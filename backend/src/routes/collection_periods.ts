// US3: CollectionPeriod routes
// GET /api/v1/collection-periods/active — public

import express, { Request, Response, NextFunction } from 'express';
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

export default router;
