import 'dart:collection';

import 'package:flutter/foundation.dart';

import '../data/dashboard_prepared_deck_repository.dart';
import '../domain/dashboard_prepared_deck.dart';
import 'dashboard_prepared_deck_cache.dart';

@immutable
final class DashboardPreparedState {
  factory DashboardPreparedState({
    required Iterable<DashboardPreparedDeckKey> cachedKeys,
    required Iterable<DashboardPreparedDeckKey> inFlightKeys,
    required int? coreRevision,
    required bool seedGateOpen,
    required bool interactionActive,
    required int preparationGeneration,
  }) => DashboardPreparedState._(
    cachedKeys: Set<DashboardPreparedDeckKey>.unmodifiable(cachedKeys),
    inFlightKeys: Set<DashboardPreparedDeckKey>.unmodifiable(inFlightKeys),
    coreRevision: coreRevision,
    seedGateOpen: seedGateOpen,
    interactionActive: interactionActive,
    preparationGeneration: preparationGeneration,
  );

  const DashboardPreparedState._({
    required this.cachedKeys,
    required this.inFlightKeys,
    required this.coreRevision,
    required this.seedGateOpen,
    required this.interactionActive,
    required this.preparationGeneration,
  });

  final Set<DashboardPreparedDeckKey> cachedKeys;
  final Set<DashboardPreparedDeckKey> inFlightKeys;
  final int? coreRevision;
  final bool seedGateOpen;
  final bool interactionActive;
  final int preparationGeneration;
}

final class DashboardPreparationDiscarded implements Exception {
  const DashboardPreparationDiscarded(this.reason);

  final String reason;

  @override
  String toString() => 'DashboardPreparationDiscarded($reason)';
}

final class DashboardPreparedDeckPipeline {
  DashboardPreparedDeckPipeline({
    required DashboardPreparedDeckRepository repository,
    required this.cache,
  }) : _repository = repository;

  final DashboardPreparedDeckRepository _repository;
  final DashboardPreparedDeckCache cache;
  final LinkedHashMap<DashboardPreparedDeckKey, _InFlightPreparation>
  _inFlight = LinkedHashMap<DashboardPreparedDeckKey, _InFlightPreparation>();

  bool _seedGateOpen = false;
  bool _interactionActive = false;
  int? _coreRevision;
  int _preparationGeneration = 0;

  int discardedCompletionCount = 0;
  int suppressedPrewarmCount = 0;
  int preparationStartedCount = 0;
  int preparationReadyCount = 0;
  int preparationFailureCount = 0;

  int get inFlightCount => _inFlight.length;

  DashboardPreparedState get state => DashboardPreparedState(
    cachedKeys: cache.keys,
    inFlightKeys: _inFlight.keys,
    coreRevision: _coreRevision,
    seedGateOpen: _seedGateOpen,
    interactionActive: _interactionActive,
    preparationGeneration: _preparationGeneration,
  );

  DashboardPreparedDeckLookup lookup(DashboardPreparedDeckKey key) {
    if (!_seedGateOpen ||
        key.coreRevision <= 0 ||
        key.coreRevision != _coreRevision) {
      return const DashboardPreparedDeckLookup.miss();
    }
    return cache.lookup(key);
  }

  Future<DashboardPreparedDeck> prepareRequired(
    DashboardPreparedDeckRequest request,
  ) {
    try {
      _validateRequest(request);
    } catch (error, stackTrace) {
      return Future<DashboardPreparedDeck>.error(error, stackTrace);
    }

    final cached = cache.lookup(request.key).deck;
    if (cached != null) return Future<DashboardPreparedDeck>.value(cached);

    final existing = _inFlight[request.key];
    if (existing != null && !existing.token.isCancelled) {
      existing.token.promoteToRequired();
      return existing.future;
    }
    if (existing != null) _inFlight.remove(request.key);
    return _start(request, required: true);
  }

