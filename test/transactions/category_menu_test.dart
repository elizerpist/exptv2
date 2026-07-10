import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_card.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_icon_badge.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_menu_panel.dart';
import 'package:exptv2/features/transactions/widgets/slide_up_menu_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('category panel filters cards and protects used categories', (
    tester,
  ) async {
    TransactionCategory? selected;
    TransactionCategory? modified;
    TransactionCategory? deleted;
    var addPressed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            activeType: TransactionType.expense,
            categories: categoryFixtures,
            categoryTransactionCounts: const {6: 3},
            activeCategory: null,
            onSelect: (category) => selected = category,
            onModify: (category) => modified = category,
            onDelete: (category) => deleted = category,
            onAdd: () => addPressed = true,
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.text('Válassz kategóriát'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('category-menu-back-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-menu-all-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-menu-add-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-menu-apply-button')),
      findsOneWidget,
    );
    expect(find.text('Q'), findsOneWidget);
    expect(find.text('Salary'), findsNothing);

    await tester.tap(find.byKey(const ValueKey('category-card-6')));
    expect(selected?.name, 'Q');

    selected = null;
    modified = null;
    await tester.tapAt(
      tester.getCenter(find.byKey(const ValueKey('category-icon-6'))),
    );
    expect(selected?.name, 'Q');
    expect(modified, isNull);

    await tester.longPress(
      find.byKey(const ValueKey('category-card-6')),
      warnIfMissed: false,
    );
    expect(modified?.name, 'Q');

    await tester.tap(find.byKey(const ValueKey('category-delete-6')));
    expect(deleted, isNull);

    expect(addPressed, isFalse);
    await tester.tap(find.byKey(const ValueKey('category-menu-add-card')));
    expect(addPressed, isTrue);
  });

  testWidgets('home header category button opens picker and filters logs', (
    tester,
  ) async {
    final store = TransactionStore(FakeTransactionRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(find.text('Válassz kategóriát'), findsOneWidget);
    await _scrollCategoryCardIntoView(tester, 6);
    await tester.tap(find.byKey(const ValueKey('category-card-6')));
    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));
    await tester.pumpAndSettle();

    expect(store.activeCategory?.name, 'Q');
    expect(find.text('Test Store'), findsOneWidget);
  });

  testWidgets('home shows listed transaction count below search pill', (
    tester,
  ) async {
    final store = TransactionStore(FakeTransactionRepository());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('search-pill-filtered-count')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-list-header-date')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('transaction-list-header-count')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('transaction-date-group-2025.09.25')),
      findsOneWidget,
    );
    expect(find.text('2025.09.25'), findsOneWidget);
    expect(find.text('1 tranzakció'), findsOneWidget);
  });

  testWidgets('slide-up category menu keeps picker behind add editor', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = TransactionStore(FakeTransactionRepository());
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 919,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-menu-add-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('category-menu-add-card')),
      findsOneWidget,
    );

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final addRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-add-card')),
    );
    expect(sheetRect.bottom, moreOrLessEquals(919, epsilon: 1));
    expect(addRect.top, greaterThan(sheetRect.top));

    final shortDrag = await tester.startGesture(
      sheetRect.topCenter + const Offset(0, 24),
    );
    await shortDrag.moveBy(const Offset(0, 48));
    await tester.pump(const Duration(milliseconds: 240));
    await shortDrag.up();
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );

    await tester.tap(find.byKey(const ValueKey('category-menu-add-card')));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('category-editor-slide-card')),
      findsOneWidget,
    );
  });

  testWidgets('slide-up category menu scroll body ends above the add pill', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = TransactionStore(FakeTransactionRepository());
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 919,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    final body = tester.getRect(
      find.byKey(const ValueKey('category-menu-scroll-body')),
    );
    final applyButton = tester.getRect(
      find.byKey(const ValueKey('category-menu-apply-button')),
    );

    expect(body.bottom, lessThan(applyButton.top));
    expect(applyButton.top - body.bottom, greaterThanOrEqualTo(0));
  });

  testWidgets('slide-up category menu drags only from the handler', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final store = TransactionStore(FakeTransactionRepository());
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 919,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();

    final initialTranslation = _slideCardTranslationY(tester);
    final contentDrag = await tester.startGesture(
      tester.getCenter(find.byKey(const ValueKey('category-card-6'))),
    );
    await contentDrag.moveBy(const Offset(0, 92));
    await tester.pump();
    expect(_slideCardTranslationY(tester), initialTranslation);
    await contentDrag.up();
    await tester.pumpAndSettle();

    final sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final handlerDrag = await tester.startGesture(
      sheetRect.topCenter + const Offset(0, 24),
    );
    await handlerDrag.moveBy(const Offset(0, 64));
    await tester.pump();
    expect(_slideCardTranslationY(tester), greaterThan(initialTranslation));
    await handlerDrag.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
  });

  testWidgets('vendor sheet drag is disabled while vendor list is scrolled', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 919);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = FakeTransactionRepository();
    repository.transactions
      ..clear()
      ..addAll([
        for (var index = 0; index < 30; index += 1)
          TransactionRecord.fromMap({
            'id': index + 1,
            'date': '2025.09.25',
            'time': '20:30:00',
            'merchant': 'Vendor $index',
            'amount': -100 - index,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
      ]);
    final store = TransactionStore(repository);
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 919,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    SlideUpMenuCard vendorSheet() => tester.widget<SlideUpMenuCard>(
      find.ancestor(
        of: find.byKey(const ValueKey('vendor-filter-slide-card')),
        matching: find.byType(SlideUpMenuCard),
      ),
    );

    expect(vendorSheet().canDragFrom, isNotNull);
    expect(vendorSheet().canDragFrom!(Offset.zero, Offset.zero, 0, 32), isTrue);

    await tester.drag(
      find.byKey(const ValueKey('vendor-filter-list')),
      const Offset(0, -420),
    );
    await tester.pumpAndSettle();

    expect(
      vendorSheet().canDragFrom!(Offset.zero, Offset.zero, 0, 32),
      isFalse,
    );
  });

  testWidgets(
    'vendor sheet search filters rows and keeps card fixed for keyboard',
    (tester) async {
      final repository = FakeTransactionRepository();
      repository.transactions
        ..clear()
        ..addAll([
          TransactionRecord.fromMap({
            'id': 1,
            'date': '2025.09.25',
            'time': '20:30:00',
            'merchant': 'Alpha Market',
            'amount': -100,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
          TransactionRecord.fromMap({
            'id': 2,
            'date': '2025.09.25',
            'time': '20:31:00',
            'merchant': 'Beta Bolt',
            'amount': -200,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
          TransactionRecord.fromMap({
            'id': 3,
            'date': '2025.09.25',
            'time': '20:32:00',
            'merchant': 'Gamma Shop',
            'amount': -300,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
        ]);
      final store = TransactionStore(repository);
      final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 919),
              viewInsets: EdgeInsets.only(bottom: 180),
            ),
            child: Scaffold(
              resizeToAvoidBottomInset: false,
              body: SizedBox(
                width: 390,
                height: 919,
                child: TransactionHomePage(store: store, expenseTheme: theme),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('vendor-filter-search-pill')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-search-field')),
        findsOneWidget,
      );
      expect(find.text('3 vendor'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Alpha Market')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Beta Bolt')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Gamma Shop')),
        findsOneWidget,
      );

      final transform = tester.widget<Transform>(
        find.byKey(const ValueKey('slide-up-menu-transform')),
      );
      expect(transform.transform.getTranslation().y, moreOrLessEquals(0));

      final footerRect = tester.getRect(
        find.byKey(const ValueKey('vendor-filter-footer')),
      );
      expect(footerRect.bottom, lessThanOrEqualTo(919 - 180));

      await tester.enterText(
        find.byKey(const ValueKey('vendor-filter-search-field')),
        'beta',
      );
      await tester.pumpAndSettle();

      expect(find.text('1 vendor'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Alpha Market')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Beta Bolt')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Gamma Shop')),
        findsNothing,
      );
    },
  );

  testWidgets('vendor sheet groups sorted vendors by alphabetic headers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = FakeTransactionRepository();
    repository.transactions
      ..clear()
      ..addAll([
        TransactionRecord.fromMap({
          'id': 1,
          'date': '2025.09.25',
          'time': '20:30:00',
          'merchant': 'Élelmiszer Bolt',
          'amount': -100,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
        TransactionRecord.fromMap({
          'id': 2,
          'date': '2025.09.25',
          'time': '20:31:00',
          'merchant': 'alpha Market',
          'amount': -200,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
        TransactionRecord.fromMap({
          'id': 3,
          'date': '2025.09.25',
          'time': '20:32:00',
          'merchant': '# Corner',
          'amount': -300,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
        TransactionRecord.fromMap({
          'id': 4,
          'date': '2025.09.25',
          'time': '20:33:00',
          'merchant': 'Beta Bolt',
          'amount': -400,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
      ]);
    final store = TransactionStore(repository);
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 1200,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    for (final group in const ['#', 'A', 'B', 'E']) {
      expect(
        find.byKey(ValueKey('vendor-filter-section-$group')),
        findsOneWidget,
      );
    }

    final hashTop = tester
        .getTopLeft(find.byKey(const ValueKey('vendor-filter-section-#')))
        .dy;
    final aTop = tester
        .getTopLeft(find.byKey(const ValueKey('vendor-filter-section-A')))
        .dy;
    final bTop = tester
        .getTopLeft(find.byKey(const ValueKey('vendor-filter-section-B')))
        .dy;
    final eTop = tester
        .getTopLeft(find.byKey(const ValueKey('vendor-filter-section-E')))
        .dy;
    expect(hashTop, lessThan(aTop));
    expect(aTop, lessThan(bTop));
    expect(bTop, lessThan(eTop));

    expect(
      tester
          .getTopLeft(find.byKey(const ValueKey('vendor-filter-row-# Corner')))
          .dy,
      greaterThan(hashTop),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('vendor-filter-row-alpha Market')),
          )
          .dy,
      greaterThan(aTop),
    );
    expect(
      tester
          .getTopLeft(
            find.byKey(const ValueKey('vendor-filter-row-Élelmiszer Bolt')),
          )
          .dy,
      greaterThan(eTop),
    );

    final dateHeaderText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('transaction-date-group-2025.09.25')),
        matching: find.text('2025.09.25'),
      ),
    );
    final vendorHeaderText = tester.widget<Text>(
      find.descendant(
        of: find.byKey(const ValueKey('vendor-filter-section-A')),
        matching: find.text('A'),
      ),
    );
    expect(vendorHeaderText.style?.fontSize, dateHeaderText.style?.fontSize);

    await tester.enterText(
      find.byKey(const ValueKey('vendor-filter-search-field')),
      'bolt',
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('vendor-filter-section-#')), findsNothing);
    expect(find.byKey(const ValueKey('vendor-filter-section-A')), findsNothing);
    expect(
      find.byKey(const ValueKey('vendor-filter-section-B')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('vendor-filter-section-E')),
      findsOneWidget,
    );
  });

  testWidgets('vendor cards use the same background color as category cards', (
    tester,
  ) async {
    final repository = FakeTransactionRepository();
    final store = TransactionStore(repository);
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(boxColor: AppBoxColor.darkgray),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 919,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    final vendorSurface = tester.widget<Container>(
      find.byKey(const ValueKey('vendor-filter-row-surface-Test Store')),
    );
    final decoration = vendorSurface.decoration! as BoxDecoration;
    expect(decoration.color, theme.categoryCard);
  });

  testWidgets('vendor cards are compact grid tiles under alphabetic headers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    final repository = FakeTransactionRepository();
    repository.transactions
      ..clear()
      ..addAll([
        TransactionRecord.fromMap({
          'id': 1,
          'date': '2025.09.25',
          'time': '20:30:00',
          'merchant': 'Alpha Market',
          'amount': -100,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
        TransactionRecord.fromMap({
          'id': 2,
          'date': '2025.09.25',
          'time': '20:31:00',
          'merchant': 'Aqua Shop',
          'amount': -200,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
      ]);
    final store = TransactionStore(repository);
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 1200,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    final alphaRect = tester.getRect(
      find.byKey(const ValueKey('vendor-filter-row-Alpha Market')),
    );
    final aquaRect = tester.getRect(
      find.byKey(const ValueKey('vendor-filter-row-Aqua Shop')),
    );
    final headerRect = tester.getRect(
      find.byKey(const ValueKey('vendor-filter-section-A')),
    );

    expect(alphaRect.top, greaterThanOrEqualTo(headerRect.bottom));
    expect(aquaRect.top, moreOrLessEquals(alphaRect.top, epsilon: 1));
    expect(alphaRect.width, lessThan(180));
    expect(aquaRect.left, greaterThan(alphaRect.right));
    expect(alphaRect.height, moreOrLessEquals(150, epsilon: 1));
  });

  testWidgets('vendor amounts use log amount sign and color by active type', (
    tester,
  ) async {
    final repository = FakeTransactionRepository();
    repository.transactions
      ..clear()
      ..addAll([
        TransactionRecord.fromMap({
          'id': 1,
          'date': '2025.09.25',
          'time': '20:30:00',
          'merchant': 'Expense Vendor',
          'amount': -1200,
          'userAssignedName': null,
          'transactionCategoryID': 6,
        }),
        TransactionRecord.fromMap({
          'id': 2,
          'date': '2025.09.25',
          'time': '20:31:00',
          'merchant': 'Income Vendor',
          'amount': 3400,
          'userAssignedName': null,
          'transactionCategoryID': 5,
        }),
      ]);
    final store = TransactionStore(repository);
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 919,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    final expenseAmount = tester.widget<Text>(
      find.byKey(const ValueKey('vendor-filter-amount-Expense Vendor')),
    );
    expect(expenseAmount.data, '-1 200 Ft');
    expect(expenseAmount.style?.color, AppColors.expense);

    await tester.tap(find.byKey(const ValueKey('vendor-filter-apply-button')));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Bevétel'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
    await tester.pumpAndSettle();

    final incomeAmount = tester.widget<Text>(
      find.byKey(const ValueKey('vendor-filter-amount-Income Vendor')),
    );
    expect(incomeAmount.data, '+3 400 Ft');
    expect(incomeAmount.style?.color, AppColors.income);
  });

  testWidgets(
    'vendor name edits inline, refreshes matching logs, and can reset',
    (tester) async {
      tester.view.physicalSize = const Size(390, 919);
      tester.view.devicePixelRatio = 1;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });
      final repository = FakeTransactionRepository();
      repository.transactions
        ..clear()
        ..addAll([
          TransactionRecord.fromMap({
            'id': 1,
            'date': '2025.09.25',
            'time': '20:30:00',
            'merchant': 'Test Store',
            'amount': -500,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
          TransactionRecord.fromMap({
            'id': 2,
            'date': '2025.09.25',
            'time': '20:31:00',
            'merchant': 'Test Store',
            'amount': -700,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
          TransactionRecord.fromMap({
            'id': 3,
            'date': '2025.09.25',
            'time': '20:32:00',
            'merchant': 'Other Shop',
            'amount': -900,
            'userAssignedName': null,
            'transactionCategoryID': 6,
          }),
        ]);
      final store = TransactionStore(repository);
      final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 390,
              height: 919,
              child: TransactionHomePage(store: store, expenseTheme: theme),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('search-pill-vendor-button')));
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(const ValueKey('vendor-filter-name-Test Store')),
      );
      await tester.pumpAndSettle();

      final inputFinder = find.byKey(
        const ValueKey('vendor-filter-name-input-Test Store'),
      );
      expect(inputFinder, findsOneWidget);
      final input = tester.widget<TextField>(inputFinder);
      expect(input.controller?.selection.baseOffset, 'Test Store'.length);

      await tester.enterText(inputFinder, 'Fresh Mart');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(repository.renameArgs, ['Test Store', 'Fresh Mart']);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('transaction-logbox-name-text-1')),
            )
            .data,
        'Fresh Mart',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('transaction-logbox-name-text-2')),
            )
            .data,
        'Fresh Mart',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('transaction-logbox-name-text-3')),
            )
            .data,
        'Other Shop',
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Fresh Mart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-amount-Fresh Mart')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-reset-Test Store')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('vendor-filter-reset-Test Store')),
      );
      await tester.pumpAndSettle();

      expect(repository.resetMerchant, 'Test Store');
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('transaction-logbox-name-text-1')),
            )
            .data,
        'Test Store',
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-row-Test Store')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('vendor-filter-reset-Test Store')),
        findsNothing,
      );
    },
  );

  testWidgets('slide-up category menu closes on apply and drag gestures', (
    tester,
  ) async {
    final store = TransactionStore(FakeTransactionRepository());
    final theme = ExpenseTheme.fromSettings(AppThemeSettings.defaults());

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: TransactionHomePage(store: store, expenseTheme: theme),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();
    await _scrollCategoryCardIntoView(tester, 6);
    await tester.tap(find.byKey(const ValueKey('category-card-6')));
    await tester.pump();
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
    await tester.tap(find.byKey(const ValueKey('category-menu-apply-button')));
    await tester.pumpAndSettle();

    expect(store.activeCategory?.name, 'Q');
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();
    var sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final longDrag = await tester.startGesture(
      sheetRect.topCenter + const Offset(0, 24),
    );
    await longDrag.moveBy(const Offset(0, 130));
    await longDrag.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();
    sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final fastSwipe = await tester.startGesture(
      sheetRect.topCenter + const Offset(0, 24),
    );
    await fastSwipe.moveBy(const Offset(0, 82));
    await tester.pump(const Duration(milliseconds: 12));
    await fastSwipe.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsNothing,
    );

    await tester.tap(find.byKey(const ValueKey('header-category-button')));
    await tester.pumpAndSettle();
    sheetRect = tester.getRect(
      find.byKey(const ValueKey('category-menu-slide-card')),
    );
    final diagonalDrag = await tester.startGesture(
      sheetRect.topCenter + const Offset(0, 24),
    );
    await diagonalDrag.moveBy(const Offset(80, 88));
    await diagonalDrag.up();
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('category-menu-slide-card')),
      findsOneWidget,
    );
  });

  testWidgets(
    'category cards use inset body and raised avatar in neumorphism',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryMenuPanel(
              activeType: TransactionType.expense,
              categories: categoryFixtures,
              categoryTransactionCounts: const {6: 3},
              activeCategory: categoryFixtures.last,
              surfaceColor: AppColors.gray200,
              cardSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
              avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
              onSelect: (_) {},
              onModify: (_) {},
              onDelete: (_) {},
              onAdd: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('category-card-surface-6')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('category-icon-surface-6')),
        findsOneWidget,
      );
      final card = tester.widget<Container>(
        find.byKey(const ValueKey('category-card-surface-6')),
      );
      expect((card.decoration! as BoxDecoration).boxShadow, isNull);
    },
  );

  testWidgets('category card neumorph style uses raised card shadows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            activeType: TransactionType.expense,
            categories: categoryFixtures,
            categoryTransactionCounts: const {6: 3},
            activeCategory: null,
            cardSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
            onSelect: (_) {},
            onModify: (_) {},
            onDelete: (_) {},
            onAdd: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('category-card-surface-6')),
    );
    final shadows = (card.decoration! as BoxDecoration).boxShadow;
    expect(shadows, hasLength(2));
    expect(shadows!.first.offset, const Offset(7, 7));
    expect(shadows.first.blurRadius, 15);
  });

  testWidgets(
    'selected category card stays inset without active border until apply',
    (tester) async {
      Set<int>? applied;
      const accent = Color(0xFF06B6D4);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryMenuPanel(
              activeType: TransactionType.expense,
              categories: categoryFixtures,
              categoryTransactionCounts: const {6: 3},
              activeCategory: null,
              selectedCategoryIds: const <int>{},
              onApply: (ids) => applied = ids,
              cardSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
              avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
              accentColor: accent,
              onSelect: (_) {},
              onModify: (_) {},
              onDelete: (_) {},
              onAdd: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('category-card-6')));
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('category-card-active-border-6')),
        findsNothing,
      );
      final cardSurface = tester.widget<Container>(
        find.byKey(const ValueKey('category-card-surface-6')),
      );
      expect((cardSurface.decoration! as BoxDecoration).boxShadow, isNull);
      expect(applied, isNull);

      await tester.tap(
        find.byKey(const ValueKey('category-menu-apply-button')),
      );
      expect(applied, {6});
    },
  );

  testWidgets('category body press applies avatar neumorph in the same frame', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 180,
            child: CategoryCard(
              category: categoryFixtures.last,
              transactionCount: 3,
              cardSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
              avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
              onSelect: (_) {},
              onModify: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );

    final cardFinder = find.byKey(const ValueKey('category-card-surface-6'));
    final avatarFinder = find.byKey(const ValueKey('category-icon-surface-6'));
    final releasedCardDecoration =
        tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
    final releasedAvatarDecoration =
        tester.widget<Container>(avatarFinder).decoration! as BoxDecoration;
    final cardRect = tester.getRect(cardFinder);

    final gesture = await tester.startGesture(
      cardRect.bottomCenter - const Offset(0, 36),
    );
    await tester.pump();

    final pressedCardDecoration =
        tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
    final pressedAvatarDecoration =
        tester.widget<Container>(avatarFinder).decoration! as BoxDecoration;
    expect(pressedCardDecoration, isNot(releasedCardDecoration));
    expect(pressedAvatarDecoration, isNot(releasedAvatarDecoration));

    await gesture.up();
  });

  testWidgets(
    'add category card body press applies plus avatar neumorph shadow',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryMenuPanel(
              activeType: TransactionType.expense,
              categories: categoryFixtures,
              categoryTransactionCounts: const {6: 3},
              activeCategory: null,
              cardSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
              avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
              onSelect: (_) {},
              onModify: (_) {},
              onDelete: (_) {},
              onAdd: () {},
              onClose: () {},
            ),
          ),
        ),
      );

      final cardFinder = find.byKey(
        const ValueKey('category-utility-surface-Új kategória'),
      );
      final avatarFinder = find.byKey(
        const ValueKey('category-utility-avatar-surface-Új kategória'),
      );
      final releasedCardDecoration =
          tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
      final releasedAvatarDecoration =
          tester.widget<Container>(avatarFinder).decoration! as BoxDecoration;
      final cardRect = tester.getRect(cardFinder);

      final gesture = await tester.startGesture(
        cardRect.bottomCenter - const Offset(0, 36),
      );
      await tester.pump();

      final pressedCardDecoration =
          tester.widget<Container>(cardFinder).decoration! as BoxDecoration;
      final pressedAvatarDecoration =
          tester.widget<Container>(avatarFinder).decoration! as BoxDecoration;
      expect(pressedCardDecoration, isNot(releasedCardDecoration));
      expect(pressedAvatarDecoration, isNot(releasedAvatarDecoration));

      await gesture.up();
    },
  );

  testWidgets('selected category avatar follows the card neumorph offset', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 180,
            height: 180,
            child: CategoryCard(
              category: categoryFixtures.last,
              transactionCount: 3,
              active: true,
              cardSurfaceStyle: ExpenseSurfaceInteraction.neutralInset,
              avatarSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
              onSelect: (_) {},
              onModify: (_) {},
              onDelete: (_) {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final cardTop = tester
        .getTopLeft(find.byKey(const ValueKey('category-card-surface-6')))
        .dy;
    final avatarTop = tester
        .getTopLeft(find.byKey(const ValueKey('category-icon-surface-6')))
        .dy;
    expect(avatarTop - cardTop, moreOrLessEquals(15, epsilon: 0.1));
  });

  testWidgets('category cards keep neutral shadow and thin icon stroke', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            activeType: TransactionType.expense,
            categories: categoryFixtures,
            categoryTransactionCounts: const {6: 3},
            activeCategory: null,
            onSelect: (_) {},
            onModify: (_) {},
            onDelete: (_) {},
            onAdd: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    final card = tester.widget<Container>(
      find.byKey(const ValueKey('category-card-surface-6')),
    );
    expect((card.decoration! as BoxDecoration).boxShadow, isNotEmpty);

    final badge = tester.widget<CategoryIconBadge>(
      find.descendant(
        of: find.byKey(const ValueKey('category-icon-surface-6')),
        matching: find.byType(CategoryIconBadge),
      ),
    );
    expect(badge.iconSize, 44);
    expect(badge.iconStrokeWidth, 1.35);
  });
}

