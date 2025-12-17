# API 계약 문서

이 디렉토리는 42 도서 관리 시스템의 API 계약 명세를 포함합니다.

## 파일

- `openapi.yaml`: OpenAPI 3.0 형식의 전체 REST API 명세서

## OpenAPI 명세서 사용법

### Swagger UI로 보기

백엔드 서버 실행 후 http://localhost:3000/api-docs 접속

### 온라인 에디터로 보기

1. https://editor.swagger.io/ 방문
2. `openapi.yaml` 내용 복사하여 붙여넣기
3. 대화형 문서 확인

### 클라이언트 코드 생성

```bash
# Flutter/Dart 클라이언트 생성
openapi-generator generate -i openapi.yaml -g dart -o lib/api_client

# TypeScript 클라이언트 생성
openapi-generator generate -i openapi.yaml -g typescript-axios -o frontend/src/api
```

## 주요 엔드포인트

### 인증
- `POST /api/v1/auth/42/callback` - 42 OAuth 콜백

### 도서
- `GET /api/v1/books` - 도서 목록 조회
- `GET /api/v1/books/search` - 도서 검색
- `GET /api/v1/books/{id}` - 도서 상세 조회
- `POST /api/v1/books` - 도서 추가 (관리자)
- `PUT /api/v1/books/{id}` - 도서 수정 (관리자)
- `DELETE /api/v1/books/{id}` - 도서 삭제 (관리자)

### 대출
- `POST /api/v1/loans/request` - 대출 요청
- `GET /api/v1/loans/my` - 내 대출 목록
- `POST /api/v1/loans/{id}/approve` - 대출 승인 (관리자)
- `POST /api/v1/loans/{id}/return` - 도서 반납

### 예약
- `POST /api/v1/reservations` - 예약 생성
- `GET /api/v1/reservations/my` - 내 예약 목록
- `GET /api/v1/reservations/queue/{bookId}` - 도서별 예약 큐 조회

### 희망 도서
- `POST /api/v1/suggestions` - 희망 도서 제안
- `GET /api/v1/suggestions` - 제안 목록 조회 (관리자)
- `PUT /api/v1/suggestions/{id}` - 제안 상태 변경 (관리자)

## 인증 방식

모든 보호된 엔드포인트는 Bearer 토큰 인증 필요:

```
Authorization: Bearer <jwt_token>
```

## 오류 응답 형식

```json
{
  "error": {
    "code": "ERROR_CODE",
    "message": "사용자 친화적 오류 메시지",
    "details": {}
  }
}
```

---

**참고**: 영문 원본은 `specs/001-library-management/contracts/openapi.yaml` 참조
