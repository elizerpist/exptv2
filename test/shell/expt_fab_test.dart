import 'package:exptv2/features/shell/widgets/expt_fab.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('FAB horizontal drag steps once and suppresses tap dispatch', (
    tester,
  ) async {
    var pressed = 0;
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExptFab(
              onPressed: () => pressed += 1,
              onHorizontalDragStep: steps.add,
            ),
          ),
        ),
      ),
    );

    await tester.drag(
      find.byKey(const ValueKey('expt-fab')),
      const Offset(48, 0),
    );
    await tester.pumpAndSettle();

    expect(steps, [1]);
    expect(pressed, 0);
  });

  testWidgets('FAB tap still dispatches when no horizontal step happened', (
    tester,
  ) async {
    var pressed = 0;
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExptFab(
              onPressed: () => pressed += 1,
              onHorizontalDragStep: steps.add,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('expt-fab')));
    await tester.pumpAndSettle();

    expect(steps, isEmpty);
    expect(pressed, 1);
  });

  testWidgets('FAB joystick accelerates threshold upward with finger height', (
    tester,
  ) async {
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExptFab(onPressed: () {}, onVerticalDragStep: steps.add),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('expt-fab')));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(center - const Offset(0, 30));
    await tester.pump(const Duration(milliseconds: 270));
    await gesture.moveTo(center - const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 90));
    await gesture.moveTo(center - const Offset(0, 160));
    await tester.pump(const Duration(milliseconds: 90));
    await gesture.up();

    expect(steps, [1, 2, 6]);
  });

  testWidgets('FAB joystick accelerates threshold downward with finger depth', (
    tester,
  ) async {
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExptFab(onPressed: () {}, onVerticalDragStep: steps.add),
          ),
        ),
      ),
    );

    final center = tester.getCenter(find.byKey(const ValueKey('expt-fab')));
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(center + const Offset(0, 160));
    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();

    expect(steps, isNotEmpty);
    expect(steps, everyElement(-6));
  });

  testWidgets(
    'FAB joystick shows upward direction and all strengths before ticking',
    (tester) async {
      final steps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExptFab(onPressed: () {}, onVerticalDragStep: steps.add),
            ),
          ),
        ),
      );

      final fab = find.byKey(const ValueKey('expt-fab'));
      final restingCenter = tester.getCenter(fab);
      final gesture = await tester.startGesture(restingCenter);
      await tester.pump(const Duration(milliseconds: 600));

      await gesture.moveTo(restingCenter - const Offset(0, 30));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-increase-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-slow')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab).dy, restingCenter.dy - 2);
      expect(steps, isEmpty);

      await gesture.moveTo(restingCenter - const Offset(0, 100));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-medium')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab).dy, restingCenter.dy - 4);
      expect(steps, isEmpty);

      await gesture.moveTo(restingCenter - const Offset(0, 160));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-fast')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab).dy, restingCenter.dy - 6);
      expect(steps, isEmpty);

      await gesture.up();
    },
  );

  testWidgets(
    'FAB joystick shows downward direction and suppresses sheet tap',
    (tester) async {
      var pressed = 0;
      final steps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExptFab(
                onPressed: () => pressed += 1,
                onVerticalDragStep: steps.add,
              ),
            ),
          ),
        ),
      );

      final fab = find.byKey(const ValueKey('expt-fab'));
      final restingCenter = tester.getCenter(fab);
      final gesture = await tester.startGesture(restingCenter);
      await tester.pump(const Duration(milliseconds: 600));
      await gesture.moveTo(restingCenter + const Offset(0, 100));
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        find.byKey(const ValueKey('expt-fab-joystick-decrease-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-medium')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab).dy, restingCenter.dy + 4);
      expect(steps, isEmpty);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(pressed, 0);
    },
  );
}
