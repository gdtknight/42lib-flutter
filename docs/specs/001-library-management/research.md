# 조사 문서: 42 학습 공간 도서 관리 시스템

**브랜치**: `001-library-management` | **날짜**: 2025-12-17 | **단계**: 0 - 조사 및 해결

## 목적

이 문서는 plan.md의 Technical Context에서 모든 "NEEDS CLARIFICATION" 항목을 해결하고, 선택된 기술에 대한 모범 사례를 조사하며, 근거와 함께 아키텍처 결정을 문서화합니다.

---

## 1. Flutter 버전 및 에코시스템

### 결정: Flutter 3.16.0 (최신 안정 버전)

**근거**: 
- Flutter 3.16.0은 현재 안정 릴리스로 프로덕션 준비 완료 기능 제공 (2024년 12월 기준)
- Material Design 3 지원으로 현대적인 UI 제공
- 웹 성능 및 컴파일 개선
- iOS 17, Android 14 안정적 지원
- 필요한 플랫폼 버전과 하위 호환 (iOS 14-17, Android 11-14)

**고려한 대안**:
- Flutter 3.13.x: 구버전 안정판이지만 웹 성능 개선 사항 누락
- Flutter 3.19.x (beta/dev): 프로덕션에는 불안정, 잠재적 호환성 문제

**버전 호환성 검증**:
- iOS 17/16/15/14: ✅ Flutter 3.16.0에서 완전 지원
- Android 14/13/12/11: ✅ Flutter 3.16.0에서 완전 지원
- Web (Chrome, Safari, Firefox, Edge 최신 2개 버전): ✅ 지원

---

## 2. 상태 관리 솔루션

### 결정: flutter_bloc (BLoC 패턴)

**근거**:
- 비즈니스 로직과 UI의 명확한 분리
- 예측 가능한 상태 전환으로 우수한 테스트 가능성
- 복잡한 상태(대출 큐, 예약 관리)를 다루는 애플리케이션에 확장 가능
- 강력한 커뮤니티 지원 및 문서화
- 내장 디버깅 도구 (bloc observer, 타임 트래블 디버깅)
- 실시간 동기화 요구사항에 적합 (스트림 기반 아키텍처)

**고려한 대안**:
- Provider: 단순하지만 예약 큐 같은 복잡한 상태 플로우에는 구조가 부족
- Riverpod: 현대적이고 강력하지만 에코시스템과 문서화가 덜 성숙
- GetX: 너무 많은 마법, 테스트 가능성 원칙 위반
- setState만 사용: 앱 전체 상태(인증, 오프라인 동기화)에 불충분

**BLoC 구현 전략**:
- 각 기능별 BLoC (BookBloc, LoanBloc, ReservationBloc)
- 공유 상태용 글로벌 BLoC (AuthBloc, SyncBloc)
- BlocObserver로 모든 상태 전환 로깅
- Equatable로 상태 비교 최적화

---

## 3. 로컬 스토리지 전략

### 결정: Hive + sqflite 하이브리드 접근

**근거**:
- **Hive**: 빠른 키-값 스토리지, 사용자 설정 및 세션 데이터에 이상적
- **sqflite**: 관계형 쿼리, 도서 카탈로그 및 복잡한 검색에 필수
- 하이브리드 접근으로 두 가지 장점 활용

**사용 분할**:
- **Hive**: 인증 토큰, 사용자 환경설정, 앱 설정, 마지막 동기화 타임스탬프
- **sqflite**: 도서 카탈로그 (전체 텍스트 검색), 대출 기록, 예약 큐

**오프라인 전략**:
1. 초기 로드 시 전체 카탈로그 동기화 (500-1000권, ~5-10MB)
2. 30초마다 델타 동기화 (변경된 레코드만)
3. 백그라운드에서 충돌 해결 (마지막 쓰기 우선)
4. 온라인 재접속 시 보류 중인 작업 큐 재생

**고려한 대안**:
- SharedPreferences만 사용: 복잡한 쿼리 불가능, 성능 부족
- Hive만 사용: 관계형 쿼리 제한적
- sqflite만 사용: 간단한 키-값 작업에 오버헤드

---

## 4. 백엔드 기술 스택

### 결정: Node.js/Express + PostgreSQL

**근거**:
- **Node.js/Express**: 빠른 개발, 대규모 에코시스템, 팀 친화적
- **PostgreSQL**: 강력한 관계형 모델, JSONB 지원, 뛰어난 성능
- REST API 설계 단순성 (GraphQL은 이 규모에서는 과도함)

