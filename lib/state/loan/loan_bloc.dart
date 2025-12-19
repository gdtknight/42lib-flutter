import 'package:flutter_bloc/flutter_bloc.dart';
import '../../repositories/loan_request_repository.dart';
import '../../repositories/reservation_repository.dart';
import '../../models/loan_request.dart';
import '../../models/reservation.dart';
import 'loan_event.dart';
import 'loan_state.dart';

/// BLoC for managing loan requests and reservations
class LoanBloc extends Bloc<LoanEvent, LoanState> {
  final LoanRequestRepository loanRequestRepository;
  final ReservationRepository reservationRepository;

  LoanBloc({
    required this.loanRequestRepository,
    required this.reservationRepository,
  }) : super(const LoanInitial()) {
    on<LoadMyLoanRequests>(_onLoadMyLoanRequests);
    on<CreateLoanRequest>(_onCreateLoanRequest);
    on<CancelLoanRequest>(_onCancelLoanRequest);
    on<RefreshLoanRequests>(_onRefreshLoanRequests);
    on<LoadReservationQueue>(_onLoadReservationQueue);
    on<LoadMyReservations>(_onLoadMyReservations);
    on<CancelReservation>(_onCancelReservation);
    on<ClearLoanError>(_onClearLoanError);
  }

  /// Load user's loan requests
  Future<void> _onLoadMyLoanRequests(
    LoadMyLoanRequests event,
    Emitter<LoanState> emit,
  ) async {
    try {
      emit(const LoanLoading());

      final loanRequests = await loanRequestRepository.getMyLoanRequests();
      final reservations = await reservationRepository.getMyReservations();

      emit(LoanLoaded(
        loanRequests: loanRequests,
        reservations: reservations,
      ));
    } catch (error) {
      emit(LoanError(
        message: '대출 요청 목록을 불러올 수 없습니다',
        error: error,
      ));
    }
  }

  /// Create a new loan request
  Future<void> _onCreateLoanRequest(
    CreateLoanRequest event,
    Emitter<LoanState> emit,
  ) async {
    try {
      emit(LoanRequestCreating(bookId: event.bookId));

      final result = await loanRequestRepository.createLoanRequest(
        bookId: event.bookId,
        notes: event.notes,
      );

      // Check if result is a LoanRequest or Reservation
      if (result is LoanRequest) {
        emit(LoanRequestCreated(
          loanRequest: result,
          message: '대출 요청이 접수되었습니다',
        ));
      } else if (result is Reservation) {
        // Book was unavailable, reservation created
        final queue = await reservationRepository.getReservationQueue(
          bookId: event.bookId,
        );
        final myPosition = queue.indexWhere((r) => r.id == result.id) + 1;

        emit(ReservationCreated(
          reservation: result,
          queuePosition: myPosition,
          message: '도서가 품절되어 예약 대기열에 추가되었습니다 (대기 순위: $myPosition)',
        ));
      }

      // Refresh the list after creation
      add(const LoadMyLoanRequests());
    } catch (error) {
      emit(LoanError(
        message: '대출 요청 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Cancel a pending loan request
  Future<void> _onCancelLoanRequest(
    CancelLoanRequest event,
    Emitter<LoanState> emit,
  ) async {
    try {
      emit(LoanOperationInProgress(operation: 'cancel_request'));

      await loanRequestRepository.cancelLoanRequest(event.requestId);

      emit(LoanRequestCancelled(
        requestId: event.requestId,
        message: '대출 요청이 취소되었습니다',
      ));

      // Refresh the list after cancellation
      add(const LoadMyLoanRequests());
    } catch (error) {
      emit(LoanError(
        message: '대출 요청 취소 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Refresh loan requests (pull-to-refresh)
  Future<void> _onRefreshLoanRequests(
    RefreshLoanRequests event,
    Emitter<LoanState> emit,
  ) async {
    try {
      // Don't show loading state for refresh
      final loanRequests = await loanRequestRepository.getMyLoanRequests();
      final reservations = await reservationRepository.getMyReservations();

      emit(LoanLoaded(
        loanRequests: loanRequests,
        reservations: reservations,
      ));
    } catch (error) {
      emit(LoanError(
        message: '새로고침 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Load reservation queue for a specific book
  Future<void> _onLoadReservationQueue(
    LoadReservationQueue event,
    Emitter<LoanState> emit,
  ) async {
    try {
      emit(const LoanLoading());

      final queue = await reservationRepository.getReservationQueue(
        bookId: event.bookId,
      );

      // Find user's position in queue if they have a reservation
      final myReservations = await reservationRepository.getMyReservations();
      final myReservation = myReservations.firstWhere(
        (r) => r.bookId == event.bookId && r.status == ReservationStatus.active,
        orElse: () => Reservation(
          id: '',
          studentId: '',
          bookId: '',
          position: 0,
          status: ReservationStatus.cancelled,
          createdAt: DateTime.now(),
        ),
      );

      final myPosition = myReservation.id.isNotEmpty
          ? queue.indexWhere((r) => r.id == myReservation.id) + 1
          : null;

      emit(ReservationQueueLoaded(
        bookId: event.bookId,
        queue: queue,
        myPosition: myPosition,
      ));
    } catch (error) {
      emit(LoanError(
        message: '예약 대기열을 불러올 수 없습니다',
        error: error,
      ));
    }
  }

  /// Load user's reservations
  Future<void> _onLoadMyReservations(
    LoadMyReservations event,
    Emitter<LoanState> emit,
  ) async {
    try {
      emit(const LoanLoading());

      final reservations = await reservationRepository.getMyReservations();
      final loanRequests = await loanRequestRepository.getMyLoanRequests();

      emit(LoanLoaded(
        loanRequests: loanRequests,
        reservations: reservations,
      ));
    } catch (error) {
      emit(LoanError(
        message: '예약 목록을 불러올 수 없습니다',
        error: error,
      ));
    }
  }

  /// Cancel a reservation
  Future<void> _onCancelReservation(
    CancelReservation event,
    Emitter<LoanState> emit,
  ) async {
    try {
      emit(LoanOperationInProgress(operation: 'cancel_reservation'));

      await reservationRepository.cancelReservation(event.reservationId);

      emit(LoanOperationSuccess(
        operation: 'cancel_reservation',
        message: '예약이 취소되었습니다',
      ));

      // Refresh the list after cancellation
      add(const LoadMyLoanRequests());
    } catch (error) {
      emit(LoanError(
        message: '예약 취소 중 오류가 발생했습니다',
        error: error,
      ));
    }
  }

  /// Clear error state
  Future<void> _onClearLoanError(
    ClearLoanError event,
    Emitter<LoanState> emit,
  ) async {
    emit(const LoanInitial());
  }
}
