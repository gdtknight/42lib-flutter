// T114, T115: Loan Request Service
// Handles loan request creation, validation, and reservation queue management
// Reference: data-model.md Entity 3 (LoanRequest) and Entity 4 (Reservation)

import { PrismaClient, LoanRequestStatus, ReservationStatus } from '@prisma/client';
import { logger } from '../utils/logger';

const prisma = new PrismaClient();

export class LoanRequestService {
  /**
   * T112: Create a new loan request
   * BR-201: Status starts as 'pending' on creation
   * BR-203: If book unavailable, create Reservation instead
   * BR-205: Administrators see pending requests in dashboard
   */
  async createLoanRequest(studentId: string, bookId: string, notes?: string) {
    try {
      // Validate student exists
      const student = await prisma.student.findUnique({
        where: { id: studentId },
      });

      if (!student) {
        throw new Error('학생을 찾을 수 없습니다.');
      }

      // Validate book exists
      const book = await prisma.book.findUnique({
        where: { id: bookId },
      });

      if (!book) {
        throw new Error('책을 찾을 수 없습니다.');
      }

      // Check if student already has pending request for this book (VR-205)
      const existingRequest = await prisma.loanRequest.findFirst({
        where: {
          studentId,
          bookId,
          status: LoanRequestStatus.pending,
        },
      });

      if (existingRequest) {
        throw new Error('이미 해당 책에 대한 대출 신청이 있습니다.');
      }

      // Create loan request
      const loanRequest = await prisma.loanRequest.create({
        data: {
          studentId,
          bookId,
          status: LoanRequestStatus.pending,
          notes,
        },
        include: {
          student: {
            select: {
              id: true,
              username: true,
              fullName: true,
            },
          },
          book: {
            select: {
              id: true,
              title: true,
              author: true,
              availableQuantity: true,
            },
          },
        },
      });

      // T115: If book unavailable, automatically create reservation
      if (book.availableQuantity === 0) {
        await this.createReservation(studentId, bookId);
        logger.info('Book unavailable, created reservation', {
          loanRequestId: loanRequest.id,
          studentId,
          bookId,
        });
      }

      logger.info('Loan request created', {
        loanRequestId: loanRequest.id,
        studentId,
        bookId,
        bookAvailable: book.availableQuantity > 0,
      });

      return loanRequest;
    } catch (error: any) {
      logger.error('Failed to create loan request', {
        error: error.message,
        studentId,
        bookId,
      });
      throw error;
    }
  }

  /**
   * T114: Create reservation when book is unavailable
   * BR-301: Reservations managed as FIFO queue per book
   */
  private async createReservation(studentId: string, bookId: string) {
    try {
      // Get next queue position for this book
      const lastReservation = await prisma.reservation.findFirst({
        where: {
          bookId,
          status: { in: [ReservationStatus.waiting, ReservationStatus.notified] },
        },
        orderBy: { queuePosition: 'desc' },
      });

      const nextPosition = (lastReservation?.queuePosition || 0) + 1;

      // Create reservation
      const reservation = await prisma.reservation.create({
        data: {
          studentId,
          bookId,
          queuePosition: nextPosition,
          status: ReservationStatus.waiting,
        },
      });

      logger.info('Reservation created', {
        reservationId: reservation.id,
        studentId,
        bookId,
        queuePosition: nextPosition,
      });

      return reservation;
    } catch (error: any) {
      logger.error('Failed to create reservation', {
        error: error.message,
        studentId,
        bookId,
      });
      throw error;
    }
  }

  /**
   * T113: Get loan requests for a specific student
   */
  async getStudentLoanRequests(studentId: string) {
    try {
      const loanRequests = await prisma.loanRequest.findMany({
        where: { studentId },
        include: {
          book: {
            select: {
              id: true,
              title: true,
              author: true,
              coverImageUrl: true,
              availableQuantity: true,
            },
          },
        },
        orderBy: { requestDate: 'desc' },
      });

      logger.info('Retrieved student loan requests', {
        studentId,
        count: loanRequests.length,
      });

      return loanRequests;
    } catch (error: any) {
      logger.error('Failed to get student loan requests', {
        error: error.message,
        studentId,
      });
      throw error;
    }
  }

  /**
   * Get all pending loan requests (for admin)
   */
  async getPendingLoanRequests() {
    try {
      const loanRequests = await prisma.loanRequest.findMany({
        where: { status: LoanRequestStatus.pending },
        include: {
          student: {
            select: {
              id: true,
              username: true,
              fullName: true,
              email: true,
            },
          },
          book: {
            select: {
              id: true,
              title: true,
              author: true,
              availableQuantity: true,
            },
          },
        },
        orderBy: { requestDate: 'asc' },
      });

      logger.info('Retrieved pending loan requests', { count: loanRequests.length });

      return loanRequests;
    } catch (error: any) {
      logger.error('Failed to get pending loan requests', { error: error.message });
      throw error;
    }
  }

  /**
   * Get student's active reservations with queue positions
   */
  async getStudentReservations(studentId: string) {
    try {
      const reservations = await prisma.reservation.findMany({
        where: {
          studentId,
          status: { in: [ReservationStatus.waiting, ReservationStatus.notified] },
        },
        include: {
          book: {
            select: {
              id: true,
              title: true,
              author: true,
              coverImageUrl: true,
            },
          },
        },
        orderBy: { queuePosition: 'asc' },
      });

      logger.info('Retrieved student reservations', {
        studentId,
        count: reservations.length,
      });

      return reservations;
    } catch (error: any) {
      logger.error('Failed to get student reservations', {
        error: error.message,
        studentId,
      });
      throw error;
    }
  }

  /**
   * Cancel a loan request
   * BR-204: Student can cancel only pending requests
   */
  async cancelLoanRequest(loanRequestId: string, studentId: string) {
    try {
      const loanRequest = await prisma.loanRequest.findUnique({
        where: { id: loanRequestId },
      });

      if (!loanRequest) {
        throw new Error('대출 신청을 찾을 수 없습니다.');
      }

      if (loanRequest.studentId !== studentId) {
        throw new Error('권한이 없습니다.');
      }

      if (loanRequest.status !== LoanRequestStatus.pending) {
        throw new Error('대기 중인 신청만 취소할 수 있습니다.');
      }

      const updatedRequest = await prisma.loanRequest.update({
        where: { id: loanRequestId },
        data: { status: LoanRequestStatus.cancelled },
      });

      logger.info('Loan request cancelled', { loanRequestId, studentId });

      return updatedRequest;
    } catch (error: any) {
      logger.error('Failed to cancel loan request', {
        error: error.message,
        loanRequestId,
        studentId,
      });
      throw error;
    }
  }
}

export const loanRequestService = new LoanRequestService();
