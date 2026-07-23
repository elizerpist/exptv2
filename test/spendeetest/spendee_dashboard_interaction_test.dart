import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:exptv2/core/theme/category_color_manager.dart' as core_colors;
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
      findsNothing,
      reason: 'The separate top decorative arc has been removed.',
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-body-highlight-category-1'),
      ),
      findsOneWidget,
      reason: 'The configurable body gloss is the only avatar highlight.',
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
        find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
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
    'header background opacity is adjustable without fading Mind content',
    (tester) async {
      await _pumpDashboard(tester);
      await _switchToMindBackground(tester);

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-header-menu-button')),
      );
      await tester.pumpAndSettle();
      final sliderFinder = find.byKey(
        const ValueKey('spendee-test-header-background-opacity-slider'),
      );
      await tester.ensureVisible(sliderFinder);
      await tester.pumpAndSettle();
      final slider = tester.widget<Slider>(sliderFinder);
      expect(slider.min, .1);
      expect(slider.max, 1);

      await tester.drag(sliderFinder, const Offset(-90, 0));
      await tester.pumpAndSettle();
      final backgroundOpacity = tester.widget<Opacity>(
        find.byKey(
          const ValueKey('spendee-test-header-background-opacity-layer'),
        ),
      );
      expect(backgroundOpacity.opacity, inInclusiveRange(.1, .99));
      expect(
        find.byKey(const ValueKey('spendee-test-mind-header-score-value')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mind SUM container choices wrap the Activity Field and heatmap independently',
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
        find.byKey(
          const ValueKey('spendee-test-mind-activity-field-liquid-glass'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-stage2-acrylic')),
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

      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-activity-field-background'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-stage2-background')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mind background surface removes all inner component containers',
    (tester) async {
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
        const ValueKey('spendee-test-mind-activity-field'),
      );
      final stage2 = find.byKey(
        const ValueKey('spendee-test-mind-yearly-heatmap'),
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

  testWidgets('mind Activity Field follows the active type with live volume', (
    tester,
  ) async {
    final store = await _pumpDashboard(
      tester,
      repository: _MindDashboardStatsRepository(),
    );
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

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-expense-type-pill')),
    );
    await tester.pumpAndSettle();

    final expenseFrame = SpendeeMindStatsFrame.fromStore(store);
    final expenseVolumePaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('spendee-test-mind-activity-field-paint')),
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

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-income-type-pill')),
    );
    await tester.pumpAndSettle();

    final incomeFrame = SpendeeMindStatsFrame.fromStore(store);
    final incomeVolumePaint = tester.widget<CustomPaint>(
      find.byKey(const ValueKey('spendee-test-mind-activity-field-paint')),
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

  testWidgets('mind score chart preserves Stage0 and fills later stages', (
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
    final stage0HeaderRect = tester.getRect(header);
    expect(stage0Rect.top - stage0HeaderRect.top, closeTo(43, .1));
    expect(stage0Rect.height, closeTo(47, .1));

    await _dragHeaderBy(tester, 134);
    await tester.pump(const Duration(milliseconds: 500));

    final stage1HeaderRect = tester.getRect(header);
    final stage1Rect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-mind-score-chart')),
    );
    expect(stage1Rect.top - stage1HeaderRect.top, closeTo(14, .1));
    expect(stage1HeaderRect.bottom - stage1Rect.bottom, closeTo(14, .1));
    expect(stage1Rect.height, greaterThan(stage0Rect.height));

    await _dragHeaderBy(tester, 272);
    await tester.pump(const Duration(milliseconds: 500));

    final stage2HeaderRect = tester.getRect(header);
    final stage2Rect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-mind-score-chart')),
    );
    expect(stage2Rect.top - stage2HeaderRect.top, closeTo(14, .1));
    expect(stage2HeaderRect.bottom - stage2Rect.bottom, closeTo(14, .1));
    expect(stage2Rect.height, greaterThan(stage1Rect.height));
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
      find.byKey(const ValueKey('spendee-test-mind-activity-field')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-mind-time-rail-carousel')),
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

  testWidgets(
    'Mind SUM places a compact live time rail below Search and keeps Stage1 to Activity Field',
    (tester) async {
      await _pumpDashboard(
        tester,
        repository: _MindSumDashboardStatsRepository(),
      );
      await _switchToMindBackground(tester);

      final search = find.byKey(const ValueKey('spendee-test-search-pill'));
      final refinement = find.byKey(
        const ValueKey('spendee-test-mind-time-rail-control'),
      );
      final rail = find.byKey(
        const ValueKey('spendee-test-mind-time-rail-carousel'),
      );
      expect(refinement, findsOneWidget);
      expect(rail, findsOneWidget);
      expect(
        tester.getRect(refinement).top,
        greaterThan(tester.getRect(search).bottom),
      );

      final selected = find.byKey(
        const ValueKey('spendee-test-mind-sum-year-card-2026-selected'),
      );
      final outer = find.byKey(
        const ValueKey('spendee-test-mind-sum-year-card-2024'),
      );
      expect(selected, findsOneWidget);
      expect(outer, findsOneWidget);
      expect(
        tester.getRect(selected).width,
        greaterThan(tester.getRect(outer).width),
      );
      expect(tester.getRect(selected).width, closeTo(53, .1));
      expect(tester.getRect(outer).width, closeTo(38, .1));

      final liveBars = tester.widget<CustomPaint>(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-volume-2026')),
      );
      final monthlyTotals =
          (liveBars.painter as dynamic).monthlyTotals as Map<int, double>;
      expect(monthlyTotals, isNotEmpty);
      expect(monthlyTotals.length, lessThanOrEqualTo(12));

      await tester.tap(
        find.byKey(
          const ValueKey('spendee-test-mind-time-rail-collapse-toggle'),
        ),
      );
      await tester.pumpAndSettle();
      expect(rail, findsNothing);
      expect(
        find.byKey(const ValueKey('spendee-test-mind-time-rail-expand-toggle')),
        findsOneWidget,
      );
      await tester.tap(
        find.byKey(const ValueKey('spendee-test-mind-time-rail-expand-toggle')),
      );
      await tester.pumpAndSettle();
      expect(rail, findsOneWidget);

      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-mind-activity-field')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-stage1-boxed-graphs')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-activity-field-paint')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mind SUM renders a query-scoped year rail and selected-year month heatmap',
    (tester) async {
      final store = await _pumpDashboard(
        tester,
        repository: _MindSumDashboardStatsRepository(),
      );
      await _switchToMindBackground(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-carousel')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-year-card-2026-selected'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-card-2025')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-card-2022')),
        findsOneWidget,
      );
      final initialRailRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-carousel')),
      );
      final selectedYearRect = tester.getRect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-year-card-2026-selected'),
        ),
      );
      final leftYearRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-card-2022')),
      );
      final rightYearRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-card-2025')),
      );
      expect(selectedYearRect.width, greaterThan(leftYearRect.width));
      expect(selectedYearRect.width, greaterThan(rightYearRect.width));
      expect(leftYearRect.center.dx, lessThan(selectedYearRect.center.dx));
      expect(rightYearRect.center.dx, greaterThan(selectedYearRect.center.dx));
      expect(leftYearRect.left, greaterThanOrEqualTo(initialRailRect.left));
      expect(rightYearRect.right, lessThanOrEqualTo(initialRailRect.right));

      final yearRail = find.byKey(
        const ValueKey('spendee-test-mind-sum-year-carousel-gesture'),
      );
      final gesture = await tester.startGesture(tester.getCenter(yearRail));
      await gesture.moveBy(const Offset(-24, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-64, 0));
      await tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-year-card-2025-selected'),
        ),
        findsOneWidget,
      );
      expect(store.summaryWindow, SummaryWindow.allTime);

      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-selected-year-heatmap'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-stage2-scroll')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-day-2025-12-31')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-total-2025-1')),
        findsOneWidget,
      );
      final januaryRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-1')),
      );
      final februaryRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-2')),
      );
      final marchRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-3')),
      );
      final aprilRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-4')),
      );
      final mayRect = tester.getRect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-5')),
      );
      expect(februaryRect.left, greaterThan(januaryRect.left));
      expect(marchRect.left, greaterThan(februaryRect.left));
      expect(aprilRect.left, greaterThan(marchRect.left));
      expect(februaryRect.width, closeTo(januaryRect.width, .1));
      expect(marchRect.width, closeTo(januaryRect.width, .1));
      expect(aprilRect.top, closeTo(januaryRect.top, .1));
      expect(mayRect.top, greaterThan(januaryRect.top));

      await tester.tap(
        find.byKey(
          const ValueKey('spendee-test-mind-header-background-tap-target'),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-layout-menu')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-center-size-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-inner-size-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-inner-offset-slider')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-volume-bars-toggle')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-month-card-opacity-slider'),
        ),
        findsOneWidget,
      );

      final yearCardSurfacePicker = find.byKey(
        const ValueKey('spendee-test-mind-sum-year-card-surface-picker'),
      );
      await tester.ensureVisible(yearCardSurfacePicker);
      await tester.pumpAndSettle();
      await tester.tap(yearCardSurfacePicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Feher').last);
      await tester.pumpAndSettle();
      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-year-card-2025-white'),
        ),
        findsOneWidget,
      );

      final monthOpacitySlider = find.byKey(
        const ValueKey('spendee-test-mind-sum-month-card-opacity-slider'),
      );
      await tester.ensureVisible(monthOpacitySlider);
      await tester.pumpAndSettle();
      await tester.drag(monthOpacitySlider, const Offset(-72, 0));
      await tester.pump();
      final monthOpacity = tester.widget<Opacity>(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-month-2025-1-opacity'),
        ),
      );
      expect(monthOpacity.opacity, lessThan(.86));

      final volumeToggle = find.byKey(
        const ValueKey('spendee-test-mind-sum-volume-bars-toggle'),
      );
      await tester.ensureVisible(volumeToggle);
      await tester.pumpAndSettle();
      await tester.tap(volumeToggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-year-volume-2025')),
        findsNothing,
      );

      final monthCardToggle = find.byKey(
        const ValueKey('spendee-test-mind-sum-month-card-toggle'),
      );
      await tester.ensureVisible(monthCardToggle);
      await tester.pumpAndSettle();
      await tester.tap(monthCardToggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-1-glossy')),
        findsNothing,
      );

      final stage2OuterToggle = find.byKey(
        const ValueKey('spendee-test-mind-sum-stage2-outer-toggle'),
      );
      await tester.ensureVisible(stage2OuterToggle);
      await tester.pumpAndSettle();
      await tester.tap(stage2OuterToggle);
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-stage2-background')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mind SUM background opacity and surfaces stay isolated from YEAR mode',
    (tester) async {
      final store = await _pumpDashboard(
        tester,
        repository: _MindSumDashboardStatsRepository(),
      );
      await _switchToMindBackground(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('spendee-test-mind-header-background-tap-target'),
        ),
      );
      await tester.pumpAndSettle();

      final railSurfacePicker = find.byKey(
        const ValueKey('spendee-test-mind-sum-rail-surface-picker'),
      );
      await tester.ensureVisible(railSurfacePicker);
      await tester.tap(railSurfacePicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Nincs hatter').last);
      await tester.pumpAndSettle();

      final railOpacitySlider = find.byKey(
        const ValueKey('spendee-test-mind-sum-rail-opacity-slider'),
      );
      await tester.ensureVisible(railOpacitySlider);
      await tester.drag(railOpacitySlider, const Offset(-90, 0));
      await tester.pumpAndSettle();
      final railOpacity = tester.widget<Opacity>(
        find.byKey(const ValueKey('spendee-test-mind-sum-stage1-opacity')),
      );
      expect(railOpacity.opacity, lessThan(.9));

      final stage2SurfacePicker = find.byKey(
        const ValueKey('spendee-test-mind-sum-stage2-surface-picker'),
      );
      await tester.ensureVisible(stage2SurfacePicker);
      await tester.tap(stage2SurfacePicker);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Feher').last);
      await tester.pumpAndSettle();

      await tester.tapAt(const Offset(4, 4));
      await tester.pumpAndSettle();
      store.commitStatsViewMutation(
        await store.prepareStatsViewMutation(
          summaryWindow: SummaryWindow.yearly,
          year: 2026,
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-mind-activity-field-glossy')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-month-1-glossy')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'mind SUM keeps the open Stage2 heatmap on its published year during rail drag',
    (tester) async {
      final store = await _pumpDashboard(
        tester,
        repository: _MindSumDashboardStatsRepository(),
      );
      await _switchToMindBackground(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2026-1')),
        findsOneWidget,
      );

      final rail = find.byKey(
        const ValueKey('spendee-test-mind-sum-year-carousel-gesture'),
      );
      await tester.ensureVisible(rail);
      await tester.pumpAndSettle();
      final gesture = await tester.startGesture(tester.getCenter(rail));
      await gesture.moveBy(const Offset(-24, 0));
      await tester.pump();
      await gesture.moveBy(const Offset(-64, 0));
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey('spendee-test-mind-sum-year-card-2025-selected'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2026-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-1')),
        findsNothing,
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-month-2025-1')),
        findsOneWidget,
      );
      expect(store.summaryWindow, SummaryWindow.allTime);
    },
  );

  testWidgets('mind SUM month grids use a cell-sized aspect ratio', (
    tester,
  ) async {
    await _pumpDashboard(
      tester,
      repository: _MindSumDashboardStatsRepository(),
    );
    await _switchToMindBackground(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    final january = find.byKey(
      const ValueKey('spendee-test-mind-sum-month-2026-1'),
    );
    final grid = tester.widget<GridView>(
      find.descendant(of: january, matching: find.byType(GridView)),
    );
    final delegate =
        grid.gridDelegate as SliverGridDelegateWithFixedCrossAxisCount;
    expect(delegate.childAspectRatio, lessThan(1));
  });

  testWidgets(
    'mind SUM layout menu matches the avatar menu height and scrolls',
    (tester) async {
      await _pumpDashboard(
        tester,
        repository: _MindSumDashboardStatsRepository(),
      );
      await _switchToMindBackground(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      await tester.tap(
        find.byKey(
          const ValueKey('spendee-test-mind-header-background-tap-target'),
        ),
      );
      await tester.pumpAndSettle();

      final menu = tester.widget<Container>(
        find.byKey(const ValueKey('spendee-test-mind-sum-layout-menu')),
      );
      expect(menu.constraints?.maxHeight, 332);
      expect(
        find.byKey(const ValueKey('spendee-test-mind-sum-layout-menu-scroll')),
        findsOneWidget,
      );
    },
  );

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

  testWidgets(
    'summary pill mirrors old vertical drag feedback and logs a tick',
    (tester) async {
      final store = await _pumpDashboard(tester);
      store.commitStatsViewMutation(
        await store.prepareStatsViewMutation(
          summaryWindow: SummaryWindow.monthly,
          year: 2026,
          month: 7,
        ),
      );
      await tester.pump();
      DebugConsole.clear();

      final pill = find.byKey(const ValueKey('spendee-test-summary-pill'));
      final gesture = await tester.startGesture(tester.getCenter(pill));
      await gesture.moveBy(const Offset(0, -18));
      await tester.pump(const Duration(milliseconds: 16));
      await gesture.moveBy(const Offset(0, -46));
      await tester.pump();

      final draggedPill = tester.widget<AnimatedContainer>(pill);
      expect(draggedPill.transform?.storage[13] ?? 0, lessThan(-24));

      await gesture.up();
      await tester.pump(const Duration(milliseconds: 400));

      expect(store.summaryWindow, SummaryWindow.yearly);
      final settledPill = tester.widget<AnimatedContainer>(pill);
      expect(settledPill.transform?.storage[12] ?? 0, 0);
      expect(settledPill.transform?.storage[13] ?? 0, 0);
      expect(
        DebugConsole.entries,
        contains(
          predicate<String>(
            (line) =>
                line.contains('[Perf] SpendeeTest summary_tick') &&
                line.contains('axis=vertical'),
          ),
        ),
      );
    },
  );

  testWidgets('budget and mind container softness sliders are scoped', (
    tester,
  ) async {
    final store = await _pumpDashboard(tester);

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

    store.commitStatsViewMutation(
      await store.prepareStatsViewMutation(
        summaryWindow: SummaryWindow.yearly,
        year: 2026,
      ),
    );
    await tester.pump();

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
      const ValueKey('spendee-test-mind-activity-field-liquid-glass'),
    );
    final firstMindMonth = SpendeeMindStatsFrame.fromStore(
      store,
    ).activeFrame.yearData.graphMonths.first.month;
    final mindStage2 = find.byKey(
      ValueKey('spendee-test-mind-month-$firstMindMonth-liquid-glass'),
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

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
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
    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();
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
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
      reason: 'Stage 2 chart paging loops vendor -> category on forward swipe.',
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

  testWidgets('live carousel ticks do not pulse the new center', (
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
    expect(selected.pulsing, isFalse);

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

  testWidgets('budget carousel publishes store filter only after idle', (
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
    final firstGesture = await tester.startGesture(tester.getCenter(carousel));
    await firstGesture.moveBy(const Offset(-70, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await firstGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(
      store.categoryFilterChanges,
      0,
      reason:
          'Release animation must not immediately start store filtering/list '
          'rebuilds while the user may continue swiping.',
    );

    final secondGesture = await tester.startGesture(tester.getCenter(carousel));
    await secondGesture.moveBy(const Offset(-70, 0));
    await tester.pump(const Duration(milliseconds: 16));
    await secondGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pump();

    expect(
      store.categoryFilterChanges,
      0,
      reason:
          'A newer carousel gesture must cancel the previous pending filter '
          'publish during rapid back-and-forth swipes.',
    );

    await tester.pump(const Duration(milliseconds: 420));
    await tester.pump();
    expect(
      store.categoryFilterChanges,
      1,
      reason:
          'Only the latest settled carousel item should publish once after '
          'the carousel has been idle.',
    );
  });

  testWidgets('budget carousel continues an interrupted release drag', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final carousel = find.byKey(
      const ValueKey('spendee-test-context-carousel-gesture'),
    );
    final firstGesture = await tester.startGesture(tester.getCenter(carousel));
    await firstGesture.moveBy(const Offset(-30, 0));
    await tester.pump(const Duration(milliseconds: 220));
    await firstGesture.up();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 40));

    final secondGesture = await tester.startGesture(tester.getCenter(carousel));
    await secondGesture.moveBy(const Offset(-58, 0));
    await tester.pump(const Duration(milliseconds: 16));

    expect(
      find.byKey(const ValueKey('spendee-test-category-avatar-2-selected')),
      findsOneWidget,
      reason:
          'A new drag should keep the in-flight release residual offset; '
          'resetting it to zero makes the belt jump and misses this tick.',
    );

    await secondGesture.cancel();
    await tester.pumpAndSettle();
  });

  testWidgets(
    'budget carousel threshold release ticks before publishing filter',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final carousel = find.byKey(
        const ValueKey('spendee-test-context-carousel-gesture'),
      );
      DebugConsole.clear();
      final gesture = await tester.startGesture(tester.getCenter(carousel));
      await gesture.moveBy(const Offset(-46, 0));
      await tester.pump();
      await gesture.up();
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 420));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('spendee-test-category-avatar-2-selected')),
        findsOneWidget,
      );
      final entries = DebugConsole.entries;
      final tickIndex = entries.indexWhere(
        (line) =>
            line.contains('[Perf] SpendeeTest carousel_tick') &&
            line.contains('selected=category-2-'),
      );
      final scheduleIndex = entries.indexWhere(
        (line) =>
            line.contains('[Perf] SpendeeTest carousel_filter_schedule') &&
            line.contains('selected=category-2-'),
      );
      expect(
        tickIndex,
        greaterThanOrEqualTo(0),
        reason:
            'A residual beyond the snap threshold must cross a carousel '
            'boundary and emit a tick before the filter is scheduled.',
      );
      expect(scheduleIndex, greaterThan(tickIndex));
    },
  );

  testWidgets('side avatar tap recenters through tick steps', (tester) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    DebugConsole.clear();
    await tester.tap(
      find.byKey(const ValueKey('spendee-test-category-avatar-3')),
    );
    await tester.pumpAndSettle();

    final tickLines = DebugConsole.entries
        .where((line) => line.contains('[Perf] SpendeeTest carousel_tick'))
        .toList();
    final category2Tick = tickLines.indexWhere(
      (line) => line.contains('selected=category-2-'),
    );
    final category3Tick = tickLines.indexWhere(
      (line) => line.contains('selected=category-3-'),
    );
    expect(category2Tick, greaterThanOrEqualTo(0));
    expect(category3Tick, greaterThan(category2Tick));
    expect(
      find.byKey(const ValueKey('spendee-test-category-avatar-3-selected')),
      findsOneWidget,
    );
  });

  testWidgets('chart taps use the faster diagram recenter step timing', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    DebugConsole.clear();
    final donutRect = tester.getRect(
      find.byKey(const ValueKey('spendee-test-budget-pie-donut')),
    );
    await tester.tapAt(donutRect.center + const Offset(-28, 34));
    await tester.pumpAndSettle();

    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (line) =>
              line.contains('[Perf] SpendeeTest carousel_motion_start') &&
              line.contains('source=diagram') &&
              line.contains('stepMs=72'),
        ),
      ),
    );
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

  testWidgets(
    'budget carousel drag moves outer slot and reveals incoming offscreen avatar',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final gestureTarget = find.byKey(
        const ValueKey('spendee-test-context-carousel-gesture'),
      );
      final outerSlot = find.byKey(
        const ValueKey('spendee-test-context-avatar-slot-2'),
      );
      final innerSlot = find.byKey(
        const ValueKey('spendee-test-context-avatar-slot-1'),
      );
      expect(outerSlot, findsOneWidget);
      expect(innerSlot, findsOneWidget);

      final outerBefore = tester.getRect(outerSlot);
      final gesture = await tester.startGesture(
        tester.getCenter(gestureTarget),
      );
      await gesture.moveBy(const Offset(48, 0));
      await tester.pump(const Duration(milliseconds: 16));

      final outerDuring = tester.getRect(outerSlot);
      final innerDuring = tester.getRect(innerSlot);
      expect(
        outerDuring.center.dx,
        greaterThan(outerBefore.center.dx + 12),
        reason:
            'Dragging right must keep pushing the outside avatar instead of '
            'clamping it in place.',
      );
      expect(
        innerDuring.right,
        lessThanOrEqualTo(outerDuring.left),
        reason:
            'The inner avatar must not slide over the fixed outside avatar.',
      );
      expect(
        find.byKey(const ValueKey('spendee-test-context-avatar-slot--3')),
        findsOneWidget,
        reason: 'A right drag must reveal the incoming offscreen left avatar.',
      );

      await gesture.up();
      await tester.pumpAndSettle();
      expect(
        find.byKey(const ValueKey('spendee-test-context-avatar-slot--3')),
        findsNothing,
      );
    },
  );

  testWidgets('header menu removes avatar arcs and keeps max body gloss', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    expect(_avatar3dEffectFinders(), findsNothing);
    expect(_avatarTopHighlightFinders(), findsNothing);
    expect(
      find.byKey(
        const ValueKey(
          'spendee-test-avatar-body-highlight-overview-expense_budget-all_time-all',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-body-highlight-category-1'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-effect-3d-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-effect-top-highlight-toggle'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-body-highlight-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-body-highlight-strength-slider'),
      ),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-progress-thickness-slider'),
      ),
      findsNothing,
      reason: 'Circle progress sizing moved to the avatar layout customizer.',
    );
    expect(
      find.byKey(
        const ValueKey(
          'spendee-test-avatar-body-highlight-overview-expense_budget-all_time-all',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-body-highlight-category-1'),
      ),
      findsOneWidget,
      reason: 'Avatar body gloss is no longer user-disableable.',
    );
  });

  testWidgets('avatar progress controls live in no-veil avatar customizer', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final selectedAvatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    final beforeAvatarRect = tester.getRect(selectedAvatar);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-menu-button')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-progress-thickness-slider'),
      ),
      findsNothing,
      reason:
          'Circle size belongs in the live avatar customizer, not the header dropdown.',
    );
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
    );
    await tester.pumpAndSettle();

    final visibleBarriers = tester
        .widgetList<ModalBarrier>(find.byType(ModalBarrier))
        .where((barrier) => (barrier.color?.a ?? 0) > 0)
        .toList();
    expect(
      visibleBarriers,
      isEmpty,
      reason:
          'The avatar customizer must not dim the app with a veil while tuning.',
    );
    final menu = find.byKey(const ValueKey('spendee-test-avatar-layout-menu'));
    expect(menu, findsOneWidget);
    expect(
      tester.getSize(menu).height,
      lessThanOrEqualTo(360),
      reason:
          'Adding circle controls must not make the avatar customizer taller.',
    );
    expect(
      find.byKey(const ValueKey('spendee-test-avatar-layout-menu-scroll')),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-layout-progress-thickness-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-progress-fade-inner-field'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-progress-fade-outer-field'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey('spendee-test-avatar-progress-fade-curve-slider'),
      ),
      findsOneWidget,
    );
    _expectRectsClose(tester.getRect(selectedAvatar), beforeAvatarRect);
  });

  testWidgets(
    'avatar customizer changes selected avatar progress fade endpoints and curve',
    (tester) async {
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

      final selectedAvatar = find.byKey(
        const ValueKey('spendee-test-category-avatar-1-selected'),
      );
      final beforeAvatarRect = tester.getRect(selectedAvatar);

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
      );
      await tester.pumpAndSettle();

      final innerField = find.byKey(
        const ValueKey('spendee-test-avatar-progress-fade-inner-field'),
      );
      final outerField = find.byKey(
        const ValueKey('spendee-test-avatar-progress-fade-outer-field'),
      );
      final curveSlider = find.byKey(
        const ValueKey('spendee-test-avatar-progress-fade-curve-slider'),
      );
      expect(innerField, findsOneWidget);
      expect(outerField, findsOneWidget);
      expect(curveSlider, findsOneWidget);

      await tester.enterText(innerField, '0.25');
      await tester.pump();
      await tester.enterText(outerField, '0.90');
      await tester.pump();
      await tester.ensureVisible(curveSlider);
      await tester.pumpAndSettle();
      await tester.drag(curveSlider, const Offset(300, 0));
      await tester.pump();
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      final progressPaint = tester.widget<CustomPaint>(
        find.byKey(
          const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
        ),
      );
      final painter = progressPaint.painter as dynamic;
      expect(painter.fadeInnerEndpoint, closeTo(.25, .001));
      expect(painter.fadeOuterEndpoint, closeTo(.90, .001));
      expect(painter.innerEdgeAlpha, closeTo(.25, .001));
      expect(painter.outerEdgeAlpha, closeTo(.90, .001));
      expect(painter.fadeCurveBalance, greaterThan(.95));
      expect(
        painter.outerTransitionStartUnit,
        greaterThan(.85),
        reason:
            'At the right edge the outer endpoint should appear abruptly near '
            'the outside of the ring.',
      );
      expect(painter.progressPathDrawPassCount, 1);
      expect(painter.progressStrokeDrawPassCount, 0);
      _expectRectsClose(tester.getRect(selectedAvatar), beforeAvatarRect);
    },
  );

  testWidgets(
    'avatar progress draws optional remaining segment including zero spend limit',
    (tester) async {
      final seventyFiveStore = TransactionStore(
        _DashboardTestRepository(
          transactions: [_record(1, 1, -75000, 'Bolt')],
          limitRows: [
            _limit(1, LimitTargetType.overview, 0, 100000),
            _limit(2, LimitTargetType.category, 1, 100000),
          ],
        ),
        clock: () => DateTime(2026, 7, 17),
      );
      await seventyFiveStore.start();
      seventyFiveStore.commitStatsViewMutation(
        await seventyFiveStore.prepareStatsViewMutation(
          summaryWindow: SummaryWindow.monthly,
          year: 2026,
          month: 7,
        ),
      );
      await _pumpDashboardWithStore(tester, seventyFiveStore);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final progressRing = find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      );
      expect(
        progressRing,
        paints
          ..path()
          ..path(),
      );
      final seventyFivePainter =
          tester.widget<CustomPaint>(progressRing).painter as dynamic;
      expect(seventyFivePainter.progress, closeTo(.75, .001));
      expect(seventyFivePainter.remainingProgress, closeTo(.25, .001));
      expect(seventyFivePainter.remainingPathDrawPassCount, 1);

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('spendee-test-avatar-remaining-toggle')),
      );
      await tester.pump();
      final disabledPainter =
          tester.widget<CustomPaint>(progressRing).painter as dynamic;
      expect(disabledPainter.remainingEnabled, isFalse);
      expect(disabledPainter.remainingPathDrawPassCount, 0);
      expect(progressRing, paints..path());
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      final zeroSpendStore = TransactionStore(
        _DashboardTestRepository(
          transactions: const <TransactionRecord>[],
          limitRows: [
            _limit(1, LimitTargetType.overview, 0, 100000),
            _limit(2, LimitTargetType.category, 1, 100000),
          ],
        ),
        clock: () => DateTime(2026, 7, 17),
      );
      await zeroSpendStore.start();
      zeroSpendStore.commitStatsViewMutation(
        await zeroSpendStore.prepareStatsViewMutation(
          summaryWindow: SummaryWindow.monthly,
          year: 2026,
          month: 7,
        ),
      );
      await _pumpDashboardWithStore(tester, zeroSpendStore);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final zeroRing = find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      );
      expect(zeroRing, paints..path());
      final zeroPainter =
          tester.widget<CustomPaint>(zeroRing).painter as dynamic;
      expect(zeroPainter.progress, 0);
      expect(zeroPainter.hasPositiveLimit, isTrue);
      expect(zeroPainter.remainingProgress, 1);
      expect(zeroPainter.progressPathDrawPassCount, 0);
      expect(zeroPainter.remainingPathDrawPassCount, 1);
    },
  );

  testWidgets(
    'avatar customizer changes remaining opacity and solid threshold colors',
    (tester) async {
      final store = TransactionStore(
        _DashboardTestRepository(
          transactions: [_record(1, 1, -75000, 'Bolt')],
          limitRows: [
            _limit(1, LimitTargetType.overview, 0, 100000),
            _limit(2, LimitTargetType.category, 1, 100000),
          ],
        ),
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

      final selectedAvatar = find.byKey(
        const ValueKey('spendee-test-category-avatar-1-selected'),
      );
      final beforeAvatarRect = tester.getRect(selectedAvatar);

      await tester.tap(
        find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
      );
      await tester.pumpAndSettle();

      final opacitySlider = find.byKey(
        const ValueKey('spendee-test-avatar-remaining-opacity-slider'),
      );
      expect(
        find.byKey(const ValueKey('spendee-test-avatar-remaining-toggle')),
        findsOneWidget,
      );
      expect(opacitySlider, findsOneWidget);
      expect(_avatarThresholdSwatches('danger'), findsNWidgets(5));
      expect(_avatarThresholdSwatches('warning'), findsNWidgets(5));

      await tester.ensureVisible(opacitySlider);
      await tester.pumpAndSettle();
      await tester.drag(opacitySlider, const Offset(-28, 0));
      await tester.pump();
      await tester.ensureVisible(
        find.byKey(const ValueKey('spendee-test-avatar-threshold-danger-4')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('spendee-test-avatar-threshold-danger-4')),
      );
      await tester.ensureVisible(
        find.byKey(const ValueKey('spendee-test-avatar-threshold-warning-3')),
      );
      await tester.pumpAndSettle();
      await tester.tap(
        find.byKey(const ValueKey('spendee-test-avatar-threshold-warning-3')),
      );
      await tester.tapAt(Offset.zero);
      await tester.pumpAndSettle();

      final progressPaint = tester.widget<CustomPaint>(
        find.byKey(
          const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
        ),
      );
      final painter = progressPaint.painter as dynamic;
      expect(painter.remainingOpacity, lessThan(.45));
      expect(painter.remainingOpacity, greaterThan(0));
      expect(painter.dangerProgressColor, const Color(0xFF991B1B));
      expect(painter.warningProgressColor, const Color(0xFFEA580C));
      expect(painter.progressColor, const Color(0xFFEA580C));
      expect(painter.usesSolidThresholdColors, isTrue);
      expect(painter.progressPathDrawPassCount, 1);
      expect(painter.remainingPathDrawPassCount, 1);
      _expectRectsClose(tester.getRect(selectedAvatar), beforeAvatarRect);
    },
  );

  testWidgets('selected avatar progress keeps one halo while body border is shared', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final selectedCategory = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    expect(selectedCategory, findsOneWidget);
    expect(
      _circularAvatarBodyBorders(tester, selectedCategory),
      isNotEmpty,
      reason:
          'The shared avatar border setting should apply to selected category avatars too.',
    );

    final categoryProgressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      ),
    );
    final categoryPainter = categoryProgressPaint.painter as dynamic;
    final categoryProgress = categoryPainter.progress as double;
    expect(categoryPainter.usesOuterGlassHalo, isTrue);
    expect(categoryPainter.progressStrokeDrawPassCount, 0);
    expect(categoryPainter.usesRadialBandFade, isTrue);
    expect(categoryPainter.usesAngularFadeStroke, isFalse);
    expect(categoryPainter.drawsSeparateInnerProgressRing, isFalse);
    expect(
      categoryPainter.visibleProgressRingCount,
      categoryProgress > 0 ? 1 : 0,
    );
    if (categoryProgress > 0) {
      expect(categoryPainter.progressDrawPassCount, 1);
      expect(categoryPainter.progressPathDrawPassCount, 1);
      expect(
        categoryPainter.innerEdgeAlpha,
        greaterThan(categoryPainter.outerEdgeAlpha),
      );
    } else {
      expect(categoryPainter.progressDrawPassCount, 0);
      expect(categoryPainter.progressPathDrawPassCount, 0);
    }
    expect(
      _selectedAvatarOuterGlowShadows(tester, selectedCategory),
      isEmpty,
      reason:
          'The selected avatar body must not add a separate glow ring around the progress bar.',
    );

    await tester.tap(
      find.byKey(
        const ValueKey(
          'spendee-test-budget-avatar-overview-expense_budget-all_time-all',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final selectedOverview = find.byKey(
      const ValueKey(
        'spendee-test-budget-avatar-overview-expense_budget-all_time-all-selected',
      ),
    );
    expect(selectedOverview, findsOneWidget);
    expect(
      _circularAvatarBodyBorders(tester, selectedOverview),
      isNotEmpty,
      reason:
          'Selected overview avatars should follow the same shared border policy as categories.',
    );
  });

  testWidgets(
    'avatar progress painter draws one radial path without track or glow',
    (tester) async {
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

      final progressRing = find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      );
      expect(progressRing, findsOneWidget);
      expect(
        progressRing,
        paints..path(),
        reason:
            'The progress indicator must be one annular path so radial alpha '
            'does not create a second stroked circle.',
      );
      expect(
        progressRing,
        isNot(paints..arc()),
        reason:
            'A stroked arc can read as separate inner/outer rings once radial '
            'softening is applied.',
      );
      expect(
        progressRing,
        isNot(paints..circle()),
        reason: 'Full-circle progress must not be a stroked circle pass.',
      );
      expect(
        progressRing,
        isNot(paints..something((methodName, _) => methodName == #drawOval)),
        reason:
            'A separate full oval track creates the inner/outer double-ring look in screenshots.',
      );

      final progressPaint = tester.widget<CustomPaint>(progressRing);
      final painter = progressPaint.painter as dynamic;
      expect(painter.visibleProgressRingCount, 1);
      expect(painter.trackDrawPassCount, 0);
      expect(painter.glowDrawPassCount, 0);
      expect(painter.usesRadialFadeStroke, isFalse);
      expect(painter.usesStrokeBlur, isFalse);
      expect(painter.usesRadialBandFade, isTrue);
      expect(painter.usesAngularFadeStroke, isFalse);
      expect(painter.progressPathDrawPassCount, 1);
      expect(painter.progressStrokeDrawPassCount, 0);
      expect(painter.innerEdgeAlpha, greaterThan(painter.outerEdgeAlpha));
      expect(
        progressRing,
        paints..something(_progressPathUsesShader),
        reason:
            'The single annular path provides the requested radial fade: '
            'stronger near the avatar, softer at the outside edge.',
      );
      expect(
        progressRing,
        isNot(paints..something(_progressPaintUsesShader)),
        reason:
            'The progress must not use a shader-backed stroke; that creates '
            'the unwanted angular/bottom fade or double-ring look.',
      );
      expect(
        progressRing,
        isNot(paints..something(_progressPaintUsesMaskFilter)),
        reason: 'The progress stroke must not add a second blurred/glow ring.',
      );
    },
  );

  testWidgets(
    'avatar progress and body share immediate sizing during fast movement',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final selectedAvatar = find.byKey(
        const ValueKey('spendee-test-category-avatar-1-selected'),
      );
      final glossyAvatarFinder = find.descendant(
        of: selectedAvatar,
        matching: find.byType(GlossyCategoryAvatar),
      );
      expect(glossyAvatarFinder, findsOneWidget);
      final glossyAvatar = tester.widget<GlossyCategoryAvatar>(
        glossyAvatarFinder,
      );
      final bodyContainers = tester
          .widgetList<AnimatedContainer>(
            find.descendant(
              of: selectedAvatar,
              matching: find.byType(AnimatedContainer),
            ),
          )
          .where((container) {
            final constraints = container.constraints;
            return constraints?.minWidth == glossyAvatar.size &&
                constraints?.maxWidth == glossyAvatar.size &&
                constraints?.minHeight == glossyAvatar.size &&
                constraints?.maxHeight == glossyAvatar.size;
          })
          .toList();

      expect(bodyContainers, hasLength(1));
      expect(
        bodyContainers.single.duration,
        Duration.zero,
        reason:
            'Context avatar body sizing must not animate separately from the halo during fast grow/shrink movement.',
      );
    },
  );

  testWidgets('avatar layout menu controls circle progress thickness', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final selectedAvatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    final beforeAvatarRect = tester.getRect(selectedAvatar);
    final beforeProgressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      ),
    );
    final beforeStroke =
        (beforeProgressPaint.painter as dynamic).strokeWidth as double;

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
    );
    await tester.pumpAndSettle();

    final slider = find.byKey(
      const ValueKey('spendee-test-avatar-layout-progress-thickness-slider'),
    );
    expect(slider, findsOneWidget);
    await tester.drag(slider, const Offset(88, 0));
    await tester.pump();
    await tester.tapAt(Offset.zero);
    await tester.pumpAndSettle();

    final afterProgressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      ),
    );
    expect(
      (afterProgressPaint.painter as dynamic).strokeWidth as double,
      greaterThan(beforeStroke),
    );
    _expectRectsClose(tester.getRect(selectedAvatar), beforeAvatarRect);
  });

  testWidgets('budget overview avatar uses the same glossy body and halo ring', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final categoryProgressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-1'),
      ),
    );
    final categoryPainter = categoryProgressPaint.painter as dynamic;

    await tester.tap(
      find.byKey(
        const ValueKey(
          'spendee-test-budget-avatar-overview-expense_budget-all_time-all',
        ),
      ),
    );
    await tester.pumpAndSettle();

    final overviewAvatar = find.byKey(
      const ValueKey(
        'spendee-test-budget-avatar-overview-expense_budget-all_time-all-selected',
      ),
    );
    expect(overviewAvatar, findsOneWidget);
    expect(
      find.descendant(
        of: overviewAvatar,
        matching: find.byType(GlossyCategoryAvatar),
      ),
      findsOneWidget,
      reason: 'Budget overview must use the same avatar body as categories.',
    );
    final overviewProgressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey(
          'spendee-test-avatar-outer-halo-progress-overview-expense_budget-all_time-all',
        ),
      ),
    );
    final overviewPainter = overviewProgressPaint.painter as dynamic;
    final overviewProgress = overviewPainter.progress as double;
    expect(
      overviewPainter.visibleProgressRingCount,
      overviewProgress > 0 ? 1 : 0,
    );
    if (overviewProgress > 0) {
      expect(overviewPainter.progressDrawPassCount, 1);
      expect(overviewPainter.progressPathDrawPassCount, 1);
    } else {
      expect(overviewPainter.progressDrawPassCount, 0);
      expect(overviewPainter.progressPathDrawPassCount, 0);
    }
    expect(overviewPainter.progressStrokeDrawPassCount, 0);
    expect(overviewPainter.drawsSeparateInnerProgressRing, isFalse);
    expect(overviewPainter.strokeWidth, categoryPainter.strokeWidth);
  });

  testWidgets(
    'stage 2 vendor rows use current period data and category colors',
    (tester) async {
      final store = TransactionStore(
        _DashboardTestRepository(
          categories: [
            _category(1, 'Élelmiszer', 7, 0),
            _category(2, 'Közlekedés', 3, 1),
          ],
          transactions: [
            _record(1, 1, -100000, 'Aktuális bolt'),
            _record(2, 1, -50000, 'Régi bolt', date: '2026.06.17'),
            _record(3, 2, -1, 'Kerekítési apró'),
          ],
          limitRows: [
            _limit(1, LimitTargetType.overview, 0, 200000),
            _limit(2, LimitTargetType.category, 1, 120000),
            _limit(3, LimitTargetType.category, 2, 40000),
          ],
        ),
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
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      final panel = tester.widget<Container>(
        find.byKey(const ValueKey('spendee-test-budget-pie-panel')),
      );
      expect(
        panel.child,
        isA<ClipRRect>(),
        reason:
            'The glass panel must clip content directly instead of painting a '
            'square-cornered radial remnant over the rounded panel.',
      );
      expect(
        find.text('0% · 1 Ft'),
        findsNothing,
        reason: 'Rounded zero-percent entries are hidden from category rows.',
      );

      await tester.drag(
        find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
        const Offset(-140, 0),
      );
      await tester.pumpAndSettle();

      expect(
        find.descendant(
          of: find.byKey(const ValueKey('spendee-test-budget-vendor-row-0')),
          matching: find.text('Aktuális bolt'),
        ),
        findsOneWidget,
      );
      expect(find.text('Régi bolt'), findsNothing);

      final dot = tester.widget<Container>(
        find.byKey(const ValueKey('spendee-test-budget-vendor-row-0-dot')),
      );
      final decoration = dot.decoration as BoxDecoration;
      final gradient = decoration.gradient as LinearGradient;
      expect(
        gradient.colors,
        core_colors.CategoryColorManager.gradient(7).colors,
      );
    },
  );

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
    expect(
      painter.progressColor,
      const Color(0xFFEF4444),
      reason: 'Over 90% budget usage must tint the halo progress red.',
    );
    expect(painter.usesOuterGlassHalo, isTrue);
    expect(painter.drawsInsideAvatarBody, isFalse);
    expect(painter.usesRadialFadeStroke, isFalse);
    expect(painter.usesRadialBandFade, isTrue);
    expect(painter.usesAngularFadeStroke, isFalse);
    expect(painter.progressDrawPassCount, 1);
    expect(painter.progressPathDrawPassCount, 1);
    expect(painter.progressStrokeDrawPassCount, 0);
    expect(painter.drawsSeparateInnerProgressRing, isFalse);
    expect(painter.innerEdgeAlpha, greaterThan(painter.outerEdgeAlpha));
    expect(painter.startRadians, closeTo(-math.pi / 2, .001));
    expect(painter.clockwise, isTrue);
    expect(painter.strokeWidth, greaterThanOrEqualTo(8));

    final selectedAvatar = tester.widget<GlossyCategoryAvatar>(
      find.descendant(
        of: find.byKey(
          const ValueKey('spendee-test-category-avatar-1-selected'),
        ),
        matching: find.byType(GlossyCategoryAvatar),
      ),
    );
    expect(
      (selectedAvatar as dynamic).scaleSelection,
      isFalse,
      reason:
          'The avatar body and progress halo must share one outer transform.',
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-category-avatar-2')),
    );
    await tester.pumpAndSettle();
    final yellowProgressPaint = tester.widget<CustomPaint>(
      find.byKey(
        const ValueKey('spendee-test-avatar-outer-halo-progress-category-2'),
      ),
    );
    expect(
      (yellowProgressPaint.painter as dynamic).progressColor,
      const Color(0xFFFBBF24),
      reason: 'At least 75% budget usage must tint the halo progress yellow.',
    );
  });

  testWidgets('avatar taps and long press use shrink feedback only', (
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
    expect(
      tester.widget<AnimatedScale>(scaleFinder).duration,
      greaterThanOrEqualTo(const Duration(milliseconds: 100)),
      reason: 'Press shrink/grow should be smooth enough to avoid choppy taps.',
    );

    final avatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );

    final tapGesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 1));
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, closeTo(.8, .001));

    await tapGesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);

    final gesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 650));

    expect(tester.widget<AnimatedScale>(scaleFinder).scale, closeTo(.8, .001));

    await gesture.up();
    await tester.pumpAndSettle();
    expect(tester.widget<AnimatedScale>(scaleFinder).scale, 1.0);
  });

  testWidgets('stage 2 downward second tick springs directly to stage 0', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
      findsOneWidget,
    );

    DebugConsole.clear();
    await _dragHeaderBy(tester, 42);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-dashboard-stage-stage0')),
      findsOneWidget,
    );
    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (line) =>
              line.contains('[Perf] SpendeeTest header_drag') &&
              line.contains('targetStage=stage0') &&
              line.contains('springBack=true'),
        ),
      ),
    );
  });

  testWidgets(
    'stage 1 collapse keeps the dragged height for spring animation',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final header = find.byKey(const ValueKey('spendee-test-header-card'));
      final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, 4));
      await tester.pump();
      final draggedHeight = tester.getSize(header).height;
      expect(draggedHeight, greaterThan(238));

      await gesture.up();
      await tester.pump();

      expect(
        tester.getSize(header).height,
        greaterThan(104),
        reason:
            'The first release frame should animate down from the dragged C2 '
            'height instead of rebuilding directly at Stage 0 height.',
      );
    },
  );

  testWidgets(
    'stage 2 collapse keeps the dragged height for spring animation',
    (tester) async {
      await _pumpDashboard(tester);
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();
      await _dragHeaderBy(tester, 272);
      await tester.pumpAndSettle();

      final header = find.byKey(const ValueKey('spendee-test-header-card'));
      final handle = find.byKey(const ValueKey('spendee-test-header-handle'));
      final gesture = await tester.startGesture(tester.getCenter(handle));
      await gesture.moveBy(const Offset(0, 42));
      await tester.pump();
      final draggedHeight = tester.getSize(header).height;
      expect(draggedHeight, greaterThan(510));

      await gesture.up();
      await tester.pump();

      expect(
        tester.getSize(header).height,
        greaterThan(104),
        reason:
            'The first release frame should animate down from the dragged C3 '
            'height instead of rebuilding directly at Stage 0 height.',
      );
    },
  );

  testWidgets('deep stage 0 drag opens stage 2 directly', (tester) async {
    await _pumpDashboard(tester);

    DebugConsole.clear();
    await _dragHeaderBy(tester, 406);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-dashboard-stage-stage2')),
      findsOneWidget,
    );
    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (line) =>
              line.contains('[Perf] SpendeeTest header_drag') &&
              line.contains('targetStage=stage2'),
        ),
      ),
    );
  });

  testWidgets(
    'stage 2 category rows select avatar without leaving category chart',
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
        find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('spendee-test-category-avatar-3-selected')),
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
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
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

  testWidgets('limit edit auto ticks while held away from the avatar', (
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
    await gesture.moveBy(const Offset(0, -62));
    await tester.pump(const Duration(milliseconds: 80));
    final savesAfterDrag = repository.savedLimitPayloads.length;

    await tester.pump(const Duration(milliseconds: 700));
    expect(
      repository.savedLimitPayloads.length,
      greaterThan(savesAfterDrag),
      reason:
          'Limit edit should keep auto-ticking while the hold remains far '
          'above or below the avatar, even without additional move events.',
    );

    await gesture.up();
    await tester.pumpAndSettle();
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
    DebugConsole.clear();
    final gesture = await tester.startGesture(tester.getCenter(avatar));
    await tester.pump(const Duration(milliseconds: 1350));
    await gesture.up();
    await tester.pumpAndSettle();

    expect(repository.savedLimitPayloads, isNotEmpty);
    expect(repository.savedLimitPayloads.last['targetType'], 'category');
    expect(repository.savedLimitPayloads.last['targetId'], 1);
    expect(repository.savedLimitPayloads.last['hasLimit'], isFalse);
    expect(repository.savedLimitPayloads.last['limitAmount'], 0);
    expect(
      DebugConsole.entries,
      contains(
        predicate<String>(
          (line) =>
              line.contains('[Perf] SpendeeTest budget_limit_clear') &&
              line.contains('strength=strong'),
        ),
      ),
    );
  });

  testWidgets('stage 2 always offers category and vendor pages by swipe', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );
    expect(
      tester
          .widget<Text>(
            find.byKey(const ValueKey('spendee-test-budget-pie-focus-title')),
          )
          .data,
      'Élelmiszer',
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
      find.byKey(
        const ValueKey(
          'spendee-test-budget-avatar-overview-expense_budget-all_time-all-selected',
        ),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
    );
    expect(find.text('Busz'), findsOneWidget);
    expect(find.text('Burger'), findsOneWidget);

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

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(140, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
      reason: 'Swiping backward from categories should loop to vendors.',
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
      reason: 'Swiping forward from vendors should loop to categories.',
    );
  });

  testWidgets('header background opens avatar layout customization menu', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    final selectedAvatar = find.byKey(
      const ValueKey('spendee-test-category-avatar-1-selected'),
    );
    final beforeWidth = tester.getRect(selectedAvatar).width;
    final innerBefore = tester.getRect(
      find.byKey(const ValueKey('spendee-test-category-avatar-2')),
    );
    final centerBefore = tester.getRect(selectedAvatar).center.dx;

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
    );
    await tester.pumpAndSettle();

    const centerSliderKey = ValueKey(
      'spendee-test-avatar-layout-center-size-slider',
    );
    const innerSizeSliderKey = ValueKey(
      'spendee-test-avatar-layout-inner-size-slider',
    );
    const outerSizeSliderKey = ValueKey(
      'spendee-test-avatar-layout-outer-size-slider',
    );
    const innerOffsetSliderKey = ValueKey(
      'spendee-test-avatar-layout-inner-offset-slider',
    );
    const outerOffsetSliderKey = ValueKey(
      'spendee-test-avatar-layout-outer-offset-slider',
    );
    expect(find.byKey(centerSliderKey), findsOneWidget);
    expect(find.byKey(innerSizeSliderKey), findsOneWidget);
    expect(find.byKey(outerSizeSliderKey), findsOneWidget);
    expect(find.byKey(innerOffsetSliderKey), findsOneWidget);
    expect(find.byKey(outerOffsetSliderKey), findsOneWidget);

    await tester.ensureVisible(find.byKey(centerSliderKey));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(centerSliderKey), const Offset(80, 0));
    await tester.pumpAndSettle();
    expect(tester.getRect(selectedAvatar).width, greaterThan(beforeWidth));

    await tester.ensureVisible(find.byKey(innerOffsetSliderKey));
    await tester.pumpAndSettle();
    await tester.drag(find.byKey(innerOffsetSliderKey), const Offset(-80, 0));
    await tester.pumpAndSettle();
    final innerAfter = tester.getRect(
      find.byKey(const ValueKey('spendee-test-category-avatar-2')),
    );
    expect(
      (innerAfter.center.dx - centerBefore).abs(),
      lessThan((innerBefore.center.dx - centerBefore).abs()),
      reason:
          'Dragging the inner offset slider left moves inner avatars inward.',
    );
  });

  testWidgets('avatar layout menu toggles the shared white avatar border', (
    tester,
  ) async {
    await _pumpDashboard(tester);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();

    GlossyCategoryAvatar selectedAvatar() =>
        tester.widget<GlossyCategoryAvatar>(
          find.descendant(
            of: find.byKey(
              const ValueKey('spendee-test-category-avatar-1-selected'),
            ),
            matching: find.byType(GlossyCategoryAvatar),
          ),
        );
    GlossyCategoryAvatar sideAvatar() => tester.widget<GlossyCategoryAvatar>(
      find.descendant(
        of: find.byKey(const ValueKey('spendee-test-category-avatar-2')),
        matching: find.byType(GlossyCategoryAvatar),
      ),
    );

    expect(selectedAvatar().showBodyBorder, isTrue);
    expect(sideAvatar().showBodyBorder, isTrue);

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-header-background-tap-target')),
    );
    await tester.pumpAndSettle();
    const borderToggleKey = ValueKey('spendee-test-avatar-border-toggle');
    await tester.ensureVisible(find.byKey(borderToggleKey));
    await tester.pumpAndSettle();
    expect(find.byKey(borderToggleKey), findsOneWidget);

    await tester.tap(find.byKey(borderToggleKey));
    await tester.pumpAndSettle();

    expect(selectedAvatar().showBodyBorder, isFalse);
    expect(sideAvatar().showBodyBorder, isFalse);
  });

  testWidgets(
    'header value omits slash zero when selected avatar has no limit',
    (tester) async {
      await _pumpDashboard(
        tester,
        repository: _NoLimitDashboardTestRepository(),
      );
      await _dragHeaderBy(tester, 134);
      await tester.pumpAndSettle();

      final value = tester
          .widget<Text>(find.byKey(const ValueKey('spendee-test-header-value')))
          .data;
      expect(value, '75 240 Ft');
      expect(value, isNot(contains('/ 0 Ft')));
    },
  );

  testWidgets('fast filters render closable capsules in the search pill', (
    tester,
  ) async {
    final store = await _pumpDashboard(tester);
    store.setCategoryFilter(store.categoriesById[1]!);
    await tester.pumpAndSettle();
    store.setMerchantFilter('Élelmiszer bolt');
    await tester.pumpAndSettle();

    final categoryCapsule = find.byKey(
      const ValueKey('search-pill-capsule-category-1'),
    );
    final merchantCapsule = find.byKey(
      const ValueKey('search-pill-capsule-merchant-Élelmiszer bolt'),
    );
    expect(categoryCapsule, findsOneWidget);
    expect(merchantCapsule, findsOneWidget);
    expect(
      find.descendant(of: categoryCapsule, matching: find.text('Élelmiszer')),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: merchantCapsule,
        matching: find.text('Élelmiszer bolt'),
      ),
      findsOneWidget,
    );

    await tester.tap(
      find.descendant(of: categoryCapsule, matching: find.byType(IconButton)),
    );
    await tester.pumpAndSettle();
    expect(store.activeCategoryIds, isEmpty);
    expect(merchantCapsule, findsOneWidget);
  });

  testWidgets('stage 2 blocks vendor page when selected category is empty', (
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
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-row-2')),
      findsOneWidget,
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
      reason:
          'A selected empty category should keep the shared period category '
          'chart visible instead of opening an empty vendor page.',
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-budget-pie-row-2')),
      findsOneWidget,
    );
  });

  testWidgets('stage 2 clears stale vendor page after an empty category', (
    tester,
  ) async {
    final store = TransactionStore(
      _DashboardTestRepository(transactions: [_record(1, 1, -42000, 'Piac')]),
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-category-avatar-2')),
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

    await tester.tap(
      find.byKey(const ValueKey('spendee-test-budget-pie-row-1')),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsOneWidget,
      reason:
          'Selecting a spend category after an empty category should not reuse '
          'a hidden stale vendor page state.',
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );
  });

  testWidgets('stage 2 empty period shows a single non-pageable empty panel', (
    tester,
  ) async {
    final store = TransactionStore(
      _DashboardTestRepository(transactions: const <TransactionRecord>[]),
      clock: () => DateTime(2026, 7, 17),
    );
    await store.start();
    await _pumpDashboardWithStore(tester, store);
    await _dragHeaderBy(tester, 134);
    await tester.pumpAndSettle();
    await _dragHeaderBy(tester, 272);
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-empty-panel')),
      findsOneWidget,
    );
    expect(find.text('Nincs adat'), findsOneWidget);
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-categories')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('spendee-test-stage2-page-vendors')),
      findsNothing,
    );

    await tester.drag(
      find.byKey(const ValueKey('spendee-test-budget-pie-stage2-layer')),
      const Offset(-140, 0),
    );
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('spendee-test-stage2-empty-panel')),
      findsOneWidget,
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

