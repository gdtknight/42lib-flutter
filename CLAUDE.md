# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Big Picture

This is a **monorepo** with three stacks glued together by Docker Compose:

- **`lib/`** — Flutter app (iOS / Android / Web). Dart SDK `>=3.0.0 <4.0.0`, Flutter 3.24 in CI.
- **`backend/`** — Node.js + Express + TypeScript + Prisma API. Postgres 16 for persistence, Redis 7 for cache.
- **`docker/docker-compose.yml`** — orchestrates `postgres-db`, `redis-cache`, `backend-api`, `flutter-dev` (which auto-runs `flutter run -d web-server` on port 8080).

Constitution VIII mandates that **all development happens inside Docker containers** — do not attempt to run `flutter` or `npm` on the host. Exec into the relevant container instead. The `Makefile` is the canonical entry point; prefer it over raw `docker compose` invocations.

Service URLs: backend `http://localhost:3000` (API at `/api/v1`, health at `/health`), Flutter web `http://localhost:8080`. **Inside** the `flutter-dev` container the API is reachable at `http://backend-api:3000/api/v1` (service name, not `localhost`).

## Commands

### Environment

```bash
make up            # start all services (backend + DB + redis + flutter web)
make down          # stop all services (volumes preserved)
make clean         # stop + remove volumes (destroys DB data; prompts for confirmation)
make status        # docker compose ps
make health        # curl /health, /api/v1/books, frontend
make logs          # follow all services
make web-logs      # follow flutter-dev only
make web-restart
```

### Flutter (run inside `flutter-dev` container via `make flutter-shell`)

```bash
flutter pub get
flutter analyze --no-fatal-infos
dart format --set-exit-if-changed .

flutter test                                      # all tests
flutter test --coverage                           # with lcov
flutter test test/unit_test/models/book_test.dart # single file
flutter test --name "should <expected> when <cond>"  # single test by name

# After changing any model with json_annotation (generates *.g.dart):
dart run build_runner build --delete-conflicting-outputs

flutter build web --release
flutter build apk --release    # MVP-phase local only; not in CI yet
flutter build ios --release --no-codesign
```

### Backend (run inside `backend-api` container via `make backend-shell`)

```bash
npm run dev            # ts-node-dev, auto-restart
npm run build          # tsc
npm test               # jest
npm run test:coverage
npm run migrate        # prisma migrate dev (interactive)
npm run seed
```

Shortcuts: `make db-shell`, `make db-migrate` (runs `prisma migrate deploy`), `make db-reset` (destructive).

### Pre-push verification (Constitution XVI — MANDATORY)

```bash
./scripts/local-verify.sh --mvp-mode              # all platforms (Android + iOS + Web) — required pre-MVP
./scripts/local-verify.sh                         # single platform (default: web) — post-MVP
./scripts/local-verify.sh --skip-build            # fast: analyze + format + tests only
./scripts/local-verify.sh --platform=android
```

Runs analyze, format, unit tests, and platform build(s); writes to `logs/YYYY-MM-DD/verify-*.log`. CI/CD currently only builds web (`.github/workflows/ci.yml`) — iOS/Android build jobs are commented out until v0.1.0. **Local verification is your only guarantee for mobile builds.**

## Flutter Architecture (important — two styles coexist)

The codebase is mid-migration from **layer-first** to **feature-first** organization. Both patterns are currently live:

- **Layer-first (legacy)**: `lib/models/`, `lib/services/`, `lib/state/`, `lib/screens/mobile/{auth,book_detail,home,loan}/`, `lib/repositories/`.
- **Feature-first (new)**: `lib/features/books/{data,domain,presentation}/` (Clean Architecture layering inside a feature).

When touching an existing area, match its current style. When adding a new feature, prefer the `lib/features/<name>/{data,domain,presentation}` layout. Don't opportunistically migrate legacy code — that's its own task.

Cross-cutting:
- **Entry**: `lib/main.dart` → `MaterialApp.router` with `AppRouter.router`.
- **Routing**: `lib/core/routes/app_router.dart` uses `go_router`. The `/books/:id` route reads the `Book` from `state.extra` (passed from the list screen); this is intentional after the recent navigation fix — don't replace it with `Navigator.push`.
- **State management**: `flutter_bloc` (`lib/state/{auth,book,loan}/*_bloc.dart`). Tests use `bloc_test`.
- **HTTP**: `dio` via `lib/services/api/base_api_client.dart`.
- **Persistence**: `hive` + `flutter_secure_storage` + `sqflite` depending on sensitivity.
- **Code generation**: models use `json_serializable`; `*.g.dart` files are committed. Regenerate with `build_runner` after model changes. Generated files are excluded from `analyze` via `analysis_options.yaml`.

## Backend Architecture

- **Entry**: `backend/src/server.ts`.
- **Routes**: `backend/src/routes/{auth,books,loan_requests}.ts`.
- **Services**: `backend/src/services/{auth_42_service,book_service,loan_request_service,reservation_service}.ts`.
- **Persistence**: Prisma (`backend/prisma/schema.prisma`, seed at `backend/prisma/seed.ts`).
- **Auth**: 42 OAuth via `auth_42_service`; JWTs via `jsonwebtoken`. Hardening via `helmet`, `express-rate-limit`, `cors`. Validation via `zod`.

## Project Conventions (from Constitution — `.specify/memory/constitution.md`)

- **Branches (non-negotiable)**: `main` / `dev` / `feature/*` / `fix/*` / `release/*`. Never commit directly to `main` or `dev` — PR only. Default target branch for work is `dev`.
- **Commits**: every commit references an issue: `[#NN] <description>` (or conventional commits with issue footer). Commit messages, PR titles, issue titles, and user-facing docs are in **Korean**. Code identifiers and code comments in English.
- **Issues**: must have specific hierarchical labels (`type:subtype`), a Project, a Milestone, and a linked feature branch in the Development section *before* work begins.
- **SpecKit**: feature specs live in `specs/<NNN-name>/` (currently `001-library-management/`). `plan.md`, `tasks.md`, `contracts/openapi.yaml`, `data-model.md` are the source of truth for what's being built. Check `tasks.md` for task IDs referenced as `T00x` in issues.
- Before starting any non-trivial task: read `.specify/memory/constitution.md`, create a GitHub issue, create a linked `feature/<N>-<slug>` branch.

## Linting specifics

`analysis_options.yaml` enforces:
- `require_trailing_commas: true` — Dart format expects trailing commas on multi-line constructor/function calls.
- `prefer_const_constructors`, `prefer_const_declarations`, `prefer_final_fields`, `prefer_final_locals`.
- `avoid_print: true` — use `logger` package, not `print`.
- `implicit-casts: false`, `implicit-dynamic: false` (strong mode).
- Generated files (`*.g.dart`, `*.freezed.dart`, `*.mocks.dart`) and `test/**` are excluded from analysis.

## Where things live that aren't obvious

- Constitution (project law): `.specify/memory/constitution.md`
- Feature spec / data model / OpenAPI: `specs/001-library-management/`
- ADRs: `docs/decisions/` (create new ones as `NNNN-title.md`)
- Verification logs: `logs/YYYY-MM-DD/`
- SpecKit templates: `.specify/templates/`
- CI workflow: `.github/workflows/ci.yml` (web build only; mobile builds gated on MVP)
