import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../data/dashboard_data_runtime_repository.dart';
import '../domain/prepared_dashboard_index.dart';

abstract interface class DashboardStableFrameScheduler {
  void scheduleStableFrame(void Function() callback);
}

typedef DashboardRevisionChanged = void Function(int revision);
typedef DashboardIndexBuildStarted =
    void Function(PreparedDashboardIndexRequest request, int generation);
typedef DashboardIndexBuildReady =
    void Function(
      PreparedDashboardIndex index,
      DataAcquisitionReason reason,
      Duration duration,
    );
typedef DashboardIndexBuildDiscarded =
    void Function(PreparedDashboardIndexRequest request, int generation);

final class FlutterDashboardStableFrameScheduler
    implements DashboardStableFrameScheduler {
  const FlutterDashboardStableFrameScheduler();

  @override
  void scheduleStableFrame(void Function() callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }
}

final class DashboardIndexPreparationDiscarded implements Exception {
  const DashboardIndexPreparationDiscarded(this.reason);

  final String reason;

  @override
  String toString() => 'DashboardIndexPreparationDiscarded($reason)';
}

final class GlobalCoreRevisionObserver {
  GlobalCoreRevisionObserver({
    required DashboardCoreRevisionRepository repository,
  }) : _repository = repository;

  final DashboardCoreRevisionRepository _repository;
  final Completer<int> _firstPositive = Completer<int>();
  StreamSubscription<int>? _subscription;
  void Function(int revision)? _onRevision;
  int? _lastRevision;
  bool _disposed = false;

  int subscribeCount = 0;
  int cancelCount = 0;

  Future<int> get firstPositiveRevision => _firstPositive.future;

  void start(void Function(int revision) onRevision) {
    if (_disposed) throw StateError('Global revision observer is disposed.');
    _onRevision = onRevision;
    if (_subscription != null) return;
    subscribeCount += 1;
    _subscription = _repository.watchCoreRevision().listen(
      (revision) {
        if (revision <= 0 || revision == _lastRevision) return;
        _lastRevision = revision;
        if (!_firstPositive.isCompleted) _firstPositive.complete(revision);
        _onRevision?.call(revision);
      },
      onError: (Object error, StackTrace stackTrace) {
        if (!_firstPositive.isCompleted) {
          _firstPositive.completeError(error, stackTrace);
        }
      },
    );
  }

  Future<void> dispose() async {
    if (_disposed) return;
    _disposed = true;
    final subscription = _subscription;
    _subscription = null;
    if (subscription != null) {
      cancelCount += 1;
      await subscription.cancel();
    }
  }
}

final class PreparedDashboardIndexBuilder {
  PreparedDashboardIndexBuilder({
    required PreparedDashboardIndexRepository repository,
  }) : _repository = repository;

  final PreparedDashboardIndexRepository _repository;
  DashboardIndexPreparationToken? _activeToken;
  int _generation = 0;

  int startedCount = 0;
  int readyCount = 0;
  int discardedCount = 0;
  int get nextGeneration => _generation + 1;

  Future<PreparedDashboardIndex> build(
    PreparedDashboardIndexRequest request,
  ) async {
    request.reason.requireIndexBuild();
    final token = DashboardIndexPreparationToken(generation: ++_generation);
    _activeToken?.cancel();
    _activeToken = token;
    startedCount += 1;
    late final PreparedDashboardIndex index;
    try {
      index = await _repository.prepareIndex(request, token);
    } on Object {
      if (token.isCancelled || !identical(_activeToken, token)) {
        discardedCount += 1;
        throw const DashboardIndexPreparationDiscarded('cancelled');
      }
      rethrow;
    }
    if (token.isCancelled ||
        !identical(_activeToken, token) ||
        index.key != request.key ||
        index.generation != token.generation ||
        index.coreRevision != request.key.coreRevision) {
      discardedCount += 1;
      throw const DashboardIndexPreparationDiscarded('stale-or-inexact');
    }
    readyCount += 1;
    return index;
  }

