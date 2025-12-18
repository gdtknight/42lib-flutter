# Feature Specification: 42 Learning Space Library Management System

**Feature Branch**: `001-library-management`  
**Created**: 2025-12-17  
**Status**: Draft  
**Input**: User description: "42 학습 공간에 비치된 학습용 도서 관리용 앱을 제작할 예정. 일반 사용자용 앱을 제작하고, 도서 관리자를 위한 기능들은 웹으로 제공할 예정. 도서 개수는 약 500개 정도이고 공간상 제약으로 최대 1000개 정도까지 늘어날 것으로 예상함. 우선적으로 사용자 앱을 통해 도서 정보 열람이 가능하도록 할 것이고, 42 API 연동을 통해 도서 대출까지 확장할 계획을 가지고 있음. 도서 관리자용 기능은 도서 추가, 제거, 조회, 대출 관련 정보 조회가 필수로 들어갈 예정이고, 희망 도서 목록 수집과 관련된 기능도 추가적으로 들어갈 예정. 희망 도서는 반기 내지 분기 1회 정도로 요청받을 계획."

## Clarifications

### Session 2025-12-18

- Q: What is the testing and verification environment? → A: Docker Compose with project containers
- Q: How should developers respond when CI verification fails? → A: Checkout locally, re-run `scripts/local-verify.sh`, fix issues, verify locally, then re-push
- Q: What platform verification priority should be used based on developer environment? → A: macOS: iOS simulator build first; Linux/Windows: Web build first (fastest, least dependencies); Android optional (slowest)
- Q: How should documentation changes be validated? → A: Apply `dart format` automatically to documentation; exclude Markdown files from format checks; script auto-detects changed file types
- Q: How should verification results be recorded? → A: Log files: `logs/YYYY-MM-DD/verify-YYYYMMDD-HHmmss.log`; verification pass: simple checkmark output; verification fail: detailed error log; consider Git commit hook for auto-execution
- Q: What defines feature completion and MVP readiness? → A: Functional completeness P1 user stories + 80% coverage + README
- Q: How should platform-specific issues be tracked during development? → A: Create separate platform-specific issues, mark as "platform:android" or "platform:ios", continue Web development
- Q: How should MVP declaration be managed and verified? → A: Manual MVP declaration via GitHub milestone completion, CI workflow updated in separate PR
- Q: How should iOS verification be handled on non-macOS developer machines? → A: Skip iOS local verification on non-macOS, rely on CI/CD after MVP or use macOS for final validation
- Q: What is the development priority order across platforms? → A: Web-first development priority (fastest feedback), then Android, iOS last (slowest build)

## User Scenarios & Testing *(mandatory)*

### User Story 1 - Browse and Search Books in Mobile App (Priority: P1)

Students at 42 learning space need to discover available books in the library collection. They open the mobile app to browse through the catalog of approximately 500-1000 books, search by title, author, or topic, and view detailed information about each book including availability status.

**Why this priority**: This is the core value proposition - enabling students to find learning resources. Without this, the app has no purpose. This story delivers immediate value and can stand alone as a viable MVP.

**Independent Test**: Can be fully tested by launching the app, browsing the book list, performing searches, and viewing book details. Delivers value by helping students discover available learning materials without visiting the physical library.

**Design/UX Requirements**:
- Visual identity: Use 42 brand colors (typically teal/cyan and dark theme) as primary color scheme
- User convenience: Quick search with auto-complete, filters by category/topic, and clear availability indicators
- UI simplicity: Clean card-based layout for book listings, minimal steps to find and view book information

**Acceptance Scenarios**:

1. **Given** a student opens the mobile app, **When** they view the home screen, **Then** they see a list of all available books with title, author, and availability status
2. **Given** a student is browsing books, **When** they tap on a book card, **Then** they see detailed information including description, publication year, category, and current availability
3. **Given** a student wants to find a specific book, **When** they type in the search bar, **Then** results filter in real-time showing matching titles and authors
4. **Given** a student views book details, **When** the book is currently borrowed, **Then** they see "Currently Unavailable" status with expected return date displayed
5. **Given** there are multiple books in the library, **When** a student applies category filters, **Then** only books matching selected categories are displayed

---

### User Story 2 - Request Book Loans via Mobile App (Priority: P2)

Students who find a book they want to borrow can submit a loan request through the mobile app. The system integrates with 42 API for authentication and tracks loan requests which library administrators can process.

**Why this priority**: This extends the P1 browsing feature to enable the core library function of borrowing books. While browsing is useful alone, loan requests provide the complete library experience and are essential for long-term value.

