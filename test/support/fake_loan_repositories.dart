import 'package:lib_42_flutter/models/loan_request.dart';
import 'package:lib_42_flutter/models/reservation.dart';
import 'package:lib_42_flutter/repositories/loan_request_repository.dart';
import 'package:lib_42_flutter/repositories/reservation_repository.dart';

/// Test fake for [LoanRequestRepository]. Override only the subset of methods
/// LoanBloc actually invokes; remaining abstract methods fall through to
/// [_unimplemented] which throws a clear test failure.
class FakeLoanRequestRepository implements LoanRequestRepository {
  Object? createReturnValue; // LoanRequest, Reservation, or Exception
  List<LoanRequest> myLoanRequests = [];
  Exception? error;
  int createCalls = 0;
  int cancelCalls = 0;
  String? lastCancelledId;

  @override
  Future<dynamic> createLoanRequest({
    required String bookId,
    String? notes,
  }) async {
    createCalls++;
    if (error != null) throw error!;
    if (createReturnValue is Exception) throw createReturnValue as Exception;
    return createReturnValue;
  }

  @override
  Future<List<LoanRequest>> getMyLoanRequests() async {
    if (error != null) throw error!;
    return myLoanRequests;
  }

  @override
  Future<void> cancelLoanRequest(String requestId) async {
    cancelCalls++;
    lastCancelledId = requestId;
    if (error != null) throw error!;
  }

  Never _unimplemented(String name) =>
      throw UnimplementedError('FakeLoanRequestRepository.$name not configured');

  @override
  Future<LoanRequest?> getLoanRequestById(String id) => _unimplemented('getLoanRequestById');
  @override
  Future<List<LoanRequest>> getStudentLoanRequests({
    required String studentId,
    LoanRequestStatus? status,
    int page = 1,
    int limit = 20,
  }) =>
      _unimplemented('getStudentLoanRequests');
  @override
  Future<List<LoanRequest>> getPendingLoanRequests({int page = 1, int limit = 20}) =>
      _unimplemented('getPendingLoanRequests');
  @override
  Future<bool> hasPendingRequestForBook({
    required String studentId,
    required String bookId,
  }) =>
      _unimplemented('hasPendingRequestForBook');
  @override
  Future<void> syncWithApi() => _unimplemented('syncWithApi');
}

class FakeReservationRepository implements ReservationRepository {
  List<Reservation> myReservations = [];
  Map<String, List<Reservation>> queueByBookId = {};
  Exception? error;
  int cancelCalls = 0;

  @override
  Future<List<Reservation>> getMyReservations() async {
    if (error != null) throw error!;
    return myReservations;
  }

  @override
  Future<List<Reservation>> getReservationQueue({required String bookId}) async {
    if (error != null) throw error!;
    return queueByBookId[bookId] ?? [];
  }

  @override
  Future<void> cancelReservation(String reservationId) async {
    cancelCalls++;
    if (error != null) throw error!;
  }

  Never _unimplemented(String name) =>
      throw UnimplementedError('FakeReservationRepository.$name not configured');

  @override
  Future<Reservation> createReservation({required String studentId, required String bookId}) =>
      _unimplemented('createReservation');
  @override
  Future<Reservation?> getReservationById(String id) => _unimplemented('getReservationById');
  @override
  Future<List<Reservation>> getStudentReservations({
    required String studentId,
    ReservationStatus? status,
    int page = 1,
    int limit = 20,
  }) =>
      _unimplemented('getStudentReservations');
  @override
  Future<List<Reservation>> getBookReservations({
    required String bookId,
    bool onlyActive = true,
  }) =>
      _unimplemented('getBookReservations');
  @override
  Future<int?> getQueuePosition({required String studentId, required String bookId}) =>
      _unimplemented('getQueuePosition');
  @override
  Future<bool> hasActiveReservationForBook({required String studentId, required String bookId}) =>
      _unimplemented('hasActiveReservationForBook');
  @override
  Future<void> syncWithApi() => _unimplemented('syncWithApi');
}

LoanRequest makeLoanRequest({
  String id = 'lr-1',
  String studentId = 'stu-1',
  String bookId = 'book-1',
  LoanRequestStatus status = LoanRequestStatus.pending,
}) {
  return LoanRequest(
    id: id,
    studentId: studentId,
    bookId: bookId,
    status: status,
    requestDate: DateTime(2024, 1, 1),
  );
}

Reservation makeReservation({
  String id = 'rsv-1',
  String studentId = 'stu-1',
  String bookId = 'book-1',
  int queuePosition = 1,
  ReservationStatus status = ReservationStatus.waiting,
}) {
  return Reservation(
    id: id,
    studentId: studentId,
    bookId: bookId,
    queuePosition: queuePosition,
    status: status,
    createdAt: DateTime(2024, 1, 1),
  );
}
