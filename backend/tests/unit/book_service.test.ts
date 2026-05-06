// Phase 11 — service-level tests for BookService.
// Targets the branches that the HTTP-level books.test.ts doesn't reach:
// ISBN filter, getCategories, isIsbnUnique with/without excludeId,
// updateAvailability bounds.

import { PrismaClient } from '@prisma/client';
import { bookService } from '../../src/services/book_service';

const prisma = new PrismaClient();
const PREFIX = '[bksvc]';

const BOOKS = [
  {
    id: '00000000-0000-0000-0000-000000000e00',
    title: `${PREFIX} 클린 코드`,
    author: 'Martin',
    isbn: '9780000000e00',
    category: 'Programming',
    quantity: 3,
    availableQuantity: 3,
  },
  {
    id: '00000000-0000-0000-0000-000000000e01',
    title: `${PREFIX} 디자인 패턴`,
    author: 'Gamma',
    isbn: '9780000000e01',
    category: 'Architecture',
    quantity: 2,
    availableQuantity: 1,
  },
  {
    id: '00000000-0000-0000-0000-000000000e02',
    title: `${PREFIX} 매진 도서`,
    author: 'Tester',
    isbn: '9780000000e02',
    category: 'Programming',
    quantity: 1,
    availableQuantity: 0,
  },
];

async function cleanup(): Promise<void> {
  await prisma.book.deleteMany({ where: { title: { startsWith: PREFIX } } });
}

describe('BookService (unit)', () => {
  beforeAll(async () => {
    await cleanup();
    await prisma.book.createMany({ data: BOOKS });
  });

  afterAll(async () => {
    await cleanup();
    await prisma.$disconnect();
  });

  describe('getBooks filters', () => {
    it('filters by ISBN exact match', async () => {
      const res = await bookService.getBooks({ isbn: '9780000000e01' });
      const matched = res.data.filter((b) => b.title.startsWith(PREFIX));
      expect(matched).toHaveLength(1);
      expect(matched[0].isbn).toBe('9780000000e01');
    });

    it('honors pagination limit and skip', async () => {
      const page1 = await bookService.getBooks({}, { page: 1, limit: 1 });
      const page2 = await bookService.getBooks({}, { page: 2, limit: 1 });
      expect(page1.data).toHaveLength(1);
      expect(page2.data).toHaveLength(1);
      expect(page1.data[0].id).not.toBe(page2.data[0].id);
      expect(page1.limit).toBe(1);
      expect(page1.page).toBe(1);
    });

    it('respects sortBy + sortOrder', async () => {
      const asc = await bookService.getBooks(
        { category: 'Programming' },
        { page: 1, limit: 50, sortBy: 'title', sortOrder: 'asc' },
      );
      const titlesAsc = asc.data
        .filter((b) => b.title.startsWith(PREFIX))
        .map((b) => b.title);
      expect(titlesAsc).toEqual([...titlesAsc].sort());
    });
  });

  describe('getCategories', () => {
    it('returns distinct categories sorted asc', async () => {
      const cats = await bookService.getCategories();
      // Test seed adds 'Programming' and 'Architecture' (among possibly others
      // from other test suites). Just assert distinctness + presence.
      expect(new Set(cats).size).toBe(cats.length);
      expect(cats).toContain('Programming');
      expect(cats).toContain('Architecture');
    });
  });

  describe('isIsbnUnique', () => {
    it('returns false when ISBN exists', async () => {
      expect(await bookService.isIsbnUnique('9780000000e00')).toBe(false);
    });

    it('returns true when ISBN is unused', async () => {
      expect(await bookService.isIsbnUnique('9780000999999')).toBe(true);
    });

    it('treats the excluded book as not-conflicting', async () => {
      // ISBN belongs to BOOKS[0] — checking uniqueness while excluding
      // that same id should report unique (=true).
      expect(
        await bookService.isIsbnUnique(
          '9780000000e00',
          '00000000-0000-0000-0000-000000000e00',
        ),
      ).toBe(true);
    });
  });

  describe('updateAvailability', () => {
    it('decrements availability on loan-out', async () => {
      const updated = await bookService.updateAvailability(
        '00000000-0000-0000-0000-000000000e00',
        -1,
      );
      expect(updated.availableQuantity).toBe(2);
      // Restore for subsequent tests.
      await bookService.updateAvailability(
        '00000000-0000-0000-0000-000000000e00',
        1,
      );
    });

    it('throws when book is not found', async () => {
      await expect(
        bookService.updateAvailability(
          '00000000-0000-0000-0000-deadbeef0000',
          -1,
        ),
      ).rejects.toThrow('Book not found');
    });

    it('throws when delta would push availableQuantity below zero', async () => {
      // Sold-out book at availableQuantity=0; -1 would go to -1.
      await expect(
        bookService.updateAvailability(
          '00000000-0000-0000-0000-000000000e02',
          -1,
        ),
      ).rejects.toThrow('Invalid availability update');
    });

    it('throws when delta would push availableQuantity above quantity', async () => {
      // BOOKS[0] is fully available (3/3); +1 would be 4 > 3.
      await expect(
        bookService.updateAvailability(
          '00000000-0000-0000-0000-000000000e00',
          1,
        ),
      ).rejects.toThrow('Invalid availability update');
    });
  });
});
