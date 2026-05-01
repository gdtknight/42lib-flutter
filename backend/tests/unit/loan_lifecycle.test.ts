// T135/T136/T137: Loan lifecycle — approve, reject, return, overdue detection,
// reservation queue notification on return.

import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient, LoanStatus, ReservationStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { generateAdminToken, generateStudentToken } from '../../src/utils/jwt';
import { loanService } from '../../src/services/loan_service';

const prisma = new PrismaClient();

const TITLE_PREFIX = '[LOAN-CYCLE]';

const ADMIN = {
  username: 'cycle_admin',
  password: 'cycle-admin-pass',
  email: 'cycle_admin@42lib.kr',
  fullName: '대출 사이클 관리자',
};

async function cleanup(): Promise<void> {
  await prisma.loan.deleteMany({ where: { book: { title: { startsWith: TITLE_PREFIX } } } });
  await prisma.loanRequest.deleteMany({ where: { book: { title: { startsWith: TITLE_PREFIX } } } });
  await prisma.reservation.deleteMany({ where: { book: { title: { startsWith: TITLE_PREFIX } } } });
  await prisma.book.deleteMany({ where: { title: { startsWith: TITLE_PREFIX } } });
  await prisma.student.deleteMany({ where: { username: { startsWith: 'cycle_student_' } } });
  await prisma.administrator.deleteMany({ where: { username: ADMIN.username } });
}

async function createStudent(suffix: string) {
  return prisma.student.create({
    data: {
      fortytwoUserId: 970000 + suffix.charCodeAt(0),
      username: `cycle_student_${suffix}`,
      email: `cycle_student_${suffix}@42.fr`,
      fullName: `사이클 학생 ${suffix}`,
    },
  });
}