  void cancel() {
    _activeToken?.cancel();
    _activeToken = null;
  }
}

final class DashboardIndexRequestTemplate {
  const DashboardIndexRequestTemplate({
    required this.filterScope,
    required this.pageSize,
    required this.initialYear,
    required this.yearWindowRadius,
  });

  final CurrentLedgerQueryScope filterScope;
  final int pageSize;
  final int initialYear;
  final int yearWindowRadius;

  PreparedDashboardIndexRequest requestFor({
    required int coreRevision,
    required DataAcquisitionReason reason,
  }) {
    reason.requireIndexBuild();
    return PreparedDashboardIndexRequest(
      key: PreparedDashboardIndexKey.fromScope(
        scope: filterScope,
        coreRevision: coreRevision,
        pageSize: pageSize,
        yearWindowStart: initialYear - yearWindowRadius,
        yearWindowEndInclusive: initialYear + yearWindowRadius,
      ),
      filterScope: filterScope,
      initialYear: initialYear,
      reason: reason,
    );
  }
}

final class DashboardDataRuntime {
  DashboardDataRuntime({
    required GlobalCoreRevisionObserver revisionObserver,
    required PreparedDashboardIndexBuilder indexBuilder,
    required this.requestTemplate,
    required this.onIndexPublished,
    DashboardStableFrameScheduler? stableFrameScheduler,
    this.onGlobalRevisionWatchSubscribed,
    this.onGlobalRevisionChanged,
    this.onIndexBuildStarted,
    this.onIndexBuildReady,
    this.onIndexBuildDiscarded,
  }) : _revisionObserver = revisionObserver,
       _indexBuilder = indexBuilder,
       _stableFrameScheduler =
           stableFrameScheduler ?? const FlutterDashboardStableFrameScheduler();

  final GlobalCoreRevisionObserver _revisionObserver;
  final PreparedDashboardIndexBuilder _indexBuilder;
  final DashboardIndexRequestTemplate requestTemplate;
  final void Function(PreparedDashboardIndex index) onIndexPublished;
  final DashboardStableFrameScheduler _stableFrameScheduler;
  final void Function()? onGlobalRevisionWatchSubscribed;
  final DashboardRevisionChanged? onGlobalRevisionChanged;
  final DashboardIndexBuildStarted? onIndexBuildStarted;
  final DashboardIndexBuildReady? onIndexBuildReady;
  final DashboardIndexBuildDiscarded? onIndexBuildDiscarded;

  PreparedDashboardIndex? _currentIndex;
  PreparedDashboardIndex? _pendingIndex;
  Future<PreparedDashboardIndex>? _bootstrapFuture;
  int? _desiredRevision;
  bool _bootstrapped = false;
  bool _motionActive = false;
  bool _stableFrameScheduled = false;
  bool _disposed = false;

  int discardedIndexCount = 0;
  int publishedIndexCount = 0;
  int lastIndexPublishDurationMicros = 0;
  Object? lastBuildError;

  PreparedDashboardIndex? get currentIndex => _currentIndex;
  PreparedDashboardIndex? get pendingIndex => _pendingIndex;
  int get globalRevisionSubscribeCount => _revisionObserver.subscribeCount;
  int get globalRevisionCancelCount => _revisionObserver.cancelCount;

  Future<PreparedDashboardIndex> bootstrap({int? initialCoreRevision}) {
    final existing = _bootstrapFuture;
    if (existing != null) return existing;
    if (_disposed) {
      return Future<PreparedDashboardIndex>.error(
        StateError('Dashboard data runtime is disposed.'),
      );
    }
    final subscriptionsBefore = _revisionObserver.subscribeCount;
    _revisionObserver.start(_onRevision);
    if (_revisionObserver.subscribeCount != subscriptionsBefore) {
      onGlobalRevisionWatchSubscribed?.call();
    }
    late final Future<PreparedDashboardIndex> operation;
    operation = _bootstrap(initialCoreRevision).whenComplete(() {
      if (!_bootstrapped && identical(_bootstrapFuture, operation)) {
        _bootstrapFuture = null;
      }
    });
    _bootstrapFuture = operation;
    return operation;
  }

