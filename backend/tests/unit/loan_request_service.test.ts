// Phase 11 hardening — service-level tests for LoanRequestService.
// The HTTP-level tests in loan_requests.test.ts cover happy paths through
// the route layer; this file targets the validation/error branches and the
// reservation auto-creation behavior in createLoanRequest.

import { LoanRequestStatus, PrismaClient, ReservationStatus } from '@prisma/client';
import { loanRequestService } from '../../src/services/loan_request_service';

const prisma = new PrismaClient();

const PREFIX = 'lrq_svc_';
const BOOK_AVAIL = '00000000-0000-0000-0000-000000000d00';
const BOOK_FULL = '00000000-0000-0000-0000-000000000d01';

const BOOK_AVAIL_DATA = {
  id: BOOK_AVAIL,
  title: '[T112-svc] 사용 가능 도서',
  author: 'Service Test',
  isbn: '9780000000d00',
  category: 'Programming',
  quantity: 2,
  availableQuantity: 2,
};

const BOOK_FULL_DATA = {
  id: BOOK_FULL,
  title: '[T112-svc] 매진 도서',
  author: 'Service Test',
  isbn: '9780000000d01',
  category: 'Programming',
  quantity: 1,
  availableQuantity: 0,
};

async function cleanup(): Promise<void> {
  await prisma.loanRequest.deleteMany({
    where: { book: { title: { startsWith: '[T112-svc]' } } },
  });
  await prisma.reservation.deleteMany({
    where: { book: { title: { startsWith: '[T112-svc]' } } },
  });
  await prisma.book.deleteMany({
    where: { title: { startsWith: '[T112-svc]' } },
  });
  await prisma.student.deleteMany({
    where: { username: { startsWith: PREFIX } },
  });
}

async function createStudent(suffix: string) {
  const u = `${PREFIX}${suffix}`;
  return prisma.student.create({
    data: {
      fortytwoUserId: 960000 + suffix.charCodeAt(0),
      username: u,
      email: `${u}@42.fr`,
      fullName: `대출 학생 ${suffix}`,
    },
  });
}

