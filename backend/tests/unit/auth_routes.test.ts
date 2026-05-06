// Phase 11 — HTTP route tests for /api/v1/auth/*.
// Mocks axios to avoid real 42 API calls; uses real Prisma for student
// upsert verification.

import axios from 'axios';
import request from 'supertest';
import { PrismaClient } from '@prisma/client';
import { generateStudentToken } from '../../src/utils/jwt';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

const prisma = new PrismaClient();
const PREFIX = 'auth_route_';

async function cleanup(): Promise<void> {
  await prisma.student.deleteMany({
    where: { username: { startsWith: PREFIX } },
  });
}

beforeAll(async () => {
  process.env.FORTYTWO_CLIENT_ID = 'test-client';
  process.env.FORTYTWO_CLIENT_SECRET = 'test-secret';
  process.env.FORTYTWO_REDIRECT_URI = 'http://localhost:3000/api/v1/auth/42/callback';
  await cleanup();
});

afterAll(async () => {
  await cleanup();
  await prisma.$disconnect();
});

beforeEach(() => {
  jest.clearAllMocks();
});

afterEach(async () => {
  await cleanup();
});

// Lazy require so the mocked axios is in place when auth_42_service loads.
function getApp() {
  const { app } = require('../../src/server');
  return app;
}

describe('GET /api/v1/auth/42/login', () => {
  it('redirects to the 42 authorization URL', async () => {
    const res = await request(getApp()).get('/api/v1/auth/42/login').expect(302);

    expect(res.headers.location).toMatch(
      /^https:\/\/api\.intra\.42\.fr\/oauth\/authorize\?/,
    );
    expect(res.headers.location).toContain('client_id=test-client');
    expect(res.headers.location).toContain('response_type=code');
  });
});

describe('GET /api/v1/auth/42/callback', () => {
  it('returns 400 when code is missing', async () => {
    const res = await request(getApp())
      .get('/api/v1/auth/42/callback')
      .expect(400);

    expect(res.body.error).toBe('Bad Request');
    expect(res.body.message).toContain('인증 코드');
    expect(mockedAxios.post).not.toHaveBeenCalled();
  });

  it('returns JWT + student profile on successful OAuth handshake', async () => {
    mockedAxios.post.mockResolvedValueOnce({
      data: {
        access_token: 'at-1',
        token_type: 'bearer',
        expires_in: 7200,
        refresh_token: 'rt-1',
        scope: 'public',
        created_at: 1700000000,
      },
    });
    mockedAxios.get.mockResolvedValueOnce({
      data: {
        id: 940100,
        login: `${PREFIX}happy`,
        email: `${PREFIX}happy@42.fr`,
        displayname: 'Happy Path',
        usual_full_name: '해피 패스',
      },
    });

    const res = await request(getApp())
      .get('/api/v1/auth/42/callback')
      .query({ code: 'auth-code-abc' })
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.token).toBeTruthy();
    expect(res.body.data.student.username).toBe(`${PREFIX}happy`);
    expect(res.body.data.student.fortytwoUserId).toBe(940100);
    expect(res.body.data.expiresIn).toBeTruthy();

    // Student should have been persisted.
    const persisted = await prisma.student.findUnique({
      where: { fortytwoUserId: 940100 },
    });
    expect(persisted).not.toBeNull();
  });

  it('returns 500 when 42 token exchange fails', async () => {
    mockedAxios.post.mockRejectedValueOnce({
      response: { data: { error: 'invalid_grant' } },
      message: 'Request failed',
    });

    const res = await request(getApp())
      .get('/api/v1/auth/42/callback')
      .query({ code: 'bad-code' })
      .expect(500);

    expect(res.body.error).toBe('Internal Server Error');
    expect(res.body.message).toContain('42 OAuth 인증');
  });
});

describe('GET /api/v1/auth/me', () => {
  it('returns 401 when Authorization header is missing', async () => {
    const res = await request(getApp()).get('/api/v1/auth/me').expect(401);
    expect(res.body.message).toContain('인증 토큰');
  });

  it('returns 401 when Authorization header is malformed', async () => {
    const res = await request(getApp())
      .get('/api/v1/auth/me')
      .set('Authorization', 'NotBearer token')
      .expect(401);
    expect(res.body.message).toContain('인증 토큰');
  });

  it('returns 401 when token signature is invalid', async () => {
    const res = await request(getApp())
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer not.a.valid.jwt')
      .expect(401);
    expect(res.body.message).toContain('유효하지 않은 토큰');
  });

  it('returns the JWT payload when token is valid', async () => {
    const token = generateStudentToken(
      'stu-1',
      `${PREFIX}me`,
      `${PREFIX}me@42.fr`,
      940200,
    );

    const res = await request(getApp())
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`)
      .expect(200);

    expect(res.body.success).toBe(true);
    expect(res.body.data.userId).toBe('stu-1');
    expect(res.body.data.username).toBe(`${PREFIX}me`);
    expect(res.body.data.fortytwoUserId).toBe(940200);
    expect(res.body.data.role).toBe('student');
  });
});
