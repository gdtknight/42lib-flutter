import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../state/book/book_bloc.dart';
import '../../../state/book/book_event.dart';
import '../../../state/book/book_state.dart';
import '../../../widgets/book_card.dart';
import '../../../widgets/book_search_bar.dart' as custom;
import '../../../widgets/category_filter.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ScrollController _scrollController = ScrollController();
  final List<String> _categories = [
    'Programming',
    'Design',
    'Business',
    'Science',
    'Art',
    'Language',
    'History',
    'Philosophy',
  ];

  @override
  void initState() {
    super.initState();

    // Fetch books on initial load
    context.read<BookBloc>().add(const FetchBooks());

    // Setup infinite scroll
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_isBottom) {
      context.read<BookBloc>().add(const LoadMoreBooks());
    }
  }

  bool get _isBottom {
    if (!_scrollController.hasClients) return false;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.offset;
    return currentScroll >= (maxScroll * 0.9);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('도서 목록'),
        centerTitle: true,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: custom.BookSearchBar(
              onChanged: (query) {
                context.read<BookBloc>().add(SearchBooks(query: query));
              },
            ),
          ),

          // Category filter
          BlocBuilder<BookBloc, BookState>(
            builder: (context, state) {
              String? selectedCategory;
              if (state is BookLoaded) {
                selectedCategory = state.activeFilter;
              }

              return CategoryFilter(
                categories: _categories,
                selectedCategory: selectedCategory,
                onCategorySelected: (category) {
                  if (category == null) {
                    context.read<BookBloc>().add(const ClearSearch());
                  } else {
                    context
                        .read<BookBloc>()
                        .add(FilterByCategory(category: category));
                  }
                },
              );
            },
          ),

          // Book list
          Expanded(
            child: BlocBuilder<BookBloc, BookState>(
              builder: (context, state) {
                if (state is BookLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is BookError) {
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
                          state.message,
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () {
                            context.read<BookBloc>().add(const FetchBooks());
                          },
                          child: const Text('다시 시도'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is BookLoaded) {
                  if (state.books.isEmpty) {
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
                            '검색 결과가 없습니다',
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
                    onRefresh: () async {
                      context.read<BookBloc>().add(const RefreshBooks());
                    },
                    child: ListView.builder(
                      controller: _scrollController,
                      itemCount: state.books.length + (state.hasMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index >= state.books.length) {
                          return const Center(
                            child: Padding(
                              padding: EdgeInsets.all(16),
                              child: CircularProgressIndicator(),
                            ),
                          );
                        }

                        final book = state.books[index];

                        return BookCard(
                          book: book,
                          onTap: () {
                            context.go('/books/${book.id}', extra: book);
                          },
                        );
                      },
                    ),
                  );
                }

                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }
}