describe('LoanRequestService (unit, service-level)', () => {
  beforeAll(async () => {
    await cleanup();
    await prisma.book.create({ data: BOOK_AVAIL_DATA });
    await prisma.book.create({ data: BOOK_FULL_DATA });
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    // Wipe loan requests + reservations + students between tests; keep books.
    await prisma.loanRequest.deleteMany({
      where: { OR: [{ bookId: BOOK_AVAIL }, { bookId: BOOK_FULL }] },
    });
    await prisma.reservation.deleteMany({
      where: { OR: [{ bookId: BOOK_AVAIL }, { bookId: BOOK_FULL }] },
    });
    await prisma.student.deleteMany({
      where: { username: { startsWith: PREFIX } },
    });
  });

  describe('createLoanRequest', () => {
    it('creates a pending request when book is available — no reservation', async () => {
      const s = await createStudent('a');
      const req = await loanRequestService.createLoanRequest(
        s.id,
        BOOK_AVAIL,
        '학기 과제용',
      );

      expect(req.status).toBe(LoanRequestStatus.pending);
      expect(req.studentId).toBe(s.id);
      expect(req.notes).toBe('학기 과제용');

      const reservations = await prisma.reservation.findMany({
        where: { studentId: s.id, bookId: BOOK_AVAIL },
      });
      expect(reservations).toHaveLength(0);
    });

    it('auto-creates a waiting reservation when book is unavailable', async () => {
      const s = await createStudent('b');
      const req = await loanRequestService.createLoanRequest(s.id, BOOK_FULL);

      expect(req.status).toBe(LoanRequestStatus.pending);

      const reservation = await prisma.reservation.findFirst({
        where: { studentId: s.id, bookId: BOOK_FULL },
      });
      expect(reservation).not.toBeNull();
      expect(reservation!.status).toBe(ReservationStatus.waiting);
      expect(reservation!.queuePosition).toBe(1);
    });

    it('assigns sequential queue positions to multiple students for the same full book', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const c = await createStudent('c');
      await loanRequestService.createLoanRequest(a.id, BOOK_FULL);
      await loanRequestService.createLoanRequest(b.id, BOOK_FULL);
      await loanRequestService.createLoanRequest(c.id, BOOK_FULL);

      const positions = await prisma.reservation.findMany({
        where: { bookId: BOOK_FULL },
        orderBy: { queuePosition: 'asc' },
        select: { studentId: true, queuePosition: true },
      });
      expect(positions.map((p) => p.queuePosition)).toEqual([1, 2, 3]);
      expect(positions.map((p) => p.studentId)).toEqual([a.id, b.id, c.id]);
    });

    it('throws when student is not found', async () => {
      await expect(
        loanRequestService.createLoanRequest(
          '00000000-0000-0000-0000-000000000000',
          BOOK_AVAIL,
        ),
      ).rejects.toThrow('학생을 찾을 수 없습니다');
    });

    it('throws when book is not found', async () => {
      const s = await createStudent('a');
      await expect(
        loanRequestService.createLoanRequest(
          s.id,
          '00000000-0000-0000-0000-deadbeef0000',
        ),
      ).rejects.toThrow('책을 찾을 수 없습니다');
    });

    it('throws when student already has a pending request for the same book', async () => {
      const s = await createStudent('a');
      await loanRequestService.createLoanRequest(s.id, BOOK_AVAIL);

      await expect(
        loanRequestService.createLoanRequest(s.id, BOOK_AVAIL),
      ).rejects.toThrow('이미 해당 책에 대한 대출 신청');
    });
  });

  describe('getStudentLoanRequests', () => {
    it('returns requests for the student in descending requestDate order', async () => {
      const s = await createStudent('a');
      await loanRequestService.createLoanRequest(s.id, BOOK_AVAIL, 'first');
      // Small delay so requestDate timestamps differ enough to sort.
      await new Promise((r) => setTimeout(r, 10));
      await loanRequestService.createLoanRequest(s.id, BOOK_FULL, 'second');

      const list = await loanRequestService.getStudentLoanRequests(s.id);

      expect(list).toHaveLength(2);
      expect(list[0].notes).toBe('second');
      expect(list[1].notes).toBe('first');
    });

    it('returns an empty array when student has no requests', async () => {
      const s = await createStudent('a');
      const list = await loanRequestService.getStudentLoanRequests(s.id);
      expect(list).toEqual([]);
    });
  });

  describe('getPendingLoanRequests', () => {
    it('returns only pending requests across all students, ordered by requestDate asc', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      await loanRequestService.createLoanRequest(a.id, BOOK_AVAIL, 'a-pending');
      await new Promise((r) => setTimeout(r, 10));
      const second = await loanRequestService.createLoanRequest(
        b.id,
        BOOK_FULL,
        'b-pending',
      );
      // Manually flip the second one to cancelled so it must be excluded.
      await prisma.loanRequest.update({
        where: { id: second.id },
        data: { status: LoanRequestStatus.cancelled },
      });

      const list = await loanRequestService.getPendingLoanRequests();
      const fromTestData = list.filter((r) =>
        [BOOK_AVAIL, BOOK_FULL].includes(r.bookId),
      );

      expect(fromTestData).toHaveLength(1);
      expect(fromTestData[0].studentId).toBe(a.id);
      expect(fromTestData[0].status).toBe(LoanRequestStatus.pending);
    });
  });

  describe('getStudentReservations', () => {
    it('returns waiting + notified reservations ordered by queuePosition', async () => {
      const a = await createStudent('a');
      // Two reservations on full book — both waiting at positions 1, 2.
      await prisma.reservation.create({
        data: {
          studentId: a.id,
          bookId: BOOK_FULL,
          queuePosition: 5,
          status: ReservationStatus.waiting,
        },
      });
      await prisma.reservation.create({
        data: {
          studentId: a.id,
          bookId: BOOK_AVAIL,
          queuePosition: 1,
          status: ReservationStatus.notified,
          notifiedAt: new Date(),
          expiresAt: new Date(Date.now() + 60_000),
        },
      });
      // Cancelled one must not appear.
      await prisma.reservation.create({
        data: {
          studentId: a.id,
          bookId: BOOK_FULL,
          queuePosition: 7,
          status: ReservationStatus.cancelled,
        },
      });

      const list = await loanRequestService.getStudentReservations(a.id);

      expect(list).toHaveLength(2);
      expect(list.map((r) => r.queuePosition)).toEqual([1, 5]);
      expect(list.every((r) => r.status !== ReservationStatus.cancelled)).toBe(true);
    });

    it('returns empty list when student has no active reservations', async () => {
      const a = await createStudent('a');
      const list = await loanRequestService.getStudentReservations(a.id);
      expect(list).toEqual([]);
    });
  });

  describe('cancelLoanRequest', () => {
    it('cancels a pending request owned by the student', async () => {
      const s = await createStudent('a');
      const req = await loanRequestService.createLoanRequest(s.id, BOOK_AVAIL);

      const updated = await loanRequestService.cancelLoanRequest(req.id, s.id);

      expect(updated.status).toBe(LoanRequestStatus.cancelled);
    });

    it('throws when request is not found', async () => {
      await expect(
        loanRequestService.cancelLoanRequest(
          '00000000-0000-0000-0000-000000000000',
          'nope',
        ),
      ).rejects.toThrow('대출 신청을 찾을 수 없습니다');
    });

    it('throws when student does not own the request', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const req = await loanRequestService.createLoanRequest(a.id, BOOK_AVAIL);

      await expect(
        loanRequestService.cancelLoanRequest(req.id, b.id),
      ).rejects.toThrow('권한이 없습니다');
    });

    it('throws when request is not in pending status', async () => {
      const s = await createStudent('a');
      const req = await loanRequestService.createLoanRequest(s.id, BOOK_AVAIL);
      await prisma.loanRequest.update({
        where: { id: req.id },
        data: { status: LoanRequestStatus.approved },
      });

      await expect(
        loanRequestService.cancelLoanRequest(req.id, s.id),
      ).rejects.toThrow('대기 중인 신청만');
    });
  });
});
