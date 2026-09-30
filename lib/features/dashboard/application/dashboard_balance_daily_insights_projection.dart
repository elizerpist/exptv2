import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../query/data/dashboard_ledger_entry.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import 'dashboard_balance_primary_identity.dart';

/// The four semantic locations of the Napi 4 financial coordinate system.
///
/// The coordinate convention is intentionally explicit: income growth moves
/// upward, while expense growth moves rightward.
enum DashboardBalanceDailyMomentumQuadrant {
  stableBuilding('Stabil építkezés', 'Biztonságos alapok'),
  growth('Növekedés', 'Lehetőségek és fejlődés'),
  caution('Óvatosság szükséges', 'Megfontolt lépések'),
  attention('Figyelem szükséges', 'Optimalizálási lehetőség');

  const DashboardBalanceDailyMomentumQuadrant(this.label, this.detail);

  final String label;
  final String detail;
}

/// One endpoint of the same rolling 30-versus-previous-30 calculation used by
/// both the coordinate marker and the lower 60-cell rhythm strip.
@immutable
final class DashboardBalanceDailyMomentumPoint {
  const DashboardBalanceDailyMomentumPoint({
    required this.epochDay,
    required this.currentIncomeMinor,
    required this.referenceIncomeMinor,
    required this.currentExpenseMinor,
    required this.referenceExpenseMinor,
    required this.isCurrentHalf,
    required this.incomeAxis,
    required this.expenseAxis,
    required this.magnitude,
  });

  final int epochDay;
  final int currentIncomeMinor;
  final int referenceIncomeMinor;
  final int currentExpenseMinor;
  final int referenceExpenseMinor;
  final bool isCurrentHalf;

  /// Signed, visible-range-normalised values used directly by the renderer.
  final double incomeAxis;
  final double expenseAxis;

  /// Euclidean magnitude in [0, 1], also derived from these same axes.
  final double magnitude;

  int get incomeChangeMinor => currentIncomeMinor - referenceIncomeMinor;
  int get expenseChangeMinor => currentExpenseMinor - referenceExpenseMinor;

  DashboardBalanceDailyMomentumQuadrant get quadrant {
    if (incomeChangeMinor >= 0) {
      return expenseChangeMinor >= 0
          ? DashboardBalanceDailyMomentumQuadrant.growth
          : DashboardBalanceDailyMomentumQuadrant.stableBuilding;
    }
    return expenseChangeMinor >= 0
        ? DashboardBalanceDailyMomentumQuadrant.attention
        : DashboardBalanceDailyMomentumQuadrant.caution;
  }
}

@immutable
final class DashboardBalanceDailyMomentumPresentation {
  DashboardBalanceDailyMomentumPresentation({
    required this.available,
    required this.selected,
    required List<DashboardBalanceDailyMomentumPoint> rhythm,
  }) : rhythm = List<DashboardBalanceDailyMomentumPoint>.unmodifiable(rhythm);

  factory DashboardBalanceDailyMomentumPresentation.unavailable({
    required int selectedEpochDay,
  }) => DashboardBalanceDailyMomentumPresentation(
    available: false,
    selected: DashboardBalanceDailyMomentumPoint(
      epochDay: selectedEpochDay,
      currentIncomeMinor: 0,
      referenceIncomeMinor: 0,
      currentExpenseMinor: 0,
      referenceExpenseMinor: 0,
      isCurrentHalf: true,
      incomeAxis: 0,
      expenseAxis: 0,
      magnitude: 0,
    ),
    rhythm: const <DashboardBalanceDailyMomentumPoint>[],
  );

  final bool available;
  final DashboardBalanceDailyMomentumPoint selected;
  final List<DashboardBalanceDailyMomentumPoint> rhythm;
}

/// Expense-only Napi hatás payload. Support net values remain explicitly
/// separate so they can never leak into the impact calculation.
@immutable
final class DashboardBalanceDailyImpactPresentation {
  const DashboardBalanceDailyImpactPresentation({
    required this.available,
    required this.previousSevenExpenseMinor,
    required this.currentSevenExpenseMinor,
    required this.valuePercent,
    required this.scaleExtentPercent,
    required this.markerFraction,
    required this.overflow,
    required this.todayNetMinor,
    required this.referenceAverageNetMinor,
  });

  factory DashboardBalanceDailyImpactPresentation.unavailable({
    required int todayNetMinor,
    required int referenceAverageNetMinor,
  }) => DashboardBalanceDailyImpactPresentation(
    available: false,
    previousSevenExpenseMinor: 0,
    currentSevenExpenseMinor: 0,
    valuePercent: null,
    scaleExtentPercent: 10,
    markerFraction: .5,
    overflow: false,
    todayNetMinor: todayNetMinor,
    referenceAverageNetMinor: referenceAverageNetMinor,
  );