**API 아키텍처**:
- RESTful 엔드포인트 (CRUD + 커스텀 액션)
- JWT 인증 (42 OAuth + 자체 세션)
- Express 미들웨어: 인증, 로깅, 오류 처리
- Sequelize ORM: 타입 안전, 마이그레이션

**데이터베이스 스키마**:
- 8개 테이블: books, students, administrators, loan_requests, loans, reservations, book_suggestions, sync_metadata
- 인덱스: books(title, author, category), loan_requests(student_id, book_id)
- 제약조건: 외래 키, 고유 제약, 체크 제약

**확장성 고려사항**:
- 연결 풀링 (최대 20개 연결)
- 쿼리 캐싱 (Redis로 자주 조회되는 도서)
- 페이지네이션 (모든 목록 엔드포인트에서 페이지당 20-50개 항목)

**고려한 대안**:
- Firebase: 벤더 종속, 제한된 쿼리 기능
- Django/Python: 학습 곡선, 팀 친숙도 낮음
- Supabase: 프로젝트에는 성숙도 부족

---

## 5. 인증 및 권한 부여

### 결정: 42 API OAuth 2.0 + JWT 세션

**인증 플로우**:
1. 학생이 "42로 로그인" 클릭
2. 앱이 42 OAuth 엔드포인트로 리디렉션
3. 학생이 42 계정으로 인증
4. 42가 인증 코드로 콜백
5. 백엔드가 코드를 액세스 토큰으로 교환
6. 백엔드가 42 API에서 사용자 프로필 가져오기
7. 백엔드가 JWT 세션 토큰 발급 (7일 만료)
8. 앱이 토큰을 Hive에 안전하게 저장

**권한 부여 역할**:
- **학생**: 도서 조회, 대출 요청, 제안 제출
- **관리자**: 모든 학생 권한 + 도서 관리, 대출 승인, 제안 검토

**보안 조치**:
- HTTPS 전용 (프로덕션)
- 토큰 갱신 (만료 전 자동 갱신)
- 요청 속도 제한 (IP당 분당 100개 요청)
- 입력 유효성 검사 (모든 엔드포인트에서 파라미터 정제)

---

## 6. 테스팅 전략

### 결정: 3계층 테스트 피라미드

**단위 테스트 (70% 커버리지)**:
- 모든 BLoC 로직 (상태 전환)
- 모든 데이터 모델 (직렬화, 유효성 검사)
- 유틸리티 함수 (날짜 형식, 문자열 파싱)
- 도구: flutter_test, mockito, bloc_test

**위젯 테스트 (20% 커버리지)**:
- 모든 재사용 가능한 위젯 (BookCard, SearchBar)
- 화면별 주요 상호작용 (탭, 스크롤, 입력)
- 도구: flutter_test, golden_toolkit (시각적 회귀)

**통합 테스트 (10% 커버리지)**:
- 주요 사용자 플로우 (도서 검색 → 상세 정보 → 대출 요청)
- 오프라인-온라인 전환
- 도구: integration_test, flutter_driver

**테스트 자동화**:
- GitHub Actions에서 모든 PR에 대해 테스트 실행
- 단위 테스트 실패 시 병합 차단
- 주간 전체 통합 테스트 스위트

**목표 메트릭**:
- 전체 코드 커버리지 80%
- 모든 테스트 <5분 실행
- 통합 테스트 <15분 실행

---

## 7. 성능 최적화

### 목표 메트릭 (plan.md에서)
- 검색 응답 <1초
- 페이지 로드 <2초
- 도서 검색 <30초
- UI 애니메이션 60fps
- 폴링 동기화 30초

### 최적화 전략

**프론트엔드 (Flutter)**:
- 가상화된 목록 (ListView.builder, 1000권 도서용)
- 이미지 캐싱 (cached_network_image)
- 디바운스 검색 입력 (300ms 지연)
- 지연 로딩 (필요할 때만 데이터 가져오기)
- const 위젯 (불필요한 재빌드 방지)

**백엔드 (Node.js)**:
- 데이터베이스 인덱스 (books.title, books.author, books.category)
- 응답 압축 (gzip)
- Redis 캐싱 (자주 조회되는 도서 목록, 5분 TTL)
- 연결 풀링 (PostgreSQL, 최대 20개 연결)

