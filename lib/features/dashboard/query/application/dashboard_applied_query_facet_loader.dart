import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../data/query_menu_repository.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import '../domain/query_menu_data.dart';
import 'current_query_controller.dart';

/// Terminal transport state for the canonical applied Query facet request.
///
/// This is deliberately not another Query/domain store. It says whether the
/// one [CurrentQueryController] presentation is pending, ready, or failed for
/// an exact scope so a renderer cannot describe a completed failure as an
/// indefinite loading state.
enum DashboardAppliedQueryFacetLoadState { idle, loading, ready, failed }

/// Loads facet data for the active *applied* Query, independently of whether
/// the Query editor happens to be open.
///
/// [CurrentQueryController] remains the only stored applied-domain authority.
/// This class owns only a latest-wins transport request and publishes a ready
/// immutable result into that controller for its exact directional scope. The
/// Mind host and the Query menu therefore share one accepted amount domain;
/// this is not a Mind-local Query or an amount-range cache.
final class DashboardAppliedQueryFacetLoader extends ChangeNotifier {
  DashboardAppliedQueryFacetLoader({
    required CurrentQueryController currentQuery,
    required Listenable directionChanges,
    required LedgerDirection Function() activeDirection,
    required QueryMenuRepository repository,
  }) : _currentQuery = currentQuery,
       _directionChanges = directionChanges,
       _activeDirection = activeDirection,
       _repository = repository {
    _currentQuery.addListener(_onAppliedQueryChanged);
    _directionChanges.addListener(_onActiveDirectionChanged);
  }

  final CurrentQueryController _currentQuery;
  final Listenable _directionChanges;
  final LedgerDirection Function() _activeDirection;
  final QueryMenuRepository _repository;

  var _started = false;
  var _disposed = false;
  var _generation = 0;
  DashboardAppliedQueryFacetLoadState _state =
      DashboardAppliedQueryFacetLoadState.idle;
  Object? _error;
  CurrentLedgerQueryScope? _stateScope;
  LedgerDirection? _stateDirection;
  var _stateGeneration = 0;
  Future<void>? _activeOperation;
  CurrentLedgerQueryScope? _activeScope;
  LedgerDirection? _activeRequestDirection;

  bool get isLoading => _state == DashboardAppliedQueryFacetLoadState.loading;
  DashboardAppliedQueryFacetLoadState get state => _state;
  Object? get error => _error;
  CurrentLedgerQueryScope? get stateScope => _stateScope;
  LedgerDirection? get stateDirection => _stateDirection;
  int get stateGeneration => _stateGeneration;
  Future<void> get whenIdle => _activeOperation ?? Future<void>.value();

  /// Begins (or joins) the one request needed to give the active applied Query
  /// a canonical facet/domain presentation.
  Future<void> start() {
    _started = true;
    return _ensureActivePresentation(reason: 'start');
  }

  /// A direct user retry after an explicit terminal failure. This starts no
  /// timer and retains the same canonical scope/data authority.
  Future<void> retry() {
    _started = true;
    return _ensureActivePresentation(reason: 'userRetry');
  }

  void _onAppliedQueryChanged() {
    if (!_started) return;
    unawaited(_ensureActivePresentation(reason: 'appliedQueryChanged'));
  }

  void _onActiveDirectionChanged() {
    if (!_started) return;
    unawaited(_ensureActivePresentation(reason: 'activeDirectionChanged'));
  }

