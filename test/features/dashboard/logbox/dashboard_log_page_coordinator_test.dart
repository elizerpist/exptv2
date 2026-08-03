import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_committed_query_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_area_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_page_coordinator.dart';
import 'package:fluvi/features/dashboard/logbox/data/dashboard_log_repository.dart';
import 'package:fluvi/features/dashboard/logbox/domain/dashboard_log_models.dart';
import 'package:fluvi/features/dashboard/application/dashboard_summary_metrics_source.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/scope_summary_metrics.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_spec.dart';

class _LogRepository
    implements DashboardLedgerRepository, DashboardLogPageRepository {
  _LogRepository(this._initial);

  final DashboardLedgerResult _initial;
  final streams = <String, StreamController<DashboardLedgerResult>>{};
  int logPageReads = 0;
  DashboardDayGroupPage? nextPage;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => _initial;

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) =>
      (streams[scope.key.value] ??=
              StreamController<DashboardLedgerResult>.broadcast())
          .stream;

  @override
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async {
    logPageReads += 1;
    return nextPage ??
        DashboardDayGroupPage(
          canonicalQueryKey: scope.key.value,
          coreRevision: 12,
          groups: const [],
          nextCursor: null,
        );
  }

  Future<void> emit(
    CurrentLedgerQueryScope scope,
    DashboardLedgerResult result,
  ) async {
    streams[scope.key.value]!.add(result);
    await Future<void>.value();
  }

  Future<void> dispose() async {
    for (final stream in streams.values) {
      await stream.close();
    }
  }
}

class _PrefetchLogRepository
    implements
        DashboardLedgerRepository,
        DashboardLedgerFirstPagePrefetchRepository,
        DashboardLogPageRepository {
  int watchCalls = 0;
  int prefetchCalls = 0;
  int nextPageCalls = 0;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => const DashboardLedgerResult(totalMinor: 0);

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  }) async {
    prefetchCalls += 1;
    const entry = DashboardLedgerEntry(
      id: 'prefetched-entry',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 901489,
      bookedLocalEpochDay: 20525,
      bookedLocalTimeMinutes: 720,
    );
    return DashboardLedgerResult(
      totalMinor: 901489,
      entryCount: 1,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
      dayGroups: const [
        DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: [entry]),
      ],
    );
  }

  @override
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async {
    nextPageCalls += 1;
    return DashboardDayGroupPage(
      canonicalQueryKey: scope.key.value,
      coreRevision: 12,
      groups: const [],
      nextCursor: null,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    watchCalls += 1;
    return const Stream<DashboardLedgerResult>.empty();
  }
}

class _PreviewCacheRepository
    implements
        DashboardLedgerRepository,
        DashboardLedgerFirstPagePrefetchRepository,
        DashboardLogPageRepository {
  int watchCalls = 0;
  int prefetchCalls = 0;
  int nextPageCalls = 0;
  bool provideNextCursor = false;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => _resultFor(scope);

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  }) async {
    prefetchCalls += 1;
    return _resultFor(scope);
  }

  @override
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async {
    nextPageCalls += 1;
    return DashboardDayGroupPage(
      canonicalQueryKey: scope.key.value,
      coreRevision: 12,
      groups: const [],
      nextCursor: null,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    watchCalls += 1;
    return const Stream<DashboardLedgerResult>.empty();
  }

  DashboardLedgerResult _resultFor(CurrentLedgerQueryScope scope) {
    final day = switch (scope.timeScope) {
      DayScope(:final date) => date.day,
      _ => 0,
    };
    final entryCount = day == 22
        ? 0
        : day == 21
        ? 4
        : 2;
    final totalMinor = day == 22
        ? 0
        : day == 21
        ? 1075384
        : 466229;
    final groups = entryCount == 0
        ? const <DashboardLedgerDayGroup>[]
        : [
            DashboardLedgerDayGroup(
              bookedLocalEpochDay: 20500 + day,
              entries: List<DashboardLedgerEntry>.generate(
                entryCount,
                (index) => DashboardLedgerEntry(
                  id: '${scope.key.value}-$index',
                  partnerId: 'partner-$index',
                  categoryId: 'category-$index',
                  direction: scope.direction.name,
                  amountMinor: totalMinor ~/ entryCount,
                  bookedLocalEpochDay: 20500 + day,
                  bookedLocalTimeMinutes: 720 - index,
                ),
              ),
            ),
          ];
    return DashboardLedgerResult(
      totalMinor: totalMinor,
      entryCount: entryCount,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
      dayGroups: groups,
      nextDayCursor: provideNextCursor
          ? const {'beforeLocalEpochDayExclusive': 20500}
          : null,
    );
  }
}

