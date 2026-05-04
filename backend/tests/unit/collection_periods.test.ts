// T164: GET /api/v1/collection-periods/active

import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient, PeriodStatus } from '@prisma/client';

const prisma = new PrismaClient();
const NAME_PREFIX = '[T164]';

async function cleanup(): Promise<void> {
  await prisma.bookSuggestion.deleteMany({
    where: { collectionPeriod: { name: { startsWith: NAME_PREFIX } } },
  });
  await prisma.collectionPeriod.deleteMany({
    where: { name: { startsWith: NAME_PREFIX } },
  });
}

describe('GET /api/v1/collection-periods/active (T164)', () => {
  beforeAll(async () => {
    await cleanup();
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  it('returns 404 when no period is active', async () => {
    // Ensure no active period exists by setting any pre-existing active to closed.
    await prisma.collectionPeriod.updateMany({
      where: { status: PeriodStatus.active },
      data: { status: PeriodStatus.closed },
    });

    const res = await request(app)
      .get('/api/v1/collection-periods/active')
      .expect(404);
    expect(res.body.error).toBe('no_active_period');
  });

  it('returns active period', async () => {
    const period = await prisma.collectionPeriod.create({
      data: {
        name: `${NAME_PREFIX} 2024 Spring`,
        startDate: new Date('2024-03-01'),
        endDate: new Date('2024-05-31'),
        status: PeriodStatus.active,
      },
    });

    const res = await request(app)
      .get('/api/v1/collection-periods/active')
      .expect(200);
    expect(res.body.success).toBe(true);
    expect(res.body.data.id).toBe(period.id);
    expect(res.body.data.name).toBe(`${NAME_PREFIX} 2024 Spring`);
  });
});
