import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_display_frame_coalescer.dart';
import 'package:fluvi/features/dashboard/runtime/application/dashboard_presentation_controller.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_physics.dart';

import 'dashboard_runtime_test_fixtures.dart';

void main() {
  late DebugPrintCallback originalDebugPrint;

  setUp(() {
    originalDebugPrint = debugPrint;
    debugPrint = (String? _, {int? wrapWidth}) {};
  });

  tearDown(() => debugPrint = originalDebugPrint);

  test(
    'identical gesture target is invariant across 0, 1, 94 and 658 rows',
    () {
      final targetsByDensity = <int, List<double>>{};

      for (final density in <int>[0, 1, 94, 658]) {
        final scheduler = _DisplayFrameScheduler();
        final controller = DashboardPresentationController(
          initialDate: DateTime(2026, 7, 14),
          displayFrameScheduler: scheduler,
        );
        addTearDown(controller.dispose);
        controller.installIndex(
          buildRuntimeTestIndex(
            revision: 7,
            amountMultiplier: density == 0 ? 0 : 1,
            entryCountOverride: density,
          ),
          publishImmediately: true,
        );
        final physics = controller.motion.dashboardPhysics;
        final targets = List<double>.generate(
          100,
          (_) => calculateTargetRawIndex(
            currentPixels: 14 * physics.itemExtent,
            velocity: 2200,
            itemExtent: physics.itemExtent,
            minScrollExtent: 0,
            physics: physics,
          ),
          growable: false,
        );
        targetsByDensity[density] = targets;
        expect(targets.toSet(), hasLength(1));
        expect(targets.first, greaterThan(15), reason: 'long fling collapsed');
        expect(controller.motion.carouselController.physicsCreationCount, 1);
      }

      final reference = targetsByDensity[0]!;
      for (final density in <int>[1, 94, 658]) {
        expect(targetsByDensity[density], reference);
      }
    },
  );

  test('first and tenth gesture use the same immutable motion path', () {
    final scheduler = _DisplayFrameScheduler();
    final controller = DashboardPresentationController(
      initialDate: DateTime(2026, 7, 14),
      displayFrameScheduler: scheduler,
    );
    addTearDown(controller.dispose);
    controller.installIndex(
      buildRuntimeTestIndex(revision: 7, entryCountOverride: 94),
      publishImmediately: true,
    );
    final physics = controller.motion.dashboardPhysics;

    double targetForGesture() => calculateTargetRawIndex(
      currentPixels: 14 * physics.itemExtent,
      velocity: 2200,
      itemExtent: physics.itemExtent,
      minScrollExtent: 0,
      physics: physics,
    );

    final first = targetForGesture();
    final repeated = List<double>.generate(9, (_) => targetForGesture());
    expect(repeated.last, first);
    expect(repeated.toSet(), <double>{first});
  });
}

final class _DisplayFrameScheduler implements DashboardDisplayFrameScheduler {
  @override
  int currentFrameNumber = 0;

  @override
  void scheduleFrame(void Function() callback) {}
}
