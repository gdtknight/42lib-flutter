import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

const TEST_ADMIN = {
  username: 'test_admin_login',
  password: 'secure-password-123',
  email: 'test_admin_login@42lib.kr',
  fullName: '테스트 관리자',
};

describe('POST /api/v1/admin/login (T071)', () => {
  beforeAll(async () => {
    await prisma.administrator.deleteMany({
      where: { username: TEST_ADMIN.username },
    });
    const passwordHash = await bcrypt.hash(TEST_ADMIN.password, 10);
    await prisma.administrator.create({
      data: {
        username: TEST_ADMIN.username,
        email: TEST_ADMIN.email,
        fullName: TEST_ADMIN.fullName,
        passwordHash,
        role: 'admin',
      },
    });
  });

  afterAll(async () => {
    await prisma.administrator.deleteMany({
      where: { username: TEST_ADMIN.username },
    });
    await prisma.$disconnect();
  });

  it('returns 200 with JWT and admin payload on valid credentials', async () => {
    const res = await request(app)
      .post('/api/v1/admin/login')
      .send({ username: TEST_ADMIN.username, password: TEST_ADMIN.password })
      .expect(200);

    expect(res.body.token).toEqual(expect.any(String));
    expect(res.body.admin).toEqual(
      expect.objectContaining({
        username: TEST_ADMIN.username,
        email: TEST_ADMIN.email,
        fullName: TEST_ADMIN.fullName,
        role: 'admin',
      }),
    );
    expect(res.body.admin.id).toEqual(expect.any(String));
  });

  it('returns 401 when password is wrong', async () => {
    const res = await request(app)
      .post('/api/v1/admin/login')
      .send({ username: TEST_ADMIN.username, password: 'wrong' })
      .expect(401);

    expect(res.body.error).toBe('Unauthorized');
  });

  it('returns 401 when username does not exist', async () => {
    const res = await request(app)
      .post('/api/v1/admin/login')
      .send({ username: 'nonexistent', password: 'any' })
      .expect(401);

    expect(res.body.error).toBe('Unauthorized');
  });

  it('returns 400 when required fields are missing', async () => {
    const res = await request(app)
      .post('/api/v1/admin/login')
      .send({ username: '' })
      .expect(400);

    expect(res.body.error).toBe('Bad Request');
  });
});
