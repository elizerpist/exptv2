import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_area_state.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/performance/dashboard_performance_trace.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_summary_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _RenderProbe {
  int headerBuilds = 0;
  int railShellBuilds = 0;
  int logBoxBuilds = 0;

  void didBuildHeader() => headerBuilds += 1;

  void didBuildLogBox() => logBoxBuilds += 1;

  void didBuildRailShell() => railShellBuilds += 1;

  void reset() {
    headerBuilds = 0;
    railShellBuilds = 0;
    logBoxBuilds = 0;
  }
}

class _BuildCounter extends StatelessWidget {
  const _BuildCounter({required this.onBuild, required this.child});

  final VoidCallback onBuild;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    onBuild();
    return child;
  }
}

/// Minimal mounted presentation topology used to prove listener ownership.
/// It deliberately avoids dashboard motion/asset rendering, while retaining
/// the real core controllers and the same header/rail/summary/LogBox listener
/// boundaries as [CoreDashboard].
class _DashboardRenderBoundaryHarness extends StatelessWidget {
  const _DashboardRenderBoundaryHarness({
    required this.core,
    required this.probe,
  });

  final DashboardCoreController core;
  final _RenderProbe probe;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      _BuildCounter(
        onBuild: probe.didBuildHeader,
        child: const SizedBox(key: ValueKey('dashboard-header-shell')),
      ),
      _BuildCounter(
        onBuild: probe.didBuildRailShell,
        child: const SizedBox(key: ValueKey('dashboard-rail-shell')),
      ),
      ListenableBuilder(
        listenable: core.summaryMetrics,
        builder: (context, _) => Text(
          core.summaryMetrics.presentation.formattedAmount,
          key: const ValueKey('dashboard-summary-preview-amount'),
        ),
      ),
      ListenableBuilder(
        listenable: core.logBox,
        builder: (context, _) {
          probe.didBuildLogBox();
          return Text(
            core.logBox.state.queryKey,
            key: const ValueKey('dashboard-logbox-query-key'),
          );
        },
      ),
    ],
  );
}

/// Frame-level visual contract for a parent change. The three displayed values
/// are owned by separate real controllers, so an intermediate frame reveals a
/// mixed parent immediately without needing a platform SVG/compositor scene.
class _DashboardAtomicParentHarness extends StatelessWidget {
  _DashboardAtomicParentHarness({required DashboardCoreController core})
    : _core = core,
      _display = Listenable.merge([
        core.rail,
        core.summaryMetrics,
        core.logBox,
      ]);

  final DashboardCoreController _core;
  final Listenable _display;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: _display,
    builder: (context, _) => Column(
      children: [
        Text(
          'parent=${_core.rail.state.parentScope.canonicalKey}',
          key: const ValueKey('dashboard-parent-label'),
        ),
        Text(
          'amount=${_core.summaryMetrics.presentation.formattedAmount}',
          key: const ValueKey('dashboard-parent-amount'),
        ),
        Text(
          'log=${_core.logBox.state.queryKey}',
          key: const ValueKey('dashboard-parent-logbox-key'),
        ),
      ],
    ),
  );
}

class _RecordingDashboardRepository implements DashboardLedgerRepository {
  final requestedScopes = <LedgerTimeScope>[];
  int watchCount = 0;

  @override
  Future<DashboardLedgerResult> read(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    requestedScopes.add(scope.timeScope);
    return const DashboardLedgerResult(totalMinor: 0);
  }

  @override
  Stream<DashboardLedgerResult> watch(
    scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watchCount += 1;
    requestedScopes.add(scope.timeScope);
    yield const DashboardLedgerResult(totalMinor: 0);
  }
}

