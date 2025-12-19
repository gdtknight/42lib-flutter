# 42lib-flutter Web 애플리케이션 테스트 가이드

## 🚀 실행 방법

### 1. Web 빌드 (이미 완료됨)

```bash
cd docker
docker-compose exec flutter-dev flutter build web --release
```

### 2. Web 서버 실행

```bash
cd build/web
python3 -m http.server 8080
```

### 3. 브라우저 접속

```
http://localhost:8080
```

## 📋 현재 구현된 기능 (User Story 1)

### ✅ 구현 완료

**1. 도서 목록 화면 (BookListScreen)**

- 위치: `lib/features/books/presentation/screens/book_list_screen.dart`
- 기능:
  - 도서 목록 표시
  - Grid/List 레이아웃 전환
  - 검색 바 표시

**2. 도서 카드 위젯 (BookCard)**

- 위치: `lib/features/books/presentation/widgets/book_card.dart`
- 기능:
  - 도서 정보 표시 (제목, 저자, ISBN)
  - 표지 이미지 표시
  - 대출 가능 여부 배지
  - 카테고리 배지
  - 탭 동작 지원

**3. 검색 바 위젯 (BookSearchBar)**

- 위치: `lib/features/books/presentation/widgets/book_search_bar.dart`
- 기능:
  - 텍스트 입력
  - Debounce 처리 (500ms)
  - 클리어 버튼
  - 비활성화 상태 지원

**4. Book 모델**

- 위치: `lib/features/books/data/models/book.dart`
- 기능:
  - JSON 직렬화/역직렬화
  - 유효성 검증
  - 대출 가능 여부 계산

**5. 라우팅 설정**

- 위치: `lib/core/routes/app_router.dart`
- 기능:
  - go_router 기반 라우팅
  - `/` → BookListScreen
  - 확장 가능한 구조

## 🧪 테스트 시나리오

### 시나리오 1: 초기 화면 확인

1. 브라우저에서 <http://localhost:8080> 접속
2. **예상 결과**:
   - 도서 목록 화면 표시
   - 검색 바 상단에 위치
   - Grid 레이아웃으로 도서 카드 표시

### 시나리오 2: 검색 기능 테스트

1. 검색 바 클릭
2. 텍스트 입력 (예: "Flutter")
3. **예상 결과**:
   - 텍스트 입력 가능
   - 클리어 버튼 표시
   - Debounce 적용 (0.5초 후 콜백)

### 시나리오 3: 도서 카드 확인

1. 도서 카드 hover
2. 도서 카드 클릭
3. **예상 결과**:
   - Hover 시 elevation 변화
   - 클릭 시 콜백 동작 (현재는 로그)
   - 도서 정보 정확히 표시

### 시나리오 4: 반응형 레이아웃

1. 브라우저 창 크기 조절
2. **예상 결과**:
   - 큰 화면: Grid 4열
   - 중간 화면: Grid 2열
   - 작은 화면: List 1열

## 🔍 현재 제약사항 (알려진 이슈)

### 데이터 소스

- ❌ **백엔드 연동 없음**: 현재 하드코딩된 샘플 데이터
- ⏳ **42 API 통합 필요**: User Story 4에서 구현 예정

### 상세 화면

- ❌ **도서 상세 화면 없음**: User Story 2에서 구현 예정
- ⏳ **라우팅만 준비됨**: `/books/:id` 경로 정의됨

### 상태 관리

- ❌ **Riverpod 미적용**: 현재 StatefulWidget 사용
- ⏳ **User Story 3에서 적용 예정**

## 📊 테스트 커버리지

### Unit Tests (9개)

- ✅ Book 모델 생성
- ✅ JSON 직렬화/역직렬화
- ✅ 유효성 검증 (제목, 저자, ISBN, 수량)
- ✅ 대출 가능 여부 계산

### Widget Tests (14개)

- ✅ BookCard 렌더링
- ✅ BookCard 상호작용
- ✅ BookSearchBar 렌더링
- ✅ BookSearchBar 입력 처리
- ✅ BookSearchBar Debounce

**총 23/23 테스트 통과** ✅

## 🎯 다음 단계 (User Story 2)

1. 도서 상세 화면 구현
2. 라우팅 연결
3. 뒤로가기 동작
4. 도서 정보 상세 표시

## 📝 참고 사항

### 개발 모드 실행 (Hot Reload)

```bash
# Docker 컨테이너 내부에서
cd /app
flutter run -d web-server --web-port=8080 --web-hostname=0.0.0.0
```

### 빌드 재실행

```bash
cd docker
docker-compose exec flutter-dev flutter build web --release
```

### 로그 확인

브라우저 개발자 도구 (F12) → Console 탭에서 확인

## 🎉 완료 상태

**User Story 1: ✅ 완료**

- AC-001: ✅ 도서 목록 표시
- AC-002: ✅ 검색 바 표시
- AC-003: ✅ 도서 카드 클릭 가능
- AC-004: ✅ Grid/List 레이아웃

**CI/CD: ✅ 통과**

- 코드 분석: 29s
- 테스트: 46s (23/23)
- Web 빌드: 58s

**Constitution: v1.10.0 (Production-ready)** 🚀
