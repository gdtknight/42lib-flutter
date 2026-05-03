// T112, T113: Loan Request Routes
// POST /loan-requests - Create loan request
// GET /loan-requests/my - Get student's loan requests
// Reference: data-model.md Entity 3 (LoanRequest)

import express, { Response } from 'express';
import { loanRequestService } from '../services/loan_request_service';
import { loanService, LoanError } from '../services/loan_service';
import {
  authenticateStudent,
  authenticateAdmin,
  AuthenticatedRequest,
} from '../middleware/auth';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * T112: POST /loan-requests
 * Create a new loan request
 * Requires student authentication
 */
router.post('/', authenticateStudent, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { bookId, notes } = req.body;
    const studentId = req.user!.userId;

    if (!bookId) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '책 ID가 필요합니다.',
      });
    }

    const loanRequest = await loanRequestService.createLoanRequest(studentId, bookId, notes);

    res.status(201).json({
      success: true,
      message: '대출 신청이 완료되었습니다.',
      data: loanRequest,
    });
  } catch (error: any) {
    logger.error('Failed to create loan request', {
      error: error.message,
      studentId: req.user?.userId,
    });

    res.status(400).json({
      error: 'Bad Request',
      message: error.message || '대출 신청에 실패했습니다.',
    });
  }
});

/**
 * T113: GET /loan-requests/my
 * Get current student's loan requests
 * Requires student authentication
 */
router.get('/my', authenticateStudent, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const studentId = req.user!.userId;

    const loanRequests = await loanRequestService.getStudentLoanRequests(studentId);

    res.json({
      success: true,
      data: loanRequests,
    });
  } catch (error: any) {
    logger.error('Failed to get student loan requests', {
      error: error.message,
      studentId: req.user?.userId,
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: '대출 신청 목록을 불러오는데 실패했습니다.',
    });
  }
});

/**
 * GET /loan-requests/my/reservations
 * Get current student's active reservations with queue positions
 * Requires student authentication
 */
router.get('/my/reservations', authenticateStudent, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const studentId = req.user!.userId;

    const reservations = await loanRequestService.getStudentReservations(studentId);

    res.json({
      success: true,
      data: reservations,
    });
  } catch (error: any) {
    logger.error('Failed to get student reservations', {
      error: error.message,
      studentId: req.user?.userId,
    });

    res.status(500).json({
      error: 'Internal Server Error',
      message: '예약 목록을 불러오는데 실패했습니다.',
    });
  }
});

/**
 * DELETE /loan-requests/:id
 * Cancel a loan request
 * Requires student authentication
 */
router.delete('/:id', authenticateStudent, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const { id } = req.params;
    const studentId = req.user!.userId;

    const cancelledRequest = await loanRequestService.cancelLoanRequest(id, studentId);

    res.json({
      success: true,
      message: '대출 신청이 취소되었습니다.',
      data: cancelledRequest,
    });
  } catch (error: any) {
    logger.error('Failed to cancel loan request', {
      error: error.message,
      loanRequestId: req.params.id,
      studentId: req.user?.userId,
    });

    res.status(400).json({
      error: 'Bad Request',
      message: error.message || '대출 신청 취소에 실패했습니다.',
    });
  }
});

/**
 * T140: GET /api/v1/loan-requests
 * List pending loan requests (admin only).
 */
router.get('/', authenticateAdmin, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const data = await loanRequestService.getPendingLoanRequests();
    res.json({ success: true, data });
  } catch (error: any) {
    logger.error('Failed to list loan requests for admin', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: '대출 요청 목록을 불러오지 못했습니다.',
    });
  }
});

/**
 * T141: PUT /api/v1/loan-requests/:id/approve
 * Approve a pending loan request — creates an active Loan.
 */
router.put('/:id/approve', authenticateAdmin, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const adminId = req.user!.userId;
    const { dueInDays, notes } = req.body ?? {};
    const loan = await loanService.approveLoanRequest(req.params.id, adminId, {
      dueInDays: typeof dueInDays === 'number' ? dueInDays : undefined,
      notes,
    });
    res.json({ success: true, data: loan });
  } catch (error: any) {
    if (error instanceof LoanError) {
      const status =
        error.code === 'request_not_found' ? 404
          : error.code === 'book_unavailable' ? 409
            : 400;
      return res.status(status).json({ error: error.code, message: error.message });
    }
    logger.error('Failed to approve loan request', { error: error.message });
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

/**
 * T142: PUT /api/v1/loan-requests/:id/reject
 * Reject a pending loan request with required reason.
 */
router.put('/:id/reject', authenticateAdmin, async (req: AuthenticatedRequest, res: Response) => {
  try {
    const adminId = req.user!.userId;
    const reason = (req.body?.rejectionReason as string | undefined)?.trim();
    if (!reason) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '반려 사유는 필수입니다.',
      });
    }
    const updated = await loanService.rejectLoanRequest(req.params.id, adminId, reason);
    res.json({ success: true, data: updated });
  } catch (error: any) {
    if (error instanceof LoanError) {
      const status = error.code === 'request_not_found' ? 404 : 400;
      return res.status(status).json({ error: error.code, message: error.message });
    }
    logger.error('Failed to reject loan request', { error: error.message });
    res.status(500).json({ error: 'Internal Server Error', message: error.message });
  }
});

export default router;
