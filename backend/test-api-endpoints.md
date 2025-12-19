# User Story 2: Backend API Endpoints - Testing Guide

## Implemented Endpoints

### 1. Authentication Endpoints

#### GET /api/v1/auth/42/login
- **Description**: Initiates 42 OAuth flow
- **Response**: Redirects to 42 OAuth authorization page
- **Test**:
```bash
curl http://localhost:3000/api/v1/auth/42/login
```

#### GET /api/v1/auth/42/callback?code=xxx
- **Description**: Handles 42 OAuth callback
- **Response**: Returns JWT token and student data
- **Test**: Use browser to complete OAuth flow

#### GET /api/v1/auth/me
- **Description**: Get current authenticated user
- **Headers**: `Authorization: Bearer <token>`
- **Response**: User information
- **Test**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/v1/auth/me
```

### 2. Loan Request Endpoints

#### POST /api/v1/loan-requests
- **Description**: Create a new loan request
- **Auth**: Student JWT required
- **Body**:
```json
{
  "bookId": "book-uuid",
  "notes": "Optional notes"
}
```
- **Test**:
```bash
curl -X POST http://localhost:3000/api/v1/loan-requests \
  -H "Authorization: Bearer YOUR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"bookId":"xxx-xxx-xxx","notes":"Need for project"}'
```

#### GET /api/v1/loan-requests/my
- **Description**: Get current student's loan requests
- **Auth**: Student JWT required
- **Test**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/v1/loan-requests/my
```

#### GET /api/v1/loan-requests/my/reservations
- **Description**: Get current student's reservations with queue positions
- **Auth**: Student JWT required
- **Test**:
```bash
curl -H "Authorization: Bearer YOUR_TOKEN" http://localhost:3000/api/v1/loan-requests/my/reservations
```

#### DELETE /api/v1/loan-requests/:id
- **Description**: Cancel a loan request
- **Auth**: Student JWT required
- **Test**:
```bash
curl -X DELETE http://localhost:3000/api/v1/loan-requests/YOUR_REQUEST_ID \
  -H "Authorization: Bearer YOUR_TOKEN"
```

## Business Logic Implemented

✅ **T107**: 42 OAuth 2.0 authentication service
- Exchange authorization code for access token
- Fetch user info from 42 API
- Create or update student in database

✅ **T108-T109**: OAuth endpoints
- Initiate OAuth flow
- Handle callback with token exchange

✅ **T110**: JWT token generation for students
- Include 42 user ID in token payload
- 7-day token expiration

✅ **T111**: Student authentication middleware
- Validate JWT tokens
- Role-based access control

✅ **T112-T113**: Loan request creation and retrieval
- Create loan requests with pending status
- Retrieve student's loan history

✅ **T114-T115**: Reservation queue management
- FIFO queue system
- Automatic reservation creation when book unavailable
- Queue position tracking

## Testing Prerequisites

1. **Database Setup**:
```bash
cd backend
npx prisma migrate dev
npx prisma db seed  # Optional: seed test data
```

2. **Environment Variables** (backend/.env):
```env
DATABASE_URL="postgresql://user:pass@localhost:5432/library_db"
JWT_SECRET="your-secret-key"
JWT_EXPIRES_IN="7d"
FORTYTWO_CLIENT_ID="your_42_client_id"
FORTYTWO_CLIENT_SECRET="your_42_client_secret"
FORTYTWO_REDIRECT_URI="http://localhost:3000/api/v1/auth/42/callback"
PORT=3000
```

3. **Start Backend**:
```bash
cd backend
npm run dev
```

4. **Verify Server**:
```bash
curl http://localhost:3000/health
# Expected: {"status":"ok","timestamp":"..."}
```

## Next Steps

The following tasks remain for complete User Story 2 implementation:

### Frontend (Flutter) Tasks:
- T102-T106: Student, LoanRequest, Reservation models
- T116-T119: State management (LoanBloc, AuthBloc)
- T120-T121: 42 OAuth client service
- T122-T123: UI components (LoanRequestButton, ReservationQueueIndicator)
- T124-T127: Screens (LoginScreen, MyLoansScreen)
- T128-T131: Integration & Polish

### Backend Tests:
- T099: Unit test for 42 OAuth integration
- T100: Unit test for POST /loan-requests
- T101: Unit test for reservation queue logic

