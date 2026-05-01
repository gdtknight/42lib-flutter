// US5: Admin Loan Routes
// GET    /api/v1/loans              — list loans (admin)
// GET    /api/v1/loans/history      — loan history with date filters
// PUT    /api/v1/loans/:id/return   — mark loan returned, notify queue

import express, { Response, NextFunction } from 'express';
import { LoanStatus } from '@prisma/client';
import { z } from 'zod';
import { authenticateAdmin, AuthenticatedRequest } from '../middleware/auth';
import { loanService, LoanError } from '../services/loan_service';

const router = express.Router();

const statusSchema = z.nativeEnum(LoanStatus).optional();

router.get('/', authenticateAdmin, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const status = statusSchema.parse(req.query.status as string | undefined);
    const result = await loanService.getLoans({
      status,
      studentId: req.query.studentId as string | undefined,
      bookId: req.query.bookId as string | undefined,
      page: req.query.page ? parseInt(req.query.page as string, 10) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : undefined,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
});

router.get('/history', authenticateAdmin, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const result = await loanService.getHistory({
      from: req.query.from ? new Date(req.query.from as string) : undefined,
      to: req.query.to ? new Date(req.query.to as string) : undefined,
      page: req.query.page ? parseInt(req.query.page as string, 10) : undefined,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : undefined,
    });
    res.json(result);
  } catch (e) {
    next(e);
  }
});

router.put('/:id/return', authenticateAdmin, async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
  try {
    const loan = await loanService.returnLoan(req.params.id);
    res.json({ success: true, data: loan });
  } catch (e) {
    if (e instanceof LoanError) {
      const status = e.code === 'loan_not_found' ? 404 : 409;
      return res.status(status).json({ error: e.code, message: e.message });
    }
    next(e);
  }
});

export default router;
