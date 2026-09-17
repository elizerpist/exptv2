import 'package:flutter/foundation.dart';

import '../domain/dashboard_directional_query_set.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_amount_range.dart';
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
  final Map<CurrentLedgerQueryScope, _AmountDomainBinding> _amountDomains =
      <CurrentLedgerQueryScope, _AmountDomainBinding>{};
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

  /// Returns the amount domain for [scope]'s exact non-amount identity.
  ///
  /// The applied query templates intentionally remain non-temporal.  Mind's
  /// physical range, however, is observed through the currently visible
  /// structural time scope, so callers that render Mind must use this method
  /// rather than accidentally falling back to an all-time template maximum.
  QueryMenuAmountDomain? amountDomainForScope(CurrentLedgerQueryScope scope) {
    final domainScope = QueryAmountRange.domainScope(scope);
    return _amountDomains[domainScope]?.domain;
  }

  /// Compatibility access for consumers whose canonical scope is the stored
  /// non-temporal template (for example the Query Menu itself).
  QueryMenuAmountDomain? amountDomainFor(LedgerDirection direction) =>
      amountDomainForScope(scopeFor(direction));

  /// Publishes the native facet/domain result for an already-visible scope
  /// without mutating the stored applied Query template.  Structural time is
  /// owned by DashboardNavigation, not by this controller.
  bool publishAmountDomainForScope(
    CurrentLedgerQueryScope scope,
    QueryMenuAmountDomain domain,
  ) {
    final domainScope = QueryAmountRange.domainScope(scope);
    final binding = _AmountDomainBinding(scope: domainScope, domain: domain);
    if (_amountDomains[domainScope] == binding) return false;
    _amountDomains[domainScope] = binding;
    notifyListeners();
    return true;
  }

  /// Publishes a complete native facet result.  The compact Mind control can
  /// also receive its already-prepared amount domain through
  /// [publishAmountDomainForScope] while the rest of Query Menu data remains
  /// owned by its native facet loader.
  bool publishFacetPresentationForScope(
    CurrentLedgerQueryScope scope,
    QueryMenuData data,
  ) {
    final direction = scope.direction;
    final domainScope = QueryAmountRange.domainScope(scope);
    final binding = _AmountDomainBinding(
      scope: domainScope,
      domain: data.amountDomain,
    );
    if (identical(_facetPresentations[direction], data) &&
        _amountDomains[domainScope] == binding) {
      return false;
    }
    _facetPresentations[direction] = data;
    _amountDomains[domainScope] = binding;
    notifyListeners();
    return true;
  }

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
    final previousDomain =
        _amountDomains[QueryAmountRange.domainScope(previousScope)];
    // A renderer-side temporary facet gap is not a new applied Query result.
    // Keep the exact QueryMenuData that was accepted for this unchanged scope
    // so every host retains the same canonical amount domain until a new
    // semantic scope supplies its own presentation.
    final nextPresentation =
        facetPresentation ??
        (nextScope == previousScope ? previousPresentation : null);
    final domainScope = QueryAmountRange.domainScope(nextScope);
    final nextDomain = facetPresentation != null
        ? _AmountDomainBinding(
            scope: domainScope,
            domain: facetPresentation.amountDomain,
          )
        : previousDomain?.scope == domainScope
        ? previousDomain
        : null;
    if (nextScope == previousScope &&
        nextPresentation == previousPresentation &&
        nextDomain == previousDomain) {
      return false;
    }
    _queries = _queries.replaceDirection(direction, nextScope);
    _facetPresentations[direction] = nextPresentation;
    if (!QueryAmountRange.hasSameDomainIdentity(previousScope, nextScope)) {
      _amountDomains.removeWhere((scope, _) => scope.direction == direction);
    }
    if (nextDomain != null) {
      _amountDomains[domainScope] = nextDomain;
    }
    _lastChangedDirection = direction;
    _generation += 1;
    _directionGenerations[direction] = generationFor(direction) + 1;
    notifyListeners();
    return true;
  }
}

@immutable
final class _AmountDomainBinding {
  const _AmountDomainBinding({required this.scope, required this.domain});

  final CurrentLedgerQueryScope scope;
  final QueryMenuAmountDomain domain;

  @override
  bool operator ==(Object other) =>
      other is _AmountDomainBinding &&
      other.scope == scope &&
      identical(other.domain, domain);

  @override
  int get hashCode => Object.hash(scope, identityHashCode(domain));
}
