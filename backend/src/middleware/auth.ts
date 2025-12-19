// T111: Student Authentication Middleware
// Validates JWT token and ensures user is authenticated student
// Reference: data-model.md Entity 2 (Student)

import { Request, Response, NextFunction } from 'express';
import { verifyToken, TokenPayload } from '../utils/jwt';
import { logger } from '../utils/logger';

export interface AuthenticatedRequest extends Request {
  user?: TokenPayload;
}

/**
 * Middleware to authenticate student requests
 * Validates JWT token from Authorization header
 */
export const authenticateStudent = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '인증 토큰이 필요합니다.',
      });
    }

    const token = authHeader.substring(7); // Remove 'Bearer ' prefix
    const payload = verifyToken(token);

    if (payload.role !== 'student') {
      return res.status(403).json({
        error: 'Forbidden',
        message: '학생 권한이 필요합니다.',
      });
    }

    req.user = payload;
    next();
  } catch (error: any) {
    logger.error('Student authentication failed', {
      error: error.message,
      path: req.path,
    });

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '토큰이 만료되었습니다. 다시 로그인해주세요.',
      });
    }

    return res.status(401).json({
      error: 'Unauthorized',
      message: '유효하지 않은 토큰입니다.',
    });
  }
};

/**
 * Middleware to authenticate admin requests
 * Validates JWT token and ensures user is admin or super_admin
 */
export const authenticateAdmin = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '인증 토큰이 필요합니다.',
      });
    }

    const token = authHeader.substring(7);
    const payload = verifyToken(token);

    if (payload.role !== 'admin' && payload.role !== 'super_admin') {
      return res.status(403).json({
        error: 'Forbidden',
        message: '관리자 권한이 필요합니다.',
      });
    }

    req.user = payload;
    next();
  } catch (error: any) {
    logger.error('Admin authentication failed', {
      error: error.message,
      path: req.path,
    });

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '토큰이 만료되었습니다. 다시 로그인해주세요.',
      });
    }

    return res.status(401).json({
      error: 'Unauthorized',
      message: '유효하지 않은 토큰입니다.',
    });
  }
};

/**
 * Middleware to authenticate any user (student or admin)
 */
export const authenticate = (
  req: AuthenticatedRequest,
  res: Response,
  next: NextFunction
) => {
  try {
    const authHeader = req.headers.authorization;

    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '인증 토큰이 필요합니다.',
      });
    }

    const token = authHeader.substring(7);
    const payload = verifyToken(token);

    req.user = payload;
    next();
  } catch (error: any) {
    logger.error('Authentication failed', {
      error: error.message,
      path: req.path,
    });

    if (error.name === 'TokenExpiredError') {
      return res.status(401).json({
        error: 'Unauthorized',
        message: '토큰이 만료되었습니다. 다시 로그인해주세요.',
      });
    }

    return res.status(401).json({
      error: 'Unauthorized',
      message: '유효하지 않은 토큰입니다.',
    });
  }
};