class _FiniteBundleDashboardRepository
    implements
        DashboardLedgerRepository,
        DashboardChildSummaryRepository,
        DashboardParentDisplayBundleRepository,
        DashboardLedgerFirstPagePrefetchRepository {
  int childSummaryReadCount = 0;
  int previewPrefetchCount = 0;
  int watchCount = 0;
  final bundleRequests = <DashboardParentDisplayBundleRequest>[];
  Completer<DashboardParentDisplayBundlePayload>? _deferredBundle;
  DashboardParentDisplayBundleRequest? _deferredRequest;
  Completer<DashboardLedgerResult>? _deferredFirstPage;
  CurrentLedgerQueryScope? _deferredFirstPageScope;

  void deferNextParentBundle() {
    _deferredBundle = Completer<DashboardParentDisplayBundlePayload>();
  }

  void completeDeferredParentBundle() {
    final completer = _deferredBundle;
    final request = _deferredRequest;
    if (completer == null || request == null) {
      throw StateError('No parent bundle is waiting to complete.');
    }
    _deferredBundle = null;
    _deferredRequest = null;
    completer.complete(_bundlePayloadFor(request));
  }

  void deferNextParentFirstPage() {
    _deferredFirstPage = Completer<DashboardLedgerResult>();
  }

  void completeDeferredParentFirstPage() {
    final completer = _deferredFirstPage;
    final scope = _deferredFirstPageScope;
    if (completer == null || scope == null) {
      throw StateError('No parent first page is waiting to complete.');
    }
    _deferredFirstPage = null;
    _deferredFirstPageScope = null;
    completer.complete(
      DashboardLedgerResult(
        totalMinor: 100,
        entryCount: 1,
        coreRevision: 41,
        scopeKey: scope.key.value,
      ),
    );
  }

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => DashboardLedgerResult(
    totalMinor: 100,
    entryCount: 1,
    coreRevision: 41,
    scopeKey: scope.key.value,
  );

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
    watchCount += 1;
    yield await read(scope, pageSize: pageSize, after: after);
  }

  @override
  Future<DashboardTimeChildSummaryIndex> readChildSummaries(
    DashboardChildSummaryRequest request,
  ) async {
    childSummaryReadCount += 1;
    return DashboardTimeChildSummaryIndex(
      parentQueryKey: request.parentScope.key.value,
      direction: request.parentScope.direction,
      childPeriod: request.childPeriod,
      coreRevision: 41,
      isComplete: true,
      values: const <String, DashboardTimeChildSummary>{},
    );
  }

  @override
  Future<DashboardParentDisplayBundlePayload> readParentDisplayBundle(
    DashboardParentDisplayBundleRequest request,
  ) async {
    bundleRequests.add(request);
    final deferred = _deferredBundle;
    if (deferred != null) {
      _deferredRequest = request;
      return deferred.future;
    }
    return _bundlePayloadFor(request);
  }

  DashboardParentDisplayBundlePayload _bundlePayloadFor(
    DashboardParentDisplayBundleRequest request,
  ) => DashboardParentDisplayBundlePayload(
    parentScope: request.parentScope,
    plane: request.plane,
    coreRevision: 41,
    snapshots: request.expectedChildren
        .where(
          (child) =>
              child.timeScope is! DayScope ||
              (child.timeScope as DayScope).date.day != 26,
        )
        .map((child) {
          final metrics = switch (child.timeScope) {
            MonthScope(:final value) => (
              totalMinor: 200000 + value.month * 1000,
              entryCount: value.month % 5 + 1,
            ),
            _ => (totalMinor: 100, entryCount: 1),
          };
          final localDate = switch (child.timeScope) {
            MonthScope(:final value) => LocalDate(
              year: value.year,
              month: value.month,
              day: 1,
            ),
            DayScope(:final date) => date,
            _ => const LocalDate(year: 2026, month: 1, day: 1),
          };
          final List<DashboardDayLogGroup> groups =
              child.timeScope is MonthScope
              ? [
                  DashboardDayLogGroup(
                    localDate: localDate,
                    rows: [
                      DashboardLedgerEntry(
                        id: '${child.key.value}-first-row',
                        partnerId: 'partner-1',
                        categoryId: 'category-1',
                        direction: child.direction.name,
                        amountMinor: metrics.totalMinor,
                        bookedLocalEpochDay: 20500 + localDate.day,
                        bookedLocalTimeMinutes: 720,
                      ),
                    ],
                  ),
                ]
              : const <DashboardDayLogGroup>[];
          return DashboardLogPreviewSnapshot.populated(
            scope: child,
            coreRevision: 41,
            totalMinor: metrics.totalMinor,
            entryCount: metrics.entryCount,
            groups: groups,
          );
        })
        .toList(growable: false),
  );

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  }) {
    previewPrefetchCount += 1;
    final deferred = _deferredFirstPage;
    if (deferred != null) {
      _deferredFirstPageScope = scope;
      return deferred.future;
    }
    return Future<DashboardLedgerResult>.value(
      DashboardLedgerResult(
        totalMinor: 100,
        entryCount: 1,
        coreRevision: 41,
        scopeKey: scope.key.value,
      ),
    );
  }
}

