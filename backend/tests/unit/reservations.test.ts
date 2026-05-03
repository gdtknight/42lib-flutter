// T101: Reservation queue logic tests
// Verifies FIFO queue position assignment per book.

import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient } from '@prisma/client';
import { generateStudentToken } from '../../src/utils/jwt';

const prisma = new PrismaClient();

const STUDENT_PREFIX = 'rsv_test_';

const BOOK_FULL = {
  id: '00000000-0000-0000-0000-000000000b00',
  title: '[T101] 매진 도서',
  author: 'T101 Author',
  isbn: '9780000000b00',
  category: 'Programming',
  quantity: 1,
  availableQuantity: 0,
};

async function cleanup(): Promise<void> {
  await prisma.loanRequest.deleteMany({ where: { book: { title: { startsWith: '[T101]' } } } });
  await prisma.reservation.deleteMany({ where: { book: { title: { startsWith: '[T101]' } } } });
  await prisma.book.deleteMany({ where: { title: { startsWith: '[T101]' } } });
  await prisma.student.deleteMany({ where: { username: { startsWith: STUDENT_PREFIX } } });
}

async function createStudent(suffix: string) {
  const u = `${STUDENT_PREFIX}${suffix}`;
  return prisma.student.create({
    data: {
      fortytwoUserId: 990000 + suffix.charCodeAt(0),
      username: u,
      email: `${u}@42.fr`,
      fullName: `예약 학생 ${suffix}`,
    },
  });
}

function tokenFor(s: { id: string; username: string; email: string; fortytwoUserId: number }) {
  return generateStudentToken(s.id, s.username, s.email, s.fortytwoUserId);
}

describe('Reservation queue (T101)', () => {
  beforeAll(async () => {
    await cleanup();
    await prisma.book.create({ data: BOOK_FULL });
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  it('assigns increasing queue positions to sequential reservations', async () => {
    // Three students each request the unavailable book → three reservations
    // at positions 1, 2, 3 in arrival order.
    const a = await createStudent('a');
    const b = await createStudent('b');
    const c = await createStudent('c');

    await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${tokenFor(a)}`)
      .send({ bookId: BOOK_FULL.id })
      .expect(201);

    await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${tokenFor(b)}`)
      .send({ bookId: BOOK_FULL.id })
      .expect(201);

    await request(app)
      .post('/api/v1/loan-requests')
      .set('Authorization', `Bearer ${tokenFor(c)}`)
      .send({ bookId: BOOK_FULL.id })
      .expect(201);

    const reservations = await prisma.reservation.findMany({
      where: { bookId: BOOK_FULL.id },
      orderBy: { queuePosition: 'asc' },
      include: { student: { select: { username: true } } },
    });

    expect(reservations).toHaveLength(3);
    expect(reservations.map((r) => r.queuePosition)).toEqual([1, 2, 3]);
    expect(reservations.map((r) => r.student.username)).toEqual([
      `${STUDENT_PREFIX}a`,
      `${STUDENT_PREFIX}b`,
      `${STUDENT_PREFIX}c`,
    ]);
    expect(reservations.every((r) => r.status === 'waiting')).toBe(true);
  });

  it('exposes student reservations via GET /api/v1/loan-requests/my/reservations', async () => {
    const student = await prisma.student.findFirst({
      where: { username: `${STUDENT_PREFIX}a` },
    });
    expect(student).not.toBeNull();

    const token = tokenFor({
      id: student!.id,
      username: student!.username,
      email: student!.email,
      fortytwoUserId: student!.fortytwoUserId,
    });

    const res = await request(app)
      .get('/api/v1/loan-requests/my/reservations')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(Array.isArray(res.body.data)).toBe(true);
    expect(res.body.data.length).toBeGreaterThanOrEqual(1);
    expect(res.body.data[0].queuePosition).toBe(1);
  });
});
