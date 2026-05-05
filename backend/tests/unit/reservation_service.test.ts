// Phase 11 hardening — direct service-level tests for ReservationService.
// Complements the HTTP integration tests in reservations.test.ts by covering
// branches not reachable via the loan-request endpoints
// (handleExpiredReservations, reorderQueue, cancel ownership/state checks,
// getQueuePosition).

import { PrismaClient, ReservationStatus } from '@prisma/client';
import { reservationService } from '../../src/services/reservation_service';

const prisma = new PrismaClient();

const PREFIX = 'rsv_svc_';
const BOOK_ID = '00000000-0000-0000-0000-000000000c00';
const BOOK_DATA = {
  id: BOOK_ID,
  title: '[T101-svc] 서비스 테스트 도서',
  author: 'Service Test',
  isbn: '9780000000c00',
  category: 'Programming',
  quantity: 1,
  availableQuantity: 0,
};

async function cleanup(): Promise<void> {
  await prisma.loanRequest.deleteMany({
    where: { book: { title: { startsWith: '[T101-svc]' } } },
  });
  await prisma.reservation.deleteMany({
    where: { book: { title: { startsWith: '[T101-svc]' } } },
  });
  await prisma.book.deleteMany({ where: { title: { startsWith: '[T101-svc]' } } });
  await prisma.student.deleteMany({ where: { username: { startsWith: PREFIX } } });
}

async function createStudent(suffix: string) {
  const u = `${PREFIX}${suffix}`;
  return prisma.student.create({
    data: {
      fortytwoUserId: 970000 + suffix.charCodeAt(0),
      username: u,
      email: `${u}@42.fr`,
      fullName: `예약 학생 ${suffix}`,
    },
  });
}

async function makeReservation(
  studentId: string,
  position: number,
  status: ReservationStatus = ReservationStatus.waiting,
  overrides: Partial<{ notifiedAt: Date; expiresAt: Date }> = {},
) {
  return prisma.reservation.create({
    data: {
      studentId,
      bookId: BOOK_ID,
      queuePosition: position,
      status,
      ...overrides,
    },
  });
}

