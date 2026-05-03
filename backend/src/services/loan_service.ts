// T146/T147/T148: Loan Service — admin approval workflow + return + overdue detection
// Reference: data-model.md Entity 5 (Loan)

import {
  PrismaClient,
  LoanRequestStatus,
  LoanStatus,
  ReservationStatus,
} from '@prisma/client';
import { logger } from '../utils/logger';
import { reservationService } from './reservation_service';

const prisma = new PrismaClient();

export class LoanError extends Error {
  constructor(
    public code:
      | 'request_not_found'
      | 'not_pending'
      | 'book_unavailable'
      | 'loan_not_found'
      | 'not_active',
    message: string,
  ) {
    super(message);
    this.name = 'LoanError';
  }
}

const DEFAULT_LOAN_DAYS = 14;

export class LoanService {
  /**
   * T141/T146: Approve a pending loan request and create a Loan.
   * Decrements book.availableQuantity within a transaction.
   */
  async approveLoanRequest(
    loanRequestId: string,
    adminId: string,
    options: { dueInDays?: number; notes?: string } = {},
  ) {
    const dueInDays = options.dueInDays ?? DEFAULT_LOAN_DAYS;
    const dueDate = new Date(Date.now() + dueInDays * 24 * 60 * 60 * 1000);

    return prisma.$transaction(async (tx) => {
      const request = await tx.loanRequest.findUnique({
        where: { id: loanRequestId },
        include: { book: true },
      });
      if (!request) {
        throw new LoanError('request_not_found', '대출 요청을 찾을 수 없습니다.');
      }
      if (request.status !== LoanRequestStatus.pending) {
        throw new LoanError(
          'not_pending',
          `대기 중인 요청만 승인 가능합니다. 현재 상태: ${request.status}`,
        );
      }
      if (request.book.availableQuantity <= 0) {
        throw new LoanError('book_unavailable', '도서가 가용하지 않습니다.');
      }

      // Decrement availability
      await tx.book.update({
        where: { id: request.bookId },
        data: { availableQuantity: { decrement: 1 } },
      });

      // Create active loan
      const loan = await tx.loan.create({
        data: {
          studentId: request.studentId,
          bookId: request.bookId,
          loanRequestId: request.id,
          status: LoanStatus.active,
          dueDate,
          approvedBy: adminId,
          notes: options.notes,
        },
        include: { book: true, student: { select: { id: true, username: true, fullName: true } } },
      });

      // Update request status
      await tx.loanRequest.update({
        where: { id: loanRequestId },
        data: {
          status: LoanRequestStatus.approved,
          reviewedAt: new Date(),
          reviewedBy: adminId,
        },
      });

      logger.info('Loan request approved', { loanRequestId, loanId: loan.id, adminId });
      return loan;
    });
  }

  /**
   * T142: Reject a pending loan request with reason.
   */
  async rejectLoanRequest(
    loanRequestId: string,
    adminId: string,
    rejectionReason: string,
  ) {
    const request = await prisma.loanRequest.findUnique({
      where: { id: loanRequestId },
    });
    if (!request) {
      throw new LoanError('request_not_found', '대출 요청을 찾을 수 없습니다.');
    }
    if (request.status !== LoanRequestStatus.pending) {
      throw new LoanError(
        'not_pending',
        `대기 중인 요청만 반려 가능합니다. 현재 상태: ${request.status}`,
      );
    }

    const updated = await prisma.loanRequest.update({
      where: { id: loanRequestId },
      data: {
        status: LoanRequestStatus.rejected,
        reviewedAt: new Date(),
        reviewedBy: adminId,
        rejectionReason,
      },
    });
    logger.info('Loan request rejected', { loanRequestId, adminId });
    return updated;
  }

  /**
   * T144/T148: Return a loan and notify next reservation in queue.
   */
  async returnLoan(loanId: string) {
    const loan = await prisma.$transaction(async (tx) => {
      const existing = await tx.loan.findUnique({
        where: { id: loanId },
        include: { book: true },
      });
      if (!existing) {
        throw new LoanError('loan_not_found', '대출을 찾을 수 없습니다.');
      }
      if (existing.status !== LoanStatus.active && existing.status !== LoanStatus.overdue) {
        throw new LoanError('not_active', '진행 중인 대출만 반납 처리할 수 있습니다.');
      }

      const updated = await tx.loan.update({
        where: { id: loanId },
        data: {
          status: LoanStatus.returned,
          returnedDate: new Date(),
        },
        include: { book: true, student: { select: { id: true, username: true, fullName: true } } },
      });

      await tx.book.update({
        where: { id: existing.bookId },
        data: { availableQuantity: { increment: 1 } },
      });

      return updated;
    });

    // Notification happens outside the transaction (best effort).
    try {
      await reservationService.notifyNextInQueue(loan.bookId);
    } catch (err: any) {
      logger.warn('Failed to notify next in queue', {
        loanId: loan.id,
        bookId: loan.bookId,
        error: err.message,
      });
    }

    logger.info('Loan returned', { loanId });
    return loan;
  }

  /**
   * T143: List loans (admin view), optionally filtered by status.
   */
  async getLoans(filters: {
    status?: LoanStatus;
    studentId?: string;
    bookId?: string;
    limit?: number;
    page?: number;
  } = {}) {
    const limit = filters.limit ?? 50;
    const page = filters.page ?? 1;
    const where: any = {};
    if (filters.status) where.status = filters.status;
    if (filters.studentId) where.studentId = filters.studentId;
    if (filters.bookId) where.bookId = filters.bookId;

    const [loans, total] = await Promise.all([
      prisma.loan.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { checkoutDate: 'desc' },
        include: {
          book: { select: { id: true, title: true, author: true } },
          student: { select: { id: true, username: true, fullName: true } },
        },
      }),
      prisma.loan.count({ where }),
    ]);

    return { data: loans, total, page, limit };
  }

  /**
   * T145: Loan history with date filters.
   */
  async getHistory(filters: { from?: Date; to?: Date; limit?: number; page?: number } = {}) {
    const limit = filters.limit ?? 50;
    const page = filters.page ?? 1;
    const where: any = {};
    if (filters.from || filters.to) {
      where.checkoutDate = {};
      if (filters.from) where.checkoutDate.gte = filters.from;
      if (filters.to) where.checkoutDate.lte = filters.to;
    }

    const [loans, total] = await Promise.all([
      prisma.loan.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: { checkoutDate: 'desc' },
        include: {
          book: { select: { id: true, title: true } },
          student: { select: { id: true, username: true } },
        },
      }),
      prisma.loan.count({ where }),
    ]);

    return { data: loans, total, page, limit };
  }

  /**
   * T147: Mark active loans past their dueDate as overdue.
   * Returns number of rows updated.
   */
  async detectOverdue(now: Date = new Date()): Promise<number> {
    const result = await prisma.loan.updateMany({
      where: {
        status: LoanStatus.active,
        dueDate: { lt: now },
      },
      data: { status: LoanStatus.overdue },
    });

    if (result.count > 0) {
      logger.info('Marked loans as overdue', { count: result.count });
    }
    return result.count;
  }
}

export const loanService = new LoanService();