final categoryFixtures = <TransactionCategory>[
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
    'name': 'Q',
    'type': 'kiadás',
    'colorSlot': 7,
    'iconSlot': 2,
    'backgroundColor': '#dc2626',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  }),
];

class FakeTransactionRepository extends TransactionRepositoryContract {
  final renameArgs = <String>[];
  String? resetMerchant;

  final transactions = <TransactionRecord>[
    TransactionRecord.fromMap({
      'id': 1,
      'date': '2025.09.25',
      'time': '20:30:00',
      'merchant': 'Test Store',
      'amount': -505,
      'userAssignedName': null,
      'transactionCategoryID': 6,
    }),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: categoryFixtures,
    transactions: transactions,
    limits: const [],
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
  ) async {
    renameArgs
      ..add(originalMerchant)
      ..add(userAssignedName);
    var count = 0;
    for (var index = 0; index < transactions.length; index += 1) {
      final transaction = transactions[index];
      if (transaction.merchant != originalMerchant) continue;
      final map = transaction.toMap();
      map['userAssignedName'] = userAssignedName;
      transactions[index] = TransactionRecord.fromMap(map);
      count += 1;
    }
    return count;
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async {
    resetMerchant = originalMerchant;
    var count = 0;
    for (var index = 0; index < transactions.length; index += 1) {
      final transaction = transactions[index];
      if (transaction.merchant != originalMerchant) continue;
      final map = transaction.toMap();
      map['userAssignedName'] = null;
      transactions[index] = TransactionRecord.fromMap(map);
      count += 1;
    }
    return count;
  }

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async => const [];

  @override
  Future<Map<int, int>> categoryCounts() async => const {6: 1};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async => const [];

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async => throw UnimplementedError();
}

double _slideCardTranslationY(WidgetTester tester) {
  final transform = tester.widget<Transform>(
    find.byKey(const ValueKey('slide-up-menu-transform')),
  );
  return transform.transform.getTranslation().y;
}

Future<void> _scrollCategoryCardIntoView(WidgetTester tester, int id) async {
  await tester.ensureVisible(find.byKey(ValueKey('category-card-$id')));
  await tester.pumpAndSettle();
}