  Future<void> _ensureActivePresentation({required String reason}) {
    if (_disposed) return Future<void>.value();
    final direction = _activeDirection();
    final scope = _currentQuery.scopeFor(direction);
    final existing = _currentQuery.facetPresentationFor(direction);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'MIND|RANGE_REQUIRED',
        flowId: 'generation:$_generation',
        queryKey: scope.key.value,
        direction: direction.name,
        scope:
            'reason=$reason requestGeneration=$_generation '
            'currentQueryGeneration=${_currentQuery.generationFor(direction)} '
            'canonicalDomain=${existing == null ? 'absent' : 'present'}',
      ),
    );
    if (existing != null) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|RANGE_CACHE_HIT',
          queryKey: scope.key.value,
          direction: direction.name,
          scope:
              'source=currentQuery reason=$reason '
              'currentQueryGeneration=${_currentQuery.generationFor(direction)} '
              'minimum=${existing.amountDomain.minimumAmountScaled100} '
              'maximum=${existing.amountDomain.maximumAmountScaled100}',
        ),
      );
      _setState(
        DashboardAppliedQueryFacetLoadState.ready,
        scope: scope,
        direction: direction,
        generation: _generation,
        reason: 'canonicalAlreadyReady:$reason',
        data: existing,
      );
      return Future<void>.value();
    }
    final active = _activeOperation;
    if (active != null &&
        _activeScope == scope &&
        _activeRequestDirection == direction) {
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|RANGE_REQUEST_JOIN',
          flowId: 'generation:$_generation',
          queryKey: scope.key.value,
          direction: direction.name,
          scope: 'reason=$reason activeRequest=true',
        ),
      );
      return active;
    }
    final generation = ++_generation;
    _activeScope = scope;
    _activeRequestDirection = direction;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'MIND|RANGE_CACHE_MISS',
        flowId: 'generation:$generation',
        queryKey: scope.key.value,
        direction: direction.name,
        scope: 'source=currentQuery reason=$reason canonicalDomain=absent',
      ),
    );
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'MIND|RANGE_REQUEST',
        flowId: 'generation:$generation',
        queryKey: scope.key.value,
        direction: direction.name,
        scope:
            'source=appliedQueryFacetLoader reason=$reason '
            'currentQueryGeneration=${_currentQuery.generationFor(direction)}',
      ),
    );
    _setState(
      DashboardAppliedQueryFacetLoadState.loading,
      scope: scope,
      direction: direction,
      generation: generation,
      reason: 'requestStarted:$reason',
    );
    late final Future<void> operation;
    operation =
        _load(
          generation: generation,
          direction: direction,
          scope: scope,
        ).whenComplete(() {
          if (identical(_activeOperation, operation)) {
            _activeOperation = null;
            _activeScope = null;
            _activeRequestDirection = null;
          }
        });
    _activeOperation = operation;
    return operation;
  }

  Future<void> _load({
    required int generation,
    required LedgerDirection direction,
    required CurrentLedgerQueryScope scope,
  }) async {
    final timer = Stopwatch()..start();
    try {
      final data = await _repository.readFacets(scope);
      timer.stop();
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|RANGE_RESULT',
          flowId: 'generation:$generation',
          queryKey: scope.key.value,
          direction: direction.name,
          durationMs: timer.elapsedMilliseconds,
          scope:
              'status=success minimum=${data.amountDomain.minimumAmountScaled100} '
              'maximum=${data.amountDomain.maximumAmountScaled100} '
              'entryCount=${data.result.entryCount}',
        ),
      );
      if (_disposed ||
          generation != _generation ||
          _activeDirection() != direction ||
          _currentQuery.scopeFor(direction) != scope ||
          _currentQuery.facetPresentationFor(direction) != null) {
        final rejectionReason = _disposed
            ? 'disposed'
            : generation != _generation
            ? 'superseded'
            : _activeDirection() != direction
            ? 'directionChanged'
            : _currentQuery.scopeFor(direction) != scope
            ? 'scopeChanged'
            : 'canonicalAlreadyReady';
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'MIND|RANGE_REJECT',
            flowId: 'generation:$generation',
            queryKey: scope.key.value,
            direction: direction.name,
            durationMs: timer.elapsedMilliseconds,
            scope: 'reason=$rejectionReason',
          ),
        );
        return;
      }
      final published = _currentQuery.replaceDirection(
        direction,
        scope,
        facetPresentation: data,
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|RANGE_PUBLISH',
          flowId: 'generation:$generation',
          queryKey: scope.key.value,
          direction: direction.name,
          durationMs: timer.elapsedMilliseconds,
          scope:
              'accepted=$published source=repository '
              'currentQueryGeneration=${_currentQuery.generationFor(direction)} '
              'minimum=${data.amountDomain.minimumAmountScaled100} '
              'maximum=${data.amountDomain.maximumAmountScaled100} '
              'entryCount=${data.result.entryCount}',
        ),
      );
      if (published || _currentQuery.facetPresentationFor(direction) != null) {
        _setState(
          DashboardAppliedQueryFacetLoadState.ready,
          scope: scope,
          direction: direction,
          generation: generation,
          reason: 'published',
          data: data,
        );
      } else {
        _setState(
          DashboardAppliedQueryFacetLoadState.failed,
          scope: scope,
          direction: direction,
          generation: generation,
          reason: 'publicationRejected',
          error: StateError('Mind range publication was not accepted.'),
        );
      }
    } on Object catch (error) {
      timer.stop();
      if (!_disposed && generation == _generation) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'MIND|RANGE_RESULT',
            flowId: 'generation:$generation',
            queryKey: scope.key.value,
            direction: direction.name,
            durationMs: timer.elapsedMilliseconds,
            scope: 'status=failure',
            error: '$error',
          ),
        );
        _setState(
          DashboardAppliedQueryFacetLoadState.failed,
          scope: scope,
          direction: direction,
          generation: generation,
          reason: 'requestFailed',
          error: error,
        );
      }
    }
  }

  void _setState(
    DashboardAppliedQueryFacetLoadState next, {
    required CurrentLedgerQueryScope scope,
    required LedgerDirection direction,
    required int generation,
    required String reason,
    QueryMenuData? data,
    Object? error,
  }) {
    final changed =
        _state != next ||
        _stateScope != scope ||
        _stateDirection != direction ||
        _stateGeneration != generation ||
        _error != error;
    _state = next;
    _stateScope = scope;
    _stateDirection = direction;
    _stateGeneration = generation;
    _error = error;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'MIND|RANGE_STATE',
        flowId: 'generation:$generation',
        queryKey: scope.key.value,
        direction: direction.name,
        scope:
            'state=${next.name} reason=$reason '
            'loading=${next == DashboardAppliedQueryFacetLoadState.loading} '
            'minimum=${data?.amountDomain.minimumAmountScaled100 ?? '-'} '
            'maximum=${data?.amountDomain.maximumAmountScaled100 ?? '-'} '
            'currentQueryGeneration=${_currentQuery.generationFor(direction)}',
        error: error == null ? null : '$error',
      ),
    );
    if (changed) notifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    _generation += 1;
    _currentQuery.removeListener(_onAppliedQueryChanged);
    _directionChanges.removeListener(_onActiveDirectionChanged);
    super.dispose();
  }
}
