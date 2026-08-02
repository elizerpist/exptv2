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
  SummaryTextContent? candidate,
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
              horizontalCandidate: candidate,
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

  testWidgets('horizontal drag renders the whole candidate block in X only', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller, candidate: _next));

    controller
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.forward,
        canNavigate: true,
      )
      ..updateHorizontalDragProgress(.5);
    await tester.pump();

    expect(find.text(_current.title), findsNWidgets(2));
    expect(find.text(_current.subtitle), findsOneWidget);
    expect(find.text(_next.subtitle), findsOneWidget);
    final outgoing = _translation(
      tester,
      const ValueKey('summary-navigation-drag-outgoing'),
    );
    final incoming = _translation(
      tester,
      const ValueKey('summary-navigation-drag-incoming'),
    );
    expect(outgoing.dx, lessThan(0));
    expect(incoming.dx, greaterThan(0));
    expect(outgoing.dy, 0);
    expect(incoming.dy, 0);
  });

  testWidgets('SUM resistance returns the current text without a candidate', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller, candidate: _next));

    controller
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.forward,
        canNavigate: false,
      )
      ..updateHorizontalDragProgress(.5);
    await tester.pump();

    expect(find.text(_current.subtitle), findsOneWidget);
    expect(find.text(_next.subtitle), findsNothing);
    expect(
      _translation(tester, const ValueKey('summary-navigation-drag-outgoing')),
      const Offset(-2.5, 0),
    );

    controller.cancelHorizontalDrag();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));

    final returning = _translation(
      tester,
      const ValueKey('summary-navigation-drag-outgoing'),
    );
    expect(returning.dx, inExclusiveRange(-2.5, 0));
    expect(returning.dy, 0);
    expect(find.text(_next.subtitle), findsNothing);

    await tester.pump(const Duration(milliseconds: 100));
    expect(
      controller.horizontalMotion.phase,
      SummaryHorizontalMotionPhase.idle,
    );
  });

  testWidgets('a stale cancellation return cannot clear a newer drag', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(_host(controller: controller, candidate: _next));

    controller
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.forward,
        canNavigate: true,
      )
      ..updateHorizontalDragProgress(.5)
      ..cancelHorizontalDrag();
    await tester.pump();

    controller
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.backward,
        canNavigate: true,
      )
      ..updateHorizontalDragProgress(.4);
    await tester.pump(const Duration(milliseconds: 150));

    expect(
      controller.horizontalMotion.phase,
      SummaryHorizontalMotionPhase.dragging,
    );
    expect(
      controller.horizontalMotion.direction,
      SummaryTransitionDirection.backward,
    );
    expect(controller.horizontalMotion.progress, .4);
  });

  testWidgets('horizontal commit continues from the interactive drag frame', (
    tester,
  ) async {
    final controller = SummaryNavigationMotionController();
    addTearDown(controller.dispose);
    await tester.pumpWidget(
      _host(
        controller: controller,
        candidate: _next,
        axis: SummaryTransitionAxis.horizontal,
        animateAxis: true,
      ),
    );

    controller
      ..beginHorizontalDrag(
        direction: SummaryTransitionDirection.forward,
        canNavigate: true,
      )
      ..updateHorizontalDragProgress(.5);
    await tester.pump();
    final dragOutgoing = _translation(
      tester,
      const ValueKey('summary-navigation-drag-outgoing'),
    );
    final dragIncoming = _translation(
      tester,
      const ValueKey('summary-navigation-drag-incoming'),
    );

    controller.commitHorizontalDrag();
    await tester.pumpWidget(
      _host(
        controller: controller,
        content: _next,
        candidate: _current,
        axis: SummaryTransitionAxis.horizontal,
        animateAxis: true,
      ),
    );

    expect(
      _translation(tester, const ValueKey('summary-navigation-axis-outgoing')),
      closeToOffset(dragOutgoing, .3),
    );
    expect(
      _translation(tester, const ValueKey('summary-navigation-axis-incoming')),
      closeToOffset(dragIncoming, .3),
    );
  });
}

Matcher closeToOffset(Offset expected, double tolerance) => predicate<Offset>(
  (actual) =>
      (actual.dx - expected.dx).abs() <= tolerance &&
      (actual.dy - expected.dy).abs() <= tolerance,
  'an offset close to $expected',
);
