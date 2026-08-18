import 'dart:async';

import 'package:flutter/scheduler.dart';
import 'package:flutter/foundation.dart' show immutable;

import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../query/domain/current_ledger_query_scope.dart';
import '../../query/domain/dashboard_directional_query_set.dart';
import '../../query/domain/ledger_direction.dart';
import '../data/dashboard_data_runtime_repository.dart';
import '../domain/prepared_dashboard_index.dart';
import '../domain/prepared_budget_limit_snapshot.dart';

abstract interface class DashboardStableFrameScheduler {
  void scheduleStableFrame(void Function() callback);
}

/// Grants one cache-only unit only after Flutter has yielded to higher-priority
/// input/event work. Application controllers depend on this narrow runtime
/// boundary instead of importing [SchedulerBinding] or assuming a microtask
/// is an idle turn.
abstract interface class DashboardSpeculativeWorkScheduler {
  DashboardSpeculativeWorkSlot scheduleInputFairIdleSlot(
    void Function() callback,
  );
}

/// One revocable event-queue grant for cache-only maintenance. Foreground work
/// owns neither this handle nor its callback; it can only revoke an obsolete
/// speculative grant before the callback begins.
abstract interface class DashboardSpeculativeWorkSlot {
  void cancel();
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

/// Exact data publication for one prepared dashboard revision.  The optional
/// Budget bank stays absent only for legacy/test repositories that do not yet
/// expose the narrow native acquisition capability; production publication
/// supplies it before the index can enter the visible dashboard.
@immutable
final class DashboardPreparedIndexPublication {
  DashboardPreparedIndexPublication({
    required this.index,
    required this.budgetLimitSnapshot,
  }) : assert(index.coreRevision > 0) {
    final snapshot = budgetLimitSnapshot;
    if (snapshot != null && snapshot.coreRevision != index.coreRevision) {
      throw ArgumentError(
        'Prepared Budget snapshot and dashboard index revisions must match.',
      );
    }
  }

