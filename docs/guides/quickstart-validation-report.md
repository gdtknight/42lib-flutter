# Quickstart 검증 리포트 (T236, v0.6.0 기준)

> **수행일**: v0.6.0 머지 직후 (2026-05-06).
> **소스**: `specs/001-library-management/quickstart.md` (Phase 1, 2025-12-17 작성).
> **방법**: 각 절차를 실제로 수행하면서 결과 검증 + 코드/설정과 대조.

원본 quickstart는 **Phase 1 설계 단계** 산출물이라 v0.6.0 시점에 노후한 부분이 다수 발견되었습니다. 본 리포트는 발견 사항을 정리하고, 같은 PR에서 quickstart를 v0.6.0 기준으로 갱신했습니다.

## 검증 결과 요약

| 검증 카테고리 | 통과 | 갭 발견 |
|--|--|--|
| 사전 요구 (Docker / Git) | ✅ | — |
| 환경 변수 설정 | ⚠️ | `.env.example`이 PR #124 이후 풍부해졌으나 quickstart는 미반영 |
| 서비스 기동 | ⚠️ | `docker-compose` 명령이 `-f docker/docker-compose.yml` 누락 / Make 미언급 |
| DB 마이그레이션 | ✅ | — |
| API 엔드포인트 | ❌ | **Swagger UI URL 오류** (`/api-docs` → 실제는 `/api/docs/`) |
| Flutter 명령 | ❌ | `flutter format`, `flutter pub run build_runner` deprecated |
| OAuth 모킹 | ❌ | **`MOCK_42_API` env var 존재하지 않음** — 실제 동작 안 함 |
| 테스트 커버리지 목표 | ⚠️ | "60%/30%/10%" 표기 — spec MVP 기준 80% (이미 v0.6.0에 도달) |
| 다음 단계 | ❌ | "Phase 2: Task Generation" — Phase 1 산출물의 잔재 |

## 발견 사항 (상세)

### 🔴 H1. Swagger UI URL 오류

```
quickstart.md:76 → "API Documentation: http://localhost:3000/api-docs (Swagger UI)"
실제                → http://localhost:3000/api/docs/
```

**검증**:
```bash
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:3000/api-docs   # → 404
curl -fsS -o /dev/null -w "%{http_code}\n" http://localhost:3000/api/docs/  # → 200
```

PR #122에서 Swagger UI를 `/api/docs/` 경로로 마운트했고, raw OpenAPI는 `/api/docs/openapi.json`. quickstart 작성 시점 (Phase 1, 2025-12-17)에는 이 라우트가 존재하지 않았음.

**조치**: quickstart.md의 두 군데 (§5 / §10) 모두 `/api/docs/`로 정정.

### 🔴 H2. `MOCK_42_API` 환경 변수가 존재하지 않음

```
quickstart.md:217-222 → "MOCK_42_API=true  # Bypasses actual 42 API"
```

`backend/src/` 어디에도 `MOCK_42_API`를 참조하는 코드가 없음. 실제로 학생 OAuth는 항상 42 API를 직접 호출함.

**검증**:
```bash
grep -rE "MOCK_42_API" backend/src/   # → 결과 없음
```

**조치**: 해당 섹션 삭제. 현재 OAuth 통합 테스트 패턴 (`jest.mock('axios')` + 실 DB)은 `backend/tests/unit/auth_42_service.test.ts` 참고로 대체.

### 🔴 H3. 명령 deprecated

| quickstart 명령 | 현재 권장 |
|--|--|
| `flutter format lib/ test/` | `dart format .` (Flutter 3.16+에서 `flutter format` 제거 예정) |
| `flutter pub run build_runner build` | `dart run build_runner build` |

**조치**: 두 명령 갱신.

### 🟡 M1. `docker-compose` 명령 경로 누락

quickstart는 repo 루트에서 `docker-compose up -d`를 실행하라고 안내하지만, `docker-compose.yml`은 `docker/` 하위에 있음. 그래서:

```bash
$ docker compose ps
no configuration file provided: not found
```

**대안 1**: `cd docker && docker compose up -d`
**대안 2**: `docker compose -f docker/docker-compose.yml up -d`
**대안 3**: `make up` (이게 사실상 표준 — Makefile이 wrapper)

**조치**: `make up`을 1순위로 안내, raw 명령은 `-f docker/docker-compose.yml` 형태로 갱신. README의 Quick Start 섹션과 일관되게.

### 🟡 M2. `.env.example` 안내가 빈약

