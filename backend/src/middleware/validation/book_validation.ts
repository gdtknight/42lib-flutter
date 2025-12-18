import { Request, Response, NextFunction } from 'express';
import { z } from 'zod';

// Schema for book query parameters
const bookQuerySchema = z.object({
  title: z.string().optional(),
  author: z.string().optional(),
  category: z.string().optional(),
  isbn: z.string().optional(),
  page: z.string().regex(/^\d+$/).optional().default('1'),
  limit: z.string().regex(/^\d+$/).optional().default('20'),
  sortBy: z.enum(['title', 'author', 'category', 'createdAt', 'updatedAt']).optional(),
  sortOrder: z.enum(['asc', 'desc']).optional(),
});

// Schema for UUID validation
const uuidSchema = z.string().uuid();

// Schema for book creation/update
const bookCreateSchema = z.object({
  title: z.string().min(1).max(500).trim(),
  author: z.string().min(1).max(200).trim(),
  isbn: z.string().regex(/^\d{10}$|^\d{13}$/).optional().nullable(),
  category: z.string().min(1).max(100).trim(),
  description: z.string().max(2000).optional().nullable(),
  publicationYear: z.number().int().min(1000).max(new Date().getFullYear() + 1).optional().nullable(),
  quantity: z.number().int().min(1).max(100),
  availableQuantity: z.number().int().min(0),
  coverImageUrl: z.string().url().optional().nullable(),
});

// Custom validation: availableQuantity <= quantity
const bookCreateWithAvailabilitySchema = bookCreateSchema.refine(
  (data) => data.availableQuantity <= data.quantity,
  {
    message: 'Available quantity must not exceed total quantity',
    path: ['availableQuantity'],
  }
);

/**
 * Middleware to validate book query parameters
 */
export const validateBookQuery = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    const parsed = bookQuerySchema.parse(req.query);
    
    // Validate pagination limits
    const page = parseInt(parsed.page, 10);
    const limit = parseInt(parsed.limit, 10);

    if (page < 1) {
      return res.status(400).json({ error: 'Page must be at least 1' });
    }

    if (limit < 1 || limit > 100) {
      return res.status(400).json({ error: 'Limit must be between 1 and 100' });
    }

    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Invalid query parameters',
        details: error.errors,
      });
    }
    next(error);
  }
};

/**
 * Middleware to validate book ID parameter
 */
export const validateBookId = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    uuidSchema.parse(req.params.id);
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Invalid book ID format. Expected UUID.',
        details: error.errors,
      });
    }
    next(error);
  }
};

/**
 * Middleware to validate book creation data
 */
export const validateBookCreate = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    bookCreateWithAvailabilitySchema.parse(req.body);
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Invalid book data',
        details: error.errors,
      });
    }
    next(error);
  }
};

/**
 * Middleware to validate book update data
 */
export const validateBookUpdate = (
  req: Request,
  res: Response,
  next: NextFunction
) => {
  try {
    // For updates, all fields are optional
    const partialSchema = bookCreateWithAvailabilitySchema.partial();
    partialSchema.parse(req.body);
    next();
  } catch (error) {
    if (error instanceof z.ZodError) {
      return res.status(400).json({
        error: 'Invalid book update data',
        details: error.errors,
      });
    }
    next(error);
  }
};
