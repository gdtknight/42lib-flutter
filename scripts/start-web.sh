#!/bin/bash

# Flutter Web 개발 서버 시작 스크립트
# Usage: ./scripts/start-web.sh [--auto|--manual]

set -e

cd "$(dirname "$0")/.."

MODE=${1:-"--auto"}

case "$MODE" in
  --auto)
    echo "🚀 자동 모드: Flutter Web 서버를 자동으로 시작합니다..."
    echo "📝 docker-compose.yml의 command가 자동 실행으로 설정됩니다."
    echo ""
    
    # docker-compose.yml이 이미 자동 실행으로 설정되어 있는지 확인
    if grep -q "flutter run -d web-server" docker/docker-compose.yml; then
      echo "✅ 이미 자동 실행 모드로 설정되어 있습니다."
      echo ""
      echo "컨테이너를 재시작합니다..."
      docker compose -f docker/docker-compose.yml restart flutter-dev
      echo ""
      echo "✅ Flutter Web 서버가 시작되었습니다!"
      echo "🌐 브라우저에서 http://localhost:8080 접속"
      echo ""
      echo "📋 로그 확인:"
      echo "   docker compose -f docker/docker-compose.yml logs -f flutter-dev"
    else
      echo "❌ docker-compose.yml이 수동 모드로 설정되어 있습니다."
      echo "   자동 모드로 전환하려면 docker-compose.yml을 수정하세요."
      exit 1
    fi
    ;;
    
  --manual)
    echo "🔧 수동 모드: Flutter 컨테이너에 접속합니다..."
    echo "📝 컨테이너 내부에서 수동으로 서버를 실행할 수 있습니다."
    echo ""
    
    # docker-compose.yml을 수동 모드로 변경
    if grep -q "flutter run -d web-server" docker/docker-compose.yml; then
      echo "⚠️  docker-compose.yml을 수동 모드로 변경합니다..."
      sed -i.bak 's/command: >.*$/command: tail -f \/dev\/null/' docker/docker-compose.yml
      docker compose -f docker/docker-compose.yml restart flutter-dev
      echo "✅ 수동 모드로 변경 완료"
      echo ""
    fi
    
    echo "컨테이너에 접속합니다..."
    echo ""
    echo "💡 컨테이너 내부에서 다음 명령어를 실행하세요:"
    echo "   cd /app"
    echo "   flutter pub get"
    echo "   flutter run -d web-server --web-hostname=0.0.0.0 --web-port=8080"
    echo ""
    
    docker compose -f docker/docker-compose.yml exec flutter-dev bash
    ;;
    
  --stop)
    echo "⏹️  Flutter Web 서버를 중지합니다..."
    docker compose -f docker/docker-compose.yml stop flutter-dev
    echo "✅ 중지 완료"
    ;;
    
  --restart)
    echo "🔄 Flutter Web 서버를 재시작합니다..."
    docker compose -f docker/docker-compose.yml restart flutter-dev
    echo "✅ 재시작 완료"
    echo "🌐 브라우저에서 http://localhost:8080 접속"
    ;;
    
  --logs)
    echo "📋 Flutter Web 서버 로그를 확인합니다..."
    docker compose -f docker/docker-compose.yml logs -f flutter-dev
    ;;
    
  --help)
    echo "Flutter Web 개발 서버 관리 스크립트"
    echo ""
    echo "사용법:"
    echo "  ./scripts/start-web.sh [옵션]"
    echo ""
    echo "옵션:"
    echo "  --auto      자동 모드 (기본값): docker-compose up 시 자동으로 서버 시작"
    echo "  --manual    수동 모드: 컨테이너 접속 후 수동으로 서버 실행"
    echo "  --stop      서버 중지"
    echo "  --restart   서버 재시작"
    echo "  --logs      서버 로그 확인"
    echo "  --help      도움말 표시"
    echo ""
    echo "예시:"
    echo "  ./scripts/start-web.sh              # 자동 모드로 시작"
    echo "  ./scripts/start-web.sh --manual     # 수동 모드로 전환"
    echo "  ./scripts/start-web.sh --logs       # 로그 확인"
    ;;
    
  *)
    echo "❌ 알 수 없는 옵션: $MODE"
    echo "도움말을 보려면: ./scripts/start-web.sh --help"
    exit 1
    ;;
esac
