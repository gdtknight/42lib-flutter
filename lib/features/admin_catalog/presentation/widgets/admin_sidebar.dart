import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../bloc/admin_auth_bloc.dart';
import '../bloc/admin_auth_event.dart';
import '../bloc/admin_auth_state.dart';

/// Side navigation for admin screens. Lists primary destinations and a
/// logout action. Catalog item is enabled but currently routes to a
/// placeholder until US4-C-β lands.
class AdminSidebar extends StatelessWidget {
  const AdminSidebar({super.key, required this.currentRoute});

  final String currentRoute;

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AdminAuthBloc, AdminAuthState>(
      buildWhen: (prev, next) =>
          prev is AdminAuthenticated || next is AdminAuthenticated,
      builder: (context, state) {
        final admin = state is AdminAuthenticated ? state.admin : null;
        return NavigationDrawer(
          selectedIndex: _selectedIndex,
          onDestinationSelected: (i) => _onSelect(context, i),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(28, 16, 28, 8),
              child: Text(
                admin?.fullName ?? '관리자',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            if (admin != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(28, 0, 28, 16),
                child: Text(
                  admin.email,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const Divider(),
            const NavigationDrawerDestination(
              icon: Icon(Icons.dashboard_outlined),
              selectedIcon: Icon(Icons.dashboard),
              label: Text('대시보드'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.book_outlined),
              selectedIcon: Icon(Icons.book),
              label: Text('도서 관리'),
            ),
            const NavigationDrawerDestination(
              icon: Icon(Icons.assignment_outlined),
              selectedIcon: Icon(Icons.assignment),
              label: Text('대출 관리'),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(28, 16, 28, 8),
              child: Divider(),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('로그아웃'),
              onTap: () => context
                  .read<AdminAuthBloc>()
                  .add(const AdminAuthLogoutRequested()),
            ),
          ],
        );
      },
    );
  }

  int get _selectedIndex {
    if (currentRoute.startsWith('/admin/catalog')) return 1;
    if (currentRoute.startsWith('/admin/loans')) return 2;
    return 0;
  }

  void _onSelect(BuildContext context, int index) {
    Navigator.of(context).maybePop(); // close drawer if open
    switch (index) {
      case 0:
        context.go('/admin');
        break;
      case 1:
        context.go('/admin/catalog');
        break;
      case 2:
        context.go('/admin/loans');
        break;
    }
  }
}
