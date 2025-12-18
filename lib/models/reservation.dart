import 'package:json_annotation/json_annotation.dart';

part 'reservation.g.dart';

enum ReservationStatus {
  waiting,
  notified,
  expired,
  fulfilled,
  cancelled,
}

@JsonSerializable()
class Reservation {
  final String id;
  final String studentId;
  final String bookId;
  final int queuePosition;
  final ReservationStatus status;
  final DateTime createdAt;
  final DateTime? notifiedAt;
  final DateTime? expiresAt;
  final DateTime? fulfilledAt;

  Reservation({
    required this.id,
    required this.studentId,
    required this.bookId,
    required this.queuePosition,
    required this.status,
    required this.createdAt,
    this.notifiedAt,
    this.expiresAt,
    this.fulfilledAt,
  }) {
    _validate();
  }

  void _validate() {
    // VR-301: studentId must exist (enforced at repository level)
    if (studentId.trim().isEmpty) {
      throw ArgumentError('Student ID must not be empty');
    }

    // VR-302: bookId must exist (enforced at repository level)
    if (bookId.trim().isEmpty) {
      throw ArgumentError('Book ID must not be empty');
    }

    // VR-304: queuePosition must be at least 1
    if (queuePosition < 1) {
      throw ArgumentError('Queue position must be at least 1');
    }

    // VR-305: notifiedAt required if status is notified, expired, or fulfilled
    if ((status == ReservationStatus.notified ||
            status == ReservationStatus.expired ||
            status == ReservationStatus.fulfilled) &&
        notifiedAt == null) {
      throw ArgumentError(
          'Notified date required for notified/expired/fulfilled reservations');
    }

    // VR-306: expiresAt = notifiedAt + 24 hours when status is notified
    if (status == ReservationStatus.notified &&
        notifiedAt != null &&
        expiresAt != null) {
      final expectedExpiry = notifiedAt!.add(Duration(hours: 24));
      final diff = expiresAt!.difference(expectedExpiry).inMinutes.abs();
      if (diff > 1) {
        // Allow 1 minute tolerance for clock differences
        throw ArgumentError('Expires date must be 24 hours after notified date');
      }
    }
  }

  /// Check if reservation is waiting
  bool get isWaiting => status == ReservationStatus.waiting;

  /// Check if reservation is notified
  bool get isNotified => status == ReservationStatus.notified;

  /// Check if reservation has expired
  bool get isExpired => status == ReservationStatus.expired;

  /// Check if reservation is fulfilled
  bool get isFulfilled => status == ReservationStatus.fulfilled;

  /// Check if reservation is cancelled
  bool get isCancelled => status == ReservationStatus.cancelled;

  /// Check if reservation is active (waiting or notified)
  bool get isActive =>
      status == ReservationStatus.waiting ||
      status == ReservationStatus.notified;

  /// Check if reservation is first in queue
  bool get isFirstInQueue => queuePosition == 1;

  /// Create Reservation from JSON
  factory Reservation.fromJson(Map<String, dynamic> json) =>
      _$ReservationFromJson(json);

  /// Convert Reservation to JSON
  Map<String, dynamic> toJson() => _$ReservationToJson(this);

  /// Create a copy of Reservation with updated fields
  Reservation copyWith({
    String? id,
    String? studentId,
    String? bookId,
    int? queuePosition,
    ReservationStatus? status,
    DateTime? createdAt,
    DateTime? notifiedAt,
    DateTime? expiresAt,
    DateTime? fulfilledAt,
  }) {
    return Reservation(
      id: id ?? this.id,
      studentId: studentId ?? this.studentId,
      bookId: bookId ?? this.bookId,
      queuePosition: queuePosition ?? this.queuePosition,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      notifiedAt: notifiedAt ?? this.notifiedAt,
      expiresAt: expiresAt ?? this.expiresAt,
      fulfilledAt: fulfilledAt ?? this.fulfilledAt,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Reservation && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Reservation(id: $id, studentId: $studentId, bookId: $bookId, queuePosition: $queuePosition, status: $status)';
  }
}
