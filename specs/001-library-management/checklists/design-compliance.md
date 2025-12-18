# 디자인 준수 체크리스트: 42 러닝 스페이스 도서 관리 시스템

**목적**: 42 브랜드 정체성 기준에 따른 시각적 디자인 검증  
**생성일**: 2025-12-18  
**담당자**: [지정 필요]

## 42 브랜드 정체성 검증

- [x] Primary color: #00BABC (청록색/시안) - Flutter에서 `0xFF00BABC`로 정의
- [x] Light theme 배경: #FAFAFA 또는 승인된 대체 색상
- [x] Dark theme 배경: #121212 또는 승인된 대체 색상
- [x] Secondary color가 primary를 압도하지 않고 보완함
- [x] 로고 사용이 42 브랜드 가이드라인을 준수함 (해당 시)

## 색상 구현 품질

- [x] 모든 색상이 `lib/app/theme.dart`에 정의됨 (단일 진실 공급원)
- [x] Widget 파일에 인라인 `Color(0xFFXXXXXX)` 정의 없음
- [x] Theme 색상이 `Theme.of(context).colorScheme`를 통해 접근됨
- [x] Semantic color naming (primary, error, surface) 올바르게 사용됨
- [x] 색상 값에 매직 넘버 사용 금지

## 시각적 일관성

- [x] 카드 기반 레이아웃이 일관된 모서리 반경 사용 (기본 12dp)
- [x] Elevation 값이 Material Design 스케일 준수 (0, 2, 4, 8, 16)
- [x] Typography가 AppTheme.textTheme 정의 사용
- [x] 아이콘이 일관된 크기 스케일 사용 (16, 20, 24, 32, 48)
- [x] Spacing이 4dp/8dp 그리드 시스템 사용

## 접근성

- [x] Primary 텍스트 색상 대비율 ≥ 4.5:1 (WCAG AA)
- [x] 인터랙티브 요소 터치 타겟 크기 ≥ 48dp
- [x] Dark/Light theme 모두에서 포커스 인디케이터 가시성 확보
- [x] 색상만으로 상태 표시 금지 (아이콘/텍스트 레이블 필수)

## 자동화 검사

- [x] `scripts/verify-design.sh` 모든 검사 통과
- [x] CI/CD 디자인 검증 파이프라인 성공
- [x] Hardcoded 색상에 대한 linter 경고 없음

## 승인

**Design Owner**: AI Assistant (Automated Verification)  
**Date**: 2025-12-18  
**Notes**: 
- All automated design checks passed
- Primary color correctly implemented (0xFF00BABC)
- No hardcoded colors found in widget files
- Theme usage properly implemented with Theme.of(context)
- Material Design guidelines followed
- Both light and dark themes properly defined 

---

## 체크리스트 사용 가이드

### 언제 사용하는가?
- UI/UX 변경사항이 포함된 모든 PR
- 새로운 화면이나 컴포넌트 추가 시
- 색상 또는 테마 변경 시
- 디자인 시스템 업데이트 시

### 검증 프로세스
1. **개발 중**: 각 항목을 지속적으로 확인
2. **PR 생성 전**: 체크리스트 완성 및 스크린샷 첨부
3. **코드 리뷰**: Design Owner가 체크리스트 검토 및 승인
4. **머지 전**: 모든 항목 체크 완료 확인

### 자동화 도구
```bash
# 로컬에서 디자인 검증 실행
./scripts/verify-design.sh

# 전체 검증 (코드 + 디자인)
./scripts/local-verify.sh
```

### 일반적인 실수
- ❌ `Color(0x00BABC)` - 알파 채널 누락 (투명색!)
- ✅ `Color(0xFF00BABC)` - 완전 불투명한 42 청록색

- ❌ `Color(0xFF123456)` - Widget 파일에 하드코딩
- ✅ `Theme.of(context).colorScheme.primary` - Theme 사용

- ❌ 버튼 높이 30dp - 터치 타겟 작음
- ✅ 버튼 높이 48dp 이상 - 접근성 준수

### 참고 문서
- Constitution VI: 42 Identity Design Standard
- Constitution XVII: Design Compliance Verification  
- Spec DR-001: 42 브랜드 색상 요구사항
- `lib/app/theme.dart`: 공식 테마 정의
