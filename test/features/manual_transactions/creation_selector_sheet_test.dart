import 'package:fluvi/features/manual_transactions/presentation/creation_selector_sheet.dart';
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
                selected = await showCreationSelectorSheet(context);
              },
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.text('Új létrehozása'), findsOneWidget);
    expect(find.text('Manuális tranzakció'), findsOneWidget);
    expect(find.text('Ismétlődő tranzakció'), findsOneWidget);
    expect(find.text('Push profil'), findsOneWidget);

    await tester.tap(find.text('Manuális tranzakció'));
    await tester.pumpAndSettle();
    expect(selected, CreationSelectorAction.manualTransaction);
  });
}
