import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_daily_insights_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

const _selected = LocalDate(year: 2026, month: 6, day: 30);
const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'test',
  indexGeneration: 1,
  coreRevision: 1,
);

void main() {
  group('DashboardBalanceDailyInsightsProjection', () {
    test(
      'shares the exact selected 30×30 result with the final rhythm point',
      () {
        final result = _build(
          selected: _selected,
          income: _income(),
          expense: _expense(),
        );

        expect(result.momentum.available, isTrue);
        expect(result.momentum.rhythm, hasLength(60));
        expect(result.momentum.selected, same(result.momentum.rhythm.last));
        expect(result.momentum.selected.incomeChangeMinor, 30 * 1000);
        expect(result.momentum.selected.expenseChangeMinor, 60 * 1000);
        expect(
          result.momentum.selected.quadrant,
          DashboardBalanceDailyMomentumQuadrant.growth,
        );
        expect(
          result.momentum.rhythm
              .take(30)
              .every((point) => !point.isCurrentHalf),
          isTrue,
        );
        expect(
          result.momentum.rhythm.skip(30).every((point) => point.isCurrentHalf),
          isTrue,
        );
      },
    );

    test('applies the open-day cutoff only to D and D−30 terminal days', () {
      final selectedEpoch = _selected.epochDay;
      final result = _build(
        selected: _selected,
        income: <DashboardLedgerEntry>[
          ..._income(),
          _entry(
            'income-included-today',
            2000,
            selectedEpoch,
            LedgerDirection.income,
            minute: 600,
          ),
          _entry(
            'income-excluded-today',
            9000,
            selectedEpoch,
            LedgerDirection.income,
            minute: 900,
          ),
          _entry(
            'income-included-reference',
            1000,
            selectedEpoch - 30,
            LedgerDirection.income,
            minute: 600,
          ),
          _entry(
            'income-excluded-reference',
            8000,
            selectedEpoch - 30,
            LedgerDirection.income,
            minute: 900,
          ),
        ],
        expense: _expense(),
        asOfMinute: 12 * 60,
      );

      expect(result.momentum.selected.currentIncomeMinor, 62 * 1000);
      expect(result.momentum.selected.referenceIncomeMinor, 31 * 1000);
      expect(result.momentum.selected.incomeChangeMinor, 31 * 1000);
    });

    test(
      'daily impact is expense-only and its p95 scale excludes current day',
      () {
        final epoch = _selected.epochDay;
        final expense = <DashboardLedgerEntry>[
          for (var offset = -37; offset <= 0; offset += 1)
            _entry(
              'expense-$offset',
              offset == 0 ? 2000 : 1000,
              epoch + offset,
              LedgerDirection.expense,
            ),
        ];
        final result = _build(
          selected: _selected,
          income: _income(),
          expense: expense,
        );

        expect(result.impact.available, isTrue);
        expect(result.impact.previousSevenExpenseMinor, 7000);
        expect(result.impact.currentSevenExpenseMinor, 8000);
        expect(result.impact.valuePercent, closeTo(-14.2857, .0001));
        expect(result.impact.scaleExtentPercent, 10);
        expect(result.impact.isWorsening, isTrue);
        expect(result.impact.markerFraction, 0);
        expect(result.impact.overflow, isTrue);
      },
    );

    test('uses a 5 percent upward-rounded historical p95 scale', () {
      final epoch = _selected.epochDay;
      final expense = <DashboardLedgerEntry>[
        for (var offset = -37; offset <= 0; offset += 1)
          _entry(
            'expense-$offset',
            1000 + ((offset + 37) * 37),
            epoch + offset,
            LedgerDirection.expense,
          ),
      ];
      final result = _build(
        selected: _selected,
        income: _income(),
        expense: expense,
      );

      expect(result.impact.available, isTrue);
      expect(result.impact.scaleExtentPercent % 5, 0);
      expect(result.impact.scaleExtentPercent, greaterThanOrEqualTo(10));
      expect(result.impact.scaleExtentPercent, lessThan(100));
    });

    test(
      'does not invent comparable data when a full daily momentum history is absent',
      () {
        final result = _build(
          selected: _selected,
          income: <DashboardLedgerEntry>[
            _entry(
              'only',
              1000,
              _selected.epochDay - 20,
              LedgerDirection.income,
            ),
          ],
          expense: <DashboardLedgerEntry>[
            _entry(
              'only-expense',
              1000,
              _selected.epochDay - 20,
              LedgerDirection.expense,
            ),
          ],
        );

        expect(result.momentum.available, isFalse);
        expect(result.momentum.rhythm, isEmpty);
      },
    );

    test(
      'returns unavailable impact instead of a fake percent when previous seven spend is zero',
      () {
        final result = _build(
          selected: _selected,
          income: _income(),
          expense: const <DashboardLedgerEntry>[],
        );

        expect(result.impact.available, isFalse);
        expect(result.impact.valuePercent, isNull);
      },
    );

    test(
      'links the one daily presentation through the resident Balance payload',
      () {
        final linked = DashboardBalanceLinkedProjection.build(
          identity: _identity,
          timeScope: const DayScope(_selected),
          selectedDirection: LedgerDirection.expense,
          logicalAsOfDate: _selected,
          incomeEntries: _income(),
          expenseEntries: _expense(),
        );

        expect(linked.dailyInsights.momentum.available, isTrue);
        expect(
          linked.dailyInsights.momentum.selected,
          same(linked.dailyInsights.momentum.rhythm.last),
        );
      },
    );
  });
}

DashboardBalanceDailyInsightsPresentation _build({
  required LocalDate selected,
  required List<DashboardLedgerEntry> income,
  required List<DashboardLedgerEntry> expense,
  int asOfMinute = 23 * 60 + 59,
}) => DashboardBalanceDailyInsightsProjection.build(
  identity: _identity,
  timeScope: DayScope(selected),
  logicalAsOfDate: selected,
  logicalAsOfLocalTimeMinutes: asOfMinute,
  incomeEntries: income,
  expenseEntries: expense,
);

List<DashboardLedgerEntry> _income() => <DashboardLedgerEntry>[
  for (var offset = -118; offset <= 0; offset += 1)
    _entry(
      'income-$offset',
      offset >= -29 ? 2000 : 1000,
      _selected.epochDay + offset,
      LedgerDirection.income,
    ),
];

List<DashboardLedgerEntry> _expense() => <DashboardLedgerEntry>[
  for (var offset = -118; offset <= 0; offset += 1)
    _entry(
      'expense-$offset',
      offset >= -29 ? 3000 : 1000,
      _selected.epochDay + offset,
      LedgerDirection.expense,
    ),
];

DashboardLedgerEntry _entry(
  String id,
  int amountMinor,
  int epochDay,
  LedgerDirection direction, {
  int minute = 12 * 60,
}) => DashboardLedgerEntry(
  id: id,
  partnerId: 'partner-$id',
  categoryId: 'category-$id',
  direction: direction.name,
  amountMinor: amountMinor,
  bookedLocalEpochDay: epochDay,
  bookedLocalTimeMinutes: minute,
);
