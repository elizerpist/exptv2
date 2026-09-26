import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_history_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test(
    'Balance presentation settings retain chart/time choices and independently own Balance card presentation alternatives',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(controller.value.chartMode, BalanceHeaderChartMode.allTime);
      expect(controller.value.timeLabels, BalanceHeaderChartTimeLabels.visible);
      expect(
        controller.value.latestTransactionCardPresentation,
        BalanceLatestTransactionCardPresentation.avatarPartner,
      );
      expect(controller.value.balanceCarouselBorderEnabled, isTrue);
      expect(controller.value.balanceCarouselBorderOpacity, 1);
      expect(controller.value.balanceCarouselWaveOpacity, 1);
      expect(controller.value.balanceCarouselTintedBackgroundEnabled, isTrue);
      expect(controller.value.balanceContentCardBorderOpacity, 1);
      controller
        ..setChartMode(BalanceHeaderChartMode.adaptiveSummary)
        ..setTimeLabels(BalanceHeaderChartTimeLabels.hidden)
        ..setLatestTransactionCardPresentation(
          BalanceLatestTransactionCardPresentation.threeLine,
        )
        ..setBalanceCarouselBorderEnabled(false)
        ..setBalanceCarouselBorderOpacity(.42)
        ..setBalanceCarouselWaveOpacity(.61)
        ..setBalanceCarouselTintedBackgroundEnabled(false)
        ..setBalanceContentCardBorderOpacity(.27);
      expect(
        controller.value.chartMode,
        BalanceHeaderChartMode.adaptiveSummary,
      );
      expect(controller.value.timeLabels, BalanceHeaderChartTimeLabels.hidden);
      expect(
        controller.value.latestTransactionCardPresentation,
        BalanceLatestTransactionCardPresentation.threeLine,
      );
      expect(controller.value.balanceCarouselBorderEnabled, isFalse);
      expect(
        controller.value.balanceCarouselBorderOpacity,
        .42,
        reason:
            'Disabling the outline must preserve the independently chosen opacity.',
      );
      expect(controller.value.balanceCarouselWaveOpacity, .61);
      expect(controller.value.balanceCarouselTintedBackgroundEnabled, isFalse);
      expect(controller.value.balanceContentCardBorderOpacity, .27);
      expect(controller.value.revision, 8);

      final unchangedRevision = controller.value.revision;
      controller.setLatestTransactionCardPresentation(
        BalanceLatestTransactionCardPresentation.threeLine,
      );
      expect(controller.value.revision, unchangedRevision);
      expect(
        controller.value.copyWith(),
        controller.value,
        reason: 'The render-only setting participates in value identity.',
      );
    },
  );

  test(
    'Balance visual customization clamps only its opacity writer and preserves every sibling setting',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      controller
        ..setBalanceCarouselBorderOpacity(-.2)
        ..setBalanceCarouselWaveOpacity(1.4)
        ..setBalanceContentCardBorderOpacity(.5);

      expect(controller.value.balanceCarouselBorderOpacity, 0);
      expect(controller.value.balanceCarouselWaveOpacity, 1);
      expect(controller.value.balanceContentCardBorderOpacity, .5);
      expect(controller.value.balanceCarouselBorderEnabled, isTrue);
      expect(controller.value.balanceCarouselTintedBackgroundEnabled, isTrue);

      final revision = controller.value.revision;
      controller
        ..setBalanceCarouselBorderOpacity(0)
        ..setBalanceCarouselWaveOpacity(1)
        ..setBalanceContentCardBorderOpacity(.5);
      expect(controller.value.revision, revision);
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

  test(
    'COMPOUND-RED: fourth mode selects closing trend by Summary dimension',
    () {
      final history = DashboardBalanceHistorySeries(
        startInclusiveEpochMinute: _epochDay(2024, 1, 2) * 1440,
        endInclusiveEpochMinute: _epochDay(2026, 4, 2) * 1440,
        points: <DashboardBalanceHistoryPoint>[
          _point('2024-salary', 2024, 1, 2, 1000),
          _point('2024-expense', 2024, 1, 18, 700),
          _point('2024-feb', 2024, 2, 8, 1200),
          _point('2025-salary', 2025, 1, 4, 2200),
          _point('2025-expense', 2025, 1, 22, 1800),
          _point('2026-salary', 2026, 1, 3, 3000),
          _point('2026-feb', 2026, 2, 12, 2700),
          _point('2026-mar', 2026, 3, 6, 3400),
          _point('partial-april', 2026, 4, 2, 3300),
        ],
      );

      expect(BalanceHeaderChartMode.values, hasLength(4));
      expect(BalanceHeaderChartMode.compound.tunerLabel, 'Compound');

      final sum = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const AllTimeScope(),
      )!;
      expect(
        sum.points.map((point) => point.entryId),
        everyElement(startsWith('month-close:')),
      );
      expect(sum.points.map((point) => point.epochDay), <int>[
        _epochDay(2024, 1, 31),
        _epochDay(2024, 2, 29),
        _epochDay(2024, 3, 31),
        _epochDay(2024, 4, 30),
        _epochDay(2024, 5, 31),
        _epochDay(2024, 6, 30),
        _epochDay(2024, 7, 31),
        _epochDay(2024, 8, 31),
        _epochDay(2024, 9, 30),
        _epochDay(2024, 10, 31),
        _epochDay(2024, 11, 30),
        _epochDay(2024, 12, 31),
        _epochDay(2025, 1, 31),
        _epochDay(2025, 2, 28),
        _epochDay(2025, 3, 31),
        _epochDay(2025, 4, 30),
        _epochDay(2025, 5, 31),
        _epochDay(2025, 6, 30),
        _epochDay(2025, 7, 31),
        _epochDay(2025, 8, 31),
        _epochDay(2025, 9, 30),
        _epochDay(2025, 10, 31),
        _epochDay(2025, 11, 30),
        _epochDay(2025, 12, 31),
        _epochDay(2026, 1, 31),
        _epochDay(2026, 2, 28),
        _epochDay(2026, 3, 31),
      ]);

      final year = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const YearScope(2026),
      )!;
      expect(year.points.map((point) => point.epochDay), <int>[
        _epochDay(2026, 1, 31),
        _epochDay(2026, 2, 28),
        _epochDay(2026, 3, 31),
      ]);
      expect(
        year.points.first.balanceMinor,
        3000,
        reason: 'January must keep absolute Balance, not reset to zero.',
      );

      final month = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const MonthScope(YearMonth(year: 2025, month: 1)),
      )!;
      expect(month.points.map((point) => point.entryId), <String>[
        '2025-salary',
        '2025-expense',
      ]);
      expect(month.points.map((point) => point.balanceMinor), <int>[
        2200,
        1800,
      ]);

      final day = DashboardBalanceHistoryViewProjection.project(
        source: history,
        mode: BalanceHeaderChartMode.compound,
        adaptiveScope: const DayScope(LocalDate(year: 2025, month: 1, day: 4)),
      )!;
      expect(day.points.single.entryId, '2025-salary');
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
