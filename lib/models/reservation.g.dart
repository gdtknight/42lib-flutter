// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reservation.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Reservation _$ReservationFromJson(Map<String, dynamic> json) => Reservation(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      bookId: json['bookId'] as String,
      queuePosition: json['queuePosition'] as int,
      status: $enumDecode(_$ReservationStatusEnumMap, json['status']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      notifiedAt: json['notifiedAt'] == null
          ? null
          : DateTime.parse(json['notifiedAt'] as String),
      expiresAt: json['expiresAt'] == null
          ? null
          : DateTime.parse(json['expiresAt'] as String),
      fulfilledAt: json['fulfilledAt'] == null
          ? null
          : DateTime.parse(json['fulfilledAt'] as String),
    );

Map<String, dynamic> _$ReservationToJson(Reservation instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'bookId': instance.bookId,
      'queuePosition': instance.queuePosition,
      'status': _$ReservationStatusEnumMap[instance.status]!,
      'createdAt': instance.createdAt.toIso8601String(),
      'notifiedAt': instance.notifiedAt?.toIso8601String(),
      'expiresAt': instance.expiresAt?.toIso8601String(),
      'fulfilledAt': instance.fulfilledAt?.toIso8601String(),
    };

const _$ReservationStatusEnumMap = {
  ReservationStatus.waiting: 'waiting',
  ReservationStatus.notified: 'notified',
  ReservationStatus.expired: 'expired',
  ReservationStatus.fulfilled: 'fulfilled',
  ReservationStatus.cancelled: 'cancelled',
};

K _$enumDecode<K, V>(
  Map<K, V> enumValues,
  Object? source, {
  K? unknownValue,
}) {
  if (source == null) {
    throw ArgumentError(
      'A value must be provided. Supported values: '
      '${enumValues.values.join(', ')}',
    );
  }

  return enumValues.entries.singleWhere(
    (e) => e.value == source,
    orElse: () {
      if (unknownValue == null) {
        throw ArgumentError(
          '`$source` is not one of the supported values: '
          '${enumValues.values.join(', ')}',
        );
      }
      return MapEntry(unknownValue, enumValues.values.first);
    },
  ).key;
}
