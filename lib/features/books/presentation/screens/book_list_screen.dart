import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/book.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../../domain/repositories/book_repository.dart';
import '../widgets/book_card.dart';
import '../widgets/book_search_bar.dart';
import '../../../../models/book.dart' as app_book;

/// Book list screen displaying available books
class BookListScreen extends StatefulWidget {
  const BookListScreen({super.key});

  @override
  State<BookListScreen> createState() => _BookListScreenState();
}

class _BookListScreenState extends State<BookListScreen> {
  final BookRepository _repository = BookRepositoryImpl();
  List<Book> _books = [];
  bool _isLoading = false;
  bool _isGridView = true;
  String? _searchQuery;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadBooks();
  }

  Future<void> _loadBooks() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final books = _searchQuery != null && _searchQuery!.isNotEmpty
          ? await _repository.searchBooks(query: _searchQuery)
          : await _repository.fetchBooks();

      setState(() {
        _books = books;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load books: $e';
        _isLoading = false;
      });
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query;
    });
    _loadBooks();
  }

  void _toggleView() {
    setState(() {
      _isGridView = !_isGridView;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Library Books'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.list : Icons.grid_view),
            onPressed: _toggleView,
            tooltip: _isGridView ? 'List view' : 'Grid view',
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BookSearchBar(
              onChanged: _onSearchChanged,
              hintText: 'Search by title, author, or ISBN...',
            ),
          ),

          // Book list
          Expanded(
            child: _buildContent(),
          ),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadBooks,
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_books.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              _searchQuery != null && _searchQuery!.isNotEmpty
                  ? 'No books found for "$_searchQuery"'
                  : 'No books available',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadBooks,
      child: _isGridView ? _buildGridView() : _buildListView(),
    );
  }

  Widget _buildGridView() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return BookCard(
          book: _books[index],
          onTap: () => _onBookTap(_books[index]),
        );
      },
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _books.length,
      itemBuilder: (context, index) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BookCard(
            book: _books[index],
            onTap: () => _onBookTap(_books[index]),
          ),
        );
      },
    );
  }

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  void _onBookTap(Book book) {
    // Convert feature Book to app Book model for navigation
    final appBook = app_book.Book(
      id: book.id,
      title: book.title,
      author: book.author,
      category: book.category ?? 'Unknown',
      isbn: book.isbn,
      publicationYear: book.publicationYear,
      quantity: book.quantity ?? 1,
      availableQuantity: book.availableQuantity ?? 0,
      description: book.description,
      coverImageUrl: book.coverImageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    
    context.go('/books/${book.id}', extra: appBook);
  }
}
