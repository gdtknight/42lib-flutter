# 로컬 개발 환경과 CI/CD 환경 동등성 보장

## 목적

로컬 개발 환경과 GitHub Actions CI/CD 환경의 완전한 동등성을 보장하여 "works on my machine" 문제를 방지합니다.

## 환경 사양

### 공통 사양

| 항목 | 버전/설정 | 비고 |
|------|----------|------|
| **Flutter** | 3.24.0 | Stable channel |
| **Dart** | 3.5.x | Flutter 3.24.0에 포함 |
| **Base OS** | Ubuntu 24.04 | 로컬: Docker, CI: GitHub Runner |
| **Java** | OpenJDK 17 | Android 빌드용 |

### 로컬 환경 (Docker)

**파일**: `docker/Dockerfile`, `docker/docker-compose.yml`

```dockerfile
FROM ubuntu:24.04
ENV FLUTTER_VERSION=3.24.0
RUN git clone https://github.com/flutter/flutter.git -b ${FLUTTER_VERSION} /opt/flutter
```

**실행 방법**:
```bash
cd docker
docker-compose up -d
docker-compose exec flutter-dev flutter --version
```

### CI/CD 환경 (GitHub Actions)

**파일**: `.github/workflows/ci.yml`

```yaml
- name: Flutter 설정
  uses: subosito/flutter-action@v2
  with:
    flutter-version: '3.24.0'
    channel: 'stable'
    cache: true
```

## 환경 검증

### 1. Flutter 버전 확인

**로컬**:
```bash
docker-compose exec flutter-dev flutter --version
```

**CI/CD**:
GitHub Actions 로그에서 "Flutter 설정" 단계 확인

**기대 결과**:
```
Flutter 3.24.0 • channel stable
Framework • revision ...
Engine • revision ...
Tools • Dart 3.5.x • DevTools ...
```

### 2. Dart 버전 확인

**로컬**:
```bash
docker-compose exec flutter-dev dart --version
```

**기대 결과**:
```
Dart SDK version: 3.5.x
```

### 3. 의존성 확인

**로컬**:
```bash
docker-compose exec flutter-dev flutter pub get
docker-compose exec flutter-dev flutter pub outdated
```

**CI/CD**:
GitHub Actions "의존성 설치" 단계 로그 확인

### 4. 플랫폼 지원 확인

**로컬**:
```bash
docker-compose exec flutter-dev flutter doctor -v
```

**기대 출력**:
```
[✓] Flutter (Channel stable, 3.24.0, on Linux, locale ko_KR.UTF-8)
[✓] Android toolchain - develop for Android devices
[✓] Chrome - develop for the web
[!] Linux toolchain - develop for Linux desktop (not required)
[!] Connected device (not required for Docker)
```

## 환경 불일치 감지 및 대응

### 자동 감지

`scripts/check-env-parity.sh` 스크립트 실행:

```bash
#!/bin/bash
# 로컬 Flutter 버전 확인
LOCAL_VERSION=$(docker-compose -f docker/docker-compose.yml exec -T flutter-dev flutter --version | head -1)

# CI Flutter 버전 확인 (ci.yml 파싱)
CI_VERSION=$(grep "flutter-version:" .github/workflows/ci.yml | head -1 | awk '{print $2}' | tr -d "'")

echo "로컬: $LOCAL_VERSION"
echo "CI:   Flutter $CI_VERSION"

if [[ "$LOCAL_VERSION" != *"$CI_VERSION"* ]]; then
  echo "❌ 환경 불일치 감지!"
  exit 1
fi

echo "✅ 환경 일치 확인"
```

### 불일치 발생 시 대응

**증상**:
- 로컬에서는 통과하지만 CI에서 실패
- 로컬에서는 실패하지만 CI에서 통과
- 빌드 결과물 차이

**원인 분석**:
1. Flutter/Dart 버전 차이
2. 의존성 버전 차이
3. 플랫폼별 차이 (macOS vs Linux)

**해결 방법**:

**1단계: 버전 확인**
```bash
# 로컬
docker-compose exec flutter-dev flutter --version

# CI 로그 확인
gh run view <run-id> --log
```

**2단계: Docker 이미지 재빌드** (버전 불일치 시)
```bash
cd docker
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

**3단계: 의존성 갱신**
```bash
docker-compose exec flutter-dev flutter pub upgrade
docker-compose exec flutter-dev flutter pub get
```

**4단계: 재검증**
```bash
./scripts/local-verify.sh
```

## 환경 동기화 체크리스트

- [ ] Flutter 버전 일치 (로컬 Docker == CI/CD)
- [ ] Dart 버전 일치
- [ ] Base OS 일치 (Ubuntu 24.04)
- [ ] Java 버전 일치 (OpenJDK 17)
- [ ] pubspec.lock 커밋 및 동기화
- [ ] Docker 이미지 최신 상태
- [ ] CI/CD 워크플로우 최신 상태

## 주기적 점검

### 월간 점검 (매월 1일)

1. Flutter 최신 stable 버전 확인
2. 로컬 Docker 이미지 업데이트 필요 여부 확인
3. CI/CD 워크플로우 업데이트 필요 여부 확인
4. 의존성 보안 업데이트 확인

### 즉시 업데이트가 필요한 경우

- Flutter 보안 패치 릴리스
- 주요 의존성 보안 취약점 발견
- CI/CD 환경에서 반복적인 실패 발생

## 참고 자료

- [Flutter 버전 관리](https://docs.flutter.dev/release/archive)
- [GitHub Actions Flutter Setup](https://github.com/marketplace/actions/flutter-action)
- [Docker Best Practices](https://docs.docker.com/develop/dev-best-practices/)

## 변경 이력

| 날짜 | 버전 | 변경 내용 |
|------|------|-----------|
| 2025-12-18 | 1.0.0 | 초기 문서 작성, Flutter 3.24.0 동기화 |
