import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../screens/mobile/home/home_screen.dart' as mobile;
import '../screens/mobile/book_detail/book_detail_screen.dart';
import '../models/book.dart';

/// 앱 라우팅 설정
/// Constitution 원칙 VII: 사용자 중심 UX (직관적 네비게이션)
class AppRouter {
  /// 라우트 경로 상수
  static const String home = '/';
  static const String bookDetail = '/books/:id';

  /// GoRouter 인스턴스
  static GoRouter get router => _router;

  static final GoRouter _router = GoRouter(
    initialLocation: home,
    debugLogDiagnostics: true,

    routes: [
      // 메인 홈 - 도서 검색 및 탐색 (User Story 1)
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const mobile.HomeScreen(),
      ),

      // 도서 상세 (User Story 1)
      GoRoute(
        path: bookDetail,
        name: 'book-detail',
        builder: (context, state) {
          final bookId = state.pathParameters['id'];
          final book = state.extra as Book?;

          if (book != null) {
            return BookDetailScreen(book: book);
          }

          // bookId로 조회가 필요한 경우 (향후 구현)
          return Scaffold(
            appBar: AppBar(title: const Text('책 상세')),
            body: Center(
              child: Text('책을 찾을 수 없습니다. ID: $bookId'),
            ),
          );
        },
      ),
    ],

    // 에러 페이지
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error.toString(),
    ),
  );
}

// ============================================================================
// 에러 화면
// ============================================================================

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('오류')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline,
                size: 64, color: Theme.of(context).colorScheme.error),
            const SizedBox(height: 16),
            const Text('페이지를 찾을 수 없습니다'),
            const SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: const Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