**Independent Test**: Can be tested by authenticating via 42 API, selecting an available book, requesting a loan, and verifying the request appears in the admin system. Delivers value by digitizing the borrowing process.

**Acceptance Scenarios**:

1. **Given** a student is authenticated with 42 API credentials, **When** they view an available book, **Then** they see a "Request Loan" button
2. **Given** a student taps "Request Loan", **When** they confirm the request, **Then** the system records the loan request with student ID and timestamp
3. **Given** a book has an active loan request, **When** another student views it, **Then** the book shows available status and allows additional reservation requests, creating a FIFO queue of waiting students
4. **Given** a book becomes available while reservations exist, **When** the first person in the queue is notified, **Then** they have 24 hours to complete the loan before the reservation automatically cancels and moves to the next person in queue
5. **Given** a student has requested a loan, **When** they view their profile, **Then** they see a list of their active loan requests and their position in any reservation queues
6. **Given** a loan request is submitted, **When** an administrator views the admin dashboard, **Then** the request appears in the pending loans list

---

### User Story 3 - Submit Book Suggestions (Priority: P3)

Students can suggest books they would like to see added to the library collection. These suggestions are collected quarterly or bi-annually for review by library administrators.

**Why this priority**: This enhances library curation by gathering user input, but the library can function without it. It's a nice-to-have feature that improves collection relevance over time.

**Independent Test**: Can be tested by submitting a book suggestion through the app and verifying it appears in the admin dashboard's suggestion collection. Delivers value by giving students a voice in library expansion.

**Acceptance Scenarios**:

1. **Given** a student opens the app, **When** they navigate to "Suggest a Book" section, **Then** they see a form to enter book details (title, author, reason for suggestion)
2. **Given** a student fills out the suggestion form, **When** they submit it, **Then** the system saves the suggestion with student ID and submission date
3. **Given** a suggestion period is active, **When** a student submits a suggestion, **Then** they receive confirmation that it will be reviewed in the next collection cycle
4. **Given** a suggestion period has closed, **When** a student tries to submit, **Then** they see a message indicating when the next suggestion period opens
5. **Given** multiple students suggest the same book, **When** viewing admin dashboard, **Then** duplicate suggestions are grouped showing total request count

---

### User Story 4 - Manage Library Catalog via Web Dashboard (Priority: P1)

Library administrators access a web dashboard to manage the book collection. They can add new books to the catalog with all relevant details, update book information, remove books that are no longer available, and search/browse the entire collection.

**Why this priority**: Administrator functionality is essential for maintaining the library - without it, the catalog cannot be updated. This is co-P1 with user browsing as both are required for a functioning system.

**Independent Test**: Can be tested by logging into the web dashboard, adding/editing/removing books, and verifying changes reflect in both admin and user views. Delivers value by enabling library maintenance.

**Acceptance Scenarios**:

1. **Given** an administrator accesses the web dashboard, **When** they click "Add Book", **Then** they see a form with fields for title, author, ISBN, category, description, publication year, and quantity
2. **Given** an administrator fills out the book form, **When** they submit it, **Then** the new book appears in both the admin catalog and mobile app
3. **Given** an administrator views the book list, **When** they search or filter by category, **Then** results update to show matching books
4. **Given** an administrator selects a book, **When** they click "Edit", **Then** they can modify book details and save changes
5. **Given** an administrator selects a book, **When** they click "Remove", **Then** they see a confirmation dialog and upon confirming, the book is removed from the system
6. **Given** a book has active loans or loan requests, **When** an administrator tries to remove it, **Then** the system displays a warning message about active loans and provides an option to force removal, which will cancel all pending reservations and mark the book as permanently unavailable

---

### User Story 5 - Track and Manage Loans via Web Dashboard (Priority: P2)

Library administrators view and manage all loan activity through the web dashboard. They can see pending loan requests, approve or reject requests, view currently active loans, process book returns, and view loan history.

**Why this priority**: This complements the mobile loan request feature (User Story 2) by providing the admin side of loan management. Essential for operating a lending library but depends on the catalog management foundation.

**Independent Test**: Can be tested by processing loan requests, marking books as returned, and viewing loan history reports. Delivers value by digitizing loan tracking and reducing manual paperwork.

**Acceptance Scenarios**:

1. **Given** an administrator accesses the loans section, **When** they view pending requests, **Then** they see a list with student name, book title, and request date
2. **Given** an administrator views a loan request, **When** they click "Approve", **Then** the loan status changes to "Active" and the book availability updates
3. **Given** an active loan exists, **When** an administrator clicks "Mark as Returned", **Then** the loan status changes to "Completed" and the book becomes available again
4. **Given** an administrator wants to track overdue items, **When** they view active loans, **Then** loans past their return date are highlighted or flagged
5. **Given** loan data exists, **When** an administrator requests a loan history report, **Then** they can view/export data filtered by date range, student, or book

