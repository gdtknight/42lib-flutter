# Implementation Tasks: User Story 2 - Request Book Loans via Mobile App

**Branch**: `001-library-management`  
**Date**: 2025-12-18  
**Phase**: Implementation - User Story 2  
**Dependencies**: User Story 1 (Browse and Search Books) - ✅ COMPLETED

## Overview

User Story 2 enables students to request book loans through the mobile app with 42 API authentication. This story adds:
- 42 OAuth authentication integration
- Loan request submission functionality  
- Reservation queue system (FIFO with 24-hour expiration)
- User profile showing active loans and reservation positions

## Task Execution Plan

### Phase 0: Setup & Infrastructure (Backend)
*Prerequisites: Backend service must support User Story 2 endpoints*

- [ ] **TASK-201**: Setup 42 OAuth application credentials
  - Register application in 42 Intra API
  - Obtain client ID and client secret
  - Configure callback URLs for mobile/web
  - **Files**: `backend/.env.example`, `backend/src/config/auth.ts`
  - **Estimated**: 30 minutes

- [ ] **TASK-202**: Implement 42 API authentication service (Backend)
  - Create OAuth2 flow with 42 API
  - Token management (access + refresh tokens)
  - User profile sync from 42 API
  - **Files**: `backend/src/services/auth_service.ts`, `backend/src/middleware/auth_middleware.ts`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-201

- [ ] **TASK-203**: Create loan request database models (Backend)
  - LoanRequest entity (id, studentId, bookId, status, timestamps)
  - Reservation entity (id, studentId, bookId, position, notificationTime, expirationTime)
  - Loan entity (id, studentId, bookId, checkoutDate, returnDate)
  - **Files**: `backend/src/models/loan_request.ts`, `backend/src/models/reservation.ts`, `backend/src/models/loan.ts`
  - **Estimated**: 2 hours

