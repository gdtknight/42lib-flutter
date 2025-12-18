# 42lib-flutter

42 러닝 스페이스 도서 관리 시스템

## 프로젝트 개요

42 러닝 스페이스 사용자를 위한 도서 대출 및 관리 시스템입니다. 학생들은 42 OAuth로 로그인하여 도서를 검색하고 대출 신청할 수 있으며, 관리자는 웹 대시보드에서 도서 및 대출을 관리합니다.

**주요 기능**:
- 📚 도서 검색 및 대출 신청 (학생 앱)
- 🔐 42 OAuth 인증
- ⏰ 예약 대기열 및 알림
- 📊 관리자 대시보드 (웹)
- 💡 도서 추천 시스템

**플랫폼 지원**: iOS, Android, Web  
**개발 환경**: Docker 기반 (로컬 머신 환경 보호)  
**호환성**: iOS 14-17, Android 11-14, 모던 웹 브라우저

## 주요 원칙

프로젝트는 다음 핵심 원칙을 따릅니다:

1. **Git 기반 프로젝트 관리**: 모든 활동이 Git과 GitHub를 통해 추적됩니다
2. **브랜치 전략**: main/dev/feature/fix/release 구조를 엄격히 준수합니다
3. **이슈 기반 커밋 & 메타데이터**: 모든 커밋은 GitHub Issue 번호를 포함하며, Issue는 Labels, Projects, Milestones가 설정되어야 합니다
4. **한글 문서화**: 모든 사용자 대상 문서는 한글로 작성됩니다
5. **구조화된 문서/로그**: 체계적인 디렉토리 구조로 정보를 관리합니다
6. **42 아이덴티티 디자인**: 42 브랜드 색상 체계를 반영한 일관된 디자인
7. **사용자 중심 UX**: 사용자 편의성과 단순한 UI를 우선시합니다
8. **Docker 기반 개발 환경**: 모든 개발 활동은 Docker 컨테이너 내에서 수행됩니다
9. **Flutter 크로스플랫폼 호환성**: iOS, Android, Web 3개 플랫폼 동시 지원 및 버전 호환성 유지
10. **헌법 준수 확인**: 모든 명령 완료 후 헌법 준수 여부를 검증합니다
11. **Pull Request 리뷰 게이트**: dev 통합 PR은 반드시 승인 확인 후 다음 단계 진행
12. **지속적 통합 & 즉시 공유**: 오류 검증 프로세스를 갖추며, 코드에 영향 없는 변경사항은 즉시 GitHub에 푸시합니다
13. **명확한 Issue & PR 제목**: GitHub Issue와 Pull Request 제목은 전체 내용을 포괄적으로 나타내야 합니다
14. **Issue/PR/커밋 메시지 동기화**: Issue 제목, PR 제목, 커밋 메시지가 개발 생명주기 전반에 걸쳐 일관성과 추적가능성을 유지해야 합니다
15. **필수 헌법 사전 확인 및 작업 워크플로우**: 모든 작업 전 헌법 검토 필수, T00x 작업은 개별 Issue 생성 및 feature 브랜치 연결 필수
16. **필수 로컬 검증 (CI/CD 전)**: MVP 완성 전 모든 플랫폼 빌드 검증 필수, MVP 완성 후 최소 1개 플랫폼으로 완화

자세한 내용은 [프로젝트 헌법](.specify/memory/constitution.md)을 참조하세요.

## 프로젝트 구조

```
42lib-flutter/
├── .github/              # GitHub Actions, 이슈/PR 템플릿
├── .specify/             # SpecKit 구성 및 템플릿
├── backend/              # Node.js/Express API 서버
│   ├── prisma/           # Prisma 스키마 및 마이그레이션
│   ├── src/              # 백엔드 소스 코드
│   └── tests/            # 백엔드 테스트
├── docker/               # Docker 관련 파일
│   ├── Dockerfile        # Backend Dockerfile
│   ├── Dockerfile.flutter # Flutter Dockerfile
│   └── docker-compose.yml # Docker Compose 구성
├── docs/                 # 프로젝트 문서 (한글)
│   ├── architecture/     # 아키텍처 문서
│   ├── api/              # API 문서
│   ├── guides/           # 가이드 및 튜토리얼
│   ├── processes/        # 개발 프로세스
│   │   ├── constitution-compliance-guide.md
│   │   └── constitution-compliance-report-2025-12-17.md
│   └── decisions/        # 의사결정 기록 (ADR)
├── lib/                  # Flutter 앱 소스 코드
├── logs/                 # 실행 로그 (일자별 구분)
├── scripts/              # 유틸리티 스크립트
│   └── check-constitution.sh  # Constitution 자동 검증
├── specs/                # 기능 명세 및 계획 (SpecKit)
│   └── 001-library-management/  # 도서 관리 시스템 명세
└── test/                 # Flutter 테스트
```

