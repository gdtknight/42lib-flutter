import { Router, Request, Response, NextFunction } from 'express';
import { PrismaClient } from '@prisma/client';
import { bookService } from '../services/book_service';
import { validateBookQuery, validateBookId } from '../middleware/validation/book_validation';
import { authenticateAdmin } from '../middleware/auth';

const prisma = new PrismaClient();

const router = Router();

/**
 * GET /api/books
 * Get all books with optional filters and pagination
 */
router.get(
  '/',
  validateBookQuery,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const {
        title,
        author,
        category,
        isbn,
        page = '1',
        limit = '20',
        sortBy = 'createdAt',
        sortOrder = 'desc',
      } = req.query;

      const filters = {
        title: title as string | undefined,
        author: author as string | undefined,
        category: category as string | undefined,
        isbn: isbn as string | undefined,
      };

      const options = {
        page: parseInt(page as string, 10),
        limit: parseInt(limit as string, 10),
        sortBy: sortBy as string,
        sortOrder: (sortOrder as 'asc' | 'desc') || 'desc',
      };

      const result = await bookService.getBooks(filters, options);

      res.json(result);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * GET /api/books/categories
 * Get all distinct book categories
 */
router.get('/categories', async (req: Request, res: Response, next: NextFunction) => {
  try {
    const categories = await bookService.getCategories();
    res.json({ categories });
  } catch (error) {
    next(error);
  }
});

/**
 * GET /api/books/:id
 * Get a single book by ID
 */
router.get(
  '/:id',
  validateBookId,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;

      const book = await bookService.getBookById(id);

      if (!book) {
        return res.status(404).json({ error: 'Book not found' });
      }

      res.json(book);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * POST /api/v1/books
 * Create a new book (admin only)
 */
router.post('/', authenticateAdmin, async (req: Request, res: Response, next: NextFunction) => {
  try {
    const bookData = req.body;

    // Check ISBN uniqueness if provided
    if (bookData.isbn) {
      const isUnique = await bookService.isIsbnUnique(bookData.isbn);
      if (!isUnique) {
        return res.status(400).json({ error: 'ISBN already exists' });
      }
    }

    const book = await bookService.createBook(bookData);

    res.status(201).json(book);
  } catch (error) {
    next(error);
  }
});

/**
 * PUT /api/v1/books/:id
 * Update a book (admin only)
 */
router.put(
  '/:id',
  authenticateAdmin,
  validateBookId,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;
      const bookData = req.body;

      // Check if book exists
      const existingBook = await bookService.getBookById(id);
      if (!existingBook) {
        return res.status(404).json({ error: 'Book not found' });
      }

      // Check ISBN uniqueness if changed
      if (bookData.isbn && bookData.isbn !== existingBook.isbn) {
        const isUnique = await bookService.isIsbnUnique(bookData.isbn, id);
        if (!isUnique) {
          return res.status(400).json({ error: 'ISBN already exists' });
        }
      }

      const updatedBook = await bookService.updateBook(id, bookData);

      res.json(updatedBook);
    } catch (error) {
      next(error);
    }
  }
);

/**
 * DELETE /api/v1/books/:id
 * Delete a book (admin only). Rejects with 409 Conflict when the book has
 * active loans or pending loan requests.
 */
router.delete(
  '/:id',
  authenticateAdmin,
  validateBookId,
  async (req: Request, res: Response, next: NextFunction) => {
    try {
      const { id } = req.params;

      const book = await bookService.getBookById(id);
      if (!book) {
        return res.status(404).json({ error: 'Book not found' });
      }

      const [activeLoans, pendingRequests] = await Promise.all([
        prisma.loan.count({ where: { bookId: id, status: 'active' } }),
        prisma.loanRequest.count({ where: { bookId: id, status: 'pending' } }),
      ]);

      if (activeLoans > 0 || pendingRequests > 0) {
        return res.status(409).json({
          error: 'Conflict',
          message: '활성 대출 또는 대기 중인 대출 요청이 있어 삭제할 수 없습니다.',
          activeLoans,
          pendingRequests,
        });
      }

      await bookService.deleteBook(id);

      res.status(204).send();
    } catch (error) {
      next(error);
    }
  }
);

export default router;
