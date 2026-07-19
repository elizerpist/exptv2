import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:exptv2/core/debug/debug_console.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/fast_info_metric.dart';
import 'package:exptv2/features/transactions/widgets/experimental/fluvi_logo.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/recurring_rule.dart';
import 'package:exptv2/features/transactions/models/summary_window.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_header_glass.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_mind_stats_adapter.dart';
import 'package:exptv2/features/transactions/widgets/experimental/spendee_test_dashboard.dart';
import 'package:exptv2/features/transactions/widgets/glossy_category_avatar.dart';
import 'package:exptv2/features/transactions/widgets/header_card/magnet_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('experimental logbox avatar hides top semicircle highlight', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    final row = find.byKey(const ValueKey('spendee-test-logbox-1'));
    expect(row, findsOneWidget);

    final avatar = tester.widget<GlossyCategoryAvatar>(
      find.descendant(of: row, matching: find.byType(GlossyCategoryAvatar)),
    );
    expect((avatar as dynamic).showTopHighlight, isFalse);
  });

  testWidgets('experimental logbox accepts deliberate slow right swipe', (
    tester,
  ) async {
    final deleted = <int>[];
    await _pumpDashboard(
      tester,
      onDeleteTransactionRequested: (record) async {
        deleted.add(record.id);
        return false;
      },
    );

    final row = find.byKey(const ValueKey('spendee-test-logbox-1'));
    expect(row, findsOneWidget);

    await tester.timedDrag(
      row,
      const Offset(120, 0),
      const Duration(seconds: 1),
    );
    await tester.pumpAndSettle();

    expect(deleted, [1]);
  });

  testWidgets('experimental logbox accepts deliberate slow left swipe', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(
      find.byKey(const ValueKey('spendee-test-transaction-count')),
      findsOneWidget,
    );
    expect(find.text('6 tranzakció'), findsOneWidget);

    final row = find.byKey(const ValueKey('spendee-test-logbox-1'));
    expect(row, findsOneWidget);

    final gesture = await tester.startGesture(tester.getCenter(row));
    await gesture.moveBy(const Offset(-48, 0));
    await tester.pump(const Duration(milliseconds: 260));
    await gesture.moveBy(const Offset(-48, 0));
    await tester.pump(const Duration(milliseconds: 260));
    await gesture.moveBy(const Offset(-48, 0));
    await tester.pump(const Duration(milliseconds: 260));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(find.text('1 tranzakció'), findsOneWidget);
  });

  testWidgets('stage 1 keeps C2 avatar-only glossy layout and core progress', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(
      find.byKey(const ValueKey('spendee-test-header-core-partition')),
      findsOneWidget,
    );
    expect(find.textContaining('Elköltve'), findsNothing);
    expect(find.textContaining('Maradt'), findsNothing);

    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final glossy = find.byKey(
      const ValueKey('spendee-test-budget-stage1-glossy'),
    );
    expect(glossy, findsOneWidget);
    expect(tester.getRect(glossy), const Rect.fromLTWH(36, 200, 340, 130));
    expect(
      find.descendant(
        of: glossy,
        matching: find.byKey(const ValueKey('spendee-test-context-carousel')),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: glossy,
        matching: find.byKey(const ValueKey('spendee-test-partition-bar')),
      ),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey('spendee-test-partition-segment-used-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-partition-segment-remaining-1')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-partition-segment-free')),
      findsOneWidget,
    );

    final selectedAvatar = tester.widget<GlossyCategoryAvatar>(
      find.descendant(
        of: find.byKey(
          const ValueKey('spendee-test-category-avatar-1-selected'),
        ),
        matching: find.byType(GlossyCategoryAvatar),
      ),
    );
    expect(selectedAvatar.iconSize, 30);
    expect((selectedAvatar as dynamic).showTopHighlight, isFalse);
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-top-highlight-category-1'),
      ),
      findsOneWidget,
    );
  });

  testWidgets(
    'stage 1 avatar belt moves avatars through a fixed center anchor',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final carousel = find.byKey(
        const ValueKey('spendee-test-context-carousel'),
      );
      final carouselRect = tester.getRect(carousel);
      final gestureTarget = find.byKey(
        const ValueKey('spendee-test-context-carousel-gesture'),
      );
      final carouselCenterX = carouselRect.center.dx;

      final gesture = await tester.startGesture(
        tester.getCenter(gestureTarget),
      );
      await gesture.moveBy(const Offset(-52, 0));
      await tester.pump();

      final translated = tester.widget<AnimatedContainer>(carousel);
      expect(translated.transform?.storage[12] ?? 0, 0);

      final outgoingFinder = find.byKey(
        const ValueKey('spendee-test-category-avatar-1-selected'),
      );
      final outgoingRect = tester.getRect(outgoingFinder);
      final incomingFinder = find.byKey(
        const ValueKey('spendee-test-category-avatar-2'),
      );
      final incomingRect = tester.getRect(incomingFinder);
      expect(outgoingRect.center.dx, lessThan(carouselCenterX));
      expect(incomingRect.center.dx, greaterThan(carouselCenterX));
      expect(outgoingRect.right, lessThan(incomingRect.left));

      final outgoing = tester.widget<GlossyCategoryAvatar>(
        find.descendant(
          of: outgoingFinder,
          matching: find.byType(GlossyCategoryAvatar),
        ),
      );
      final incoming = tester.widget<GlossyCategoryAvatar>(
        find.descendant(
          of: incomingFinder,
          matching: find.byType(GlossyCategoryAvatar),
        ),
      );
      expect(outgoing.size, allOf(greaterThan(46), lessThan(66)));
      expect(incoming.size, allOf(greaterThan(46), lessThan(66)));
      expect(incoming.size, greaterThan(outgoing.size));
      expect(incomingRect.right, lessThanOrEqualTo(carouselRect.right));

      await gesture.cancel();
      await tester.pumpAndSettle();
    },
  );

  testWidgets(
    'header menu opens design dropdown for avatar and chart surfaces',
    (tester) async {
      await _pumpDashboard(tester);

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-header-menu-button')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-header-design-menu')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-avatar-surface-background')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-chart-surface-background')),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-avatar-surface-background')),
      );
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-budget-stage1-background')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-budget-stage1-glossy')),
        findsNothing,
      );

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-header-menu-button')),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(
        find.byKey(const ValueKey('spendee-test-chart-surface-background')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('spendee-test-chart-surface-background')),
      );
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-budget-pie-background')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-budget-pie-panel')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-budget-vendor-focus-title')),
        findsOneWidget,
      );
      await tester.drag(
        find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
        const Offset(-140, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-budget-pie-background')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
        findsNothing,
      );
    },
  );

  testWidgets('header menu exposes header avatar and chart glass choices', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-html-c2-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-acrylic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-html-c2-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-acrylic')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-surface-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-surface-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-surface-html-c2-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-surface-liquid-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-surface-acrylic')),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-none')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-none')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-original')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-html-c2-glass'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-liquid-glass'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-acrylic')),
      findsOneWidget,
    );
  });

  testWidgets('header background menu selects one mind page without swipe', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-background-budget')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-background-swipe')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      const Offset(-180, 0),
      warnIfMissed: false,
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d3g')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d4')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d5')),
      findsNothing,
    );
  });

  testWidgets('expense type pill does not paint a pink glow', (tester) async {
    await _pumpDashboard(tester);

    final expenseContainer = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-expense-type-pill')),
        matching: find.byType(Container),
      ),
    );
    final decoration = expenseContainer.decoration as BoxDecoration;
    final shadowColors = decoration.boxShadow
        ?.map((shadow) => shadow.color)
        .toList(growable: false);

    expect(
      shadowColors,
      isNot(contains(predicate<Color>(_isPinkPurpleGlowColor))),
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-expense-type-pill')),
    );
    await tester.pumpAndSettle();

    final activeExpenseContainer = tester.widget<Container>(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-expense-type-pill')),
        matching: find.byType(Container),
      ),
    );
    final activeDecoration = activeExpenseContainer.decoration as BoxDecoration;
    final activeShadowColors = activeDecoration.boxShadow
        ?.map((shadow) => shadow.color)
        .toList(growable: false);

    expect(
      activeShadowColors,
      isNot(contains(predicate<Color>(_isPinkPurpleGlowColor))),
    );
  });

  testWidgets('mind score chart uses fastinfo score graph for active type', (
    tester,
  ) async {
    final store = await _pumpDashboard(
      tester,
      repository: _MindDashboardStatsRepository(),
    );
    await _switchToMindBackground(tester);
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.yearly,
        year: 2026,
      ),
    );
    await tester.pump();

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-expense-type-pill')),
    );
    await tester.pumpAndSettle();

    final expenseScore = SpendeeMindStatsFrame.fromStore(
      store,
    ).expenseFrame.categoryScopeSeries.kontrollScore;
    final expenseChart = find.byKey(
      const ValueKey('spendee-test-mind-score-fastinfo-expense'),
    );
    expect(expenseChart, findsOneWidget);
    expect(
      find.descendant(of: expenseChart, matching: find.byType(MagnetStrip)),
      findsNothing,
    );
    final expenseCustomPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: expenseChart,
        matching: find.byKey(
          const ValueKey('spendee-test-mind-score-fastinfo-paint'),
        ),
      ),
    );
    expect((expenseCustomPaint.painter as dynamic).score, expenseScore);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-income-type-pill')),
    );
    await tester.pumpAndSettle();

    final incomeScore = SpendeeMindStatsFrame.fromStore(
      store,
    ).incomeFrame.categoryScopeSeries.kontrollScore;
    final incomeChart = find.byKey(
      const ValueKey('spendee-test-mind-score-fastinfo-income'),
    );
    expect(incomeChart, findsOneWidget);
    final incomeCustomPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: incomeChart,
        matching: find.byKey(
          const ValueKey('spendee-test-mind-score-fastinfo-paint'),
        ),
      ),
    );
    expect((incomeCustomPaint.painter as dynamic).score, incomeScore);

    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 1,
      ),
    );
    await tester.pump();
    final monthlyIncomeScore = SpendeeMindStatsFrame.fromStore(
      store,
    ).incomeFrame.categoryScopeSeries.kontrollScore;
    final monthlyIncomeCustomPaint = tester.widget<CustomPaint>(
      find.descendant(
        of: incomeChart,
        matching: find.byKey(
          const ValueKey('spendee-test-mind-score-fastinfo-paint'),
        ),
      ),
    );
    expect(
      (monthlyIncomeCustomPaint.painter as dynamic).score,
      monthlyIncomeScore,
    );
    expect(monthlyIncomeScore, isNot(incomeScore));
  });

  testWidgets('mind header menu keeps a single mind mode', (tester) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d3g')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d4')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-mode-d5')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-d1')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-d2')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-d3g')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-d4')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-page-d5')),
      findsNothing,
    );
    expect(find.text('MIND'), findsOneWidget);
    expect(find.text('MIND D1'), findsNothing);
  });

  testWidgets(
    'mind background container choices use separated component surfaces',
    (tester) async {
      await _pumpDashboard(tester);
      await _switchToMindBackground(tester);

      await _dragHeaderBy(tester, 134);
      await tester.pump(const Duration(milliseconds: 500));
      await _dragHeaderBy(tester, 272);
      await tester.pump(const Duration(milliseconds: 500));

      await _tapHeaderMenuItem(
        tester,
        const ValueKey('spendee-test-mind-stage1-surface-liquid-glass'),
      );
      await _tapHeaderMenuItem(
        tester,
        const ValueKey('spendee-test-mind-stage2-surface-acrylic'),
      );

      expect(
        find.byKey(const ValueKey('spendee-test-mind-stage1-liquid-glass')),
        findsNothing,
        reason: 'Mind stage1 must not create a shared liquid wrapper.',
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-stage2-acrylic')),
        findsNothing,
        reason: 'Mind stage2 must not create a shared acrylic wrapper.',
      );
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-volume-card-liquid-glass'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-pattern-card-liquid-glass'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-year-2026-acrylic')),
        findsOneWidget,
      );

      await _tapHeaderMenuItem(
        tester,
        const ValueKey('spendee-test-mind-stage1-surface-background'),
      );
      await _tapHeaderMenuItem(
        tester,
        const ValueKey('spendee-test-mind-stage2-surface-background'),
      );

      _expectOnlyBackgroundSurface('spendee-test-mind-volume-card');
      _expectOnlyBackgroundSurface('spendee-test-mind-pattern-card');
      _expectOnlyBackgroundSurface('spendee-test-mind-year-2026');
      expect(
        find.byKey(const ValueKey('spendee-test-mind-stage1-background')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-stage2-background')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'mind background surface removes all inner component containers',
    (tester) async {
      await _pumpDashboard(tester);
      await _switchToMindBackground(tester);

      await _dragHeaderBy(tester, 134);
      await tester.pump(const Duration(milliseconds: 500));
      await _dragHeaderBy(tester, 272);
      await tester.pump(const Duration(milliseconds: 500));

      await _tapHeaderMenuItem(
        tester,
        const ValueKey('spendee-test-mind-stage1-surface-background'),
      );
      await _tapHeaderMenuItem(
        tester,
        const ValueKey('spendee-test-mind-stage2-surface-background'),
      );

      final stage1 = find.byKey(
        const ValueKey('spendee-test-mind-stage1-boxed-graphs'),
      );
      final stage2 = find.byKey(
        const ValueKey('spendee-test-mind-sum-heatmap'),
      );
      expect(stage1, findsOneWidget);
      expect(stage2, findsOneWidget);
      expect(
        find.descendant(
          of: stage1,
          matching: find.byWidgetPredicate(_isWhiteGlassContainerDecoration),
        ),
        findsNothing,
      );
      expect(
        find.descendant(
          of: stage2,
          matching: find.byWidgetPredicate(_isWhiteGlassContainerDecoration),
        ),
        findsNothing,
      );
    },
  );

  testWidgets('mind stage1 volume and pattern charts follow active type', (
    tester,
  ) async {
    final store = await _pumpDashboard(
      tester,
      repository: _MindDashboardStatsRepository(),
    );
    await _switchToMindBackground(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 500));

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-expense-type-pill')),
    );
    await tester.pumpAndSettle();

    final expenseFrame = SpendeeMindStatsFrame.fromStore(store);
    final expenseVolumePaint = _mindCustomPaint(
      tester,
      const ValueKey('spendee-test-mind-volume-chart-expense'),
      const ValueKey('spendee-test-mind-volume-paint'),
    );
    final expensePatternPaint = _mindCustomPaint(
      tester,
      const ValueKey('spendee-test-mind-pattern-chart-expense'),
      const ValueKey('spendee-test-mind-pattern-paint'),
    );
    expect(
      (expenseVolumePaint.painter as dynamic).activeType,
      TransactionType.expense,
    );
    expect(
      _seriesPointSignature(
        (expenseVolumePaint.painter as dynamic).volumePoints,
      ),
      _seriesPointSignature(
        expenseFrame.expenseFrame.categoryScopeSeries.valueIndex,
      ),
    );
    expect(
      (expensePatternPaint.painter as dynamic).activeType,
      TransactionType.expense,
    );
    expect(
      _helperBarSignature((expensePatternPaint.painter as dynamic).patternBars),
      _helperBarSignature(
        expenseFrame.expenseFrame.categoryScopeSeries.helperBars,
      ),
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-volume-chart-income')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-pattern-chart-income')),
      findsNothing,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-income-type-pill')),
    );
    await tester.pumpAndSettle();

    final incomeFrame = SpendeeMindStatsFrame.fromStore(store);
    final incomeVolumePaint = _mindCustomPaint(
      tester,
      const ValueKey('spendee-test-mind-volume-chart-income'),
      const ValueKey('spendee-test-mind-volume-paint'),
    );
    final incomePatternPaint = _mindCustomPaint(
      tester,
      const ValueKey('spendee-test-mind-pattern-chart-income'),
      const ValueKey('spendee-test-mind-pattern-paint'),
    );
    expect(
      (incomeVolumePaint.painter as dynamic).activeType,
      TransactionType.income,
    );
    expect(
      _seriesPointSignature(
        (incomeVolumePaint.painter as dynamic).volumePoints,
      ),
      _seriesPointSignature(
        incomeFrame.incomeFrame.categoryScopeSeries.valueIndex,
      ),
    );
    expect(
      (incomePatternPaint.painter as dynamic).activeType,
      TransactionType.income,
    );
    expect(
      _helperBarSignature((incomePatternPaint.painter as dynamic).patternBars),
      _helperBarSignature(
        incomeFrame.incomeFrame.categoryScopeSeries.helperBars,
      ),
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-volume-chart-expense')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-pattern-chart-expense')),
      findsNothing,
    );
  });

  testWidgets('mind header surface choices sit above the mind background', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-normal')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-html-c2-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-surface-acrylic')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-html-c2-glass')),
    );
    await tester.pumpAndSettle();

    final c2 = find.byKey(const ValueKey('spendee-test-header-c2-glass'));
    expect(c2, findsOneWidget);
    expect(
      find.descendant(
        of: c2,
        matching: find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      ),
      findsOneWidget,
    );
    final c2Paint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('spendee-test-header-c2-paint')),
    );
    expect(
      c2Paint.foregroundPainter,
      isNotNull,
      reason: 'C2 design must paint over the colored Mind header.',
    );
    expect(
      _widgetContainsKey(
        c2Paint.child!,
        const ValueKey('spendee-test-mind-page-mind'),
      ),
      isTrue,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-acrylic')),
    );
    await tester.pumpAndSettle();

    final acrylic = find.byKey(const ValueKey('spendee-test-header-acrylic'));
    expect(acrylic, findsOneWidget);
    expect(
      find.descendant(
        of: acrylic,
        matching: find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      ),
      findsOneWidget,
      reason: 'Acrylic must wrap the full colored Mind header container.',
    );
    expect(
      find.descendant(of: acrylic, matching: find.text('MIND')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: acrylic,
        matching: find.byKey(
          const ValueKey('spendee-test-header-acrylic-highlight'),
        ),
      ),
      findsOneWidget,
    );
    final acrylicStack = _stackContainingKeys(tester, acrylic, const [
      ValueKey('spendee-test-mind-page-mind'),
      ValueKey('spendee-test-header-acrylic-highlight'),
    ]);
    expect(
      _stackChildIndexContainingKey(
        acrylicStack,
        const ValueKey('spendee-test-mind-page-mind'),
      ),
      lessThan(
        _stackChildIndexContainingKey(
          acrylicStack,
          const ValueKey('spendee-test-header-acrylic-highlight'),
        ),
      ),
      reason: 'Acrylic highlight must be painted over the full Mind header.',
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    final liquid = find.byKey(
      const ValueKey('spendee-test-header-liquid-glass'),
    );
    expect(liquid, findsOneWidget);
    expect(
      find.descendant(
        of: liquid,
        matching: find.byKey(const ValueKey('spendee-test-mind-page-mind')),
      ),
      findsOneWidget,
      reason: 'Liquid Glass must wrap the full colored Mind header container.',
    );
    expect(
      find.descendant(
        of: liquid,
        matching: find.byKey(
          const ValueKey('spendee-test-header-liquid-glare'),
        ),
      ),
      findsOneWidget,
    );
    final liquidStack = tester
        .widgetList<Stack>(
          find.descendant(
            of: find.byKey(
              const ValueKey('spendee-test-header-liquid-fallback'),
            ),
            matching: find.byType(Stack),
          ),
        )
        .firstWhere(
          (stack) =>
              _stackChildIndexContainingKey(
                    stack,
                    const ValueKey('spendee-test-mind-page-mind'),
                  ) >=
                  0 &&
              _stackChildIndexContainingKey(
                    stack,
                    const ValueKey('spendee-test-header-liquid-glare'),
                  ) >=
                  0,
        );
    final mindIndex = _stackChildIndexContainingKey(
      liquidStack,
      const ValueKey('spendee-test-mind-page-mind'),
    );
    final glareIndex = _stackChildIndexContainingKey(
      liquidStack,
      const ValueKey('spendee-test-header-liquid-glare'),
    );
    expect(
      mindIndex,
      lessThan(glareIndex),
      reason: 'Liquid glare must be painted over the full Mind header.',
    );
  });

  testWidgets('mind stage0 score chart uses the Stats FastInfo style', (
    tester,
  ) async {
    await _pumpDashboard(tester, repository: _MindDashboardStatsRepository());
    await _switchToMindBackground(tester);

    final paint = _mindCustomPaint(
      tester,
      const ValueKey('spendee-test-mind-score-fastinfo-expense'),
      const ValueKey('spendee-test-mind-score-fastinfo-paint'),
    );

    final painter = paint.painter as dynamic;
    expect(painter.drawsBackground, isTrue);
    expect(painter.drawsEndpointBadge, isTrue);
  });

  testWidgets('mind acrylic header design paints over the colored header', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _switchToMindBackground(tester);
    await _tapHeaderMenuItem(
      tester,
      const ValueKey('spendee-test-header-surface-acrylic'),
    );

    final acrylic = find.byKey(const ValueKey('spendee-test-header-acrylic'));
    expect(acrylic, findsOneWidget);
    expect(
      find.descendant(
        of: acrylic,
        matching: find.byKey(
          const ValueKey('spendee-test-header-acrylic-highlight'),
        ),
      ),
      findsOneWidget,
    );
    final acrylicStack = _stackContainingKeys(tester, acrylic, const [
      ValueKey('spendee-test-mind-page-mind'),
      ValueKey('spendee-test-header-acrylic-highlight'),
    ]);
    expect(
      _stackChildIndexContainingKey(
        acrylicStack,
        const ValueKey('spendee-test-mind-page-mind'),
      ),
      lessThan(
        _stackChildIndexContainingKey(
          acrylicStack,
          const ValueKey('spendee-test-header-acrylic-highlight'),
        ),
      ),
    );
  });

  testWidgets('mind stage1 hides the inline summary and filter label', (
    tester,
  ) async {
    final store = await _pumpDashboard(tester);
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.yearly,
        year: 2026,
      ),
    );
    await tester.pump();
    await _switchToMindBackground(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 500));

    final header = find.byKey(const ValueKey('spendee-test-header-card'));
    expect(header, findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-summary-pill')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: header,
        matching: find.text('2026 · Minden kategória'),
      ),
      findsNothing,
      reason: 'The summary pill already owns the period/filter label.',
    );
  });

  testWidgets('mind score chart keeps the stage0 rect across stages', (
    tester,
  ) async {
    await _pumpDashboard(tester, repository: _MindDashboardStatsRepository());
    await _switchToMindBackground(tester);

    final header = find.byKey(const ValueKey('spendee-test-header-card'));
    expect(
      find.descendant(
        of: header,
        matching: find.textContaining('Minden kategória'),
      ),
      findsNothing,
      reason: 'The summary pill already owns the filter label.',
    );
    final stage0Rect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-mind-score-chart')),
    );

    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 500));

    _expectRectsClose(
      tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-score-chart')),
      ),
      stage0Rect,
    );

    await _dragHeaderBy(tester, 272);
    await tester.pump(const Duration(milliseconds: 500));

    _expectRectsClose(
      tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-score-chart')),
      ),
      stage0Rect,
    );
  });

  testWidgets('budget interactions do not build mind stats frames', (
    tester,
  ) async {
    final builds = _captureMindStatsBuilds();
    await _pumpDashboard(tester, repository: _MindDashboardStatsRepository());
    builds.clear();

    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 16));

    final carouselGesture = find.byKey(
      const ValueKey('spendee-test-context-carousel-gesture'),
    );
    expect(carouselGesture, findsOneWidget);
    final gesture = await tester.startGesture(
      tester.getCenter(carouselGesture),
    );
    await gesture.moveBy(const Offset(-34, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(-34, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.up();
    await tester.pump();

    expect(
      builds,
      isEmpty,
      reason:
          'Budget header/avatar motion should stay on the old smooth path and '
          'must not pay the Mind stats-frame cost.',
    );
  });

  testWidgets('spendee test mode skips classic home metrics before dashboard', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _CountingTransactionStore(_MindDashboardStatsRepository());
    await store.start();
    store.resetAccessCounts();
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        dashboardDesignMode: DashboardDesignMode.spendeeTest,
      ),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionHomePage(store: store, expenseTheme: theme),
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(SpendeeTestDashboard), findsOneWidget);
    expect(
      store.fastInfoMetricsAccesses,
      0,
      reason:
          'The classic FastInfo metrics are not used by SpendeeTestDashboard '
          'and are too expensive to compute before returning it.',
    );
    expect(
      store.visibleGhostTransactionsAccesses,
      0,
      reason:
          'SpendeeTestDashboard does not render the classic ghost log input.',
    );
  });

  testWidgets('header geometry drag does not requery spendee log content', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(412, 892);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final store = _CountingTransactionStore(_MindDashboardStatsRepository());
    await store.start();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpendeeTestDashboard(
            store: store,
            expenseTheme: ExpenseTheme.fromSettings(
              AppThemeSettings.defaults(),
            ),
            onPickSummaryMonth: () {},
            onEditTransaction: (_) {},
            onDeleteTransactionRequested: (_) async => true,
            onVendorSheetRequested: () {},
            logBottomPadding: 0,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    store.resetAccessCounts();

    final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
    final gesture = await tester.startGesture(tester.getCenter(handle));
    for (var index = 0; index < 4; index += 1) {
      await gesture.moveBy(const Offset(0, 12));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await gesture.up();
    await tester.pump();

    expect(
      store.visibleTransactionsAccesses,
      0,
      reason:
          'Header geometry-only drag should not rebuild the transaction count.',
    );
    expect(
      store.visibleDisplayLogEntriesAccesses,
      0,
      reason:
          'Header geometry-only drag should not rebuild or requery the log list.',
    );
  });

  testWidgets('mind interactions reuse cached stats frame and log cache misses', (
    tester,
  ) async {
    final builds = _captureMindStatsBuilds();
    DebugConsole.clear();
    final store = await _pumpDashboard(
      tester,
      repository: _MindDashboardStatsRepository(),
    );
    builds.clear();
    DebugConsole.clear();

    await _switchToMindBackground(tester);
    expect(builds, hasLength(1));
    expect(builds.single.reason, 'header-background-mind');
    expect(builds.single.modeKey, 'sum');
    expect(builds.single.activeType, TransactionType.expense);
    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (line) =>
              line.contains('[Perf] SpendeeTest MindStats cache_miss') &&
              line.contains('reason=header-background-mind') &&
              line.contains('mode=sum') &&
              line.contains('type=expense'),
        ),
      ),
    );

    builds.clear();
    DebugConsole.clear();
    final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
    final drag = await tester.startGesture(tester.getCenter(handle));
    for (var index = 0; index < 4; index += 1) {
      await drag.moveBy(const Offset(0, 18));
      await tester.pump(const Duration(milliseconds: 16));
    }
    await drag.up();
    await tester.pump();

    expect(
      builds,
      isEmpty,
      reason:
          'Mind header drag changes only geometry; unchanged stats inputs must '
          'reuse the cached frame.',
    );
    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (line) =>
              line.contains('[Perf] SpendeeTest header_drag') &&
              line.contains('background=mind') &&
              line.contains('updates=4'),
        ),
      ),
    );

    builds.clear();
    DebugConsole.clear();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-income-type-pill')),
    );
    await tester.pumpAndSettle();
    expect(
      builds,
      isEmpty,
      reason:
          'The cached Mind frame already contains income and expense frames; '
          'type switching should only swap activeFrame.',
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-score-fastinfo-income')),
      findsOneWidget,
    );

    builds.clear();
    DebugConsole.clear();
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.yearly,
        year: 2026,
      ),
    );
    await tester.pump();
    expect(builds, hasLength(1));
    expect(builds.single.modeKey, 'yearly');
  });

  testWidgets('mind stage content follows summary pill scope', (tester) async {
    final store = await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
    );
    await tester.pumpAndSettle();

    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('spendee-test-mind-stage1-boxed-graphs')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-stage1-sum')),
      findsOneWidget,
    );

    await _dragHeaderBy(tester, 272);
    await tester.pump(const Duration(milliseconds: 500));
    expect(
      find.byKey(const ValueKey('spendee-test-mind-stage2-sum')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-sum-heatmap')),
      findsOneWidget,
    );

    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.yearly,
        year: 2026,
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('spendee-test-mind-stage2-yearly')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-yearly-heatmap')),
      findsOneWidget,
    );

    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await tester.pump();
    expect(
      find.byKey(const ValueKey('spendee-test-mind-stage2-monthly')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-monthly-heatmap')),
      findsOneWidget,
    );
  });

  testWidgets('summary pill drags with feedback and shifts the period', (
    tester,
  ) async {
    final store = await _pumpDashboard(tester);
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await tester.pump();

    expect(store.activeSummaryTitle, 'Július 2026');
    final pill = find.byKey(const ValueKey('spendee-test-summary-pill'));

    final gesture = await tester.startGesture(tester.getCenter(pill));
    await gesture.moveBy(const Offset(-18, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await gesture.moveBy(const Offset(-46, 0));
    await tester.pump();

    final draggedPill = tester.widget<AnimatedContainer>(pill);
    expect(draggedPill.transform?.storage[12] ?? 0, lessThan(-24));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.activeSummaryTitle, 'Augusztus 2026');
    final settledPill = tester.widget<AnimatedContainer>(pill);
    expect(settledPill.transform?.storage[12] ?? 0, 0);

    await tester.drag(pill, const Offset(0, -56), warnIfMissed: false);
    await tester.pump(const Duration(milliseconds: 400));

    expect(store.summaryWindow, SummaryWindow.yearly);
  });

  testWidgets('budget and mind container softness sliders are scoped', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 500));
    final budgetStage1 = find.byKey(
      const ValueKey('spendee-test-budget-stage1-liquid-glass'),
    );
    expect(budgetStage1, findsOneWidget);
    expect((tester.widget(budgetStage1) as dynamic).softness as double, 0);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    final avatarSlider = find.byKey(
      const ValueKey('spendee-test-avatar-surface-softness-slider'),
    );
    expect(avatarSlider, findsOneWidget);
    await tester.ensureVisible(avatarSlider);
    await tester.pumpAndSettle();
    await tester.drag(avatarSlider, const Offset(72, 0));
    await tester.pump();
    final avatarSoftness =
        (tester.widget(budgetStage1) as dynamic).softness as double;
    expect(avatarSoftness, greaterThan(0));
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await _dragHeaderBy(tester, 272);
    await tester.pump(const Duration(milliseconds: 500));
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-chart-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    final budgetStage2 = find.byKey(
      const ValueKey('spendee-test-budget-pie-liquid-glass'),
    );
    expect(budgetStage2, findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    final chartSlider = find.byKey(
      const ValueKey('spendee-test-chart-surface-softness-slider'),
    );
    expect(chartSlider, findsOneWidget);
    await tester.ensureVisible(chartSlider);
    await tester.pumpAndSettle();
    await tester.drag(chartSlider, const Offset(84, 0));
    await tester.pump();
    final chartSoftness =
        (tester.widget(budgetStage2) as dynamic).softness as double;
    expect(chartSoftness, greaterThan(0));
    expect((tester.widget(budgetStage1) as dynamic).softness, avatarSoftness);
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-mind')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('spendee-test-mind-stage1-surface-liquid-glass'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('spendee-test-mind-stage1-surface-liquid-glass'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('spendee-test-mind-stage2-surface-liquid-glass'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('spendee-test-mind-stage2-surface-liquid-glass'),
      ),
    );
    await tester.pumpAndSettle();

    final mindStage1 = find.byKey(
      const ValueKey('spendee-test-mind-volume-card-liquid-glass'),
    );
    final mindStage2 = find.byKey(
      const ValueKey('spendee-test-mind-year-2026-liquid-glass'),
    );
    expect(mindStage1, findsOneWidget);
    expect(mindStage2, findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    final mindStage1Slider = find.byKey(
      const ValueKey('spendee-test-mind-stage1-softness-slider'),
    );
    expect(mindStage1Slider, findsOneWidget);
    await tester.ensureVisible(mindStage1Slider);
    await tester.pumpAndSettle();
    await tester.drag(mindStage1Slider, const Offset(72, 0));
    await tester.pump();
    expect(
      (tester.widget(mindStage1) as dynamic).softness as double,
      greaterThan(0),
    );
    expect((tester.widget(mindStage2) as dynamic).softness as double, 0);
  });

  testWidgets('header menu controls chart list row surface mode', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-html-c2-glass'),
      ),
      findsOneWidget,
    );
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-html-c2-glass'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-html-c2-glass'),
      ),
    );
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey('spendee-test-budget-vendor-row-0-html-c2-glass'),
      ),
      findsOneWidget,
    );
    final row = find.byKey(
      const ValueKey('spendee-test-budget-vendor-row-0-html-c2-glass'),
    );
    await tester.ensureVisible(row);
    await tester.tap(row);
    await tester.pumpAndSettle();
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey('spendee-test-budget-vendor-focus-title'),
            ),
          )
          .data,
      'Élelmiszer bolt',
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-liquid-glass'),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('spendee-test-chart-list-surface-liquid-glass'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('spendee-test-budget-vendor-row-0-liquid-glass'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-acrylic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-acrylic')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-budget-vendor-row-0-acrylic')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-none')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-chart-list-surface-none')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-budget-vendor-row-0-pillless')),
      findsOneWidget,
    );
  });

  testWidgets('header avatar and chart select c2 liquid and acrylic surfaces', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-html-c2-glass')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-c2-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-c2-mask')),
      findsNothing,
    );
    expect(find.text('BUDGET'), findsOneWidget);

    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-liquid-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-liquid-glare')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(
          const ValueKey('spendee-test-budget-stage1-liquid-glass'),
        ),
        matching: find.byKey(const ValueKey('spendee-test-context-carousel')),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-avatar-surface-acrylic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-avatar-surface-acrylic')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-acrylic')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-budget-stage1-acrylic')),
        matching: find.byKey(const ValueKey('spendee-test-context-carousel')),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-liquid-glass')),
      findsOneWidget,
    );
    expect(find.text('BUDGET'), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-acrylic')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-header-acrylic')),
      findsOneWidget,
    );
    expect(find.text('BUDGET'), findsOneWidget);

    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-surface-html-c2-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-chart-surface-html-c2-glass')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-html-c2-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-html-c2-mask')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-vendor-focus-title')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-chart-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-liquid-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-liquid-glare')),
      findsOneWidget,
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-chart-surface-acrylic')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-chart-surface-acrylic')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-acrylic')),
      findsOneWidget,
    );
    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
    );
  });

  testWidgets('header liquid softness slider only adjusts header glass', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    final headerSurfaceFinder = find.byKey(
      const ValueKey('spendee-test-header-liquid-glass'),
    );
    expect(headerSurfaceFinder, findsOneWidget);
    final initialHeaderSoftness =
        (tester.widget(headerSurfaceFinder) as dynamic).softness as double;
    expect(initialHeaderSoftness, greaterThan(.45));

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    final slider = find.byKey(
      const ValueKey('spendee-test-header-liquid-softness-slider'),
    );
    expect(slider, findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-header-liquid-softness-value')),
      findsOneWidget,
    );

    await tester.drag(slider, const Offset(72, 0));
    await tester.pump();

    final adjustedHeaderSoftness =
        (tester.widget(headerSurfaceFinder) as dynamic).softness as double;
    expect(adjustedHeaderSoftness, greaterThan(initialHeaderSoftness));

    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-avatar-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    final avatarSurface =
        tester.widget(
              find.byKey(
                const ValueKey('spendee-test-budget-stage1-liquid-glass'),
              ),
            )
            as dynamic;
    expect(avatarSurface.softness as double, 0);
  });

  testWidgets('header menu selects exact HTML C2 avatar glass container', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-background')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-glass')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-surface-html-c2-glass')),
      findsOneWidget,
    );

    await tester.ensureVisible(
      find.byKey(const ValueKey('spendee-test-avatar-surface-html-c2-glass')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-avatar-surface-html-c2-glass')),
    );
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final c2Surface = find.byKey(
      const ValueKey('spendee-test-budget-stage1-html-c2-glass'),
    );
    expect(c2Surface, findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-glossy')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-background')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-partition-summary-label')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-context-avatar-label')),
      findsNothing,
    );
    expect(tester.getRect(c2Surface), const Rect.fromLTWH(36, 200, 340, 130));

    final clip = tester.widget<ClipRRect>(
      find.byKey(const ValueKey('spendee-test-budget-stage1-html-c2-clip')),
    );
    expect(clip.borderRadius, BorderRadius.circular(17));
    expect(
      find.descendant(of: c2Surface, matching: find.byType(BackdropFilter)),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-html-c2-mask')),
      findsNothing,
    );

    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-html-c2-linear')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-html-c2-radial')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-html-c2-paint')),
      findsOneWidget,
    );

    final avatarArea = find.byKey(
      const ValueKey('spendee-test-budget-stage1-html-c2-avatar-area'),
    );
    expect(
      find.descendant(
        of: avatarArea,
        matching: find.byKey(const ValueKey('spendee-test-context-carousel')),
      ),
      findsOneWidget,
    );
    final surfaceRect = tester.getRect(c2Surface);
    final avatarAreaRect = tester.getRect(avatarArea);
    expect(avatarAreaRect.left - surfaceRect.left, closeTo(10, .75));
    expect(surfaceRect.right - avatarAreaRect.right, closeTo(10, .75));
    expect(avatarAreaRect.top - surfaceRect.top, closeTo(0, .75));
    expect(surfaceRect.bottom - avatarAreaRect.bottom, closeTo(0, .75));

    final sampled = await _sampleHeaderBoundaryPixel(
      tester,
      surfaceRect.topLeft + const Offset(58, 34),
    );
    expect(sampled.red, lessThan(218));
    expect(sampled.green, greaterThan(sampled.red + 10));
    expect(sampled.blue, greaterThan(sampled.red + 18));
  });

  testWidgets(
    'stage 1 and 2 show avatar name and partition summary below progress',
    (tester) async {
      await _pumpDashboard(tester);

      expect(
        find.byKey(const ValueKey('spendee-test-context-avatar-label')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-partition-summary-label')),
        findsNothing,
      );

      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-context-avatar-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-partition-summary-label')),
        findsOneWidget,
      );
      final partitionRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-partition-bar')),
      );
      final headerRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-header-card')),
      );
      expect(partitionRect.left - headerRect.left, closeTo(20, .75));
      expect(headerRect.right - partitionRect.right, closeTo(20, .75));
      final summaryRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-partition-summary-label')),
      );
      expect(summaryRect.top - partitionRect.bottom, greaterThanOrEqualTo(5));
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('spendee-test-context-avatar-label')),
            )
            .data,
        'Élelmiszer',
      );
      final summaryTexts = tester
          .widgetList<Text>(
            find.descendant(
              of: find.byKey(
                const ValueKey('spendee-test-partition-summary-label'),
              ),
              matching: find.byType(Text),
            ),
          )
          .map((widget) => widget.data)
          .toList();
      expect(summaryTexts, contains('Elköltve: 100%'));
      expect(summaryTexts, contains('Maradt: 0 Ft'));
      final spentRect = tester.getRect(find.text('Elköltve: 100%'));
      final remainingRect = tester.getRect(find.text('Maradt: 0 Ft'));
      expect(remainingRect.left - spentRect.right, greaterThanOrEqualTo(12));
      expect(summaryRect.right - remainingRect.right, closeTo(0, .75));

      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-context-avatar-label')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-partition-summary-label')),
        findsOneWidget,
      );
    },
  );

  testWidgets('stage 1 raises avatar belt without moving the selected name', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final carouselRect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-context-carousel')),
    );
    final selectedAvatarRect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-category-avatar-1-selected')),
    );
    final surfaceRect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-budget-stage1-glossy')),
    );
    final nameRect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-context-avatar-label')),
    );

    expect(selectedAvatarRect.center.dy, lessThan(carouselRect.center.dy - 3));
    expect(surfaceRect.bottom - nameRect.bottom, closeTo(9, .75));
  });

  testWidgets('live carousel ticks pulse the new center and cancel recenters', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final carousel = find.byKey(
      const ValueKey('spendee-test-context-carousel-gesture'),
    );
    final gesture = await tester.startGesture(tester.getCenter(carousel));
    await gesture.moveBy(const Offset(-20, 0));
    await gesture.moveBy(const Offset(-50, 0));
    await tester.pump(const Duration(milliseconds: 20));

    final selected = tester.widget<GlossyCategoryAvatar>(
      find.descendant(
        of: find.byKey(
          const ValueKey('spendee-test-category-avatar-2-selected'),
        ),
        matching: find.byType(GlossyCategoryAvatar),
      ),
    );
    expect(selected.pulsing, isTrue);

    await gesture.cancel();
    await tester.pumpAndSettle();
    final translated = tester.widget<AnimatedContainer>(
      find.byKey(const ValueKey('spendee-test-context-carousel')),
    );
    expect(translated.transform?.storage[12] ?? 0, 0);
  });

  testWidgets('budget carousel defers store filter while sliding', (
    tester,
  ) async {
    final store = _CountingTransactionStore(_DashboardTestRepository());
    await store.start();
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    store.resetAccessCounts();

    final carousel = find.byKey(
      const ValueKey('spendee-test-context-carousel-gesture'),
    );
    final gesture = await tester.startGesture(tester.getCenter(carousel));
    await gesture.moveBy(const Offset(-70, 0));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      store.categoryFilterChanges,
      0,
      reason:
          'Carousel sliding should keep selection local and avoid store '
          'filter/prewarm work until the user releases.',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(store.categoryFilterChanges, lessThanOrEqualTo(1));
  });

  testWidgets('budget carousel includes overview budget avatar', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'spendee-test-budget-avatar-overview-expense_budget-all_time-all',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-category-avatar-1-selected')),
      findsOneWidget,
    );
  });

  testWidgets('budget carousel renders exactly five bounded avatar slots', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final carousel = find.byKey(
      const ValueKey('spendee-test-context-carousel'),
    );
    final carouselRect = tester.getRect(carousel);
    final slotFinders = find.byWidgetPredicate((widget) {
      final key = widget.key;
      return key is ValueKey<String> &&
          key.value.startsWith('spendee-test-context-avatar-slot-');
    });

    expect(slotFinders, findsNWidgets(5));
    for (final element in slotFinders.evaluate()) {
      final key = element.widget.key;
      expect(key, isA<ValueKey<String>>());
      final rect = tester.getRect(find.byKey(key!));
      expect(rect.left, greaterThanOrEqualTo(carouselRect.left));
      expect(rect.right, lessThanOrEqualTo(carouselRect.right));
    }
  });

  testWidgets('header menu toggles colored avatar depth and top highlights', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final categoryDepth = find.byKey(
      const ValueKey('spendee-test-avatar-3d-effect-category-1'),
    );
    expect(categoryDepth, findsOneWidget);
    final depthPainter =
        tester.widget<CustomPaint>(categoryDepth).painter as dynamic;
    expect(depthPainter.drawsWhiteArc, isFalse);
    expect(depthPainter.usesAccentColor, isTrue);
    expect(depthPainter.hasInnerDepthShadow, isTrue);
    expect(
      find.byKey(
        const ValueKey(
          'spendee-test-avatar-top-highlight-overview-expense_budget-all_time-all',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-top-highlight-category-1'),
      ),
      findsOneWidget,
    );
    expect(
      (tester.widget<GlossyCategoryAvatar>(
                find.descendant(
                  of: find.byKey(
                    const ValueKey('spendee-test-category-avatar-1-selected'),
                  ),
                  matching: find.byType(GlossyCategoryAvatar),
                ),
              )
              as dynamic)
          .showTopHighlight,
      isFalse,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-effect-3d-toggle')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-effect-top-highlight-toggle'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-avatar-effect-3d-toggle')),
    );
    await tester.pumpAndSettle();
    expect(_avatar3dEffectFinders(), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(
        const ValueKey('spendee-test-avatar-effect-top-highlight-toggle'),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey(
          'spendee-test-avatar-top-highlight-overview-expense_budget-all_time-all',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-top-highlight-category-1'),
      ),
      findsNothing,
    );
    expect(
      (tester.widget<GlossyCategoryAvatar>(
                find.descendant(
                  of: find.byKey(
                    const ValueKey('spendee-test-category-avatar-1-selected'),
                  ),
                  matching: find.byType(GlossyCategoryAvatar),
                ),
              )
              as dynamic)
          .showTopHighlight,
      isFalse,
    );
  });

  testWidgets('avatar outer glass halo is white limit progress', (
    tester,
  ) async {
    final store = TransactionStore(
      _DashboardTestRepository(),
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    expect(_avatarLegacyProgressFinders(), findsNothing);
    final progressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      ),
    );
    final painter = progressPaint.painter as dynamic;
    expect(painter.progress, closeTo(75240 / 80000, .001));
    expect(painter.progressColor, Colors.white);
    expect(painter.usesOuterGlassHalo, isTrue);
    expect(painter.drawsInsideAvatarBody, isFalse);
    expect(painter.startRadians, closeTo(-math.pi / 2, .001));
    expect(painter.clockwise, isTrue);
    expect(painter.strokeWidth, greaterThanOrEqualTo(8));
  });

  testWidgets('long press avatar shrinks while limit edit is active', (
    tester,
  ) async {
    final repository = _SavingDashboardTestRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final scaleFinder = find.byKey(
      const ValueKey('spendee-test-avatar-press-scale-category-1'),
    );
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);

    final avatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );

    final previewGesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, closeTo(.8, .001));

    await previewGesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);

    await tester.tap(avatar);
    await tester.pump(const Duration(milliseconds: 180));
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);

    final gesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 650));

    expect(tester.widget<AnimatedScale>(scaleFinder).scale, closeTo(.8, .001));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);
  });

  testWidgets(
    'stage 2 category rows select avatar then switch to vendor chart',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      await tester.tapAt(
        tester
            .getRect(
              find.byKey(const ValueKey('spendee-test-budget-pie-donut')),
            )
            .center,
      );
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('spendee-test-budget-pie-row-3'));
      await tester.ensureVisible(row);
      await tester.pump();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-category-avatar-3-selected')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey('spendee-test-budget-vendor-focus-title'),
              ),
            )
            .data,
        'Albérlet',
      );
    },
  );

  testWidgets('stage 2 keeps pie fixed and only scrolls the list', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    expect(find.text('Kategória arány'), findsNothing);
    expect(find.text('limit mix'), findsNothing);
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-fixed-top')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-list-scroll')),
      findsOneWidget,
    );
  });

  testWidgets('stage 2 pie center and slices select budget avatars', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    final donutRect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-budget-pie-donut')),
    );
    await tester.tapAt(donutRect.center);
    await tester.pumpAndSettle();

    expect(
      find.byKey(
        const ValueKey(
          'spendee-test-budget-avatar-overview-expense_budget-all_time-all-selected',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
    );

    await tester.tapAt(donutRect.center + const Offset(34, -18));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-category-avatar-1-selected')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
    );
  });

  testWidgets('long press avatar vertical swipe saves live category limits', (
    tester,
  ) async {
    final repository = _SavingDashboardTestRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final avatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    final gesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveBy(const Offset(0, -22));
    await tester.pump(const Duration(milliseconds: 90));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.savedLimitPayloads, isNotEmpty);
    expect(repository.savedLimitPayloads.last['targetType'], 'category');
    expect(repository.savedLimitPayloads.last['targetId'], 1);
    expect(repository.savedLimitPayloads.last['hasLimit'], isTrue);
    expect(
      repository.savedLimitPayloads.last['limitAmount'],
      greaterThan(80000),
    );
    expect(
      tester
          .widget<Text>(find.byKey(const ValueKey('spendee-test-header-value')))
          .data,
      contains('81 000 Ft'),
    );
  });

  testWidgets('limit ticks save without store notify storms until release', (
    tester,
  ) async {
    final repository = _SavingDashboardTestRepository();
    final store = _CountingTransactionStore(repository);
    await store.start();
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    store.resetAccessCounts();

    final avatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    final gesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 650));
    await gesture.moveBy(const Offset(0, -52));
    await tester.pump(const Duration(milliseconds: 90));

    expect(
      repository.savedLimitPayloads,
      isNotEmpty,
      reason: 'Limit ticks still persist automatically while swiping.',
    );
    expect(
      store.listenerNotifications,
      0,
      reason:
          'Tick saves must not notify the whole store and trigger Stats '
          'prewarm/content rebuild storms before release.',
    );

    await gesture.up();
    await tester.pumpAndSettle();
    expect(store.listenerNotifications, lessThanOrEqualTo(1));
  });

  testWidgets('very long press avatar clears category limit', (tester) async {
    final repository = _SavingDashboardTestRepository();
    final store = TransactionStore(
      repository,
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.monthly,
        year: 2026,
        month: 7,
      ),
    );
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final avatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    final gesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 1350));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.savedLimitPayloads, isNotEmpty);
    expect(repository.savedLimitPayloads.last['targetType'], 'category');
    expect(repository.savedLimitPayloads.last['targetId'], 1);
    expect(repository.savedLimitPayloads.last['hasLimit'], isFalse);
    expect(repository.savedLimitPayloads.last['limitAmount'], 0);
  });

  testWidgets('stage 2 follows selected avatar and ignores horizontal swipe', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-prev-page-button')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-next-page-button')),
      findsNothing,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey('spendee-test-budget-vendor-focus-title'),
            ),
          )
          .data,
      'Élelmiszer bolt',
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsNothing,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-budget-vendor-row-0')),
        matching: find.text('Élelmiszer bolt'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-budget-vendor-row-1')),
        matching: find.text('Piac'),
      ),
      findsOneWidget,
    );
    expect(find.text('84% · 63 240 Ft'), findsOneWidget);
    expect(find.text('16% · 12 000 Ft'), findsOneWidget);
    expect(
      tester
          .widget<Text>(
            find.byKey(
              const ValueKey('spendee-test-budget-vendor-focus-title'),
            ),
          )
          .data,
      'Élelmiszer bolt',
    );

    await tester.tapAt(
      tester
          .getRect(find.byKey(const ValueKey('spendee-test-budget-pie-donut')))
          .center,
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(140, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );
  });

  testWidgets('stage 2 hides chart shell when selected data is empty', (
    tester,
  ) async {
    final store = TransactionStore(
      _DashboardTestRepository(transactions: [_record(2, 2, -31700, 'Busz')]),
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-empty-hidden')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );
  });

  testWidgets('dashboard omits hardcoded header background glow', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    expect(
      find.byKey(const ValueKey('spendee-test-dashboard')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-card')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-header-outer-glow')),
      findsNothing,
    );
    final headerGlass = tester.widget<SpendeeHeaderGlassSurface>(
      find.byType(SpendeeHeaderGlassSurface),
    );
    _expectNoPinkOrPurpleShadows(headerGlass.spec.glass.cardShadows);
  });

  testWidgets('header glass choices do not keep pink or purple card glow', (
    tester,
  ) async {
    await _pumpDashboard(tester);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-surface-liquid-glass')),
    );
    await tester.pumpAndSettle();

    final liquidFrameDecorations = tester
        .widgetList<DecoratedBox>(
          find.descendant(
            of: find.byKey(const ValueKey('spendee-test-header-card')),
            matching: find.byType(DecoratedBox),
          ),
        )
        .map((widget) => widget.decoration)
        .whereType<BoxDecoration>()
        .where((decoration) => decoration.boxShadow?.isNotEmpty ?? false);
    for (final decoration in liquidFrameDecorations) {
      _expectNoPinkOrPurpleShadows(decoration.boxShadow!);
    }
  });

  testWidgets(
    'D1A logo tap opens slide-up editor with palette and custom slots',
    (tester) async {
      await _pumpDashboard(tester);

      expect(
        tester.getRect(find.byKey(const ValueKey('spendee-test-brand-lockup'))),
        const Rect.fromLTWH(0, 33.3, 412, 118),
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('spendee-test-brand-logo'))),
        const Rect.fromLTWH(30, 39.3, 47.88, 47.88),
      );

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-brand-logo-tap')),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-logo-editor-sheet')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-editor-preview')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-slot-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-slot-20')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-selected-D1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-palette-app-gray900')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-custom-slot-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-custom-slot-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-component-top')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-component-bottom')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-logo-component-path2')),
        findsNothing,
      );
    },
  );

  testWidgets('logo editor sends custom endpoint and boundary to an arc SVG', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await tester.tap(find.byKey(const ValueKey('spendee-test-brand-logo-tap')));
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-palette-slot-7')),
    );
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-custom-left-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-palette-slot-20')),
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-custom-right-1')),
    );
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-custom-swatch-1')),
    );
    final slider = find.byKey(
      const ValueKey('spendee-test-logo-custom-boundary-1'),
    );
    await tester.drag(slider, const Offset(-70, 0));
    await tester.pump();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-logo-component-top')),
    );
    await tester.pump();

    final preview = tester.widget<FluviLogo>(
      find.byKey(const ValueKey('spendee-test-fluvi-logo-preview')),
    );
    final fill = preview.fills[FluviLogoArc.top]!;
    expect(fill.left, const Color(0xFF35C76E));
    expect(fill.right, const Color(0xFFFB56A8));
    expect(fill.boundary, isNot(50));

    final svg = FluviLogoSvg.document(preview.fills);
    expect(svg, contains('id="fluvi-arc-top"'));
    expect(svg, contains('id="fluvi-arc-bottom"'));
    expect(svg, contains('offset="${_svgPercent(fill.boundary)}%"'));
    expect(RegExp(r'<path id="fluvi-arc-').allMatches(svg), hasLength(2));
  });
}

