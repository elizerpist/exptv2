import 'package:flutter/foundation.dart';

import '../query/domain/current_ledger_query_scope.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/local_date.dart';
import '../time_navigation/domain/year_month.dart';
import '../time_navigation/presentation/time_label_formatter.dart';

enum DashboardChildKind { year, month, day }

@immutable
final class DashboardSemanticEntry {
  const DashboardSemanticEntry({
    required this.logicalIndex,
    required this.value,
    required this.label,
    required this.semanticLabel,
    required this.childKind,
    required this.scope,
    required this.queryKey,
  });

  final int logicalIndex;
  final int value;
  final String label;
  final String semanticLabel;
  final DashboardChildKind childKind;
  final CurrentLedgerQueryScope scope;
  final LedgerQueryKey queryKey;

  String get semanticIdentity => '${childKind.name}:$value:${queryKey.value}';
}

/// Immutable semantic data installed before a rail can start moving.
///
/// Both logical-index and QueryKey selection are direct list/map lookups. No
/// scope construction, canonical sorting or label formatting occurs in the
/// crossing path.
@immutable
final class DashboardSemanticCatalog {
  DashboardSemanticCatalog._({
    required this.parentScope,
    required this.childKind,
    required this.windowIdentity,
    required List<DashboardSemanticEntry> entries,
  }) : entries = List<DashboardSemanticEntry>.unmodifiable(entries),
       values = List<int>.unmodifiable(entries.map((entry) => entry.value)),
       _entriesByQueryKey =
           Map<LedgerQueryKey, DashboardSemanticEntry>.unmodifiable(
             <LedgerQueryKey, DashboardSemanticEntry>{
               for (final entry in entries) entry.queryKey: entry,
             },
           ),
       contentDigest = Object.hashAll(
         entries.map(
           (entry) => Object.hash(entry.logicalIndex, entry.queryKey),
         ),
       );

  factory DashboardSemanticCatalog.forParent({
    required CurrentLedgerQueryScope parentScope,
    required DashboardChildKind childKind,
    int? retainedYear,
    int yearWindowRadius = 12,
  }) {
    if (yearWindowRadius < 1) {
      throw ArgumentError.value(
        yearWindowRadius,
        'yearWindowRadius',
        'must be positive',
      );
    }
    final parent = parentScope.timeScope;
    return switch ((parent, childKind)) {
      (AllTimeScope(), DashboardChildKind.year) => _yearCatalog(
        parentScope,
        retainedYear: retainedYear,
        radius: yearWindowRadius,
      ),
      (YearScope(:final year), DashboardChildKind.month) => _monthCatalog(
        parentScope,
        year,
      ),
      (MonthScope(:final value), DashboardChildKind.day) => _dayCatalog(
        parentScope,
        value,
      ),
      _ => throw ArgumentError(
        'Child kind ${childKind.name} is incompatible with '
        '${parent.canonicalKey}.',
      ),
    };
  }

  final CurrentLedgerQueryScope parentScope;
  final DashboardChildKind childKind;
  final String windowIdentity;
  final List<DashboardSemanticEntry> entries;
  final List<int> values;
  final Map<LedgerQueryKey, DashboardSemanticEntry> _entriesByQueryKey;
  final int contentDigest;

  int get length => entries.length;
  bool get isEmpty => entries.isEmpty;

  DashboardSemanticEntry operator [](int logicalIndex) =>
      entryAtLogicalIndex(logicalIndex);

  DashboardSemanticEntry entryAtLogicalIndex(int logicalIndex) {
    if (logicalIndex < 0 || logicalIndex >= entries.length) {
      throw RangeError.index(logicalIndex, entries, 'logicalIndex');
    }
    return entries[logicalIndex];
  }

  DashboardSemanticEntry? entryForQueryKey(LedgerQueryKey queryKey) =>
      _entriesByQueryKey[queryKey];

  int logicalIndexForValue(int value) {
    final firstValue = entries.first.value;
    final index = value - firstValue;
    if (index < 0 || index >= entries.length || entries[index].value != value) {
      throw ArgumentError.value(value, 'value', 'is outside the catalog');
    }
    return index;
  }

  static DashboardSemanticCatalog _yearCatalog(
    CurrentLedgerQueryScope parentScope, {
    required int? retainedYear,
    required int radius,
  }) {
    if (retainedYear == null) {
      throw ArgumentError.notNull('retainedYear');
    }
    final firstYear = retainedYear - radius;
    final lastYear = retainedYear + radius;
    return DashboardSemanticCatalog._(
      parentScope: parentScope,
      childKind: DashboardChildKind.year,
      windowIdentity: 'years:$firstYear-$lastYear',
      entries: List<DashboardSemanticEntry>.generate(lastYear - firstYear + 1, (
        index,
      ) {
        final year = firstYear + index;
        final scope = parentScope.copyWith(timeScope: YearScope(year));
        return DashboardSemanticEntry(
          logicalIndex: index,
          value: year,
          label: '$year',
          semanticLabel: 'Év $year',
          childKind: DashboardChildKind.year,
          scope: scope,
          queryKey: scope.key,
        );
      }, growable: false),
    );
  }

  static DashboardSemanticCatalog _monthCatalog(
    CurrentLedgerQueryScope parentScope,
    int year,
  ) => DashboardSemanticCatalog._(
    parentScope: parentScope,
    childKind: DashboardChildKind.month,
    windowIdentity: 'months:$year',
    entries: List<DashboardSemanticEntry>.generate(12, (index) {
      final monthValue = index + 1;
      final month = YearMonth(year: year, month: monthValue);
      final scope = parentScope.copyWith(timeScope: MonthScope(month));
      final label = DashboardTimeLabelFormatter.monthName(monthValue);
      return DashboardSemanticEntry(
        logicalIndex: index,
        value: monthValue,
        label: label,
        semanticLabel: 'Hónap $label',
        childKind: DashboardChildKind.month,
        scope: scope,
        queryKey: scope.key,
      );
    }, growable: false),
  );

  static DashboardSemanticCatalog _dayCatalog(
    CurrentLedgerQueryScope parentScope,
    YearMonth month,
  ) => DashboardSemanticCatalog._(
    parentScope: parentScope,
    childKind: DashboardChildKind.day,
    windowIdentity: 'days:${month.isoString}',
    entries: List<DashboardSemanticEntry>.generate(month.daysInMonth, (index) {
      final day = index + 1;
      final scope = parentScope.copyWith(
        timeScope: DayScope(
          LocalDate(year: month.year, month: month.month, day: day),
        ),
      );
      return DashboardSemanticEntry(
        logicalIndex: index,
        value: day,
        label: '$day',
        semanticLabel: 'Nap $day',
        childKind: DashboardChildKind.day,
        scope: scope,
        queryKey: scope.key,
      );
    }, growable: false),
  );
}
