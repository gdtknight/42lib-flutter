# Quickstart Guide: 42 Library Management System

**Last validated**: v0.6.0 (T236) | **Original**: 2025-12-17 (Phase 1)

> **검증 리포트**: 이 quickstart는 v0.6.0 시점에 [T236 검증 리포트](../../docs/guides/quickstart-validation-report.md)를 통해 갱신되었습니다. Phase 1 시점의 노후 사항 (Swagger UI URL 오류, deprecated Flutter 명령, 존재하지 않는 `MOCK_42_API` 등)이 정정되었습니다.

## Overview

This guide provides a quick setup and development workflow for the 42 Library Management System. The system consists of a Flutter cross-platform app (iOS, Android, Web) and a Node.js backend API.

상세한 운영·사용 가이드는 별도로 정리되어 있습니다:
- 배포: [`docs/guides/deployment.md`](../../docs/guides/deployment.md)
- 42 OAuth 등록: [`docs/guides/42-oauth-setup.md`](../../docs/guides/42-oauth-setup.md)
- DB 백업/복원: [`docs/guides/database-backup-restore.md`](../../docs/guides/database-backup-restore.md)
- CI/CD 동작: [`docs/guides/ci-cd-pipeline.md`](../../docs/guides/ci-cd-pipeline.md)
- 학생 사용: [`docs/guides/user-guide.md`](../../docs/guides/user-guide.md)
- 관리자 사용: [`docs/guides/admin-guide.md`](../../docs/guides/admin-guide.md)

---

## Prerequisites

- **Docker** (v20.10+) and **Docker Compose** (v2.0+)
- **Git** (v2.30+)
- **VS Code** (recommended) with Remote-Containers extension
- **42 API Credentials** (OAuth client ID and secret)

**Note**: All development happens inside Docker containers per Constitution VIII. No local installation of Flutter, Node.js, or PostgreSQL required.

---

## Quick Setup (5 minutes)

### 1. Clone Repository

```bash
git clone git@github.com:gdtknight/42lib-flutter.git
cd 42lib-flutter
git checkout v0.6.0   # 안정 태그 권장 (또는 dev 최신)
```

### 2. Configure Environment

```bash
cp backend/.env.example backend/.env
# 파일 주석을 따라 필수 항목(JWT_SECRET, FORTYTWO_*) 채우기
# 자세한 OAuth 발급: docs/guides/42-oauth-setup.md
```

> Docker Compose는 `backend/.env`가 없어도 docker-compose.yml의 기본값으로 부팅됩니다 (개발 편의). 운영은 반드시 명시 주입.

### 3. Start Docker Environment

```bash
# Makefile (권장)
make up
make status

# 또는 raw 명령
docker compose -f docker/docker-compose.yml up -d
docker compose -f docker/docker-compose.yml ps
```

**Expected Services**:
- `flutter-dev`: Flutter web 개발 서버 (port 8080)
- `backend-api`: Node.js + Express API (port 3000)
- `postgres-db`: PostgreSQL 16 (port 5432)
- `redis-cache`: Redis 7 (port 6379, **현재 코드 미사용** — 예약)

### 4. Initialize Database

```bash
# 마이그레이션
make db-migrate
# 또는: docker compose -f docker/docker-compose.yml exec backend-api npx prisma migrate deploy

# 시드 (선택; 운영에서는 보통 skip)
docker compose -f docker/docker-compose.yml exec backend-api npm run seed
```

### 5. Access Applications

| 용도 | URL |
|--|--|
| Flutter 앱 (학생) | http://localhost:8080 |
| 관리자 대시보드 | http://localhost:8080/admin/login |
| Backend API | http://localhost:3000/api/v1 |
| **API 문서 (Swagger UI)** | **http://localhost:3000/api/docs/** |
| 원본 OpenAPI JSON | http://localhost:3000/api/docs/openapi.json |
| Health Check | http://localhost:3000/health |

---

## Development Workflow

### Running Flutter App

**Mobile Preview (Web)**:
```bash
# Hot reload enabled
docker-compose exec flutter-dev flutter run -d web-server --web-port 8080
```

**iOS Simulator** (requires macOS host):
```bash
# Start iOS simulator on host machine
open -a Simulator

# Run app in simulator from Docker
docker-compose exec flutter-dev flutter run -d <device-id>
```

**Android Emulator** (requires Android SDK on host):
```bash
# Start emulator on host
emulator -avd Pixel_5_API_31

# Run app in emulator from Docker
docker-compose exec flutter-dev flutter run -d <device-id>
```

### Backend Development

**Start Backend with Auto-Reload**:
```bash
docker-compose exec backend-api npm run dev
```

**Run Backend Tests**:
```bash
docker-compose exec backend-api npm test
```

**Database Management**:
```bash
# Create new migration
docker-compose exec backend-api npx prisma migrate dev --name <migration_name>

# View database in Prisma Studio
docker-compose exec backend-api npx prisma studio
# Access at http://localhost:5555
```

### Flutter Development