  final bool available;
  final int previousSevenExpenseMinor;
  final int currentSevenExpenseMinor;
  final double? valuePercent;
  final int scaleExtentPercent;

  /// 0 is the lower end of the visible tube, .5 is zero, 1 is the upper end.
  final double markerFraction;
  final bool overflow;
  final int todayNetMinor;
  final int referenceAverageNetMinor;

  bool get isWorsening => (valuePercent ?? 0) < 0;
  bool get isImproving => (valuePercent ?? 0) > 0;
}

/// The one immutable Napi 4 read model owned by Dashboard Core.
@immutable
final class DashboardBalanceDailyInsightsPresentation {
  DashboardBalanceDailyInsightsPresentation({
    required this.identity,
    required this.timeScope,
    required this.momentum,
    required this.impact,
  }) : presentationId = Object.hash(
         identity,
         timeScope.canonicalKey,
         momentum.available,
         impact.valuePercent,
         Object.hashAll(
           momentum.rhythm.map(
             (point) => Object.hash(
               point.epochDay,
               point.incomeChangeMinor,
               point.expenseChangeMinor,
             ),
           ),
         ),
       );

  final DashboardBalancePrimaryIdentity identity;
  final LedgerTimeScope timeScope;
  final DashboardBalanceDailyMomentumPresentation momentum;
  final DashboardBalanceDailyImpactPresentation impact;
  final int presentationId;

  factory DashboardBalanceDailyInsightsPresentation.unavailable({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
  }) => DashboardBalanceDailyInsightsPresentation(
    identity: identity,
    timeScope: timeScope,
    momentum: DashboardBalanceDailyMomentumPresentation.unavailable(
      selectedEpochDay: switch (timeScope) {
        DayScope(:final date) => date.epochDay,
        _ => 0,
      },
    ),
    impact: DashboardBalanceDailyImpactPresentation.unavailable(
      todayNetMinor: 0,
      referenceAverageNetMinor: 0,
    ),
  );
}

/// Pure domain projection for the Napi 4 coordinate, impact scale and rhythm.
/// It receives only resident ledger rows and builds one daily aggregation core
/// before deriving every visible chart from it.
abstract final class DashboardBalanceDailyInsightsProjection {
  static DashboardBalanceDailyInsightsPresentation build({
    required DashboardBalancePrimaryIdentity identity,
    required LedgerTimeScope timeScope,
    required LocalDate logicalAsOfDate,
    required int logicalAsOfLocalTimeMinutes,
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
  }) {
    final selectedEpochDay = switch (timeScope) {
      DayScope(:final date) => date.epochDay,
      _ => null,
    };
    if (selectedEpochDay == null) {
      final momentum = DashboardBalanceDailyMomentumPresentation.unavailable(
        selectedEpochDay: logicalAsOfDate.epochDay,
      );
      return DashboardBalanceDailyInsightsPresentation(
        identity: identity,
        timeScope: timeScope,
        momentum: momentum,
        impact: DashboardBalanceDailyImpactPresentation.unavailable(
          todayNetMinor: 0,
          referenceAverageNetMinor: 0,
        ),
      );
    }
    final series = _DailyBalanceSeries.fromEntries(
      incomeEntries: incomeEntries,
      expenseEntries: expenseEntries,
      asOfEpochDay: logicalAsOfDate.epochDay,
      asOfMinute: logicalAsOfLocalTimeMinutes,
    );
    return DashboardBalanceDailyInsightsPresentation(
      identity: identity,
      timeScope: timeScope,
      momentum: _momentum(series, selectedEpochDay),
      impact: _impact(series, selectedEpochDay),
    );
  }

