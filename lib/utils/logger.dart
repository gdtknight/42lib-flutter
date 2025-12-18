import 'package:logger/logger.dart';

/// 로깅 유틸리티
class AppLogger {
  static final Logger _logger = Logger(
    printer: PrettyPrinter(methodCount: 0, colors: true),
  );
  
  static void debug(String message) => _logger.d(message);
  static void info(String message) => _logger.i(message);
  static void warning(String message) => _logger.w(message);
  static void error(String message, [dynamic error]) => _logger.e(message, error: error);
}
