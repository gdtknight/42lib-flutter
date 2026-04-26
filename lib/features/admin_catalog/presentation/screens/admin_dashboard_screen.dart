import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/admin_auth_bloc.dart';
import '../bloc/admin_auth_state.dart';
import '../widgets/admin_sidebar.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('관리자 대시보드')),
      drawer: const AdminSidebar(currentRoute: '/admin'),
      body: BlocBuilder<AdminAuthBloc, AdminAuthState>(
        builder: (context, state) {
          if (state is! AdminAuthenticated) {
            return const SizedBox.shrink();
          }
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      '환영합니다, ${state.admin.fullName}님',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '역할: ${state.admin.isSuperAdmin ? "최고 관리자" : "관리자"}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.book),
                        title: const Text('도서 관리'),
                        subtitle: const Text('도서 추가, 편집, 삭제'),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => context.go('/admin/catalog'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Placeholder for catalog screen — replaced in US4-C-β.
class AdminCatalogPlaceholderScreen extends StatelessWidget {
  const AdminCatalogPlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('도서 관리')),
      drawer: const AdminSidebar(currentRoute: '/admin/catalog'),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            '도서 관리 화면은 곧 제공됩니다 (US4-C-β).',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
