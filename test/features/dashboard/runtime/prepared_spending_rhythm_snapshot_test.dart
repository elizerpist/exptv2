import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';

void main() {
  group('PreparedSpendingRhythmDirectionBank', () {
    test('retains exactly eight 3-hour values for one prepared local day', () {
      final bank = PreparedSpendingRhythmDirectionBank(
        targetCount: 1,
        targetOffsets: const <int>[0, 1],
        epochDays: const <int>[20],
        dailyActualScaled100: const <int>[3600],
        dayPartActualScaled100: const <int>[
          100,
          200,
          300,
          400,
          500,
          600,
          700,
          800,
        ],
      );

      final day = bank.targetView(0).dayAtEpochDay(20);
      expect(day, isNotNull);
      expect(day!.actualScaled100, 3600);
      expect(day.actualFor(SpendingRhythmDayPart.lateEvening), 800);
      expect(SpendingRhythmDayPart.values, hasLength(8));
    });

    test('rejects a daily total that does not equal its eight parts', () {
      expect(
        () => PreparedSpendingRhythmDirectionBank(
          targetCount: 1,
          targetOffsets: const <int>[0, 1],
          epochDays: const <int>[20],
          dailyActualScaled100: const <int>[3599],
          dayPartActualScaled100: const <int>[
            100,
            200,
            300,
            400,
            500,
            600,
            700,
            800,
          ],
        ),
        throwsArgumentError,
      );
    });

    test('keeps target rows sorted and never copies another target range', () {
      final bank = PreparedSpendingRhythmDirectionBank(
        targetCount: 2,
        targetOffsets: const <int>[0, 1, 2],
        epochDays: const <int>[20, 30],
        dailyActualScaled100: const <int>[80, 160],
        dayPartActualScaled100: const <int>[
          10,
          10,
          10,
          10,
          10,
          10,
          10,
          10,
          20,
          20,
          20,
          20,
          20,
          20,
          20,
          20,
        ],
      );

      final first = bank.targetView(0);
      final second = bank.targetView(1);
      expect(first.dayAtEpochDay(30), isNull);
      expect(second.dayAtEpochDay(20), isNull);
      expect(second.dayAtEpochDay(30)!.actualScaled100, 160);
    });

    test('retains the bounded month-to-date contract for DAY pace', () {
      final marchFirst = _epochDay(2022, 3, 1);
      final marchThird = _epochDay(2022, 3, 3);
      final aprilFirst = _epochDay(2022, 4, 1);
      final bank = PreparedSpendingRhythmDirectionBank(
        targetCount: 1,
        targetOffsets: const <int>[0, 3],
        epochDays: <int>[marchFirst, marchThird, aprilFirst],
        dailyActualScaled100: const <int>[10, 30, 40],
        dayPartActualScaled100: const <int>[
          10,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          30,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          40,
          0,
          0,
          0,
        ],
      );

      final target = bank.targetView(0);
      expect(
        target.actualForMonthThroughEpochDay(
          year: 2022,
          month: 3,
          throughEpochDay: _epochDay(2022, 3, 2),
        ),
        10,
      );
      expect(
        target.actualForMonthThroughEpochDay(
          year: 2022,
          month: 3,
          throughEpochDay: _epochDay(2022, 3, 31),
        ),
        40,
      );
      expect(
        target.actualForMonthThroughEpochDay(
          year: 2022,
          month: 3,
          throughEpochDay: _epochDay(2022, 2, 28),
        ),
        0,
      );
    });
  });
}

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;
