import '../../time_navigation/domain/ledger_time_scope.dart';
import 'ledger_direction.dart';
import 'query_temporal_filter.dart';

class LedgerQueryKey {
  const LedgerQueryKey(this.value);

  final String value;

  @override
  bool operator ==(Object other) =>
      other is LedgerQueryKey && other.value == value;

  @override
  int get hashCode => value.hashCode;

  @override
  String toString() => value;
}

class CurrentLedgerQueryScope {
  CurrentLedgerQueryScope({
    required this.direction,
    required this.timeScope,
    Set<String> categoryIds = const <String>{},
    Set<String> partnerIds = const <String>{},
    Map<String, Object?> refinements = const <String, Object?>{},
    this.normalizedSearch,
    this.temporalFilter = const QueryTemporalFilter.allTime(),
  }) : categoryIds = Set.unmodifiable(categoryIds),
       partnerIds = Set.unmodifiable(partnerIds),
       refinements = Map.unmodifiable(refinements);

  final LedgerDirection direction;
  final LedgerTimeScope timeScope;
  final Set<String> categoryIds;
  final Set<String> partnerIds;
  final Map<String, Object?> refinements;

  /// Dashboard-local interactive search overlay. It is part of the immutable
  /// prepared projection identity, but deliberately not a committed Query
  /// Menu/Room filter: the prepared membership seed evaluates it in RAM.
  final String? normalizedSearch;

  /// Applied Query Menu time selection. [timeScope] remains the dashboard's
  /// current structural parent/child navigation scope.
  final QueryTemporalFilter temporalFilter;

  /// Canonical identity is computed once for this immutable scope.
  ///
  /// The string construction and sorting semantics are unchanged; retaining
  /// the object removes repeated sorting/allocation from memory lookup paths.
  late final LedgerQueryKey key = LedgerQueryKey(_canonicalValue);

  String get _canonicalValue {
    final categories = categoryIds.toList()..sort();
    final partners = partnerIds.toList()..sort();
    final refinementEntries = refinements.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final refinementValue = refinementEntries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(',');
    final values = [
      direction.name,
      timeScope.canonicalKey,
      'categories:${categories.join(',')}',
      'partners:${partners.join(',')}',
      'refinements:$refinementValue',
    ];
    // Preserve every pre-Search canonical key byte-for-byte. A non-empty
    // prepared-only search facet still gets its own immutable projection key,
    // while unfiltered scene/cache identities retain their established route.
    final search = normalizedSearch;
    if (search != null) values.add('search:$search');
    if (temporalFilter.isRestrictive) {
      values.add('periods:${temporalFilter.canonicalKey}');
    }
    return values.join('|');
  }

  CurrentLedgerQueryScope copyWith({
    LedgerDirection? direction,
    LedgerTimeScope? timeScope,
    Set<String>? categoryIds,
    Set<String>? partnerIds,
    Map<String, Object?>? refinements,
    String? normalizedSearch,
    bool clearNormalizedSearch = false,
    QueryTemporalFilter? temporalFilter,
  }) {
    return CurrentLedgerQueryScope(
      direction: direction ?? this.direction,
      timeScope: timeScope ?? this.timeScope,
      categoryIds: categoryIds ?? this.categoryIds,
      partnerIds: partnerIds ?? this.partnerIds,
      refinements: refinements ?? this.refinements,
      normalizedSearch: clearNormalizedSearch
          ? null
          : normalizedSearch ?? this.normalizedSearch,
      temporalFilter: temporalFilter ?? this.temporalFilter,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CurrentLedgerQueryScope && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
