import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_vertical_scroll_observer.dart';

void main() {
  testWidgets(
    'observes goBallistic without altering the framework velocity or physics',
    (tester) async {
      final observations = <DashboardVerticalBallisticObservation>[];
      final controller = DashboardVerticalScrollController(
        onBallistic: observations.add,
        onContentDimensionsChanged: (_) {},
      );
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 320,
            child: CustomScrollView(
              controller: controller,
              physics: const ClampingScrollPhysics(),
              slivers: const <Widget>[
                SliverToBoxAdapter(child: SizedBox(height: 4000)),
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      final position = controller.position as ScrollPositionWithSingleContext;
      final physics = position.physics;
      position.goBallistic(1234);

      expect(observations, isNotEmpty);
      expect(observations.last.initialVelocity, 1234);
      expect(observations.last.releaseInvocation, isFalse);
      expect(observations.last.goBallisticInvocationCount, greaterThan(0));
      expect(identical(position.physics, physics), isTrue);
    },
  );
}
