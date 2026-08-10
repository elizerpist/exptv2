import 'package:flutter/foundation.dart';

import '../domain/current_ledger_query_scope.dart';
import '../domain/query_menu_data.dart';

/// The single owner of the applied dashboard Query Menu configuration.
///
/// Dashboard navigation decorates this immutable scope with its current
/// structural [CurrentLedgerQueryScope.timeScope]; it never becomes a second
/// applied-filter owner.
final class CurrentQueryController extends ChangeNotifier {
  CurrentQueryController({required CurrentLedgerQueryScope initialScope})
    : _scope = initialScope;

  CurrentLedgerQueryScope _scope;
  QueryMenuData? _facetPresentation;
  int _generation = 0;

  CurrentLedgerQueryScope get scope => _scope;
  QueryMenuData? get facetPresentation => _facetPresentation;
  int get generation => _generation;

  /// Applies one already-canonical immutable scope. Returns false for an
  /// identical request to avoid redundant dashboard rebuilds.
  bool apply(
    CurrentLedgerQueryScope nextScope, {
    QueryMenuData? facetPresentation,
  }) {
    if (nextScope == _scope && facetPresentation == _facetPresentation) {
      return false;
    }
    _scope = nextScope;
    _facetPresentation = facetPresentation;
    _generation += 1;
    notifyListeners();
    return true;
  }
}
