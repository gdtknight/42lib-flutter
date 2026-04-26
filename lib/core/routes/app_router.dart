import 'package:go_router/go_router.dart';

import '../../features/admin_catalog/presentation/bloc/admin_auth_bloc.dart';
import '../../features/admin_catalog/presentation/bloc/admin_auth_state.dart';
import '../../features/admin_catalog/presentation/screens/admin_dashboard_screen.dart';
import '../../features/admin_catalog/presentation/screens/admin_login_screen.dart';
import '../../features/admin_catalog/presentation/screens/catalog_management_screen.dart';
import '../../features/books/presentation/screens/book_list_screen.dart';
import '../../models/book.dart';
import '../../screens/mobile/auth/login_screen.dart';
import '../../screens/mobile/book_detail/book_detail_screen.dart';
import '../../screens/mobile/loan/my_loans_screen.dart';
import 'go_router_refresh_stream.dart';

class AppRouter {
  /// Build a [GoRouter] wired up with admin authentication guards.
  ///
  /// The router's `redirect` callback inspects [adminAuthBloc] state to
  /// gate `/admin/*` routes. The router refreshes whenever the bloc emits.
  static GoRouter create(AdminAuthBloc adminAuthBloc) {
    return GoRouter(
      initialLocation: '/',
      debugLogDiagnostics: true,
      refreshListenable: GoRouterRefreshStream(adminAuthBloc.stream),
      redirect: (context, state) {
        final loc = state.matchedLocation;
        final isAdminRoute = loc.startsWith('/admin');
        if (!isAdminRoute) return null;

        final authState = adminAuthBloc.state;
        final isAuthenticated = authState is AdminAuthenticated;
        final isOnLogin = loc == '/admin/login';

        if (!isAuthenticated && !isOnLogin) return '/admin/login';
        if (isAuthenticated && isOnLogin) return '/admin';
        return null;
      },
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => const BookListScreen(),
        ),

        // Book detail screen
        GoRoute(
          path: '/books/:id',
          builder: (context, state) {
            final book = state.extra as Book?;
            if (book != null) {
              return BookDetailScreen(book: book);
            }
            return const BookListScreen();
          },
        ),

        // Student login
        GoRoute(
          path: '/login',
          builder: (context, state) => const LoginScreen(),
        ),

        GoRoute(
          path: '/my-loans',
          builder: (context, state) => const MyLoansScreen(),
        ),

        // Admin
        GoRoute(
          path: '/admin/login',
          builder: (context, state) => const AdminLoginScreen(),
        ),
        GoRoute(
          path: '/admin',
          builder: (context, state) => const AdminDashboardScreen(),
        ),
        GoRoute(
          path: '/admin/catalog',
          builder: (context, state) => const CatalogManagementScreen(),
        ),
      ],
    );
  }
}
