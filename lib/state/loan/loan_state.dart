import 'package:equatable/equatable.dart';
import '../../models/loan_request.dart';
import '../../models/reservation.dart';

/// Base class for all loan states
abstract class LoanState extends Equatable {
  const LoanState();

  @override
  List<Object?> get props => [];
}

/// Initial state when the bloc is created
class LoanInitial extends LoanState {
  const LoanInitial();
}

/// State when loading loan requests
class LoanLoading extends LoanState {
  const LoanLoading();
}

/// State when loan requests are successfully loaded
class LoanLoaded extends LoanState {
  final List<LoanRequest> loanRequests;
  final List<Reservation> reservations;

  const LoanLoaded({
    required this.loanRequests,
    required this.reservations,
  });

  @override
  List<Object?> get props => [loanRequests, reservations];

  LoanLoaded copyWith({
    List<LoanRequest>? loanRequests,
    List<Reservation>? reservations,
  }) {
    return LoanLoaded(
      loanRequests: loanRequests ?? this.loanRequests,
      reservations: reservations ?? this.reservations,
    );
  }
}

/// State when creating a loan request
class LoanRequestCreating extends LoanState {
  final String bookId;

  const LoanRequestCreating({required this.bookId});

  @override
  List<Object?> get props => [bookId];
}

/// State when loan request is successfully created
class LoanRequestCreated extends LoanState {
  final LoanRequest loanRequest;
  final String message;

  const LoanRequestCreated({
    required this.loanRequest,
    required this.message,
  });

  @override
  List<Object?> get props => [loanRequest, message];
}

/// State when a reservation is created (book unavailable)
class ReservationCreated extends LoanState {
  final Reservation reservation;
  final int queuePosition;
  final String message;

  const ReservationCreated({
    required this.reservation,
    required this.queuePosition,
    required this.message,
  });

  @override
  List<Object?> get props => [reservation, queuePosition, message];
}

/// State when loan request is cancelled
class LoanRequestCancelled extends LoanState {
  final String requestId;
  final String message;

  const LoanRequestCancelled({
    required this.requestId,
    required this.message,
  });

  @override
  List<Object?> get props => [requestId, message];
}

/// State when reservation queue is loaded for a book
class ReservationQueueLoaded extends LoanState {
  final String bookId;
  final List<Reservation> queue;
  final int? myPosition;

  const ReservationQueueLoaded({
    required this.bookId,
    required this.queue,
    this.myPosition,
  });

  @override
  List<Object?> get props => [bookId, queue, myPosition];
}

/// State when an error occurs
class LoanError extends LoanState {
  final String message;
  final String? code;
  final dynamic error;

  const LoanError({
    required this.message,
    this.code,
    this.error,
  });

  @override
  List<Object?> get props => [message, code, error];
}

/// State when operation is in progress (generic)
class LoanOperationInProgress extends LoanState {
  final String operation;

  const LoanOperationInProgress({required this.operation});

  @override
  List<Object?> get props => [operation];
}

/// State when operation is successful (generic)
class LoanOperationSuccess extends LoanState {
  final String operation;
  final String message;

  const LoanOperationSuccess({
    required this.operation,
    required this.message,
  });

  @override
  List<Object?> get props => [operation, message];
}