describe('Loan lifecycle (T135/T136/T137)', () => {
  let adminId: string;
  let adminToken: string;

  beforeAll(async () => {
    await cleanup();
    const passwordHash = await bcrypt.hash(ADMIN.password, 10);
    const admin = await prisma.administrator.create({
      data: {
        username: ADMIN.username,
        email: ADMIN.email,
        fullName: ADMIN.fullName,
        passwordHash,
        role: 'admin',
      },
    });
    adminId = admin.id;
    adminToken = generateAdminToken(admin.id, admin.username, admin.email, admin.role);
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  describe('PUT /api/v1/loan-requests/:id/approve (T135)', () => {
    it('creates Loan and decrements availableQuantity', async () => {
      const student = await createStudent('a');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} approve-target`,
          author: 'Approve Author',
          category: 'Programming',
          quantity: 2,
          availableQuantity: 2,
        },
      });
      const lr = await prisma.loanRequest.create({
        data: { studentId: student.id, bookId: book.id, status: 'pending' },
      });

      const res = await request(app)
        .put(`/api/v1/loan-requests/${lr.id}/approve`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({})
        .expect(200);

      expect(res.body.data.status).toBe('active');
      expect(res.body.data.bookId).toBe(book.id);

      const refreshedBook = await prisma.book.findUnique({ where: { id: book.id } });
      expect(refreshedBook!.availableQuantity).toBe(1);

      const refreshedRequest = await prisma.loanRequest.findUnique({ where: { id: lr.id } });
      expect(refreshedRequest!.status).toBe('approved');
      expect(refreshedRequest!.reviewedBy).toBe(adminId);
    });

    it('rejects approval when book is unavailable (409)', async () => {
      const student = await createStudent('b');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} approve-unavailable`,
          author: 'X',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 0,
        },
      });
      const lr = await prisma.loanRequest.create({
        data: { studentId: student.id, bookId: book.id, status: 'pending' },
      });

      const res = await request(app)
        .put(`/api/v1/loan-requests/${lr.id}/approve`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(409);

      expect(res.body.error).toBe('book_unavailable');
    });

    it('rejects non-pending requests (400)', async () => {
      const student = await createStudent('c');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} approve-already-reviewed`,
          author: 'X',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 1,
        },
      });
      const lr = await prisma.loanRequest.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: 'rejected',
          reviewedAt: new Date(),
          reviewedBy: adminId,
          rejectionReason: '이전 반려',
        },
      });

      await request(app)
        .put(`/api/v1/loan-requests/${lr.id}/approve`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(400);
    });
  });

  describe('PUT /api/v1/loan-requests/:id/reject', () => {
    it('rejects with reason and updates request', async () => {
      const student = await createStudent('d');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} reject-target`,
          author: 'X',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 1,
        },
      });
      const lr = await prisma.loanRequest.create({
        data: { studentId: student.id, bookId: book.id, status: 'pending' },
      });

      const res = await request(app)
        .put(`/api/v1/loan-requests/${lr.id}/reject`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ rejectionReason: '학생이 이전 도서를 반납하지 않음' })
        .expect(200);

      expect(res.body.data.status).toBe('rejected');
      expect(res.body.data.rejectionReason).toContain('학생이 이전');
    });

    it('returns 400 when rejectionReason missing', async () => {
      const student = await createStudent('e');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} reject-no-reason`,
          author: 'X',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 1,
        },
      });
      const lr = await prisma.loanRequest.create({
        data: { studentId: student.id, bookId: book.id, status: 'pending' },
      });

      await request(app)
        .put(`/api/v1/loan-requests/${lr.id}/reject`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({})
        .expect(400);
    });
  });

  describe('PUT /api/v1/loans/:id/return (T136)', () => {
    it('marks loan returned, increments availability, notifies queue', async () => {
      const borrower = await createStudent('f');
      const waiter = await createStudent('g');

      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} return-target`,
          author: 'X',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 0, // borrowed out
        },
      });

      // Active loan held by borrower
      const loan = await prisma.loan.create({
        data: {
          studentId: borrower.id,
          bookId: book.id,
          status: LoanStatus.active,
          dueDate: new Date(Date.now() + 7 * 86400_000),
          approvedBy: adminId,
        },
      });

      // Waiter is queued for this book
      await prisma.reservation.create({
        data: {
          studentId: waiter.id,
          bookId: book.id,
          queuePosition: 1,
          status: ReservationStatus.waiting,
        },
      });

      const res = await request(app)
        .put(`/api/v1/loans/${loan.id}/return`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body.data.status).toBe('returned');
      expect(res.body.data.returnedDate).not.toBeNull();

      const refreshedBook = await prisma.book.findUnique({ where: { id: book.id } });
      expect(refreshedBook!.availableQuantity).toBe(1);

      const refreshedReservation = await prisma.reservation.findFirst({
        where: { studentId: waiter.id, bookId: book.id },
      });
      expect(refreshedReservation!.status).toBe(ReservationStatus.notified);
      expect(refreshedReservation!.notifiedAt).not.toBeNull();
    });

    it('returns 404 for non-existent loan', async () => {
      await request(app)
        .put('/api/v1/loans/00000000-0000-0000-0000-000000000000/return')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(404);
    });

    it('returns 409 when loan already returned', async () => {
      const student = await createStudent('h');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} double-return`,
          author: 'X',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 1,
        },
      });
      const loan = await prisma.loan.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanStatus.returned,
          dueDate: new Date(),
          returnedDate: new Date(),
          approvedBy: adminId,
        },
      });

      await request(app)
        .put(`/api/v1/loans/${loan.id}/return`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(409);
    });
  });

  describe('detectOverdue (T137)', () => {
    it('marks active loans past dueDate as overdue', async () => {
      const student = await createStudent('i');
      const book = await prisma.book.create({
        data: {
          title: `${TITLE_PREFIX} overdue-target`,
          author: 'X',
          category: 'Programming',
          quantity: 2,
          availableQuantity: 0,
        },
      });
      // Two active loans: one past due, one not yet
      const pastDue = await prisma.loan.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanStatus.active,
          dueDate: new Date(Date.now() - 86400_000), // 1 day ago
          approvedBy: adminId,
        },
      });
      const notYet = await prisma.loan.create({
        data: {
          studentId: student.id,
          bookId: book.id,
          status: LoanStatus.active,
          dueDate: new Date(Date.now() + 86400_000), // 1 day from now
          approvedBy: adminId,
        },
      });

      const updatedCount = await loanService.detectOverdue();
      expect(updatedCount).toBeGreaterThanOrEqual(1);

      const refreshedPastDue = await prisma.loan.findUnique({ where: { id: pastDue.id } });
      const refreshedNotYet = await prisma.loan.findUnique({ where: { id: notYet.id } });
      expect(refreshedPastDue!.status).toBe('overdue');
      expect(refreshedNotYet!.status).toBe('active');
    });
  });

  describe('GET /api/v1/loans (T143 list)', () => {
    it('rejects student token (admin only)', async () => {
      const student = await createStudent('j');
      const studentToken = generateStudentToken(
        student.id,
        student.username,
        student.email,
        student.fortytwoUserId,
      );

      await request(app)
        .get('/api/v1/loans')
        .set('Authorization', `Bearer ${studentToken}`)
        .expect(403);
    });

    it('returns paginated results for admin', async () => {
      const res = await request(app)
        .get('/api/v1/loans?limit=5')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(res.body).toEqual(
        expect.objectContaining({
          data: expect.any(Array),
          total: expect.any(Number),
          page: 1,
          limit: 5,
        }),
      );
    });
  });
});
