// T112, T113: Loan Request Routes
// POST /loan-requests - Create loan request
// GET /loan-requests/my - Get student's loan requests
// Reference: data-model.md Entity 3 (LoanRequest)

import express, { Response } from 'express';
import { loanRequestService } from '../services/loan_request_service';
import { authenticateStudent, AuthenticatedRequest } from '../middleware/auth';
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

export default router;