**네트워크**:
- API 응답 페이지네이션 (페이지당 20개 항목)
- 델타 동기화 (전체 카탈로그 대신 변경 사항만)
- HTTP/2 (멀티플렉싱)

**모니터링**:
- 프론트엔드 성능 타임라인 (DevTools)
- 백엔드 APM (New Relic 또는 Datadog)
- 데이터베이스 느린 쿼리 로그

---

## 8. 42 브랜드 정체성 (디자인)

### 결정: 청록색 및 다크 테마

**색상 팔레트**:
- **주 색상**: 청록색 #00BABC (42 브랜드 색상)
- **배경**: 다크 그레이 #1A1D23 (가독성)
- **텍스트**: 화이트 #FFFFFF (주 텍스트), 라이트 그레이 #B0B0B0 (보조 텍스트)
- **강조**: 오렌지 #FF6B35 (액션 버튼, 경고)

**타이포그래피**:
- **제목**: Roboto Bold, 24-32pt
- **본문**: Roboto Regular, 14-16pt
- **캡션**: Roboto Light, 12pt

**UI 컴포넌트**:
- 카드 기반 레이아웃 (Material Design 3)
- 둥근 모서리 (8px 반경)
- 미묘한 그림자 (깊이 강조)
- 아이콘 우선 내비게이션 (BottomNavigationBar)

**접근성**:
- WCAG AA 대비 비율 (4.5:1 이상)
- 터치 타겟 크기 최소 48x48dp
- 스크린 리더 지원 (Semantics 위젯)

---

## 9. Docker 개발 환경

### 결정: 3컨테이너 설정

**서비스**:
1. **flutter-dev**: Flutter SDK, 앱 코드 마운트
2. **backend-api**: Node.js/Express, PostgreSQL 연결
3. **postgres-db**: PostgreSQL 14, 데이터 볼륨

**docker-compose.yml 구조**:
```yaml
services:
  flutter-dev:
    build: ./flutter
    volumes:
      - .:/workspace
      - flutter-cache:/root/.pub-cache
    ports:
      - "8080:8080"  # Flutter web dev server
  
  backend-api:
    build: ./backend
    environment:
      DATABASE_URL: postgres://user:pass@postgres-db:5432/library
    ports:
      - "3000:3000"
  
  postgres-db:
    image: postgres:14
    volumes:
      - db-data:/var/lib/postgresql/data
```

**개발 워크플로우**:
1. `docker-compose up -d` - 모든 서비스 시작
2. `docker-compose exec flutter-dev bash` - Flutter 컨테이너 접속
3. `flutter run -d web-server` - 웹 개발 서버 실행
4. 코드 변경 → 핫 리로드 자동

**이점**:
- 로컬 머신 오염 없음
- 팀 전체 일관된 환경
- CI/CD와 동일한 환경

---

## 10. 플랫폼 특화 고려사항

### iOS (14, 15, 16, 17)
- **iOS 14**: Minimum deployment target
- **iOS 15-17**: 모든 기능 완전 지원
- **고려사항**: 
  - Safe area insets (노치 지원)
  - iOS 14에서 deprecated된 API 피하기
  - App Store 검토 가이드라인 준수

### Android (11, 12, 13, 14)
- **Android 11**: Minimum SDK 30
- **Android 12-14**: Material You, 향상된 권한
- **고려사항**:
  - 스코프 스토리지 (Android 11+)
  - 포그라운드 서비스 알림 (동기화용)
  - Proguard/R8 난독화

### Web
- **브라우저**: Chrome, Safari, Firefox, Edge (최신 2개 버전)
- **고려사항**:
  - 반응형 레이아웃 (모바일 + 데스크톱)
  - 웹 워커 (백그라운드 동기화)
  - PWA 기능 (오프라인, 홈 스크린 추가)

**플랫폼 간 일관성**:
- 동일한 UI 컴포넌트 (플랫폼별 분기 최소화)
- 공유 비즈니스 로직 (BLoC)
- 플랫폼별 코드는 명확히 격리 (if-else 대신 추상화)

---

## 결론

모든 기술적 불확실성이 해결되었습니다. 스택은 프로덕션 준비 완료되었으며, 헌법 IX (플랫폼 호환성)를 준수하고, 오프라인 기능, 실시간 동기화, 42 브랜드 정체성을 지원합니다.

**다음 단계**: Phase 1 설계 (data-model.md, contracts/openapi.yaml, quickstart.md)
