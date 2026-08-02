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

Widget _host({
  required SummaryNavigationMotionController controller,
  SummaryTextContent content = _current,
  SummaryTransitionAxis axis = SummaryTransitionAxis.none,
  bool animateAxis = false,
}) {
  return MaterialApp(
    home: Scaffold(
      body: Row(
        children: [
          Expanded(
            child: SummaryNavigationMotionRegion(
              controller: controller,
              content: content,
              axis: axis,
              direction: SummaryTransitionDirection.forward,
              animateAxis: animateAxis,
            ),
          ),
          const Text('707 000 Ft', key: ValueKey('summary-amount')),
        ],
      ),
    ),
  );
}

Offset _translation(WidgetTester tester, Key key) {
  final transform = tester.widget<Transform>(find.byKey(key));
  final translation = transform.transform.getTranslation();
  return Offset(translation.x, translation.y);
}

void main() {
  testWidgets('rail tick lifts the full text block but not the amount', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller));

    controller.triggerRailTick(oldLogicalIndex: 20, newLogicalIndex: 21);
    await tester.pump();

    final offset = _translation(
      tester,
      const ValueKey('summary-navigation-tick-transform'),
    );
    expect(offset.dx, 0);
    expect(offset.dy, inInclusiveRange(-4.0, 0.0));
    expect(
      find.ancestor(
        of: find.byKey(const ValueKey('summary-amount')),
        matching: find.byKey(
          const ValueKey('summary-navigation-tick-transform'),
        ),
      ),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 160));
    expect(
      _translation(
        tester,
        const ValueKey('summary-navigation-tick-transform'),
      ).dy,
      closeTo(0, .05),
    );
  });

  testWidgets(
    'holding shell return freezes outgoing text and starts no axis transition',
    (tester) async {
      final controller = SummaryNavigationMotionController();
      addTearDown(controller.dispose);
      await tester.pumpWidget(_host(controller: controller, content: _next));

      final generation = controller.holdTextForShellReturn(
        outgoing: _current,
        axis: SummaryTransitionAxis.horizontal,
        direction: SummaryTransitionDirection.forward,
      );
      controller.bindShellReturnIncoming(
        generation: generation,
        incoming: _next,
      );
      await tester.pump();

      expect(find.text(_current.title), findsOneWidget);
      expect(find.text(_current.subtitle), findsOneWidget);
      expect(find.text(_next.subtitle), findsNothing);
      expect(
        find.byKey(const ValueKey('summary-navigation-axis-outgoing')),
        findsNothing,
      );
    },
  );

  testWidgets('matching shell completion starts X-only text transition', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller, content: _next));

    final generation = controller.holdTextForShellReturn(
      outgoing: _current,
      axis: SummaryTransitionAxis.horizontal,
      direction: SummaryTransitionDirection.forward,
    );
    controller.bindShellReturnIncoming(generation: generation, incoming: _next);
    controller.completeShellReturn(generation: generation);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final outgoing = _translation(
      tester,
      const ValueKey('summary-navigation-axis-outgoing'),
    );
    final incoming = _translation(
      tester,
      const ValueKey('summary-navigation-axis-incoming'),
    );
    expect(outgoing.dx, lessThan(0));
    expect(incoming.dx, greaterThan(0));
    expect(outgoing.dy, 0);
    expect(incoming.dy, 0);
  });

  testWidgets('staged vertical transition stays on the Y axis', (tester) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller, content: _next));

    final generation = controller.holdTextForShellReturn(
      outgoing: _current,
      axis: SummaryTransitionAxis.vertical,
      direction: SummaryTransitionDirection.backward,
    );
    controller.bindShellReturnIncoming(generation: generation, incoming: _next);
    controller.completeShellReturn(generation: generation);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final outgoing = _translation(
      tester,
      const ValueKey('summary-navigation-axis-outgoing'),
    );
    final incoming = _translation(
      tester,
      const ValueKey('summary-navigation-axis-incoming'),
    );
    expect(outgoing.dx, 0);
    expect(incoming.dx, 0);
    expect(outgoing.dy, greaterThan(0));
    expect(incoming.dy, lessThan(0));
  });

  testWidgets('staged axis motion suppresses the visual rail tick only', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller));

    final generation = controller.holdTextForShellReturn(
      outgoing: _current,
      axis: SummaryTransitionAxis.horizontal,
      direction: SummaryTransitionDirection.forward,
    );
    controller.triggerRailTick(oldLogicalIndex: 20, newLogicalIndex: 21);
    await tester.pump();

    expect(
      _translation(tester, const ValueKey('summary-navigation-tick-transform')),
      Offset.zero,
    );
    expect(controller.railTick, const SummaryRailTick(20, 21));

    controller.bindShellReturnIncoming(generation: generation, incoming: _next);
    controller.completeShellReturn(generation: generation);
    controller.completeTextTransition(generation: generation);
    await tester.pump();

    expect(
      _translation(tester, const ValueKey('summary-navigation-tick-transform')),
      Offset.zero,
    );
  });
}