String _svgPercent(double value) {
  final fixed = value.toStringAsFixed(2);
  return fixed.replaceFirst(RegExp(r'\\.?0+$'), '');
}

void _expectNoPinkOrPurpleShadows(List<BoxShadow> shadows) {
  for (final shadow in shadows) {
    final color = shadow.color;
    final alpha = color.a;
    final redDominant = color.r > color.g + .12;
    final blueDominant = color.b > color.g + .12;
    final saturatedAgainstGreen = redDominant || blueDominant;
    expect(
      saturatedAgainstGreen && alpha > .02,
      isFalse,
      reason:
          'Header shadow must not keep pink/purple tint: '
          '$color with alpha $alpha.',
    );
  }
}

Future<_SampledPixel> _sampleHeaderBoundaryPixel(
  WidgetTester tester,
  Offset globalOffset,
) async {
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('spendee-test-header-golden-boundary')),
  );
  final local = globalOffset - boundary.localToGlobal(Offset.zero);
  return (await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.rawRgba);
    image.dispose();
    final data = bytes!;
    final x = local.dx.round().clamp(0, image.width - 1);
    final y = local.dy.round().clamp(0, image.height - 1);
    final offset = (y * image.width + x) * 4;
    return _SampledPixel(
      alpha: data.getUint8(offset + 3),
      red: data.getUint8(offset),
      green: data.getUint8(offset + 1),
      blue: data.getUint8(offset + 2),
    );
  }))!;
}

