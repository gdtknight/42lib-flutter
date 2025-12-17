# 구현 계획: 42 학습 공간 도서 관리 시스템

**브랜치**: `001-library-management` | **날짜**: 2025-12-17 | **명세서**: [spec.md](./spec.md)
**입력**: `/specs/001-library-management/spec.md`의 기능 명세서

**참고**: 이 문서는 `/speckit.plan` 명령어로 생성됩니다.

## 요약

42 학습 공간을 위한 도서 관리 시스템 구축. 학생들이 약 500-1000권의 도서를 검색하고, 카탈로그를 조회하며, 42 API 인증을 통해 대출을 요청하고, 도서 제안을 제출할 수 있는 Flutter 모바일 앱(iOS/Android)을 제공합니다. 관리자는 웹 대시보드를 통해 카탈로그 관리(도서 추가/수정/삭제), 대출 요청 처리, 활성 대출 추적, 도서 제안 검토를 수행합니다. 시스템은 50명의 동시 사용자를 지원하며 실시간 동기화 및 오프라인 기능을 제공합니다.

**기술 컨텍스트** *(모든 항목은 research.md에서 해결됨)*

**언어/버전**: Flutter 3.16.0 (최신 안정 버전, 프로덕션 준비 완료)
**주요 의존성**: flutter_bloc (상태 관리), dio (HTTP 클라이언트), oauth2 (42 API 인증), hive + sqflite (하이브리드 스토리지)
**스토리지**: 로컬: Hive (키-값) + sqflite (관계형) | 원격: 커스텀 REST API (Node.js/Express + PostgreSQL)
**테스팅**: flutter_test, integration_test, mockito (목표 커버리지 80%)
**타겟 플랫폼**: iOS, Android, Web (헌법 IX에 따라 3가지 모두 필수)
**iOS 지원**: iOS 17, 16, 15, 14 (헌법 IX에 따라 4개 버전)
**Android 지원**: Android 14, 13, 12, 11 (헌법 IX에 따라 4개 버전)
**Web 지원**: Chrome, Safari, Firefox, Edge (최신 2개 버전)
**개발 환경**: Docker 기반 (flutter-dev, backend-api, postgres-db 컨테이너)
**프로젝트 유형**: Flutter 모바일/웹 크로스플랫폼 애플리케이션
**성능 목표**: 검색 응답 <1초, 페이지 로드 <2초, 도서 검색 <30초, UI 애니메이션 60fps, 폴링 동기화 30초
**제약사항**: 캐시된 데이터로 오프라인 동작 가능, 모바일 앱 크기 <50MB, 콜드 스타트 <2초, 50명 동시 사용자 지원, 1000권 카탈로그에서 성능 저하 없음
**규모/범위**: 500-1000권 도서, 모바일 화면 약 10-15개, 웹 관리자 화면 약 8-10개, API 엔드포인트 15-20개, 분기/반기별 도서 제안 수집

## 헌법 검증

*게이트: Phase 0 조사 전 통과 필수. Phase 1 설계 후 재검증.*

### 초기 검증 (Phase 0 이전)

**필수 검증사항**:
- [x] Git 워크플로우: `dev`에서 `001-library-management` 브랜치 생성, 커밋은 이슈 참조
- [x] 문서화: 사용자 대면 콘텐츠는 한글 (spec.md는 한글 입력 사용, 구현 문서도 한글)
- [x] 로깅: `logs/YYYY-MM-DD/YYYYMMDD-HHmmss-<descriptor>.log` 형식 준수
- [x] 42 정체성: 42 브랜드 정체성을 반영하는 색상 구성 (spec의 DR-001은 청록색/시안 및 다크 테마 요구)
- [x] UX 우선순위: 사용자 편의성 우선 및 단순한 UI 추구 (DR-002, DR-003은 빠른 검색, 카드 기반 단순성 강조)
- [x] Docker 환경: 모든 개발 의존성은 Docker에서, 로컬 오염 없음 (PR-005는 Docker 컨테이너 의무화)
- [x] Flutter 플랫폼 지원: iOS/Android/Web 빌드 검증 예정 (PR-001은 동일한 동작 요구)
- [x] 플랫폼 버전: iOS 17/16/15/14, Android 14/13/12/11 (PR-002, PR-003은 각각 4개 버전 명시)
- [x] 테스팅: 품질 게이트 정의됨 (SC-001 ~ SC-016은 측정 가능한 성공 기준 제공)