void main() {
  test(
    'bootstrap binds a concrete initial parent snapshot before live observation',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 7, 3),
        autoStart: false,
      );
      addTearDown(core.dispose);

      expect(repository.bundleRequests, isEmpty);
      expect(repository.watchCount, 0);
      expect(core.summaryMetrics.presentation.formattedAmount, '— Ft');

      await core.bootstrapInitialDisplay();

      expect(repository.watchCount, 0);
      expect(
        core.query.state.scope.timeScope,
        const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      expect(
        core.query.state.result?.scopeKey,
        core.query.state.scope.key.value,
      );
      expect(core.query.state.isLoading, isFalse);
      expect(core.summaryMetrics.presentation.formattedAmount, '1,00 Ft');
      expect(core.logBox.state.queryKey, core.query.state.scope.key.value);
      expect(core.parentDisplayBundles!.currentBundle, isNotNull);
    },
  );

  test(
    'entering YEAR prepares both adjacent parent decks before a pill swipe',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      core.requestBroaderPlane();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        repository.bundleRequests
            .where((request) => request.plane == TimePlane.year)
            .map((request) => request.parentScope.timeScope)
            .toSet(),
        {const YearScope(2025), const YearScope(2026), const YearScope(2027)},
      );
    },
  );

  test('forwards every owned child state notification to core listeners', () {
    final core = DashboardCoreController();
    var notifications = 0;
    core.addListener(() => notifications += 1);

    core.expansion.setProgress(1);
    core.rail.setExpanded(true);
    core.transactionDirection.select(TransactionDirection.expense);

    expect(notifications, 3);
    core.dispose();
  });

  test('demo month navigation retargets the production query scope', () async {
    final repository = _RecordingDashboardRepository();
    final core = DashboardCoreController(
      queryRepository: repository,
      initialDate: DateTime(2026, 8, 2),
    );
    addTearDown(core.dispose);

    await Future<void>.delayed(Duration.zero);

    expect(
      repository.requestedScopes.last,
      const MonthScope(YearMonth(year: 2026, month: 8)),
    );

    core.rail.navigateToMonth(const YearMonth(year: 2026, month: 7));
    await Future<void>.delayed(Duration.zero);

    expect(
      core.query.state.scope.timeScope,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
    expect(
      repository.requestedScopes.last,
      const MonthScope(YearMonth(year: 2026, month: 7)),
    );
  });

  test(
    'rail preview does not notify the dashboard root or create a query',
    () async {
      final repository = _RecordingDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 7, 14),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      core.rail.setRailOpen(true);
      await Future<void>.delayed(Duration.zero);
      final watchCountBeforePreviews = repository.watchCount;
      var rootNotifications = 0;
      core.addListener(() => rootNotifications += 1);

      for (var index = 0; index < 100; index += 1) {
        core.rail.previewChildLogicalIndex(index);
      }

      expect(repository.watchCount, watchCountBeforePreviews);
      expect(rootNotifications, 0);
    },
  );

  test(
    'ten rapid child commits activate only the final live-query lease',
    () async {
      final repository = _RecordingDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 7, 14),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      core.rail.setRailOpen(true);
      await Future<void>.delayed(Duration.zero);
      final watchesBeforeRapidCommits = repository.watchCount;

      for (var logicalIndex = 0; logicalIndex < 10; logicalIndex += 1) {
        core.rail.settleChildLogicalIndex(logicalIndex);
      }

      await Future<void>.delayed(const Duration(milliseconds: 80));
      expect(repository.watchCount, watchesBeforeRapidCommits);

      await Future<void>.delayed(const Duration(milliseconds: 180));
      expect(repository.watchCount, watchesBeforeRapidCommits + 1);
      expect(
        repository.requestedScopes.last,
        const DayScope(LocalDate(year: 2026, month: 7, day: 10)),
      );
    },
  );

  test(
    'complete MONTH and YEAR bundles serve core rail previews without legacy child reads',
    () async {
      DashboardPerformanceTrace.resetForTest(enabled: true);
      addTearDown(DashboardPerformanceTrace.resetForTest);
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      core.rail.setRailOpen(true);
      await Future<void>.delayed(Duration.zero);

      final monthBundle = core.parentDisplayBundles!.currentBundle!;
      expect(monthBundle.key.plane, TimePlane.month);
      expect(monthBundle.childDeck.snapshots, hasLength(30));
      for (final day in List<int>.generate(30, (index) => index + 1)) {
        final scope = core.query.state.scope.copyWith(
          timeScope: DayScope(
            const YearMonth(year: 2026, month: 6).clampDay(day),
          ),
        );
        expect(core.parentDisplayBundles!.previewFor(scope), isNotNull);
      }
      for (final day in const [15, 16, 21, 26]) {
        core.prefetchLogForRailTarget(day - 1);
      }
      expect(
        core.parentDisplayBundles!
            .previewFor(
              core.query.state.scope.copyWith(
                timeScope: const DayScope(
                  LocalDate(year: 2026, month: 6, day: 26),
                ),
              ),
            )!
            .isExplicitEmpty,
        isTrue,
      );
      expect(repository.previewPrefetchCount, 0);
      expect(repository.childSummaryReadCount, 0);
      expect(
        DashboardPerformanceTrace.events.where(
          (event) =>
              event.kind ==
              DashboardPerformanceTraceKind.displaySnapshotSelected,
        ),
        isNotEmpty,
      );

      core.rail.moveToBroaderPlane();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final yearBundle = core.parentDisplayBundles!.currentBundle!;
      expect(yearBundle.key.plane, TimePlane.year);
      expect(yearBundle.childDeck.snapshots, hasLength(12));
      final committedScopeBeforeYearTicks = core.query.state.scope;
      for (final fixture in const [
        (month: 2, totalMinor: 202000, entryCount: 3),
        (month: 4, totalMinor: 204000, entryCount: 5),
        (month: 5, totalMinor: 205000, entryCount: 1),
        (month: 6, totalMinor: 206000, entryCount: 2),
        (month: 7, totalMinor: 207000, entryCount: 3),
      ]) {
        core.rail.previewChildLogicalIndex(fixture.month - 1);
        final expectedScope = committedScopeBeforeYearTicks.copyWith(
          timeScope: MonthScope(YearMonth(year: 2026, month: fixture.month)),
        );
        final metrics = core.summaryMetrics.metrics!;
        expect(metrics.canonicalQueryKey, expectedScope.key.value);
        expect(metrics.totalMinor, fixture.totalMinor);
        expect(metrics.entryCount, fixture.entryCount);
        expect(metrics.isLoading, isFalse);
        expect(metrics.isStale, isFalse);
        final logState = core.logBox.state;
        expect(logState.queryKey, expectedScope.key.value);
        expect(logState, isA<DashboardLogData>());
        expect(
          (logState as DashboardLogData).snapshot.summaryMetrics.entryCount,
          fixture.entryCount,
        );
      }
      expect(core.query.state.scope, committedScopeBeforeYearTicks);
      expect(repository.previewPrefetchCount, 0);
      expect(repository.childSummaryReadCount, 0);
    },
  );

  test(
    'finite rail is not renderable before its first complete deck',
    () async {
      final repository = _FiniteBundleDashboardRepository()
        ..deferNextParentBundle();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final previousAmount = core.summaryMetrics.presentation.formattedAmount;
      final previousLogBox = core.logBox.state;
      expect(previousAmount, '1,00 Ft');

      core.rail.setRailOpen(true);
      expect(core.canRenderTimeRail, isFalse);
      expect(core.summaryMetrics.presentation.formattedAmount, previousAmount);
      expect(core.logBox.state, same(previousLogBox));

      repository.completeDeferredParentBundle();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(core.canRenderTimeRail, isTrue);
    },
  );

  test(
    'direction change stages the exact finite deck and page without a placeholder frame',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      core.rail.setRailOpen(true);
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final oldQueryScope = core.query.state.scope;
      final oldAmount = core.summaryMetrics.presentation.formattedAmount;
      final oldLogBox = core.logBox.state;
      final emittedAmounts = <String>[];
      core.summaryMetrics.addListener(
        () => emittedAmounts.add(
          core.summaryMetrics.presentation.formattedAmount,
        ),
      );
      final prefetchesBeforeDirection = repository.previewPrefetchCount;
      repository
        ..deferNextParentBundle()
        ..deferNextParentFirstPage();

      core.transactionDirection.select(TransactionDirection.expense);
      await Future<void>.delayed(Duration.zero);

      expect(
        repository.bundleRequests.last.parentScope.direction,
        LedgerDirection.expense,
      );
      expect(repository.previewPrefetchCount, prefetchesBeforeDirection + 1);
      expect(core.query.state.scope, oldQueryScope);
      expect(core.canRenderTimeRail, isTrue);
      expect(core.isTimeRailInteractive, isFalse);
      expect(core.summaryMetrics.presentation.formattedAmount, oldAmount);
      expect(core.logBox.state, same(oldLogBox));
      expect(emittedAmounts, isNot(contains('— Ft')));

      // A motion target may arrive while the target direction is staged; it
      // must not start an additional legacy read for this tick.
      core.prefetchLogForRailTarget(8);
      expect(repository.previewPrefetchCount, prefetchesBeforeDirection + 1);

      repository.completeDeferredParentBundle();
      await Future<void>.delayed(Duration.zero);
      expect(core.query.state.scope, oldQueryScope);
      expect(core.summaryMetrics.presentation.formattedAmount, oldAmount);
      expect(core.logBox.state, same(oldLogBox));

      repository.completeDeferredParentFirstPage();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(core.query.state.scope.direction, LedgerDirection.expense);
      expect(
        core.parentDisplayBundles!.currentBundle!.parentScope.direction,
        LedgerDirection.expense,
      );
      expect(
        core.summaryMetrics.metrics!.scope.direction,
        LedgerDirection.expense,
      );
      expect(core.canRenderTimeRail, isTrue);
      expect(core.isTimeRailInteractive, isTrue);
      expect(core.summaryMetrics.presentation.formattedAmount, isNot('— Ft'));
      expect(
        core.logBox.state.queryKey,
        core.query.state.scope
            .copyWith(timeScope: core.rail.state.effectiveScope)
            .key
            .value,
      );
      expect(emittedAmounts, isNot(contains('— Ft')));
    },
  );

  test(
    'parent navigation retains the old snapshot until target deck and LogBox page are ready',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      final visibleBefore = core.parentDisplayBundles!.currentBundle!;
      repository.deferNextParentBundle();
      repository.deferNextParentFirstPage();

      core.requestParentNext();
      await Future<void>.delayed(Duration.zero);

      expect(
        core.rail.state.parentScope,
        const MonthScope(YearMonth(year: 2026, month: 6)),
      );
      expect(core.parentDisplayBundles!.currentBundle, same(visibleBefore));

      repository.completeDeferredParentBundle();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        core.rail.state.parentScope,
        const MonthScope(YearMonth(year: 2026, month: 6)),
      );
      expect(core.parentDisplayBundles!.currentBundle, same(visibleBefore));

      repository.completeDeferredParentFirstPage();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(
        core.rail.state.parentScope,
        const MonthScope(YearMonth(year: 2026, month: 7)),
      );
      expect(
        core.parentDisplayBundles!.currentBundle!.parentScope.timeScope,
        const MonthScope(YearMonth(year: 2026, month: 7)),
      );
    },
  );

  test(
    'plane transition stages the target child deck before replacing its rail source',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      core.rail.setRailOpen(true);
      final visibleBefore = core.parentDisplayBundles!.currentBundle!;
      repository.deferNextParentBundle();

      core.requestBroaderPlane();
      await Future<void>.delayed(Duration.zero);

      expect(core.rail.state.plane, TimePlane.month);
      expect(core.parentDisplayBundles!.currentBundle, same(visibleBefore));

      repository.completeDeferredParentBundle();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(core.rail.state.plane, TimePlane.year);
      expect(core.rail.state.parentScope, const YearScope(2026));
      expect(
        core.rail.state.childScope,
        const MonthScope(YearMonth(year: 2026, month: 6)),
      );
      expect(
        core.parentDisplayBundles!.currentBundle!.key.plane,
        TimePlane.year,
      );
      expect(
        core.query.state.scope.timeScope,
        const MonthScope(YearMonth(year: 2026, month: 6)),
      );
    },
  );

  test(
    'SUM has a bounded exact year preview deck instead of a child-summary fallback',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);

      await core.bootstrapInitialDisplay();
      core.requestBroaderPlane();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      core.requestBroaderPlane();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      expect(core.rail.state.plane, TimePlane.sum);
      final deck = core.parentDisplayBundles!.currentBundle!;
      expect(deck.key.plane, TimePlane.sum);
      expect(deck.childDeck.snapshots, hasLength(401));
      expect(
        deck.childDeck.snapshotFor(
          core.query.state.scope.copyWith(timeScope: const YearScope(2026)),
        ),
        isNotNull,
      );
      expect(repository.childSummaryReadCount, 0);
    },
  );

  test(
    'YEAR SummaryPill parent intent advances the year with rail closed and open',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
        autoStart: false,
      );
      addTearDown(core.dispose);

      await core.bootstrapInitialDisplay();
      core.requestBroaderPlane();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(core.rail.state.plane, TimePlane.year);
      expect(core.rail.state.isRailOpen, isFalse);

      core.requestParentNext();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(core.rail.state.parentScope, const YearScope(2027));

      core.rail.setRailOpen(true);
      core.requestParentNext();
      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);
      expect(core.rail.state.parentScope, const YearScope(2028));
      expect(
        core.rail.state.effectiveScope,
        const MonthScope(YearMonth(year: 2028, month: 6)),
      );
    },
  );

  test(
    'startup warms only current and adjacent finite parents after the shell',
    () async {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);
      final warmedIconIds = <String>[];

      await core.startStartupWarmup(
        warmCategorySvgAssets: (iconIds) async {
          warmedIconIds.addAll(iconIds);
        },
      );

      expect(
        repository.bundleRequests
            .map((request) => request.parentScope.timeScope)
            .toSet(),
        {
          const MonthScope(YearMonth(year: 2026, month: 5)),
          const MonthScope(YearMonth(year: 2026, month: 6)),
          const MonthScope(YearMonth(year: 2026, month: 7)),
        },
      );
      expect(warmedIconIds, isEmpty);
    },
  );

  testWidgets('100 rail previews do not rebuild header or rail shell', (
    tester,
  ) async {
    final originalDebugPrint = debugPrint;
    debugPrint = (_, {int? wrapWidth}) {};
    try {
      final repository = _FiniteBundleDashboardRepository();
      final core = DashboardCoreController(
        queryRepository: repository,
        initialDate: DateTime(2026, 6, 15),
      );
      addTearDown(core.dispose);
      final probe = _RenderProbe();

      await tester.pumpWidget(
        MaterialApp(
          home: _DashboardRenderBoundaryHarness(core: core, probe: probe),
        ),
      );
      await tester.pump();
      core.rail.setRailOpen(true);
      await tester.pump();
      probe.reset();

      for (var index = 0; index < 100; index += 1) {
        core.rail.previewChildLogicalIndex(index % 30);
      }
      await tester.pump();

      expect(probe.headerBuilds, 0);
      expect(probe.railShellBuilds, 0);
    } finally {
      debugPrint = originalDebugPrint;
    }
  });

  testWidgets('cache-hit parent navigation has no mixed placeholder frame', (
    tester,
  ) async {
    final repository = _FiniteBundleDashboardRepository();
    final core = DashboardCoreController(
      queryRepository: repository,
      initialDate: DateTime(2026, 6, 15),
    );
    addTearDown(core.dispose);
    await tester.pumpWidget(
      MaterialApp(home: _DashboardAtomicParentHarness(core: core)),
    );
    await tester.pump();
    await tester.pump();
    expect(find.text('parent=month:2026-06'), findsOneWidget);
    expect(find.textContaining('amount=—'), findsNothing);
    expect(find.textContaining('log=income|month:2026-06'), findsOneWidget);

    repository
      ..deferNextParentBundle()
      ..deferNextParentFirstPage();
    core.requestParentNext();
    await tester.pump();
    expect(find.text('parent=month:2026-06'), findsOneWidget);
    expect(find.text('parent=month:2026-07'), findsNothing);
    expect(find.textContaining('amount=—'), findsNothing);
    expect(find.textContaining('log=income|month:2026-06'), findsOneWidget);

    repository.completeDeferredParentBundle();
    await tester.pump();
    await tester.pump();
    expect(find.text('parent=month:2026-06'), findsOneWidget);
    expect(find.text('parent=month:2026-07'), findsNothing);
    expect(find.textContaining('amount=—'), findsNothing);
    expect(find.textContaining('log=income|month:2026-06'), findsOneWidget);

    repository.completeDeferredParentFirstPage();
    await tester.pump();
    await tester.pump();
    expect(find.text('parent=month:2026-06'), findsNothing);
    expect(find.text('parent=month:2026-07'), findsOneWidget);
    expect(find.textContaining('amount=—'), findsNothing);
    expect(find.textContaining('log=income|month:2026-07'), findsOneWidget);
    await tester.pump(const Duration(milliseconds: 181));
  });
}
