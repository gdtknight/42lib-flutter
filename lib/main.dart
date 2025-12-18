import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'app/theme.dart';
import 'app/routes.dart';
import 'app/config.dart';
import 'state/book/book_bloc.dart';
import 'repositories/book_repository_impl.dart';
import 'services/api/base_api_client.dart';
import 'services/storage/sqflite_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Hive 초기화
  await Hive.initFlutter();

  // Config 초기화
  await AppConfig.initialize();

  // Database 초기화
  final database = await SqfliteService.database;

  runApp(Library42App(database: database));
}

class Library42App extends StatelessWidget {
  final dynamic database;

  const Library42App({super.key, required this.database});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // BookBloc 프로바이더
        BlocProvider(
          create: (context) {
            final apiClient = BaseApiClient(baseUrl: AppConfig.apiBaseUrl);
            final repository = BookRepositoryImpl(
              database: database,
              apiClient: apiClient,
            );
            return BookBloc(repository: repository);
          },
        ),
      ],
      child: MaterialApp.router(
        title: '42 도서 관리',
        theme: AppTheme.darkTheme,
        routerConfig: AppRouter.router,
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}
