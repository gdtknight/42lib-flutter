# Constitution 준수 가이드

**버전**: 1.0.0  
**Constitution 버전**: v1.7.0  
**작성일**: 2025-12-17

---

## 📖 개요

이 문서는 42lib-flutter 프로젝트의 Constitution v1.7.0 (14개 원칙)을 실무에서 준수하기 위한 실용적인 가이드입니다.

---

## 🎯 Issue 생성 시 체크리스트

### 1. 제목 작성 (원칙 XIII)
```
[Type] 구체적이고 명확한 설명

✅ 좋은 예:
- [Bug] 로그인 시 세션 만료 오류
- [Feature] 사용자 프로필 편집 기능 추가
- [T001] 프로젝트 디렉토리 구조 생성 및 초기화

❌ 나쁜 예:
- 버그 수정
- 업데이트
- 작업
```

### 2. Labels 할당 (원칙 III)
**구체적인 계층 구조** 사용 (type:subtype)

```bash
# 필수: 최소 2개 이상
- priority: critical/high/medium/low
- type: setup/feature/bug/refactor/docs

# 권장: 기술 스택
- tech: flutter/nodejs/docker/postgresql

# 예시
gh issue create --label "priority:critical,type:setup,tech:docker"
```

### 3. Milestone 할당 (원칙 III)
```bash
# 릴리스 계획에 따라 할당
gh issue create --milestone "v0.1.0 - 기초 설정"
```

### 4. Development Section 연결 (원칙 III) ⭐ **중요**
```bash
# Issue 생성 후 branch 생성 및 연결
gh issue create --title "[Bug] 로그인 오류" --body "..."

# Branch 생성 및 자동 연결
gh issue develop 123 --name feature/123-login-fix

# 또는 GitHub UI에서:
# Issue 페이지 > Development > Create a branch > Link branch
```

### 5. 본문 작성 (원칙 XIII)
```markdown
## 📋 작업 설명
명확한 작업 내용 설명

## 🎯 목표
달성해야 할 목표

## ✅ 완료 조건
- [ ] 조건 1
- [ ] 조건 2

## 🔗 관련 작업
- 선행: #123
- 후속: #124
```

---

## 🎯 Pull Request 생성 시 체크리스트

### 1. 제목 작성 (원칙 XIV)
```
[#ISSUE_NO] Issue 제목 확장 + 구현 상세

✅ 좋은 예:
- [#1] 도서 관리 시스템 구현 계획 수립, Docker 개발 환경 구축
- [#6][#7] Docker 개발 환경 구축 (Flutter + Backend)
- [#123] 사용자 인증 구현 - JWT 토큰 기반 로그인/로그아웃

❌ 나쁜 예:
- 버그 수정
- Update (#123)
- 작업 완료
```

### 2. Labels 할당 (원칙 XI) ⭐ **필수**
**Issue labels를 PR에 반영**

```bash
# Issue #123의 labels 확인
gh issue view 123 --json labels

# PR 생성 시 동일한 labels 적용
gh pr create --label "priority:critical,type:setup,tech:docker"

# 또는 GitHub UI에서:
# PR 생성 후 우측 Labels 섹션에서 선택
```

### 3. Development Section 연결 (원칙 XI) ⭐ **필수**
```bash
# PR 생성 시 자동으로 source branch 연결됨
# GitHub UI에서 확인:
# PR 페이지 > Development > Linked issues

# CLI로 확인:
gh pr view 8 --json headRefName
# 결과: "headRefName": "feature/docker-setup"
```

### 4. 본문 작성 (원칙 XIII, XIV)
```markdown
## 📋 변경 사항 설명
상세한 변경사항 설명

## 🔗 관련 이슈
Closes #123, #124

## 📝 주요 변경사항
- 변경 1: 상세 설명
- 변경 2: 상세 설명

## ✅ Constitution 준수 체크리스트
- [x] I. Git 기반 프로젝트 관리
- [x] II. Branch Strategy
- [x] III. Issue 기반 커밋 + 메타데이터
... (14개 원칙)

## 🧪 테스트 증거
- 테스트 결과 또는 스크린샷

## 📊 파일 변경 통계
- 커밋 수: N개
- 생성된 파일: N개
```

