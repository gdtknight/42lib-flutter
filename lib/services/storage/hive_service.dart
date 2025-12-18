import 'package:hive_flutter/hive_flutter.dart';

/// Hive 기반 Key-Value 스토리지 서비스
/// Constitution 원칙 IX: 크로스플랫폼 호환성 (iOS, Android, Web)
/// 
/// 빠른 읽기/쓰기가 필요한 간단한 데이터 저장
/// 예: 사용자 설정, 캐시, 임시 데이터
class HiveService {
  static const String _settingsBox = 'settings';
  static const String _cacheBox = 'cache';
  
  /// 초기화
  static Future<void> initialize() async {
    await Hive.initFlutter();
    
    // 박스 열기
    await Hive.openBox(_settingsBox);
    await Hive.openBox(_cacheBox);
  }
  
  /// 설정 박스 가져오기
  static Box get _settings => Hive.box(_settingsBox);
  
  /// 캐시 박스 가져오기
  static Box get _cache => Hive.box(_cacheBox);
  
  // ========================================
  // 설정 관련 메서드
  // ========================================
  
  /// 설정 저장
  static Future<void> saveSetting(String key, dynamic value) async {
    await _settings.put(key, value);
  }
  
  /// 설정 가져오기
  static T? getSetting<T>(String key, {T? defaultValue}) {
    return _settings.get(key, defaultValue: defaultValue) as T?;
  }
  
  /// 설정 삭제
  static Future<void> deleteSetting(String key) async {
    await _settings.delete(key);
  }
  
  /// 모든 설정 삭제
  static Future<void> clearSettings() async {
    await _settings.clear();
  }
  
  // ========================================
  // 캐시 관련 메서드
  // ========================================
  
  /// 캐시 저장
  static Future<void> cacheData(String key, dynamic value) async {
    await _cache.put(key, value);
  }
  
  /// 캐시 가져오기
  static T? getCachedData<T>(String key) {
    return _cache.get(key) as T?;
  }
  
  /// 캐시 삭제
  static Future<void> deleteCache(String key) async {
    await _cache.delete(key);
  }
  
  /// 모든 캐시 삭제
  static Future<void> clearCache() async {
    await _cache.clear();
  }
  
  // ========================================
  // 유틸리티 메서드
  // ========================================
  
  /// 박스 크기 확인
  static int getBoxSize(String boxName) {
    if (boxName == _settingsBox) {
      return _settings.length;
    } else if (boxName == _cacheBox) {
      return _cache.length;
    }
    return 0;
  }
  
  /// 모든 데이터 삭제 (설정 + 캐시)
  static Future<void> clearAll() async {
    await clearSettings();
    await clearCache();
  }
  
  /// 정리 (앱 종료 시)
  static Future<void> dispose() async {
    await _settings.close();
    await _cache.close();
  }
}
