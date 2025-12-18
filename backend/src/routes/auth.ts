// T108, T109: 42 OAuth Authentication Routes
// GET /auth/42/login - Initiate OAuth flow
// GET /auth/42/callback - Handle OAuth callback
// Reference: research.md Section 3 (42 API Integration)

import express, { Request, Response } from 'express';
import { auth42Service } from '../services/auth_42_service';
import { generateStudentToken } from '../utils/jwt';
import { logger } from '../utils/logger';

const router = express.Router();

/**
 * T108: GET /auth/42/login
 * Initiates 42 OAuth flow by redirecting to 42 authorization URL
 */
router.get('/42/login', (req: Request, res: Response) => {
  try {
    const state = Math.random().toString(36).substring(7);
    const authUrl = auth42Service.getAuthorizationUrl(state);

    logger.info('Initiating 42 OAuth login', { state });

    // Redirect to 42 OAuth authorization page
    res.redirect(authUrl);
  } catch (error: any) {
    logger.error('Failed to initiate 42 OAuth login', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: '42 OAuth 로그인을 시작할 수 없습니다.',
    });
  }
});

/**
 * T109: GET /auth/42/callback
 * Handles OAuth callback from 42 API
 * Exchanges authorization code for access token
 * Creates or updates student account
 * Returns JWT token for app authentication
 */
router.get('/42/callback', async (req: Request, res: Response) => {
  try {
    const { code, state } = req.query;

    if (!code || typeof code !== 'string') {
      logger.warn('42 OAuth callback missing code');
      return res.status(400).json({
        error: 'Bad Request',
        message: '인증 코드가 누락되었습니다.',
      });
    }

    logger.info('Processing 42 OAuth callback', { code: code.substring(0, 10) + '...' });

    // Complete OAuth flow: exchange code, fetch user, create/update student
    const { student, accessToken, expiresIn } = await auth42Service.authenticateWithCode(code);

    // Generate JWT token for student
    const jwtToken = generateStudentToken(
      student.id,
      student.username,
      student.email,
      student.fortytwoUserId
    );

    logger.info('Successfully authenticated student via 42 OAuth', {
      studentId: student.id,
      username: student.username,
    });

    // Return JWT token to client
    // In production, you might want to redirect to a frontend URL with the token
    res.json({
      success: true,
      message: '로그인 성공',
      data: {
        token: jwtToken,
        student: {
          id: student.id,
          username: student.username,
          email: student.email,
          fullName: student.fullName,
          fortytwoUserId: student.fortytwoUserId,
        },
        expiresIn: process.env.JWT_EXPIRES_IN || '7d',
      },
    });
  } catch (error: any) {
    logger.error('42 OAuth callback failed', { error: error.message });
    res.status(500).json({
      error: 'Internal Server Error',
      message: '42 OAuth 인증에 실패했습니다.',
      details: error.message,
    });
  }
});

/**
 * GET /auth/me
 * Returns current authenticated user information
 * Requires valid JWT token
 */
router.get('/me', async (req: Request, res: Response) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '인증 토큰이 필요합니다.',
      });
    }

    const token = authHeader.substring(7);
    const { verifyToken } = await import('../utils/jwt');
    const payload = verifyToken(token);

    res.json({
      success: true,
      data: {
        userId: payload.userId,
        username: payload.username,
        email: payload.email,
        role: payload.role,
        fortytwoUserId: payload.fortytwoUserId,
      },
    });
  } catch (error: any) {
    logger.error('Failed to get current user', { error: error.message });
    res.status(401).json({
      error: 'Unauthorized',
      message: '유효하지 않은 토큰입니다.',
    });
  }
});

export default router;