**결과**: ✅ 모든 검증 통과. 헌법 위반 없음.

### 설계 후 검증 (Phase 1 이후)

**설계 후 재검증**:
- [x] 42 정체성: research.md에서 청록색(#00BABC) 및 다크 테마(#1A1D23)로 색상 시스템 정의
- [x] Docker: docker-compose.yml에 flutter-dev, backend-api, postgres-db 서비스 정의
- [x] 플랫폼 호환성: data-model.md 및 contracts/openapi.yaml에서 3개 플랫폼 모두 고려

**결과**: ✅ 설계 산출물이 헌법 원칙 준수. 다음 단계 진행 가능.

## Phase 0: 조사 및 해결

**목표**: Technical Context의 모든 "NEEDS CLARIFICATION" 항목 해결

**산출물**: `research.md` - 모든 기술 결정 문서화

**주요 결정사항** (research.md에서 상세 내용 확인):
1. Flutter 3.16.0 선택 (안정성, M3 지원, 웹 성능)
2. flutter_bloc 상태 관리 (테스트 가능성, 확장성)
3. Hive + sqflite 하이브리드 로컬 스토리지 (키-값 + 관계형)
4. Node.js/Express + PostgreSQL 백엔드 (팀 친화성, 확장성)
5. 42 브랜드 색상: 청록색 (#00BABC), 다크 배경 (#1A1D23)

## Phase 1: 설계

**목표**: 데이터 모델, API 계약, 빠른 시작 가이드 생성

**산출물**:
1. `data-model.md` - 8개 엔티티, 검증 규칙, 관계
2. `contracts/openapi.yaml` - OpenAPI 3.0 명세 (20+ 엔드포인트)
3. `quickstart.md` - 개발자 설정 가이드

**데이터 엔티티** (data-model.md에서 상세 내용 확인):
- Book: 도서 카탈로그 엔트리
- Student: 학생 사용자 프로필
- Administrator: 관리자 사용자 프로필
- LoanRequest: 대출 요청
- Loan: 활성 대출
- Reservation: 예약 대기열
- BookSuggestion: 희망 도서 제안
- SyncMetadata: 오프라인 동기화 추적

**API 엔드포인트** (contracts/openapi.yaml에서 상세 내용 확인):
- 도서: GET /books, POST /books, GET /books/{id}, PUT /books/{id}, DELETE /books/{id}
- 검색: GET /books/search
- 대출: POST /loans/request, GET /loans/my, POST /loans/{id}/approve
- 예약: POST /reservations, GET /reservations/queue/{bookId}
- 제안: POST /suggestions, GET /suggestions (관리자)
- 인증: POST /auth/42/callback

## Phase 2: 작업 생성

**다음 단계**: `/speckit.tasks` 명령어 실행

**생성될 내용**:
- Phase 3 (기초): Docker 설정, Flutter 프로젝트 초기화, 백엔드 스캐폴딩
- Phase 4 (핵심): Book CRUD, 검색, 대출 플로우, 예약 시스템
- Phase 5 (통합): 42 OAuth, 오프라인 동기화, 관리자 대시보드
- Phase 6 (완성): 테스팅, 성능 최적화, 문서화

**추정 작업**: 약 30-40개 작업, 의존성 순서대로 정렬

---

**상태**: ✅ Phase 0 & 1 완료. Phase 2 준비됨.
