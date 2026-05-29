import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/models/fast_info_config.dart';
import 'package:exptv2/features/transactions/widgets/header_card/fast_info_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('same card renders compact value in pill and richer content in box', (
    tester,
  ) async {
    final card = fastInfoCardById('havi_koltes')!;
    final config = FastInfoConfig(
      pills: [FastInfoSlot.fromCard(card, FastInfoSlotType.pill), null, null],
      boxes: [FastInfoSlot.fromCard(card, FastInfoSlotType.box), null, null],
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: FastInfoPanel(config: config)),
      ),
    );

    expect(find.text('184k'), findsOneWidget);
    expect(find.text('Havi költés'), findsOneWidget);
    expect(find.text('184k / 250k'), findsOneWidget);
    expect(find.text('A havi keret 74%-a'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('fastinfo-visual-progress-havi_koltes')),
      findsOneWidget,
    );
  });

  testWidgets('clear buttons are shown only when callbacks are provided', (
    tester,
  ) async {
    final config = FastInfoConfig.defaults();

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: FastInfoPanel(config: config))),
    );
    expect(find.byKey(const ValueKey('fastinfo-clear-pill-0')), findsNothing);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: FastInfoPanel(
            config: config,
            onClearPillSlot: (_) {},
            onClearBoxSlot: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('fastinfo-clear-pill-0')), findsOneWidget);
    expect(find.byKey(const ValueKey('fastinfo-clear-box-0')), findsOneWidget);
  });

  testWidgets('drag target callback receives dropped card id', (tester) async {
    String? dropped;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              FastInfoPanel(
                config: FastInfoConfig(
                  pills: const [null, null, null],
                  boxes: const [null, null, null],
                ),
                onDropPillCard: (index, cardId) => dropped = '$index:$cardId',
              ),
              Positioned(
                left: 24,
                top: 260,
                child: Draggable<String>(
                  data: 'mai_koltes',
                  feedback: const Material(child: Text('Mai költés')),
                  child: const SizedBox(
                    width: 80,
                    height: 40,
                    child: Text('Drag'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final dragStart = tester.getCenter(find.text('Drag'));
    final dropCenter = tester.getCenter(find.byKey(const ValueKey('fastinfo-pill-drop-0')));
    await tester.dragFrom(dragStart, dropCenter - dragStart);
    await tester.pumpAndSettle();

    expect(dropped, '0:mai_koltes');
  });
}
