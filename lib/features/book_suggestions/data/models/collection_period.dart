import 'package:equatable/equatable.dart';

enum PeriodStatus { upcoming, active, closed }

PeriodStatus _parsePeriodStatus(String raw) {
  switch (raw) {
    case 'upcoming':
      return PeriodStatus.upcoming;
    case 'active':
      return PeriodStatus.active;
    case 'closed':
      return PeriodStatus.closed;
    default:
      throw ArgumentError('Unknown period status: $raw');
  }
}

class CollectionPeriod extends Equatable {
  final String id;
  final String name;
  final DateTime startDate;
  final DateTime endDate;
  final PeriodStatus status;

  const CollectionPeriod({
    required this.id,
    required this.name,
    required this.startDate,
    required this.endDate,
    required this.status,
  });

  factory CollectionPeriod.fromJson(Map<String, dynamic> json) {
    return CollectionPeriod(
      id: json['id'] as String,
      name: json['name'] as String,
      startDate: DateTime.parse(json['startDate'] as String),
      endDate: DateTime.parse(json['endDate'] as String),
      status: _parsePeriodStatus(json['status'] as String),
    );
  }

  bool get isActive => status == PeriodStatus.active;

  /// Days remaining until end date (0 if already past).
  int daysRemaining(DateTime now) {
    final diff = endDate.difference(now).inDays;
    return diff < 0 ? 0 : diff;
  }

  @override
  List<Object?> get props => [id, name, startDate, endDate, status];
}
