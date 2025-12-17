# Data Model: 42 Learning Space Library Management System

**Branch**: `001-library-management` | **Date**: 2025-12-17 | **Phase**: 1 - Design

## Purpose

This document defines all data entities extracted from the feature specification, their fields, relationships, validation rules, and state transitions.

---

## 1. Entity: Book

**Description**: Represents a physical book in the library collection.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique book identifier |
| title | String | Yes | 1-500 chars | Book title |
| author | String | Yes | 1-200 chars | Author name(s) |
| isbn | String | No | ISBN-10 or ISBN-13 format | International Standard Book Number |
| category | String | Yes | 1-100 chars | Book category/topic (e.g., "Programming", "Design") |
| description | Text | No | 0-2000 chars | Book description |
| publicationYear | Integer | No | 1000-2100 | Year of publication |
| quantity | Integer | Yes | Min: 1, Max: 100 | Total number of copies |
| availableQuantity | Integer | Yes | Min: 0, Max: quantity | Currently available copies |
| coverImageUrl | String | No | Valid URL | Book cover image URL |
| createdAt | Timestamp | Yes | Auto-generated | Record creation timestamp |
| updatedAt | Timestamp | Yes | Auto-updated | Last update timestamp |

### Validation Rules

- **VR-001**: `title` must not be empty or whitespace-only
- **VR-002**: `author` must not be empty or whitespace-only
- **VR-003**: `isbn` if provided, must match ISBN-10 (10 digits) or ISBN-13 (13 digits) format
- **VR-004**: `isbn` must be unique across all books (FR-029: prevent duplicates)
- **VR-005**: `quantity` must be at least 1
- **VR-006**: `availableQuantity` must be between 0 and `quantity` (inclusive)
- **VR-007**: `publicationYear` if provided, must be between 1000 and current year + 1
- **VR-008**: `category` must not be empty or whitespace-only

### Relationships

- **One-to-Many** with `LoanRequest`: A book can have multiple loan requests
- **One-to-Many** with `Reservation`: A book can have multiple active reservations
- **One-to-Many** with `Loan`: A book can have multiple loan records (history)
- **One-to-Many** with `BookSuggestion`: Students may suggest the same book multiple times

### State Transitions

**Availability Status** (derived from `availableQuantity`):
- `Available`: `availableQuantity > 0`
- `Unavailable`: `availableQuantity == 0`

**Lifecycle States**:
1. **Created**: Book added to catalog by administrator
2. **Active**: Book available for browsing and loans
3. **Removed**: Book soft-deleted (marked inactive but retained in history)

### Business Rules

- **BR-001**: When a loan is approved, `availableQuantity` decreases by 1
- **BR-002**: When a book is returned, `availableQuantity` increases by 1
- **BR-003**: Books with `availableQuantity = 0` can still receive reservations (FR-008a)
- **BR-004**: Books cannot be deleted if active loans exist (warning shown, force delete option per FR-016a)

---

## 2. Entity: Student

**Description**: Represents a student user authenticated via 42 API.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Internal student identifier |
| fortytwoUserId | Integer | Yes | Unique | 42 API user ID |
| username | String | Yes | 1-50 chars | 42 username (login) |
| email | String | Yes | Valid email format | 42 email address |
| fullName | String | Yes | 1-200 chars | Student's full name from 42 API |
| createdAt | Timestamp | Yes | Auto-generated | First login timestamp |
| lastLoginAt | Timestamp | Yes | Auto-updated | Last login timestamp |

### Validation Rules

- **VR-101**: `fortytwoUserId` must be unique (one student per 42 account)
- **VR-102**: `email` must be valid email format
- **VR-103**: Data synchronized from 42 API on each login (source of truth: 42 API)

### Relationships

- **One-to-Many** with `LoanRequest`: A student can submit multiple loan requests
- **One-to-Many** with `Reservation`: A student can have multiple active reservations
- **One-to-Many** with `Loan`: A student can have multiple loan records
- **One-to-Many** with `BookSuggestion`: A student can submit multiple suggestions

