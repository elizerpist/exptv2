import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_rail_flight_recorder.dart';
import 'package:fluvi/features/dashboard/application/dashboard_performance_counters.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_motion_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_motion_diagnostics.dart';

void main() {
  test('disabled recorder does not read the clock or retain events', () {
    var clockReads = 0;
    final recorder = DashboardRailFlightRecorder(
      enabled: false,
      capacity: 8,
      clockMicros: () {
        clockReads += 1;
        return clockReads;
      },
    );
    addTearDown(recorder.dispose);

    recorder.record(_gestureStart(gestureId: 1));

    expect(recorder.snapshot(), isEmpty);
    expect(clockReads, 0);
  });

  test('aggregates pointer samples and keeps a bounded typed event ring', () {
    var now = 1000;
    final recorder = DashboardRailFlightRecorder(
      enabled: true,
      capacity: 12,
      collectFrameTimings: false,
      clockMicros: () => now += 10,
    );
    addTearDown(recorder.dispose);
    recorder.bindContextProvider(_context);
    final counters = DashboardPerformanceCounters();
    recorder.bindPerformanceCounters(counters);

    recorder.record(_gestureStart(gestureId: 7));
    counters.increment(DashboardPerformanceMetric.logBoxBuild);
    counters
      ..increment(DashboardPerformanceMetric.railLayoutMicros, by: 41)
      ..increment(DashboardPerformanceMetric.logLayoutMicros, by: 43)
      ..increment(DashboardPerformanceMetric.railPaintMicros, by: 47)
      ..increment(DashboardPerformanceMetric.logPaintMicros, by: 53);
    recorder.record(
      const CenteredCarouselGestureSample(
        gestureId: 7,
        timestampMicros: 1100,
        eventTimestampMicros: 10_000,
        pointerX: 270,
        pointerY: 24,
      ),
    );
    recorder.record(
      const CenteredCarouselGestureSample(
        gestureId: 7,
        timestampMicros: 1200,
        eventTimestampMicros: 20_000,
        pointerX: 200,
        pointerY: 24,
      ),
    );
    recorder.record(
      const CenteredCarouselGestureSample(
        gestureId: 7,
        timestampMicros: 1300,
        eventTimestampMicros: 30_000,
        pointerX: 120,
        pointerY: 24,
      ),
    );
    recorder.record(
      CenteredCarouselGestureReleased(
        gestureId: 7,
        timestampMicros: 1400,
        eventTimestampMicros: 40_000,
        dragEndVelocityX: -2200,
        dragEndVelocityY: 0,
        primaryVelocity: -2200,
        startPixels: 100,
        releasePixels: 380,
        semanticStartIndex: 14,
        semanticReleaseIndex: 18,
        identities: _identities,
        geometry: _geometry(pixels: 380),
      ),
    );
    recorder.record(
      CenteredCarouselBallisticStarted(
        gestureId: 7,
        timestampMicros: 1500,
        inputVelocity: -2200,
        simulationKind: CenteredCarouselSimulationKind.scrollSpring,
        simulationStartPosition: 380,
        targetPixels: 660,
        targetRawIndex: 22,
        identities: _identities,
        geometry: _geometry(pixels: 380),
        activityIdentity: 41,
      ),
    );
    recorder.record(
      CenteredCarouselSettled(
        gestureId: 7,
        timestampMicros: 3000,
        inputVelocity: -2200,
        startPixels: 100,
        finalPixels: 660,
        startLogicalIndex: 14,
        finalLogicalIndex: 22,
        elapsedMicros: 2000,
        crossedChildCount: 8,
        activityInterruptCount: 0,
        metricChangeCount: 0,
        identities: _identities,
        geometry: _geometry(pixels: 660),
      ),
    );

    final events = recorder.snapshot();
    expect(events.length, lessThanOrEqualTo(12));
    expect(recorder.overwrittenEventCount, greaterThanOrEqualTo(0));
    final summary = events.singleWhere(
      (event) =>
          event.type == DashboardRailFlightEventType.gestureSampleSummary,
    );
    expect(summary.gestureId, 7);
    expect(summary.sampleCount, 3);
    expect(summary.totalPointerDistance, 220);
    expect(summary.longestPointerEventGapMicros, 10_000);
    expect(summary.lastThreeSampleVelocities.length, 3);
    final start = events.singleWhere(
      (event) => event.type == DashboardRailFlightEventType.gestureStart,
    );
    expect(start.pointerX, 340);
    expect(start.pointerY, 24);

    final ballistic = events.singleWhere(
      (event) => event.type == DashboardRailFlightEventType.ballisticStarted,
    );
    expect(ballistic.ballisticInputVelocity, -2200);
    expect(ballistic.queryKey, const LedgerQueryKey('income|month:2026-07'));
    expect(ballistic.entryCount, 94);
    expect(ballistic.preparedPreviewRowCount, 9);

    final settle = events.singleWhere(
      (event) => event.type == DashboardRailFlightEventType.railSettled,
    );
    expect(settle.finalLogicalIndex, 22);
    expect(settle.activityInterruptCount, 0);
    expect(settle.metricChangeCount, 0);
    expect(settle.dataIoCount, 0);
    expect(settle.toReportMap()['event'], 'RAIL_SETTLED');
    expect(
      (settle.toReportMap()['identities']! as Map)['physics'],
      _identities.physicsIdentity,
    );
    final frameTiming = events.singleWhere(
      (event) => event.type == DashboardRailFlightEventType.frameTiming,
    );
    expect(frameTiming.layoutDurationMicros, 84);
    expect(frameTiming.paintDurationMicros, 100);
    expect(frameTiming.buildDurationMicros, 0);
    expect(frameTiming.rasterDurationMicros, 0);
  });
}

const _identities = CenteredCarouselMotionIdentity(
  controllerIdentity: 11,
  positionIdentity: 12,
  physicsIdentity: 13,
  viewportIdentity: 14,
);

CenteredCarouselScrollGeometry _geometry({required double pixels}) =>
    CenteredCarouselScrollGeometry(
      pixels: pixels,
      minScrollExtent: 0,
      maxScrollExtent: 1000,
      viewportDimension: 360,
      itemExtent: 56,
      devicePixelRatio: 2.75,
    );

CenteredCarouselGestureStarted _gestureStart({required int gestureId}) =>
    CenteredCarouselGestureStarted(
      gestureId: gestureId,
      timestampMicros: 1000,
      eventTimestampMicros: 0,
      startPixels: 100,
      startLogicalIndex: 14,
      pointerX: 340,
      pointerY: 24,
      identities: _identities,
      geometry: _geometry(pixels: 100),
    );

DashboardRailFlightContext _context() => const DashboardRailFlightContext(
  motionEpoch: 4,
  navigationEpoch: 5,
  presentationEpoch: 6,
  queryKey: LedgerQueryKey('income|month:2026-07'),
  parentQueryKey: LedgerQueryKey('income|year:2026'),
  direction: LedgerDirection.income,
  childKind: DashboardChildKind.day,
  plane: TimePlane.month,
  semanticIndex: 14,
  coreRevision: 1,
  presentationGeneration: 8,
  presentationMode: DashboardVisibleMode.preview,
  dataOrigin: DashboardDataOrigin.preparedIndex,
  hasData: true,
  entryCount: 94,
  preparedPreviewRowCount: 9,
  frameDigest: 99,
  displayFrameNumber: 12,
  motionState: DashboardMotionActivity.drag,
);
