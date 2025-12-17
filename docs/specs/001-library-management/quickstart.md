# 빠른 시작 가이드: 42 도서 관리 시스템

**브랜치**: `001-library-management` | **날짜**: 2025-12-17 | **단계**: 1 - 설계

## 개요

이 가이드는 42 도서 관리 시스템의 빠른 설정 및 개발 워크플로우를 제공합니다. 시스템은 Flutter 크로스플랫폼 앱(iOS, Android, Web)과 Node.js 백엔드 API로 구성됩니다.

---

## 사전 요구사항

- **Docker** (v20.10+) 및 **Docker Compose** (v2.0+)
- **Git** (v2.30+)
- **VS Code** (권장) + Remote-Containers 확장
- **42 API 인증 정보** (OAuth 클라이언트 ID 및 시크릿)

**참고**: 헌법 VIII에 따라 모든 개발은 Docker 컨테이너 내부에서 진행됩니다. Flutter, Node.js, PostgreSQL의 로컬 설치가 필요하지 않습니다.

---

## 빠른 설정 (5분)

### 1. 저장소 클론

```bash
git clone git@github.com:gdtknight/42lib-flutter.git
cd 42lib-flutter
git checkout 001-library-management
```

### 2. 환경 설정

예제 환경 파일을 복사하고 42 API 인증 정보로 업데이트합니다:

```bash
# 백엔드 API 설정
cp backend/.env.example backend/.env

# backend/.env를 42 OAuth 인증 정보로 수정
# FORTYTWO_CLIENT_ID=your_client_id
# FORTYTWO_CLIENT_SECRET=your_client_secret
# FORTYTWO_REDIRECT_URI=http://localhost:3000/api/v1/auth/42/callback
```

### 3. Docker 환경 시작

```bash
# 모든 컨테이너 빌드 및 시작
docker-compose up -d

# 모든 서비스 실행 확인
docker-compose ps
```

**예상 서비스**:
- `flutter-dev`: Flutter 개발 환경 (포트 8080)
- `backend-api`: Node.js Express API 서버 (포트 3000)
- `postgres-db`: PostgreSQL 데이터베이스 (포트 5432)

### 4. 데이터베이스 초기화

```bash
# 데이터베이스 마이그레이션 실행
docker-compose exec backend-api npm run migrate

# 초기 데이터 시드 (선택사항)
docker-compose exec backend-api npm run seed
```

### 5. 애플리케이션 접속

- **모바일 앱 (웹 미리보기)**: http://localhost:8080
- **관리자 대시보드 (웹)**: http://localhost:8080/admin
- **백엔드 API**: http://localhost:3000/api/v1
- **API 문서**: http://localhost:3000/api-docs (Swagger UI)

---

## 개발 워크플로우

### Flutter 앱 개발

```bash
# Flutter 컨테이너 접속
docker-compose exec flutter-dev bash

# 웹 개발 서버 실행
flutter run -d web-server --web-port 8080 --web-hostname 0.0.0.0

# 또는 특정 플랫폼용 빌드
flutter build apk      # Android
flutter build ios      # iOS (macOS에서만)
flutter build web      # Web
```

### 백엔드 API 개발

```bash
# 백엔드 컨테이너 접속
docker-compose exec backend-api bash

# 개발 모드 실행 (핫 리로드)
npm run dev

# 테스트 실행
npm test

# 데이터베이스 마이그레이션 생성
npm run migration:create -- migration_name
```

### 일반적인 작업

#### 패키지 의존성 추가

**Flutter**:
```bash
docker-compose exec flutter-dev bash
flutter pub add package_name
flutter pub get
```

**Backend**:
```bash
docker-compose exec backend-api bash
npm install package_name
```

#### 로그 확인

```bash
# 모든 서비스 로그
docker-compose logs -f

# 특정 서비스 로그
docker-compose logs -f flutter-dev
docker-compose logs -f backend-api
```

#### 데이터베이스 접속

```bash
# PostgreSQL CLI 접속
docker-compose exec postgres-db psql -U library_user -d library_db

# 또는 pgAdmin 사용 (http://localhost:5050)
```

---

## 테스팅

### Flutter 테스트

```bash
docker-compose exec flutter-dev bash

# 단위 테스트
flutter test

# 커버리지 포함 테스트
flutter test --coverage

# 통합 테스트
flutter drive --target=test_driver/app.dart
```

### 백엔드 테스트

```bash
docker-compose exec backend-api bash

# 전체 테스트 스위트
npm test

# 특정 테스트 파일
npm test -- tests/books.test.js

# 커버리지 리포트
npm run test:coverage
```

---

## 문제 해결

### 컨테이너가 시작되지 않음

```bash
# 컨테이너 재시작
docker-compose restart

# 완전히 재빌드
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### 데이터베이스 연결 오류

```bash
# 데이터베이스 서비스 상태 확인
docker-compose ps postgres-db

# 데이터베이스 로그 확인
docker-compose logs postgres-db

# 데이터베이스 재시작
docker-compose restart postgres-db
```

### Flutter 핫 리로드 작동 안 함

```bash
# Flutter 캐시 정리
docker-compose exec flutter-dev flutter clean
docker-compose exec flutter-dev flutter pub get

# 개발 서버 재시작
```

### 포트 충돌

로컬에서 이미 포트를 사용 중인 경우 `docker-compose.yml`에서 포트 매핑을 변경하세요:

```yaml
services:
  flutter-dev:
    ports:
      - "8081:8080"  # 8080 대신 8081 사용
```

---

## 일반적인 개발 시나리오

### 새로운 API 엔드포인트 추가

1. `backend/src/routes/`에 라우트 정의 추가
2. `backend/src/controllers/`에 컨트롤러 로직 작성
3. `backend/src/models/`에 데이터 모델 업데이트 (필요시)
4. `backend/tests/`에 테스트 작성
5. `specs/001-library-management/contracts/openapi.yaml` 업데이트

### 새로운 Flutter 화면 추가

1. `lib/presentation/screens/`에 화면 위젯 생성
2. `lib/presentation/blocs/`에 BLoC 생성 (상태 관리)
3. `lib/domain/entities/`에 도메인 엔티티 정의
4. `lib/data/repositories/`에 저장소 구현
5. `test/`에 단위 테스트 작성

### 데이터베이스 스키마 변경

1. 마이그레이션 생성:
   ```bash
   docker-compose exec backend-api npm run migration:create -- add_column_to_books
   ```
2. `backend/migrations/XXXXXX-add_column_to_books.js` 편집
3. 마이그레이션 실행:
   ```bash
   docker-compose exec backend-api npm run migrate
   ```
4. 모델 파일 업데이트 (`backend/src/models/`)

---

## 추가 리소스

- **API 문서**: http://localhost:3000/api-docs
- **프로젝트 명세서**: `docs/specs/001-library-management/spec.md`
- **데이터 모델**: `docs/specs/001-library-management/data-model.md`
- **기술 조사**: `docs/specs/001-library-management/research.md`
- **Docker 가이드**: `docs/processes/docker-guide.md`

---

**다음 단계**: 작업 목록 생성 (`/speckit.tasks`)
