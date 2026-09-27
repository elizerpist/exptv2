import 'package:flutter/foundation.dart';

import '../../application/dashboard_balance_category_movers_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

/// Shared render-only labels for the immutable Movers payload. No formatter
/// here has access to ledger, Query, current time, or a widget state owner.
String balanceCategoryMoverPercentageLabel(
  DashboardBalanceCategoryMover mover,
) {
  if (mover.isNew) return 'Új';
  final basisPoints = mover.percentageBasisPoints;
  if (basisPoints == null) return '0%';
  final rounded = (basisPoints / 100).round();
  return '${rounded > 0 ? '+' : ''}$rounded%';
}

String balanceCategoryMoverSignedAmountLabel(int amountMinor) =>
    '${amountMinor < 0 ? '-' : '+'}'
    '${DashboardPreparedFormatter.amountMinor(amountMinor.abs())}';

String balanceCategoryMoverCompactAmountLabel(int amountMinor) =>
    DashboardPreparedFormatter.compactAmountMinor(amountMinor);

/// Compact scope copy for the shared Page 1/Page 2 top-right heading.
String balanceCategoryMoverScopeLabel(
  DashboardBalanceCategoryMoversPresentation presentation,
) {
  final current = presentation.currentWindow;
  return switch (presentation.timeScope) {
    MonthScope() =>
      '${DashboardTimeLabelFormatter.shortMonthName(current.startInclusive.month).toUpperCase()} ${current.startInclusive.year}',
    YearScope() || AllTimeScope() when _isCompleteCalendarYear(current) =>
      '${current.startInclusive.year}',
    YearScope() || AllTimeScope() => '${current.startInclusive.year} YTD',
    DayScope() =>
      '${DashboardTimeLabelFormatter.shortMonthName(current.startInclusive.month).toUpperCase()} ${current.startInclusive.day}. ${current.startInclusive.year}',
  };
}

/// Exact, localized window copy for the selected-period KPI. It is based on
/// actual endpoints rather than the current date or a fixture month name.
String balanceCategoryMoverWindowLabel(
  DashboardBalanceCategoryComparisonWindow window,
) {
  final start = window.startInclusive;
  final end = window.endInclusive;
  if (start == end) return _fullDate(start);
  if (start.year == end.year && start.month == end.month) {
    return '${start.year}. ${_shortMonth(start.month)} ${start.day}–${end.day}.';
  }
  if (start.year == end.year) {
    return '${start.year}. ${_shortMonth(start.month)} ${start.day}–${_shortMonth(end.month)} ${end.day}.';
  }
  return '${_fullDate(start)} – ${_fullDate(end)}';
}

@immutable
final class BalanceCategoryMoverLegendLabels {
  const BalanceCategoryMoverLegendLabels({
    required this.current,
    required this.reference,
  });

  final String current;
  final String reference;
}

/// Legend wording resolves from the presentation's canonical comparison
/// windows. It deliberately has no static fixture-period assumption.
BalanceCategoryMoverLegendLabels balanceCategoryMoverLegendLabels(
  DashboardBalanceCategoryMoversPresentation presentation,
) {
  final current = presentation.currentWindow;
  final reference = presentation.referenceWindow;
  return switch (presentation.timeScope) {
    MonthScope()
        when _isCompleteCalendarMonth(current) &&
            _isCompleteCalendarMonth(reference) =>
      BalanceCategoryMoverLegendLabels(
        current:
            '${_capitalizedMonth(current.startInclusive.month)} ${current.startInclusive.year}',
        reference:
            '${_capitalizedMonth(reference.startInclusive.month)} ${reference.startInclusive.year}',
      ),
    MonthScope() => BalanceCategoryMoverLegendLabels(
      current: _shortRangeWithoutRepeatedYear(current),
      reference: _shortRangeWithoutRepeatedYear(reference),
    ),
    YearScope() || AllTimeScope()
        when _isCompleteCalendarYear(current) &&
            _isCompleteCalendarYear(reference) =>
      BalanceCategoryMoverLegendLabels(
        current: '${current.startInclusive.year}',
        reference: '${reference.startInclusive.year}',
      ),
    YearScope() || AllTimeScope() => BalanceCategoryMoverLegendLabels(
      current: '${current.startInclusive.year} YTD',
      reference: '${reference.startInclusive.year} azonos időszak',
    ),
    DayScope() => BalanceCategoryMoverLegendLabels(
      current: balanceCategoryMoverWindowLabel(current),
      reference: balanceCategoryMoverWindowLabel(reference),
    ),
  };
}

