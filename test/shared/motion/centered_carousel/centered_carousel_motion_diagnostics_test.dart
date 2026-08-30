import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

void main() {
  test('semantic cadence stays bounded and reports gaps/skips', () {
    final cadence = CenteredCarouselSemanticCadenceAccumulator(capacity: 4)
      ..reset(startedAtMicros: 1000)
      ..recordTick(1, timestampMicros: 2000)
      ..recordTick(2, timestampMicros: 12000)
      ..recordTick(4, timestampMicros: 52000)
      ..recordTick(4, timestampMicros: 57000)
      ..recordTick(5, timestampMicros: 67000);

    final snapshot = cadence.snapshot(endedAtMicros: 70000);
    expect(snapshot.tickCount, 5);
    expect(snapshot.retainedTickCount, 4);
    expect(snapshot.firstTickLatencyMicros, 11000);
    expect(snapshot.interTickMinimumMicros, 5000);
    expect(snapshot.interTickMedianMicros, 10000);
    expect(snapshot.interTickP95Micros, 40000);
    expect(snapshot.interTickMaximumMicros, 40000);
    expect(snapshot.longGapCount, 1);
    expect(snapshot.duplicateTickCount, 1);
    expect(snapshot.skippedSemanticIndexCount, 1);
  });

  testWidgets(
    'reports one raw gesture, exact ballistic handoff and stable identities',
    (tester) async {
      final controller = CenteredCarouselController(initialIndex: 14);
      final diagnostics = _RecordingMotionDiagnostics();
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox(
              width: 360,
              height: 80,
              child: CenteredCarousel<int>(
                dataSource: CyclicCarouselDataSource<int>(
                  List<int>.generate(31, (index) => index),
                ),
                controller: controller,
                spec: CenteredCarouselPresets.timeRail(itemExtent: 56),
                height: 48,
                motionDiagnostics: diagnostics,
                itemBuilder: (context, item, metrics) => Text('$item'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      diagnostics.events.clear();

      await tester.fling(
        find.byKey(const ValueKey('centered-carousel-viewport')),
        const Offset(-280, 0),
        2200,
      );
      await tester.pumpAndSettle();

      final starts = diagnostics.events
          .whereType<CenteredCarouselGestureStarted>()
          .toList();
      final samples = diagnostics.events
          .whereType<CenteredCarouselGestureSample>()
          .toList();
      final releases = diagnostics.events
          .whereType<CenteredCarouselGestureReleased>()
          .toList();
      final ballistics = diagnostics.events
          .whereType<CenteredCarouselBallisticStarted>()
          .toList();
      final settles = diagnostics.events
          .whereType<CenteredCarouselSettled>()
          .toList();

      expect(starts, hasLength(1));
      expect(samples, isNotEmpty);
      expect(releases, hasLength(1));
      expect(ballistics, hasLength(1));
      expect(settles, hasLength(1));
      expect(releases.single.primaryVelocity.abs(), greaterThan(0));
      expect(ballistics.single.inputVelocity.abs(), greaterThan(0));
      expect(ballistics.single.targetPixels, isNotNull);
      expect(
        ballistics.single.simulationKind,
        CenteredCarouselSimulationKind.scrollSpring,
      );
      expect(settles.single.finalLogicalIndex, controller.selectedLogicalIndex);
      expect(settles.single.metricChangeCount, 0);

      final identities = <CenteredCarouselMotionIdentity>[
        starts.single.identities,
        ballistics.single.identities,
        settles.single.identities,
      ];
      expect(
        identities.map((value) => value.controllerIdentity).toSet(),
        hasLength(1),
      );
      expect(
        identities.map((value) => value.positionIdentity).toSet(),
        hasLength(1),
      );
      expect(
        identities.map((value) => value.physicsIdentity).toSet(),
        hasLength(1),
      );
      expect(
        diagnostics.events.whereType<CenteredCarouselScrollMetricsChanged>(),
        isEmpty,
      );
    },
  );

  testWidgets('disabled diagnostics allocate and publish no events', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 4);
    final diagnostics = _RecordingMotionDiagnostics(enabled: false);
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 80,
          child: CenteredCarousel<int>(
            dataSource: CyclicCarouselDataSource<int>(
              List<int>.generate(12, (index) => index),
            ),
            controller: controller,
            spec: CenteredCarouselPresets.timeRail(itemExtent: 56),
            height: 48,
            motionDiagnostics: diagnostics,
            itemBuilder: (context, item, metrics) => Text('$item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.fling(
      find.byKey(const ValueKey('centered-carousel-viewport')),
      const Offset(-180, 0),
      1600,
    );
    await tester.pumpAndSettle();

    expect(diagnostics.events, isEmpty);
  });

  testWidgets('counts a replaced ballistic activity as an interruption', (
    tester,
  ) async {
    final controller = CenteredCarouselController(initialIndex: 14);
    final diagnostics = _RecordingMotionDiagnostics();
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 80,
          child: CenteredCarousel<int>(
            dataSource: CyclicCarouselDataSource<int>(
              List<int>.generate(31, (index) => index),
            ),
            controller: controller,
            spec: CenteredCarouselPresets.timeRail(itemExtent: 56),
            height: 48,
            motionDiagnostics: diagnostics,
            itemBuilder: (context, item, metrics) => Text('$item'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    diagnostics.events.clear();

    await tester.fling(
      find.byKey(const ValueKey('centered-carousel-viewport')),
      const Offset(-280, 0),
      2200,
    );
    await tester.pump();
    (controller.scrollController.position as ScrollPositionWithSingleContext)
        .goBallistic(1800);
    await tester.pumpAndSettle();

    final settle = diagnostics.events
        .whereType<CenteredCarouselSettled>()
        .single;
    expect(settle.activityInterruptCount, greaterThanOrEqualTo(1));
    expect(
      diagnostics.events
          .whereType<CenteredCarouselScrollActivityChanged>()
          .where(
            (event) =>
                event.previousActivity ==
                    CenteredCarouselActivityKind.ballistic &&
                event.nextActivity == CenteredCarouselActivityKind.ballistic &&
                event.previousActivityIdentity != event.nextActivityIdentity,
          ),
      isNotEmpty,
    );
  });
}

final class _RecordingMotionDiagnostics
    implements CenteredCarouselMotionDiagnosticSink {
  _RecordingMotionDiagnostics({this.enabled = true});

  final bool enabled;
  final List<CenteredCarouselMotionDiagnosticEvent> events = [];

  @override
  bool get isEnabled => enabled;

  @override
  void record(CenteredCarouselMotionDiagnosticEvent event) => events.add(event);
}
