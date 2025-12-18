# Implementation Plan: 42 Learning Space Library Management System

**Branch**: `001-library-management` | **Date**: 2025-12-17 | **Spec**: [spec.md](./spec.md)
**Input**: Feature specification from `/specs/001-library-management/spec.md`
**Project Duration**: 2025-12-17 ~ 2026-01-17 (1 month)
**Milestone**: v0.1.0 - 기초 설정 (Due: 2026-01-17)

**Note**: This template is filled in by the `/speckit.plan` command. See `.specify/templates/commands/plan.md` for the execution workflow.

## Summary

Building a library management system for 42 Learning Space with a Flutter mobile app (iOS/Android) for students to browse ~500-1000 books, search catalog, request loans via 42 API authentication, and submit book suggestions. Web dashboard for administrators to manage catalog (add/edit/remove books), process loan requests, track active loans, and review book suggestions. System designed for 50 concurrent users with real-time synchronization and offline capability.

**Technical Context** *(All items resolved in research.md)*

**Language/Version**: Flutter 3.16.0 (latest stable, production-ready)
**Primary Dependencies**: flutter_bloc (state management), dio (HTTP client), oauth2 (42 API auth), hive + sqflite (hybrid storage)
**Storage**: Local: Hive (key-value) + sqflite (relational) | Remote: Custom REST API (Node.js/Express + PostgreSQL)
**Testing**: flutter_test, integration_test, mockito (80% coverage target)
**Target Platform**: iOS, Android, Web (all three required per Constitution IX)
**iOS Support**: iOS 17, 16, 15, 14 (4 versions per Constitution IX)
**Android Support**: Android 14, 13, 12, 11 (4 versions per Constitution IX)
**Web Support**: Chrome, Safari, Firefox, Edge (latest 2 versions)
**Development Environment**: Docker-based (flutter-dev, backend-api, postgres-db containers)
**Project Type**: Flutter mobile/web cross-platform application
**Performance Goals**: <1s search response, <2s page loads, <30s book discovery, 60fps UI animations, 30s polling sync
**Constraints**: Offline-capable with cached data, <50MB mobile app size, <2s cold start, support 50 concurrent users, handle 1000-book catalog without performance degradation
**Scale/Scope**: 500-1000 books, ~10-15 mobile screens, ~8-10 web admin screens, 15-20 API endpoints, quarterly/bi-annual suggestion collection cycles

## Constitution Check

*GATE: Must pass before Phase 0 research. Re-check after Phase 1 design.*

### Initial Check (Before Phase 0)

**Required Validations**:
- [x] Git workflow: Branch `001-library-management` created from `dev`, commits will reference issues
- [x] Documentation: Korean language for user-facing content (spec.md uses Korean input, implementation docs in Korean)
- [x] Logging: Follows `logs/YYYY-MM-DD/YYYYMMDD-HHmmss-<descriptor>.log` format (will be implemented)
- [x] 42 Identity: Color scheme reflects 42 brand identity (DR-001 in spec requires teal/cyan and dark theme)
- [x] UX Priority: Design prioritizes user convenience and pursues simple UI (DR-002, DR-003 emphasize quick discovery, card-based simplicity)
- [x] Docker Environment: All development dependencies in Docker, no local pollution (PR-005 mandates Docker containers)
- [x] Flutter Platform Support: iOS/Android/Web builds to be validated (PR-001 requires identical behavior)
- [x] Platform Versions: iOS 17/16/15/14, Android 14/13/12/11 (PR-002, PR-003 specify 4 versions each)
- [x] Testing: Quality gates defined (SC-001 through SC-016 provide measurable success criteria)

**Result**: ✅ All validations passed. No constitution violations.

### Post-Design Check (After Phase 1)