@immutable
final class BalanceCategoryMoverCumulativeSeries {
  BalanceCategoryMoverCumulativeSeries({
    required List<int> currentMinor,
    required List<int> referenceMinor,
  }) : currentMinor = List<int>.unmodifiable(currentMinor),
       referenceMinor = List<int>.unmodifiable(referenceMinor);

  final List<int> currentMinor;
  final List<int> referenceMinor;

  int get currentTotalMinor => currentMinor.isEmpty ? 0 : currentMinor.last;
  int get referenceTotalMinor =>
      referenceMinor.isEmpty ? 0 : referenceMinor.last;
}

/// Converts published bucket amounts into bounded cumulative render values
/// before the painter receives them.
BalanceCategoryMoverCumulativeSeries balanceCategoryMoverCumulativeSeries(
  Iterable<DashboardBalanceCategoryMoverTrendPoint> trend,
) {
  var currentTotal = 0;
  var referenceTotal = 0;
  final current = <int>[];
  final reference = <int>[];
  for (final point in trend) {
    currentTotal += point.currentMinor;
    referenceTotal += point.referenceMinor;
    current.add(currentTotal);
    reference.add(referenceTotal);
  }
  return BalanceCategoryMoverCumulativeSeries(
    currentMinor: current,
    referenceMinor: reference,
  );
}

/// Axis labels are derived once from the same true current window that owns
/// the trend buckets. The painter receives strings, never dates or money.
List<String> balanceCategoryMoverChartXAxisLabels({
  required DashboardBalanceCategoryMoversPresentation presentation,
  required int bucketCount,
}) {
  if (bucketCount <= 0) return const <String>[];
  final start = presentation.currentWindow.startInclusive;
  return List<String>.unmodifiable(
    List<String>.generate(bucketCount, (index) {
      return switch (presentation.timeScope) {
        AllTimeScope() ||
        YearScope() => DashboardTimeLabelFormatter.shortMonthName(
          ((start.month - 1 + index) % 12) + 1,
        ),
        MonthScope() => '${start.day + index}.',
        DayScope() => '${start.day}.',
      };
    }),
  );
}

String _shortRangeWithoutRepeatedYear(
  DashboardBalanceCategoryComparisonWindow window,
) {
  final start = window.startInclusive;
  final end = window.endInclusive;
  if (start == end) return _fullDate(start);
  if (start.month == end.month && start.year == end.year) {
    return '${_capitalizedShortMonth(start.month)} ${start.day}–${end.day}.';
  }
  return balanceCategoryMoverWindowLabel(window);
}

bool _isCompleteCalendarMonth(
  DashboardBalanceCategoryComparisonWindow window,
) =>
    window.startInclusive.day == 1 &&
    window.startInclusive.year == window.endInclusive.year &&
    window.startInclusive.month == window.endInclusive.month &&
    window.endInclusive.day ==
        _daysInMonth(window.endInclusive.year, window.endInclusive.month);

bool _isCompleteCalendarYear(DashboardBalanceCategoryComparisonWindow window) =>
    window.startInclusive.month == 1 &&
    window.startInclusive.day == 1 &&
    window.endInclusive.month == 12 &&
    window.endInclusive.day == 31 &&
    window.startInclusive.year == window.endInclusive.year;

String _fullDate(LocalDate date) =>
    '${date.year}. ${_shortMonth(date.month)} ${date.day}.';

String _shortMonth(int month) =>
    '${DashboardTimeLabelFormatter.shortMonthName(month)}.';

String _capitalizedShortMonth(int month) {
  final value = DashboardTimeLabelFormatter.shortMonthName(month);
  return '${value[0].toUpperCase()}${value.substring(1)}.';
}

String _capitalizedMonth(int month) {
  final value = DashboardTimeLabelFormatter.monthName(month);
  return '${value[0].toUpperCase()}${value.substring(1)}';
}

int _daysInMonth(int year, int month) => DateTime.utc(year, month + 1, 0).day;
