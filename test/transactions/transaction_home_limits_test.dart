import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/backheader_budget_item.dart';
import 'package:exptv2/features/transactions/models/budget_goal_kind.dart';
import 'package:exptv2/features/transactions/models/category_budget_bar_data.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/overview_budget_data.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/header_card/budget_target_editor_sheet.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_panel_metrics.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'limit editor keeps save button close to the budget limit field',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final overview = OverviewBudgetData(
        kind: BudgetGoalKind.expenseBudget,
        window: LimitWindow.monthly,
        periodKey: '2026-05',
        amount: 100,
        hasLimit: true,
        limitAmount: 1000,
        alertActive: false,
        sourceLimit: null,
      );
      final item = BackheaderBudgetItem.overview(overview);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BudgetTargetEditorSheet(
              item: item,
              items: [item],
              periodLabel: '2026 május',
              categoryBars: const <CategoryBudgetBarData>[],
              periodIncome: 1000,
              onCancel: () {},
              onActiveItemChanged: (_) {},
              onSaveOverview:
                  (_, {required limitAmount, required alertActive}) async {},
              onSaveCategory:
                  (_, {required limitAmount, required alertActive}) async {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final limitCard = tester.getRect(
        find.byKey(const ValueKey('budget-target-editor-card')),
      );
      final saveButton = tester.getRect(
        find.byKey(const ValueKey('limit-save-button')),
      );
      final amountInput = tester.getRect(
        find.byKey(const ValueKey('limit-amount-input')),
      );
      expect(SlideUpPanelMetrics.budgetBaseHeight, 432);
      expect(limitCard.height, moreOrLessEquals(432, epsilon: 0.1));
      expect(
        limitCard.bottom - saveButton.bottom,
        moreOrLessEquals(
          SlideUpPanelMetrics.transactionActionBottomInset,
          epsilon: 0.1,
        ),
      );
      expect(saveButton.top - amountInput.bottom, lessThanOrEqualTo(22));
    },
  );

  testWidgets('limit editor handle starts near the sheet top', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overview = OverviewBudgetData(
      kind: BudgetGoalKind.expenseBudget,
      window: LimitWindow.monthly,
      periodKey: '2026-05',
      amount: 100,
      hasLimit: true,
      limitAmount: 1000,
      alertActive: false,
      sourceLimit: null,
    );
    final item = BackheaderBudgetItem.overview(overview);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTargetEditorSheet(
            item: item,
            items: [item],
            periodLabel: '2026 május',
            categoryBars: const <CategoryBudgetBarData>[],
            periodIncome: 1000,
            onCancel: () {},
            onActiveItemChanged: (_) {},
            onSaveOverview:
                (_, {required limitAmount, required alertActive}) async {},
            onSaveCategory:
                (_, {required limitAmount, required alertActive}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final limitCard = tester.getRect(
      find.byKey(const ValueKey('budget-target-editor-card')),
    );
    final handle = tester.getRect(
      find.byKey(const ValueKey('limit-card-drag-handle')),
    );

    expect(handle.top - limitCard.top, lessThanOrEqualTo(16));
  });

  testWidgets('limit editor keeps avatar above combined title and period row', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overview = OverviewBudgetData(
      kind: BudgetGoalKind.expenseBudget,
      window: LimitWindow.monthly,
      periodKey: '2026-05',
      amount: 100,
      hasLimit: true,
      limitAmount: 1000,
      alertActive: false,
      sourceLimit: null,
    );
    final item = BackheaderBudgetItem.overview(overview);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTargetEditorSheet(
            item: item,
            items: [item],
            periodLabel: '2026 május',
            categoryBars: const <CategoryBudgetBarData>[],
            periodIncome: 1000,
            onCancel: () {},
            onActiveItemChanged: (_) {},
            onSaveOverview:
                (_, {required limitAmount, required alertActive}) async {},
            onSaveCategory:
                (_, {required limitAmount, required alertActive}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final period = tester.getRect(
      find.byKey(const ValueKey('limit-card-period-label')),
    );
    final avatar = tester.getRect(
      find.byKey(const ValueKey('limit-card-avatar')),
    );
    final title = tester.getRect(
      find.byKey(const ValueKey('limit-card-title')),
    );
    final progress = tester.getRect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
    );
    final slider = tester.getRect(
      find.byKey(const ValueKey('category-limit-slider')),
    );
    final input = tester.getRect(
      find.byKey(const ValueKey('limit-amount-input')),
    );
    final save = tester.getRect(
      find.byKey(const ValueKey('limit-save-button')),
    );

    expect(avatar.bottom, lessThanOrEqualTo(title.top));
    expect(avatar.bottom, lessThanOrEqualTo(period.top));
    expect(period.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1.0));
    expect(title.bottom, lessThan(progress.top));
    expect(progress.bottom, lessThan(slider.top));
    expect(slider.bottom, lessThan(input.top));
    expect(input.bottom, lessThan(save.top));
  });

  testWidgets('limit editor avatar is 20 percent smaller', (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final overview = OverviewBudgetData(
      kind: BudgetGoalKind.expenseBudget,
      window: LimitWindow.monthly,
      periodKey: '2026-05',
      amount: 100,
      hasLimit: true,
      limitAmount: 1000,
      alertActive: false,
      sourceLimit: null,
    );
    final item = BackheaderBudgetItem.overview(overview);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BudgetTargetEditorSheet(
            item: item,
            items: [item],
            periodLabel: '2026 május',
            categoryBars: const <CategoryBudgetBarData>[],
            periodIncome: 1000,
            onCancel: () {},
            onActiveItemChanged: (_) {},
            onSaveOverview:
                (_, {required limitAmount, required alertActive}) async {},
            onSaveCategory:
                (_, {required limitAmount, required alertActive}) async {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      tester.getSize(find.byKey(const ValueKey('limit-card-avatar'))),
      const Size(50, 50),
    );
  });

  testWidgets(
    'expanded home stage saves first item as overview expense budget',
    (tester) async {
      final repository = FakeHomeLimitRepository();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );

      await pumpExpandedMonthlyHome(tester, store);

      expect(
        find.byKey(const ValueKey('category-budget-stage')),
        findsOneWidget,
      );
      expect(find.text('Budget'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('limit-save-button')), findsOneWidget);
      expect(
        tester.getSize(find.byKey(const ValueKey('limit-save-button'))).height,
        50,
      );
      expect(find.byKey(const ValueKey('limit-cancel-button')), findsNothing);
      expect(find.byKey(const ValueKey('limit-alert-toggle')), findsNothing);
      expect(find.byKey(const ValueKey('limit-card-avatar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('limit-reset-inline-button')),
        findsOneWidget,
      );
      final resetButton = tester.widget<IconButton>(
        find.byKey(const ValueKey('limit-reset-inline-button')),
      );
      expect((resetButton.icon as Icon).icon, Icons.delete_outline);

      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '300000',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repository.savedLimits, isEmpty);

      await tester.tap(find.byKey(const ValueKey('limit-save-button')));
      await tester.pumpAndSettle();

      expect(repository.savedLimits.single['targetType'], 'overview');
      expect(repository.savedLimits.single['targetId'], 0);
      expect(repository.savedLimits.single['transactionType'], 'expense');
      expect(repository.savedLimits.single['window'], 'monthly');
      expect(repository.savedLimits.single['periodKey'], '2026-05');
      expect(repository.savedLimits.single['limitAmount'], 300000);
    },
  );

  testWidgets(
    'expanded home stage opens category limit after swiping past budget item',
    (tester) async {
      final repository = FakeHomeLimitRepository();
      repository.limits = [
        CategoryLimit.fromMap({
          'id': 9,
          'targetType': 'overview',
          'targetId': 0,
          'transactionType': 'expense',
          'window': 'monthly',
          'periodKey': '2026-05',
          'hasLimit': true,
          'limitAmount': 1000,
          'alertActive': false,
          'createdAt': 0,
          'updatedAt': 1,
        }),
      ];
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );

      await pumpExpandedMonthlyHome(tester, store);
      await tester.drag(
        find.byKey(const ValueKey('category-budget-bar')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      expect(find.text('Food'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();
      expect(find.text('Food'), findsWidgets);
      expect(find.byKey(const ValueKey('limit-save-button')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('category-limit-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
        findsOneWidget,
      );
      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '250',
      );
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle();
      expect(repository.savedLimits, isEmpty);

      await tester.tap(find.byKey(const ValueKey('limit-save-button')));
      await tester.pumpAndSettle();

      expect(repository.savedLimits.single['targetType'], 'category');
      expect(repository.savedLimits.single['targetId'], 6);
      expect(repository.savedLimits.single['transactionType'], 'expense');
      expect(repository.savedLimits.single['limitAmount'], 250);
    },
  );

  testWidgets(
    'budget magnet strip follows the active swiped category limit',
    (tester) async {
      final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
      repository.limits = [
        CategoryLimit.fromMap({
          'id': 10,
          'targetType': 'overview',
          'targetId': 0,
          'transactionType': 'expense',
          'window': 'monthly',
          'periodKey': '2026-05',
          'hasLimit': true,
          'limitAmount': 1000,
          'alertActive': false,
          'createdAt': 0,
          'updatedAt': 1,
        }),
        CategoryLimit.fromMap({
          'id': 11,
          'targetType': 'category',
          'targetId': 6,
          'transactionType': 'expense',
          'window': 'monthly',
          'periodKey': '2026-05',
          'hasLimit': true,
          'limitAmount': 125,
          'alertActive': false,
          'createdAt': 0,
          'updatedAt': 1,
        }),
      ];
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );
      final budgetTheme = ExpenseTheme.fromSettings(
        AppThemeSettings.defaults().copyWith(magnetType: MagnetType.budget),
      );

      await pumpExpandedMonthlyHome(tester, store, expenseTheme: budgetTheme);
      await tester.drag(
        find.byKey(const ValueKey('category-budget-bar')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();

      final trackRect = tester.getRect(
        find.byKey(const ValueKey('magnet-budget-progress-track')),
      );
      final fillRect = tester.getRect(
        find.byKey(const ValueKey('magnet-budget-progress-fill')),
      );
      final fill = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('magnet-budget-progress-fill')),
      );
      final decoration = fill.decoration as BoxDecoration;

      expect(find.text('Food'), findsOneWidget);
      expect(
        fillRect.width,
        moreOrLessEquals(trackRect.width * 0.8, epsilon: 0.5),
      );
      expect(decoration.color, const Color(0xffff8800));
    },
  );

  testWidgets('budget end button saves period income as overview limit', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('limit-slider-end-button')));
    await tester.pumpAndSettle();
    expect(repository.savedLimits, isEmpty);

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.savedLimits.single['targetType'], 'overview');
    expect(repository.savedLimits.single['limitAmount'], 1000);
  });

  testWidgets(
    'limit editor slider keeps adaptive max after manual high input',
    (tester) async {
      final repository = FakeHomeLimitRepository.withoutBudgetLimits();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );
      await pumpExpandedMonthlyHome(tester, store);

      await tester.drag(
        find.byKey(const ValueKey('category-budget-bar')),
        const Offset(-180, 0),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();

      final initialSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('category-limit-slider')),
      );
      expect(initialSlider.max, 100000);
      expect(initialSlider.divisions, 100);

      await tester.enterText(
        find.byKey(const ValueKey('limit-amount-input')),
        '250000',
      );
      await tester.pump(const Duration(milliseconds: 500));

      final highSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('category-limit-slider')),
      );
      expect(highSlider.max, 250000);

      await tester.drag(
        find.byKey(const ValueKey('category-limit-slider')),
        const Offset(-120, 0),
      );
      await tester.pumpAndSettle();

      final reducedSlider = tester.widget<Slider>(
        find.byKey(const ValueKey('category-limit-slider')),
      );
      expect(reducedSlider.max, 250000);
    },
  );

  testWidgets('limit editor is inline slide-up panel reaching screen bottom', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: TransactionHomePage(store: store)),
      ),
    );
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('summary-pill')),
      const Offset(0, -90),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('header-expand-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    final summaryTop = tester
        .getRect(find.byKey(const ValueKey('summary-pill')))
        .top;
    final card = tester.getRect(
      find.byKey(const ValueKey('budget-target-editor-card')),
    );
    expect(card.top, greaterThan(summaryTop + 70));
    expect(card.height, greaterThan(400));
    expect(card.bottom, moreOrLessEquals(844, epsilon: 0.1));
    expect(find.byKey(const ValueKey('slide-up-menu-veil')), findsOneWidget);
    final veil = tester.widget<ColoredBox>(
      find.byKey(const ValueKey('slide-up-menu-veil')),
    );
    expect(veil.color, Colors.black.withValues(alpha: 0.28));
    expect(find.byKey(const ValueKey('header-balance-text')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('header-category-button')),
      findsOneWidget,
    );
    final balanceOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const ValueKey('header-balance-text')),
        matching: find.byType(Opacity),
      ),
    );
    final categoryOpacity = tester.widget<Opacity>(
      find.ancestor(
        of: find.byKey(const ValueKey('header-category-button')),
        matching: find.byType(Opacity),
      ),
    );
    expect(balanceOpacity.opacity, 0);
    expect(categoryOpacity.opacity, 0);
    expect(find.byKey(const ValueKey('limit-save-button')), findsOneWidget);
    expect(find.byKey(const ValueKey('limit-cancel-button')), findsNothing);
  });

  testWidgets(
    'redesigned limit card stacks avatar title period partition slider input and save',
    (tester) async {
      final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );
      await pumpExpandedMonthlyHome(tester, store);

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('limit-card-previous-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('limit-card-next-button')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('limit-card-avatar')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('limit-card-period-label')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('limit-amount-input')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('limit-reset-inline-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-limit-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
        findsOneWidget,
      );

      final title = tester.getRect(
        find.byKey(const ValueKey('limit-card-title')),
      );
      final period = tester.getRect(
        find.byKey(const ValueKey('limit-card-period-label')),
      );
      final avatar = tester.getRect(
        find.byKey(const ValueKey('limit-card-avatar')),
      );
      final partition = tester.getRect(
        find.byKey(const ValueKey('category-limit-partition-bar')),
      );
      final slider = tester.getRect(
        find.byKey(const ValueKey('category-limit-slider')),
      );
      final amount = tester.getRect(
        find.byKey(const ValueKey('limit-amount-input')),
      );
      final save = tester.getRect(
        find.byKey(const ValueKey('limit-save-button')),
      );

      expect(avatar.bottom, lessThanOrEqualTo(title.top));
      expect(avatar.bottom, lessThanOrEqualTo(period.top));
      expect(period.center.dy, moreOrLessEquals(title.center.dy, epsilon: 1.0));
      expect(partition.top, greaterThanOrEqualTo(title.bottom));
      expect(partition.height, moreOrLessEquals(18.8, epsilon: 0.2));
      expect(slider.top, greaterThan(partition.bottom));
      expect(amount.top, greaterThan(slider.bottom));
      expect(save.top, greaterThan(amount.bottom));
    },
  );

  testWidgets('limit editor avatar double tap jumps back to budget item', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('limit-card-next-button')));
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('limit-card-title'))).data,
      'Food',
    );

    final avatarCenter = tester.getCenter(
      find.byKey(const ValueKey('limit-card-avatar')),
    );
    await tester.tapAt(avatarCenter);
    await tester.pump(const Duration(milliseconds: 50));
    await tester.tapAt(avatarCenter);
    await tester.pumpAndSettle();

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('limit-card-title'))).data,
      'Budget',
    );
  });

  testWidgets('partition tap selects category and syncs backheader', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('limit-allocation-pie-chart')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('category-limit-partition-segment-0')),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('limit-card-title')), findsOneWidget);
    expect(find.text('Food'), findsWidgets);
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('backheader-active-title')))
          .data,
      'Food',
    );
  });

  testWidgets('editor arrows sync active backheader bar', (tester) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('limit-card-next-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('backheader-active-title')),
      findsOneWidget,
    );
    expect(find.text('Food'), findsWidgets);
  });

  testWidgets('backheader bar single tap opens the limit editor immediately', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.drag(
      find.byKey(const ValueKey('category-budget-bar')),
      const Offset(-100, 0),
    );
    await tester.pumpAndSettle();
    expect(find.text('Food'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('backheader-overview-jump-button')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pump(const Duration(milliseconds: 50));

    expect(
      find.byKey(const ValueKey('budget-target-editor-card')),
      findsOneWidget,
    );
    expect(find.text('Food'), findsWidgets);
  });

  testWidgets(
    'external limit editor request does not mark home overlay as blocking',
    (tester) async {
      final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
      final store = TransactionStore(
        repository,
        clock: () => DateTime(2026, 5, 17),
      );
      final activeKey = ValueNotifier<String?>(null);
      final blockingStates = <bool>[];
      String? requestedTitle;
      addTearDown(activeKey.dispose);

      await pumpExpandedMonthlyHome(
        tester,
        store,
        onBlockingOverlayChanged: blockingStates.add,
        budgetEditorActiveKey: activeKey,
        onBudgetTargetEditorRequested:
            (item, {required requestedAt, required headerExpanded}) {
              requestedTitle = item.title;
              activeKey.value = item.key;
            },
      );
      blockingStates.clear();

      await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
      await tester.pump(const Duration(milliseconds: 50));

      expect(requestedTitle, 'Budget');
      expect(blockingStates, isNot(contains(true)));
      expect(
        find.byKey(const ValueKey('budget-target-editor-card')),
        findsNothing,
      );
    },
  );

  testWidgets('limit editor discards pending changes when swiped closed', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '350000',
    );
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pumpAndSettle();

    final cardTopLeft = tester.getTopLeft(
      find.byKey(const ValueKey('budget-target-editor-card')),
    );
    final gesture = await tester.startGesture(
      cardTopLeft + const Offset(180, 90),
    );
    await gesture.moveBy(const Offset(0, 260));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.savedLimits, isEmpty);
    expect(
      find.byKey(const ValueKey('budget-target-editor-card')),
      findsNothing,
    );
  });

  testWidgets('limit editor save commits pending edits across items', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withBudgetAndCategoryLimits();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '800',
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('limit-card-next-button')));
    await tester.pumpAndSettle();
    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '150',
    );
    await tester.pumpAndSettle();

    expect(repository.savedLimits, isEmpty);

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.savedLimits, hasLength(2));
    expect(
      repository.savedLimits.map((row) => row['targetType']),
      containsAll(['overview', 'category']),
    );
  });

  testWidgets('income side uses income goal and income category allocation', (
    tester,
  ) async {
    final repository = FakeHomeLimitRepository.withIncomeData();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 5, 17),
    );
    await pumpExpandedMonthlyHome(tester, store);

    await tester.tap(find.text('Bevétel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('category-budget-bar')));
    await tester.pumpAndSettle();

    expect(find.text('Beveteli cel'), findsWidgets);
    expect(
      find.byKey(const ValueKey('category-limit-partition-bar')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('limit-allocation-pie-chart')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('limit-slider-end-button')));
    await tester.pumpAndSettle();
    expect(repository.savedLimits, isEmpty);

    await tester.enterText(
      find.byKey(const ValueKey('limit-amount-input')),
      '700',
    );
    await tester.pumpAndSettle();
    expect(repository.savedLimits, isEmpty);

    await tester.tap(find.byKey(const ValueKey('limit-save-button')));
    await tester.pumpAndSettle();

    expect(repository.savedLimits.last['targetType'], 'overview');
    expect(repository.savedLimits.last['transactionType'], 'income');
  });
}

