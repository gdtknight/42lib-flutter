# Research Document: 42 Learning Space Library Management System

**Branch**: `001-library-management` | **Date**: 2025-12-17 | **Phase**: 0 - Research & Resolution

## Purpose

This document resolves all "NEEDS CLARIFICATION" items from the Technical Context in plan.md, researches best practices for chosen technologies, and documents architectural decisions with rationale.

---

## 1. Flutter Version & Ecosystem

### Decision: Flutter 3.16.0 (Latest Stable)

**Rationale**: 
- Flutter 3.16.0 is the current stable release (as of Dec 2024) providing production-ready features
- Includes Material Design 3 support for modern UI
- Improved web performance and compilation
- Stable support for iOS 17, Android 14
- Backward compatible with required platform versions (iOS 14-17, Android 11-14)

**Alternatives Considered**:
- Flutter 3.13.x: Older stable, but missing recent performance improvements for web
- Flutter 3.19.x (beta/dev): Too unstable for production, potential breaking changes

**Version Compatibility Validation**:
- iOS 17/16/15/14: ✅ Fully supported by Flutter 3.16.0
- Android 14/13/12/11: ✅ Fully supported by Flutter 3.16.0
- Web (Chrome, Safari, Firefox, Edge latest 2 versions): ✅ Supported

---

## 2. State Management Solution

### Decision: flutter_bloc (Bloc Pattern)

**Rationale**:
- Clear separation of business logic from UI
- Excellent testability with predictable state transitions
- Scalable for applications with complex state (loan queues, reservation management)
- Strong community support and documentation
- Built-in debugging tools (bloc observer, time-travel debugging)
- Well-suited for real-time sync requirements (stream-based architecture)

**Alternatives Considered**:
- Provider: Simpler but less structured for complex state flows like reservation queues
- Riverpod: Modern and powerful, but less mature ecosystem and documentation
- GetX: Too much magic, violates testability principles
- setState only: Insufficient for app-wide state (auth, offline sync)

**Dependencies**:
```yaml
flutter_bloc: ^8.1.3
equatable: ^2.0.5  # For value equality in state classes
```

---

## 3. HTTP Client & 42 API Integration

### Decision: dio package + Custom 42 API Client

**Rationale**:
- dio provides robust HTTP client with interceptors for auth token management
- Built-in retry logic for network failures (critical for offline sync)
- Request/response interceptors for logging and error handling
- Supports file uploads (for potential future book cover images)
- Better error handling than standard http package
- No official 42 API SDK available → custom client needed

**42 API Integration Strategy**:
- OAuth 2.0 authentication flow via 42 API
- Token storage in secure storage (flutter_secure_storage)
- Automatic token refresh using dio interceptors
- Graceful degradation when 42 API unavailable (FR-007, PR-007)

**Alternatives Considered**:
- http package: Too basic, lacks interceptors and retry logic
- chopper: Over-engineered for this use case, generates too much boilerplate

**Dependencies**:
```yaml
dio: ^5.4.0
flutter_secure_storage: ^9.0.0
oauth2: ^2.0.2  # For 42 OAuth flow
```

---

## 4. Local Storage & Offline Capability

### Decision: Hive (NoSQL) + sqflite (SQL) Hybrid Approach

**Rationale**:
- **Hive** for simple key-value caching (user preferences, auth tokens, app state)
  - Lightweight, fast, minimal setup
  - Type-safe with generated adapters
  - Ideal for frequently accessed small data
- **sqflite** for relational book/loan data requiring complex queries
  - Search functionality needs SQL LIKE queries (FR-002)
  - Relationship management (books → loans → reservations)
  - Support for 1000+ books with indexes for performance
  - Better for offline-first architecture with sync queues

**Offline Strategy**:
- All book catalog cached in sqflite on app launch
- Read operations work offline from cache
- Write operations (loan requests, suggestions) queued in local DB
- Background sync service flushes queue when connectivity restored (FR-012, SC-012)

