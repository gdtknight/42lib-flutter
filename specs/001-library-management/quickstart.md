# Quickstart Guide: 42 Library Management System

**Branch**: `001-library-management` | **Date**: 2025-12-17 | **Phase**: 1 - Design

## Overview

This guide provides a quick setup and development workflow for the 42 Library Management System. The system consists of a Flutter cross-platform app (iOS, Android, Web) and a Node.js backend API.

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
git checkout 001-library-management
```

### 2. Configure Environment

Copy example environment files and update with your 42 API credentials:

```bash
# Backend API configuration
cp backend/.env.example backend/.env

# Edit backend/.env with your 42 OAuth credentials
# FORTYTWO_CLIENT_ID=your_client_id
# FORTYTWO_CLIENT_SECRET=your_client_secret
# FORTYTWO_REDIRECT_URI=http://localhost:3000/api/v1/auth/42/callback
```

### 3. Start Docker Environment

```bash
# Build and start all containers
docker-compose up -d

# Verify all services are running
docker-compose ps
```

**Expected Services**:
- `flutter-dev`: Flutter development environment (port 8080)
- `backend-api`: Node.js Express API server (port 3000)
- `postgres-db`: PostgreSQL database (port 5432)

### 4. Initialize Database

```bash
# Run database migrations
docker-compose exec backend-api npm run migrate

# Seed initial data (optional)
docker-compose exec backend-api npm run seed
```

### 5. Access Applications

- **Mobile App (Web Preview)**: http://localhost:8080
- **Admin Dashboard (Web)**: http://localhost:8080/admin
- **Backend API**: http://localhost:3000/api/v1
- **API Documentation**: http://localhost:3000/api-docs (Swagger UI)

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

**Code Generation** (for Bloc, Mockito, etc.):
```bash
docker-compose exec flutter-dev flutter pub run build_runner build --delete-conflicting-outputs
```

**Format Code**:
```bash
docker-compose exec flutter-dev flutter format lib/ test/
```

**Analyze Code**:
```bash
docker-compose exec flutter-dev flutter analyze
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

**Mock 42 API** (for local development):
```bash
# Use test credentials in .env
FORTYTWO_CLIENT_ID=test_client_id
FORTYTWO_CLIENT_SECRET=test_client_secret
MOCK_42_API=true  # Bypasses actual 42 API
```

**Test with Real 42 API**:
1. Register OAuth app at https://profile.intra.42.fr/oauth/applications
2. Set redirect URI: `http://localhost:3000/api/v1/auth/42/callback`
3. Update `.env` with real credentials
4. Test login flow in mobile app

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

**Unit Tests** (60% coverage target):
```bash
# Flutter unit tests
docker-compose exec flutter-dev flutter test test/unit_test/

# Backend unit tests
docker-compose exec backend-api npm test -- --testPathPattern=unit
```

**Widget Tests** (30% coverage target):
```bash
docker-compose exec flutter-dev flutter test test/widget_test/
```

**Integration Tests** (10% coverage target):
```bash
# Full user flows
docker-compose exec flutter-dev flutter test integration_test/
```

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

## Next Steps

1. ✅ Review this quickstart guide
2. ✅ Verify Docker environment setup
3. ✅ Explore API documentation (Swagger UI at http://localhost:3000/api-docs)
4. ⏭️ Proceed to **Phase 2: Task Generation** (`/speckit.tasks` command)
5. ⏭️ Start implementing User Story 1 (Book browsing - P1)

**Ready to Code!** 🚀

---

## Changelog

| Version | Date | Changes |
|---------|------|---------|
| 1.0.0 | 2025-12-17 | Initial quickstart guide created (Phase 1) |
