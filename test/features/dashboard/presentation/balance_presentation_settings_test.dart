import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_history_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'BALANCE-PRESENTATION-SETTINGS RED: defaults preserve current all-time labels and neutral carousel geometry',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.chartMode, BalanceHeaderChartMode.allTime);
      expect(controller.value.timeLabels, BalanceHeaderChartTimeLabels.visible);
      expect(controller.value.cardWidthBoost, 0);
      expect(controller.value.carouselSpacingAdjustment, 0);
      expect(BalancePresentationSettings.maximumCardWidthBoost, .30);
      expect(BalancePresentationSettings.maximumCarouselSpacingAdjustment, .12);

      controller
        ..setChartMode(BalanceHeaderChartMode.adaptiveSummary)
        ..setTimeLabels(BalanceHeaderChartTimeLabels.hidden)
        ..setCardWidthBoost(.30)
        ..setCarouselSpacingAdjustment(.12);
      expect(
        controller.value.chartMode,
        BalanceHeaderChartMode.adaptiveSummary,
      );
      expect(controller.value.timeLabels, BalanceHeaderChartTimeLabels.hidden);
      expect(controller.value.cardWidthBoost, .30);
      expect(controller.value.carouselSpacingAdjustment, .12);
      expect(controller.value.revision, 4);
    },
  );

  test(
    'BALANCE-CHART-MODES RED: views preserve cumulative money and use only immutable Balance history',
    () {
      final history = _history();
      expect(
        DashboardBalanceHistoryViewProjection.project(
          source: history,
          mode: BalanceHeaderChartMode.allTime,
          adaptiveScope: const MonthScope(YearMonth(year: 2026, month: 2)),
        ),
        same(history),
      );

      final adaptive = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.adaptiveSummary,
        adaptiveScope: const MonthScope(YearMonth(year: 2026, month: 2)),
      )!;
      expect(adaptive.points.map((point) => point.balanceMinor), <int>[
        800,
        750,
      ]);
      expect(
        DashboardBalanceHistoryViewProjection.project(
          source: history,
          mode: BalanceHeaderChartMode.adaptiveSummary,
          adaptiveScope: const DayScope(
            LocalDate(year: 2025, month: 1, day: 1),
          ),
        ),
        isNull,
        reason: 'No Summary-period point must not fabricate a Balance trend.',
      );

      final monthEnds = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.monthEndClosingExperimental,
        adaptiveScope: const AllTimeScope(),
      )!;
      expect(monthEnds.points.map((point) => point.balanceMinor), <int>[
        1000,
        750,
        750,
      ]);
      expect(monthEnds.points[1].epochDay, _epochDay(2026, 2, 28));
      expect(monthEnds.points[2].epochDay, _epochDay(2026, 3, 31));
      expect(monthEnds.points[2].entryId, startsWith('month-close:'));
      expect(
        monthEnds.points.last.epochDay,
        _epochDay(2026, 3, 31),
        reason:
            'A partial April ledger must not be presented at April month-end.',
      );
      final onlyPartialMonth = DashboardBalanceHistorySeries(
        startInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
        endInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
        points: <DashboardBalanceHistoryPoint>[
          _point('only-partial', 2026, 4, 2, 900),
        ],
      );
      expect(
        DashboardBalanceHistoryViewProjection.project(
          source: onlyPartialMonth,
          mode: BalanceHeaderChartMode.monthEndClosingExperimental,
          adaptiveScope: const AllTimeScope(),
        ),
        isNull,
        reason: 'A partial first month has no truthful month-end close yet.',
      );
    },
  );
}

DashboardBalanceHistorySeries _history() => DashboardBalanceHistorySeries(
  startInclusiveEpochMinute: _epochDay(2026, 1, 10) * 1440,
  endInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
  points: <DashboardBalanceHistoryPoint>[
    _point('jan', 2026, 1, 10, 1000),
    _point('feb-income', 2026, 2, 4, 800),
    _point('feb-expense', 2026, 2, 21, 750),
    _point('apr', 2026, 4, 2, 900),
  ],
);

DashboardBalanceHistoryPoint _point(
  String id,
  int year,
  int month,
  int day,
  int balance,
) => DashboardBalanceHistoryPoint(
  entryId: id,
  epochDay: _epochDay(year, month, day),
  epochMinute: _epochDay(year, month, day) * 1440,
  incomeTotalMinor: balance,
  expenseTotalMinor: 0,
  balanceMinor: balance,
);

int _epochDay(int year, int month, int day) =>
    DateTime.utc(year, month, day).difference(DateTime.utc(1970)).inDays;
