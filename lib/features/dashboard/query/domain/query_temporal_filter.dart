import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/domain/year_month.dart';

/// Immutable query-time restriction independent from the dashboard's current
/// navigated parent scope. An empty filter means the existing all-time domain.
final class QueryTemporalFilter {
  const QueryTemporalFilter.allTime() : groups = const <QueryPeriodGroup>[];

  QueryTemporalFilter({required Iterable<QueryPeriodGroup> groups})
    : groups = List<QueryPeriodGroup>.unmodifiable(_canonicalGroups(groups)) {
    final keys = this.groups.map((group) => group.key).toSet();
    if (keys.length != this.groups.length) {
      throw ArgumentError.value(groups, 'groups', 'group keys must be unique');
    }
  }

  factory QueryTemporalFilter.periods(
    Iterable<QueryPeriodSelection> selections,
  ) => QueryTemporalFilter(
    groups: <QueryPeriodGroup>[
      QueryPeriodGroup(key: 'time', selections: selections),
    ],
  );

  final List<QueryPeriodGroup> groups;

  bool get isRestrictive => groups.isNotEmpty;

  String get canonicalKey => groups.isEmpty
      ? 'all'
      : groups
            .map((group) => '${group.key}=${group.canonicalSelectionKey}')
            .join(';');

  @override
  bool operator ==(Object other) =>
      other is QueryTemporalFilter && other.canonicalKey == canonicalKey;

  @override
  int get hashCode => canonicalKey.hashCode;

  static List<QueryPeriodGroup> _canonicalGroups(
    Iterable<QueryPeriodGroup> source,
  ) {
    final groups = source.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    return groups;
  }
}

final class QueryPeriodGroup {
  QueryPeriodGroup({
    required this.key,
    required Iterable<QueryPeriodSelection> selections,
  }) : selections = List<QueryPeriodSelection>.unmodifiable(
         _canonicalSelections(selections),
       ) {
    if (key.trim().isEmpty) {
      throw ArgumentError.value(key, 'key', 'must not be blank');
    }
    if (this.selections.isEmpty) {
      throw ArgumentError.value(selections, 'selections', 'must not be empty');
    }
  }

  final String key;
  final List<QueryPeriodSelection> selections;

  String get canonicalSelectionKey =>
      selections.map((selection) => selection.canonicalKey).join(',');

  static List<QueryPeriodSelection> _canonicalSelections(
    Iterable<QueryPeriodSelection> source,
  ) {
    final distinct = <String, QueryPeriodSelection>{
      for (final selection in source) selection.canonicalKey: selection,
    };
    final selections = distinct.values.toList()
      ..sort((left, right) => left.compareTo(right));
    return selections;
  }
}

enum QueryPeriodKind { year, month, day }

final class QueryPeriodSelection implements Comparable<QueryPeriodSelection> {
  const QueryPeriodSelection._(this.kind, this.value);

  factory QueryPeriodSelection.year(int year) {
    if (year < 1 || year > 9999) {
      throw ArgumentError.value(year, 'year');
    }
    return QueryPeriodSelection._(
      QueryPeriodKind.year,
      year.toString().padLeft(4, '0'),
    );
  }

  factory QueryPeriodSelection.month(int year, int month) =>
      QueryPeriodSelection._(
        QueryPeriodKind.month,
        YearMonth(year: year, month: month).isoString,
      );

  factory QueryPeriodSelection.day(int year, int month, int day) =>
      QueryPeriodSelection._(
        QueryPeriodKind.day,
        LocalDate(year: year, month: month, day: day).isoString,
      );

  final QueryPeriodKind kind;
  final String value;

  String get canonicalKey => '${kind.name}:$value';

  @override
  int compareTo(QueryPeriodSelection other) {
    final kindOrder = kind.index.compareTo(other.kind.index);
    return kindOrder == 0 ? value.compareTo(other.value) : kindOrder;
  }

  @override
  bool operator ==(Object other) =>
      other is QueryPeriodSelection && other.canonicalKey == canonicalKey;

  @override
  int get hashCode => canonicalKey.hashCode;
}
