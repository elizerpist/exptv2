import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/settings/widgets/options/fast_info_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('layout selector switches preview without changing cards', (
    tester,
  ) async {
    FastInfoConfig? changed;
    await tester.pumpWidget(
      _subject(
        config: FastInfoConfig.defaults(),
        onChanged: (value) => changed = value,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('fastinfo-layout-six-boxes')));
    await tester.pumpAndSettle();

    expect(changed?.layoutMode, FastInfoLayoutMode.sixBoxes);
    expect(
      changed?.pills.map((slot) => slot?.id),
      FastInfoConfig.defaults().pills.map((slot) => slot?.id),
    );
    expect(
      find.byKey(const ValueKey('fastinfo-upper-box-slot-0')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('fastinfo-pill-slot-0')), findsNothing);
  });

  testWidgets('pool and assigned card taps open help', (tester) async {
    await tester.pumpWidget(_subject(config: FastInfoConfig.defaults()));

    await tester.tap(
      find.byKey(const ValueKey('fastinfo-pool-card-megtakaritas')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-megtakaritas')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('fastinfo-help-close')));
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fastinfo-pill-slot-0')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsOneWidget,
    );
  });

  testWidgets('clear button does not open card help', (tester) async {
    FastInfoConfig? changed;
    await tester.pumpWidget(
      _subject(
        config: FastInfoConfig.defaults(),
        onChanged: (value) => changed = value,
      ),
    );

    await tester.tap(find.byKey(const ValueKey('fastinfo-clear-pill-0')));
    await tester.pumpAndSettle();

    expect(changed?.pills[0], isNull);
    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsNothing,
    );
  });

  testWidgets('assigned cards disappear from pool and clear returns them', (
    tester,
  ) async {
    FastInfoConfig? changed;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: FastInfoOptionsPanel(
              config: FastInfoConfig(
                pills: const [null, null, null],
                boxes: const [null, null, null],
              ),
              onChanged: (config) => changed = config,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')),
      findsOneWidget,
    );

    await _dragCardToPill(tester, 'mai_koltes', 0);

    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-mai_koltes')),
      findsNothing,
    );
    expect(changed?.pills[0]?.id, 'mai_koltes');
    expect(
      find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('fastinfo-clear-pill-0')));
    await tester.pumpAndSettle();

    expect(changed?.pills[0], isNull);
    expect(
      find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')),
      findsOneWidget,
    );
  });

  testWidgets(
    'dropping onto occupied slot replaces old card and returns old card to pool',
    (tester) async {
      FastInfoConfig? changed;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: FastInfoOptionsPanel(
                config: FastInfoConfig(
                  pills: const [null, null, null],
                  boxes: const [null, null, null],
                ),
                onChanged: (config) => changed = config,
              ),
            ),
          ),
        ),
      );

      await _dragCardToPill(tester, 'mai_koltes', 0);
      await _dragCardToPill(tester, 'havi_koltes', 0);

      expect(changed?.pills[0]?.id, 'havi_koltes');
      expect(
        find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-pool-card-havi_koltes')),
        findsNothing,
      );
    },
  );

  testWidgets('preview halves title gap and keeps menu above bottom nav', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: FastInfoOptionsPanel(
              config: FastInfoConfig.defaults(),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final panelTop = tester
        .getTopLeft(find.byKey(const ValueKey('fast-info-panel')))
        .dy;
    final firstPillTop = tester
        .getTopLeft(find.byKey(const ValueKey('fastinfo-pill-slot-0')))
        .dy;
    expect(firstPillTop - panelTop, 27);

    final pool = tester.widget<GridView>(
      find.byKey(const ValueKey('fastinfo-card-pool')),
    );
    final padding = pool.padding! as EdgeInsets;
    expect(padding.bottom, 96);
  });

  testWidgets(
    'preview uses live-like metrics instead of catalog placeholders',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 780,
              child: FastInfoOptionsPanel(
                config: FastInfoConfig.defaults(),
                onChanged: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('184k'), findsNothing);
      expect(find.text('27k'), findsWidgets);
      expect(
        tester.getSize(find.byKey(const ValueKey('fast-info-panel'))).height,
        328,
      );
      expect(find.text('Nincs adat'), findsNothing);
      expect(find.textContaining('Debug'), findsNothing);
      final pool = tester.widget<GridView>(
        find.byKey(const ValueKey('fastinfo-card-pool')),
      );
      final delegate = pool.childrenDelegate as SliverChildBuilderDelegate;
      expect(delegate.childCount, 12);
    },
  );

  testWidgets('pool cards require a longer haptic long press before dragging', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: FastInfoOptionsPanel(
              config: FastInfoConfig(
                pills: const [null, null, null],
                boxes: const [null, null, null],
              ),
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final draggable = tester.widget<LongPressDraggable<String>>(
      find.ancestor(
        of: find.byKey(const ValueKey('fastinfo-pool-card-mai_koltes')),
        matching: find.byType(LongPressDraggable<String>),
      ),
    );

    expect(draggable.delay, const Duration(milliseconds: 650));
    expect(draggable.hapticFeedbackOnStart, isTrue);
  });
}

Widget _subject({
  required FastInfoConfig config,
  ValueChanged<FastInfoConfig>? onChanged,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 390,
        height: 780,
        child: FastInfoOptionsPanel(
          config: config,
          onChanged: onChanged ?? (_) {},
        ),
      ),
    ),
  );
}

Future<void> _dragCardToPill(
  WidgetTester tester,
  String cardId,
  int slotIndex,
) async {
  final cardFinder = find.byKey(ValueKey('fastinfo-pool-card-$cardId'));
  await tester.ensureVisible(cardFinder);
  await tester.pumpAndSettle();
  final dragStart = tester.getCenter(cardFinder);
  final dropCenter = tester.getCenter(
    find.byKey(ValueKey('fastinfo-pill-drop-$slotIndex')),
  );
  final gesture = await tester.startGesture(dragStart);
  await tester.pump(const Duration(milliseconds: 700));
  await gesture.moveTo(dropCenter);
  await gesture.up();
  await tester.pumpAndSettle();
}
