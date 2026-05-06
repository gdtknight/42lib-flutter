# 데이터베이스 백업 / 복원 절차

> **대상**: 운영 / 스테이징 인스턴스를 관리하는 운영자.
> **DB 엔진**: PostgreSQL 16 (`docker/docker-compose.yml`의 `postgres-db` 서비스).

## 큰 그림

이 시스템은 두 가지 영속성을 사용합니다:

1. **Postgres** — 모든 비즈니스 데이터 (도서, 학생, 대출, 예약, 추천 등). **반드시 백업해야 함**.
2. **Redis** — 캐시 전용. 휘발성 OK. 백업 불필요.

학생/관리자가 업로드한 파일은 현재 없습니다 (도서 표지는 외부 URL 참조).

## 권장 정책 (recommended defaults)

| 환경 | 빈도 | 보관 기간 | 도구 |
|--|--|--|--|
| 운영 (production) | 일 1회 + WAL 연속 | 30일 | `pg_dumpall` + cron + cloud storage |
| 스테이징 | 주 1회 | 14일 | `pg_dump` + 로컬 |
| 개발 | 즉시 시드 가능 | n/a | `make db-reset` + `npm run seed` |

자세한 백업/복원 정책 ADR은 운영 환경 결정 시 추가합니다 (TODO).

---

## 1. 수동 백업 (full dump)

### 1.1 컨테이너 내부에서 (개발/스테이징)

```bash
# 단일 DB 덤프 (custom format, pg_restore로 부분 복원 가능)
docker compose -f docker/docker-compose.yml exec postgres-db \
  pg_dump -U library_user -F c -d library_db > backup-$(date +%Y%m%d-%H%M%S).dump

# 평문 SQL 덤프 (psql로 전체 적용 — 가독성 우선)
docker compose -f docker/docker-compose.yml exec postgres-db \
  pg_dump -U library_user library_db > backup-$(date +%Y%m%d-%H%M%S).sql
```

### 1.2 호스트에서 직접 (운영)

운영 인스턴스가 호스트의 `5432`로 노출되어 있다면:

```bash
PGPASSWORD=$DB_PASSWORD pg_dump \
  -h $DB_HOST -p 5432 -U $DB_USER -F c \
  -d $DB_NAME > backup-$(date +%Y%m%d-%H%M%S).dump
```

**주의**: 운영에서는 `DATABASE_URL`을 환경 변수로 주입하고 위 변수도 거기서 파싱하세요. 시크릿을 명령 히스토리에 남기지 마세요.

---

## 2. 복원

### 2.1 custom format dump 복원

```bash
# 컨테이너 내부 (테스트/스테이징)
cat backup-20240315-093000.dump | \
  docker compose -f docker/docker-compose.yml exec -T postgres-db \
  pg_restore -U library_user -d library_db --clean --if-exists

# 호스트 직접
PGPASSWORD=$DB_PASSWORD pg_restore \
  -h $DB_HOST -p 5432 -U $DB_USER -d $DB_NAME \
  --clean --if-exists backup-20240315-093000.dump
```

`--clean --if-exists`는 기존 객체를 drop 후 복원합니다. 빈 DB로 복원하려면 빼도 됩니다.

### 2.2 평문 SQL 덤프 복원

```bash
# 컨테이너
cat backup-20240315-093000.sql | \
  docker compose -f docker/docker-compose.yml exec -T postgres-db \
  psql -U library_user -d library_db
```

### 2.3 복원 후 점검 체크리스트

- [ ] `SELECT count(*) FROM books;` — 도서 수 일치
- [ ] `SELECT count(*) FROM students;` — 학생 수 일치
- [ ] `SELECT count(*) FROM loan_requests WHERE status = 'pending';` — pending 상태 보존
- [ ] `SELECT count(*) FROM reservations WHERE status IN ('waiting','notified');` — 활성 예약 보존
- [ ] `npm run migrate` — Prisma 스키마와 일치 확인 (필요 시 마이그레이션)
- [ ] `/health` 엔드포인트 200 OK
- [ ] 학생 로그인 + 관리자 로그인 한 번씩 수동 검증

---

## 3. 자동 백업 (cron 예시)

운영 인스턴스 호스트에서:

```bash
# /etc/cron.d/lib42-backup (운영자 수정 필요)
0 3 * * * lib42 /opt/lib42/scripts/backup-postgres.sh
```

`scripts/backup-postgres.sh` 예시 골격:

```bash
#!/usr/bin/env bash
set -euo pipefail
TS=$(date +%Y%m%d-%H%M%S)
DEST=${BACKUP_DIR:-/var/backups/lib42}
mkdir -p "$DEST"
PGPASSWORD="$DB_PASSWORD" pg_dump \
  -h "$DB_HOST" -U "$DB_USER" -F c -d "$DB_NAME" \
  | gzip > "$DEST/library_db-$TS.dump.gz"

# 30일 이상 된 백업 정리
find "$DEST" -name 'library_db-*.dump.gz' -mtime +30 -delete

# (옵션) 클라우드 스토리지 업로드
# aws s3 cp "$DEST/library_db-$TS.dump.gz" s3://your-backup-bucket/postgres/
```

이 스크립트는 아직 repo에 포함되어 있지 않습니다. 운영 환경 결정 시 추가 (TODO).

---

## 4. 마이그레이션과의 관계

- `npm run migrate` (`prisma migrate deploy`)는 **스키마 변경**을 적용합니다. 데이터 백업과는 별개입니다.
- 운영 배포 순서: **(1) DB 백업 → (2) 마이그레이션 → (3) 앱 배포**.
- 마이그레이션은 항상 backwards-compatible로 작성합니다 (컬럼 추가는 nullable, 삭제는 단계적). 자세한 정책은 `~/.claude/rules/database.md` 참조.

---

## 5. 로컬 개발자에게: 빠른 초기화

데이터를 통째로 날리고 시드 데이터로 다시 채우려면:

```bash
make db-reset       # 컨테이너 + 볼륨 재생성
make db-migrate     # Prisma 스키마 적용
docker compose -f docker/docker-compose.yml exec backend-api npm run seed
```

**경고**: `db-reset`은 모든 데이터를 삭제합니다. 운영에서는 절대 사용하지 마세요.
