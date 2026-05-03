import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const ADMIN = {
  username: 'test_books_admin',
  password: 'admin-test-pass',
  email: 'test_books_admin@42lib.kr',
  fullName: '도서 관리 테스트',
};

const STUDENT = {
  fortytwoUserId: 999991,
  username: 'test_books_student',
  email: 'test_books_student@42.fr',
  fullName: '학생 테스트',
};

async function loginAs(username: string, password: string): Promise<string> {
  const res = await request(app)
    .post('/api/v1/admin/login')
    .send({ username, password });
  return res.body.token as string;
}

async function cleanup(): Promise<void> {
  await prisma.loan.deleteMany({});
  await prisma.loanRequest.deleteMany({});
  await prisma.reservation.deleteMany({});
  await prisma.book.deleteMany({ where: { title: { startsWith: '[T068-T070]' } } });
  await prisma.student.deleteMany({ where: { username: STUDENT.username } });
  await prisma.administrator.deleteMany({ where: { username: ADMIN.username } });
}

describe('Admin book CRUD (T068/T069/T070)', () => {
  let adminToken: string;

  beforeAll(async () => {
    await cleanup();
    const passwordHash = await bcrypt.hash(ADMIN.password, 10);
    await prisma.administrator.create({
      data: {
        username: ADMIN.username,
        email: ADMIN.email,
        fullName: ADMIN.fullName,
        passwordHash,
        role: 'admin',
      },
    });
    await prisma.student.create({ data: STUDENT });
    adminToken = await loginAs(ADMIN.username, ADMIN.password);
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  describe('POST /api/v1/books (T068)', () => {
    const payload = {
      title: '[T068-T070] New Book',
      author: 'Test Author',
      isbn: '9780000000068',
      category: 'Programming',
      quantity: 3,
      availableQuantity: 3,
    };

    afterEach(async () => {
      await prisma.book.deleteMany({ where: { title: payload.title } });
    });

    it('rejects anonymous request with 401', async () => {
      await request(app).post('/api/v1/books').send(payload).expect(401);
    });

    it('creates book and returns 201 when authenticated as admin', async () => {
      const res = await request(app)
        .post('/api/v1/books')
        .set('Authorization', `Bearer ${adminToken}`)
        .send(payload)
        .expect(201);

      expect(res.body).toEqual(
        expect.objectContaining({
          title: payload.title,
          author: payload.author,
          isbn: payload.isbn,
          category: payload.category,
        }),
      );
      expect(res.body.id).toEqual(expect.any(String));
    });

    it('rejects duplicate ISBN with 400', async () => {
      await prisma.book.create({ data: payload });
      await request(app)
        .post('/api/v1/books')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ ...payload, title: '[T068-T070] Duplicate ISBN' })
        .expect(400);
    });
  });

  describe('PUT /api/v1/books/:id (T069)', () => {
    let bookId: string;

    beforeEach(async () => {
      const book = await prisma.book.create({
        data: {
          title: '[T068-T070] Original',
          author: 'Orig Author',
          isbn: '9780000000069',
          category: 'Programming',
          quantity: 2,
          availableQuantity: 2,
        },
      });
      bookId = book.id;
    });

    afterEach(async () => {
      await prisma.book.deleteMany({ where: { title: { startsWith: '[T068-T070]' } } });
    });

    it('rejects anonymous request with 401', async () => {
      await request(app)
        .put(`/api/v1/books/${bookId}`)
        .send({ title: '[T068-T070] Updated' })
        .expect(401);
    });

    it('updates book and returns 200 when authenticated', async () => {
      const res = await request(app)
        .put(`/api/v1/books/${bookId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ title: '[T068-T070] Updated', quantity: 5 })
        .expect(200);

      expect(res.body.title).toBe('[T068-T070] Updated');
      expect(res.body.quantity).toBe(5);
    });

    it('returns 404 for non-existent book id', async () => {
      await request(app)
        .put('/api/v1/books/00000000-0000-0000-0000-000000000000')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ title: '[T068-T070] X' })
        .expect(404);
    });
  });

  describe('DELETE /api/v1/books/:id (T070)', () => {
    let bookId: string;
    let studentId: string;

    beforeEach(async () => {
      const book = await prisma.book.create({
        data: {
          title: '[T068-T070] Deletable',
          author: 'Del Author',
          isbn: '9780000000070',
          category: 'Programming',
          quantity: 1,
          availableQuantity: 1,
        },
      });
      bookId = book.id;
      const student = await prisma.student.findFirst({ where: { username: STUDENT.username },
      });
      studentId = student!.id;
    });

    afterEach(async () => {
      await prisma.loan.deleteMany({ where: { bookId } });
      await prisma.loanRequest.deleteMany({ where: { bookId } });
      await prisma.book.deleteMany({ where: { id: bookId } });
    });

    it('rejects anonymous request with 401', async () => {
      await request(app).delete(`/api/v1/books/${bookId}`).expect(401);
    });

    it('deletes book and returns 204 when no active usage', async () => {
      await request(app)
        .delete(`/api/v1/books/${bookId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(204);

      const deleted = await prisma.book.findUnique({ where: { id: bookId } });
      expect(deleted).toBeNull();
    });

    it('returns 409 Conflict when book has active loan', async () => {
      // Need an admin row to satisfy Loan.approvedBy FK
      const approver = await prisma.administrator.findUnique({
        where: { username: ADMIN.username },
      });
      await prisma.loan.create({
        data: {
          studentId,
          bookId,
          status: 'active',
          dueDate: new Date(Date.now() + 7 * 24 * 60 * 60 * 1000),
          approvedBy: approver!.id,
        },
      });

      const res = await request(app)
        .delete(`/api/v1/books/${bookId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(409);

      expect(res.body.error).toBe('Conflict');
      expect(res.body.activeLoans).toBe(1);
    });

    it('returns 409 Conflict when book has pending loan request', async () => {
      await prisma.loanRequest.create({
        data: { studentId, bookId, status: 'pending' },
      });

      const res = await request(app)
        .delete(`/api/v1/books/${bookId}`)
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(409);

      expect(res.body.error).toBe('Conflict');
      expect(res.body.pendingRequests).toBe(1);
    });
  });
});
