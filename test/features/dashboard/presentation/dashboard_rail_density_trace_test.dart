import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_core_mode_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_flight_recorder.dart';
import 'package:fluvi/features/dashboard/presentation/core_dashboard.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

import '../runtime/dashboard_runtime_test_fixtures.dart';
import '../../../support/dashboard_render_resources.dart';
import '../../../support/test_category_collection.dart';

void main() {
  setUpAll(prepareDashboardTestRenderResources);

  testWidgets(
    'month-day scripted matrix isolates density amount and mixed children',
    (tester) async {
      await _withRailTraceOnly(() async {
        final subject = await _TraceSubject.create(tester);
        addTearDown(subject.dispose);

        final empty = await subject.runThirty(
          tester,
          index: _monthDayIndex(generation: 1, previewRows: 0),
          startLogicalIndex: 14,
        );
        final twoRows = await subject.runThirty(
          tester,
          index: _monthDayIndex(generation: 2, previewRows: 2),
          startLogicalIndex: 14,
        );
        final fourRows = await subject.runThirty(
          tester,
          index: _monthDayIndex(
            generation: 21,
            previewRows: 4,
            previewGroupCount: 2,
          ),
          startLogicalIndex: 14,
        );
        final nineRows = await subject.runThirty(
          tester,
          index: _monthDayIndex(
            generation: 3,
            previewRows: 9,
            previewGroupCount: 3,
          ),
          startLogicalIndex: 14,
        );
        final largeAmountFewRows = await subject.runThirty(
          tester,
          index: _monthDayIndex(
            generation: 4,
            previewRows: 2,
            amountMultiplier: 1,
          ),
          startLogicalIndex: 14,
        );
        final mixed = await subject.runThirty(
          tester,
          index: _monthDayIndex(
            generation: 5,
            previewRows: 9,
            previewGroupCount: 3,
            mixed: true,
          ),
          startLogicalIndex: 14,
        );

        _printTraceSummary(
          'month_day_0_vs_2',
          empty: empty,
          populated: twoRows,
        );
        _printTraceSummary(
          'month_day_0_vs_9_bounded',
          empty: empty,
          populated: nineRows,
        );
        _printTraceSummary(
          'month_day_2_vs_large_amount_2',
          empty: twoRows,
          populated: largeAmountFewRows,
        );
        _printTraceSummary(
          'month_day_mixed_vs_populated',
          empty: mixed,
          populated: nineRows,
        );
        _expectMotionParity(empty, twoRows);
        _expectMotionParity(empty, fourRows);
        _expectMotionParity(empty, nineRows);
        _expectMotionParity(twoRows, largeAmountFewRows);
        _expectMotionParity(mixed, nineRows);
        _expectFirstWarmParity(empty);
        _expectFirstWarmParity(twoRows);
        _expectFirstWarmParity(fourRows);
        _expectFirstWarmParity(nineRows);
        expect(
          empty.every((trace) => trace.logVisibleSlotPaintCount == 0),
          isTrue,
        );
        expect(
          twoRows.every((trace) => trace.logVisibleSlotPaintCount > 0),
          isTrue,
          reason: 'Populated content must remain visible during motion.',
        );
        expect(
          nineRows.every((trace) => trace.logVisibleSlotPaintCount > 0),
          isTrue,
          reason: 'Bounded prepared rows must remain visible during motion.',
        );
        expect(
          mixed.every((trace) => trace.populatedChildCrossCount > 0),
          isTrue,
        );
        expect(mixed.every((trace) => trace.emptyChildCrossCount > 0), isTrue);
      });
    },
  );

  testWidgets(
    'year-month scripted matrix isolates density mixed children and direction',
    (tester) async {
      await _withRailTraceOnly(() async {
        final subject = await _TraceSubject.create(tester, yearPlane: true);
        addTearDown(subject.dispose);

        final empty = await subject.runThirty(
          tester,
          index: _yearMonthIndex(generation: 11, previewRows: 0),
          startLogicalIndex: 6,
        );
        final populated = await subject.runThirty(
          tester,
          index: _yearMonthIndex(generation: 12, previewRows: 24),
          startLogicalIndex: 6,
        );
        final sparse = await subject.runThirty(
          tester,
          index: _yearMonthIndex(
            generation: 15,
            previewRows: 2,
            totalMonthEntries: 2,
            totalYearEntries: 24,
          ),
          startLogicalIndex: 6,
        );
        final denseStress = await subject.runThirty(
          tester,
          index: _yearMonthIndex(
            generation: 16,
            previewRows: 24,
            totalMonthEntries: 100000,
            totalYearEntries: 1200000,
          ),
          startLogicalIndex: 6,
        );
        final mixed = await subject.runThirty(
          tester,
          index: _yearMonthIndex(generation: 13, previewRows: 24, mixed: true),
          startLogicalIndex: 6,
        );
        final populatedReverse = await subject.runThirty(
          tester,
          index: _yearMonthIndex(generation: 14, previewRows: 24),
          startLogicalIndex: 6,
          dragOffset: const Offset(280, 0),
        );

        _printTraceSummary(
          'year_month_0_vs_94_parent_658',
          empty: empty,
          populated: populated,
        );
        _printTraceSummary(
          'year_month_mixed_vs_populated',
          empty: mixed,
          populated: populated,
        );
        _printTraceSummary(
          'year_month_empty_vs_sparse_2',
          empty: empty,
          populated: sparse,
        );
        _printTraceSummary(
          'year_month_94_vs_dense_100000_bounded_24',
          empty: populated,
          populated: denseStress,
        );
        _printTraceSummary(
          'year_month_forward_vs_reverse',
          empty: populated,
          populated: populatedReverse,
        );
        _expectMotionParity(empty, populated);
        _expectMotionParity(empty, sparse);
        _expectMotionParity(populated, denseStress);
        _expectMotionParity(mixed, populated);
        _expectMotionParity(
          populated,
          populatedReverse,
          compareAbsoluteDirection: true,
        );
        _expectFirstWarmParity(empty);
        _expectFirstWarmParity(populated);
        _expectFirstWarmParity(sparse);
        _expectFirstWarmParity(denseStress);
        _expectFirstWarmParity(mixed);
        expect(
          empty.every((trace) => trace.logVisibleSlotPaintCount == 0),
          isTrue,
        );
        expect(
          populated.every((trace) => trace.logVisibleSlotPaintCount > 0),
          isTrue,
          reason: 'Populated content must remain visible during motion.',
        );
        expect(
          mixed.every((trace) => trace.populatedChildCrossCount > 0),
          isTrue,
        );
        expect(mixed.every((trace) => trace.emptyChildCrossCount > 0), isTrue);
      });
    },
  );

  testWidgets(
    'opening the rail during a pending plane transition targets the final plane',
    (tester) async {
      final subject = await _TraceSubject.create(tester, yearPlane: true);
      addTearDown(subject.dispose);

      expect(
        subject.controller.navigation.state.plane,
        TimePlane.year,
        reason:
            'The explicit rail-open intent must reconcile with the pending '
            'structural target rather than superseding it from the old MONTH '
            'state.',
      );
      expect(subject.controller.navigation.state.isRailOpen, isTrue);
    },
  );

  testWidgets(
    'the first YEAR rail fling after a pending plane open paints populated siblings',
    (tester) async {
      final subject = await _TraceSubject.create(tester, yearPlane: true);
      addTearDown(subject.dispose);

      final traces = await subject.runThirty(
        tester,
        index: _yearMonthIndex(generation: 99, previewRows: 24),
        startLogicalIndex: 6,
        repetitions: 1,
      );

      expect(
        traces.single.logVisibleSlotPaintCount,
        greaterThan(0),
        reason:
            'The first rail fling must paint the final YEAR plane’s prepared '
            'siblings. A stale MONTH open candidate leaves the rail geometry '
            'interactive but its populated LogBoxes blank.',
      );
    },
  );
}