Future<void> pumpExpandedMonthlyHome(
  WidgetTester tester,
  TransactionStore store, {
  ValueChanged<bool>? onBlockingOverlayChanged,
  BudgetTargetEditorRequest? onBudgetTargetEditorRequested,
  ValueNotifier<String?>? budgetEditorActiveKey,
  ExpenseTheme? expenseTheme,
}) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 780,
          child: TransactionHomePage(
            store: store,
            expenseTheme: expenseTheme,
            onBlockingOverlayChanged: onBlockingOverlayChanged,
            onBudgetTargetEditorRequested: onBudgetTargetEditorRequested,
            budgetEditorActiveKey: budgetEditorActiveKey,
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();

  await tester.drag(
    find.byKey(const ValueKey('summary-pill')),
    const Offset(0, -90),
  );
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('header-expand-button')));
  await tester.pumpAndSettle();
}

class FakeHomeLimitRepository extends TransactionRepositoryContract {
  FakeHomeLimitRepository();

  FakeHomeLimitRepository.withoutBudgetLimits();

  FakeHomeLimitRepository.withIncomeData() {
    limits = [
      CategoryLimit.fromMap({
        'id': 20,
        'targetType': 'overview',
        'targetId': 0,
        'transactionType': 'income',
        'window': 'monthly',
        'periodKey': '2026-05',
        'hasLimit': true,
        'limitAmount': 1000,
        'alertActive': false,
        'createdAt': 0,
        'updatedAt': 1,
      }),
    ];
  }

