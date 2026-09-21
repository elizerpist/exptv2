import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_history_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';

void main() {
  test(
    'BALANCE-HISTORY RED: transaction-ordered cumulative history retains actual endpoints and extrema',
    () {
      final series = DashboardBalanceHistoryProjection.build(
        incomeEntries: <DashboardLedgerEntry>[
          _entry(
            id: 'income-jan',
            direction: 'income',
            amount: 100000,
            epochDay: 20000,
            minute: 480,
          ),
          _entry(
            id: 'income-mar',
            direction: 'income',
            amount: 80000,
            epochDay: 20062,
            minute: 600,
          ),
        ],
        expenseEntries: <DashboardLedgerEntry>[
          _entry(
            id: 'expense-jan',
            direction: 'expense',
            amount: 40000,
            epochDay: 20000,
            minute: 720,
          ),
          _entry(
            id: 'expense-mar',
            direction: 'expense',
            amount: 20000,
            epochDay: 20062,
            minute: 540,
          ),
        ],
      );

      expect(series, isNotNull);
      expect(series!.points, hasLength(4));
      expect(series.startInclusiveEpochMinute, 20000 * 1440 + 480);
      expect(series.endInclusiveEpochMinute, 20062 * 1440 + 600);
      expect(
        series.points.map((point) => point.balanceMinor),
        <int>[100000, 60000, 40000, 120000],
        reason:
            'Each point is cumulative income through its transaction minus '
            'cumulative expense through the same transaction, never a '
            'period-local reset.',
      );
      expect(series.points.first.epochDay, 20000);
      expect(series.points.last.epochDay, 20062);
      expect(series.points.first.balanceMinor, 100000);
      expect(series.points.last.balanceMinor, 120000);
      expect(
        series.points.map((point) => point.balanceMinor),
        containsAll(<int>[40000, 120000]),
        reason: 'The immutable transaction sampling retains real extrema.',
      );
    },
  );

  test(
    'BALANCE-HISTORY RED: empty history remains absent without invented points',
    () {
      expect(
        DashboardBalanceHistoryProjection.build(
          incomeEntries: const <DashboardLedgerEntry>[],
          expenseEntries: const <DashboardLedgerEntry>[],
        ),
        isNull,
      );
    },
  );
}

DashboardLedgerEntry _entry({
  required String id,
  required String direction,
  required int amount,
  required int epochDay,
  required int minute,
}) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$id',
  categoryId: 'category-$direction',
  direction: direction,
  amountMinor: amount,
  bookedLocalEpochDay: epochDay,
  bookedLocalTimeMinutes: minute,
);
