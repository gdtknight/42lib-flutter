import { Router, Request, Response } from 'express';
import { BookService } from '../services/book_service';

const router = Router();

/**
 * GET /api/v1/books
 * List all books with pagination and filters
 */
router.get('/', async (req: Request, res: Response) => {
  try {
    const params = {
      page: req.query.page ? parseInt(req.query.page as string, 10) : 1,
      limit: req.query.limit ? parseInt(req.query.limit as string, 10) : 20,
      search: req.query.search as string | undefined,
      category: req.query.category as string | undefined,
      availableOnly: req.query.availableOnly === 'true',
    };

    const result = await BookService.getBooks(params);
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
    const book = await BookService.getBookById(id);
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
