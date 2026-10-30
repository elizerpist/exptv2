import 'package:fluvi/features/manual_transactions/presentation/creation_selector_sheet.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('creation selector is compact and returns the manual action', (
    tester,
  ) async {
    CreationSelectorAction? selected;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () async {
                selected = await showCreationSelectorSheet(
                  context,
                  direction: LedgerDirection.expense,
                );
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Új kiadás'), findsOneWidget);
    expect(find.text('Manuális tranzakció'), findsOneWidget);
    expect(find.text('Ismétlődő tranzakció'), findsOneWidget);
    expect(find.text('Push profil létrehozása'), findsOneWidget);
    expect(find.text('Egyszeri kiadás rögzítése.'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('creation-action-manual')),
      findsOneWidget,
    );

    await tester.tap(find.text('Manuális tranzakció'));
    await tester.pumpAndSettle();
    expect(selected, CreationSelectorAction.manualTransaction);
  });

  testWidgets('creation selector keeps the FAB direction in its title', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCreationSelectorSheet(
                context,
                direction: LedgerDirection.income,
              ),
              child: const Text('open income'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open income'));
    await tester.pumpAndSettle();
    expect(find.text('Új bevétel'), findsOneWidget);
    expect(find.text('Egyszeri bevétel rögzítése.'), findsOneWidget);
    expect(find.text('Időzítve vagy banki értesítés alapján.'), findsOneWidget);
  });

  testWidgets('income creation selector visual reference', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          backgroundColor: const Color(0xffedf1f6),
          body: Builder(
            builder: (context) => FilledButton(
              onPressed: () => showCreationSelectorSheet(
                context,
                direction: LedgerDirection.income,
              ),
              child: const Text('open visual'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open visual'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byKey(const ValueKey('creation-selector-sheet-boundary')),
      matchesGoldenFile(
        '../../goldens/manual_transaction_creation_selector_income.png',
      ),
    );
  });

  testWidgets('modified direction palettes reach the primary FAB action', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => Column(
              children: [
                FilledButton(
                  onPressed: () => showCreationSelectorSheet(
                    context,
                    direction: LedgerDirection.income,
                    directionColorProfile: FluviDirectionColorProfile.vivid,
                  ),
                  child: const Text('open vivid income'),
                ),
                FilledButton(
                  onPressed: () => showCreationSelectorSheet(
                    context,
                    direction: LedgerDirection.expense,
                    directionColorProfile: FluviDirectionColorProfile.pastel,
                  ),
                  child: const Text('open pastel expense'),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open vivid income'));
    await tester.pumpAndSettle();
    expect(
      _primaryActionGradient(tester),
      FluviDirectionColorPaletteCatalog.income(
        FluviDirectionColorProfile.vivid,
      ),
    );
    Navigator.of(
      tester.element(find.byKey(const ValueKey('creation-action-manual'))),
    ).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.text('open pastel expense'));
    await tester.pumpAndSettle();
    expect(
      _primaryActionGradient(tester),
      FluviDirectionColorPaletteCatalog.expense(
        FluviDirectionColorProfile.pastel,
      ),
    );
  });
}

LinearGradient _primaryActionGradient(WidgetTester tester) {
  final manualAction = find.byKey(const ValueKey('creation-action-manual'));
  final iconSurface = tester
      .widgetList<Container>(
        find.descendant(of: manualAction, matching: find.byType(Container)),
      )
      .firstWhere(
        (container) =>
            container.decoration is BoxDecoration &&
            (container.decoration! as BoxDecoration).gradient != null,
      );
  return (iconSurface.decoration! as BoxDecoration).gradient! as LinearGradient;
}
