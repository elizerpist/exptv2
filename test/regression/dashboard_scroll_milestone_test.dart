import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_vertical_geometry_manifest.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_kernel.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import '../support/dashboard_render_resources.dart';
import '../support/test_category_collection.dart';

/// These tests intentionally name the Android-approved interaction boundary.
/// They are deterministic regression contracts, not a claim that widget tests
/// measure device frame rate.
void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'APPROVED SCROLL MILESTONE: live page publication keeps an active vertical ballistic geometry-neutral',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(
        pageSize: 24,
        pagePreparationPolicy: const CommittedPagePreparationPolicy(
          contiguousUiBudgetMicros: 1000000,
        ),
      );
      final scenes = DashboardLogBoxPreparedSceneCache();
      final counters = DashboardPerformanceCounters();
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(scenes.dispose);

      final frame = _frame(
        totalRows: 192,
        mode: DashboardVisibleMode.committed,
      );
      final manifest = _manifest(frame);
      store.publish(frame);
      cache.seed(
        _page(frame, ordinal: 0),
        generation: 1,
        geometryManifest: manifest,
      );
      cache.configureSurfaceWidth(378);
      for (var ordinal = 1; ordinal <= 5; ordinal += 1) {
        expect(
          await cache.prepareAndCommit(
            _page(frame, ordinal: ordinal),
            canPublish: () => true,
          ),
          isTrue,
        );
      }
      await _activateRailScene(scenes, frame);

      await tester.pumpWidget(
        _logBoxViewport(
          store: store,
          cache: cache,
          scenes: scenes,
          counters: counters,
        ),
      );
      await tester.pump();

      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      await tester.fling(scrollView, const Offset(0, -180), 5000);
      await tester.pump(const Duration(milliseconds: 16));

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final position = scrollable.position;
      final scrollController = scrollable.widget.controller;
      final physics = position.physics;
      final extentBefore = cache.contentHeight;
      final maxBefore = position.maxScrollExtent;
      final geometryGeneration = cache.geometryGeneration;
      final resourceGeneration = cache.renderGeneration;

      expect(
        await cache.prepareAndCommit(
          _page(frame, ordinal: 6),
          canPublish: () => true,
        ),
        isTrue,
      );
      await tester.pump(const Duration(milliseconds: 16));

      expect(cache.contentHeight, extentBefore);
      expect(cache.geometryGeneration, geometryGeneration);
      expect(cache.renderGeneration, greaterThan(resourceGeneration));
      expect(position.maxScrollExtent, maxBefore);
      expect(identical(position.physics, physics), isTrue);
      expect(
        identical(
          tester.state<ScrollableState>(find.byType(Scrollable)),
          scrollable,
        ),
        isTrue,
      );
      expect(
        identical(
          tester.state<ScrollableState>(find.byType(Scrollable)).position,
          position,
        ),
        isTrue,
      );
      expect(
        identical(
          tester
              .state<ScrollableState>(find.byType(Scrollable))
              .widget
              .controller,
          scrollController,
        ),
        isTrue,
      );
      expect(cache.retainedPageCount, lessThanOrEqualTo(5));
      expect(cache.rootPagePresent, isTrue);
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
      expect(cache.textLayoutMissCount, 0);
      expect(counters.value(DashboardPerformanceMetric.verticalCacheMiss), 0);
      expect(counters.value(DashboardPerformanceMetric.textLayoutMiss), 0);
      expect(cache.virtualPageMissCount, 0);
      expect(cache.virtualGeometryMismatchCount, 0);

      await tester.pumpAndSettle();
      final summary = FluviDiagnosticLogger.entries
          .where((event) => event.stage == 'VERTICAL_INTERACTION_PERF_SUMMARY')
          .single;
      expect(summary.message, contains('goBallisticInvocationCount=1'));
      expect(summary.message, contains('contentDimensionChangeCount=0'));
    },
  );

  testWidgets(
    'APPROVED SCROLL MILESTONE: rail motion and Query publication retain the horizontal controller contract',
    (tester) async {
      final core = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
      );
      final modeController = DashboardCoreModeController(
        initialMode: DashboardModeSpec.balance,
      );
      addTearDown(core.dispose);
      addTearDown(modeController.dispose);
      await core.bootstrap();
      await tester.pumpWidget(
        MaterialApp(
          home: CoreDashboard(
            controller: core,
            modeController: modeController,
            categoryCollection: emptyTestCategoryCollection,
          ),
        ),
      );
      await tester.pump();

      final rail = find.byKey(const ValueKey('dashboard-time-rail'));
      final railState = tester.state(rail);
      final carousel = core.motion.carouselController;
      final scrollController = carousel.scrollController;
      final position = scrollController.position;
      final physics = core.motion.dashboardPhysics;
      final nextIndex =
          (core.motion.state.semanticIndex + 1) % core.motion.catalog.length;

      core.setRailOpen(true);
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(nextIndex);
      core.settleRail(nextIndex);
      await tester.pump();

      final applied = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        categoryIds: const <String>{'food'},
      );
      expect(await core.applyQuery(applied), isTrue);
      await tester.pumpAndSettle();

      expect(identical(tester.state(rail), railState), isTrue);
      expect(identical(core.motion.carouselController, carousel), isTrue);
      expect(identical(carousel.scrollController, scrollController), isTrue);
      expect(identical(scrollController.position, position), isTrue);
      expect(identical(core.motion.dashboardPhysics, physics), isTrue);
      expect(carousel.physicsCreationCount, 1);
      expect(core.motion.state.semanticIndex, carousel.selectedLogicalIndex);
      expect(core.committedLogViewport.isVerticalRenderingActive, isFalse);
      expect(core.renderReadinessDiagnostics.railCriticalCacheMissCount, 0);
      expect(
        core.performanceCounters.value(
          DashboardPerformanceMetric.textLayoutMiss,
        ),
        0,
      );
    },
  );

  test(
    'APPROVED SCROLL MILESTONE: Query publication, rail ownership and virtual resources stay independent',
    () async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final rail = DashboardMotionKernel(
        catalog: DashboardSemanticCatalog.forParent(
          parentScope: CurrentLedgerQueryScope(
            direction: LedgerDirection.expense,
            timeScope: const AllTimeScope(),
          ),
          childKind: DashboardChildKind.year,
          retainedYear: 2026,
        ),
        initialLogicalIndex: 0,
      );
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(rail.dispose);

      final railController = rail.carouselController;
      final railScrollController = railController.scrollController;
      final railPhysics = rail.dashboardPhysics;
      final queryA = _frame(
        totalRows: 96,
        mode: DashboardVisibleMode.committed,
      );
      final queryB = _frame(
        totalRows: 96,
        mode: DashboardVisibleMode.committed,
        categoryIds: const <String>{'food'},
        presentationEpoch: 2,
      );

      store.publish(queryA);
      cache.seed(
        _page(queryA, ordinal: 0),
        generation: 1,
        geometryManifest: _manifest(queryA),
      );
      cache.configureSurfaceWidth(378);
      // This models the atomic boundary after a fully prepared Query
      // candidate activates: no rail object is a vertical resource owner.
      store.publish(queryB);
      cache.seed(
        _page(queryB, ordinal: 0),
        generation: 2,
        geometryManifest: _manifest(queryB),
      );
      final geometryGeneration = cache.geometryGeneration;
      final extent = cache.contentHeight;

      expect(
        await cache.prepareAndCommit(
          _page(queryB, ordinal: 1),
          canPublish: () => true,
        ),
        isTrue,
      );
      rail.beginGesture();
      rail.semanticCrossed(1);
      rail.settled(1);

      expect(store.value?.queryKey, queryB.queryKey);
      expect(cache.queryKey, queryB.queryKey);
      expect(cache.contentHeight, extent);
      expect(cache.geometryGeneration, geometryGeneration);
      expect(identical(rail.carouselController, railController), isTrue);
      expect(
        identical(railController.scrollController, railScrollController),
        isTrue,
      );
      expect(identical(rail.dashboardPhysics, railPhysics), isTrue);
    },
  );
}