  final PreparedDashboardIndex index;
  final PreparedBudgetLimitSnapshot? budgetLimitSnapshot;
}

final class FlutterDashboardStableFrameScheduler
    implements DashboardStableFrameScheduler {
  const FlutterDashboardStableFrameScheduler();

  @override
  void scheduleStableFrame(void Function() callback) {
    SchedulerBinding.instance.addPostFrameCallback((_) => callback());
  }
}

final class FlutterDashboardSpeculativeWorkScheduler
    implements DashboardSpeculativeWorkScheduler {
  const FlutterDashboardSpeculativeWorkScheduler();

  @override
  DashboardSpeculativeWorkSlot scheduleInputFairIdleSlot(
    void Function() callback,
  ) {
    // This is deliberately one event-queue turn, never a microtask. A
    // platform pointer event already waiting for Dart can therefore run
    // before the next speculative neighbour acquires the shared query lane.
    // The cancellable zone timer is the one issued grant, not a retry or a
    // delay policy; cancellation removes the queued event completely.
    late final _FlutterDashboardSpeculativeWorkSlot slot;
    final scheduleEvent = Zone.current.createTimer;
    final timer = scheduleEvent(Duration.zero, () {
      if (!slot.isCancelled) callback();
    });
    slot = _FlutterDashboardSpeculativeWorkSlot(timer);
    return slot;
  }
}

final class _FlutterDashboardSpeculativeWorkSlot
    implements DashboardSpeculativeWorkSlot {
  _FlutterDashboardSpeculativeWorkSlot(this._timer);

  final Timer _timer;
  var _cancelled = false;

  bool get isCancelled => _cancelled;

  @override
  void cancel() {
    if (_cancelled) return;
    _cancelled = true;
    _timer.cancel();
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
    final token = DashboardIndexPreparationToken(
      generation: ++_generation,
      reason: request.reason,
    );
    _cancelActiveToken();
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
    final token = DashboardIndexPreparationToken(
      generation: ++_generation,
      reason: request.request.reason,
    );
    _cancelActiveToken();
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
    _cancelActiveToken();
    _activeToken = null;
  }

  void _cancelActiveToken() {
    final token = _activeToken;
    if (token == null || token.isCancelled) return;
    token.cancel();
    final cancellationRepository = _repository;
    if (token.reason == DataAcquisitionReason.query &&
        cancellationRepository
            is PreparedDashboardIndexCancellationRepository) {
      unawaited(
        (cancellationRepository as PreparedDashboardIndexCancellationRepository)
            .cancelPreparedIndex(token),
      );
    }
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

  /// Reuses the active immutable prepared index's actual physical coverage
  /// for a Query candidate. Query temporal navigation changes semantic
  /// selection only; it must not silently create a different backing index.
  factory DashboardIndexRequestTemplate.forPreparedYearWindow({
    required DashboardDirectionalQuerySet directionalQueries,
    required int pageSize,
    required DashboardPreparedYearWindow yearWindow,
  }) => DashboardIndexRequestTemplate(
    directionalQueries: directionalQueries,
    pageSize: pageSize,
    initialYear: yearWindow.centerYear,
    yearWindowRadius: yearWindow.radius,
  );

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

  /// One canonical physical year-window derivation. Bootstrap, exact Budget
  /// snapshot acquisition and the debug seed use this rather than carrying a
  /// second hard-coded horizon.
  DashboardPreparedYearWindow get preparedYearWindow =>
      DashboardPreparedYearWindow(
        start: initialYear - yearWindowRadius,
        endInclusive: initialYear + yearWindowRadius,
        centerYear: initialYear,
      );

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

/// The exact symmetric physical year coverage owned by an immutable prepared
/// dashboard index. This is intentionally distinct from a visible temporal
/// anchor, which is presentation metadata rather than Query-cache identity.
@immutable
final class DashboardPreparedYearWindow {
  const DashboardPreparedYearWindow({
    required this.start,
    required this.endInclusive,
    required this.centerYear,
  });

  factory DashboardPreparedYearWindow.fromIndex(PreparedDashboardIndex index) =>
      DashboardPreparedYearWindow.fromKey(index.key);

  factory DashboardPreparedYearWindow.fromKey(PreparedDashboardIndexKey key) {
    final radius = key.yearWindowEndInclusive - key.yearWindowStart;
    if (radius < 2 || radius.isOdd) {
      throw ArgumentError(
        'Prepared dashboard year window must be symmetric and non-empty.',
      );
    }
    final half = radius ~/ 2;
    return DashboardPreparedYearWindow(
      start: key.yearWindowStart,
      endInclusive: key.yearWindowEndInclusive,
      centerYear: key.yearWindowStart + half,
    );
  }

  final int start;
  final int endInclusive;
  final int centerYear;

  int get radius => centerYear - start;
  String get cacheIdentity => 'window:$start-$endInclusive';
}

final class DashboardDataRuntime {
  DashboardDataRuntime({
    required GlobalCoreRevisionObserver revisionObserver,
    required PreparedDashboardIndexBuilder indexBuilder,
    required DashboardIndexRequestTemplate requestTemplate,
    required this.onIndexPublished,
    PreparedBudgetLimitSnapshotRepository? budgetSnapshotRepository,
    DashboardStableFrameScheduler? stableFrameScheduler,
    this.onGlobalRevisionWatchSubscribed,
    this.onGlobalRevisionChanged,
    this.onIndexBuildStarted,
    this.onIndexBuildReady,
    this.onIndexBuildDiscarded,
  }) : _revisionObserver = revisionObserver,
       _indexBuilder = indexBuilder,
       _requestTemplate = requestTemplate,
       _budgetSnapshotRepository = budgetSnapshotRepository,
       _stableFrameScheduler =
           stableFrameScheduler ?? const FlutterDashboardStableFrameScheduler();

  final GlobalCoreRevisionObserver _revisionObserver;
  final PreparedDashboardIndexBuilder _indexBuilder;
  DashboardIndexRequestTemplate _requestTemplate;
  final void Function(DashboardPreparedIndexPublication publication)
  onIndexPublished;
  final PreparedBudgetLimitSnapshotRepository? _budgetSnapshotRepository;
  final DashboardStableFrameScheduler _stableFrameScheduler;
  final void Function()? onGlobalRevisionWatchSubscribed;
  final DashboardRevisionChanged? onGlobalRevisionChanged;
  final DashboardIndexBuildStarted? onIndexBuildStarted;
  final DashboardIndexBuildReady? onIndexBuildReady;
  final DashboardIndexBuildDiscarded? onIndexBuildDiscarded;

  PreparedDashboardIndex? _currentIndex;
  DashboardPreparedIndexPublication? _pendingPublication;
  PreparedBudgetLimitSnapshot? _activeBudgetSnapshot;
  _BudgetSnapshotRequest? _inFlightBudgetSnapshot;
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
  PreparedDashboardIndex? get pendingIndex => _pendingPublication?.index;
  PreparedBudgetLimitSnapshot? get activeBudgetSnapshot =>
      _activeBudgetSnapshot;
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

  /// Acquires one query-independent exact bank at most once per revision and
  /// physical year window. Query candidates call this after their immutable
  /// index build; same-revision applies join the existing bank rather than
  /// starting another native aggregate read.
  Future<PreparedBudgetLimitSnapshot?> prepareBudgetLimitSnapshotFor(
    PreparedDashboardIndex index,
  ) async {
    final repository = _budgetSnapshotRepository;
    if (repository == null) return null;
    final key = _BudgetSnapshotKey.fromIndex(index);
    final active = _activeBudgetSnapshot;
    if (active != null && key.matches(active)) {
      _recordBudgetSnapshotReused(key);
      return active;
    }
    final inFlight = _inFlightBudgetSnapshot;
    if (inFlight != null && inFlight.key == key) {
      _recordBudgetSnapshotReused(key);
      return inFlight.future;
    }
    final future = repository.prepareBudgetLimitSnapshot(
      coreRevision: key.coreRevision,
      yearWindowStart: key.yearWindowStart,
      yearWindowEndInclusive: key.yearWindowEndInclusive,
    );
    final request = _BudgetSnapshotRequest(key, future);
    _inFlightBudgetSnapshot = request;
    try {
      final snapshot = await future;
      if (!key.matches(snapshot)) {
        throw StateError('Prepared Budget snapshot identity is inexact.');
      }
      _activeBudgetSnapshot = snapshot;
      return snapshot;
    } finally {
      if (identical(_inFlightBudgetSnapshot, request)) {
        _inFlightBudgetSnapshot = null;
      }
    }
  }

  void _recordBudgetSnapshotReused(_BudgetSnapshotKey key) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'FINANCIAL_LIMIT_SNAPSHOT_REUSED',
        coreRevision: key.coreRevision,
        scope:
            'yearWindowStart=${key.yearWindowStart} '
            'yearWindowEnd=${key.yearWindowEndInclusive} cacheHit=true',
      ),
    );
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
        final budgetLimitSnapshot = await prepareBudgetLimitSnapshotFor(index);
        // The native aggregate read is intentionally part of the exact
        // revision publication barrier. A newer revision observed while it
        // was in flight invalidates this pair as a whole.
        if (_disposed || _desiredRevision != revision) {
          discardedIndexCount += 1;
          continue;
        }
        _publish(
          DashboardPreparedIndexPublication(
            index: index,
            budgetLimitSnapshot: budgetLimitSnapshot,
          ),
        );
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
      final publication = DashboardPreparedIndexPublication(
        index: index,
        budgetLimitSnapshot: await prepareBudgetLimitSnapshotFor(index),
      );
      if (_disposed || revision != _desiredRevision) {
        discardedIndexCount += 1;
        return;
      }
      _pendingPublication = publication;
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
    if (!active && _pendingPublication != null) _schedulePendingPublication();
  }

