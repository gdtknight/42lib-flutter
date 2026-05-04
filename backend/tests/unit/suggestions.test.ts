// T163: BookSuggestion endpoints — submit, list, dedupe, period validation

import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient, PeriodStatus } from '@prisma/client';
import { generateStudentToken } from '../../src/utils/jwt';

const prisma = new PrismaClient();

const STUDENT = {
  fortytwoUserId: 980100,
  username: 'sgst_student',
  email: 'sgst_student@42.fr',
  fullName: '추천 테스트 학생',
};

async function cleanup(): Promise<void> {
  await prisma.bookSuggestion.deleteMany({
    where: {
      OR: [
        { suggestedTitle: { startsWith: '[T163]' } },
        { student: { username: STUDENT.username } },
      ],
    },
  });
  await prisma.collectionPeriod.deleteMany({
    where: { name: { startsWith: '[T163]' } },
  });
  await prisma.student.deleteMany({ where: { username: STUDENT.username } });
}

describe('Suggestions endpoints (T163)', () => {
  let studentId: string;
  let token: string;

  beforeAll(async () => {
    await cleanup();
    const student = await prisma.student.create({ data: STUDENT });
    studentId = student.id;
    token = generateStudentToken(
      student.id,
      student.username,
      student.email,
      student.fortytwoUserId,
    );
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  beforeEach(async () => {
    await prisma.bookSuggestion.deleteMany({ where: { studentId } });
    await prisma.collectionPeriod.deleteMany({
      where: { name: { startsWith: '[T163]' } },
    });
  });

  describe('POST /api/v1/suggestions', () => {
    it('rejects anonymous request with 401', async () => {
      await request(app)
        .post('/api/v1/suggestions')
        .send({ suggestedTitle: 'X', suggestedAuthor: 'Y' })
        .expect(401);
    });

    it('returns 400 when active period absent', async () => {
      const res = await request(app)
        .post('/api/v1/suggestions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          suggestedTitle: '[T163] 도서',
          suggestedAuthor: '저자',
        })
        .expect(400);
      expect(res.body.error).toBe('no_active_period');
    });

    it('creates suggestion within active period', async () => {
      await prisma.collectionPeriod.create({
        data: {
          name: '[T163] 2024 Q1',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-03-31'),
          status: PeriodStatus.active,
        },
      });

      const res = await request(app)
        .post('/api/v1/suggestions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          suggestedTitle: '[T163] Effective TypeScript',
          suggestedAuthor: 'Dan Vanderkam',
          reason: 'TS 깊은 이해를 위한 책',
        })
        .expect(201);

      expect(res.body.success).toBe(true);
      expect(res.body.data.suggestedTitle).toBe('[T163] Effective TypeScript');
      expect(res.body.data.status).toBe('submitted');
    });

    it('returns 400 when payload missing required fields', async () => {
      await prisma.collectionPeriod.create({
        data: {
          name: '[T163] 2024 Q1 v',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-03-31'),
          status: PeriodStatus.active,
        },
      });
      await request(app)
        .post('/api/v1/suggestions')
        .set('Authorization', `Bearer ${token}`)
        .send({ suggestedTitle: '' })
        .expect(400);
    });

    it('rejects duplicate title+author for same student in same period', async () => {
      await prisma.collectionPeriod.create({
        data: {
          name: '[T163] 2024 Q1 dedupe',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-03-31'),
          status: PeriodStatus.active,
        },
      });

      await request(app)
        .post('/api/v1/suggestions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          suggestedTitle: '[T163] Dup Book',
          suggestedAuthor: 'Author',
        })
        .expect(201);

      const res = await request(app)
        .post('/api/v1/suggestions')
        .set('Authorization', `Bearer ${token}`)
        .send({
          suggestedTitle: '[T163] Dup Book',
          suggestedAuthor: 'Author',
        })
        .expect(409);
      expect(res.body.error).toBe('duplicate_suggestion');
    });
  });

  describe('GET /api/v1/suggestions/my', () => {
    it('returns empty array for new student', async () => {
      const res = await request(app)
        .get('/api/v1/suggestions/my')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);
      expect(res.body.data).toEqual([]);
    });

    it('returns student own suggestions in reverse chronological order', async () => {
      const period = await prisma.collectionPeriod.create({
        data: {
          name: '[T163] my list period',
          startDate: new Date('2024-01-01'),
          endDate: new Date('2024-03-31'),
          status: PeriodStatus.active,
        },
      });

      await prisma.bookSuggestion.create({
        data: {
          studentId,
          collectionPeriodId: period.id,
          suggestedTitle: '[T163] First',
          suggestedAuthor: 'A',
          submittedAt: new Date('2024-02-01'),
        },
      });
      await prisma.bookSuggestion.create({
        data: {
          studentId,
          collectionPeriodId: period.id,
          suggestedTitle: '[T163] Second',
          suggestedAuthor: 'B',
          submittedAt: new Date('2024-02-10'),
        },
      });

      const res = await request(app)
        .get('/api/v1/suggestions/my')
        .set('Authorization', `Bearer ${token}`)
        .expect(200);

      expect(res.body.data).toHaveLength(2);
      expect(res.body.data[0].suggestedTitle).toBe('[T163] Second'); // newest first
      expect(res.body.data[1].suggestedTitle).toBe('[T163] First');
    });
  });
});
