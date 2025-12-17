# Docker 개발 환경 사용 가이드

## 시작하기

### 1. Docker 이미지 빌드
```bash
docker-compose build
```

### 2. 개발 컨테이너 시작
```bash
docker-compose up -d
```

### 3. 컨테이너 접속
```bash
docker-compose exec flutter-dev bash
```

### 4. Flutter 프로젝트 초기화 (최초 1회)
```bash
# 컨테이너 내부에서 실행
flutter create --org com.fortytwo --platforms=ios,android,web .
flutter pub get
```

## 일반적인 작업

### Flutter 명령어 실행
```bash
# 컨테이너 내부에서
flutter doctor
flutter pub get
flutter test
flutter analyze
```

### Web 개발 서버 실행
```bash
# 컨테이너 내부에서
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0
```
브라우저에서 `http://localhost:8080` 접속

### 컨테이너 중지
```bash
docker-compose down
```

## 볼륨 관리

프로젝트는 다음 볼륨을 사용합니다:
- `flutter-pub-cache`: Dart 패키지 캐시
- `flutter-gradle-cache`: Android Gradle 캐시

### 캐시 초기화 (필요시)
```bash
docker-compose down -v
docker-compose up -d
```

## 포트

- **8080**: Flutter Web 개발 서버
- **9100**: Flutter DevTools

## 문제 해결

### Permission 문제
```bash
# 호스트에서 실행
sudo chown -R $USER:$USER .
```

### 컨테이너 재시작
```bash
docker-compose restart
```

### 로그 확인
```bash
docker-compose logs -f flutter-dev
```
