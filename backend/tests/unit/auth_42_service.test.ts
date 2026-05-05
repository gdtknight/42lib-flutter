// Phase 11 hardening — service-level tests for Auth42Service.
// Complements auth_42.test.ts (which covers construction + missing-creds
// guards) by exercising the OAuth network paths (mocked axios) and the
// findOrCreateStudent / authenticateWithCode database branches.

import axios from 'axios';
import { PrismaClient } from '@prisma/client';

jest.mock('axios');
const mockedAxios = axios as jest.Mocked<typeof axios>;

const prisma = new PrismaClient();

const PREFIX = 'auth42_svc_';

async function cleanup(): Promise<void> {
  await prisma.student.deleteMany({
    where: { username: { startsWith: PREFIX } },
  });
}

beforeAll(async () => {
  // Configure 42 OAuth env once before the service module is loaded so the
  // constructor sees real values. Resetting modules per-test would discard
  // the jest.mock('axios') hoisted binding, so we keep one shared instance
  // and clear axios mock state between tests instead.
  process.env.FORTYTWO_CLIENT_ID = 'test-client';
  process.env.FORTYTWO_CLIENT_SECRET = 'test-secret';
  process.env.FORTYTWO_REDIRECT_URI = 'http://localhost:3000/cb';
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

function loadService() {
  const mod = require('../../src/services/auth_42_service');
  return new mod.Auth42Service();
}

describe('Auth42Service.exchangeCodeForToken', () => {
  it('POSTs to 42 token URL and returns the token payload on success', async () => {
    const tokenPayload = {
      access_token: 'at-1',
      token_type: 'bearer',
      expires_in: 7200,
      refresh_token: 'rt-1',
      scope: 'public',
      created_at: 1700000000,
    };
    mockedAxios.post.mockResolvedValueOnce({ data: tokenPayload });

    const svc = loadService();
    const result = await svc.exchangeCodeForToken('the-code');

    expect(result.access_token).toBe('at-1');
    expect(mockedAxios.post).toHaveBeenCalledTimes(1);
    const [url, body, config] = mockedAxios.post.mock.calls[0];
    expect(url).toBe('https://api.intra.42.fr/oauth/token');
    expect(body).toMatchObject({
      grant_type: 'authorization_code',
      client_id: 'test-client',
      client_secret: 'test-secret',
      code: 'the-code',
      redirect_uri: 'http://localhost:3000/cb',
    });
    expect((config as any).headers['Content-Type']).toBe(
      'application/x-www-form-urlencoded',
    );
  });

  it('throws "42 OAuth token exchange failed" on axios error', async () => {
    mockedAxios.post.mockRejectedValueOnce({
      response: { data: { error: 'invalid_grant' } },
      message: 'Request failed with status 400',
    });

    const svc = loadService();
    await expect(svc.exchangeCodeForToken('bad-code')).rejects.toThrow(
      '42 OAuth token exchange failed',
    );
  });
});

describe('Auth42Service.getUserInfo', () => {
  it('GETs /v2/me with bearer token and returns the user payload', async () => {
    const user = {
      id: 12345,
      login: 'tester',
      email: 'tester@42.fr',
      displayname: 'Test User',
      usual_full_name: '테스트 사용자',
    };
    mockedAxios.get.mockResolvedValueOnce({ data: user });

    const svc = loadService();
    const result = await svc.getUserInfo('access-token-xyz');

    expect(result).toEqual(user);
    const [url, config] = mockedAxios.get.mock.calls[0];
    expect(url).toBe('https://api.intra.42.fr/v2/me');
    expect((config as any).headers.Authorization).toBe(
      'Bearer access-token-xyz',
    );
  });

  it('throws "42 API user info fetch failed" on axios error', async () => {
    mockedAxios.get.mockRejectedValueOnce({
      response: { data: { error: 'unauthorized' } },
      message: 'Request failed with status 401',
    });

    const svc = loadService();
    await expect(svc.getUserInfo('expired-token')).rejects.toThrow(
      '42 API user info fetch failed',
    );
  });
});

describe('Auth42Service.findOrCreateStudent', () => {
  function fortyTwoUser(overrides: Partial<{
    id: number;
    login: string;
    email: string;
    displayname: string;
    usual_full_name: string;
  }> = {}) {
    return {
      id: 950100,
      login: `${PREFIX}new`,
      email: `${PREFIX}new@42.fr`,
      displayname: 'Display Name',
      usual_full_name: '실제 이름',
      ...overrides,
    };
  }

  it('creates a new student when no record exists (BR-102)', async () => {
    const svc = loadService();
    const user = fortyTwoUser();
    const before = await prisma.student.count({
      where: { fortytwoUserId: user.id },
    });
    expect(before).toBe(0);

    const student = await svc.findOrCreateStudent(user);

    expect(student.fortytwoUserId).toBe(user.id);
    expect(student.username).toBe(user.login);
    expect(student.email).toBe(user.email);
    expect(student.fullName).toBe('실제 이름');
  });

  it('falls back to displayname when usual_full_name is empty', async () => {
    const svc = loadService();
    const student = await svc.findOrCreateStudent(
      fortyTwoUser({ id: 950101, login: `${PREFIX}fallback`, usual_full_name: '' }),
    );
    expect(student.fullName).toBe('Display Name');
  });

  it('refreshes existing student data on subsequent login (BR-103)', async () => {
    const svc = loadService();
    const fortyTwoId = 950102;
    const initial = await svc.findOrCreateStudent(
      fortyTwoUser({
        id: fortyTwoId,
        login: `${PREFIX}initial`,
        email: `${PREFIX}initial@42.fr`,
        usual_full_name: '초기 이름',
      }),
    );
    const initialLastLogin = initial.lastLoginAt;

    // Wait briefly so lastLoginAt timestamps differ.
    await new Promise((r) => setTimeout(r, 10));

    const updated = await svc.findOrCreateStudent(
      fortyTwoUser({
        id: fortyTwoId,
        login: `${PREFIX}renamed`,
        email: `${PREFIX}renamed@42.fr`,
        usual_full_name: '새 이름',
      }),
    );

    expect(updated.id).toBe(initial.id);
    expect(updated.username).toBe(`${PREFIX}renamed`);
    expect(updated.email).toBe(`${PREFIX}renamed@42.fr`);
    expect(updated.fullName).toBe('새 이름');
    expect(updated.lastLoginAt.getTime()).toBeGreaterThan(
      initialLastLogin.getTime(),
    );
  });
});

describe('Auth42Service.authenticateWithCode (end-to-end)', () => {
  it('chains exchange → getUserInfo → findOrCreateStudent on success', async () => {
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
        id: 950200,
        login: `${PREFIX}e2e`,
        email: `${PREFIX}e2e@42.fr`,
        displayname: 'E2E',
        usual_full_name: '엔드투엔드',
      },
    });

    const svc = loadService();
    const result = await svc.authenticateWithCode('the-code');

    expect(result.accessToken).toBe('at-1');
    expect(result.expiresIn).toBe(7200);
    expect(result.student.username).toBe(`${PREFIX}e2e`);
    expect(result.student.fortytwoUserId).toBe(950200);

    // Verify the student was actually persisted.
    const persisted = await prisma.student.findUnique({
      where: { fortytwoUserId: 950200 },
    });
    expect(persisted).not.toBeNull();
  });

  it('propagates token-exchange error and short-circuits before /v2/me', async () => {
    mockedAxios.post.mockRejectedValueOnce({
      response: { data: { error: 'invalid_grant' } },
    });

    const svc = loadService();
    await expect(svc.authenticateWithCode('bad-code')).rejects.toThrow(
      '42 OAuth token exchange failed',
    );
    expect(mockedAxios.get).not.toHaveBeenCalled();
  });

  it('propagates getUserInfo error after successful token exchange', async () => {
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
    mockedAxios.get.mockRejectedValueOnce({
      response: { data: { error: 'forbidden' } },
    });

    const svc = loadService();
    await expect(svc.authenticateWithCode('the-code')).rejects.toThrow(
      '42 API user info fetch failed',
    );
  });
});