```
quickstart.md:38-44 → 3개 변수만 예시 (FORTYTWO_*)
실제 .env.example     → DB / JWT / 42 OAuth / 서버 / 예약 6개 섹션 + 각 변수 의미·필수 표기
```

PR #124에서 `.env.example`을 대폭 보강했음.

**조치**: quickstart는 "`backend/.env.example`의 주석을 따라 채우기"로 위임. 자세한 OAuth 발급은 별도 가이드 (`docs/guides/42-oauth-setup.md`)로 링크.

### 🟡 M3. 코드 커버리지 목표 표기가 spec과 불일치

```
quickstart.md:303 → "Unit Tests (60% coverage target)"
quickstart.md:347 → "80% code coverage" (Quality Gates)
```

두 값이 한 문서 안에서 충돌. Spec MVP는 80%이고, v0.6.0 시점에 backend 81.5% / Flutter 80.8%로 도달.

**조치**: 80% 단일 표기. 현재 실측치 명시.

### 🟢 L1. Redis 서비스 미언급

quickstart §3은 3개 서비스 (`flutter-dev`, `backend-api`, `postgres-db`)만 나열하지만, `docker-compose.yml`에는 `redis-cache`도 있음 (현재 코드는 미사용이지만 컨테이너는 띄움).

**조치**: 4번째 서비스로 추가 + "현재 코드는 미사용 (예약)" 주석.

### 🟢 L2. Prisma Studio 포트 미공개

quickstart.md:127 → `npx prisma studio` → `http://localhost:5555` 안내.
`docker-compose.yml`은 5555 포트를 호스트에 매핑하지 않음 → 컨테이너 내부에서만 접근 가능 → 호스트 브라우저로는 닿지 않음.

**조치**: "포트 매핑이 필요하다" 주석 + Make 명령 (`make db-shell`로 SQL 직접) 대안 안내.

### 🟢 L3. "Phase 2: Task Generation" 안내가 잔재

quickstart.md:435 → "Proceed to Phase 2: Task Generation (`/speckit.tasks` command)"

Phase 1 시점의 안내. v0.6.0에서는 task가 모두 정의되어 있고 (`tasks.md`, T001-T268), 마무리 단계.

**조치**: "현재 출하 상태 (v0.6.0)" 섹션으로 교체. README의 "현재 출하 상태"와 일관되게.

## quickstart.md 갱신 사항 (이 PR에서 함께 처리)

- §1.1 Clone에 `git checkout v0.6.0` (안정 태그) 옵션 추가
- §1.2 Configure → `cp` 후 "주석 따라" + OAuth 가이드 링크
- §1.3 Start → `make up` 1순위
- §1.4 Initialize → migrate / seed (변경 없음)
- §1.5 Access → **Swagger UI URL 정정** (`/api/docs/`) + Mobile/Admin URL 분리 명시
- §2.X Flutter 명령 → `dart format`, `dart run build_runner` 갱신
- §3 OAuth Mocking 섹션 → 삭제, 실제 패턴 (auth_42_service.test.ts) 안내로 교체
- §4 테스트 → 80% 단일 목표
- §6 Next Steps → "현재 출하 상태 (v0.6.0)" 섹션
- 각 운영/배포 주제는 새 가이드들로 위임:
  - 배포: `docs/guides/deployment.md`
  - DB 백업/복원: `docs/guides/database-backup-restore.md`
  - 42 OAuth 등록: `docs/guides/42-oauth-setup.md`
  - CI/CD: `docs/guides/ci-cd-pipeline.md`

이로써 quickstart는 **첫 5분 셋업에만 집중**하고, 나머지는 전문 가이드로 위임하는 구조로 슬림화.

## Phase 12 잔여 작업

이 PR로 T236 종료. Phase 12 7항목 모두 완료:

| Task | 상태 | 릴리스 |
|--|--|--|
| T230 Swagger UI | ✅ | v0.5.1 |
| T231 README | ✅ | v0.5.1 |
| T232 .env.example | ✅ | v0.5.1 |
| T233 deployment guide | ✅ | v0.6.x (다음 패치) |
| T234 user manual | ✅ | v0.6.x |
| T235 admin manual | ✅ | v0.6.x |
| T236 quickstart 검증 | ✅ | v0.6.x (이 PR) |
| T237 DB 백업/복원 | ✅ | v0.5.4 |
| T238 42 OAuth 가이드 | ✅ | v0.5.4 |
| T239 CI/CD 문서화 | ✅ | v0.5.4 |
