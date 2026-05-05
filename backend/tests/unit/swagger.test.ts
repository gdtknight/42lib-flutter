// T230: smoke test for /api/docs (Swagger UI) + /api/docs/openapi.json.
// We only assert on stable, content-agnostic shape so the test doesn't have
// to be touched every time the OpenAPI spec evolves.

import request from 'supertest';
import { app } from '../../src/server';

describe('GET /api/docs (T230 — Swagger UI)', () => {
  it('serves Swagger UI HTML at /api/docs/', async () => {
    const res = await request(app).get('/api/docs/').expect(200);
    expect(res.headers['content-type']).toMatch(/html/);
    expect(res.text).toContain('swagger-ui');
  });

  it('serves the raw OpenAPI document at /api/docs/openapi.json', async () => {
    const res = await request(app)
      .get('/api/docs/openapi.json')
      .expect(200)
      .expect('content-type', /json/);

    expect(res.body.openapi).toMatch(/^3\./);
    expect(res.body.info?.title).toContain('42');
    expect(res.body.paths).toBeDefined();
    expect(Object.keys(res.body.paths).length).toBeGreaterThan(0);
  });
});
