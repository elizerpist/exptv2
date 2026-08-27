import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_rhythm_snapshot.dart';

void main() {
  test(
    'target-local month-to-date sum excludes future points without allocation',
    () {
      final augustTen = DateTime.utc(
        2026,
        8,
        10,
      ).difference(DateTime.utc(1970)).inDays;
      final bank = PreparedBudgetRhythmDirectionBank.fromTargetPoints(
        targetPoints: <List<PreparedBudgetRhythmPoint>>[
          <PreparedBudgetRhythmPoint>[
            PreparedBudgetRhythmPoint(
              epochDay: augustTen - 9,
              actualScaled100: 100,
            ),
            PreparedBudgetRhythmPoint(
              epochDay: augustTen,
              actualScaled100: 200,
            ),
            PreparedBudgetRhythmPoint(
              epochDay: augustTen + 1,
              actualScaled100: 400,
            ),
          ],
          const <PreparedBudgetRhythmPoint>[],
        ],
      );

      expect(
        bank.monthToDateActualScaled100(
          targetHandle: 0,
          year: 2026,
          month: 8,
          throughEpochDay: augustTen,
        ),
        300,
      );
    },
  );
}
