import 'dart:async';

import 'package:flutter/scheduler.dart';

import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
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
  bool get supportsDirectionalPartitionReuse =>
      _repository is PreparedDashboardIndexPartitionRepository;

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

  Future<PreparedDashboardIndex> buildPartition(
    PreparedDashboardIndexPartitionRequest request,
  ) async {
    final repository = _repository;
    if (repository is! PreparedDashboardIndexPartitionRepository) {
      throw StateError('The dashboard repository cannot acquire a partition.');
    }
    final partitionRepository =
        repository as PreparedDashboardIndexPartitionRepository;
    request.request.reason.requireIndexBuild();
    final token = DashboardIndexPreparationToken(generation: ++_generation);
    _activeToken?.cancel();
    _activeToken = token;
    startedCount += 1;
    late final PreparedDashboardIndex index;
    try {
      index = await partitionRepository.prepareIndexPartition(request, token);
    } on Object {
      if (token.isCancelled || !identical(_activeToken, token)) {
        discardedCount += 1;
        throw const DashboardIndexPreparationDiscarded('cancelled');
      }
      rethrow;
    }
    if (token.isCancelled ||
        !identical(_activeToken, token) ||
        index.key != request.request.key ||
        index.generation != token.generation ||
        index.coreRevision != request.request.key.coreRevision) {
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
  DashboardIndexRequestTemplate({
    CurrentLedgerQueryScope? filterScope,
    DashboardDirectionalQuerySet? directionalQueries,
    required this.pageSize,
    required this.initialYear,
    required this.yearWindowRadius,
  }) : directionalQueries =
           directionalQueries ??
           DashboardDirectionalQuerySet.fromInitial(
             _requireLegacyFilterScope(filterScope),
           ),
       filterScope = filterScope ?? directionalQueries!.income;

  static CurrentLedgerQueryScope _requireLegacyFilterScope(
    CurrentLedgerQueryScope? scope,
  ) {
    if (scope == null) {
      throw ArgumentError(
        'Dashboard index templates require directional queries.',
      );
    }
    return scope;
  }

  /// Compatibility projection. New index identity and transport use
  /// [directionalQueries].
  final CurrentLedgerQueryScope filterScope;
  final DashboardDirectionalQuerySet directionalQueries;
  final int pageSize;
  final int initialYear;
  final int yearWindowRadius;

  PreparedDashboardIndexRequest requestFor({
    required int coreRevision,
    required DataAcquisitionReason reason,
  }) {
    reason.requireIndexBuild();
    return PreparedDashboardIndexRequest(
      key: PreparedDashboardIndexKey.fromDirectionalQuerySet(
        queries: directionalQueries,
        coreRevision: coreRevision,
        pageSize: pageSize,
        yearWindowStart: initialYear - yearWindowRadius,
        yearWindowEndInclusive: initialYear + yearWindowRadius,
      ),
      directionalQueries: directionalQueries,
      initialYear: initialYear,
      reason: reason,
    );
  }
}

final class DashboardDataRuntime {
  DashboardDataRuntime({
    required GlobalCoreRevisionObserver revisionObserver,
    required PreparedDashboardIndexBuilder indexBuilder,
    required DashboardIndexRequestTemplate requestTemplate,
    required this.onIndexPublished,
    DashboardStableFrameScheduler? stableFrameScheduler,
    this.onGlobalRevisionWatchSubscribed,
    this.onGlobalRevisionChanged,
    this.onIndexBuildStarted,
    this.onIndexBuildReady,
    this.onIndexBuildDiscarded,
  }) : _revisionObserver = revisionObserver,
       _indexBuilder = indexBuilder,
       _requestTemplate = requestTemplate,
       _stableFrameScheduler =
           stableFrameScheduler ?? const FlutterDashboardStableFrameScheduler();

  final GlobalCoreRevisionObserver _revisionObserver;
  final PreparedDashboardIndexBuilder _indexBuilder;
  DashboardIndexRequestTemplate _requestTemplate;
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
  DashboardIndexRequestTemplate get requestTemplate => _requestTemplate;
  int get globalRevisionSubscribeCount => _revisionObserver.subscribeCount;
  int get globalRevisionCancelCount => _revisionObserver.cancelCount;

  /// Builds a complete next query index without publishing it. The dashboard
  /// coordinator owns the later single presentation commit, so no frame can
  /// expose new filters against an old prepared index.
  Future<PreparedDashboardIndex> prepareQuery(
    DashboardIndexRequestTemplate nextTemplate,
  ) async {
    if (_disposed) throw StateError('Dashboard data runtime is disposed.');
    final revision = _currentIndex?.coreRevision ?? _desiredRevision;
    if (revision == null || revision <= 0) {
      throw StateError('A bootstrapped core revision is required for Query.');
    }
    final request = nextTemplate.requestFor(
      coreRevision: revision,
      reason: DataAcquisitionReason.query,
    );
    final current = _currentIndex;
    final changedDirection = current == null
        ? null
        : _singleChangedDirection(current.key, request.key);
    final index =
        current != null &&
            changedDirection != null &&
            _indexBuilder.supportsDirectionalPartitionReuse
        ? await _buildWithReusedDirectionalPartition(
            request: request,
            current: current,
            changedDirection: changedDirection,
          )
        : await _build(
            revision,
            reason: DataAcquisitionReason.query,
            template: nextTemplate,
          );
    if (_disposed || index.coreRevision != revision) {
      discardedIndexCount += 1;
      throw const DashboardIndexPreparationDiscarded('query-stale');
    }
    return index;
  }

  LedgerDirection? _singleChangedDirection(
    PreparedDashboardIndexKey current,
    PreparedDashboardIndexKey next,
  ) {
    if (current.coreRevision != next.coreRevision ||
        current.pageSize != next.pageSize ||
        current.yearWindowStart != next.yearWindowStart ||
        current.yearWindowEndInclusive != next.yearWindowEndInclusive) {
      return null;
    }
    final incomeChanged = current.incomeFilterKey != next.incomeFilterKey;
    final expenseChanged = current.expenseFilterKey != next.expenseFilterKey;
    return switch ((incomeChanged, expenseChanged)) {
      (true, false) => LedgerDirection.income,
      (false, true) => LedgerDirection.expense,
      _ => null,
    };
  }

  Future<PreparedDashboardIndex> _buildWithReusedDirectionalPartition({
    required PreparedDashboardIndexRequest request,
    required PreparedDashboardIndex current,
    required LedgerDirection changedDirection,
  }) async {
    final generation = _indexBuilder.nextGeneration;
    onIndexBuildStarted?.call(request, generation);
    final timer = Stopwatch()..start();
    try {
      final partial = await _indexBuilder.buildPartition(
        PreparedDashboardIndexPartitionRequest(
          request: request,
          direction: changedDirection,
        ),
      );
      timer.stop();
      final reusedDirection = switch (changedDirection) {
        LedgerDirection.income => LedgerDirection.expense,
        LedgerDirection.expense => LedgerDirection.income,
      };
      final changed = partial.partitionFor(changedDirection);
      final reused = current.partitionFor(reusedDirection);
      final index = switch (changedDirection) {
        LedgerDirection.income =>
          PreparedDashboardIndex.composeDirectionalPartitions(
            key: request.key,
            income: changed,
            expense: reused,
            generation: partial.generation,
            contentDigest: Object.hash(
              request.key,
              partial.contentDigest,
              reused.filterKey,
              'directional-reuse',
            ),
            preparedAt: partial.preparedAt,
            buildMetrics: _combinedDirectionalBuildMetrics(
              partial: partial,
              reused: reused,
            ),
            builtDirection: changedDirection,
            reusedDirection: reusedDirection,
          ),
        LedgerDirection.expense =>
          PreparedDashboardIndex.composeDirectionalPartitions(
            key: request.key,
            income: reused,
            expense: changed,
            generation: partial.generation,
            contentDigest: Object.hash(
              request.key,
              partial.contentDigest,
              reused.filterKey,
              'directional-reuse',
            ),
            preparedAt: partial.preparedAt,
            buildMetrics: _combinedDirectionalBuildMetrics(
              partial: partial,
              reused: reused,
            ),
            builtDirection: changedDirection,
            reusedDirection: reusedDirection,
          ),
      };
      onIndexBuildReady?.call(
        index,
        DataAcquisitionReason.query,
        timer.elapsed,
      );
      return index;
    } on DashboardIndexPreparationDiscarded {
      timer.stop();
      onIndexBuildDiscarded?.call(request, generation);
      rethrow;
    }
  }

  PreparedDashboardIndexBuildMetrics _combinedDirectionalBuildMetrics({
    required PreparedDashboardIndex partial,
    required PreparedDashboardDirectionalPartition reused,
  }) {
    final metrics = partial.buildMetrics;
    final reusedRows = reused.preparedRowCount;
    return metrics.copyWith(
      uniquePreviewRowCount: metrics.uniquePreviewRowCount + reusedRows,
      frameCount: partial.frames.length + reused.frames.length,
      estimatedIndexBytes:
          metrics.estimatedIndexBytes +
          reusedRows * 256 +
          reused.frames.length * 256,
    );
  }

  /// Discards only a not-yet-published Query candidate.  The visible runtime
  /// index remains immutable and active, so Query Menu cancellation never
  /// needs a compensating/rollback build.
  void cancelPreparedQuery() => _indexBuilder.cancel();

  /// Completes the data-side half of a query publication after the dashboard
  /// coordinator has atomically installed its prepared visual revision.
  /// Unlike [_publish], this intentionally does not invoke [onIndexPublished]
  /// again: that callback is the normal revision observer path.
  void commitPreparedQuery(
    PreparedDashboardIndex index,
    DashboardIndexRequestTemplate template,
  ) {
    if (_disposed) return;
    if (index.key !=
        template
            .requestFor(
              coreRevision: index.coreRevision,
              reason: DataAcquisitionReason.query,
            )
            .key) {
      throw StateError('A mismatched query index cannot be committed.');
    }
    _requestTemplate = template;
    _currentIndex = index;
    publishedIndexCount += 1;
  }

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
    DashboardIndexRequestTemplate? template,
  }) async {
    final request = (template ?? _requestTemplate).requestFor(
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
