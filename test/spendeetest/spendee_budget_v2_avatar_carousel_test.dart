import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required double width,
    required ValueChanged<int> onSettled,
    void Function(int index, {required bool directDrag})? onDetailedSettled,
    int itemCount = 7,
    int selectedIndex = 0,
    int externalSelectionEpoch = 0,
    void Function(int index, {required bool directDrag})? onPreview,
    VoidCallback? onPointerDown,
    double Function(double logicalOffset)? centerOffsetBuilder,
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: const ValueKey('budget-v2-avatar-carousel-test-root'),
            width: width,
            height: 80,
            child: SpendeeBudgetV2AvatarCarousel(
              key: const ValueKey('budget-v2-avatar-carousel-test-rail'),
              itemCount: itemCount,
              selectedIndex: selectedIndex,
              externalSelectionEpoch: externalSelectionEpoch,
              height: 72,
              slotDistance: 58,
              centerOffsetBuilder:
                  centerOffsetBuilder ?? (logicalOffset) => logicalOffset * 58,
              itemSizeBuilder: (_, _) => const Size(72, 72),
              onPreview: onPreview,
              onSettled: (index, {required directDrag}) {
                onSettled(index);
                onDetailedSettled?.call(index, directDrag: directDrag);
              },
              onPointerDown: onPointerDown,
              itemBuilder: (context, index, selected, select) =>
                  GestureDetector(
                    key: ValueKey('budget-v2-avatar-carousel-test-item-$index'),
                    onTap: select,
                    child: ColoredBox(
                      key: ValueKey(
                        'budget-v2-avatar-carousel-test-item-$index-'
                        '${selected ? 'selected' : 'idle'}',
                      ),
                      color: selected ? Colors.deepPurple : Colors.grey,
                    ),
                  ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('centres the selected avatar in the actual available rail width', (
    tester,
  ) async {
    for (final width in const <double>[328, 378]) {
      await tester.pumpWidget(host(width: width, onSettled: (_) {}));
      await tester.pump();

      final rail = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-root'),
      );
      final selected = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-item-0-selected'),
      );
      expect(tester.getSize(rail).width, width);
      expect(
        tester.getCenter(selected).dx,
        closeTo(tester.getCenter(rail).dx, .01),
        reason:
            'The selected centre must be derived from LayoutBuilder constraints, '
            'not the former 378px/189px authored canvas constants.',
      );
    }
  });

  testWidgets('changes the selected visual in the same direct-drag tick', (
    tester,
  ) async {
    final previews = <({int index, bool directDrag})>[];
    await tester.pumpWidget(
      host(
        width: 328,
        onSettled: (_) {},
        onPreview: (index, {required directDrag}) {
          previews.add((index: index, directDrag: directDrag));
        },
      ),
    );

    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    final gesture = await tester.startGesture(tester.getCenter(rail));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-60, 0));
    await tester.pump();

    expect(previews, contains((index: 1, directDrag: true)));
    expect(
      find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-item-1-selected'),
      ),
      findsOneWidget,
      reason:
          'The selected ring builder must change on the exact local boundary '
          'tick, before any dashboard/filter work is published.',
    );

    await gesture.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'honours a remote selection epoch even when its published index is unchanged',
    (tester) async {
      final settled = <int>[];
      await tester.pumpWidget(host(width: 328, onSettled: settled.add));
      await tester.pump();

      final rail = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-rail'),
      );
      await tester.timedDrag(
        rail,
        const Offset(-142, 0),
        const Duration(milliseconds: 260),
      );
      await tester.pumpAndSettle();
      expect(settled.last, isNot(0));

      await tester.pumpWidget(
        host(width: 328, onSettled: settled.add, externalSelectionEpoch: 1),
      );
      await tester.pumpAndSettle();

      expect(settled.last, 0);
    },
  );

  testWidgets(
    'ignores a parent selection acknowledgement while direct drag owns the rail',
    (tester) async {
      DebugConsole.clear();
      await tester.pumpWidget(host(width: 328, onSettled: (_) {}));
      await tester.pump();

      final rail = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-rail'),
      );
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();

      DebugConsole.clear();
      await tester.pumpWidget(
        host(
          width: 328,
          onSettled: (_) {},
          selectedIndex: 1,
          externalSelectionEpoch: 0,
        ),
      );
      await tester.pump();

      expect(
        DebugConsole.entries.where(
          (entry) =>
              entry.contains('[BudgetV2AvatarRail] phase=start') &&
              entry.contains('source=step'),
        ),
        isEmpty,
        reason:
            'A parent acknowledgement is not a new external intent and must '
            'not take control away from an active direct manipulation.',
      );
      expect(
        find.byKey(
          const ValueKey('budget-v2-avatar-carousel-test-item-0-selected'),
        ),
        findsOneWidget,
      );

      await gesture.cancel();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('pointer contact immediately preempts an external rail step', (
    tester,
  ) async {
    await tester.pumpWidget(host(width: 328, onSettled: (_) {}));
    await tester.pump();
    await tester.pumpWidget(
      host(
        width: 328,
        onSettled: (_) {},
        selectedIndex: 2,
        externalSelectionEpoch: 1,
      ),
    );
    await tester.pump(const Duration(milliseconds: 16));

    final root = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-root'),
    );
    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    expect(
      find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-item-0-selected'),
      ),
      findsOneWidget,
      reason: 'The first external step must still be travelling at 16 ms.',
    );

    final hold = await tester.startGesture(tester.getCenter(rail));
    await tester.pump();

    final selected = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-item-2-selected'),
    );
    expect(
      tester.getCenter(selected).dx,
      closeTo(tester.getCenter(root).dx, .01),
      reason:
          'Raw contact must settle the known external target at centre before '
          'Flutter recognises the next horizontal drag.',
    );

    await hold.up();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'a dragless pointer release completes the interrupted external request',
    (tester) async {
      final settled = <({int index, bool directDrag})>[];
      await tester.pumpWidget(
        host(
          width: 328,
          onSettled: (_) {},
          onDetailedSettled: (index, {required directDrag}) {
            settled.add((index: index, directDrag: directDrag));
          },
        ),
      );
      await tester.pump();
      await tester.pumpWidget(
        host(
          width: 328,
          onSettled: (_) {},
          selectedIndex: 2,
          externalSelectionEpoch: 1,
          onDetailedSettled: (index, {required directDrag}) {
            settled.add((index: index, directDrag: directDrag));
          },
        ),
      );
      await tester.pump(const Duration(milliseconds: 16));

      final rail = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-rail'),
      );
      final hold = await tester.startGesture(tester.getCenter(rail));
      await tester.pump();
      await hold.up();
      await tester.pumpAndSettle();

      expect(
        settled,
        contains((index: 2, directDrag: false)),
        reason:
            'A raw pointer that never becomes a horizontal drag must not '
            'discard the external chart/legend request it interrupted.',
      );
    },
  );

  testWidgets('notifies raw pointer contact before a drag is recognised', (
    tester,
  ) async {
    var pointerDowns = 0;
    await tester.pumpWidget(
      host(
        width: 328,
        onSettled: (_) {},
        onPointerDown: () => pointerDowns += 1,
      ),
    );
    await tester.pump();

    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    final hold = await tester.startGesture(tester.getCenter(rail));
    expect(pointerDowns, 1);
    await hold.up();
  });

  testWidgets('retains both entering belt avatars before they become visible', (
    tester,
  ) async {
    await tester.pumpWidget(host(width: 328, itemCount: 7, onSettled: (_) {}));
    await tester.pump();

    final entering = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-item-3-idle'),
    );
    final oppositeEntering = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-item-4-idle'),
    );
    expect(entering, findsOneWidget);
    expect(oppositeEntering, findsOneWidget);
    final priorElement = tester.element(entering);
    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: entering, matching: find.byType(Opacity)).first,
          )
          .opacity,
      0,
    );

    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    final gesture = await tester.startGesture(tester.getCenter(rail));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    expect(
      tester
          .widget<Opacity>(
            find.ancestor(of: entering, matching: find.byType(Opacity)).first,
          )
          .opacity,
      greaterThan(0),
    );

    await gesture.moveBy(const Offset(-58, 0));
    await tester.pump();
    expect(tester.element(entering), same(priorElement));
    await gesture.cancel();
  });

  testWidgets(
    'keeps all five belt entries opaque when outer spacing is widened',
    (tester) async {
      await tester.pumpWidget(
        host(
          width: 378,
          itemCount: 7,
          onSettled: (_) {},
          centerOffsetBuilder: (logicalOffset) {
            final sign = logicalOffset.sign;
            final distance = logicalOffset.abs();
            if (distance <= 1) return logicalOffset * 58;
            if (distance <= 2) return sign * 144;
            return sign * (144 + (distance - 2) * 58);
          },
        ),
      );
      await tester.pump();

      final visibleOuter = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-item-2-idle'),
      );
      final retainedEntry = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-item-3-idle'),
      );
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(of: visibleOuter, matching: find.byType(Opacity))
                  .first,
            )
            .opacity,
        1,
      );
      expect(
        tester
            .widget<Opacity>(
              find
                  .ancestor(of: retainedEntry, matching: find.byType(Opacity))
                  .first,
            )
            .opacity,
        0,
      );
    },
  );

  testWidgets('keeps every small-belt avatar unique when logical slots wrap', (
    tester,
  ) async {
    await tester.pumpWidget(host(width: 328, itemCount: 3, onSettled: (_) {}));
    await tester.pump();

    expect(tester.takeException(), isNull);
    expect(
      find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-item-0-selected'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('budget-v2-avatar-carousel-test-item-1-idle')),
      findsOneWidget,
      reason:
          'A wrapped item must have one interaction target, not two copies '
          'with the same category identity.',
    );
    expect(
      find.byKey(const ValueKey('budget-v2-avatar-carousel-test-item-2-idle')),
      findsOneWidget,
    );
  });

  testWidgets('emits interaction-scoped diagnostics rather than frame logs', (
    tester,
  ) async {
    DebugConsole.clear();
    await tester.pumpWidget(host(width: 328, onSettled: (_) {}));

    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    final gesture = await tester.startGesture(tester.getCenter(rail));
    await gesture.moveBy(const Offset(-220, 0));
    await tester.pump();
    await gesture.up();
    await tester.pumpAndSettle();

    final railLogs = DebugConsole.entries
        .where((entry) => entry.contains('[BudgetV2AvatarRail]'))
        .toList();
    expect(railLogs, hasLength(2), reason: railLogs.join('\n'));
    expect(
      railLogs.singleWhere((entry) => entry.contains('phase=start')),
      isNotEmpty,
    );
    expect(
      railLogs.singleWhere((entry) => entry.contains('phase=settle')),
      isNotEmpty,
    );
    expect(
      railLogs.any((entry) => entry.contains('phase=tick')),
      isFalse,
      reason: 'Drag frames must not flood the diagnostic console.',
    );
  });

  testWidgets('a restarted drag suppresses the stale release settlement', (
    tester,
  ) async {
    final settled = <int>[];
    await tester.pumpWidget(host(width: 328, onSettled: settled.add));

    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    final first = await tester.startGesture(tester.getCenter(rail));
    await first.moveBy(const Offset(-20, 0));
    await first.moveBy(const Offset(-90, 0));
    await first.up();
    await tester.pump(const Duration(milliseconds: 16));

    final second = await tester.startGesture(tester.getCenter(rail));
    await second.moveBy(const Offset(20, 0));
    await second.moveBy(const Offset(90, 0));
    await second.up();
    await tester.pumpAndSettle();

    expect(settled, hasLength(1));
  });
}