### Business Rules

- **BR-101**: Student data minimal storage (GDPR compliance, 42 API as source)
- **BR-102**: Student account created automatically on first 42 OAuth login
- **BR-103**: Student data refreshed from 42 API on each login

---

## 3. Entity: LoanRequest

**Description**: Represents a student's request to borrow a book.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique loan request identifier |
| studentId | UUID | Yes | Foreign Key → Student | Requesting student |
| bookId | UUID | Yes | Foreign Key → Book | Requested book |
| status | Enum | Yes | `pending`, `approved`, `rejected`, `cancelled` | Request status |
| requestDate | Timestamp | Yes | Auto-generated | Request submission timestamp |
| reviewedAt | Timestamp | No | Set on approval/rejection | Admin review timestamp |
| reviewedBy | UUID | No | Foreign Key → Administrator | Reviewing administrator |
| rejectionReason | Text | No | 0-500 chars | Optional reason for rejection |
| notes | Text | No | 0-1000 chars | Additional notes from admin or student |

### Validation Rules

- **VR-201**: `studentId` must exist in Student table
- **VR-202**: `bookId` must exist in Book table
- **VR-203**: `status` must be one of: `pending`, `approved`, `rejected`, `cancelled`
- **VR-204**: `reviewedAt` required if status is `approved` or `rejected`
- **VR-205**: Student cannot have duplicate pending requests for same book

### Relationships

- **Many-to-One** with `Student`: Multiple requests by one student
- **Many-to-One** with `Book`: Multiple requests for one book
- **Many-to-One** with `Administrator`: Administrator who reviewed
- **One-to-One** with `Loan` (optional): If approved, creates a Loan record

### State Transitions

```
[Created] → pending
          ↓
pending → approved → Loan created
       → rejected
       → cancelled (by student)
```

### Business Rules

- **BR-201**: Status starts as `pending` on creation
- **BR-202**: When approved, create `Loan` record and decrease `Book.availableQuantity`
- **BR-203**: If book unavailable when approved, create `Reservation` instead
- **BR-204**: Student can cancel only `pending` requests
- **BR-205**: Administrators see pending requests in dashboard (FR-018)

---

## 4. Entity: Reservation

**Description**: Represents a student's place in the waiting queue for an unavailable book.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique reservation identifier |
| studentId | UUID | Yes | Foreign Key → Student | Student in queue |
| bookId | UUID | Yes | Foreign Key → Book | Reserved book |
| queuePosition | Integer | Yes | Min: 1 | Position in FIFO queue (1 = first) |
| status | Enum | Yes | `waiting`, `notified`, `expired`, `fulfilled`, `cancelled` | Reservation status |
| createdAt | Timestamp | Yes | Auto-generated | Reservation creation timestamp |
| notifiedAt | Timestamp | No | Set when book becomes available | Notification sent timestamp |
| expiresAt | Timestamp | No | `notifiedAt + 24 hours` | Reservation expiration timestamp |
| fulfilledAt | Timestamp | No | Set when loan completed | Fulfillment timestamp |

### Validation Rules

- **VR-301**: `studentId` must exist in Student table
- **VR-302**: `bookId` must exist in Book table
- **VR-303**: `status` must be one of: `waiting`, `notified`, `expired`, `fulfilled`, `cancelled`
- **VR-304**: `queuePosition` must be unique per book (1, 2, 3, ... N)
- **VR-305**: `notifiedAt` required if status is `notified`, `expired`, or `fulfilled`
- **VR-306**: `expiresAt` = `notifiedAt + 24 hours` when status becomes `notified`

### Relationships

- **Many-to-One** with `Student`: Multiple reservations by one student
- **Many-to-One** with `Book`: Multiple reservations for one book
- **One-to-One** with `Loan` (optional): When fulfilled, creates Loan record

### State Transitions

