import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_card.dart';
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('header balance label and value sit higher in the card', (
    tester,
  ) async {
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
    expect(TransactionHeaderMetrics.balanceTop, 134);
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
    expect(find.byKey(const ValueKey('header-expand-button')), findsNothing);
    expect(
      find.byKey(const ValueKey('header-expand-button-hit-area')),
      findsNothing,
    );
    expect(find.byIcon(Icons.photo_camera_outlined), findsNothing);
    expect(
      find.byKey(const ValueKey('header-budget-trigger-chip')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('header-card-drag-handle')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.tap(find.byKey(const ValueKey('header-budget-trigger-chip')));

    expect(categoryPressed, isTrue);
    expect(expandPressed, isTrue);
  });

  testWidgets('header budget trigger chip is compact', (tester) async {
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

    expect(
      tester.getSize(find.byKey(const ValueKey('header-budget-trigger-chip'))),
      const Size(36, 28),
    );
    expect(find.byIcon(Icons.account_balance_wallet_outlined), findsOneWidget);
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
