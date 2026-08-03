import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import 'dashboard_summary_amount_controller.dart';
import 'dashboard_parent_display_bundle_controller.dart';
import 'dashboard_parent_display_bundle.dart';
import 'dashboard_startup_warmup_coordinator.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';
import '../query/application/current_query_controller.dart';
import '../query/application/dashboard_live_query_lease_coordinator.dart';
import '../query/application/dashboard_query_debug.dart';
import '../query/data/dashboard_ledger_repository.dart';
import '../query/data/dashboard_child_summary_repository.dart';
import '../logbox/application/dashboard_log_page_coordinator.dart';
import '../logbox/data/dashboard_log_repository.dart';
import '../query/domain/current_ledger_query_scope.dart';
import '../query/domain/ledger_direction.dart';
import '../time_navigation/application/summary_timing_debug.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import '../time_navigation/domain/ledger_time_scope.dart';
import '../time_navigation/domain/time_plane.dart';
import '../time_navigation/domain/year_month.dart';
import '../../../shared/motion/centered_carousel/centered_carousel_motion.dart';

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  static const _sumPreviewCoverageRadius = 200;

  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardLedgerRepository? queryRepository,
    DateTime? initialDate,
    this.autoStart = true,
  }) : expansion = DashboardExpansionController(metrics: metrics),
       rail = DashboardRailController(
         initialDate: initialDate,
         initialPlane: TimePlane.month,
       ),
       transactionDirection = TransactionDirectionController() {
    final repository =
        queryRepository ?? const EmptyDashboardLedgerRepository();
    query = CurrentQueryController(
      repository: repository,
      initialScope: CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: rail.state.effectiveScope,
      ),
    );
    liveQueryLeases = DashboardLiveQueryLeaseCoordinator(
      activateLease: (scope) {
        if (_disposed) return;
        query.activateLiveLease(scope, reason: 'railInteractionQuiescent');
      },
    );
    parentDisplayBundles = repository is DashboardParentDisplayBundleRepository
        ? DashboardParentDisplayBundleController(
            repository: repository as DashboardParentDisplayBundleRepository,
          )
        : null;
    summaryMetrics = DashboardSummaryMetricsController(
      navigation: rail,
      query: query,
      childSummaryRepository: repository is DashboardChildSummaryRepository
          ? repository as DashboardChildSummaryRepository
          : null,
      parentDisplayBundles: parentDisplayBundles,
    );
    logBox = DashboardLogPageCoordinator(
      query: query,
      repository: repository is DashboardLogPageRepository
          ? repository as DashboardLogPageRepository
          : null,
      previewMetrics: summaryMetrics,
      navigation: rail,
      previewBundles: parentDisplayBundles,
    );
    startupWarmup = DashboardStartupWarmupCoordinator(
      ensureCurrentBundle: _ensureCurrentBundleForStartup,
      warmCurrentAndAdjacentCategoryAssets: (bundle) async {
        final warmer = _warmCategorySvgAssets;
        if (warmer == null) return;
        await warmer(_categoryIconIdsForCurrentAndAdjacent(bundle));
      },
      prewarmAdjacentBundles: _prewarmAdjacentFiniteBundles,
      isCriticalMotionActive: () =>
          expansion.isDragging || rail.timeCarousel.isScrolling,
      motionListenable: Listenable.merge([expansion, rail.timeCarousel]),
    );
    expansion.addListener(_forwardChildNotification);
    rail.addListener(_handleRailChanged);
    rail.timeCarousel.motionNotifier.addListener(_handleRailMotionChanged);
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    transactionDirection.addListener(_handleDirectionChanged);
    query.addListener(_forwardChildNotification);
    parentDisplayBundles?.addListener(_forwardChildNotification);
    if (autoStart) {
      _ensureFiniteDisplayBundle();
      query.refresh();
    }
  }

  /// The single metric source shared by dashboard geometry and expansion state.
  final DashboardLayoutMetrics metrics;

  /// Production app bootstrap passes false so the first query cannot race a
  /// debug seed or render an unbound loading scope. Legacy/test consumers keep
  /// the historical eager behavior by default.
  final bool autoStart;

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;
  late final CurrentQueryController query;
  late final DashboardLiveQueryLeaseCoordinator liveQueryLeases;
  late final DashboardLogPageCoordinator logBox;
  late final DashboardSummaryMetricsController summaryMetrics;
  late final DashboardStartupWarmupCoordinator startupWarmup;
  DashboardParentDisplayBundleController? parentDisplayBundles;
  late int _lastHandledRailNavigationRevision;
  RailMotionSnapshot? _lastHandledRailMotion;
  int _parentNavigationGeneration = 0;
  int _planeNavigationGeneration = 0;
  int _directionTransitionGeneration = 0;
  Future<void>? _initialDisplayBootstrap;
  bool _initialDisplayReady = false;
  final Set<String> _adjacentPrewarmScheduled = <String>{};
  bool _isDirectionTransitionInFlight = false;
  bool _disposed = false;
  Future<void> Function(Iterable<String> iconIds)? _warmCategorySvgAssets;

  /// The rail viewport must exist only when its currently displayed child has
  /// a complete immutable deck snapshot. This is a presentation-readiness
  /// query: it performs no I/O and does not take ownership of rail motion.
  bool get canRenderTimeRail {
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(rail.state);
    if (bundles == null || request == null) return true;
    final displayedScope = query.state.scope.copyWith(
      timeScope: rail.state.effectiveScope,
    );
    return bundles.canServeFinitePreview(displayedScope);
  }

  /// Direction data is staged behind a complete finite deck and exact first
  /// page. The existing rail motor remains visible but cannot accept input
  /// until that one atomic data handoff is complete.
  bool get isTimeRailInteractive => !_isDirectionTransitionInFlight;

  void _forwardChildNotification() => notifyListeners();

  void _handleRailMotionChanged() {
    final motion = rail.timeCarousel.motion;
    final previous = _lastHandledRailMotion;
    if (previous != null &&
        previous.epoch == motion.epoch &&
        previous.origin == motion.origin &&
        previous.state == motion.state) {
      return;
    }
    _lastHandledRailMotion = motion;
    liveQueryLeases.onMotion(motion);
  }

  void _handleRailChanged() {
    // Preview is presentation-only. Let the SummaryPill observe the rail
    // directly, but keep it out of the aggregate dashboard listener so a
    // fast child fling cannot rebuild the motion host, amount region or query
    // pipeline for every crossed index.
    if (rail.state.navigationRevision == _lastHandledRailNavigationRevision) {
      return;
    }
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    _ensureFiniteDisplayBundle();
    final nextScope = rail.state.effectiveScope;
    final nextQueryScope = query.state.scope.copyWith(timeScope: nextScope);
    DashboardQueryDebug.mark(
      'RAIL_SCOPE_PROJECTION',
      scope: nextQueryScope,
      detail:
          'change=${rail.state.lastChange.kind.name} '
          'plane=${rail.state.plane.name} railOpen=${rail.state.isRailOpen} '
          'parent=${rail.state.parentScope.canonicalKey} '
          'child=${rail.state.childScope.canonicalKey} '
          'logical=${rail.selectedChildLogicalIndex} '
          'physical=${rail.timeCarousel.selectedPhysicalIndex} '
          'motionEpoch=${rail.timeCarousel.motion.epoch} '
          'motion=${rail.timeCarousel.motion.state.name}',
    );
    if (nextQueryScope != query.state.scope) {
      DashboardSummaryTimingDebug.mark(
        'S4 effectiveScopeEmitted',
        value: nextScope,
      );
      if (DashboardQueryDebug.isEnabled) {
        DashboardQueryDebug.mark(
          'R4 QUERY_SCOPE_COMMITTED',
          scope: nextQueryScope,
          detail: 'reason=${_railQueryReason()}',
        );
      }
      final changeKind = rail.state.lastChange.kind;
      if (changeKind == DashboardTimeNavigationChangeKind.child) {
        // A child display snapshot is already exact at this point. Queue only
        // its expensive repository observation behind the motion boundary.
        liveQueryLeases.request(
          nextQueryScope,
          motionEpoch: rail.timeCarousel.motion.epoch,
        );
      } else if (changeKind != DashboardTimeNavigationChangeKind.rail ||
          !rail.state.isRailOpen) {
        if (parentDisplayBundles == null) {
          // Keep the historical behavior for repository implementations that
          // cannot supply an atomic finite deck. Production never uses this
          // path, but it keeps the legacy adapter's scope contract intact.
          liveQueryLeases.cancelPending();
          query.activateLiveLease(nextQueryScope, reason: _railQueryReason());
          notifyListeners();
          return;
        }
        // Plane and parent transitions are staged with their exact first page
        // before navigation commits. Promote that cache entry now, but leave
        // observation to the same latest-wins idle lease as child settles.
        // This keeps a new scope out of the rail-motion critical path.
        final promoted = query.commitPreparedScope(
          nextQueryScope,
          reason: _railQueryReason(),
        );
        DashboardQueryDebug.mark(
          'DISPLAY_SCOPE_COMMIT',
          scope: nextQueryScope,
          detail:
              'reason=${_railQueryReason()} prepared=$promoted '
              'motion=${rail.timeCarousel.motion.state.name}',
        );
        liveQueryLeases.request(
          nextQueryScope,
          motionEpoch: rail.timeCarousel.motion.epoch,
        );
      }
      DashboardSummaryTimingDebug.mark(
        'S5 queryScopeHandled',
        value: nextScope,
      );
      // One notification for a committed intent is allowed. Preview ticks
      // never enter this path, so the rail viewport remains isolated.
      notifyListeners();
      return;
    }
    // A committed plane/data-source transition can leave the canonical scope
    // unchanged. It still needs one dashboard rebuild, unlike preview.
    notifyListeners();
  }

  /// Binds the initial exact first page and finite child deck before the app
  /// exposes an interactive dashboard. This is display-only: detailed native
  /// observation is scheduled separately by [scheduleInitialLiveLease].
  Future<void> bootstrapInitialDisplay() =>
      _initialDisplayBootstrap ??= _bootstrapInitialDisplay();

  Future<void> _bootstrapInitialDisplay() async {
    final initialScope = query.state.scope;
    DashboardQueryDebug.mark(
      'BOOTSTRAP_DISPLAY_STARTED',
      scope: initialScope,
      detail: 'plane=${rail.state.plane.name} autoStart=$autoStart',
    );
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(rail.state);
    final firstPageFuture = query.prefetchFirstDayGroupPage(
      initialScope,
      reason: 'bootstrapInitialDisplay',
    );
    final bundleFuture = bundles == null || request == null
        ? Future<DashboardParentDisplayBundle?>.value()
        : bundles
              .prewarmFiniteBundle(
                parentScope: request.parentScope,
                plane: request.plane,
                expectedChildren: request.expectedChildren,
              )
              .then<DashboardParentDisplayBundle?>((bundle) => bundle);
    final ready = await Future.wait<Object?>([firstPageFuture, bundleFuture]);
    if (_disposed) return;
    final firstPage = ready.first as DashboardLedgerResult?;
    final bundle = ready.last as DashboardParentDisplayBundle?;
    if (firstPage == null) {
      DashboardQueryDebug.mark(
        'BOOTSTRAP_FAILED',
        scope: initialScope,
        detail: 'missingInitialFirstPage=true',
      );
      throw StateError('Bootstrap display requires an exact first page.');
    }
    if (bundle != null &&
        firstPage.coreRevision != null &&
        firstPage.coreRevision != bundle.key.coreRevision) {
      DashboardQueryDebug.mark(
        'BOOTSTRAP_FAILED',
        scope: initialScope,
        result: firstPage,
        detail:
            'revisionMismatch firstPage=${firstPage.coreRevision} '
            'bundle=${bundle.key.coreRevision}',
      );
      throw StateError('Bootstrap first page and finite deck disagree.');
    }
    if (bundle != null) bundles!.activatePreparedBundle(bundle, notify: false);
    if (!query.bindPreparedFirstDayGroupPage(
      initialScope,
      firstPage,
      reason: 'bootstrapInitialDisplay',
    )) {
      DashboardQueryDebug.mark(
        'BOOTSTRAP_FAILED',
        scope: initialScope,
        result: firstPage,
        detail: 'preparedInitialPageRejected=true',
      );
      throw StateError(
        'Bootstrap first page failed canonical identity checks.',
      );
    }
    _initialDisplayReady = true;
    DashboardQueryDebug.mark(
      'BOOTSTRAP_DISPLAY_READY',
      scope: initialScope,
      result: firstPage,
      detail:
          'finiteBundle=${bundle != null} '
          'plane=${rail.state.plane.name} watchActive=false',
    );
    notifyListeners();
  }

  /// Starts the non-critical detailed observer after a concrete first frame
  /// exists. The lease is still latest-wins and cancels if rail motion starts.
  void scheduleInitialLiveLease() {
    if (_disposed || !_initialDisplayReady) return;
    liveQueryLeases.request(
      query.state.scope,
      motionEpoch: rail.timeCarousel.motion.epoch,
    );
  }

  String _railQueryReason() => switch (rail.state.lastChange.kind) {
    DashboardTimeNavigationChangeKind.rail =>
      rail.state.isRailOpen ? 'railOpened' : 'railClosed',
    DashboardTimeNavigationChangeKind.plane => 'planeCommitted',
    DashboardTimeNavigationChangeKind.parent => 'parentCommitted',
    DashboardTimeNavigationChangeKind.child => 'childSettled',
    DashboardTimeNavigationChangeKind.initial => 'initial',
  };

  /// Defers a finite horizontal commit until its whole target deck exists.
  /// The old navigation state and active bundle therefore stay coherent while
  /// a target is loading; the ready bundle becomes active immediately before
  /// the one navigation publication that changes label, amount/count and
  /// LogBox scope together.
  void requestParentNext() =>
      _requestParentNavigation(DashboardTimeNavigationChangeDirection.forward);

  void requestParentPrevious() =>
      _requestParentNavigation(DashboardTimeNavigationChangeDirection.backward);

  /// Stages a finer time plane (SUM -> YEAR -> MONTH) before its datasource
  /// becomes visible. The rail can therefore never render a year source under
  /// a month/day projection, or vice versa.
  void requestFinerPlane() =>
      _requestPlaneNavigation(DashboardTimeNavigationChangeDirection.forward);

  /// Stages a broader time plane (MONTH -> YEAR -> SUM) before commit.
  void requestBroaderPlane() =>
      _requestPlaneNavigation(DashboardTimeNavigationChangeDirection.backward);

  void _requestPlaneNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    _parentNavigationGeneration += 1;
    final targetState = rail.planePreview(direction);
    if (targetState == null) return;
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(targetState);
    final targetScope = query.state.scope.copyWith(
      timeScope: targetState.effectiveScope,
    );
    if (bundles == null || request == null) {
      DashboardQueryDebug.mark(
        'PLANE_TRANSITION_UNSTAGED',
        scope: targetScope,
        detail: 'direction=${direction.name} reason=legacyRepository',
      );
      _commitPlaneNavigation(direction);
      return;
    }
    final generation = ++_planeNavigationGeneration;
    DashboardQueryDebug.mark(
      'PLANE_TRANSITION_CANDIDATE',
      scope: targetScope,
      detail:
          'direction=${direction.name} '
          'from=${rail.state.plane.name} to=${targetState.plane.name} '
          'parent=${request.parentScope.timeScope.canonicalKey} '
          'children=${request.expectedChildren.length} generation=$generation',
    );
    final deckFuture = bundles.prewarmFiniteBundle(
      parentScope: request.parentScope,
      plane: request.plane,
      expectedChildren: request.expectedChildren,
    );
    final firstPageFuture = query.prefetchFirstDayGroupPage(
      targetScope,
      reason: 'planeTransitionReady',
    );
    unawaited(
      (() async {
        try {
          final bundle = await deckFuture;
          final firstPage = await firstPageFuture;
          if (_disposed || generation != _planeNavigationGeneration) return;
          if (firstPage == null ||
              (firstPage.coreRevision != null &&
                  firstPage.coreRevision != bundle.key.coreRevision)) {
            DashboardQueryDebug.mark(
              'PLANE_TRANSITION_REJECTED',
              scope: targetScope,
              result: firstPage,
              detail: 'generation=$generation reason=missingOrStaleFirstPage',
            );
            return;
          }
          DashboardQueryDebug.mark(
            'PLANE_PREWARM_READY',
            scope: targetScope,
            result: firstPage,
            detail:
                'direction=${direction.name} plane=${targetState.plane.name} '
                'generation=$generation',
          );
          bundles.activatePreparedBundle(bundle, notify: false);
          DashboardQueryDebug.mark(
            'PLANE_TRANSITION_COMMITTED',
            scope: targetScope,
            result: firstPage,
            detail:
                'direction=${direction.name} plane=${targetState.plane.name} '
                'generation=$generation',
          );
          _commitPlaneNavigation(direction);
          _scheduleAdjacentFinitePrewarmIfCurrent(request, bundle);
        } on Object catch (error) {
          DashboardQueryDebug.mark(
            'PLANE_TRANSITION_REJECTED',
            scope: targetScope,
            detail: 'generation=$generation reason=readError error=$error',
          );
          // The existing concrete deck remains mounted; a later navigation
          // intent can retry this target without a partial plane switch.
        }
      })(),
    );
  }

  void _commitPlaneNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    switch (direction) {
      case DashboardTimeNavigationChangeDirection.forward:
        rail.moveToFinerPlane();
      case DashboardTimeNavigationChangeDirection.backward:
        rail.moveToBroaderPlane();
      case DashboardTimeNavigationChangeDirection.none:
        return;
    }
  }

  void _requestParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    _planeNavigationGeneration += 1;
    final targetState = rail.parentPreview(direction);
    if (targetState == null) {
      DashboardQueryDebug.mark(
        'PARENT_SWIPE_BLOCKED',
        scope: query.state.scope,
        detail: 'direction=${direction.name} reason=noParentCandidate',
      );
      return;
    }
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(targetState);
    if (bundles == null || request == null) {
      DashboardQueryDebug.mark(
        'PARENT_SWIPE_ACCEPTED',
        scope: query.state.scope,
        detail:
            'direction=${direction.name} target=${targetState.parentScope.canonicalKey} '
            'deck=unavailable',
      );
      _commitParentNavigation(direction);
      return;
    }
    DashboardQueryDebug.mark(
      'PARENT_SWIPE_CANDIDATE',
      scope: request.parentScope,
      detail:
          'direction=${direction.name} plane=${request.plane.name} '
          'expectedChildren=${request.expectedChildren.length}',
    );
    DashboardQueryDebug.mark(
      'PARENT_SWIPE_ACCEPTED',
      scope: request.parentScope,
      detail:
          'direction=${direction.name} plane=${request.plane.name} '
          'preparedTarget=true',
    );
    final generation = ++_parentNavigationGeneration;
    final bundleFuture = bundles.prewarmFiniteBundle(
      parentScope: request.parentScope,
      plane: request.plane,
      expectedChildren: request.expectedChildren,
    );
    // A parent deck alone contains its finite child previews, not the full
    // parent LogBox page. Keep the old visible parent until the canonical
    // first page has also reached CurrentQueryController's cache; committing
    // both in one synchronous turn prevents a new label over stale rows.
    final targetScope = query.state.scope.copyWith(
      timeScope: targetState.effectiveScope,
    );
    final parentPageFuture = query.prefetchFirstDayGroupPage(
      targetScope,
      reason: 'parentNavigationReady',
    );
    unawaited(
      (() async {
        try {
          final bundle = await bundleFuture;
          final parentPage = await parentPageFuture;
          if (_disposed || generation != _parentNavigationGeneration) return;
          if (parentPage == null ||
              (parentPage.coreRevision != null &&
                  parentPage.coreRevision != bundle.key.coreRevision)) {
            DashboardQueryDebug.mark(
              'PARENT_SWIPE_REJECTED',
              scope: targetScope,
              result: parentPage,
              detail: 'generation=$generation reason=missingOrStaleFirstPage',
            );
            return;
          }
          DashboardQueryDebug.mark(
            'PARENT_PREWARM_READY',
            scope: targetScope,
            result: parentPage,
            detail:
                'direction=${direction.name} plane=${request.plane.name} '
                'generation=$generation',
          );
          bundles.activatePreparedBundle(bundle, notify: false);
          DashboardQueryDebug.mark(
            'PARENT_SWIPE_COMMITTED',
            scope: targetScope,
            result: parentPage,
            detail:
                'direction=${direction.name} plane=${request.plane.name} '
                'generation=$generation',
          );
          _commitParentNavigation(direction);
          _scheduleAdjacentFinitePrewarmIfCurrent(request, bundle);
        } on Object catch (error) {
          DashboardQueryDebug.mark(
            'PARENT_SWIPE_REJECTED',
            scope: targetScope,
            detail: 'generation=$generation reason=readError error=$error',
          );
          // The current displayed snapshot remains active and internally
          // consistent. A later user action may request this target again.
        }
      })(),
    );
  }

  void _commitParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    switch (direction) {
      case DashboardTimeNavigationChangeDirection.forward:
        rail.moveParentNext();
      case DashboardTimeNavigationChangeDirection.backward:
        rail.moveParentPrevious();
      case DashboardTimeNavigationChangeDirection.none:
        return;
    }
  }

  /// Starts non-critical startup work after the first interactive shell frame.
  /// The presentation layer supplies only SVG cache warming; this controller
  /// retains the sequencing and finite parent read ownership.
  Future<void> startStartupWarmup({
    required Future<void> Function(Iterable<String> iconIds)
    warmCategorySvgAssets,
  }) {
    // Existing dashboard consumers that have not opted into the finite bundle
    // repository retain their interactive shell. There is no current/adjacent
    // bundle to warm for that legacy path, so startup work is intentionally a
    // no-op rather than an asynchronous post-frame error.
    if (parentDisplayBundles == null) return Future<void>.value();
    _warmCategorySvgAssets ??= warmCategorySvgAssets;
    return startupWarmup.start();
  }

  void _handleDirectionChanged() {
    _parentNavigationGeneration += 1;
    _planeNavigationGeneration += 1;
    liveQueryLeases.cancelPending();
    final direction =
        transactionDirection.direction == TransactionDirection.income
        ? LedgerDirection.income
        : LedgerDirection.expense;
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(rail.state, direction: direction);

    // Non-finite/legacy repositories retain the existing committed-query
    // behavior. The no-placeholder contract is supplied by complete finite
    // display bundles when that capability is available.
    if (bundles == null || request == null) {
      _isDirectionTransitionInFlight = false;
      query.setDirection(direction);
      _ensureFiniteDisplayBundle();
      return;
    }

    final targetScope = query.state.scope.copyWith(direction: direction);
    final generation = ++_directionTransitionGeneration;
    if (targetScope == query.state.scope) {
      _isDirectionTransitionInFlight = false;
      notifyListeners();
      return;
    }

    _isDirectionTransitionInFlight = true;
    notifyListeners();
    final bundleFuture = bundles.prewarmFiniteBundle(
      parentScope: request.parentScope,
      plane: request.plane,
      expectedChildren: request.expectedChildren,
    );
    // The staged query uses the current committed time scope (the selected
    // child when the rail is open), never an arbitrary first child. That makes
    // the following setDirection a synchronous cache hit and prevents a
    // direction label over an empty LogBox.
    final firstPageFuture = query.prefetchFirstDayGroupPage(
      targetScope,
      reason: 'directionChangeReady',
    );
    unawaited(
      Future.wait<Object?>([bundleFuture, firstPageFuture]).then<void>(
        (ready) {
          if (_disposed || generation != _directionTransitionGeneration) {
            return;
          }
          final bundle = ready.first as DashboardParentDisplayBundle;
          final firstPage = ready.last as DashboardLedgerResult?;
          if (firstPage == null ||
              (firstPage.coreRevision != null &&
                  firstPage.coreRevision != bundle.key.coreRevision)) {
            _isDirectionTransitionInFlight = false;
            notifyListeners();
            return;
          }
          bundles.activatePreparedBundle(bundle, notify: false);
          _isDirectionTransitionInFlight = false;
          query.setDirection(direction);
        },
        onError: (error, stackTrace) {
          if (_disposed || generation != _directionTransitionGeneration) {
            return;
          }
          // Keep the already concrete income/expense snapshot visible on a
          // failed staged read. A subsequent direction selection retries.
          _isDirectionTransitionInFlight = false;
          notifyListeners();
        },
      ),
    );
  }

  /// Data-only warmup for an already resolved rail target. The shared carousel
  /// owns motion target calculation; this adapter merely maps that logical
  /// child through the application navigation state and never observes ticks.
  void prefetchLogForRailTarget(int logicalIndex) {
    if (!rail.state.isRailOpen || _isDirectionTransitionInFlight) return;
    final targetScope = query.state.scope.copyWith(
      timeScope: rail.childScopeForLogicalIndex(logicalIndex),
    );
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(rail.state);
    // A matching finite deck owns every child target from dispatch onward.
    // In particular, do not mistake its loading phase for a cache miss after
    // a direction change; doing so starts one legacy read per scroll tick.
    if (bundles != null &&
        request != null &&
        bundles.isFiniteBundleActiveOrLoading(
          parentScope: request.parentScope,
          plane: request.plane,
        )) {
      return;
    }
    if (bundles?.shouldFallbackToMotionTargetPrefetch(targetScope) == false) {
      return;
    }
    logBox.prefetchForMotionTarget(targetScope, reason: 'motionTargetResolved');
  }

  void _ensureFiniteDisplayBundle() {
    final bundles = parentDisplayBundles;
    final state = rail.state;
    final request = _finiteBundleRequestFor(state);
    if (bundles == null || request == null) return;
    unawaited(
      bundles
          .ensureFiniteBundle(
            parentScope: request.parentScope,
            plane: request.plane,
            expectedChildren: request.expectedChildren,
          )
          .then<void>((_) {}, onError: (Object _, StackTrace _) {}),
    );
  }

  void _scheduleAdjacentFinitePrewarmIfCurrent(
    ({
      CurrentLedgerQueryScope parentScope,
      TimePlane plane,
      List<CurrentLedgerQueryScope> expectedChildren,
    })
    request,
    DashboardParentDisplayBundle currentBundle,
  ) {
    if (_disposed) return;
    final current = _finiteBundleRequestFor(rail.state);
    if (current == null ||
        current.parentScope != request.parentScope ||
        current.plane != request.plane ||
        DashboardParentDisplayBundle.coverageKeyFor(current.expectedChildren) !=
            DashboardParentDisplayBundle.coverageKeyFor(
              request.expectedChildren,
            )) {
      return;
    }
    final key =
        '${request.parentScope.key.value}|${request.plane.name}|'
        '${DashboardParentDisplayBundle.coverageKeyFor(request.expectedChildren)}';
    if (!_adjacentPrewarmScheduled.add(key)) return;
    DashboardQueryDebug.mark(
      'DISPLAY_DECK_PREWARM_REQUESTED',
      scope: request.parentScope,
      detail: 'plane=${request.plane.name} adjacent=true',
    );
    unawaited(
      _prewarmAdjacentFiniteBundles(currentBundle).then<void>((_) {
        DashboardQueryDebug.mark(
          'DISPLAY_DECK_PREWARM_READY',
          scope: request.parentScope,
          detail: 'plane=${request.plane.name} adjacent=true',
        );
      }, onError: (_, _) {}),
    );
  }

  ({
    CurrentLedgerQueryScope parentScope,
    TimePlane plane,
    List<CurrentLedgerQueryScope> expectedChildren,
  })?
  _finiteBundleRequestFor(
    DashboardTimeNavigationState state, {
    LedgerDirection? direction,
  }) {
    final parentScope = query.state.scope.copyWith(
      direction: direction,
      timeScope: state.parentScope,
    );
    final expectedChildren = switch (state.plane) {
      TimePlane.month => List<CurrentLedgerQueryScope>.generate(
        state.monthCursor.daysInMonth,
        (index) => parentScope.copyWith(
          timeScope: DayScope(state.monthCursor.clampDay(index + 1)),
        ),
      ),
      TimePlane.year => List<CurrentLedgerQueryScope>.generate(
        12,
        (index) => parentScope.copyWith(
          timeScope: MonthScope(
            YearMonth(year: state.yearCursor, month: index + 1),
          ),
        ),
      ),
      // SUM has an infinite visual corridor, but a finite, explicit data
      // window. Every child in the normal-session corridor is populated or
      // verified-empty before the rail becomes interactive; a crossing never
      // starts a repository read.
      TimePlane.sum => List<CurrentLedgerQueryScope>.generate(
        _sumPreviewCoverageRadius * 2 + 1,
        (index) => parentScope.copyWith(
          timeScope: YearScope(
            state.settledChildYear - _sumPreviewCoverageRadius + index,
          ),
        ),
      ),
    };
    return (
      parentScope: parentScope,
      plane: state.plane,
      expectedChildren: expectedChildren,
    );
  }

  Future<DashboardParentDisplayBundle> _ensureCurrentBundleForStartup() {
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(rail.state);
    if (bundles == null || request == null) {
      return Future<DashboardParentDisplayBundle>.error(
        StateError(
          'Startup finite warmup requires a finite bundle repository.',
        ),
      );
    }
    return bundles.ensureFiniteBundle(
      parentScope: request.parentScope,
      plane: request.plane,
      expectedChildren: request.expectedChildren,
    );
  }

  Future<void> _prewarmAdjacentFiniteBundles(
    DashboardParentDisplayBundle _,
  ) async {
    final bundles = parentDisplayBundles;
    if (bundles == null) return;
    final requests =
        <
          ({
            CurrentLedgerQueryScope parentScope,
            TimePlane plane,
            List<CurrentLedgerQueryScope> expectedChildren,
            CurrentLedgerQueryScope displayScope,
          })
        >[];
    for (final direction in const [
      DashboardTimeNavigationChangeDirection.backward,
      DashboardTimeNavigationChangeDirection.forward,
    ]) {
      final target = rail.parentPreview(direction);
      if (target == null) continue;
      final request = _finiteBundleRequestFor(target);
      if (request != null) {
        requests.add((
          parentScope: request.parentScope,
          plane: request.plane,
          expectedChildren: request.expectedChildren,
          displayScope: query.state.scope.copyWith(
            timeScope: target.effectiveScope,
          ),
        ));
      }
    }
    // Adjacent decks are non-critical warming. Do not enqueue two whole
    // Room/channel transactions at once beside the first interactive rail
    // frames; direction A becomes immediately swipe-ready, then direction B
    // follows without competing for the main-isolate bridge callbacks.
    for (final request in requests) {
      if (_disposed || rail.timeCarousel.motion.state != RailMotionState.idle) {
        return;
      }
      await bundles.prewarmFiniteBundle(
        parentScope: request.parentScope,
        plane: request.plane,
        expectedChildren: request.expectedChildren,
      );
      if (_disposed || rail.timeCarousel.motion.state != RailMotionState.idle) {
        return;
      }
      await query.prefetchFirstDayGroupPage(
        request.displayScope,
        reason: 'startupAdjacentParentReady',
      );
    }
  }

  Iterable<String> _categoryIconIdsForCurrentAndAdjacent(
    DashboardParentDisplayBundle bundle,
  ) sync* {
    final state = rail.state;
    final childCount = switch (state.plane) {
      TimePlane.month => state.monthCursor.daysInMonth,
      TimePlane.year => 12,
      TimePlane.sum => 0,
    };
    final selected = rail.selectedChildLogicalIndex;
    for (final logicalIndex in [selected - 1, selected, selected + 1]) {
      if (logicalIndex < 0 || logicalIndex >= childCount) continue;
      final childScope = switch (state.plane) {
        TimePlane.month => bundle.parentScope.copyWith(
          timeScope: DayScope(state.monthCursor.clampDay(logicalIndex + 1)),
        ),
        TimePlane.year => bundle.parentScope.copyWith(
          timeScope: MonthScope(
            YearMonth(year: state.yearCursor, month: logicalIndex + 1),
          ),
        ),
        TimePlane.sum => null,
      };
      if (childScope == null) continue;
      final snapshot = bundle.childDeck.snapshotFor(childScope);
      if (snapshot == null) continue;
      for (final group in snapshot.viewGroups) {
        for (final row in group.rows) {
          yield row.categoryIconId;
        }
      }
    }
  }

  @override
  void dispose() {
    _disposed = true;
    _parentNavigationGeneration += 1;
    _planeNavigationGeneration += 1;
    _directionTransitionGeneration += 1;
    startupWarmup.dispose();
    expansion.removeListener(_forwardChildNotification);
    rail.removeListener(_handleRailChanged);
    rail.timeCarousel.motionNotifier.removeListener(_handleRailMotionChanged);
    transactionDirection.removeListener(_handleDirectionChanged);
    query.removeListener(_forwardChildNotification);
    parentDisplayBundles?.removeListener(_forwardChildNotification);
    logBox.dispose();
    summaryMetrics.dispose();
    parentDisplayBundles?.dispose();
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    liveQueryLeases.dispose();
    query.dispose();
    super.dispose();
  }
}
