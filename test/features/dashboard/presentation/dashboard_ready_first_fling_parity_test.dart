import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_flight_recorder.dart';
import 'package:fluvi/features/dashboard/application/dashboard_render_readiness_diagnostics.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../../../support/dashboard_render_resources.dart';
import '../runtime/dashboard_runtime_test_fixtures.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  for (final plane in <TimePlane>[TimePlane.month, TimePlane.year]) {
    testWidgets(
      '${plane.name} first READY fling and tenth fling share one prepared render path',
      (tester) async {
        final recorder = DashboardRailFlightRecorder(
          enabled: true,
          capacity: 2048,
        );
        final renderDiagnostics = DashboardRenderReadinessDiagnostics(
          enabled: true,
          capacity: 2048,
        );
        final controller = DashboardCoreController(
          initialDate: DateTime(2026, 7, 14),
          initialPlane: plane,
          initialRailOpen: true,
          initialDirection: LedgerDirection.expense,
          initialCoreRevision: 1,
          railFlightRecorder: recorder,
          renderReadinessDiagnostics: renderDiagnostics,
        );
        addTearDown(controller.dispose);
        await controller.bootstrap();
        controller.presentation.installIndex(
          _populatedIndex(plane),
          publishImmediately: true,
        );

        var ready = false;
        await tester.pumpWidget(
          MaterialApp(
            home: CoreDashboard(
              mode: DashboardModeSpec.balance,
              controller: controller,
              onLogBoxWarmupTextLayoutsPrepared: (_) {
                renderDiagnostics.markReady();
                ready = true;
              },
            ),
          ),
        );
        for (var frame = 0; frame < 160 && !ready; frame += 1) {
          await tester.pump(const Duration(milliseconds: 1));
        }
        expect(ready, isTrue);

        final firstUseBefore = _firstUseCount(renderDiagnostics);
        final textLayoutFallbacksBefore = controller.performanceCounters.value(
          DashboardPerformanceMetric.logTextLayoutFallback,
        );
        final startIndex = plane == TimePlane.month ? 13 : 6;
        final summaries = <DashboardRenderReadinessEvent>[];
        for (var repetition = 0; repetition < 10; repetition += 1) {
          if (repetition != 0) {
            controller.motion.carouselController.jumpToIndex(startIndex);
            await tester.pumpAndSettle();
            controller.settleRail(startIndex);
            await tester.pump();
          }

          await tester.fling(
            find.byKey(const ValueKey('dashboard-time-rail')),
            const Offset(-280, 0),
            2200,
          );
          await tester.pumpAndSettle();
          summaries.add(
            renderDiagnostics.snapshot().lastWhere(
              (event) =>
                  event.type ==
                  DashboardRenderReadinessEventType.realGestureSummary,
            ),
          );
        }

        final first = summaries.first;
        final tenth = summaries.last;
        expect(
          _relativeDifference(first.dragEndVelocity, tenth.dragEndVelocity),
          lessThanOrEqualTo(.02),
        );
        expect(
          _relativeDifference(
            first.ballisticInputVelocity,
            tenth.ballisticInputVelocity,
          ),
          lessThanOrEqualTo(.02),
        );
        expect(
          ((first.finalIndex - first.startIndex) -
                  (tenth.finalIndex - tenth.startIndex))
              .abs(),
          lessThanOrEqualTo(1),
        );
        expect(first.uiMissedFramesDuringGesture, 0);
        expect(tenth.uiMissedFramesDuringGesture, 0);
        expect(_firstUseCount(renderDiagnostics), firstUseBefore);
        expect(renderDiagnostics.postReadyFirstUseViolationCount, 0);
        expect(renderDiagnostics.railCriticalCacheMissCount, 0);
        expect(
          controller.performanceCounters.value(
            DashboardPerformanceMetric.logTextLayoutFallback,
          ),
          textLayoutFallbacksBefore,
          reason: 'READY rail motion must never lay out LogBox text in paint.',
        );
        expect(
          controller.performanceCounters.value(
            DashboardPerformanceMetric.controllerRecreation,
          ),
          0,
        );
        expect(
          controller.performanceCounters.value(
            DashboardPerformanceMetric.physicsRecreation,
          ),
          0,
        );
        expect(
          controller.performanceCounters.value(
            DashboardPerformanceMetric.scrollPositionRecreation,
          ),
          0,
        );
        for (final metric in const <DashboardPerformanceMetric>[
          DashboardPerformanceMetric.sqlCallsDuringMotion,
          DashboardPerformanceMetric.platformCallsDuringMotion,
          DashboardPerformanceMetric.repositoryReadsDuringMotion,
          DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
          DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
          DashboardPerformanceMetric.formattingDuringMotion,
        ]) {
          expect(controller.performanceCounters.value(metric), 0);
        }

        controller.performanceCounters.reset();
        final report = controller.exportPhysicalRailReport();
        expect(report['firstTenFlings'], hasLength(10));
        final memoryBudget = report['memoryBudget']! as Map<String, Object?>;
        expect(memoryBudget['logBoxTextLayoutEstimatedBytes'], greaterThan(0));
        final firstTimeline =
            (report['firstTenFlings']! as List<Object?>).first
                as Map<String, Object?>;
        expect(firstTimeline['motionTimeline'], isNotEmpty);
        expect(firstTimeline['logBoxTimeline'], isNotEmpty);
      },
    );
  }
}

PreparedDashboardIndex _populatedIndex(TimePlane plane) =>
    buildRuntimeTestIndex(
      revision: 1,
      generation: plane == TimePlane.month ? 31 : 32,
      entryCountForScope: (scope) => switch (scope.timeScope) {
        DayScope(:final date) when date.year == 2026 && date.month == 7 => 9,
        MonthScope(:final value) when value.year == 2026 => 94,
        YearScope(:final year) when year == 2026 => 658,
        _ => 0,
      },
      previewRowCountForScope: (scope) => switch (scope.timeScope) {
        DayScope(:final date) when date.year == 2026 && date.month == 7 => 9,
        MonthScope(:final value) when value.year == 2026 => 24,
        _ => 0,
      },
      previewGroupCountForScope: (scope) => switch (scope.timeScope) {
        DayScope(:final date) when date.year == 2026 && date.month == 7 => 3,
        MonthScope(:final value) when value.year == 2026 => 12,
        _ => 0,
      },
    );

int _firstUseCount(DashboardRenderReadinessDiagnostics diagnostics) =>
    diagnostics
        .snapshot()
        .where(
          (event) =>
              event.type ==
              DashboardRenderReadinessEventType.firstUseWorkStarted,
        )
        .length;

double _relativeDifference(double left, double right) {
  final denominator = math.max(left.abs(), right.abs());
  return denominator == 0 ? 0 : (left - right).abs() / denominator;
}
