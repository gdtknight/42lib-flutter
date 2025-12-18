# 플랫폼 빌드 검증 가이드

**작성일**: 2025-12-17  
**Constitution 원칙**: IX. Flutter Cross-Platform Compatibility

---

## 개요

42lib-flutter는 iOS, Android, Web 3개 플랫폼을 지원하며, 각 플랫폼의 최신 버전-1 및 이전 3개 버전 호환성을 보장합니다.

---

## 지원 플랫폼 및 버전

### iOS (4개 버전)
- **iOS 17**: 최신 버전
- **iOS 16**: 최신-1
- **iOS 15**: 이전 2
- **iOS 14**: 이전 3

**최소 요구 버전**: iOS 14.0  
**Target SDK**: iOS 17.0

### Android (4개 버전)
- **Android 14 (API 34)**: 최신 버전
- **Android 13 (API 33)**: 최신-1
- **Android 12 (API 31)**: 이전 2
- **Android 11 (API 30)**: 이전 3

**최소 SDK 버전**: API 30 (Android 11)  
**Target SDK**: API 34 (Android 14)

### Web
- **Chrome** (최신 2개 버전)
- **Safari** (최신 2개 버전)
- **Firefox** (최신 2개 버전)
- **Edge** (최신 2개 버전)

---

## Flutter 프로젝트 설정

### pubspec.yaml
```yaml
environment:
  sdk: ">=3.0.0 <4.0.0"

flutter:
  # iOS/Android/Web 지원
  platforms:
    ios:
      deployment_target: 14.0
    android:
      min_sdk_version: 30
      target_sdk_version: 34
    web:
      renderer: canvaskit
```

---

## iOS 빌드 검증 (T009)

### 필수 파일
- `ios/Podfile`: CocoaPods 의존성
- `ios/Runner.xcodeproj`: Xcode 프로젝트
- `ios/Runner/Info.plist`: iOS 앱 설정

### 설정 확인
```ruby
# ios/Podfile
platform :ios, '14.0'
```

### 검증 명령
```bash
# Docker 환경 내부
flutter doctor -v
flutter build ios --release --no-codesign

# 또는 Xcode 시뮬레이터
flutter run -d iPhone
```

### 호환성 테스트
- iOS 14.0 시뮬레이터에서 앱 실행
- iOS 17.0 시뮬레이터에서 앱 실행
- 주요 기능 동작 확인

---

## Android 빌드 검증 (T010)

### 필수 파일
- `android/app/build.gradle`: Android 빌드 설정
- `android/app/src/main/AndroidManifest.xml`: 앱 매니페스트

### 설정 확인
```gradle
// android/app/build.gradle
android {
    compileSdkVersion 34
    
    defaultConfig {
        minSdkVersion 30
        targetSdkVersion 34
    }
}
```

### 검증 명령
```bash
# Docker 환경 내부
flutter doctor -v
flutter build apk --release

# 또는 Android 에뮬레이터
flutter run -d emulator-5554
```

### 호환성 테스트
- Android 11 (API 30) 에뮬레이터에서 앱 실행
- Android 14 (API 34) 에뮬레이터에서 앱 실행
- 주요 기능 동작 확인

---

## Web 빌드 검증 (T011)

### 필수 파일
- `web/index.html`: 웹 진입점
- `web/manifest.json`: PWA 매니페스트

### 설정 확인
```html
<!-- web/index.html -->
<!DOCTYPE html>
<html>
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>42lib - 도서 관리 시스템</title>
</head>
<body>
  <script src="main.dart.js" type="application/javascript"></script>
</body>
</html>
```

### 검증 명령
```bash
# Docker 환경 내부
flutter build web --release

# 개발 서버 실행
flutter run -d web-server --web-port=8080

# http://localhost:8080 접속
```

### 브라우저 호환성 테스트
- Chrome (최신 버전)
- Safari (macOS)
- Firefox (최신 버전)
- Edge (최신 버전)

### 반응형 테스트
- Desktop (1920x1080)
- Tablet (768x1024)
- Mobile (375x667)

---

## CI/CD 플랫폼 검증

### GitHub Actions 워크플로우

```yaml
name: Platform Build Verification

on: [push, pull_request]

jobs:
  ios-build:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build ios --release --no-codesign
  
  android-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: actions/setup-java@v3
        with:
          distribution: 'zulu'
          java-version: '17'
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build apk --release
  
  web-build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v3
      - uses: subosito/flutter-action@v2
        with:
          flutter-version: '3.16.0'
      - run: flutter pub get
      - run: flutter build web --release
```

---

## 플랫폼별 주의사항

### iOS
- **42 OAuth 리다이렉트**: Custom URL Scheme 설정 필요
- **권한 요청**: Info.plist에 NSCameraUsageDescription 등 설정
- **App Store 제출**: Apple Developer Program 필요

### Android
- **42 OAuth 리다이렉트**: Deep Link 설정 (AndroidManifest.xml)
- **권한 요청**: uses-permission 태그 설정
- **Google Play 배포**: Signing Key 관리

### Web
- **OAuth 리다이렉트**: CORS 설정 필요
- **브라우저 저장소**: LocalStorage 사용 (Hive 대신)
- **PWA 지원**: Service Worker 및 Manifest 설정

---

## 호환성 매트릭스

| 플랫폼 | 최소 버전 | 권장 버전 | 최신 버전 | 테스트 완료 |
|--------|-----------|-----------|-----------|-------------|
| iOS    | 14.0      | 16.0      | 17.0      | ⏳ 대기     |
| Android| API 30    | API 33    | API 34    | ⏳ 대기     |
| Web    | ES6       | ES2020    | ES2023    | ⏳ 대기     |

---

## 다음 단계

### Setup Phase 완료 후
1. Flutter 프로젝트 완전 초기화
2. iOS/Android/Web 빌드 실제 검증
3. 플랫폼별 설정 파일 추가
4. CI/CD 파이프라인 통합

### Foundational Phase
1. 각 플랫폼에서 42 OAuth 테스트
2. 플랫폼별 UI/UX 검증
3. 성능 벤치마크 (FR-027)

---

**참고 문서**:
- Constitution 원칙 IX: Flutter Cross-Platform Compatibility
- [Flutter 플랫폼 지원 문서](https://docs.flutter.dev/platform-integration)
- [iOS 버전 지원 정책](https://developer.apple.com/support/app-store/)
- [Android API 레벨](https://developer.android.com/tools/releases/platforms)
