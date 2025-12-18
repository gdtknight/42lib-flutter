import 'package:go_router/go_router.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';

/// Application router configuration using go_router
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BookListScreen(),
      ),
      // Future routes will be added here
      // GoRoute(
      //   path: '/books/:id',
      //   builder: (context, state) {
      //     final id = state.pathParameters['id']!;
      //     return BookDetailScreen(bookId: id);
      //   },
      // ),
    ],
  );
}
