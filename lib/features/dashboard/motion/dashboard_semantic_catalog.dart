import 'package:flutter/foundation.dart';

import '../../../shared/motion/centered_carousel/centered_carousel_data_source.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../time_navigation/domain/dashboard_temporal_availability.dart';
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
final class DashboardSemanticCatalog
    implements CenteredCarouselDataSource<DashboardSemanticEntry> {
  DashboardSemanticCatalog._({
    required this.parentScope,
    required this.childKind,
    required this.windowIdentity,
    required this.dataMode,
    required List<DashboardSemanticEntry> entries,
  }) : entries = List<DashboardSemanticEntry>.unmodifiable(entries),
       values = List<int>.unmodifiable(entries.map((entry) => entry.value)),
       _entriesByQueryKey =
           Map<LedgerQueryKey, DashboardSemanticEntry>.unmodifiable(
             <LedgerQueryKey, DashboardSemanticEntry>{
               for (final entry in entries) entry.queryKey: entry,
             },
           ),
       _logicalIndexByValue = Map<int, int>.unmodifiable(<int, int>{
         for (final entry in entries) entry.value: entry.logicalIndex,
       }),
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
    DashboardTemporalAvailability availability =
        const DashboardTemporalAvailability.unrestricted(),
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
        allowedYears: availability.allowedYears,
      ),
      (YearScope(:final year), DashboardChildKind.month) => _monthCatalog(
        parentScope,
        year,
        allowedMonths: availability.monthsForYear(year),
      ),
      (MonthScope(:final value), DashboardChildKind.day) => _dayCatalog(
        parentScope,
        value,
        allowedDays: availability.daysForMonth(value.year, value.month),
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
  final CenteredCarouselDataMode dataMode;
  final List<DashboardSemanticEntry> entries;
  final List<int> values;
  final Map<LedgerQueryKey, DashboardSemanticEntry> _entriesByQueryKey;
  final Map<int, int> _logicalIndexByValue;
  final int contentDigest;

  int get length => entries.length;
  bool get isEmpty => entries.isEmpty;

  @override
  CenteredCarouselDataMode get mode => dataMode;

  @override
  int get finiteLength => entries.length;

  @override
  DashboardSemanticEntry itemAtLogicalIndex(int logicalIndex) =>
      entryAtLogicalIndex(logicalIndex);

  DashboardSemanticEntry operator [](int logicalIndex) =>
      entryAtLogicalIndex(logicalIndex);

  DashboardSemanticEntry entryAtLogicalIndex(int logicalIndex) {
    if (mode == CenteredCarouselDataMode.cyclic) {
      final normalized =
          ((logicalIndex % entries.length) + entries.length) % entries.length;
      return entries[normalized];
    }
    if (logicalIndex < 0 || logicalIndex >= entries.length) {
      throw RangeError.index(logicalIndex, entries, 'logicalIndex');
    }
    return entries[logicalIndex];
  }

  DashboardSemanticEntry? entryForQueryKey(LedgerQueryKey queryKey) =>
      _entriesByQueryKey[queryKey];

  int logicalIndexForValue(int value) {
    final index = _logicalIndexByValue[value];
    if (index == null) {
      throw ArgumentError.value(value, 'value', 'is outside the catalog');
    }
    return index;
  }

  static DashboardSemanticCatalog _yearCatalog(
    CurrentLedgerQueryScope parentScope, {
    required int? retainedYear,
    required int radius,
    required List<int>? allowedYears,
  }) {
    if (retainedYear == null) {
      throw ArgumentError.notNull('retainedYear');
    }
    final years =
        allowedYears ??
        List<int>.generate(
          radius * 2 + 1,
          (index) => retainedYear - radius + index,
          growable: false,
        );
    return DashboardSemanticCatalog._(
      parentScope: parentScope,
      childKind: DashboardChildKind.year,
      windowIdentity: allowedYears == null
          ? 'years:${retainedYear - radius}-${retainedYear + radius}'
          : 'years:restricted:${years.join(',')}',
      dataMode: CenteredCarouselDataMode.bounded,
      entries: List<DashboardSemanticEntry>.generate(years.length, (index) {
        final year = years[index];
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
    int year, {
    required List<int>? allowedMonths,
  }) => DashboardSemanticCatalog._(
    parentScope: parentScope,
    childKind: DashboardChildKind.month,
    windowIdentity: allowedMonths == null
        ? 'months:$year'
        : 'months:restricted:$year:${allowedMonths.join(',')}',
    dataMode: allowedMonths == null
        ? CenteredCarouselDataMode.cyclic
        : CenteredCarouselDataMode.bounded,
    entries: List<DashboardSemanticEntry>.generate(
      allowedMonths?.length ?? 12,
      (index) {
        final monthValue = allowedMonths?[index] ?? index + 1;
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
      },
      growable: false,
    ),
  );

  static DashboardSemanticCatalog _dayCatalog(
    CurrentLedgerQueryScope parentScope,
    YearMonth month, {
    required List<int>? allowedDays,
  }) => DashboardSemanticCatalog._(
    parentScope: parentScope,
    childKind: DashboardChildKind.day,
    windowIdentity: allowedDays == null
        ? 'days:${month.isoString}'
        : 'days:restricted:${month.isoString}:${allowedDays.join(',')}',
    dataMode: allowedDays == null
        ? CenteredCarouselDataMode.cyclic
        : CenteredCarouselDataMode.bounded,
    entries: List<DashboardSemanticEntry>.generate(
      allowedDays?.length ?? month.daysInMonth,
      (index) {
        final day = allowedDays?[index] ?? index + 1;
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
      },
      growable: false,
    ),
  );
}