class _SampledPixel {
  const _SampledPixel({
    required this.alpha,
    required this.red,
    required this.green,
    required this.blue,
  });

  final int alpha;
  final int red;
  final int green;
  final int blue;
}

bool _isPinkPurpleGlowColor(Color color) {
  final hsv = HSVColor.fromColor(color);
  return color.a > 0 &&
      hsv.saturation > .25 &&
      ((hsv.hue >= 285 && hsv.hue <= 340) ||
          (color.r > .75 && color.g < .45 && color.b > .45));
}

Future<TransactionStore> _pumpDashboard(
  WidgetTester tester, {
  ValueChanged<TransactionRecord>? onEditTransaction,
  Future<bool> Function(TransactionRecord record)? onDeleteTransactionRequested,
  TransactionRepositoryContract? repository,
}) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  final store = TransactionStore(
    repository ?? _DashboardTestRepository(),
    clock: () => DateTime(2026, 7, 17),
  );
  await store.start();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return SpendeeTestDashboard(
              store: store,
              expenseTheme: ExpenseTheme.fromSettings(
                AppThemeSettings.defaults(),
              ),
              onPickSummaryMonth: () {},
              onEditTransaction: onEditTransaction ?? (_) {},
              onDeleteTransactionRequested:
                  onDeleteTransactionRequested ?? (_) async => true,
              onVendorSheetRequested: () {},
              logBottomPadding: 0,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
  return store;
}