Widget _logBoxViewport({
  required DashboardVisibleFrameStore store,
  required CommittedLogViewportCache cache,
  required DashboardLogBoxPreparedSceneCache scenes,
  required DashboardPerformanceCounters counters,
}) => MaterialApp(
  home: SizedBox(
    width: 378,
    height: 420,
    child: DashboardLogBoxViewport(
      bounds: const DashboardBounds(left: 0, top: 28, width: 378, height: 28),
      visibleFrames: store,
      committedViewport: cache,
      preparedSceneCache: scenes,
      preparedRasters: PreparedVectorAssetAtlas.instance.logBoxRastersFor(3),
      onLoadNextPage: (_) {},
      performanceCounters: counters,
    ),
  ),
);

Future<void> _activateRailScene(
  DashboardLogBoxPreparedSceneCache cache,
  DashboardVisibleFrame frame,
) async {
  final window = DashboardLogBoxSceneWindow(
    identity: 'approved-milestone:${frame.queryKey.value}',
    payloads: <DashboardLogViewportState>[frame.logBox],
  );
  await cache.prepareWindow(window: window, surfaceWidth: 378);
  cache.activateWindow(window);
}

DashboardVisibleFrame _frame({
  required int totalRows,
  required DashboardVisibleMode mode,
  Set<String> categoryIds = const <String>{},
  int presentationEpoch = 1,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const AllTimeScope(),
    categoryIds: categoryIds,
  );
  final rootRows = List<DashboardLogRowViewModel>.generate(
    totalRows.clamp(0, 24).toInt(),
    _row,
    growable: false,
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: <DashboardDayLogGroupViewModel>[
      DashboardDayLogGroupViewModel(
        dateKey: '2026-07-01',
        dayLabel: '2026. július 1.',
        rows: rootRows,
      ),
    ],
    entryCount: totalRows,
    nextCursor: totalRows > 24 ? _cursor(0) : null,
    direction: LedgerDirection.expense,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: 1,
    formattedAmount: '1 Ft',
    entryCount: totalRows,
    formattedEntryCount: '$totalRows',
    logBox: logBox,
    presentationDigest: Object.hash(scope.key, totalRows),
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026. július',
    navigationEpoch: presentationEpoch,
    presentationEpoch: presentationEpoch,
    frameGeneration: presentationEpoch,
    mode: mode,
  );
}

