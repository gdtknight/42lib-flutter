// T110: JWT Token Generation for Students and Admins
import jwt from 'jsonwebtoken';

const JWT_SECRET = process.env.JWT_SECRET || 'dev-secret-change-in-production';
const JWT_EXPIRES_IN = process.env.JWT_EXPIRES_IN || '7d';

export interface TokenPayload {
  userId: string;
  username: string;
  email: string;
  role: 'student' | 'admin' | 'super_admin';
  fortytwoUserId?: number; // For students authenticated via 42 OAuth
}

export const generateToken = (payload: TokenPayload): string => {
  return jwt.sign(payload, JWT_SECRET, { expiresIn: JWT_EXPIRES_IN } as jwt.SignOptions);
};

export const verifyToken = (token: string): TokenPayload => {
  return jwt.verify(token, JWT_SECRET) as TokenPayload;
};

export const decodeToken = (token: string): TokenPayload | null => {
  try {
    return jwt.decode(token) as TokenPayload;
  } catch {
    return null;
  }
};

// T110: Generate JWT token for authenticated student
export const generateStudentToken = (
  studentId: string,
  username: string,
  email: string,
  fortytwoUserId: number
): string => {
  return generateToken({
    userId: studentId,
    username,
    email,
    role: 'student',
    fortytwoUserId,
  });
};

// Generate JWT token for authenticated admin
export const generateAdminToken = (
  adminId: string,
  username: string,
  email: string,
  role: 'admin' | 'super_admin'
): string => {
  return generateToken({
    userId: adminId,
    username,
    email,
    role,
  });
};
