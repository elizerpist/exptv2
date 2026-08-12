import 'package:flutter/foundation.dart';

import '../domain/dashboard_directional_query_set.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_menu_data.dart';

/// The single owner of the applied dashboard Query Menu configuration.
///
/// Dashboard navigation decorates this immutable scope with its current
/// structural [CurrentLedgerQueryScope.timeScope]; it never becomes a second
/// applied-filter owner.
final class CurrentQueryController extends ChangeNotifier {
  CurrentQueryController({required CurrentLedgerQueryScope initialScope})
    : _queries = DashboardDirectionalQuerySet.fromInitial(initialScope),
      _lastChangedDirection = initialScope.direction;

  DashboardDirectionalQuerySet _queries;
  final Map<LedgerDirection, QueryMenuData?> _facetPresentations =
      <LedgerDirection, QueryMenuData?>{};
  LedgerDirection _lastChangedDirection;
  int _generation = 0;
  final Map<LedgerDirection, int> _directionGenerations =
      <LedgerDirection, int>{
        LedgerDirection.income: 0,
        LedgerDirection.expense: 0,
      };

  DashboardDirectionalQuerySet get queries => _queries;

  /// Temporary compatibility projection for callers that are migrated to
  /// [scopeFor] in the same feature change. It is never direction selection
  /// state; reading another direction does not mutate it.
  CurrentLedgerQueryScope get scope => scopeFor(_lastChangedDirection);

  CurrentLedgerQueryScope scopeFor(LedgerDirection direction) =>
      _queries.scopeFor(direction);

  QueryMenuData? get facetPresentation =>
      facetPresentationFor(_lastChangedDirection);

  QueryMenuData? facetPresentationFor(LedgerDirection direction) =>
      _facetPresentations[direction];

  int get generation => _generation;
  int generationFor(LedgerDirection direction) =>
      _directionGenerations[direction] ?? 0;

  /// Applies one already-canonical immutable scope. Returns false for an
  /// identical request to avoid redundant dashboard rebuilds.
  bool apply(
    CurrentLedgerQueryScope nextScope, {
    QueryMenuData? facetPresentation,
  }) => replaceDirection(
    nextScope.direction,
    nextScope,
    facetPresentation: facetPresentation,
  );

  /// The one applied-query owner changes exactly one direction template at a
  /// time. The other template and its facet presentation remain byte-for-byte
  /// intact, which makes dashboard direction selection a read/activation
  /// operation rather than a Query mutation.
  bool replaceDirection(
    LedgerDirection direction,
    CurrentLedgerQueryScope nextScope, {
    QueryMenuData? facetPresentation,
  }) {
    if (nextScope.direction != direction) {
      throw ArgumentError.value(
        nextScope,
        'nextScope',
        'A directional replacement must retain its target direction.',
      );
    }
    final previousScope = scopeFor(direction);
    final previousPresentation = facetPresentationFor(direction);
    if (nextScope == previousScope && facetPresentation == previousPresentation) {
      return false;
    }
    _queries = _queries.replaceDirection(direction, nextScope);
    _facetPresentations[direction] = facetPresentation;
    _lastChangedDirection = direction;
    _generation += 1;
    _directionGenerations[direction] = generationFor(direction) + 1;
    notifyListeners();
    return true;
  }
}
