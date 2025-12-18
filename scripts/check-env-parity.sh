#!/bin/bash
#
# Environment Parity Check Script
# 로컬 개발 환경과 CI/CD 환경의 동등성 확인
#
# Usage: ./scripts/check-env-parity.sh

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         Environment Parity Check                          ║${NC}"
echo -e "${BLUE}║         로컬 환경 ↔ CI/CD 환경 일치 확인                  ║${NC}"
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""

print_step() {
  echo -e "\n${BLUE}▶ $1${NC}"
}

print_success() {
  echo -e "${GREEN}✓ $1${NC}"
}

print_error() {
  echo -e "${RED}✗ $1${NC}"
}

print_warning() {
  echo -e "${YELLOW}⚠ $1${NC}"
}

# Check if Docker is running
print_step "1. Docker 환경 확인..."
if ! docker info > /dev/null 2>&1; then
  print_error "Docker가 실행 중이지 않습니다"
  exit 1
fi

cd "${PROJECT_ROOT}/docker"
if ! docker-compose ps flutter-dev | grep -q "Up"; then
  print_warning "Flutter dev container가 실행 중이지 않습니다. 시작 중..."
  docker-compose up -d flutter-dev
  sleep 5
fi
print_success "Docker 환경 준비 완료"

# Get local Flutter version
print_step "2. 로컬 Flutter 버전 확인..."
LOCAL_FLUTTER=$(docker-compose exec -T flutter-dev flutter --version 2>/dev/null | head -1 | awk '{print $2}')
if [ -z "$LOCAL_FLUTTER" ]; then
  print_error "로컬 Flutter 버전을 확인할 수 없습니다"
  exit 1
fi
echo "   로컬 Docker: Flutter ${LOCAL_FLUTTER}"

# Get CI Flutter version from workflow file
print_step "3. CI/CD Flutter 버전 확인..."
cd "${PROJECT_ROOT}"
CI_FLUTTER=$(grep "flutter-version:" .github/workflows/ci.yml | head -1 | sed "s/.*flutter-version: *'\([^']*\)'.*/\1/")
if [ -z "$CI_FLUTTER" ]; then
  print_error "CI/CD Flutter 버전을 확인할 수 없습니다"
  exit 1
fi
echo "   GitHub Actions: Flutter ${CI_FLUTTER}"

# Compare versions
print_step "4. 버전 일치 여부 확인..."
if [ "$LOCAL_FLUTTER" = "$CI_FLUTTER" ]; then
  print_success "Flutter 버전 일치: ${LOCAL_FLUTTER}"
else
  print_error "Flutter 버전 불일치!"
  echo "   로컬: ${LOCAL_FLUTTER}"
  echo "   CI:   ${CI_FLUTTER}"
  echo ""
  print_warning "해결 방법:"
  echo "   1. docker/Dockerfile에서 FLUTTER_VERSION을 ${CI_FLUTTER}로 수정"
  echo "   2. cd docker && docker-compose down"
  echo "   3. docker-compose build --no-cache"
  echo "   4. docker-compose up -d"
  exit 1
fi

# Get Dart version
print_step "5. Dart 버전 확인..."
cd "${PROJECT_ROOT}/docker"
LOCAL_DART=$(docker-compose exec -T flutter-dev dart --version 2>&1 | head -1 | awk '{print $4}')
echo "   로컬 Docker: Dart ${LOCAL_DART}"
print_success "Dart 버전 확인 완료"

# Check Ubuntu version
print_step "6. Base OS 확인..."
LOCAL_OS=$(docker-compose exec -T flutter-dev cat /etc/os-release 2>/dev/null | grep "PRETTY_NAME" | cut -d'"' -f2)
echo "   로컬 Docker: ${LOCAL_OS}"

CI_OS=$(grep "runs-on:" "${PROJECT_ROOT}/.github/workflows/ci.yml" | head -1 | awk '{print $2}')
echo "   GitHub Actions: ${CI_OS}"

if [[ "$LOCAL_OS" == *"Ubuntu"* ]] && [[ "$CI_OS" == *"ubuntu"* ]]; then
  print_success "Base OS 호환 확인"
else
  print_warning "Base OS 차이가 있을 수 있습니다"
fi

# Check pubspec.lock exists
print_step "7. 의존성 동기화 확인..."
if [ -f "${PROJECT_ROOT}/pubspec.lock" ]; then
  print_success "pubspec.lock 존재 (의존성 버전 고정)"
else
  print_warning "pubspec.lock이 없습니다. flutter pub get을 실행하세요"
fi

# Summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║              ✓ 환경 일치 확인 완료                         ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "환경 사양:"
echo "  - Flutter: ${LOCAL_FLUTTER}"
echo "  - Dart:    ${LOCAL_DART}"
echo "  - OS:      ${LOCAL_OS}"
echo ""
echo "로컬 개발 환경과 CI/CD 환경이 일치합니다."
echo "안전하게 로컬 검증 후 푸시할 수 있습니다."
echo ""

cd "${PROJECT_ROOT}"
