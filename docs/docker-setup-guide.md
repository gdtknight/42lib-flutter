# Docker 개발 환경 셋업 가이드

**작성일**: 2025-12-19  
**버전**: v1.0  
**대상**: 42 Learning Space Library Management System

## 목차

1. [개요](#개요)
2. [시스템 요구사항](#시스템-요구사항)
3. [서비스 구성](#서비스-구성)
4. [설치 및 실행](#설치-및-실행)
5. [개발 워크플로우](#개발-워크플로우)
6. [환경 변수 관리](#환경-변수-관리)
7. [데이터베이스 관리](#데이터베이스-관리)
8. [트러블슈팅](#트러블슈팅)

## 개요

42lib-flutter 프로젝트는 Docker Compose를 사용하여 로컬 개발 환경의 오염 없이 전체 개발 스택을 실행합니다. 이는 Constitution 원칙 VIII (Docker 기반 개발 환경)을 준수합니다.

### Docker Compose로 관리되는 서비스

- **PostgreSQL**: 데이터베이스 (포트 5432)
- **Redis**: 캐싱 레이어 (포트 6379)
- **Backend API**: Node.js/Express 서버 (포트 3000)
- **Flutter Dev**: Flutter 개발 환경

## 시스템 요구사항

### 필수 소프트웨어

- **Docker Desktop** (최신 버전 권장)
  - macOS: Docker Desktop for Mac
  - Windows: Docker Desktop for Windows (WSL2 권장)
  - Linux: Docker Engine + Docker Compose
- **Git** 2.0 이상
- **최소 시스템 사양**:
  - RAM: 8GB 이상
  - 디스크 여유 공간: 20GB 이상
  - CPU: 멀티코어 프로세서 (권장)

### Docker 설치 확인

```bash
# Docker 버전 확인
docker --version
# 예상 출력: Docker version 24.0.x, build ...

# Docker Compose 버전 확인
docker compose version
# 예상 출력: Docker Compose version v2.x.x
```

## 서비스 구성

### docker-compose.yml 구조

```yaml
services:
  postgres-db:     # PostgreSQL 16 (Alpine)
  redis-cache:     # Redis 7 (Alpine)
  backend-api:     # Node.js 20 + Express + Prisma
  flutter-dev:     # Flutter SDK (최신 stable)

volumes:
  postgres_data:   # 데이터베이스 영구 저장소
  redis_data:      # Redis 영구 저장소
  flutter_pub_cache: # Flutter 패키지 캐시
```

### 네트워크 포트

| 서비스 | 호스트 포트 | 컨테이너 포트 | 용도 |
|--------|------------|--------------|------|
| PostgreSQL | 5432 | 5432 | 데이터베이스 |
| Redis | 6379 | 6379 | 캐시 |
| Backend API | 3000 | 3000 | REST API |
| Flutter Web | 8080 | 8080 | 개발 서버 (수동 실행) |

## 설치 및 실행

### 1단계: 저장소 클론 및 이동

```bash
git clone git@github.com:gdtknight/42lib-flutter.git
cd 42lib-flutter
```

### 2단계: 환경 변수 확인

```bash
# Backend 환경 변수 확인 (이미 생성됨)
cat backend/.env

# 필수 환경 변수:
# - DATABASE_URL: PostgreSQL 연결 문자열
# - JWT_SECRET: JWT 토큰 시크릿 키
# - FORTYTWO_CLIENT_ID: 42 OAuth Client ID
# - FORTYTWO_CLIENT_SECRET: 42 OAuth Client Secret
```

**주의**: `.env` 파일은 Git에 커밋되지 않습니다. 필요 시 `.env.example`을 복사하여 사용하세요.

### 3단계: Docker Compose 실행

```bash
# docker/ 디렉토리로 이동
cd docker

# 컨테이너 빌드 및 시작 (최초 실행 시 5-10분 소요)
docker compose up -d

# 출력 예시:
# [+] Building 120.5s (24/24) FINISHED
# [+] Running 7/7
#  ✔ Network docker_default          Created
#  ✔ Volume "docker_postgres_data"   Created
#  ✔ Volume "docker_redis_data"      Created
#  ✔ Volume "docker_flutter_pub_cache" Created
#  ✔ Container 42lib-postgres        Started (healthy)
#  ✔ Container 42lib-redis           Started (healthy)
#  ✔ Container 42lib-backend         Started (healthy)
#  ✔ Container 42lib-flutter-dev     Started
```

### 4단계: 서비스 상태 확인

```bash
# 실행 중인 컨테이너 확인
docker compose ps

# 예상 출력:
NAME                  IMAGE                      STATUS          PORTS
42lib-postgres        postgres:16-alpine         Up (healthy)    0.0.0.0:5432->5432/tcp
42lib-redis           redis:7-alpine             Up (healthy)    0.0.0.0:6379->6379/tcp
42lib-backend         docker-backend-api         Up (healthy)    0.0.0.0:3000->3000/tcp
42lib-flutter-dev     docker-flutter-dev         Up              -
```

### 5단계: 데이터베이스 초기화

```bash
# Backend 컨테이너에 접속
docker compose exec backend-api sh

# Prisma 마이그레이션 실행
npm run migrate

# 출력 예시:
# Prisma schema loaded from prisma/schema.prisma
# Datasource "db": PostgreSQL database "library_db"
# ✔ Generated Prisma Client (5.7.0)
# Database schema is up to date!

# 초기 데이터 시드 (선택사항)
npm run seed

# 컨테이너 종료
exit
```

### 6단계: Flutter 의존성 설치

```bash
# Flutter 컨테이너에 접속
docker compose exec flutter-dev bash

# Flutter 의존성 설치
flutter pub get

# 출력 예시:
# Resolving dependencies...
# Got dependencies!

# 컨테이너 종료
exit
```

### 7단계: 서비스 접속 확인

```bash
# Backend API Health Check
curl http://localhost:3000/health
# 예상 응답: {"status":"ok","timestamp":"2025-12-19T..."}

# Backend API 버전 확인
curl http://localhost:3000/api/v1
# 예상 응답: {"message":"42lib API v1","status":"ready"}

# PostgreSQL 연결 확인
docker compose exec postgres-db psql -U library_user -d library_db -c "SELECT version();"

# Redis 연결 확인
docker compose exec redis-cache redis-cli ping
# 예상 응답: PONG
```

## 개발 워크플로우

### Backend API 개발

Backend는 자동으로 실행되며 핫 리로드가 활성화되어 있습니다.

```bash
# 로그 확인 (실시간)
docker compose logs -f backend-api

# 컨테이너 접속
docker compose exec backend-api sh

# Prisma Studio 실행 (데이터베이스 GUI)
npx prisma studio
# 브라우저에서 http://localhost:5555 접속
```

### Flutter 개발

#### Flutter Web 개발

```bash
# Flutter 컨테이너 접속
docker compose exec flutter-dev bash

# Web 개발 서버 실행
flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080

# 브라우저에서 접속: http://localhost:8080
```

#### Flutter Android 개발

```bash
# Android Emulator 실행 (호스트 머신에서)
# AVD Manager에서 에뮬레이터 시작

# Flutter 컨테이너에서 실행
flutter run -d android
```

#### Flutter iOS 개발 (macOS만 해당)

```bash
# iOS Simulator 실행 (호스트 머신에서)
open -a Simulator

# Flutter 컨테이너에서 실행
flutter run -d ios
```

### 코드 변경 후 자동 재시작

- **Backend**: `ts-node-dev`가 자동으로 재시작
- **Flutter Web**: Hot Reload 지원 (r 키 또는 파일 저장)

## 환경 변수 관리

### backend/.env 파일 구조

```bash
# Database
DATABASE_URL="postgresql://library_user:library_pass@postgres-db:5432/library_db?schema=public"

# Redis Cache
REDIS_HOST="redis-cache"
REDIS_PORT=6379
REDIS_PASSWORD=""

# JWT
JWT_SECRET="your-secret-key-change-in-production"
JWT_EXPIRES_IN="7d"

# 42 API OAuth
FORTYTWO_CLIENT_ID="your_42_client_id"
FORTYTWO_CLIENT_SECRET="your_42_client_secret"
FORTYTWO_REDIRECT_URI="http://localhost:3000/api/v1/auth/42/callback"

# Server
PORT=3000
NODE_ENV="development"

# Rate Limiting
RATE_LIMIT_WINDOW_MS=60000
RATE_LIMIT_MAX_REQUESTS=100

# Logging
LOG_LEVEL="info"
```

### 42 OAuth 설정

1. 42 Intra에서 애플리케이션 등록:
   - Redirect URI: `http://localhost:3000/api/v1/auth/42/callback`
2. Client ID와 Client Secret을 `.env` 파일에 추가
3. Backend 재시작: `docker compose restart backend-api`

## 데이터베이스 관리

### Prisma 마이그레이션

```bash
# 새로운 마이그레이션 생성
docker compose exec backend-api sh
npm run migrate

# 마이그레이션 상태 확인
npx prisma migrate status

# 마이그레이션 히스토리 확인
npx prisma migrate history
```

### 데이터베이스 초기화 (주의!)

```bash
# 모든 데이터 삭제 후 재생성
docker compose exec backend-api sh
npx prisma migrate reset

# 또는 볼륨 삭제
docker compose down -v
docker compose up -d
```

### 데이터베이스 백업

```bash
# 백업 생성
docker compose exec postgres-db pg_dump -U library_user library_db > backup_$(date +%Y%m%d).sql

# 백업 복원
cat backup_20251219.sql | docker compose exec -T postgres-db psql -U library_user -d library_db
```

### 데이터베이스 직접 접속

```bash
# psql 클라이언트로 접속
docker compose exec postgres-db psql -U library_user -d library_db

# 테이블 목록 확인
\dt

# 쿼리 실행 예시
SELECT * FROM books LIMIT 10;

# 종료
\q
```

## 트러블슈팅

### 문제 1: 포트 충돌 (Address already in use)

**증상**: `Error starting userland proxy: listen tcp4 0.0.0.0:5432: bind: address already in use`

**해결**:
```bash
# 사용 중인 프로세스 확인
lsof -i :5432

# 프로세스 종료 또는 docker-compose.yml에서 포트 변경
# 예: "5433:5432"로 변경
```

### 문제 2: 데이터베이스 마이그레이션 실패

**증상**: `Prisma Migrate could not create the shadow database`

**해결**:
```bash
# Prisma Client 재생성
docker compose exec backend-api npx prisma generate

# 마이그레이션 재실행
docker compose exec backend-api npm run migrate

# 여전히 실패 시 데이터베이스 초기화
docker compose exec backend-api npx prisma migrate reset
```

### 문제 3: Flutter 의존성 설치 실패

**증상**: `Failed to resolve dependencies`

**해결**:
```bash
# Pub cache 클리어
docker compose exec flutter-dev flutter clean
docker compose exec flutter-dev flutter pub get

# 여전히 실패 시 Flutter 컨테이너 재빌드
docker compose down
docker compose build --no-cache flutter-dev
docker compose up -d
```

### 문제 4: 컨테이너 헬스체크 실패

**증상**: `Container unhealthy` 상태

**해결**:
```bash
# 로그 확인
docker compose logs backend-api
docker compose logs postgres-db

# 컨테이너 재시작
docker compose restart backend-api

# 여전히 실패 시 전체 재시작
docker compose down
docker compose up -d
```

### 문제 5: Docker 디스크 공간 부족

**증상**: `no space left on device`

**해결**:
```bash
# 사용하지 않는 이미지/컨테이너/볼륨 정리
docker system prune -a --volumes

# 특정 볼륨만 삭제 (주의: 데이터 손실!)
docker volume rm docker_postgres_data
```

### 문제 6: Mac에서 성능 문제

**증상**: 컨테이너가 느림

**해결**:
- Docker Desktop → Settings → Resources에서 CPU/메모리 할당 증가
- VirtioFS 파일 시스템 사용 (Settings → General → VirtioFS)

## 유용한 명령어 모음

```bash
# 모든 컨테이너 로그 확인
docker compose logs -f

# 특정 컨테이너 로그 확인
docker compose logs -f backend-api

# 컨테이너 재시작
docker compose restart backend-api

# 컨테이너 중지
docker compose stop

# 컨테이너 시작
docker compose start

# 전체 환경 종료 (데이터 유지)
docker compose down

# 전체 환경 종료 + 볼륨 삭제 (데이터 삭제)
docker compose down -v

# 빌드 캐시 클리어 후 재빌드
docker compose build --no-cache
docker compose up -d

# 컨테이너 리소스 사용량 확인
docker stats

# 실행 중인 컨테이너 셸 접속
docker compose exec backend-api sh    # Backend
docker compose exec flutter-dev bash  # Flutter
docker compose exec postgres-db bash  # PostgreSQL
docker compose exec redis-cache sh    # Redis
```

## 참고 자료

- [Docker Compose 공식 문서](https://docs.docker.com/compose/)
- [Prisma 마이그레이션 가이드](https://www.prisma.io/docs/concepts/components/prisma-migrate)
- [Flutter Docker 개발 환경](https://flutter.dev/docs/deployment/cd#docker)
- [PostgreSQL Docker 이미지](https://hub.docker.com/_/postgres)
- [Redis Docker 이미지](https://hub.docker.com/_/redis)

---

**작성자**: 42lib-flutter team  
**최종 수정**: 2025-12-19  
**버전**: v1.0
