import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host({
    required double width,
    required ValueChanged<int> onSettled,
    int itemCount = 7,
    void Function(int index, {required bool directDrag})? onPreview,
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
              selectedIndex: 0,
              height: 72,
              slotDistance: 58,
              centerOffsetBuilder: (logicalOffset) => logicalOffset * 58,
              itemSizeBuilder: (_, _) => const Size(72, 72),
              onPreview: onPreview,
              onSettled: onSettled,
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