  static DashboardBalanceDailyMomentumPresentation _momentum(
    _DailyBalanceSeries series,
    int selectedEpochDay,
  ) {
    final earliest = series.earliestEpochDay;
    if (earliest == null || earliest > selectedEpochDay - 118) {
      return DashboardBalanceDailyMomentumPresentation.unavailable(
        selectedEpochDay: selectedEpochDay,
      );
    }
    final raw = <_RawMomentumPoint>[
      for (var offset = -59; offset <= 0; offset += 1)
        _rawMomentum(series, selectedEpochDay + offset),
    ];
    final incomeExtent = raw.fold<int>(
      0,
      (extent, point) => math.max(extent, point.incomeChangeMinor.abs()),
    );
    final expenseExtent = raw.fold<int>(
      0,
      (extent, point) => math.max(extent, point.expenseChangeMinor.abs()),
    );
    final points = <DashboardBalanceDailyMomentumPoint>[
      for (var index = 0; index < raw.length; index += 1)
        DashboardBalanceDailyMomentumPoint(
          epochDay: raw[index].epochDay,
          currentIncomeMinor: raw[index].currentIncomeMinor,
          referenceIncomeMinor: raw[index].referenceIncomeMinor,
          currentExpenseMinor: raw[index].currentExpenseMinor,
          referenceExpenseMinor: raw[index].referenceExpenseMinor,
          isCurrentHalf: index >= 30,
          incomeAxis: incomeExtent == 0
              ? 0
              : raw[index].incomeChangeMinor / incomeExtent,
          expenseAxis: expenseExtent == 0
              ? 0
              : raw[index].expenseChangeMinor / expenseExtent,
          magnitude: _magnitude(
            incomeExtent == 0 ? 0 : raw[index].incomeChangeMinor / incomeExtent,
            expenseExtent == 0
                ? 0
                : raw[index].expenseChangeMinor / expenseExtent,
          ),
        ),
    ];
    return DashboardBalanceDailyMomentumPresentation(
      available: true,
      selected: points.last,
      rhythm: points,
    );
  }

  static _RawMomentumPoint _rawMomentum(
    _DailyBalanceSeries series,
    int endpointEpochDay,
  ) => _RawMomentumPoint(
    epochDay: endpointEpochDay,
    currentIncomeMinor: series.sumIncome(
      endpointEpochDay - 29,
      endpointEpochDay,
      terminalForCutoff: endpointEpochDay,
    ),
    referenceIncomeMinor: series.sumIncome(
      endpointEpochDay - 59,
      endpointEpochDay - 30,
      terminalForCutoff: endpointEpochDay,
    ),
    currentExpenseMinor: series.sumExpense(
      endpointEpochDay - 29,
      endpointEpochDay,
      terminalForCutoff: endpointEpochDay,
    ),
    referenceExpenseMinor: series.sumExpense(
      endpointEpochDay - 59,
      endpointEpochDay - 30,
      terminalForCutoff: endpointEpochDay,
    ),
  );

  static DashboardBalanceDailyImpactPresentation _impact(
    _DailyBalanceSeries series,
    int selectedEpochDay,
  ) {
    final todayNet =
        series.incomeForDay(selectedEpochDay) -
        series.expenseForDay(selectedEpochDay);
    final referenceAverageNet =
        series.netSum(selectedEpochDay - 7, selectedEpochDay - 1) ~/ 7;
    final previous = series.sumExpense(
      selectedEpochDay - 7,
      selectedEpochDay - 1,
    );
    final current = series.sumExpense(selectedEpochDay - 6, selectedEpochDay);
    if (previous == 0) {
      return DashboardBalanceDailyImpactPresentation.unavailable(
        todayNetMinor: todayNet,
        referenceAverageNetMinor: referenceAverageNet,
      );
    }
    final value = (previous - current) / previous * 100;
    final historical = <double>[
      for (
        var endpoint = selectedEpochDay - 30;
        endpoint <= selectedEpochDay - 1;
        endpoint += 1
      )
        if (_impactForEndpoint(series, endpoint) case final impact?)
          impact.abs(),
    ];
    final rawExtent = historical.isEmpty ? 0.0 : _percentile(historical, .95);
    final extent = math.max(10, (rawExtent / 5).ceil() * 5);
    final normalised = value / extent;
    return DashboardBalanceDailyImpactPresentation(
      available: true,
      previousSevenExpenseMinor: previous,
      currentSevenExpenseMinor: current,
      valuePercent: value,
      scaleExtentPercent: extent,
      markerFraction: (.5 + normalised / 2).clamp(0.0, 1.0),
      overflow: normalised.abs() > 1,
      todayNetMinor: todayNet,
      referenceAverageNetMinor: referenceAverageNet,
    );
  }

  static double? _impactForEndpoint(_DailyBalanceSeries series, int endpoint) {
    final previous = series.sumExpense(endpoint - 7, endpoint - 1);
    if (previous == 0) return null;
    final current = series.sumExpense(endpoint - 6, endpoint);
    return (previous - current) / previous * 100;
  }

  static double _percentile(List<double> values, double percentile) {
    final sorted = values.toList()..sort();
    final position = (sorted.length - 1) * percentile;
    final lower = position.floor();
    final upper = position.ceil();
    if (lower == upper) return sorted[lower];
    return sorted[lower] + (sorted[upper] - sorted[lower]) * (position - lower);
  }

