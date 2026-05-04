// US3: Suggestion routes
// POST /api/v1/suggestions      — submit (student)
// GET  /api/v1/suggestions/my   — student's own list

import express, { Response, NextFunction } from 'express';
import { z } from 'zod';
import { SuggestionStatus } from '@prisma/client';
import {
  authenticateStudent,
  authenticateAdmin,
  AuthenticatedRequest,
} from '../middleware/auth';
import { suggestionService, SuggestionError } from '../services/suggestion_service';

const router = express.Router();

const submitSchema = z.object({
  suggestedTitle: z.string().min(1).max(500),
  suggestedAuthor: z.string().min(1).max(200),
  reason: z.string().max(1000).optional(),
});

router.post(
  '/',
  authenticateStudent,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const parsed = submitSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'Bad Request',
        message: parsed.error.issues[0]?.message ?? 'Invalid payload',
      });
    }

    try {
      const studentId = req.user!.userId;
      const suggestion = await suggestionService.createSuggestion(
        studentId,
        parsed.data,
      );
      return res.status(201).json({ success: true, data: suggestion });
    } catch (error) {
      if (error instanceof SuggestionError) {
        const status = error.code === 'duplicate_suggestion' ? 409 : 400;
        return res
          .status(status)
          .json({ error: error.code, message: error.message });
      }
      return next(error);
    }
  },
);

router.get(
  '/my',
  authenticateStudent,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const studentId = req.user!.userId;
      const data = await suggestionService.getStudentSuggestions(studentId);
      return res.json({ success: true, data });
    } catch (error) {
      return next(error);
    }
  },
);

/**
 * T184: Admin grouped list — same title+author within a period collapsed.
 * Optional ?periodId= filter (default = active period).
 */
router.get(
  '/',
  authenticateAdmin,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    try {
      const periodId = req.query.periodId as string | undefined;
      const data = await suggestionService.getGroupedSuggestions({ periodId });
      return res.json({ success: true, data });
    } catch (error) {
      return next(error);
    }
  },
);

const reviewSchema = z.object({
  status: z.nativeEnum(SuggestionStatus),
  adminNotes: z.string().max(1000).optional(),
});

/**
 * T185: Admin reviews a suggestion — sets status + optional adminNotes.
 */
router.put(
  '/:id/status',
  authenticateAdmin,
  async (req: AuthenticatedRequest, res: Response, next: NextFunction) => {
    const parsed = reviewSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'Bad Request',
        message: parsed.error.issues[0]?.message ?? 'Invalid payload',
      });
    }

    try {
      const adminId = req.user!.userId;
      const updated = await suggestionService.reviewSuggestion(
        req.params.id,
        adminId,
        parsed.data,
      );
      return res.json({ success: true, data: updated });
    } catch (error) {
      if (error instanceof SuggestionError) {
        const status = error.code === 'suggestion_not_found' ? 404 : 400;
        return res
          .status(status)
          .json({ error: error.code, message: error.message });
      }
      return next(error);
    }
  },
);

export default router;