---

### User Story 6 - Review Book Suggestions via Web Dashboard (Priority: P3)

Library administrators access collected book suggestions through the web dashboard. They can view all suggestions submitted during the current collection period, see how many students requested each book, and mark suggestions as approved, rejected, or under consideration.

**Why this priority**: This is the admin counterpart to User Story 3. It enables data-driven collection expansion but is not critical for core library operations.

**Independent Test**: Can be tested by viewing the suggestions dashboard, filtering by date range, and updating suggestion statuses. Delivers value by streamlining the collection review process.

**Acceptance Scenarios**:

1. **Given** an administrator accesses the suggestions section, **When** they view the list, **Then** they see all submitted suggestions with book details, requester count, and submission dates
2. **Given** multiple students suggested the same book, **When** viewing the list, **Then** suggestions are grouped showing total request count
3. **Given** an administrator reviews a suggestion, **When** they mark it as "Approved", **Then** they can optionally add it directly to the catalog or track it for future purchase
4. **Given** a new suggestion period begins, **When** viewing the dashboard, **Then** previous period suggestions are archived and the list shows current period only
5. **Given** an administrator wants to analyze trends, **When** they view suggestion statistics, **Then** they see most requested categories or authors

---

### Edge Cases

- What happens when a student tries to request a loan for a book that just became unavailable (race condition)?
- How does the system handle books with multiple copies (same title/author but quantity > 1)?
- What happens if 42 API authentication fails or is unavailable during loan requests?
- How does the system handle book data with missing fields (e.g., no ISBN, unknown author)?
- How does the system handle duplicate book entries (same ISBN added twice)?
- What happens to reservation queues if a book is force-removed from the system?
- What happens if a student in a reservation queue deletes their account or leaves 42?
- How does the mobile app behave when offline or with poor connectivity?
- What happens if the catalog exceeds 1000 books (stated maximum capacity)?
- How are students notified when they reach the front of a reservation queue?
- What happens if multiple copies of a book are available and multiple reservations exist?
- How does the system handle time zone differences for 24-hour reservation expiration?
- **CI Failure Recovery**: When CI verification fails, developers MUST checkout the branch locally, re-run `scripts/local-verify.sh` to reproduce the issue, fix the root cause, verify the fix passes locally, then re-push to trigger CI again
- **Verification Script Behavior**: The `scripts/local-verify.sh` script MUST auto-detect file types in changed files and apply appropriate checks (Dart formatting for `.dart` files, skip formatting for `.md` files)

## Requirements *(mandatory)*

### Functional Requirements

**Mobile App - User Features**

- **FR-001**: System MUST display a browsable catalog of all books with title, author, and availability status
- **FR-002**: System MUST provide search functionality that filters books by title and author in real-time
- **FR-003**: System MUST provide category/topic filters to narrow book listings
- **FR-004**: System MUST display detailed book information including title, author, description, category, publication year, ISBN, and availability
- **FR-005**: System MUST authenticate students via 42 API integration
- **FR-006**: System MUST allow authenticated students to submit loan requests for available books
- **FR-007**: System MUST display loan request status (pending, approved, active, completed) to students
- **FR-007a**: System MUST display expected return dates for books currently on loan
- **FR-008**: System MUST allow students to view their personal loan history and active loans
- **FR-008a**: System MUST allow multiple students to reserve the same book, creating a FIFO (first-in-first-out) reservation queue
- **FR-008b**: System MUST automatically notify the first person in the reservation queue when a book becomes available
- **FR-008c**: System MUST automatically cancel reservations if the notified student does not complete the loan within 24 hours
- **FR-008d**: System MUST automatically move to the next person in the reservation queue after a reservation expires
- **FR-008e**: System MUST display the student's position in any reservation queues in their profile
- **FR-009**: System MUST allow students to submit book suggestions with title, author, and reason
- **FR-010**: System MUST display suggestion submission periods and block submissions outside active periods
- **FR-011**: System MUST provide confirmation messages for all user actions (loan requests, suggestions submitted)
- **FR-012**: System MUST handle offline scenarios gracefully with cached data and queue actions when connectivity is restored

**Web Dashboard - Administrator Features**

