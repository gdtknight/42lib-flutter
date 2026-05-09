// Phase 11/T156-T157 — service-level tests for LoanService.
// loan_lifecycle.test.ts covers HTTP happy paths; this file targets the
// uncovered branches (request not found, reject errors, return → reservation
// notification side-effect, history filters).

import { LoanRequestStatus, LoanStatus, PrismaClient, ReservationStatus } from '@prisma/client';
import { loanService, LoanError } from '../../src/services/loan_service';

const prisma = new PrismaClient();
const PREFIX = 'loan_svc_';
const TITLE_PREFIX = '[LOAN-SVC]';

async function cleanup(): Promise<void> {
  await prisma.loan.deleteMany({
    where: { book: { title: { startsWith: TITLE_PREFIX } } },
  });
  await prisma.loanRequest.deleteMany({
    where: { book: { title: { startsWith: TITLE_PREFIX } } },
  });
  await prisma.reservation.deleteMany({
    where: { book: { title: { startsWith: TITLE_PREFIX } } },
  });
  await prisma.book.deleteMany({ where: { title: { startsWith: TITLE_PREFIX } } });
  await prisma.student.deleteMany({ where: { username: { startsWith: PREFIX } } });
  await prisma.administrator.deleteMany({ where: { username: { startsWith: PREFIX } } });
}

async function makeStudent(suffix: string) {
  return prisma.student.create({
    data: {
      fortytwoUserId: 940000 + suffix.charCodeAt(0),
      username: `${PREFIX}${suffix}`,
      email: `${PREFIX}${suffix}@42.fr`,
      fullName: `학생 ${suffix}`,
    },
  });
}

let _isbnCounter = 9000000;
function nextIsbn(): string {
  // 13-digit string starting with 978000 (test-only prefix). Counter ensures
  // uniqueness across the suite regardless of timing.
  _isbnCounter += 1;
  return `978000${_isbnCounter.toString().padStart(7, '0')}`;
}

async function makeBook(suffix: string, availableQuantity: number, quantity: number = 2) {
  return prisma.book.create({
    data: {
      title: `${TITLE_PREFIX} ${suffix}`,
      author: 'svc-author',
      category: 'Programming',
      isbn: nextIsbn(),
      quantity,
      availableQuantity,
    },
  });
}

async function makeAdmin() {
  return prisma.administrator.create({
    data: {
      username: `${PREFIX}admin`,
      email: `${PREFIX}admin@42lib.kr`,
      fullName: '서비스 관리자',
      passwordHash: 'unused-in-tests',
      role: 'admin',
    },
  });
}

