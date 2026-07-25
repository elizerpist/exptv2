import 'dart:ui' show SemanticsAction, Tristate;

import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_post_content.dart';
import 'package:exptv2/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget host(Widget child, {bool disableAnimations = false}) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(
          size: const Size(412, 892),
          disableAnimations: disableAnimations,
        ),
        child: Scaffold(
          body: Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: 378, child: child),
          ),
        ),
      ),
    );
  }

  Future<void> settleActionAssets(WidgetTester tester) async {
    final loading = find.byKey(
      const ValueKey('spendee-balance-action-assets-loading'),
    );
    if (loading.evaluate().isEmpty) return;
    final context = tester.element(loading);
    await tester.runAsync(
      () => SpendeeBalanceActionToggle.precacheAssets(context),
    );
    await tester.pump();
  }

  testWidgets('action row has exact geometry and one selected action', (
    tester,
  ) async {
    TransactionType? selected;
    await tester.pumpWidget(
      host(
        SpendeeBalanceActionToggle(
          activeType: TransactionType.income,
          onChanged: (value) => selected = value,
        ),
      ),
    );
    await settleActionAssets(tester);

    final row = find.byKey(const ValueKey('spendee-balance-actions'));
    final income = find.byKey(const ValueKey('spendee-balance-income-action'));
    final expense = find.byKey(
      const ValueKey('spendee-balance-expense-action'),
    );
    expect(tester.getSize(row), const Size(378, 42));
    expect(tester.getSize(income), const Size(180, 42));
    expect(tester.getSize(expense), const Size(180, 42));
    expect(tester.getTopLeft(income).dx - tester.getTopLeft(row).dx, 4);
    expect(tester.getTopLeft(expense).dx - tester.getTopRight(income).dx, 10);
    expect(
      tester.getSemantics(income).getSemanticsData().flagsCollection.isToggled,
      Tristate.isTrue,
    );
    expect(
      tester.getSemantics(income).getSemanticsData().label,
      'Bevétel hozzáadása',
    );
    expect(
      tester.getSemantics(expense).getSemanticsData().flagsCollection.isToggled,
      Tristate.isFalse,
    );
    expect(
      tester.getSemantics(expense).getSemanticsData().label,
      'Kiadás hozzáadása',
    );
    final group = tester.getSemantics(
      find.byKey(const ValueKey('spendee-balance-actions-semantics')),
    );
    expect(group.label, 'Tranzakció típusa');
    expect(group.childrenCount, 2);
    final expenseNode = tester.getSemantics(expense);
    expect(
      expenseNode.getSemanticsData().hasAction(SemanticsAction.tap),
      isTrue,
    );
    expenseNode.owner!.performAction(expenseNode.id, SemanticsAction.tap);
    await tester.pump();
    expect(selected, TransactionType.expense);
    selected = null;

    final incomeDecoration = _actionDecoration(tester, income);
    expect(
      incomeDecoration.gradient,
      const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFF7054ED),
          Color(0xFF7054ED),
          Color(0xFFB54EDE),
          Color(0xFFF5368D),
        ],
        stops: [0, 46 / 180, .64, 1],
      ),
    );
    expect(incomeDecoration.boxShadow, const [
      BoxShadow(
        color: Color(0x4D7054ED),
        offset: Offset(0, 11),
        blurRadius: 20,
      ),
    ]);
    final inactiveExpenseDecoration = _actionDecoration(tester, expense);
    expect(inactiveExpenseDecoration.gradient, isA<CssLinearGradient>());
    expect(
      (inactiveExpenseDecoration.gradient! as CssLinearGradient).cssDegrees,
      126,
    );
    expect(inactiveExpenseDecoration.boxShadow, const [
      BoxShadow(
        color: Color(0x14707070),
        offset: Offset(0, 11),
        blurRadius: 20,
      ),
    ]);

    expect(
      find.byKey(const ValueKey('spendee-balance-income-wallet-raster')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-expense-bag-raster')),
      findsOneWidget,
    );
    expect(
      _imageAssetName(
        tester,
        const ValueKey('spendee-balance-income-wallet-raster'),
      ),
      'assets/b3ma3/final_income_glass_wallet_plus_3d_inkscape2_mapped.png',
    );
    expect(
      _imageAssetName(
        tester,
        const ValueKey('spendee-balance-expense-bag-raster'),
      ),
      'assets/b3ma3/expense_glass_shopping_bag_3d_perspective_fixed_final1_mapped.png',
    );
    expect(
      B3ma3ActionRasterPalette.income[0xFF7A63FF],
      const Color(0xFF7054ED),
      reason: 'the raster follows the active income material token',
    );
    expect(
      B3ma3ActionRasterPalette.income[0xFF251178],
      const Color(0xFF1D163E),
      reason: 'the wallet retains the exact 26% sRGB depth mix',
    );
    expect(
      B3ma3ActionRasterPalette.expense[0xFFFF82BE],
      const Color(0xFFFA96C4),
      reason: 'the bag retains the exact 52% sRGB light mix',
    );
    expect(
      B3ma3ActionRasterPalette.expense[0xFF8E1457],
      const Color(0xFF7B1B47),
      reason: 'the bag retains the exact 50% sRGB depth mix',
    );

    await tester.tap(expense);
    await tester.pumpWidget(
      host(
        SpendeeBalanceActionToggle(
          activeType: TransactionType.expense,
          onChanged: (value) => selected = value,
        ),
      ),
    );
    expect(selected, TransactionType.expense);
    final activeExpenseDecoration = _actionDecoration(tester, expense);
    expect(
      activeExpenseDecoration.gradient,
      const LinearGradient(
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
        colors: [
          Color(0xFFFFB15C),
          Color(0xFFFF6B6B),
          Color(0xFFF5368D),
          Color(0xFFF5368D),
        ],
        stops: [0, .36, 136 / 180, 1],
      ),
    );
    expect(activeExpenseDecoration.boxShadow, const [
      BoxShadow(
        color: Color(0x4DF5368D),
        offset: Offset(0, 11),
        blurRadius: 20,
      ),
    ]);
    expect(
      tester.getSemantics(income).getSemanticsData().flagsCollection.isToggled,
      Tristate.isFalse,
    );
    expect(
      tester.getSemantics(expense).getSemanticsData().flagsCollection.isToggled,
      Tristate.isTrue,
    );
  });

  testWidgets(
    'action row is exposed only after both DPR-selected raster frames decode',
    (tester) async {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
      await tester.pumpWidget(
        host(
          SpendeeBalanceActionToggle(
            activeType: TransactionType.income,
            onChanged: (_) {},
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('spendee-balance-action-assets-loading')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-actions')),
        findsOneWidget,
        reason: 'asset decode must not move any content below the action row',
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('spendee-balance-actions'))),
        const Size(378, 42),
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-income-action')),
        findsNothing,
        reason: 'a capture must never observe a half-decoded action row',
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-expense-action')),
        findsNothing,
        reason: 'a capture must never observe a half-decoded action row',
      );

      await settleActionAssets(tester);

      expect(
        find.byKey(const ValueKey('spendee-balance-action-assets-loading')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('spendee-balance-actions')),
        findsOneWidget,
      );
      final incomeRender = tester.widget<RawImage>(
        find.descendant(
          of: find.byKey(
            const ValueKey('spendee-balance-income-wallet-raster'),
          ),
          matching: find.byType(RawImage),
        ),
      );
      final expenseRender = tester.widget<RawImage>(
        find.descendant(
          of: find.byKey(const ValueKey('spendee-balance-expense-bag-raster')),
          matching: find.byType(RawImage),
        ),
      );
      expect(incomeRender.image, isNotNull);
      expect(incomeRender.image!.width, 50);
      expect(incomeRender.image!.height, 50);
      expect(expenseRender.image, isNotNull);
      expect(expenseRender.image!.width, 48);
      expect(expenseRender.image!.height, 48);
    },
  );

  test('action raster variants have exact authored CSS pixel dimensions', () async {
    const variants = <(String, int)>[
      (
        'assets/b3ma3/final_income_glass_wallet_plus_3d_inkscape2_mapped.png',
        50,
      ),
      (
        'assets/b3ma3/2.0x/final_income_glass_wallet_plus_3d_inkscape2_mapped.png',
        100,
      ),
      (
        'assets/b3ma3/3.0x/final_income_glass_wallet_plus_3d_inkscape2_mapped.png',
        150,
      ),
      (
        'assets/b3ma3/expense_glass_shopping_bag_3d_perspective_fixed_final1_mapped.png',
        48,
      ),
      (
        'assets/b3ma3/2.0x/expense_glass_shopping_bag_3d_perspective_fixed_final1_mapped.png',
        96,
      ),
      (
        'assets/b3ma3/3.0x/expense_glass_shopping_bag_3d_perspective_fixed_final1_mapped.png',
        144,
      ),
      ('assets/b3ma3/filter_glyph.png', 18),
      ('assets/b3ma3/2.0x/filter_glyph.png', 36),
      ('assets/b3ma3/3.0x/filter_glyph.png', 54),
    ];

    for (final (asset, expectedDimension) in variants) {
      final png = await rootBundle.load(asset);
      expect(_pngDimensions(png), (
        width: expectedDimension,
        height: expectedDimension,
      ), reason: asset);
    }
  });

  test('action SVG assets retain the approved authored layer graphs', () async {
    final income = await rootBundle.loadString(
      'assets/b3ma3/final_income_glass_wallet_plus_3d_inkscape2.svg',
    );
    final expense = await rootBundle.loadString(
      'assets/b3ma3/expense_glass_shopping_bag_3d_perspective_fixed_final1.svg',
    );

    expect(income, contains('viewBox="0 0 1024 1024"'));
    expect(
      RegExp(r'<filter\s').allMatches(income),
      hasLength(4),
      reason: 'wallet keeps three depth shadows and one soft highlight',
    );
    expect(RegExp(r'<linearGradient\s').allMatches(income), hasLength(8));
    expect(RegExp(r'<radialGradient\s').allMatches(income), hasLength(1));
    expect(income, contains('transform="rotate(-11,490,470)"'));
    expect(income, contains('transform="rotate(-11,603.46857,405.14603)"'));

    expect(expense, contains('viewBox="0 0 1024 1024"'));
    expect(
      RegExp(r'<filter\s').allMatches(expense),
      hasLength(4),
      reason: 'bag keeps three depth shadows and one soft blur',
    );
    expect(RegExp(r'<linearGradient\s').allMatches(expense), hasLength(10));
    expect(RegExp(r'<path\b').allMatches(expense), hasLength(11));
    expect(expense, contains('transform="rotate(11 500 500)"'));
    expect(
      expense,
      contains('transform="rotate(10.711679,560.23028,228.94409)"'),
    );
  });

  testWidgets('action icon pulse samples exact B3M-A3 keyframes', (
    tester,
  ) async {
    var active = TransactionType.income;
    late StateSetter setHostState;
    await tester.pumpWidget(
      host(
        StatefulBuilder(
          builder: (context, setState) {
            setHostState = setState;
            return SpendeeBalanceActionToggle(
              activeType: active,
              onChanged: (value) => setState(() => active = value),
            );
          },
        ),
      ),
    );
    await settleActionAssets(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-expense-action')),
    );
    await tester.pump();
    expect(_iconScale(tester, TransactionType.expense), closeTo(.9, .001));

    await tester.pump(const Duration(milliseconds: 189));
    expect(_iconScale(tester, TransactionType.expense), closeTo(1.12, .015));

    await tester.pump(const Duration(milliseconds: 113));
    expect(_iconScale(tester, TransactionType.expense), closeTo(.98, .015));

    await tester.pump(const Duration(milliseconds: 118));
    expect(_iconScale(tester, TransactionType.expense), closeTo(1, .001));

    setHostState(() => active = TransactionType.expense);
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-expense-action')),
    );
    await tester.pump();
    expect(_iconScale(tester, TransactionType.expense), closeTo(.9, .001));
  });

  testWidgets(
    'reduced motion stops an in-flight pulse and commits action once',
    (tester) async {
      var active = TransactionType.income;
      var callbackCount = 0;
      var disableAnimations = false;
      late StateSetter setHostState;

      await tester.pumpWidget(
        MaterialApp(
          home: StatefulBuilder(
            builder: (context, setState) {
              setHostState = setState;
              return MediaQuery(
                data: MediaQueryData(
                  size: const Size(412, 892),
                  disableAnimations: disableAnimations,
                ),
                child: Scaffold(
                  body: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      width: 378,
                      child: SpendeeBalanceActionToggle(
                        activeType: active,
                        onChanged: (value) {
                          callbackCount += 1;
                          setState(() => active = value);
                        },
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      );
      await settleActionAssets(tester);

      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-expense-action')),
      );
      await tester.pump(const Duration(milliseconds: 40));
      expect(callbackCount, 1);

      setHostState(() => disableAnimations = true);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('spendee-balance-income-action')),
      );
      await tester.pump();

      expect(callbackCount, 2);
      expect(active, TransactionType.income);
      expect(_iconScale(tester, TransactionType.income), 1);
      expect(tester.binding.hasScheduledFrame, isFalse);

      await tester.pump(const Duration(milliseconds: 500));
      expect(callbackCount, 2);
      expect(_iconScale(tester, TransactionType.income), 1);
    },
  );

  testWidgets('summary exact visual settles before horizontal action', (
    tester,
  ) async {
    var direction = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceSummary(
          label: 'Aktuális hónap',
          amount: '-486 320 Ft',
          onOpenScopePicker: () {},
          onResetCurrentMonth: () {},
          onShiftPeriod: (value) => direction = value,
          onCycleScope: () {},
        ),
      ),
    );

    final summary = find.byKey(const ValueKey('spendee-balance-summary'));
    expect(tester.getSize(summary), const Size(378, 59));
    expect(find.text('Aktuális hónap'), findsOneWidget);
    expect(find.text('-486 320 Ft'), findsOneWidget);
    final summaryDecoration =
        tester.widget<Container>(summary).decoration! as BoxDecoration;
    expect(summaryDecoration.boxShadow, hasLength(2));
    expect(
      summaryDecoration.boxShadow!.last,
      const BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    );

    final gesture = await tester.startGesture(tester.getCenter(summary));
    // The first move resolves Flutter's horizontal/vertical gesture arena;
    // the second is the delta observed by the production SummaryPill logic.
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-65, 0));
    await tester.pump();
    expect(direction, 0);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('spendee-balance-summary-transform')),
          )
          .transform
          .getTranslation()
          .x,
      closeTo(-6.5, .01),
    );
    await gesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 159));
    expect(direction, 0);
    await tester.pumpAndSettle();
    expect(direction, 1);
  });

  testWidgets('reduced motion commits summary slide without settle frames', (
    tester,
  ) async {
    final directions = <int>[];
    await tester.pumpWidget(
      host(
        SpendeeBalanceSummary(
          label: 'Aktuális hónap',
          amount: '-486 320 Ft',
          onOpenScopePicker: () {},
          onResetCurrentMonth: () {},
          onShiftPeriod: directions.add,
          onCycleScope: () {},
        ),
        disableAnimations: true,
      ),
    );

    final summary = find.byKey(const ValueKey('spendee-balance-summary'));
    final gesture = await tester.startGesture(tester.getCenter(summary));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-65, 0));
    await gesture.up();
    await tester.pump();

    expect(directions, const [1]);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('spendee-balance-summary-transform')),
          )
          .transform
          .getTranslation()
          .x,
      0,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
    // Flush GestureDetector's independent double-tap recognition timer.
    await tester.pump(const Duration(milliseconds: 40));
  });

  testWidgets('summary exposes semantic and keyboard period alternatives', (
    tester,
  ) async {
    final directions = <int>[];
    var cycleCount = 0;
    var resetCount = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceSummary(
          label: 'Aktuális hónap',
          amount: '-486 320 Ft',
          onOpenScopePicker: () {},
          onResetCurrentMonth: () => resetCount += 1,
          onShiftPeriod: directions.add,
          onCycleScope: () => cycleCount += 1,
        ),
      ),
    );

    final actions = _customActions(
      tester,
      const ValueKey('spendee-balance-summary-semantics'),
    );
    actions['Előző időszak']!();
    actions['Következő időszak']!();
    actions['Nézet váltása']!();
    actions['Aktuális hónap visszaállítása']!();
    expect(directions, const [-1, 1]);
    expect(cycleCount, 1);
    expect(resetCount, 1);

    final summary = find.byKey(const ValueKey('spendee-balance-summary'));
    Focus.of(tester.element(summary)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.sendKeyEvent(LogicalKeyboardKey.home);

    expect(directions, const [-1, 1, -1, 1]);
    expect(cycleCount, 2);
    expect(resetCount, 2);
  });

  testWidgets('search grid keeps filter separate and fires only callback', (
    tester,
  ) async {
    var query = '';
    var filterCalls = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceSearchFilter(
          query: query,
          filters: const [],
          onQueryChanged: (value) => query = value,
          onRemoveFilter: (_) {},
          onFilterPressed: () => filterCalls += 1,
          onCycleScope: () {},
        ),
      ),
    );

    final row = find.byKey(const ValueKey('spendee-balance-search-row'));
    final field = find.byKey(const ValueKey('spendee-balance-search-field'));
    final filter = find.byKey(const ValueKey('spendee-balance-filter-button'));
    expect(tester.getSize(row), const Size(378, 39));
    expect(tester.getSize(field), const Size(329, 39));
    expect(tester.getSize(filter), const Size(40, 39));
    expect(tester.getTopLeft(filter).dx - tester.getTopRight(field).dx, 9);
    final fieldDecoration =
        tester.widget<Container>(field).decoration! as BoxDecoration;
    expect(fieldDecoration.boxShadow, hasLength(2));
    expect(
      fieldDecoration.boxShadow!.last,
      const BoxShadow(
        color: Color(0xF0FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    );
    final filterDecoration =
        tester.widget<Container>(filter).decoration! as BoxDecoration;
    expect(filterDecoration.boxShadow, fieldDecoration.boxShadow);
    _expectTransparentInteraction(
      tester.widget<InkWell>(
        find.descendant(of: filter, matching: find.byType(InkWell)),
      ),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('spendee-balance-search-glyph')),
      ),
      const Size(14, 14),
    );
    expect(
      tester.getSize(
        find.byKey(const ValueKey('spendee-balance-filter-glyph')),
      ),
      const Size(18, 18),
    );
    expect(
      _imageAssetName(tester, const ValueKey('spendee-balance-filter-glyph')),
      'assets/b3ma3/filter_glyph.png',
      reason: 'the filter uses the frozen browser-rendered CSS glyph',
    );

    await tester.enterText(find.byType(TextField), 'lidl');
    expect(query, 'lidl');
    await tester.tap(filter);
    await tester.pump();
    expect(filterCalls, 1);
    expect(find.byType(BottomSheet), findsNothing);
  });

  testWidgets(
    'filter keyboard traversal paints an inset outline and activates once',
    (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      var filterCalls = 0;
      await tester.pumpWidget(
        host(
          SpendeeBalanceSearchFilter(
            query: '',
            filters: const [],
            onQueryChanged: (_) {},
            onRemoveFilter: (_) {},
            onFilterPressed: () => filterCalls += 1,
            onCycleScope: () {},
          ),
        ),
      );

      final filter = find.byKey(
        const ValueKey('spendee-balance-filter-button'),
      );
      final filterRect = tester.getRect(filter);
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(
        tester
            .widget<EditableText>(find.byType(EditableText))
            .focusNode
            .hasFocus,
        isTrue,
      );
      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      _expectInsetFocusOutline(
        tester,
        controlRect: filterRect,
        outlineKey: const ValueKey(
          'spendee-balance-filter-button-focus-outline',
        ),
        borderRadius: BorderRadius.circular(16),
      );
      expect(tester.getRect(filter), filterRect);
      _expectTransparentInteraction(
        tester.widget<InkWell>(
          find.descendant(of: filter, matching: find.byType(InkWell)),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.enter);
      expect(filterCalls, 1);
    },
  );

  testWidgets('reduced motion commits search cycle without settle frames', (
    tester,
  ) async {
    var cycleCount = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceSearchFilter(
          query: '',
          filters: const [],
          onQueryChanged: (_) {},
          onRemoveFilter: (_) {},
          onFilterPressed: () {},
          onCycleScope: () => cycleCount += 1,
        ),
        disableAnimations: true,
      ),
    );

    final row = find.byKey(const ValueKey('spendee-balance-search-row'));
    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(0, -20));
    await gesture.moveBy(const Offset(0, -65));
    await gesture.up();
    await tester.pump();

    expect(cycleCount, 1);
    expect(
      tester
          .widget<Transform>(
            find.byKey(const ValueKey('spendee-balance-search-transform')),
          )
          .transform
          .getTranslation()
          .y,
      0,
    );
    expect(tester.binding.hasScheduledFrame, isFalse);
  });

  testWidgets('search cycle is available to semantics and hardware keyboard', (
    tester,
  ) async {
    var cycleCount = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceSearchFilter(
          query: '',
          filters: const [],
          onQueryChanged: (_) {},
          onRemoveFilter: (_) {},
          onFilterPressed: () {},
          onCycleScope: () => cycleCount += 1,
        ),
      ),
    );

    final actions = _customActions(
      tester,
      const ValueKey('spendee-balance-search-semantics'),
    );
    actions['Nézet váltása']!();
    expect(cycleCount, 1);

    await tester.tap(find.byType(TextField));
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.pageDown);
    expect(cycleCount, 2);
  });

  testWidgets('every search filter chip suppresses Material overlays', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SpendeeBalanceSearchFilter(
          query: '',
          filters: const [
            SpendeeBalanceSearchChip(
              keyValue: 'category:1',
              label: 'Élelmiszer',
              color: Color(0xFFFF4D79),
            ),
            SpendeeBalanceSearchChip(
              keyValue: 'merchant:2',
              label: 'Lidl',
              color: Color(0xFF7054ED),
            ),
          ],
          onQueryChanged: (_) {},
          onRemoveFilter: (_) {},
          onFilterPressed: () {},
          onCycleScope: () {},
        ),
      ),
    );

    final row = find.byKey(const ValueKey('spendee-balance-search-row'));
    final interactions = find.descendant(
      of: row,
      matching: find.byType(InkWell),
    );
    expect(interactions, findsNWidgets(3));
    for (final element in interactions.evaluate()) {
      _expectTransparentInteraction(element.widget as InkWell);
    }
  });

  testWidgets('permanent rail keeps exact handle pills and dots', (
    tester,
  ) async {
    String? selected;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTimeScopeRail(
          label: 'ÉV FINOMÍTÁS',
          currentLabel: '2024',
          selectedKey: '2024',
          options: const [
            SpendeeBalanceTimeScopeItem(key: '2021', label: '2021'),
            SpendeeBalanceTimeScopeItem(key: '2022', label: '2022'),
            SpendeeBalanceTimeScopeItem(key: '2023', label: '2023'),
            SpendeeBalanceTimeScopeItem(key: '2024', label: '2024'),
            SpendeeBalanceTimeScopeItem(key: '2025', label: '2025'),
            SpendeeBalanceTimeScopeItem(key: '2026', label: '2026'),
          ],
          collapseProgress: 0,
          dragging: false,
          onSelected: (value) => selected = value.key,
          onCollapseDragStart: () {},
          onCollapseDragUpdate: (_) {},
          onCollapseDragEnd: () {},
          onCollapseToggle: () {},
        ),
      ),
    );

    final rail = find.byKey(const ValueKey('spendee-balance-time-rail'));
    final handle = find.byKey(
      const ValueKey('spendee-balance-collapse-handle'),
    );
    expect(tester.getSize(rail), const Size(378, 79));
    expect(tester.getSize(handle), const Size(92, 21));
    expect(tester.getTopLeft(handle).dx - tester.getTopLeft(rail).dx, 178);
    expect(find.text('ÉV FINOMÍTÁS'), findsOneWidget);
    expect(find.text('2024'), findsNWidgets(2));
    expect(
      find.byKey(const ValueKey('spendee-balance-year-pill-2024')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-year-dot-2024')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-balance-rail-ticking-viewport')),
      findsOneWidget,
    );
    expect(
      find.descendant(of: rail, matching: find.byType(SingleChildScrollView)),
      findsNothing,
    );
    final activeTransform = tester.widget<Transform>(
      find.byKey(const ValueKey('spendee-balance-year-pill-transform-2024')),
    );
    expect(activeTransform.transform.getTranslation().y, -1);
    final activePill = tester.widget<Container>(
      find.byKey(const ValueKey('spendee-balance-year-pill-2024')),
    );
    final activePillDecoration = activePill.decoration! as BoxDecoration;
    expect(activePillDecoration.gradient, isA<CssLinearGradient>());
    expect(
      (activePillDecoration.gradient! as CssLinearGradient).cssDegrees,
      126,
    );
    expect(activePillDecoration.boxShadow, hasLength(2));
    expect(
      activePillDecoration.boxShadow!.last,
      const BoxShadow(
        color: Color(0x61FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    );
    final idlePill = tester.widget<Container>(
      find.byKey(const ValueKey('spendee-balance-year-pill-2023')),
    );
    expect(
      (idlePill.decoration! as BoxDecoration).boxShadow!.last.blurStyle,
      BlurStyle.inner,
    );
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey(
                        'spendee-balance-year-dot-decoration-2024',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration)
          .boxShadow,
      hasLength(2),
    );
    expect(
      (tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey(
                        'spendee-balance-year-dot-decoration-2023',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration)
          .boxShadow,
      hasLength(1),
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-balance-year-pill-2025')),
    );
    await tester.pumpAndSettle();
    expect(selected, '2025');
  });

  testWidgets('monthly rail labels stay complete inside two-line pills', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SpendeeBalanceTimeScopeRail(
          label: 'HÓNAP FINOMÍTÁS',
          currentLabel: 'Augusztus 2026',
          selectedKey: '2026-08',
          options: const [
            SpendeeBalanceTimeScopeItem(key: '2026-07', label: 'Július 2026'),
            SpendeeBalanceTimeScopeItem(
              key: '2026-08',
              label: 'Augusztus 2026',
            ),
            SpendeeBalanceTimeScopeItem(
              key: '2026-09',
              label: 'Szeptember 2026',
            ),
          ],
          collapseProgress: 0,
          onSelected: (_) {},
          onCollapseDragStart: () {},
          onCollapseDragUpdate: (_) {},
          onCollapseDragEnd: () {},
          onCollapseToggle: () {},
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    for (final key in ['2026-07', '2026-08', '2026-09']) {
      final pill = find.byKey(ValueKey('spendee-balance-year-pill-$key'));
      final label = find.byKey(
        ValueKey('spendee-balance-time-pill-label-$key'),
      );
      expect(label, findsOneWidget);
      expect(
        tester.getRect(pill).contains(tester.getRect(label).topLeft),
        isTrue,
      );
      expect(
        tester.getRect(pill).contains(tester.getRect(label).bottomRight),
        isTrue,
      );
    }
    expect(find.text('Augusztus'), findsOneWidget);
    expect(find.text('2026'), findsNWidgets(3));
  });

  testWidgets('two-month rail keeps public pill keys on canonical items only', (
    tester,
  ) async {
    await tester.pumpWidget(
      host(
        SpendeeBalanceTimeScopeRail(
          label: 'HÓNAP FINOMÍTÁS',
          currentLabel: 'Augusztus 2026',
          selectedKey: '2026-08',
          options: const [
            SpendeeBalanceTimeScopeItem(key: '2026-07', label: 'Július 2026'),
            SpendeeBalanceTimeScopeItem(
              key: '2026-08',
              label: 'Augusztus 2026',
            ),
          ],
          collapseProgress: 0,
          onSelected: (_) {},
          onCollapseDragStart: () {},
          onCollapseDragUpdate: (_) {},
          onCollapseDragEnd: () {},
          onCollapseToggle: () {},
        ),
      ),
    );

    final decorativeSlot = find.byKey(
      const ValueKey('spendee-balance-ticking-slot-0--1'),
    );
    expect(decorativeSlot, findsOneWidget);
    for (final key in [
      'spendee-balance-year-pill-2026-07',
      'spendee-balance-year-pill-transform-2026-07',
      'spendee-balance-time-pill-label-2026-07',
      'spendee-balance-time-pill-month-2026-07',
      'spendee-balance-time-pill-year-2026-07',
    ]) {
      final publicKey = find.byKey(ValueKey(key));
      expect(publicKey, findsOneWidget);
      expect(
        find.descendant(of: decorativeSlot, matching: publicKey),
        findsNothing,
      );
    }
  });

  testWidgets('collapse handle exposes exact idle and dragging materials', (
    tester,
  ) async {
    Widget rail({required bool dragging}) {
      return SpendeeBalanceTimeScopeRail(
        label: 'ÉV FINOMÍTÁS',
        currentLabel: '2024',
        selectedKey: '2024',
        options: const [
          SpendeeBalanceTimeScopeItem(key: '2024', label: '2024'),
        ],
        collapseProgress: 0,
        dragging: dragging,
        onSelected: (_) {},
        onCollapseDragStart: () {},
        onCollapseDragUpdate: (_) {},
        onCollapseDragEnd: () {},
        onCollapseToggle: () {},
      );
    }

    await tester.pumpWidget(host(rail(dragging: false)));

    BoxDecoration barDecoration() =>
        tester
                .widget<DecoratedBox>(
                  find.byKey(
                    const ValueKey('spendee-balance-collapse-handle-bar'),
                  ),
                )
                .decoration
            as BoxDecoration;
    TextStyle labelStyle() => tester
        .widget<Text>(
          find.byKey(const ValueKey('spendee-balance-collapse-handle-label')),
        )
        .style!;

    expect(barDecoration().color, const Color(0xFFAEB7C8));
    expect(barDecoration().boxShadow, const [
      BoxShadow(
        color: Color(0x94FFFFFF),
        offset: Offset(0, 1),
        blurRadius: 0,
        blurStyle: BlurStyle.inner,
      ),
    ]);
    expect(labelStyle().color, const Color(0xFF65748B));

    await tester.pumpWidget(host(rail(dragging: true)));
    expect(barDecoration().color, const Color(0xFF6E5CF1));
    expect(labelStyle().color, const Color(0xFF4C3ED3));
  });

  testWidgets('scope pills expose one node and Enter or Space selects once', (
    tester,
  ) async {
    final selected = <String>[];
    await tester.pumpWidget(
      host(
        SpendeeBalanceTimeScopeRail(
          label: 'ÉV FINOMÍTÁS',
          currentLabel: '2024',
          selectedKey: '2024',
          options: const [
            SpendeeBalanceTimeScopeItem(key: '2024', label: '2024'),
            SpendeeBalanceTimeScopeItem(key: '2025', label: '2025'),
          ],
          collapseProgress: 0,
          onSelected: (value) => selected.add(value.key),
          onCollapseDragStart: () {},
          onCollapseDragUpdate: (_) {},
          onCollapseDragEnd: () {},
          onCollapseToggle: () {},
        ),
      ),
    );

    Future<void> activate(String key, LogicalKeyboardKey keyboardKey) async {
      final pill = find.byKey(ValueKey('spendee-balance-year-pill-$key'));
      final semantics = tester.getSemantics(pill);
      expect(semantics.label, '$key kiválasztása');
      expect(semantics.flagsCollection.isButton, isTrue);
      expect(semantics.childrenCount, 0);
      final inkWell = find.ancestor(of: pill, matching: find.byType(InkWell));
      expect(inkWell, findsOneWidget);
      Focus.of(tester.element(pill)).requestFocus();
      await tester.pump();
      await tester.sendKeyEvent(keyboardKey);
      await tester.pumpAndSettle();
    }

    await activate('2025', LogicalKeyboardKey.enter);
    expect(selected, ['2025']);
    await activate('2024', LogicalKeyboardKey.space);
    expect(selected, ['2025', '2024']);
  });

  testWidgets('collapse handle has semantic and keyboard toggle alternatives', (
    tester,
  ) async {
    var toggleCount = 0;
    await tester.pumpWidget(
      host(
        SpendeeBalanceTimeScopeRail(
          label: 'ÉV FINOMÍTÁS',
          currentLabel: '2024',
          selectedKey: '2024',
          options: const [
            SpendeeBalanceTimeScopeItem(key: '2024', label: '2024'),
          ],
          collapseProgress: 0,
          onSelected: (_) {},
          onCollapseDragStart: () {},
          onCollapseDragUpdate: (_) {},
          onCollapseDragEnd: () {},
          onCollapseToggle: () => toggleCount += 1,
        ),
      ),
    );

    final semantics = tester.widget<Semantics>(
      find.byKey(const ValueKey('spendee-balance-collapse-handle-semantics')),
    );
    expect(semantics.properties.button, isTrue);
    expect(semantics.properties.expanded, isTrue);
    expect(semantics.properties.label, 'Nézet összecsukása');
    semantics.properties.onTap!();
    expect(toggleCount, 1);

    final handle = find.byKey(
      const ValueKey('spendee-balance-collapse-handle'),
    );
    Focus.of(tester.element(handle)).requestFocus();
    await tester.pump();
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyEvent(LogicalKeyboardKey.space);
    expect(toggleCount, 3);
  });

  testWidgets(
    'scope pill and collapse handle paint geometry-preserving focus outlines',
    (tester) async {
      final previousStrategy = FocusManager.instance.highlightStrategy;
      FocusManager.instance.highlightStrategy =
          FocusHighlightStrategy.alwaysTraditional;
      addTearDown(
        () => FocusManager.instance.highlightStrategy = previousStrategy,
      );
      await tester.pumpWidget(
        host(
          SpendeeBalanceTimeScopeRail(
            label: 'ÉV FINOMÍTÁS',
            currentLabel: '2024',
            selectedKey: '2024',
            options: const [
              SpendeeBalanceTimeScopeItem(key: '2024', label: '2024'),
              SpendeeBalanceTimeScopeItem(key: '2025', label: '2025'),
            ],
            collapseProgress: 0,
            onSelected: (_) {},
            onCollapseDragStart: () {},
            onCollapseDragUpdate: (_) {},
            onCollapseDragEnd: () {},
            onCollapseToggle: () {},
          ),
        ),
      );

      final pill = find.byKey(const ValueKey('spendee-balance-year-pill-2024'));
      final pillRect = tester.getRect(pill);
      Focus.of(tester.element(pill)).requestFocus();
      await tester.pump();
      _expectInsetFocusOutline(
        tester,
        controlRect: pillRect,
        outlineKey: const ValueKey(
          'spendee-balance-year-pill-2024-focus-outline',
        ),
        borderRadius: BorderRadius.circular(15),
      );
      expect(tester.getRect(pill), pillRect);
      _expectTransparentInteraction(
        tester.widget<InkWell>(
          find.ancestor(of: pill, matching: find.byType(InkWell)),
        ),
      );

      final handle = find.byKey(
        const ValueKey('spendee-balance-collapse-handle'),
      );
      final handleRect = tester.getRect(handle);
      Focus.of(tester.element(handle)).requestFocus();
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('spendee-balance-year-pill-2024-focus-outline'),
        ),
        findsNothing,
      );
      _expectInsetFocusOutline(
        tester,
        controlRect: handleRect,
        outlineKey: const ValueKey(
          'spendee-balance-collapse-handle-focus-outline',
        ),
        borderRadius: BorderRadius.circular(9.5),
      );
      expect(tester.getRect(handle), handleRect);
    },
  );

  testWidgets(
    'keyboard focus paints exact action outline without geometry shift',
    (tester) async {
      await tester.pumpWidget(
        host(
          SpendeeBalanceActionToggle(
            activeType: TransactionType.income,
            onChanged: (_) {},
          ),
        ),
      );
      await settleActionAssets(tester);

      final income = find.byKey(
        const ValueKey('spendee-balance-income-action'),
      );
      final expense = find.byKey(
        const ValueKey('spendee-balance-expense-action'),
      );
      expect(
        find.byKey(
          const ValueKey('spendee-balance-income-action-focus-outline'),
        ),
        findsNothing,
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();

      final incomeOutline = find.byKey(
        const ValueKey('spendee-balance-income-action-focus-outline'),
      );
      expect(incomeOutline, findsOneWidget);
      expect(tester.getSize(income), const Size(180, 42));
      expect(tester.getSize(incomeOutline), const Size(178, 40));
      final decoration =
          tester.widget<DecoratedBox>(incomeOutline).decoration
              as BoxDecoration;
      expect(
        decoration.border,
        Border.all(color: const Color(0xF0FFFFFF), width: 2),
      );
      _expectTransparentInteraction(
        tester.widget<InkWell>(
          find.descendant(of: income, matching: find.byType(InkWell)),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.tab);
      await tester.pump();
      expect(incomeOutline, findsNothing);
      expect(
        find.byKey(
          const ValueKey('spendee-balance-expense-action-focus-outline'),
        ),
        findsOneWidget,
      );
      expect(tester.getSize(expense), const Size(180, 42));
    },
  );
}

double _iconScale(WidgetTester tester, TransactionType type) {
  final transform = tester.widget<Transform>(
    find.byKey(ValueKey('spendee-balance-${type.name}-icon-transform')),
  );
  // Matrix4 keeps the untouched z axis at 1, therefore
  // getMaxScaleOnAxis() cannot observe the required .9/.98 x-y samples.
  return transform.transform.storage[0];
}

BoxDecoration _actionDecoration(WidgetTester tester, Finder action) {
  final ink = find.descendant(of: action, matching: find.byType(Ink));
  return tester.widget<Ink>(ink).decoration! as BoxDecoration;
}

String _imageAssetName(WidgetTester tester, ValueKey<String> key) {
  final image = tester.widget<Image>(find.byKey(key));
  return (image.image as AssetImage).assetName;
}

void _expectTransparentInteraction(InkWell ink) {
  expect(ink.splashFactory, NoSplash.splashFactory);
  expect(ink.overlayColor, isA<WidgetStatePropertyAll<Color?>>());
  for (final states in <Set<WidgetState>>[
    const <WidgetState>{},
    const <WidgetState>{WidgetState.hovered},
    const <WidgetState>{WidgetState.focused},
    const <WidgetState>{WidgetState.pressed},
  ]) {
    expect(ink.overlayColor!.resolve(states), Colors.transparent);
  }
}

void _expectInsetFocusOutline(
  WidgetTester tester, {
  required Rect controlRect,
  required ValueKey<String> outlineKey,
  required BorderRadius borderRadius,
}) {
  final outline = find.byKey(outlineKey);
  expect(outline, findsOneWidget);
  expect(tester.getRect(outline), controlRect.deflate(1));
  final decoration =
      tester.widget<DecoratedBox>(outline).decoration as BoxDecoration;
  expect(
    decoration.border,
    Border.all(color: const Color(0x6B7D8798), width: 2),
  );
  expect(decoration.borderRadius, borderRadius);
}

Map<String, VoidCallback> _customActions(WidgetTester tester, Key key) {
  final semantics = tester.widget<Semantics>(find.byKey(key));
  final actions = semantics.properties.customSemanticsActions;
  expect(actions, isNotNull);
  return <String, VoidCallback>{
    for (final entry in actions!.entries) entry.key.label!: entry.value,
  };
}

({int width, int height}) _pngDimensions(ByteData png) {
  expect(png.buffer.asUint8List(png.offsetInBytes, 8), const [
    137,
    80,
    78,
    71,
    13,
    10,
    26,
    10,
  ]);
  return (width: png.getUint32(16), height: png.getUint32(20));
}
