import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle.dart';
import 'package:fluvi/features/dashboard/application/dashboard_parent_display_bundle_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/performance/dashboard_performance_trace.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_summary_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _RenderProbe implements DashboardRenderRebuildProbe {
  int headerBuilds = 0;
  int railShellBuilds = 0;
  int logBoxBuilds = 0;

  @override
  void didBuildHeader() => headerBuilds += 1;

  @override
  void didBuildLogBox() => logBoxBuilds += 1;

  @override
  void didBuildRailShell() => railShellBuilds += 1;

  void reset() {
    headerBuilds = 0;
    railShellBuilds = 0;
    logBoxBuilds = 0;
  }
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
        totalMinor: 0,
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
    totalMinor: 0,
    coreRevision: 41,
    scopeKey: scope.key.value,
  );

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async* {
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
        .map(
          (child) => DashboardLogPreviewSnapshot.populated(
            scope: child,
            coreRevision: 41,
            totalMinor: 100,
            entryCount: 1,
            groups: const [],
          ),
        )
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
        totalMinor: 0,
        coreRevision: 41,
        scopeKey: scope.key.value,
      ),
    );
  }
}

void main() {
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
      expect(repository.previewPrefetchCount, 0);
      expect(repository.childSummaryReadCount, 0);
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
    addTearDown(() => debugPrint = originalDebugPrint);
    final repository = _FiniteBundleDashboardRepository();
    final core = DashboardCoreController(
      queryRepository: repository,
      initialDate: DateTime(2026, 6, 15),
    );
    addTearDown(core.dispose);
    final probe = _RenderProbe();

    await tester.pumpWidget(
      MaterialApp(
        home: CoreDashboard(
          mode: DashboardModeSpec.balance,
          controller: core,
          renderRebuildProbe: probe,
          enableStartupWarmup: false,
        ),
      ),
    );
    await Future<void>.delayed(Duration.zero);
    await tester.pump();
    core.rail.setRailOpen(true);
    await Future<void>.delayed(Duration.zero);
    await tester.pump();
    probe.reset();

    for (var index = 0; index < 100; index += 1) {
      core.rail.previewChildLogicalIndex(index % 30);
    }
    await tester.pump();

    expect(probe.headerBuilds, 0);
    expect(probe.railShellBuilds, 0);
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
    await Future<void>.delayed(Duration.zero);
    await Future<void>.delayed(Duration.zero);
    await tester.pumpWidget(
      MaterialApp(
        home: CoreDashboard(
          mode: DashboardModeSpec.balance,
          controller: core,
          enableStartupWarmup: false,
        ),
      ),
    );
    await tester.pump();
    expect(find.text('2026. június'), findsOneWidget);
    expect(find.text('— Ft'), findsNothing);

    repository
      ..deferNextParentBundle()
      ..deferNextParentFirstPage();
    core.requestParentNext();
    await tester.pump();
    expect(find.text('2026. június'), findsOneWidget);
    expect(find.text('2026. július'), findsNothing);
    expect(find.text('— Ft'), findsNothing);

    repository.completeDeferredParentBundle();
    await Future<void>.delayed(Duration.zero);
    await tester.pump();
    expect(find.text('2026. június'), findsOneWidget);
    expect(find.text('2026. július'), findsNothing);
    expect(find.text('— Ft'), findsNothing);

    repository.completeDeferredParentFirstPage();
    await Future<void>.delayed(Duration.zero);
    await tester.pump();
    expect(find.text('2026. június'), findsNothing);
    expect(find.text('2026. július'), findsOneWidget);
    expect(find.text('— Ft'), findsNothing);
  });
}
