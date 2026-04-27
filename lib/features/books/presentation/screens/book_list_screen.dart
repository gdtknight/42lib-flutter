import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/book.dart';
import '../../data/repositories/book_repository_impl.dart';
import '../bloc/book_bloc.dart';
import '../bloc/book_event.dart';
import '../bloc/book_state.dart';
import '../widgets/book_card.dart';
import '../widgets/book_search_bar.dart';
import '../../../../models/book.dart' as app_book;

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key, this.bloc});

  final BookBloc? bloc;

  @override
  Widget build(BuildContext context) {
    if (bloc != null) {
      return BlocProvider<BookBloc>.value(
        value: bloc!,
        child: const _BookListView(),
      );
    }
    return BlocProvider<BookBloc>(
      create: (_) => BookBloc(repository: BookRepositoryImpl())
        ..add(const FetchBooks()),
      child: const _BookListView(),
    );
  }
}

class _BookListView extends StatefulWidget {
  const _BookListView();

  @override
  State<_BookListView> createState() => _BookListViewState();
}

class _BookListViewState extends State<_BookListView> {
  bool _isGridView = true;

  void _toggleView() {
    setState(() => _isGridView = !_isGridView);
  }

  void _loadMore(BuildContext context) {
    context.read<BookBloc>().add(const LoadMoreBooks());
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
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: BookSearchBar(
              onChanged: (query) =>
                  context.read<BookBloc>().add(SearchBooks(query: query)),
              hintText: 'Search by title, author, or ISBN...',
            ),
          ),
          Expanded(
            child: BlocBuilder<BookBloc, BookState>(
              builder: (context, state) => _buildContent(context, state),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, BookState state) {
    if (state is BookLoading || state is BookInitial) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state is BookError) {
      return _ErrorView(
        message: state.message,
        onRetry: () => context.read<BookBloc>().add(const FetchBooks()),
      );
    }

    if (state is BookLoaded) {
      if (state.books.isEmpty) {
        return _EmptyView(searchQuery: state.searchQuery);
      }
      final onLoadMore = () => _loadMore(context);
      return RefreshIndicator(
        onRefresh: () async =>
            context.read<BookBloc>().add(const RefreshBooks()),
        child: _isGridView
            ? _BookGrid(
                books: state.books,
                hasMore: state.hasMore,
                onTap: _onBookTap,
                onLoadMore: onLoadMore,
              )
            : _BookList(
                books: state.books,
                hasMore: state.hasMore,
                onTap: _onBookTap,
                onLoadMore: onLoadMore,
              ),
      );
    }

    return const SizedBox.shrink();
  }

  void _onBookTap(Book book) {
    final appBook = app_book.Book(
      id: book.id,
      title: book.title,
      author: book.author,
      category: book.category,
      isbn: book.isbn,
      publicationYear: book.publicationYear,
      quantity: book.quantity,
      availableQuantity: book.availableQuantity,
      description: book.description,
      coverImageUrl: book.coverImageUrl,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    context.go('/books/${book.id}', extra: appBook);
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(
            'Failed to load books: $message',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16),
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: onRetry,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}

class _EmptyView extends StatelessWidget {
  final String? searchQuery;

  const _EmptyView({this.searchQuery});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            searchQuery != null && searchQuery!.isNotEmpty
                ? 'No books found for "$searchQuery"'
                : 'No books available',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}

/// Mixin for the grid/list views to share infinite-scroll pagination wiring.
/// Triggers [onLoadMore] when the user scrolls within [_loadMoreThreshold]
/// pixels of the bottom AND a new page is available AND we haven't already
/// triggered for the current item count.
mixin _PaginationMixin<W extends StatefulWidget> on State<W> {
  static const double _loadMoreThreshold = 200;

  late final ScrollController _scrollController;
  int _lastTriggerCount = 0;

  bool get hasMore;
  int get itemCount;
  VoidCallback get onLoadMore;

  @override
  void initState() {
    super.initState();
    _scrollController = ScrollController()..addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!hasMore) return;
    if (!_scrollController.hasClients) return;
    final position = _scrollController.position;
    if (position.pixels < position.maxScrollExtent - _loadMoreThreshold) return;
    if (itemCount <= _lastTriggerCount) return;
    _lastTriggerCount = itemCount;
    onLoadMore();
  }
}

class _BookGrid extends StatefulWidget {
  final List<Book> books;
  final bool hasMore;
  final void Function(Book) onTap;
  final VoidCallback onLoadMore;

  const _BookGrid({
    required this.books,
    required this.hasMore,
    required this.onTap,
    required this.onLoadMore,
  });

  @override
  State<_BookGrid> createState() => _BookGridState();
}

class _BookGridState extends State<_BookGrid> with _PaginationMixin<_BookGrid> {
  @override
  bool get hasMore => widget.hasMore;
  @override
  int get itemCount => widget.books.length;
  @override
  VoidCallback get onLoadMore => widget.onLoadMore;

  int _getCrossAxisCount(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 4;
    if (width > 800) return 3;
    if (width > 600) return 2;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: _getCrossAxisCount(context),
        childAspectRatio: 0.65,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: widget.books.length,
      itemBuilder: (context, index) => BookCard(
        book: widget.books[index],
        onTap: () => widget.onTap(widget.books[index]),
      ),
    );
  }
}

class _BookList extends StatefulWidget {
  final List<Book> books;
  final bool hasMore;
  final void Function(Book) onTap;
  final VoidCallback onLoadMore;

  const _BookList({
    required this.books,
    required this.hasMore,
    required this.onTap,
    required this.onLoadMore,
  });

  @override
  State<_BookList> createState() => _BookListState();
}

class _BookListState extends State<_BookList> with _PaginationMixin<_BookList> {
  @override
  bool get hasMore => widget.hasMore;
  @override
  int get itemCount => widget.books.length;
  @override
  VoidCallback get onLoadMore => widget.onLoadMore;

  @override
  Widget build(BuildContext context) {
    final showSpinner = widget.hasMore;
    final listLength = widget.books.length + (showSpinner ? 1 : 0);
    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: listLength,
      itemBuilder: (context, index) {
        if (index >= widget.books.length) {
          return const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: BookCard(
            book: widget.books[index],
            onTap: () => widget.onTap(widget.books[index]),
          ),
        );
      },
    );
  }
}
