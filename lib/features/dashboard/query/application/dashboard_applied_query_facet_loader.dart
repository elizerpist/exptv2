import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../data/query_menu_repository.dart';
import '../domain/current_ledger_query_scope.dart';
import '../domain/ledger_direction.dart';
import 'current_query_controller.dart';

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
  var _isLoading = false;
  Future<void>? _activeOperation;
  CurrentLedgerQueryScope? _activeScope;
  LedgerDirection? _activeRequestDirection;

  bool get isLoading => _isLoading;
  Future<void> get whenIdle => _activeOperation ?? Future<void>.value();

  /// Begins (or joins) the one request needed to give the active applied Query
  /// a canonical facet/domain presentation.
  Future<void> start() {
    _started = true;
    return _ensureActivePresentation(reason: 'start');
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
    if (existing != null) {
      _setLoading(false);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND_SLIDER_DOMAIN_READY',
          queryKey: scope.key.value,
          direction: direction.name,
          scope:
              'source=currentQuery reason=$reason '
              'minimum=${existing.amountDomain.minimumAmountScaled100} '
              'maximum=${existing.amountDomain.maximumAmountScaled100}',
        ),
      );
      return Future<void>.value();
    }
    final active = _activeOperation;
    if (active != null &&
        _activeScope == scope &&
        _activeRequestDirection == direction) {
      return active;
    }
    final generation = ++_generation;
    _activeScope = scope;
    _activeRequestDirection = direction;
    _setLoading(true);
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'MIND_SLIDER_DOMAIN_REQUESTED',
        flowId: 'generation:$generation',
        queryKey: scope.key.value,
        direction: direction.name,
        scope: 'source=appliedQueryFacetLoader reason=$reason',
      ),
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
      if (_disposed ||
          generation != _generation ||
          _activeDirection() != direction ||
          _currentQuery.scopeFor(direction) != scope ||
          _currentQuery.facetPresentationFor(direction) != null) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'MIND_SLIDER_DOMAIN_DROPPED',
            flowId: 'generation:$generation',
            queryKey: scope.key.value,
            direction: direction.name,
            durationMs: timer.elapsedMilliseconds,
            scope:
                'reason=${_disposed
                    ? 'disposed'
                    : generation != _generation
                    ? 'superseded'
                    : _activeDirection() != direction
                    ? 'directionChanged'
                    : _currentQuery.scopeFor(direction) != scope
                    ? 'scopeChanged'
                    : 'canonicalAlreadyReady'}',
          ),
        );
        return;
      }
      _currentQuery.replaceDirection(direction, scope, facetPresentation: data);
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND_SLIDER_DOMAIN_READY',
          flowId: 'generation:$generation',
          queryKey: scope.key.value,
          direction: direction.name,
          durationMs: timer.elapsedMilliseconds,
          scope:
              'source=repository minimum=${data.amountDomain.minimumAmountScaled100} '
              'maximum=${data.amountDomain.maximumAmountScaled100} '
              'entryCount=${data.result.entryCount}',
        ),
      );
    } on Object catch (error) {
      timer.stop();
      if (!_disposed && generation == _generation) {
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'MIND_SLIDER_DOMAIN_FAILED',
            flowId: 'generation:$generation',
            queryKey: scope.key.value,
            direction: direction.name,
            durationMs: timer.elapsedMilliseconds,
            error: '$error',
          ),
        );
      }
    } finally {
      if (!_disposed && generation == _generation) _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
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