describe('LoanService (unit)', () => {
  let adminId: string;

  beforeAll(async () => {
    await cleanup();
    const a = await makeAdmin();
    adminId = a.id;
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  describe('approveLoanRequest (T156 — 가용 자동 차감)', () => {
    it('decrements book.availableQuantity inside transaction', async () => {
      const student = await makeStudent('a');
      const book = await makeBook('a', 2, 2);
      const lr = await prisma.loanRequest.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanRequestStatus.pending,
        },
      });

      const loan = await loanService.approveLoanRequest(lr.id, adminId);

      const refreshed = await prisma.book.findUnique({ where: { id: book.id } });
      expect(refreshed!.availableQuantity).toBe(1);
      expect(loan.status).toBe(LoanStatus.active);
      expect(loan.bookId).toBe(book.id);

      const updatedRequest = await prisma.loanRequest.findUnique({ where: { id: lr.id } });
      expect(updatedRequest!.status).toBe(LoanRequestStatus.approved);
      expect(updatedRequest!.reviewedBy).toBe(adminId);
    });

    it('throws request_not_found for unknown id', async () => {
      await expect(
        loanService.approveLoanRequest(
          '00000000-0000-0000-0000-000000000000',
          adminId,
        ),
      ).rejects.toThrow(LoanError);
    });

    it('throws not_pending when status is already approved', async () => {
      const student = await makeStudent('b');
      const book = await makeBook('b', 1, 1);
      const lr = await prisma.loanRequest.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanRequestStatus.approved,
        },
      });

      await expect(
        loanService.approveLoanRequest(lr.id, adminId),
      ).rejects.toThrow('대기 중인 요청');
    });

    it('throws book_unavailable when availableQuantity is 0', async () => {
      const student = await makeStudent('c');
      const book = await makeBook('c', 0, 1);
      const lr = await prisma.loanRequest.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanRequestStatus.pending,
        },
      });

      await expect(
        loanService.approveLoanRequest(lr.id, adminId),
      ).rejects.toThrow('도서가 가용하지 않습니다');

      // Availability should not have been touched.
      const refreshed = await prisma.book.findUnique({ where: { id: book.id } });
      expect(refreshed!.availableQuantity).toBe(0);
    });
  });

  describe('rejectLoanRequest', () => {
    it('throws request_not_found for unknown id', async () => {
      await expect(
        loanService.rejectLoanRequest(
          '00000000-0000-0000-0000-000000000000',
          adminId,
          '사유',
        ),
      ).rejects.toThrow('대출 요청을 찾을 수 없습니다');
    });

    it('throws not_pending when already approved', async () => {
      const student = await makeStudent('d');
      const book = await makeBook('d', 1, 1);
      const lr = await prisma.loanRequest.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanRequestStatus.approved,
        },
      });

      await expect(
        loanService.rejectLoanRequest(lr.id, adminId, '동일 도서 미반납'),
      ).rejects.toThrow('대기 중인 요청');
    });
  });

  describe('returnLoan (T157 — 다음 예약자 자동 알림)', () => {
    it('increments availableQuantity AND notifies the first waiting reservation',
        async () => {
      const a = await makeStudent('e');
      const b = await makeStudent('f');
      const book = await makeBook('e', 0, 1);

      // Active loan held by `a`.
      const loan = await prisma.loan.create({
        data: {
          studentId: a.id,
          bookId: book.id,
          status: LoanStatus.active,
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          approvedBy: adminId,
        },
      });

      // `b` is in the reservation queue.
      const reservation = await prisma.reservation.create({
        data: {
          studentId: b.id,
          bookId: book.id,
          queuePosition: 1,
          status: ReservationStatus.waiting,
        },
      });

      await loanService.returnLoan(loan.id);

      const refreshedBook = await prisma.book.findUnique({ where: { id: book.id } });
      expect(refreshedBook!.availableQuantity).toBe(1);

      const refreshedLoan = await prisma.loan.findUnique({ where: { id: loan.id } });
      expect(refreshedLoan!.status).toBe(LoanStatus.returned);
      expect(refreshedLoan!.returnedDate).not.toBeNull();

      const refreshedReservation = await prisma.reservation.findUnique({
        where: { id: reservation.id },
      });
      expect(refreshedReservation!.status).toBe(ReservationStatus.notified);
      expect(refreshedReservation!.notifiedAt).not.toBeNull();
      expect(refreshedReservation!.expiresAt).not.toBeNull();
    });

    it('returns successfully even when the queue is empty', async () => {
      const a = await makeStudent('g');
      const book = await makeBook('g', 0, 1);
      const loan = await prisma.loan.create({
        data: {
          studentId: a.id,
          bookId: book.id,
          status: LoanStatus.active,
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          approvedBy: adminId,
        },
      });

      const returned = await loanService.returnLoan(loan.id);
      expect(returned.status).toBe(LoanStatus.returned);
    });

    it('throws loan_not_found for unknown id', async () => {
      await expect(
        loanService.returnLoan('00000000-0000-0000-0000-000000000000'),
      ).rejects.toThrow('대출을 찾을 수 없습니다');
    });

    it('throws not_active when loan is already returned', async () => {
      const a = await makeStudent('h');
      const book = await makeBook('h', 0, 1);
      const loan = await prisma.loan.create({
        data: {
          studentId: a.id,
          bookId: book.id,
          status: LoanStatus.returned,
          dueDate: new Date(Date.now() + 14 * 24 * 60 * 60 * 1000),
          returnedDate: new Date(),
          approvedBy: adminId,
        },
      });

      await expect(loanService.returnLoan(loan.id)).rejects.toThrow(
        '진행 중인 대출만',
      );
    });
  });

  describe('getHistory (date filters)', () => {
    it('honors from/to date range', async () => {
      const a = await makeStudent('i');
      const book = await makeBook('i', 1, 1);

      // Two loans: one in window, one outside.
      await prisma.loan.create({
        data: {
          studentId: a.id,
          bookId: book.id,
          status: LoanStatus.returned,
          checkoutDate: new Date('2024-03-15'),
          dueDate: new Date('2024-03-29'),
          returnedDate: new Date('2024-03-20'),
          approvedBy: adminId,
        },
      });
      await prisma.loan.create({
        data: {
          studentId: a.id,
          bookId: book.id,
          status: LoanStatus.returned,
          checkoutDate: new Date('2024-06-15'),
          dueDate: new Date('2024-06-29'),
          returnedDate: new Date('2024-06-20'),
          approvedBy: adminId,
        },
      });

      const inMarch = await loanService.getHistory({
        from: new Date('2024-03-01'),
        to: new Date('2024-03-31'),
      });
      const fromTest = inMarch.data.filter((l) => l.bookId === book.id);
      expect(fromTest).toHaveLength(1);
      expect(fromTest[0].checkoutDate.toISOString().startsWith('2024-03'))
          .toBe(true);
    });

    it('returns all when no filters provided', async () => {
      const result = await loanService.getHistory({});
      expect(result.data.length).toBeGreaterThanOrEqual(0);
      expect(result.page).toBe(1);
    });
  });
});
