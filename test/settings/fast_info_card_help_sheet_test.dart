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
      expect(
        find.byKey(const ValueKey('fastinfo-help-card-preview-mai_koltes')),
        findsOneWidget,
      );
      expect(find.text('Ez azt mutatja'), findsOneWidget);
      expect(find.text('Így számol'), findsOneWidget);
      expect(find.text('Ha nincs elég adat'), findsOneWidget);
      expect(find.textContaining('Napi plafon'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('body scrolls normally but drags the help sheet at top', (
    tester,
  ) async {
    await _pumpHelpLauncher(tester, 'havi_koltes');

    await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('fastinfo-help-close')), findsNothing);
    final before = _slideCardTranslationY(tester);

    await tester.drag(
      find.byKey(const ValueKey('fastinfo-help-body-havi_koltes')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();
    expect(
      _slideCardTranslationY(tester),
      moreOrLessEquals(before, epsilon: 0.1),
    );
    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('fastinfo-help-drag-handle-havi_koltes')),
      const Offset(0, 180),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
    await tester.pumpAndSettle();
    final reopened = _slideCardTranslationY(tester);
    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('fastinfo-help-body-havi_koltes')),
      ),
    );
    await gesture.moveBy(const Offset(0, 70));
    await tester.pump();
    expect(_slideCardTranslationY(tester), greaterThan(reopened + 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsOneWidget,
    );
  });

  testWidgets('help sheet drag can be cancelled before dismiss threshold', (
    tester,
  ) async {
    await _pumpHelpLauncher(tester, 'havi_koltes');

    await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('fastinfo-help-drag-handle-havi_koltes')),
      const Offset(0, 120),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsOneWidget,
    );

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('fastinfo-help-drag-handle-havi_koltes')),
      ),
    );
    await gesture.moveBy(const Offset(0, 190));
    await tester.pump();
    expect(_slideCardTranslationY(tester), greaterThan(150));
    await gesture.moveBy(const Offset(0, -170));
    await tester.pump();
    expect(_slideCardTranslationY(tester), lessThan(60));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsOneWidget,
    );
  });

  testWidgets('help sheet card handle still supports free drag', (
    tester,
  ) async {
    await _pumpHelpLauncher(tester, 'havi_koltes');

    await tester.tap(find.byKey(const ValueKey('open-fastinfo-help')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('slide-up-menu-transform')),
      findsOneWidget,
    );
    final before = _slideCardTranslationY(tester);

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('fastinfo-help-drag-handle-havi_koltes')),
      ),
    );
    await gesture.moveBy(const Offset(0, 70));
    await tester.pump();
    expect(_slideCardTranslationY(tester), greaterThan(before + 40));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('fastinfo-help-sheet-havi_koltes')),
      findsOneWidget,
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
          find.byKey(ValueKey('fastinfo-help-body-${card.id}')),
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
      find.byKey(const ValueKey('fastinfo-help-body-havi_koltes')),
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

double _slideCardTranslationY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey('slide-up-menu-transform')),
  );
  return transform.transform.getTranslation().y;
}