Future<void> _pumpDashboardWithStore(
  WidgetTester tester,
  TransactionStore store,
) async {
  tester.view.physicalSize = const Size(412, 892);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: store,
          builder: (context, _) {
            return SpendeeTestDashboard(
              store: store,
              expenseTheme: ExpenseTheme.fromSettings(
                AppThemeSettings.defaults(),
              ),
              onPickSummaryMonth: () {},
              onEditTransaction: (_) {},
              onDeleteTransactionRequested: (_) async => true,
              onVendorSheetRequested: () {},
              logBottomPadding: 0,
            );
          },
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Future<void> _dragHeaderBy(WidgetTester tester, double dy) async {
  final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
  final gesture = await tester.startGesture(tester.getCenter(handle));
  await gesture.moveBy(Offset(0, dy));
  await tester.pump();
  await gesture.up();
}

Future<void> _switchToMindBackground(WidgetTester tester) async {
  await _tapHeaderMenuItem(
    tester,
    const ValueKey('spendee-test-header-background-mind'),
  );
}

Future<void> _tapHeaderMenuItem(WidgetTester tester, Key key) async {
  await tester.tap(
    find.byKey(const ValueKey('spendee-test-header-menu-button')),
  );
  await tester.pumpAndSettle();
  final item = find.byKey(key);
  await tester.ensureVisible(item);
  await tester.pumpAndSettle();
  await tester.tap(item);
  await tester.pumpAndSettle();
}

void _expectOnlyBackgroundSurface(String keyBase) {
  expect(find.byKey(ValueKey('$keyBase-background')), findsOneWidget);
  expect(find.byKey(ValueKey('$keyBase-glossy')), findsNothing);
  expect(find.byKey(ValueKey('$keyBase-html-c2-glass')), findsNothing);
  expect(find.byKey(ValueKey('$keyBase-liquid-glass')), findsNothing);
  expect(find.byKey(ValueKey('$keyBase-acrylic')), findsNothing);
}

bool _isWhiteGlassContainerDecoration(Widget widget) {
  if (widget is! DecoratedBox) return false;
  final decoration = widget.decoration;
  if (decoration is! BoxDecoration) return false;
  final color = decoration.color;
  final hasWhiteColor = color != null && _isTranslucentWhite(color);
  final hasWhiteShadow =
      decoration.boxShadow?.any(
        (shadow) => _isTranslucentWhite(shadow.color),
      ) ??
      false;
  final gradient = decoration.gradient;
  final hasWhiteGradient =
      gradient is LinearGradient && gradient.colors.any(_isTranslucentWhite);
  return hasWhiteColor || hasWhiteShadow || hasWhiteGradient;
}

bool _isTranslucentWhite(Color color) {
  return color.a > 0 && color.r > .85 && color.g > .85 && color.b > .85;
}

Finder _avatar3dEffectFinders() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('spendee-test-avatar-3d-effect-');
  });
}

