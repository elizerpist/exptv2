import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import 'dashboard_summary_amount_controller.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';
import '../logbox/application/dashboard_log_paging_coordinator.dart';
import '../logbox/application/dashboard_log_presentation_adapter.dart';
import '../logbox/application/dashboard_log_performance_diagnostics.dart';
import '../query/application/current_query_controller.dart';
import '../query/application/dashboard_parent_display_bundle.dart';
import '../query/application/dashboard_presentation_diagnostics.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/application/dashboard_presentation_store.dart';
import '../query/data/dashboard_ledger_repository.dart';
import '../query/data/dashboard_child_summary_repository.dart';
import '../query/data/dashboard_child_preview_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';
import '../query/domain/time_child_summary.dart';
import '../time_navigation/application/summary_timing_debug.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/time_plane.dart';
import '../../../shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'dashboard_adjacent_parent_prewarm_coordinator.dart';
import 'dashboard_rail_motion_coordinator.dart';

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardLedgerRepository? queryRepository,
    DateTime? initialDate,
    Duration liveQueryLeaseQuiescence = Duration.zero,
    bool autoStartQuery = true,
    bool seedReady = true,
    DashboardPresentationDiagnostics? diagnostics,
  }) : expansion = DashboardExpansionController(metrics: metrics),
       presentationDiagnostics =
           diagnostics ?? DashboardPresentationDiagnostics(),
       rail = DashboardRailController(
         initialDate: initialDate,
         initialPlane: TimePlane.month,
       ),
       transactionDirection = TransactionDirectionController() {
    _seedReady = seedReady;
    final repository =
        queryRepository ?? const EmptyDashboardLedgerRepository();
    presentationStore = DashboardPresentationStore();
    logPerformanceDiagnostics = DashboardLogPerformanceDiagnostics();
    logPresentation = DashboardLogPresentationAdapter(
      store: presentationStore,
      performanceDiagnostics: logPerformanceDiagnostics,
      motionEpochProvider: () => railMotion.currentEpoch?.id ?? 0,
    );
    logPaging = DashboardLogPagingCoordinator(
      store: presentationStore,
      repository: repository,
    );
    query = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: rail.state.effectiveScope,
      ),
      presentationStore: presentationStore,
      liveLeaseQuiescence: liveQueryLeaseQuiescence,
    );
    adjacentParentPrewarm = DashboardAdjacentParentPrewarmCoordinator();
    railMotion = DashboardRailMotionCoordinator(
      onMotionStarted: _handleMotionStarted,
    );
    // The parent lane reuses the same semantic motion coordinator. It does
    // not own a second scroll engine; it only gives parent preview and lease
    // work the same epoch/latest-wins boundary as the child rail.
    parentMotion = DashboardRailMotionCoordinator(
      onMotionStarted: _handleMotionStarted,
    );
    summaryMetrics = DashboardSummaryMetricsController(
      navigation: rail,
      query: query,
      childSummaryRepository: repository is DashboardChildSummaryRepository
          ? repository as DashboardChildSummaryRepository
          : null,
      childPreviewRepository: repository is DashboardChildPreviewRepository
          ? repository as DashboardChildPreviewRepository
          : null,
      presentationStore: presentationStore,
      diagnostics: presentationDiagnostics,
      seedReady: seedReady,
    );
    expansion.addListener(_forwardChildNotification);
    rail.addListener(_handleRailChanged);
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    transactionDirection.addListener(_handleDirectionChanged);
    query.addListener(_forwardChildNotification);
    if (autoStartQuery && seedReady) {
      startQuery(reason: 'initial');
    } else {
      DashboardQueryDebug.mark(
        'QUERY_START_DEFERRED',
        scope: query.state.scope,
        flowId: DashboardQueryDebug.flowIdFor(query.state.scope),
        detail: 'reason=seedGate',
      );
    }
  }

  /// The single metric source shared by dashboard geometry and expansion state.
  final DashboardLayoutMetrics metrics;
  final DashboardPresentationDiagnostics presentationDiagnostics;
  late final DashboardAdjacentParentPrewarmCoordinator adjacentParentPrewarm;
  late final DashboardRailMotionCoordinator railMotion;
  late final DashboardRailMotionCoordinator parentMotion;

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;
  late final DashboardPresentationStore presentationStore;
  late final DashboardLogPresentationAdapter logPresentation;
  late final DashboardLogPerformanceDiagnostics logPerformanceDiagnostics;
  late final DashboardLogPagingCoordinator logPaging;
  late final CurrentQueryController query;
  late final DashboardSummaryMetricsController summaryMetrics;
  late int _lastHandledRailNavigationRevision;
  final ChangeNotifier _summaryNavigationNotifier = ChangeNotifier();
  DashboardTimeNavigationState? _parentPreviewState;
  DashboardTimeNavigationChangeDirection? _parentPreviewDirection;
  bool _queryStarted = false;
  late bool _seedReady;
  int _atomicParentChildPublishes = 0;
  int _parentDeckMismatchPrevented = 0;
  int _parentWhileOpenTransitions = 0;
  final int _liveFallbackDuringCachedParentNavigation = 0;
  int _repositoryReadsBeforeVisiblePublish = 0;
  int _openRailParentTransitionGeneration = 0;
  bool _disposed = false;

  Listenable get summaryNavigationListenable => _summaryNavigationNotifier;
  DashboardTimeNavigationState? get parentPreviewState => _parentPreviewState;
  int get atomicParentChildPublishes => _atomicParentChildPublishes;
  int get parentDeckMismatchPrevented => _parentDeckMismatchPrevented;
  int get parentWhileOpenTransitions => _parentWhileOpenTransitions;
  int get liveFallbackDuringCachedParentNavigation =>
      _liveFallbackDuringCachedParentNavigation;
  int get repositoryReadsBeforeVisiblePublish =>
      _repositoryReadsBeforeVisiblePublish;
  int get staleRailCallbacksRejected => rail.staleCallbackRejectionCount;

  /// Starts the query lane against the current navigation state. Seed-gated
  /// startup calls this only after the native seed transaction has committed.
  void startQuery({String reason = 'initial'}) {
    _seedReady = true;
    summaryMetrics.markSeedCommitted();
    _queryStarted = true;
    final navigationScope = rail.state.effectiveScope;
    if (query.state.scope.timeScope != navigationScope) {
      query.refreshAtScope(
        query.state.scope.copyWith(timeScope: navigationScope),
        reason: reason,
      );
    } else {
      query.refresh(reason: reason);
    }
    final oppositeDirection =
        query.state.scope.direction == LedgerDirection.income
        ? LedgerDirection.expense
        : LedgerDirection.income;
    Future<void>.microtask(() {
      if (_disposed) return;
      query.prewarm(
        query.state.scope.copyWith(direction: oppositeDirection),
        reason: 'startupOppositeDirection',
      );
    });
  }

  /// Bootstrap read boundary used by the app shell. It starts the existing
  /// query lane when seed/default resolution is complete and waits for that
  /// lane's one canonical result; no observer or second query is created.
  Future<DashboardPresentationSnapshot>
  readCriticalSnapshotForBootstrap() async {
    if (!_queryStarted) startQuery(reason: 'bootstrap');
    await query.waitForCurrentSnapshot();
    final snapshot = presentationStore.activeSnapshot;
    if (snapshot != null &&
        snapshot.hasValue &&
        !snapshot.isLoading &&
        !snapshot.isStale &&
        !snapshot.hasError &&
        snapshot.queryKey == query.state.scope.key) {
      return snapshot;
    }
    final result = query.state.result;
    if (result == null) {
      throw StateError('Dashboard critical snapshot was not published.');
    }
    return DashboardPresentationSnapshot.fromResult(
      scope: query.state.scope,
      generation: 0,
      result: result,
    );
  }

  Future<void> prepareCurrentChildPreviewForBootstrap() =>
      summaryMetrics.waitForCurrentParentPreview();

  /// Bootstrap boundary for the complete parent presentation. The dashboard
  /// route is not mounted until both the parent snapshot and its child
  /// preview bundle are ready.
  Future<DashboardParentDisplayBundle>
  readParentDisplayBundleForBootstrap() async {
    if (!_queryStarted) startQuery(reason: 'bootstrap');
    await query.waitForCurrentSnapshot();
    final bundle = await summaryMetrics.prepareCurrentParentDisplayBundle();
    _scheduleAdjacentParentPrewarm();
    return bundle;
  }

  void _forwardChildNotification() => notifyListeners();

  void beginRailMotion(CenteredCarouselMotionOrigin origin) {
    railMotion.begin(
      origin: switch (origin) {
        CenteredCarouselMotionOrigin.userDrag =>
          DashboardRailMotionOrigin.userDrag,
        CenteredCarouselMotionOrigin.programmatic =>
          DashboardRailMotionOrigin.programmatic,
      },
    );
  }

  void _handleMotionStarted(DashboardRailMotionEpoch epoch) {
    if (_queryStarted) {
      query.invalidatePendingLiveLease(motionEpoch: epoch.id);
    }
    adjacentParentPrewarm.beginMotion();
  }

  void beginParentMotion(CenteredCarouselMotionOrigin origin) {
    _parentPreviewState = null;
    _parentPreviewDirection = null;
    parentMotion.begin(
      origin: switch (origin) {
        CenteredCarouselMotionOrigin.userDrag =>
          DashboardRailMotionOrigin.userDrag,
        CenteredCarouselMotionOrigin.programmatic =>
          DashboardRailMotionOrigin.programmatic,
      },
    );
    _summaryNavigationNotifier.notifyListeners();
  }

  /// Publishes a cached parent preview without committing the query scope.
  /// The navigation label is changed only when amount/count can be changed by
  /// the same exact snapshot, so a cold parent never gets a dash frame.
  bool previewParent(DashboardTimeNavigationChangeDirection direction) {
    if (_disposed) return false;
    if (parentMotion.currentEpoch == null || !parentMotion.isMotionActive) {
      beginParentMotion(CenteredCarouselMotionOrigin.userDrag);
    }
    final candidate = rail.parentPreview(direction);
    final epoch = parentMotion.currentEpoch;
    if (candidate == null || epoch == null) return false;
    final didPublish = summaryMetrics.previewParent(
      candidate,
      presentationEpoch: epoch.id,
    );
    if (didPublish) {
      _parentPreviewState = candidate;
      _parentPreviewDirection = direction;
    }
    _summaryNavigationNotifier.notifyListeners();
    return didPublish;
  }

  bool publishParentMotionIdle() {
    final epoch = parentMotion.currentEpoch;
    if (epoch == null) return false;
    final accepted = parentMotion.publishIdle(
      epoch: epoch.id,
      logicalIndex: rail.selectedChildLogicalIndex,
    );
    if (accepted) {
      adjacentParentPrewarm.endMotion();
      DashboardSummaryTimingDebug.mark('PARENT_MOTION_IDLE');
    }
    return accepted;
  }

  bool publishParentMotionSettle() {
    final epoch = parentMotion.currentEpoch;
    if (epoch == null) return false;
    final accepted = parentMotion.publishSettle(
      epoch: epoch.id,
      logicalIndex: rail.selectedChildLogicalIndex,
    );
    if (accepted) DashboardSummaryTimingDebug.mark('PARENT_SETTLED');
    return accepted;
  }

  /// Commits one parent navigation after the preview lane has had a chance to
  /// select a cached snapshot. The existing navigation controller remains the
  /// sole owner of the committed parent state and carousel re-centering.
  void commitParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    if (rail.state.isRailOpen) {
      _commitParentWhileRailOpen(direction);
      return;
    }
    if (parentMotion.currentEpoch == null || !parentMotion.isMotionActive) {
      beginParentMotion(CenteredCarouselMotionOrigin.programmatic);
    }
    if (_parentPreviewDirection != direction) {
      previewParent(direction);
    }
    publishParentMotionIdle();
    publishParentMotionSettle();
    switch (direction) {
      case DashboardTimeNavigationChangeDirection.forward:
        rail.moveParentNext();
      case DashboardTimeNavigationChangeDirection.backward:
        rail.moveParentPrevious();
      case DashboardTimeNavigationChangeDirection.none:
        break;
    }
    // Let the committed navigation update the underlying rail state before
    // dropping the preview override. This keeps label, amount and count on
    // one coherent frame even for synchronous listeners.
    _parentPreviewState = null;
    _parentPreviewDirection = null;
    _summaryNavigationNotifier.notifyListeners();
  }

  void _commitParentWhileRailOpen(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    final candidate = rail.parentPreview(direction);
    if (candidate == null) return;
    _parentWhileOpenTransitions += 1;
    if (parentMotion.currentEpoch == null || !parentMotion.isMotionActive) {
      beginParentMotion(CenteredCarouselMotionOrigin.programmatic);
    }
    final epoch = parentMotion.currentEpoch?.id ?? 0;
    final parentScope = query.state.scope.copyWith(
      timeScope: candidate.parentScope,
    );
    final childPeriod = _childPeriodFor(candidate);
    final transitionGeneration = ++_openRailParentTransitionGeneration;
    DashboardQueryDebug.mark(
      'PARENT_NAVIGATION_STARTED',
      scope: parentScope,
      detail:
          'railOpen=true retainedChild=${candidate.displayedChild} '
          'presentationEpoch=$epoch navigationRevision=${rail.state.navigationRevision}',
    );
    final complete = summaryMetrics.hasCompleteParentDisplayBundle(
      parentScope: parentScope,
      childPeriod: childPeriod,
    );
    if (!complete) {
      _repositoryReadsBeforeVisiblePublish += 1;
      unawaited(
        _prepareAndCommitOpenRailParent(
          candidate: candidate,
          direction: direction,
          parentScope: parentScope,
          childPeriod: childPeriod,
          transitionGeneration: transitionGeneration,
          presentationEpoch: epoch,
          cacheHit: false,
        ),
      );
      publishParentMotionIdle();
      publishParentMotionSettle();
      return;
    }
    _finishOpenRailParentTransition(
      candidate: candidate,
      direction: direction,
      parentScope: parentScope,
      presentationEpoch: epoch,
      transitionGeneration: transitionGeneration,
      cacheHit: true,
    );
  }

  Future<void> _prepareAndCommitOpenRailParent({
    required DashboardTimeNavigationState candidate,
    required DashboardTimeNavigationChangeDirection direction,
    required CurrentLedgerQueryScope parentScope,
    required TimeChildPeriod childPeriod,
    required int transitionGeneration,
    required int presentationEpoch,
    required bool cacheHit,
  }) async {
    final bundle = await summaryMetrics.prepareParentDisplayBundle(
      parentScope: parentScope,
      childPeriod: childPeriod,
      source: 'parentNavigationWhileRailOpen',
    );
    if (_disposed ||
        !_seedReady ||
        transitionGeneration != _openRailParentTransitionGeneration ||
        !rail.state.isRailOpen ||
        bundle == null ||
        !bundle.isComplete) {
      return;
    }
    _finishOpenRailParentTransition(
      candidate: candidate,
      direction: direction,
      parentScope: parentScope,
      presentationEpoch: presentationEpoch,
      transitionGeneration: transitionGeneration,
      cacheHit: cacheHit,
    );
  }

  void _finishOpenRailParentTransition({
    required DashboardTimeNavigationState candidate,
    required DashboardTimeNavigationChangeDirection direction,
    required CurrentLedgerQueryScope parentScope,
    required int presentationEpoch,
    required int transitionGeneration,
    required bool cacheHit,
  }) {
    if (_disposed ||
        transitionGeneration != _openRailParentTransitionGeneration ||
        !rail.state.isRailOpen) {
      return;
    }
    if (_parentPreviewDirection != direction && !previewParent(direction)) {
      _parentDeckMismatchPrevented += 1;
      return;
    }
    final target = presentationStore.visibleTarget;
    final childKey = candidate.isRailOpen
        ? presentationStore.activeSnapshot?.queryKey
        : null;
    if (target == null ||
        target.parentQueryKey != parentScope.key ||
        target.expectedVisibleQueryKey != childKey ||
        childKey == null) {
      _parentDeckMismatchPrevented += 1;
      return;
    }
    DashboardQueryDebug.mark(
      'PARENT_BUNDLE_SELECTED',
      scope: parentScope,
      detail:
          'visibleParentQueryKey=${parentScope.key.value} '
          'deckParentQueryKey=${parentScope.key.value} '
          'expectedVisibleQueryKey=${childKey.value} '
          'snapshotQueryKey=${childKey.value} accepted=true '
          'railOpen=true targetParent=${parentScope.key.value} '
          'child=${childKey.value} cacheHit=$cacheHit childBundle=true '
          'repositoryReadStarted=${!cacheHit} '
          'presentationEpoch=$presentationEpoch deckEpoch=${rail.state.deckEpoch} '
          'parentNavigationRevision=${rail.state.navigationRevision}',
    );
    publishParentMotionIdle();
    publishParentMotionSettle();
    // A parent replacement invalidates any in-flight child motion callback.
    railMotion.invalidate();
    summaryMetrics.pinParentBundle(
      parentScope: parentScope,
      childPeriod: _childPeriodFor(candidate),
    );
    rail.commitParentWhileRailOpen(direction);
    _atomicParentChildPublishes += 1;
    _parentPreviewState = null;
    _parentPreviewDirection = null;
    _summaryNavigationNotifier.notifyListeners();
    DashboardQueryDebug.mark(
      'PARENT_BUNDLE_PUBLISHED',
      scope: parentScope,
      detail:
          'atomic=true railOpen=true parentQueryKey=${parentScope.key.value} '
          'childQueryKey=${childKey.value} childBundle=true '
          'presentationEpoch=$presentationEpoch deckEpoch=${rail.state.deckEpoch} '
          'parentNavigationRevision=${rail.state.navigationRevision} '
          'visibleParentQueryKey=${parentScope.key.value} '
          'deckParentQueryKey=${parentScope.key.value} '
          'expectedVisibleQueryKey=${childKey.value} '
          'snapshotQueryKey=${childKey.value} accepted=true',
    );
  }

  void publishRailMotionIdle(int logicalIndex) {
    final epoch = railMotion.currentEpoch?.id;
    if (epoch == null) return;
    if (railMotion.publishIdle(epoch: epoch, logicalIndex: logicalIndex)) {
      DashboardSummaryTimingDebug.mark('R2 SCROLL_ACTIVITY_IDLE');
      adjacentParentPrewarm.endMotion();
    }
  }

  bool publishRailMotionSettle(int logicalIndex) {
    final epoch = railMotion.currentEpoch?.id;
    if (epoch == null) return true;
    final accepted = railMotion.publishSettle(
      epoch: epoch,
      logicalIndex: logicalIndex,
    );
    if (accepted) {
      DashboardSummaryTimingDebug.mark('RAIL_SETTLE_COMMITTED');
    }
    return accepted;
  }

  void _handleRailChanged() {
    // This is a narrow navigation-only signal. It lets the SummaryPill read
    // committed rail text without rebuilding the dashboard root.
    _summaryNavigationNotifier.notifyListeners();
    // Preview is presentation-only. Let the SummaryPill observe the rail
    // directly, but keep it out of the aggregate dashboard listener so a
    // fast child fling cannot rebuild the motion host, amount region or query
    // pipeline for every crossed index.
    if (rail.state.navigationRevision == _lastHandledRailNavigationRevision) {
      return;
    }
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    if (rail.state.lastChange.kind == DashboardTimeNavigationChangeKind.rail &&
        !rail.state.isRailOpen) {
      railMotion.invalidate();
    }
    if (!_queryStarted) return;
    final previousScope = query.state.scope.timeScope;
    final nextScope = rail.state.effectiveScope;
    if (previousScope != nextScope) {
      DashboardSummaryTimingDebug.mark(
        'S4 effectiveScopeEmitted',
        value: nextScope,
      );
      DashboardQueryDebug.mark(
        'R4 QUERY_SCOPE_COMMITTED',
        scope: query.state.scope.copyWith(timeScope: nextScope),
        detail: 'reason=${_railQueryReason()}',
      );
      final reason = _railQueryReason();
      if (rail.state.lastChange.kind ==
          DashboardTimeNavigationChangeKind.rail) {
        // SummaryMetrics observes the same navigation notification after this
        // listener. Defer the committed query/watch transition so a prepared
        // child or parent snapshot becomes visible before any live lease or
        // native watch can run during rail open/close.
        final navigationRevision = rail.state.navigationRevision;
        Future<void>.microtask(() {
          if (!_disposed &&
              _queryStarted &&
              rail.state.navigationRevision == navigationRevision &&
              rail.state.effectiveScope == nextScope) {
            query.setTimeScope(nextScope, reason: reason);
          }
        });
        // Rail open/close is a semantic dashboard event even though the
        // query transition is deliberately deferred behind the prepared
        // presentation snapshot. Preserve the core listener contract now;
        // preview crossings still return through the no-root-rebuild path.
        notifyListeners();
      } else if (rail.state.lastChange.kind ==
          DashboardTimeNavigationChangeKind.parent) {
        // Horizontal parent navigation prepares the target summary and child
        // bundle before committing the query scope. The navigation lane may
        // move immediately, but the visible presentation remains the
        // complete outgoing snapshot until this future is ready.
        final navigationRevision = rail.state.navigationRevision;
        final parentScope = query.state.scope.copyWith(
          timeScope: rail.state.parentScope,
        );
        unawaited(
          _prepareAndCommitParent(
            parentScope: parentScope,
            navigationRevision: navigationRevision,
            reason: reason,
          ),
        );
        notifyListeners();
      } else if (rail.state.lastChange.kind ==
          DashboardTimeNavigationChangeKind.parentWhileRailOpen) {
        final reason = 'parentCommittedWhileRailOpen';
        // The complete target child was published before the structural rail
        // transition. Defer the query call one microtask so the visible
        // publication and its diagnostic precede any live refresh work.
        final navigationRevision = rail.state.navigationRevision;
        Future<void>.microtask(() {
          if (!_disposed &&
              _queryStarted &&
              rail.state.navigationRevision == navigationRevision &&
              rail.state.effectiveScope == nextScope) {
            query.setTimeScope(nextScope, reason: reason);
          }
        });
        notifyListeners();
      } else {
        query.setTimeScope(nextScope, reason: reason);
      }
      DashboardSummaryTimingDebug.mark('S5 queryScopeSet', value: nextScope);
      return;
    }
    // A committed plane/data-source transition can leave the canonical scope
    // unchanged. It still needs one dashboard rebuild, unlike preview.
    notifyListeners();
  }

  String _railQueryReason() => switch (rail.state.lastChange.kind) {
    DashboardTimeNavigationChangeKind.rail =>
      rail.state.isRailOpen ? 'railOpened' : 'railClosed',
    DashboardTimeNavigationChangeKind.plane => 'planeCommitted',
    DashboardTimeNavigationChangeKind.parent => 'parentCommitted',
    DashboardTimeNavigationChangeKind.parentWhileRailOpen =>
      'parentCommittedWhileRailOpen',
    DashboardTimeNavigationChangeKind.child => 'childSettled',
    DashboardTimeNavigationChangeKind.initial => 'initial',
  };

  Future<void> _prepareAndCommitParent({
    required CurrentLedgerQueryScope parentScope,
    required int navigationRevision,
    required String reason,
  }) async {
    DashboardQueryDebug.mark(
      'PARENT_NAVIGATION_STARTED',
      scope: parentScope,
      detail:
          'navigationRevision=$navigationRevision target=${parentScope.key.value}',
    );
    final childPeriod = switch (rail.state.plane) {
      TimePlane.sum => TimeChildPeriod.year,
      TimePlane.year => TimeChildPeriod.month,
      TimePlane.month => TimeChildPeriod.day,
    };
    final bundle = await summaryMetrics.prepareParentDisplayBundle(
      parentScope: parentScope,
      childPeriod: childPeriod,
      source: 'parentNavigation',
    );
    if (_disposed ||
        !_queryStarted ||
        rail.state.navigationRevision != navigationRevision ||
        rail.state.parentScope != parentScope.timeScope ||
        bundle == null ||
        !bundle.isComplete) {
      return;
    }
    summaryMetrics.pinParentBundle(
      parentScope: parentScope,
      childPeriod: childPeriod,
    );
    query.setTimeScope(parentScope.timeScope, reason: reason);
    DashboardQueryDebug.mark(
      'PARENT_BUNDLE_PUBLISHED',
      scope: parentScope,
      result: bundle.parentSnapshot.hasValue
          ? DashboardLedgerResult(
              totalMinor: bundle.parentSnapshot.totalMinor!,
              entryCount: bundle.parentSnapshot.entryCount!,
              coreRevision: bundle.parentSnapshot.coreRevision,
              scopeKey: bundle.parentSnapshot.queryKey.value,
            )
          : null,
      detail: 'atomic=true childBundle=${bundle.childPreviewBundle != null}',
    );
    _scheduleAdjacentParentPrewarm();
  }

  TimeChildPeriod _childPeriodFor(DashboardTimeNavigationState navigation) =>
      switch (navigation.plane) {
        TimePlane.sum => TimeChildPeriod.year,
        TimePlane.year => TimeChildPeriod.month,
        TimePlane.month => TimeChildPeriod.day,
      };

  void _scheduleAdjacentParentPrewarm() {
    adjacentParentPrewarm.schedule((_) => _prewarmAdjacentParents());
  }

  Future<void> _prewarmAdjacentParents() async {
    final navigation = rail.state;
    final directions = <DashboardTimeNavigationChangeDirection>[
      DashboardTimeNavigationChangeDirection.backward,
      DashboardTimeNavigationChangeDirection.forward,
    ];
    for (final direction in directions) {
      final candidate = rail.parentPreview(direction);
      if (candidate == null ||
          _disposed ||
          adjacentParentPrewarm.isMotionActive) {
        return;
      }
      final parentScope = query.state.scope.copyWith(
        timeScope: candidate.parentScope,
      );
      final childPeriod = switch (candidate.plane) {
        TimePlane.sum => TimeChildPeriod.year,
        TimePlane.year => TimeChildPeriod.month,
        TimePlane.month => TimeChildPeriod.day,
      };
      await summaryMetrics.prepareParentDisplayBundle(
        parentScope: parentScope,
        childPeriod: childPeriod,
        source: 'adjacentParentPrewarm',
      );
      if (_disposed ||
          rail.state.navigationRevision != navigation.navigationRevision) {
        return;
      }
    }
  }

  void _handleDirectionChanged() {
    if (!_queryStarted) return;
    final direction =
        transactionDirection.direction == TransactionDirection.income
        ? LedgerDirection.income
        : LedgerDirection.expense;
    query.setDirection(direction);
    final opposite = direction == LedgerDirection.income
        ? LedgerDirection.expense
        : LedgerDirection.income;
    Future<void>.microtask(() {
      if (_disposed) return;
      query.prewarm(
        query.state.scope.copyWith(direction: opposite),
        reason: 'directionToggleOpposite',
      );
    });
  }

  @override
  void dispose() {
    _disposed = true;
    adjacentParentPrewarm.dispose();
    expansion.removeListener(_forwardChildNotification);
    rail.removeListener(_handleRailChanged);
    transactionDirection.removeListener(_handleDirectionChanged);
    query.removeListener(_forwardChildNotification);
    summaryMetrics.dispose();
    logPaging.dispose();
    logPresentation.dispose();
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    query.dispose();
    presentationStore.dispose();
    _summaryNavigationNotifier.dispose();
    super.dispose();
  }
}
