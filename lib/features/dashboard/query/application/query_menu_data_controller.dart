import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../data/query_menu_repository.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/query_menu_data.dart';

/// How an accepted Query Apply obtained its exact menu presentation.
///
/// The value is deliberately bounded metadata: the shell passes it to the
/// publication owner for diagnostics, while this controller remains the only
/// owner of the SQL-backed facet request itself.
enum QueryFacetPresentationSource { alreadyReady, joinedInFlight, unavailable }

@immutable
final class QueryFacetPresentationResolution {
  const QueryFacetPresentationResolution({
    required this.scope,
    required this.data,
    required this.source,
  });

  final CurrentLedgerQueryScope scope;
  final QueryMenuData? data;
  final QueryFacetPresentationSource source;

  bool get isExact =>
      data != null && source != QueryFacetPresentationSource.unavailable;
}

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
  final Map<String, _QueryFacetRequest> _inFlightByScope =
      <String, _QueryFacetRequest>{};

  bool get isLoading => _isLoading;
  CurrentLedgerQueryScope? get lastScope => _lastScope;
  QueryMenuData? get data => _data;

  /// The last SQL-confirmed count remains present while a newer draft is
  /// loading. Presentation can therefore keep one stable numeric CTA instead
  /// of replacing it with a transient loading label on every discrete edit.
  int? get confirmedEntryCount => _data?.result.entryCount;
  Object? get error => _error;

  /// Returns the one exact presentation request already owned by this menu
  /// controller for [draft]. It never starts a repair request: normal sheet
  /// editing has already called [refresh], and a programmatic caller without
  /// such a request receives the explicit unavailable state instead.
  ///
  /// This lets an accepted Apply join facets and an independently staged
  /// immutable candidate concurrently. It prevents a facet result that
  /// finished before candidate publication from being lost merely because the
  /// Apply tap observed a transient null snapshot.
  Future<QueryFacetPresentationResolution> presentationForAcceptedApply(
    CurrentLedgerQueryScope draft,
  ) async {
    if (_lastScope == draft && _data != null) {
      return QueryFacetPresentationResolution(
        scope: draft,
        data: _data,
        source: QueryFacetPresentationSource.alreadyReady,
      );
    }
    final request = _inFlightByScope[_scopeIdentity(draft)];
    if (request == null || request.scope != draft) {
      return QueryFacetPresentationResolution(
        scope: draft,
        data: null,
        source: QueryFacetPresentationSource.unavailable,
      );
    }
    try {
      return QueryFacetPresentationResolution(
        scope: draft,
        data: await request.future,
        source: QueryFacetPresentationSource.joinedInFlight,
      );
    } on Object {
      return QueryFacetPresentationResolution(
        scope: draft,
        data: null,
        source: QueryFacetPresentationSource.unavailable,
      );
    }
  }

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
      final next = await _requestFor(draft);
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

  Future<QueryMenuData> _requestFor(CurrentLedgerQueryScope draft) {
    final identity = _scopeIdentity(draft);
    final existing = _inFlightByScope[identity];
    if (existing != null && existing.scope == draft) return existing.future;
    final future = _repository.readFacets(draft);
    final request = _QueryFacetRequest(scope: draft, future: future);
    _inFlightByScope[identity] = request;
    future.then<void>(
      (_) => _removeRequest(identity, request),
      onError: (Object error, StackTrace stackTrace) =>
          _removeRequest(identity, request),
    );
    return future;
  }

  void _removeRequest(String identity, _QueryFacetRequest request) {
    if (identical(_inFlightByScope[identity], request)) {
      _inFlightByScope.remove(identity);
    }
  }

  String _scopeIdentity(CurrentLedgerQueryScope scope) =>
      '${scope.direction.name}:${scope.key.value}';
}

final class _QueryFacetRequest {
  const _QueryFacetRequest({required this.scope, required this.future});

  final CurrentLedgerQueryScope scope;
  final Future<QueryMenuData> future;
}