Future<void> _withRailTraceOnly(Future<void> Function() body) async {
  final originalDebugPrint = debugPrint;
  debugPrint = (message, {wrapWidth}) {
    if (message?.startsWith('RAIL_TRACE ') ?? false) {
      originalDebugPrint(message, wrapWidth: wrapWidth);
    }
  };
  try {
    await body();
  } finally {
    debugPrint = originalDebugPrint;
  }
}

void _printTraceSummary(
  String scenario, {
  required List<_GestureTrace> empty,
  required List<_GestureTrace> populated,
}) {
  int percentile(List<int> values, double fraction) {
    final sorted = List<int>.of(values)..sort();
    return sorted[((sorted.length - 1) * fraction).ceil()];
  }

  Map<String, Object> side(List<_GestureTrace> traces) {
    final apply = traces.map((trace) => trace.presentationApplyMicros).toList();
    final logBind = traces.map((trace) => trace.logViewportBindMicros).toList();
    return <String, Object>{
      'repetitions': traces.length,
      'drag_end_velocity': traces.first.dragEndVelocity,
      'ballistic_input_velocity': traces.first.ballisticInputVelocity,
      'logical_delta': traces.first.logicalDelta,
      'pixel_distance': traces.first.totalPixelDistance,
      'apply_p50_micros': percentile(apply, .50),
      'apply_p95_micros': percentile(apply, .95),
      'apply_p99_micros': percentile(apply, .99),
      'first_apply_micros': traces.first.presentationApplyMicros,
      'tenth_apply_micros': traces[9].presentationApplyMicros,
      'selector_p95_micros': percentile(
        traces.map((trace) => trace.selectorMicros).toList(),
        .95,
      ),
      'equality_p95_micros': percentile(
        traces.map((trace) => trace.equalityMicros).toList(),
        .95,
      ),
      'notifier_p95_micros': percentile(
        traces.map((trace) => trace.notifierMicros).toList(),
        .95,
      ),
      'log_bind_p95_micros': percentile(logBind, .95),
      'visible_slot_paint_p95': percentile(
        traces.map((trace) => trace.logVisibleSlotPaintCount).toList(),
        .95,
      ),
      'activity_interrupt_count': traces.fold<int>(
        0,
        (sum, trace) => sum + trace.activityInterruptCount,
      ),
      'metric_change_count': traces.fold<int>(
        0,
        (sum, trace) => sum + trace.metricChangeCount,
      ),
    };
  }

  debugPrint(
    'RAIL_TRACE ${jsonEncode(<String, Object>{'scenario': scenario, 'left': side(empty), 'right': side(populated)})}',
  );
}