## 시작하기

### 필수 요구사항

- Docker 및 Docker Compose 설치
- Git 설치
- GitHub 계정 및 저장소 접근 권한

### 저장소 클론

```bash
git clone git@github.com:gdtknight/42lib-flutter.git
cd 42lib-flutter
```

### Docker 개발 환경 설정

```bash
# 1. Docker 컨테이너 빌드 및 시작
cd docker
docker-compose up -d

# 2. 서비스 확인
docker-compose ps
# flutter-dev (포트 8080), backend-api (포트 3000), postgres-db (포트 5432)

# 3. Flutter 컨테이너 접속
docker-compose exec flutter-dev bash

# 4. Flutter 의존성 설치
flutter pub get

# 5. Backend 컨테이너 접속 (별도 터미널)
docker-compose exec backend-api sh

# 6. Prisma 마이그레이션 실행
npm run migrate

# 7. 개발 서버 시작
# Backend: npm run dev (자동 시작됨)
# Flutter Web: flutter run -d web-server --web-port=8080

# 8. 접속 확인
# Flutter Web: http://localhost:8080
# Backend API: http://localhost:3000
# PostgreSQL: localhost:5432
```

### 개발 워크플로우

**⚠️ 작업 시작 전 필수 확인사항**:
1. Constitution 검토 (`.specify/memory/constitution.md`)
2. T00x 작업은 개별 GitHub Issue 생성
3. Feature 브랜치 생성 및 Issue 연결

```bash
# 1. 헌법 확인 (필수!)
cat .specify/memory/constitution.md

# 2. Issue 생성
gh issue create --title "[T033] 작업 설명" \
  --body "..." --label "type:feature" --milestone "v0.1.0"
# 결과: Issue #14 생성됨

# 3. Feature 브랜치 생성 및 연결
gh issue develop 14 --name feature/14-short-description
git checkout feature/14-short-description

# 4. 작업 수행 및 커밋
git add .
git commit -m "[#14] feat: 작업 내용"

# 5. PR 생성
git push origin feature/14-short-description
gh pr create --title "[#14] 작업 요약" \
  --body "Closes #14" --label "type:feature"

# 6. ⏸️ PR 승인 대기 (필수!)
# 7. 승인 후 dev로 병합
```

자세한 워크플로우는 [개발 워크플로우 가이드](docs/processes/development-workflow.md)를 참조하세요.

---

### 개발 워크플로우 (기존)

1. **이슈 생성**: GitHub에서 작업 이슈 생성 (한글)
2. **브랜치 생성**: `dev`에서 `feature/<이슈번호>-<설명>` 브랜치 생성
3. **개발 진행**: 커밋 메시지에 이슈 번호 포함 (`[#123] 기능 구현`)
4. **PR 생성**: `dev`로 PR 생성 (한글 설명)
5. **리뷰 및 병합**: CI/CD 통과 후 리뷰 승인 후 병합

자세한 워크플로우는 [프로젝트 헌법](.specify/memory/constitution.md)을 참조하세요.

## CI/CD

GitHub Actions를 통한 자동화:
- 자동 테스트 실행 (모든 플랫폼)
- 빌드 검증 (iOS, Android, Web)
- 코드 품질 검사 (linting, formatting)
- 플랫폼 버전 호환성 검증
- Docker 기반 빌드 파이프라인
- 릴리스 배포 자동화

## 문서

### 프로젝트 관리
- [프로젝트 헌법](.specify/memory/constitution.md) - 프로젝트 거버넌스 및 핵심 원칙 (v1.10.0)
- [Constitution 준수 가이드](docs/processes/constitution-compliance-guide.md) - 실무 체크리스트
- [Constitution 준수 보고서](docs/processes/constitution-compliance-report-2025-12-17.md) - 분석 결과

