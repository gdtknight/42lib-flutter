import '../models/loan_request.dart';

/// Repository interface for LoanRequest operations
/// Follows Repository pattern for data abstraction
abstract class LoanRequestRepository {
  /// Create a new loan request
  /// Returns the created loan request
  Future<LoanRequest> createLoanRequest({
    required String studentId,
    required String bookId,
    String? notes,
  });

  /// Get loan request by ID
  /// Returns null if not found
  Future<LoanRequest?> getLoanRequestById(String id);

  /// Get all loan requests for a student
  /// [studentId] - Student's ID
  /// [status] - Optional filter by status
  /// [page] - Page number (default: 1)
  /// [limit] - Number of items per page (default: 20)
  Future<List<LoanRequest>> getStudentLoanRequests({
    required String studentId,
    LoanRequestStatus? status,
    int page = 1,
    int limit = 20,
  });

  /// Get all pending loan requests (admin view)
  /// [page] - Page number (default: 1)
  /// [limit] - Number of items per page (default: 20)
  Future<List<LoanRequest>> getPendingLoanRequests({
    int page = 1,
    int limit = 20,
  });

  /// Cancel a loan request (student only, pending status only)
  /// Returns updated loan request
  Future<LoanRequest> cancelLoanRequest(String id);

  /// Check if student has duplicate pending request for book
  /// Returns true if duplicate exists
  Future<bool> hasPendingRequestForBook({
    required String studentId,
    required String bookId,
  });

  /// Sync local cache with remote API
  Future<void> syncWithApi();
}
