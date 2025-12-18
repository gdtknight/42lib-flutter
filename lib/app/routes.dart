import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// 앱 라우팅 설정
/// Constitution 원칙 VII: 사용자 중심 UX (직관적 네비게이션)
class AppRouter {
  /// 라우트 경로 상수
  static const String splash = '/';
  static const String login = '/login';
  static const String home = '/home';
  static const String bookList = '/books';
  static const String bookDetail = '/books/:id';
  static const String loanRequests = '/loans';
  static const String reservations = '/reservations';
  static const String suggestions = '/suggestions';
  static const String profile = '/profile';
  
  /// GoRouter 인스턴스
  static GoRouter get router => _router;
  
  static final GoRouter _router = GoRouter(
    initialLocation: splash,
    debugLogDiagnostics: true,
    
    // 인증 가드 (향후 구현)
    redirect: (BuildContext context, GoRouterState state) {
      // TODO: 인증 상태 확인
      // final isAuthenticated = ...;
      // if (!isAuthenticated && state.location != login) {
      //   return login;
      // }
      return null;
    },
    
    routes: [
      // 스플래시 화면
      GoRoute(
        path: splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      
      // 로그인 화면 (42 OAuth)
      GoRoute(
        path: login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      
      // 메인 홈 (네비게이션 바 포함)
      GoRoute(
        path: home,
        name: 'home',
        builder: (context, state) => const HomeScreen(),
        routes: [
          // 도서 목록
          GoRoute(
            path: 'books',
            name: 'books',
            builder: (context, state) => const BookListScreen(),
            routes: [
              // 도서 상세
              GoRoute(
                path: ':id',
                name: 'book-detail',
                builder: (context, state) {
                  final bookId = state.pathParameters['id']!;
                  return BookDetailScreen(bookId: bookId);
                },
              ),
            ],
          ),
          
          // 대출 신청 목록
          GoRoute(
            path: 'loans',
            name: 'loans',
            builder: (context, state) => const LoanRequestsScreen(),
          ),
          
          // 예약 대기 목록
          GoRoute(
            path: 'reservations',
            name: 'reservations',
            builder: (context, state) => const ReservationsScreen(),
          ),
          
          // 도서 추천
          GoRoute(
            path: 'suggestions',
            name: 'suggestions',
            builder: (context, state) => const SuggestionsScreen(),
          ),
          
          // 프로필
          GoRoute(
            path: 'profile',
            name: 'profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
    ],
    
    // 에러 페이지
    errorBuilder: (context, state) => ErrorScreen(
      error: state.error.toString(),
    ),
  );
}

// ============================================================================
// 임시 화면 위젯 (User Story 구현 시 교체)
// ============================================================================

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.book, size: 80, color: Theme.of(context).primaryColor),
            SizedBox(height: 16),
            Text(
              '42lib',
              style: Theme.of(context).textTheme.displayLarge,
            ),
            SizedBox(height: 8),
            Text(
              '도서 관리 시스템',
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
  }
}

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('로그인', style: Theme.of(context).textTheme.displayMedium),
            SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => context.go('/home'),
              child: Text('42 OAuth 로그인'),
            ),
          ],
        ),
      ),
    );
  }
}

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('42lib')),
      body: Center(child: Text('홈 화면')),
      bottomNavigationBar: BottomNavigationBar(
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.book), label: '도서'),
          BottomNavigationBarItem(icon: Icon(Icons.pending_actions), label: '대출'),
          BottomNavigationBarItem(icon: Icon(Icons.bookmark), label: '예약'),
          BottomNavigationBarItem(icon: Icon(Icons.lightbulb), label: '추천'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: '프로필'),
        ],
        onTap: (index) {
          final routes = ['/home/books', '/home/loans', '/home/reservations', '/home/suggestions', '/home/profile'];
          context.go(routes[index]);
        },
      ),
    );
  }
}

class BookListScreen extends StatelessWidget {
  const BookListScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('도서 목록')),
      body: Center(child: Text('도서 목록 화면')),
    );
  }
}

class BookDetailScreen extends StatelessWidget {
  final String bookId;
  const BookDetailScreen({super.key, required this.bookId});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('도서 상세')),
      body: Center(child: Text('도서 ID: $bookId')),
    );
  }
}

class LoanRequestsScreen extends StatelessWidget {
  const LoanRequestsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('대출 신청')),
      body: Center(child: Text('대출 신청 목록')),
    );
  }
}

class ReservationsScreen extends StatelessWidget {
  const ReservationsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('예약 대기')),
      body: Center(child: Text('예약 대기 목록')),
    );
  }
}

class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('도서 추천')),
      body: Center(child: Text('도서 추천 화면')),
    );
  }
}

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('프로필')),
      body: Center(child: Text('프로필 화면')),
    );
  }
}

class ErrorScreen extends StatelessWidget {
  final String error;
  const ErrorScreen({super.key, required this.error});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('오류')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.error_outline, size: 64, color: Theme.of(context).colorScheme.error),
            SizedBox(height: 16),
            Text('페이지를 찾을 수 없습니다'),
            SizedBox(height: 8),
            Text(error, style: Theme.of(context).textTheme.bodySmall),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.go('/'),
              child: Text('홈으로 돌아가기'),
            ),
          ],
        ),
      ),
    );
  }
}
