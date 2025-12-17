import 'package:flutter/material.dart';

void main() {
  runApp(const Library42App());
}

class Library42App extends StatelessWidget {
  const Library42App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '42 도서 관리',
      theme: ThemeData(
        // 42 brand color - teal/cyan
        primarySwatch: Colors.cyan,
        primaryColor: const Color(0x00BABC),
        scaffoldBackgroundColor: const Color(0x1A1D23),
        brightness: Brightness.dark,
        useMaterial3: true,
      ),
      home: const HomePage(),
    );
  }
}

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('42 도서관'),
      ),
      body: const Center(
        child: Text(
          '42 Learning Space\n도서 관리 시스템',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 24),
        ),
      ),
    );
  }
}
