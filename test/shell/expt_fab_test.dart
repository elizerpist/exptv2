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

  testWidgets(
    'FAB horizontal drag shows right direction, strength, and exact offset',
    (tester) async {
      final steps = <int>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: ExptFab(onPressed: () {}, onHorizontalDragStep: steps.add),
            ),
          ),
        ),
      );

      final fab = find.byKey(const ValueKey('expt-fab'));
      final restingCenter = tester.getCenter(fab);
      final gesture = await tester.startGesture(restingCenter);

      await gesture.moveTo(restingCenter + const Offset(1, 0));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-right-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-slow')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab), restingCenter + const Offset(2, 0));
      expect(steps, isEmpty);

      await gesture.moveTo(restingCenter + const Offset(30, 0));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-right-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-slow')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab), restingCenter + const Offset(2, 0));
      expect(steps, isEmpty);

      await gesture.moveTo(restingCenter + const Offset(100, 0));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-medium')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab), restingCenter + const Offset(4, 0));

      await gesture.moveTo(restingCenter + const Offset(160, 0));
      await tester.pump(const Duration(milliseconds: 1));
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-fast')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab), restingCenter + const Offset(6, 0));

      await gesture.up();
    },
  );

  testWidgets(
    'FAB horizontal drag shows left feedback then cleans up and suppresses tap',
    (tester) async {
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

      final fab = find.byKey(const ValueKey('expt-fab'));
      final restingCenter = tester.getCenter(fab);
      final gesture = await tester.startGesture(restingCenter);
      await gesture.moveTo(restingCenter - const Offset(100, 0));
      await tester.pump(const Duration(milliseconds: 1));

      expect(
        find.byKey(const ValueKey('expt-fab-joystick-left-active')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('expt-fab-joystick-speed-medium')),
        findsOneWidget,
      );
      expect(tester.getCenter(fab), restingCenter - const Offset(4, 0));
      expect(steps, [-1]);

      await gesture.up();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('expt-fab-joystick-left-active')),
        findsNothing,
      );
      expect(tester.getCenter(fab), restingCenter);
      expect(pressed, 0);

      await tester.tap(fab);
      await tester.pumpAndSettle();
      expect(pressed, 1);
    },
  );

  testWidgets('FAB horizontal threshold stays at 32 px and cancel cleans up', (
    tester,
  ) async {
    final steps = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: ExptFab(onPressed: () {}, onHorizontalDragStep: steps.add),
          ),
        ),
      ),
    );

    final fab = find.byKey(const ValueKey('expt-fab'));
    final restingCenter = tester.getCenter(fab);
    final gesture = await tester.startGesture(restingCenter);
    await gesture.moveBy(const Offset(31, 0));
    await tester.pump(const Duration(milliseconds: 1));
    expect(steps, isEmpty);

    await gesture.moveBy(const Offset(1, 0));
    await tester.pump(const Duration(milliseconds: 1));
    expect(steps, [1]);

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('expt-fab-joystick-right-active')),
      findsNothing,
    );
    expect(tester.getCenter(fab), restingCenter);
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

  testWidgets('FAB cancels an active joystick when its callback is removed', (
    tester,
  ) async {
    final steps = <int>[];
    var joystickEnabled = true;
    late StateSetter updateHost;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: StatefulBuilder(
            builder: (context, setState) {
              updateHost = setState;
              return Center(
                child: ExptFab(
                  onPressed: () {},
                  onVerticalDragStep: joystickEnabled ? steps.add : null,
                ),
              );
            },
          ),
        ),
      ),
    );

    final fab = find.byKey(const ValueKey('expt-fab'));
    final center = tester.getCenter(fab);
    final gesture = await tester.startGesture(center);
    await tester.pump(const Duration(milliseconds: 600));
    await gesture.moveTo(center - const Offset(0, 100));
    await tester.pump(const Duration(milliseconds: 1));
    expect(
      find.byKey(const ValueKey('expt-fab-joystick-increase-active')),
      findsOneWidget,
    );

    updateHost(() => joystickEnabled = false);
    await tester.pump();
    expect(
      find.byKey(const ValueKey('expt-fab-joystick-increase-active')),
      findsNothing,
    );

    await tester.pump(const Duration(milliseconds: 300));
    await gesture.up();
    expect(steps, isEmpty);
  });
}
