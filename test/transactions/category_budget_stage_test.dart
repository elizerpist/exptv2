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
    expect(find.byKey(const ValueKey('category-progress-fill')), findsNothing);
    expect(find.byKey(const ValueKey('category-budget-dot-0')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('category-budget-bar')),
      const Offset(-180, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Travel'), findsOneWidget);
    expect(find.text('40 Ft'), findsOneWidget);

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
              backheaderStyle: BackheaderStyle.colorFieldPartition,
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
      find.byKey(const ValueKey('backheader-style-colorFieldPartition')),
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
              height: 260,
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
      expect(find.text('Food'), findsOneWidget);
      expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
    }
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
              height: 260,
              child: CategoryBudgetStage(
                backheaderStyle: BackheaderStyle.mosaicBudget,
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
    expect(savedAlert, isFalse);

    await tester.tap(find.byKey(const ValueKey('limit-reset-inline-button')));
    await tester.pumpAndSettle();
    expect(savedAmount, 250);

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();
    expect(savedAmount, 0);
  });

  testWidgets('category limit editor slider updates the limit amount', (
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
    expect(find.byKey(const ValueKey('category-limit-slider')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('category-limit-slider')),
      const Offset(220, 0),
    );
    await tester.pumpAndSettle();

    expect(savedAmount, isNull);
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
    expect(bar.height, moreOrLessEquals(23.5, epsilon: 0.1));
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
  double limit,
) {
  final category = TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': title,
    'type': 'kiadás',
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
    transactionType: TransactionType.expense,
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
