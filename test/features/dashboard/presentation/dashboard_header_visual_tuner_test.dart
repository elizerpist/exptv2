import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_category_scale.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_mind_score_color.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_portal_material_field.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_logbox_layout_profile.dart';
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/presentation/budget_section_order.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_corner_roundness.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_logbox_height.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_border_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_logbox_amount_palette.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shell_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_summary_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_budget_header_presentation.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_behavioral_score_settings.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_header_score_chart_presentation.dart';
import 'package:fluvi/features/dashboard/mind/domain/mind_year_heatmap_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_history_projection.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/core/financial_limits/presentation/budget_ring_presentation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets(
    'Balance Header tuner exposes the approved palette selector and manual position/window controls',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(800, 2600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final controller = DashboardHeaderVisualController(vsync: tester);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 2500,
            child: DashboardHeaderVisualTuner(controller: controller),
          ),
        ),
      );
      final selector = find.byKey(
        const ValueKey<String>('dashboard-header-balance-palette-selector'),
      );
      await tester.ensureVisible(selector);
      final dropdown = tester
          .widget<DropdownButton<DashboardBalanceHeaderPalette>>(selector);
      expect(dropdown.items, hasLength(8));
      final variantSelector = find.byKey(
        const ValueKey<String>('dashboard-header-balance-variant-selector'),
      );
      final variantDropdown = tester
          .widget<DropdownButton<DashboardBalanceHeaderPaletteVariant>>(
            variantSelector,
          );
      expect(variantDropdown.items, hasLength(3));
      variantDropdown.onChanged!(DashboardBalanceHeaderPaletteVariant.vivid);
      for (final palette in const <DashboardBalanceHeaderPalette>[
        DashboardBalanceHeaderPalette.balanceDiverging,
        DashboardBalanceHeaderPalette.limitColorLabNoWhite,
        DashboardBalanceHeaderPalette.softRainbowNoYellowLeft,
        DashboardBalanceHeaderPalette.softRainbowReordered,
      ]) {
        dropdown.onChanged!(palette);
        expect(controller.tuning.value.balanceColor.palette, palette);
        expect(
          controller.tuning.value.balanceColor.variant,
          DashboardBalanceHeaderPaletteVariant.vivid,
        );
      }
      final position = find.byKey(
        const ValueKey<String>('dashboard-header-balance-position-slider'),
      );
      final window = find.byKey(
        const ValueKey<String>('dashboard-header-balance-window-width-slider'),
      );
      // The all-family loop deliberately leaves the last remix selected. Switch
      // back to a deterministic family before asserting position/window
      // preservation through the same selector path.
      dropdown.onChanged!(DashboardBalanceHeaderPalette.balanceDiverging);
      tester
          .widget<Slider>(
            find.descendant(of: position, matching: find.byType(Slider)),
          )
          .onChanged!(100);
      tester
          .widget<Slider>(
            find.descendant(of: window, matching: find.byType(Slider)),
          )
          .onChanged!(10);
      await tester.pump();
      expect(
        controller.tuning.value.balanceColor.palette,
        DashboardBalanceHeaderPalette.balanceDiverging,
      );
      expect(
        controller.tuning.value.balanceColor.variant,
        DashboardBalanceHeaderPaletteVariant.vivid,
      );
      expect(controller.tuning.value.balanceColor.positionPercent, 100);
      expect(controller.tuning.value.balanceColor.windowWidthPercent, 10);

      final iconSize = find.byKey(
        const ValueKey<String>('dashboard-header-mode-icon-size-slider'),
      );
      await tester.ensureVisible(iconSize);
      tester
          .widget<Slider>(
            find.descendant(of: iconSize, matching: find.byType(Slider)),
          )
          .onChanged!(100);
      await tester.pump();
      expect(controller.tuning.value.headerModeIconSizePercent, 100);

      final balanceTextBlack = find.byKey(
        const ValueKey<String>('dashboard-header-balance-text-black'),
      );
      final balanceChartWhite = find.byKey(
        const ValueKey<String>('dashboard-header-balance-chart-white'),
      );
      for (final control in <Finder>[balanceTextBlack, balanceChartWhite]) {
        await tester.ensureVisible(control);
        await tester.tap(control);
      }
      await tester.pump();
      expect(
        controller.tuning.value.balanceHeader.textColor,
        DashboardHeaderForegroundColor.black,
      );
      expect(
        controller.tuning.value.balanceHeader.chartColor,
        DashboardHeaderForegroundColor.white,
      );
      final balanceIconSoftened = find.byKey(
        const ValueKey<String>('dashboard-header-balance-icon-softenedDark'),
      );
      final balanceVeilBlack = find.byKey(
        const ValueKey<String>('dashboard-header-balance-veil-black'),
      );
      await tester.ensureVisible(balanceIconSoftened);
      await tester.tap(balanceIconSoftened);
      await tester.ensureVisible(balanceVeilBlack);
      await tester.tap(balanceVeilBlack);
      final balanceVeilEnabled = find.byKey(
        const ValueKey<String>('dashboard-header-balance-veil-enabled'),
      );
      await tester.ensureVisible(balanceVeilEnabled);
      await tester.tap(balanceVeilEnabled);
      await tester.pump();
      expect(
        controller.tuning.value.balanceHeader.iconColor,
        DashboardHeaderForegroundColor.softenedDark,
      );
      expect(
        controller.tuning.value.balanceHeader.chartVeilColor,
        DashboardHeaderForegroundColor.black,
      );
      expect(controller.tuning.value.balanceHeader.chartVeilEnabled, isFalse);

      final mindSelector = find.byKey(
        const ValueKey<String>('dashboard-header-mind-palette-selector'),
      );
      await tester.ensureVisible(mindSelector);
      tester
          .widget<DropdownButton<MindHeaderScorePalette>>(mindSelector)
          .onChanged!(MindHeaderScorePalette.trafficColorLab);
      await tester.pump();
      expect(
        controller.tuning.value.mindScore.palette,
        MindHeaderScorePalette.trafficColorLab,
      );

      final mindTextWhite = find.byKey(
        const ValueKey<String>('dashboard-header-mind-text-white'),
      );
      final mindChartBlack = find.byKey(
        const ValueKey<String>('dashboard-header-mind-chart-black'),
      );
      for (final control in <Finder>[mindTextWhite, mindChartBlack]) {
        await tester.ensureVisible(control);
        await tester.tap(control);
      }
      await tester.pump();
      expect(
        controller.tuning.value.mindHeader.textColor,
        DashboardHeaderForegroundColor.white,
      );
      expect(
        controller.tuning.value.mindHeader.chartColor,
        DashboardHeaderForegroundColor.black,
      );
      final mindIconBlack = find.byKey(
        const ValueKey<String>('dashboard-header-mind-icon-black'),
      );
      final mindVeilSoftened = find.byKey(
        const ValueKey<String>('dashboard-header-mind-veil-softenedDark'),
      );
      for (final control in <Finder>[mindIconBlack, mindVeilSoftened]) {
        await tester.ensureVisible(control);
        await tester.tap(control);
      }
      await tester.pump();
      expect(
        controller.tuning.value.mindHeader.iconColor,
        DashboardHeaderForegroundColor.black,
      );
      expect(
        controller.tuning.value.mindHeader.chartVeilColor,
        DashboardHeaderForegroundColor.softenedDark,
      );

      final budgetIconBlack = find.byKey(
        const ValueKey<String>('dashboard-header-budget-icon-black'),
      );
      expect(budgetIconBlack, findsOneWidget);
      controller.setBudgetHeaderIconColor(DashboardHeaderForegroundColor.black);
      await tester.pump();
      expect(
        controller.tuning.value.budgetHeader.iconColor,
        DashboardHeaderForegroundColor.black,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets(
    'BALANCE-PRESENTATION-TUNER: chart controls remain while retired geometry controls are absent',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      final balance = BalancePresentationController();
      addTearDown(balance.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 1800,
            child: DashboardHeaderVisualTuner(
              controller: controller,
              balancePresentationSettings: balance,
            ),
          ),
        ),
      );

      final adaptive = find.byKey(
        const ValueKey<String>('balance-header-chart-mode-adaptiveSummary'),
      );
      await tester.ensureVisible(adaptive);
      await tester.tap(adaptive);
      await tester.pump();
      expect(balance.value.chartMode, BalanceHeaderChartMode.adaptiveSummary);

      final labels = find.byKey(
        const ValueKey<String>(
          'balance-header-history-chart-time-labels-hidden',
        ),
      );
      await tester.ensureVisible(labels);
      await tester.tap(labels);
      await tester.pump();
      expect(balance.value.timeLabels, BalanceHeaderChartTimeLabels.hidden);

      final latestDefault = find.byKey(
        const ValueKey<String>(
          'balance-latest-card-presentation-avatarPartner',
        ),
      );
      await tester.ensureVisible(latestDefault);
      expect(latestDefault, findsOneWidget);
      final latestThreeLine = find.byKey(
        const ValueKey<String>('balance-latest-card-presentation-threeLine'),
      );
      await tester.tap(latestThreeLine);
      await tester.pump();
      expect(
        balance.value.latestTransactionCardPresentation,
        BalanceLatestTransactionCardPresentation.threeLine,
      );

      expect(
        find.byKey(const ValueKey<String>('balance-carousel-width-boost')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-carousel-spacing')),
        findsNothing,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('BottomNav layout style is default-raised and tuner-selectable', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final shell = DashboardShellPresentationController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 2400,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            shellPresentation: shell,
          ),
        ),
      ),
    );

    expect(
      shell.value.bottomNavLayoutStyle,
      DashboardBottomNavLayoutStyle.raisedFab,
    );
    final contained = find.byKey(
      const ValueKey<String>(
        'dashboard-bottom-nav-layout-DashboardBottomNavLayoutStyle.containedFlat',
      ),
    );
    await tester.ensureVisible(contained);
    await tester.tap(contained);
    await tester.pump();
    expect(
      shell.value.bottomNavLayoutStyle,
      DashboardBottomNavLayoutStyle.containedFlat,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    shell.dispose();
  });

  testWidgets(
    'HTF-04/HTY-01 RED: the real tuner exposes softened foregrounds and Header typography',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      await tester.binding.setSurfaceSize(const Size(800, 1200));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            child: DashboardHeaderVisualTuner(controller: controller),
          ),
        ),
      );

      final app = find.byKey(
        const ValueKey<String>('dashboard-header-typography-app'),
      );
      final colorLab = find.byKey(
        const ValueKey<String>('dashboard-header-typography-colorLab'),
      );
      for (final control in <Finder>[app, colorLab]) {
        await tester.ensureVisible(control);
        expect(control, findsOneWidget);
      }
      await tester.tap(colorLab);
      await tester.pump();
      expect(
        controller.tuning.value.headerTypography,
        DashboardHeaderTypographyProfile.colorLab,
      );

      final controls = <Finder>[
        find.byKey(
          const ValueKey<String>('dashboard-header-balance-text-softenedDark'),
        ),
        find.byKey(
          const ValueKey<String>('dashboard-header-balance-chart-softenedDark'),
        ),
        find.byKey(
          const ValueKey<String>('dashboard-header-mind-text-softenedDark'),
        ),
        find.byKey(
          const ValueKey<String>('dashboard-header-mind-chart-softenedDark'),
        ),
      ];
      for (final control in controls) {
        expect(control, findsOneWidget);
        await tester.scrollUntilVisible(
          control,
          120,
          scrollable: find.descendant(
            of: find.byKey(
              const ValueKey<String>('dashboard-header-visual-tuner-list'),
            ),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.tap(control);
        await tester.pump();
      }
      expect(
        controller.tuning.value.balanceHeader.textColor,
        DashboardHeaderForegroundColor.softenedDark,
      );
      expect(
        controller.tuning.value.balanceHeader.chartColor,
        DashboardHeaderForegroundColor.softenedDark,
      );
      expect(
        controller.tuning.value.mindHeader.textColor,
        DashboardHeaderForegroundColor.softenedDark,
      );
      expect(
        controller.tuning.value.mindHeader.chartColor,
        DashboardHeaderForegroundColor.softenedDark,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
    },
  );

  testWidgets('Budget content composition is session-owned and live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final cardStyle = BudgetContentCardStyleController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            budgetContentCardStyle: cardStyle,
          ),
        ),
      ),
    );

    final control = find.byKey(
      const ValueKey<String>('dashboard-budget-content-unifiedCard'),
    );
    await tester.ensureVisible(control);
    expect(control, findsOneWidget);
    expect(cardStyle.value, BudgetContentLayout.split);

    await tester.tap(control);
    await tester.pump();
    expect(cardStyle.value, BudgetContentLayout.unifiedCard);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    cardStyle.dispose();
  });

  testWidgets('independent corner scale is session-owned and live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final roundness = DashboardCornerRoundnessController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            cornerRoundness: roundness,
          ),
        ),
      ),
    );

    controller.toggleTunerSection(DashboardHeaderTunerSection.cornerRoundness);
    await tester.pump();
    final control = find.byKey(
      const ValueKey<String>('dashboard-corner-searchPill-slider'),
    );
    await tester.ensureVisible(control);
    expect(
      roundness.value.positionFor(DashboardCornerSurfaceFamily.searchPill),
      0,
    );
    tester
        .widget<Slider>(
          find.descendant(of: control, matching: find.byType(Slider)),
        )
        .onChanged!(1);
    await tester.pump();
    expect(
      roundness.value.positionFor(DashboardCornerSurfaceFamily.searchPill),
      1,
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    roundness.dispose();
  });

  testWidgets('shadow style and stepped LogBox height controls are live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final shadow = DashboardShadowStyleController();
    final height = DashboardLogBoxHeightController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            shadowStyle: shadow,
            logBoxHeight: height,
          ),
        ),
      ),
    );

    expect(shadow.value, DashboardShadowStyle.current);
    final soft = find.byKey(
      const ValueKey<String>('dashboard-shadow-style-soft'),
    );
    await tester.ensureVisible(soft);
    await tester.tap(soft);
    await tester.pump();
    expect(shadow.value, DashboardShadowStyle.soft);

    final referenceDepth = find.byKey(
      const ValueKey<String>('dashboard-shadow-style-reference3d'),
    );
    await tester.ensureVisible(referenceDepth);
    await tester.tap(referenceDepth);
    await tester.pump();
    expect(shadow.value, DashboardShadowStyle.reference3d);

    final slider = find.byKey(
      const ValueKey<String>('dashboard-logbox-height-slider'),
    );
    await tester.ensureVisible(slider);
    tester
        .widget<Slider>(
          find.descendant(of: slider, matching: find.byType(Slider)),
        )
        .onChanged!(.5);
    await tester.pump();
    expect(height.value, DashboardLogBoxHeight(.5));
    final heightSemantics = find
        .descendant(of: slider, matching: find.byType(Semantics))
        .first;
    expect(
      tester.widget<Semantics>(heightSemantics).properties.label,
      contains('LogBox magasság 50%'),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    shadow.dispose();
    height.dispose();
  });

  testWidgets('border and amount-palette controls remain independent', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final borders = DashboardBorderController();
    final palettes = DashboardLogBoxAmountPaletteController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            border: borders,
            amountPalette: palettes,
          ),
        ),
      ),
    );

    controller.toggleTunerSection(DashboardHeaderTunerSection.borders);
    await tester.pump();
    final incomeBorder = find.byKey(
      const ValueKey<String>('dashboard-border-incomeDirection'),
    );
    await tester.ensureVisible(incomeBorder);
    await tester.tap(incomeBorder);
    await tester.pump();
    expect(borders.value.incomeDirection, isTrue);
    expect(borders.value.expenseDirection, isFalse);

    controller.toggleTunerSection(
      DashboardHeaderTunerSection.logBoxAmountColours,
    );
    await tester.pump();
    final incomePalette = find.byKey(
      const ValueKey<String>('dashboard-logbox-income-palette'),
    );
    await tester.ensureVisible(incomePalette);
    final dropdown = tester
        .widget<DropdownButton<DashboardLogBoxIncomePalette>>(
          find.descendant(
            of: incomePalette,
            matching: find.byType(DropdownButton<DashboardLogBoxIncomePalette>),
          ),
        );
    dropdown.onChanged!(DashboardLogBoxIncomePalette.balanceReference);
    await tester.pump();
    expect(
      palettes.value.income,
      DashboardLogBoxIncomePalette.balanceReference,
    );
    expect(palettes.value.expense, DashboardLogBoxExpensePalette.current);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    borders.dispose();
    palettes.dispose();
  });

  testWidgets('Summary and Budget order presentation controls are live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    final summary = DashboardSummaryPresentationController();
    final budgetOrder = BudgetSectionOrderController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            summaryPresentation: summary,
            budgetSectionOrder: budgetOrder,
          ),
        ),
      ),
    );

    final separators = find.byKey(
      const ValueKey<String>('dashboard-summary-separators'),
    );
    await tester.ensureVisible(separators);
    await tester.tap(separators);
    await tester.pump();
    expect(summary.value.showSeparators, isFalse);
    expect(
      find.byKey(const ValueKey('dashboard-summary-mode-layout-largeIcon')),
      findsNothing,
      reason: 'the product has one permanently large icon-only selector',
    );

    final dynamicTrio = find.byKey(
      ValueKey<String>(
        'dashboard-summary-fling-presentation-'
        '${SummaryTemporalFlingPresentation.dynamicTrio}',
      ),
    );
    await tester.ensureVisible(dynamicTrio);
    await tester.tap(dynamicTrio);
    await tester.pump();
    expect(
      summary.value.temporalFlingPresentation,
      SummaryTemporalFlingPresentation.dynamicTrio,
    );

    final normal = find.byKey(
      ValueKey<String>(
        'dashboard-summary-segmented-orientation-'
        '${SummarySegmentedOrientation.normal}',
      ),
    );
    await tester.ensureVisible(normal);
    await tester.tap(normal);
    await tester.pump();
    expect(
      summary.value.segmentedOrientation,
      SummarySegmentedOrientation.normal,
    );

    final mirrored = find.byKey(
      ValueKey<String>(
        'dashboard-summary-segmented-orientation-'
        '${SummarySegmentedOrientation.mirrored}',
      ),
    );
    await tester.ensureVisible(mirrored);
    await tester.tap(mirrored);
    await tester.pump();
    expect(
      summary.value.segmentedOrientation,
      SummarySegmentedOrientation.mirrored,
    );

    final chartFirst = find.byKey(
      const ValueKey<String>('dashboard-budget-section-order-chartThenAvatars'),
    );
    await tester.ensureVisible(chartFirst);
    await tester.tap(chartFirst);
    await tester.pump();
    expect(budgetOrder.value, BudgetSectionOrder.chartThenAvatars);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    summary.dispose();
    budgetOrder.dispose();
  });

  testWidgets(
    'SUM controls and Header presentation settings remain independent',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      final ring = BudgetRingPresentationController();
      final header = DashboardBudgetHeaderPresentationController();
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(
              controller: controller,
              budgetRingPresentation: ring,
              budgetHeaderPresentation: header,
            ),
          ),
        ),
      );

      final arc = find.text('Színes skála + fehér szegmens');
      await tester.ensureVisible(arc);
      await tester.tap(arc);
      await tester.pump();
      expect(ring.value.sumRingStyle, BudgetSumRingStyle.coloredScaleWhiteArc);

      final accent = find.text('Egészséges szín: Kategóriaszín');
      await tester.ensureVisible(accent);
      await tester.tap(accent);
      await tester.pump();
      expect(ring.value.healthyColorMode, BudgetHealthyColorMode.targetAccent);

      header
        ..setPartitionContour(true)
        ..selectTextContrastStyle(
          DashboardHeaderTextContrastStyle.oppositeOutline,
        );
      expect(header.value.showPartitionContour, isTrue);
      expect(
        header.value.textContrastStyle,
        DashboardHeaderTextContrastStyle.oppositeOutline,
      );
      await tester.pumpWidget(const SizedBox.shrink());
      controller.dispose();
      ring.dispose();
      header.dispose();
    },
  );

  test('tuner placement always reserves the live Header plus its gap', () {
    const gap = 12.0;
    for (final headerBottom in <double>[124, 214, 346]) {
      final placement = DashboardHeaderVisualTunerPlacement.resolve(
        headerBottom: headerBottom,
        viewportHeight: 760,
        safeBottom: 24,
        gap: gap,
      );
      expect(placement.top, greaterThanOrEqualTo(headerBottom + gap));
      expect(placement.maxHeight, greaterThanOrEqualTo(0));
    }
  });

  testWidgets('controls apply Header visual settings synchronously', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );

    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-cool-position-slider'),
      ),
      findsOneWidget,
    );
    for (final entry in <({String key, void Function(double) change})>[
      (
        key: 'dashboard-header-balance-opacity-slider',
        change: controller.setBalanceHeaderOpacityPercent,
      ),
      (
        key: 'dashboard-header-mind-opacity-slider',
        change: controller.setMindHeaderOpacityPercent,
      ),
      (
        key: 'dashboard-header-budget-opacity-slider',
        change: controller.setBudgetHeaderOpacityPercent,
      ),
    ]) {
      final slider = find.byKey(ValueKey<String>(entry.key));
      await tester.ensureVisible(slider);
      tester
          .widget<Slider>(
            find.descendant(of: slider, matching: find.byType(Slider)),
          )
          .onChanged!(entry.key.contains('balance') ? 0 : 100);
    }
    await tester.pump();
    expect(controller.tuning.value.balanceHeader.opacityPercent, 0);
    expect(controller.tuning.value.mindHeader.opacityPercent, 100);
    expect(controller.tuning.value.budgetHeader.opacityPercent, 100);
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-cool-window-width-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-balance-opacity-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-mind-opacity-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-budget-opacity-slider'),
      ),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
      findsOneWidget,
    );
    expect(find.text('Kategória színskálák'), findsNothing);
    expect(controller.tuning.value.budgetCool.positionPercent, 50);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 28);
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-colour-source-category'),
      ),
      findsOneWidget,
    );

    final positionSlider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('dashboard-header-cool-position-slider'),
        ),
        matching: find.byType(Slider),
      ),
    );
    positionSlider.onChanged!(80);
    await tester.pump();
    expect(controller.tuning.value.budgetCool.positionPercent, 80);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 28);

    final widthSlider = tester.widget<Slider>(
      find.descendant(
        of: find.byKey(
          const ValueKey<String>('dashboard-header-cool-window-width-slider'),
        ),
        matching: find.byType(Slider),
      ),
    );
    widthSlider.onChanged!(100);
    await tester.pump();
    expect(controller.tuning.value.budgetCool.positionPercent, 80);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 100);
    expect(
      tester
          .widget<Slider>(
            find.descendant(
              of: find.byKey(
                const ValueKey<String>('dashboard-header-cool-position-slider'),
              ),
              matching: find.byType(Slider),
            ),
          )
          .onChanged,
      isNotNull,
      reason: 'Position stays directly controllable at a 100% window.',
    );

    // This test exercises synchronous owner wiring; its preceding opacity
    // controls intentionally scroll the bounded tuner through all three
    // mode sections. Selection gesture coverage lives in the dedicated
    // Budget tuner flow, so use the same controller intent directly here.
    controller.selectBudgetHeaderColorSource(
      DashboardBudgetHeaderColorSource.category,
    );
    await tester.pump();
    expect(
      controller.tuning.value.budgetCategory.source,
      DashboardBudgetHeaderColorSource.category,
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-cool-position-slider'),
      ),
      findsNothing,
      reason: 'Category position is data-derived, never a second user value.',
    );
    final categoryWidthControl = find.byKey(
      const ValueKey<String>('dashboard-header-category-window-width-slider'),
    );
    final categoryWidth = tester.widget<Slider>(
      find.descendant(of: categoryWidthControl, matching: find.byType(Slider)),
    );
    categoryWidth.onChanged!(42);
    await tester.pump();
    expect(controller.tuning.value.budgetCategory.windowWidthPercent, 42);

    final pulseTrigger = find.byKey(
      const ValueKey<String>('dashboard-header-pulse-trigger'),
    );
    await tester.ensureVisible(pulseTrigger);
    await tester.pump();
    await tester.tap(pulseTrigger);
    await tester.pump();
    expect(controller.pulseAmount, 1);
    controller.dispose();
  });
  testWidgets('Portal channel controls remain separate and reset live', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    controller.selectPortalEffect(
      DashboardHeaderPortalChannel.innerMotion,
      DashboardHeaderPortalMaterialEffectId.staticMatter,
    );
    controller.selectPortalEffect(
      DashboardHeaderPortalChannel.backgroundMorph,
      DashboardHeaderPortalMaterialEffectId.formingClouds,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );

    final innerTitle = find.text('PORTÁL BELSŐ MOZGÁS');
    await tester.ensureVisible(innerTitle);
    await tester.pump();
    expect(innerTitle, findsOneWidget);
    final innerEnabled = find.byKey(
      const ValueKey<String>('dashboard-header-portal-inner-enabled'),
    );
    await tester.ensureVisible(innerEnabled);
    await tester.tap(innerEnabled);
    await tester.pump();
    expect(controller.portalInnerMotion.enabled, isFalse);
    expect(controller.portalBackgroundMorph.enabled, isTrue);
    expect(
      controller.portalBackgroundMorph.effect,
      DashboardHeaderPortalMaterialEffectId.formingClouds,
    );
    await tester.tap(innerEnabled);
    await tester.pump();
    expect(controller.portalInnerMotion.enabled, isTrue);
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-portal-inner-selector'),
      ),
      findsOneWidget,
    );
    final backgroundSelector = find.byKey(
      const ValueKey<String>('dashboard-header-portal-background-selector'),
    );
    await tester.ensureVisible(backgroundSelector);
    await tester.pump();
    expect(backgroundSelector, findsOneWidget);

    final coverageControl = find.byKey(
      const ValueKey<String>('dashboard-header-portal-inner-control-coverage'),
    );
    await tester.ensureVisible(coverageControl);
    await tester.pump();
    final coverageSlider = tester.widget<Slider>(
      find.descendant(of: coverageControl, matching: find.byType(Slider)),
    );
    coverageSlider.onChanged!(70);
    await tester.pump();
    expect(
      controller.portalInnerMotion.settingsFor(
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      )['coverage'],
      70,
    );
    expect(
      controller.portalBackgroundMorph.settingsFor(
        DashboardHeaderPortalMaterialEffectId.formingClouds,
      )['density'],
      4,
    );

    final innerReset = find.byKey(
      const ValueKey<String>('dashboard-header-portal-inner-reset'),
    );
    await tester.ensureVisible(innerReset);
    await tester.pump(const Duration(milliseconds: 300));
    await tester.tap(innerReset);
    await tester.pump();
    expect(
      controller.portalInnerMotion.settingsFor(
        DashboardHeaderPortalMaterialEffectId.staticMatter,
      )['coverage'],
      34,
    );
    expect(
      controller.portalBackgroundMorph.effect,
      DashboardHeaderPortalMaterialEffectId.formingClouds,
    );
    controller.dispose();
  });

  testWidgets(
    'tap-wave controls update the shared visual state without closing the tuner',
    (tester) async {
      final controller = DashboardHeaderVisualController(vsync: tester);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 360,
            height: 520,
            child: DashboardHeaderVisualTuner(controller: controller),
          ),
        ),
      );
      final control = find.byKey(
        const ValueKey<String>(
          'dashboard-header-tap-wave-control-interactionOpacity',
        ),
      );
      await tester.ensureVisible(control);
      await tester.pump();
      final slider = tester.widget<Slider>(
        find.descendant(of: control, matching: find.byType(Slider)),
      );
      slider.onChanged!(64);
      await tester.pump();
      expect(controller.tapWaveTuning.value.valueFor('interactionOpacity'), 64);
      expect(
        find.byKey(
          const ValueKey<String>('dashboard-header-visual-tuner-list'),
        ),
        findsOneWidget,
      );
      controller.dispose();
    },
  );

  testWidgets('Deep Drift is selectable once and tunes the live shader input', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    controller.selectEffect(DashboardHeaderEffectId.deepDrift);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );

    final selector = tester.widget<DropdownButton<DashboardHeaderEffectId>>(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
    );
    expect(selector.value, DashboardHeaderEffectId.deepDrift);
    expect(find.text('Mélységi áramlás'), findsOneWidget);

    final materialSize = find.byKey(
      const ValueKey<String>('dashboard-header-effect-control-blobScale'),
    );
    await tester.ensureVisible(materialSize);
    await tester.pump();
    final slider = tester.widget<Slider>(
      find.descendant(of: materialSize, matching: find.byType(Slider)),
    );
    slider.onChanged!(1.24);
    await tester.pump();
    expect(
      controller.tuning.value.settingsFor(
        DashboardHeaderEffectId.deepDrift,
      )['blobScale'],
      1.24,
    );
    expect(
      find.byKey(const ValueKey<String>('dashboard-header-visual-tuner-list')),
      findsOneWidget,
    );
    controller.dispose();
  });

  testWidgets('family selector exposes one active classic, full-flow, or '
      'space-fabric list', (tester) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );
    expect(
      find.byKey(
        const ValueKey<String>('dashboard-header-animation-family-selector'),
      ),
      findsOneWidget,
    );
    expect(find.text('Referencia mozgás · 69d109'), findsOneWidget);
    expect(find.text('Szabad áramlás'), findsNothing);

    controller.selectAnimationFamily(
      DashboardHeaderAnimationFamily.fullFieldFlow,
    );
    await tester.pump();
    expect(controller.tuning.value.effect, DashboardHeaderEffectId.freeFlow);
    expect(find.text('Áramlás típusa'), findsNWidgets(2));
    expect(find.text('Referencia mozgás · 69d109'), findsNothing);
    final selector = tester.widget<DropdownButton<DashboardHeaderEffectId>>(
      find.byKey(const ValueKey<String>('dashboard-header-effect-selector')),
    );
    expect(selector.items!.map((item) => item.value), <DashboardHeaderEffectId>[
      DashboardHeaderEffectId.freeFlow,
      DashboardHeaderEffectId.chaoticAdvection,
      DashboardHeaderEffectId.elasticSpace,
      DashboardHeaderEffectId.braidedCurrent,
      DashboardHeaderEffectId.volumetricCurrent,
    ]);

    controller.selectAnimationFamily(
      DashboardHeaderAnimationFamily.spaceFabricWarp,
    );
    await tester.pump();
    expect(controller.tuning.value.effect, DashboardHeaderEffectId.metricBloom);
    expect(find.text('Térszövet típusa'), findsNWidgets(2));
    final spaceSelector = tester
        .widget<DropdownButton<DashboardHeaderEffectId>>(
          find.byKey(
            const ValueKey<String>('dashboard-header-effect-selector'),
          ),
        );
    expect(
      spaceSelector.items!.map((item) => item.value),
      <DashboardHeaderEffectId>[
        DashboardHeaderEffectId.metricBloom,
        DashboardHeaderEffectId.gravitationalFabric,
        DashboardHeaderEffectId.breathingMetric,
        DashboardHeaderEffectId.tidalCurvature,
      ],
    );
    controller.dispose();
  });

  testWidgets('MBS-06 Mind score window width is live and independent', (
    tester,
  ) async {
    final controller = DashboardHeaderVisualController(vsync: tester);
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 520,
          child: DashboardHeaderVisualTuner(controller: controller),
        ),
      ),
    );
    final sliderKey = const ValueKey<String>(
      'dashboard-header-mind-score-window-width-slider',
    );
    await tester.ensureVisible(find.byKey(sliderKey));
    final slider = tester.widget<Slider>(
      find.descendant(of: find.byKey(sliderKey), matching: find.byType(Slider)),
    );
    expect(controller.tuning.value.mindScore.windowWidthPercent, 28);
    slider.onChanged!(42);
    await tester.pump();
    expect(controller.tuning.value.mindScore.windowWidthPercent, 42);
    expect(controller.tuning.value.budgetCool.windowWidthPercent, 28);
    expect(controller.tuning.value.budgetCategory.windowWidthPercent, 28);
    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
  });

  testWidgets('Mind score and heatmap settings use their separate owners', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(800, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    final controller = DashboardHeaderVisualController(vsync: tester);
    final scoreSettings = MindBehavioralScoreSettingsController();
    final chartPresentation = MindHeaderScoreChartPresentationController();
    final heatmapSettings = MindYearHeatmapPresentationController();
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 360,
          height: 1500,
          child: DashboardHeaderVisualTuner(
            controller: controller,
            mindBehavioralScoreSettings: scoreSettings,
            mindHeaderScoreChartPresentation: chartPresentation,
            mindYearHeatmapPresentation: heatmapSettings,
          ),
        ),
      ),
    );

    final htmlTrailing = find.byKey(
      const ValueKey('mind-expense-score-algorithm-htmlTrailing'),
    );
    await tester.ensureVisible(htmlTrailing);
    await tester.tap(htmlTrailing);
    await tester.pump();
    expect(
      scoreSettings.value.expenseAlgorithm,
      MindExpenseScoreAlgorithm.htmlTrailing,
    );
    expect(
      tester
          .widget<RadioListTile<MindCausalHistoryOrigin>>(
            find.byKey(
              const ValueKey('mind-causal-history-origin-fullFilteredHistory'),
            ),
          )
          .enabled,
      isFalse,
    );

    final labels = find.byKey(
      const ValueKey('mind-header-score-chart-time-labels-visible'),
    );
    await tester.ensureVisible(labels);
    await tester.tap(labels);
    await tester.pump();
    expect(
      chartPresentation.value.timeLabels,
      MindHeaderScoreChartTimeLabels.visible,
    );
    for (final style in MindYearHeatmapPaletteStyle.values) {
      final palette = find.byKey(
        ValueKey('mind-heatmap-palette-${style.name}'),
      );
      await tester.ensureVisible(palette);
      await tester.tap(palette);
      await tester.pump();
      expect(heatmapSettings.value.paletteStyle, style);
    }
    for (final resolution in MindHeatmapScaleResolution.values) {
      final scale = find.byKey(
        ValueKey('mind-heatmap-scale-resolution-${resolution.name}'),
      );
      await tester.ensureVisible(scale);
      await tester.tap(scale);
      await tester.pump();
      expect(heatmapSettings.value.scaleResolution, resolution);
    }
    for (final layout in MindDayTimelineLayout.values) {
      final dayLayout = find.byKey(
        ValueKey('mind-day-timeline-layout-${layout.name}'),
      );
      await tester.ensureVisible(dayLayout);
      await tester.tap(dayLayout);
      await tester.pump();
      expect(heatmapSettings.value.dayTimelineLayout, layout);
    }
    for (final count in MindSumVisibleChartCount.values) {
      final density = find.byKey(
        ValueKey('mind-sum-visible-chart-count-${count.name}'),
      );
      await tester.ensureVisible(density);
      await tester.tap(density);
      await tester.pump();
      expect(heatmapSettings.value.sumVisibleChartCount, count);
    }
    final profitabilityToggle = find.byKey(
      const ValueKey<String>('mind-year-profitability-tint-enabled'),
    );
    await tester.ensureVisible(profitabilityToggle);
    await tester.tap(profitabilityToggle);
    await tester.pump();
    expect(
      heatmapSettings.value.yearThreeColumnProfitabilityTintEnabled,
      isTrue,
    );
    final profitabilityOpacity = find.byKey(
      const ValueKey<String>('mind-year-profitability-tint-opacity'),
    );
    await tester.ensureVisible(profitabilityOpacity);
    tester
        .widget<Slider>(
          find.descendant(
            of: profitabilityOpacity,
            matching: find.byType(Slider),
          ),
        )
        .onChanged!(.38);
    await tester.pump();
    expect(
      heatmapSettings.value.yearThreeColumnProfitabilityTintOpacity,
      closeTo(.38, .0001),
    );
    final cardBorder = find.byKey(
      const ValueKey<String>('mind-year-month-card-border-enabled'),
    );
    tester
        .widget<Switch>(
          find.descendant(of: cardBorder, matching: find.byType(Switch)),
        )
        .onChanged!(false);
    await tester.pump();
    expect(heatmapSettings.value.yearMonthCardBorderEnabled, isFalse);
    final catmull = find.byKey(
      const ValueKey<String>('mind-sum-line-interpolation-catmullRom'),
    );
    await tester.ensureVisible(catmull);
    await tester.tap(catmull);
    await tester.pump();
    expect(
      heatmapSettings.value.sumLineInterpolationMode,
      MindSumLineInterpolationMode.catmullRom,
    );
    final tension = find.byKey(
      const ValueKey<String>('mind-sum-line-catmull-rom-tension'),
    );
    await tester.ensureVisible(tension);
    tester
        .widget<Slider>(
          find.descendant(of: tension, matching: find.byType(Slider)),
        )
        .onChanged!(.61);
    final smoothing = find.byKey(
      const ValueKey<String>('mind-sum-line-smoothing-enabled'),
    );
    await tester.ensureVisible(smoothing);
    await tester.tap(smoothing);
    final window = find.byKey(
      const ValueKey<String>('mind-sum-line-smoothing-window-days7'),
    );
    await tester.ensureVisible(window);
    await tester.tap(window);
    final adaptive = find.byKey(
      const ValueKey<String>('mind-sum-line-zoom-adaptive-smoothing-enabled'),
    );
    await tester.ensureVisible(adaptive);
    await tester.tap(adaptive);
    await tester.pump();
    expect(heatmapSettings.value.sumLineCatmullRomTension, closeTo(.61, .0001));
    expect(heatmapSettings.value.sumLineTemporalSmoothingEnabled, isTrue);
    expect(
      heatmapSettings.value.sumLineSmoothingWindow,
      MindSumSmoothingWindow.days7,
    );
    expect(heatmapSettings.value.sumLineZoomAdaptiveSmoothingEnabled, isTrue);
    expect(
      find.byKey(const ValueKey('mind-heatmap-legend-toggle')),
      findsNothing,
      reason: 'The final Mind legend is permanently inline, not tunable.',
    );
    expect(
      find.byKey(const ValueKey('mind-heatmap-legend-placement-aboveSlider')),
      findsNothing,
    );
    expect(
      find.byKey(
        const ValueKey(
          'mind-heatmap-legend-placement-inlineBetweenRangeValues',
        ),
      ),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('mind-heatmap-layout-fourColumns')),
      findsNothing,
      reason: 'Annual grid layout is now local to the Year card header.',
    );
    expect(
      find.byKey(const ValueKey('mind-heatmap-monthly-net-toggle')),
      findsNothing,
    );
    expect(
      find.byKey(const ValueKey('mind-heatmap-annual-surface-directCells')),
      findsNothing,
    );
    expect(controller.tuning.value.mindScore.windowWidthPercent, 28);

    await tester.pumpWidget(const SizedBox.shrink());
    controller.dispose();
    scoreSettings.dispose();
    chartPresentation.dispose();
    heatmapSettings.dispose();
  });
}
