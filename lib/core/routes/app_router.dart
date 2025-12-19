import 'package:go_router/go_router.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';
import '../../screens/mobile/book_detail/book_detail_screen.dart';
import '../../screens/mobile/auth/login_screen.dart';
import '../../screens/mobile/loan/my_loans_screen.dart';
import '../../models/book.dart';

/// Application router configuration using go_router
class AppRouter {
  static final GoRouter router = GoRouter(
    initialLocation: '/',
    debugLogDiagnostics: true,
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => const BookListScreen(),
      ),
      
      // Book detail screen
      GoRoute(
        path: '/books/:id',
        builder: (context, state) {
          final bookId = state.pathParameters['id'];
          final book = state.extra as Book?;
          
          if (book != null) {
            return BookDetailScreen(book: book);
          }
          
          // If no book provided, show error
          return BookListScreen();
        },
      ),
      
      // Login screen
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // My loans screen
      GoRoute(
        path: '/my-loans',
        builder: (context, state) => const MyLoansScreen(),
      ),
    ],
  );
}
