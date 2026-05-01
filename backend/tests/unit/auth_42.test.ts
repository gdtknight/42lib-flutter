// T099: 42 OAuth Service tests
// Verifies lazy credential validation: construction succeeds without env vars,
// but OAuth methods throw when credentials are missing.

describe('Auth42Service (T099)', () => {
  const originalEnv = { ...process.env };

  afterEach(() => {
    // Restore env between tests so module re-imports see expected state.
    process.env = { ...originalEnv };
    jest.resetModules();
  });

  it('constructs without throwing when env vars are missing (lazy mode)', () => {
    delete process.env.FORTYTWO_CLIENT_ID;
    delete process.env.FORTYTWO_CLIENT_SECRET;
    delete process.env.FORTYTWO_REDIRECT_URI;

    jest.resetModules();
    const { Auth42Service } = require('../../src/services/auth_42_service');
    expect(() => new Auth42Service()).not.toThrow();
  });

  it('constructs without throwing when credentials are configured', () => {
    process.env.FORTYTWO_CLIENT_ID = 'test-client-id';
    process.env.FORTYTWO_CLIENT_SECRET = 'test-client-secret';
    process.env.FORTYTWO_REDIRECT_URI = 'http://localhost:8080/auth/callback';

    jest.resetModules();
    const { Auth42Service } = require('../../src/services/auth_42_service');
    expect(() => new Auth42Service()).not.toThrow();
  });

  it('getAuthorizationUrl throws when credentials missing', () => {
    delete process.env.FORTYTWO_CLIENT_ID;
    delete process.env.FORTYTWO_CLIENT_SECRET;
    delete process.env.FORTYTWO_REDIRECT_URI;

    jest.resetModules();
    const { Auth42Service } = require('../../src/services/auth_42_service');
    const service = new Auth42Service();

    expect(() => service.getAuthorizationUrl()).toThrow(
      '42 OAuth configuration missing',
    );
  });

  it('getAuthorizationUrl returns 42 OAuth URL when configured', () => {
    process.env.FORTYTWO_CLIENT_ID = 'test-client';
    process.env.FORTYTWO_CLIENT_SECRET = 'test-secret';
    process.env.FORTYTWO_REDIRECT_URI = 'http://localhost:8080/cb';

    jest.resetModules();
    const { Auth42Service } = require('../../src/services/auth_42_service');
    const service = new Auth42Service();
    const url = service.getAuthorizationUrl('state-xyz');

    expect(url).toContain('https://api.intra.42.fr/oauth/authorize');
    expect(url).toContain('client_id=test-client');
    expect(url).toContain('redirect_uri=http%3A%2F%2Flocalhost%3A8080%2Fcb');
    expect(url).toContain('state=state-xyz');
  });

  it('exchangeCodeForToken rejects when credentials missing', async () => {
    delete process.env.FORTYTWO_CLIENT_ID;
    delete process.env.FORTYTWO_CLIENT_SECRET;
    delete process.env.FORTYTWO_REDIRECT_URI;

    jest.resetModules();
    const { Auth42Service } = require('../../src/services/auth_42_service');
    const service = new Auth42Service();

    await expect(service.exchangeCodeForToken('code')).rejects.toThrow(
      '42 OAuth configuration missing',
    );
  });
});
