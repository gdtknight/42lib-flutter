/// 환경 설정 관리
class AppConfig {
  static const String appName = '42lib';
  static const String apiBaseUrl = 'http://localhost:3000/api/v1';
  static const String oauth42AuthUrl = 'https://api.intra.42.fr/oauth/authorize';
  static const String oauth42TokenUrl = 'https://api.intra.42.fr/oauth/token';
  
  // 환경별 설정
  static bool get isDevelopment => const bool.fromEnvironment('dart.vm.product') == false;
  static bool get isProduction => !isDevelopment;
}
