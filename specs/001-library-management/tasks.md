# Tasks: 42 Learning Space Library Management System

**Branch**: `001-library-management` | **Date**: 2025-12-17 | **Phase**: 2 - Task Generation  
**Input**: Design documents from `/specs/001-library-management/`  
**Prerequisites**: plan.md ✓, spec.md ✓, research.md ✓, data-model.md ✓, contracts/ ✓

**Tests**: Tests are included as requested in the feature specification to achieve 80% coverage target.

**Organization**: Tasks are grouped by user story to enable independent implementation and testing of each story.

> **Resync Note (#27, 2026-04-18)**: Phase 1-5 progress was re-verified against actual code state. See PR #27 for the verification table mapping each task to its source file or PR. Items still unchecked are real gaps (skipped tests, missing migration files, deferred polish items, US4 not started). Phase 6-13 not yet resynced.

## Format: `- [ ] [ID] [P?] [Story?] Description`

- **[P]**: Can run in parallel (different files, no dependencies)
- **[Story]**: Which user story this task belongs to (e.g., US1, US4)
- Include exact file paths in descriptions

**Path Conventions**: Flutter cross-platform structure with `lib/`, `test/`, `backend/` at repository root

---

## Phase 1: Setup (Shared Infrastructure)

**Purpose**: Project initialization and basic structure

- [X] T001 Create project directory structure per plan.md implementation plan
- [X] T002 Initialize Flutter project with dependencies in pubspec.yaml (flutter_bloc, dio, hive, sqflite, oauth2, etc.)
- [X] T003 Initialize backend API project in backend/ with package.json (Express, Prisma, JWT, bcrypt)
- [X] T004 [P] Configure Docker development environment in docker-compose.yml (flutter-dev, backend-api, postgres-db, redis-cache)
- [X] T005 [P] Create Dockerfile for Flutter development container
- [X] T006 [P] Create Dockerfile for backend API container in backend/Dockerfile
- [X] T007 [P] Configure Flutter linting and formatting in analysis_options.yaml
- [X] T008 [P] Configure Prisma schema in backend/prisma/schema.prisma with all 8 entities
- [ ] T009 [P] Verify iOS build configuration in ios/ directory (support iOS 14-17)
- [ ] T010 [P] Verify Android build configuration in android/ directory (support Android 11-14)
- [X] T011 [P] Verify Web build configuration in web/ directory
- [X] T012 Create environment configuration files (.env.example for backend, .dockerignore)
- [X] T013 Initialize Git repository structure with proper .gitignore
- [X] T014 Create README.md with Korean project description and setup instructions

---

## Phase 2: Foundational (Blocking Prerequisites)

**Purpose**: Core infrastructure that MUST be complete before ANY user story can be implemented

**⚠️ CRITICAL**: No user story work can begin until this phase is complete

- [ ] T015 Run initial Prisma migration to create database schema in backend/prisma/migrations/
- [X] T016 [P] Implement 42 brand theme with teal/cyan colors in lib/app/theme.dart
- [X] T017 [P] Setup navigation/routing framework in lib/app/routes.dart
- [X] T018 [P] Initialize Hive storage for key-value caching in lib/services/storage/hive_service.dart
- [X] T019 [P] Initialize sqflite storage for relational data in lib/services/storage/sqflite_service.dart
- [X] T020 [P] Implement secure storage service in lib/services/storage/secure_storage_service.dart
- [X] T021 [P] Create base API client with dio and interceptors in lib/services/api/base_api_client.dart
- [X] T022 [P] Implement error handling and logging infrastructure in lib/utils/error_handler.dart and lib/utils/logger.dart
- [X] T023 [P] Setup environment configuration management in lib/app/config.dart
- [X] T024 [P] Create reusable UI components library in lib/widgets/common/ (buttons, cards, inputs)
- [X] T025 [P] Implement platform detection utility in lib/platform/platform_detector.dart
- [X] T026 [P] Setup backend Express server initialization in backend/src/server.ts
- [X] T027 [P] Implement backend middleware (CORS, Helmet, rate limiting) in backend/src/middleware/
- [X] T028 [P] Create backend error handling middleware in backend/src/middleware/error_handler.ts
- [X] T029 [P] Implement backend logging with Winston in backend/src/utils/logger.ts
- [X] T030 [P] Create JWT utilities for token generation/validation in backend/src/utils/jwt.ts
- [X] T031 Validate Docker environment startup and container communication
- [X] T032 Run database seed script for initial test data in backend/prisma/seed.ts

**Checkpoint**: Foundation ready - user story implementation can now begin in parallel

---

## Phase 3: User Story 1 - Browse and Search Books in Mobile App (Priority: P1) 🎯 MVP

**Goal**: Enable students to discover available books through browsing and searching the catalog of 500-1000 books, view detailed book information, and check availability status.

**Independent Test**: Launch mobile app, browse book list, perform searches by title/author, apply category filters, view book details with availability status. Should deliver value without any other features.

### Tests for User Story 1

> **NOTE: Write these tests FIRST, ensure they FAIL before implementation**

- [X] T033 [P] [US1] Create unit test for Book model in test/unit_test/models/book_test.dart
- [ ] T034 [P] [US1] Create unit test for BookRepository in test/unit_test/repositories/book_repository_test.dart
- [ ] T035 [P] [US1] Create unit test for BookBloc in test/unit_test/state/book/book_bloc_test.dart
- [X] T036 [P] [US1] Create widget test for BookCard in test/widget_test/widgets/book_card_test.dart
- [X] T037 [P] [US1] Create widget test for SearchBar in test/widget_test/widgets/book_search_bar_test.dart
- [ ] T038 [P] [US1] Create widget test for HomeScreen in test/widget_test/screens/mobile/home/home_screen_test.dart
- [ ] T039 [P] [US1] Create integration test for book browsing flow in test/integration_test/book_browsing_test.dart
- [X] T040 [P] [US1] Create backend unit test for GET /books endpoint in backend/tests/unit/books.test.ts
- [X] T041 [P] [US1] Create backend unit test for GET /books/:id endpoint in backend/tests/unit/books.test.ts

### Implementation for User Story 1

**Models & Data Layer**

- [X] T042 [P] [US1] Create Book model in lib/models/book.dart with validation rules
- [X] T043 [P] [US1] Create Book entity JSON serialization in lib/models/book.g.dart (code generation)
- [X] T044 [US1] Create BookRepository interface in lib/repositories/book_repository.dart
- [X] T045 [US1] Implement BookRepository with sqflite and API sync in lib/repositories/book_repository_impl.dart

**Backend API - Books**

- [X] T046 [P] [US1] Create Book Prisma model queries in backend/src/services/book_service.ts
- [X] T047 [P] [US1] Implement GET /books endpoint with pagination/filters in backend/src/routes/books.ts
- [X] T048 [P] [US1] Implement GET /books/:id endpoint in backend/src/routes/books.ts
- [X] T049 [US1] Add request validation middleware for book endpoints in backend/src/middleware/validation/book_validation.ts

**State Management**

- [X] T050 [P] [US1] Create BookEvent classes in lib/state/book/book_event.dart
- [X] T051 [P] [US1] Create BookState classes in lib/state/book/book_state.dart
- [X] T052 [US1] Implement BookBloc with search/filter logic in lib/state/book/book_bloc.dart

**UI Components**

- [X] T053 [P] [US1] Create BookCard widget in lib/widgets/book_card.dart
- [X] T054 [P] [US1] Create SearchBar widget with debouncing in lib/widgets/search_bar.dart
- [X] T055 [P] [US1] Create CategoryFilter widget in lib/widgets/category_filter.dart

**Screens**

- [X] T056 [US1] Create HomeScreen for book browsing in lib/screens/mobile/home/home_screen.dart
- [X] T057 [US1] Create BookDetailScreen in lib/screens/mobile/book_detail/book_detail_screen.dart
- [X] T058 [US1] Add HomeScreen and BookDetailScreen to navigation routes in lib/core/routes/app_router.dart (legacy duplicate at lib/app/routes.dart)

**Performance & Polish**

- [X] T059 [US1] Implement lazy loading with ListView.builder in HomeScreen
- [X] T060 [US1] Add search debouncing (500ms) to SearchBar widget
- [X] T061 [US1] Implement offline caching for book catalog in BookRepository
- [X] T062 [US1] Add loading states and error handling to HomeScreen
- [ ] T063 [US1] Add pagination for book list (20 books per page)

**Checkpoint**: User Story 1 complete - students can browse and search books independently

---

## Phase 4: User Story 4 - Manage Library Catalog via Web Dashboard (Priority: P1)

**Goal**: Enable administrators to manage the book collection through web dashboard - add new books, update information, remove books, and search/browse catalog.

**Why co-P1 with US1**: Administrator catalog management is essential for maintaining the library. Without this, the catalog cannot be updated. Both browsing (US1) and management (US4) are required for a functioning system.

**Independent Test**: Log into web dashboard, add/edit/remove books, verify changes reflect in both admin and mobile views. Delivers value by enabling library maintenance.

### Tests for User Story 4

- [ ] T064 [P] [US4] Create unit test for Administrator model in test/unit_test/models/administrator_test.dart
- [ ] T065 [P] [US4] Create widget test for admin dashboard in test/widget_test/screens/web/dashboard/dashboard_screen_test.dart
- [ ] T066 [P] [US4] Create widget test for book management form in test/widget_test/screens/web/catalog/book_form_test.dart
- [ ] T067 [P] [US4] Create integration test for admin book management flow in test/integration_test/admin_catalog_test.dart
- [ ] T068 [P] [US4] Create backend unit test for POST /books endpoint in backend/tests/unit/books.test.ts
- [ ] T069 [P] [US4] Create backend unit test for PUT /books/:id endpoint in backend/tests/unit/books.test.ts
- [ ] T070 [P] [US4] Create backend unit test for DELETE /books/:id endpoint in backend/tests/unit/books.test.ts
- [ ] T071 [P] [US4] Create backend unit test for admin authentication in backend/tests/unit/auth.test.ts

### Implementation for User Story 4

**Models & Data Layer**

- [ ] T072 [P] [US4] Create Administrator model in lib/models/administrator.dart
- [ ] T073 [US4] Create AdministratorRepository in lib/repositories/administrator_repository.dart

**Backend API - Admin & Books Management**

- [ ] T074 [P] [US4] Implement admin authentication with bcrypt in backend/src/services/auth_service.ts
- [ ] T075 [P] [US4] Create admin authentication middleware in backend/src/middleware/auth.ts
- [ ] T076 [P] [US4] Implement POST /books endpoint (admin only) in backend/src/routes/books.ts
- [ ] T077 [P] [US4] Implement PUT /books/:id endpoint (admin only) in backend/src/routes/books.ts
- [ ] T078 [P] [US4] Implement DELETE /books/:id endpoint with active loan check in backend/src/routes/books.ts
- [ ] T079 [P] [US4] Implement POST /admin/login endpoint in backend/src/routes/admin.ts
- [ ] T080 [US4] Add ISBN uniqueness validation to book creation in backend/src/services/book_service.ts

**State Management**

- [ ] T081 [P] [US4] Create AuthEvent classes for admin in lib/state/auth/auth_event.dart
- [ ] T082 [P] [US4] Create AuthState classes for admin in lib/state/auth/auth_state.dart
- [ ] T083 [US4] Implement AuthBloc for admin authentication in lib/state/auth/auth_bloc.dart

**UI Components - Web Dashboard**

- [ ] T084 [P] [US4] Create AdminSidebar navigation widget in lib/widgets/admin/admin_sidebar.dart
- [ ] T085 [P] [US4] Create BookFormWidget for add/edit in lib/widgets/admin/book_form.dart
- [ ] T086 [P] [US4] Create DeleteConfirmationDialog in lib/widgets/admin/delete_confirmation_dialog.dart

**Screens - Web Dashboard**

- [ ] T087 [US4] Create AdminLoginScreen in lib/screens/web/login/admin_login_screen.dart
- [ ] T088 [US4] Create AdminDashboardScreen in lib/screens/web/dashboard/dashboard_screen.dart
- [ ] T089 [US4] Create CatalogManagementScreen in lib/screens/web/catalog/catalog_screen.dart
- [ ] T090 [US4] Add admin routes to navigation in lib/app/routes.dart
- [ ] T091 [US4] Implement book add/edit form with validation in CatalogManagementScreen
- [ ] T092 [US4] Implement book deletion with warning dialog for active loans

**Checkpoint**: User Story 4 complete - admins can manage catalog independently, US1 and US4 work together

---

## Phase 5: User Story 2 - Request Book Loans via Mobile App (Priority: P2)

**Goal**: Enable authenticated students to submit loan requests through mobile app, integrated with 42 API authentication. Track loan requests with reservation queue system.

**Independent Test**: Authenticate via 42 API, select available book, request loan, verify request appears in admin dashboard. Creates FIFO reservation queue if book unavailable. Delivers value by digitizing borrowing process.

### Tests for User Story 2

- [ ] T093 [P] [US2] Create unit test for LoanRequest model in test/unit_test/models/loan_request_test.dart
- [X] T094 [P] [US2] Create unit test for Reservation model in test/unit_test/models/reservation_test.dart
- [ ] T095 [P] [US2] Create unit test for Student model in test/unit_test/models/student_test.dart
- [ ] T096 [P] [US2] Create unit test for LoanBloc in test/unit_test/state/loan/loan_bloc_test.dart
- [ ] T097 [P] [US2] Create widget test for loan request flow in test/widget_test/screens/mobile/loan/loan_request_test.dart
- [ ] T098 [P] [US2] Create integration test for 42 OAuth flow in test/integration_test/auth_42_test.dart
- [ ] T099 [P] [US2] Create backend unit test for 42 OAuth integration in backend/tests/unit/auth_42.test.ts
- [ ] T100 [P] [US2] Create backend unit test for POST /loan-requests in backend/tests/unit/loan_requests.test.ts
- [ ] T101 [P] [US2] Create backend unit test for reservation queue logic in backend/tests/unit/reservations.test.ts

### Implementation for User Story 2

**Models & Data Layer**

- [X] T102 [P] [US2] Create Student model in lib/models/student.dart
- [X] T103 [P] [US2] Create LoanRequest model in lib/models/loan_request.dart
- [X] T104 [P] [US2] Create Reservation model in lib/models/reservation.dart
- [X] T105 [US2] Create LoanRequestRepository in lib/repositories/loan_request_repository.dart
- [X] T106 [US2] Create ReservationRepository in lib/repositories/reservation_repository.dart

**Backend API - Authentication & Loans**

- [X] T107 [P] [US2] Implement 42 OAuth 2.0 authentication in backend/src/services/auth_42_service.ts
- [X] T108 [P] [US2] Create GET /auth/42/login endpoint in backend/src/routes/auth.ts
- [X] T109 [P] [US2] Create GET /auth/42/callback endpoint in backend/src/routes/auth.ts
- [X] T110 [P] [US2] Implement student JWT token generation in backend/src/utils/jwt.ts
- [X] T111 [P] [US2] Create student authentication middleware in backend/src/middleware/auth.ts
- [X] T112 [P] [US2] Implement POST /loan-requests endpoint in backend/src/routes/loan_requests.ts
- [X] T113 [P] [US2] Implement GET /loan-requests/my endpoint (student's requests) in backend/src/routes/loan_requests.ts
- [X] T114 [P] [US2] Implement reservation queue service with FIFO logic in backend/src/services/reservation_service.ts
- [X] T115 [US2] Add automatic reservation creation when book unavailable in loan request logic

**State Management**

- [X] T116 [P] [US2] Create LoanEvent classes in lib/state/loan/loan_event.dart
- [X] T117 [P] [US2] Create LoanState classes in lib/state/loan/loan_state.dart
- [X] T118 [US2] Implement LoanBloc in lib/state/loan/loan_bloc.dart
- [X] T119 [US2] Update AuthBloc to support 42 OAuth flow

**Services**

- [X] T120 [P] [US2] Implement 42 OAuth client in lib/services/auth/auth_42_client.dart
- [X] T121 [US2] Implement secure token storage for 42 auth tokens in lib/services/storage/secure_storage_service.dart

**UI Components**

- [X] T122 [P] [US2] Create LoanRequestButton widget in lib/widgets/loan/loan_request_button.dart
- [X] T123 [P] [US2] Create ReservationQueueIndicator widget in lib/widgets/loan/reservation_queue_indicator.dart

**Screens**

- [X] T124 [US2] Create LoginScreen with 42 OAuth in lib/screens/mobile/auth/login_screen.dart
- [X] T125 [US2] Create MyLoansScreen in lib/screens/mobile/loan/my_loans_screen.dart
- [X] T126 [US2] Update BookDetailScreen to show loan request button
- [X] T127 [US2] Add loan-related routes to navigation in lib/core/routes/app_router.dart (legacy duplicate at lib/app/routes.dart)

**Integration & Polish**

- [ ] T128 [US2] Implement graceful handling of 42 API failures with error messages
- [ ] T129 [US2] Add loan request confirmation dialogs
- [X] T130 [US2] Display reservation queue position in student profile
- [ ] T131 [US2] Add offline queue for loan requests (sync when online)

**Checkpoint**: User Story 2 complete - students can request loans independently, integrates with US1

---

## Phase 6: User Story 5 - Track and Manage Loans via Web Dashboard (Priority: P2)

**Goal**: Enable administrators to view and manage loan activity - see pending requests, approve/reject requests, view active loans, process returns, view history.

**Independent Test**: Process loan requests, mark books as returned, view loan history reports. Delivers value by digitizing loan tracking.

### Tests for User Story 5

- [ ] T132 [P] [US5] Create unit test for Loan model in test/unit_test/models/loan_test.dart
- [ ] T133 [P] [US5] Create widget test for loan management screen in test/widget_test/screens/web/loans/loans_screen_test.dart
- [ ] T134 [P] [US5] Create integration test for loan approval flow in test/integration_test/admin_loan_management_test.dart
- [ ] T135 [P] [US5] Create backend unit test for PUT /loan-requests/:id/approve in backend/tests/unit/loan_requests.test.ts
- [ ] T136 [P] [US5] Create backend unit test for PUT /loans/:id/return in backend/tests/unit/loans.test.ts
- [ ] T137 [P] [US5] Create backend unit test for overdue detection in backend/tests/unit/loans.test.ts

### Implementation for User Story 5

**Models & Data Layer**

- [ ] T138 [P] [US5] Create Loan model in lib/models/loan.dart
- [ ] T139 [US5] Create LoanRepository in lib/repositories/loan_repository.dart

**Backend API - Loan Management**

- [ ] T140 [P] [US5] Implement GET /loan-requests endpoint (admin) in backend/src/routes/loan_requests.ts
- [ ] T141 [P] [US5] Implement PUT /loan-requests/:id/approve endpoint in backend/src/routes/loan_requests.ts
- [ ] T142 [P] [US5] Implement PUT /loan-requests/:id/reject endpoint in backend/src/routes/loan_requests.ts
- [ ] T143 [P] [US5] Implement GET /loans endpoint (admin) in backend/src/routes/loans.ts
- [ ] T144 [P] [US5] Implement PUT /loans/:id/return endpoint in backend/src/routes/loans.ts
- [ ] T145 [P] [US5] Implement GET /loans/history endpoint with filters in backend/src/routes/loans.ts
- [ ] T146 [US5] Implement loan approval logic with availability check in backend/src/services/loan_service.ts
- [ ] T147 [US5] Implement automatic overdue detection in backend/src/services/loan_service.ts
- [ ] T148 [US5] Add notification to reservation queue when book returned

**State Management**

- [ ] T149 [US5] Update LoanBloc to support admin loan management operations

**UI Components - Web Dashboard**

- [ ] T150 [P] [US5] Create LoanRequestCard widget in lib/widgets/admin/loan_request_card.dart
- [ ] T151 [P] [US5] Create ActiveLoanCard widget in lib/widgets/admin/active_loan_card.dart
- [ ] T152 [P] [US5] Create OverdueIndicator widget in lib/widgets/admin/overdue_indicator.dart

**Screens - Web Dashboard**

- [ ] T153 [US5] Create LoanManagementScreen in lib/screens/web/loans/loans_screen.dart
- [ ] T154 [US5] Create LoanHistoryScreen with filters in lib/screens/web/loans/loan_history_screen.dart
- [ ] T155 [US5] Add loan management routes to admin navigation

**Integration & Polish**

- [ ] T156 [US5] Implement loan approval with automatic book availability update
- [ ] T157 [US5] Implement book return with automatic reservation queue notification
- [ ] T158 [US5] Add overdue loan highlighting in loan list
- [ ] T159 [US5] Add date range filters for loan history

**Checkpoint**: User Story 5 complete - admins can manage loans, works with US2 and US4

---

## Phase 7: User Story 3 - Submit Book Suggestions (Priority: P3)

**Goal**: Enable students to suggest books for library addition. Suggestions collected quarterly/bi-annually for admin review.

**Independent Test**: Submit book suggestion through app, verify it appears in admin dashboard. Delivers value by giving students voice in collection expansion.

### Tests for User Story 3

- [ ] T160 [P] [US3] Create unit test for BookSuggestion model in test/unit_test/models/book_suggestion_test.dart
- [ ] T161 [P] [US3] Create unit test for CollectionPeriod model in test/unit_test/models/collection_period_test.dart
- [ ] T162 [P] [US3] Create widget test for suggestion form in test/widget_test/screens/mobile/suggestions/suggestion_form_test.dart
- [ ] T163 [P] [US3] Create backend unit test for POST /suggestions in backend/tests/unit/suggestions.test.ts
- [ ] T164 [P] [US3] Create backend unit test for collection period validation in backend/tests/unit/collection_periods.test.ts

### Implementation for User Story 3

**Models & Data Layer**

- [ ] T165 [P] [US3] Create BookSuggestion model in lib/models/book_suggestion.dart
- [ ] T166 [P] [US3] Create CollectionPeriod model in lib/models/collection_period.dart
- [ ] T167 [US3] Create BookSuggestionRepository in lib/repositories/book_suggestion_repository.dart

**Backend API - Suggestions**

- [ ] T168 [P] [US3] Implement POST /suggestions endpoint in backend/src/routes/suggestions.ts
- [ ] T169 [P] [US3] Implement GET /suggestions/my endpoint in backend/src/routes/suggestions.ts
- [ ] T170 [P] [US3] Implement GET /collection-periods/active endpoint in backend/src/routes/collection_periods.ts
- [ ] T171 [US3] Add collection period validation to suggestion submission in backend/src/services/suggestion_service.ts

**State Management**

- [ ] T172 [P] [US3] Create SuggestionEvent classes in lib/state/suggestion/suggestion_event.dart
- [ ] T173 [P] [US3] Create SuggestionState classes in lib/state/suggestion/suggestion_state.dart
- [ ] T174 [US3] Implement SuggestionBloc in lib/state/suggestion/suggestion_bloc.dart

**Screens**

- [ ] T175 [US3] Create SuggestionFormScreen in lib/screens/mobile/suggestions/suggestion_form_screen.dart
- [ ] T176 [US3] Create MySuggestionsScreen in lib/screens/mobile/suggestions/my_suggestions_screen.dart
- [ ] T177 [US3] Add suggestion routes to navigation

**Integration & Polish**

- [ ] T178 [US3] Add validation for active collection period before submission
- [ ] T179 [US3] Add confirmation message after successful suggestion submission
- [ ] T180 [US3] Display collection period status (active/closed) in suggestion screen

**Checkpoint**: User Story 3 complete - students can submit suggestions independently

---

## Phase 8: User Story 6 - Review Book Suggestions via Web Dashboard (Priority: P3)

**Goal**: Enable administrators to review collected suggestions, see request counts, mark suggestions as approved/rejected/under consideration.

**Independent Test**: View suggestions dashboard, filter by date range, update suggestion statuses. Delivers value by streamlining collection review process.

### Tests for User Story 6

- [ ] T181 [P] [US6] Create widget test for suggestions review screen in test/widget_test/screens/web/suggestions/suggestions_screen_test.dart
- [ ] T182 [P] [US6] Create backend unit test for GET /suggestions endpoint in backend/tests/unit/suggestions.test.ts
- [ ] T183 [P] [US6] Create backend unit test for suggestion grouping in backend/tests/unit/suggestions.test.ts

### Implementation for User Story 6

**Backend API - Admin Suggestions**

- [ ] T184 [P] [US6] Implement GET /suggestions endpoint (admin, grouped) in backend/src/routes/suggestions.ts
- [ ] T185 [P] [US6] Implement PUT /suggestions/:id/status endpoint in backend/src/routes/suggestions.ts
- [ ] T186 [P] [US6] Implement POST /collection-periods endpoint in backend/src/routes/collection_periods.ts
- [ ] T187 [US6] Implement suggestion grouping by title+author in backend/src/services/suggestion_service.ts
- [ ] T188 [US6] Add collection period archival logic in backend/src/services/collection_period_service.ts

**UI Components - Web Dashboard**

- [ ] T189 [P] [US6] Create SuggestionCard with requester count in lib/widgets/admin/suggestion_card.dart
- [ ] T190 [P] [US6] Create CollectionPeriodSelector widget in lib/widgets/admin/collection_period_selector.dart

**Screens - Web Dashboard**

- [ ] T191 [US6] Create SuggestionsReviewScreen in lib/screens/web/suggestions/suggestions_screen.dart
- [ ] T192 [US6] Create CollectionPeriodsScreen in lib/screens/web/suggestions/collection_periods_screen.dart
- [ ] T193 [US6] Add suggestion management routes to admin navigation

**Integration & Polish**

- [ ] T194 [US6] Implement grouped suggestion display with duplicate count
- [ ] T195 [US6] Add status update (approved/rejected/under review) functionality
- [ ] T196 [US6] Add option to add approved suggestion directly to catalog
- [ ] T197 [US6] Display suggestion statistics (most requested categories)

**Checkpoint**: User Story 6 complete - admins can review suggestions, all user stories functional

---

## Phase 9: Real-Time Synchronization & Offline Support

**Purpose**: Implement data sync and offline capabilities across all user stories

- [ ] T198 [P] Implement delta sync service with timestamp tracking in lib/services/sync/sync_service.dart
- [ ] T199 [P] Implement 30-second polling mechanism for active app in lib/services/sync/sync_manager.dart
- [ ] T200 [P] Implement offline action queue in lib/services/sync/offline_queue.dart
- [ ] T201 [P] Add connectivity monitoring in lib/services/sync/connectivity_service.dart
- [ ] T202 Integrate sync service with all repositories (Book, Loan, Suggestion)
- [ ] T203 Implement background sync when connectivity restored
- [ ] T204 Add sync status indicators in UI
- [ ] T205 Test offline browsing with cached book data
- [ ] T206 Test offline loan request queuing and sync

---

## Phase 10: Performance Optimization

**Purpose**: Ensure system meets all performance success criteria (SC-001 through SC-012)

- [ ] T207 [P] Add image caching for book covers with cached_network_image
- [ ] T208 [P] Optimize sqflite queries with proper indexes
- [ ] T209 [P] Implement virtual scrolling for 1000-book catalog
- [ ] T210 [P] Add database query logging for performance monitoring
- [ ] T211 Profile app performance with Flutter DevTools
- [ ] T212 Validate <30s book discovery time (SC-001)
- [ ] T213 Validate <1s search response time (SC-002)
- [ ] T214 Validate <2s page load times (SC-009)
- [ ] T215 Load test backend with 50 concurrent users (SC-010)
- [ ] T216 Validate <10s data sync time (SC-011)

---

## Phase 11: Testing & Quality Assurance

**Purpose**: Achieve 80% code coverage and validate all success criteria

- [ ] T217 [P] Run all unit tests and verify 60% coverage minimum in test/unit_test/
- [ ] T218 [P] Run all widget tests and verify 30% coverage minimum in test/widget_test/
- [ ] T219 [P] Run all integration tests and verify 10% coverage minimum in test/integration_test/
- [ ] T220 Generate Flutter coverage report with lcov
- [ ] T221 [P] Run backend unit tests and verify coverage in backend/tests/
- [ ] T222 Generate backend coverage report with Jest
- [ ] T223 [P] Test iOS build on iOS 17, 16, 15, 14 simulators
- [ ] T224 [P] Test Android build on Android 14, 13, 12, 11 emulators
- [ ] T225 [P] Test Web build on Chrome, Safari, Firefox, Edge (latest 2 versions)
- [ ] T226 Validate all functional requirements (FR-001 through FR-032)
- [ ] T227 Validate all design requirements (DR-001 through DR-007)
- [ ] T228 Validate all platform requirements (PR-001 through PR-007)
- [ ] T229 Validate all success criteria (SC-001 through SC-016)

---

## Phase 12: Documentation & Deployment Preparation

**Purpose**: Complete documentation and prepare for deployment

- [ ] T230 [P] Create API documentation with Swagger UI in backend/src/swagger.ts
- [ ] T231 [P] Update README.md with final setup instructions (Korean)
- [ ] T232 [P] Document environment variables in .env.example
- [ ] T233 [P] Create deployment guide in docs/deployment.md (Korean)
- [ ] T234 [P] Create user manual for mobile app in docs/user-guide.md (Korean)
- [ ] T235 [P] Create admin manual for web dashboard in docs/admin-guide.md (Korean)
- [ ] T236 Validate quickstart.md setup instructions
- [ ] T237 Create database backup and restore procedures
- [ ] T238 Document 42 OAuth setup instructions
- [ ] T239 Create CI/CD pipeline configuration in .github/workflows/ci.yml

---

## Phase 13: Polish & Cross-Cutting Concerns

**Purpose**: Final improvements across all user stories

- [ ] T240 [P] Run Flutter analyzer and fix all warnings with flutter analyze
- [ ] T241 [P] Format all Dart code with flutter format lib/ test/
- [ ] T242 [P] Run ESLint on backend code and fix warnings
- [ ] T243 [P] Format backend code with Prettier
- [ ] T244 Add loading animations with 42 brand identity
- [ ] T245 Add error message translations (Korean)
- [ ] T246 Implement app version checking
- [ ] T247 Add accessibility features (screen reader support)
- [ ] T248 Security audit - check for exposed secrets
- [ ] T249 Review and optimize Docker container sizes
- [ ] T250 Add Docker health checks for all services
- [ ] T251 Test hot reload functionality in Docker environment
- [ ] T252 Validate logs follow Constitution format (logs/YYYY-MM-DD/YYYYMMDD-HHmmss-*.log)
- [ ] T253 Create PR to dev branch with Korean description and testing evidence
- [ ] T254 **STOP and WAIT for PR review approval** before proceeding

---

## Final Constitution Compliance Check

**Required Before Feature Completion** (Constitution X):

Review compliance with all applicable principles:

- [ ] T255 Git-Based Project Management (I): All work tracked in Git/GitHub
- [ ] T256 Branch Strategy (II): Feature branch 001-library-management used, PRs follow process
- [ ] T257 Issue-Driven Commits & Metadata (III): Commits reference issues, labels/milestones configured
- [ ] T258 Korean Documentation (IV): User-facing docs (README, guides) in Korean
- [ ] T259 Structured Documentation & Logging (V): Proper directory structure, logs in correct format
- [ ] T260 42 Identity Design (VI): Teal/cyan brand colors implemented in theme
- [ ] T261 User-Centric UX (VII): Quick discovery, simple UI, convenience prioritized
- [ ] T262 Docker-Based Environment (VIII): All dev in Docker, no local pollution
- [ ] T263 Flutter Cross-Platform (IX): iOS/Android/Web compatibility verified, 95% shared code
- [ ] T264 Compliance Verification (X): This checklist completed
- [ ] T265 Pull Request Review Gate (XI): PR created to dev, approval received
- [ ] T266 CI & Immediate Sharing (XII): CI pipeline configured
- [ ] T267 Descriptive Issue/PR Titles (XIII): Titles comprehensively represent content
- [ ] T268 Issue/PR/Commit Synchronization (XIV): Titles maintain consistency

**Compliance Status**: [PENDING VERIFICATION]  
**Verified By**: [TBD]  
**Verification Date**: [TBD]

---

## Dependencies & Execution Order

### Phase Dependencies

- **Setup (Phase 1)**: No dependencies - can start immediately
- **Foundational (Phase 2)**: Depends on Setup completion - **BLOCKS all user stories**
- **User Story 1 (Phase 3)**: Depends on Foundational (Phase 2) completion
- **User Story 4 (Phase 4)**: Depends on Foundational (Phase 2) completion, can run parallel with US1
- **User Story 2 (Phase 5)**: Depends on Foundational (Phase 2) and US1 (BookDetailScreen integration)
- **User Story 5 (Phase 6)**: Depends on Foundational (Phase 2) and US2 (loan request data)
- **User Story 3 (Phase 7)**: Depends on Foundational (Phase 2) completion, independent of other stories
- **User Story 6 (Phase 8)**: Depends on Foundational (Phase 2) and US3 (suggestion data)
- **Sync & Offline (Phase 9)**: Depends on US1, US2, US3 completion
- **Performance (Phase 10)**: Depends on all user stories being implemented
- **Testing (Phase 11)**: Continuous throughout, final validation after all features
- **Documentation (Phase 12)**: Can start early, finalize after all features
- **Polish (Phase 13)**: Depends on all desired features being complete

### User Story Dependencies

**P1 Stories (MVP - Must Have)**:
- **User Story 1**: Can start after Foundational - No dependencies
- **User Story 4**: Can start after Foundational - No dependencies

**P2 Stories (Important)**:
- **User Story 2**: Requires US1 (integrates with BookDetailScreen)
- **User Story 5**: Requires US2 (manages loan requests from US2)

**P3 Stories (Nice to Have)**:
- **User Story 3**: Independent after Foundational
- **User Story 6**: Requires US3 (manages suggestions from US3)

### Parallel Opportunities

**Within Setup Phase**:
- T004 (docker-compose), T005 (Flutter Dockerfile), T006 (Backend Dockerfile) can run in parallel
- T007 (Flutter lint), T008 (Prisma schema), T009-T011 (platform configs) can run in parallel

**Within Foundational Phase**:
- T016-T025 (Flutter infrastructure) can run in parallel
- T026-T030 (Backend infrastructure) can run in parallel
- Frontend and Backend foundational tasks can run in parallel teams

**After Foundational Complete**:
- **US1 and US4 can run in parallel** (different teams/developers)
- Once US1 complete: US2 can start
- Once US2 complete: US5 can start
- US3 can run in parallel with US1/US2/US4/US5 (independent)
- Once US3 complete: US6 can start

**Within Each User Story**:
- All tests for a story can run in parallel
- Models within a story can run in parallel (marked [P])
- Backend route implementations can run in parallel (marked [P])
- UI components can run in parallel (marked [P])

---

## Parallel Example: MVP (US1 + US4)

```bash
# After Foundational Phase completes, launch MVP user stories in parallel:

## Team A: User Story 1 (Mobile Browsing)
# Tests first (parallel):
Task T033: Unit test Book model
Task T034: Unit test BookRepository
Task T035: Unit test BookBloc
Task T036: Widget test BookCard
Task T037: Widget test SearchBar
Task T038: Widget test HomeScreen
Task T039: Integration test browsing flow
Task T040-T041: Backend tests

# Models (parallel):
Task T042: Book model
Task T043: JSON serialization

# Backend (parallel):
Task T046: Prisma queries
Task T047: GET /books endpoint
Task T048: GET /books/:id endpoint

# State (parallel):
Task T050: BookEvent
Task T051: BookState

# UI Components (parallel):
Task T053: BookCard widget
Task T054: SearchBar widget
Task T055: CategoryFilter widget

## Team B: User Story 4 (Admin Catalog Management)
# Tests first (parallel):
Task T064-T071: All admin tests in parallel

# Models (parallel):
Task T072: Administrator model

# Backend (parallel):
Task T074: Admin auth service
Task T075: Auth middleware
Task T076-T080: Book management endpoints

# UI Components (parallel):
Task T084: AdminSidebar
Task T085: BookFormWidget
Task T086: DeleteConfirmationDialog
```

---

## Implementation Strategy

### MVP First (US1 + US4 Only)

1. Complete Phase 1: Setup (~1-2 days)
2. Complete Phase 2: Foundational (~3-5 days) **CRITICAL BLOCKER**
3. Complete Phase 3: User Story 1 (~5-7 days)
4. Complete Phase 4: User Story 4 (~5-7 days) - Can run parallel with US1
5. **STOP and VALIDATE**: Test US1 and US4 independently and together
6. Deploy/demo MVP (students can browse, admins can manage)

**MVP Delivers**:
- Students: Browse and search 500-1000 books ✓
- Admins: Add, edit, remove books ✓
- Complete, testable, deployable system ✓

### Incremental Delivery (After MVP)

1. **MVP** (US1 + US4): Browse + Catalog Management → Deploy
2. **+US2** (Loan Requests): Add student loan requests → Deploy
3. **+US5** (Loan Management): Add admin loan processing → Deploy
4. **+US3** (Suggestions): Add student suggestions → Deploy
5. **+US6** (Suggestion Review): Add admin suggestion review → Deploy
6. Each increment adds value without breaking previous features

### Full Feature Set Timeline

- **Week 1**: Setup + Foundational
- **Week 2-3**: MVP (US1 + US4)
- **Week 4**: US2 + US5 (Loan system)
- **Week 5**: US3 + US6 (Suggestion system)
- **Week 6**: Sync, Performance, Testing, Polish
- **Total**: ~6 weeks for full feature set

---

## Task Summary

**Total Tasks**: 268

**By Phase**:
- Setup: 14 tasks
- Foundational: 18 tasks (BLOCKING)
- User Story 1 (P1): 31 tasks
- User Story 4 (P1): 29 tasks
- User Story 2 (P2): 39 tasks
- User Story 5 (P2): 28 tasks
- User Story 3 (P3): 21 tasks
- User Story 6 (P3): 15 tasks
- Sync & Offline: 9 tasks
- Performance: 10 tasks
- Testing: 13 tasks
- Documentation: 10 tasks
- Polish: 17 tasks
- Constitution: 14 tasks

**By User Story**:
- US1 (Browse Books): 31 tasks
- US2 (Loan Requests): 39 tasks
- US3 (Suggestions): 21 tasks
- US4 (Admin Catalog): 29 tasks
- US5 (Admin Loans): 28 tasks
- US6 (Admin Suggestions): 15 tasks

**Parallelizable Tasks**: 152 marked with [P]

**Independent Test Criteria**:
- US1: Launch app → browse → search → view details ✓
- US2: Login → select book → request loan → check status ✓
- US3: Open app → submit suggestion → confirm receipt ✓
- US4: Login admin → add/edit/delete book → verify changes ✓
- US5: Login admin → approve loan → mark return → view history ✓
- US6: Login admin → view suggestions → update status → see stats ✓

**Suggested MVP Scope**: User Story 1 (Browse) + User Story 4 (Admin Catalog) = 60 tasks for working system

---

## Format Validation

✅ **ALL tasks follow checklist format**:
- `- [ ]` checkbox: Present
- `[ID]` sequential (T001-T268): Present
- `[P]` marker: 152 parallelizable tasks marked
- `[Story]` label: All user story tasks labeled (US1-US6)
- File paths: Included in all implementation tasks
- Description: Clear actions specified

✅ **Organization by user story**: Enables independent implementation and testing

✅ **Tests included**: 80% coverage target with unit, widget, integration, backend tests

✅ **Independent test criteria**: Each user story can be validated standalone

✅ **Dependency graph**: Clear phase and story dependencies documented

✅ **Parallel opportunities**: 152 tasks marked, examples provided per story

✅ **MVP identified**: US1 + US4 = 60 tasks for minimal viable product