**Re-validated After Design**:
- [x] 42 Identity: Color system defined with teal (#00BABC) and dark theme (#1A1D23) in research.md
- [x] UX Priority: Card-based layouts, search debouncing (300ms), lazy loading confirmed in research.md
- [x] Docker Environment: Multi-container setup (flutter-dev, backend-api, postgres-db) specified in research.md
- [x] Flutter Platform Support: 95% shared code architecture defined in research.md
- [x] Platform Versions: Flutter 3.16.0 compatibility with iOS 14-17, Android 11-14 validated in research.md

**Design Decisions Validated**:
- Data model (8 entities) aligns with spec requirements
- API contracts (OpenAPI 3.0) cover all functional requirements (FR-001 through FR-032)
- Technology stack (Flutter + Node.js + PostgreSQL) meets scale/performance goals
- Offline-first architecture (Hive + sqflite + sync service) satisfies FR-012

**Result**: ✅ All post-design validations passed. Constitution compliance maintained.

## Project Structure

### Documentation (this feature)

```text
specs/[###-feature]/
├── plan.md              # This file (/speckit.plan command output)
├── research.md          # Phase 0 output (/speckit.plan command)
├── data-model.md        # Phase 1 output (/speckit.plan command)
├── quickstart.md        # Phase 1 output (/speckit.plan command)
├── contracts/           # Phase 1 output (/speckit.plan command)
└── tasks.md             # Phase 2 output (/speckit.tasks command - NOT created by /speckit.plan)
```

### Source Code (repository root)

```text
# Flutter Cross-Platform (iOS + Android + Web per Constitution IX)
lib/
├── main.dart              # Application entry point
├── app/                   # App-level configuration
│   ├── routes.dart        # Route definitions
│   ├── theme.dart         # 42 brand theme (teal/cyan, dark)
│   └── config.dart        # App configuration
├── screens/               # UI screens (mobile & web)
│   ├── mobile/            # Mobile-specific screens
│   │   ├── home/          # Book browsing & search
│   │   ├── book_detail/   # Book details
│   │   ├── loan/          # Loan requests & history
│   │   └── suggestions/   # Book suggestions
│   └── web/               # Web admin dashboard screens
│       ├── dashboard/     # Admin home
│       ├── catalog/       # Book management
│       ├── loans/         # Loan management
│       └── suggestions/   # Suggestion review
├── widgets/               # Reusable widgets
│   ├── book_card.dart     # Book display card
│   ├── search_bar.dart    # Search component
│   └── common/            # Common UI components
├── models/                # Data models
│   ├── book.dart          # Book entity
│   ├── loan.dart          # Loan & reservation entities
│   ├── suggestion.dart    # Book suggestion entity
│   └── user.dart          # User/Student entity
├── services/              # Business logic
│   ├── api/               # API clients
│   │   ├── book_api.dart
│   │   ├── loan_api.dart
│   │   └── auth_api.dart  # 42 API integration
│   ├── storage/           # Local storage
│   │   └── cache_service.dart
│   └── sync/              # Offline sync logic
│       └── sync_service.dart
├── repositories/          # Data repositories (abstraction layer)
│   ├── book_repository.dart
│   ├── loan_repository.dart
│   └── suggestion_repository.dart
├── state/                 # State management (bloc/provider/riverpod)
│   ├── book/
│   ├── loan/
│   └── auth/
├── utils/                 # Utilities
│   ├── constants.dart     # App constants
│   ├── validators.dart    # Input validation
│   └── formatters.dart    # Date/text formatters
└── platform/              # Platform-specific code (minimal per Constitution IX)
    ├── ios/               # iOS-specific implementations
    ├── android/           # Android-specific implementations
    └── web/               # Web-specific implementations

test/
├── widget_test/           # Widget tests
│   ├── screens/
│   └── widgets/
├── integration_test/      # Integration tests
│   ├── mobile_flow_test.dart
│   └── web_admin_flow_test.dart
└── unit_test/             # Unit tests
    ├── models/
    ├── services/
    └── repositories/

ios/                       # iOS platform files (generated)
android/                   # Android platform files (generated)
web/                       # Web platform files (generated)

# Backend API (if custom backend chosen in Phase 0)
backend/
├── src/
│   ├── models/            # Database models
│   ├── routes/            # API endpoints
│   ├── services/          # Business logic
│   └── middleware/        # Auth, validation
└── tests/
    ├── unit/
    └── integration/
```

**Structure Decision**: Flutter-first cross-platform architecture with separate mobile and web screen implementations sharing common widgets, models, and services. Custom backend (structure TBD in Phase 0 based on BaaS vs custom API decision) for data persistence and 42 API integration. Platform-specific code minimized and isolated per Constitution IX.

## GitHub Issue Workflow

**Task-to-Issue Mapping** (per Constitution XV):

### Grouping Policy
- **One Issue per User Story**: Group all T00x tasks within a User Story into single Issue
- **Issue Title Format**: `[User Story N] Brief description (T0XX-T0YY)`
- **Example**: `[User Story 1] Browse and Search Books (T033-T057)`

### Branch Strategy
- **Feature Branch**: Create `feature/<issue-no>-<short-desc>` from `dev`
- **Example**: `feature/16-browse-search-books`
- **Link Branch**: Use `gh issue develop <issue-no>` to link branch to Issue

### Commit Format
- **Reference T00x in commits**: `[#ISSUE_NO] type(T00x): description`
- **Examples**:
  - `[#16] test(T033): Add unit test for Book model`
  - `[#16] feat(T042): Create Book model with validation`
  - `[#16] feat(T047): Implement GET /books endpoint`

### Pull Request Process
1. Create PR from feature branch to `dev`
2. PR title: `[#ISSUE_NO] User Story N summary`
3. PR body must include: `Closes #ISSUE_NO`
4. Self-review acceptable for solo projects (5min reflection period)
5. Merge after approval, delete feature branch

### Example Workflow
```bash
# Create Issue for US1 (T033-T057)
gh issue create \
  --title "[User Story 1] Browse and Search Books (T033-T057)" \
  --label "type:feature,priority:high" \
  --milestone "v0.1.0"

# Create and link branch
gh issue develop 16 --name feature/16-browse-search-books
git checkout feature/16-browse-search-books

# Work with T00x-specific commits
git commit -m "[#16] test(T033): Add Book model unit test"
git commit -m "[#16] feat(T042): Create Book model"

# Create PR
git push origin feature/16-browse-search-books
gh pr create --title "[#16] User Story 1: Browse and Search Books" \
  --body "Closes #16"
```

## Complexity Tracking

> **Fill ONLY if Constitution Check has violations that must be justified**

| Violation | Why Needed | Simpler Alternative Rejected Because |
|-----------|------------|-------------------------------------|
| [e.g., 4th project] | [current need] | [why 3 projects insufficient] |
| [e.g., Repository pattern] | [specific problem] | [why direct DB access insufficient] |
