import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/settings/widgets/options/fast_info_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
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

  testWidgets('dropping onto occupied slot replaces old card and returns old card to pool', (
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
  });
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
  await tester.dragFrom(dragStart, dropCenter - dragStart);
  await tester.pumpAndSettle();
}
