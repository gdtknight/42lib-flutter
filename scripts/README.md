# Constitution Checker Script

Constitution v1.7.0 준수 여부를 자동으로 검증하는 도구입니다.

## 사용법

### Pull Request 검증
```bash
./scripts/check-constitution.sh --pr <PR_NUMBER>
```

### Issue 검증
```bash
./scripts/check-constitution.sh --issue <ISSUE_NUMBER>
```

## 검증 항목

### Pull Request
- **Principle III**: Issue 참조 ([#N] 형식)
- **Principle XI**: Labels, Body 내용, Branch 명명 규칙
- **Principle XIV**: Commit message에 Issue 참조

### Issue
- **Principle III**: Labels, Milestone 할당
- **Principle XIII**: 제목 길이 및 명확성

## 예시

```bash
# PR #8 검증 (실패 예시)
$ ./scripts/check-constitution.sh --pr 8
✗ No labels (must match Issue labels)
✗ Body too short (13 chars, need 50+)
FAILED (2 violation(s))

# PR #2 검증 (성공 예시)
$ ./scripts/check-constitution.sh --pr 2
✓ Constitution compliance: PASSED
```

## Exit Codes
- `0`: 검증 통과 (PASSED)
- `1`: 검증 실패 (FAILED) - 하나 이상의 위반 사항 존재

## CI/CD 통합

향후 GitHub Actions 워크플로우에 통합 가능:
```yaml
- name: Check Constitution Compliance
  run: ./scripts/check-constitution.sh --pr ${{ github.event.pull_request.number }}
```

## 참고
- Constitution 위치: `.specify/memory/constitution.md`
- Constitution 버전: v1.7.0
- 가이드: `docs/processes/constitution-compliance-guide.md`
