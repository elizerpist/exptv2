import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/committed_log_viewport_cache.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/runtime/application/explicit_committed_paging_controller.dart';
import 'package:fluvi/features/dashboard/runtime/data/dashboard_data_runtime_repository.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/application/dashboard_visible_frame_store.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

import '../../../support/dashboard_render_resources.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'activating the exact prepared scene schedules paint without an external rebuild',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final railScenes = DashboardLogBoxPreparedSceneCache();
      final counters = DashboardPerformanceCounters();
      final publishedExtents = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(store.dispose);
      addTearDown(railScenes.dispose);
      final visible = _visible(rowId: 'activation', epoch: 1, rowCount: 2);
      final inactive = _visible(rowId: 'inactive', epoch: 2, month: 8);
      final inactiveWindow = DashboardLogBoxSceneWindow(
        identity: 'inactive-scene-window',
        payloads: <DashboardLogViewportState>[inactive.logBox],
      );
      store.publish(visible);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              preparedSceneCache: railScenes,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              sceneWindowProvider: () => inactiveWindow,
              onLoadNextPage: (_) {},
              onExtentPublished: publishedExtents.add,
              performanceCounters: counters,
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pumpAndSettle();

      expect(railScenes.sceneFor(visible.logBox), isNull);
      expect(
        publishedExtents.last.drawableRowCount,
        2,
        reason:
            'The committed root fallback is now the automatic exact-width '
            'paint source whenever the initial rail scene is absent.',
      );
      expect(tester.binding.hasScheduledFrame, isFalse);

      final window = DashboardLogBoxSceneWindow(
        identity: 'activation-without-parent-rebuild',
        payloads: <DashboardLogViewportState>[visible.logBox],
      );
      await railScenes.prepareWindow(window: window, surfaceWidth: 378);
      expect(tester.binding.hasScheduledFrame, isFalse);
      final paintedRowsBeforeActivation = counters.value(
        DashboardPerformanceMetric.logVisibleSlotPaint,
      );
      final sceneHitsBeforeActivation = railScenes.railCriticalLookupHitCount;

      railScenes.activateWindow(window);

      // This assertion is the regression contract. A later tester.pump() may
      // consume a scheduled frame, but must never be the event that creates it.
      expect(tester.binding.hasScheduledFrame, isTrue);

      await tester.pump();
      await tester.pump();

      expect(
        railScenes.railCriticalLookupHitCount,
        greaterThan(sceneHitsBeforeActivation),
      );
      expect(
        counters.value(DashboardPerformanceMetric.logVisibleSlotPaint),
        paintedRowsBeforeActivation + 2,
      );
    },
  );

  testWidgets('viewport State and Scrollable identity survive frame swaps', (
    tester,
  ) async {
    final store = DashboardVisibleFrameStore();
    final counters = DashboardPerformanceCounters();
    addTearDown(store.dispose);
    store.publish(_visible(rowId: 'first', epoch: 1));

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          height: 700,
          child: DashboardLogBoxViewport(
            bounds: const DashboardBounds(
              left: 0,
              top: 28,
              width: 378,
              height: 28,
            ),
            visibleFrames: store,
            preparedRasters: PreparedVectorAssetAtlas.instance.logBoxRastersFor(
              3,
            ),
            onLoadNextPage: (_) {},
            performanceCounters: counters,
          ),
        ),
      ),
    );
    final viewportFinder = find.byType(DashboardLogBoxViewport);
    final viewportState = tester.state(viewportFinder);
    final scrollState = tester.state(find.byType(Scrollable));
    final surface = find.byKey(
      const ValueKey('dashboard-logbox-stable-render-surface'),
    );
    final surfaceRenderObject = tester.renderObject(surface);
    counters.reset();

    store.publish(_visible(rowId: 'second', epoch: 2));
    await tester.pump();

    expect(identical(tester.state(viewportFinder), viewportState), isTrue);
    expect(
      identical(tester.state(find.byType(Scrollable)), scrollState),
      isTrue,
    );
    expect(
      identical(tester.renderObject(surface), surfaceRenderObject),
      isTrue,
    );
    expect(
      counters.value(DashboardPerformanceMetric.logViewportBuild),
      0,
      reason: 'A frame swap must not rebuild the viewport shell.',
    );
    expect(counters.value(DashboardPerformanceMetric.logBoxBuild), 1);
    expect(
      counters.value(DashboardPerformanceMetric.logRenderSurfaceUpdate),
      1,
    );
  });

  testWidgets(
    'a sibling preview resets a deep stable vertical position before its first frame',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final scopeResets = <int>[];
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      final july = _visible(
        rowId: 'july',
        epoch: 1,
        rowCount: 24,
        mode: DashboardVisibleMode.committed,
      );
      store.publish(july);
      cache.seed(
        CommittedLogPage(
          queryKey: july.queryKey,
          coreRevision: july.coreRevision,
          generation: 1,
          ordinal: 0,
          startCursor: null,
          previousStartCursor: null,
          payload: july.logBox,
        ),
        generation: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              onCommittedScopeReset: () => scopeResets.add(1),
            ),
          ),
        ),
      );
      await tester.pump();
      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final position = scrollable.position;
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(position.pixels, greaterThan(position.minScrollExtent));

      final augustPreview = _visible(
        rowId: 'preview-august',
        epoch: 2,
        month: 8,
        rowCount: 24,
        mode: DashboardVisibleMode.preview,
      );
      final payloadOffsets = <double>[];
      store.logBoxLane.addListener(() {
        if (store.logBoxLane.value?.queryKey == augustPreview.queryKey) {
          payloadOffsets.add(position.pixels);
        }
      });
      store.publish(augustPreview);
      expect(
        position.pixels,
        position.minScrollExtent,
        reason:
            'the April-like preview must never inherit the old sibling offset',
      );
      expect(
        payloadOffsets,
        <double>[position.minScrollExtent],
        reason: 'the new payload listener observes the pre-paint top reset',
      );
      expect(scopeResets.length, 1);

      final preview = store.value!;
      expect(
        store.promoteCommitted(
          expectedKey: preview.queryKey,
          epoch: preview.presentationEpoch,
        ),
        isTrue,
      );
      expect(position.pixels, position.minScrollExtent);

      for (final month in <int>[3, 2, 1]) {
        store.publish(
          _visible(
            rowId: 'rapid-$month',
            epoch: 10 - month,
            month: month,
            rowCount: 24,
            mode: DashboardVisibleMode.preview,
          ),
        );
        expect(position.pixels, position.minScrollExtent);
      }
      expect(
        scopeResets.length,
        1,
        reason:
            'only the first rapid sibling crossing mutates an already-top position',
      );

      expect(
        identical(
          tester.state<ScrollableState>(find.byType(Scrollable)).position,
          position,
        ),
        isTrue,
      );
      expect(position.pixels, position.minScrollExtent);
    },
  );

  testWidgets(
    'a visible sibling reset interrupts an active vertical ballistic without replacing its position',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      final may = _visible(
        rowId: 'may',
        epoch: 1,
        month: 5,
        rowCount: 24,
        mode: DashboardVisibleMode.committed,
      );
      store.publish(may);
      cache.seed(
        CommittedLogPage(
          queryKey: may.queryKey,
          coreRevision: may.coreRevision,
          generation: 1,
          ordinal: 0,
          startCursor: null,
          previousStartCursor: null,
          payload: may.logBox,
        ),
        generation: 1,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final originalPosition = position;
      expect(position.maxScrollExtent, greaterThan(position.minScrollExtent));
      unawaited(
        position.animateTo(
          position.maxScrollExtent,
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));
      expect(position.pixels, greaterThan(position.minScrollExtent));

      store.publish(
        _visible(
          rowId: 'april',
          epoch: 2,
          month: 4,
          rowCount: 24,
          mode: DashboardVisibleMode.preview,
        ),
      );
      expect(position.pixels, position.minScrollExtent);
      await tester.pump(const Duration(seconds: 2));
      expect(position.pixels, position.minScrollExtent);
      expect(
        identical(
          tester.state<ScrollableState>(find.byType(Scrollable)).position,
          originalPosition,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'a stale pre-session update cannot page or move a newly committed sibling',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final demands = <int>[];
      var demandEpochs = 0;
      var previewTakeovers = 0;
      addTearDown(store.dispose);
      addTearDown(cache.dispose);

      void takeOverCurrentPreview() {
        final preview = store.value;
        if (preview == null || preview.mode != DashboardVisibleMode.preview) {
          return;
        }
        if (!store.promoteCommitted(
          expectedKey: preview.queryKey,
          epoch: preview.presentationEpoch,
        )) {
          return;
        }
        final committed = store.value!;
        cache.seed(
          CommittedLogPage(
            queryKey: committed.queryKey,
            coreRevision: committed.coreRevision,
            generation: 2,
            ordinal: 0,
            startCursor: null,
            previousStartCursor: null,
            payload: committed.logBox,
          ),
          generation: 2,
        );
        previewTakeovers += 1;
      }

      final may = _visible(
        rowId: 'may',
        epoch: 1,
        month: 5,
        rowCount: 24,
        totalEntryCount: 300,
        nextCursor: _pageCursor(0),
        mode: DashboardVisibleMode.committed,
      );
      store.publish(may);
      cache.seed(
        CommittedLogPage(
          queryKey: may.queryKey,
          coreRevision: may.coreRevision,
          generation: 1,
          ordinal: 0,
          startCursor: null,
          previousStartCursor: null,
          payload: may.logBox,
        ),
        generation: 1,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onVerticalScrollStarted: () => demandEpochs += 1,
              onVerticalPointerDown: takeOverCurrentPreview,
              onLoadNextPage: demands.add,
            ),
          ),
        ),
      );
      await tester.pump();
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      final oldGesture = await tester.startGesture(
        tester.getCenter(scrollView),
      );
      await tester.pump();
      await oldGesture.moveBy(const Offset(0, -100));
      await tester.pump();
      await oldGesture.moveBy(const Offset(0, -500));
      await tester.pump();
      expect(position.pixels, greaterThan(position.minScrollExtent));
      expect(demandEpochs, 1);
      demands.clear();
      demandEpochs = 0;

      final aprilPreview = _visible(
        rowId: 'april',
        epoch: 2,
        month: 4,
        rowCount: 24,
        totalEntryCount: 300,
        nextCursor: _pageCursor(0),
        mode: DashboardVisibleMode.preview,
      );
      store.publish(aprilPreview);
      expect(position.pixels, position.minScrollExtent);
      await tester.pump();

      await oldGesture.up();
      // A stale ballistic continuation has no new user drag identity. It must
      // be rejected rather than becoming April's demand epoch 0 paging path.
      unawaited(
        position.animateTo(
          position.maxScrollExtent,
          duration: const Duration(seconds: 1),
          curve: Curves.linear,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 120));

      expect(demands, isEmpty);
      expect(demandEpochs, 0);
      expect(position.pixels, position.minScrollExtent);
      expect(cache.queryKey, may.queryKey);
      expect(
        FluviDiagnosticLogger.entries
            .where((event) => event.stage == 'STALE_VERTICAL_ACTIVITY_REJECTED')
            .length,
        1,
      );

      await tester.drag(scrollView, const Offset(0, -600));
      await tester.pump();

      expect(previewTakeovers, 1);
      expect(store.value?.queryKey, aprilPreview.queryKey);
      expect(demandEpochs, 1);
      expect(cache.isVerticalRenderingActive, isTrue);
      expect(demands, isNotEmpty);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) => event.stage == 'VERTICAL_DOMAIN_PROMOTION_LATE',
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'a metadata-only same-scope settle does not reset a stable vertical position',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      final preview = _visible(
        rowId: 'june-preview',
        epoch: 1,
        month: 6,
        rowCount: 24,
        mode: DashboardVisibleMode.preview,
      );
      store.publish(preview);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
            ),
          ),
        ),
      );
      await tester.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      position.jumpTo(position.maxScrollExtent);
      await tester.pump();
      expect(position.pixels, greaterThan(position.minScrollExtent));

      var payloadNotifications = 0;
      var presentationNotifications = 0;
      store.logBoxLane.addListener(() => payloadNotifications += 1);
      store.logBoxPresentationLane.addListener(
        () => presentationNotifications += 1,
      );

      expect(
        store.promoteCommitted(
          expectedKey: preview.queryKey,
          epoch: preview.presentationEpoch,
        ),
        isTrue,
      );
      await tester.pump();

      expect(payloadNotifications, 0);
      expect(presentationNotifications, 1);
      expect(position.pixels, greaterThan(position.minScrollExtent));
    },
  );

  testWidgets(
    'plane and direction visible scopes reset once at preview while same-scope settle preserves top',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final resets = <int>[];
      addTearDown(store.dispose);
      final initial = _visible(
        rowId: 'expense-month',
        epoch: 1,
        rowCount: 24,
        mode: DashboardVisibleMode.committed,
      );
      store.publish(initial);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              onCommittedScopeReset: () => resets.add(1),
            ),
          ),
        ),
      );
      await tester.pump();
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;

      Future<void> scrollDeep() async {
        position.jumpTo(position.maxScrollExtent);
        await tester.pump();
        expect(position.pixels, greaterThan(position.minScrollExtent));
      }

      await scrollDeep();
      final dayPreview = _visibleForScope(
        rowId: 'expense-day-preview',
        epoch: 2,
        scope: DayScope(const YearMonth(year: 2026, month: 7).clampDay(16)),
        plane: TimePlane.month,
        direction: LedgerDirection.expense,
        mode: DashboardVisibleMode.preview,
      );
      store.publish(dayPreview);
      await tester.pump();
      expect(resets.length, 1, reason: 'a plane preview resets before paint');
      expect(position.pixels, position.minScrollExtent);

      expect(
        store.promoteCommitted(
          expectedKey: dayPreview.queryKey,
          epoch: dayPreview.presentationEpoch,
        ),
        isTrue,
      );
      await tester.pump();
      await tester.pump();
      expect(resets.length, 1);
      expect(position.pixels, position.minScrollExtent);

      await scrollDeep();
      final incomePreview = _visibleForScope(
        rowId: 'income-month-preview',
        epoch: 3,
        scope: const MonthScope(YearMonth(year: 2026, month: 7)),
        plane: TimePlane.month,
        direction: LedgerDirection.income,
        mode: DashboardVisibleMode.preview,
      );
      store.publish(incomePreview);
      await tester.pump();
      expect(
        resets.length,
        2,
        reason: 'a direction preview resets before paint',
      );
      expect(position.pixels, position.minScrollExtent);

      expect(
        store.promoteCommitted(
          expectedKey: incomePreview.queryKey,
          epoch: incomePreview.presentationEpoch,
        ),
        isTrue,
      );
      await tester.pump();
      await tester.pump();
      expect(resets.length, 2);
      expect(position.pixels, position.minScrollExtent);

      await scrollDeep();
      final yearPreview = _visibleForScope(
        rowId: 'income-year-preview',
        epoch: 4,
        scope: const YearScope(2025),
        plane: TimePlane.sum,
        direction: LedgerDirection.income,
        mode: DashboardVisibleMode.preview,
      );
      store.publish(yearPreview);
      await tester.pump();
      expect(resets.length, 3, reason: 'a SUM/year sibling also resets');
      expect(position.pixels, position.minScrollExtent);
      expect(
        store.promoteCommitted(
          expectedKey: yearPreview.queryKey,
          epoch: yearPreview.presentationEpoch,
        ),
        isTrue,
      );
      await tester.pump();
      expect(resets.length, 3);
    },
  );

  testWidgets('day-group rows are built lazily', (tester) async {
    final rows = List<DashboardLogRowViewModel>.generate(
      1000,
      (index) => _row('row-$index'),
    );
    final group = DashboardDayLogGroupViewModel(
      dateKey: '2026-07-01',
      dayLabel: '2026. július 1.',
      rows: rows,
    );
    final counters = DashboardPerformanceCounters();
    final store = DashboardVisibleFrameStore();
    addTearDown(store.dispose);
    store.publish(_visibleWithGroups(<DashboardDayLogGroupViewModel>[group]));

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 378,
          height: 700,
          child: DashboardLogBoxViewport(
            bounds: const DashboardBounds(
              left: 0,
              top: 28,
              width: 378,
              height: 28,
            ),
            visibleFrames: store,
            preparedRasters: PreparedVectorAssetAtlas.instance.logBoxRastersFor(
              3,
            ),
            onLoadNextPage: (_) {},
            performanceCounters: counters,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('dashboard-logbox-stable-render-surface')),
      findsOneWidget,
    );
    expect(
      counters.value(DashboardPerformanceMetric.logVisibleSlotPaint),
      lessThan(1000),
    );
    expect(counters.value(DashboardPerformanceMetric.logRowBuild), 0);
  });

  testWidgets(
    'many prepared day groups use one lazy row slot per transaction',
    (tester) async {
      final groups = List<DashboardDayLogGroupViewModel>.generate(
        24,
        (index) => DashboardDayLogGroupViewModel(
          dateKey: '2026-07-${(index + 1).toString().padLeft(2, '0')}',
          dayLabel: '2026. július ${index + 1}.',
          rows: <DashboardLogRowViewModel>[_row('row-$index')],
        ),
      );
      final store = DashboardVisibleFrameStore();
      final counters = DashboardPerformanceCounters();
      addTearDown(store.dispose);
      store.publish(_visibleWithGroups(groups));

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) {},
              performanceCounters: counters,
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('dashboard-logbox-stable-render-surface')),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate(
          (widget) => widget.runtimeType.toString() == 'DashboardLogRow',
        ),
        findsNothing,
      );
      expect(
        store.value!.logBox.flatItems.length,
        groups.length,
        reason:
            'Day headers and gaps must be decoration inside a lazy transaction '
            'slot; a 24-row month must not become 71 sliver children.',
      );
    },
  );

  testWidgets(
    'metadata-only settle enables paging without remount or visual notify',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      addTearDown(store.dispose);
      store.publish(
        _visible(
          rowId: 'page',
          epoch: 1,
          rowCount: 40,
          nextCursor: const <String, Object?>{'entryId': 'page-39'},
          mode: DashboardVisibleMode.preview,
        ),
      );
      var pageRequests = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (_) => pageRequests += 1,
            ),
          ),
        ),
      );
      final viewportState = tester.state(find.byType(DashboardLogBoxViewport));
      expect(
        store.promoteCommitted(
          expectedKey: store.value!.queryKey,
          epoch: store.value!.presentationEpoch,
        ),
        isTrue,
      );

      await tester.drag(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        const Offset(0, -1600),
      );
      await tester.pump();

      expect(pageRequests, greaterThan(0));
      expect(
        identical(
          tester.state(find.byType(DashboardLogBoxViewport)),
          viewportState,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'same-payload committed settle publishes the full 94-row vertical extent through Flutter layout',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final railScenes = DashboardLogBoxPreparedSceneCache();
      final repository = _ImmediatePagedRepository(totalRows: 94);
      final publishedExtents = <DashboardLogBoxRenderExtentSnapshot>[];
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final preview = _visible(
        rowId: 'paged',
        epoch: 1,
        month: 6,
        rowCount: 24,
        totalEntryCount: 94,
        nextCursor: _pageCursor(0),
        mode: DashboardVisibleMode.preview,
      );
      store.publish(preview);
      final paging = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: store,
        committedViewport: cache,
        pageSize: 24,
      );
      addTearDown(paging.dispose);
      final sceneWindow = DashboardLogBoxSceneWindow(
        identity: 'june-preview-no-op-settle',
        payloads: <DashboardLogViewportState>[preview.logBox],
      );
      await railScenes.prepareWindow(window: sceneWindow, surfaceWidth: 378);
      railScenes.activateWindow(sceneWindow);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedSceneCache: railScenes,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (desired) {
                unawaited(paging.requestForwardDemand(desired));
              },
              onExtentPublished: publishedExtents.add,
            ),
          ),
        ),
      );
      await tester.pump();
      final surface = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final initialSurfaceHeight = tester.getSize(surface).height;
      final actualSurfaceWidth = tester.getSize(surface).width;
      var payloadNotifications = 0;
      store.logBoxLane.addListener(() => payloadNotifications += 1);

      expect(
        store.promoteCommitted(
          expectedKey: preview.queryKey,
          epoch: preview.presentationEpoch,
        ),
        isTrue,
      );
      paging.commitMetadata(store.value!);
      await tester.pump();
      await tester.pump();

      expect(
        payloadNotifications,
        0,
        reason: 'same visual payload must remain a no-op settle',
      );
      expect(cache.surfaceWidth, actualSurfaceWidth);

      for (
        var attempts = 0;
        cache.contiguousReadyRowCount < 94 && attempts < 40;
        attempts += 1
      ) {
        await tester.drag(scrollView, const Offset(0, -900));
        await tester.pump();
        await tester.pump();
      }

      final scrollable = tester.state<ScrollableState>(find.byType(Scrollable));
      final finalSurfaceHeight = tester.getSize(surface).height;
      expect(cache.contiguousReadyRowCount, 94, reason: '${cache.report()}');
      expect(cache.isVerticalRenderingActive, isTrue);
      expect(finalSurfaceHeight, greaterThan(initialSurfaceHeight));
      expect(finalSurfaceHeight, closeTo(cache.drawableExtent, 0.1));
      expect(scrollable.position.maxScrollExtent, greaterThan(1000));

      for (
        var attempts = 0;
        scrollable.position.pixels < scrollable.position.maxScrollExtent &&
            attempts < 40;
        attempts += 1
      ) {
        await tester.drag(scrollView, const Offset(0, -900));
        await tester.pump();
      }
      expect(
        scrollable.position.pixels,
        closeTo(scrollable.position.maxScrollExtent, 1),
      );
      expect(cache.rowAt(93)?.row.entryId, 'paged-93');
      expect(publishedExtents, isNotEmpty);
      expect(
        publishedExtents.last.toReportMap(),
        containsPair('renderDomain', 'committedVertical'),
      );
      expect(publishedExtents.last.renderedRowCount, 94);
      expect(publishedExtents.last.payloadRowCount, 24);
      expect(publishedExtents.last.drawableRowCount, 94);
      expect(publishedExtents.last.paintedRowCount, greaterThan(0));
      expect(publishedExtents.last.committedCacheReadyRows, 94);
      expect(publishedExtents.last.isMismatch, isFalse);
      final extentEvents = FluviDiagnosticLogger.entries
          .where(
            (event) =>
                event.stage == 'VERTICAL_EXTENT_PUBLISHED' &&
                event.queryKey == preview.queryKey.value,
          )
          .toList(growable: false);
      expect(extentEvents, isNotEmpty);
      expect(
        extentEvents.last.message,
        allOf(
          contains('renderDomain=committedVertical'),
          contains('payloadRowCount=24'),
          contains('drawableRowCount=94'),
          contains('paintedRowCount='),
          contains('committedCacheReadyRows=94'),
          contains('payloadViewportId=${preview.logBox.viewportId}'),
          contains('maxScrollExtent='),
        ),
      );
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'VERTICAL_SCROLL_EXTENT_MISMATCH' &&
              event.queryKey == preview.queryKey.value,
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'July and sibling month scopes publish their complete 94-row scroll extent after a visual no-op settle',
    (tester) async {
      for (final month in <int>[7, 6, 5, 4]) {
        final store = DashboardVisibleFrameStore();
        final cache = CommittedLogViewportCache(pageSize: 24);
        final railScenes = DashboardLogBoxPreparedSceneCache();
        final repository = _ImmediatePagedRepository(totalRows: 94);
        addTearDown(store.dispose);
        addTearDown(cache.dispose);
        addTearDown(railScenes.dispose);
        final preview = _visible(
          rowId: 'month-$month',
          epoch: month,
          month: month,
          rowCount: 24,
          totalEntryCount: 94,
          nextCursor: _pageCursor(0),
          mode: DashboardVisibleMode.preview,
        );
        store.publish(preview);
        final paging = ExplicitCommittedPagingController(
          repository: repository,
          visibleFrames: store,
          committedViewport: cache,
          pageSize: 24,
        );
        addTearDown(paging.dispose);
        final sceneWindow = DashboardLogBoxSceneWindow(
          identity: 'month-$month-preview-no-op-settle',
          payloads: <DashboardLogViewportState>[preview.logBox],
        );
        await railScenes.prepareWindow(window: sceneWindow, surfaceWidth: 378);
        railScenes.activateWindow(sceneWindow);

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 378,
              height: 420,
              child: DashboardLogBoxViewport(
                key: ValueKey<String>('month-$month-viewport'),
                bounds: const DashboardBounds(
                  left: 0,
                  top: 28,
                  width: 378,
                  height: 28,
                ),
                visibleFrames: store,
                committedViewport: cache,
                preparedSceneCache: railScenes,
                preparedRasters: PreparedVectorAssetAtlas.instance
                    .logBoxRastersFor(3),
                onLoadNextPage: (desired) {
                  unawaited(paging.requestForwardDemand(desired));
                },
              ),
            ),
          ),
        );
        await tester.pump();
        expect(
          store.promoteCommitted(
            expectedKey: preview.queryKey,
            epoch: preview.presentationEpoch,
          ),
          isTrue,
        );
        paging.commitMetadata(store.value!);
        await tester.pump();

        final scrollView = find.byKey(
          const ValueKey('dashboard-logbox-scroll-view'),
        );
        for (
          var attempts = 0;
          cache.contiguousReadyRowCount < 94 && attempts < 40;
          attempts += 1
        ) {
          await tester.drag(scrollView, const Offset(0, -900));
          await tester.pump();
          await tester.pump();
        }

        final surface = tester.getSize(
          find.byKey(const ValueKey('dashboard-logbox-stable-render-surface')),
        );
        final position = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        expect(
          cache.contiguousReadyRowCount,
          94,
          reason: '$month: ${cache.report()}',
        );
        expect(store.logBoxLane.value!.mode, DashboardVisibleMode.preview);
        expect(
          store.logBoxPresentationLane.value!.mode,
          DashboardVisibleMode.committed,
        );
        expect(surface.height, closeTo(cache.drawableExtent, 0.1));
        expect(position.maxScrollExtent, greaterThan(1000));
        expect(cache.rowAt(93)?.row.entryId, 'paged-93');

        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      }
    },
  );

  testWidgets(
    'one stable viewport resets once and its first sibling gesture crosses dense pages',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final railScenes = DashboardLogBoxPreparedSceneCache();
      const totalRows = 300;
      final repository = _ImmediatePagedRepository(totalRows: totalRows);
      final scopeResets = <int>[];
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final julyPreview = _visible(
        rowId: 'month-7',
        epoch: 1,
        month: 7,
        rowCount: 24,
        totalEntryCount: totalRows,
        nextCursor: _pageCursor(0),
        mode: DashboardVisibleMode.preview,
      );
      store.publish(julyPreview);
      final paging = ExplicitCommittedPagingController(
        repository: repository,
        visibleFrames: store,
        committedViewport: cache,
        pageSize: 24,
      );
      addTearDown(paging.dispose);
      void takeOverCurrentPreview() {
        final preview = store.value;
        if (preview == null || preview.mode != DashboardVisibleMode.preview) {
          return;
        }
        if (!store.promoteCommitted(
          expectedKey: preview.queryKey,
          epoch: preview.presentationEpoch,
        )) {
          return;
        }
        paging.commitMetadata(store.value!);
      }

      final initialWindow = DashboardLogBoxSceneWindow(
        identity: 'month-7-preview',
        payloads: <DashboardLogViewportState>[julyPreview.logBox],
      );
      await railScenes.prepareWindow(window: initialWindow, surfaceWidth: 378);
      railScenes.activateWindow(initialWindow);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedSceneCache: railScenes,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: (desired) {
                unawaited(paging.requestForwardDemand(desired));
              },
              onVerticalPointerDown: takeOverCurrentPreview,
              onVerticalScrollStarted: paging.beginForwardDemandEpoch,
              onCommittedScopeReset: () => scopeResets.add(1),
            ),
          ),
        ),
      );
      await tester.pump();
      final viewportFinder = find.byType(DashboardLogBoxViewport);
      final viewportState = tester.state(viewportFinder);
      final scrollableFinder = find.byType(Scrollable);
      final position = tester.state<ScrollableState>(scrollableFinder).position;
      final surfaceFinder = find.byKey(
        const ValueKey('dashboard-logbox-stable-render-surface'),
      );
      final surfaceRenderObject = tester.renderObject(surfaceFinder);
      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );

      for (final step in <({int month, int epoch})>[
        (month: 7, epoch: 1),
        (month: 6, epoch: 2),
        (month: 5, epoch: 3),
        (month: 4, epoch: 4),
      ]) {
        final isInitial = step.month == 7;
        final preview = isInitial
            ? julyPreview
            : _visible(
                rowId: 'month-${step.month}',
                epoch: step.epoch,
                month: step.month,
                rowCount: 24,
                totalEntryCount: totalRows,
                nextCursor: _pageCursor(0),
                mode: DashboardVisibleMode.preview,
              );
        if (!isInitial) {
          final window = DashboardLogBoxSceneWindow(
            identity: 'month-${step.month}-preview',
            payloads: <DashboardLogViewportState>[preview.logBox],
          );
          await railScenes.prepareWindow(window: window, surfaceWidth: 378);
          railScenes.activateWindow(window);
          final resetsBeforePreview = scopeResets.length;
          store.publish(preview);
          await tester.pump();
          expect(
            scopeResets.length,
            resetsBeforePreview + 1,
            reason: 'a sibling preview resets before its first paint',
          );
          expect(position.pixels, position.minScrollExtent);
        }

        final payloadNotificationsBefore = store.logBoxPayloadNotifyCount;
        final presentationNotificationsBefore =
            store.logBoxPresentationMetaNotifyCount;
        final resetsBeforeSettle = scopeResets.length;

        // The first new pointer owns the preview-to-committed handoff. Do not
        // manually promote page zero before this drag: production pointer-down
        // must make this same gesture eligible for a vertical session.
        await tester.drag(scrollView, const Offset(0, -900));
        await tester.pump();
        await tester.pump();

        expect(store.value?.mode, DashboardVisibleMode.committed);
        expect(store.value?.queryKey, preview.queryKey);
        expect(store.logBoxPayloadNotifyCount, payloadNotificationsBefore);
        expect(
          store.logBoxPresentationMetaNotifyCount,
          presentationNotificationsBefore + 1,
        );
        expect(scopeResets.length, resetsBeforeSettle);
        expect(identical(tester.state(viewportFinder), viewportState), isTrue);
        expect(
          identical(
            tester.state<ScrollableState>(scrollableFinder).position,
            position,
          ),
          isTrue,
        );
        expect(
          identical(tester.renderObject(surfaceFinder), surfaceRenderObject),
          isTrue,
        );

        for (
          var attempts = 0;
          cache.contiguousReadyRowCount < totalRows && attempts < 40;
          attempts += 1
        ) {
          await tester.drag(scrollView, const Offset(0, -900));
          await tester.pump();
          await tester.pump();
        }
        expect(
          cache.contiguousReadyRowCount,
          totalRows,
          reason: cache.report().toString(),
        );
        for (
          var attempts = 0;
          position.pixels < position.maxScrollExtent && attempts < 40;
          attempts += 1
        ) {
          await tester.drag(scrollView, const Offset(0, -900));
          await tester.pump();
        }
        expect(position.pixels, closeTo(position.maxScrollExtent, 1));
        expect(
          cache.rowAt(totalRows - 1)?.row.entryId,
          'paged-${totalRows - 1}',
        );
      }

      expect(scopeResets.length, 3);
      expect(
        FluviDiagnosticLogger.entries.where(
          (event) =>
              event.stage == 'VERTICAL_CACHE_MISS' ||
              event.stage == 'VERTICAL_SCROLL_EXTENT_MISMATCH',
        ),
        isEmpty,
      );
    },
  );

  testWidgets(
    'a 658-row committed scope exposes only page zero and sends bounded demand',
    (tester) async {
      final store = DashboardVisibleFrameStore();
      final cache = CommittedLogViewportCache(pageSize: 24);
      final railScenes = DashboardLogBoxPreparedSceneCache();
      final counters = DashboardPerformanceCounters();
      final forwardDemands = <int>[];
      addTearDown(store.dispose);
      addTearDown(cache.dispose);
      addTearDown(railScenes.dispose);
      final frame = _visible(
        rowId: 'virtual',
        epoch: 1,
        rowCount: 24,
        totalEntryCount: 658,
        nextCursor: const <String, Object?>{'entryId': 'virtual-23'},
      );
      cache.seed(
        CommittedLogPage(
          queryKey: frame.queryKey,
          coreRevision: frame.coreRevision,
          generation: 1,
          ordinal: 0,
          startCursor: null,
          previousStartCursor: null,
          payload: frame.logBox,
        ),
        generation: 1,
      );
      final sceneWindow = DashboardLogBoxSceneWindow(
        identity: 'test-initial-rail-preview',
        payloads: <DashboardLogViewportState>[frame.logBox],
      );
      await railScenes.prepareWindow(window: sceneWindow, surfaceWidth: 378);
      railScenes.activateWindow(sceneWindow);
      store.publish(frame);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 378,
            height: 420,
            child: DashboardLogBoxViewport(
              bounds: const DashboardBounds(
                left: 0,
                top: 28,
                width: 378,
                height: 28,
              ),
              visibleFrames: store,
              committedViewport: cache,
              preparedSceneCache: railScenes,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              onLoadNextPage: forwardDemands.add,
              performanceCounters: counters,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(cache.contentHeight, cache.pageHeightForOrdinal(0));
      expect(
        cache.preparedTextRowCount,
        24,
        reason:
            'The non-empty root keeps a bounded, asynchronously prepared '
            'fallback so it cannot expose scroll geometry without paint.',
      );
      expect(cache.rootPagePresent, isTrue);
      expect(cache.retainedPageCount, 0);
      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
        0,
      );

      await tester.drag(
        find.byKey(const ValueKey('dashboard-logbox-scroll-view')),
        const Offset(0, -600),
      );
      await tester.pump();

      expect(cache.isVerticalRenderingActive, isTrue);
      expect(forwardDemands, <int>[2]);
      expect(cache.preparedTextRowCount, 24);
      expect(cache.visibleEntryCount, greaterThan(0));
      expect(
        cache.estimatedBytes,
        lessThanOrEqualTo(cache.maximumRetainedBytes),
      );
      expect(counters.value(DashboardPerformanceMetric.logRowBuild), 0);
      expect(
        counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
        0,
        reason:
            'the initial vertical page uses its ready rail scene or the '
            'bounded committed-root fallback, never a paint-time layout.',
      );
    },
  );

  testWidgets(
    '658- and 1k-row committed lists cross every page boundary without blank content',
    (tester) async {
      const configurations = <({int totalRows, List<int> checkpoints})>[
        (totalRows: 658, checkpoints: <int>[24, 48, 96, 240, 657]),
        (totalRows: 1000, checkpoints: <int>[24, 100, 500, 999]),
      ];
      for (final configuration in configurations) {
        final totalRows = configuration.totalRows;
        final store = DashboardVisibleFrameStore();
        final cache = CommittedLogViewportCache(pageSize: 24);
        final railScenes = DashboardLogBoxPreparedSceneCache();
        final repository = _ImmediatePagedRepository(totalRows: totalRows);
        final counters = DashboardPerformanceCounters();
        addTearDown(store.dispose);
        addTearDown(cache.dispose);
        addTearDown(railScenes.dispose);
        final frame = _visible(
          rowId: 'paged',
          epoch: 1,
          rowCount: 24,
          totalEntryCount: totalRows,
          nextCursor: _pageCursor(0),
        );
        store.publish(frame);
        final controller = ExplicitCommittedPagingController(
          repository: repository,
          visibleFrames: store,
          committedViewport: cache,
          pageSize: 24,
        );
        addTearDown(controller.dispose);
        controller.commitMetadata(frame);
        final sceneWindow = DashboardLogBoxSceneWindow(
          identity: 'test-paged-rail-preview',
          payloads: <DashboardLogViewportState>[frame.logBox],
        );
        await railScenes.prepareWindow(window: sceneWindow, surfaceWidth: 378);
        railScenes.activateWindow(sceneWindow);

        await tester.pumpWidget(
          MaterialApp(
            home: SizedBox(
              width: 378,
              height: 420,
              child: DashboardLogBoxViewport(
                key: ValueKey<String>('full-paging-$totalRows'),
                bounds: const DashboardBounds(
                  left: 0,
                  top: 28,
                  width: 378,
                  height: 28,
                ),
                visibleFrames: store,
                committedViewport: cache,
                preparedSceneCache: railScenes,
                preparedRasters: PreparedVectorAssetAtlas.instance
                    .logBoxRastersFor(3),
                onLoadNextPage: (desired) {
                  unawaited(controller.requestForwardDemand(desired));
                },
                performanceCounters: counters,
              ),
            ),
          ),
        );
        await tester.pump();
        final scrollView = find.byKey(
          const ValueKey('dashboard-logbox-scroll-view'),
        );

        for (final row in configuration.checkpoints) {
          for (
            var attempts = 0;
            cache.contiguousReadyRowCount <= row && attempts < 40;
            attempts += 1
          ) {
            await tester.drag(scrollView, const Offset(0, -900));
            await tester.pump();
            await tester.pump();
          }
          final targetOffset =
              DashboardLogBoxTokens.summaryHeaderHeight +
              cache.pageTopForOrdinal(row ~/ cache.pageSize);
          for (
            var attempts = 0;
            tester
                        .state<ScrollableState>(find.byType(Scrollable))
                        .position
                        .pixels <
                    targetOffset - 32 &&
                attempts < 40;
            attempts += 1
          ) {
            await tester.drag(scrollView, const Offset(0, -900));
            await tester.pump();
            await tester.pump();
          }
          expect(
            cache.contiguousReadyRowCount,
            greaterThan(row),
            reason: 'page demand stalled: ${cache.report()}',
          );
          expect(
            cache.rowAt(row)?.row.entryId,
            'paged-$row',
            reason: 'row was not retained/drawable: ${cache.report()}',
          );
          expect(
            cache.layoutAt(row),
            isNotNull,
            reason: 'text layout was not drawable: ${cache.report()}',
          );
          expect(cache.contentHeight, greaterThan(0));
        }

        expect(cache.contiguousReadyRowCount, totalRows);
        expect(cache.hasMorePages, isFalse);
        expect(
          cache.estimatedBytes,
          lessThanOrEqualTo(cache.maximumRetainedBytes),
        );
        expect(
          counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
          0,
          reason: FluviDiagnosticLogger.entries
              .where(
                (event) =>
                    event.stage == 'VERTICAL_CACHE_MISS' ||
                    event.stage == 'TEXT_LAYOUT_MISS',
              )
              .map((event) => event.toLine())
              .join('\n'),
        );
        expect(
          repository.requestedOrdinals.toSet().length,
          repository.requestedOrdinals.length,
        );

        final scrollPosition = tester
            .state<ScrollableState>(find.byType(Scrollable))
            .position;
        for (var round = 0; round < 3; round += 1) {
          scrollPosition.jumpTo(scrollPosition.minScrollExtent);
          cache.updateVisibleRowWindow(start: 0, end: cache.pageSize);
          await tester.pump();

          expect(cache.rootPagePresent, isTrue);
          expect(
            cache.pageForOrdinal(0)?.payload.flatItems.first.row.entryId,
            'paged-0',
          );
          expect(cache.pageTopForOrdinal(0), 0);
          expect(
            counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
            0,
            reason: 'returning to root page must not produce a blank frame',
          );

          scrollPosition.jumpTo(scrollPosition.maxScrollExtent);
          cache.updateVisibleRowWindow(
            start: (totalRows - 1) ~/ cache.pageSize * cache.pageSize,
            end: totalRows,
          );
          await tester.pump();

          expect(
            cache.rowAt(totalRows - 1)?.row.entryId,
            'paged-${totalRows - 1}',
          );
          expect(
            counters.value(DashboardPerformanceMetric.logTextLayoutFallback),
            0,
          );
        }
      }
    },
  );
}

