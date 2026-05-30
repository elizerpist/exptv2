import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_card.dart';
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('header balance label and value are shifted down', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '123 Ft',
            onCategoryPressed: () {},
            onExpandPressed: () {},
          ),
        ),
      ),
    );

    expect(TransactionHeaderMetrics.balanceLabelTop, 112);
    expect(TransactionHeaderMetrics.balanceTop, 142);
  });

  testWidgets('header card copies stage0 layout and controls', (tester) async {
    var categoryPressed = false;
    var expandPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '-7 080 Ft',
            onCategoryPressed: () => categoryPressed = true,
            onExpandPressed: () => expandPressed = true,
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('transaction-header-card')))
          .height,
      TransactionHeaderMetrics.cardHeight,
    );
    expect(find.text('ExpenseTracker'), findsOneWidget);
    expect(find.text('Egyenleg'), findsOneWidget);
    expect(find.text('-7 080 Ft'), findsOneWidget);

    expect(find.byKey(const ValueKey('header-calendar-button')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.tap(find.byKey(const ValueKey('header-expand-button')));

    expect(categoryPressed, isTrue);
    expect(expandPressed, isTrue);
  });

  testWidgets('header renders taller magnet strip height', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '-7 080 Ft',
            onCategoryPressed: () {},
            onExpandPressed: () {},
          ),
        ),
      ),
    );

    expect(
      tester.getSize(find.byKey(const ValueKey('magnet-strip-fade'))).height,
      TransactionHeaderMetrics.magnetHeight,
    );
  });
}
