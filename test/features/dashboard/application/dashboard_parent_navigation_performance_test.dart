import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_summary_amount_controller.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_store.dart';
import 'package:fluvi/features/dashboard/query/application/dashboard_presentation_diagnostics.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_visible_presentation_target.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_bundle.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_child_preview_repository.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/time_child_summary.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_controller.dart';
import 'package:fluvi/features/dashboard/time_navigation/application/dashboard_time_navigation_state.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

class _RecordingLedgerRepository implements DashboardLedgerRepository {
  final List<String> reads = <String>[];
  final List<String> watches = <String>[];

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads.add(scope.key.value);
    return DashboardLedgerResult(
      totalMinor: 0,
      entryCount: 0,
      coreRevision: 1,
      scopeKey: scope.key.value,
    );
  }

  @override
  Stream<DashboardLedgerResult> watch(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) {
    watches.add(scope.key.value);
    return Stream<DashboardLedgerResult>.empty();
  }
}

class _ParentBundleRepository extends _RecordingLedgerRepository
    implements DashboardChildPreviewRepository {
  int childBundleReads = 0;

  @override
  Future<DashboardLedgerResult> read(
    CurrentLedgerQueryScope scope, {
    int pageSize = 50,
    Map<String, Object?>? after,
  }) async {
    reads.add(scope.key.value);
    final amount = switch (scope.timeScope) {
      MonthScope(:final value) => value.month * 100,
      _ => 0,
    };
    return DashboardLedgerResult(
      totalMinor: amount,
      entryCount: amount == 0 ? 0 : 30,
      coreRevision: 1,
      scopeKey: scope.key.value,
    );
  }

  @override
  Future<DashboardChildPreviewBundle> readChildPreviewBundle(
    DashboardChildPreviewBundleRequest request,
  ) async {
    childBundleReads += 1;
    final month = (request.parentScope.timeScope as MonthScope).value;
    final day = month.clampDay(27);
    final childScope = request.parentScope.copyWith(timeScope: DayScope(day));
    final childResult = DashboardLedgerResult(
      totalMinor: month.month * 1000 + day.day,
      entryCount: day.day,
      coreRevision: 1,
      scopeKey: childScope.key.value,
    );
    return DashboardChildPreviewBundle(
      parentScope: request.parentScope,
      childPeriod: request.childPeriod,
      coreRevision: 1,
      childrenByQueryKey: {
        childScope.key: DashboardChildPreview(
          childPeriodValue: day.isoString,
          scope: childScope,
          result: childResult,
        ),
      },
    );
  }
}

DashboardPresentationSnapshot _snapshot(
  CurrentLedgerQueryScope scope, {
  required int amount,
  required int count,
}) => DashboardPresentationSnapshot(
  queryKey: scope.key,
  generation: 1,
  scope: scope,
  coreRevision: 1,
  totalMinor: amount,
  entryCount: count,
  entries: const <DashboardLedgerEntry>[],
  dataOrigin: DashboardDataOrigin.memoryCache,
);

CurrentLedgerQueryScope _scope(
  LedgerTimeScope timeScope, {
  LedgerDirection direction = LedgerDirection.income,
}) => CurrentLedgerQueryScope(direction: direction, timeScope: timeScope);

void _seed(
  DashboardPresentationStore store,
  CurrentLedgerQueryScope scope, {
  required int amount,
  required int count,
}) {
  store.publish(
    _snapshot(scope, amount: amount, count: count),
    activate: false,
  );
}