**Run Flutter Tests**:
```bash
# Unit + Widget tests
docker-compose exec flutter-dev flutter test

# Integration tests
docker-compose exec flutter-dev flutter test integration_test/
```

**Code Generation** (for json_serializable, mockito, etc.):
```bash
docker compose -f docker/docker-compose.yml exec flutter-dev \
  dart run build_runner build --delete-conflicting-outputs
```

**Format Code**:
```bash
docker compose -f docker/docker-compose.yml exec flutter-dev dart format .
```

**Analyze Code**:
```bash
docker compose -f docker/docker-compose.yml exec flutter-dev flutter analyze --no-fatal-infos
```

---

## Project Structure

```
42lib-flutter/
├── lib/                    # Flutter application source
│   ├── app/                # App configuration (routes, theme)
│   ├── screens/            # UI screens (mobile & web)
│   ├── widgets/            # Reusable widgets
│   ├── models/             # Data models
│   ├── services/           # Business logic & API clients
│   ├── repositories/       # Data layer abstraction
│   ├── state/              # State management (Bloc)
│   └── platform/           # Platform-specific code
├── test/                   # Flutter tests
│   ├── unit_test/
│   ├── widget_test/
│   └── integration_test/
├── backend/                # Node.js backend API
│   ├── src/
│   │   ├── routes/         # Express routes
│   │   ├── services/       # Business logic
│   │   ├── models/         # Prisma models
│   │   └── middleware/     # Auth, validation
│   ├── prisma/             # Database schema & migrations
│   └── tests/              # Backend tests
├── docker-compose.yml      # Docker orchestration
├── Dockerfile              # Flutter dev container
└── specs/                  # SpecKit documentation
    └── 001-library-management/
        ├── spec.md
        ├── plan.md
        ├── research.md
        ├── data-model.md
        ├── contracts/
        └── quickstart.md (this file)
```

---

## Common Tasks

### Adding a New Flutter Screen

1. **Create screen file**: `lib/screens/mobile/my_screen/my_screen.dart`
2. **Create Bloc** (if needed): `lib/state/my_feature/my_feature_bloc.dart`
3. **Add route**: Update `lib/app/routes.dart`
4. **Add tests**: `test/widget_test/my_screen_test.dart`

### Adding a New API Endpoint

1. **Define route**: `backend/src/routes/my_route.ts`
2. **Create service**: `backend/src/services/my_service.ts`
3. **Update OpenAPI**: `specs/001-library-management/contracts/openapi.yaml`
4. **Add tests**: `backend/tests/my_route.test.ts`
5. **Run migration** (if DB changes): `npx prisma migrate dev`

### Testing 42 OAuth Integration

> **참고**: `MOCK_42_API` 환경 변수는 **존재하지 않습니다** (T236 검증에서 발견된 잔존 문서 오류). 백엔드는 항상 실제 42 API를 호출합니다.

**Unit/integration 테스트에서는** `jest.mock('axios')`로 외부 호출을 차단하는 패턴을 씁니다 (`backend/tests/unit/auth_42_service.test.ts` 참고).

**실제 OAuth 흐름을 로컬에서 검증하려면**:
1. https://profile.intra.42.fr/oauth/applications 에서 dev 전용 앱 등록
2. Redirect URI: `http://localhost:3000/api/v1/auth/42/callback`
3. `backend/.env`에 자격증명 주입
4. 앱 (또는 `curl`)으로 `/api/v1/auth/42/login` 호출 → 인트라 → 콜백

자세한 절차: [`docs/guides/42-oauth-setup.md`](../../docs/guides/42-oauth-setup.md).

---

## Troubleshooting

### Container Won't Start

```bash
# View logs
docker-compose logs <service-name>

# Rebuild containers
docker-compose down
docker-compose build --no-cache
docker-compose up -d
```

### Database Connection Issues

```bash
# Check PostgreSQL is running
docker-compose ps postgres-db

# Reset database (WARNING: deletes all data)
docker-compose exec backend-api npx prisma migrate reset
```

### Flutter Build Errors

```bash
# Clean build cache
docker-compose exec flutter-dev flutter clean
docker-compose exec flutter-dev flutter pub get

# Regenerate code
docker-compose exec flutter-dev flutter pub run build_runner build --delete-conflicting-outputs
```

### Hot Reload Not Working

```bash
# Restart Flutter dev server
docker-compose restart flutter-dev

# Or run with verbose logging
docker-compose exec flutter-dev flutter run -v
```

---

## VS Code Remote Development

**Recommended Setup** for seamless Docker development:

1. **Install Extensions**:
   - Remote - Containers (ms-vscode-remote.remote-containers)
   - Flutter (Dart-Code.flutter)
   - Prisma (Prisma.prisma)

2. **Open in Container**:
   - Press `F1` → "Remote-Containers: Reopen in Container"
   - Select `flutter-dev` container

3. **Benefits**:
   - IntelliSense works inside container
   - Integrated terminal runs in container
   - Extensions (linters, formatters) use container tools
   - No local environment pollution

---

## Testing Strategy

