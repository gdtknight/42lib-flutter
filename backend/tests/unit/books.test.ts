import request from 'supertest';
import { app } from '../../src/server';
import { PrismaClient } from '@prisma/client';

const prisma = new PrismaClient();

describe('GET /books', () => {
  beforeAll(async () => {
    // Clean up test data
    await prisma.book.deleteMany({});

    // Seed test books
    await prisma.book.createMany({
      data: [
        {
          id: '123e4567-e89b-12d3-a456-426614174000',
          title: 'Clean Code',
          author: 'Robert C. Martin',
          isbn: '9780132350884',
          category: 'Programming',
          description: 'A handbook of agile software craftsmanship',
          publicationYear: 2008,
          quantity: 5,
          availableQuantity: 3,
          coverImageUrl: 'https://example.com/cover1.jpg',
        },
        {
          id: '123e4567-e89b-12d3-a456-426614174001',
          title: 'Design Patterns',
          author: 'Gang of Four',
          isbn: '9780201633610',
          category: 'Programming',
          description: 'Elements of Reusable Object-Oriented Software',
          publicationYear: 1994,
          quantity: 3,
          availableQuantity: 0,
          coverImageUrl: 'https://example.com/cover2.jpg',
        },
        {
          id: '123e4567-e89b-12d3-a456-426614174002',
          title: 'The Design of Everyday Things',
          author: 'Don Norman',
          isbn: '9780465050659',
          category: 'Design',
          description: 'Revised and expanded edition',
          publicationYear: 2013,
          quantity: 4,
          availableQuantity: 2,
          coverImageUrl: 'https://example.com/cover3.jpg',
        },
      ],
    });
  });

  afterAll(async () => {
    await prisma.book.deleteMany({});
    await prisma.$disconnect();
  });

  it('should return all books with default pagination', async () => {
    const response = await request(app).get('/api/v1/books').expect(200);

    expect(response.body.data).toHaveLength(3);
    expect(response.body.total).toBe(3);
    expect(response.body.page).toBe(1);
    expect(response.body.limit).toBe(20);
  });

  it('should return books with custom pagination', async () => {
    const response = await request(app)
      .get('/api/v1/books?page=1&limit=2')
      .expect(200);

    expect(response.body.data).toHaveLength(2);
    expect(response.body.total).toBe(3);
    expect(response.body.page).toBe(1);
    expect(response.body.limit).toBe(2);
  });

  it('should filter books by title', async () => {
    const response = await request(app)
      .get('/api/v1/books?title=Clean')
      .expect(200);

    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].title).toBe('Clean Code');
  });

  it('should filter books by author', async () => {
    const response = await request(app)
      .get('/api/v1/books?author=Martin')
      .expect(200);

    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].author).toBe('Robert C. Martin');
  });

  it('should filter books by category', async () => {
    const response = await request(app)
      .get('/api/v1/books?category=Programming')
      .expect(200);

    expect(response.body.data).toHaveLength(2);
    expect(response.body.data.every((book: any) => book.category === 'Programming')).toBe(true);
  });

  it('should search books by multiple criteria', async () => {
    const response = await request(app)
      .get('/api/v1/books?title=Design&category=Programming')
      .expect(200);

    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].title).toBe('Design Patterns');
  });

  it('should return empty array when no books match', async () => {
    const response = await request(app)
      .get('/api/v1/books?title=NonExistent')
      .expect(200);

    expect(response.body.data).toHaveLength(0);
    expect(response.body.total).toBe(0);
  });

  it('should sort books by title ascending', async () => {
    const response = await request(app)
      .get('/api/v1/books?sortBy=title&sortOrder=asc')
      .expect(200);

    expect(response.body.data[0].title).toBe('Clean Code');
  });

  it('should sort books by createdAt descending', async () => {
    const response = await request(app)
      .get('/api/v1/books?sortBy=createdAt&sortOrder=desc')
      .expect(200);

    expect(response.body.data).toHaveLength(3);
  });

  it('should return book with availability status', async () => {
    const response = await request(app).get('/api/v1/books').expect(200);

    const availableBook = response.body.data.find(
      (book: any) => book.id === '123e4567-e89b-12d3-a456-426614174000'
    );
    const unavailableBook = response.body.data.find(
      (book: any) => book.id === '123e4567-e89b-12d3-a456-426614174001'
    );

    expect(availableBook.availableQuantity).toBeGreaterThan(0);
    expect(unavailableBook.availableQuantity).toBe(0);
  });

  it('should return 400 for invalid pagination parameters', async () => {
    const response = await request(app)
      .get('/api/v1/books?page=-1&limit=0')
      .expect(400);

    expect(response.body.error).toBeDefined();
  });

  it('should handle case-insensitive search', async () => {
    const response = await request(app)
      .get('/api/v1/books?title=clean%20code')
      .expect(200);

    expect(response.body.data).toHaveLength(1);
    expect(response.body.data[0].title).toBe('Clean Code');
  });
});

describe('GET /books/:id', () => {
  const testBookId = '123e4567-e89b-12d3-a456-426614174000';

  beforeAll(async () => {
    await prisma.book.deleteMany({});
    await prisma.book.create({
      data: {
        id: testBookId,
        title: 'Clean Code',
        author: 'Robert C. Martin',
        isbn: '9780132350884',
        category: 'Programming',
        description: 'A handbook of agile software craftsmanship',
        publicationYear: 2008,
        quantity: 5,
        availableQuantity: 3,
        coverImageUrl: 'https://example.com/cover.jpg',
      },
    });
  });

  afterAll(async () => {
    await prisma.book.deleteMany({});
    await prisma.$disconnect();
  });

  it('should return a book by id', async () => {
    const response = await request(app)
      .get(`/api/v1/books/${testBookId}`)
      .expect(200);

    expect(response.body.id).toBe(testBookId);
    expect(response.body.title).toBe('Clean Code');
    expect(response.body.author).toBe('Robert C. Martin');
    expect(response.body.isbn).toBe('9780132350884');
  });

  it('should return 404 for non-existent book', async () => {
    const nonExistentId = '123e4567-e89b-12d3-a456-426614174999';
    const response = await request(app)
      .get(`/api/v1/books/${nonExistentId}`)
      .expect(404);

    expect(response.body.error).toBe('Book not found');
  });

  it('should return 400 for invalid UUID format', async () => {
    const response = await request(app)
      .get('/api/v1/books/invalid-uuid')
      .expect(400);

    expect(response.body.error).toBeDefined();
  });

  it('should include all book fields', async () => {
    const response = await request(app)
      .get(`/api/v1/books/${testBookId}`)
      .expect(200);

    expect(response.body).toHaveProperty('id');
    expect(response.body).toHaveProperty('title');
    expect(response.body).toHaveProperty('author');
    expect(response.body).toHaveProperty('isbn');
    expect(response.body).toHaveProperty('category');
    expect(response.body).toHaveProperty('description');
    expect(response.body).toHaveProperty('publicationYear');
    expect(response.body).toHaveProperty('quantity');
    expect(response.body).toHaveProperty('availableQuantity');
    expect(response.body).toHaveProperty('coverImageUrl');
    expect(response.body).toHaveProperty('createdAt');
    expect(response.body).toHaveProperty('updatedAt');
  });
});
