import { PrismaClient, Book, Prisma } from '@prisma/client';

const prisma = new PrismaClient();

export interface BookFilters {
  title?: string;
  author?: string;
  category?: string;
  isbn?: string;
}

export interface PaginationOptions {
  page: number;
  limit: number;
  sortBy?: string;
  sortOrder?: 'asc' | 'desc';
}

export class BookService {
  /**
   * Get all books with pagination and optional filters
   */
  async getBooks(
    filters: BookFilters = {},
    options: PaginationOptions = { page: 1, limit: 20 }
  ): Promise<{ data: Book[]; total: number; page: number; limit: number }> {
    const { page, limit, sortBy = 'createdAt', sortOrder = 'desc' } = options;
    const skip = (page - 1) * limit;

    // Build where clause
    const where: Prisma.BookWhereInput = {};

    if (filters.title) {
      where.title = {
        contains: filters.title,
        mode: 'insensitive',
      };
    }

    if (filters.author) {
      where.author = {
        contains: filters.author,
        mode: 'insensitive',
      };
    }

    if (filters.category) {
      where.category = filters.category;
    }

    if (filters.isbn) {
      where.isbn = filters.isbn;
    }

    // Execute queries in parallel
    const [books, total] = await Promise.all([
      prisma.book.findMany({
        where,
        skip,
        take: limit,
        orderBy: {
          [sortBy]: sortOrder,
        },
      }),
      prisma.book.count({ where }),
    ]);

    return {
      data: books,
      total,
      page,
      limit,
    };
  }

  /**
   * Get a single book by ID
   */
  async getBookById(id: string): Promise<Book | null> {
    return prisma.book.findUnique({
      where: { id },
    });
  }

  /**
   * Get all distinct categories
   */
  async getCategories(): Promise<string[]> {
    const result = await prisma.book.findMany({
      select: {
        category: true,
      },
      distinct: ['category'],
      orderBy: {
        category: 'asc',
      },
    });

    return result.map((book) => book.category);
  }

  /**
   * Create a new book
   */
  async createBook(data: Prisma.BookCreateInput): Promise<Book> {
    return prisma.book.create({
      data,
    });
  }

  /**
   * Update a book
   */
  async updateBook(id: string, data: Prisma.BookUpdateInput): Promise<Book> {
    return prisma.book.update({
      where: { id },
      data,
    });
  }

  /**
   * Delete a book (soft delete by marking as inactive)
   */
  async deleteBook(id: string): Promise<Book> {
    // For now, hard delete - can be changed to soft delete later
    return prisma.book.delete({
      where: { id },
    });
  }

  /**
   * Check if ISBN already exists
   */
  async isIsbnUnique(isbn: string, excludeId?: string): Promise<boolean> {
    const where: Prisma.BookWhereInput = { isbn };
    
    if (excludeId) {
      where.id = { not: excludeId };
    }

    const count = await prisma.book.count({ where });
    return count === 0;
  }

  /**
   * Update book availability (when loan is created/returned)
   */
  async updateAvailability(id: string, delta: number): Promise<Book> {
    const book = await this.getBookById(id);
    
    if (!book) {
      throw new Error('Book not found');
    }

    const newAvailableQuantity = book.availableQuantity + delta;

    if (newAvailableQuantity < 0 || newAvailableQuantity > book.quantity) {
      throw new Error('Invalid availability update');
    }

    return this.updateBook(id, {
      availableQuantity: newAvailableQuantity,
    });
  }
}

export const bookService = new BookService();
