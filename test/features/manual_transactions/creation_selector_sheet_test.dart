import 'package:fluvi/features/manual_transactions/presentation/creation_selector_sheet.dart';
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
    expect(find.text('Új kiadási tranzakció létrehozása'), findsOneWidget);
    expect(find.text('Manuális tranzakció'), findsOneWidget);
    expect(find.text('Ismétlődő tranzakció'), findsOneWidget);
    expect(find.text('Push profil'), findsOneWidget);

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
    expect(find.text('Új bevételi tranzakció létrehozása'), findsOneWidget);
  });
}