class _MutablePreviewCommitRepository
    implements
        DashboardLedgerRepository,
        DashboardLedgerFirstPagePrefetchRepository,
        DashboardLogPageRepository {
  String partnerDisplayName = 'Eredeti partner';

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async => _resultFor(scope);

  @override
  Future<DashboardLedgerResult> readFirstDayGroupPage(
    CurrentLedgerQueryScope scope, {
    int maxDayGroups = 7,
  }) async => _resultFor(scope);

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) => Stream<DashboardLedgerResult>.value(_resultFor(scope));

  @override
  Future<DashboardDayGroupPage> readLogPage(
    CurrentLedgerQueryScope scope, {
    DashboardDayGroupPageCursor? before,
    int maxDayGroups = 7,
  }) async => DashboardDayGroupPage(
    canonicalQueryKey: scope.key.value,
    coreRevision: 12,
    groups: const [],
    nextCursor: null,
  );

  DashboardLedgerResult _resultFor(CurrentLedgerQueryScope scope) {
    const entryId = 'same-row-id';
    return DashboardLedgerResult(
      totalMinor: 100,
      entryCount: 1,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
      dayGroups: [
        DashboardLedgerDayGroup(
          bookedLocalEpochDay: 20525,
          entries: [
            DashboardLedgerEntry(
              id: entryId,
              partnerId: 'partner-1',
              partnerDisplayName: partnerDisplayName,
              categoryId: 'category-1',
              categoryDisplayName: 'Kategória',
              categoryColorId: 'color_01',
              categoryIconId: 'icon_01',
              direction: scope.direction.name,
              amountMinor: 100,
              bookedLocalEpochDay: 20525,
              bookedLocalTimeMinutes: 720,
            ),
          ],
        ),
      ],
    );
  }
}

class _PreviewMetricsSource extends ChangeNotifier
    implements DashboardSummaryMetricsSource {
  @override
  ScopeSummaryMetrics? metrics;

  @override
  DashboardTimeChildSummaryIndex? get index => null;

  DashboardTimeChildSummaryIndex? _readyIndex;

  @override
  DashboardTimeChildSummaryIndex? get readyIndex => _readyIndex;

  CurrentLedgerQueryScope? _readyParentScope;

  @override
  CurrentLedgerQueryScope? get readyParentScope => _readyParentScope;

  void publish(ScopeSummaryMetrics value) {
    metrics = value;
    notifyListeners();
  }

  void publishReadyIndex({
    required DashboardTimeChildSummaryIndex index,
    required CurrentLedgerQueryScope parentScope,
  }) {
    _readyIndex = index;
    _readyParentScope = parentScope;
    notifyListeners();
  }
}