```
[Created] → waiting (in queue)
          ↓ (book becomes available + first in queue)
waiting → notified (24-hour timer starts)
       → cancelled (by student or book removed)
          ↓ (student completes loan within 24h)
notified → fulfilled (Loan created)
         → expired (24h passed) → next in queue notified
```

### Business Rules

- **BR-301**: Reservations managed as FIFO queue per book (FR-008a)
- **BR-302**: When book returned, notify first `waiting` reservation (queuePosition = 1)
- **BR-303**: If notified student doesn't complete loan within 24h, status → `expired`, next in queue notified (FR-008c, FR-008d)
- **BR-304**: When reservation fulfilled, create `Loan` record and decrease `Book.availableQuantity`
- **BR-305**: When reservation cancelled/expired, reorder queue (update queuePosition for remaining)
- **BR-306**: Students see their queue position in profile (FR-008e)

---

## 5. Entity: Loan

**Description**: Represents an active or completed book loan.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique loan identifier |
| studentId | UUID | Yes | Foreign Key → Student | Borrowing student |
| bookId | UUID | Yes | Foreign Key → Book | Borrowed book |
| loanRequestId | UUID | No | Foreign Key → LoanRequest | Original loan request (if applicable) |
| reservationId | UUID | No | Foreign Key → Reservation | Original reservation (if applicable) |
| status | Enum | Yes | `active`, `returned`, `overdue` | Loan status |
| checkoutDate | Timestamp | Yes | Auto-generated | Loan start timestamp |
| dueDate | Timestamp | Yes | `checkoutDate + 14 days` (default) | Expected return date |
| returnedDate | Timestamp | No | Set when book returned | Actual return timestamp |
| approvedBy | UUID | Yes | Foreign Key → Administrator | Administrator who approved loan |
| notes | Text | No | 0-1000 chars | Additional notes |

### Validation Rules

- **VR-401**: `studentId` must exist in Student table
- **VR-402**: `bookId` must exist in Book table
- **VR-403**: `status` must be one of: `active`, `returned`, `overdue`
- **VR-404**: `dueDate` must be after `checkoutDate`
- **VR-405**: `returnedDate` if set, must be after `checkoutDate`
- **VR-406**: Either `loanRequestId` or `reservationId` should be set (traceability)

### Relationships

- **Many-to-One** with `Student`: Multiple loans by one student
- **Many-to-One** with `Book`: Multiple loans for one book (over time)
- **One-to-One** with `LoanRequest`: Originated from a loan request
- **One-to-One** with `Reservation`: Originated from a reservation
- **Many-to-One** with `Administrator`: Administrator who approved

### State Transitions

```
[Created] → active (checkout date = now, due date = +14 days)
          ↓ (due date passed, not returned)
active → overdue (flagged in admin dashboard)
      → returned (book available again)
```

### Business Rules

- **BR-401**: Default loan period is 14 days (assumption from spec)
- **BR-402**: When loan created, decrease `Book.availableQuantity` by 1
- **BR-403**: When loan returned, increase `Book.availableQuantity` by 1
- **BR-404**: When book returned, check if reservations exist → notify first in queue (BR-302)
- **BR-405**: Status automatically becomes `overdue` if `dueDate` passed and not returned (FR-023)
- **BR-406**: Overdue loans highlighted in admin dashboard (FR-023)
- **BR-407**: Loan history retained indefinitely for audit trail (FR-031)

---

## 6. Entity: BookSuggestion

**Description**: Represents a student's suggestion to add a book to the library.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique suggestion identifier |
| studentId | UUID | Yes | Foreign Key → Student | Suggesting student |
| suggestedTitle | String | Yes | 1-500 chars | Suggested book title |
| suggestedAuthor | String | Yes | 1-200 chars | Suggested book author |
| reason | Text | No | 0-1000 chars | Why student wants this book |
| collectionPeriodId | UUID | Yes | Foreign Key → CollectionPeriod | Collection period |
| status | Enum | Yes | `submitted`, `approved`, `rejected`, `under_review` | Suggestion status |
| submittedAt | Timestamp | Yes | Auto-generated | Submission timestamp |
| reviewedAt | Timestamp | No | Set when reviewed | Admin review timestamp |
| reviewedBy | UUID | No | Foreign Key → Administrator | Reviewing administrator |
| adminNotes | Text | No | 0-500 chars | Admin's notes on decision |

