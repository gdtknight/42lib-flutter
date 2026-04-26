import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import 'app/config.dart';
import 'core/routes/app_router.dart';
import 'features/admin_catalog/data/repositories/admin_auth_repository_impl.dart';
import 'features/admin_catalog/presentation/bloc/admin_auth_bloc.dart';
import 'features/admin_catalog/presentation/bloc/admin_auth_event.dart';

void main() {
  runApp(const Library42App());
}

class Library42App extends StatefulWidget {
  const Library42App({super.key});

  @override
  State<Library42App> createState() => _Library42AppState();
}

class _Library42AppState extends State<Library42App> {
  late final AdminAuthBloc _adminAuthBloc;
  late final GoRouter _router;

  @override
  void initState() {
    super.initState();
    _adminAuthBloc = AdminAuthBloc(
      repository: AdminAuthRepositoryImpl(baseUrl: AppConfig.apiBaseUrl),
    )..add(const AdminAuthSessionRestored());
    _router = AppRouter.create(_adminAuthBloc);
  }

  @override
  void dispose() {
    _adminAuthBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminAuthBloc>.value(
      value: _adminAuthBloc,
      child: MaterialApp.router(
        title: '42 Library Management',
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
          useMaterial3: true,
        ),
        darkTheme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: Colors.blue,
            brightness: Brightness.dark,
          ),
          useMaterial3: true,
        ),
        routerConfig: _router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