final class _TraceSubject {
  _TraceSubject(this.controller, this.recorder, this.modeController);

  final DashboardCoreController controller;
  final DashboardRailFlightRecorder recorder;
  final DashboardCoreModeController modeController;

  static Future<_TraceSubject> create(
    WidgetTester tester, {
    bool yearPlane = false,
  }) async {
    final recorder = DashboardRailFlightRecorder(enabled: true, capacity: 256);
    final controller = DashboardCoreController(
      initialDate: DateTime(2026, 7, 14),
      initialCoreRevision: 1,
      railFlightRecorder: recorder,
    );
    final modeController = DashboardCoreModeController(
      initialMode: DashboardModeSpec.balance,
    );
    await controller.bootstrap();
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: CoreDashboard(
            controller: controller,
            modeController: modeController,
            categoryCollection: emptyTestCategoryCollection,
          ),
        ),
      ),
    );
    if (yearPlane) controller.navigatePlane(finer: false);
    controller.setRailOpen(true);
    await tester.pumpAndSettle();
    return _TraceSubject(controller, recorder, modeController);
  }

  Future<List<_GestureTrace>> runThirty(
    WidgetTester tester, {
    required PreparedDashboardIndex index,
    required int startLogicalIndex,
    Offset dragOffset = const Offset(-280, 0),
    int repetitions = 30,
  }) async {
    // Production scene preparation yields to post-frame work so it cannot
    // share an input frame. Drive those frames before awaiting its completion;
    // awaiting first would deadlock a widget test's fake frame clock.
    final install = controller.installPreparedIndex(index);
    await tester.pumpAndSettle();
    await install;
    final result = <_GestureTrace>[];
    for (var repetition = 0; repetition < repetitions; repetition += 1) {
      controller.motion.carouselController.jumpToIndexSilently(
        startLogicalIndex,
      );
      await tester.pumpAndSettle();
      recorder.clear();
      controller.performanceCounters.reset();

      await tester.fling(
        find.byKey(const ValueKey('centered-carousel-viewport')),
        dragOffset,
        2200,
      );
      await tester.pumpAndSettle();

      final events = recorder.snapshot();
      final release = events.singleWhere(
        (event) => event.type == DashboardRailFlightEventType.gestureReleased,
      );
      final ballistic = events.singleWhere(
        (event) => event.type == DashboardRailFlightEventType.ballisticStarted,
      );
      final settle = events.singleWhere(
        (event) => event.type == DashboardRailFlightEventType.railSettled,
      );
      final applyEvents = events.where(
        (event) =>
            event.type ==
            DashboardRailFlightEventType.presentationApplyCompleted,
      );
      if (controller.navigation.state.plane == TimePlane.year) {
        expect(
          events.where(
            (event) =>
                event.type ==
                DashboardRailFlightEventType.yearMonthFrameSelected,
          ),
          isNotEmpty,
        );
        expect(
          events.where(
            (event) =>
                event.type ==
                DashboardRailFlightEventType.yearMonthFrameApplied,
          ),
          isNotEmpty,
        );
      }
      result.add(
        _GestureTrace(
          dragEndVelocity: release.dragEndVelocity,
          ballisticInputVelocity: ballistic.ballisticInputVelocity,
          startPixels: settle.startPixels,
          finalPixels: settle.finalPixels,
          startLogicalIndex: settle.startLogicalIndex,
          finalLogicalIndex: settle.finalLogicalIndex,
          activityInterruptCount: settle.activityInterruptCount,
          metricChangeCount: settle.metricChangeCount,
          populatedChildCrossCount: settle.populatedChildCrossCount,
          emptyChildCrossCount: settle.emptyChildCrossCount,
          controllerIdentity: settle.identities!.controllerIdentity,
          positionIdentity: settle.identities!.positionIdentity,
          physicsIdentity: settle.identities!.physicsIdentity,
          logVisibleSlotPaintCount: controller.performanceCounters.value(
            DashboardPerformanceMetric.logVisibleSlotPaint,
          ),
          presentationApplyMicros: applyEvents.fold(
            0,
            (sum, event) => sum + event.applyMicros,
          ),
          selectorMicros: applyEvents.fold(
            0,
            (sum, event) => sum + event.selectorMicros,
          ),
          equalityMicros: applyEvents.fold(
            0,
            (sum, event) => sum + event.equalityMicros,
          ),
          notifierMicros: applyEvents.fold(
            0,
            (sum, event) => sum + event.notifierMicros,
          ),
          logViewportBindMicros: applyEvents.fold(
            0,
            (sum, event) => sum + event.logViewportBindMicros,
          ),
          counterSnapshot: controller.performanceCounters.snapshotValues(),
        ),
      );
    }
    return List<_GestureTrace>.unmodifiable(result);
  }

  void dispose() {
    modeController.dispose();
    controller.dispose();
  }
}

