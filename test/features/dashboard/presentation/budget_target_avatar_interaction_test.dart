import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_interaction.dart';

void main() {
  testWidgets('raw pointer press uses the approved immediate scale contract', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 80,
              height: 80,
              child: BudgetTargetAvatarInteraction(
                child: ColoredBox(color: Colors.blue),
              ),
            ),
          ),
        ),
      ),
    );

    final scaleFinder = find.byKey(
      const ValueKey('budget-target-avatar-press-scale'),
    );
    AnimatedScale scale() => tester.widget<AnimatedScale>(scaleFinder);
    expect(scale().scale, 1);
    expect(scale().duration, const Duration(milliseconds: 115));
    expect(scale().curve, Curves.easeOutQuad);

    final pointer = await tester.startGesture(tester.getCenter(scaleFinder));
    await tester.pump();
    expect(scale().scale, .8);

    await pointer.cancel();
    await tester.pump();
    expect(scale().scale, 1);
  });
}