DashboardVisibleFrame _visible({
  required String rowId,
  required int epoch,
  int month = 7,
  int rowCount = 1,
  int? totalEntryCount,
  Map<String, Object?>? nextCursor,
  DashboardVisibleMode mode = DashboardVisibleMode.committed,
}) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: MonthScope(YearMonth(year: 2026, month: month)),
  );
  final total = totalEntryCount ?? rowCount;
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: [
      DashboardDayLogGroupViewModel(
        dateKey: '2026-${month.toString().padLeft(2, '0')}-01',
        dayLabel: '2026. $month. 1.',
        rows: List<DashboardLogRowViewModel>.generate(
          rowCount,
          (index) => _row(rowCount == 1 ? rowId : '$rowId-$index'),
        ),
      ),
    ],
    entryCount: total,
    nextCursor: nextCursor,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: epoch * 100,
    formattedAmount: '$epoch,00 Ft',
    entryCount: total,
    formattedEntryCount: '$total',
    logBox: logBox,
    presentationDigest: Object.hash(rowId, epoch),
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: '2026. $month.',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: epoch,
    mode: mode,
  );
}

DashboardVisibleFrame _visibleForScope({
  required String rowId,
  required int epoch,
  required LedgerTimeScope scope,
  required TimePlane plane,
  required LedgerDirection direction,
  required DashboardVisibleMode mode,
}) {
  final queryScope = CurrentLedgerQueryScope(
    direction: direction,
    timeScope: scope,
  );
  final logBox = DashboardLogViewportState(
    queryKey: queryScope.key,
    revision: 1,
    groups: <DashboardDayLogGroupViewModel>[
      DashboardDayLogGroupViewModel(
        dateKey: '2026-07-01',
        dayLabel: '2026. július 1.',
        rows: List<DashboardLogRowViewModel>.generate(
          24,
          (index) => _row('$rowId-$index'),
        ),
      ),
    ],
    entryCount: 24,
    nextCursor: null,
    direction: direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: queryScope,
    parentQueryKey: queryScope.key,
    coreRevision: 1,
    totalMinor: epoch,
    formattedAmount: '$epoch Ft',
    entryCount: 24,
    formattedEntryCount: '24',
    logBox: logBox,
    presentationDigest: Object.hash(rowId, epoch),
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: queryScope.key,
    plane: plane,
    railOpen: true,
    semanticIndex: 0,
    childLabel: 'child',
    navigationEpoch: epoch,
    presentationEpoch: epoch,
    frameGeneration: epoch,
    mode: mode,
  );
}

