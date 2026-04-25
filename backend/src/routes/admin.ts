import { Router, Request, Response, NextFunction } from 'express';
import { z } from 'zod';
import { adminAuthService, AdminAuthError } from '../services/admin_auth_service';

const router = Router();

const loginSchema = z.object({
  username: z.string().min(1, 'username is required'),
  password: z.string().min(1, 'password is required'),
});

/**
 * POST /api/v1/admin/login
 * Authenticate admin with username/password and return JWT.
 */
router.post('/login', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const parsed = loginSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({
        error: 'Bad Request',
        message: parsed.error.issues[0]?.message ?? 'Invalid payload',
      });
    }

    const { username, password } = parsed.data;
    const result = await adminAuthService.login(username, password);
    return res.json(result);
  } catch (error) {
    if (error instanceof AdminAuthError) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: error.message,
      });
    }
    return next(error);
  }
});

export default router;