  Future<PreparedDashboardIndex> _bootstrap(int? initialCoreRevision) async {
    var revision =
        initialCoreRevision ?? await _revisionObserver.firstPositiveRevision;
    if (revision <= 0) throw StateError('Bootstrap revision must be positive.');
    final observed = _desiredRevision;
    if (observed == null || revision > observed) {
      _desiredRevision = revision;
    }
    while (true) {
      revision = _desiredRevision!;
      try {
        final index = await _build(
          revision,
          reason: DataAcquisitionReason.bootstrap,
        );
        if (_disposed) {
          discardedIndexCount += 1;
          throw const DashboardIndexPreparationDiscarded('disposed');
        }
        if (_desiredRevision != revision) {
          discardedIndexCount += 1;
          continue;
        }
        _publish(index);
        _bootstrapped = true;
        return index;
      } on DashboardIndexPreparationDiscarded {
        if (!_disposed && _desiredRevision != revision) {
          discardedIndexCount += 1;
          continue;
        }
        rethrow;
      }
    }
  }

  void _onRevision(int revision) {
    if (_disposed || revision <= 0) return;
    final desired = _desiredRevision;
    if (desired != null && revision <= desired) {
      return;
    }
    _desiredRevision = revision;
    onGlobalRevisionChanged?.call(revision);
    if (!_bootstrapped) {
      _indexBuilder.cancel();
      return;
    }
    unawaited(_buildRevision(revision));
  }

  Future<void> _buildRevision(int revision) async {
    try {
      final index = await _build(
        revision,
        reason: DataAcquisitionReason.databaseRevision,
      );
      if (_disposed || revision != _desiredRevision) {
        discardedIndexCount += 1;
        return;
      }
      _pendingIndex = index;
      if (!_motionActive) _schedulePendingPublication();
    } on DashboardIndexPreparationDiscarded {
      discardedIndexCount += 1;
    } on Object catch (error) {
      if (revision == _desiredRevision) lastBuildError = error;
    }
  }

  Future<PreparedDashboardIndex> _build(
    int revision, {
    required DataAcquisitionReason reason,
  }) async {
    final request = requestTemplate.requestFor(
      coreRevision: revision,
      reason: reason,
    );
    final generation = _indexBuilder.nextGeneration;
    onIndexBuildStarted?.call(request, generation);
    final timer = Stopwatch()..start();
    try {
      final index = await _indexBuilder.build(request);
      timer.stop();
      onIndexBuildReady?.call(index, reason, timer.elapsed);
      return index;
    } on DashboardIndexPreparationDiscarded {
      timer.stop();
      onIndexBuildDiscarded?.call(request, generation);
      rethrow;
    }
  }

  void setMotionActive(bool active) {
    if (_disposed || active == _motionActive) return;
    _motionActive = active;
    if (!active && _pendingIndex != null) _schedulePendingPublication();
  }

  void _schedulePendingPublication() {
    if (_stableFrameScheduled || _motionActive || _pendingIndex == null) return;
    _stableFrameScheduled = true;
    _stableFrameScheduler.scheduleStableFrame(() {
      _stableFrameScheduled = false;
      if (_disposed || _motionActive) return;
      final pending = _pendingIndex;
      if (pending == null || pending.coreRevision != _desiredRevision) return;
      _pendingIndex = null;
      _publish(pending);
    });
  }

  void _publish(PreparedDashboardIndex index) {
    final timer = Stopwatch()..start();
    _currentIndex = index;
    publishedIndexCount += 1;
    onIndexPublished(index);
    timer.stop();
    lastIndexPublishDurationMicros = timer.elapsedMicroseconds;
  }

  void dispose() {
    if (_disposed) return;
    _disposed = true;
    _indexBuilder.cancel();
    unawaited(_revisionObserver.dispose());
  }
}