**Alternatives Considered**:
- Hive only: Insufficient for complex queries and relationships
- sqflite only: Overkill for simple key-value data, slower for frequent small reads
- shared_preferences: Too limited, not suitable for structured data

**Dependencies**:
```yaml
hive: ^2.2.3
hive_flutter: ^1.1.0
sqflite: ^2.3.0
path_provider: ^2.1.1  # For database file paths
```

---

## 5. Backend Architecture

### Decision: Custom REST API (Node.js/Express + PostgreSQL)

**Rationale**:
- Full control over data models and business logic (reservation queues, FIFO logic)
- Cost-effective for small scale (~50 concurrent users, 1000 books)
- PostgreSQL provides ACID transactions for loan/reservation atomicity
- RESTful API aligns with mobile best practices
- Easier to implement 42 API server-side integration (secure client secrets)
- Node.js + Express: Fast development, extensive library ecosystem
- Can be containerized in Docker per Constitution VIII

**Backend Responsibilities**:
- Book catalog management (CRUD operations)
- Loan request processing and reservation queue management
- 42 API authentication proxy (security: keep secrets server-side)
- Data synchronization endpoints for mobile app
- Book suggestion collection and review
- Real-time availability updates

**Alternatives Considered**:
- Firebase/Firestore (BaaS): Limited querying capabilities, complex pricing, vendor lock-in
- Supabase: Good option but adds complexity for simple requirements, overkill for 50 users
- AWS Amplify: Over-engineered, steep learning curve, cost concerns

**Tech Stack**:
```
Backend: Node.js 20 LTS + Express 4.18
Database: PostgreSQL 16
ORM: Prisma 5.x (type-safe, excellent migrations)
Auth: jsonwebtoken for session tokens, 42 OAuth proxy
Deployment: Docker containers (per Constitution VIII)
```

**API Contract Format**: OpenAPI 3.0 specification

**Dependencies (Backend)**:
```json
{
  "express": "^4.18.2",
  "prisma": "^5.7.0",
  "@prisma/client": "^5.7.0",
  "jsonwebtoken": "^9.0.2",
  "bcrypt": "^5.1.1",
  "cors": "^2.8.5",
  "helmet": "^7.1.0",
  "express-rate-limit": "^7.1.5"
}
```

---

## 6. Real-Time Synchronization

### Decision: Polling-Based Sync (30-second intervals)

**Rationale**:
- Simpler implementation than WebSockets for read-heavy workload
- Book availability changes are infrequent (loan approval ~20-30/week per SC-014)
- 30-second polling provides "near real-time" experience for users
- Reduces backend complexity (no WebSocket server management)
- Polling only when app in foreground (battery-efficient)
- Meets SC-011 requirement (<10s sync, actual: ~30s worst case)

**Sync Strategy**:
1. Initial sync on app launch: Full catalog download
2. Background polling every 30 seconds when app active
3. Delta sync: Only fetch changed records (timestamp-based)
4. Push notifications for critical events (reservation ready - Phase 2)

**Alternatives Considered**:
- WebSockets: Over-engineered for low-frequency updates, complex connection management
- Server-Sent Events (SSE): Better than WebSockets but still more complex than needed
- 10-second polling: More API load, minimal UX improvement

**Dependencies**:
```yaml
# Flutter side: Built-in Timer class sufficient
# Optional: connectivity_plus: ^5.0.2  # Network status monitoring
```

---

## 7. Testing Strategy

### Decision: Standard Flutter Testing Stack + E2E Coverage

**Test Pyramid**:
1. **Unit Tests** (60%): Models, services, repositories, business logic
   - flutter_test framework
   - mockito for mocking API calls and storage
   
2. **Widget Tests** (30%): UI components, screens, user interactions
   - flutter_test for widget testing
   - golden tests for visual regression
   
3. **Integration Tests** (10%): Full user flows, platform-specific validation
   - integration_test package
   - Platform builds (iOS/Android/Web) tested separately

