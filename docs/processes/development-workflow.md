# 개발 워크플로우 가이드

**버전**: 1.0 (Constitution v1.8.0 기반)  
**최종 수정**: 2025-12-18

---

## ⚠️ 필수 규칙

### 작업 시작 전 확인사항 (위반 시 작업 중단)

```bash
# ✅ 1. Constitution 확인 (필수!)
cat .specify/memory/constitution.md | less

# ✅ 2. 15개 원칙 숙지 확인
# - 원칙 II: Branch Strategy
# - 원칙 XI: PR Review Gate  
# - 원칙 XV: Mandatory Pre-Check ⭐ NEW

# ✅ 3. 브랜치 전략 재확인
# main ← release/* ← dev ← feature/* (현재 위치)
```

---

## 📋 T00x 작업 워크플로우

### Step 1: Constitution 검토 (MANDATORY)

**질문**: "오늘 Constitution을 확인했는가?"

```bash
# Constitution 읽기
cat .specify/memory/constitution.md

# 핵심 원칙 재확인
# - dev 브랜치에 직접 커밋 금지
# - 모든 변경은 PR을 통해서만
# - T00x 작업은 개별 Issue 필수
```

---

### Step 2: GitHub Issue 생성

**규칙**: 모든 T00x 작업은 개별 Issue가 있어야 함

```bash
# Issue 생성
gh issue create \
  --title "[T033] 42 OAuth 로그인 구현" \
  --body "## 📋 작업 설명
T033: 학생이 42 OAuth를 통해 로그인

## 🎯 완료 조건
- [ ] 42 API OAuth 연동
- [ ] JWT 토큰 저장
- [ ] 자동 로그인 처리

## 🔗 관련 작업
- 선행: T015 (Prisma 마이그레이션)
- 후속: T034 (사용자 프로필)

## ✅ Constitution 준수
- [x] III. Issue 기반 커밋
- [x] XV. Issue 생성 후 작업 시작" \
  --label "priority:high,type:feature,tech:flutter" \
  --milestone "v0.1.0 - 기초 설정"

# 결과 확인
# Created issue #14
```

---

### Step 3: Feature 브랜치 생성 및 연결

**규칙**: Issue에 브랜치 연결 필수 (Development section)

```bash
# 브랜치 생성 및 Issue 연결 (자동)
gh issue develop 14 --name feature/14-oauth-login

# 또는 수동으로 브랜치 생성
git checkout dev
git pull origin dev
git checkout -b feature/14-oauth-login

# GitHub UI에서 Issue #14 → Development → Link branch
```

**확인**:
```bash
# 현재 브랜치 확인
git branch --show-current
# 출력: feature/14-oauth-login ✅

# 절대 dev나 main에 있으면 안됨!
```

---

### Step 4: 작업 수행

**규칙**: 모든 커밋은 Issue 번호 포함

```bash
# 파일 수정
code lib/auth/oauth_service.dart

# 커밋
git add lib/auth/oauth_service.dart
git commit -m "[#14] feat: 42 OAuth 로그인 서비스 구현

- OAuth2 클라이언트 설정
- 토큰 저장 로직
- 자동 로그인 처리

Constitution 준수:
- ✅ III. Issue 기반 커밋
- ✅ XV. Feature 브랜치에서 작업"

# 여러 커밋 가능 (모두 #14 참조)
git commit -m "[#14] test: OAuth 서비스 단위 테스트 추가"
git commit -m "[#14] docs: OAuth 설정 가이드 추가"
```

---

### Step 5: Push 및 PR 생성

**규칙**: PR 없이 dev에 직접 병합 금지

```bash
# Push
git push origin feature/14-oauth-login

# PR 생성
gh pr create \
  --title "[#14] 42 OAuth 로그인 구현" \
  --body "## 📋 변경 사항
42 OAuth 인증 시스템 구현 완료

## 🔗 관련 이슈
Closes #14

## 📝 주요 변경사항
- OAuth2 클라이언트 구현
- JWT 토큰 secure storage 저장
- 자동 로그인 처리

## 🧪 테스트
- [x] 단위 테스트 통과
- [x] 통합 테스트 (42 sandbox)
- [x] 수동 테스트 (iOS, Android)

## ✅ Constitution 체크리스트
- [x] III. Issue 기반 커밋
- [x] XI. PR Review Gate
- [x] XIII. 명확한 제목
- [x] XIV. Issue/PR/Commit 동기화
- [x] XV. Feature 브랜치 사용" \
  --label "priority:high,type:feature,tech:flutter" \
  --assignee @me

# PR 번호 확인
# Created pull request #15
```

---

### Step 6: ⏸️ PR 승인 대기 (MANDATORY)

**⚠️ 중요**: 승인 전까지 다음 작업 시작 금지!