- [ ] **TASK-204**: Implement loan request API endpoints (Backend)
  - POST /api/loan-requests (submit loan request)
  - GET /api/loan-requests (list user's loan requests)
  - GET /api/loan-requests/:id (get specific request)
  - DELETE /api/loan-requests/:id (cancel request)
  - **Files**: `backend/src/routes/loan_requests.ts`, `backend/src/controllers/loan_request_controller.ts`
  - **Estimated**: 4 hours
  - **Dependencies**: TASK-203

- [ ] **TASK-205**: Implement reservation queue management (Backend)
  - Create reservation when book unavailable
  - FIFO queue position calculation
  - Notification trigger when book available
  - Auto-expiration after 24 hours
  - Move to next in queue on expiration
  - **Files**: `backend/src/services/reservation_service.ts`, `backend/src/jobs/reservation_expiry_job.ts`
  - **Estimated**: 5 hours
  - **Dependencies**: TASK-204

- [ ] **TASK-206**: Implement user profile API endpoints (Backend)
  - GET /api/users/me (authenticated user profile)
  - GET /api/users/me/loans (active loans and history)
  - GET /api/users/me/reservations (queue positions)
  - **Files**: `backend/src/routes/users.ts`, `backend/src/controllers/user_controller.ts`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-202

### Phase 1: Flutter Models & Data Layer

- [ ] **TASK-211**: Create loan-related data models (Flutter)
  - LoanRequest model with status enum
  - Reservation model with queue position
  - Loan model with dates
  - JSON serialization/deserialization
  - **Files**: `lib/models/loan_request.dart`, `lib/models/reservation.dart`, `lib/models/loan.dart`
  - **Estimated**: 2 hours

- [ ] **TASK-212**: Implement 42 API authentication client (Flutter)
  - OAuth2 flow using oauth2 package
  - Token storage (secure storage)
  - Auto token refresh
  - User session management
  - **Files**: `lib/services/api/auth_api.dart`, `lib/services/storage/auth_storage.dart`
  - **Estimated**: 4 hours
  - **Dependencies**: TASK-202

- [ ] **TASK-213**: Implement loan request API client (Flutter)
  - Submit loan request
  - Fetch user loan requests
  - Cancel loan request
  - Handle API errors
  - **Files**: `lib/services/api/loan_api.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-211, TASK-212

- [ ] **TASK-214**: Implement user profile API client (Flutter)
  - Fetch user profile
  - Fetch active loans
  - Fetch reservation queue positions
  - **Files**: `lib/services/api/user_api.dart`
  - **Estimated**: 1.5 hours
  - **Dependencies**: TASK-212

- [ ] **TASK-215**: Create loan repository (Flutter)
  - Abstract API calls
  - Local caching with Hive
  - Offline queue for loan requests
  - **Files**: `lib/repositories/loan_repository.dart`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-213

### Phase 2: State Management

- [ ] **TASK-221**: Create auth state management (Bloc)
  - AuthBloc with states (unauthenticated, authenticating, authenticated, error)
  - Login/logout events
  - Token refresh handling
  - User session persistence
  - **Files**: `lib/state/auth/auth_bloc.dart`, `lib/state/auth/auth_event.dart`, `lib/state/auth/auth_state.dart`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-212

- [ ] **TASK-222**: Create loan request state management (Bloc)
  - LoanRequestBloc with CRUD events
  - Loading, success, error states
  - Optimistic updates
  - **Files**: `lib/state/loan/loan_request_bloc.dart`, `lib/state/loan/loan_request_event.dart`, `lib/state/loan/loan_request_state.dart`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-215

- [ ] **TASK-223**: Create user profile state management (Bloc)
  - UserProfileBloc for profile data
  - Fetch loans and reservations
  - Real-time updates
  - **Files**: `lib/state/user/user_profile_bloc.dart`, `lib/state/user/user_profile_event.dart`, `lib/state/user/user_profile_state.dart`
  - **Estimated**: 2.5 hours
  - **Dependencies**: TASK-214

### Phase 3: UI Components (Mobile)

- [ ] **TASK-231**: Create login screen
  - 42 OAuth login button
  - Loading state during authentication
  - Error handling with user-friendly messages
  - Redirect to home after successful login
  - **Files**: `lib/screens/mobile/auth/login_screen.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-221

- [ ] **TASK-232**: Update book detail screen - add loan request button
  - Show "Request Loan" button for available books
  - Show "Join Queue" button for unavailable books
  - Require authentication (redirect to login if needed)
  - Success/error feedback
  - **Files**: `lib/screens/mobile/book_detail/book_detail_screen.dart` (update existing)
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-222, TASK-231

- [ ] **TASK-233**: Create loan request dialog/modal
  - Confirm loan request
  - Show estimated wait time for reservations
  - Cancel option
  - **Files**: `lib/widgets/loan/loan_request_dialog.dart`
  - **Estimated**: 1.5 hours
  - **Dependencies**: TASK-232

- [ ] **TASK-234**: Create user profile screen
  - Display user info from 42 API
  - Active loans list with due dates
  - Loan history
  - Active reservations with queue positions
  - **Files**: `lib/screens/mobile/profile/profile_screen.dart`
  - **Estimated**: 4 hours
  - **Dependencies**: TASK-223

- [ ] **TASK-235**: Create loan request status widget
  - Display request status (pending, approved, active)
  - Show expected return date for active loans
  - Show queue position for reservations
  - **Files**: `lib/widgets/loan/loan_status_widget.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-234

- [ ] **TASK-236**: Update navigation - add profile route
  - Add profile icon to app bar/bottom navigation
  - Route protection (require authentication)
  - **Files**: `lib/app/routes.dart` (update existing)
  - **Estimated**: 1 hour
  - **Dependencies**: TASK-234

### Phase 4: Testing

- [ ] **TASK-241**: Unit tests for auth service
  - Test OAuth flow
  - Test token refresh
  - Test session management
  - **Files**: `test/unit_test/services/auth_api_test.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-212

- [ ] **TASK-242**: Unit tests for loan models
  - Test JSON serialization
  - Test status transitions
  - Test validation
  - **Files**: `test/unit_test/models/loan_request_test.dart`, `test/unit_test/models/reservation_test.dart`
  - **Estimated**: 1.5 hours
  - **Dependencies**: TASK-211

- [ ] **TASK-243**: Unit tests for loan repository
  - Test API client integration
  - Test caching logic
  - Test offline queue
  - **Files**: `test/unit_test/repositories/loan_repository_test.dart`
  - **Estimated**: 2.5 hours
  - **Dependencies**: TASK-215

- [ ] **TASK-244**: Unit tests for auth bloc
  - Test state transitions
  - Test login/logout flows
  - Test error handling
  - **Files**: `test/unit_test/state/auth/auth_bloc_test.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-221

- [ ] **TASK-245**: Unit tests for loan request bloc
  - Test CRUD operations
  - Test optimistic updates
  - Test error handling
  - **Files**: `test/unit_test/state/loan/loan_request_bloc_test.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-222

- [ ] **TASK-246**: Widget tests for login screen
  - Test UI rendering
  - Test button interactions
  - Test error display
  - **Files**: `test/widget_test/screens/mobile/auth/login_screen_test.dart`
  - **Estimated**: 1.5 hours
  - **Dependencies**: TASK-231

- [ ] **TASK-247**: Widget tests for profile screen
  - Test profile data display
  - Test loan list rendering
  - Test reservation list rendering
  - **Files**: `test/widget_test/screens/mobile/profile/profile_screen_test.dart`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-234

- [ ] **TASK-248**: Integration test for loan request flow
  - Test end-to-end: login → browse → request loan → view profile
  - Test reservation queue flow
  - Test offline scenario
  - **Files**: `test/integration_test/loan_request_flow_test.dart`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-236

### Phase 5: Backend Testing

- [ ] **TASK-251**: Backend unit tests for auth service
  - Test 42 OAuth integration
  - Test token validation
  - Test user sync
  - **Files**: `backend/tests/unit/services/auth_service.test.ts`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-202

- [ ] **TASK-252**: Backend unit tests for reservation service
  - Test queue management
  - Test FIFO ordering
  - Test 24-hour expiration
  - Test notification triggers
  - **Files**: `backend/tests/unit/services/reservation_service.test.ts`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-205

- [ ] **TASK-253**: Backend integration tests for loan request API
  - Test POST /loan-requests
  - Test GET /loan-requests
  - Test queue creation when book unavailable
  - Test authentication middleware
  - **Files**: `backend/tests/integration/loan_requests.test.ts`
  - **Estimated**: 3 hours
  - **Dependencies**: TASK-204

- [ ] **TASK-254**: Backend integration tests for user profile API
  - Test GET /users/me
  - Test GET /users/me/loans
  - Test GET /users/me/reservations
  - **Files**: `backend/tests/integration/users.test.ts`
  - **Estimated**: 2 hours
  - **Dependencies**: TASK-206

### Phase 6: Documentation & Polish

- [ ] **TASK-261**: Update README with User Story 2 features
  - Document authentication setup
  - Document loan request flow
  - Document reservation queue
  - **Files**: `README.md`
  - **Estimated**: 1 hour

- [ ] **TASK-262**: Create API documentation for loan endpoints
  - Document authentication requirements
  - Document request/response formats
  - Document error codes
  - **Files**: `docs/api/loan-requests.md`
  - **Estimated**: 1.5 hours

- [ ] **TASK-263**: Add user guide for loan requests
  - How to authenticate with 42
  - How to request a loan
  - Understanding queue positions
  - **Files**: `docs/user-guide/loan-requests.md`
  - **Estimated**: 1 hour

## Summary

**Total Tasks**: 36  
**Estimated Time**: ~70 hours (~2 weeks with 1 developer)

**Critical Path**:
1. Backend setup (TASK-201 → 202 → 203 → 204 → 205 → 206)
2. Flutter data layer (TASK-211 → 212 → 213/214 → 215)
3. State management (TASK-221 → 222/223)
4. UI implementation (TASK-231 → 232 → 234 → 236)
5. Testing (TASK-241-254)
6. Documentation (TASK-261-263)

**Parallel Opportunities**:
- Phase 1 & Phase 5 can start in parallel (Backend testing doesn't block Flutter development)
- Within Phase 3, TASK-235 and TASK-236 can run parallel after TASK-234
- Phase 4 tests can run parallel once dependencies are complete

## Acceptance Criteria Validation

This implementation covers all acceptance scenarios from User Story 2:

1. ✅ **AS-1**: "Request Loan" button visible for authenticated users on available books
2. ✅ **AS-2**: Loan request recorded with student ID and timestamp
3. ✅ **AS-3**: Multiple students can reserve same book (FIFO queue)
4. ✅ **AS-4**: First person notified when book available, 24-hour window, auto-cancel
5. ✅ **AS-5**: User profile shows active requests and queue positions
6. ✅ **AS-6**: Admin dashboard receives loan requests (covered in Phase 0 backend)

## Risk Mitigation

**Risk 1**: 42 API changes or downtime
- Mitigation: Mock 42 API for development/testing, graceful error handling

**Risk 2**: Notification system complexity (24-hour expiration)
- Mitigation: Use backend cron job + database timestamps, test thoroughly

**Risk 3**: Race conditions in queue management
- Mitigation: Use database transactions, implement row-level locking

**Risk 4**: OAuth flow complexity on mobile
- Mitigation: Use battle-tested oauth2 package, implement fallback flows
