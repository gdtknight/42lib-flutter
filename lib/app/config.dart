/// 환경 설정 관리
class AppConfig {
  static const String appName = '42lib';

  /// 백엔드 API base URL.
  ///
  /// 빌드 시 `--dart-define=API_BASE_URL=...` 로 override 가능.
  /// 기본값은 웹 개발 환경 (호스트의 localhost:3000).
  ///
  /// 예시:
  /// - Web/iOS Simulator: 기본값 사용
  /// - Android Emulator: `--dart-define=API_BASE_URL=http://10.0.2.2:3000/api`
  /// - 실 디바이스: `--dart-define=API_BASE_URL=http://<host-ip>:3000/api`
  /// - Production: `--dart-define=API_BASE_URL=https://api.example.com/api`
  static const String apiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:3000/api',
  );

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
