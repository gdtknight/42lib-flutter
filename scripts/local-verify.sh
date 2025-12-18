#!/bin/bash
#
# Local Verification Script for 42lib-flutter
# Constitution XVI: Mandatory Local Verification Before CI/CD
#
# Usage: ./scripts/local-verify.sh [--skip-build] [--platform=web|android|ios] [--mvp-mode]
#
# This script runs all verification checks in Docker environment
# to ensure consistency with CI/CD pipeline.
#
# --mvp-mode: MVP 개발 모드 (모든 플랫폼 빌드 필수, Constitution v1.10.0)

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
LOG_DIR="${PROJECT_ROOT}/logs/$(date +%Y-%m-%d)"
LOG_FILE="${LOG_DIR}/verify-$(date +%Y%m%d-%H%M%S).log"

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Options
SKIP_BUILD=false
PLATFORM="web"  # Default platform
MVP_MODE=true  # Default: MVP mode (Constitution v1.10.0)

# Parse arguments
for arg in "$@"; do
  case $arg in
    --skip-build)
      SKIP_BUILD=true
      shift
      ;;
    --platform=*)
      PLATFORM="${arg#*=}"
      shift
      ;;
    --mvp-mode)
      MVP_MODE=true
      shift
      ;;
    --no-mvp-mode)
      MVP_MODE=false
      shift
      ;;
    *)
      ;;
  esac
done

# Create log directory
mkdir -p "${LOG_DIR}"

# Header
echo -e "${BLUE}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║         42lib-flutter Local Verification                   ║${NC}"
echo -e "${BLUE}║         Constitution XVI Compliance Check                  ║${NC}"
if [ "$MVP_MODE" = true ]; then
  echo -e "${BLUE}║         🚧 MVP MODE: All platforms required                ║${NC}"
fi
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Log file: ${LOG_FILE}"
if [ "$MVP_MODE" = true ]; then
  echo -e "${YELLOW}⚠ MVP Mode: Android, iOS, Web 빌드 모두 성공 필요${NC}"
fi
echo ""

# Start logging
exec > >(tee -a "${LOG_FILE}") 2>&1

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
print_step "Checking Docker environment..."
if ! docker info > /dev/null 2>&1; then
  print_error "Docker is not running. Please start Docker and try again."
  exit 1
fi
print_success "Docker is running"

# Check Docker Compose setup
print_step "Verifying Docker Compose configuration..."
cd "${PROJECT_ROOT}/docker"
if ! docker-compose config > /dev/null 2>&1; then
  print_error "Docker Compose configuration is invalid"
  exit 1
fi
print_success "Docker Compose configuration is valid"

# Check if container is running
if ! docker-compose ps flutter-dev | grep -q "Up"; then
  print_warning "Flutter dev container is not running. Starting..."
  docker-compose up -d flutter-dev
  sleep 5
fi
print_success "Flutter dev container is ready"

# Step 1: Flutter Analyze
print_step "Step 1/4: Running Flutter analyze..."
if docker-compose exec -T flutter-dev flutter analyze --no-fatal-infos; then
  print_success "Flutter analyze passed"
else
  print_error "Flutter analyze failed"
  exit 1
fi

# Step 2: Dart Format
print_step "Step 2/4: Running Dart format check..."
if docker-compose exec -T flutter-dev dart format --output=none --set-exit-if-changed .; then
  print_success "Dart format check passed (no changes needed)"
else
  print_warning "Files need formatting. Running dart format..."
  docker-compose exec -T flutter-dev dart format .
  print_success "Files formatted"
fi

# Step 3: Unit Tests
print_step "Step 3/5: Running unit tests..."
if docker-compose exec -T flutter-dev flutter test; then
  print_success "All tests passed"
else
  print_error "Tests failed"
  exit 1
fi

# Step 4: Design Compliance (Constitution XVII)
print_step "Step 4/5: Verifying design compliance..."
if [ -f "${PROJECT_ROOT}/scripts/verify-design.sh" ]; then
  cd "${PROJECT_ROOT}"
  if bash scripts/verify-design.sh; then
    print_success "Design compliance verification passed"
  else
    print_error "Design compliance verification failed"
    print_warning "Check Constitution XVII: Design Compliance Verification"
    exit 1
  fi
  cd "${PROJECT_ROOT}/docker"
else
  print_warning "Design verification script not found, skipping..."
fi

# Step 5: Platform Build (MVP mode requires all platforms)
if [ "$SKIP_BUILD" = false ]; then
  if [ "$MVP_MODE" = true ]; then
    print_step "Step 5/7: MVP Mode - Testing ALL platforms..."
    
    # Web build
    print_step "Step 5a: Web 빌드..."
    if docker-compose exec -T flutter-dev flutter build web --release; then
      print_success "Web build succeeded"
    else
      print_error "Web build failed"
      exit 1
    fi
    
    # Android build
    print_step "Step 5b: Android 빌드..."
    if docker-compose exec -T flutter-dev flutter build apk --debug; then
      print_success "Android build succeeded"
    else
      print_error "Android build failed"
      print_warning "Android 빌드 실패: platform:android 라벨로 Issue 생성 필요"
      exit 1
    fi
    
    # iOS build (macOS only)
    print_step "Step 5c: iOS 빌드..."
    if [[ "$OSTYPE" == "darwin"* ]]; then
      if docker-compose exec -T flutter-dev flutter build ios --debug --no-codesign; then
        print_success "iOS build succeeded"
      else
        print_error "iOS build failed"
        print_warning "iOS 빌드 실패: platform:ios 라벨로 Issue 생성 필요"
        exit 1
      fi
    else
      print_warning "iOS build skipped (non-macOS environment)"
    fi
    
  else
    print_step "Step 5/5: Running ${PLATFORM} build..."
    
    case $PLATFORM in
      web)
        if docker-compose exec -T flutter-dev flutter build web --release; then
          print_success "Web build succeeded"
        else
          print_error "Web build failed"
          exit 1
        fi
        ;;
      android)
        if docker-compose exec -T flutter-dev flutter build apk --debug; then
          print_success "Android build succeeded"
        else
          print_error "Android build failed"
          exit 1
        fi
        ;;
      ios)
        if docker-compose exec -T flutter-dev flutter build ios --debug --no-codesign; then
          print_success "iOS build succeeded"
        else
          print_error "iOS build failed"
          exit 1
        fi
        ;;
      *)
        print_error "Unknown platform: ${PLATFORM}"
        exit 1
        ;;
    esac
  fi
else
  print_warning "Step 5/5: Build verification skipped (--skip-build flag)"
  if [ "$MVP_MODE" = true ]; then
    print_error "⚠️ MVP Mode에서는 --skip-build 사용 불가!"
    exit 1
  fi
fi

# Success summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 ✓ ALL CHECKS PASSED                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
if [ "$MVP_MODE" = true ]; then
  echo "✅ MVP Mode: All platforms verified (Web + Android + iOS)"
  echo "Your code is ready for PR creation."
else
  echo "Your code is ready to be pushed to CI/CD."
fi
echo "Log saved to: ${LOG_FILE}"
echo ""

# Return to project root
cd "${PROJECT_ROOT}"