DashboardVisibleFrame _visibleWithGroups(
  List<DashboardDayLogGroupViewModel> groups,
) {
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: const YearScope(2026),
  );
  final logBox = DashboardLogViewportState(
    queryKey: scope.key,
    revision: 1,
    groups: groups,
    entryCount: groups.length,
    nextCursor: null,
    direction: scope.direction,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.key,
    coreRevision: 1,
    totalMinor: groups.length * 100,
    formattedAmount: '${groups.length},00 Ft',
    entryCount: groups.length,
    formattedEntryCount: '${groups.length}',
    logBox: logBox,
    presentationDigest: groups.length,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: scope.key,
    plane: TimePlane.year,
    railOpen: true,
    semanticIndex: 0,
    childLabel: '2026',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.preview,
  );
}

DashboardLogRowViewModel _row(String id) => DashboardLogRowViewModel(
  entryId: id,
  displayName: 'Partner $id',
  categoryDisplayName: 'Category',
  formattedAmount: '-1,00 Ft',
  displayTime: '12:00',
  amountStyle: LogAmountStyle.expense,
  categoryColorId: 'fallback',
  categoryIconId: 'fallback',
  semanticLabel: 'Partner $id, -1,00 Ft, kiadás, Category',
);

Map<String, Object?> _pageCursor(int ordinal) => <String, Object?>{
  'bookedLocalEpochDay': 20_000 - ordinal,
  'bookedLocalTimeMinutes': 600,
  'entryId': 'paged-${ordinal * 24 + 23}',
};