  FakeHomeLimitRepository.withBudgetAndCategoryLimits() {
    categories.add(
      TransactionCategory.fromMap({
        'transactionCategoryID': 7,
        'name': 'Travel',
        'type': 'kiadás',
        'colorSlot': 8,
        'iconSlot': 3,
        'backgroundColor': '#38bdf8',
        'hasLimit': false,
        'limitAmount': 0,
        'alertActive': false,
        'isCustomIcon': true,
      }),
    );
    limits = [
      CategoryLimit.fromMap({
        'id': 10,
        'targetType': 'overview',
        'targetId': 0,
        'transactionType': 'expense',
        'window': 'monthly',
        'periodKey': '2026-05',
        'hasLimit': true,
        'limitAmount': 1000,
        'alertActive': false,
        'createdAt': 0,
        'updatedAt': 1,
      }),
      CategoryLimit.fromMap({
        'id': 11,
        'targetType': 'category',
        'targetId': 6,
        'transactionType': 'expense',
        'window': 'monthly',
        'periodKey': '2026-05',
        'hasLimit': true,
        'limitAmount': 250,
        'alertActive': false,
        'createdAt': 0,
        'updatedAt': 1,
      }),
    ];
  }

  final savedLimits = <Map<String, Object?>>[];
  var limits = <CategoryLimit>[];