Finder _avatarTopHighlightFinders() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('spendee-test-avatar-top-highlight-');
  });
}

Finder _avatarLegacyProgressFinders() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('spendee-test-avatar-progress-');
  });
}

Finder _avatarThresholdSwatches(String group) {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('spendee-test-avatar-threshold-$group-');
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

List<BoxDecoration> _circularAvatarBodyBorders(
  WidgetTester tester,
  Finder root,
) {
  return tester
      .widgetList<DecoratedBox>(
        find.descendant(of: root, matching: find.byType(DecoratedBox)),
      )
      .map((widget) => widget.decoration)
      .whereType<BoxDecoration>()
      .where(
        (decoration) =>
            decoration.shape == BoxShape.circle && decoration.border != null,
      )
      .toList();
}

List<BoxShadow> _selectedAvatarOuterGlowShadows(
  WidgetTester tester,
  Finder root,
) {
  final decoration = _glossyAvatarBodyDecoration(tester, root);
  return (decoration.boxShadow ?? const <BoxShadow>[])
      .where((shadow) => shadow.spreadRadius > 0)
      .toList();
}

BoxDecoration _glossyAvatarBodyDecoration(WidgetTester tester, Finder root) {
  final glossyAvatar = tester.widget<GlossyCategoryAvatar>(
    find.descendant(of: root, matching: find.byType(GlossyCategoryAvatar)),
  );
  final bodyContainers = tester
      .widgetList<AnimatedContainer>(
        find.descendant(of: root, matching: find.byType(AnimatedContainer)),
      )
      .where((container) {
        final constraints = container.constraints;
        return constraints?.minWidth == glossyAvatar.size &&
            constraints?.maxWidth == glossyAvatar.size &&
            constraints?.minHeight == glossyAvatar.size &&
            constraints?.maxHeight == glossyAvatar.size;
      })
      .toList();
  expect(bodyContainers, hasLength(1));
  return bodyContainers.single.decoration! as BoxDecoration;
}

bool _progressPaintUsesShader(Symbol methodName, List<dynamic> arguments) {
  if (methodName != #drawArc && methodName != #drawCircle) return false;
  final paint = arguments.last as Paint;
  return paint.shader != null;
}

bool _progressPaintUsesMaskFilter(Symbol methodName, List<dynamic> arguments) {
  if (methodName != #drawArc &&
      methodName != #drawCircle &&
      methodName != #drawPath) {
    return false;
  }
  final paint = arguments.last as Paint;
  return paint.maskFilter != null;
}

bool _progressPathUsesShader(Symbol methodName, List<dynamic> arguments) {
  if (methodName != #drawPath) return false;
  final paint = arguments.last as Paint;
  return paint.style == PaintingStyle.fill &&
      paint.shader != null &&
      paint.maskFilter == null;
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

class _MindSumDashboardStatsRepository extends _DashboardTestRepository {
  _MindSumDashboardStatsRepository()
    : super(
        categories: [
          _category(1, 'Élelmiszer', 7, 0),
          _category(2, 'Közlekedés', 3, 1),
          _category(101, 'Fizetés', 12, 2, type: 'bevétel'),
        ],
        transactions: [
          _record(1, 1, -8400, 'Piac', date: '2022.01.08'),
          _record(2, 2, -5600, 'Busz', date: '2023.02.12'),
          _record(101, 1, -12000, 'Piac', date: '2024.01.04'),
          _record(201, 1, -21000, 'Piac', date: '2025.01.03'),
          _record(202, 2, -9200, 'Busz', date: '2025.02.12'),
          _record(203, 101, 300000, 'Munkahely', date: '2025.02.01'),
          _record(301, 1, -11000, 'Piac', date: '2026.01.03'),
          _record(302, 2, -7200, 'Busz', date: '2026.01.11'),
          _record(303, 1, -31000, 'Piac', date: '2026.02.04'),
          _record(304, 2, -9600, 'Metro', date: '2026.03.12'),
          _record(305, 101, 280000, 'Munkahely', date: '2026.01.01'),
          _record(306, 101, 310000, 'Munkahely', date: '2026.02.01'),
          _record(307, 101, 500000, 'Munkahely', date: '2026.03.01'),
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
    List<CategoryLimit>? limitRows,
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
           ],
       limits =
           limitRows ??
           [
             _limit(1, LimitTargetType.overview, 0, 200000),
             _limit(2, LimitTargetType.category, 1, 80000),
             _limit(3, LimitTargetType.category, 2, 40000),
             _limit(4, LimitTargetType.category, 3, 30000),
             _limit(5, LimitTargetType.category, 4, 10000),
             _limit(6, LimitTargetType.category, 5, 10000),
           ];

  final List<TransactionCategory> categories;
  final List<TransactionRecord> transactions;
  final List<CategoryLimit> limits;

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

class _NoLimitDashboardTestRepository extends _DashboardTestRepository {
  _NoLimitDashboardTestRepository() : super(limitRows: const <CategoryLimit>[]);
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