Finder _avatarLegacyProgressFinders() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('spendee-test-avatar-progress-');
  });
}

int _stackChildIndexContainingKey(Stack stack, Key key) {
  return stack.children.indexWhere((child) => _widgetContainsKey(child, key));
}

Stack _stackContainingKeys(WidgetTester tester, Finder root, List<Key> keys) {
  return tester
      .widgetList<Stack>(
        find.descendant(of: root, matching: find.byType(Stack)),
      )
      .firstWhere(
        (stack) =>
            keys.every((key) => _stackChildIndexContainingKey(stack, key) >= 0),
      );
}

bool _widgetContainsKey(Widget widget, Key key) {
  if (widget.key == key) return true;
  if (widget is Stack) {
    return widget.children.any((child) => _widgetContainsKey(child, key));
  }
  if (widget is MultiChildRenderObjectWidget) {
    return widget.children.any((child) => _widgetContainsKey(child, key));
  }
  if (widget is ProxyWidget) {
    return _widgetContainsKey(widget.child, key);
  }
  if (widget is SingleChildRenderObjectWidget) {
    final child = widget.child;
    return child != null && _widgetContainsKey(child, key);
  }
  return false;
}

void _expectRectsClose(Rect actual, Rect expected, {double epsilon = .75}) {
  expect(actual.left, closeTo(expected.left, epsilon));
  expect(actual.top, closeTo(expected.top, epsilon));
  expect(actual.width, closeTo(expected.width, epsilon));
  expect(actual.height, closeTo(expected.height, epsilon));
}

