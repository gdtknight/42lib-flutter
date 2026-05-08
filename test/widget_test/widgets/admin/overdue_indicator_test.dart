import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lib_42_flutter/widgets/admin/overdue_indicator.dart';

Future<void> _pump(WidgetTester tester, Widget child) async {
  await tester.pumpWidget(MaterialApp(home: Scaffold(body: child)));
}

void main() {
  // Fixed reference time so tests are deterministic regardless of when run.
  final now = DateTime(2024, 6, 15);

  group('OverdueIndicator', () {
    testWidgets('overdue: dueDate before now → "연체 N일" + warning icon',
        (tester) async {
      await _pump(
        tester,
        OverdueIndicator(
          dueDate: DateTime(2024, 6, 10), // 5 days ago
          now: now,
        ),
      );
      expect(find.text('연체 5일'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('overdue: explicit isOverdue=true wins even when daysLeft >= 0',
        (tester) async {
      // dueDate today (daysLeft == 0) but server flagged it overdue.
      await _pump(
        tester,
        OverdueIndicator(
          dueDate: DateTime(2024, 6, 15),
          isOverdue: true,
          now: now,
        ),
      );
      // -daysLeft when daysLeft==0 is 0 → "연체 0일" (still flags as overdue).
      expect(find.textContaining('연체'), findsOneWidget);
      expect(find.byIcon(Icons.warning), findsOneWidget);
    });

    testWidgets('due soon: 0 ≤ daysLeft ≤ 2 → amber "D-N" + schedule icon',
        (tester) async {
      await _pump(
        tester,
        OverdueIndicator(
          dueDate: DateTime(2024, 6, 17), // 2 days
          now: now,
        ),
      );
      expect(find.text('D-2'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('on track: daysLeft > threshold → muted "D-N" + event icon',
        (tester) async {
      await _pump(
        tester,
        OverdueIndicator(
          dueDate: DateTime(2024, 6, 25), // 10 days
          now: now,
        ),
      );
      expect(find.text('D-10'), findsOneWidget);
      expect(find.byIcon(Icons.event_outlined), findsOneWidget);
    });

    testWidgets('custom threshold flips due-soon vs on-track', (tester) async {
      // 5 days left, threshold = 7 → should be "due soon" (amber).
      await _pump(
        tester,
        OverdueIndicator(
          dueDate: DateTime(2024, 6, 20),
          now: now,
          dueSoonThresholdDays: 7,
        ),
      );
      expect(find.text('D-5'), findsOneWidget);
      expect(find.byIcon(Icons.schedule), findsOneWidget);
    });

    testWidgets('overdue label is bold; on-track label is medium-weight',
        (tester) async {
      // overdue
      await _pump(
        tester,
        OverdueIndicator(dueDate: DateTime(2024, 6, 10), now: now),
      );
      final overdueText = tester.widget<Text>(find.text('연체 5일'));
      expect(overdueText.style?.fontWeight, FontWeight.w700);

      // on-track
      await _pump(
        tester,
        OverdueIndicator(dueDate: DateTime(2024, 7, 1), now: now),
      );
      final onTrackText = tester.widget<Text>(find.textContaining('D-'));
      expect(onTrackText.style?.fontWeight, FontWeight.w500);
    });
  });
}
