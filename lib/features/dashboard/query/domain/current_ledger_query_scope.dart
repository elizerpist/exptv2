import '../../time_navigation/domain/ledger_time_scope.dart';
import 'ledger_direction.dart';

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
  }) : categoryIds = Set.unmodifiable(categoryIds),
       partnerIds = Set.unmodifiable(partnerIds),
       refinements = Map.unmodifiable(refinements);

  final LedgerDirection direction;
  final LedgerTimeScope timeScope;
  final Set<String> categoryIds;
  final Set<String> partnerIds;
  final Map<String, Object?> refinements;

  LedgerQueryKey get key => LedgerQueryKey(_canonicalValue);

  String get _canonicalValue {
    final categories = categoryIds.toList()..sort();
    final partners = partnerIds.toList()..sort();
    final refinementEntries = refinements.entries.toList()
      ..sort((left, right) => left.key.compareTo(right.key));
    final refinementValue = refinementEntries
        .map((entry) => '${entry.key}=${entry.value}')
        .join(',');
    return [
      direction.name,
      timeScope.canonicalKey,
      'categories:${categories.join(',')}',
      'partners:${partners.join(',')}',
      'refinements:$refinementValue',
    ].join('|');
  }

  CurrentLedgerQueryScope copyWith({
    LedgerDirection? direction,
    LedgerTimeScope? timeScope,
    Set<String>? categoryIds,
    Set<String>? partnerIds,
    Map<String, Object?>? refinements,
  }) {
    return CurrentLedgerQueryScope(
      direction: direction ?? this.direction,
      timeScope: timeScope ?? this.timeScope,
      categoryIds: categoryIds ?? this.categoryIds,
      partnerIds: partnerIds ?? this.partnerIds,
      refinements: refinements ?? this.refinements,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is CurrentLedgerQueryScope && other.key == key;

  @override
  int get hashCode => key.hashCode;
}
