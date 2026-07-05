import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_card.dart';
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_metrics.dart';
import 'package:exptv2/features/transactions/widgets/transaction_menu_metrics.dart';
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

    expect(TransactionHeaderMetrics.cardHeight, 188);
    expect(TransactionHeaderMetrics.balanceLabelTop, 112);
    expect(TransactionHeaderMetrics.balanceTop, 134);
    expect(TransactionHeaderMetrics.titleTop, 35);
    expect(TransactionHeaderMetrics.cameraTop, 62);
    expect(TransactionHeaderMetrics.magnetTop, 41);
    expect(TransactionHeaderMetrics.categoryButtonTop, 112);
    expect(
      TransactionHeaderMetrics.contentTop +
          TransactionMenuMetrics.typePillTopPadding -
          TransactionHeaderMetrics.cardHeight,
      TransactionMenuMetrics.typePillBottomPadding,
    );
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
    expect(find.byKey(const ValueKey('header-card-drag-handle')), findsNothing);

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
    final chipContainer = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('header-budget-trigger-chip')),
        matching: find.byType(Container),
      ),
    );
    final decoration = chipContainer.decoration! as BoxDecoration;
    expect(decoration.color, const Color(0xFFFBBF24));
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