---

## 🎯 Commit 작성 시 체크리스트

### 1. 커밋 메시지 형식 (원칙 III, XIV)
```bash
# 기본 형식
[#ISSUE_NO] type: 간단한 설명

# 상세 형식 (권장)
[#ISSUE_NO] type: 간단한 설명

상세한 변경사항:
- 변경 1
- 변경 2

헌법 원칙 N 준수: 원칙 내용
```

### 2. 예시
```bash
# 단일 Issue
git commit -m "[#123] feat: JWT 인증 미들웨어 추가"

# 다중 Issue
git commit -m "[#6][#7] feat: Docker 개발 환경 구축 (Flutter + Backend)

Issue #6: Flutter 개발용 Dockerfile 생성
Issue #7: Backend API용 Dockerfile 생성

변경사항:
- Dockerfile.flutter 생성 (Flutter 3.16.0)
- backend/Dockerfile 생성 (Node.js 20)
- docker-compose.yml 업데이트 (3개 서비스)

헌법 원칙 VIII 준수: Docker 기반 개발 환경"
```

---

## 🚀 워크플로우 예시

### 시나리오: 새로운 기능 구현

#### Step 1: Issue 생성
```bash
gh issue create \
  --title "[Feature] 사용자 프로필 편집 기능 추가" \
  --body "사용자가 자신의 프로필을 편집할 수 있는 기능을 구현합니다." \
  --label "priority:high,type:feature,tech:flutter" \
  --milestone "v0.2.0"

# 결과: Issue #150 생성됨
```

#### Step 2: Branch 생성 및 Development 연결
```bash
# Issue에 branch 연결 (자동으로 Development section 업데이트)
gh issue develop 150 --name feature/150-user-profile-edit

# Branch로 전환
git checkout feature/150-user-profile-edit
```

#### Step 3: 작업 및 커밋
```bash
# 작업 수행
# ...

# 커밋 (Issue 번호 포함)
git add .
git commit -m "[#150] feat: 사용자 프로필 편집 UI 구현"
git commit -m "[#150] feat: 프로필 업데이트 API 연동"
git commit -m "[#150] test: 프로필 편집 기능 테스트 추가"

# Push
git push origin feature/150-user-profile-edit
```

#### Step 4: Pull Request 생성
```bash
gh pr create \
  --title "[#150] 사용자 프로필 편집 기능 추가 - UI 구현 및 API 연동" \
  --body "$(cat <<EOF
## 📋 변경 사항 설명
사용자 프로필 편집 기능을 구현했습니다.

## 🔗 관련 이슈
Closes #150

## 📝 주요 변경사항
- 프로필 편집 UI 구현 (Flutter)
- 프로필 업데이트 API 연동 (dio)
- 유효성 검증 추가
- 테스트 코드 작성

## ✅ Constitution 준수 체크리스트
- [x] III. Issue 기반 커밋 + 메타데이터
- [x] XI. Pull Request Review Gate
- [x] XIII. 명확한 Issue/PR 제목
- [x] XIV. Issue/PR/커밋 동기화

## 🧪 테스트 증거
- Flutter 테스트: PASSED
- iOS 시뮬레이터: 정상 동작
- Android 에뮬레이터: 정상 동작
EOF
)" \
  --label "priority:high,type:feature,tech:flutter" \
  --assignee @me

# 결과: PR #45 생성됨
```

#### Step 5: Code Review 대기 (원칙 XI)
```
⏸️ 구현 작업 중단
✅ PR 승인 대기
📧 리뷰어에게 알림
```

