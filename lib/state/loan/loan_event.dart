import 'package:equatable/equatable.dart';

/// Base class for all loan-related events
abstract class LoanEvent extends Equatable {
  const LoanEvent();

  @override
  List<Object?> get props => [];
}

/// Event to fetch user's loan requests
class LoadMyLoanRequests extends LoanEvent {
  const LoadMyLoanRequests();
}

/// Event to create a new loan request for a book
class CreateLoanRequest extends LoanEvent {
  final String bookId;
  final String? notes;

  const CreateLoanRequest({
    required this.bookId,
    this.notes,
  });

  @override
  List<Object?> get props => [bookId, notes];
}

/// Event to cancel a pending loan request
class CancelLoanRequest extends LoanEvent {
  final String requestId;

  const CancelLoanRequest({required this.requestId});

  @override
  List<Object?> get props => [requestId];
}

/// Event to refresh loan request data
class RefreshLoanRequests extends LoanEvent {
  const RefreshLoanRequests();
}

/// Event to load reservation queue for a book
class LoadReservationQueue extends LoanEvent {
  final String bookId;

  const LoadReservationQueue({required this.bookId});

  @override
  List<Object?> get props => [bookId];
}

/// Event to load user's reservations
class LoadMyReservations extends LoanEvent {
  const LoadMyReservations();
}

/// Event to cancel a reservation
class CancelReservation extends LoanEvent {
  final String reservationId;

  const CancelReservation({required this.reservationId});

  @override
  List<Object?> get props => [reservationId];
}

/// Event to clear error state
class ClearLoanError extends LoanEvent {
  const ClearLoanError();
}