void _expectMotionParity(
  List<_GestureTrace> empty,
  List<_GestureTrace> populated, {
  bool compareAbsoluteDirection = false,
}) {
  expect(empty, hasLength(30));
  expect(populated, hasLength(30));
  for (var index = 0; index < 30; index += 1) {
    final left = empty[index];
    final right = populated[index];
    final leftDragVelocity = compareAbsoluteDirection
        ? left.dragEndVelocity.abs()
        : left.dragEndVelocity;
    final rightDragVelocity = compareAbsoluteDirection
        ? right.dragEndVelocity.abs()
        : right.dragEndVelocity;
    final leftBallisticVelocity = compareAbsoluteDirection
        ? left.ballisticInputVelocity.abs()
        : left.ballisticInputVelocity;
    final rightBallisticVelocity = compareAbsoluteDirection
        ? right.ballisticInputVelocity.abs()
        : right.ballisticInputVelocity;
    final leftPixelDistance = compareAbsoluteDirection
        ? left.totalPixelDistance.abs()
        : left.totalPixelDistance;
    final rightPixelDistance = compareAbsoluteDirection
        ? right.totalPixelDistance.abs()
        : right.totalPixelDistance;
    final leftLogicalDelta = compareAbsoluteDirection
        ? left.logicalDelta.abs()
        : left.logicalDelta;
    final rightLogicalDelta = compareAbsoluteDirection
        ? right.logicalDelta.abs()
        : right.logicalDelta;
    expect(
      _relativeDifference(leftDragVelocity, rightDragVelocity),
      lessThanOrEqualTo(.02),
    );
    expect(
      _relativeDifference(leftBallisticVelocity, rightBallisticVelocity),
      lessThanOrEqualTo(.02),
    );
    expect(
      (leftPixelDistance - rightPixelDistance).abs(),
      lessThanOrEqualTo(26.5),
      reason: 'repetition=$index',
    );
    expect(
      (leftLogicalDelta - rightLogicalDelta).abs(),
      lessThanOrEqualTo(1),
      reason: 'repetition=$index',
    );
    expect(left.activityInterruptCount, 0);
    expect(right.activityInterruptCount, 0);
    expect(left.metricChangeCount, 0);
    expect(right.metricChangeCount, 0);
    expect(left.controllerIdentity, right.controllerIdentity);
    expect(left.positionIdentity, right.positionIdentity);
    expect(left.physicsIdentity, right.physicsIdentity);
    for (final trace in <_GestureTrace>[left, right]) {
      expect(trace.counter(DashboardPerformanceMetric.dashboardRootBuild), 0);
      expect(trace.counter(DashboardPerformanceMetric.summaryPillBuild), 0);
      expect(trace.counter(DashboardPerformanceMetric.railSubtreeBuild), 0);
      expect(trace.counter(DashboardPerformanceMetric.logViewportBuild), 0);
      expect(trace.counter(DashboardPerformanceMetric.svgPulseSubtreeBuild), 0);
      expect(trace.counter(DashboardPerformanceMetric.controllerRecreation), 0);
      expect(trace.counter(DashboardPerformanceMetric.physicsRecreation), 0);
      expect(
        trace.counter(DashboardPerformanceMetric.scrollPositionRecreation),
        0,
      );
      for (final metric in <DashboardPerformanceMetric>[
        DashboardPerformanceMetric.sqlCallsDuringMotion,
        DashboardPerformanceMetric.platformCallsDuringMotion,
        DashboardPerformanceMetric.repositoryReadsDuringMotion,
        DashboardPerformanceMetric.liveLeaseStartsDuringMotion,
        DashboardPerformanceMetric.logBoxProjectionsDuringMotion,
        DashboardPerformanceMetric.formattingDuringMotion,
        DashboardPerformanceMetric.railPresentationDataDependencyViolation,
      ]) {
        expect(trace.counter(metric), 0);
      }
    }
  }
  expect(empty.first.logicalDelta, empty[9].logicalDelta);
  expect(populated.first.logicalDelta, populated[9].logicalDelta);
}

