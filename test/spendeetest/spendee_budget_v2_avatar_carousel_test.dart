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
    void Function(int index, bool selected)? onItemBuilt,
    void Function(int index)? onAvatarLeafBuilt,
    VoidCallback? onHostBuilt,
    SpendeeBudgetV2AvatarCarouselItemSizeBuilder? itemSizeBuilder,
    SpendeeBudgetV2AvatarCarouselItemBuilder? customItemBuilder,
    String inheritedValue = 'host',
  }) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            key: const ValueKey('budget-v2-avatar-carousel-test-root'),
            width: width,
            height: 80,
            child: _BuildProbe(
              onBuild: onHostBuilt,
              child: _TestInheritedValue(
                value: inheritedValue,
                child: SpendeeBudgetV2AvatarCarousel(
                  key: const ValueKey('budget-v2-avatar-carousel-test-rail'),
                  itemCount: itemCount,
                  selectedIndex: selectedIndex,
                  externalSelectionEpoch: externalSelectionEpoch,
                  height: 72,
                  slotDistance: 58,
                  centerOffsetBuilder:
                      centerOffsetBuilder ??
                      (logicalOffset) => logicalOffset * 58,
                  itemSizeBuilder:
                      itemSizeBuilder ?? (_, _) => const Size(72, 72),
                  onPreview: onPreview,
                  onSettled: (index, {required directDrag}) {
                    onSettled(index);
                    onDetailedSettled?.call(index, directDrag: directDrag);
                  },
                  onPointerDown: onPointerDown,
                  itemBuilder:
                      customItemBuilder ??
                      (context, index, selected, select) {
                        onItemBuilt?.call(index, selected);
                        return _BuildProbe(
                          key: ValueKey(
                            'budget-v2-avatar-carousel-test-leaf-$index',
                          ),
                          onBuild: onAvatarLeafBuilt == null
                              ? null
                              : () => onAvatarLeafBuilt(index),
                          child: Semantics(
                            button: true,
                            label: 'Avatar $index',
                            child: GestureDetector(
                              key: ValueKey(
                                'budget-v2-avatar-carousel-test-item-$index',
                              ),
                              onTap: select,
                              child: ColoredBox(
                                key: ValueKey(
                                  'budget-v2-avatar-carousel-test-item-$index-'
                                  '${selected ? 'selected' : 'idle'}',
                                ),
                                color: selected
                                    ? Colors.deepPurple
                                    : Colors.grey,
                              ),
                            ),
                          ),
                        );
                      },
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
    'within-slot direct motion repaints without rebuilding retained avatars',
    (tester) async {
      final itemBuilds = <int, int>{};
      final leafBuilds = <int, int>{};
      var hostBuilds = 0;
      await tester.pumpWidget(
        host(
          width: 328,
          itemCount: 10,
          onSettled: (_) {},
          onItemBuilt: (index, _) {
            itemBuilds.update(index, (value) => value + 1, ifAbsent: () => 1);
          },
          onAvatarLeafBuilt: (index) {
            leafBuilds.update(index, (value) => value + 1, ifAbsent: () => 1);
          },
          onHostBuilt: () => hostBuilds += 1,
        ),
      );
      await tester.pump();
      final initialItemBuilds = Map<int, int>.of(itemBuilds);
      final initialLeafBuilds = Map<int, int>.of(leafBuilds);
      final initialHostBuilds = hostBuilds;
      final flow = find.byKey(
        const ValueKey('spendee-budget-v2-avatar-carousel-stack'),
      );
      final priorFlowWidget = tester.widget<Flow>(flow);

      final rail = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-rail'),
      );
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-20, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-8, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-8, 0));
      await tester.pump();

      expect(tester.widget<Flow>(flow), same(priorFlowWidget));
      expect(itemBuilds, initialItemBuilds);
      expect(leafBuilds, initialLeafBuilds);
      expect(
        hostBuilds,
        initialHostBuilds,
        reason:
            'Direct physical movement must stay below the carousel widget '
            'boundary rather than rebuilding host/card/log/store work.',
      );

      await gesture.cancel();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'an index crossing reuses retained slots and builds only changed leaves',
    (tester) async {
      final itemBuilds = <int, int>{};
      await tester.pumpWidget(
        host(
          width: 328,
          itemCount: 10,
          onSettled: (_) {},
          onItemBuilt: (index, _) {
            itemBuilds.update(index, (value) => value + 1, ifAbsent: () => 1);
          },
        ),
      );
      await tester.pump();
      final retained = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-leaf-2'),
      );
      final retainedElement = tester.element(retained);
      final initialItemBuilds = Map<int, int>.of(itemBuilds);

      final rail = find.byKey(
        const ValueKey('budget-v2-avatar-carousel-test-rail'),
      );
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-20, 0));
      await gesture.moveBy(const Offset(-60, 0));
      await tester.pump();

      final rebuiltIndexes = <int>[
        for (final entry in itemBuilds.entries)
          if (entry.value != (initialItemBuilds[entry.key] ?? 0)) entry.key,
      ]..sort();
      expect(
        rebuiltIndexes,
        <int>[0, 1, 4],
        reason:
            'Only the old/new selection presentations and the entering +3 '
            'slot may need a new avatar widget.',
      );
      expect(tester.element(retained), same(retainedElement));

      await gesture.cancel();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'selected and updated item sizes relayout only on widget boundaries',
    (tester) async {
      var selectedSize = const Size(82, 64);
      var idleSize = const Size(38, 32);
      Size sizes(int index, bool selected) =>
          selected ? selectedSize : idleSize;

      await tester.pumpWidget(
        host(
          width: 328,
          itemCount: 10,
          onSettled: (_) {},
          itemSizeBuilder: sizes,
        ),
      );
      await tester.pump();
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('budget-v2-avatar-carousel-test-item-0-selected'),
          ),
        ),
        selectedSize,
      );

      await tester.pumpWidget(
        host(
          width: 328,
          itemCount: 10,
          selectedIndex: 1,
          externalSelectionEpoch: 1,
          onSettled: (_) {},
          itemSizeBuilder: sizes,
        ),
      );
      await tester.pumpAndSettle();
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('budget-v2-avatar-carousel-test-item-0-idle'),
          ),
        ),
        idleSize,
      );
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('budget-v2-avatar-carousel-test-item-1-selected'),
          ),
        ),
        selectedSize,
      );

      selectedSize = const Size(68, 58);
      idleSize = const Size(30, 26);
      await tester.pumpWidget(
        host(
          width: 328,
          itemCount: 10,
          selectedIndex: 1,
          externalSelectionEpoch: 1,
          onSettled: (_) {},
          itemSizeBuilder: sizes,
        ),
      );
      await tester.pump();

      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('budget-v2-avatar-carousel-test-item-0-idle'),
          ),
        ),
        idleSize,
      );
      expect(
        tester.getSize(
          find.byKey(
            const ValueKey('budget-v2-avatar-carousel-test-item-1-selected'),
          ),
        ),
        selectedSize,
      );
    },
  );

  testWidgets(
    'a stable item builder refreshes inherited UI and captured callbacks',
    (tester) async {
      var generation = 'old';
      final taps = <String>[];
      late final SpendeeBudgetV2AvatarCarouselItemBuilder stableBuilder;
      stableBuilder = (context, index, selected, select) {
        final builtGeneration = generation;
        final inheritedValue = _TestInheritedValue.of(context);
        final presentation = '$builtGeneration-$inheritedValue-$index';
        return GestureDetector(
          key: ValueKey('stable-builder-item-$index'),
          onTap: () => taps.add(presentation),
          child: Text(presentation),
        );
      };

      await tester.pumpWidget(
        host(
          width: 328,
          onSettled: (_) {},
          customItemBuilder: stableBuilder,
          inheritedValue: 'first',
        ),
      );
      await tester.pump();
      expect(find.text('old-first-0'), findsOneWidget);

      generation = 'new';
      await tester.pumpWidget(
        host(
          width: 328,
          onSettled: (_) {},
          customItemBuilder: stableBuilder,
          inheritedValue: 'second',
        ),
      );
      await tester.pump();

      expect(find.text('old-first-0'), findsNothing);
      expect(find.text('new-second-0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('stable-builder-item-0')));
      expect(taps, <String>['new-second-0']);
    },
  );

  testWidgets(
    'an inherited-only update invalidates a stable builder presentation',
    (tester) async {
      final inheritedValue = ValueNotifier<String>('first');
      addTearDown(inheritedValue.dispose);
      var generation = 'old';
      final taps = <String>[];
      late final SpendeeBudgetV2AvatarCarouselItemBuilder stableBuilder;
      stableBuilder = (context, index, selected, select) {
        final presentation =
            '$generation-${_TestInheritedValue.of(context)}-$index';
        return GestureDetector(
          key: ValueKey('inherited-only-item-$index'),
          onTap: () => taps.add(presentation),
          child: Text(presentation),
        );
      };
      final retainedCarousel = SizedBox(
        width: 328,
        height: 80,
        child: SpendeeBudgetV2AvatarCarousel(
          itemCount: 7,
          selectedIndex: 0,
          height: 72,
          slotDistance: 58,
          itemSizeBuilder: (_, _) => const Size(72, 72),
          itemBuilder: stableBuilder,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ValueListenableBuilder<String>(
              valueListenable: inheritedValue,
              child: retainedCarousel,
              builder: (context, value, child) =>
                  _TestInheritedValue(value: value, child: child!),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(find.text('old-first-0'), findsOneWidget);

      generation = 'new';
      inheritedValue.value = 'second';
      await tester.pump();

      expect(find.text('old-first-0'), findsNothing);
      expect(find.text('new-second-0'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('inherited-only-item-0')));
      expect(taps, <String>['new-second-0']);
    },
  );

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
    final semantics = tester.ensureSemantics();
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
    expect(
      find.bySemanticsLabel('Avatar 3'),
      findsNothing,
      reason: 'A fully transparent retained edge slot is not accessible.',
    );
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-avatar-carousel-stack')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-budget-v2-avatar-carousel-scale-3')),
      findsOneWidget,
    );
    final priorElement = tester.element(entering);
    final initialCenter = tester.getCenter(entering);

    final rail = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-rail'),
    );
    final gesture = await tester.startGesture(tester.getCenter(rail));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-40, 0));
    await tester.pump();

    expect(
      tester.getCenter(entering).dx,
      lessThan(initialCenter.dx),
      reason:
          'The retained entering child must move under the Flow transform '
          'without needing a replacement Opacity/Positioned widget.',
    );
    expect(
      entering.hitTestable(),
      findsOneWidget,
      reason:
          'Once Flow paints the entering slot visibly inside the rail, its '
          'tap target must participate in hit testing.',
    );
    expect(
      find.bySemanticsLabel('Avatar 3'),
      findsOneWidget,
      reason:
          'The visible entering slot must expose its retained child semantics.',
    );
    final firstSemanticRect = _transformedSemanticsRect(tester, entering);
    await gesture.moveBy(const Offset(-8, 0));
    await tester.pump();
    final secondSemanticRect = _transformedSemanticsRect(tester, entering);
    expect(
      secondSemanticRect.center.dx,
      closeTo(firstSemanticRect.center.dx - 8, .01),
      reason:
          'Accessibility geometry must follow the same paint-only residual '
          'transform as the retained avatar and its hit target.',
    );

    await gesture.moveBy(const Offset(-58, 0));
    await tester.pump();
    expect(tester.element(entering), same(priorElement));
    await gesture.cancel();
    semantics.dispose();
  });

  testWidgets('keeps authored outer spacing when the rail is widened', (
    tester,
  ) async {
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
    final root = find.byKey(
      const ValueKey('budget-v2-avatar-carousel-test-root'),
    );
    final rootCenter = tester.getCenter(root).dx;
    expect(tester.getCenter(visibleOuter).dx - rootCenter, closeTo(144, .01));
    expect(
      tester.getCenter(retainedEntry).dx - rootCenter,
      closeTo(202, .01),
      reason:
          'The retained +3 child keeps the authored +2 outer gap plus one '
          'slot while its opacity is applied directly during Flow paint.',
    );
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

class _BuildProbe extends StatelessWidget {
  const _BuildProbe({super.key, required this.child, this.onBuild});

  final Widget child;
  final VoidCallback? onBuild;

  @override
  Widget build(BuildContext context) {
    onBuild?.call();
    return child;
  }
}

class _TestInheritedValue extends InheritedWidget {
  const _TestInheritedValue({required this.value, required super.child});

  final String value;

  static String of(BuildContext context) {
    return context
        .dependOnInheritedWidgetOfExactType<_TestInheritedValue>()!
        .value;
  }

  @override
  bool updateShouldNotify(_TestInheritedValue oldWidget) =>
      value != oldWidget.value;
}

Rect _transformedSemanticsRect(WidgetTester tester, Finder finder) {
  final node = tester.getSemantics(finder);
  return MatrixUtils.transformRect(
    node.transform ?? Matrix4.identity(),
    node.rect,
  );
}
