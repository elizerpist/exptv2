import 'package:flutter/foundation.dart';

import '../data/query_menu_repository.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/query_menu_data.dart';

/// Latest-wins bounded data state for one visible Query Menu draft.
///
/// Draft editing stays synchronous in [QueryComposerController]; this owner
/// only maps a draft to SQL-backed facet/count data and never changes the
/// applied dashboard scope.
final class QueryMenuDataController extends ChangeNotifier {
  QueryMenuDataController({required QueryMenuRepository repository})
    : _repository = repository;

  final QueryMenuRepository _repository;
  int _generation = 0;
  bool _disposed = false;
  bool _isLoading = false;
  CurrentLedgerQueryScope? _lastScope;
  QueryMenuData? _data;
  Object? _error;

  bool get isLoading => _isLoading;
  CurrentLedgerQueryScope? get lastScope => _lastScope;
  QueryMenuData? get data => _data;
  Object? get error => _error;

  Future<void> refresh(CurrentLedgerQueryScope draft) async {
    if (_disposed) return;
    final generation = ++_generation;
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final next = await _repository.readFacets(draft);
      if (_disposed || generation != _generation) return;
      _data = next;
      _lastScope = draft;
    } on Object catch (error) {
      if (_disposed || generation != _generation) return;
      _error = error;
    } finally {
      if (!_disposed && generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
