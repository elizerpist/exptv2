import 'dart:async';

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/data/limit_allocation_manager.dart';
import 'package:exptv2/features/transactions/models/backheader_budget_item.dart';
import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/overview_budget_data.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/header_card/budget_bar_geometry.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_budget_bar.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_budget_stage.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_limit_editor_sheet.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_limit_partition_bar.dart';
import 'package:exptv2/features/transactions/widgets/header_card/category_limit_slider.dart';
import 'package:exptv2/features/transactions/widgets/header_card/magnet_strip.dart';
import 'package:exptv2/features/transactions/widgets/header_card/transaction_header_metrics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('budget bar geometry is 20 percent smaller with centered frame', () {
    expect(BudgetBarGeometry.barHeight, moreOrLessEquals(43.2));
    expect(BudgetBarGeometry.frameHeight, moreOrLessEquals(51.84));
    expect(BudgetBarGeometry.frameHeight, lessThan(54));
    expect(BudgetBarGeometry.barCenterY, 112);
    expect(BudgetBarGeometry.barTop + BudgetBarGeometry.barHeight / 2, 112);
    expect(BudgetBarGeometry.frameTop + BudgetBarGeometry.frameHeight / 2, 112);
  });

  testWidgets('category budget stage shows labels and swipes category bars', (
    tester,
  ) async {
    BackheaderBudgetItem? tapped;
    final bars = [
      barFixture(6, 'Food', 100, 150),
      barFixture(7, 'Travel', 40, 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (item) => tapped = item,
            ),
          ),
        ),
      ),
    );

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-progress-fill')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-budget-dot-0')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('category-budget-bar')),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('40 Ft'), findsOneWidget);
    expect(find.byKey(const ValueKey('category-progress-fill')), findsNothing);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    expect(tapped?.category?.title, 'Travel');
  });

  testWidgets('classic backheader style keeps current bar renderer', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 100, 150)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.classic,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('category-budget-bar')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('backheader-experimental-surface')),
      findsNothing,
    );
  });

  testWidgets('backheader uses configured app background color', (
    tester,
  ) async {
    const backgroundColor = Color(0xFFEFF7ED);
    final bars = [barFixture(6, 'Food', 100, 150)];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backgroundColor: backgroundColor,
              backheaderStyle: BackheaderStyle.classic,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final classicSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('category-budget-stage-background')),
    );
    expect((classicSurface.decoration as BoxDecoration).color, backgroundColor);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backgroundColor: backgroundColor,
              backheaderStyle: BackheaderStyle.heroToken,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final heroSurface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('backheader-style-heroToken')),
    );
    expect((heroSurface.decoration as BoxDecoration).color, backgroundColor);
  });

  testWidgets('backheader colored bars use raised surfaces in neumorphism', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 100, 150)];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 300,
          child: CategoryBudgetStage(
            items: bars.map(BackheaderBudgetItem.category).toList(),
            categoryBars: bars,
            periodLabel: 'Június',
            activeKey: null,
            surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onActiveItemChanged: (_) {},
            onItemTap: (_) {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-bar-surface-0')),
      findsOneWidget,
    );
  });

  testWidgets('experimental backheader style uses experimental surface', (
    tester,
  ) async {
    BackheaderBudgetItem? tapped;
    final bars = [barFixture(6, 'Food', 100, 150)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.heroToken,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (item) => tapped = item,
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-experimental-surface')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-style-heroToken')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-partition-strip')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-budget-bar')), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('backheader-experimental-surface')),
    );
    expect(tapped?.category?.title, 'Food');
  });

  testWidgets('experimental backheader styles render distinct surfaces', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 100, 150)];
    for (final style in BackheaderStyle.values.where(
      (style) => style != BackheaderStyle.classic,
    )) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 300,
              child: CategoryBudgetStage(
                backheaderStyle: style,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(ValueKey('backheader-style-${style.nativeValue}')),
        findsOneWidget,
      );
      if (style == BackheaderStyle.orbitBudget) {
        expect(find.text('Food'), findsOneWidget);
        expect(
          find.byKey(const ValueKey('backheader-orbit-limit-pill')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('backheader-orbit-amount-slash')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('backheader-orbit-spent-text')),
          findsOneWidget,
        );
        expect(find.text('100 Ft'), findsOneWidget);
        final input = tester.widget<TextField>(
          find.byKey(const ValueKey('backheader-orbit-amount-input')),
        );
        expect(input.controller!.text, '150');
      } else if (style == BackheaderStyle.centerBadgeBudget) {
        expect(
          find.byKey(const ValueKey('backheader-center-budget-button')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('backheader-center-progress-ring')),
          findsOneWidget,
        );
        expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
      } else {
        expect(find.text('Food'), findsOneWidget);
        expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
      }
    }
  });

  testWidgets('orbitBudget renders icon title amount and real partition bar', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-style-orbitBudget-content')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('backheader-orbit-icon')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('backheader-orbit-title')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-orbit-amount')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-orbit-handle')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-partition-strip')),
      findsNothing,
    );

    final icon = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-icon')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-title')),
    );
    final amount = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-amount')),
    );
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
    );
    final inputRect = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
    );
    final ring = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
    );
    final pill = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-limit-pill')),
    );
    final spent = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-spent-text')),
    );
    final slash = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-amount-slash')),
    );
    final partition = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    expect(icon.left, lessThan(title.left));
    expect(amount.top, greaterThan(partition.bottom));
    expect(amount.left, lessThan(title.left));
    final previousTrackHeight = MagnetStripPainter.visualTrackHeight(
      MagnetType.fade,
      TransactionHeaderMetrics.magnetHeight,
    );
    final expectedTrackHeight = previousTrackHeight * 0.5103;
    final expectedPartitionTop =
        TransactionHeaderMetrics.magnetTop +
        TransactionHeaderMetrics.magnetHeight / 2 -
        previousTrackHeight / 2;
    final expectedOrbitTop =
        TransactionHeaderMetrics.cardHeight -
        TransactionHeaderMetrics.expandedSlideDistance +
        10;
    expect(partition.top, moreOrLessEquals(expectedPartitionTop, epsilon: 0.1));
    expect(
      partition.height,
      moreOrLessEquals(expectedTrackHeight, epsilon: 0.1),
    );
    expect(icon.top, moreOrLessEquals(expectedOrbitTop, epsilon: 0.1));
    expect(expectedOrbitTop, moreOrLessEquals(54, epsilon: 0.1));
    expect(ring.painter, isNotNull);
    expect(ring.child, isNotNull);
    final ringSize = tester.getSize(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
    );
    expect(ringSize.width, greaterThan(0));
    expect(ringSize.width, moreOrLessEquals(icon.width, epsilon: 0.1));
    expect(input.controller!.text, '150');
    expect(input.style!.fontSize, moreOrLessEquals(16.8, epsilon: 0.01));
    expect(input.cursorColor, AppColors.white);
    expect(input.decoration!.filled, isFalse);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('backheader-orbit-spent-text')),
          )
          .data,
      '100 Ft',
    );
    final partitionContainer = tester.widget<Container>(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    final foreground =
        partitionContainer.foregroundDecoration! as BoxDecoration;
    final border = foreground.border! as Border;
    expect(foreground.borderRadius, isNull);
    expect(border.top.width, moreOrLessEquals(1.6, epsilon: 0.01));
    expect(border.bottom.width, moreOrLessEquals(1.6, epsilon: 0.01));
    expect(border.left.style, BorderStyle.none);
    expect(border.right.style, BorderStyle.none);
    expect(spent.left, lessThan(slash.left));
    expect(slash.left, lessThan(pill.left));
    expect(inputRect.center.dx, moreOrLessEquals(pill.center.dx, epsilon: 1));
    expect(spent.center.dy, moreOrLessEquals(pill.center.dy, epsilon: 0.5));
    expect(amount.top - partition.bottom, greaterThan(6));
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('/'), findsOneWidget);
    expect(find.text('100 Ft'), findsOneWidget);
  });

  testWidgets(
    'centerBadgeBudget renders requested badge layout and opens sheet tap',
    (tester) async {
      final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000);
      final food = barFixture(6, 'Food', 100, 500);
      final travel = barFixture(7, 'Travel', 40, 0);
      final books = barFixture(8, 'Books', 30, 100);
      final health = barFixture(9, 'Health', 20, 100);
      BackheaderBudgetItem? tapped;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                centerPartitionRingEnabled: true,
                backgroundColor: const Color(0xfff8fafc),
                items: [
                  BackheaderBudgetItem.overview(overview),
                  BackheaderBudgetItem.category(food),
                  BackheaderBudgetItem.category(travel),
                  BackheaderBudgetItem.category(books),
                  BackheaderBudgetItem.category(health),
                ],
                categoryBars: [food, travel, books, health],
                overviewItems: [overview],
                activeKey: BackheaderBudgetItem.category(food).key,
                periodIncome: 1000,
                onItemTap: (item) => tapped = item,
                onSaveOverview:
                    (_, {required limitAmount, required alertActive}) async {},
                onSaveCategory:
                    (_, {required limitAmount, required alertActive}) async {},
              ),
            ),
          ),
        ),
      );

      final surface = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('backheader-style-centerBadgeBudget')),
      );
      final decoration = surface.decoration as BoxDecoration;
      expect(decoration.color, const Color(0xfff8fafc));
      expect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
        findsNothing,
      );

      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('backheader-center-badge-amount')),
      );
      expect(amount.data, '100 Ft / 500 Ft');
      expect(amount.style?.fontSize, 13);
      expect(amount.style?.color, AppColors.gray800);
      final surfaceRect = tester.getRect(
        find.byKey(const ValueKey('backheader-style-centerBadgeBudget')),
      );
      final amountRect = tester.getRect(
        find.byKey(const ValueKey('backheader-center-badge-amount')),
      );
      expect(amountRect.left - surfaceRect.left, moreOrLessEquals(24));
      expect(amountRect.top - surfaceRect.top, lessThanOrEqualTo(28));
      expect(find.byKey(const ValueKey('category-budget-dot-0')), findsNothing);

      expect(
        find.byKey(const ValueKey('backheader-center-budget-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-badge-title')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('backheader-center-badge-title')),
            )
            .data,
        'Food',
      );
      expect(
        find.byKey(const ValueKey('backheader-center-progress-ring')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-partition-ring')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-partition-ring')),
        paints
          ..arc(color: food.color)
          ..arc(color: food.color.withValues(alpha: 0.70))
          ..arc(color: books.color)
          ..arc(color: books.color.withValues(alpha: 0.70))
          ..arc(color: health.color)
          ..arc(color: health.color.withValues(alpha: 0.70))
          ..arc(color: travel.color)
          ..arc(color: AppColors.gray200),
      );
      expect(
        find.byKey(const ValueKey('backheader-center-reset-action')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-max-action')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-2')),
        findsOneWidget,
      );

      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('backheader-experimental-surface')),
        ),
      );
      await drag.moveBy(const Offset(-40, 0));
      await tester.pump();
      final draggedSurfaceRect = tester.getRect(
        find.byKey(const ValueKey('backheader-style-centerBadgeBudget')),
      );
      expect(draggedSurfaceRect.left, moreOrLessEquals(surfaceRect.left));
      await drag.cancel();
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('backheader-center-budget-button')),
      );
      expect(tapped?.category?.title, 'Food');
    },
  );

  testWidgets(
    'centerBadgeBudget stacks amount badge title and handle without overlap',
    (tester) async {
      final food = barFixture(6, 'Food', 100, 500);
      final travel = barFixture(7, 'Travel', 40, 0);

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(padding: EdgeInsets.only(top: 35)),
            child: Scaffold(
              body: SizedBox(
                width: 390,
                height: 340,
                child: CategoryBudgetStage(
                  backheaderStyle: BackheaderStyle.centerBadgeBudget,
                  items: [
                    BackheaderBudgetItem.category(food),
                    BackheaderBudgetItem.category(travel),
                  ],
                  categoryBars: [food, travel],
                  activeKey: BackheaderBudgetItem.category(food).key,
                  onItemTap: (_) {},
                ),
              ),
            ),
          ),
        ),
      );

      final surfaceRect = tester.getRect(
        find.byKey(const ValueKey('backheader-style-centerBadgeBudget')),
      );
      final amountRect = tester.getRect(
        find.byKey(const ValueKey('backheader-center-badge-amount')),
      );
      final badgeRect = tester.getRect(
        find.byKey(const ValueKey('backheader-center-budget-button')),
      );
      final titleFinder = find.byKey(
        const ValueKey('backheader-center-badge-title'),
      );
      final titleRect = tester.getRect(titleFinder);
      final title = tester.widget<Text>(titleFinder);
      final handleRect = tester.getRect(
        find.byKey(const ValueKey('backheader-center-handle')),
      );

      expect(amountRect.top - surfaceRect.top, greaterThanOrEqualTo(43));
      expect(badgeRect.top, greaterThan(amountRect.bottom));
      expect(badgeRect.top - amountRect.bottom, lessThanOrEqualTo(18));
      expect(
        badgeRect.top,
        moreOrLessEquals(surfaceRect.top + 65.5, epsilon: 0.75),
      );
      expect(title.style?.fontSize, greaterThanOrEqualTo(14));
      expect(
        titleRect.top,
        moreOrLessEquals(surfaceRect.top + 140, epsilon: 0.75),
      );
      expect(titleRect.top, greaterThanOrEqualTo(badgeRect.bottom + 2));
      expect(titleRect.bottom, lessThanOrEqualTo(handleRect.top - 10));
      expect(
        handleRect.bottom,
        moreOrLessEquals(surfaceRect.bottom - 2, epsilon: 1),
      );
    },
  );

  testWidgets('centerBadgeBudget shows the active period in the top right', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 500);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              periodLabel: '2026 július',
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('backheader-style-centerBadgeBudget')),
    );
    final periodFinder = find.byKey(
      const ValueKey('backheader-center-period-label'),
    );
    expect(periodFinder, findsOneWidget);
    expect(tester.widget<Text>(periodFinder).data, '2026 július');
    final periodRect = tester.getRect(periodFinder);
    expect(periodRect.right, lessThanOrEqualTo(surfaceRect.right - 23));
    expect(periodRect.top - surfaceRect.top, lessThanOrEqualTo(28));
  });

  testWidgets('centerBadgeBudget partition ring follows pending amount map', (
    tester,
  ) async {
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000);
    final food = barFixture(6, 'Food', 100, 500);
    final foodItem = BackheaderBudgetItem.category(food);

    Future<void> pumpStage(Map<String, double> pendingAmountsByKey) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                centerPartitionRingEnabled: true,
                items: [BackheaderBudgetItem.overview(overview), foodItem],
                categoryBars: [food],
                overviewItems: [overview],
                pendingAmountsByKey: pendingAmountsByKey,
                activeKey: foodItem.key,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    await pumpStage(const <String, double>{});
    expect(
      find.byKey(const ValueKey('backheader-center-partition-ring')),
      paints
        ..arc(color: food.color)
        ..arc(color: food.color.withValues(alpha: 0.70))
        ..arc(color: AppColors.gray200),
    );

    await pumpStage(<String, double>{foodItem.key: 1000});
    await tester.pump();

    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('backheader-center-badge-amount')),
          )
          .data,
      '100 Ft / 1 000 Ft',
    );
    expect(
      find.byKey(const ValueKey('backheader-center-partition-ring')),
      isNot(
        paints
          ..arc(color: food.color)
          ..arc(color: food.color.withValues(alpha: 0.70))
          ..arc(color: AppColors.gray200),
      ),
    );
  });

  testWidgets('centerBadgeBudget carousel renders nine fading badge slots', (
    tester,
  ) async {
    final bars = [
      barFixture(6, 'Food', 10, 100),
      barFixture(7, 'Travel', 20, 100),
      barFixture(8, 'Books', 30, 100),
      barFixture(9, 'Health', 40, 100),
      barFixture(10, 'Home', 50, 100),
      barFixture(11, 'Rent', 60, 100),
      barFixture(12, 'Gifts', 70, 100),
      barFixture(13, 'Pets', 80, 100),
      barFixture(14, 'Garden', 90, 100),
    ];
    final selected = <String>[];

    Future<void> pumpStage() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onActiveItemChanged: (item) => selected.add(item.title),
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );
    }

    await pumpStage();
    await tester.tap(
      find.byKey(const ValueKey('backheader-center-preview-next-4')),
    );
    await tester.pumpAndSettle();
    expect(selected.last, 'Home');

    final previousEdge = find.byKey(
      const ValueKey('backheader-center-preview-previous-4'),
    );
    final previousFarthest = find.byKey(
      const ValueKey('backheader-center-preview-previous-3'),
    );
    final previousOuter = find.byKey(
      const ValueKey('backheader-center-preview-previous-2'),
    );
    final previousInner = find.byKey(
      const ValueKey('backheader-center-preview-previous-1'),
    );
    final nextInner = find.byKey(
      const ValueKey('backheader-center-preview-next-1'),
    );
    final nextOuter = find.byKey(
      const ValueKey('backheader-center-preview-next-2'),
    );
    final nextFarthest = find.byKey(
      const ValueKey('backheader-center-preview-next-3'),
    );
    final nextEdge = find.byKey(
      const ValueKey('backheader-center-preview-next-4'),
    );
    expect(previousEdge, findsOneWidget);
    expect(previousFarthest, findsOneWidget);
    expect(previousOuter, findsOneWidget);
    expect(previousInner, findsOneWidget);
    expect(nextInner, findsOneWidget);
    expect(nextOuter, findsOneWidget);
    expect(nextFarthest, findsOneWidget);
    expect(nextEdge, findsOneWidget);
    expect(
      tester.getSize(previousEdge).width,
      lessThan(tester.getSize(previousFarthest).width),
    );
    expect(
      tester.getSize(previousFarthest).width,
      lessThan(tester.getSize(previousOuter).width),
    );
    expect(
      tester.getSize(previousOuter).width,
      lessThan(tester.getSize(previousInner).width),
    );
    expect(
      tester.getSize(nextOuter).width,
      lessThan(tester.getSize(nextInner).width),
    );
    expect(
      tester.getSize(nextFarthest).width,
      lessThan(tester.getSize(nextOuter).width),
    );
    expect(
      tester.getSize(nextEdge).width,
      lessThan(tester.getSize(nextFarthest).width),
    );
    expect(
      tester.getSize(previousEdge).width,
      moreOrLessEquals(28 * 1.10 * 1.10 * 1.10 * 1.10 * 1.10, epsilon: 0.1),
    );
    expect(
      tester.getSize(previousFarthest).width,
      moreOrLessEquals(34 * 1.10 * 1.10 * 1.10 * 1.10 * 1.10, epsilon: 0.1),
    );
    expect(
      tester.getSize(previousOuter).width,
      moreOrLessEquals(40 * 1.10 * 1.10 * 1.10 * 1.10 * 1.10, epsilon: 0.1),
    );
    expect(
      tester.getSize(previousInner).width,
      moreOrLessEquals(48 * 1.10 * 1.10 * 1.10 * 1.10 * 1.10, epsilon: 0.1),
    );
    expect(
      tester
          .getSize(
            find.byKey(const ValueKey('backheader-center-budget-button')),
          )
          .width,
      moreOrLessEquals(58 * 1.15, epsilon: 0.1),
    );
    final activeFillRect = tester.getRect(
      find.byKey(const ValueKey('backheader-center-budget-button')),
    );
    final previousInnerFillRect = tester.getRect(
      find.byKey(const ValueKey('backheader-center-preview-fill-previous-1')),
    );
    final nextInnerFillRect = tester.getRect(
      find.byKey(const ValueKey('backheader-center-preview-fill-next-1')),
    );
    expect(
      activeFillRect.left - previousInnerFillRect.right,
      moreOrLessEquals(11, epsilon: 0.8),
    );
    expect(
      nextInnerFillRect.left - activeFillRect.right,
      moreOrLessEquals(11, epsilon: 0.8),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(
              of: previousFarthest,
              matching: find.byType(Opacity),
            ),
          )
          .opacity,
      lessThan(
        tester
            .widget<Opacity>(
              find.descendant(
                of: previousOuter,
                matching: find.byType(Opacity),
              ),
            )
            .opacity,
      ),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(of: nextInner, matching: find.byType(Opacity)),
          )
          .opacity,
      greaterThanOrEqualTo(0.60),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(of: nextOuter, matching: find.byType(Opacity)),
          )
          .opacity,
      greaterThanOrEqualTo(0.42),
    );
    expect(
      tester
          .widget<Opacity>(
            find.descendant(of: nextEdge, matching: find.byType(Opacity)),
          )
          .opacity,
      greaterThanOrEqualTo(0.42),
    );

    expect(selected.last, 'Home');
  });

  testWidgets('centerBadgeBudget renders the incoming drag edge before tick', (
    tester,
  ) async {
    final bars = [
      for (var index = 0; index < 11; index++)
        barFixture(20 + index, 'Item $index', 10.0 + index, 100),
    ];
    final selected = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onActiveItemChanged: (item) => selected.add(item.title),
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-center-preview-next-5')),
      findsNothing,
    );

    final drag = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('backheader-experimental-surface')),
      ),
    );
    await drag.moveBy(const Offset(-45, 0));
    await tester.pump(const Duration(milliseconds: 16));

    expect(selected, isEmpty);
    expect(
      find.byKey(const ValueKey('backheader-center-preview-next-5')),
      findsOneWidget,
    );

    await drag.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'centerBadgeBudget keeps badge rail aligned during continuous drag',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onActiveItemChanged: (_) {},
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('backheader-center-preview-next-1-category-7'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('backheader-center-preview-previous-1-category-12'),
        ),
        findsOneWidget,
      );

      final initialCenter = tester.getCenter(
        find.byKey(const ValueKey('backheader-center-budget-button')),
      );
      final initialNextCenter = tester.getCenter(
        find.byKey(const ValueKey('backheader-center-preview-next-1')),
      );
      expect(
        initialNextCenter.dy,
        moreOrLessEquals(initialCenter.dy, epsilon: 0.5),
      );
      expect(initialNextCenter.dx - initialCenter.dx, greaterThanOrEqualTo(62));
      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('backheader-experimental-surface')),
        ),
      );
      await drag.moveBy(const Offset(-45, 0));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-previous-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-2')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-preview-next-3')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-wheel-outgoing')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('backheader-center-wheel-incoming')),
        findsNothing,
      );
      final draggedCenter = tester.getCenter(
        find.byKey(const ValueKey('backheader-center-budget-button')),
      );
      expect(draggedCenter.dx, lessThan(initialCenter.dx - 8));
      expect(
        draggedCenter.dy,
        moreOrLessEquals(initialCenter.dy, epsilon: 0.5),
      );
      expect(
        tester
            .getCenter(
              find.byKey(const ValueKey('backheader-center-preview-next-1')),
            )
            .dy,
        moreOrLessEquals(initialCenter.dy, epsilon: 0.5),
      );

      await drag.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'centerBadgeBudget incoming badge uses active-sized fill and ring before tick',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final activeFill = find.byKey(
        const ValueKey('backheader-center-budget-button'),
      );
      final focusedFillWidth = tester.getSize(activeFill).width;
      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('backheader-experimental-surface')),
        ),
      );
      await drag.moveBy(const Offset(-60, 0));
      await tester.pump();

      final incomingFill = find.byKey(
        const ValueKey('backheader-center-preview-fill-next-1'),
      );
      expect(incomingFill, findsOneWidget);
      expect(
        tester.getSize(incomingFill).width,
        lessThanOrEqualTo(focusedFillWidth),
      );
      expect(
        find.byKey(
          const ValueKey('backheader-center-preview-progress-ring-next-1'),
        ),
        findsOneWidget,
      );

      await drag.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'centerBadgeBudget progress and partition rings use border layers',
    (tester) async {
      final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000);
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                centerPartitionRingEnabled: true,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                overviewItems: [overview],
                periodIncome: 1000,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final activeFill = find.byKey(
        const ValueKey('backheader-center-budget-button'),
      );
      final activeRing = find.byKey(
        const ValueKey('backheader-center-progress-ring'),
      );
      final activePartition = find.byKey(
        const ValueKey('backheader-center-partition-ring'),
      );
      final activeFillSize = tester.getSize(activeFill);
      final activeRingSize = tester.getSize(activeRing);
      final activePartitionSize = tester.getSize(activePartition);
      expect(activeFillSize.width, moreOrLessEquals(58 * 1.15, epsilon: 0.1));
      expect(activeRingSize, activeFillSize);
      expect(activePartitionSize.width, greaterThan(activeRingSize.width));
      expect(
        activePartitionSize.width - activeRingSize.width,
        moreOrLessEquals(8 * 1.15, epsilon: 0.2),
      );

      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('backheader-experimental-surface')),
        ),
      );
      await drag.moveBy(const Offset(-60, 0));
      await tester.pump();

      final incomingFill = find.byKey(
        const ValueKey('backheader-center-preview-fill-next-1'),
      );
      final incomingRing = find.byKey(
        const ValueKey('backheader-center-preview-progress-ring-next-1'),
      );
      final incomingFillSize = tester.getSize(incomingFill);
      expect(incomingFillSize.width, lessThanOrEqualTo(activeFillSize.width));
      expect(tester.getSize(incomingRing), incomingFillSize);

      await drag.up();
      await tester.pumpAndSettle();
    },
  );

  testWidgets('centerBadgeBudget badge icons do not use async placeholders', (
    tester,
  ) async {
    final bars = [
      barFixture(6, 'Food', 10, 100),
      barFixture(7, 'Travel', 20, 100),
      barFixture(8, 'Books', 30, 100),
      barFixture(9, 'Health', 40, 100),
      barFixture(10, 'Home', 50, 100),
      barFixture(11, 'Rent', 60, 100),
      barFixture(12, 'Gifts', 70, 100),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.descendant(
        of: find.byKey(const ValueKey('backheader-center-budget-button')),
        matching: find.byType(FutureBuilder<String>),
      ),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('backheader-center-preview-next-1')),
        matching: find.byType(FutureBuilder<String>),
      ),
      findsNothing,
    );
  });

  testWidgets('centerBadgeBudget background tap does not open item action', (
    tester,
  ) async {
    final bars = [
      barFixture(6, 'Food', 10, 100),
      barFixture(7, 'Travel', 20, 100),
      barFixture(8, 'Books', 30, 100),
      barFixture(9, 'Health', 40, 100),
      barFixture(10, 'Home', 50, 100),
      barFixture(11, 'Rent', 60, 100),
      barFixture(12, 'Gifts', 70, 100),
    ];
    final tapped = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (item) => tapped.add(item.title),
            ),
          ),
        ),
      ),
    );

    final surfaceTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('backheader-experimental-surface')),
    );
    await tester.tapAt(surfaceTopLeft + const Offset(24, 24));
    await tester.pump();
    expect(tapped, isEmpty);

    await tester.tap(
      find.byKey(const ValueKey('backheader-center-budget-button')),
    );
    await tester.pump();
    expect(tapped, ['Food']);
  });

  testWidgets('centerBadgeBudget belt ticks while drag is held', (
    tester,
  ) async {
    final bars = [
      barFixture(6, 'Food', 10, 100),
      barFixture(7, 'Travel', 20, 100),
      barFixture(8, 'Books', 30, 100),
      barFixture(9, 'Health', 40, 100),
      barFixture(10, 'Home', 50, 100),
      barFixture(11, 'Rent', 60, 100),
      barFixture(12, 'Gifts', 70, 100),
    ];
    final selected = <String>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onActiveItemChanged: (item) => selected.add(item.title),
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final drag = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('backheader-experimental-surface')),
      ),
    );
    await drag.moveBy(const Offset(-150, 0));
    await tester.pump();

    expect(selected, isEmpty);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('backheader-center-badge-title')),
          )
          .data,
      'Books',
    );

    await drag.up();
    await tester.pumpAndSettle();

    expect(selected, ['Health']);
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('backheader-center-badge-title')),
          )
          .data,
      'Health',
    );
  });

  testWidgets(
    'centerBadgeBudget between-slot release settles in swipe direction',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];
      final selected = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onActiveItemChanged: (item) => selected.add(item.title),
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.timedDrag(
        find.byKey(const ValueKey('backheader-experimental-surface')),
        const Offset(-96, 0),
        const Duration(milliseconds: 600),
      );
      await tester.pumpAndSettle();

      expect(selected, ['Books']);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('backheader-center-badge-title')),
            )
            .data,
        'Books',
      );
    },
  );

  testWidgets(
    'centerBadgeBudget release direction follows total drag after reverse tail',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];
      final selected = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onActiveItemChanged: (item) => selected.add(item.title),
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final drag = await tester.startGesture(
        tester.getCenter(
          find.byKey(const ValueKey('backheader-experimental-surface')),
        ),
      );
      await drag.moveBy(
        const Offset(-120, 0),
        timeStamp: const Duration(milliseconds: 16),
      );
      await drag.moveBy(
        const Offset(8, 0),
        timeStamp: const Duration(milliseconds: 32),
      );
      await drag.up();
      await tester.pumpAndSettle();

      expect(selected, isNotEmpty);
    },
  );

  testWidgets(
    'centerBadgeBudget equivalent drags settle to the same sequence',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];

      Future<List<String>> runGesture(
        List<MapEntry<Duration, double>> moves,
      ) async {
        final selected = <String>[];
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 340,
                child: CategoryBudgetStage(
                  backheaderStyle: BackheaderStyle.centerBadgeBudget,
                  items: bars.map(BackheaderBudgetItem.category).toList(),
                  categoryBars: bars,
                  onActiveItemChanged: (item) => selected.add(item.title),
                  onItemTap: (_) {},
                ),
              ),
            ),
          ),
        );

        final drag = await tester.startGesture(
          tester.getCenter(
            find.byKey(const ValueKey('backheader-experimental-surface')),
          ),
        );
        for (final move in moves) {
          await drag.moveBy(Offset(move.value, 0), timeStamp: move.key);
        }
        await drag.up();
        await tester.pumpAndSettle();
        return selected;
      }

      final tailWeighted = await runGesture([
        MapEntry(const Duration(milliseconds: 16), -120),
        MapEntry(const Duration(milliseconds: 48), -30),
      ]);
      final evenlySplit = await runGesture([
        MapEntry(const Duration(milliseconds: 24), -75),
        MapEntry(const Duration(milliseconds: 48), -75),
      ]);

      expect(tailWeighted, evenlySplit);
      expect(evenlySplit, ['Health']);
    },
  );

  testWidgets(
    'centerBadgeBudget fast short fling keeps spinning after release',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 10, 100),
        barFixture(7, 'Travel', 20, 100),
        barFixture(8, 'Books', 30, 100),
        barFixture(9, 'Health', 40, 100),
        barFixture(10, 'Home', 50, 100),
        barFixture(11, 'Rent', 60, 100),
        barFixture(12, 'Gifts', 70, 100),
      ];
      final selected = <String>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onActiveItemChanged: (item) => selected.add(item.title),
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.fling(
        find.byKey(const ValueKey('backheader-experimental-surface')),
        const Offset(-92, 0),
        2600,
      );
      await tester.pump(const Duration(milliseconds: 40));

      expect(selected, isEmpty);

      await tester.pumpAndSettle();

      expect(selected, ['Home']);
    },
  );

  testWidgets('centerBadgeBudget writes copyable carousel diagnostics', (
    tester,
  ) async {
    DebugConsole.clear();
    final bars = [
      barFixture(6, 'Food', 10, 100),
      barFixture(7, 'Travel', 20, 100),
      barFixture(8, 'Books', 30, 100),
      barFixture(9, 'Health', 40, 100),
      barFixture(10, 'Home', 50, 100),
      barFixture(11, 'Rent', 60, 100),
      barFixture(12, 'Gifts', 70, 100),
    ];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onActiveItemChanged: (_) {},
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    await tester.fling(
      find.byKey(const ValueKey('backheader-experimental-surface')),
      const Offset(-92, 0),
      2600,
    );
    await tester.pumpAndSettle();

    final logs = DebugConsole.entries
        .where((entry) => entry.contains('[CenterCarousel]'))
        .join('\n');
    expect(logs, contains('down pointer='));
    expect(logs, contains('accept dx='));
    expect(logs, contains('move delta='));
    expect(logs, contains('up accepted=true'));
    expect(logs, contains('release travel='));
    expect(logs, contains('tick source='));
    expect(logs, contains('settled source=release'));
  });

  testWidgets('centerBadgeBudget badge joystick adjusts limit live', (
    tester,
  ) async {
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 5000);
    final food = barFixture(6, 'Food', 100, 500);
    final savedAmounts = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: [
                BackheaderBudgetItem.overview(overview),
                BackheaderBudgetItem.category(food),
              ],
              categoryBars: [food],
              overviewItems: [overview],
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {
                    savedAmounts.add(limitAmount);
                  },
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('backheader-center-budget-button'),
    );
    final start = tester.getCenter(button);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 620));
    await gesture.moveTo(start.translate(0, -150));
    await tester.pump(const Duration(milliseconds: 320));

    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('backheader-center-badge-amount')),
    );
    expect(amount.data, isNot('100 Ft / 500 Ft'));

    await gesture.up();
    await tester.pump();
    expect(savedAmounts, isNotEmpty);
  });

  testWidgets('centerBadgeBudget joystick can raise budget above old cap', (
    tester,
  ) async {
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000);
    final food = barFixture(6, 'Food', 100, 500);
    final travel = barFixture(7, 'Travel', 100, 500);
    final savedAmounts = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: [
                BackheaderBudgetItem.overview(overview),
                BackheaderBudgetItem.category(food),
                BackheaderBudgetItem.category(travel),
              ],
              categoryBars: [food, travel],
              overviewItems: [overview],
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {
                    savedAmounts.add(limitAmount);
                  },
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('backheader-center-budget-button'),
    );
    final start = tester.getCenter(button);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 620));
    await gesture.moveTo(start.translate(0, -170));
    await tester.pump(const Duration(milliseconds: 200));

    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('backheader-center-badge-amount')),
    );
    final limitMatch = RegExp(r'/ ([\d ]+) Ft$').firstMatch(amount.data ?? '');
    expect(limitMatch, isNotNull);
    final limit = int.parse(limitMatch!.group(1)!.replaceAll(' ', ''));
    expect(limit, greaterThan(500));

    await gesture.up();
    await tester.pump();
    expect(savedAmounts.last, greaterThan(500));
  });

  testWidgets('centerBadgeBudget tiny upward joystick pull stays slower', (
    tester,
  ) async {
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 50000);
    final food = barFixture(6, 'Food', 100, 500);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: [
                BackheaderBudgetItem.overview(overview),
                BackheaderBudgetItem.category(food),
              ],
              categoryBars: [food],
              overviewItems: [overview],
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (_, {required limitAmount, required alertActive}) async {},
            ),
          ),
        ),
      ),
    );

    final button = find.byKey(
      const ValueKey('backheader-center-budget-button'),
    );
    final start = tester.getCenter(button);
    final gesture = await tester.startGesture(start);
    await tester.pump(const Duration(milliseconds: 620));
    await gesture.moveTo(start.translate(0, -16));
    await tester.pump(const Duration(milliseconds: 320));

    final amount = tester.widget<Text>(
      find.byKey(const ValueKey('backheader-center-badge-amount')),
    );
    final limitMatch = RegExp(r'/ ([\d ]+) Ft$').firstMatch(amount.data ?? '');
    expect(limitMatch, isNotNull);
    final limit = int.parse(limitMatch!.group(1)!.replaceAll(' ', ''));
    expect(limit, lessThanOrEqualTo(3000));

    await gesture.up();
    await tester.pump();
  });

  testWidgets(
    'centerBadgeBudget far upward joystick pull keeps fast limit speed',
    (tester) async {
      final overview = overviewFixture(
        BudgetGoalKind.expenseBudget,
        100,
        50000,
      );
      final food = barFixture(6, 'Food', 100, 500);
      final savedAmounts = <double>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                items: [
                  BackheaderBudgetItem.overview(overview),
                  BackheaderBudgetItem.category(food),
                ],
                categoryBars: [food],
                overviewItems: [overview],
                activeKey: BackheaderBudgetItem.category(food).key,
                onItemTap: (_) {},
                onSaveOverview:
                    (_, {required limitAmount, required alertActive}) async {},
                onSaveCategory:
                    (bar, {required limitAmount, required alertActive}) async {
                      savedAmounts.add(limitAmount);
                    },
              ),
            ),
          ),
        ),
      );

      final button = find.byKey(
        const ValueKey('backheader-center-budget-button'),
      );
      final start = tester.getCenter(button);
      final gesture = await tester.startGesture(start);
      await tester.pump(const Duration(milliseconds: 620));
      await gesture.moveTo(start.translate(0, -42));
      await tester.pump(const Duration(milliseconds: 320));

      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('backheader-center-badge-amount')),
      );
      final limitMatch = RegExp(
        r'/ ([\d ]+) Ft$',
      ).firstMatch(amount.data ?? '');
      expect(limitMatch, isNotNull);
      final limit = int.parse(limitMatch!.group(1)!.replaceAll(' ', ''));
      expect(limit, greaterThanOrEqualTo(3500));

      await gesture.up();
      await tester.pump();
      expect(savedAmounts.last, greaterThanOrEqualTo(3500));
    },
  );

  testWidgets('centerBadgeBudget colored design uses orbit-like white veil', (
    tester,
  ) async {
    const backgroundColor = Color(0xffeef3f7);
    final food = barFixture(6, 'Food', 100, 500);
    final travel = barFixture(7, 'Travel', 40, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              centerBackheaderDesign: BackheaderCenterDesign.colored,
              backgroundColor: backgroundColor,
              items: [
                BackheaderBudgetItem.category(food),
                BackheaderBudgetItem.category(travel),
              ],
              categoryBars: [food, travel],
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final surface = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('backheader-style-centerBadgeBudget')),
    );
    expect(
      (surface.decoration as BoxDecoration).color,
      Color.alphaBlend(food.color.withValues(alpha: 0.72), backgroundColor),
    );

    final button = tester.widget<Container>(
      find.byKey(const ValueKey('backheader-center-budget-button')),
    );
    expect(
      (button.decoration as BoxDecoration).color,
      AppColors.white.withValues(alpha: 0.18),
    );
    final handleLine = tester.widget<Container>(
      find.byKey(const ValueKey('backheader-center-handle-line')),
    );
    expect(
      (handleLine.decoration as BoxDecoration).color,
      AppColors.white.withValues(alpha: 0.78),
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('backheader-center-badge-amount')),
          )
          .style
          ?.color,
      AppColors.white,
    );
    expect(
      find.byKey(const ValueKey('backheader-center-progress-ring')),
      paints
        ..arc(color: AppColors.white.withValues(alpha: 0.34))
        ..arc(color: AppColors.white),
    );
  });

  testWidgets(
    'centerBadgeBudget can hide colored white badge disc independently',
    (tester) async {
      const backgroundColor = Color(0xffeef3f7);
      final food = barFixture(6, 'Food', 100, 500);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.centerBadgeBudget,
                centerBackheaderDesign: BackheaderCenterDesign.colored,
                centerBadgeDiscEnabled: false,
                backgroundColor: backgroundColor,
                items: [BackheaderBudgetItem.category(food)],
                categoryBars: [food],
                activeKey: BackheaderBudgetItem.category(food).key,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final button = tester.widget<Container>(
        find.byKey(const ValueKey('backheader-center-budget-button')),
      );
      expect((button.decoration as BoxDecoration).color, Colors.transparent);
      expect(
        find.byKey(const ValueKey('backheader-center-progress-ring')),
        paints
          ..arc(color: AppColors.white.withValues(alpha: 0.34))
          ..arc(color: AppColors.white),
      );
    },
  );

  testWidgets(
    'centerBadgeBudget limit-only border distinguishes no-limit from zero progress limit',
    (tester) async {
      final noLimit = barFixture(6, 'No limit', 0, 0);
      final zeroProgressLimit = barFixture(7, 'Zero limit spend', 0, 500);

      Future<void> pumpActive(BackheaderBudgetItem activeItem) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 390,
                height: 340,
                child: CategoryBudgetStage(
                  backheaderStyle: BackheaderStyle.centerBadgeBudget,
                  centerBackheaderDesign: BackheaderCenterDesign.colored,
                  centerBadgeBorderMode: CenterBadgeBorderMode.limitOnly,
                  backgroundColor: const Color(0xffeef3f7),
                  items: [
                    BackheaderBudgetItem.category(noLimit),
                    BackheaderBudgetItem.category(zeroProgressLimit),
                  ],
                  categoryBars: [noLimit, zeroProgressLimit],
                  activeKey: activeItem.key,
                  onItemTap: (_) {},
                ),
              ),
            ),
          ),
        );
      }

      await pumpActive(BackheaderBudgetItem.category(noLimit));
      expect(
        find.byKey(const ValueKey('backheader-center-progress-ring')),
        isNot(paints..arc(color: AppColors.white.withValues(alpha: 0.34))),
      );

      await pumpActive(BackheaderBudgetItem.category(zeroProgressLimit));
      expect(
        find.byKey(const ValueKey('backheader-center-progress-ring')),
        paints..arc(color: AppColors.white.withValues(alpha: 0.34)),
      );
    },
  );

  testWidgets('centerBadgeBudget always border mode keeps no-limit track', (
    tester,
  ) async {
    final noLimit = barFixture(6, 'No limit', 0, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              centerBackheaderDesign: BackheaderCenterDesign.colored,
              centerBadgeBorderMode: CenterBadgeBorderMode.always,
              backgroundColor: const Color(0xffeef3f7),
              items: [BackheaderBudgetItem.category(noLimit)],
              categoryBars: [noLimit],
              activeKey: BackheaderBudgetItem.category(noLimit).key,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-center-progress-ring')),
      paints..arc(color: AppColors.white.withValues(alpha: 0.34)),
    );
  });

  testWidgets('centerBadgeBudget handle expands remaining amount and closes', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 500);
    var closeRequests = 0;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 420,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.centerBadgeBudget,
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              onItemTap: (_) {},
              onOrbitCloseRequested: () => closeRequests += 1,
            ),
          ),
        ),
      ),
    );

    final handle = find.byKey(const ValueKey('backheader-center-handle'));
    expect(handle, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(handle));
    await gesture.moveBy(const Offset(0, 60));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('backheader-center-remaining-amount')),
      findsOneWidget,
    );
    expect(find.textContaining('400 Ft'), findsOneWidget);
    final remainingRect = tester.getRect(
      find.byKey(const ValueKey('backheader-center-remaining-amount')),
    );
    expect(
      remainingRect.top,
      greaterThanOrEqualTo(TransactionHeaderMetrics.cardHeight - 2),
    );

    await gesture.moveBy(const Offset(0, 40));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(closeRequests, 1);
  });

  testWidgets('orbitBudget stage height follows header card height metric', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 390,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.orbitBudget,
                items: [BackheaderBudgetItem.category(food)],
                categoryBars: [food],
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    expect(
      tester
          .getSize(find.byKey(const ValueKey('category-budget-stage')))
          .height,
      TransactionHeaderMetrics.cardHeight,
    );
  });

  testWidgets('orbitBudget hides progress ring for unlimited category', (
    tester,
  ) async {
    final travel = barFixture(7, 'Travel', 40, 0);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [BackheaderBudgetItem.category(travel)],
              categoryBars: [travel],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('backheader-orbit-icon')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
      findsNothing,
    );
    expect(find.text('Travel'), findsOneWidget);
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
    );
    expect(input.controller!.text, isEmpty);
    expect(input.decoration!.hintText, 'n/a');
    expect(
      find.byKey(const ValueKey('backheader-orbit-limit-pill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-orbit-spent-text')),
      findsOneWidget,
    );
    expect(find.text('40 Ft'), findsOneWidget);
  });

  testWidgets('heroToken keeps legacy experimental partition layout', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.heroToken,
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-partition-strip')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('backheader-orbit-icon')), findsNothing);
    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsNothing,
    );
  });

  testWidgets(
    'orbitBudget is compact and has only the white backheader handle',
    (tester) async {
      final food = barFixture(6, 'Food', 100, 150);
      final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 300,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.orbitBudget,
                items: [
                  BackheaderBudgetItem.overview(overview),
                  BackheaderBudgetItem.category(food),
                ],
                categoryBars: [food],
                overviewItems: [overview],
                activeKey: BackheaderBudgetItem.category(food).key,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('backheader-orbit-handle')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-orbit-inline-editor')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('backheader-orbit-slider')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('backheader-overview-jump-button')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('backheader-orbit-amount-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('limit-reset-inline-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('backheader-orbit-handle')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'orbitBudget handle ignores diagonal drag while horizontal swipe remains',
    (tester) async {
      BackheaderBudgetItem? activeItem;
      final food = barFixture(6, 'Food', 100, 150);
      final travel = barFixture(7, 'Travel', 40, 0);
      final overview = BackheaderBudgetItem.overview(
        overviewFixture(BudgetGoalKind.expenseBudget, 100, 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 300,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.orbitBudget,
                items: [
                  overview,
                  BackheaderBudgetItem.category(food),
                  BackheaderBudgetItem.category(travel),
                ],
                categoryBars: [food, travel],
                activeKey: BackheaderBudgetItem.category(food).key,
                onActiveItemChanged: (item) => activeItem = item,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey('backheader-orbit-handle')),
        const Offset(70, 72),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('backheader-orbit-inline-editor')),
        findsNothing,
      );

      await tester.drag(
        find.byKey(const ValueKey('backheader-experimental-surface')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      expect(activeItem?.category?.title, 'Travel');
    },
  );

  testWidgets('orbitBudget shows neighboring card preview while swiping', (
    tester,
  ) async {
    BackheaderBudgetItem? activeItem;
    final food = barFixture(6, 'Food', 100, 150);
    final travel = barFixture(7, 'Travel', 40, 300);
    final overview = BackheaderBudgetItem.overview(
      overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 300,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [
                overview,
                BackheaderBudgetItem.category(food),
                BackheaderBudgetItem.category(travel),
              ],
              categoryBars: [food, travel],
              activeKey: BackheaderBudgetItem.category(food).key,
              onActiveItemChanged: (item) => activeItem = item,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(
        find.byKey(const ValueKey('backheader-experimental-surface')),
      ),
    );
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-48, 0));
    await tester.pump();

    expect(
      find.byKey(const ValueKey('backheader-orbit-preview-next')),
      findsOneWidget,
    );
    expect(activeItem, isNull);

    await gesture.up();
    await tester.pumpAndSettle();
    expect(activeItem?.category?.title, 'Travel');
  });

  testWidgets('orbitBudget handle overpull snaps or requests close', (
    tester,
  ) async {
    var closeRequests = 0;
    final food = barFixture(6, 'Food', 100, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 300,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onOrbitCloseRequested: () => closeRequests += 1,
            ),
          ),
        ),
      ),
    );

    final normalHeight = tester
        .getRect(find.byKey(const ValueKey('category-budget-stage')))
        .height;

    await tester.drag(
      find.byKey(const ValueKey('backheader-orbit-handle')),
      const Offset(0, 22),
    );
    await tester.pumpAndSettle();
    expect(closeRequests, 0);
    expect(
      tester
          .getRect(find.byKey(const ValueKey('category-budget-stage')))
          .height,
      moreOrLessEquals(normalHeight, epsilon: 0.1),
    );

    await tester.drag(
      find.byKey(const ValueKey('backheader-orbit-handle')),
      const Offset(0, 62),
    );
    await tester.pumpAndSettle();
    expect(closeRequests, 1);
  });

  testWidgets('orbitBudget partition bar acts as the live limit slider', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 1000);
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 10000);
    final savedCategoryAmounts = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [
                BackheaderBudgetItem.overview(overview),
                BackheaderBudgetItem.category(food),
              ],
              categoryBars: [food],
              overviewItems: [overview],
              periodIncome: 10000,
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {
                    savedCategoryAmounts.add(limitAmount);
                  },
            ),
          ),
        ),
      ),
    );

    expect(find.byType(CategoryLimitSlider), findsNothing);
    expect(find.byKey(const ValueKey('limit-save-button')), findsNothing);

    final partition = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    expect(
      find.byKey(const ValueKey('backheader-orbit-partition-handle')),
      findsOneWidget,
    );
    final initialHandle = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-partition-handle')),
    );
    final usedSegment = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-segment-0')),
    );
    final remainingSegment = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-segment-1')),
    );
    expect(
      usedSegment.width,
      moreOrLessEquals(partition.width * 100 / 10000, epsilon: 0.1),
    );
    expect(
      remainingSegment.width,
      moreOrLessEquals(partition.width * 900 / 10000, epsilon: 0.1),
    );
    expect(
      initialHandle.center.dx,
      moreOrLessEquals(partition.left + partition.width * 0.10, epsilon: 1.5),
    );

    await tester.dragFrom(
      Offset(partition.left + 8, partition.center.dy),
      Offset(partition.width * 0.55, 0),
    );
    await tester.pump(const Duration(milliseconds: 180));
    final movedHandle = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-partition-handle')),
    );

    expect(savedCategoryAmounts, isNotEmpty);
    expect(savedCategoryAmounts.last, greaterThan(1000));
    expect(movedHandle.center.dx, greaterThan(initialHandle.center.dx));
    expect(find.text('100 Ft / 1 000 Ft'), findsNothing);
  });

  testWidgets('orbitBudget partition slider defers saves during drag', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 1000);
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 10000);
    final savedCategoryAmounts = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [
                BackheaderBudgetItem.overview(overview),
                BackheaderBudgetItem.category(food),
              ],
              categoryBars: [food],
              overviewItems: [overview],
              periodIncome: 10000,
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {
                    savedCategoryAmounts.add(limitAmount);
                  },
            ),
          ),
        ),
      ),
    );

    final partition = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    final initialHandle = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-partition-handle')),
    );
    final gesture = await tester.startGesture(
      Offset(partition.left + 8, partition.center.dy),
    );
    await gesture.moveBy(Offset(partition.width * 0.25, 0));
    await tester.pump();
    await gesture.moveBy(Offset(partition.width * 0.20, 0));
    await tester.pump(const Duration(milliseconds: 160));

    final movedHandle = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-partition-handle')),
    );
    expect(movedHandle.center.dx, greaterThan(initialHandle.center.dx));
    expect(savedCategoryAmounts, isEmpty);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 180));

    expect(savedCategoryAmounts, isNotEmpty);
    expect(savedCategoryAmounts.length, 1);
    expect(savedCategoryAmounts.last, greaterThan(1000));
  });

  testWidgets('orbitBudget amount text edits category limits inline', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 1000);
    final overview = overviewFixture(
      BudgetGoalKind.expenseBudget,
      100,
      10000000,
    );
    final saved = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [
                BackheaderBudgetItem.overview(overview),
                BackheaderBudgetItem.category(food),
              ],
              categoryBars: [food],
              overviewItems: [overview],
              periodIncome: 10000000,
              activeKey: BackheaderBudgetItem.category(food).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {
                    saved.add(limitAmount);
                  },
            ),
          ),
        ),
      ),
    );

    final initialPill = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-limit-pill')),
    );
    await tester.tap(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
      '7000000',
    );
    await tester.pump(const Duration(milliseconds: 180));
    final expandedPill = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-limit-pill')),
    );

    expect(saved, isNotEmpty);
    expect(saved.last, 7000000);
    expect(expandedPill.width, greaterThan(initialPill.width));
    expect(find.byKey(const ValueKey('limit-amount-input')), findsNothing);
  });

  testWidgets('orbitBudget overview amount max and reset sit at top right', (
    tester,
  ) async {
    final overview = overviewFixture(BudgetGoalKind.expenseBudget, 100, 1000);
    final saved = <({double amount, bool alert})>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 300,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [BackheaderBudgetItem.overview(overview)],
              overviewItems: [overview],
              periodIncome: 9000,
              activeKey: BackheaderBudgetItem.overview(overview).key,
              onItemTap: (_) {},
              onSaveOverview:
                  (kind, {required limitAmount, required alertActive}) async {
                    saved.add((amount: limitAmount, alert: alertActive));
                  },
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-orbit-max-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('limit-reset-inline-button')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('backheader-overview-jump-button')),
      findsNothing,
    );
    final reset = tester.getRect(
      find.byKey(const ValueKey('limit-reset-inline-button')),
    );
    final max = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-max-button')),
    );
    final surface = tester.getRect(
      find.byKey(const ValueKey('backheader-style-orbitBudget')),
    );
    final partition = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    final expectedOrbitTop =
        TransactionHeaderMetrics.cardHeight -
        TransactionHeaderMetrics.expandedSlideDistance +
        10;
    expect(max.left, greaterThan(reset.right));
    expect(max.right, lessThanOrEqualTo(surface.right));
    expect(reset.top, moreOrLessEquals(expectedOrbitTop, epsilon: 0.1));
    expect(max.top, moreOrLessEquals(expectedOrbitTop, epsilon: 0.1));
    expect(reset.bottom, lessThan(partition.top));
    expect(max.bottom, lessThan(partition.top));
    final overviewRing = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
    );
    expect(overviewRing.painter, isNotNull);
    expect(overviewRing.child, isNotNull);

    await tester.tap(find.byKey(const ValueKey('backheader-orbit-max-button')));
    await tester.pump(const Duration(milliseconds: 180));
    expect(saved, isNotEmpty);
    expect(saved.last.amount, 9000);
    expect(saved.last.alert, isTrue);

    await tester.tap(find.byKey(const ValueKey('limit-reset-inline-button')));
    await tester.pump(const Duration(milliseconds: 180));
    expect(saved.last.amount, 0);
    expect(saved.last.alert, isFalse);
  });

  testWidgets('orbitBudget no-limit category shows empty editable y pill', (
    tester,
  ) async {
    final travel = barFixture(7, 'Travel', 40, 0);
    final saved = <double>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 300,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [BackheaderBudgetItem.category(travel)],
              categoryBars: [travel],
              activeKey: BackheaderBudgetItem.category(travel).key,
              onItemTap: (_) {},
              onSaveCategory:
                  (bar, {required limitAmount, required alertActive}) async {
                    saved.add(limitAmount);
                  },
            ),
          ),
        ),
      ),
    );

    final input = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
    );
    final pill = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-limit-pill')),
    );
    final spent = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-spent-text')),
    );
    final slash = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-amount-slash')),
    );
    final surface = tester.getRect(
      find.byKey(const ValueKey('backheader-style-orbitBudget')),
    );
    expect(spent.left, lessThan(surface.left + 180));
    expect(spent.left, lessThan(slash.left));
    expect(slash.left, lessThan(pill.left));
    expect(input.center.dx, moreOrLessEquals(pill.center.dx, epsilon: 1));
    expect(
      tester
          .widget<TextField>(
            find.byKey(const ValueKey('backheader-orbit-amount-input')),
          )
          .decoration!
          .hintText,
      'n/a',
    );
    expect(find.text('40 Ft'), findsOneWidget);
    expect(
      tester.widget<EditableText>(find.byType(EditableText)).controller.text,
      isEmpty,
    );

    await tester.enterText(
      find.byKey(const ValueKey('backheader-orbit-amount-input')),
      '300',
    );
    await tester.pump(const Duration(milliseconds: 180));
    expect(saved, isNotEmpty);
    expect(saved.last, 300);
  });

  testWidgets(
    'orbitBudget partition slider coalesces saves and catches errors',
    (tester) async {
      final food = barFixture(6, 'Food', 100, 1000);
      final overview = overviewFixture(
        BudgetGoalKind.expenseBudget,
        100,
        10000,
      );
      final savedAmounts = <double>[];
      final saveCompleters = <Completer<void>>[];
      var inFlight = 0;
      var maxInFlight = 0;
      var throwOnNextSave = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 340,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.orbitBudget,
                items: [
                  BackheaderBudgetItem.overview(overview),
                  BackheaderBudgetItem.category(food),
                ],
                categoryBars: [food],
                overviewItems: [overview],
                periodIncome: 10000,
                activeKey: BackheaderBudgetItem.category(food).key,
                onItemTap: (_) {},
                onSaveOverview:
                    (_, {required limitAmount, required alertActive}) async {},
                onSaveCategory:
                    (bar, {required limitAmount, required alertActive}) async {
                      if (throwOnNextSave) {
                        throwOnNextSave = false;
                        throw StateError('forced save failure');
                      }
                      inFlight += 1;
                      maxInFlight = maxInFlight < inFlight
                          ? inFlight
                          : maxInFlight;
                      savedAmounts.add(limitAmount);
                      final completer = Completer<void>();
                      saveCompleters.add(completer);
                      await completer.future;
                      inFlight -= 1;
                    },
              ),
            ),
          ),
        ),
      );

      final partition = tester.getRect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
      );
      await tester.dragFrom(
        Offset(partition.left + 10, partition.center.dy),
        Offset(partition.width * 0.20, 0),
      );
      await tester.dragFrom(
        Offset(partition.left + 10, partition.center.dy),
        Offset(partition.width * 0.30, 0),
      );
      await tester.dragFrom(
        Offset(partition.left + 10, partition.center.dy),
        Offset(partition.width * 0.40, 0),
      );
      await tester.pump();

      expect(maxInFlight, 1);
      expect(savedAmounts.length, lessThanOrEqualTo(1));

      for (final completer in saveCompleters) {
        if (!completer.isCompleted) completer.complete();
      }
      await tester.pump(const Duration(milliseconds: 220));
      for (final completer in saveCompleters) {
        if (!completer.isCompleted) completer.complete();
      }
      await tester.pumpAndSettle();

      expect(savedAmounts, isNotEmpty);
      expect(savedAmounts.last, greaterThan(3000));
      expect(maxInFlight, 1);

      throwOnNextSave = true;
      await tester.dragFrom(
        Offset(partition.left + 10, partition.center.dy),
        Offset(partition.width * 0.50, 0),
      );
      await tester.pump(const Duration(milliseconds: 220));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('orbitBudget icon is smaller and fixed during close overpull', (
    tester,
  ) async {
    final food = barFixture(6, 'Food', 100, 150);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.orbitBudget,
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final collapsedIcon = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-icon')),
    );
    final collapsedRing = tester.getSize(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
    );

    final overpull = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('backheader-orbit-handle'))),
    );
    await overpull.moveBy(const Offset(0, 18));
    await tester.pump();

    final overpulledIcon = tester.getRect(
      find.byKey(const ValueKey('backheader-orbit-icon')),
    );
    final overpulledRing = tester.getSize(
      find.byKey(const ValueKey('backheader-orbit-progress-ring')),
    );
    await overpull.up();
    await tester.pumpAndSettle();

    expect(collapsedIcon.size.width, moreOrLessEquals(40.6, epsilon: 0.5));
    expect(collapsedIcon.size.height, moreOrLessEquals(40.6, epsilon: 0.5));
    expect(collapsedRing.width, moreOrLessEquals(40.6, epsilon: 0.5));
    expect(
      overpulledRing.width,
      moreOrLessEquals(collapsedRing.width, epsilon: 0.1),
    );
    expect(
      overpulledIcon.top,
      moreOrLessEquals(collapsedIcon.top, epsilon: 0.1),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 340,
            child: CategoryBudgetStage(
              backheaderStyle: BackheaderStyle.heroToken,
              items: [BackheaderBudgetItem.category(food)],
              categoryBars: [food],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('backheader-style-heroToken-content')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('backheader-orbit-icon')), findsNothing);
  });

  testWidgets(
    'experimental backheader preserves swipe and long press behavior',
    (tester) async {
      BackheaderBudgetItem? activeItem;
      final food = barFixture(6, 'Food', 100, 150);
      final travel = barFixture(7, 'Travel', 40, 0);
      final overview = BackheaderBudgetItem.overview(
        overviewFixture(BudgetGoalKind.expenseBudget, 100, 300),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 300,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.orbitBudget,
                items: [
                  overview,
                  BackheaderBudgetItem.category(food),
                  BackheaderBudgetItem.category(travel),
                ],
                categoryBars: [food, travel],
                activeKey: BackheaderBudgetItem.category(food).key,
                onActiveItemChanged: (item) => activeItem = item,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      await tester.drag(
        find.byKey(const ValueKey('backheader-experimental-surface')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      expect(activeItem?.category?.title, 'Travel');

      await tester.longPress(
        find.byKey(const ValueKey('backheader-experimental-surface')),
      );
      await tester.pumpAndSettle();
      expect(activeItem?.overview?.kind, BudgetGoalKind.expenseBudget);
    },
  );

  testWidgets('category budget bar follows horizontal drag before settling', (
    tester,
  ) async {
    final bars = [
      barFixture(6, 'Food', 100, 150),
      barFixture(7, 'Travel', 40, 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('category-budget-bar'))),
    );
    await gesture.moveBy(const Offset(-20, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-15, 0));
    await tester.pump();

    final translatedBar = tester.widget<Transform>(
      find.byKey(const ValueKey('category-budget-bar-translation')),
    );
    expect(translatedBar.transform.getTranslation().x, lessThan(0));
    expect(find.text('Food'), findsOneWidget);

    await gesture.up();
    await tester.pumpAndSettle();

    final settledBar = tester.widget<Transform>(
      find.byKey(const ValueKey('category-budget-bar-translation')),
    );
    expect(settledBar.transform.getTranslation().x, 0);
    expect(find.text('Food'), findsOneWidget);
  });

  testWidgets(
    'long press on category bar jumps back to the overview budget bar',
    (tester) async {
      BackheaderBudgetItem? activeItem;
      final food = barFixture(6, 'Food', 100, 150);
      final overview = BackheaderBudgetItem.overview(
        overviewFixture(BudgetGoalKind.expenseBudget, 100, 300),
      );
      final category = BackheaderBudgetItem.category(food);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 260,
              child: CategoryBudgetStage(
                items: [overview, category],
                categoryBars: [food],
                activeKey: category.key,
                onActiveItemChanged: (item) => activeItem = item,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(find.text('Food'), findsOneWidget);

      await tester.longPress(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();

      expect(activeItem?.overview?.kind, BudgetGoalKind.expenseBudget);
      expect(find.text('Budget'), findsOneWidget);
    },
  );

  testWidgets('category budget stage switches only when drag is released', (
    tester,
  ) async {
    final bars = [
      barFixture(6, 'Food', 100, 150),
      barFixture(7, 'Travel', 40, 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final gesture = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('category-budget-bar'))),
    );
    await gesture.moveBy(const Offset(-24, 0));
    await tester.pump();
    await gesture.moveBy(const Offset(-90, 0));
    await tester.pump();

    expect(find.text('Food'), findsOneWidget);
    expect(find.text('Travel'), findsNothing);

    final held = tester.widget<Transform>(
      find.byKey(const ValueKey('category-budget-bar-translation')),
    );
    final heldDistance = held.transform.getTranslation().x.abs();
    expect(heldDistance, greaterThanOrEqualTo(44));
    expect(heldDistance, lessThanOrEqualTo(72));

    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Food'), findsOneWidget);

    await gesture.up();
    await tester.pump();
    await tester.pumpAndSettle();

    expect(find.text('Travel'), findsOneWidget);
    final settled = tester.widget<Transform>(
      find.byKey(const ValueKey('category-budget-bar-translation')),
    );
    expect(settled.transform.getTranslation().x, 0);
  });

  testWidgets('category bar shows full strength when limit has no spending', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryBudgetBar(
            bar: barFixture(6, 'Food', 0, 10000),
            onTap: () {},
          ),
        ),
      ),
    );

    expect(
      find.byKey(const ValueKey('category-budget-remaining-fill')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-budget-spent-overlay')),
      findsNothing,
    );
  });

  testWidgets('category budget bar renders React-style limit progress fill', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 120,
            child: CategoryBudgetBar(
              bar: barFixture(6, 'Food', 80, 100),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final fill = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('category-progress-fill')),
    );
    final decoration = fill.decoration as BoxDecoration;
    expect(decoration.color, const Color(0xffff8800));

    final barRect = tester.getRect(
      find.byKey(const ValueKey('category-budget-bar')),
    );
    final fillRect = tester.getRect(
      find.byKey(const ValueKey('category-progress-fill')),
    );
    expect(fillRect.width, moreOrLessEquals(barRect.width * 0.8, epsilon: 0.5));
  });

  testWidgets(
    'category bar foreground shrinks over full-width gray background',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 300,
              child: CategoryBudgetBar(
                bar: barFixture(6, 'Food', 5000, 10000),
                onTap: () {},
              ),
            ),
          ),
        ),
      );

      final background = tester.getRect(
        find.byKey(const ValueKey('category-budget-background')),
      );
      final bar = tester.getRect(
        find.byKey(const ValueKey('category-budget-bar')),
      );
      expect(background.width, moreOrLessEquals(300, epsilon: 0.5));
      expect(bar.width, moreOrLessEquals(150, epsilon: 0.5));
      expect(bar.left, moreOrLessEquals(background.left, epsilon: 0.1));
      expect(
        find.byKey(const ValueKey('category-budget-spent-overlay')),
        findsNothing,
      );
    },
  );

  testWidgets('category bar keeps minimum icon width at full spending', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: CategoryBudgetBar(
              bar: barFixture(6, 'Food', 12000, 10000),
              onTap: () {},
            ),
          ),
        ),
      ),
    );

    final background = tester.getRect(
      find.byKey(const ValueKey('category-budget-background')),
    );
    final bar = tester.getRect(
      find.byKey(const ValueKey('category-budget-bar')),
    );
    expect(background.width, moreOrLessEquals(300, epsilon: 0.5));
    expect(bar.width, moreOrLessEquals(84, epsilon: 0.5));
  });

  testWidgets('repeated taps on a bar stay single-tap only', (tester) async {
    var taps = 0;
    final bars = [
      barFixture(6, 'Food', 100, 150),
      barFixture(7, 'Travel', 40, 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) => taps += 1,
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    expect(taps, 2);
  });

  testWidgets('expense budget overview bar shrinks as budget is consumed', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: [
                BackheaderBudgetItem.overview(
                  overviewFixture(BudgetGoalKind.expenseBudget, 25, 100),
                ),
              ],
              categoryBars: const [],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final mask = tester.getRect(
      find.byKey(const ValueKey('budget-progress-frame-mask')),
    );
    final bar = tester.getRect(
      find.byKey(const ValueKey('category-budget-bar')),
    );
    final fillFinder = find.byKey(
      const ValueKey('overview-budget-remaining-fill'),
    );
    expect(fillFinder, findsNothing);
    // Stage width 390 minus 40 px insets on each side gives a 310 px slot.
    // The gray mask remains full width; the visible bar uses the 0.75 ratio.
    expect(mask.width, moreOrLessEquals(310, epsilon: 0.5));
    expect(bar.width, moreOrLessEquals(232.5, epsilon: 0.5));
  });

  testWidgets(
    'stage renders budget progress frame when overview limit exists',
    (tester) async {
      final bars = [
        barFixture(6, 'Food', 50, 0),
        barFixture(7, 'Travel', 25, 0),
        barFixture(8, 'Unused', 0, 0),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 260,
              child: CategoryBudgetStage(
                items: [
                  BackheaderBudgetItem.overview(
                    overviewFixture(BudgetGoalKind.expenseBudget, 70, 100),
                  ),
                  ...bars.map(BackheaderBudgetItem.category),
                ],
                categoryBars: bars,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('budget-progress-frame')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-progress-frame-segment-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-progress-frame-segment-1')),
        findsOneWidget,
      );
      final frameRect = tester.getRect(
        find.byKey(const ValueKey('budget-progress-frame')),
      );
      final segmentRect = tester.getRect(
        find.byKey(const ValueKey('budget-progress-frame-segment-0')),
      );
      final maskRect = tester.getRect(
        find.byKey(const ValueKey('budget-progress-frame-mask')),
      );
      final barRect = tester.getRect(
        find.byKey(const ValueKey('category-budget-bar')),
      );
      expect(
        frameRect.height,
        moreOrLessEquals(BudgetBarGeometry.barHeight * 1.20, epsilon: 0.1),
      );
      expect(segmentRect.height, moreOrLessEquals(frameRect.height));
      final frameBackground = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('budget-progress-frame-background')),
      );
      final frameDecoration = frameBackground.decoration as BoxDecoration;
      expect(frameDecoration.color, Colors.transparent);
      expect(frameDecoration.boxShadow, isNull);
      expect(maskRect.width, greaterThan(barRect.width));
      expect(maskRect.height, moreOrLessEquals(barRect.height, epsilon: 0.1));
      expect(maskRect.left, moreOrLessEquals(barRect.left, epsilon: 0.1));
      expect(
        find.byKey(const ValueKey('budget-progress-frame-border')),
        findsNothing,
      );
      final segmentColor = tester.widget<ColoredBox>(
        find.descendant(
          of: find.byKey(const ValueKey('budget-progress-frame-segment-0')),
          matching: find.byType(ColoredBox),
        ),
      );
      expect(segmentColor.color, segmentColor.color.withValues(alpha: 1));
      expect(find.text('Budget'), findsOneWidget);
      expect(find.text('70 Ft / 100 Ft'), findsOneWidget);
    },
  );

  testWidgets('stage renders warning border only when overview is high', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: [
                BackheaderBudgetItem.overview(
                  overviewFixture(BudgetGoalKind.expenseBudget, 80, 100),
                ),
                BackheaderBudgetItem.category(barFixture(6, 'Food', 80, 0)),
              ],
              categoryBars: [barFixture(6, 'Food', 80, 0)],
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final border = tester.widget<DecoratedBox>(
      find.byKey(const ValueKey('budget-progress-frame-border')),
    );
    final decoration = border.decoration as BoxDecoration;
    expect(decoration.border!.top.color, const Color(0xffff9800));
  });

  testWidgets('stage hides background progress frame without overview limit', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 100, 0)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('budget-progress-frame')), findsNothing);
  });

  testWidgets('category limit editor saves input and reset clears limit', (
    tester,
  ) async {
    double? savedAmount;
    bool? savedAlert;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryLimitEditorSheet(
            bar: barFixture(6, 'Food', 100, 150),
            onCancel: () {},
            onSave: ({required limitAmount, required alertActive}) async {
              savedAmount = limitAmount;
              savedAlert = alertActive;
            },
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('limit-save-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('limit-alert-toggle')), findsNothing);
    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '250',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    expect(savedAmount, isNull);

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(savedAmount, 250);
    expect(savedAlert, isTrue);

    await tester.tap(find.byKey(const ValueKey('limit-reset-inline-button')));
    await tester.pumpAndSettle();
    expect(savedAmount, 250);

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();
    expect(savedAmount, 0);
    expect(savedAlert, isFalse);
  });

  testWidgets('category limit editor partition bar updates the limit amount', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    double? savedAmount;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryLimitEditorSheet(
            bar: barFixture(6, 'Food', 100, 0),
            onCancel: () {},
            onSave: ({required limitAmount, required alertActive}) async {
              savedAmount = limitAmount;
            },
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('category-limit-slider')), findsNothing);
    expect(
      find.byKey(const ValueKey('category-limit-partition-handle')),
      findsOneWidget,
    );

    final barRect = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    await tester.tapAt(
      Offset(barRect.left + barRect.width * 0.72, barRect.center.dy),
    );
    await tester.pump();

    expect(savedAmount, isNull);
    final input = tester.widget<TextField>(
      find.byKey(const ValueKey('limit-amount-input')),
    );
    expect(double.parse(input.controller!.text), greaterThan(0));
    final handle = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-handle')),
    );
    expect(
      handle.center.dx,
      moreOrLessEquals(barRect.left + barRect.width * 0.72, epsilon: 8),
    );

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(savedAmount, isNotNull);
    expect(savedAmount!, greaterThan(0));
  });

  testWidgets('stage lowers labels and hides bottom controls', (tester) async {
    final bars = [
      barFixture(6, 'Food', 100, 150),
      barFixture(7, 'Travel', 40, 0),
    ];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: Align(
              alignment: Alignment.topCenter,
              child: CategoryBudgetStage(
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                periodLabel: 'Május 2026',
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      ),
    );

    final titleTop = tester
        .getRect(find.byKey(const ValueKey('backheader-active-title')))
        .top;
    final barTop = tester
        .getRect(find.byKey(const ValueKey('category-budget-bar')))
        .top;
    final dotTop = tester
        .getRect(find.byKey(const ValueKey('category-budget-dot-0')))
        .top;

    expect(titleTop, greaterThanOrEqualTo(46));
    expect(barTop, greaterThanOrEqualTo(80));
    expect(dotTop, moreOrLessEquals(150, epsilon: 0.1));
    expect(find.byKey(const ValueKey('backheader-period-label')), findsNothing);
    expect(
      find.byKey(const ValueKey('backheader-overview-jump-button')),
      findsNothing,
    );
  });

  testWidgets('classic backheader right-aligns amount without limit', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 40, 0)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final amount = tester.getRect(
      find.byKey(const ValueKey('backheader-active-amount')),
    );

    expect(amount.right, moreOrLessEquals(360, epsilon: 1));
  });

  testWidgets(
    'stage title stays enlarged while amount returns to compact size',
    (tester) async {
      final bars = [barFixture(6, 'Food', 100, 150)];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 260,
              child: CategoryBudgetStage(
                items: bars.map(BackheaderBudgetItem.category).toList(),
                categoryBars: bars,
                onItemTap: (_) {},
              ),
            ),
          ),
        ),
      );

      final title = tester.widget<Text>(
        find.byKey(const ValueKey('backheader-active-title')),
      );
      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('backheader-active-amount')),
      );

      expect(title.style!.fontSize, moreOrLessEquals(16.5, epsilon: 0.01));
      expect(amount.style!.fontSize, moreOrLessEquals(13, epsilon: 0.01));
    },
  );

  testWidgets('progress frame keeps vertical overhang around active bar', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 50, 0)];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              items: [
                BackheaderBudgetItem.overview(
                  overviewFixture(BudgetGoalKind.expenseBudget, 50, 100),
                ),
                ...bars.map(BackheaderBudgetItem.category),
              ],
              categoryBars: bars,
              periodLabel: 'Május 2026',
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    final frame = tester.getRect(
      find.byKey(const ValueKey('budget-progress-frame')),
    );
    final bar = tester.getRect(
      find.byKey(const ValueKey('category-budget-bar')),
    );
    expect(bar.left - frame.left, moreOrLessEquals(BudgetBarGeometry.overhang));
    expect(bar.center.dy, moreOrLessEquals(frame.center.dy, epsilon: 0.1));
    expect(
      bar.top - frame.top,
      moreOrLessEquals(frame.bottom - bar.bottom, epsilon: 0.1),
    );
    expect(bar.width, lessThan(frame.width));
  });

  testWidgets('partition bar renders compact rounded-square allocation', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryLimitPartitionBar(
            height: 23.5,
            allocation: LimitAllocationManager.build(
              overviewLimit: 100,
              bars: [barFixture(6, 'Food', 25, 50)],
            ),
          ),
        ),
      ),
    );

    final bar = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    final container = tester.widget<Container>(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    final decoration = container.foregroundDecoration! as BoxDecoration;
    final border = decoration.border! as Border;
    expect(bar.height, moreOrLessEquals(23.5, epsilon: 0.1));
    expect(border.top.color, Colors.white);
    expect(border.top.width, moreOrLessEquals(1.6, epsilon: 0.01));
    expect(
      find.byKey(const ValueKey('category-limit-partition-segment-0')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-limit-partition-segment-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-limit-partition-segment-2')),
      findsOneWidget,
    );
    final segment = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-segment-0')),
    );
    expect(segment.left, moreOrLessEquals(bar.left, epsilon: 0.1));
    expect(segment.top, moreOrLessEquals(bar.top, epsilon: 0.1));
    expect(segment.bottom, moreOrLessEquals(bar.bottom, epsilon: 0.1));
  });

  testWidgets('partition bar segment tap reports category target id', (
    tester,
  ) async {
    int? tappedTargetId;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            child: CategoryLimitPartitionBar(
              height: 23.5,
              allocation: LimitAllocationManager.build(
                overviewLimit: 100,
                bars: [
                  barFixture(6, 'Food', 25, 50),
                  barFixture(7, 'Travel', 0, 20),
                ],
              ),
              onSegmentTap: (targetId) => tappedTargetId = targetId,
            ),
          ),
        ),
      ),
    );

    await tester.tap(
      find.byKey(const ValueKey('category-limit-partition-segment-0')),
    );
    await tester.pump();

    expect(tappedTargetId, 6);
  });
}

CategoryBudgetBarData barFixture(
  int id,
  String title,
  double spent,
  double limit, {
  TransactionType transactionType = TransactionType.expense,
}) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': transactionType.nativeValue == 'income' ? 'bevétel' : 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#0ea5e9',
    'hasLimit': limit > 0,
    'limitAmount': limit,
    'alertActive': true,
    'isCustomIcon': true,
  });
  return CategoryBudgetBarData(
    key: 'category-$id',
    targetType: LimitTargetType.category,
    targetId: id,
    transactionType: transactionType,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    title: title,
    spent: spent,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: true,
    color: category.slotColor,
    iconSlot: category.iconSlot,
    category: category,
    sourceLimit: null,
  );
}

OverviewBudgetData overviewFixture(
  BudgetGoalKind kind,
  double amount,
  double limit,
) {
  return OverviewBudgetData(
    kind: kind,
    window: LimitWindow.monthly,
    periodKey: '2026-05',
    amount: amount,
    hasLimit: limit > 0,
    limitAmount: limit,
    alertActive: false,
    sourceLimit: null,
  );
}