- **FR-013**: System MUST provide administrator authentication for web dashboard access
- **FR-014**: System MUST allow administrators to add new books with all catalog details (title, author, ISBN, category, description, publication year, quantity)
- **FR-015**: System MUST allow administrators to edit existing book information
- **FR-016**: System MUST allow administrators to remove books from the catalog
- **FR-016a**: System MUST display a warning message when administrators attempt to remove books with active loans or reservations
- **FR-016b**: System MUST provide an option for administrators to force removal of books with active loans
- **FR-016c**: System MUST cancel all pending reservations when a book is force-removed
- **FR-017**: System MUST allow administrators to search and filter the book catalog
- **FR-018**: System MUST display all pending loan requests with student information and request date
- **FR-019**: System MUST allow administrators to approve or reject loan requests
- **FR-020**: System MUST display all active loans with student information, book details, and loan date
- **FR-021**: System MUST allow administrators to mark loans as returned
- **FR-022**: System MUST display loan history with filtering by date range, student, or book
- **FR-023**: System MUST highlight or flag overdue loans based on expected return dates
- **FR-024**: System MUST display all book suggestions grouped by book with requester count
- **FR-025**: System MUST allow administrators to mark suggestions as approved, rejected, or under consideration
- **FR-026**: System MUST archive suggestions when a new collection period begins

**Data Management**

- **FR-027**: System MUST support catalog sizes up to 1000 books without performance degradation
- **FR-028**: System MUST track book quantities and update availability based on active loans
- **FR-029**: System MUST prevent duplicate book entries based on ISBN
- **FR-030**: System MUST handle books with missing optional fields (ISBN, description)
- **FR-031**: System MUST timestamp all transactions (loans, returns, suggestions) for audit trail
- **FR-032**: System MUST synchronize data between mobile app and web dashboard in real-time

### Design & UX Requirements

- **DR-001**: Visual design MUST use 42 brand identity colors (teal/cyan and dark theme) as primary scheme
- **DR-002**: Mobile app UI MUST prioritize quick discovery with prominent search bar and category filters
- **DR-003**: Interface MUST pursue simplicity with card-based layouts for book browsing
- **DR-004**: Book detail screens MUST display information hierarchically with availability status prominently shown
- **DR-005**: Web dashboard MUST use responsive design suitable for desktop browsers
- **DR-006**: Administrative actions MUST include confirmation dialogs for destructive operations (book removal, loan rejection)
- **DR-007**: Loading states and progress indicators MUST be shown for all async operations

### Platform & Environment Requirements

- **PR-001**: Mobile app MUST work identically on iOS and Android platforms
- **PR-002**: iOS compatibility MUST support iOS 17, 16, 15, and 14
- **PR-003**: Android compatibility MUST support Android 14, 13, 12, and 11
- **PR-004**: Web dashboard MUST support modern browsers (Chrome, Safari, Firefox, Edge - latest 2 versions)
- **PR-005**: Development and testing MUST be conducted within Docker Compose environment with project containers
- **PR-006**: Platform-specific code MUST be minimized and isolated in lib/platform/
- **PR-007**: 42 API integration MUST handle authentication failures gracefully with user-friendly error messages
- **PR-008**: Local verification script `scripts/local-verify.sh` MUST be provided for developers to run identical CI checks locally
- **PR-009**: Platform verification priority MUST be: macOS environments prioritize iOS simulator builds first; Linux/Windows environments prioritize Web builds first (fastest with minimal dependencies); Android builds are optional (slowest)
- **PR-010**: Code formatting via `dart format` MUST be applied automatically to Dart source files; Markdown files MUST be excluded from format checks
- **PR-011**: Verification results MUST be logged to `logs/YYYY-MM-DD/verify-YYYYMMDD-HHmmss.log` with simple checkmark output on success and detailed error logs on failure

### Development Workflow Requirements

- **DW-001**: Development priority order MUST be Web-first (fastest feedback), then Android, iOS last (slowest build)
- **DW-002**: Platform-specific issues MUST be tracked separately with labels "platform:android" or "platform:ios"
- **DW-003**: Web development MAY continue independently when platform-specific blockers exist
- **DW-004**: iOS local verification MUST be skipped on non-macOS developer machines; rely on CI/CD after MVP or use macOS for final validation
- **DW-005**: MVP declaration MUST be managed manually via GitHub milestone completion
- **DW-006**: CI workflow updates for MVP gating MUST be implemented in a separate PR (not in feature branch)

### Key Entities

