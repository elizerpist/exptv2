import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_ticking_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required ValueChanged<int> onIndexChanged,
    required VoidCallback onTick,
    int itemCount = 3,
    int? selectedIndex,
    bool disableAnimations = false,
    String? semanticLabel,
  }) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: disableAnimations),
        child: Scaffold(
          body: Center(
            child: SpendeeBalanceTickingViewport(
              key: const ValueKey('ticking-test-viewport'),
              width: 300,
              height: 80,
              itemCount: itemCount,
              slotDistance: 100,
              centerAnchor: 150,
              selectedIndex: selectedIndex,
              onIndexChanged: onIndexChanged,
              onTick: onTick,
              semanticLabel: semanticLabel,
              itemSizeBuilder: (_, selected) =>
                  Size(selected ? 70 : 60, selected ? 50 : 40),
              itemBuilder: (context, index, selected, select) {
                return GestureDetector(
                  key: ValueKey('ticking-test-item-$index'),
                  behavior: HitTestBehavior.opaque,
                  onTap: select,
                  child: ColoredBox(
                    color: selected ? Colors.purple : Colors.grey,
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('uses boundary ticks, haptics, snap and two-way wrap', (
    tester,
  ) async {
    final selected = <int>[];
    var haptics = 0;
    await tester.pumpWidget(
      host(onIndexChanged: selected.add, onTick: () => haptics += 1),
    );

    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-0'))).dx,
      400,
    );

    await tester.timedDrag(
      find.byKey(const ValueKey('ticking-test-viewport')),
      const Offset(75, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(selected.last, 2);
    expect(haptics, 1);
    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-2'))).dx,
      400,
    );

    await tester.timedDrag(
      find.byKey(const ValueKey('ticking-test-viewport')),
      const Offset(-75, 0),
      const Duration(milliseconds: 600),
    );
    await tester.pumpAndSettle();
    expect(selected.last, 0);
    expect(haptics, 2);
  });

  testWidgets(
    'two-item viewport materializes the other option on both wrap sides',
    (tester) async {
      await tester.pumpWidget(
        host(itemCount: 2, onIndexChanged: (_) {}, onTick: () {}),
      );

      final left = find.byKey(
        const ValueKey('spendee-balance-ticking-slot-1--1'),
      );
      final center = find.byKey(
        const ValueKey('spendee-balance-ticking-slot-0-0'),
      );
      final right = find.byKey(
        const ValueKey('spendee-balance-ticking-slot-1-1'),
      );
      expect(left, findsOneWidget);
      expect(center, findsOneWidget);
      expect(right, findsOneWidget);
      expect(tester.getCenter(left).dx, 300);
      expect(tester.getCenter(center).dx, 400);
      expect(tester.getCenter(right).dx, 500);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('ticking-test-viewport'))),
      );
      await gesture.moveBy(const Offset(20, 0));
      await gesture.moveBy(const Offset(40, 0));
      await tester.pump();
      expect(tester.getCenter(left).dx, closeTo(340, .01));
      expect(tester.getCenter(center).dx, closeTo(440, .01));
      expect(tester.getCenter(right).dx, closeTo(540, .01));
      await gesture.cancel();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('keeps residual motion under the finger and cancels to center', (
    tester,
  ) async {
    await tester.pumpWidget(host(onIndexChanged: (_) {}, onTick: () {}));
    final viewport = find.byKey(const ValueKey('ticking-test-viewport'));
    final gesture = await tester.startGesture(tester.getCenter(viewport));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-0'))).dx,
      closeTo(360, .01),
    );
    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-1'))).dx,
      closeTo(460, .01),
    );

    await gesture.cancel();
    await tester.pumpAndSettle();
    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-0'))).dx,
      closeTo(400, .01),
    );
  });

  testWidgets(
    'tap and fling use the same logical index and survive count changes',
    (tester) async {
      final selected = <int>[];
      var itemCount = 4;
      late StateSetter updateHost;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                updateHost = setState;
                return Center(
                  child: SpendeeBalanceTickingViewport(
                    key: const ValueKey('ticking-test-viewport'),
                    width: 300,
                    height: 80,
                    itemCount: itemCount,
                    slotDistance: 100,
                    centerAnchor: 150,
                    onIndexChanged: selected.add,
                    onTick: () {},
                    itemSizeBuilder: (_, _) => const Size(60, 40),
                    itemBuilder: (context, index, selected, select) {
                      return GestureDetector(
                        key: ValueKey('ticking-test-item-$index'),
                        behavior: HitTestBehavior.opaque,
                        onTap: select,
                        child: const ColoredBox(color: Colors.purple),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('ticking-test-item-1')));
      await tester.pumpAndSettle();
      expect(selected.last, 1);

      final beforeFling = selected.length;
      await tester.fling(
        find.byKey(const ValueKey('ticking-test-viewport')),
        const Offset(-120, 0),
        2000,
      );
      await tester.pumpAndSettle();
      expect(selected.length, greaterThan(beforeFling));

      updateHost(() => itemCount = 2);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('ticking-test-item-0')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('ticking-test-item-1')),
        findsNWidgets(2),
      );
      expect(find.byKey(const ValueKey('ticking-test-item-2')), findsNothing);
    },
  );

  testWidgets('reduced motion commits a tapped item without animation frames', (
    tester,
  ) async {
    final selected = <int>[];
    var haptics = 0;
    await tester.pumpWidget(
      host(
        onIndexChanged: selected.add,
        onTick: () => haptics += 1,
        disableAnimations: true,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ticking-test-item-1')));
    await tester.pump();

    expect(selected, const [1]);
    expect(haptics, 1);
    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-1'))).dx,
      400,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('reduced motion settles a partial drag immediately', (
    tester,
  ) async {
    final selected = <int>[];
    await tester.pumpWidget(
      host(
        onIndexChanged: selected.add,
        onTick: () {},
        disableAnimations: true,
      ),
    );

    final viewport = find.byKey(const ValueKey('ticking-test-viewport'));
    final gesture = await tester.startGesture(tester.getCenter(viewport));
    // The first move resolves the horizontal gesture arena.
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();
    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-0'))).dx,
      closeTo(360, .01),
    );

    await gesture.up();
    await tester.pump();
    expect(selected, isEmpty);
    expect(
      tester.getCenter(find.byKey(const ValueKey('ticking-test-item-0'))).dx,
      closeTo(400, .01),
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('semantics and arrow keys select previous and next once', (
    tester,
  ) async {
    final selected = <int>[];
    var haptics = 0;
    await tester.pumpWidget(
      host(
        onIndexChanged: selected.add,
        onTick: () => haptics += 1,
        semanticLabel: 'Teszt időszakok',
      ),
    );

    final semantics = tester.widget<Semantics>(
      find.byWidgetPredicate(
        (widget) =>
            widget is Semantics && widget.properties.label == 'Teszt időszakok',
      ),
    );
    expect(semantics.properties.onIncrease, isNotNull);
    expect(semantics.properties.onDecrease, isNotNull);
    semantics.properties.onIncrease!();
    await tester.pumpAndSettle();
    semantics.properties.onDecrease!();
    await tester.pumpAndSettle();
    expect(selected, const [1, 0]);
    expect(haptics, 2);

    final dragSurface = find.descendant(
      of: find.byKey(const ValueKey('ticking-test-viewport')),
      matching: find.byWidgetPredicate(
        (widget) =>
            widget is GestureDetector && widget.onHorizontalDragStart != null,
      ),
    );
    Focus.of(tester.element(dragSurface)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    expect(selected, const [1, 0, 1, 0]);
    expect(haptics, 4);
  });

  testWidgets(
    'fully offscreen items are inert while partially visible items stay accessible',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SpendeeBalanceTickingViewport(
                key: const ValueKey('ticking-test-viewport'),
                width: 300,
                height: 80,
                itemCount: 3,
                slotDistance: 100,
                centerAnchor: 150,
                centerOffsetBuilder: (logicalOffset) {
                  return switch (logicalOffset) {
                    1 => 170,
                    -1 => -220,
                    _ => 0,
                  };
                },
                onIndexChanged: (_) {},
                onTick: () {},
                itemSizeBuilder: (_, _) => const Size(60, 40),
                itemBuilder: (context, index, selected, select) {
                  return Semantics(
                    label: 'Ticking card $index',
                    button: true,
                    child: Focus(
                      child: GestureDetector(
                        key: ValueKey('ticking-test-item-$index'),
                        behavior: HitTestBehavior.opaque,
                        onTap: select,
                        child: const ColoredBox(color: Colors.purple),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      );

      final viewport = tester.getRect(
        find.byKey(const ValueKey('ticking-test-viewport')),
      );
      final partialItem = find.byKey(const ValueKey('ticking-test-item-1'));
      final offscreenItem = find.byKey(const ValueKey('ticking-test-item-2'));
      final partialRect = tester.getRect(partialItem);
      final offscreenRect = tester.getRect(offscreenItem);
      expect(partialRect.left, lessThan(viewport.right));
      expect(partialRect.right, greaterThan(viewport.right));
      expect(offscreenRect.right, lessThanOrEqualTo(viewport.left));

      _expectViewportAccessGate(tester, partialItem, excluded: false);
      _expectViewportAccessGate(tester, offscreenItem, excluded: true);
      expect(find.bySemanticsLabel('Ticking card 1'), findsOneWidget);
      expect(find.bySemanticsLabel('Ticking card 2'), findsNothing);
    },
  );
}

void _expectViewportAccessGate(
  WidgetTester tester,
  Finder item, {
  required bool excluded,
}) {
  expect(
    tester
        .widget<IgnorePointer>(
          find.ancestor(of: item, matching: find.byType(IgnorePointer)).first,
        )
        .ignoring,
    excluded,
  );
  expect(
    tester
        .widget<ExcludeFocus>(
          find.ancestor(of: item, matching: find.byType(ExcludeFocus)).first,
        )
        .excluding,
    excluded,
  );
  expect(
    tester
        .widget<ExcludeSemantics>(
          find
              .ancestor(of: item, matching: find.byType(ExcludeSemantics))
              .first,
        )
        .excluding,
    excluded,
  );
}
