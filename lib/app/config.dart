/// 환경 설정 관리
class AppConfig {
  static const String appName = '42lib';
  static const String apiBaseUrl = 'http://localhost:3000/api';
  static const String oauth42AuthUrl =
      'https://api.intra.42.fr/oauth/authorize';
  static const String oauth42TokenUrl = 'https://api.intra.42.fr/oauth/token';

  // 환경별 설정
  static bool get isDevelopment =>
      const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction => !isDevelopment;

  /// 앱 초기화 (향후 환경변수 로딩 등 추가 가능)
  static Future<void> initialize() async {
    // 현재는 추가 초기화 작업 없음
    // 향후 .env 파일 로딩 등 추가 가능
  }
}