- **Book**: Represents a physical book in the library collection with attributes including title, author, ISBN, category/topic, description, publication year, quantity (number of copies), and current availability status
- **Loan Request**: Represents a student's request to borrow a book, linked to Student (via 42 API ID) and Book, with status (pending, approved, rejected), request date, and approval date
- **Book Reservation**: Represents a student's place in the queue for a currently unavailable book, with Student ID, Book reference, reservation timestamp, queue position, notification timestamp (when student was notified of availability), and expiration timestamp (24 hours after notification)
- **Active Loan**: Represents an ongoing book loan with Student ID, Book reference, checkout date, expected return date, and actual return date when completed
- **Book Suggestion**: Represents a student's suggestion for library addition with suggested book details (title, author), student ID, reason for suggestion, submission date, and collection period
- **Student**: Identified via 42 API integration with minimal stored data (42 ID, name from API) - primary data remains in 42 system
- **Administrator**: User with elevated privileges for catalog and loan management with authentication credentials for web dashboard
- **Collection Period**: Time window (quarterly or bi-annually) during which book suggestions are accepted

## Success Criteria *(mandatory)*

### MVP Readiness Definition

**MVP-001**: MVP is declared complete when ALL of the following conditions are met:
- All P1 (Priority 1) user stories are functionally complete and tested
- Test coverage reaches minimum 80% across all modules
- README documentation is complete with setup, architecture, and usage instructions

### Measurable Outcomes

**User Experience Metrics**

- **SC-001**: Students can find a book and view its details within 30 seconds of opening the app
- **SC-002**: Book search returns relevant results within 1 second of user input
- **SC-003**: 90% of students successfully complete their first loan request without assistance
- **SC-004**: Students can browse the entire catalog of 500-1000 books without performance lag or loading delays

**Administrative Efficiency Metrics**

- **SC-005**: Administrators can add a new book to the catalog in under 2 minutes
- **SC-006**: Administrators can process (approve/reject) a loan request in under 30 seconds
- **SC-007**: Loan history reports can be generated and viewed within 5 seconds for any date range
- **SC-008**: Book suggestion review process can be completed for a quarterly collection (50-100 suggestions) in under 1 hour

**System Performance Metrics**

- **SC-009**: System maintains responsive performance (< 2 second page loads) with 1000 books in catalog
- **SC-010**: System handles 50 concurrent mobile app users without degradation
- **SC-011**: Data synchronization between mobile app and web dashboard occurs within 10 seconds of any change
- **SC-012**: Mobile app functions with cached data when offline, synchronizing changes when connectivity restored

**Feature Adoption Metrics**

- **SC-013**: 70% of 42 learning space students install and use the mobile app within first month of launch
- **SC-014**: Average of 20-30 loan requests processed per week (indicating active usage)
- **SC-015**: Student book suggestions collected reach 50-100 submissions per collection period
- **SC-016**: 95% of loan requests are processed by administrators within 24 hours

## Assumptions

- Students have smartphones with iOS or Android operating systems
- 42 API provides stable authentication endpoints and student identification data
- Internet connectivity is available in the 42 learning space for mobile app usage
- A single administrator or small admin team will manage the system
- Books are physical items shelved in the learning space, not digital/ebooks
- Loan periods will be defined by administrators (default assumption: 2-week loans)
- Collection periods for suggestions occur 2-4 times per year (quarterly or bi-annually)
- Book catalog will grow gradually from current 500 books toward 1000 book maximum
- Students are trusted users within the 42 community (no complex fraud prevention needed initially)
- Web dashboard administrators access the system from desktop/laptop computers
- Basic book metadata (title, author, category) will be manually entered by administrators
- ISBN is optional as some educational materials may not have ISBN numbers

## Dependencies

- **42 API Access**: Authentication and student identification depends on stable 42 API endpoints
- **Hosting Infrastructure**: System requires cloud hosting or server infrastructure for backend services (assumed available)
- **Initial Book Data**: Library catalog must be populated with initial 500 books before user launch
- **Administrator Training**: Admin users need basic training on web dashboard functionality
- **Network Connectivity**: Both mobile app and web dashboard require internet connectivity for real-time sync
- **Docker Compose Environment**: Development requires Docker Compose with project containers configured for testing and verification workflows
- **Git Commit Hooks**: Optional but recommended for automated local verification before pushing to CI

## Future Extensibility

This specification focuses on the core library management functionality with the following extensions planned for future phases:

- **Phase 2**: Full loan lifecycle management including automated reminders and overdue notifications (note: loan extension functionality is not planned)
- **Phase 3**: QR code or barcode scanning for quick book lookup and checkout
- **Phase 4**: Reading statistics and recommendation engine based on user behavior
- **Phase 5**: Integration with external book databases (Google Books, Open Library) for automated metadata population
- **Phase 6**: Discussion forums or review system for books in the collection
- **Phase 7**: Advanced analytics on reservation patterns and book popularity trends