```bash
# PR 상태 확인
gh pr view 15

# Constitution Checker 실행
./scripts/check-constitution.sh --pr 15

# 승인 대기...
# ⏸️ 이 시점에서 다른 작업을 시작하면 안됨!
```

**Self-Review 시**:
```bash
# 코드 재확인
gh pr view 15 --web

# Constitution 준수 확인
# - Labels 있는가?
# - Issue 참조 있는가?
# - Development section 연결되어 있는가?

# 승인
gh pr review 15 --approve --body "Constitution v1.8.0 준수 확인"
```

---

### Step 7: PR 병합

```bash
# 병합 (squash merge)
gh pr merge 15 --squash --delete-branch

# dev 브랜치로 돌아가기
git checkout dev
git pull origin dev

# 브랜치 정리 (이미 삭제되었을 것)
git branch -d feature/14-oauth-login
```

---

## 🚫 금지 사항

### ❌ 절대 하면 안되는 것

```bash
# ❌ dev 브랜치에 직접 커밋
git checkout dev
git commit -m "quick fix"  # FORBIDDEN!

# ❌ Issue 없이 작업 시작
git checkout -b feature/random-work  # No Issue!

# ❌ PR 승인 없이 병합
gh pr merge 15 --admin  # FORBIDDEN!

# ❌ Constitution 확인 없이 작업 시작
# "오늘 Constitution 확인했는가?" → No = STOP!
```

---

## 🔍 Constitution Checker 사용

### PR 검증

```bash
# PR 생성 후 자동 검증
./scripts/check-constitution.sh --pr 15

# 출력 예시:
# ✓ Issue reference in title
# ✓ Has 3 label(s)
# ✓ Branch: feature/14-oauth-login
# ✓ All 3 commit(s) reference issue
# Constitution compliance: PASSED
```

### Issue 검증

```bash
./scripts/check-constitution.sh --issue 14

# 출력 예시:
# ✓ Has 3 label(s)
# ✓ Milestone assigned
# Constitution compliance: PASSED
```

---

## 📊 워크플로우 체크리스트

### 작업 시작 전
- [ ] Constitution 검토 완료
- [ ] T00x 작업에 대한 Issue 생성
- [ ] Feature 브랜치 생성 및 연결
- [ ] 현재 브랜치가 feature/*인지 확인

### 작업 중
- [ ] 모든 커밋에 [#ISSUE_NO] 포함
- [ ] dev/main 브랜치에 직접 커밋하지 않음
- [ ] 정기적으로 push (백업)

### 작업 완료 후
- [ ] PR 생성
- [ ] Constitution Checker 실행
- [ ] PR 승인 대기 (다음 작업 시작 안함!)
- [ ] 승인 후 병합
- [ ] 브랜치 정리

---

## 🔄 여러 작업 병렬 진행

**가능**: 서로 다른 Issue/브랜치

```bash
# Issue #14: OAuth 로그인 (PR 대기 중) ⏸️
# → 다른 작업 시작 가능

# Issue #15 생성 및 새 브랜치
gh issue create --title "[T034] 사용자 프로필 조회"
gh issue develop 15 --name feature/15-user-profile
git checkout feature/15-user-profile

# 작업 진행
# ...

# 각각 별도 PR 생성
```

**불가능**: 같은 브랜치에서 여러 작업

```bash
# ❌ feature/14-oauth-login에서
#    T034도 함께 작업 → FORBIDDEN!

# ✅ T033 완료 후 새 브랜치에서 T034 시작
```

---

## ❓ FAQ

### Q: Constitution 매번 읽어야 하나요?
**A**: 예! 최소한 15개 원칙 제목은 확인해야 합니다.

### Q: 작은 수정도 PR이 필요한가요?
**A**: 예! dev/main에 직접 커밋은 절대 금지입니다.

### Q: PR을 스스로 승인해도 되나요?
**A**: 예, 하지만 Constitution 준수를 확인한 후에만 가능합니다.

### Q: T00x가 아닌 작업은?
**A**: T00x가 아니어도 모든 작업은 Issue가 있어야 하며, feature 브랜치를 사용해야 합니다.

### Q: 긴급 버그 수정은?
**A**: fix/* 브랜치 사용, 같은 워크플로우 적용됩니다.

---

## 📚 관련 문서

- [Constitution v1.8.0](.specify/memory/constitution.md)
- [Constitution 준수 가이드](constitution-compliance-guide.md)
- [Constitution Checker 사용법](../scripts/README.md)
- [Branch Strategy](constitution.md#ii-branch-strategy)
- [PR Review Gate](constitution.md#xi-pull-request-review-gate)

---

**마지막 업데이트**: 2025-12-18  
**Constitution 버전**: v1.8.0  
**준수 필수**: 원칙 XV (Mandatory Pre-Check)