### Validation Rules

- **VR-501**: `studentId` must exist in Student table
- **VR-502**: `suggestedTitle` must not be empty or whitespace-only
- **VR-503**: `suggestedAuthor` must not be empty or whitespace-only
- **VR-504**: `collectionPeriodId` must exist in CollectionPeriod table
- **VR-505**: `status` must be one of: `submitted`, `approved`, `rejected`, `under_review`
- **VR-506**: Student can only submit during active collection period (FR-010)

### Relationships

- **Many-to-One** with `Student`: Multiple suggestions by one student
- **Many-to-One** with `CollectionPeriod`: Multiple suggestions per period
- **Many-to-One** with `Administrator`: Administrator who reviewed

### State Transitions

```
[Created] → submitted (during active collection period)
          ↓ (admin review)
submitted → under_review → approved (optionally added to catalog)
                        → rejected
```

### Business Rules

- **BR-501**: Suggestions only accepted during active collection periods (FR-010)
- **BR-502**: Duplicate suggestions grouped by title+author, showing count (FR-025, SC-008)
- **BR-503**: When collection period ends, suggestions archived (FR-026)
- **BR-504**: Approved suggestions can be added to catalog directly from dashboard (FR-025)
- **BR-505**: Submission confirmation shown to student (FR-011)

---

## 7. Entity: CollectionPeriod

**Description**: Represents a time window for accepting book suggestions.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique period identifier |
| name | String | Yes | 1-100 chars | Period name (e.g., "2025 Q1 Suggestions") |
| startDate | Timestamp | Yes | Must be before endDate | Period start timestamp |
| endDate | Timestamp | Yes | Must be after startDate | Period end timestamp |
| status | Enum | Yes | `upcoming`, `active`, `closed` | Period status |
| createdAt | Timestamp | Yes | Auto-generated | Record creation timestamp |

### Validation Rules

- **VR-601**: `name` must be unique
- **VR-602**: `endDate` must be after `startDate`
- **VR-603**: `status` must be one of: `upcoming`, `active`, `closed`
- **VR-604**: Only one period can be `active` at a time

### Relationships

- **One-to-Many** with `BookSuggestion`: A period has multiple suggestions

### State Transitions

```
[Created] → upcoming (before startDate)
          ↓ (startDate reached)
upcoming → active (accepting suggestions)
        ↓ (endDate passed)
active → closed (archived)
```

### Business Rules

- **BR-601**: Status automatically updates based on current date vs startDate/endDate
- **BR-602**: Students can only submit suggestions when status = `active` (FR-010)
- **BR-603**: When period closes, suggestions archived but retained (FR-026)
- **BR-604**: Collection periods occur quarterly or bi-annually (assumption)

---

## 8. Entity: Administrator

**Description**: Represents an administrator user with elevated privileges.

### Fields

| Field | Type | Required | Constraints | Description |
|-------|------|----------|-------------|-------------|
| id | UUID | Yes | Primary Key | Unique administrator identifier |
| username | String | Yes | Unique, 3-50 chars | Login username |
| passwordHash | String | Yes | Bcrypt hash | Hashed password |
| email | String | Yes | Valid email format | Administrator email |
| fullName | String | Yes | 1-200 chars | Administrator full name |
| role | Enum | Yes | `admin`, `super_admin` | Administrator role level |
| createdAt | Timestamp | Yes | Auto-generated | Account creation timestamp |
| lastLoginAt | Timestamp | No | Auto-updated | Last login timestamp |

### Validation Rules

- **VR-701**: `username` must be unique and alphanumeric
- **VR-702**: `email` must be valid email format and unique
- **VR-703**: `passwordHash` must be bcrypt hash (never store plaintext)
- **VR-704**: `role` must be one of: `admin`, `super_admin`