  Future<void> prewarm(DashboardPreparedDeckRequest request) {
    if (_interactionActive) {
      suppressedPrewarmCount += 1;
      return Future<void>.value();
    }
    try {
      _validateRequest(request);
    } catch (error, stackTrace) {
      return Future<void>.error(error, stackTrace);
    }

    if (cache.lookup(request.key).deck != null) return Future<void>.value();
    final existing = _inFlight[request.key];
    final future = existing?.future ?? _start(request, required: false);
    return future.then<void>(
      (_) {},
      onError: (Object error, StackTrace stackTrace) {
        if (error is! DashboardPreparationDiscarded) {
          preparationFailureCount += 1;
        }
      },
    );
  }

  void setInteractionActive(bool active) {
    if (_interactionActive == active) return;
    _interactionActive = active;
    if (!active) return;
    for (final operation in _inFlight.values) {
      if (!operation.token.isRequired) operation.token.cancel();
    }
  }

  void acceptCoreRevision(int revision) {
    if (revision <= 0) {
      throw ArgumentError.value(revision, 'revision', 'must be positive');
    }
    if (_coreRevision == revision) return;
    _coreRevision = revision;
    _preparationGeneration += 1;
    for (final operation in _inFlight.values) {
      operation.token.cancel();
    }
    _inFlight.clear();
    cache.retainOnlyRevision(revision);
  }

  void openSeedGate() => _seedGateOpen = true;

  void closeSeedGate() {
    if (!_seedGateOpen) return;
    _seedGateOpen = false;
    _preparationGeneration += 1;
    for (final operation in _inFlight.values) {
      operation.token.cancel();
    }
    _inFlight.clear();
    cache.clear();
  }

  Future<DashboardPreparedDeck> _start(
    DashboardPreparedDeckRequest request, {
    required bool required,
  }) {
    final token = DashboardPreparationToken(
      generation: ++_preparationGeneration,
      required: required,
    );
    preparationStartedCount += 1;
    late final _InFlightPreparation operation;
    final rawFuture = Future<DashboardPreparedDeck>.sync(
      () => _repository.prepareDeck(request, token),
    );
    final future = () async {
      try {
        final deck = await rawFuture;
        if (token.isCancelled ||
            !_seedGateOpen ||
            token.generation != operation.token.generation ||
            request.key.coreRevision != _coreRevision ||
            deck.key != request.key ||
            deck.coreRevision != _coreRevision ||
            !deck.isComplete) {
          discardedCompletionCount += 1;
          throw const DashboardPreparationDiscarded('stale-or-inexact');
        }
        cache.store(deck);
        preparationReadyCount += 1;
        return deck;
      } finally {
        if (identical(_inFlight[request.key], operation)) {
          _inFlight.remove(request.key);
        }
      }
    }();
    operation = _InFlightPreparation(token: token, future: future);
    _inFlight[request.key] = operation;
    return future;
  }

  void _validateRequest(DashboardPreparedDeckRequest request) {
    if (!_seedGateOpen) throw StateError('Dashboard seed gate is closed.');
    final revision = _coreRevision;
    if (revision == null || revision <= 0) {
      throw StateError('No committed nonzero core revision is available.');
    }
    if (request.key.coreRevision <= 0 || request.key.coreRevision != revision) {
      throw StateError('Prepared request revision is not current.');
    }
    if (request.key.parentQueryKey != request.parentScope.key ||
        request.key.parentQueryKey != request.semanticCatalog.parentScope.key ||
        request.key.childKind != request.semanticCatalog.childKind ||
        request.key.semanticWindowIdentity !=
            request.semanticCatalog.windowIdentity) {
      throw StateError('Prepared request identity is inconsistent.');
    }
  }
}

final class _InFlightPreparation {
  const _InFlightPreparation({required this.token, required this.future});

  final DashboardPreparationToken token;
  final Future<DashboardPreparedDeck> future;
}
