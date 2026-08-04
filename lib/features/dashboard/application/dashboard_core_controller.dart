import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import 'dashboard_summary_amount_controller.dart';
import 'dashboard_expansion_controller.dart';
import 'dashboard_rail_controller.dart';
import 'transaction_direction_controller.dart';
import '../logbox/application/dashboard_log_paging_coordinator.dart';
import '../logbox/application/dashboard_log_presentation_adapter.dart';
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

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardLedgerRepository? queryRepository,
    DateTime? initialDate,
    Duration liveQueryLeaseQuiescence = Duration.zero,
    bool autoStartQuery = true,
    DashboardPresentationDiagnostics? diagnostics,
  }) : expansion = DashboardExpansionController(metrics: metrics),
       presentationDiagnostics =
           diagnostics ?? DashboardPresentationDiagnostics(),
       rail = DashboardRailController(
         initialDate: initialDate,
         initialPlane: TimePlane.month,
       ),
       transactionDirection = TransactionDirectionController() {
    final repository =
        queryRepository ?? const EmptyDashboardLedgerRepository();
    presentationStore = DashboardPresentationStore();
    logPresentation = DashboardLogPresentationAdapter(store: presentationStore);
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
    );
    expansion.addListener(_forwardChildNotification);
    rail.addListener(_handleRailChanged);
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    transactionDirection.addListener(_handleDirectionChanged);
    query.addListener(_forwardChildNotification);
    if (autoStartQuery) {
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

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;
  late final DashboardPresentationStore presentationStore;
  late final DashboardLogPresentationAdapter logPresentation;
  late final DashboardLogPagingCoordinator logPaging;
  late final CurrentQueryController query;
  late final DashboardSummaryMetricsController summaryMetrics;
  late int _lastHandledRailNavigationRevision;
  bool _queryStarted = false;
  bool _disposed = false;
  Timer? _adjacentParentPrewarmTimer;

  /// Starts the query lane against the current navigation state. Seed-gated
  /// startup calls this only after the native seed transaction has committed.
  void startQuery({String reason = 'initial'}) {
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

  void _handleRailChanged() {
    // Preview is presentation-only. Let the SummaryPill observe the rail
    // directly, but keep it out of the aggregate dashboard listener so a
    // fast child fling cannot rebuild the motion host, amount region or query
    // pipeline for every crossed index.
    if (rail.state.navigationRevision == _lastHandledRailNavigationRevision) {
      return;
    }
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
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

  void _scheduleAdjacentParentPrewarm() {
    _adjacentParentPrewarmTimer?.cancel();
    _adjacentParentPrewarmTimer = Timer(Duration.zero, () {
      _adjacentParentPrewarmTimer = null;
      if (!_disposed) unawaited(_prewarmAdjacentParents());
    });
  }

  Future<void> _prewarmAdjacentParents() async {
    final navigation = rail.state;
    final directions = <DashboardTimeNavigationChangeDirection>[
      DashboardTimeNavigationChangeDirection.backward,
      DashboardTimeNavigationChangeDirection.forward,
    ];
    for (final direction in directions) {
      final candidate = rail.parentPreview(direction);
      if (candidate == null || _disposed) continue;
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
    _adjacentParentPrewarmTimer?.cancel();
    _adjacentParentPrewarmTimer = null;
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
    super.dispose();
  }
}