  static double _magnitude(double incomeAxis, double expenseAxis) =>
      (math.sqrt(incomeAxis * incomeAxis + expenseAxis * expenseAxis) /
              math.sqrt2)
          .clamp(0.0, 1.0);
}

@immutable
final class _RawMomentumPoint {
  const _RawMomentumPoint({
    required this.epochDay,
    required this.currentIncomeMinor,
    required this.referenceIncomeMinor,
    required this.currentExpenseMinor,
    required this.referenceExpenseMinor,
  });

  final int epochDay;
  final int currentIncomeMinor;
  final int referenceIncomeMinor;
  final int currentExpenseMinor;
  final int referenceExpenseMinor;

  int get incomeChangeMinor => currentIncomeMinor - referenceIncomeMinor;
  int get expenseChangeMinor => currentExpenseMinor - referenceExpenseMinor;
}

/// Compact index with full-day values plus a matched logical-as-of variant for
/// exactly the two Napi 4 momentum terminal days.
final class _DailyBalanceSeries {
  _DailyBalanceSeries({
    required this.fullIncome,
    required this.fullExpense,
    required this.cutoffIncome,
    required this.cutoffExpense,
    required this.asOfEpochDay,
  });

  factory _DailyBalanceSeries.fromEntries({
    required Iterable<DashboardLedgerEntry> incomeEntries,
    required Iterable<DashboardLedgerEntry> expenseEntries,
    required int asOfEpochDay,
    required int asOfMinute,
  }) {
    final fullIncome = <int, int>{};
    final fullExpense = <int, int>{};
    final cutoffIncome = <int, int>{};
    final cutoffExpense = <int, int>{};
    void add(
      Iterable<DashboardLedgerEntry> entries,
      Map<int, int> full,
      Map<int, int> cutoff,
    ) {
      for (final entry in entries) {
        final amount = entry.amountMinor.abs();
        full.update(
          entry.bookedLocalEpochDay,
          (value) => value + amount,
          ifAbsent: () => amount,
        );
        if ((entry.bookedLocalEpochDay == asOfEpochDay ||
                entry.bookedLocalEpochDay == asOfEpochDay - 30) &&
            entry.bookedLocalTimeMinutes <= asOfMinute) {
          cutoff.update(
            entry.bookedLocalEpochDay,
            (value) => value + amount,
            ifAbsent: () => amount,
          );
        }
      }
    }

    add(incomeEntries, fullIncome, cutoffIncome);
    add(expenseEntries, fullExpense, cutoffExpense);
    return _DailyBalanceSeries(
      fullIncome: Map<int, int>.unmodifiable(fullIncome),
      fullExpense: Map<int, int>.unmodifiable(fullExpense),
      cutoffIncome: Map<int, int>.unmodifiable(cutoffIncome),
      cutoffExpense: Map<int, int>.unmodifiable(cutoffExpense),
      asOfEpochDay: asOfEpochDay,
    );
  }

  final Map<int, int> fullIncome;
  final Map<int, int> fullExpense;
  final Map<int, int> cutoffIncome;
  final Map<int, int> cutoffExpense;
  final int asOfEpochDay;

  int? get earliestEpochDay {
    final keys = <int>[...fullIncome.keys, ...fullExpense.keys];
    if (keys.isEmpty) return null;
    return keys.reduce(math.min);
  }

  int incomeForDay(int epochDay) => fullIncome[epochDay] ?? 0;
  int expenseForDay(int epochDay) => fullExpense[epochDay] ?? 0;

  int sumIncome(int start, int end, {int? terminalForCutoff}) => _sum(
    fullIncome,
    cutoffIncome,
    start,
    end,
    terminalForCutoff: terminalForCutoff,
  );

  int sumExpense(int start, int end, {int? terminalForCutoff}) => _sum(
    fullExpense,
    cutoffExpense,
    start,
    end,
    terminalForCutoff: terminalForCutoff,
  );

  int netSum(int start, int end) =>
      sumIncome(start, end) - sumExpense(start, end);

  int _sum(
    Map<int, int> full,
    Map<int, int> cutoff,
    int start,
    int end, {
    int? terminalForCutoff,
  }) {
    var total = 0;
    for (var day = start; day <= end; day += 1) {
      final terminal = terminalForCutoff;
      final usesCutoff =
          terminal != null &&
          terminal == asOfEpochDay &&
          (day == terminal || day == terminal - 30);
      total += usesCutoff ? (cutoff[day] ?? 0) : (full[day] ?? 0);
    }
    return total;
  }
}