CustomPaint _mindCustomPaint(WidgetTester tester, Key chartKey, Key paintKey) {
  return tester.widget<CustomPaint>(
    find.descendant(of: find.byKey(chartKey), matching: find.byKey(paintKey)),
  );
}

List<SpendeeMindStatsFrameBuildEvent> _captureMindStatsBuilds() {
  final builds = <SpendeeMindStatsFrameBuildEvent>[];
  SpendeeMindStatsFrame.debugBuildObserver = builds.add;
  addTearDown(() => SpendeeMindStatsFrame.debugBuildObserver = null);
  return builds;
}

List<String> _seriesPointSignature(Iterable<dynamic> points) {
  return [
    for (final point in points)
      '${point.index}|${point.value.toStringAsFixed(4)}|${point.position}',
  ];
}

List<String> _helperBarSignature(Iterable<dynamic> bars) {
  return [
    for (final bar in bars)
      '${bar.index}|${bar.rawValue.toStringAsFixed(2)}|'
          '${bar.value.toStringAsFixed(4)}|${bar.position}|${bar.colorHex}',
  ];
}

class _MindDashboardStatsRepository extends _DashboardTestRepository {
  _MindDashboardStatsRepository()
    : super(
        categories: [
          _category(1, 'Élelmiszer', 7, 0),
          _category(2, 'Közlekedés', 3, 1),
          _category(101, 'Fizetés', 12, 2, type: 'bevétel'),
        ],
        transactions: [
          _record(1, 1, -11000, 'Piac', date: '2026.01.03'),
          _record(2, 2, -7200, 'Busz', date: '2026.01.11'),
          _record(3, 1, -31000, 'Piac', date: '2026.02.04'),
          _record(4, 2, -9600, 'Metro', date: '2026.03.12'),
          _record(5, 101, 280000, 'Munkahely', date: '2026.01.01'),
          _record(6, 101, 310000, 'Munkahely', date: '2026.02.01'),
          _record(7, 101, 500000, 'Munkahely', date: '2026.03.01'),
        ],
      );
}