### Relationships

- **One-to-Many** with `LoanRequest`: Administrator reviews loan requests
- **One-to-Many** with `Loan`: Administrator approves loans
- **One-to-Many** with `BookSuggestion`: Administrator reviews suggestions

### Business Rules

- **BR-701**: Separate authentication from 42 OAuth (internal admin accounts)
- **BR-702**: Password minimum 8 characters, must include uppercase, lowercase, number
- **BR-703**: `super_admin` can manage other administrators, `admin` cannot
- **BR-704**: Administrator credentials for web dashboard only (FR-013)

---

## Entity Relationship Diagram (ERD)

```
┌─────────────┐       ┌──────────────┐       ┌──────────────┐
│   Student   │──1:N──│ LoanRequest  │──N:1──│     Book     │
└─────────────┘       └──────────────┘       └──────────────┘
       │                      │                       │
       │                      │                       │
      1:N                    1:1                     1:N
       │                      │                       │
       ↓                      ↓                       ↓
┌─────────────┐       ┌──────────────┐       ┌──────────────┐
│Reservation  │       │     Loan     │       │BookSuggestion│
└─────────────┘       └──────────────┘       └──────────────┘
       │                      │                       │
       │                      │                       │
      N:1                    N:1                     N:1
       │                      │                       │
       ↓                      ↓                       ↓
┌─────────────┐       ┌──────────────┐       ┌──────────────┐
│    Book     │       │Administrator │       │CollectionPeriod│
└─────────────┘       └──────────────┘       └──────────────┘
```

---

## Database Indexing Strategy

**Critical Indexes** (for performance per FR-027, SC-009):

1. **Book**:
   - Primary index: `id` (UUID)
   - Composite index: `(title, author)` for search queries (FR-002)
   - Index: `isbn` for duplicate check (FR-029)
   - Index: `category` for filtering (FR-003)

2. **Student**:
   - Primary index: `id` (UUID)
   - Unique index: `fortytwoUserId` for 42 API lookups

3. **LoanRequest**:
   - Primary index: `id` (UUID)
   - Composite index: `(studentId, status)` for student's active requests
   - Composite index: `(bookId, status)` for pending requests per book
   - Index: `requestDate` for sorting

4. **Reservation**:
   - Primary index: `id` (UUID)
   - Composite index: `(bookId, queuePosition)` for FIFO queue management
   - Index: `(studentId, status)` for student's active reservations

5. **Loan**:
   - Primary index: `id` (UUID)
   - Composite index: `(studentId, status)` for student's loan history
   - Index: `dueDate` for overdue loan detection (FR-023)
   - Index: `returnedDate` for reporting

6. **BookSuggestion**:
   - Primary index: `id` (UUID)
   - Composite index: `(collectionPeriodId, status)` for period's suggestions
   - Composite index: `(suggestedTitle, suggestedAuthor)` for duplicate grouping (FR-025)

---

## Data Migration Strategy

**Initial Data Load**:
- Import ~500 existing books via CSV or admin bulk upload
- Create initial administrator accounts
- Set up first collection period

**Version Control**:
- Database schema versioned in repository
- Prisma migrations for schema changes
- Rollback capability for failed migrations

**Backup Strategy**:
- Daily automated PostgreSQL backups
- Retention: 30 days
- Point-in-time recovery enabled

---

## Data Model Summary

**Total Entities**: 8
- **Core**: Book, Student, Loan
- **Workflow**: LoanRequest, Reservation
- **Feature**: BookSuggestion, CollectionPeriod
- **System**: Administrator

**Relationships**: 17 (mostly Many-to-One with proper foreign keys)

**Complexity Score**: Medium
- Most entities have straightforward CRUD operations
- Reservation queue management adds moderate complexity (FIFO ordering, expiration)
- All validation rules defined explicitly for implementation

**Next Phase**: API Contract Generation (contracts/ directory)
