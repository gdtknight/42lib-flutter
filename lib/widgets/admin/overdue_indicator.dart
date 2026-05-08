import 'package:flutter/material.dart';

/// Visual indicator for a loan's due date.
///
/// Three variants based on `daysLeft` (`dueDate - now`):
/// - **overdue** (`daysLeft < 0` or `isOverdue`): error chip + "연체 N일"
/// - **due soon** (`0 ≤ daysLeft ≤ 2`): warning amber chip + "D-N"
/// - **on track** (`daysLeft > 2`): muted chip + "D-N"
///
/// Used by admin loan management screens (T152) to draw attention to
/// overdue loans without changing list semantics.
class OverdueIndicator extends StatelessWidget {
  const OverdueIndicator({
    super.key,
    required this.dueDate,
    this.isOverdue = false,
    this.now,
    this.dueSoonThresholdDays = 2,
  });

  final DateTime dueDate;
  final bool isOverdue;
  final DateTime? now;
  final int dueSoonThresholdDays;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final reference = now ?? DateTime.now();
    final daysLeft = dueDate.difference(reference).inDays;
    final overdue = isOverdue || daysLeft < 0;

    final (Color bg, Color fg, IconData icon, String label) = switch (overdue) {
      true => (
          theme.colorScheme.errorContainer,
          theme.colorScheme.onErrorContainer,
          Icons.warning,
          '연체 ${-daysLeft}일',
        ),
      false when daysLeft <= dueSoonThresholdDays => (
          Colors.amber.shade100,
          Colors.amber.shade900,
          Icons.schedule,
          'D-$daysLeft',
        ),
      false => (
          theme.colorScheme.surfaceContainerHighest,
          theme.colorScheme.onSurface,
          Icons.event_outlined,
          'D-$daysLeft',
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: fg,
              fontWeight: overdue ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
