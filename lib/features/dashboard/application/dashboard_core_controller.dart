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

/// Aggregates the dashboard's only shared temporary-state owners.
class DashboardCoreController extends ChangeNotifier {
  DashboardCoreController({
    this.metrics = DashboardLayoutMetrics.reference,
    DashboardLedgerRepository? queryRepository,
    DateTime? initialDate,
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
    _lastHandledRailNavigationRevision = rail.state.navigationRevision;
    transactionDirection.addListener(_handleDirectionChanged);
    query.addListener(_forwardChildNotification);
    _ensureFiniteDisplayBundle();
    query.refresh();
  }

  /// The single metric source shared by dashboard geometry and expansion state.
  final DashboardLayoutMetrics metrics;

  final DashboardExpansionController expansion;
  final DashboardRailController rail;
  final TransactionDirectionController transactionDirection;
  late final CurrentQueryController query;
  late final DashboardLogPageCoordinator logBox;
  late final DashboardSummaryMetricsController summaryMetrics;
  late final DashboardStartupWarmupCoordinator startupWarmup;
  DashboardParentDisplayBundleController? parentDisplayBundles;
  late int _lastHandledRailNavigationRevision;
  int _parentNavigationGeneration = 0;
  bool _disposed = false;
  Future<void> Function(Iterable<String> iconIds)? _warmCategorySvgAssets;

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
    _ensureFiniteDisplayBundle();
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
      query.setTimeScope(nextScope, reason: _railQueryReason());
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

  /// Defers a finite horizontal commit until its whole target deck exists.
  /// The old navigation state and active bundle therefore stay coherent while
  /// a target is loading; the ready bundle becomes active immediately before
  /// the one navigation publication that changes label, amount/count and
  /// LogBox scope together.
  void requestParentNext() =>
      _requestParentNavigation(DashboardTimeNavigationChangeDirection.forward);

  void requestParentPrevious() =>
      _requestParentNavigation(DashboardTimeNavigationChangeDirection.backward);

  void _requestParentNavigation(
    DashboardTimeNavigationChangeDirection direction,
  ) {
    final targetState = rail.parentPreview(direction);
    if (targetState == null) return;
    final bundles = parentDisplayBundles;
    final request = _finiteBundleRequestFor(targetState);
    if (bundles == null || request == null) {
      _commitParentNavigation(direction);
      return;
    }
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
    final parentPageFuture = query.prefetchFirstDayGroupPage(
      request.parentScope,
      reason: 'parentNavigationReady',
    );
    unawaited(
      Future.wait<Object?>([bundleFuture, parentPageFuture]).then<void>(
        (ready) {
          if (_disposed || generation != _parentNavigationGeneration) return;
          final bundle = ready.first as DashboardParentDisplayBundle;
          final parentPage = ready.last as DashboardLedgerResult?;
          if (parentPage == null ||
              (parentPage.coreRevision != null &&
                  parentPage.coreRevision != bundle.key.coreRevision)) {
            return;
          }
          bundles.activatePreparedBundle(bundle, notify: false);
          _commitParentNavigation(direction);
        },
        onError: (error, stackTrace) {
          // The current displayed snapshot remains active and internally
          // consistent. A later user action may request this target again.
        },
      ),
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
    query.setDirection(
      transactionDirection.direction == TransactionDirection.income
          ? LedgerDirection.income
          : LedgerDirection.expense,
    );
  }

  /// Data-only warmup for an already resolved rail target. The shared carousel
  /// owns motion target calculation; this adapter merely maps that logical
  /// child through the application navigation state and never observes ticks.
  void prefetchLogForRailTarget(int logicalIndex) {
    if (!rail.state.isRailOpen) return;
    final targetScope = query.state.scope.copyWith(
      timeScope: rail.childScopeForLogicalIndex(logicalIndex),
    );
    if (parentDisplayBundles?.shouldFallbackToMotionTargetPrefetch(
          targetScope,
        ) ==
        false) {
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
          .then<void>(
            (_) {},
            onError: (error, stackTrace) {
              // A failed background warmup must not make the rail state owner
              // fail; the existing scoped cache-miss UI remains the cold path.
            },
          ),
    );
  }

  ({
    CurrentLedgerQueryScope parentScope,
    TimePlane plane,
    List<CurrentLedgerQueryScope> expectedChildren,
  })?
  _finiteBundleRequestFor(DashboardTimeNavigationState state) {
    if (state.plane == TimePlane.sum) return null;
    final parentScope = query.state.scope.copyWith(
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
      TimePlane.sum => const <CurrentLedgerQueryScope>[],
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
          })
        >[];
    for (final direction in const [
      DashboardTimeNavigationChangeDirection.backward,
      DashboardTimeNavigationChangeDirection.forward,
    ]) {
      final target = rail.parentPreview(direction);
      if (target == null) continue;
      final request = _finiteBundleRequestFor(target);
      if (request != null) requests.add(request);
    }
    await Future.wait(
      requests.expand(
        (request) => <Future<Object?>>[
          bundles.prewarmFiniteBundle(
            parentScope: request.parentScope,
            plane: request.plane,
            expectedChildren: request.expectedChildren,
          ),
          query.prefetchFirstDayGroupPage(
            request.parentScope,
            reason: 'startupAdjacentParentReady',
          ),
        ],
      ),
    );
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
    startupWarmup.dispose();
    expansion.removeListener(_forwardChildNotification);
    rail.removeListener(_handleRailChanged);
    transactionDirection.removeListener(_handleDirectionChanged);
    query.removeListener(_forwardChildNotification);
    logBox.dispose();
    summaryMetrics.dispose();
    parentDisplayBundles?.dispose();
    expansion.dispose();
    rail.dispose();
    transactionDirection.dispose();
    query.dispose();
    super.dispose();
  }
}