void main() {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 3)),
  );

  const rows = <DashboardLedgerEntry>[
    DashboardLedgerEntry(
      id: 'entry-13-b',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 400000,
      bookedLocalEpochDay: 20525,
      bookedLocalTimeMinutes: 720,
    ),
    DashboardLedgerEntry(
      id: 'entry-13-a',
      partnerId: 'partner-1',
      categoryId: 'category-1',
      direction: 'expense',
      amountMinor: 501489,
      bookedLocalEpochDay: 20525,
      bookedLocalTimeMinutes: 600,
    ),
  ];

  test(
    'binds summary metrics and complete day rows from one committed snapshot',
    () async {
      final result = DashboardLedgerResult(
        totalMinor: 901489,
        entryCount: 2,
        scopeKey: scope.key.value,
        timeScopeKey: scope.timeScope.canonicalKey,
        direction: scope.direction.name,
        coreRevision: 12,
        entries: rows,
        dayGroups: const [
          DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: rows),
        ],
      );
      final repository = _LogRepository(result);
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      addTearDown(repository.dispose);

      query.refresh();
      await repository.emit(scope, result);

      final state = coordinator.state;
      expect(state, isA<DashboardLogData>());
      final data = state as DashboardLogData;
      expect(data.snapshot.summaryMetrics.canonicalQueryKey, scope.key.value);
      expect(data.snapshot.summaryMetrics.coreRevision, 12);
      expect(data.snapshot.summaryMetrics.totalMinor, 901489);
      expect(data.snapshot.summaryMetrics.entryCount, 2);
      expect(data.groups, hasLength(1));
      expect(data.groups.single.rows.map((row) => row.id), [
        'entry-13-b',
        'entry-13-a',
      ]);
      expect(repository.logPageReads, 0);
    },
  );

  test(
    'selects every cached child page and count during preview without a watch',
    () async {
      final repository = _PreviewCacheRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);

      final day20 = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 20)),
      );
      final day21 = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      final day22 = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 22)),
      );
      await query.warmFirstDayGroupPages([
        day20,
        day21,
        day22,
      ], reason: 'previewRegressionSetup');
      final readsBeforePreview = repository.prefetchCalls;

      for (final fixture in [
        (scope: day20, totalMinor: 466229, entryCount: 2),
        (scope: day21, totalMinor: 1075384, entryCount: 4),
        (scope: day22, totalMinor: 0, entryCount: 0),
      ]) {
        preview.publish(
          ScopeSummaryMetrics(
            scope: fixture.scope,
            canonicalQueryKey: fixture.scope.key.value,
            coreRevision: 12,
            totalMinor: fixture.totalMinor,
            entryCount: fixture.entryCount,
            source: SummaryMetricsSource.childPreviewIndex,
            isLoading: false,
            isStale: false,
            hasError: false,
          ),
        );
        final state = coordinator.state;
        expect(state.queryKey, fixture.scope.key.value);
        expect(state.coreRevision, 12);
        expect(switch (state) {
          DashboardLogData(:final snapshot) =>
            snapshot.summaryMetrics.entryCount,
          DashboardLogEmpty(:final snapshot) =>
            snapshot.summaryMetrics.entryCount,
          _ => null,
        }, fixture.entryCount);
      }

      expect(repository.prefetchCalls, readsBeforePreview);
      expect(repository.watchCalls, 0);
    },
  );

  test(
    'preview pagination cannot read the previously committed query page',
    () async {
      final repository = _PreviewCacheRepository()..provideNextCursor = true;
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);

      final committed = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 20)),
      );
      final previewScope = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      await query.prefetchFirstDayGroupPage(committed);
      query.setTimeScope(committed.timeScope, reason: 'previewPagingSetup');
      expect((coordinator.state as DashboardLogData).hasNextPage, isTrue);

      await query.prefetchFirstDayGroupPage(previewScope);
      preview.publish(
        ScopeSummaryMetrics(
          scope: previewScope,
          canonicalQueryKey: previewScope.key.value,
          coreRevision: 12,
          totalMinor: 1075384,
          entryCount: 4,
          source: SummaryMetricsSource.childPreviewIndex,
          isLoading: false,
          isStale: false,
          hasError: false,
        ),
      );
      expect(coordinator.state, isA<DashboardLogData>());
      expect(
        (coordinator.state as DashboardLogData).snapshot,
        isA<DashboardPreviewQuerySnapshot>(),
      );

      await coordinator.loadNextPage();

      expect(repository.nextPageCalls, 0);
    },
  );

  test(
    'keeps a cached preview visually stable when that child settles',
    () async {
      final repository = _PreviewCacheRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);

      final child = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      await query.warmFirstDayGroupPages([
        child,
      ], reason: 'previewSettleRegressionSetup');
      final previewMetrics = ScopeSummaryMetrics(
        scope: child,
        canonicalQueryKey: child.key.value,
        coreRevision: 12,
        totalMinor: 1075384,
        entryCount: 4,
        source: SummaryMetricsSource.childPreviewIndex,
        isLoading: false,
        isStale: false,
        hasError: false,
      );
      preview.publish(previewMetrics);
      final previewState = coordinator.state;
      var visibleRebuilds = 0;
      coordinator.addListener(() => visibleRebuilds += 1);
      FluviDiagnosticLogger.clear();

      query.setTimeScope(child.timeScope, reason: 'childSettled');
      preview.publish(
        ScopeSummaryMetrics(
          scope: child,
          canonicalQueryKey: child.key.value,
          coreRevision: 12,
          totalMinor: 1075384,
          entryCount: 4,
          source: SummaryMetricsSource.childSettledIndex,
          isLoading: false,
          isStale: false,
          hasError: false,
        ),
      );

      // Promotion changes only the coordinator's committed ownership. The
      // mounted LogBox keeps the exact immutable preview state, so it cannot
      // replace its delegate, reset its scroll position or rebuild rows.
      expect(coordinator.state, same(previewState));
      expect(coordinator.state.queryKey, child.key.value);
      expect(visibleRebuilds, 0);
      expect(repository.watchCalls, 0);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'LOG_FIRST_PAGE_BOUND',
        ),
        isEmpty,
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'PREVIEW_PROMOTED_TO_COMMITTED',
        ),
        hasLength(1),
      );
    },
  );

  test(
    'does not promote equal row IDs when a visible display field changed',
    () async {
      final repository = _MutablePreviewCommitRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      final child = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      await query.prefetchFirstDayGroupPage(child);
      final previewMetrics = ScopeSummaryMetrics(
        scope: child,
        canonicalQueryKey: child.key.value,
        coreRevision: 12,
        totalMinor: 100,
        entryCount: 1,
        source: SummaryMetricsSource.childPreviewIndex,
        isLoading: false,
        isStale: false,
        hasError: false,
      );
      preview.publish(previewMetrics);
      final previewState = coordinator.state;
      repository.partnerDisplayName = 'Megváltozott partner';
      query.refresh(reason: 'contentDigestNegativeSetup');
      query.setTimeScope(child.timeScope, reason: 'childSettledChangedContent');
      await Future<void>.delayed(Duration.zero);
      preview.publish(
        ScopeSummaryMetrics(
          scope: child,
          canonicalQueryKey: child.key.value,
          coreRevision: 12,
          totalMinor: 100,
          entryCount: 1,
          source: SummaryMetricsSource.childSettledIndex,
          isLoading: false,
          isStale: false,
          hasError: false,
        ),
      );

      expect(coordinator.state, isNot(same(previewState)));
      expect(
        (coordinator.state as DashboardLogData)
            .groups
            .single
            .rows
            .single
            .partnerDisplayName,
        'Megváltozott partner',
      );
    },
  );

  test('a preview cache miss has only its exact scoped loading state', () {
    final repository = _PreviewCacheRepository();
    final query = CurrentQueryController(
      repository: repository,
      initialScope: scope,
    );
    final preview = _PreviewMetricsSource();
    final coordinator = DashboardLogPageCoordinator(
      query: query,
      repository: repository,
      previewMetrics: preview,
    );
    addTearDown(coordinator.dispose);
    addTearDown(query.dispose);

    final target = scope.copyWith(
      timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
    );
    preview.publish(
      ScopeSummaryMetrics(
        scope: target,
        canonicalQueryKey: target.key.value,
        coreRevision: 12,
        totalMinor: 1075384,
        entryCount: 4,
        source: SummaryMetricsSource.childPreviewIndex,
        isLoading: false,
        isStale: false,
        hasError: false,
      ),
    );

    expect(coordinator.state, isA<DashboardLogPreviewLoading>());
    final state = coordinator.state as DashboardLogPreviewLoading;
    expect(state.queryKey, target.key.value);
    expect(state.metrics.entryCount, 4);
    expect(repository.prefetchCalls, 0);
    expect(repository.watchCalls, 0);
  });

  test(
    'warms every finite month child before rail preview without a watch',
    () async {
      final repository = _PreviewCacheRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
        navigation: navigation,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);

      preview.publishReadyIndex(
        parentScope: scope,
        index: DashboardTimeChildSummaryIndex(
          parentQueryKey: scope.key.value,
          direction: scope.direction,
          childPeriod: TimeChildPeriod.day,
          coreRevision: 12,
          isComplete: true,
          values: const <String, DashboardTimeChildSummary>{},
        ),
      );
      for (
        var turn = 0;
        turn < 40 && repository.prefetchCalls < 31;
        turn += 1
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(repository.prefetchCalls, 31);
      expect(repository.watchCalls, 0);
      final readsBeforePreview = repository.prefetchCalls;
      final child = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      preview.publish(
        ScopeSummaryMetrics(
          scope: child,
          canonicalQueryKey: child.key.value,
          coreRevision: 12,
          totalMinor: 1075384,
          entryCount: 4,
          source: SummaryMetricsSource.childPreviewIndex,
          isLoading: false,
          isStale: false,
          hasError: false,
        ),
      );

      expect(coordinator.state, isA<DashboardLogData>());
      expect(
        (coordinator.state as DashboardLogData)
            .snapshot
            .summaryMetrics
            .entryCount,
        4,
      );
      expect(repository.prefetchCalls, readsBeforePreview);
      expect(repository.watchCalls, 0);
    },
  );

  test(
    'warms only the bounded SUM child window around its selected year',
    () async {
      final repository = _PreviewCacheRepository();
      final parentScope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      );
      final query = CurrentQueryController(
        repository: repository,
        initialScope: parentScope,
      );
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 3, 14),
        initialPlane: TimePlane.sum,
        yearAnchor: 2026,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
        navigation: navigation,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);

      preview.publishReadyIndex(
        parentScope: parentScope,
        index: DashboardTimeChildSummaryIndex(
          parentQueryKey: parentScope.key.value,
          direction: parentScope.direction,
          childPeriod: TimeChildPeriod.year,
          coreRevision: 12,
          isComplete: true,
          values: const <String, DashboardTimeChildSummary>{},
        ),
      );
      final expectedCount =
          CenteredCarouselPresets.timeRailMaxItemsPerFling * 2 + 3;
      for (
        var turn = 0;
        turn < 40 && repository.prefetchCalls < expectedCount;
        turn += 1
      ) {
        await Future<void>.delayed(Duration.zero);
      }

      expect(repository.prefetchCalls, expectedCount);
      expect(repository.watchCalls, 0);
      expect(
        query.cachedFirstDayGroupPage(
          parentScope.copyWith(timeScope: const YearScope(2020)),
        ),
        isNotNull,
      );
      expect(
        query.cachedFirstDayGroupPage(
          parentScope.copyWith(timeScope: const YearScope(2032)),
        ),
        isNotNull,
      );
    },
  );

  test(
    'deduplicates preview-bound and preview-miss diagnostics by scope',
    () async {
      final repository = _PreviewCacheRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final preview = _PreviewMetricsSource();
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
        previewMetrics: preview,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);

      final cached = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 20)),
      );
      final missing = scope.copyWith(
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 21)),
      );
      await query.warmFirstDayGroupPages([
        cached,
      ], reason: 'previewDiagnosticSetup');
      FluviDiagnosticLogger.clear();
      final cachedMetrics = ScopeSummaryMetrics(
        scope: cached,
        canonicalQueryKey: cached.key.value,
        coreRevision: 12,
        totalMinor: 466229,
        entryCount: 2,
        source: SummaryMetricsSource.childPreviewIndex,
        isLoading: false,
        isStale: false,
        hasError: false,
      );
      final missingMetrics = ScopeSummaryMetrics(
        scope: missing,
        canonicalQueryKey: missing.key.value,
        coreRevision: 12,
        totalMinor: 1075384,
        entryCount: 4,
        source: SummaryMetricsSource.childPreviewIndex,
        isLoading: false,
        isStale: false,
        hasError: false,
      );

      preview.publish(cachedMetrics);
      preview.publish(cachedMetrics);
      preview.publish(missingMetrics);
      preview.publish(missingMetrics);

      final previewEvents = FluviDiagnosticLogger.entries.where(
        (event) => event.stage.startsWith('LOG_PREVIEW_'),
      );
      expect(
        previewEvents.where((event) => event.stage == 'LOG_PREVIEW_BOUND'),
        hasLength(1),
      );
      expect(
        previewEvents.where((event) => event.stage == 'LOG_PREVIEW_CACHE_MISS'),
        hasLength(1),
      );
      expect(
        previewEvents.map((event) => event.queryKey),
        containsAll(<String>[cached.key.value, missing.key.value]),
      );
    },
  );

  test(
    'a resolved rail target prefetches invisibly and binds as a cache hit',
    () async {
      final repository = _PrefetchLogRepository();
      final query = CurrentQueryController(
        repository: repository,
        initialScope: scope,
      );
      final coordinator = DashboardLogPageCoordinator(
        query: query,
        repository: repository,
      );
      addTearDown(coordinator.dispose);
      addTearDown(query.dispose);
      final target = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const DayScope(LocalDate(year: 2026, month: 3, day: 13)),
      );

      final before = coordinator.state;
      await coordinator.prefetchForMotionTarget(
        target,
        reason: 'motionTargetResolved',
      );

      // Prefetch owns data cache only: the visible list cannot change before
      // the application's normal settled-scope commit.
      expect(coordinator.state, same(before));
      expect(repository.prefetchCalls, 1);
      expect(repository.watchCalls, 0);
      expect(repository.nextPageCalls, 0);

      query.setTimeScope(target.timeScope, reason: 'childSettled');

      final data = coordinator.state as DashboardLogData;
      expect(data.queryKey, target.key.value);
      expect(data.cacheHit, isTrue);
      expect(data.groups.single.rows.single.id, 'prefetched-entry');
      expect(repository.watchCalls, 0);
    },
  );

  test('appends one complete older day with stable query identity', () async {
    final first = DashboardLedgerResult(
      totalMinor: 1301489,
      entryCount: 3,
      scopeKey: scope.key.value,
      timeScopeKey: scope.timeScope.canonicalKey,
      direction: scope.direction.name,
      coreRevision: 12,
      dayGroups: const [
        DashboardLedgerDayGroup(bookedLocalEpochDay: 20525, entries: rows),
      ],
      nextDayCursor: const {'beforeLocalEpochDayExclusive': 20525},
    );
    final repository = _LogRepository(first)
      ..nextPage = DashboardDayGroupPage(
        canonicalQueryKey: scope.key.value,
        coreRevision: 12,
        groups: const [
          DashboardDayLogGroup(
            localDate: LocalDate(year: 2026, month: 3, day: 12),
            rows: [
              DashboardLedgerEntry(
                id: 'entry-12',
                partnerId: 'partner-1',
                categoryId: 'category-1',
                direction: 'expense',
                amountMinor: 400000,
                bookedLocalEpochDay: 20524,
                bookedLocalTimeMinutes: 600,
              ),
            ],
          ),
        ],
        nextCursor: null,
      );
    final query = CurrentQueryController(
      repository: repository,
      initialScope: scope,
    );
    final coordinator = DashboardLogPageCoordinator(
      query: query,
      repository: repository,
    );
    addTearDown(coordinator.dispose);
    addTearDown(query.dispose);
    addTearDown(repository.dispose);

    query.refresh();
    await repository.emit(scope, first);
    final firstViewGroup =
        (coordinator.state as DashboardLogData).viewGroups.single;
    await coordinator.loadNextPage();

    final data = coordinator.state as DashboardLogData;
    expect(repository.logPageReads, 1);
    expect(data.queryKey, scope.key.value);
    expect(data.coreRevision, 12);
    expect(data.groups.map((group) => group.localDate.isoString), [
      '2026-03-13',
      '2026-03-12',
    ]);
    expect(data.groups.expand((group) => group.rows).map((row) => row.id), [
      'entry-13-b',
      'entry-13-a',
      'entry-12',
    ]);
    expect(
      data.viewGroups.first,
      same(firstViewGroup),
      reason: 'Appending an older page must not reproject visible day groups.',
    );
    expect(data.hasNextPage, isFalse);
  });
}
