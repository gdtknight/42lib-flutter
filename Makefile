.PHONY: help up down restart logs web-start web-stop web-logs web-manual db-shell backend-shell flutter-shell clean

# 기본 명령어
help:
@echo "42lib-flutter 개발 환경 관리"
@echo ""
@echo "전체 환경:"
@echo "  make up          - 모든 서비스 시작 (Backend + DB + Flutter Web)"
@echo "  make down        - 모든 서비스 중지"
@echo "  make restart     - 모든 서비스 재시작"
@echo "  make logs        - 모든 서비스 로그 확인"
@echo ""
@echo "Flutter Web:"
@echo "  make web-start   - Flutter Web 서버 시작 (자동)"
@echo "  make web-manual  - Flutter 컨테이너 접속 (수동 실행)"
@echo "  make web-stop    - Flutter Web 서버 중지"
@echo "  make web-restart - Flutter Web 서버 재시작"
@echo "  make web-logs    - Flutter Web 로그 확인"
@echo ""
@echo "데이터베이스:"
@echo "  make db-shell    - PostgreSQL 접속"
@echo "  make db-migrate  - Prisma 마이그레이션 실행"
@echo "  make db-reset    - 데이터베이스 초기화"
@echo ""
@echo "컨테이너 접속:"
@echo "  make backend-shell  - Backend 컨테이너 접속"
@echo "  make flutter-shell  - Flutter 컨테이너 접속"
@echo ""
@echo "정리:"
@echo "  make clean       - 모든 컨테이너 및 볼륨 삭제"
@echo ""
@echo "브라우저 접속:"
@echo "  Frontend: http://localhost:8080"
@echo "  Backend:  http://localhost:3000"

# 전체 환경 관리
up:
docker compose -f docker/docker-compose.yml up -d
@echo ""
@echo "✅ 모든 서비스가 시작되었습니다!"
@echo "🌐 Frontend: http://localhost:8080"
@echo "🔧 Backend:  http://localhost:3000"
@echo ""
@echo "📋 로그 확인: make logs"

down:
docker compose -f docker/docker-compose.yml down
@echo "✅ 모든 서비스가 중지되었습니다."

restart:
docker compose -f docker/docker-compose.yml restart
@echo "✅ 모든 서비스가 재시작되었습니다."

logs:
docker compose -f docker/docker-compose.yml logs -f

# Flutter Web 관리
web-start:
@./scripts/start-web.sh --auto

web-manual:
@./scripts/start-web.sh --manual

web-stop:
docker compose -f docker/docker-compose.yml stop flutter-dev
@echo "✅ Flutter Web 서버가 중지되었습니다."

web-restart:
docker compose -f docker/docker-compose.yml restart flutter-dev
@echo "✅ Flutter Web 서버가 재시작되었습니다."
@echo "🌐 http://localhost:8080"

web-logs:
docker compose -f docker/docker-compose.yml logs -f flutter-dev

# 데이터베이스 관리
db-shell:
docker compose -f docker/docker-compose.yml exec postgres-db psql -U library_user -d library_db

db-migrate:
docker compose -f docker/docker-compose.yml exec backend-api sh -c "cd /app && npx prisma migrate deploy"
@echo "✅ 마이그레이션이 완료되었습니다."

db-reset:
docker compose -f docker/docker-compose.yml exec backend-api sh -c "cd /app && npx prisma migrate reset --force"
@echo "✅ 데이터베이스가 초기화되었습니다."

# 컨테이너 접속
backend-shell:
docker compose -f docker/docker-compose.yml exec backend-api sh

flutter-shell:
docker compose -f docker/docker-compose.yml exec flutter-dev bash

# 정리
clean:
@echo "⚠️  모든 컨테이너와 볼륨을 삭제합니다. 계속하려면 Enter를 누르세요..."
@read confirm
docker compose -f docker/docker-compose.yml down -v
@echo "✅ 정리가 완료되었습니다."

# 상태 확인
status:
docker compose -f docker/docker-compose.yml ps

# 헬스 체크
health:
@echo "🏥 서비스 상태 확인..."
@echo ""
@echo "Backend API:"
@curl -s http://localhost:3000/health | jq . || echo "❌ Backend 응답 없음"
@echo ""
@echo "Books API:"
@curl -s http://localhost:3000/api/v1/books | jq '.data | length' | xargs -I {} echo "✅ {} books found" || echo "❌ Books API 응답 없음"
@echo ""
@echo "Frontend:"
@curl -s -o /dev/null -w "Status: %{http_code}\n" http://localhost:8080 || echo "❌ Frontend 응답 없음"
