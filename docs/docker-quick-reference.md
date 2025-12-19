# Docker 개발 환경 빠른 참조 가이드

## 일일 개발 워크플로우

### 아침: 개발 환경 시작

```bash
cd 42lib-flutter/docker
docker compose up -d
docker compose ps  # 모든 서비스 healthy 확인
```

### 개발 작업

**Backend 작업**:
```bash
# 컨테이너 접속
docker compose exec backend-api sh

# 로그 확인
docker compose logs -f backend-api

# Prisma 마이그레이션
npm run migrate
```

**Flutter 작업**:
```bash
# 컨테이너 접속
docker compose exec flutter-dev bash

# Web 개발 서버 실행
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080
```

### 저녁: 개발 환경 정리

```bash
# 컨테이너 중지 (데이터 유지)
docker compose stop

# 또는 완전 종료 (데이터 유지)
docker compose down
```

## 자주 사용하는 명령어

### 서비스 관리

| 명령어 | 용도 |
|--------|------|
| `docker compose up -d` | 모든 서비스 시작 (백그라운드) |
| `docker compose ps` | 실행 중인 서비스 확인 |
| `docker compose logs -f [SERVICE]` | 로그 실시간 확인 |
| `docker compose restart [SERVICE]` | 서비스 재시작 |
| `docker compose stop` | 모든 서비스 중지 |
| `docker compose down` | 모든 서비스 종료 |
| `docker compose down -v` | 모든 서비스 종료 + 데이터 삭제 |

### 컨테이너 접속

| 서비스 | 명령어 |
|--------|--------|
| Backend API | `docker compose exec backend-api sh` |
| Flutter Dev | `docker compose exec flutter-dev bash` |
| PostgreSQL | `docker compose exec postgres-db psql -U library_user -d library_db` |
| Redis | `docker compose exec redis-cache redis-cli` |

### 데이터베이스

| 작업 | 명령어 |
|------|--------|
| 마이그레이션 실행 | `docker compose exec backend-api npm run migrate` |
| 데이터 시드 | `docker compose exec backend-api npm run seed` |
| Prisma Studio | `docker compose exec backend-api npx prisma studio` |
| DB 백업 | `docker compose exec postgres-db pg_dump -U library_user library_db > backup.sql` |
| DB 복원 | `cat backup.sql \| docker compose exec -T postgres-db psql -U library_user -d library_db` |

## 트러블슈팅 빠른 참조

| 문제 | 해결 |
|------|------|
| 포트 충돌 | `docker-compose.yml`에서 포트 변경 |
| 마이그레이션 실패 | `npx prisma generate && npm run migrate` |
| Flutter 의존성 오류 | `flutter clean && flutter pub get` |
| 헬스체크 실패 | `docker compose restart [SERVICE]` |
| 디스크 공간 부족 | `docker system prune -a` |
| 느린 성능 (Mac) | Docker Desktop → Resources에서 CPU/메모리 증가 |

## 서비스 URL

| 서비스 | URL | 용도 |
|--------|-----|------|
| Backend API | http://localhost:3000/api/v1 | REST API |
| Health Check | http://localhost:3000/health | 서버 상태 확인 |
| Prisma Studio | http://localhost:5555 | DB GUI (수동 실행) |
| Flutter Web | http://localhost:8080 | 웹 앱 (수동 실행) |
| PostgreSQL | localhost:5432 | DB 직접 연결 |
| Redis | localhost:6379 | 캐시 직접 연결 |

## 환경 변수

**backend/.env** (주요 항목):
- `DATABASE_URL`: PostgreSQL 연결 문자열
- `REDIS_HOST`, `REDIS_PORT`: Redis 설정
- `JWT_SECRET`: JWT 토큰 시크릿
- `FORTYTWO_CLIENT_ID`, `FORTYTWO_CLIENT_SECRET`: 42 OAuth
- `PORT`: Backend 서버 포트

## 유용한 팁

1. **로그 색상 구분**: `docker compose logs -f --tail=100`
2. **특정 컨테이너만 재빌드**: `docker compose build --no-cache backend-api`
3. **컨테이너 리소스 모니터링**: `docker stats`
4. **볼륨 목록 확인**: `docker volume ls`
5. **네트워크 확인**: `docker network ls`

## 추가 문서

- 상세 가이드: [docs/docker-setup-guide.md](./docker-setup-guide.md)
- 개발 워크플로우: [docs/processes/development-workflow.md](./processes/development-workflow.md)
- Constitution: [.specify/memory/constitution.md](../.specify/memory/constitution.md)