class _CountingTransactionStore extends TransactionStore {
  _CountingTransactionStore(super.repository)
    : super(clock: () => DateTime(2026, 7, 17));

  var fastInfoMetricsAccesses = 0;
  var visibleTransactionsAccesses = 0;
  var visibleDisplayLogEntriesAccesses = 0;
  var visibleGhostTransactionsAccesses = 0;
  var categoryFilterChanges = 0;
  var listenerNotifications = 0;

  void resetAccessCounts() {
    fastInfoMetricsAccesses = 0;
    visibleTransactionsAccesses = 0;
    visibleDisplayLogEntriesAccesses = 0;
    visibleGhostTransactionsAccesses = 0;
    categoryFilterChanges = 0;
    listenerNotifications = 0;
  }

  @override
  Map<String, FastInfoMetricResult> get fastInfoMetrics {
    fastInfoMetricsAccesses += 1;
    return super.fastInfoMetrics;
  }

  @override
  List<TransactionRecord> get visibleTransactions {
    visibleTransactionsAccesses += 1;
    return super.visibleTransactions;
  }

  @override
  List<TransactionLogEntry> get visibleDisplayLogEntries {
    visibleDisplayLogEntriesAccesses += 1;
    return super.visibleDisplayLogEntries;
  }

  @override
  List<RecurringGhostRecord> get visibleGhostTransactions {
    visibleGhostTransactionsAccesses += 1;
    return super.visibleGhostTransactions;
  }

