# ADR 0002: 전역 BLoC 채택 및 BookBloc의 feature-first 경로 이전

- **Status**: Accepted
- **Date**: 2026-04-24
- **Deciders**: @gdtknight
- **Related**: #32, #39, [ADR 0001](0001-lib-organization.md)

## Context

[ADR 0001](0001-lib-organization.md) 확정 이후에도 `lib/`에는 state management 패턴 **불일치**가 남아 있다.

### 현 상태

| 도메인 | 위치 | 패턴 | 활성 여부 |
|---|---|---|---|
| Auth | `lib/state/auth/auth_bloc.dart` | BLoC | ✅ 활성 (LoginScreen이 사용) |
| Loan | `lib/state/loan/loan_bloc.dart` | BLoC | ✅ 활성 (MyLoansScreen 등이 사용) |
| Book | `lib/state/book/book_bloc.dart` | BLoC | ❌ orphan (PR #32 머지 후 유일한 user였던 legacy HomeScreen이 도달 불가) |
| Book (활성) | `lib/features/books/presentation/screens/book_list_screen.dart` | **repository 직접 호출** (BLoC 없음) | ✅ 활성 |

### 문제

- 활성 도서 화면이 BLoC를 사용하지 않아 auth/loan과 아키텍처 비일관
- US4 관리자 웹이 BLoC 전제(tasks.md T081-T083)라 앞으로 더 증폭됨
- 테스트 전략 혼재: BookBloc 테스트(T035)는 dead code 대상, BookListScreen 테스트는 별도 패턴 필요
- `flutter_bloc` dep이 pubspec에 있는데 활용이 부분적

## Decision

**도서 도메인도 BLoC로 통일한다.**

### 세부

1. **BookBloc을 `lib/features/books/presentation/bloc/`로 이전**
   - 신규 경로: `lib/features/books/presentation/bloc/book_bloc.dart`, `book_event.dart`, `book_state.dart`
   - [ADR 0001](0001-lib-organization.md) "신규 feature 코드는 `lib/features/<name>/`에만 추가" 준수
   - 기존 `lib/state/book/*` 는 이전 후 삭제

2. **BookListScreen을 `BlocProvider` + `BlocBuilder` 기반으로 리팩터**
   - 내부 `setState` 기반 `_books`, `_isLoading`, `_errorMessage` 제거
   - 이벤트: `LoadBooks`, `SearchBooks`, `RefreshBooks` (기존 event 재사용)
   - 상태: `BookInitial`, `BookLoading`, `BookLoaded`, `BookError`

3. **Repository 일원화**
   - 신설 BookBloc은 활성 경로 repository인 `lib/features/books/data/repositories/book_repository_impl.dart` 사용
   - legacy `lib/repositories/book_repository*.dart` 삭제 (BookBloc 외 consumer 없음)

4. **레거시 일괄 삭제**
   - `lib/screens/mobile/home/home_screen.dart`
   - `lib/state/book/{book_bloc,book_event,book_state}.dart`
   - `lib/repositories/book_repository.dart`, `book_repository_impl.dart`
   - `lib/widgets/category_filter.dart` — BookListScreen이 사용 안 함이 확인되면 삭제 대상 (리팩터 PR에서 검증)

5. **tasks.md 경로 갱신**
   - T050 → `lib/features/books/presentation/bloc/book_event.dart`
   - T051 → `lib/features/books/presentation/bloc/book_state.dart`
   - T052 → `lib/features/books/presentation/bloc/book_bloc.dart`
   - T056 → T056의 "HomeScreen" 구현 위치는 이미 `BookListScreen`으로 대체됨을 명시

### 나머지 도메인 (Auth, Loan)

**지금은 이전하지 않는다.** Auth/Loan BLoC도 이상적으로는 `lib/features/auth/`, `lib/features/loan/`으로 이전되어야 하나:
- 이미 활성이라 리팩터 위험 + 이득 비대칭
- US4가 `AuthBloc`을 레거시 경로에서 import할 예정 (tasks.md T083)
- 도서 이전이 먼저 끝난 뒤, MVP 이후 별도 ADR로 재검토

따라서 **ADR 0001의 "동결" 원칙의 예외로 도서만 이전**한다. 근거: 도서 BLoC은 orphan 상태라 이전/삭제 비용이 최소고, 활성 경로에 일관성을 주입해야 US1 테스트 백필이 가능.

## Consequences

### Positive

- 모든 도메인(Auth/Loan/Book)이 BLoC 일관 패턴
- US1 테스트 백필 시 T034/T035/T038이 실존 코드 대상이 되어 유효
- US4(AuthBloc 전제) 개시 시 혼선 없음
- `flutter_bloc` dep이 저장소 전역에서 일관 사용됨

### Negative

- 활성 BookListScreen 리팩터 = regression 가능성. 충분한 위젯 테스트로 완화(PR 3)
- 기존 T052 위치(`lib/state/book/`)에 누적된 구현이 경로 이전됨 — git blame 역사는 rename 추적 가능
- ADR 0001 "동결" 원칙에 부분 예외 — 본 ADR이 그 justification

### Neutral

- Auth/Loan은 `lib/state/`에 당분간 잔존. MVP 이후 전체 feature-first 이전(ADR 0001의 A안)이 재검토될 때 합쳐서 정리 가능

## Follow-up PR 순서

1. **본 PR (#39)** — ADR 0002 문서 추가만
2. **리팩터 PR** — 이슈 별도 생성: `lib/features/books/presentation/bloc/` 신설 + BookListScreen 전환 (레거시 유지)
3. **레거시 삭제 PR** — 이슈 별도 생성: 레거시 경로 일괄 삭제 + tasks.md 경로 갱신
4. **테스트 백필 PR** — 이슈 별도 생성: T034/T035/T038/T039, `integration_test` dep 추가

각 PR은 독립 CI green 후 병합.

## References

- [ADR 0001](0001-lib-organization.md) — lib/ 조직 동결
- `specs/001-library-management/tasks.md` — T050-T056 경로 갱신 대상
- PR #32 — 라우터 제거로 BLoC orphan 드러낸 PR
- `~/.claude/rules/project-structure.md` — 조직 일관성 가이드 (ADR override 허용)