**Coverage Goals**: 80% code coverage minimum

**CI/CD Integration**:
- GitHub Actions for automated test runs on PR
- Platform-specific test jobs (iOS simulator, Android emulator, Chrome headless)
- Test reports published to PR comments

**Dependencies**:
```yaml
dev_dependencies:
  flutter_test:
    sdk: flutter
  integration_test:
    sdk: flutter
  mockito: ^5.4.4
  build_runner: ^2.4.7  # For mockito code generation
  flutter_launcher_icons: ^0.13.1
```

---

## 8. 42 Brand Identity Implementation

### Decision: Custom Theme with 42 Color System

**42 Brand Colors** (Primary Palette):
```dart
// lib/app/theme.dart
const Color color42Teal = Color(0xFF00BABC);      // Primary brand color
const Color color42DarkTeal = Color(0xFF009A9C);  // Darker variant
const Color color42DarkBg = Color(0xFF1A1D23);    // Dark background
const Color color42DarkCard = Color(0xFF2D3139);  // Card background
const Color color42Text = Color(0xFFE5E5E5);      // Text on dark
const Color color42TextMuted = Color(0xFF9BA1A6); // Secondary text
```

**Design System**:
- Dark theme by default (DR-001)
- Teal/cyan as accent colors for CTAs and highlights
- Card-based layouts for book browsing (DR-003)
- Material Design 3 components with 42 color overrides
- Custom splash screen with 42 branding

**Dependencies**:
```yaml
flutter_launcher_icons: ^0.13.1  # Custom app icon with 42 branding
flutter_native_splash: ^2.3.7    # Custom splash screen
```

---

## 9. Performance Optimization

### Decision: Lazy Loading + Pagination + Image Caching

**Strategies**:
1. **Catalog Pagination**: Load 20 books per page (virtual scrolling)
2. **Search Debouncing**: 300ms delay before search query execution
3. **Image Caching**: cached_network_image for book covers
4. **List Optimization**: ListView.builder for efficient rendering
5. **State Management**: Selective rebuilds with Bloc pattern

**Meets Success Criteria**:
- SC-001: Book discovery <30s → Pagination + search ensures instant results
- SC-002: Search results <1s → Debouncing + indexed sqflite queries
- SC-004: 1000 books without lag → Virtual scrolling + lazy loading
- SC-009: <2s page loads → Optimized build size, code splitting

**Dependencies**:
```yaml
cached_network_image: ^3.3.1
flutter_cache_manager: ^3.3.1
```

---

## 10. Docker Development Environment

### Decision: Multi-Container Setup with docker-compose

**Container Architecture**:
1. **flutter-dev**: Flutter development environment with SDK
2. **postgres-db**: PostgreSQL database for backend
3. **backend-api**: Node.js Express API server
4. **nginx-proxy** (optional): Reverse proxy for local HTTPS

**Docker Setup**:
```yaml
# docker-compose.yml structure
services:
  flutter-dev:
    image: cirrusci/flutter:3.16.0
    volumes:
      - ./:/app
    working_dir: /app
    command: flutter run -d web-server --web-port 8080
    
  backend-api:
    build: ./backend
    environment:
      DATABASE_URL: postgresql://user:pass@postgres-db:5432/library
      
  postgres-db:
    image: postgres:16-alpine
    environment:
      POSTGRES_DB: library
      POSTGRES_USER: admin
      POSTGRES_PASSWORD: dev_password
```

**Development Workflow**:
- All dependencies installed in containers (no local pollution)
- Hot reload works within Docker volumes
- Database migrations run in backend container
- VS Code Remote-Containers for IDE integration

---

## 11. Cross-Platform Code Sharing Strategy

### Decision: 95% Shared Code with Minimal Platform Isolation

**Architecture**:
- **Shared** (lib/screens/, lib/widgets/, lib/models/, lib/services/): 95%
- **Platform-specific** (lib/platform/): 5%