  @override
  void setCategoryFilters({
    required TransactionType type,
    required Set<int> categoryIds,
  }) {
    categoryFilterChanges += 1;
    super.setCategoryFilters(type: type, categoryIds: categoryIds);
  }

  @override
  void clearCategoryFilter() {
    categoryFilterChanges += 1;
    super.clearCategoryFilter();
  }

  @override
  void notifyListeners() {
    listenerNotifications += 1;
    super.notifyListeners();
  }
}

class _SavingDashboardTestRepository extends _DashboardTestRepository {
  final savedLimitPayloads = <Map<String, Object?>>[];
  var _nextLimitId = 100;

  @override
  Future<CategoryLimit> upsertCategoryLimit(
    Map<String, Object?> payload,
  ) async {
    savedLimitPayloads.add(Map<String, Object?>.unmodifiable(payload));
    final targetType = LimitTargetTypeX.fromAny(payload['targetType']);
    final targetId = _payloadInt(payload['targetId']);
    final transactionType = payload['transactionType']?.toString() ?? 'expense';
    final window = LimitWindowX.fromAny(payload['window']);
    final periodKey = payload['periodKey']?.toString() ?? 'all';
    final hasLimit = _payloadBool(payload['hasLimit']);
    final amount = hasLimit ? _payloadDouble(payload['limitAmount']) : 0.0;
    final alertActive = hasLimit && _payloadBool(payload['alertActive']);
    final existingIndex = limits.indexWhere(
      (limit) =>
          limit.targetType == targetType &&
          limit.targetId == targetId &&
          limit.transactionType == transactionType &&
          limit.window == window &&
          limit.periodKey == periodKey,
    );
    final saved = CategoryLimit(
      id: existingIndex >= 0 ? limits[existingIndex].id : _nextLimitId++,
      targetType: targetType,
      targetId: targetId,
      transactionType: transactionType,
      window: window,
      periodKey: periodKey,
      hasLimit: hasLimit,
      limitAmount: amount,
      alertActive: alertActive,
      createdAt: 0,
      updatedAt: savedLimitPayloads.length,
    );
    if (existingIndex >= 0) {
      limits[existingIndex] = saved;
    } else {
      limits.add(saved);
    }
    return saved;
  }
}

int _payloadInt(Object? value) =>
    value is int ? value : int.parse(value.toString());

double _payloadDouble(Object? value) =>
    value is num ? value.toDouble() : double.parse(value.toString());

bool _payloadBool(Object? value) =>
    value == true || value == 1 || value?.toString() == 'true';

class _DashboardTestRepository implements TransactionRepositoryContract {
  _DashboardTestRepository({
    List<TransactionCategory>? categories,
    List<TransactionRecord>? transactions,
  }) : categories =
           categories ??
           [
             _category(1, 'Élelmiszer', 7, 0),
             _category(2, 'Közlekedés', 3, 1),
             _category(3, 'Lakás', 19, 2),
             _category(4, 'Gyorsétterem', 1, 3),
             _category(5, 'Rezsi', 18, 4),
           ],
       transactions =
           transactions ??
           [
             _record(1, 1, -63240, 'Élelmiszer bolt'),
             _record(2, 2, -31700, 'Busz'),
             _record(3, 3, -54000, 'Albérlet'),
             _record(4, 4, -28400, 'Burger'),
             _record(5, 5, -22600, 'Villany'),
             _record(6, 1, -12000, 'Piac'),
           ];

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;

  late final limits = <CategoryLimit>[
    _limit(1, LimitTargetType.overview, 0, 200000),
    _limit(2, LimitTargetType.category, 1, 80000),
    _limit(3, LimitTargetType.category, 2, 40000),
    _limit(4, LimitTargetType.category, 3, 30000),
    _limit(5, LimitTargetType.category, 4, 10000),
    _limit(6, LimitTargetType.category, 5, 10000),
  ];

  @override
  Future<TransactionBootstrap> loadBootstrap() async {
    return TransactionBootstrap(
      categories: categories,
      transactions: transactions,
      limits: limits,
    );
  }

  @override
  Future<TransactionPage> listTransactionPage(
    TransactionPageQuery query,
  ) async {
    final rows = transactions.where((transaction) {
      if (query.type != null && transaction.type != query.type) return false;
      if (query.categoryId != null &&
          transaction.transactionCategoryID != query.categoryId) {
        return false;
      }
      return true;
    }).toList();
    return TransactionPage(
      transactions: rows,
      totalCount: rows.length,
      limit: query.limit,
      offset: query.offset,
    );
  }

  @override
  Future<List<TransactionRecord>> transactionsForNotificationEvents(
    Iterable<int> eventIds,
  ) async {
    return const <TransactionRecord>[];
  }

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionRecord> updateTransaction(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteTransaction(int id) async => true;

  @override
  Future<int> renameTransactionsByMerchant(
    String originalMerchant,
    String userAssignedName,
  ) async {
    return 0;
  }

  @override
  Future<int> resetTransactionNamesByMerchant(String originalMerchant) async =>
      0;

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) async {
    return const <RecurringGhostRecord>[];
  }

  @override
  Future<List<RecurringRule>> listRecurringRules() async {
    return const <RecurringRule>[];
  }

  @override
  Future<RecurringRule> addRecurringRule(RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> updateRecurringRule(int id, RecurringRuleDraft draft) {
    throw UnimplementedError();
  }

  @override
  Future<RecurringRule> toggleRecurringRule(int id, bool isActive) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteRecurringRule(int id) async => false;

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) {
    throw UnimplementedError();
  }

  @override
  Future<TransactionCategory> updateCategory(
    int id,
    Map<String, Object?> payload,
  ) {
    throw UnimplementedError();
  }

  @override
  Future<bool> deleteCategory(int id) async => true;

  @override
  Future<Map<int, int>> categoryCounts() async {
    return {
      for (final category in categories) category.transactionCategoryID: 1,
    };
  }

  @override
  Future<List<CategoryLimit>> listCategoryLimits({
    String? transactionType,
    String? window,
    String? periodKey,
  }) async {
    return limits;
  }

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) {
    throw UnimplementedError();
  }
}

CategoryLimit _limit(
  int id,
  LimitTargetType targetType,
  int targetId,
  double amount,
) {
  return CategoryLimit(
    id: id,
    targetType: targetType,
    targetId: targetId,
    transactionType: 'expense',
    window: LimitWindow.monthly,
    periodKey: '2026-07',
    hasLimit: true,
    limitAmount: amount,
    alertActive: true,
    createdAt: 0,
    updatedAt: 0,
  );
}

TransactionCategory _category(
  int id,
  String name,
  int colorSlot,
  int iconSlot, {
  String type = 'kiadás',
}) {
  return TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': name,
    'type': type,
    'colorSlot': colorSlot,
    'iconSlot': iconSlot,
    'backgroundColor': null,
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  });
}

TransactionRecord _record(
  int id,
  int categoryId,
  double amount,
  String merchant, {
  String date = '2026.07.17',
}) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': date,
    'time': '10:00',
    'merchant': merchant,
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}
