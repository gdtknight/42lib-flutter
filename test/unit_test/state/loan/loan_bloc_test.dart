import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/state/loan/loan_bloc.dart';
import 'package:lib_42_flutter/state/loan/loan_event.dart';
import 'package:lib_42_flutter/state/loan/loan_state.dart';

import '../../../support/fake_loan_repositories.dart';

void main() {
  group('LoanBloc (T096)', () {
    late FakeLoanRequestRepository loanRepo;
    late FakeReservationRepository rsvRepo;

    LoanBloc build() => LoanBloc(
          loanRequestRepository: loanRepo,
          reservationRepository: rsvRepo,
        );

    setUp(() {
      loanRepo = FakeLoanRequestRepository();
      rsvRepo = FakeReservationRepository();
    });

    blocTest<LoanBloc, LoanState>(
      'LoadMyLoanRequests: emits [Loading, Loaded] on success',
      build: () {
        loanRepo.myLoanRequests = [makeLoanRequest(id: 'a')];
        rsvRepo.myReservations = [makeReservation(id: 'r1')];
        return build();
      },
      act: (bloc) => bloc.add(const LoadMyLoanRequests()),
      expect: () => [
        isA<LoanLoading>(),
        isA<LoanLoaded>()
            .having((s) => s.loanRequests.length, 'loanRequests', 1)
            .having((s) => s.reservations.length, 'reservations', 1),
      ],
    );

    blocTest<LoanBloc, LoanState>(
      'LoadMyLoanRequests: emits [Loading, Error] on failure',
      build: () {
        loanRepo.error = Exception('boom');
        return build();
      },
      act: (bloc) => bloc.add(const LoadMyLoanRequests()),
      expect: () => [isA<LoanLoading>(), isA<LoanError>()],
    );

    blocTest<LoanBloc, LoanState>(
      'CreateLoanRequest with available book: emits [Creating, Created, Loading, Loaded]',
      build: () {
        loanRepo.createReturnValue = makeLoanRequest(id: 'new');
        loanRepo.myLoanRequests = [makeLoanRequest(id: 'new')];
        return build();
      },
      act: (bloc) => bloc.add(const CreateLoanRequest(bookId: 'book-1')),
      expect: () => [
        isA<LoanRequestCreating>().having((s) => s.bookId, 'bookId', 'book-1'),
        isA<LoanRequestCreated>()
            .having((s) => s.loanRequest.id, 'loanRequest.id', 'new'),
        // Bloc auto-dispatches LoadMyLoanRequests after success
        isA<LoanLoading>(),
        isA<LoanLoaded>().having((s) => s.loanRequests.length, 'count', 1),
      ],
    );

    blocTest<LoanBloc, LoanState>(
      'CreateLoanRequest with unavailable book: emits ReservationCreated',
      build: () {
        final rsv = makeReservation(id: 'rsv-new', bookId: 'book-X', queuePosition: 3);
        loanRepo.createReturnValue = rsv;
        rsvRepo.queueByBookId = {
          'book-X': [
            makeReservation(id: 'a', queuePosition: 1),
            makeReservation(id: 'b', queuePosition: 2),
            rsv,
          ],
        };
        rsvRepo.myReservations = [rsv];
        return build();
      },
      act: (bloc) => bloc.add(const CreateLoanRequest(bookId: 'book-X')),
      expect: () => [
        isA<LoanRequestCreating>(),
        isA<ReservationCreated>()
            .having((s) => s.reservation.id, 'reservation.id', 'rsv-new')
            .having((s) => s.queuePosition, 'queuePosition', 3),
        isA<LoanLoading>(),
        isA<LoanLoaded>(),
      ],
    );

    blocTest<LoanBloc, LoanState>(
      'CreateLoanRequest: emits Error on repository failure',
      build: () {
        loanRepo.error = Exception('network down');
        return build();
      },
      act: (bloc) => bloc.add(const CreateLoanRequest(bookId: 'book-1')),
      expect: () => [
        isA<LoanRequestCreating>(),
        isA<LoanError>().having((s) => s.message, 'message', '대출 요청 중 오류가 발생했습니다'),
      ],
    );

    blocTest<LoanBloc, LoanState>(
      'CancelLoanRequest: success path',
      build: () => build(),
      act: (bloc) => bloc.add(const CancelLoanRequest(requestId: 'lr-1')),
      expect: () => [
        isA<LoanOperationInProgress>(),
        isA<LoanRequestCancelled>().having((s) => s.requestId, 'requestId', 'lr-1'),
        // Auto-refresh after cancel
        isA<LoanLoading>(),
        isA<LoanLoaded>(),
      ],
      verify: (_) {
        expect(loanRepo.cancelCalls, 1);
        expect(loanRepo.lastCancelledId, 'lr-1');
      },
    );

    blocTest<LoanBloc, LoanState>(
      'ClearLoanError resets to Initial',
      build: () => build(),
      seed: () => const LoanError(message: 'old error'),
      act: (bloc) => bloc.add(const ClearLoanError()),
      expect: () => [isA<LoanInitial>()],
    );
  });
}
