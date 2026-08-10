import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
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
    final timer = Stopwatch()..start();
    _isLoading = true;
    _error = null;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'QUERY_FACETS_REQUESTED',
        flowId: 'generation:$generation',
        queryKey: draft.key.value,
        direction: draft.direction.name,
        scope:
            'temporalFilter=${draft.temporalFilter.canonicalKey} '
            'categories=${draft.categoryIds.length} '
            'partners=${draft.partnerIds.length}',
      ),
    );
    notifyListeners();
    try {
      final next = await _repository.readFacets(draft);
      if (_disposed || generation != _generation) return;
      _data = next;
      _lastScope = draft;
      timer.stop();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_FACETS_READY',
          flowId: 'generation:$generation',
          queryKey: draft.key.value,
          direction: draft.direction.name,
          entryCount: next.result.entryCount,
          durationMs: timer.elapsed.inMilliseconds,
          scope:
              'categories=${next.categories.length} '
              'partners=${next.partners.length} '
              'availableMonths=${next.availableMonths.length}',
        ),
      );
    } on Object catch (error) {
      if (_disposed || generation != _generation) return;
      _error = error;
      timer.stop();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'QUERY_FACETS_FAILED',
          flowId: 'generation:$generation',
          queryKey: draft.key.value,
          direction: draft.direction.name,
          durationMs: timer.elapsed.inMilliseconds,
          error: '$error',
        ),
      );
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