void _expectFirstWarmParity(List<_GestureTrace> traces) {
  final first = traces.first;
  final tenth = traces[9];
  expect(_relativeDifference(first.dragEndVelocity, tenth.dragEndVelocity), 0);
  expect(
    _relativeDifference(
      first.ballisticInputVelocity,
      tenth.ballisticInputVelocity,
    ),
    0,
  );
  expect(first.logicalDelta, tenth.logicalDelta);
  expect(first.totalPixelDistance, tenth.totalPixelDistance);
  expect(first.activityInterruptCount + tenth.activityInterruptCount, 0);
  expect(first.metricChangeCount + tenth.metricChangeCount, 0);
  expect(first.controllerIdentity, tenth.controllerIdentity);
  expect(first.positionIdentity, tenth.positionIdentity);
  expect(first.physicsIdentity, tenth.physicsIdentity);
  expect(first.logVisibleSlotPaintCount, tenth.logVisibleSlotPaintCount);
}

double _relativeDifference(double left, double right) {
  final denominator = math.max(left.abs(), right.abs());
  return denominator == 0 ? 0 : (left - right).abs() / denominator;
}

PreparedDashboardIndex _monthDayIndex({
  required int generation,
  required int previewRows,
  int previewGroupCount = 1,
  int amountMultiplier = 0,
  bool mixed = false,
}) => buildRuntimeTestIndex(
  revision: 1,
  generation: generation,
  amountMultiplier: amountMultiplier,
  entryCountForScope: (scope) => switch (scope.timeScope) {
    DayScope(:final date) when date.year == 2026 && date.month == 7 =>
      mixed && date.day.isOdd ? 0 : previewRows,
    MonthScope(:final value) when value.year == 2026 && value.month == 7 =>
      previewRows == 0 ? 0 : 94,
    _ => 0,
  },
  previewRowCountForScope: (scope) => switch (scope.timeScope) {
    DayScope(:final date) when date.year == 2026 && date.month == 7 =>
      mixed && date.day.isOdd ? 0 : previewRows,
    _ => 0,
  },
  previewGroupCountForScope: (scope) => switch (scope.timeScope) {
    DayScope(:final date)
        when date.year == 2026 &&
            date.month == 7 &&
            !(mixed && date.day.isOdd) =>
      previewRows == 0 ? 1 : previewGroupCount,
    _ => 0,
  },
);