### 기술 문서
- [기능 명세](specs/001-library-management/spec.md) - 도서 관리 시스템 요구사항
- [데이터 모델](specs/001-library-management/data-model.md) - 8개 엔티티 정의
- [API 명세](specs/001-library-management/contracts/openapi.yaml) - REST API 문서
- [구현 계획](specs/001-library-management/plan.md) - 기술 스택 및 아키텍처
- [작업 목록](specs/001-library-management/tasks.md) - 268개 구현 작업

### 개발 가이드
- [빠른 시작](specs/001-library-management/quickstart.md) - 개발자 온보딩
- [기술 조사](specs/001-library-management/research.md) - 기술 스택 결정 근거
- [문서 디렉토리](docs/) - 모든 프로젝트 문서 (한글)
- [GitHub Wiki](../../wiki) - 문서 검색 및 탐색

## 기여 방법

1. 이슈 생성 (한글)
2. 브랜치 전략 준수
3. 커밋 메시지에 이슈 번호 포함
4. Pull Request 생성 (한글)
5. 코드 리뷰 및 CI/CD 통과

## 라이선스

[라이선스 정보 추가 예정]

## 연락처

[연락처 정보 추가 예정]

## 개발 워크플로우

### 로컬 검증 (필수)

**모든 코드 변경 후 CI/CD에 푸시하기 전에 반드시 로컬 검증을 수행하세요** (Constitution XVI):

```bash
# MVP 완성 전 (v0.1.0 이전): 모든 플랫폼 빌드 검증
./scripts/local-verify.sh --mvp-mode

# MVP 완성 후 (v0.1.0 이후): 최소 1개 플랫폼 빌드 검증
./scripts/local-verify.sh

# 빌드 제외 (빠른 검증)
./scripts/local-verify.sh --skip-build

# 특정 플랫폼 빌드
./scripts/local-verify.sh --platform=android
./scripts/local-verify.sh --platform=ios
./scripts/local-verify.sh --platform=web
```

검증 항목:
- ✅ Flutter analyze (info는 경고만)
- ✅ Dart format (자동 포맷 적용)
- ✅ Unit tests (모든 테스트 통과)
- ✅ Platform build
  - **MVP 전**: Android, iOS, Web 모두 필수
  - **MVP 후**: 최소 1개 플랫폼 (기본 web)

CI/CD 전략 (Constitution XVI):
- **MVP 완성 전 (v0.1.0 이전)**: CI/CD는 Web 빌드만 수행 (빠른 피드백)
  - Android/iOS는 로컬 검증 필수 (각각 ~4분, ~2.5분 소요)
  - 목적: 개발 속도 향상, 피드백 주기 최소화
- **MVP 완성 후 (v0.1.0 이후)**: CI/CD에서 전체 플랫폼 빌드 활성화

검증 결과는 `logs/YYYY-MM-DD/verify-YYYYMMDD-HHmmss.log`에 저장됩니다.


## 🌐 Web 애플리케이션 실행

### 빠른 시작

1. **Web 빌드**
   ```bash
   cd docker
   docker-compose exec flutter-dev flutter build web --release
   ```

2. **로컬 서버 실행**
   ```bash
   cd build/web
   python3 -m http.server 8080
   ```

3. **브라우저 접속**
   ```
   http://localhost:8080
   ```

### 현재 구현된 기능 (User Story 1)

- ✅ 도서 목록 화면 (Grid/List 레이아웃)
- ✅ 도서 검색 바 (Debounce 지원)
- ✅ 도서 카드 (표지, 정보, 대출 가능 여부)
- ✅ 반응형 레이아웃
- ✅ 23개 자동화 테스트 (100% 통과)

### 테스트 시나리오

**시나리오 1: 도서 목록 확인**
- 브라우저에서 초기 화면 로드
- Grid 레이아웃으로 도서 카드 표시 확인
- 도서 정보 (제목, 저자, 대출 가능 여부) 표시 확인

**시나리오 2: 검색 기능**
- 검색 바에 텍스트 입력
- Debounce 동작 확인 (0.5초 후 반영)
- 클리어 버튼으로 입력 초기화

**시나리오 3: 반응형 테스트**
- 브라우저 창 크기 조절
- 큰 화면: 4열 Grid
- 중간 화면: 2열 Grid  
- 작은 화면: 1열 List

### 알려진 제약사항

- **데이터**: 하드코딩된 샘플 데이터 (42 API 연동은 User Story 4)
- **상세 화면**: 미구현 (User Story 2)
- **상태 관리**: Riverpod 미적용 (User Story 3)

자세한 내용은 `docs/web-test-guide.md` 참조

