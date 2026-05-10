# 배포 가이드

> **대상**: 운영 / 스테이징 인스턴스를 처음 띄우는 운영자.
> **타깃**: Docker Compose 기반 self-host (단일 호스트 또는 소규모 VM 풀).
> **범위**: 4개 서비스 (Postgres / Redis / Backend / Flutter Web) + nginx 또는 클라우드 LB 앞단.

이 문서는 spec MVP가 가정하는 배포 형태(헌법 v1.10.0)를 기준으로 합니다. Kubernetes / 서버리스 배포는 별도 ADR 후 추가합니다.

## 0. 사전 결정 사항

배포 전에 답해야 할 질문:

| 질문 | 옵션 | 가이드 |
|--|--|--|
| 어디에 배포? | 단일 VM (AWS EC2, GCP CE, 42 제공 호스트) / Docker Swarm / Kubernetes | 이 문서는 단일 VM 가정. K8s는 ADR 후 별도. |
| 도메인? | `lib.your-domain.kr` 등 | TLS 필수 (Let's Encrypt 권장) |
| 데이터 보존? | 일 1회 + 30일 보관 (`docs/guides/database-backup-restore.md`) | 운영 시작 전 cron 등록 |
| 시크릿 관리? | env 파일 / AWS Secrets Manager / GCP Secret Manager / Doppler | 운영은 SM 권장. 개발은 `.env` |
| 모니터링? | 헬스체크만 / Prometheus / Datadog | MVP는 `/health` 폴링 + 컨테이너 헬스체크로 충분 |

## 1. 호스트 사전 요구

| 항목 | 최소 | 권장 |
|--|--|--|
| OS | Linux (Ubuntu 22.04+ / Debian 12+) | Ubuntu 22.04 LTS |
| RAM | 4 GB | 8 GB |
| 디스크 | 20 GB SSD | 50 GB SSD (DB 성장 + 로그) |
| Docker | 24+ | 최신 stable |
| Docker Compose | v2 | v2.20+ |
| 도메인 / DNS | A 레코드 | + AAAA |
| TLS | Let's Encrypt | nginx + certbot |

## 2. 시크릿 / 환경 변수 준비

```bash
# 호스트에 repo 클론 (또는 CI에서 미리 빌드된 이미지 pull)
git clone git@github.com:gdtknight/42lib-flutter.git /opt/lib42
cd /opt/lib42
git checkout v0.6.0   # 안정 태그로 고정

# 운영 .env (절대 git 커밋 금지)
cp backend/.env.example backend/.env
chmod 600 backend/.env

# 필수 항목 채우기:
#   DATABASE_URL  — 호스트 외부 DB라면 RDS/Cloud SQL URL로 교체
#   JWT_SECRET    — openssl rand -hex 32
#   FORTYTWO_*    — docs/guides/42-oauth-setup.md 따라 발급한 운영 앱 자격증명
#                  (운영 redirect_uri는 staging/dev와 다른 별도 앱 권장)
```

> 🔒 **시크릿이 호스트 디스크에 평문으로 남는 것을 피하려면**: AWS Secrets Manager / GCP Secret Manager 등에서 부팅 시점에 `aws secretsmanager get-secret-value`로 fetch해 `.env`를 생성하는 systemd unit을 추가합니다 (이 문서 범위 밖).

## 3. 데이터베이스 준비

### 3.1 컨테이너 내장 Postgres (소규모)

`docker-compose.yml`의 `postgres-db` 서비스를 그대로 사용. 데이터는 named volume (`postgres_data`)에 영속.

**경고**: 이 방식은 단일 노드 + 백업이 호스트에 한정됨. 다음을 반드시:
- 일 1회 cron 백업 (`docs/guides/database-backup-restore.md`)
- 호스트 자체 디스크 스냅샷 (cloud provider 기능)

### 3.2 외부 관리형 DB (권장)

운영은 RDS / Cloud SQL / Neon 등 관리형 Postgres 16 권장. 이유:
- 자동 백업 / PITR
- 멀티 AZ 가용성
- Point-in-Time Recovery
- 마이너 버전 업그레이드 자동화

이 경우:
1. `docker-compose.yml`에서 `postgres-db` 서비스 주석 처리 (또는 `production` profile에서 제외).
2. `backend/.env`의 `DATABASE_URL`을 관리형 DB connection string으로 교체.
3. 백엔드 컨테이너의 `depends_on`에서 `postgres-db` 제거.

## 4. 첫 배포

```bash
cd /opt/lib42

# 마이그레이션 적용 (앱 시작 전!)
docker compose -f docker/docker-compose.yml run --rm backend-api npx prisma migrate deploy

# (옵션) 시드 데이터 — 운영에서는 보통 skip. 카탈로그를 직접 입력하는 경우만.
# docker compose -f docker/docker-compose.yml run --rm backend-api npm run seed

# 모든 서비스 기동
docker compose -f docker/docker-compose.yml up -d

# 상태 확인
docker compose -f docker/docker-compose.yml ps
curl -fsS http://localhost:3000/health   # → {"status":"ok",...}
curl -fsS http://localhost:8080/         # → Flutter web index
```

## 5. nginx 리버스 프록시 + TLS

운영에서는 직접 3000/8080 노출하지 말고 nginx 앞단:

```nginx
# /etc/nginx/sites-available/lib42
server {
  listen 443 ssl http2;
  server_name lib.your-domain.kr;

  ssl_certificate     /etc/letsencrypt/live/lib.your-domain.kr/fullchain.pem;
  ssl_certificate_key /etc/letsencrypt/live/lib.your-domain.kr/privkey.pem;

  # Strict-Transport-Security 등 보안 헤더는 helmet (백엔드)에서도 설정됨.
  # nginx에서 HSTS 추가:
  add_header Strict-Transport-Security "max-age=31536000; includeSubDomains" always;

  # Flutter Web (정적 파일)
  location / {
    proxy_pass http://127.0.0.1:8080;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
  }

  # Backend API
  location /api/ {
    proxy_pass http://127.0.0.1:3000;
    proxy_set_header Host $host;
    proxy_set_header X-Real-IP $remote_addr;
    proxy_set_header X-Forwarded-Proto $scheme;
    proxy_read_timeout 30s;
  }

  # Health check (LB / 모니터링용)
  location = /health {
    proxy_pass http://127.0.0.1:3000/health;
    access_log off;
  }
}

server {
  listen 80;
  server_name lib.your-domain.kr;
  return 301 https://$host$request_uri;
}
```

```bash
# Let's Encrypt 발급 (최초)
sudo certbot --nginx -d lib.your-domain.kr

# 자동 갱신 (certbot은 systemd 타이머 자동 등록)
sudo systemctl status certbot.timer
```

`backend/.env`의 `FORTYTWO_REDIRECT_URI`를 `https://lib.your-domain.kr/api/v1/auth/42/callback`로 맞추고, 42 OAuth 앱 등록 페이지에서도 동일하게 갱신.

## 6. 운영 체크리스트

### 첫 배포 직후

- [ ] `/health` 200 OK
- [ ] `/api/v1` 200 OK with `{message: "42lib API v1"}`
- [ ] `/api/docs/` Swagger UI 렌더
- [ ] 학생 OAuth: `/api/v1/auth/42/login` → 42 인트라 → 콜백 성공
- [ ] 관리자 로그인: `/admin/login` 페이지 + 토큰 발급
- [ ] DB 마이그레이션 적용 상태: `docker compose exec postgres-db psql -U library_user -d library_db -c "SELECT version FROM _prisma_migrations ORDER BY started_at DESC LIMIT 5;"`
- [ ] 컨테이너 헬스체크: `docker compose ps`에서 모든 서비스 (healthy)

### 운영 중 정기 점검

- [ ] 일 1회 자동 DB 백업 동작 (`docs/guides/database-backup-restore.md`)
- [ ] 분기 1회 백업 복원 리허설
- [ ] 디스크 사용량 (DB volume + 로그) — `df -h`
- [ ] JWT_SECRET 회전 정책 (운영 ADR에 따라)
- [ ] 컨테이너 이미지 base 보안 업데이트 (`docker compose build --no-cache --pull` 후 재배포)
- [ ] **월 1회 시크릿 audit** — `./scripts/audit-secrets.sh` (릴리스 직전에도 실행). `--history` 플래그로 전체 git 히스토리까지 스캔 가능.

## 7. 업그레이드 절차

```bash
cd /opt/lib42

# 1. 백업 먼저
docker compose -f docker/docker-compose.yml exec postgres-db \
  pg_dump -U library_user -F c library_db > /var/backups/lib42/pre-upgrade-$(date +%Y%m%d-%H%M%S).dump

# 2. 다음 안정 태그로 이동
git fetch --tags
git checkout v0.6.X   # 다음 패치 버전

# 3. 마이그레이션 (앱 정지 없이도 backwards-compatible 마이그레이션 정책상 안전. 자세한 정책은 ~/.claude/rules/database.md)
docker compose -f docker/docker-compose.yml run --rm backend-api npx prisma migrate deploy

# 4. 컨테이너 재배포 (롤링은 다중 호스트일 때만 의미. 단일 호스트는 짧은 다운타임 감수)
docker compose -f docker/docker-compose.yml up -d --build

# 5. 즉시 검증
curl -fsS https://lib.your-domain.kr/health
curl -fsS https://lib.your-domain.kr/api/v1
```

문제 발생 시 **롤백**:

```bash
# 이전 태그로 되돌리기
git checkout v0.5.5
docker compose -f docker/docker-compose.yml up -d --build

# DB가 backwards-compatible이 아닌 마이그레이션을 받았다면 (드물지만) 백업에서 복원:
# docs/guides/database-backup-restore.md 의 §2 참고
```

## 8. 알려진 한계 / 후속 작업

- **단일 호스트만 다룸**: HA가 필요하면 K8s + StatefulSet (Postgres) 또는 관리형 DB. 별도 ADR 필요.
- **CI/CD에 자동 배포 미연결**: 현재는 호스트에서 수동 `git checkout` + `docker compose up`. GitHub Actions의 `deploy` job은 운영 환경 결정 후 추가 (TODO).
- **모니터링 / 알림 미설정**: `/health`만 있음. Prometheus exporter / Sentry 통합은 운영 필요 시 추가.
- **로그 수집**: 컨테이너 로그는 호스트 디스크에만. Loki / CloudWatch / Datadog 등 중앙화는 별도.

## 관련 문서

- [42 OAuth 등록 가이드](./42-oauth-setup.md) — 운영 자격증명 발급 + redirect_uri 매핑
- [데이터베이스 백업 / 복원](./database-backup-restore.md) — 백업 자동화 + 복원 절차
- [CI/CD 파이프라인](./ci-cd-pipeline.md) — PR 게이트와 빌드 검증
- [환경 변수 레퍼런스](../../backend/.env.example) — 모든 변수의 의미 + 필수 여부