  void _schedulePendingPublication() {
    if (_stableFrameScheduled || _motionActive || _pendingPublication == null) {
      return;
    }
    _stableFrameScheduled = true;
    _stableFrameScheduler.scheduleStableFrame(() {
      _stableFrameScheduled = false;
      if (_disposed || _motionActive) return;
      final pending = _pendingPublication;
      if (pending == null || pending.index.coreRevision != _desiredRevision) {
        return;
      }
      _pendingPublication = null;
      _publish(pending);
    });
  }

  void _publish(DashboardPreparedIndexPublication publication) {
    final timer = Stopwatch()..start();
    final index = publication.index;
    _currentIndex = index;
    publishedIndexCount += 1;
    onIndexPublished(publication);
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

@immutable
final class _BudgetSnapshotKey {
  const _BudgetSnapshotKey({
    required this.coreRevision,
    required this.yearWindowStart,
    required this.yearWindowEndInclusive,
  });

  factory _BudgetSnapshotKey.fromIndex(PreparedDashboardIndex index) =>
      _BudgetSnapshotKey(
        coreRevision: index.coreRevision,
        yearWindowStart: index.key.yearWindowStart,
        yearWindowEndInclusive: index.key.yearWindowEndInclusive,
      );

  final int coreRevision;
  final int yearWindowStart;
  final int yearWindowEndInclusive;

  bool matches(PreparedBudgetLimitSnapshot snapshot) =>
      snapshot.coreRevision == coreRevision &&
      snapshot.yearWindowStart == yearWindowStart &&
      snapshot.yearWindowEndInclusive == yearWindowEndInclusive;

  @override
  bool operator ==(Object other) =>
      other is _BudgetSnapshotKey &&
      other.coreRevision == coreRevision &&
      other.yearWindowStart == yearWindowStart &&
      other.yearWindowEndInclusive == yearWindowEndInclusive;

  @override
  int get hashCode =>
      Object.hash(coreRevision, yearWindowStart, yearWindowEndInclusive);
}

final class _BudgetSnapshotRequest {
  const _BudgetSnapshotRequest(this.key, this.future);

  final _BudgetSnapshotKey key;
  final Future<PreparedBudgetLimitSnapshot> future;
}
