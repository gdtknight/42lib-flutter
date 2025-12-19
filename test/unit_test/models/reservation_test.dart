import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/models/reservation.dart';

void main() {
  group('Reservation Model', () {
    test('should create a valid Reservation instance', () {
      final reservation = Reservation(
        id: '1',
        studentId: 'student123',
        bookId: 'book456',
        queuePosition: 1,
        status: ReservationStatus.waiting,
        createdAt: DateTime(2024, 1, 1),
      );

      expect(reservation.id, '1');
      expect(reservation.studentId, 'student123');
      expect(reservation.bookId, 'book456');
      expect(reservation.queuePosition, 1);
      expect(reservation.status, ReservationStatus.waiting);
    });

    test('should serialize to JSON correctly', () {
      final reservation = Reservation(
        id: '1',
        studentId: 'student123',
        bookId: 'book456',
        queuePosition: 2,
        status: ReservationStatus.waiting,
        createdAt: DateTime(2024, 1, 1),
      );

      final json = reservation.toJson();

      expect(json['id'], '1');
      expect(json['studentId'], 'student123');
      expect(json['bookId'], 'book456');
      expect(json['queuePosition'], 2);
      expect(json['status'], 'waiting');
    });

    test('should deserialize from JSON correctly', () {
      final json = {
        'id': '1',
        'studentId': 'student123',
        'bookId': 'book456',
        'queuePosition': 3,
        'status': 'waiting',
        'createdAt': '2024-01-01T00:00:00.000',
      };

      final reservation = Reservation.fromJson(json);

      expect(reservation.id, '1');
      expect(reservation.studentId, 'student123');
      expect(reservation.bookId, 'book456');
      expect(reservation.queuePosition, 3);
      expect(reservation.status, ReservationStatus.waiting);
    });

    test('should validate studentId is not empty', () {
      expect(
        () => Reservation(
          id: '1',
          studentId: '',
          bookId: 'book456',
          queuePosition: 1,
          status: ReservationStatus.waiting,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate bookId is not empty', () {
      expect(
        () => Reservation(
          id: '1',
          studentId: 'student123',
          bookId: '',
          queuePosition: 1,
          status: ReservationStatus.waiting,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should validate queuePosition is at least 1', () {
      expect(
        () => Reservation(
          id: '1',
          studentId: 'student123',
          bookId: 'book456',
          queuePosition: 0,
          status: ReservationStatus.waiting,
          createdAt: DateTime.now(),
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('should handle different statuses', () {
      // Only test statuses that don't require additional dates
      final waitingReservation = Reservation(
        id: '1',
        studentId: 'student123',
        bookId: 'book456',
        queuePosition: 1,
        status: ReservationStatus.waiting,
        createdAt: DateTime.now(),
      );
      expect(waitingReservation.status, ReservationStatus.waiting);

      final cancelledReservation = Reservation(
        id: '2',
        studentId: 'student123',
        bookId: 'book456',
        queuePosition: 1,
        status: ReservationStatus.cancelled,
        createdAt: DateTime.now(),
      );
      expect(cancelledReservation.status, ReservationStatus.cancelled);
    });
  });
}
