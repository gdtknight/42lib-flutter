import { Router, Request, Response } from 'express';
import { listBooks, getBookById, BookListParams } from '../services/book_service';

const router = Router();

/**
 * GET /api/v1/books
 * List all books with pagination and filters
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const params: BookListParams = {
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      search: req.query.search as string | undefined,
      category: req.query.category as string | undefined,
      available:
        req.query.available !== undefined
          ? req.query.available === 'true'
          : undefined,
    };

    if (params.page && (params.page < 1 || isNaN(params.page))) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid page parameter. Must be a positive integer.',
      });
    }

    if (params.limit && (params.limit < 1 || params.limit > 100 || isNaN(params.limit))) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid limit parameter. Must be between 1 and 100.',
      });
    }

    const result = await listBooks(params);

    res.status(200).json(result);
  } catch (error) {
    console.error('Error listing books:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve books',
    });
  }
});

/**
 * GET /api/v1/books/:id
 * Get book details by ID
 */
router.get('/:id', async (req: Request, res: Response) => {
  try {
    const { id } = req.params;

    if (!id || typeof id !== 'string') {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid book ID',
      });
    }

    const book = await getBookById(id);

    if (!book) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Book not found',
      });
    }

    res.status(200).json(book);
  } catch (error) {
    console.error('Error getting book:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to retrieve book details',
    });
  }
});

export default router;