PreparedDashboardIndex _yearMonthIndex({
  required int generation,
  required int previewRows,
  int totalMonthEntries = 94,
  int totalYearEntries = 658,
  bool mixed = false,
}) => buildRuntimeTestIndex(
  revision: 1,
  generation: generation,
  amountMultiplier: 0,
  entryCountForScope: (scope) => switch (scope.timeScope) {
    MonthScope(:final value) when value.year == 2026 =>
      previewRows == 0 || (mixed && value.month.isOdd) ? 0 : totalMonthEntries,
    YearScope(:final year) when year == 2026 =>
      previewRows == 0 ? 0 : totalYearEntries,
    _ => 0,
  },
  previewRowCountForScope: (scope) => switch (scope.timeScope) {
    MonthScope(:final value) when value.year == 2026 =>
      mixed && value.month.isOdd ? 0 : previewRows,
    _ => 0,
  },
  previewGroupCountForScope: (scope) => switch (scope.timeScope) {
    MonthScope(:final value)
        when value.year == 2026 && !(mixed && value.month.isOdd) =>
      math.max(1, previewRows),
    _ => 1,
  },
);

final class _GestureTrace {
  const _GestureTrace({
    required this.dragEndVelocity,
    required this.ballisticInputVelocity,
    required this.startPixels,
    required this.finalPixels,
    required this.startLogicalIndex,
    required this.finalLogicalIndex,
    required this.activityInterruptCount,
    required this.metricChangeCount,
    required this.populatedChildCrossCount,
    required this.emptyChildCrossCount,
    required this.controllerIdentity,
    required this.positionIdentity,
    required this.physicsIdentity,
    required this.logVisibleSlotPaintCount,
    required this.presentationApplyMicros,
    required this.selectorMicros,
    required this.equalityMicros,
    required this.notifierMicros,
    required this.logViewportBindMicros,
    required this.counterSnapshot,
  });

  final double dragEndVelocity;
  final double ballisticInputVelocity;
  final double startPixels;
  final double finalPixels;
  final int startLogicalIndex;
  final int finalLogicalIndex;
  final int activityInterruptCount;
  final int metricChangeCount;
  final int populatedChildCrossCount;
  final int emptyChildCrossCount;
  final int controllerIdentity;
  final int positionIdentity;
  final int physicsIdentity;
  final int logVisibleSlotPaintCount;
  final int presentationApplyMicros;
  final int selectorMicros;
  final int equalityMicros;
  final int notifierMicros;
  final int logViewportBindMicros;
  final List<int> counterSnapshot;

  double get totalPixelDistance => finalPixels - startPixels;
  int get logicalDelta => finalLogicalIndex - startLogicalIndex;
  int counter(DashboardPerformanceMetric metric) =>
      counterSnapshot[metric.index];
}