final class _ImmediatePagedRepository
    implements DashboardCommittedPageRepository {
  _ImmediatePagedRepository({required this.totalRows});

  final int totalRows;
  final List<int> requestedOrdinals = <int>[];

  @override
  Future<CommittedLogPage> readCommittedPage(
    DashboardCommittedPageRequest request,
  ) async {
    requestedOrdinals.add(request.pageOrdinal);
    final start = request.pageOrdinal * request.pageSize;
    final count = (totalRows - start).clamp(0, request.pageSize);
    final rows = List<DashboardLogRowViewModel>.generate(
      count,
      (index) => _row('paged-${start + index}'),
      growable: false,
    );
    return CommittedLogPage(
      queryKey: request.scope.key,
      coreRevision: request.coreRevision,
      generation: request.commitGeneration,
      ordinal: request.pageOrdinal,
      startCursor: request.startCursor,
      previousStartCursor: request.previousStartCursor,
      payload: DashboardLogViewportState(
        queryKey: request.scope.key,
        revision: request.coreRevision,
        groups: rows.isEmpty
            ? const <DashboardDayLogGroupViewModel>[]
            : <DashboardDayLogGroupViewModel>[
                DashboardDayLogGroupViewModel(
                  dateKey: '2026-07-01',
                  dayLabel: '2026. július 1.',
                  rows: rows,
                ),
              ],
        entryCount: totalRows,
        nextCursor: start + count < totalRows
            ? _pageCursor(request.pageOrdinal)
            : null,
        direction: request.scope.direction,
      ),
    );
  }
}
