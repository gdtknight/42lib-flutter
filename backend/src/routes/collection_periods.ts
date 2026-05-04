// CollectionPeriod routes
// GET  /api/v1/collection-periods/active — public
// POST /api/v1/collection-periods         — admin (creates new period; new active archives existing active)

import express, { Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { PeriodStatus } from '@prisma/client';
import {
  authenticateAdmin,
  AuthenticatedRequest,
} from '../middleware/auth';
import { suggestionService } from '../services/suggestion_service';

const router = express.Router();

router.get(
  '/active',
  async (_req: Request, res: Response, next: NextFunction) => {
    try {
      const period = await suggestionService.getActivePeriod();
      if (!period) {
        return res.status(404).json({
          error: 'no_active_period',
          message: '현재 활성 수집 기간이 없습니다.',
        });
      }
      return res.json({ success: true, data: period });
    } catch (error) {
      return next(error);
    }
  },
);

const createPeriodSchema = z.object({
  name: z.string().min(1).max(100),
  startDate: z.string().min(1),
  endDate: z.string().min(1),
  status: z.nativeEnum(PeriodStatus).optional(),
});

router.post(
  '/',
  authenticateAdmin,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const parsed = createPeriodSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'Bad Request',
        message: parsed.error.issues[0]?.message ?? 'Invalid payload',
      });
    }
    const { name, startDate, endDate, status } = parsed.data;
    const start = new Date(startDate);
    const end = new Date(endDate);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '날짜 형식이 올바르지 않습니다.',
      });
    }
    if (end <= start) {
      return res.status(400).json({
        error: 'Bad Request',
        message: '종료일은 시작일보다 이후여야 합니다.',
      });
    }

    try {
      const period = await suggestionService.createPeriod({
        name,
        startDate: start,
        endDate: end,
        status,
      });
      return res.status(201).json({ success: true, data: period });
    } catch (error) {
      return next(error);
    }
  },
);

export default router;
