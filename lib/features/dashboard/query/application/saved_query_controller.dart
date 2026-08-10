import 'package:flutter/foundation.dart';

import '../data/query_menu_repository.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_menu_data.dart';
import 'query_composer_controller.dart';

/// Direction-affine, Room-backed saved-query list state.
///
/// This controller owns no dashboard query. It only presents persisted named
/// configurations and maps explicit UI actions to the repository boundary.
final class SavedQueryController extends ChangeNotifier {
  SavedQueryController({required QueryMenuRepository repository})
    : _repository = repository;

  final QueryMenuRepository _repository;
  int _generation = 0;
  bool _disposed = false;
  bool _isLoading = false;
  List<SavedLedgerQuery> _savedQueries = const <SavedLedgerQuery>[];
  String? _activeSavedQueryId;
  CurrentLedgerQueryScope? _loadedScope;

  bool get isLoading => _isLoading;
  List<SavedLedgerQuery> get savedQueries => _savedQueries;
  String? get activeSavedQueryId => _activeSavedQueryId;

  bool isDirty(CurrentLedgerQueryScope draft) =>
      _loadedScope != null && draft != _loadedScope;

  Future<void> refresh(LedgerDirection direction) async {
    final generation = ++_generation;
    _isLoading = true;
    notifyListeners();
    try {
      final next = await _repository.listSaved(direction);
      if (_disposed || generation != _generation) return;
      _savedQueries = List.unmodifiable(next);
      if (!_savedQueries.any((entry) => entry.id == _activeSavedQueryId)) {
        _activeSavedQueryId = null;
        _loadedScope = null;
      }
    } finally {
      if (!_disposed && generation == _generation) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<SavedLedgerQuery> loadIntoDraft({
    required String id,
    required QueryComposerController composer,
  }) async {
    final loaded = await _repository.loadSaved(
      id: id,
      activeDirection: composer.draft.direction,
    );
    if (_disposed) return loaded;
    composer.updateDraft(scope: loaded.scope);
    _activeSavedQueryId = loaded.id;
    _loadedScope = loaded.scope;
    _replace(loaded);
    notifyListeners();
    return loaded;
  }

  Future<SavedLedgerQuery> saveAsNew({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) async {
    final saved = await _repository.createSaved(name: name, scope: scope);
    if (_disposed) return saved;
    _activeSavedQueryId = saved.id;
    _loadedScope = saved.scope;
    _savedQueries = List.unmodifiable(<SavedLedgerQuery>[
      saved,
      ..._savedQueries.where((entry) => entry.id != saved.id),
    ]);
    notifyListeners();
    return saved;
  }

  Future<SavedLedgerQuery> updateActive({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) async {
    final id = _activeSavedQueryId;
    if (id == null) {
      throw StateError('No saved Query is active. Use saveAsNew instead.');
    }
    final saved = await _repository.updateSaved(
      id: id,
      name: name,
      scope: scope,
    );
    if (_disposed) return saved;
    _loadedScope = saved.scope;
    _replace(saved);
    notifyListeners();
    return saved;
  }

  Future<SavedLedgerQuery> rename({
    required String id,
    required String name,
  }) async {
    final saved = await _repository.renameSaved(id: id, name: name);
    if (_disposed) return saved;
    _replace(saved);
    notifyListeners();
    return saved;
  }

  Future<void> delete(String id) async {
    await _repository.deleteSaved(id: id);
    if (_disposed) return;
    _savedQueries = List.unmodifiable(
      _savedQueries.where((entry) => entry.id != id),
    );
    if (_activeSavedQueryId == id) {
      _activeSavedQueryId = null;
      _loadedScope = null;
    }
    notifyListeners();
  }

  void _replace(SavedLedgerQuery saved) {
    _savedQueries = List.unmodifiable(<SavedLedgerQuery>[
      for (final entry in _savedQueries)
        if (entry.id == saved.id) saved else entry,
      if (!_savedQueries.any((entry) => entry.id == saved.id)) saved,
    ]);
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    super.dispose();
  }
}
