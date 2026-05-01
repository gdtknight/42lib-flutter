// T100: POST /loan-requests integration tests

import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient } from '@prisma/client';
import { generateStudentToken } from '../../src/utils/jwt';

const prisma = new PrismaClient();

const STUDENT = {
  fortytwoUserId: 999100,
  username: 'lr_student',
  email: 'lr_student@42.fr',
  fullName: '대출 테스트 학생',
};

const BOOK_AVAILABLE = {
  id: '00000000-0000-0000-0000-000000000a00',
  title: '[T100] 사용 가능 도서',
  author: 'T100 저자',
  isbn: '9780000000a00',
  category: 'Programming',
  quantity: 2,
  availableQuantity: 2,
};

const BOOK_UNAVAILABLE = {
  id: '00000000-0000-0000-0000-000000000a01',
  title: '[T100] 모두 대출 중',
  author: 'T100 저자',
  isbn: '9780000000a01',
  category: 'Programming',
  quantity: 1,
  availableQuantity: 0,
};

async function cleanup(): Promise<void> {
  await prisma.loanRequest.deleteMany({ where: { book: { title: { startsWith: '[T100]' } } } });
  await prisma.reservation.deleteMany({ where: { book: { title: { startsWith: '[T100]' } } } });
  await prisma.book.deleteMany({ where: { title: { startsWith: '[T100]' } } });
  await prisma.student.deleteMany({ where: { username: STUDENT.username } });
}

describe('POST /api/v1/loan-requests (T100)', () => {
  let studentId: string;
  let token: string;

  beforeAll(async () => {
    await cleanup();
    const student = await prisma.student.create({ data: STUDENT });
    studentId = student.id;
    await prisma.book.create({ data: BOOK_AVAILABLE });
    await prisma.book.create({ data: BOOK_UNAVAILABLE });

    token = generateStudentToken(
      student.id,
      student.username,
      student.email,
      student.fortytwoUserId,
    );
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    // Reset transactional rows between tests so duplicates don't bleed.
    await prisma.loanRequest.deleteMany({ where: { studentId } });
    await prisma.reservation.deleteMany({ where: { studentId } });
  });

  it('rejects anonymous request with 401', async () => {
    await request(app)
      .post('/api/v1/loan-requests')
      .send({ bookId: BOOK_AVAILABLE.id })
      .expect(401);
  });

  it('rejects admin token with 403', async () => {
    const adminLikeToken = generateStudentToken(
      'admin-id',
      'admin-as-student',
      'a@x',
      0,
    );
    // Manually craft a token whose role isn't student — easier path:
    // student tokens with role=student should pass; this test demonstrates
    // that the route uses authenticateStudent. We assert with a non-student
    // role by signing manually.
    const jwt = require('jsonwebtoken');
    const adminToken = jwt.sign(
      {
        userId: 'a',
        username: 'a',
        email: 'a@x',
        role: 'admin',
      },
      process.env.JWT_SECRET || 'dev-secret-change-in-production',
      { expiresIn: '1h' },
    );

    await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${adminToken}`)
      .send({ bookId: BOOK_AVAILABLE.id })
      .expect(403);

    // adminLikeToken intentionally unused; kept above to document the role
    // distinction.
    expect(adminLikeToken).toEqual(expect.any(String));
  });

  it('returns 400 when bookId is missing', async () => {
    const res = await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${token}`)
      .send({})
      .expect(400);
    expect(res.body.error).toBe('Bad Request');
  });

  it('creates pending loan request when book is available (no reservation)', async () => {
    const res = await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookId: BOOK_AVAILABLE.id })
      .expect(201);

    expect(res.body.success).toBe(true);
    expect(res.body.data.status).toBe('pending');
    expect(res.body.data.book.id).toBe(BOOK_AVAILABLE.id);

    const reservationCount = await prisma.reservation.count({
      where: { studentId, bookId: BOOK_AVAILABLE.id },
    });
    expect(reservationCount).toBe(0);
  });

  it('creates loan request AND reservation when book is unavailable', async () => {
    const res = await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookId: BOOK_UNAVAILABLE.id })
      .expect(201);

    expect(res.body.data.status).toBe('pending');

    const reservation = await prisma.reservation.findFirst({
      where: { studentId, bookId: BOOK_UNAVAILABLE.id },
    });
    expect(reservation).not.toBeNull();
    expect(reservation!.queuePosition).toBe(1);
    expect(reservation!.status).toBe('waiting');
  });

  it('rejects duplicate pending request for same book (VR-205)', async () => {
    await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookId: BOOK_AVAILABLE.id })
      .expect(201);

    const res = await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${token}`)
      .send({ bookId: BOOK_AVAILABLE.id })
      .expect(400);

    expect(res.body.message).toContain('이미');
  });
});
