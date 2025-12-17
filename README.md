# 42lib-flutter

Flutter 기반 라이브러리 프로젝트

## 프로젝트 개요

이 프로젝트는 Git 기반 협업 워크플로우와 GitHub 통합을 통해 관리되는 Flutter 크로스플랫폼 라이브러리 개발 프로젝트입니다.

**플랫폼 지원**: iOS, Android, Web  
**개발 환경**: Docker 기반 (로컬 머신 환경 보호)  
**호환성**: 각 플랫폼의 최신 버전-1 및 이전 3개 버전 지원

## 주요 원칙

프로젝트는 다음 핵심 원칙을 따릅니다:

1. **Git 기반 프로젝트 관리**: 모든 활동이 Git과 GitHub를 통해 추적됩니다
2. **브랜치 전략**: main/dev/feature/fix/release 구조를 엄격히 준수합니다
3. **이슈 기반 커밋**: 모든 커밋은 GitHub Issue 번호를 포함해야 합니다
4. **한글 문서화**: 모든 사용자 대상 문서는 한글로 작성됩니다
5. **구조화된 문서/로그**: 체계적인 디렉토리 구조로 정보를 관리합니다
6. **42 아이덴티티 디자인**: 42 브랜드 색상 체계를 반영한 일관된 디자인
7. **사용자 중심 UX**: 사용자 편의성과 단순한 UI를 우선시합니다
8. **Docker 기반 개발 환경**: 모든 개발 활동은 Docker 컨테이너 내에서 수행됩니다
9. **Flutter 크로스플랫폼 호환성**: iOS, Android, Web 3개 플랫폼 동시 지원 및 버전 호환성 유지
10. **헌법 준수 확인**: 모든 명령 완료 후 헌법 준수 여부를 검증합니다

자세한 내용은 [프로젝트 헌법](.specify/memory/constitution.md)을 참조하세요.

## 프로젝트 구조

```
42lib-flutter/
├── .github/           # GitHub Actions, 이슈/PR 템플릿
├── .specify/          # SpecKit 구성 및 템플릿
├── docs/              # 프로젝트 문서 (한글)
│   ├── architecture/  # 아키텍처 문서
│   ├── api/           # API 문서
│   ├── guides/        # 가이드 및 튜토리얼
│   ├── processes/     # 개발 프로세스
│   └── decisions/     # 의사결정 기록 (ADR)
├── logs/              # 실행 로그 (일자별 구분)
└── specs/             # 기능 명세 및 계획 (SpecKit)
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
# Docker 컨테이너 빌드 및 시작
docker-compose up -d

# 컨테이너 내부 접속
docker-compose exec flutter bash

# Flutter 의존성 설치
flutter pub get

# 플랫폼별 빌드 확인
flutter build ios    # iOS 빌드
flutter build apk    # Android 빌드
flutter build web    # Web 빌드
```

### 개발 워크플로우

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

- [프로젝트 헌법](.specify/memory/constitution.md) - 프로젝트 거버넌스 및 핵심 원칙
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
