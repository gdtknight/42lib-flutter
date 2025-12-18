import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

/// 플랫폼 감지 유틸리티
class PlatformDetector {
  static bool get isWeb => kIsWeb;
  static bool get isIOS => !kIsWeb && Platform.isIOS;
  static bool get isAndroid => !kIsWeb && Platform.isAndroid;
  static bool get isMobile => isIOS || isAndroid;
  static bool get isDesktop => !kIsWeb && !isMobile;

  static String get platformName {
    if (isWeb) return 'Web';
    if (isIOS) return 'iOS';
    if (isAndroid) return 'Android';
    return 'Desktop';
  }
}