void main() {
  test(
    'complete current parent bundle survives adjacent prewarm churn and is reused',
    () async {
      final repository = _ParentBundleRepository();
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 27),
        queryRepository: repository,
        autoStartQuery: false,
      );
      addTearDown(controller.dispose);

      final first = await controller.summaryMetrics
          .prepareCurrentParentDisplayBundle();
      for (final month in <int>[8, 9, 10, 11]) {
        await controller.summaryMetrics.prepareParentDisplayBundle(
          parentScope: _scope(MonthScope(YearMonth(year: 2026, month: month))),
          childPeriod: TimeChildPeriod.day,
          source: 'testAdjacentPrewarm',
        );
      }
      final readsBeforeReuse = repository.childBundleReads;

      final second = await controller.summaryMetrics
          .prepareCurrentParentDisplayBundle();

      expect(second, same(first));
      expect(repository.childBundleReads, readsBeforeReuse);
      expect(
        controller.summaryMetrics.hasCompleteParentDisplayBundle(
          parentScope: _scope(
            const MonthScope(YearMonth(year: 2026, month: 7)),
          ),
          childPeriod: TimeChildPeriod.day,
        ),
        isTrue,
      );
      expect(
        controller.summaryMetrics.parentBundleRegistry.pinnedKey,
        isNotNull,
      );
    },
  );

  test(
    'month parent preview selects each cached parent without query or bundle work',
    () {
      final navigation = DashboardTimeNavigationController(
        initialDate: DateTime(2026, 5, 14),
        initialPlane: TimePlane.month,
        yearAnchor: 2026,
      );
      final repository = _RecordingLedgerRepository();
      final current = _scope(const MonthScope(YearMonth(year: 2026, month: 5)));
      final query = CurrentQueryController(
        repository: repository,
        initialScope: current,
      );
      final store = DashboardPresentationStore();
      final diagnostics = DashboardPresentationDiagnostics();
      final metrics = DashboardSummaryMetricsController(
        navigation: navigation,
        query: query,
        presentationStore: store,
        diagnostics: diagnostics,
      );
      addTearDown(metrics.dispose);
      addTearDown(query.dispose);
      addTearDown(navigation.dispose);
      addTearDown(store.dispose);

      final april = _scope(const MonthScope(YearMonth(year: 2026, month: 4)));
      final may = _scope(const MonthScope(YearMonth(year: 2026, month: 5)));
      final june = _scope(const MonthScope(YearMonth(year: 2026, month: 6)));
      _seed(store, april, amount: 400, count: 4);
      _seed(store, may, amount: 500, count: 5);
      _seed(store, june, amount: 600, count: 6);
      store.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.month,
          parentQueryKey: may.key,
          childQueryKey: null,
          railOpen: false,
          direction: LedgerDirection.income,
          presentationEpoch: 1,
        ),
      );
      store.publish(_snapshot(may, amount: 500, count: 5));

      final previous = navigation.parentPreview(
        DashboardTimeNavigationChangeDirection.backward,
      )!;
      final next = navigation.parentPreview(
        DashboardTimeNavigationChangeDirection.forward,
      )!;

      expect(metrics.previewParent(previous, presentationEpoch: 2), isTrue);
      expect(store.activeSnapshot?.queryKey, april.key);
      expect(metrics.presentation.totalMinor, 400);
      expect(metrics.presentation.entryCount, 4);

      expect(metrics.previewParent(next, presentationEpoch: 3), isTrue);
      expect(store.activeSnapshot?.queryKey, june.key);
      expect(metrics.presentation.totalMinor, 600);
      expect(metrics.presentation.entryCount, 6);
      expect(repository.reads, isEmpty);
      expect(repository.watches, isEmpty);
      expect(diagnostics.parentPreviewSnapshotSelectedCount, 2);
      expect(diagnostics.parentPreviewPresentationPublishedCount, 2);
    },
  );

  test('year parent preview is an O(1) exact snapshot selection', () {
    final navigation = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 5, 14),
      initialPlane: TimePlane.year,
      yearAnchor: 2026,
    );
    final repository = _RecordingLedgerRepository();
    final current = _scope(const YearScope(2026));
    final query = CurrentQueryController(
      repository: repository,
      initialScope: current,
    );
    final store = DashboardPresentationStore();
    final metrics = DashboardSummaryMetricsController(
      navigation: navigation,
      query: query,
      presentationStore: store,
    );
    addTearDown(metrics.dispose);
    addTearDown(query.dispose);
    addTearDown(navigation.dispose);
    addTearDown(store.dispose);

    final previous = _scope(const YearScope(2025));
    final active = _scope(const YearScope(2026));
    final next = _scope(const YearScope(2027));
    _seed(store, previous, amount: 2025, count: 25);
    _seed(store, active, amount: 2026, count: 26);
    _seed(store, next, amount: 2027, count: 27);
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.year,
        parentQueryKey: active.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.income,
        presentationEpoch: 1,
      ),
    );
    store.publish(_snapshot(active, amount: 2026, count: 26));

    expect(
      metrics.previewParent(
        navigation.parentPreview(
          DashboardTimeNavigationChangeDirection.forward,
        )!,
        presentationEpoch: 2,
      ),
      isTrue,
    );
    expect(store.activeSnapshot?.queryKey, next.key);
    expect(metrics.presentation.totalMinor, 2027);
    expect(metrics.presentation.entryCount, 27);
    expect(repository.reads, isEmpty);
    expect(repository.watches, isEmpty);
  });

  test('open-rail parent preview selects the target parent child key', () {
    final navigation = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 5, 14),
      initialPlane: TimePlane.month,
      initialRailOpen: true,
      yearAnchor: 2026,
    );
    final current = _scope(
      const DayScope(LocalDate(year: 2026, month: 5, day: 14)),
    );
    final query = CurrentQueryController(
      repository: _RecordingLedgerRepository(),
      initialScope: current,
    );
    final store = DashboardPresentationStore();
    final metrics = DashboardSummaryMetricsController(
      navigation: navigation,
      query: query,
      presentationStore: store,
    );
    addTearDown(metrics.dispose);
    addTearDown(query.dispose);
    addTearDown(navigation.dispose);
    addTearDown(store.dispose);

    final targetParent = const MonthScope(YearMonth(year: 2026, month: 4));
    final targetChild = const DayScope(
      LocalDate(year: 2026, month: 4, day: 14),
    );
    final targetScope = _scope(targetChild);
    _seed(store, targetScope, amount: 14, count: 1);

    final candidate = navigation.parentPreview(
      DashboardTimeNavigationChangeDirection.backward,
    )!;
    expect(candidate.parentScope, targetParent);
    expect(metrics.previewParent(candidate, presentationEpoch: 2), isTrue);
    expect(store.activeSnapshot?.queryKey, targetScope.key);
    expect(metrics.presentation.scopeKey, targetScope.key.value);
  });

  test('parent preview cache miss keeps the outgoing coherent snapshot', () {
    final navigation = DashboardTimeNavigationController(
      initialDate: DateTime(2026, 5, 14),
      initialPlane: TimePlane.month,
      yearAnchor: 2026,
    );
    final current = _scope(const MonthScope(YearMonth(year: 2026, month: 5)));
    final query = CurrentQueryController(
      repository: _RecordingLedgerRepository(),
      initialScope: current,
    );
    final store = DashboardPresentationStore();
    final metrics = DashboardSummaryMetricsController(
      navigation: navigation,
      query: query,
      presentationStore: store,
    );
    addTearDown(metrics.dispose);
    addTearDown(query.dispose);
    addTearDown(navigation.dispose);
    addTearDown(store.dispose);

    _seed(store, current, amount: 500, count: 5);
    store.setVisibleTarget(
      DashboardVisiblePresentationTarget(
        plane: TimePlane.month,
        parentQueryKey: current.key,
        childQueryKey: null,
        railOpen: false,
        direction: LedgerDirection.income,
        presentationEpoch: 1,
      ),
    );
    store.publish(_snapshot(current, amount: 500, count: 5));
    final outgoingKey = store.activeSnapshot?.queryKey;

    final candidate = navigation.parentPreview(
      DashboardTimeNavigationChangeDirection.backward,
    )!;
    expect(metrics.previewParent(candidate, presentationEpoch: 2), isFalse);
    expect(store.activeSnapshot?.queryKey, outgoingKey);
    expect(metrics.presentation.formattedAmount, '5,00 Ft');
    expect(metrics.presentation.entryCount, 5);
    expect(metrics.presentation.formattedAmount, isNot('— Ft'));
  });

  test('parent motion has one idle and one settle per epoch', () {
    final controller = DashboardCoreController(autoStartQuery: false);
    addTearDown(controller.dispose);

    controller.beginParentMotion(CenteredCarouselMotionOrigin.userDrag);
    controller.previewParent(DashboardTimeNavigationChangeDirection.forward);
    controller.publishParentMotionIdle();
    controller.publishParentMotionIdle();
    controller.publishParentMotionSettle();
    controller.publishParentMotionSettle();

    expect(controller.parentMotion.duplicateIdleDroppedCount, 1);
    expect(controller.parentMotion.duplicateSettleDroppedCount, 1);
  });

  test(
    'commit promotes an existing parent preview without republishing it',
    () {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 5, 14),
        autoStartQuery: false,
      );
      addTearDown(controller.dispose);

      final current = _scope(const MonthScope(YearMonth(year: 2026, month: 5)));
      final next = _scope(const MonthScope(YearMonth(year: 2026, month: 6)));
      _seed(controller.presentationStore, current, amount: 500, count: 5);
      _seed(controller.presentationStore, next, amount: 600, count: 6);
      controller.presentationStore.setVisibleTarget(
        DashboardVisiblePresentationTarget(
          plane: TimePlane.month,
          parentQueryKey: current.key,
          childQueryKey: null,
          railOpen: false,
          direction: LedgerDirection.income,
          presentationEpoch: 1,
        ),
      );
      controller.presentationStore.publish(
        _snapshot(current, amount: 500, count: 5),
      );

      controller.beginParentMotion(CenteredCarouselMotionOrigin.userDrag);
      expect(
        controller.previewParent(
          DashboardTimeNavigationChangeDirection.forward,
        ),
        isTrue,
      );
      expect(
        controller
            .presentationDiagnostics
            .parentPreviewPresentationPublishedCount,
        1,
      );

      controller.commitParentNavigation(
        DashboardTimeNavigationChangeDirection.forward,
      );

      expect(
        controller
            .presentationDiagnostics
            .parentPreviewPresentationPublishedCount,
        1,
      );
      expect(
        controller.rail.state.monthCursor,
        const YearMonth(year: 2026, month: 6),
      );
      expect(controller.presentationStore.activeSnapshot?.queryKey, next.key);
    },
  );

  test(
    'cached parent navigation while rail is open publishes parent and child atomically',
    () {
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 27),
        autoStartQuery: false,
      );
      addTearDown(controller.dispose);

      final targetChild = _scope(
        const DayScope(LocalDate(year: 2026, month: 6, day: 27)),
      );
      final targetParent = _scope(
        const MonthScope(YearMonth(year: 2026, month: 6)),
      );
      _seed(controller.presentationStore, targetParent, amount: 700, count: 30);
      _seed(controller.presentationStore, targetChild, amount: 627, count: 27);
      controller.startQuery(reason: 'testSeedCommitted');

      controller.rail.setRailOpen(true);
      expect(
        controller.summaryMetrics.hasCompleteParentDisplayBundle(
          parentScope: _scope(
            const MonthScope(YearMonth(year: 2026, month: 6)),
          ),
          childPeriod: TimeChildPeriod.day,
        ),
        isTrue,
      );
      controller.beginParentMotion(CenteredCarouselMotionOrigin.userDrag);
      expect(
        controller.previewParent(
          DashboardTimeNavigationChangeDirection.backward,
        ),
        isTrue,
      );

      controller.commitParentNavigation(
        DashboardTimeNavigationChangeDirection.backward,
      );

      final target = controller.presentationStore.visibleTarget;
      expect(controller.rail.state.isRailOpen, isTrue);
      expect(controller.rail.state.parentScope.canonicalKey, 'month:2026-06');
      expect(
        target?.parentQueryKey,
        _scope(const MonthScope(YearMonth(year: 2026, month: 6))).key,
      );
      expect(target?.childQueryKey, targetChild.key);
      expect(target?.expectedVisibleQueryKey, targetChild.key);
      expect(
        controller.presentationStore.activeSnapshot?.queryKey,
        targetChild.key,
      );
      expect(
        controller.rail.state.lastChange.kind,
        DashboardTimeNavigationChangeKind.parentWhileRailOpen,
      );
      expect(controller.atomicParentChildPublishes, 1);
      expect(controller.parentWhileOpenTransitions, 1);
      expect(controller.liveFallbackDuringCachedParentNavigation, 0);
      expect(controller.repositoryReadsBeforeVisiblePublish, 0);

      final mayParent = _scope(
        const MonthScope(YearMonth(year: 2026, month: 5)),
      );
      final mayChild = _scope(
        const DayScope(LocalDate(year: 2026, month: 5, day: 27)),
      );
      _seed(controller.presentationStore, mayParent, amount: 500, count: 31);
      _seed(controller.presentationStore, mayChild, amount: 527, count: 27);

      controller.commitParentNavigation(
        DashboardTimeNavigationChangeDirection.backward,
      );

      expect(controller.rail.state.parentScope.canonicalKey, 'month:2026-05');
      expect(
        controller.presentationStore.visibleTarget?.parentQueryKey,
        mayParent.key,
      );
      expect(
        controller.presentationStore.visibleTarget?.childQueryKey,
        mayChild.key,
      );
      expect(
        controller.presentationStore.activeSnapshot?.queryKey,
        mayChild.key,
      );
      expect(controller.atomicParentChildPublishes, 2);
    },
  );

  test(
    'cold open-rail parent navigation keeps the outgoing snapshot until the complete target arrives',
    () async {
      final repository = _ParentBundleRepository();
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 27),
        queryRepository: repository,
        autoStartQuery: false,
      );
      addTearDown(controller.dispose);

      final july = _scope(const MonthScope(YearMonth(year: 2026, month: 7)));
      await controller.summaryMetrics.prepareParentDisplayBundle(
        parentScope: july,
        childPeriod: TimeChildPeriod.day,
        source: 'testCurrentParent',
      );
      controller.rail.setRailOpen(true);
      await Future<void>.delayed(Duration.zero);

      final outgoing = controller.presentationStore.activeSnapshot;
      expect(
        outgoing?.scope?.timeScope,
        const DayScope(LocalDate(year: 2026, month: 7, day: 27)),
      );

      controller.commitParentNavigation(
        DashboardTimeNavigationChangeDirection.backward,
      );
      expect(
        controller.presentationStore.activeSnapshot?.queryKey,
        outgoing?.queryKey,
      );

      await Future<void>.delayed(Duration.zero);
      await Future<void>.delayed(Duration.zero);

      final target = controller.presentationStore.activeSnapshot;
      expect(
        target?.scope?.timeScope,
        const DayScope(LocalDate(year: 2026, month: 6, day: 27)),
      );
      expect(
        controller.presentationStore.visibleTarget?.parentQueryKey,
        _scope(const MonthScope(YearMonth(year: 2026, month: 6))).key,
      );
      expect(controller.atomicParentChildPublishes, 1);
      expect(controller.parentDeckMismatchPrevented, 0);
      expect(controller.repositoryReadsBeforeVisiblePublish, greaterThan(0));
    },
  );
}
