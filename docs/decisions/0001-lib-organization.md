# ADR 0001: lib/ 조직 스타일 동결

- **Status**: Accepted
- **Date**: 2026-04-20
- **Deciders**: @gdtknight
- **Related**: #27, #28, #33, [CLAUDE.md](../../CLAUDE.md), [project-structure rules](~/.claude/rules/project-structure.md)

## Context

`lib/` 디렉토리는 현재 **두 가지 조직 스타일이 공존**하는 상태다:

### Layer-first (레거시)

```
lib/
├── models/            # 데이터 모델 (book, loan_request, reservation, student)
├── services/          # api, auth, storage
├── state/             # flutter_bloc (auth, book, loan)
├── repositories/      # book, loan_request, reservation
├── screens/mobile/    # auth, book_detail, home, loan
├── widgets/           # book_card, book_search_bar, category_filter, common/, loan/
├── utils/             # logger, error_handler
└── app/               # config, theme (routes.dart는 #31에서 제거)
```

원 spec(`specs/001-library-management/tasks.md` T042-T063, T102-T131)의 경로 규약이며, US1/US2 구현 다수가 이 구조를 따름.

### Feature-first (신규)

```
lib/features/books/
├── data/          # models, repositories, datasources
├── domain/        # repositories (interfaces)
└── presentation/  # screens, widgets
```

`lib/core/routes/app_router.dart`가 실제 참조하는 `BookListScreen`이 이 구조 안에 있음. Clean Architecture 3계층 분리.

### 갈등

이 혼재는 최근 6개월 내 US1 구현 과정에서 의도적으로 도입된 것이 아니라, 스펙 경로와 실제 구현이 갈라지며 결과적으로 남은 상태로 판단됨. 전역 rule(`~/.claude/rules/project-structure.md`)은 **"Choose one organizational approach per project and be consistent. DON'T mix feature-first and layer-first in the same source root"**을 권고하고 있어 원칙상으로도 해소 대상.

## Decision

**B안: 현 상태 동결. 신규 기능은 feature-first로만 추가한다.**

### 구체 규칙

1. **기존 레거시 layer-first 코드는 유지**
   - `lib/models/`, `lib/services/`, `lib/state/`, `lib/repositories/`, `lib/screens/mobile/`, `lib/widgets/` 등
   - 기존 코드 수정은 원래 위치에서 진행. 옮기지 않는다.

2. **신규 기능은 `lib/features/<name>/{data,domain,presentation}/` 에만 추가**
   - 예: US4 관리자 카탈로그 → `lib/features/admin_catalog/`
   - 예: US3 희망 도서 → `lib/features/book_suggestions/`

3. **기존 코드의 feature-first 이전(A안)은 별도 대규모 리팩터 이슈로만 가능**
   - 단일 PR에서 partial migration 금지
   - MVP 완료(v0.1.0) 이후에 재논의

4. **예외: dead code 제거는 허용**
   - 참조가 끊긴 레거시 파일은 정리 가능 (예: #31 라우터 정리)
   - 단, 아키텍처 이전 목적의 이동은 본 결정 위반

### 공유 레이어 위치

- `lib/core/` — 라우팅, 교차관심사(예: `core/routes/app_router.dart`)
- `lib/app/` — 앱 초기화(`config.dart`, `theme.dart`)
- `lib/utils/`, `lib/platform/` — 유틸리티, 플랫폼 감지
- 위 레이어는 **feature와 legacy 양쪽에서 공유**. 한쪽 전용 코드는 해당 쪽에 둔다.

## Consequences

### Positive

- 이미 머지된 US1/US2 코드를 흔들지 않아 MVP 일정 안정
- 신규 기능(US4 이후)부터 Clean Architecture 일관성 확보
- CLAUDE.md의 기존 서술과 일치 — 장래 Claude Code 세션이 혼란 없이 작업
- tasks.md의 T042-T063, T072-T092 등의 원 경로와 코드 위치 불일치가 더 이상 "버그"가 아니라 "의도된 공존"으로 정당화됨

### Negative

- 장기적으로 두 스타일이 lib/에 계속 혼재 — 신규 합류자에게 인지 부담
- `lib/state/book/*`처럼 레거시에만 연결된 BLoC 코드가 있으면 feature-first 신규 기능에서는 같은 도메인에 대해 별도 BLoC를 다시 구현해야 할 가능성 (PR #32의 orphan 문제 참조)
- 도서 관련 중복 구현 (legacy `lib/state/book/` BLoC vs feature `features/books/` 직접 repository) 정리는 별도 결정 필요

### Neutral

- 전역 rule(project-structure.md)의 "consistent" 권고와는 충돌하나, rule 문서는 **"override with justification in ADR"** 을 허용하고 있음. 본 ADR이 그 justification.

## Follow-ups

- **#32 후속**: BLoC 기반 레거시 HomeScreen + `BookBloc` 처리 (삭제 / feature로 승격 / 유지 중 결정)
- **미번호 이슈**: US4 관리자 카탈로그는 `lib/features/admin_catalog/`로 신규 작성 (T064-T092 경로와 다를 수 있음)
- **MVP 이후**: A안(전체 feature-first 이전) 재검토 가능

## References

- 관련 PR: #28 (재정비), #30 (hygiene), #32 (라우터 정리)
- `~/.claude/rules/project-structure.md` — 전역 조직 스타일 가이드
- `specs/001-library-management/tasks.md` — 원 경로 사양
- `CLAUDE.md` — 본 결정이 반영된 개발자 가이드
