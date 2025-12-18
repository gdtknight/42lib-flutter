import { PrismaClient } from '@prisma/client';
import * as bcrypt from 'bcrypt';

const prisma = new PrismaClient();

async function main() {
  console.log('🌱 Seeding database...');

  // 관리자 계정 생성
  const adminPassword = await bcrypt.hash('admin123', 10);
  const admin = await prisma.administrator.upsert({
    where: { username: 'admin' },
    update: {},
    create: {
      username: 'admin',
      email: 'admin@42lib.kr',
      fullName: '시스템 관리자',
      passwordHash: adminPassword,
      role: 'super_admin',
    },
  });
  console.log('✅ Admin created:', admin.username);

  // 테스트 학생 (42 사용자)
  const student = await prisma.student.upsert({
    where: { fortytwoUserId: 12345 },
    update: {},
    create: {
      fortytwoUserId: 12345,
      username: 'testuser',
      email: 'testuser@student.42.fr',
      fullName: '테스트 사용자',
    },
  });
  console.log('✅ Student created:', student.username);

  // 샘플 도서 생성
  const books = await Promise.all([
    prisma.book.create({
      data: {
        title: '클린 코드',
        author: '로버트 C. 마틴',
        isbn: '9788966260959',
        category: 'Programming',
        description: '애자일 소프트웨어 장인 정신',
        publicationYear: 2013,
        quantity: 3,
        availableQuantity: 3,
      },
    }),
    prisma.book.create({
      data: {
        title: '리팩토링',
        author: '마틴 파울러',
        isbn: '9791162242742',
        category: 'Programming',
        description: '코드 구조를 체계적으로 개선하여 효율적인 리팩터링 구현하기',
        publicationYear: 2020,
        quantity: 2,
        availableQuantity: 2,
      },
    }),
    prisma.book.create({
      data: {
        title: '엘레강트 오브젝트',
        author: '예고르 부가옌코',
        category: 'Programming',
        description: '객체지향 프로그래밍의 새로운 관점',
        publicationYear: 2018,
        quantity: 2,
        availableQuantity: 2,
      },
    }),
  ]);
  console.log(`✅ ${books.length} books created`);

  // 도서 추천 수집 기간
  const period = await prisma.collectionPeriod.create({
    data: {
      name: '2025 Q1 도서 추천',
      startDate: new Date('2025-01-01'),
      endDate: new Date('2025-03-31'),
      status: 'upcoming',
    },
  });
  console.log('✅ Collection period created:', period.name);

  console.log('🎉 Seeding completed!');
}

main()
  .catch((e) => {
    console.error('❌ Seeding error:', e);
    process.exit(1);
  })
  .finally(async () => {
    await prisma.$disconnect();
  });
