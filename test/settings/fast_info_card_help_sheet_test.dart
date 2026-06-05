import 'package:exptv2/features/settings/models/fast_info_card_catalog.dart';
import 'package:exptv2/features/settings/widgets/options/fast_info_card_help_sheet.dart';
import 'package:exptv2/features/transactions/data/fast_info_preview_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'opens annotated help sheet with real previews and Hungarian copy',
    (tester) async {
      await _pumpHelpLauncher(tester, 'mai_koltes');

      await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('fastinfo-help-sheet-mai_koltes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-help-pill-mai_koltes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-help-box-mai_koltes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-help-pill-arrows-mai_koltes')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('fastinfo-help-box-arrows-mai_koltes')),
        findsOneWidget,
      );
      expect(find.text('Számítás'), findsOneWidget);
      expect(find.text('Ha nincs elég adat'), findsOneWidget);
      expect(find.textContaining('Napi plafon'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('close button dismisses the help sheet', (tester) async {
    await _pumpHelpLauncher(tester, 'mai_koltes');

    await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('fastinfo-help-close')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-mai_koltes')),
      findsNothing,
    );
  });

  for (final card in fastInfoCardCatalog) {
    for (final width in <double>[320, 600]) {
      testWidgets('help sheet for ${card.id} fits at width $width', (
        tester,
      ) async {
        await _pumpHelpLauncher(tester, card.id, width: width);

        await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
        await tester.pumpAndSettle();
        await tester.drag(
          find.byKey(ValueKey('fastinfo-help-sheet-${card.id}')),
          const Offset(0, -800),
        );
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  }

  testWidgets('help sheet tolerates large text scaling', (tester) async {
    await _pumpHelpLauncher(tester, 'havi_koltes', textScale: 1.4);

    await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
    await tester.pumpAndSettle();
    await tester.drag(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      const Offset(0, -900),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpHelpLauncher(
  WidgetTester tester,
  String cardId, {
  double width = 390,
  double textScale = 1,
}) async {
  final metrics = buildFastInfoPreviewMetrics();
  final card = fastInfoCardById(cardId)!;
  await tester.pumpWidget(
    MediaQuery(
      data: MediaQueryData(
        size: Size(width, 820),
        textScaler: TextScaler.linear(textScale),
      ),
      child: MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) {
              return TextButton(
                key: const ValueKey('open-fastinfo-help'),
                onPressed: () => showFastInfoCardHelpSheet(
                  context,
                  card: card,
                  metric: metrics[card.id],
                ),
                child: const Text('Open'),
              );
            },
          ),
        ),
      ),
    ),
  );
}
