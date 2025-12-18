import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

export interface BookQueryParams {
  page?: number;
  limit?: number;
  search?: string;
  category?: string;
  availableOnly?: boolean;
}

export class BookService {
  /**
   * 도서 목록 조회 (페이지네이션, 검색, 필터)
   */
  static async getBooks(params: BookQueryParams) {
    const {
      page = 1,
      limit = 20,
      search,
      category,
      availableOnly = false,
    } = params;

    const skip = (page - 1) * limit;

    // 검색 및 필터 조건 구성
    const where: any = {};

    if (search) {
      where.OR = [
        { title: { contains: search, mode: 'insensitive' } },
        { author: { contains: search, mode: 'insensitive' } },
      ];
    }

    if (category) {
      where.category = category;
    }

    if (availableOnly) {
      where.availableQuantity = { gt: 0 };
    }

    // 총 개수 및 데이터 조회
    const [total, books] = await Promise.all([
      prisma.book.count({ where }),
      prisma.book.findMany({
        where,
        skip,
        take: limit,
        orderBy: { createdAt: 'desc' },
        select: {
          id: true,
          title: true,
          author: true,
          isbn: true,
          category: true,
          description: true,
          publicationYear: true,
          quantity: true,
          availableQuantity: true,
          coverImageUrl: true,
        },
      }),
    ]);

    return {
      books,
      pagination: {
        page,
        limit,
        total,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * 도서 상세 조회
   */
  static async getBookById(bookId: string) {
    const book = await prisma.book.findUnique({
      where: { id: bookId },
      include: {
        loanRequests: {
          where: { status: 'pending' },
          take: 5,
          orderBy: { requestDate: 'desc' },
        },
        reservations: {
          where: { status: 'waiting' },
          orderBy: { queuePosition: 'asc' },
        },
      },
    });

    if (!book) {
      throw new Error('도서를 찾을 수 없습니다');
    }

    return book;
  }

  /**
   * 카테고리 목록 조회
   */
  static async getCategories() {
    const categories = await prisma.book.findMany({
      select: { category: true },
      distinct: ['category'],
      orderBy: { category: 'asc' },
    });

    return categories.map((c) => c.category);
  }
}