#### Step 6: PR 승인 후 병합
```bash
# 리뷰 승인 후
gh pr merge 45 --squash --delete-branch

# dev 브랜치로 병합 완료
# Issue #150 자동으로 CLOSED
```

---

## ⚠️ 흔한 실수와 해결 방법

### 실수 1: PR에 Labels 누락
```bash
# 문제: PR #8처럼 labels가 비어있음
gh pr view 8 --json labels
# 결과: "labels": []

# 해결:
gh pr edit 8 --add-label "tech:docker,type:setup,priority:critical"
```

### 실수 2: Development Section 미연결
```bash
# 문제: Issue에 branch가 연결되지 않음
gh issue view 9 --json projectItems
# 결과: "projectItems": []

# 해결: Issue에 branch 연결
gh issue develop 9 --name feature/9-docker-validation
```

### 실수 3: PR 본문이 너무 간단함
```markdown
# 문제:
Closes #6, #7

# 해결:
## 📋 변경 사항 설명
Docker 개발 환경을 구축했습니다.

## 🔗 관련 이슈
Closes #6, #7

## 📝 주요 변경사항
- Dockerfile.flutter 생성 (Flutter 3.16.0)
- backend/Dockerfile 생성 (Node.js 20)
- docker-compose.yml 업데이트 (3개 서비스)

## ✅ Constitution 준수
- [x] VIII. Docker 기반 개발 환경
```

### 실수 4: Issue/PR 제목이 모호함
```
# 문제:
- "버그 수정"
- "업데이트"
- "작업 완료"

# 해결:
- "[Bug] 로그인 시 세션 만료 오류 수정"
- "[Feature] 사용자 프로필 편집 UI 구현"
- "[T001] 프로젝트 디렉토리 구조 생성 및 초기화 완료"
```

---

## 🔍 Constitution 준수 검증

### 자동 검증 스크립트 (예정)
```bash
# Constitution 준수 여부 자동 검증
./scripts/check-constitution.sh --pr 45

# 결과:
# ✅ Labels: OK
# ✅ Development Section: OK
# ✅ Issue Reference: OK
# ✅ Commit Format: OK
# ❌ PR Body: Too short (minimum 200 characters)
```

### 수동 검증 체크리스트
```markdown
## Issue 검증
- [ ] 구체적 labels (type:subtype) 할당
- [ ] Milestone 할당
- [ ] Development section에 branch 연결
- [ ] 명확한 한글 제목 및 본문

## PR 검증
- [ ] Issue 번호 참조 ([#N])
- [ ] Issue labels 반영
- [ ] Development section에 source branch 연결
- [ ] 상세한 본문 (변경사항, 테스트 증거)
- [ ] Constitution 체크리스트 포함

## Commit 검증
- [ ] Issue 번호 포함 ([#N])
- [ ] 명확한 type: 설명
- [ ] Commit message와 Issue 내용 일관성
```

---

## 📚 참고 자료

### Constitution 문서
- 위치: `.specify/memory/constitution.md`
- 버전: v1.7.0
- 최종 수정: 2025-12-17

### 주요 원칙 Quick Reference

| 원칙 | 제목 | 핵심 |
|------|------|------|
| III | Issue-Driven Commits & Metadata | Labels, Milestone, Branch 연결 |
| XI | Pull Request Review Gate | PR Labels, Development section, 승인 필수 |
| XIII | Descriptive Titles | 명확하고 구체적인 제목/본문 |
| XIV | Issue/PR/Commit Sync | 일관된 참조 및 동기화 |

---

## 🔄 이 가이드 업데이트

- Constitution 개정 시 이 가이드도 함께 업데이트
- 새로운 사례 발견 시 "흔한 실수" 섹션 추가
- 자동화 도구 도입 시 "자동 검증" 섹션 업데이트

---

**마지막 업데이트**: 2025-12-17  
**다음 검토일**: 2026-01-17  
**문의**: GitHub Issues에 `label:docs:constitution` 태그로 질문
