// T230: Swagger UI middleware that exposes the OpenAPI contract at /api/docs.
// The OpenAPI spec is the single source of truth and lives in
// specs/001-library-management/contracts/openapi.yaml.

import path from 'path';
import { Router } from 'express';
import swaggerUi from 'swagger-ui-express';
import YAML from 'yamljs';
import { logger } from './utils/logger';

// Resolution order:
//   1. OPENAPI_SPEC_PATH env override (deploy-friendly)
//   2. /specs/... (Docker volume mount — see docker-compose.yml)
//   3. ../../specs/... (repo layout when running outside Docker)
function resolveSpecPath(): string {
  const candidates = [
    process.env.OPENAPI_SPEC_PATH,
    '/specs/001-library-management/contracts/openapi.yaml',
    path.resolve(
      __dirname,
      '..',
      '..',
      'specs',
      '001-library-management',
      'contracts',
      'openapi.yaml',
    ),
  ].filter((p): p is string => Boolean(p));

  for (const candidate of candidates) {
    try {
      // Throws if not readable. fs.statSync would also work — keeping the
      // require here cheap by deferring to YAML.load below.
      require('fs').accessSync(candidate);
      return candidate;
    } catch {
      // try next
    }
  }
  return candidates[candidates.length - 1];
}

const SPEC_PATH = resolveSpecPath();

export function buildSwaggerRouter(): Router {
  const router = Router();
  let document: object | null = null;

  try {
    document = YAML.load(SPEC_PATH);
  } catch (error: any) {
    logger.error('Failed to load OpenAPI spec for /api/docs', {
      path: SPEC_PATH,
      error: error.message,
    });
  }

  if (!document) {
    router.get('/', (_req, res) => {
      res.status(503).json({
        error: 'openapi_unavailable',
        message: 'OpenAPI 스펙을 로드하지 못했습니다.',
      });
    });
    return router;
  }

  // Raw spec for tooling (Postman / contract tests / codegen).
  router.get('/openapi.json', (_req, res) => res.json(document));

  router.use(
    '/',
    swaggerUi.serve,
    swaggerUi.setup(document, {
      customSiteTitle: '42 Library API',
      swaggerOptions: { displayRequestDuration: true },
    }),
  );

  return router;
}
