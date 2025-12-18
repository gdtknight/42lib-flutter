#!/bin/bash
#
# Local Verification Script for 42lib-flutter
# Constitution XVI: Mandatory Local Verification Before CI/CD
#
# Usage: ./scripts/local-verify.sh [--skip-build] [--platform=web|android|ios]
#
# This script runs all verification checks in Docker environment
# to ensure consistency with CI/CD pipeline.

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
echo -e "${BLUE}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Log file: ${LOG_FILE}"
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
print_step "Step 3/4: Running unit tests..."
if docker-compose exec -T flutter-dev flutter test; then
  print_success "All tests passed"
else
  print_error "Tests failed"
  exit 1
fi

# Step 4: Platform Build (optional)
if [ "$SKIP_BUILD" = false ]; then
  print_step "Step 4/4: Running ${PLATFORM} build..."
  
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
else
  print_warning "Step 4/4: Build verification skipped (--skip-build flag)"
fi

# Success summary
echo ""
echo -e "${GREEN}╔════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                 ✓ ALL CHECKS PASSED                        ║${NC}"
echo -e "${GREEN}╚════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo "Your code is ready to be pushed to CI/CD."
echo "Log saved to: ${LOG_FILE}"
echo ""

# Return to project root
cd "${PROJECT_ROOT}"
