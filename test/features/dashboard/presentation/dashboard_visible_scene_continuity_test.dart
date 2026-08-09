import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/assets/prepared_vector_asset_atlas.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_interaction_diagnostics.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_render_extent_snapshot.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_logbox_scene_window.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_prepared_scene_cache.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_logbox_viewport.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_controller.dart';

import '../../../support/dashboard_render_resources.dart';
import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    '2025 June remains drawable when real rail input cancels preparation',
    (tester) async {
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.year,
        initialDirection: LedgerDirection.expense,
        initialCoreRevision: 1,
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      await core.bootstrap();
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          initialYear: 2025,
          yearWindowRadius: 1,
          entryCountForScope: _dense2025EntryCount,
          previewRowCountForScope: _dense2025PreviewRowCount,
        ),
      );
      final railCriticalWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(
        window: railCriticalWindow,
        surfaceWidth: 378,
        devicePixelRatio: 3,
      );
      cache.activateWindow(railCriticalWindow);
      core.recordInitialSceneWindowActivation(railCriticalWindow);
      core.attachLogBoxSceneWindowCoordinator(
        prepare: (window, {required retainViewportId}) => cache.prepareWindow(
          window: window,
          retainViewportId: retainViewportId,
          surfaceWidth: 378,
          devicePixelRatio: 3,
        ),
        activate: cache.activateWindow,
        cancel: cache.cancelInFlightPreparation,
        report: cache.report,
      );

      final preparationEntered = Completer<void>();
      final releasePreparation = Completer<void>();
      final preparation = cache.prepareWindow(
        window: railCriticalWindow,
        surfaceWidth: 379,
        devicePixelRatio: 3,
        yieldEveryRows: 1,
        yieldToBackground: () {
          preparationEntered.complete();
          return releasePreparation.future;
        },
      );
      await preparationEntered.future;
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      releasePreparation.complete();
      await expectLater(
        preparation,
        throwsA(isA<DashboardLogBoxScenePreparationCancelled>()),
      );

      DashboardLogBoxRenderExtentSnapshot? snapshot;
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
              visibleFrames: core.visibleFrames,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              preparedSceneCache: cache,
              renderCriticalPayloads: core.renderCriticalLogBoxPayloads,
              sceneWindowProvider: core.railCriticalSceneWindow,
              onLoadNextPage: (_) {},
              onExtentPublished: (value) => snapshot = value,
              renderDiagnostics: core.renderReadinessDiagnostics,
            ),
          ),
        ),
      );
      await tester.pump();

      core.setRailOpen(true);
      await tester.pump();
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(core.motion.catalog.logicalIndexForValue(6));
      await tester.pump();
      await tester.pump();

      final juneExpense = core.preparedIndex!
          .frameFor(
            CurrentLedgerQueryScope(
              direction: LedgerDirection.expense,
              timeScope: MonthScope(const YearMonth(year: 2025, month: 6)),
            ),
          )
          .logBox;
      expect(core.visibleFrames.value!.queryKey, juneExpense.queryKey);
      expect(juneExpense.entryCount, 149);
      expect(juneExpense.flatItems, hasLength(24));
      expect(snapshot, isNotNull);
      expect(snapshot!.payloadRowCount, 24);
      expect(snapshot!.drawableRowCount, 24);
      expect(snapshot!.paintedRowCount, greaterThan(0));
      expect(cache.railCriticalLookupMissCount, 0);
      expect(cache.visiblePayloadWithoutDrawableCount, 0);
      expect(cache.visiblePayloadWithoutPaintCount, 0);
      expect(core.renderReadinessDiagnostics.railCriticalCacheMissCount, 0);

      // The same renderer-visible bank covers siblings beyond the old active
      // background window. Each selection is a real rail semantic crossing;
      // no preparation completion or local cache repair is involved.
      for (final month in <int>[5, 4, 12, 1, 6]) {
        core.semanticCrossed(core.motion.catalog.logicalIndexForValue(month));
        await tester.pump();
        await tester.pump();
        final payload = core.preparedIndex!
            .frameFor(
              CurrentLedgerQueryScope(
                direction: LedgerDirection.expense,
                timeScope: MonthScope(YearMonth(year: 2025, month: month)),
              ),
            )
            .logBox;
        expect(core.visibleFrames.value!.queryKey, payload.queryKey);
        expect(snapshot!.payloadRowCount, payload.flatItems.length);
        if (payload.flatItems.isNotEmpty) {
          expect(snapshot!.drawableRowCount, payload.flatItems.length);
          expect(snapshot!.paintedRowCount, greaterThan(0));
        }
      }

      core.navigatePlane(finer: true);
      await tester.pump();
      for (final day in <int>[22, 25, 19]) {
        core.semanticCrossed(core.motion.catalog.logicalIndexForValue(day));
        await tester.pump();
        await tester.pump();
        final payload = core.preparedIndex!
            .frameFor(
              CurrentLedgerQueryScope(
                direction: LedgerDirection.expense,
                timeScope: DayScope(LocalDate(year: 2025, month: 7, day: day)),
              ),
            )
            .logBox;
        expect(core.visibleFrames.value!.queryKey, payload.queryKey);
        expect(snapshot!.payloadRowCount, payload.flatItems.length);
        if (payload.flatItems.isNotEmpty) {
          expect(snapshot!.drawableRowCount, payload.flatItems.length);
          expect(snapshot!.paintedRowCount, greaterThan(0));
        }
      }
      expect(cache.railCriticalLookupMissCount, 0);
      expect(cache.visiblePayloadWithoutDrawableCount, 0);
      expect(cache.visiblePayloadWithoutPaintCount, 0);
    },
  );

  testWidgets(
    'the first vertical drag takes over the current dense 2025 rail preview',
    (tester) async {
      FluviDiagnosticLogger.clear();
      final interactionEvents = <DashboardInteractionDiagnosticEvent>[];
      final performanceCounters = DashboardPerformanceCounters();
      final core = DashboardCoreController(
        initialDate: DateTime(2025, 7, 14),
        initialPlane: TimePlane.year,
        initialDirection: LedgerDirection.expense,
        initialCoreRevision: 1,
        performanceCounters: performanceCounters,
        interactionDiagnostics: DashboardInteractionDiagnostics(
          counters: performanceCounters,
          sink: interactionEvents.add,
        ),
      );
      final cache = DashboardLogBoxPreparedSceneCache();
      addTearDown(core.dispose);
      addTearDown(cache.dispose);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetDevicePixelRatio);
      await core.bootstrap();
      await core.installPreparedIndex(
        buildRuntimeTestIndex(
          revision: 2,
          initialYear: 2025,
          yearWindowRadius: 1,
          entryCountForScope: _dense2025EntryCount,
          previewRowCountForScope: _dense2025PreviewRowCount,
        ),
      );
      final railCriticalWindow = core.railCriticalSceneWindow();
      await cache.prepareWindow(
        window: railCriticalWindow,
        surfaceWidth: 378,
        devicePixelRatio: 3,
      );
      cache.activateWindow(railCriticalWindow);
      core.recordInitialSceneWindowActivation(railCriticalWindow);

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
              visibleFrames: core.visibleFrames,
              preparedRasters: PreparedVectorAssetAtlas.instance
                  .logBoxRastersFor(3),
              committedViewport: core.committedLogViewport,
              preparedSceneCache: cache,
              renderCriticalPayloads: core.renderCriticalLogBoxPayloads,
              sceneWindowProvider: core.railCriticalSceneWindow,
              onLoadNextPage: (desiredLastReadyOrdinal) {
                unawaited(
                  core.requestForwardPageDemand(desiredLastReadyOrdinal),
                );
              },
              onVerticalPointerDown: core.noteVerticalPointerDown,
              onVerticalScrollStarted: core.beginVerticalInteraction,
              onVerticalScrollEnded:
                  core.resumeSceneWindowMaintenanceAfterVerticalInput,
              performanceCounters: core.performanceCounters,
            ),
          ),
        ),
      );
      await tester.pump();

      core.setRailOpen(true);
      core.beginRailMotion(CenteredCarouselMotionOrigin.userDrag);
      core.semanticCrossed(core.motion.catalog.logicalIndexForValue(6));
      await tester.pump();
      await tester.pump();

      final june = core.visibleFrames.value!;
      expect(june.mode, DashboardVisibleMode.preview);
      expect(june.queryKey.value, contains('month:2025-06'));
      expect(june.logBox.entryCount, 149);
      expect(june.logBox.flatItems, hasLength(24));

      final scrollView = find.byKey(
        const ValueKey('dashboard-logbox-scroll-view'),
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      await tester.drag(scrollView, const Offset(0, -600));
      await tester.pump();

      expect(core.visibleFrames.value?.mode, DashboardVisibleMode.committed);
      expect(core.committedLogViewport.queryKey, june.queryKey);
      expect(core.committedLogViewport.isVerticalRenderingActive, isTrue);
      expect(core.motion.state.activity.name, 'idle');
      expect(position.pixels, greaterThan(position.minScrollExtent));
      expect(
        core.performanceCounters.value(
          DashboardPerformanceMetric.freshVerticalGestureRejected,
        ),
        0,
      );
      expect(
        FluviDiagnosticLogger.entries
            .where(
              (event) => event.stage == 'VERTICAL_PREVIEW_TAKEOVER_COMMITTED',
            )
            .length,
        1,
      );
      expect(
        interactionEvents
            .where(
              (event) => event.event == DashboardInteractionEvent.motionSettled,
            )
            .toList(),
        isEmpty,
        reason: 'vertical takeover must not manufacture a rail settle',
      );
      expect(
        interactionEvents
            .where(
              (event) =>
                  event.event ==
                  DashboardInteractionEvent.settleMetadataCommitted,
            )
            .toList(),
        isEmpty,
        reason: 'takeover has its own metadata-only reason, not settle work',
      );
    },
  );
}

int _dense2025EntryCount(CurrentLedgerQueryScope scope) {
  if (scope.direction != LedgerDirection.expense) return 0;
  return switch (scope.timeScope) {
    MonthScope(:final value) when value.year == 2025 => switch (value.month) {
      6 => 149,
      5 => 5,
      4 => 0,
      12 => 3,
      1 => 2,
      _ => 0,
    },
    DayScope(:final date) when date.year == 2025 && date.month == 7 =>
      switch (date.day) {
        22 => 8,
        25 => 0,
        19 => 4,
        _ => 0,
      },
    _ => 0,
  };
}

int _dense2025PreviewRowCount(CurrentLedgerQueryScope scope) {
  final count = _dense2025EntryCount(scope);
  return count < 24 ? count : 24;
}