### Test Pyramid

**Spec MVP 목표**: backend + Flutter 모두 lines **80%** (v0.6.0 도달: backend 81.5% / Flutter 80.8%).

```bash
# Flutter — 단위 + 위젯 통합
docker compose -f docker/docker-compose.yml exec flutter-dev flutter test --coverage

# Backend — 단위 + 통합 (실 Postgres)
docker compose -f docker/docker-compose.yml exec backend-api npm run test:coverage
```

CI는 두 측을 병렬로 실행하고 Codecov에 `flutter` / `backend` flag로 분리 추적합니다 (`docs/guides/ci-cd-pipeline.md`).

### Running Specific Tests

```bash
# Single Flutter test file
docker-compose exec flutter-dev flutter test test/unit_test/models/book_test.dart

# Single Backend test suite
docker-compose exec backend-api npm test -- books.test.ts
```

---

## CI/CD Integration

**GitHub Actions** (`.github/workflows/ci.yml`):
- Runs on every PR and push to `dev`
- Executes all tests (Flutter + Backend)
- Builds for iOS, Android, Web platforms
- Validates API contracts against OpenAPI spec
- Checks code formatting and linting

**Quality Gates** (must pass before merge):
- All tests passing
- 80% code coverage
- No linter errors
- Platform builds successful (iOS/Android/Web)

---

## Production Deployment (Future)

**Flutter Mobile** (Phase 2):
- iOS: Build and deploy to App Store via Fastlane
- Android: Build and deploy to Google Play via Gradle

**Flutter Web** (Phase 2):
- Build optimized web bundle
- Deploy to static hosting (Firebase Hosting, Netlify, or AWS S3)

**Backend API** (Phase 2):
- Deploy Docker containers to cloud (AWS ECS, Google Cloud Run, or DigitalOcean)
- Configure PostgreSQL managed instance
- Set up SSL certificates and domain

---

## Performance Monitoring

**Development Metrics** (built-in):
- Flutter DevTools: Performance profiler, widget inspector
- Backend: Request logging with response times
- Database: Prisma query logging

**Success Criteria Validation**:
- SC-001: Book discovery <30s → Manual testing
- SC-002: Search response <1s → Backend request logs
- SC-009: <2s page loads → Flutter DevTools timeline
- SC-011: <10s data sync → Network inspector

---

## Security Notes

**Never Commit**:
- `.env` files with real credentials
- Private keys or certificates
- API secrets

**Secure Storage** (in production):
- 42 OAuth secrets: Environment variables or secrets manager
- JWT signing keys: Rotate monthly
- Database credentials: Managed service or encrypted storage

---

## Getting Help

**Documentation**:
- Feature Spec: `specs/001-library-management/spec.md`
- Data Model: `specs/001-library-management/data-model.md`
- API Contracts: `specs/001-library-management/contracts/openapi.yaml`
- Research Decisions: `specs/001-library-management/research.md`

**Common Commands Reference**:
```bash
# View all running containers
docker-compose ps

# Access Flutter container shell
docker-compose exec flutter-dev /bin/bash

# Access Backend container shell
docker-compose exec backend-api /bin/bash

# View real-time logs
docker-compose logs -f <service-name>

# Stop all services
docker-compose down

# Stop and remove volumes (clean slate)
docker-compose down -v
```

---

## 현재 출하 상태 (v0.6.0)

학생 앱 / 관리자 대시보드 / 백엔드 모두 spec MVP 게이트 통과.

| 영역 | 상태 |
|--|--|
| US1 도서 검색·상세 | ✅ |
| US2 대출·예약 (FIFO 큐, 24h 만료) | ✅ |
| US3 도서 추천 | ✅ |
| US4 카탈로그 관리 | ✅ |
| US5 대출 추적·반납 | ✅ |
| US6 추천 검토 + 수집 기간 + 카탈로그 직행 (T196) | ✅ |
| Phase 11 — 80% 게이트 | ✅ (backend 81.5% / Flutter 80.8%) |
| Phase 12 — 운영 + 사용자 가이드 | ✅ |

자세한 흐름은 [학생 가이드](../../docs/guides/user-guide.md) / [관리자 가이드](../../docs/guides/admin-guide.md).

다음 사이클 후보:
- 푸시 알림 (예약 알림이 현재 미구현)
- ADR 기반 K8s / 클라우드 배포
- 카탈로그 카테고리 필터, 검색 고도화

**Ready to ship!** 🚀

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 2.0.0 | v0.6.0 (T236) | Phase 1 잔재 정리: Swagger UI URL (`/api-docs` → `/api/docs/`), deprecated Flutter 명령 (`flutter format` → `dart format`), 존재하지 않는 `MOCK_42_API` 삭제, 80% 커버리지 목표 명시, 운영/사용자 가이드로 분리. 자세한 발견 사항: [`docs/guides/quickstart-validation-report.md`](../../docs/guides/quickstart-validation-report.md). |
| 1.0.0 | 2025-12-17 | Initial quickstart guide created (Phase 1) |