  final categories = <TransactionCategory>[
    TransactionCategory.fromMap({
      'transactionCategoryID': 5,
      'name': 'Salary',
      'type': 'bevétel',
      'colorSlot': 2,
      'iconSlot': 0,
      'backgroundColor': '#3b82f6',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
    TransactionCategory.fromMap({
      'transactionCategoryID': 6,
      'name': 'Food',
      'type': 'kiadás',
      'colorSlot': 7,
      'iconSlot': 2,
      'backgroundColor': '#0ea5e9',
      'hasLimit': false,
      'limitAmount': 0,
      'alertActive': false,
      'isCustomIcon': true,
    }),
  ];

  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({
      'id': 1,
      'date': '2026.05.04',
      'time': '12:00',
      'merchant': 'Shop',
      'amount': -100,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    }),
    TransactionRecord.fromMap({
      'id': 2,
      'date': '2026.05.01',
      'time': '09:00',
      'merchant': 'Salary',
      'amount': 1000,
      'userAssignedName': null,
      'transactionCategoryID': 5,
    }),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categories,
    transactions: transactions,
    limits: limits,
  );

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    return TransactionPage(
      transactions: const [],
      totalCount: 0,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    savedLimits.add(payload);
    final limit = CategoryLimit.fromMap({
      'id': 1,
      ...payload,
      'hasLimit': payload['hasLimit'],
      'createdAt': 0,
      'updatedAt': 1,
    });
    limits = [limit];
    return limit;
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => limits;

  @override
  Future<TransactionRecord> addTransaction(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) async {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) async {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async =>
      throw UnimplementedError();

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();

  @override
  Future<bool> deleteCategory(int id) async => throw UnimplementedError();

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async => throw UnimplementedError();

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      throw UnimplementedError();

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];

  @override
  Future<Map<int, int>> categoryCounts() async => const {5: 1, 6: 1};
}
