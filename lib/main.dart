import 'package:flutter/material.dart';
import 'core/routes/app_router.dart';

void main() {
  runApp(const Library42App());
}

class Library42App extends StatelessWidget {
  const Library42App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
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
      routerConfig: AppRouter.router,
      debugShowCheckedModeBanner: false,
    );
  }
}
