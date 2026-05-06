# 42 OAuth 등록 가이드

> **목적**: 학생 로그인을 동작시키려면 42 인트라넷에서 OAuth 앱을 등록하고 그 자격증명을 백엔드에 주입해야 합니다. 이 문서는 첫 설치 시 따라가는 절차 입니다.

## 사전 요구

- 42 인트라넷 계정 (학생 또는 직원).
- 운영/스테이징 도메인 또는 로컬 dev URL 결정.

## 절차

### 1. 42 OAuth 앱 등록

1. https://profile.intra.42.fr/oauth/applications 접속 (42 인트라 로그인 필요).
2. **Register a new app** 클릭.
3. 폼 작성:

   | 필드 | 값 |
   |--|--|
   | **Name** | `42lib (env)` 형태 권장 (예: `42lib (dev)`, `42lib (prod)`) |
   | **Redirect URI** | 환경별로 정확히 일치해야 함. 아래 표 참고. |
   | **Scopes** | `public` (현재 기본 scope; 학생 기본 정보만 필요) |

   **Redirect URI 매트릭스**

   | 환경 | Redirect URI |
   |--|--|
   | 로컬 dev (Docker) | `http://localhost:3000/api/v1/auth/42/callback` |
   | 스테이징 | `https://staging.your-domain.kr/api/v1/auth/42/callback` |
   | 운영 | `https://api.your-domain.kr/api/v1/auth/42/callback` |

   여러 환경을 쓰려면 **환경별로 별도 앱을 생성**하세요. 한 앱에 여러 redirect URI를 섞으면 콜백이 의도와 다른 환경으로 갈 위험이 있습니다.

4. 저장 후 화면에 표시되는 **UID** (= `client_id`) 와 **Secret** (= `client_secret`) 복사.

   ⚠️ **Secret은 한 번만 표시됩니다**. 안전한 곳에 즉시 저장하세요. 분실 시 앱을 재등록하거나 secret을 회전해야 합니다.

### 2. 백엔드에 자격증명 주입

`backend/.env` (없으면 `cp backend/.env.example backend/.env`):

```bash
# 위 단계에서 복사한 값을 그대로 붙여넣기
FORTYTWO_CLIENT_ID="u-s4t2ud-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"
FORTYTWO_CLIENT_SECRET="s-s4t2ud-xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx"

# 위 1단계의 Redirect URI와 정확히 일치
FORTYTWO_REDIRECT_URI="http://localhost:3000/api/v1/auth/42/callback"
```

**비밀 보호**:
- `backend/.env`는 `.gitignore`에 포함되어 있습니다. 절대 커밋하지 마세요.
- 운영에서는 secrets manager (예: AWS Secrets Manager, GCP Secret Manager, Doppler) 사용을 권장합니다.
- secret이 의심스럽게 노출됐으면 즉시 인트라 OAuth 앱 페이지에서 회전하세요.

### 3. 백엔드 재시작 후 검증

```bash
# 컨테이너 재시작으로 새 .env 반영
docker compose -f docker/docker-compose.yml restart backend-api

# 로그에서 경고가 사라졌는지 확인
docker compose -f docker/docker-compose.yml logs backend-api | grep -i "42 OAuth"
# 정상: 아무 경고 없음
# 비정상: "42 OAuth credentials not configured" → .env 미반영
```

`Auth42Service` 생성자는 자격증명이 없어도 죽지 않고 경고만 찍습니다 (관리자 흐름은 OAuth 없이 동작). 학생 로그인 시점에야 비로소 미설정이 에러로 표면화됩니다.

### 4. 학생 로그인 종단 검증

1. Flutter 앱 (web/mobile) 또는 직접 `GET /api/v1/auth/42/login` 호출.
2. 42 인트라 로그인 페이지로 리디렉트되는지.
3. 로그인 후 `FORTYTWO_REDIRECT_URI`로 돌아오면서 `?code=...` 쿼리 파라미터가 붙는지.
4. 콜백 핸들러가 JWT를 발급하고 학생 레코드를 생성/갱신하는지.

서비스 동작은 다음과 같이 단계화됩니다 (`backend/src/services/auth_42_service.ts`):

1. `exchangeCodeForToken(code)` → 42 토큰 엔드포인트 POST.
2. `getUserInfo(accessToken)` → 42 `/v2/me`로 프로필 조회.
3. `findOrCreateStudent(fortyTwoUser)` → DB upsert (BR-102: 신규 생성, BR-103: 매 로그인마다 정보 갱신).
4. 백엔드 JWT 서명 후 클라이언트에 응답.

## 트러블슈팅

| 증상 | 원인 | 해결 |
|--|--|--|
| `42 OAuth configuration missing` | 환경 변수 미주입 | `.env` 확인 후 컨테이너 재시작 |
| 콜백 리디렉트 실패 (404 또는 mismatch) | Redirect URI 불일치 | 인트라 앱 등록 화면과 `.env`의 `FORTYTWO_REDIRECT_URI` 글자 단위로 일치시키기 (trailing slash 포함) |
| `42 OAuth token exchange failed` | client_secret 오타 또는 회전됨 | 인트라에서 secret 재확인, 회전했으면 `.env` 업데이트 |
| 학생 정보가 갱신되지 않음 | 정상 동작 (BR-103: 로그인 시점에만 갱신) | 학생이 다시 로그인하면 갱신됨 |

## 보안 체크리스트

- [ ] `.env`가 git에 커밋되지 않았는가
- [ ] `JWT_SECRET`이 32자 이상의 랜덤 값인가 (`openssl rand -hex 32`)
- [ ] 운영 redirect URI가 HTTPS인가
- [ ] 운영 인스턴스에 secrets manager가 적용되었는가
- [ ] secret 회전 절차가 문서화되었는가 (이 문서 + 운영 ADR)

## 관련 문서

- 백엔드 환경 변수 전체: `backend/.env.example`
- API 문서 (Swagger UI): `http://localhost:3000/api/docs`
- 데이터베이스 백업/복원: `docs/guides/database-backup-restore.md`
