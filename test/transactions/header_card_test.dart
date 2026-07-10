import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/widgets/header_card/header_fast_info_surface.dart';
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
    expect(TransactionHeaderMetrics.expandedSlideDistance, 144);
    expect(
      TransactionHeaderMetrics.cardHeight -
          TransactionHeaderMetrics.expandedSlideDistance,
      44,
    );
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

  testWidgets('header card can show stats feedback without visibility button', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            labelText: 'HEATMAP',
            balanceText: '96 forró nap 5k felett',
            showBalanceVisibilityButton: false,
            onCategoryPressed: () {},
            onExpandPressed: () {},
          ),
        ),
      ),
    );

    expect(find.text('HEATMAP'), findsOneWidget);
    expect(find.text('96 forró nap 5k felett'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('header-balance-visibility-button')),
      findsNothing,
    );
  });

  testWidgets('ambulance skin uses white header with yellow veil and magnet', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            magnetType: MagnetType.ambulanceSkin,
            balanceText: '123 Ft',
            totalIncome: 300,
            totalExpense: -100,
            onCategoryPressed: () {},
            onExpandPressed: () {},
          ),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('transaction-header-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;

    expect(decoration.color, Colors.white);
    final veil = tester.widget<Opacity>(
      find.byKey(const ValueKey('header-ambulance-yellow-veil')),
    );
    expect(veil.opacity, 0.5);
    expect(
      find.byKey(const ValueKey('magnet-strip-ambulanceSkin')),
      findsOneWidget,
    );
  });

  testWidgets('ambulance skin colors resting fast info header surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Stack(
            children: [
              HeaderFastInfoSurface(
                visibleFastInfoExtent: 0,
                cardColor: Colors.white,
                ambulanceSkin: true,
                fastInfo: const SizedBox.shrink(),
                header: TransactionHeaderCard(
                  magnetType: MagnetType.ambulanceSkin,
                  drawSurface: false,
                  balanceText: '123 Ft',
                  totalIncome: 300,
                  totalExpense: -100,
                  onCategoryPressed: () {},
                  onExpandPressed: () {},
                ),
              ),
            ],
          ),
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('header-fast-info-surface')),
    );
    final decoration = surface.decoration as BoxDecoration;

    expect(decoration.color, Colors.white);
    final veil = tester.widget<Opacity>(
      find.byKey(const ValueKey('header-ambulance-fast-info-yellow-veil')),
    );
    expect(veil.opacity, 0.5);
    expect(
      find.byKey(const ValueKey('magnet-strip-ambulanceSkin')),
      findsOneWidget,
    );
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

  testWidgets('header category button uses add category avatar press surface', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '123 Ft',
            accent: AppColors.primary,
            buttonSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onCategoryPressed: () {},
            onExpandPressed: () {},
          ),
        ),
      ),
    );

    final button = find.byKey(const ValueKey('header-category-button'));
    final surface = find.byKey(
      const ValueKey('header-category-button-surface'),
    );
    final gesture = await tester.startGesture(tester.getCenter(button));
    await tester.pump();

    final pressedDecoration =
        tester.widget<Container>(surface).decoration! as BoxDecoration;
    final expectedPressedDecoration = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.raisedInset,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
      pressed: true,
      primary: true,
      primaryColor: AppColors.primary,
    );
    expect(pressedDecoration, expectedPressedDecoration);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(ExpenseSurface.pressDuration);

    final restingDecoration =
        tester.widget<Container>(surface).decoration! as BoxDecoration;
    final expectedRestingDecoration = ExpenseSurface.decoration(
      style: ExpenseSurfaceInteraction.raisedInset,
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(24),
      primary: true,
      primaryColor: AppColors.primary,
    );
    expect(restingDecoration, expectedRestingDecoration);
  });

  testWidgets('header notification bell renders unread badge and opens', (
    tester,
  ) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHeaderCard(
            balanceText: '123 Ft',
            onCategoryPressed: () {},
            onExpandPressed: () {},
            onNotificationPressed: () => opened = true,
            notificationUnreadCount: 4,
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('header-notification-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('header-notification-unread-badge')),
      findsOneWidget,
    );
    expect(find.text('4'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('header-notification-button')));
    expect(opened, isTrue);
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