CommittedLogPage _page(DashboardVisibleFrame frame, {required int ordinal}) {
  final start = ordinal * 24;
  final rowCount = (frame.logBox.entryCount - start).clamp(0, 24).toInt();
  final rows = List<DashboardLogRowViewModel>.generate(
    rowCount,
    (index) => _row(start + index),
    growable: false,
  );
  return CommittedLogPage(
    queryKey: frame.queryKey,
    coreRevision: frame.coreRevision,
    generation: ordinal == 0 ? 1 : frame.presentationEpoch,
    ordinal: ordinal,
    startCursor: ordinal == 0 ? null : _cursor(ordinal - 1),
    previousStartCursor: ordinal < 2 ? null : _cursor(ordinal - 2),
    payload: DashboardLogViewportState(
      queryKey: frame.queryKey,
      revision: frame.coreRevision,
      groups: <DashboardDayLogGroupViewModel>[
        DashboardDayLogGroupViewModel(
          dateKey: '2026-07-01',
          dayLabel: '2026. július 1.',
          rows: rows,
        ),
      ],
      entryCount: frame.logBox.entryCount,
      nextCursor: start + rowCount < frame.logBox.entryCount
          ? _cursor(ordinal)
          : null,
      direction: LedgerDirection.expense,
    ),
  );
}

DashboardLogRowViewModel _row(int index) => DashboardLogRowViewModel(
  entryId: 'approved-$index',
  displayName: 'Approved row $index',
  categoryDisplayName: 'Category',
  formattedAmount: '-1,00 Ft',
  displayTime: '12:00',
  amountStyle: LogAmountStyle.expense,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
  semanticLabel: 'Approved row $index',
);

Map<String, Object?> _cursor(int ordinal) => <String, Object?>{
  'bookedLocalEpochDay': 20000 - ordinal,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'approved-${ordinal * 24 + 23}',
};

CommittedVerticalGeometryManifest _manifest(DashboardVisibleFrame frame) =>
    CommittedVerticalGeometryManifest.compile(
      queryKey: frame.queryKey,
      coreRevision: frame.coreRevision,
      pageSize: 24,
      totalEntryCount: frame.logBox.entryCount,
      dayBuckets: <CommittedVerticalGeometryDayBucket>[
        if (frame.logBox.entryCount > 0)
          CommittedVerticalGeometryDayBucket(
            bookedLocalEpochDay: 20000,
            entryCount: frame.logBox.entryCount,
          ),
      ],
    );
