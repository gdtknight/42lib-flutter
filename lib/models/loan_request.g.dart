// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'loan_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

LoanRequest _$LoanRequestFromJson(Map<String, dynamic> json) => LoanRequest(
      id: json['id'] as String,
      studentId: json['studentId'] as String,
      bookId: json['bookId'] as String,
      status: $enumDecode(_$LoanRequestStatusEnumMap, json['status']),
      requestDate: DateTime.parse(json['requestDate'] as String),
      reviewedAt: json['reviewedAt'] == null
          ? null
          : DateTime.parse(json['reviewedAt'] as String),
      reviewedBy: json['reviewedBy'] as String?,
      rejectionReason: json['rejectionReason'] as String?,
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$LoanRequestToJson(LoanRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'studentId': instance.studentId,
      'bookId': instance.bookId,
      'status': _$LoanRequestStatusEnumMap[instance.status]!,
      'requestDate': instance.requestDate.toIso8601String(),
      'reviewedAt': instance.reviewedAt?.toIso8601String(),
      'reviewedBy': instance.reviewedBy,
      'rejectionReason': instance.rejectionReason,
      'notes': instance.notes,
    };

const _$LoanRequestStatusEnumMap = {
  LoanRequestStatus.pending: 'pending',
  LoanRequestStatus.approved: 'approved',
  LoanRequestStatus.rejected: 'rejected',
  LoanRequestStatus.cancelled: 'cancelled',
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
