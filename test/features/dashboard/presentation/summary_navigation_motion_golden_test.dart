import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/summary_navigation_motion_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_navigation_motion_region.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/summary_pill_text_transition.dart';

const _current = SummaryTextContent(
  title: 'Havi',
  subtitle: '2026. április 21.',
);
const _next = SummaryTextContent(title: 'Havi', subtitle: '2026. május 21.');

Widget _motionGoldenHost({
  required SummaryNavigationMotionController controller,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: const ValueKey('summary-navigation-motion-golden'),
          child: Container(
            width: 280,
            height: 58,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            alignment: Alignment.centerLeft,
            color: const Color(0xfffafafa),
            child: SummaryNavigationMotionRegion(
              controller: controller,
              content: _current,
              axis: SummaryTransitionAxis.none,
              direction: SummaryTransitionDirection.forward,
              animateAxis: false,
            ),
          ),
        ),
      ),
    ),
  );
}

Future<void> _pumpGoldenSurface(WidgetTester tester, Widget child) async {
  await tester.binding.setSurfaceSize(const Size(320, 100));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(child);
}

void main() {
  testWidgets('golden: rail tick is a compact Y-only text impulse', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await _pumpGoldenSurface(tester, _motionGoldenHost(controller: controller));

    controller.triggerRailTick(oldLogicalIndex: 31, newLogicalIndex: 32);
    await tester.pump();

    await expectLater(
      find.byKey(const ValueKey('summary-navigation-motion-golden')),
      matchesGoldenFile('../../../goldens/summary_navigation_tick.png'),
    );
  });
}
