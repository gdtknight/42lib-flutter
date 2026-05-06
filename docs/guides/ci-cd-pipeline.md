# CI/CD 파이프라인

> **대상**: 기여자 / 운영자.
> **소스**: `.github/workflows/ci.yml`, `codecov.yml`.

이 문서는 GitHub Actions 파이프라인의 동작/규칙/한계를 설명합니다. workflow 자체가 단일 진실의 원천이며, 이 가이드는 그 의도를 풀어 적은 사이드카입니다.

## 트리거

| 이벤트 | 대상 브랜치 | 무엇이 실행되나 |
|--|--|--|
| `pull_request` | `dev`, `main` | analyze → test → build-web |
| `push` | `dev`, `main` | analyze → test → build-web |
| `push` (tag) | `v*` | analyze → test → build-web + **build-android + build-ios** |

태그 (`v0.5.x` 등) 푸시에만 모바일 빌드가 도는 이유 — Constitution v1.10.0 결정. PR 피드백 시간을 보호하면서 릴리스 시점에는 모든 플랫폼 검증.

## Job 그래프

```
analyze (Ubuntu, 항상)
   │
   └─▶ test (Ubuntu, 항상) ─────────────┬─▶ build-web (Ubuntu, 항상)
                                        │
                                        ├─▶ build-android (Ubuntu, 태그 푸시만)
                                        │
                                        └─▶ build-ios (macOS, 태그 푸시만)
```

`needs:` 의존성으로 직렬화되어 있어 analyze 실패 시 그 이후가 모두 스킵됩니다.

## 각 Job의 검증 항목

### `analyze` — 코드 분석

- `flutter pub get`
- `flutter analyze --no-fatal-infos` — error/warning만 실패 사유. info는 허용.
- `dart format --set-exit-if-changed .` — 포맷 미적용 시 실패. CI는 자동 수정하지 않음 (로컬에서 `dart format .` 실행 후 커밋).

### `test` — 단위 테스트

- `flutter test --coverage` — `coverage/lcov.info` 생성.
- `codecov/codecov-action@v3`로 업로드 → Codecov가 PR에 코멘트.

### `build-web` — Flutter Web 릴리스 빌드

- `flutter build web --release`
- 산출물 `build/web/`을 `web-build` 아티팩트로 업로드 (배포 검증/수동 다운로드용).

### `build-android` / `build-ios` — 모바일 릴리스 빌드 (태그 푸시 한정)

- Android: `flutter build apk --release` → `app-release.apk` 아티팩트.
- iOS: `flutter build ios --release --no-codesign` (CI에서는 코드 사인 안 함).

## 커버리지 게이트 (`codecov.yml`)

| 체크 | 기준 |
|--|--|
| `project` | 전체 커버리지가 baseline 대비 1%p 이상 하락하면 실패 (`target: auto`, `threshold: 1%`) |
| `patch` | PR이 추가/변경한 라인의 50% 이상에 테스트 커버리지가 있어야 함 (`threshold: 5%` — 변동 허용) |

baseline은 Codecov가 머지된 main 기준으로 자동 갱신합니다. 점진 상향은 PR 단위로 spec MVP 정의 (Backend/Flutter 80%)를 목표.

## 알려진 한계 / TODO

- **백엔드 테스트가 CI에서 돌지 않습니다**. `backend/tests/`의 100건 이상이 로컬에서만 검증되는 상태. 추가 job 필요 (TODO):
  - `services` 블록으로 Postgres 16 띄우기
  - `npm ci && npm run migrate && npm test` 실행
  - lcov 업로드 (Flutter와 별도 flag로)
- 모바일 빌드는 태그 푸시에만 실행 → PR에서 모바일 회귀 발견 불가. 로컬 `./scripts/local-verify.sh --mvp-mode`로 보완 (Constitution XVI).
- iOS는 `--no-codesign` 빌드만 — 실제 .ipa는 별도 릴리스 파이프라인 필요 (App Store / TestFlight 결정 시).

## 로컬에서 CI와 동일한 검사 돌리기

```bash
# 빠른 사전 검증 (CI analyze + test와 동등)
./scripts/local-verify.sh --skip-build

# 전체 (모바일 포함; MVP 전 정책)
./scripts/local-verify.sh --mvp-mode
```

`scripts/local-verify.sh`는 `logs/YYYY-MM-DD/verify-*.log`에 기록을 남깁니다. CI 푸시 전 실패를 잡아 RTT를 줄이는 게 목적.

## 머지 게이트

- 1 approval 이상 + 모든 CI green이어야 dev/main 머지 가능 (자세한 정책은 `~/.claude/rules/code-review.md`).
- `dev`/`main` 직접 푸시 금지 (Constitution).
- feature 브랜치는 squash merge, release 브랜치는 merge commit (Git Flow + tag 추적성 유지).
