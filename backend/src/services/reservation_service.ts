// T114: Reservation Queue Service
// Manages FIFO reservation queue with notifications and expirations
// Reference: data-model.md Entity 4 (Reservation)

import { PrismaClient, ReservationStatus } from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export class ReservationService {
  /**
   * BR-302: Notify first waiting reservation when book is returned
   * BR-303: 24-hour expiration window for notified reservations
   */
  async notifyNextInQueue(bookId: string) {
    try {
      // Find first waiting reservation for this book
      const nextReservation = await prisma.reservation.findFirst({
        where: {
          bookId,
          status: ReservationStatus.waiting,
        },
        orderBy: { queuePosition: 'asc' },
        include: {
          student: true,
          book: true,
        },
      });

      if (!nextReservation) {
        logger.info('No waiting reservations for book', { bookId });
        return null;
      }

      // Update reservation status to notified
      const now = new Date();
      const expiresAt = new Date(now.getTime() + 24 * 60 * 60 * 1000); // 24 hours from now

      const updatedReservation = await prisma.reservation.update({
        where: { id: nextReservation.id },
        data: {
          status: ReservationStatus.notified,
          notifiedAt: now,
          expiresAt,
        },
        include: {
          student: true,
          book: true,
        },
      });

      logger.info('Notified next reservation in queue', {
        reservationId: updatedReservation.id,
        studentId: nextReservation.studentId,
        bookId,
        expiresAt,
      });

      // TODO: Send push notification to student (Phase 2)
      // this.sendReservationNotification(updatedReservation);

      return updatedReservation;
    } catch (error: any) {
      logger.error('Failed to notify next reservation', {
        error: error.message,
        bookId,
      });
      throw error;
    }
  }

  /**
   * BR-303: Handle expired reservations
   * If notified student doesn't complete loan within 24h, move to next in queue
   */
  async handleExpiredReservations() {
    try {
      const now = new Date();

      // Find expired reservations
      const expiredReservations = await prisma.reservation.findMany({
        where: {
          status: ReservationStatus.notified,
          expiresAt: { lte: now },
        },
        include: {
          book: true,
        },
      });

      for (const reservation of expiredReservations) {
        // Mark as expired
        await prisma.reservation.update({
          where: { id: reservation.id },
          data: { status: ReservationStatus.expired },
        });

        logger.info('Reservation expired', {
          reservationId: reservation.id,
          studentId: reservation.studentId,
          bookId: reservation.bookId,
        });

        // Notify next in queue
        await this.notifyNextInQueue(reservation.bookId);
      }

      return expiredReservations;
    } catch (error: any) {
      logger.error('Failed to handle expired reservations', { error: error.message });
      throw error;
    }
  }

  /**
   * BR-305: Reorder queue when reservation is cancelled or expired
   */
  async reorderQueue(bookId: string) {
    try {
      const reservations = await prisma.reservation.findMany({
        where: {
          bookId,
          status: { in: [ReservationStatus.waiting, ReservationStatus.notified] },
        },
        orderBy: { queuePosition: 'asc' },
      });

      // Update queue positions to be sequential (1, 2, 3, ...)
      for (let i = 0; i < reservations.length; i++) {
        if (reservations[i].queuePosition !== i + 1) {
          await prisma.reservation.update({
            where: { id: reservations[i].id },
            data: { queuePosition: i + 1 },
          });
        }
      }

      logger.info('Reservation queue reordered', {
        bookId,
        count: reservations.length,
      });

      return reservations;
    } catch (error: any) {
      logger.error('Failed to reorder reservation queue', {
        error: error.message,
        bookId,
      });
      throw error;
    }
  }

  /**
   * Cancel a reservation
   * BR-305: Reorder queue after cancellation
   */
  async cancelReservation(reservationId: string, studentId: string) {
    try {
      const reservation = await prisma.reservation.findUnique({
        where: { id: reservationId },
      });

      if (!reservation) {
        throw new Error('예약을 찾을 수 없습니다.');
      }

      if (reservation.studentId !== studentId) {
        throw new Error('권한이 없습니다.');
      }

      if (![ReservationStatus.waiting, ReservationStatus.notified].includes(reservation.status as any)) {
        throw new Error('대기 중이거나 알림받은 예약만 취소할 수 있습니다.');
      }

      // Cancel reservation
      await prisma.reservation.update({
        where: { id: reservationId },
        data: { status: ReservationStatus.cancelled },
      });

      // Reorder queue
      await this.reorderQueue(reservation.bookId);

      logger.info('Reservation cancelled', { reservationId, studentId });

      return reservation;
    } catch (error: any) {
      logger.error('Failed to cancel reservation', {
        error: error.message,
        reservationId,
        studentId,
      });
      throw error;
    }
  }

  /**
   * Get student's queue position for a book
   * BR-306: Students see their queue position in profile
   */
  async getQueuePosition(studentId: string, bookId: string) {
    try {
      const reservation = await prisma.reservation.findFirst({
        where: {
          studentId,
          bookId,
          status: { in: [ReservationStatus.waiting, ReservationStatus.notified] },
        },
      });

      if (!reservation) {
        return null;
      }

      // Count total reservations ahead in queue
      const totalInQueue = await prisma.reservation.count({
        where: {
          bookId,
          status: { in: [ReservationStatus.waiting, ReservationStatus.notified] },
        },
      });

      return {
        position: reservation.queuePosition,
        totalInQueue,
        status: reservation.status,
        notifiedAt: reservation.notifiedAt,
        expiresAt: reservation.expiresAt,
      };
    } catch (error: any) {
      logger.error('Failed to get queue position', {
        error: error.message,
        studentId,
        bookId,
      });
      throw error;
    }
  }
}

export const reservationService = new ReservationService();
