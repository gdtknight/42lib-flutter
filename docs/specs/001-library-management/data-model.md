# 데이터 모델: 42 학습 공간 도서 관리 시스템

**브랜치**: `001-library-management` | **날짜**: 2025-12-17 | **단계**: 1 - 설계

## 목적

이 문서는 기능 명세서에서 추출한 모든 데이터 엔티티, 필드, 관계, 검증 규칙 및 상태 전환을 정의합니다.

---

## 주요 엔티티

### 1. Book (도서)
물리적 도서를 나타냅니다.

**주요 필드**:
- id (UUID): 고유 식별자
- title (String): 도서 제목 (1-500자)
- author (String): 저자명 (1-200자)
- isbn (String): ISBN-10 또는 ISBN-13
- category (String): 카테고리 (예: "프로그래밍", "디자인")
- description (Text): 도서 설명 (0-2000자)
- quantity (Integer): 총 수량 (1-100)
- availableQuantity (Integer): 현재 대출 가능 수량
- coverImageUrl (String): 표지 이미지 URL

**검증 규칙**:
- 제목과 저자는 필수, 공백 불가
- ISBN은 고유해야 함 (중복 방지)
- 가용 수량은 0과 총 수량 사이여야 함

**상태 전환**:
- Available (대출 가능): availableQuantity > 0
- Unavailable (대출 불가): availableQuantity == 0

### 2. Student (학생)
42 API로 인증된 학생 사용자입니다.

**주요 필드**:
- id (UUID): 내부 식별자
- fortytwoUserId (Integer): 42 API 사용자 ID (고유)
- username (String): 42 사용자명
- email (String): 이메일 주소
- fullName (String): 전체 이름

### 3. Administrator (관리자)
도서 관리 권한을 가진 관리자입니다.

**주요 필드**:
- id (UUID): 내부 식별자
- fortytwoUserId (Integer): 42 API 사용자 ID (고유)
- username (String): 42 사용자명
- role (String): 관리자 역할 (예: "superadmin", "librarian")

### 4. LoanRequest (대출 요청)
학생의 도서 대출 요청입니다.

**주요 필드**:
- id (UUID): 요청 식별자
- studentId (UUID): 학생 ID (외래 키)
- bookId (UUID): 도서 ID (외래 키)
- status (Enum): PENDING, APPROVED, REJECTED, EXPIRED
- requestedAt (Timestamp): 요청 시간
- processedAt (Timestamp): 처리 시간

**상태 전환**:
1. PENDING → APPROVED (관리자 승인)
2. PENDING → REJECTED (관리자 거부)
3. PENDING → EXPIRED (24시간 자동 만료)

### 5. Loan (대출)
승인된 활성 대출 기록입니다.

**주요 필드**:
- id (UUID): 대출 식별자
- loanRequestId (UUID): 원본 요청 ID
- dueDate (Timestamp): 반납 예정일
- returnedAt (Timestamp): 실제 반납일 (nullable)
- status (Enum): ACTIVE, RETURNED, OVERDUE

### 6. Reservation (예약)
대출 불가능한 도서에 대한 FIFO 예약 큐입니다.

**주요 필드**:
- id (UUID): 예약 식별자
- studentId (UUID): 학생 ID
- bookId (UUID): 도서 ID
- queuePosition (Integer): 큐 내 위치
- notifiedAt (Timestamp): 알림 발송 시간
- expiresAt (Timestamp): 24시간 만료 시간

**비즈니스 규칙**:
- FIFO 방식으로 처리 (먼저 예약한 사람 우선)
- 알림 후 24시간 이내 미대출 시 자동 취소
- 취소 시 다음 사람에게 자동 알림

### 7. BookSuggestion (희망 도서)
학생의 도서 구매 제안입니다.

**주요 필드**:
- id (UUID): 제안 식별자
- studentId (UUID): 제안자 ID
- title (String): 제안 도서 제목
- author (String): 저자
- reason (Text): 제안 이유
- status (Enum): PENDING, APPROVED, REJECTED

### 8. SyncMetadata (동기화 메타데이터)
오프라인 동기화를 위한 추적 정보입니다.

**주요 필드**:
- id (UUID): 메타데이터 ID
- entityType (String): 엔티티 타입 (예: "book", "loan")
- entityId (UUID): 엔티티 ID
- lastSyncedAt (Timestamp): 마지막 동기화 시간
- changeType (Enum): CREATE, UPDATE, DELETE

---

## 엔티티 관계 다이어그램 (ERD)

```
Student (1) ──── (N) LoanRequest ──── (1) Book
  │                                      │
  │                                      │
  └──── (N) Reservation ──── (1) ────────┘
  │                                      │
  │                                      │
  └──── (N) Loan                         │
  │                                      │
  │                                      │
  └──── (N) BookSuggestion               │

Administrator (1) ──── (N) LoanRequest (processes)
```

---

## 데이터베이스 제약조건

### 외래 키
- LoanRequest.studentId → Student.id
- LoanRequest.bookId → Book.id
- Loan.loanRequestId → LoanRequest.id
- Reservation.studentId → Student.id
- Reservation.bookId → Book.id
- BookSuggestion.studentId → Student.id

### 고유 제약
- Book.isbn (NULL 허용 시 중복 불가)
- Student.fortytwoUserId
- Administrator.fortytwoUserId

### 체크 제약
- Book.availableQuantity <= Book.quantity
- Book.quantity >= 1
- Loan.returnedAt >= Loan.createdAt
- Reservation.expiresAt > Reservation.notifiedAt

---

## 인덱스 전략

**성능 최적화를 위한 인덱스**:

1. `books_search_idx`: (title, author, category) - 전체 텍스트 검색용
2. `loan_requests_student_idx`: (studentId, status) - 학생별 요청 조회
3. `loans_student_active_idx`: (studentId, status) - 활성 대출 조회
4. `reservations_book_queue_idx`: (bookId, queuePosition) - 예약 큐 순서
5. `sync_metadata_entity_idx`: (entityType, entityId, lastSyncedAt) - 동기화 델타 쿼리

---

## 데이터 마이그레이션 전략

### Phase 1: 초기 스키마
- 8개 테이블 생성
- 모든 제약조건 및 인덱스 설정
- 초기 시드 데이터 (관리자 계정, 샘플 도서)

### Phase 2: 프로덕션 데이터
- 500-1000권 도서 import
- 학생 계정 자동 생성 (42 OAuth 로그인 시)

### Phase 3: 변경 관리
- Sequelize 마이그레이션 사용
- 버전 제어된 마이그레이션 스크립트
- 롤백 가능한 변경사항

---

**다음 단계**: API 계약 정의 (contracts/openapi.yaml)