describe('ReservationService (unit, service-level)', () => {
  beforeAll(async () => {
    await cleanup();
    await prisma.book.create({ data: BOOK_DATA });
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    // Wipe reservations and students between tests to keep cases independent
    // (book row is preserved).
    await prisma.reservation.deleteMany({ where: { bookId: BOOK_ID } });
    await prisma.student.deleteMany({
      where: { username: { startsWith: PREFIX } },
    });
  });

  describe('notifyNextInQueue', () => {
    it('notifies the first waiting reservation and sets a 24h expiry', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      await makeReservation(a.id, 1);
      await makeReservation(b.id, 2);

      const before = Date.now();
      const updated = await reservationService.notifyNextInQueue(BOOK_ID);
      const after = Date.now();

      expect(updated).not.toBeNull();
      expect(updated!.studentId).toBe(a.id);
      expect(updated!.status).toBe(ReservationStatus.notified);
      expect(updated!.notifiedAt).not.toBeNull();

      const expiresAt = updated!.expiresAt!.getTime();
      // Within ±5 seconds of (now + 24h) for both bounds.
      expect(expiresAt).toBeGreaterThanOrEqual(before + 24 * 60 * 60 * 1000 - 5000);
      expect(expiresAt).toBeLessThanOrEqual(after + 24 * 60 * 60 * 1000 + 5000);

      // The second reservation should remain untouched.
      const second = await prisma.reservation.findFirst({
        where: { studentId: b.id },
      });
      expect(second!.status).toBe(ReservationStatus.waiting);
    });

    it('returns null when there is nothing waiting', async () => {
      const result = await reservationService.notifyNextInQueue(BOOK_ID);
      expect(result).toBeNull();
    });

    it('skips already-notified reservations and picks the next waiting', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      await makeReservation(a.id, 1, ReservationStatus.notified, {
        notifiedAt: new Date(),
        expiresAt: new Date(Date.now() + 60_000),
      });
      await makeReservation(b.id, 2);

      const updated = await reservationService.notifyNextInQueue(BOOK_ID);
      expect(updated!.studentId).toBe(b.id);
    });
  });

  describe('handleExpiredReservations', () => {
    it('marks notified reservations past expiry as expired and notifies the next', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const past = new Date(Date.now() - 60_000);
      await makeReservation(a.id, 1, ReservationStatus.notified, {
        notifiedAt: new Date(Date.now() - 25 * 60 * 60 * 1000),
        expiresAt: past,
      });
      await makeReservation(b.id, 2);

      const expired = await reservationService.handleExpiredReservations();

      expect(expired).toHaveLength(1);
      expect(expired[0].studentId).toBe(a.id);

      const refreshedA = await prisma.reservation.findFirst({
        where: { studentId: a.id },
      });
      expect(refreshedA!.status).toBe(ReservationStatus.expired);

      const refreshedB = await prisma.reservation.findFirst({
        where: { studentId: b.id },
      });
      expect(refreshedB!.status).toBe(ReservationStatus.notified);
    });

    it('returns empty array when nothing is expired', async () => {
      const a = await createStudent('a');
      // Notified but not yet past expiry.
      await makeReservation(a.id, 1, ReservationStatus.notified, {
        notifiedAt: new Date(),
        expiresAt: new Date(Date.now() + 60_000),
      });

      const expired = await reservationService.handleExpiredReservations();
      expect(expired).toHaveLength(0);
    });
  });

  describe('reorderQueue', () => {
    it('renumbers gaps so positions are sequential 1..N', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const c = await createStudent('c');
      // Intentional gap (1, 3, 5) to verify renumbering compacts to 1, 2, 3.
      await makeReservation(a.id, 1);
      await makeReservation(b.id, 3);
      await makeReservation(c.id, 5);

      await reservationService.reorderQueue(BOOK_ID);

      const list = await prisma.reservation.findMany({
        where: { bookId: BOOK_ID },
        orderBy: { queuePosition: 'asc' },
      });
      expect(list.map((r) => r.queuePosition)).toEqual([1, 2, 3]);
      expect(list.map((r) => r.studentId)).toEqual([a.id, b.id, c.id]);
    });

    it('renumbers active rows 1..N and parks non-active rows in a negative slot', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const c = await createStudent('c');
      // Cancelled occupies a positive slot; without parking it, the unique
      // (bookId, queuePosition) constraint would block compaction of the
      // active rows. After reorderQueue, active rows get 1..2 and cancelled
      // sits at a negative slot (its exact value is an internal detail).
      await makeReservation(a.id, 10, ReservationStatus.cancelled);
      await makeReservation(b.id, 20);
      await makeReservation(c.id, 30);

      await reservationService.reorderQueue(BOOK_ID);

      const cancelled = await prisma.reservation.findFirst({
        where: { studentId: a.id },
      });
      expect(cancelled!.status).toBe(ReservationStatus.cancelled);
      expect(cancelled!.queuePosition).toBeLessThan(0);

      const list = await prisma.reservation.findMany({
        where: {
          bookId: BOOK_ID,
          status: { in: [ReservationStatus.waiting, ReservationStatus.notified] },
        },
        orderBy: { queuePosition: 'asc' },
      });
      expect(list.map((r) => r.queuePosition)).toEqual([1, 2]);
      expect(list.map((r) => r.studentId)).toEqual([b.id, c.id]);
    });
  });

  describe('cancelReservation', () => {
    it('cancels a waiting reservation owned by the student and reorders the queue', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const r1 = await makeReservation(a.id, 1);
      await makeReservation(b.id, 2);

      await reservationService.cancelReservation(r1.id, a.id);

      const cancelled = await prisma.reservation.findUnique({ where: { id: r1.id } });
      expect(cancelled!.status).toBe(ReservationStatus.cancelled);

      // After reorder, b should now be at position 1.
      const refreshedB = await prisma.reservation.findFirst({
        where: { studentId: b.id },
      });
      expect(refreshedB!.queuePosition).toBe(1);
    });

    it('throws when reservation does not exist', async () => {
      await expect(
        reservationService.cancelReservation(
          '00000000-0000-0000-0000-000000000000',
          'nope',
        ),
      ).rejects.toThrow('예약을 찾을 수 없습니다');
    });

    it('throws when student does not own the reservation', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      const r = await makeReservation(a.id, 1);

      await expect(
        reservationService.cancelReservation(r.id, b.id),
      ).rejects.toThrow('권한이 없습니다');
    });

    it('throws when the reservation is not in a cancellable status', async () => {
      const a = await createStudent('a');
      const r = await makeReservation(a.id, 1, ReservationStatus.expired);

      await expect(
        reservationService.cancelReservation(r.id, a.id),
      ).rejects.toThrow('대기 중이거나 알림받은 예약만');
    });
  });

  describe('getQueuePosition', () => {
    it('returns position metadata for an active reservation', async () => {
      const a = await createStudent('a');
      const b = await createStudent('b');
      await makeReservation(a.id, 1);
      await makeReservation(b.id, 2);

      const pos = await reservationService.getQueuePosition(b.id, BOOK_ID);
      expect(pos).not.toBeNull();
      expect(pos!.position).toBe(2);
      expect(pos!.totalInQueue).toBe(2);
      expect(pos!.status).toBe(ReservationStatus.waiting);
    });

    it('returns null when the student has no active reservation for the book', async () => {
      const a = await createStudent('a');
      // Cancelled reservations should not count.
      await makeReservation(a.id, 1, ReservationStatus.cancelled);

      const pos = await reservationService.getQueuePosition(a.id, BOOK_ID);
      expect(pos).toBeNull();
    });
  });
});
