// T210: Shared Prisma client + query logging.
//
// 모든 서비스/라우트가 이 모듈에서 `prisma`를 import하도록 통일.
// 이전에는 각 서비스가 `new PrismaClient()`를 생성해 9개 connection
// pool이 동시에 살아있었음 (Node.js 단일 프로세스에서 자원 낭비 +
// 테스트에서 connection close 누락 위험).
//
// 로그 설정:
//   - dev / test: query / warn / error / info — 느린 쿼리 추적 + 개발 디버깅
//   - production: warn / error — 시끄러움 방지
//
// 느린 쿼리(>1s)는 별도 logger.warn으로 표면화 (observability rule §7).

import { Prisma, PrismaClient } from '@prisma/client';
import { logger } from './utils/logger';

const isDev = process.env.NODE_ENV !== 'production';

const logLevels: Prisma.LogLevel[] = isDev
  ? ['query', 'warn', 'error', 'info']
  : ['warn', 'error'];

const logEvents: Prisma.LogDefinition[] = logLevels.map((level) => ({
  emit: 'event',
  level,
}));

export const prisma = new PrismaClient({ log: logEvents });

// Forward Prisma events into our structured logger so logs follow the same
// shape as the rest of the app (timestamp / level / service).
prisma.$on('warn' as never, (e: Prisma.LogEvent) => {
  logger.warn('prisma.warn', { message: e.message });
});
prisma.$on('error' as never, (e: Prisma.LogEvent) => {
  logger.error('prisma.error', { message: e.message });
});

if (isDev) {
  // Surface slow queries (≥1s) at WARN; quieter queries at DEBUG.
  // observability rule §3: log at boundaries, include duration.
  prisma.$on('query' as never, (e: Prisma.QueryEvent) => {
    if (e.duration >= 1000) {
      logger.warn('prisma.slow_query', {
        durationMs: e.duration,
        query: e.query,
        params: e.params,
      });
    } else {
      logger.debug('prisma.query', {
        durationMs: e.duration,
        query: e.query,
      });
    }
  });
  prisma.$on('info' as never, (e: Prisma.LogEvent) => {
    logger.debug('prisma.info', { message: e.message });
  });
}
