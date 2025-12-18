import 'package:flutter/material.dart';

/// 42 러닝 스페이스 도서 관리 시스템 테마
/// Constitution 원칙 VI: 42 Identity Design Standard
///
/// 42 브랜드 색상 (#00BABC teal/cyan)을 주요 디자인 요소로 사용
class AppTheme {
  // 42 브랜드 색상
  static const Color primary42 = Color(0x00BABC);
  static const Color primary42Light = Color(0xFFD4F1F4);
  static const Color primary42Dark = Color(0xFF008B8B);

  // 보조 색상
  static const Color secondary = Color(0xFF03DAC6);
  static const Color error = Color(0xFFCF6679);
  static const Color success = Color(0xFF4CAF50);
  static const Color warning = Color(0xFFFFA726);

  // 중립 색상
  static const Color background = Color(0xFFFAFAFA);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onSurface = Color(0xFF000000);

  /// 라이트 테마
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // 색상 스키마
      colorScheme: ColorScheme.light(
        primary: primary42,
        primaryContainer: primary42Light,
        secondary: secondary,
        error: error,
        surface: surface,
        onPrimary: onPrimary,
        onSurface: onSurface,
      ),

      // 앱바 테마
      appBarTheme: AppBarTheme(
        backgroundColor: primary42,
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          color: onPrimary,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),

      // 카드 테마
      cardTheme: CardTheme(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        margin: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      ),

      // 버튼 테마
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary42,
          foregroundColor: onPrimary,
          elevation: 2,
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primary42,
          side: BorderSide(color: primary42, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),

      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primary42,
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),

      // 입력 필드 테마
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Color(0xFFF5F5F5),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primary42, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: error, width: 1.5),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),

      // 칩 테마
      chipTheme: ChipThemeData(
        backgroundColor: primary42Light,
        selectedColor: primary42,
        labelStyle: TextStyle(color: onSurface),
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // 플로팅 액션 버튼
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary42,
        foregroundColor: onPrimary,
        elevation: 4,
      ),

      // 바텀 네비게이션
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary42,
        unselectedItemColor: Colors.grey,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),

      // 스낵바
      snackBarTheme: SnackBarThemeData(
        backgroundColor: onSurface,
        contentTextStyle: TextStyle(color: surface),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),

      // 다이얼로그
      dialogTheme: DialogTheme(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),

      // 텍스트 테마
      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
        displayMedium: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
        displaySmall: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        headlineLarge: TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
        headlineMedium: TextStyle(fontSize: 20, fontWeight: FontWeight.w600),
        headlineSmall: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        titleLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        titleMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        titleSmall: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        bodyLarge: TextStyle(fontSize: 16, fontWeight: FontWeight.normal),
        bodyMedium: TextStyle(fontSize: 14, fontWeight: FontWeight.normal),
        bodySmall: TextStyle(fontSize: 12, fontWeight: FontWeight.normal),
        labelLarge: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        labelMedium: TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        labelSmall: TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  /// 다크 테마
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: ColorScheme.dark(
        primary: primary42,
        primaryContainer: primary42Dark,
        secondary: secondary,
        error: error,
        surface: Color(0xFF121212),
        onPrimary: onPrimary,
        onSurface: Color(0xFFE0E0E0),
      ),

      // 다크 테마는 라이트 테마를 기본으로 하고 색상만 조정
      appBarTheme: AppBarTheme(
        backgroundColor: Color(0xFF1E1E1E),
        foregroundColor: onPrimary,
        elevation: 0,
        centerTitle: true,
      ),

      cardTheme: CardTheme(
        color: Color(0xFF1E1E1E),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}
