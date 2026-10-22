import 'package:flutter/foundation.dart';

import '../prepared/data/dashboard_prepared_formatter.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import 'balance_daily_calculation_mode.dart';
import 'dashboard_balance_presentation.dart';

/// One financial interval from one Core publication. Amount and both bar
/// segments always move together; no linked-card or navigation data is mixed in.
@immutable
final class DashboardBalanceHeaderContextPresentation {
  const DashboardBalanceHeaderContextPresentation({
    required this.timeScope,
    required this.dailyCalculationMode,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
    required this.formattedNetTotal,
    required this.contextLabel,
    required this.scopeKey,
    required this.coreRevision,
    required this.presentationId,
  });

  final LedgerTimeScope timeScope;
  final BalanceDailyCalculationMode dailyCalculationMode;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
  int get netTotalMinor => incomeTotalMinor - expenseTotalMinor;
  final String formattedNetTotal;
  final String contextLabel;
  final String scopeKey;
  final int coreRevision;
  final int presentationId;
}

/// Memoizes the bounded prefix lookup across visual/animation rebuilds.
/// History is already sorted and revision-validated by Core. Each interval
/// lookup is O(log n), including empty days and dates before/after history.
final class DashboardBalanceHeaderContextProjection {
  DashboardBalancePresentation? _source;
  LedgerTimeScope? _scope;
  BalanceDailyCalculationMode? _mode;
  DashboardBalanceHeaderContextPresentation? _value;

  DashboardBalanceHeaderContextPresentation? project({
    required DashboardBalancePresentation? source,
    required LedgerTimeScope fallbackScope,
    required BalanceDailyCalculationMode dailyCalculationMode,
  }) {
    final scope = source?.headerTimeScope ?? fallbackScope;
    if (identical(source, _source) &&
        scope == _scope &&
        dailyCalculationMode == _mode) {
      return _value;
    }
    _source = source;
    _scope = scope;
    _mode = dailyCalculationMode;
    _value = _build(source, scope, dailyCalculationMode);
    return _value;
  }

  static DashboardBalanceHeaderContextPresentation? _build(
    DashboardBalancePresentation? source,
    LedgerTimeScope scope,
    BalanceDailyCalculationMode mode,
  ) {
    if (source == null) return null;
    var income = source.incomeTotalMinor;
    var expense = source.expenseTotalMinor;
    if (scope is! AllTimeScope) {
      final history = source.history;
      // Missing membership is unavailable, never a fabricated zero. A truly
      // empty published universe can safely render an empty interval.
      if (history == null && (income != 0 || expense != 0)) return null;
      if (history != null) {
        final bounds = scope.boundaries!;
        final start = scope is DayScope
            ? (mode == BalanceDailyCalculationMode.monthToDate
                  ? LocalDate(
                      year: scope.date.year,
                      month: scope.date.month,
                      day: 1,
                    ).epochDay
                  : null)
            : bounds.startInclusive.epochDay;
        final end = scope is DayScope
            // Calendar arithmetic, independent of local daylight saving.
            ? scope.date.epochDay + 1
            : bounds.endExclusive.epochDay;
        final endPoint = _before(history.points, end);
        final startPoint = start == null
            ? null
            : _before(history.points, start);
        income =
            (endPoint?.incomeTotalMinor ?? 0) -
            (startPoint?.incomeTotalMinor ?? 0);
        expense =
            (endPoint?.expenseTotalMinor ?? 0) -
            (startPoint?.expenseTotalMinor ?? 0);
      }
    }
    final net = income - expense;
    return DashboardBalanceHeaderContextPresentation(
      timeScope: scope,
      dailyCalculationMode: mode,
      incomeTotalMinor: income,
      expenseTotalMinor: expense,
      formattedNetTotal: scope is AllTimeScope
          ? source.formattedNetTotal
          : '${net > 0 ? '+' : ''}${DashboardPreparedFormatter.amountMinor(net)}',
      contextLabel: _label(scope, mode),
      scopeKey: source.scopeKey,
      coreRevision: source.coreRevision,
      presentationId: Object.hash(
        source.presentationId,
        scope.canonicalKey,
        mode,
      ),
    );
  }

  static DashboardBalanceHistoryPoint? _before(
    List<DashboardBalanceHistoryPoint> points,
    int exclusiveEpochDay,
  ) {
    var low = 0;
    var high = points.length;
    while (low < high) {
      final middle = low + ((high - low) >> 1);
      if (points[middle].epochDay < exclusiveEpochDay) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }
    return low == 0 ? null : points[low - 1];
  }

  static const _months = [
    'január',
    'február',
    'március',
    'április',
    'május',
    'június',
    'július',
    'augusztus',
    'szeptember',
    'október',
    'november',
    'december',
  ];
  static String _label(
    LedgerTimeScope scope,
    BalanceDailyCalculationMode mode,
  ) => switch (scope) {
    AllTimeScope() => 'Összesített nettó',
    YearScope(:final year) => '$year nettója',
    MonthScope(:final value) =>
      '${value.year}. ${_months[value.month - 1]} nettója',
    DayScope(:final date) =>
      mode == BalanceDailyCalculationMode.monthToDate
          ? '${_months[date.month - 1]} 1–${date.day}. nettó'
          : 'Kumulált nettó • ${_months[date.month - 1]} ${date.day}-ig',
  };
}
