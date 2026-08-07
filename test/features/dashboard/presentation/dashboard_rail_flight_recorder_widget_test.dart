import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_flight_recorder.dart';
import 'package:fluvi/features/dashboard/application/dashboard_render_readiness_diagnostics.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';
import '../../../support/dashboard_render_resources.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'one dashboard fling records crossing, apply, activity and settle evidence',
    (tester) async {
      final recorder = DashboardRailFlightRecorder(
        enabled: true,
        capacity: 256,
      );
      final renderDiagnostics = DashboardRenderReadinessDiagnostics(
        enabled: true,
      );
      final controller = DashboardCoreController(
        initialDate: DateTime(2026, 7, 14),
        initialCoreRevision: 1,
        railFlightRecorder: recorder,
        renderReadinessDiagnostics: renderDiagnostics,
      );
      addTearDown(controller.dispose);
      await controller.bootstrap();
      controller.presentation.installIndex(
        buildRuntimeTestIndex(
          revision: 1,
          amountMultiplier: 0,
          entryCountOverride: 94,
        ),
        publishImmediately: true,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: CoreDashboard(
            mode: DashboardModeSpec.balance,
            controller: controller,
          ),
        ),
      );
      controller.setRailOpen(true);
      await tester.pumpAndSettle();
      recorder.clear();
      controller.performanceCounters.reset();

      await tester.fling(
        find.byKey(const ValueKey('centered-carousel-viewport')),
        const Offset(-280, 0),
        2200,
      );
      await tester.pumpAndSettle();

      final events = recorder.snapshot();
      expect(
        events.where(
          (event) => event.type == DashboardRailFlightEventType.gestureStart,
        ),
        hasLength(1),
      );
      expect(
        events.where(
          (event) => event.type == DashboardRailFlightEventType.gestureReleased,
        ),
        hasLength(1),
      );
      expect(
        events.where(
          (event) =>
              event.type == DashboardRailFlightEventType.ballisticStarted,
        ),
        hasLength(1),
      );
      expect(
        events.where(
          (event) =>
              event.type == DashboardRailFlightEventType.semanticChildCrossed,
        ),
        isNotEmpty,
      );
      expect(
        events.where(
          (event) =>
              event.type ==
              DashboardRailFlightEventType.presentationApplyStarted,
        ),
        isNotEmpty,
      );
      final completed = events.where(
        (event) =>
            event.type ==
            DashboardRailFlightEventType.presentationApplyCompleted,
      );
      expect(completed, isNotEmpty);
      expect(completed.every((event) => event.selectorMicros >= 0), isTrue);
      expect(completed.every((event) => event.equalityMicros >= 0), isTrue);
      expect(completed.every((event) => event.notifierMicros >= 0), isTrue);
      expect(
        completed.every((event) => !event.rootDashboardRebuildScheduled),
        isTrue,
      );
      expect(completed.every((event) => !event.railRebuildScheduled), isTrue);

      final settle = events.singleWhere(
        (event) => event.type == DashboardRailFlightEventType.railSettled,
      );
      expect(settle.entryCount, 94);
      expect(settle.activityInterruptCount, 0);
      expect(settle.metricChangeCount, 0);
      expect(settle.populatedChildCrossCount, greaterThan(0));
      expect(settle.emptyChildCrossCount, 0);
      expect(settle.dataIoCount, 0);
      expect(settle.platformCallCount, 0);
      expect(settle.sqlCount, 0);
      expect(settle.rootRebuildCount, 0);
      expect(settle.railRebuildCount, 0);
      expect(settle.logViewportRebuildCount, 0);
      expect(settle.presentationApplyTotalMicros, greaterThanOrEqualTo(0));
      expect(settle.identities?.controllerIdentity, isNonZero);
      expect(settle.identities?.positionIdentity, isNonZero);
      expect(settle.identities?.physicsIdentity, isNonZero);
      expect(
        events.where(
          (event) => event.type == DashboardRailFlightEventType.frameTiming,
        ),
        hasLength(1),
      );
      final realGesture = renderDiagnostics.snapshot().singleWhere(
        (event) =>
            event.type == DashboardRenderReadinessEventType.realGestureSummary,
      );
      expect(realGesture.gestureId, greaterThan(0));
      expect(realGesture.sampleCount, greaterThan(0));
      expect(realGesture.dragEndVelocity.abs(), greaterThan(0));
      expect(realGesture.ballisticInputVelocity.abs(), greaterThan(0));
      expect(realGesture.finalIndex - realGesture.startIndex, isNot(0));
      final report = controller.exportPhysicalRailReport();
      expect(report['firstTenFlings'], hasLength(1));
      final timeline =
          (report['firstTenFlings']! as List<Object?>).single
              as Map<String, Object?>;
      expect(timeline['motionTimeline'], isNotEmpty);
      expect(timeline['logBoxTimeline'], isNotEmpty);
    },
  );
}
