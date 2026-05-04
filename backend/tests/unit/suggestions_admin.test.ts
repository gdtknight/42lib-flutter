// T182/T183: Admin suggestion review endpoints + grouping logic.

import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient, PeriodStatus, SuggestionStatus } from '@prisma/client';
import * as bcrypt from 'bcrypt';
import { generateAdminToken, generateStudentToken } from '../../src/utils/jwt';

const prisma = new PrismaClient();

const ADMIN = {
  username: 'sgst_admin',
  password: 'sgst-admin-pass',
  email: 'sgst_admin@42lib.kr',
  fullName: '추천 관리자',
};

const PREFIX = '[SGST-ADMIN]';

async function cleanup(): Promise<void> {
  await prisma.bookSuggestion.deleteMany({
    where: {
      OR: [
        { suggestedTitle: { startsWith: PREFIX } },
        { collectionPeriod: { name: { startsWith: PREFIX } } },
      ],
    },
  });
  await prisma.collectionPeriod.deleteMany({ where: { name: { startsWith: PREFIX } } });
  await prisma.student.deleteMany({ where: { username: { startsWith: 'sgst_st_' } } });
  await prisma.administrator.deleteMany({ where: { username: ADMIN.username } });
}

describe('Admin suggestion endpoints (T182/T183)', () => {
  let adminId: string;
  let adminToken: string;
  let activePeriodId: string;
  let studentA: { id: string; token: string };
  let studentB: { id: string; token: string };

  beforeAll(async () => {
    await cleanup();
    const passwordHash = await bcrypt.hash(ADMIN.password, 10);
    const admin = await prisma.administrator.create({
      data: {
        username: ADMIN.username,
        email: ADMIN.email,
        fullName: ADMIN.fullName,
        passwordHash,
        role: 'admin',
      },
    });
    adminId = admin.id;
    adminToken = generateAdminToken(admin.id, admin.username, admin.email, admin.role);

    const period = await prisma.collectionPeriod.create({
      data: {
        name: `${PREFIX} 2024 Q1`,
        startDate: new Date('2024-01-01'),
        endDate: new Date('2024-03-31'),
        status: PeriodStatus.active,
      },
    });
    activePeriodId = period.id;

    const a = await prisma.student.create({
      data: {
        fortytwoUserId: 970201,
        username: 'sgst_st_a',
        email: 'sgst_st_a@42.fr',
        fullName: '학생 A',
      },
    });
    const b = await prisma.student.create({
      data: {
        fortytwoUserId: 970202,
        username: 'sgst_st_b',
        email: 'sgst_st_b@42.fr',
        fullName: '학생 B',
      },
    });
    studentA = {
      id: a.id,
      token: generateStudentToken(a.id, a.username, a.email, a.fortytwoUserId),
    };
    studentB = {
      id: b.id,
      token: generateStudentToken(b.id, b.username, b.email, b.fortytwoUserId),
    };
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  describe('GET /api/v1/suggestions (admin grouped, T184)', () => {
    beforeAll(async () => {
      // Two students suggesting the same book → grouped count=2
      await prisma.bookSuggestion.create({
        data: {
          studentId: studentA.id,
          collectionPeriodId: activePeriodId,
          suggestedTitle: `${PREFIX} Effective TS`,
          suggestedAuthor: 'Vanderkam',
          status: SuggestionStatus.submitted,
        },
      });
      await prisma.bookSuggestion.create({
        data: {
          studentId: studentB.id,
          collectionPeriodId: activePeriodId,
          suggestedTitle: `${PREFIX} Effective TS`,
          suggestedAuthor: 'Vanderkam',
          status: SuggestionStatus.submitted,
        },
      });
      // Single different book → group count=1
      await prisma.bookSuggestion.create({
        data: {
          studentId: studentA.id,
          collectionPeriodId: activePeriodId,
          suggestedTitle: `${PREFIX} Solo Book`,
          suggestedAuthor: 'Lonely',
          status: SuggestionStatus.submitted,
        },
      });
    });

    it('rejects student token (admin only)', async () => {
      await request(app)
        .get('/api/v1/suggestions')
        .set('Authorization', `Bearer ${studentA.token}`)
        .expect(403);
    });

    it('returns grouped list ordered by requesterCount desc', async () => {
      const res = await request(app)
        .get('/api/v1/suggestions')
        .set('Authorization', `Bearer ${adminToken}`)
        .expect(200);

      expect(Array.isArray(res.body.data)).toBe(true);
      const effective = res.body.data.find(
        (g: any) => g.suggestedTitle === `${PREFIX} Effective TS`,
      );
      const solo = res.body.data.find(
        (g: any) => g.suggestedTitle === `${PREFIX} Solo Book`,
      );

      expect(effective).toBeDefined();
      expect(effective.requesterCount).toBe(2);
      expect(effective.items).toHaveLength(2);
      expect(solo.requesterCount).toBe(1);
      expect(res.body.data[0].requesterCount).toBeGreaterThanOrEqual(
        res.body.data[res.body.data.length - 1].requesterCount,
      );
    });
  });

  describe('PUT /api/v1/suggestions/:id/status (T185)', () => {
    let targetId: string;

    beforeEach(async () => {
      const s = await prisma.bookSuggestion.create({
        data: {
          studentId: studentA.id,
          collectionPeriodId: activePeriodId,
          suggestedTitle: `${PREFIX} Review Target`,
          suggestedAuthor: 'Author',
          status: SuggestionStatus.submitted,
        },
      });
      targetId = s.id;
    });

    afterEach(async () => {
      await prisma.bookSuggestion.deleteMany({ where: { id: targetId } });
    });

    it('approves a suggestion with admin notes', async () => {
      const res = await request(app)
        .put(`/api/v1/suggestions/${targetId}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'approved', adminNotes: '구입 예정' })
        .expect(200);

      expect(res.body.data.status).toBe('approved');
      expect(res.body.data.adminNotes).toBe('구입 예정');
      expect(res.body.data.reviewedBy).toBe(adminId);
    });

    it('rejects a suggestion', async () => {
      const res = await request(app)
        .put(`/api/v1/suggestions/${targetId}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'rejected', adminNotes: '예산 한도 초과' })
        .expect(200);
      expect(res.body.data.status).toBe('rejected');
    });

    it('returns 404 for non-existent suggestion', async () => {
      await request(app)
        .put('/api/v1/suggestions/00000000-0000-0000-0000-000000000000/status')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'approved' })
        .expect(404);
    });

    it('returns 400 for invalid status', async () => {
      await request(app)
        .put(`/api/v1/suggestions/${targetId}/status`)
        .set('Authorization', `Bearer ${adminToken}`)
        .send({ status: 'pirate' })
        .expect(400);
    });

    it('rejects student token', async () => {
      await request(app)
        .put(`/api/v1/suggestions/${targetId}/status`)
        .set('Authorization', `Bearer ${studentA.token}`)
        .send({ status: 'approved' })
        .expect(403);
    });
  });

  describe('POST /api/v1/collection-periods (T186/T188)', () => {
    afterEach(async () => {
      await prisma.collectionPeriod.deleteMany({
        where: { name: { startsWith: `${PREFIX} new ` } },
      });
    });

    it('creates upcoming period without affecting active', async () => {
      const res = await request(app)
        .post('/api/v1/collection-periods')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: `${PREFIX} new upcoming`,
          startDate: '2024-04-01T00:00:00.000Z',
          endDate: '2024-06-30T00:00:00.000Z',
          status: 'upcoming',
        })
        .expect(201);
      expect(res.body.data.status).toBe('upcoming');

      const stillActive = await prisma.collectionPeriod.findUnique({
        where: { id: activePeriodId },
      });
      expect(stillActive?.status).toBe('active');
    });

    it('creating new active period archives the existing active one', async () => {
      const res = await request(app)
        .post('/api/v1/collection-periods')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: `${PREFIX} new active`,
          startDate: '2024-04-01T00:00:00.000Z',
          endDate: '2024-06-30T00:00:00.000Z',
          status: 'active',
        })
        .expect(201);
      expect(res.body.data.status).toBe('active');

      const oldActive = await prisma.collectionPeriod.findUnique({
        where: { id: activePeriodId },
      });
      expect(oldActive?.status).toBe('closed');

      // Restore for subsequent tests
      await prisma.collectionPeriod.update({
        where: { id: activePeriodId },
        data: { status: PeriodStatus.active },
      });
    });

    it('returns 400 when endDate <= startDate', async () => {
      await request(app)
        .post('/api/v1/collection-periods')
        .set('Authorization', `Bearer ${adminToken}`)
        .send({
          name: `${PREFIX} new bad`,
          startDate: '2024-05-01T00:00:00.000Z',
          endDate: '2024-04-01T00:00:00.000Z',
        })
        .expect(400);
    });

    it('rejects student token', async () => {
      await request(app)
        .post('/api/v1/collection-periods')
        .set('Authorization', `Bearer ${studentA.token}`)
        .send({
          name: `${PREFIX} new student`,
          startDate: '2024-04-01T00:00:00.000Z',
          endDate: '2024-06-30T00:00:00.000Z',
        })
        .expect(403);
    });
  });
});