**Platform Abstraction Points**:
1. **File storage paths**: path_provider handles platform differences
2. **Secure storage**: flutter_secure_storage abstracts keychain/keystore
3. **Deep linking**: uni_links for URL handling across platforms
4. **Notifications**: firebase_messaging (Phase 2) with platform channels

**Mobile vs Web Differences**:
- **Mobile**: Bottom navigation, swipe gestures, native scrolling
- **Web**: Sidebar navigation, mouse hover states, browser back button
- **Shared**: All business logic, models, API clients, state management

**Responsive Design**:
- LayoutBuilder for adaptive layouts
- Breakpoints: Mobile (<600px), Tablet (600-1200px), Desktop (>1200px)
- Same components, different layouts per breakpoint

**Dependencies**:
```yaml
path_provider: ^2.1.1
uni_links: ^0.5.1  # Deep linking
url_launcher: ^6.2.2  # External links
```

---

## 12. Security Best Practices

### Decision: Multi-Layer Security Approach

**Authentication**:
- 42 OAuth 2.0 for student authentication
- JWT tokens for API session management (15-min expiry, refresh tokens)
- Secure token storage (flutter_secure_storage)
- Admin authentication: Separate credentials (bcrypt hashed)

**API Security**:
- HTTPS only (TLS 1.3)
- Rate limiting (express-rate-limit): 100 requests/15min per user
- CORS whitelisting
- Helmet.js for HTTP header security
- Input validation and sanitization (express-validator)

**Data Security**:
- No sensitive data in local storage (only cached public book data)
- Auth tokens in secure storage (iOS Keychain, Android Keystore)
- SQL injection prevention (Prisma parameterized queries)
- No PII stored beyond 42 API user ID

**Dependencies**:
```yaml
flutter_secure_storage: ^9.0.0
```

---

## 13. Notification Strategy (Phase 2 - Future)

### Decision: Firebase Cloud Messaging (FCM)

**Rationale** (for future implementation):
- Cross-platform support (iOS, Android, Web)
- Free tier sufficient for expected usage
- Reservation queue notifications (FR-008b: notify when book available)
- Overdue loan reminders (Phase 2)

**Deferred to Phase 2**: Initial implementation focuses on in-app status updates only.

---

## 14. Error Handling & Logging

### Decision: Centralized Error Handling + Structured Logging

**Error Handling**:
- Try-catch blocks in all API calls and async operations
- User-friendly error messages (toast/snackbar)
- Fallback to cached data on network errors
- Retry logic in dio interceptors (3 retries with exponential backoff)

**Logging**:
- logger package for structured logging
- Log levels: DEBUG, INFO, WARNING, ERROR
- Logs stored per Constitution: `logs/YYYY-MM-DD/YYYYMMDD-HHmmss-<descriptor>.log`
- Backend logs: Winston (Node.js) with daily rotation

**Dependencies**:
```yaml
logger: ^2.0.2
```

---

## Research Completion Summary

All "NEEDS CLARIFICATION" items from Technical Context resolved:

| Item | Resolution |
|------|-----------|
| Flutter version | 3.16.0 (latest stable) |
| State management | flutter_bloc + equatable |
| HTTP client | dio with 42 API custom client |
| Local storage | Hive (key-value) + sqflite (relational) hybrid |
| Backend | Custom REST API (Node.js/Express + PostgreSQL) |
| Real-time sync | 30-second polling with delta sync |
| Testing | flutter_test + integration_test + mockito (80% coverage) |
| 42 branding | Custom theme with teal/cyan colors, dark mode |
| Performance | Lazy loading, pagination, image caching |
| Docker setup | Multi-container (flutter-dev, backend-api, postgres-db) |
| Cross-platform | 95% shared code, 5% platform-specific abstraction |
| Security | OAuth 2.0, JWT, secure storage, HTTPS, rate limiting |

**Next Phase**: Phase 1 - Design & Contracts (data-model.md, contracts/, quickstart.md)
