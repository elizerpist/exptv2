import '../../query/domain/query_temporal_filter.dart';
import 'year_month.dart';

/// Immutable, derived availability for dashboard time navigation.
///
/// It deliberately has no navigation state or controller dependency. A null
/// child collection represents the existing unrestricted/cyclic domain;
/// a concrete collection means the applied Query explicitly limits it.
final class DashboardTemporalAvailability {
  const DashboardTemporalAvailability.unrestricted()
    : _years = null,
      _monthsByYear = const <int, List<int>>{},
      _daysByYearMonth = const <String, List<int>>{};

  DashboardTemporalAvailability._restricted({
    required Iterable<int> years,
    required Map<int, Iterable<int>> monthsByYear,
    required Map<String, Iterable<int>> daysByYearMonth,
  }) : _years = List<int>.unmodifiable(years.toList()..sort()),
       _monthsByYear = Map<int, List<int>>.unmodifiable(<int, List<int>>{
         for (final entry in monthsByYear.entries)
           entry.key: List<int>.unmodifiable(entry.value.toList()..sort()),
       }),
       _daysByYearMonth =
           Map<String, List<int>>.unmodifiable(<String, List<int>>{
             for (final entry in daysByYearMonth.entries)
               entry.key: List<int>.unmodifiable(entry.value.toList()..sort()),
           });

  factory DashboardTemporalAvailability.fromTemporalFilter(
    QueryTemporalFilter filter,
  ) {
    if (!filter.isRestrictive) {
      return const DashboardTemporalAvailability.unrestricted();
    }
    final years = <int>{};
    final monthsByYear = <int, Set<int>>{};
    final daysByYearMonth = <String, Set<int>>{};
    final fullYear = <int>{};
    final fullMonth = <String>{};
    for (final group in filter.groups) {
      for (final selection in group.selections) {
        final parts = selection.value.split('-').map(int.parse).toList();
        final year = parts[0];
        years.add(year);
        switch (selection.kind) {
          case QueryPeriodKind.year:
            fullYear.add(year);
          case QueryPeriodKind.month:
            fullMonth.add(selection.value);
          case QueryPeriodKind.day:
            daysByYearMonth
                .putIfAbsent(selection.value.substring(0, 7), () => <int>{})
                .add(parts[2]);
        }
        if (selection.kind != QueryPeriodKind.year) {
          monthsByYear.putIfAbsent(year, () => <int>{}).add(parts[1]);
        }
      }
    }
    for (final year in fullYear) {
      monthsByYear[year] = <int>{
        for (var month = 1; month <= 12; month++) month,
      };
    }
    for (final key in fullMonth) {
      final parts = key.split('-').map(int.parse).toList();
      monthsByYear.putIfAbsent(parts[0], () => <int>{}).add(parts[1]);
      // OR semantics: an explicit full month makes any same-month day choice
      // redundant rather than accidentally turning that month into a
      // day-restricted rail domain.
      daysByYearMonth.remove(key);
    }
    for (final year in fullYear) {
      // A selected full year similarly dominates any selected day in it.
      daysByYearMonth.removeWhere(
        (key, _) => key.startsWith('${year.toString().padLeft(4, '0')}-'),
      );
    }
    return DashboardTemporalAvailability._restricted(
      years: years,
      monthsByYear: monthsByYear,
      daysByYearMonth: daysByYearMonth,
    );
  }

  final List<int>? _years;
  final Map<int, List<int>> _monthsByYear;
  final Map<String, List<int>> _daysByYearMonth;

  bool get isRestrictive => _years != null;
  List<int>? get allowedYears => _years;

  /// Ordered finite parent domain for month-level navigation. `null` retains
  /// the historical unbounded/cyclic temporal behavior.
  List<YearMonth>? get allowedYearMonths {
    if (_years == null) return null;
    return List<YearMonth>.unmodifiable(<YearMonth>[
      for (final year in _years)
        for (final month in _monthsByYear[year] ?? const <int>[])
          YearMonth(year: year, month: month),
    ]);
  }

  bool allowsYear(int year) => _years == null || _years.contains(year);

  List<int>? monthsForYear(int year) =>
      _years == null ? null : _monthsByYear[year] ?? const <int>[];

  bool allowsMonth(int year, int month) {
    final months = monthsForYear(year);
    return months == null || months.contains(month);
  }

  List<int>? daysForMonth(int year, int month) {
    if (!isRestrictive) return null;
    final months = monthsForYear(year);
    if (months == null || !months.contains(month)) return const <int>[];
    return _daysByYearMonth['${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}'];
  }
}
