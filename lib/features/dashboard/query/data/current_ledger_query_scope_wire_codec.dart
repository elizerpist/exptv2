import '../domain/current_ledger_query_scope.dart';
import '../domain/dashboard_directional_query_set.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_temporal_filter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';

/// The one Flutter-side wire representation for the typed core Query scope.
///
/// Dashboard paging/index transport and Query Menu snapshot/facet transport
/// share this codec. Widgets never construct platform-channel maps directly.
final class CurrentLedgerQueryScopeWireCodec {
  const CurrentLedgerQueryScopeWireCodec._();

  static Map<String, Object?> encodeFilter(CurrentLedgerQueryScope scope) =>
      <String, Object?>{
        'direction': scope.direction.name,
        'periodGroups': encodeTemporalFilter(scope.temporalFilter),
        'categoryIds': _sorted(scope.categoryIds),
        'partnerIds': _sorted(scope.partnerIds),
        'refinements': scope.refinements,
        // Search is a prepared dashboard overlay rather than a persisted
        // Query Menu field. It intentionally does not cross the platform
        // query boundary as a database predicate.
      };

  static Map<String, Object?> encodeDirectionalFilterSet(
    DashboardDirectionalQuerySet queries,
  ) => <String, Object?>{
    'incomeFilter': encodeFilter(queries.income),
    'expenseFilter': encodeFilter(queries.expense),
  };

  static Map<String, Object?> encodeNavigatedScope(
    CurrentLedgerQueryScope scope,
  ) => <String, Object?>{
    ...encodeFilter(scope),
    'scopeKey': scope.key.value,
    'periodGroups': <Object?>[
      ...encodeTemporalFilter(scope.temporalFilter),
      ...encodeNavigationTime(scope.timeScope),
    ],
  };

  static List<Object?> encodeTemporalFilter(QueryTemporalFilter filter) =>
      filter.groups
          .map(
            (group) => <String, Object?>{
              'key': group.key,
              'selections': group.selections
                  .map(
                    (selection) => <String, Object?>{
                      'kind': selection.kind.name,
                      'value': selection.value,
                    },
                  )
                  .toList(growable: false),
            },
          )
          .toList(growable: false);

  static List<Object?> encodeNavigationTime(LedgerTimeScope scope) {
    final selection = switch (scope) {
      AllTimeScope() => null,
      YearScope(:final year) => <String, Object?>{
        'kind': 'year',
        'value': year.toString().padLeft(4, '0'),
      },
      MonthScope(:final value) => <String, Object?>{
        'kind': 'month',
        'value': value.isoString,
      },
      DayScope(:final date) => <String, Object?>{
        'kind': 'day',
        'value': date.isoString,
      },
    };
    if (selection == null) return const <Object?>[];
    return <Object?>[
      <String, Object?>{
        'key': 'navigation',
        'selections': <Object?>[selection],
      },
    ];
  }

  static CurrentLedgerQueryScope decodeSavedScope(Map<Object?, Object?> raw) {
    final direction = LedgerDirection.values.byName(
      _string(raw['direction'], 'direction'),
    );
    final rawGroups = _list(raw['periodGroups'], 'periodGroups');
    final groups = rawGroups.map((rawGroup) {
      final group = _map(rawGroup, 'period group');
      return QueryPeriodGroup(
        key: _string(group['key'], 'period group key'),
        selections: _list(group['selections'], 'period selections').map((raw) {
          final selection = _map(raw, 'period selection');
          return _selection(
            _string(selection['kind'], 'period kind'),
            _string(selection['value'], 'period value'),
          );
        }),
      );
    });
    final refinements = _map(raw['refinements'], 'refinements');
    return CurrentLedgerQueryScope(
      direction: direction,
      timeScope: const AllTimeScope(),
      temporalFilter: groups.isEmpty
          ? const QueryTemporalFilter.allTime()
          : QueryTemporalFilter(groups: groups),
      categoryIds: _stringSet(raw['categoryIds'], 'categoryIds'),
      partnerIds: _stringSet(raw['partnerIds'], 'partnerIds'),
      refinements: refinements,
    );
  }

  static QueryPeriodSelection _selection(String kind, String value) =>
      switch (QueryPeriodKind.values.byName(kind)) {
        QueryPeriodKind.year => QueryPeriodSelection.year(int.parse(value)),
        QueryPeriodKind.month => _monthSelection(value),
        QueryPeriodKind.day => _daySelection(value),
      };

  static QueryPeriodSelection _monthSelection(String value) {
    final parts = value.split('-').map(int.parse).toList(growable: false);
    return QueryPeriodSelection.month(parts[0], parts[1]);
  }

  static QueryPeriodSelection _daySelection(String value) {
    final parts = value.split('-').map(int.parse).toList(growable: false);
    return QueryPeriodSelection.day(parts[0], parts[1], parts[2]);
  }

  static List<String> _sorted(Iterable<String> values) =>
      values.toList()..sort();

  static Map<String, Object?> _map(Object? value, String label) {
    if (value is! Map) throw FormatException('$label must be a map.');
    return value.map((key, item) => MapEntry(key.toString(), item));
  }

  static List<Object?> _list(Object? value, String label) {
    if (value is! List) throw FormatException('$label must be a list.');
    return List<Object?>.from(value);
  }

  static String _string(Object? value, String label) {
    if (value is! String) throw FormatException('$label must be a string.');
    return value;
  }

  static Set<String> _stringSet(Object? value, String label) =>
      _list(value, label).map((item) => _string(item, label)).toSet();
}
