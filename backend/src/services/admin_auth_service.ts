import { PrismaClient, Administrator } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { generateAdminToken } from '../utils/jwt';

const prisma = new PrismaClient();

export interface AdminLoginResult {
  token: string;
  admin: {
    id: string;
    username: string;
    email: string;
    fullName: string;
    role: 'admin' | 'super_admin';
  };
}

export class AdminAuthError extends Error {
  constructor(public code: 'invalid_credentials', message: string) {
    super(message);
    this.name = 'AdminAuthError';
  }
}

export class AdminAuthService {
  async findByUsername(username: string): Promise<Administrator | null> {
    return prisma.administrator.findUnique({ where: { username } });
  }

  async login(username: string, password: string): Promise<AdminLoginResult> {
    const admin = await this.findByUsername(username);
    if (!admin) {
      throw new AdminAuthError(
        'invalid_credentials',
        '사용자명 또는 비밀번호가 올바르지 않습니다.',
      );
    }

    const passwordMatches = await bcrypt.compare(password, admin.passwordHash);
    if (!passwordMatches) {
      throw new AdminAuthError(
        'invalid_credentials',
        '사용자명 또는 비밀번호가 올바르지 않습니다.',
      );
    }

    await prisma.administrator.update({
      where: { id: admin.id },
      data: { lastLoginAt: new Date() },
    });

    const token = generateAdminToken(
      admin.id,
      admin.username,
      admin.email,
      admin.role,
    );

    return {
      token,
      admin: {
        id: admin.id,
        username: admin.username,
        email: admin.email,
        fullName: admin.fullName,
        role: admin.role,
      },
    };
  }
}

export const adminAuthService = new AdminAuthService();
