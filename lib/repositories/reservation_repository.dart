import '../models/reservation.dart';

/// Repository interface for Reservation operations
/// Follows Repository pattern for data abstraction
abstract class ReservationRepository {
  /// Get current user's reservations
  Future<List<Reservation>> getMyReservations();

  /// Get reservation queue for a book
  Future<List<Reservation>> getReservationQueue({required String bookId});

  /// Cancel a reservation
  Future<void> cancelReservation(String reservationId);

  /// Create a new reservation (automatic when book unavailable)
  /// Returns the created reservation with queue position
  Future<Reservation> createReservation({
    required String studentId,
    required String bookId,
  });

  /// Get reservation by ID
  /// Returns null if not found
  Future<Reservation?> getReservationById(String id);

  /// Get all reservations for a student
  /// [studentId] - Student's ID
  /// [status] - Optional filter by status
  /// [page] - Page number (default: 1)
  /// [limit] - Number of items per page (default: 20)
  Future<List<Reservation>> getStudentReservations({
    required String studentId,
    ReservationStatus? status,
    int page = 1,
    int limit = 20,
  });

  /// Get all reservations for a book (queue view)
  /// [bookId] - Book's ID
  /// [onlyActive] - If true, only return waiting/notified reservations
  Future<List<Reservation>> getBookReservations({
    required String bookId,
    bool onlyActive = true,
  });

  /// Get student's queue position for a book
  /// Returns null if no active reservation exists
  Future<int?> getQueuePosition({
    required String studentId,
    required String bookId,
  });

  /// Check if student has active reservation for book
  /// Returns true if active reservation exists
  Future<bool> hasActiveReservationForBook({
    required String studentId,
    required String bookId,
  });

  /// Sync local cache with remote API
  Future<void> syncWithApi();
}
