import express, { Express } from 'express';
import cors from 'cors';
import helmet from 'helmet';
import rateLimit from 'express-rate-limit';
import { PrismaClient } from '@prisma/client';
import { logger } from './utils/logger';
import { errorHandler } from './middleware/error_handler';
import bookRoutes from './routes/books';

const app: Express = express();
const prisma = new PrismaClient();
const PORT = process.env.PORT || 3000;

// 미들웨어 설정
app.use(helmet()); // 보안 헤더
app.use(cors()); // CORS 허용
app.use(express.json()); // JSON 파싱
app.use(express.urlencoded({ extended: true }));

// Rate Limiting
const limiter = rateLimit({
  windowMs: parseInt(process.env.RATE_LIMIT_WINDOW_MS || '60000'),
  max: parseInt(process.env.RATE_LIMIT_MAX_REQUESTS || '100'),
  message: '요청이 너무 많습니다. 잠시 후 다시 시도해주세요.',
});
app.use('/api', limiter);

// Health Check
app.get('/health', (req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// API 라우트
app.use('/api/books', bookRoutes);

app.get('/api/v1', (req, res) => {
  res.json({ message: '42lib API v1', status: 'ready' });
});

// 에러 핸들링 미들웨어 (마지막에 추가)
app.use(errorHandler);

// 서버 시작
app.listen(PORT, () => {
  logger.info(`🚀 Server running on port ${PORT}`);
  logger.info(`📚 42lib Backend API v1`);
  logger.info(`🔗 Health: http://localhost:${PORT}/health`);
  logger.info(`🔗 API: http://localhost:${PORT}/api/v1`);
});

// Graceful shutdown
process.on('SIGTERM', async () => {
  logger.info('SIGTERM received, closing server...');
  await prisma.$disconnect();
  process.exit(0);
});

export { app, prisma };
