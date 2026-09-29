import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/catalog/category_color_catalog.dart';
import 'package:fluvi/core/categories/presentation/category_avatar_palette_catalog.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_global_appearance.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/core/diagnostics/fluvi_diagnostic_logger.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_entity_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_border_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_category_movers_visual_tokens.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart';
import 'package:fluvi/core/design/dashboard_border_profile.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

void main() {
  // The physical default intentionally runs the ambient wave. Most surface
  // tests verify static geometry and use pumpAndSettle, so model the platform
  // reduced-motion preference unless a test explicitly owns the wave clock.
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized()
        .platformDispatcher
        .accessibilityFeaturesTestValue = const FakeAccessibilityFeatures(
      disableAnimations: true,
    );
  });
  tearDown(() {
    TestWidgetsFlutterBinding.ensureInitialized().platformDispatcher
        .clearAccessibilityFeaturesTestValue();
  });

  testWidgets(
    'Balance Header foreground frame changes text without balance data work',
    (tester) async {
      final visual = DashboardHeaderVisualController(vsync: tester)
        ..selectEffect(DashboardHeaderEffectId.staticEffect);
      final frame = ValueNotifier<DashboardHeaderVisualFrame>(
        const DashboardHeaderVisualFrame(
          colors: <Color>[Colors.red, Colors.red],
          stops: <double>[0, 1],
          opacity: 1,
          colorA: Colors.red,
          colorB: Colors.red,
          foregroundTextColor: Colors.black,
          chartColor: Colors.white,
        ),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'balance|all',
          coreRevision: 1,
          incomeTotalMinor: 120000,
          expenseTotalMinor: 20000,
          netTotalMinor: 100000,
          formattedNetTotal: '1 000 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'latest',
            title: 'Teszt',
            formattedAmount: '1 000 Ft',
            direction: LedgerDirection.income,
            occurredOrder: 1,
          ),
        ),
      );
      final mode = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: mode,
              balancePresentation: balance,
              headerVisualController: visual,
              headerVisualFrame: frame,
            ),
          ),
        ),
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style!
            .color,
        Colors.black,
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style!
            .fontFamily,
        'Roboto',
      );
      final before = balance.value;
      frame.value = const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Colors.white,
        chartColor: Colors.black,
      );
      await tester.pump();
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style!
            .color,
        Colors.white,
      );
      frame.value = const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Color(0xD114213A),
        chartColor: Colors.black,
        typography: FluviTypographyProfile.colorLab,
      );
      await tester.pump();
      final colorLabAmount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(colorLabAmount.style!.color, const Color(0xD114213A));
      expect(colorLabAmount.style!.fontFamily, 'FluviColorLabInter');
      final headerBeforeModeLabel = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-header'),
        ),
      );
      frame.value = const DashboardHeaderVisualFrame(
        colors: <Color>[Colors.red, Colors.red],
        stops: <double>[0, 1],
        opacity: 1,
        colorA: Colors.red,
        colorB: Colors.red,
        foregroundTextColor: Color(0xD114213A),
        chartColor: Colors.black,
        typography: FluviTypographyProfile.colorLab,
        showsHeaderModeLabelAboveValue: true,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-header-mode-label')),
        findsOneWidget,
      );
      final balanceAmountTop = tester.getTopLeft(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(
        balanceAmountTop.dy,
        closeTo(
          headerBeforeModeLabel.top +
              DashboardHeaderTrendChartStyle.detailTop +
              DashboardHeaderTrendChartLayout.modeLabelReserve,
          .01,
        ),
      );
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('dashboard-core-mode-balance-header'),
          ),
        ),
        headerBeforeModeLabel,
      );
      expect(balance.value, same(before));
      await tester.pumpWidget(const SizedBox.shrink());
      visual.dispose();
      frame.dispose();
      balance.dispose();
    },
  );

  test('BX1: Balance has eleven real linked topics and no prototype', () {
    expect(
      balanceCarouselCardsFor(null).map((card) => card.kind),
      <BalanceCarouselCardKind>[
        BalanceCarouselCardKind.cashflow,
        BalanceCarouselCardKind.closings,
        BalanceCarouselCardKind.momentum,
        BalanceCarouselCardKind.retention,
        BalanceCarouselCardKind.stability,
        BalanceCarouselCardKind.ghost,
        BalanceCarouselCardKind.forecast,
        BalanceCarouselCardKind.latestTransaction,
        BalanceCarouselCardKind.categoryMovers,
        BalanceCarouselCardKind.topCategory,
        BalanceCarouselCardKind.topPartner,
      ],
    );
  });

  test(
    'BAL-UNI-01/TET-01: Balance surface choices default separately and remain presentation-only',
    () {
      final controller = BalancePresentationController();
      addTearDown(controller.dispose);

      expect(
        controller.value.contentSurfaceStyle,
        BalanceContentSurfaceStyle.separateCards,
      );
      expect(
        controller.value.unifiedBodyLayout,
        BalanceUnifiedBodyLayout.currentCarouselDetail,
      );
      controller
        ..setContentSurfaceStyle(BalanceContentSurfaceStyle.unifiedCard)
        ..setUnifiedBodyLayout(BalanceUnifiedBodyLayout.fourSectionTetris);
      expect(controller.value.revision, 2);
      controller.reset();
      expect(
        controller.value.contentSurfaceStyle,
        BalanceContentSurfaceStyle.separateCards,
      );
      expect(
        controller.value.unifiedBodyLayout,
        BalanceUnifiedBodyLayout.currentCarouselDetail,
      );
    },
  );

  testWidgets(
    'BAL-UNI-02/TET-03/ALT2-02: unified surface routes SUM through five sections and preserves selected topic',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = BalancePresentationController()
        ..setContentSurfaceStyle(BalanceContentSurfaceStyle.unifiedCard);
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      final mode = _balanceModePresentation();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: mode,
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      final unified = find.byKey(
        const ValueKey<String>('balance-unified-header-content-surface'),
      );
      expect(unified, findsOneWidget);
      final unifiedRect = tester.getRect(unified);
      expect(unifiedRect.top, closeTo(mode.geometry.headerBounds.top, .01));
      expect(
        unifiedRect.bottom,
        closeTo(mode.geometry.subheaderEnvelopeBounds.bottom, .01),
        reason:
            'The seamless Balance Mother Card ends at the same Header/content '
            'envelope boundary as Mind, not after the indicator lane.',
      );
      expect(
        find.byKey(const ValueKey<String>('balance-primary-card')),
        findsNothing,
      );

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(9);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-top-category'),
        ),
        findsOneWidget,
      );

      settings.setUnifiedBodyLayout(BalanceUnifiedBodyLayout.fourSectionTetris);
      await tester.pump();
      for (final index in <int>[1, 2, 3, 4, 5]) {
        expect(
          find.byKey(ValueKey<String>('balance-tetris-card-$index')),
          findsOneWidget,
        );
      }
      final card1Slot = tester.getRect(
        find.byKey(const ValueKey<String>('balance-tetris-slot-1')),
      );
      final card2Slot = tester.getRect(
        find.byKey(const ValueKey<String>('balance-tetris-slot-2')),
      );
      final card3Slot = tester.getRect(
        find.byKey(const ValueKey<String>('balance-tetris-slot-3')),
      );
      final card4Slot = tester.getRect(
        find.byKey(const ValueKey<String>('balance-tetris-slot-4')),
      );
      final card5Slot = tester.getRect(
        find.byKey(const ValueKey<String>('balance-tetris-slot-5')),
      );
      final bodyWidth = card3Slot.width + card4Slot.width;
      final bodyHeight = card3Slot.height + card1Slot.height;
      expect(card3Slot.width / bodyWidth, closeTo(.70, .001));
      expect(card4Slot.width / bodyWidth, closeTo(.30, .001));
      expect(card1Slot.width / bodyWidth, closeTo(.50, .001));
      expect(card2Slot.width / bodyWidth, closeTo(.50, .001));
      expect(card3Slot.height / bodyHeight, closeTo(.60, .001));
      expect(card4Slot.height / bodyHeight, closeTo(.30, .001));
      expect(card5Slot.height / bodyHeight, closeTo(.30, .001));
      expect(card1Slot.height / bodyHeight, closeTo(.40, .001));
      expect(card2Slot.height / bodyHeight, closeTo(.40, .001));
      expect(card3Slot.bottom, closeTo(card1Slot.top, .01));
      expect(card4Slot.bottom, closeTo(card5Slot.top, .01));
      expect(card5Slot.bottom, closeTo(card2Slot.top, .01));
      expect(card4Slot.right, closeTo(card2Slot.right, .01));
      expect(card5Slot.right, closeTo(card2Slot.right, .01));
      expect(card1Slot.bottom, closeTo(card2Slot.bottom, .01));
      expect(find.text('Bevétel / Kiadás'), findsOneWidget);
      expect(find.byType(CenteredCarousel<BalanceCarouselCard>), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-top-category'),
        ),
        findsNothing,
      );
      expect(tester.getRect(unified), unifiedRect);

      settings.setUnifiedBodyLayout(
        BalanceUnifiedBodyLayout.currentCarouselDetail,
      );
      await tester.pump();
      expect(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-top-category'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'VIS-BAL-UNI: separate and unified Header/content surfaces retain their distinct physical contracts',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      final mode = _balanceModePresentation(
        metrics: DashboardLayoutMetrics.reference.fitToViewport(
          const Size(412, 892),
        ),
      );

      Future<void> pumpSurface() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('balance-surface-golden-boundary'),
              child: SizedBox.expand(
                child: BalanceDashboardCoreSurface(
                  presentation: mode,
                  balanceLinkedPresentation: linked,
                  presentationSettings: settings,
                ),
              ),
            ),
          ),
        ),
      );

      await pumpSurface();
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey<String>('balance-surface-golden-boundary')),
        matchesGoldenFile('../../../goldens/balance_separate_surface.png'),
      );

      settings.setContentSurfaceStyle(BalanceContentSurfaceStyle.unifiedCard);
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey<String>('balance-surface-golden-boundary')),
        matchesGoldenFile('../../../goldens/balance_unified_surface.png'),
      );

      settings.setUnifiedBodyLayout(BalanceUnifiedBodyLayout.fourSectionTetris);
      await tester.pump();
      await expectLater(
        find.byKey(const ValueKey<String>('balance-surface-golden-boundary')),
        matchesGoldenFile('../../../goldens/balance_tetris_scaffold.png'),
      );
    },
  );

  testWidgets(
    'ALT2-04/06: SUM retains five slots, while Year and Havi 2 resolve their HTML extended-sheet bodies and Day stays four-slot',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(cashflow: _alternativeYearCashflow()),
      );
      final settings = BalancePresentationController()
        ..setContentSurfaceStyle(BalanceContentSurfaceStyle.unifiedCard)
        ..setUnifiedBodyLayout(BalanceUnifiedBodyLayout.fourSectionTetris);
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey<String>('balance-alternative-year-layout')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-plot-scroll'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-year-closings-plot'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-alternative-year-income-expense-bars',
          ),
        ),
        findsOneWidget,
      );

      linked.value = _linked(cashflow: _alternativeMonthCashflow());
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-5')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-month-daily-spend-plot'),
        ),
        findsOneWidget,
      );

      linked.value = _linked(cashflow: _alternativeDayCashflow());
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-tetris-card-5')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        findsNothing,
      );
    },
  );

  testWidgets(
    'SHEET-01/02: 412×892 Havi 2 and Éves cards use direct HTML-scale content instead of a card-wide fallback',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _richAlternativeMonthLinked(),
      );
      final settings = BalancePresentationController()
        ..setContentSurfaceStyle(BalanceContentSurfaceStyle.unifiedCard)
        ..setUnifiedBodyLayout(BalanceUnifiedBodyLayout.fourSectionTetris);
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      final metrics = DashboardLayoutMetrics.reference.fitToViewport(
        const Size(412, 892),
      );
      final mode = _balanceModePresentation(
        metrics: metrics,
        hasPhysicalRail: false,
      );

      Future<void> pumpSurface() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('balance-alternative-sheet-golden'),
              child: SizedBox.expand(
                child: BalanceDashboardCoreSurface(
                  presentation: mode,
                  balanceLinkedPresentation: linked,
                  presentationSettings: settings,
                ),
              ),
            ),
          ),
        ),
      );

      Finder cardWideFallback() => find.byWidgetPredicate((widget) {
        if (widget is! FittedBox || widget.fit != BoxFit.contain) {
          return false;
        }
        final child = widget.child;
        return child is SizedBox && child.width != null && child.height != null;
      });

      await pumpSurface();
      await tester.pump();
      final canonicalMother = DashboardHeaderContentMotherCardBounds.resolve(
        geometry: _balanceModePresentation(
          metrics: metrics,
          hasPhysicalRail: false,
        ).geometry,
      );
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('balance-unified-header-content-surface'),
          ),
        ),
        Rect.fromLTWH(
          canonicalMother.left,
          canonicalMother.top,
          canonicalMother.width,
          canonicalMother.height,
        ),
        reason: 'Havi 2 uses the Balance SUM Mother Card frame.',
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-month-daily-spend-plot'),
        ),
        findsOneWidget,
      );
      expect(
        cardWideFallback(),
        findsNothing,
        reason:
            'The Havi 2 allocation at the reference viewport must keep its '
            'CSS-derived type and plot dimensions without a whole-card scale '
            'fallback.',
      );
      _expectHtmlCardSurfaceSizes(tester);
      await expectLater(
        find.byKey(const ValueKey<String>('balance-alternative-sheet-golden')),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_havi2_surface.png',
        ),
      );

      linked.value = _richAlternativeYearLinked();
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-year-closings-plot'),
        ),
        findsOneWidget,
      );
      expect(
        cardWideFallback(),
        findsNothing,
        reason:
            'The Éves allocation at the reference viewport must keep both '
            'charts and their labels at their authored scale.',
      );
      _expectHtmlCardSurfaceSizes(tester);
      await expectLater(
        find.byKey(const ValueKey<String>('balance-alternative-sheet-golden')),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_eves_surface.png',
        ),
      );
    },
  );

  testWidgets(
    'ALT-MOTHER-UI: hiding the unified mother surface preserves the alternative body allocation and data path',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = BalancePresentationController()
        ..setContentSurfaceStyle(BalanceContentSurfaceStyle.unifiedCard)
        ..setUnifiedBodyLayout(BalanceUnifiedBodyLayout.fourSectionTetris);
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-unified-header-content-surface'),
        ),
        findsOneWidget,
      );
      final card3Before = tester.getRect(
        find.byKey(const ValueKey<String>('balance-tetris-slot-3')),
      );

      settings.setAlternativeMotherCardVisible(false);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-unified-header-content-surface'),
        ),
        findsNothing,
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey<String>('balance-tetris-slot-3')),
        ),
        card3Before,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        findsOneWidget,
      );
    },
  );

  test(
    'BCV-RED: visibility is resolved before carousel membership and selected fallback follows canonical right then left order',
    () {
      const defaults = BalancePresentationSettings.defaults();
      expect(
        visibleBalanceCarouselCardKindsFor(defaults),
        BalanceCarouselCardKind.values,
      );
      final unrelatedHidden = defaults.copyWith(
        hiddenBalanceCarouselCardKinds: <BalanceCarouselCardKind>{
          BalanceCarouselCardKind.forecast,
        },
      );
      expect(
        visibleBalanceCarouselCardKindsFor(unrelatedHidden),
        isNot(contains(BalanceCarouselCardKind.forecast)),
      );
      expect(
        resolveVisibleBalanceCarouselCardKind(
          selected: BalanceCarouselCardKind.stability,
          settings: unrelatedHidden,
        ),
        BalanceCarouselCardKind.stability,
      );
      final selectedHidden = defaults.copyWith(
        hiddenBalanceCarouselCardKinds: <BalanceCarouselCardKind>{
          BalanceCarouselCardKind.stability,
        },
      );
      expect(
        resolveVisibleBalanceCarouselCardKind(
          selected: BalanceCarouselCardKind.stability,
          settings: selectedHidden,
        ),
        BalanceCarouselCardKind.ghost,
      );
      final terminalHidden = defaults.copyWith(
        hiddenBalanceCarouselCardKinds: <BalanceCarouselCardKind>{
          BalanceCarouselCardKind.topPartner,
        },
      );
      expect(
        resolveVisibleBalanceCarouselCardKind(
          selected: BalanceCarouselCardKind.topPartner,
          settings: terminalHidden,
        ),
        BalanceCarouselCardKind.topCategory,
      );
    },
  );

  testWidgets(
    'BCV-RED: visible membership drives carousel, detail, and indicators including one/two-card states',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: BalanceDashboardCoreSurface(
                presentation: _balanceModePresentation(
                  metrics: DashboardLayoutMetrics.reference.fitToViewport(
                    const Size(412, 892),
                  ),
                ),
                balanceLinkedPresentation: linked,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      CenteredCarousel<BalanceCarouselCard> carousel() =>
          tester.widget<CenteredCarousel<BalanceCarouselCard>>(
            find.byType(CenteredCarousel<BalanceCarouselCard>),
          );

      expect(carousel().dataSource!.finiteLength, 11);
      settings.setBalanceCarouselCardVisible(
        BalanceCarouselCardKind.forecast,
        false,
      );
      await tester.pump();
      expect(carousel().dataSource!.finiteLength, 10);
      expect(
        find.byKey(
          const ValueKey<String>('balance-insight-indicator-forecast'),
        ),
        findsNothing,
      );

      expect(carousel().controller.selectedIndex, 0);
      expect(carousel().controller.onSelectedChanged, isNotNull);
      carousel().controller.jumpToIndex(4);
      await tester.pump();
      expect(carousel().controller.selectedIndex, 4);
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-stability')),
        findsOneWidget,
      );
      settings.setBalanceCarouselCardVisible(
        BalanceCarouselCardKind.stability,
        false,
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-ghost')),
        findsOneWidget,
        reason: 'Hidden selected Stability resolves to its next visible topic.',
      );

      for (final kind in BalanceCarouselCardKind.values) {
        if (kind == BalanceCarouselCardKind.cashflow ||
            kind == BalanceCarouselCardKind.closings) {
          continue;
        }
        settings.setBalanceCarouselCardVisible(kind, false);
      }
      await tester.pump();
      expect(carousel().dataSource!.finiteLength, 2);
      expect(carousel().dataSource!.mode, CenteredCarouselDataMode.bounded);
      settings.setBalanceCarouselCardVisible(
        BalanceCarouselCardKind.closings,
        false,
      );
      await tester.pump();
      expect(carousel().dataSource!.finiteLength, 1);
      expect(carousel().dataSource!.mode, CenteredCarouselDataMode.bounded);
      expect(
        find.byKey(
          const ValueKey<String>('balance-insight-indicator-cashflow'),
        ),
        findsOneWidget,
      );
      expect(
        settings.setBalanceCarouselCardVisible(
          BalanceCarouselCardKind.cashflow,
          false,
        ),
        isFalse,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BCV-INIT-RED: an initially hidden default topic is reconciled before the first Balance frame',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = BalancePresentationController()
        ..setBalanceCarouselCardVisible(
          BalanceCarouselCardKind.cashflow,
          false,
        );
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: BalanceDashboardCoreSurface(
                presentation: _balanceModePresentation(
                  metrics: DashboardLayoutMetrics.reference.fitToViewport(
                    const Size(412, 892),
                  ),
                ),
                balanceLinkedPresentation: linked,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-closings')),
        findsOneWidget,
        reason:
            'The initial Cashflow selection is hidden, so the first visible '
            'canonical card must own both carousel and detail state.',
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-cashflow')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-insight-indicator-cashflow'),
        ),
        findsNothing,
      );
    },
  );

  test(
    'BX5 RED: Closings compact fraction uses strict-positive bucket DTOs',
    () {
      final summary = balanceClosingsCompactSummary(
        DashboardBalanceClosingsPresentation(
          identity: const DashboardBalancePrimaryIdentity(
            upstreamScopeKey: 'closings',
            indexGeneration: 1,
            coreRevision: 1,
          ),
          timeScope: const YearScope(2026),
          buckets: const <DashboardBalanceClosingBucket>[
            DashboardBalanceClosingBucket(
              id: 'one',
              label: 'JAN',
              incomeMinor: 100,
              expenseMinor: 0,
            ),
            DashboardBalanceClosingBucket(
              id: 'two',
              label: 'FEB',
              incomeMinor: 0,
              expenseMinor: 0,
            ),
            DashboardBalanceClosingBucket(
              id: 'three',
              label: 'MÁR',
              incomeMinor: 0,
              expenseMinor: 30,
            ),
            DashboardBalanceClosingBucket(
              id: 'four',
              label: 'ÁPR',
              incomeMinor: 80,
              expenseMinor: 0,
            ),
          ],
        ),
      );
      expect(summary, '2 / 12 hónap pluszos');

      final empty = DashboardBalanceClosingsPresentation(
        identity: const DashboardBalancePrimaryIdentity(
          upstreamScopeKey: 'empty-closings',
          indexGeneration: 1,
          coreRevision: 1,
        ),
        timeScope: const AllTimeScope(),
        buckets: const <DashboardBalanceClosingBucket>[],
      );
      expect(balanceClosingsCompactSummary(empty), 'Nincs adat');
    },
  );

  test(
    'BCL-RED-01: every carousel topic supplies the canonical primary and secondary preview copy',
    () {
      final cards = balanceCarouselCardsFor(
        _linked(categoryMovers: _moverPresentation()),
      );
      final byId = <String, BalanceCarouselCard>{
        for (final card in cards) card.id: card,
      };

      expect(byId['latest-transaction']!.amount, 'Piac');
      expect(byId['latest-transaction']!.detail, '350 Ft');
      expect(byId['top-category']!.amount, 'Fizetés');
      expect(byId['top-category']!.detail, '7 k Ft');
      expect(byId['top-partner']!.amount, 'Munkahely');
      expect(byId['top-partner']!.detail, '7 k Ft');
      expect(
        byId['category-movers']!.detail,
        '+117%',
        reason: 'The mover secondary line must be the percentage only.',
      );
      for (final id in <String>[
        'cashflow',
        'closings',
        'momentum',
        'retention',
        'stability',
        'ghost',
        'forecast',
      ]) {
        expect(
          byId[id]!.detail,
          isNotNull,
          reason: '$id must participate in the same two-line grammar.',
        );
      }
    },
  );

  testWidgets(
    'BCL-02: every selected Balance topic renders one title, visual, primary and secondary mini-card structure',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(categoryMovers: _moverPresentation()),
      );
      addTearDown(linked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: BalanceDashboardCoreSurface(
                presentation: _balanceModePresentation(
                  metrics: DashboardLayoutMetrics.reference.fitToViewport(
                    const Size(412, 892),
                  ),
                ),
                balanceLinkedPresentation: linked,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final cards =
          (carousel.dataSource!
                  as CyclicCarouselDataSource<BalanceCarouselCard>)
              .items;
      for (var index = 0; index < cards.length; index += 1) {
        final card = cards[index];
        carousel.controller.jumpToIndex(index);
        await tester.pump();
        for (final part in <String>[
          'title',
          'visual',
          'primary',
          'secondary',
        ]) {
          expect(
            find.byKey(
              ValueKey<String>('balance-carousel-card-$part-${card.id}'),
            ),
            findsOneWidget,
            reason: '${card.id} must keep the canonical $part slot.',
          );
        }
      }
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BCL-03: the selected carousel card preserves the approved title-avatar-two-line visual grammar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(categoryMovers: _moverPresentation()),
      );
      addTearDown(linked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  const Size(412, 892),
                ),
              ),
              balanceLinkedPresentation: linked,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(9);
      await tester.pumpAndSettle();

      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-carousel-card-top-category'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_carousel_canonical_layout.png',
        ),
      );
    },
  );

  testWidgets(
    'MOVERS-CORE-COMPACT: the real inherited lower envelope keeps both local pages overflow-free',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(categoryMovers: _moverPresentation()),
      );
      addTearDown(linked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  const Size(412, 892),
                ),
              ),
              balanceLinkedPresentation: linked,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(8);
      await tester.pump();

      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-category-movers'),
        ),
        findsOneWidget,
      );
      for (final id in <String>[
        'housing',
        'transport',
        'food',
        'health',
        'leisure',
      ]) {
        expect(
          find.byKey(ValueKey<String>('balance-category-mover-$id')),
          findsOneWidget,
          reason:
              'The real lower-card envelope must expose every bounded Top 5 row.',
        );
      }
      expect(tester.takeException(), isNull);
      final primaryCard = find.byKey(
        const ValueKey<String>('balance-primary-card'),
      );
      final primaryCardBounds = tester.getRect(primaryCard);
      expect(
        tester.getSize(primaryCard).height,
        lessThan(445),
        reason:
            'The compact Movers pages preserve the existing lower-card bounds.',
      );
      for (final id in <String>[
        'housing',
        'transport',
        'food',
        'health',
        'leisure',
      ]) {
        expect(
          tester
              .getRect(
                find.byKey(ValueKey<String>('balance-category-mover-$id')),
              )
              .bottom,
          lessThanOrEqualTo(primaryCardBounds.bottom),
          reason:
              '$id must remain visible inside the real primary-card bounds.',
        );
      }
      final moversShell = tester.widget<FluviRoundedBox>(
        find.descendant(
          of: find.byKey(const ValueKey<String>('balance-primary-card')),
          matching: find.byType(FluviRoundedBox),
        ),
      );
      expect(
        moversShell.borderRadius,
        BorderRadius.circular(BalanceCategoryMoversVisualTokens.outerRadius),
        reason:
            'The reference-locked Movers shell owns the required 22px contour.',
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-mover-housing')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-movers-detail')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-category-movers-cumulative-chart'),
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'RCR-RED-01: every Balance mini card uses the reference-locked shell, lower wave, and top-right tile grammar',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(categoryMovers: _moverPresentation()),
      );
      addTearDown(linked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  const Size(412, 892),
                ),
              ),
              balanceLinkedPresentation: linked,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final cards =
          (carousel.dataSource!
                  as CyclicCarouselDataSource<BalanceCarouselCard>)
              .items;
      for (var index = 0; index < cards.length; index += 1) {
        final card = cards[index];
        carousel.controller.jumpToIndex(index);
        await tester.pump();
        final cardRect = tester.getRect(
          find.byKey(ValueKey<String>('balance-carousel-card-${card.id}')),
        );
        final titleRect = tester.getRect(
          find.byKey(
            ValueKey<String>('balance-carousel-card-title-${card.id}'),
          ),
        );
        final primaryRect = tester.getRect(
          find.byKey(
            ValueKey<String>('balance-carousel-card-primary-${card.id}'),
          ),
        );
        final secondaryRect = tester.getRect(
          find.byKey(
            ValueKey<String>('balance-carousel-card-secondary-${card.id}'),
          ),
        );
        final tileRect = tester.getRect(
          find.byKey(
            ValueKey<String>('balance-carousel-card-icon-tile-${card.id}'),
          ),
        );

        expect(
          find.byKey(
            ValueKey<String>(
              'balance-carousel-card-reference-shell-${card.id}',
            ),
          ),
          findsOneWidget,
        );
        expect(
          find.byKey(
            ValueKey<String>('balance-carousel-card-reference-wave-${card.id}'),
          ),
          findsOneWidget,
        );
        final waveFinder = find.byKey(
          ValueKey<String>('balance-carousel-card-reference-wave-${card.id}'),
        );
        final decorationStack = tester.widget<Stack>(
          find.byKey(
            ValueKey<String>(
              'balance-carousel-card-decoration-stack-${card.id}',
            ),
          ),
        );
        expect(
          decorationStack.children.map((child) => child.key).toList(),
          <Key>[
            ValueKey<String>('balance-carousel-card-reference-tint-${card.id}'),
            ValueKey<String>('balance-carousel-card-wave-layer-${card.id}'),
            ValueKey<String>('balance-carousel-card-content-layer-${card.id}'),
            ValueKey<String>('balance-carousel-card-outline-layer-${card.id}'),
          ],
          reason: 'Tint, wave, content, then crisp outline is the paint order.',
        );
        expect(
          find.ancestor(of: waveFinder, matching: find.byType(ClipRRect)),
          findsOneWidget,
          reason: 'The inner rounded clip must own decoration containment.',
        );
        expect(
          find.ancestor(of: waveFinder, matching: find.byType(RepaintBoundary)),
          findsAtLeastNWidgets(1),
          reason: 'Wave ticks must stay inside a dedicated repaint boundary.',
        );
        expect(
          tester.getRect(waveFinder),
          cardRect,
          reason: 'The wave gets the complete already-clipped card interior.',
        );
        final tint = tester.widget<DecoratedBox>(
          find.byKey(
            ValueKey<String>('balance-carousel-card-reference-tint-${card.id}'),
          ),
        );
        final shell = tester.widget<DecoratedBox>(
          find.byKey(
            ValueKey<String>(
              'balance-carousel-card-reference-shell-${card.id}',
            ),
          ),
        );
        final shellDecoration = shell.decoration as BoxDecoration;
        final tintDecoration = tint.decoration as BoxDecoration;
        final outline = shellDecoration.border! as Border;
        expect(tintDecoration.color!.a, inInclusiveRange(.01, .10));
        expect(outline.top.width, greaterThan(0));
        expect(outline.top.color.a, greaterThan(0));
        expect(cardRect.width, closeTo(carousel.spec.itemExtent, .01));
        expect(titleRect.left, lessThan(cardRect.center.dx));
        expect(titleRect.top, lessThan(primaryRect.top));
        expect(tileRect.left, greaterThan(cardRect.center.dx));
        expect(tileRect.top, lessThan(primaryRect.top));
        expect(tileRect.width, lessThan(cardRect.width * .25));
        expect(primaryRect.left, lessThan(tileRect.left));
        expect(
          primaryRect.top,
          greaterThanOrEqualTo(cardRect.top + cardRect.height * .45),
        );
        expect(primaryRect.top, lessThan(secondaryRect.top));
        expect(secondaryRect.bottom, lessThanOrEqualTo(cardRect.bottom));
      }
      final selectedShell = tester.widget<DecoratedBox>(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-reference-shell-top-partner',
          ),
        ),
      );
      final neighboringShell = tester.widget<DecoratedBox>(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-reference-shell-top-category',
          ),
        ),
      );
      final selectedOutline =
          (selectedShell.decoration as BoxDecoration).border! as Border;
      final neighboringOutline =
          (neighboringShell.decoration as BoxDecoration).border! as Border;
      expect(
        selectedOutline.top.width,
        greaterThan(neighboringOutline.top.width),
      );
      final neighboringTint =
          (tester
                      .widget<DecoratedBox>(
                        find.byKey(
                          const ValueKey<String>(
                            'balance-carousel-card-reference-tint-top-category',
                          ),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      final selectedTint =
          (tester
                      .widget<DecoratedBox>(
                        find.byKey(
                          const ValueKey<String>(
                            'balance-carousel-card-reference-tint-top-partner',
                          ),
                        ),
                      )
                      .decoration
                  as BoxDecoration)
              .color!;
      expect(selectedTint.a, greaterThan(neighboringTint.a));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'BVC-CAROUSEL: independent presentation settings alter only their owned paint alpha while preserving card bounds and controller identity',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(categoryMovers: _moverPresentation()),
      );
      final settings = ValueNotifier<BalancePresentationSettings>(
        const BalancePresentationSettings.defaults().copyWith(
          balanceCarouselWaveAnimationEnabled: false,
        ),
      );
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(
                metrics: DashboardLayoutMetrics.reference.fitToViewport(
                  const Size(412, 892),
                ),
              ),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(9);
      await tester.pumpAndSettle();
      final carouselController = carousel.controller;
      final cardFinder = find.byKey(
        const ValueKey<String>('balance-carousel-card-top-category'),
      );
      final cardRect = tester.getRect(cardFinder);
      final outlineFinder = find.byKey(
        const ValueKey<String>(
          'balance-carousel-card-reference-shell-top-category',
        ),
      );
      final tintFinder = find.byKey(
        const ValueKey<String>(
          'balance-carousel-card-reference-tint-top-category',
        ),
      );
      final initialOutline =
          (tester.widget<DecoratedBox>(outlineFinder).decoration
                      as BoxDecoration)
                  .border!
              as Border;
      final initialWaveOpacity = _balanceCarouselWaveOpacity(
        tester,
        'top-category',
      );
      final initialWaveGeometry = _balanceCarouselWaveGeometry(
        tester,
        'top-category',
      );
      final initialTintOpacity =
          (tester.widget<DecoratedBox>(tintFinder).decoration as BoxDecoration)
              .color!
              .a;
      final contentShell = find.descendant(
        of: find.byKey(const ValueKey<String>('balance-primary-card')),
        matching: find.byType(FluviRoundedBox),
      );
      final initialContentBorder =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;

      settings.value = settings.value.copyWith(
        balanceCarouselBackgroundOpacity: .5,
        revision: 1,
      );
      await tester.pump();
      final halfTintDecoration =
          tester.widget<DecoratedBox>(tintFinder).decoration as BoxDecoration;
      expect(
        halfTintDecoration.color!.a,
        closeTo(initialTintOpacity * .5, .01),
        reason: 'Background opacity owns tint alpha only.',
      );
      expect(
        _balanceCarouselWaveOpacity(tester, 'top-category'),
        initialWaveOpacity,
      );

      settings.value = settings.value.copyWith(
        balanceCarouselBackgroundOpacity: 0,
        revision: 2,
      );
      await tester.pump();
      final noTintDecoration =
          tester.widget<DecoratedBox>(tintFinder).decoration as BoxDecoration;
      expect(
        noTintDecoration.color!.a,
        0,
        reason:
            'Zero background opacity is neutral even while tint is enabled.',
      );
      expect(
        _balanceCarouselWaveOpacity(tester, 'top-category'),
        initialWaveOpacity,
      );

      settings.value = settings.value.copyWith(
        balanceCarouselBorderOpacity: .4,
        balanceCarouselWaveOpacity: .5,
        balanceCarouselTintedBackgroundEnabled: false,
        balanceContentCardBorderOpacity: .3,
        revision: 3,
      );
      await tester.pump();

      final updatedDecoration =
          tester.widget<DecoratedBox>(tintFinder).decoration as BoxDecoration;
      final updatedOutline =
          (tester.widget<DecoratedBox>(outlineFinder).decoration
                      as BoxDecoration)
                  .border!
              as Border;
      final updatedContentBorder =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(updatedDecoration.color!.a, 0);
      expect(updatedOutline.top.width, initialOutline.top.width);
      expect(
        updatedOutline.top.color.a,
        closeTo(initialOutline.top.color.a * .4, .01),
      );
      expect(
        _balanceCarouselWaveOpacity(tester, 'top-category'),
        closeTo(initialWaveOpacity * .5, .001),
      );
      expect(
        _balanceCarouselWaveGeometry(tester, 'top-category'),
        initialWaveGeometry,
        reason: 'Opacity must not alter the accepted reference wave path.',
      );
      expect(updatedContentBorder.top.width, initialContentBorder.top.width);
      expect(
        updatedContentBorder.top.color.a,
        closeTo(initialContentBorder.top.color.a * .3, .01),
        reason: 'The independent content-border slider owns its alpha only.',
      );
      expect(tester.getRect(cardFinder), cardRect);
      expect(
        identical(
          tester
              .widget<CenteredCarousel<BalanceCarouselCard>>(
                find.byType(CenteredCarousel<BalanceCarouselCard>),
              )
              .controller,
          carouselController,
        ),
        isTrue,
      );

      settings.value = settings.value.copyWith(
        balanceCarouselBorderEnabled: true,
        balanceCarouselBorderOpacity: 0,
        balanceCarouselWaveOpacity: 0,
        balanceContentCardBorderOpacity: 0,
        revision: 4,
      );
      await tester.pump();
      final transparentOutline =
          (tester.widget<DecoratedBox>(outlineFinder).decoration
                      as BoxDecoration)
                  .border!
              as Border;
      final transparentContentBorder =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(transparentOutline.top.color.a, 0);
      expect(transparentOutline.top.width, initialOutline.top.width);
      expect(_balanceCarouselWaveOpacity(tester, 'top-category'), 0);
      expect(transparentContentBorder.top.color.a, 0);
      expect(
        transparentContentBorder.top.width,
        initialContentBorder.top.width,
      );

      settings.value = settings.value.copyWith(
        balanceCarouselBorderEnabled: false,
        balanceCarouselBorderOpacity: .9,
        revision: 5,
      );
      await tester.pump();
      final hiddenOutline =
          (tester.widget<DecoratedBox>(outlineFinder).decoration
                      as BoxDecoration)
                  .border!
              as Border;
      final contentAfterCarouselChange =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(hiddenOutline.top.color.a, 0);
      expect(hiddenOutline.top.width, initialOutline.top.width);
      expect(contentAfterCarouselChange.top.color.a, 0);
      expect(
        contentAfterCarouselChange.top.width,
        initialContentBorder.top.width,
      );
      expect(settings.value.balanceCarouselBorderOpacity, .9);
      expect(tester.getRect(cardFinder), cardRect);
    },
  );

  testWidgets(
    'BWD-WAVE: the startup clock progresses, while OFF and reduced motion remain static',
    (tester) async {
      tester.platformDispatcher.accessibilityFeaturesTestValue =
          const FakeAccessibilityFeatures();
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = ValueNotifier<BalancePresentationSettings>(
        const BalancePresentationSettings.defaults(),
      );
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(9);
      await tester.pump();

      double phase(String cardId) => _balanceCarouselWavePhase(tester, cardId);
      final cardBounds = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-carousel-card-top-category'),
        ),
      );
      final before = phase('top-category');
      await tester.pump(const Duration(seconds: 1));
      final animatedLater = phase('top-category');
      expect(animatedLater, isNot(before));
      final visibleMotionEvent = FluviDiagnosticLogger.entries.lastWhere(
        (entry) => entry.stage == 'BALANCE_WAVE|VISIBLE_MOTION_SAMPLE',
      );
      expect(visibleMotionEvent.scope, contains('resolvedLocalPhase='));
      expect(visibleMotionEvent.scope, contains('visibleWavePeakToPeakPx='));
      expect(
        visibleMotionEvent.scope,
        contains('visibleWaveDeltaFromPreviousSamplePx='),
      );
      expect(visibleMotionEvent.scope, contains('effectiveWaveAlpha='));
      FluviDiagnosticLogger.markUserBug('balance_wave');
      final waveMarker = FluviDiagnosticLogger.entries.last;
      expect(waveMarker.scope, contains('issue=balance_wave'));
      expect(waveMarker.scope, contains('balanceWave.'));
      expect(waveMarker.scope, contains('profile='));
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('balance-carousel-card-top-category'),
          ),
        ),
        cardBounds,
        reason: 'Ambient wave paint must not move carousel card geometry.',
      );

      settings.value =
          (settings.value as dynamic).copyWith(
                balanceCarouselWaveAnimationEnabled: false,
                revision: 1,
              )
              as BalancePresentationSettings;
      await tester.pump();
      final staticStart = phase('top-category');
      await tester.pump(const Duration(seconds: 1));
      expect(phase('top-category'), staticStart);
      expect(staticStart, 0);
      expect(phase('top-partner'), 0);

      settings.value =
          (settings.value as dynamic).copyWith(
                balanceCarouselWaveAnimationEnabled: true,
                revision: 2,
              )
              as BalancePresentationSettings;
      await tester.pump();
      final resumedStart = phase('top-category');
      await tester.pump(const Duration(seconds: 1));
      final resumedLater = phase('top-category');
      expect(resumedLater, isNot(resumedStart));
      expect(phase('top-partner'), closeTo(resumedLater, .001));
      final phaseBeforeSpeedChange = phase('top-category');
      final profileGeometryBeforeSpeedChange = _balanceCarouselWaveGeometry(
        tester,
        'top-category',
      );
      settings.value = settings.value.copyWith(
        balanceCarouselWaveSpeedMultiplier: 2,
        revision: 21,
      );
      await tester.pump();
      expect(
        phase('top-category'),
        closeTo(phaseBeforeSpeedChange, .001),
        reason:
            'A live speed change must retain the current periodic phase rather than restart at zero.',
      );
      expect(
        _balanceCarouselWaveGeometry(tester, 'top-category'),
        profileGeometryBeforeSpeedChange,
        reason: 'The speed slider changes temporal rate, not profile identity.',
      );
      await tester.pump(const Duration(milliseconds: 500));
      expect(phase('top-category'), isNot(phaseBeforeSpeedChange));
      final speedEvent = FluviDiagnosticLogger.entries.lastWhere(
        (entry) => entry.stage == 'BALANCE_WAVE|SPEED_CHANGED',
      );
      expect(speedEvent.scope, contains('newMultiplier=2.000'));
      expect(speedEvent.scope, contains('effectiveDurationMs=3000'));
      expect(speedEvent.scope, contains('controllerRecreated=false'));
      expect(speedEvent.scope, contains('discontinuityDetected=false'));
      final categoryGeometry = _balanceCarouselWaveGeometry(
        tester,
        'top-category',
      );
      final partnerGeometry = _balanceCarouselWaveGeometry(
        tester,
        'top-partner',
      );
      expect(
        categoryGeometry,
        isNot(equals(partnerGeometry)),
        reason:
            'One shared clock must not make distinct card identities paint the same wave.',
      );
      expect(
        tester.getRect(
          find.byKey(
            const ValueKey<String>('balance-carousel-card-top-category'),
          ),
        ),
        cardBounds,
        reason: 'Ambient wave animation must remain paint-only.',
      );

      settings.value = settings.value.copyWith(
        balanceCarouselWaveOpacity: 0,
        revision: 3,
      );
      await tester.pump();
      final invisibleWaveStart = phase('top-category');
      await tester.pump(const Duration(milliseconds: 400));
      expect(
        phase('top-category'),
        isNot(invisibleWaveStart),
        reason: 'Opacity owns paint only; it must not pause the shared clock.',
      );
      final phaseBeforeSelection = phase('top-category');
      final geometryBeforeSelection = _balanceCarouselWaveGeometry(
        tester,
        'top-category',
      );

      carousel.controller.jumpToIndex(10);
      await tester.pump();
      expect(
        phase('top-category'),
        closeTo(phaseBeforeSelection, .01),
        reason: 'Changing selection must not reset the shared wave phase.',
      );
      expect(
        _balanceCarouselWaveGeometry(tester, 'top-category'),
        geometryBeforeSelection,
        reason: 'Center/side position must not replace a card wave identity.',
      );

      settings.value =
          (settings.value as dynamic).copyWith(
                balanceCarouselWaveAnimationEnabled: false,
                revision: 4,
              )
              as BalancePresentationSettings;
      await tester.pump();
      expect(
        phase('top-category'),
        0,
        reason: 'Disabling animation must restore the authored static wave.',
      );

      settings.value = settings.value.copyWith(
        balanceCarouselWaveAnimationEnabled: true,
        revision: 5,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(disableAnimations: true),
            child: Scaffold(
              body: BalanceDashboardCoreSurface(
                presentation: _balanceModePresentation(),
                balanceLinkedPresentation: linked,
                presentationSettings: settings,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      tester
          .widget<CenteredCarousel<BalanceCarouselCard>>(
            find.byType(CenteredCarousel<BalanceCarouselCard>),
          )
          .controller
          .jumpToIndex(9);
      await tester.pump();
      final reducedStart = phase('top-category');
      expect(reducedStart, 0);
      await tester.pump(const Duration(seconds: 1));
      expect(phase('top-category'), reducedStart);
    },
  );

  testWidgets(
    'BWD-CONTENT-BORDER RED: optional colored content border uses the selected carousel accent without changing its geometry',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 892));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final settings = ValueNotifier<BalancePresentationSettings>(
        const BalancePresentationSettings.defaults().copyWith(
          balanceCarouselWaveAnimationEnabled: false,
        ),
      );
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      tester
          .widget<CenteredCarousel<BalanceCarouselCard>>(
            find.byType(CenteredCarousel<BalanceCarouselCard>),
          )
          .controller
          .jumpToIndex(9);
      await tester.pumpAndSettle();

      final contentShell = find.descendant(
        of: find.byKey(const ValueKey<String>('balance-primary-card')),
        matching: find.byType(FluviRoundedBox),
      );
      final baseline =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      settings.value =
          (settings.value as dynamic).copyWith(
                balanceContentCardColoredBorderEnabled: true,
                balanceContentCardBorderOpacity: .5,
                revision: 1,
              )
              as BalancePresentationSettings;
      await tester.pump();

      final colored =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      final accent = CategoryAvatarPaletteCatalog.gradientFor(
        CategoryAvatarColorProfile.original,
        CategoryColorCatalog.handleOf('color_07'),
      ).colors[1];
      expect(colored.top.width, baseline.top.width);
      expect(colored.top.color, accent.withValues(alpha: .5));

      settings.value =
          (settings.value as dynamic).copyWith(
                balanceContentCardBorderOpacity: 0.0,
                balanceCarouselBorderOpacity: .2,
                revision: 2,
              )
              as BalancePresentationSettings;
      await tester.pump();
      final transparent =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(transparent.top.width, baseline.top.width);
      expect(transparent.top.color, accent.withValues(alpha: 0));

      settings.value =
          (settings.value as dynamic).copyWith(
                balanceContentCardBorderOpacity: 1.0,
                balanceCarouselBorderOpacity: .8,
                revision: 3,
              )
              as BalancePresentationSettings;
      await tester.pump();
      final opaque =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(opaque.top.width, baseline.top.width);
      expect(opaque.top.color, accent);

      settings.value =
          (settings.value as dynamic).copyWith(
                balanceContentCardColoredBorderEnabled: false,
                balanceContentCardBorderOpacity: .2,
                revision: 4,
              )
              as BalancePresentationSettings;
      await tester.pump();
      final neutral =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(neutral.top.width, baseline.top.width);
      expect(neutral.top.color, FluviVisualTokens.border);

      tester
          .widget<CenteredCarousel<BalanceCarouselCard>>(
            find.byType(CenteredCarousel<BalanceCarouselCard>),
          )
          .controller
          .jumpToIndex(8);
      settings.value = settings.value.copyWith(
        balanceContentCardColoredBorderEnabled: true,
        balanceContentCardBorderOpacity: .5,
        revision: 5,
      );
      await tester.pumpAndSettle();
      final moverBorder =
          tester.widget<FluviRoundedBox>(contentShell).border! as Border;
      expect(
        moverBorder.top.color,
        BalanceCategoryMoversVisualTokens.purpleLight.withValues(alpha: .5),
        reason:
            'The reference-locked Movers card owns its documented lavender border family.',
      );
    },
  );

  testWidgets(
    'BVC-STRETCH-HOST: the existing content-height envelope reaches the canonical ranked layout without growing rank one',
    (tester) async {
      final topCategories = List<DashboardBalanceRankedItem>.generate(
        5,
        (index) => DashboardBalanceRankedItem(
          id: 'category-$index',
          label: 'Kategória $index',
          direction: LedgerDirection.income,
          amountMinor: 500000 - index * 10000,
          transactionCount: 5 - index,
          categoryColorId: 'color_07',
          categoryIconId: 'icon_17',
        ),
        growable: false,
      );
      Future<({double leader, double follower, double cardHeight})> measure(
        double principalModeContentExtraHeight,
      ) async {
        final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
          _linked(topCategories: topCategories),
        );
        addTearDown(linked.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BalanceDashboardCoreSurface(
                presentation: _balanceModePresentation(
                  principalModeContentExtraHeight:
                      principalModeContentExtraHeight,
                ),
                balanceLinkedPresentation: linked,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        tester
            .widget<CenteredCarousel<BalanceCarouselCard>>(
              find.byType(CenteredCarousel<BalanceCarouselCard>),
            )
            .controller
            .jumpToIndex(9);
        await tester.pumpAndSettle();
        return (
          leader: tester
              .getSize(
                find.byKey(
                  const ValueKey<String>(
                    'balance-ranked-leader-avatar-category-0',
                  ),
                ),
              )
              .width,
          follower: tester
              .getSize(
                find.byKey(
                  const ValueKey<String>(
                    'balance-ranked-follower-avatar-category-1',
                  ),
                ),
              )
              .width,
          cardHeight: tester
              .getSize(
                find.byKey(const ValueKey<String>('balance-primary-card')),
              )
              .height,
        );
      }

      final baseline = await measure(0);
      final stretched = await measure(100);
      expect(stretched.cardHeight, closeTo(baseline.cardHeight + 100, .01));
      expect(stretched.leader, baseline.leader);
      expect(stretched.follower, greaterThan(baseline.follower));
      expect(stretched.follower, lessThan(stretched.leader));
    },
  );

  testWidgets(
    'BALANCE-LOWER-ENVELOPE: the existing lower card retains its geometry for Cashflow',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      final primary = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        DashboardBalanceLinkedPresentation(
          identity: const DashboardBalancePrimaryIdentity(
            upstreamScopeKey: 'income|expense',
            indexGeneration: 3,
            coreRevision: 7,
          ),
          timeScope: const AllTimeScope(),
          selectedDirection: LedgerDirection.income,
          cashflow: DashboardBalancePrimaryPresentation(
            identity: const DashboardBalancePrimaryIdentity(
              upstreamScopeKey: 'income|expense',
              indexGeneration: 3,
              coreRevision: 7,
            ),
            timeScope: const AllTimeScope(),
            mode: DashboardBalancePrimaryMode.sum,
            incomeTotalMinor: 700000,
            expenseTotalMinor: 400000,
            periodPairs: const <DashboardBalancePrimaryPeriodPair>[
              DashboardBalancePrimaryPeriodPair(
                value: 2025,
                incomeMinor: 300000,
                expenseMinor: 200000,
              ),
              DashboardBalancePrimaryPeriodPair(
                value: 2026,
                incomeMinor: 400000,
                expenseMinor: 200000,
              ),
            ],
            dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
          ),
          latestTransactions: const <DashboardBalanceScopedTransaction>[],
          topCategories: const <DashboardBalanceRankedItem>[],
          topPartners: const <DashboardBalanceRankedItem>[],
        ),
      );
      addTearDown(balance.dispose);
      addTearDown(primary.dispose);
      final modePresentation = _balanceModePresentation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
              balanceLinkedPresentation: primary,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<DashboardCoreModeCascadeCard>(
            find.byType(DashboardCoreModeCascadeCard),
          )
          .toList(growable: false);
      final lower = cards.singleWhere(
        (card) =>
            card.semanticKey ==
            const ValueKey<String>('dashboard-core-mode-balance-card-2'),
      );
      expect(lower.showPlaceholderSurface, isFalse);
      final delta = modePresentation.geometry.subheaderOneBounds.height * .10;
      expect(
        lower.bounds.top,
        closeTo(modePresentation.geometry.zone2Bounds.top + delta, .001),
      );
      expect(
        lower.bounds.height,
        closeTo(modePresentation.geometry.zone2Bounds.height - delta, .001),
      );
      expect(
        lower.bounds.bottom,
        closeTo(modePresentation.geometry.zone2Bounds.bottom, .001),
      );
      primary.value = DashboardBalanceLinkedPresentation(
        identity: primary.value!.identity,
        timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 2)),
        selectedDirection: LedgerDirection.income,
        cashflow: DashboardBalancePrimaryPresentation(
          identity: primary.value!.identity,
          timeScope: const DayScope(LocalDate(year: 2026, month: 7, day: 2)),
          mode: DashboardBalancePrimaryMode.unsupportedDay,
          incomeTotalMinor: 0,
          expenseTotalMinor: 0,
          periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
          dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
        ),
        latestTransactions: const <DashboardBalanceScopedTransaction>[],
        topCategories: const <DashboardBalanceRankedItem>[],
        topPartners: const <DashboardBalanceRankedItem>[],
      );
      await tester.pump();
    },
  );

  testWidgets(
    'L2-RED: the selected Balance carousel topic owns the matching lower detail card',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      addTearDown(linked.dispose);
      addTearDown(balance.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balancePresentation: balance,
              balanceLinkedPresentation: linked,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-cashflow')),
        findsOneWidget,
      );
      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(1);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-closings')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(2);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-momentum')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(3);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-retention')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(4);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-stability')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(5);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-ghost')),
        findsOneWidget,
      );
      expect(
        find.textContaining('Ghost funkció még nincs bekötve'),
        findsOneWidget,
      );
      expect(
        (tester
                    .widget<DecoratedBox>(
                      find.byKey(
                        const ValueKey<String>(
                          'balance-insight-indicator-ghost',
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .gradient,
        FluviVisualTokens.appHighlightGradient,
      );
      carousel.controller.jumpToIndex(6);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-forecast')),
        findsOneWidget,
      );
      expect(
        find.textContaining('előrejelzési adatok bekötése'),
        findsOneWidget,
      );
      expect(
        (tester
                    .widget<DecoratedBox>(
                      find.byKey(
                        const ValueKey<String>(
                          'balance-insight-indicator-forecast',
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .gradient,
        FluviVisualTokens.appHighlightGradient,
      );
      carousel.controller.jumpToIndex(7);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-latest')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-title-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-visual-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-primary-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-secondary-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Utolsó tranzakció'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'balance-carousel-card-primary-latest-transaction',
                ),
              ),
            )
            .data,
        'Piac',
      );
      expect(
        tester
            .widget<Text>(
              find.byKey(
                const ValueKey<String>(
                  'balance-carousel-card-secondary-latest-transaction',
                ),
              ),
            )
            .data,
        '350 Ft',
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('balance-carousel-card-latest-transaction'),
          ),
          matching: find.textContaining('12:00'),
        ),
        findsNothing,
      );
      carousel.controller.jumpToIndex(8);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-category-movers-empty'),
        ),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(9);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-linked-detail-top-category'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-rank-salary')),
        findsOneWidget,
      );
      final categoryController = carousel.controller;
      final categoryPosition = categoryController.scrollController.position;
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-linked-rank-salary')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-category-insight-detail')),
        findsOneWidget,
      );
      expect(
        identical(
          tester
              .widget<CenteredCarousel<BalanceCarouselCard>>(
                find.byType(CenteredCarousel<BalanceCarouselCard>),
              )
              .controller,
          categoryController,
        ),
        isTrue,
      );
      expect(
        identical(
          categoryController.scrollController.position,
          categoryPosition,
        ),
        isTrue,
      );
      await tester.tap(
        find.byKey(const ValueKey<String>('balance-category-insight-back')),
      );
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-rank-salary')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(10);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-top-partner')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BX6: Ghost and Forecast selection is presentation-only and retains the shared rail identity',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      addTearDown(linked.dispose);
      addTearDown(balance.dispose);
      var publications = 0;
      linked.addListener(() => publications += 1);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balancePresentation: balance,
              balanceLinkedPresentation: linked,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final originalPayload = linked.value;
      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final controller = carousel.controller;
      final position = controller.scrollController.position;

      carousel.controller.jumpToIndex(5);
      await tester.pump();
      carousel.controller.jumpToIndex(6);
      await tester.pump();

      final rebuilt = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      expect(publications, 0);
      expect(identical(linked.value, originalPayload), isTrue);
      expect(identical(rebuilt.controller, controller), isTrue);
      expect(
        identical(rebuilt.controller.scrollController.position, position),
        isTrue,
      );
    },
  );

  testWidgets(
    'BALANCE-CAROUSEL-LATEST: the canonical grammar remains partner then compact amount for every retained setting',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      final immutablePayload = linked.value;
      final settings = BalancePresentationController();
      addTearDown(linked.dispose);
      addTearDown(settings.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final controller = carousel.controller;
      final position = controller.scrollController.position;
      controller.jumpToIndex(7);
      await tester.pump();

      expect(
        settings.value.latestTransactionCardPresentation,
        BalanceLatestTransactionCardPresentation.avatarPartner,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-title-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(find.text('Utolsó tranzakció'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-visual-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-primary-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-secondary-latest-transaction',
          ),
        ),
        findsOneWidget,
      );
      final defaultPrimary = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-primary-latest-transaction',
          ),
        ),
      );
      final defaultSecondary = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-secondary-latest-transaction',
          ),
        ),
      );
      expect(defaultPrimary.data, 'Piac');
      expect(defaultSecondary.data, '350 Ft');
      expect(defaultPrimary.style!.color, FluviVisualTokens.textPrimary);
      expect(
        defaultSecondary.style!.color,
        CategoryColorCatalog.resolve('color_07').middleColor,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('balance-carousel-card-latest-transaction'),
          ),
          matching: find.textContaining('12:00'),
        ),
        findsNothing,
      );

      settings.setLatestTransactionCardPresentation(
        BalanceLatestTransactionCardPresentation.threeLine,
      );
      await tester.pump();
      final alternatePrimary = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-primary-latest-transaction',
          ),
        ),
      );
      final alternateSecondary = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>(
            'balance-carousel-card-secondary-latest-transaction',
          ),
        ),
      );
      expect(alternatePrimary.data, 'Piac');
      expect(alternateSecondary.data, '350 Ft');
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('balance-carousel-card-latest-transaction'),
          ),
          matching: find.textContaining('12:00'),
        ),
        findsNothing,
      );
      expect(
        identical(
          tester
              .widget<CenteredCarousel<BalanceCarouselCard>>(
                find.byType(CenteredCarousel<BalanceCarouselCard>),
              )
              .controller,
          controller,
        ),
        isTrue,
      );
      expect(identical(controller.scrollController.position, position), isTrue);
      expect(identical(linked.value, immutablePayload), isTrue);
      expect(tester.takeException(), isNull);
    },
  );

  test(
    'BX6: Balance topic renderers have no acquisition or scene dependency',
    () {
      final source = File(
        'lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart',
      ).readAsStringSync();
      expect(source, isNot(contains('repository/')));
      expect(source, isNot(contains('PreparedDashboardIndex')));
      expect(source, isNot(contains('scene')));
      expect(source, isNot(contains('DateTime.now')));
    },
  );

  test(
    'BWA-PERF: one carousel clock drives paint-only decoration without per-card builders',
    () {
      final source = File(
        'lib/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart',
      ).readAsStringSync();
      expect(source.split('AnimationController(').length - 1, 1);
      expect(source, contains('super(repaint: phaseClock)'));
      expect(source, contains('RepaintBoundary('));
      expect(source, isNot(contains('AnimatedBuilder(')));
      expect(source, contains('final Path _path = Path();'));
      expect(source, contains('final Paint _paint = Paint()'));
      expect(source, isNot(contains('final path = Path(')));
    },
  );

  testWidgets(
    'BALANCE-HEADER/CAROUSEL: prepared net uses the Header detail seam and the upper card owns one shared-engine eleven-topic rail',
    (tester) async {
      final presentation = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'income|all',
          coreRevision: 7,
          incomeTotalMinor: 150000,
          expenseTotalMinor: 210000,
          netTotalMinor: -60000,
          formattedNetTotal: '-600 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'expense-latest',
            title: 'Piac',
            formattedAmount: '-30 Ft',
            direction: LedgerDirection.expense,
            occurredOrder: 42,
          ),
        ),
      );
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      addTearDown(presentation.dispose);
      addTearDown(linked.dispose);
      var interruptionCount = 0;
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );

      Future<void> pump() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                BalanceDashboardCoreSurface(
                  presentation: modePresentation,
                  balancePresentation: presentation,
                  balanceLinkedPresentation: linked,
                  onCarouselMotionInterrupted: () => interruptionCount += 1,
                ),
              ],
            ),
          ),
        ),
      );

      await pump();
      await tester.pumpAndSettle();
      expect(find.text('-600 Ft'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
        findsOneWidget,
      );

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final source =
          carousel.dataSource! as CyclicCarouselDataSource<BalanceCarouselCard>;
      expect(source.items, hasLength(11));
      expect(source.items.first.kind, BalanceCarouselCardKind.cashflow);
      expect(carousel.controller.selectedLogicalIndex, 0);
      expect(carousel.spec.visibleItemCount, 3);
      expect(
        identical(
          carousel.spec.motionProfile,
          CenteredCarouselMotionProfiles.timeRefinementRail,
        ),
        isTrue,
      );
      expect(carousel.spec.maxScale, greaterThan(carousel.spec.neighborScale));
      expect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-card-2'),
        ),
        findsOneWidget,
        reason:
            'The lower structural Balance envelope remains the single card slot.',
      );

      final selectedSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where(
            (semantics) =>
                semantics.properties.selected == true &&
                semantics.properties.label?.startsWith('Cashflow:') == true,
          )
          .toList(growable: false);
      expect(selectedSemantics, hasLength(1));
      expect(
        selectedSemantics.single.properties.label,
        startsWith('Cashflow:'),
      );

      final viewport = find.byKey(
        const ValueKey<String>('balance-carousel-viewport'),
      );
      final centerCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
      );
      final leftCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-top-partner')),
      );
      final rightCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-closings')),
      );
      expect(centerCard.width, greaterThan(leftCard.width));
      expect(centerCard.width, greaterThan(rightCard.width));
      expect(centerCard.overlaps(leftCard), isFalse);
      expect(centerCard.overlaps(rightCard), isFalse);
      expect(tester.getRect(viewport).contains(centerCard.center), isTrue);
      expect(
        tester
            .widgetList<AnimatedScale>(
              find.byKey(
                const ValueKey<String>('balance-carousel-press-scale'),
              ),
            )
            .every(
              (scale) =>
                  scale.duration == const Duration(milliseconds: 115) &&
                  scale.curve == Curves.easeOutQuad,
            ),
        isTrue,
      );

      carousel.controller.jumpToIndex(-1);
      await tester.pump();
      expect(carousel.controller.selectedLogicalIndex, -1);
      expect(source.itemAtLogicalIndex(-1).id, 'top-partner');
      carousel.controller.jumpToIndex(0);
      await tester.pump();

      final controllerIdentity = identityHashCode(carousel.controller);
      final scrollPosition = carousel.controller.scrollController.position;
      linked.value = _linkedReplacement();
      await tester.pump();
      final rebuilt = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final rebuiltSource =
          rebuilt.dataSource! as CyclicCarouselDataSource<BalanceCarouselCard>;
      expect(identityHashCode(rebuilt.controller), controllerIdentity);
      expect(
        identical(rebuilt.controller.scrollController.position, scrollPosition),
        isTrue,
      );
      expect(rebuilt.controller.selectedLogicalIndex, 0);
      expect(
        rebuiltSource.items.first.amount,
        '-460 Ft',
        reason:
            'A scope/direction linked payload frissíti a Cashflow hőskártyát '
            'anélkül, hogy a közös Carousel újraindulna.',
      );

      await tester.fling(viewport, const Offset(-420, 0), 2200);
      await tester.pump(const Duration(milliseconds: 50));
      final interruptionsBeforeReplacement = interruptionCount;
      final replacementPointer = await tester.startGesture(
        tester.getCenter(viewport),
      );
      await tester.pump();
      expect(
        interruptionCount,
        greaterThan(interruptionsBeforeReplacement),
        reason: 'A new Balance pointer must interrupt the active shared fling.',
      );
      await replacementPointer.moveBy(const Offset(-80, 0));
      await replacementPointer.up();
      await tester.pumpAndSettle();
      expect(
        rebuilt.controller.selectedLogicalIndex,
        isNot(0),
        reason: 'A direct fling must stay on the shared ballistic engine.',
      );
    },
  );

  testWidgets(
    'BALANCE-HEADER-VISIBILITY RED: prepared net uses the canonical on-dark Header foreground',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'income|all',
          coreRevision: 7,
          incomeTotalMinor: 150000,
          expenseTotalMinor: 210000,
          netTotalMinor: -60000,
          formattedNetTotal: '-600 Ft',
          presentationId: 1,
        ),
      );
      addTearDown(balance.dispose);
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final amount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(amount.data, '-600 Ft');
      expect(amount.style?.color, FluviVisualTokens.textOnAction);
      expect(
        amount.style?.color,
        isNot(modePresentation.palette.upcomingHeaderTone),
        reason: 'Widget presence alone is not evidence of visible contrast.',
      );

      balance.value = balance.value!.copyWith(
        netTotalMinor: 60000,
        formattedNetTotal: '600 Ft',
        presentationId: 2,
      );
      await tester.pump();
      expect(find.text('600 Ft'), findsOneWidget);
      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey<String>('balance-header-net-amount')),
            )
            .style
            ?.color,
        FluviVisualTokens.textOnAction,
      );
    },
  );

  testWidgets(
    'BALANCE-CAROUSEL-SURFACES RED: every cyclic logical card has the canonical white surface',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'income|all|expense|all',
          coreRevision: 7,
          incomeTotalMinor: 1000000,
          expenseTotalMinor: 400000,
          netTotalMinor: 600000,
          formattedNetTotal: '6 000 Ft',
          presentationId: 7,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'latest',
            title: 'Latest',
            formattedAmount: '100 Ft',
            direction: LedgerDirection.income,
            occurredOrder: 1,
          ),
        ),
      );
      addTearDown(balance.dispose);
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );

      void expectSurface(String id) {
        final surface = tester.widget<DecoratedBox>(
          find.byKey(ValueKey<String>('balance-carousel-card-surface-$id')),
        );
        final decoration = surface.decoration as BoxDecoration;
        expect(decoration.color, FluviVisualTokens.surface, reason: id);
      }

      for (final (index, id) in <(int, String)>[
        (0, 'cashflow'),
        (1, 'closings'),
        (2, 'momentum'),
        (3, 'retention'),
        (4, 'stability'),
        (5, 'ghost'),
        (6, 'forecast'),
        (7, 'latest-transaction'),
        (8, 'category-movers'),
        (9, 'top-category'),
        (10, 'top-partner'),
      ]) {
        carousel.controller.jumpToIndex(index);
        await tester.pump();
        expectSurface(id);
      }
    },
  );

  testWidgets(
    'BALANCE-UPPER-VISUALS RED: only carousel cards occupy the upper slot at full structural height',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'income|all',
          coreRevision: 7,
          incomeTotalMinor: 150000,
          expenseTotalMinor: 210000,
          netTotalMinor: -60000,
          formattedNetTotal: '-600 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'expense-latest',
            title: 'Piac',
            formattedAmount: '-30 Ft',
            direction: LedgerDirection.expense,
            occurredOrder: 42,
          ),
        ),
      );
      addTearDown(balance.dispose);
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                BalanceDashboardCoreSurface(
                  presentation: modePresentation,
                  balancePresentation: balance,
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<DashboardCoreModeCascadeCard>(
            find.byType(DashboardCoreModeCascadeCard),
          )
          .toList(growable: false);
      final upper = cards.singleWhere(
        (card) =>
            card.semanticKey ==
            const ValueKey<String>('dashboard-core-mode-balance-card-1'),
      );
      final lower = cards.singleWhere(
        (card) =>
            card.semanticKey ==
            const ValueKey<String>('dashboard-core-mode-balance-card-2'),
      );
      expect(upper.showPlaceholderSurface, isFalse);
      expect(
        lower.showPlaceholderSurface,
        isFalse,
        reason:
            'The lower shell is now populated through its own Balance '
            'primary-card host, not a second outer placeholder layer.',
      );
      expect(
        find.byKey(const ValueKey<String>('balance-primary-card-placeholder')),
        findsOneWidget,
        reason:
            'Without a primary payload, the existing lower visual shell remains.',
      );

      final center = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-top-partner')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-closings')),
      );
      expect(
        center.height,
        closeTo(
          modePresentation.geometry.subheaderOneBounds.height * 1.10,
          .01,
        ),
      );
      expect(left.height, lessThan(center.height));
      expect(right.height, lessThan(center.height));
      expect(
        tester
            .getRect(
              find.byKey(const ValueKey<String>('balance-carousel-viewport')),
            )
            .contains(center.center),
        isTrue,
      );
    },
  );

  testWidgets(
    'BALANCE-HEADER-HISTORY RED: all-time amount shares Mind anchor and expanded trend geometry',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        DashboardBalancePresentation(
          scopeKey: 'income|all|expense|all',
          coreRevision: 7,
          incomeTotalMinor: 1000000,
          expenseTotalMinor: 400000,
          netTotalMinor: 600000,
          formattedNetTotal: '6 000 Ft',
          presentationId: 7,
          history: DashboardBalanceHistorySeries(
            startInclusiveEpochMinute: 20000 * 1440,
            endInclusiveEpochMinute: 20620 * 1440,
            points: const <DashboardBalanceHistoryPoint>[
              DashboardBalanceHistoryPoint(
                entryId: 'first',
                epochDay: 20000,
                epochMinute: 20000 * 1440,
                incomeTotalMinor: 1000000,
                expenseTotalMinor: 0,
                balanceMinor: 1000000,
              ),
              DashboardBalanceHistoryPoint(
                entryId: 'last',
                epochDay: 20620,
                epochMinute: 20620 * 1440,
                incomeTotalMinor: 1000000,
                expenseTotalMinor: 400000,
                balanceMinor: 600000,
              ),
            ],
          ),
        ),
      );
      addTearDown(balance.dispose);
      final modePresentation = DashboardCoreModePresentation(
        geometry: DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.balance,
          collapseProgress: 0,
          isRailExpanded: false,
        ),
        palette: DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        ),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final header = tester.getRect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-header'),
        ),
      );
      final amount = tester.getTopLeft(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(
        amount.dx,
        closeTo(header.left + DashboardHeaderTrendChartStyle.detailLeft, .01),
      );
      expect(
        amount.dy,
        closeTo(header.top + DashboardHeaderTrendChartStyle.detailTop, .01),
      );
      final balanceAmount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(balanceAmount.style?.fontSize, 19);
      expect(balanceAmount.style?.height, .96);
      expect(balanceAmount.style?.letterSpacing, -.76);
      expect(balanceAmount.style?.fontWeight, FontWeight.w900);

      final plot = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-paint'),
        ),
      );
      expect(plot.left, closeTo(header.left + 16, .01));
      expect(plot.top, closeTo(header.top + 48, .01));
      expect(plot.width, 346);
      expect(plot.height, 60);
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('balance-header-history-chart-reveal'),
              ),
            )
            .height,
        60,
      );
    },
  );

  testWidgets(
    'BALANCE-GEOMETRY-10PCT RED: Balance alone transfers exactly ten percent of upper height from lower card',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      final settings = BalancePresentationController();
      addTearDown(balance.dispose);
      addTearDown(settings.dispose);
      final modePresentation = _balanceModePresentation();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final cards = tester
          .widgetList<DashboardCoreModeCascadeCard>(
            find.byType(DashboardCoreModeCascadeCard),
          )
          .toList(growable: false);
      final upper = cards.singleWhere(
        (card) =>
            card.semanticKey ==
            const ValueKey<String>('dashboard-core-mode-balance-card-1'),
      );
      final lower = cards.singleWhere(
        (card) =>
            card.semanticKey ==
            const ValueKey<String>('dashboard-core-mode-balance-card-2'),
      );
      final originalUpper = modePresentation.geometry.subheaderOneBounds;
      final originalLower = modePresentation.geometry.zone2Bounds;
      final delta = originalUpper.height * .10;

      expect(upper.bounds.height, closeTo(originalUpper.height * 1.10, .001));
      expect(lower.bounds.top, closeTo(originalLower.top + delta, .001));
      expect(lower.bounds.height, closeTo(originalLower.height - delta, .001));
      expect(
        lower.bounds.top - upper.bounds.bottom,
        closeTo(originalLower.top - originalUpper.bottom, .001),
      );
      expect(lower.bounds.bottom, closeTo(originalLower.bottom, .001));
      expect(
        tester
            .getTopLeft(
              find.byKey(
                const ValueKey<String>('dashboard-core-mode-balance-dots'),
              ),
            )
            .dy,
        closeTo(modePresentation.geometry.zone2IndicatorBounds.top, .001),
      );
      expect(
        tester
            .getSize(
              find.byKey(
                const ValueKey<String>('balance-carousel-card-cashflow'),
              ),
            )
            .height,
        closeTo(upper.bounds.height, .001),
      );
    },
  );

  testWidgets(
    'BALANCE-CARD-MATERIAL RED: carousel surfaces read the live Balance content border and shadow scopes',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(_balance());
      final border = DashboardBorderController();
      final shadow = DashboardShadowStyleController();
      addTearDown(balance.dispose);
      addTearDown(border.dispose);
      addTearDown(shadow.dispose);
      final modePresentation = _balanceModePresentation();

      Future<void> pump() => tester.pumpWidget(
        MaterialApp(
          home: DashboardBorderScope(
            controller: border,
            child: DashboardShadowStyleScope(
              controller: shadow,
              child: Scaffold(
                body: BalanceDashboardCoreSurface(
                  presentation: modePresentation,
                  balancePresentation: balance,
                ),
              ),
            ),
          ),
        ),
      );

      border.setEnabled(DashboardBorderSurface.balanceContent, true);
      shadow.select(DashboardShadowStyle.reference3d);
      await pump();
      await tester.pumpAndSettle();

      final decoration =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>(
                        'balance-carousel-card-surface-cashflow',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final expectedBorder = DashboardBorderScope.profileOf(
        tester.element(find.byType(BalanceDashboardCoreSurface)),
      ).borderFor(DashboardBorderSurface.balanceContent);
      final expectedDepth = DashboardShadowStyleScope.profileOf(
        tester.element(find.byType(BalanceDashboardCoreSurface)),
      ).depthFor(DashboardCornerSurfaceFamily.contentCard);
      expect(decoration.border, expectedBorder);
      expect(decoration.boxShadow, expectedDepth.shadows);
      expect(
        decoration.color,
        expectedDepth.surfaceColor ?? FluviVisualTokens.surface,
      );

      shadow.select(DashboardShadowStyle.soft);
      border.setEnabled(DashboardBorderSurface.balanceContent, false);
      await tester.pump();
      final updated =
          tester
                  .widget<DecoratedBox>(
                    find.byKey(
                      const ValueKey<String>(
                        'balance-carousel-card-surface-cashflow',
                      ),
                    ),
                  )
                  .decoration
              as BoxDecoration;
      final updatedContext = tester.element(
        find.byType(BalanceDashboardCoreSurface),
      );
      expect(
        updated.border,
        DashboardBorderScope.profileOf(
          updatedContext,
        ).borderFor(DashboardBorderSurface.balanceContent),
      );
      expect(
        updated.boxShadow,
        DashboardShadowStyleScope.profileOf(
          updatedContext,
        ).depthFor(DashboardCornerSurfaceFamily.contentCard).shadows,
      );
    },
  );

  testWidgets(
    'BALANCE-FIXED-CAROUSEL RED: fixed geometry locks baseline outer edges and preserves the standard rail gap after body reordering',
    (tester) async {
      final balance = ValueNotifier<DashboardBalancePresentation?>(
        _balance().copyWith(history: _history()),
      );
      final settings = BalancePresentationController();
      addTearDown(balance.dispose);
      addTearDown(settings.dispose);
      final modePresentation = _balanceModePresentation();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: modePresentation,
              balancePresentation: balance,
              presentationSettings: settings,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-time-label-0'),
        ),
        findsNothing,
      );
      final initial = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final controller = initial.controller;
      final position = controller.scrollController.position;
      final viewport = tester.getRect(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final selected = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-top-partner')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-closings')),
      );
      final legacyCardWidth = viewport.width / 3 * .82 * 1.30;
      final legacyOuterHalfDistance = legacyCardWidth * (1 + .78 / 2);
      final standardRailGap =
          modePresentation.geometry.zone2Bounds.top -
          modePresentation.geometry.subheaderOneBounds.bottom;

      settings.setTimeLabels(BalanceHeaderChartTimeLabels.visible);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-time-label-0'),
        ),
        findsOneWidget,
      );
      settings.setTimeLabels(BalanceHeaderChartTimeLabels.hidden);
      await tester.pump();
      final fixed = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-time-label-0'),
        ),
        findsNothing,
      );
      expect(selected.width, greaterThan(legacyCardWidth));
      expect(fixed.spec.itemExtent, closeTo(selected.width, .01));
      expect(fixed.spec.visibleItemCount, 3);
      expect(selected.left - left.right, closeTo(standardRailGap, 1));
      expect(right.left - selected.right, closeTo(standardRailGap, 1));
      expect(
        left.left,
        closeTo(selected.center.dx - legacyOuterHalfDistance, 1),
      );
      expect(
        right.right,
        closeTo(selected.center.dx + legacyOuterHalfDistance, 1),
      );
      expect(selected.overlaps(left), isFalse);
      expect(selected.overlaps(right), isFalse);
      final legacyLeftInnerEdge = left.left + .78 * legacyCardWidth;
      expect(left.right, greaterThan(legacyLeftInnerEdge));
      final gainedLeftPoint = Offset(
        (legacyLeftInnerEdge + left.right) / 2,
        left.center.dy,
      );
      expect(left.contains(gainedLeftPoint), isTrue);
      expect(
        tester
            .widgetList<Semantics>(find.byType(Semantics))
            .where(
              (semantics) =>
                  semantics.properties.label?.startsWith('Top partner:') ==
                  true,
            ),
        isNotEmpty,
        reason:
            'The widened visible neighbor stays inside the shared semantic item.',
      );
      await tester.tapAt(gainedLeftPoint);
      await tester.pumpAndSettle();
      expect(fixed.controller.selectedLogicalIndex, -1);
      expect(identical(fixed.controller, controller), isTrue);
      expect(
        identical(fixed.controller.scrollController.position, position),
        isTrue,
      );
      expect(
        identical(
          fixed.spec.motionProfile,
          CenteredCarouselMotionProfiles.timeRefinementRail,
        ),
        isTrue,
      );
    },
  );

  testWidgets(
    'BALANCE-FIXED-CAROUSEL: reference, narrow and wide production metrics retain the edge and standard-gap contract',
    (tester) async {
      addTearDown(() => tester.binding.setSurfaceSize(null));
      for (final viewport in <Size>[
        const Size(412, 892),
        const Size(360, 780),
        const Size(480, 1040),
      ]) {
        await tester.binding.setSurfaceSize(viewport);
        final metrics = DashboardLayoutMetrics.reference.fitToViewport(
          viewport,
        );
        final mode = _balanceModePresentation(metrics: metrics);
        final balance = ValueNotifier<DashboardBalancePresentation?>(
          _balance(),
        );
        addTearDown(balance.dispose);
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: BalanceDashboardCoreSurface(
                presentation: mode,
                balancePresentation: balance,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final selected = tester.getRect(
          find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
        );
        final left = tester.getRect(
          find.byKey(
            const ValueKey<String>('balance-carousel-card-top-partner'),
          ),
        );
        final right = tester.getRect(
          find.byKey(const ValueKey<String>('balance-carousel-card-closings')),
        );
        final legacyWidth =
            tester
                .getRect(find.byType(CenteredCarousel<BalanceCarouselCard>))
                .width /
            3 *
            .82 *
            1.30;
        final legacyOuterHalfDistance = legacyWidth * (1 + .78 / 2);
        final standardRailGap =
            mode.geometry.zone2Bounds.top -
            mode.geometry.subheaderOneBounds.bottom;
        expect(selected.width, greaterThan(legacyWidth));
        expect(selected.left - left.right, closeTo(standardRailGap, 1));
        expect(right.left - selected.right, closeTo(standardRailGap, 1));
        expect(
          left.left,
          closeTo(selected.center.dx - legacyOuterHalfDistance, 1),
        );
        expect(
          right.right,
          closeTo(selected.center.dx + legacyOuterHalfDistance, 1),
        );
        expect(selected.overlaps(left), isFalse);
        expect(selected.overlaps(right), isFalse);
      }
    },
  );

  testWidgets(
    'BALANCE-INDICATORS: Zone2 indicators reflect the one shared Balance insight selection',
    (tester) async {
      final linked = ValueNotifier<DashboardBalanceLinkedPresentation?>(
        _linked(),
      );
      addTearDown(linked.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: BalanceDashboardCoreSurface(
              presentation: _balanceModePresentation(),
              balanceLinkedPresentation: linked,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(
          const ValueKey<String>('balance-insight-indicator-cashflow'),
        ),
        findsOneWidget,
      );
      for (final id in <String>[
        'cashflow',
        'closings',
        'momentum',
        'retention',
        'stability',
        'ghost',
        'forecast',
        'latest-transaction',
        'top-category',
        'top-partner',
      ]) {
        expect(
          find.byKey(ValueKey<String>('balance-insight-indicator-$id')),
          findsOneWidget,
        );
      }
      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(1);
      await tester.pump();
      expect(
        (tester
                    .widget<DecoratedBox>(
                      find.byKey(
                        const ValueKey<String>(
                          'balance-insight-indicator-closings',
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .gradient,
        FluviVisualTokens.appHighlightGradient,
      );
      carousel.controller.jumpToIndex(5);
      await tester.pump();
      expect(
        (tester
                    .widget<DecoratedBox>(
                      find.byKey(
                        const ValueKey<String>(
                          'balance-insight-indicator-ghost',
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .gradient,
        FluviVisualTokens.appHighlightGradient,
      );
      carousel.controller.jumpToIndex(6);
      await tester.pump();
      expect(
        (tester
                    .widget<DecoratedBox>(
                      find.byKey(
                        const ValueKey<String>(
                          'balance-insight-indicator-forecast',
                        ),
                      ),
                    )
                    .decoration
                as BoxDecoration)
            .gradient,
        FluviVisualTokens.appHighlightGradient,
      );
    },
  );
}

void _expectHtmlCardSurfaceSizes(WidgetTester tester) {
  final mother = tester.getRect(
    find.byKey(
      const ValueKey<String>('balance-unified-header-content-surface'),
    ),
  );
  for (final key in <String>[
    'balance-tetris-card-3',
    'balance-tetris-card-4',
    'balance-tetris-card-5',
    'balance-tetris-card-combined',
  ]) {
    final actual = tester.getRect(find.byKey(ValueKey<String>(key)));
    expect(actual.width, greaterThan(0), reason: '$key has positive width');
    expect(actual.height, greaterThan(0), reason: '$key has positive height');
    expect(actual.left, greaterThanOrEqualTo(mother.left));
    expect(actual.top, greaterThanOrEqualTo(mother.top));
    expect(actual.right, lessThanOrEqualTo(mother.right));
    expect(actual.bottom, lessThanOrEqualTo(mother.bottom));
  }
}

DashboardCoreModePresentation _balanceModePresentation({
  DashboardLayoutMetrics? metrics,
  double principalModeContentExtraHeight = 0,
  bool hasPhysicalRail = true,
}) {
  final resolvedMetrics =
      metrics ??
      DashboardLayoutMetrics.reference.fitToViewport(const Size(412, 892));
  return DashboardCoreModePresentation(
    geometry: DashboardGeometryResolver.resolve(
      metrics: resolvedMetrics,
      mode: DashboardModeSpec.balance,
      collapseProgress: 0,
      isRailExpanded: false,
      hasPhysicalRail: hasPhysicalRail,
      principalModeContentExtraHeight: principalModeContentExtraHeight,
    ),
    palette: DashboardModePaletteResolver.resolve(DashboardModeSpec.balance),
  );
}

DashboardBalancePresentation _balance() => const DashboardBalancePresentation(
  scopeKey: 'income|all|expense|all',
  coreRevision: 7,
  incomeTotalMinor: 1000000,
  expenseTotalMinor: 400000,
  netTotalMinor: 600000,
  formattedNetTotal: '6 000 Ft',
  presentationId: 7,
  latestTransaction: DashboardBalanceLatestTransactionPresentation(
    entryId: 'latest',
    title: 'Latest',
    formattedAmount: '100 Ft',
    direction: LedgerDirection.income,
    occurredOrder: 1,
  ),
);

DashboardBalanceHistorySeries _history() => DashboardBalanceHistorySeries(
  startInclusiveEpochMinute: 20000 * 1440,
  endInclusiveEpochMinute: 20100 * 1440,
  points: const <DashboardBalanceHistoryPoint>[
    DashboardBalanceHistoryPoint(
      entryId: 'first',
      epochDay: 20000,
      epochMinute: 20000 * 1440,
      incomeTotalMinor: 1000000,
      expenseTotalMinor: 0,
      balanceMinor: 1000000,
    ),
    DashboardBalanceHistoryPoint(
      entryId: 'last',
      epochDay: 20100,
      epochMinute: 20100 * 1440,
      incomeTotalMinor: 1000000,
      expenseTotalMinor: 400000,
      balanceMinor: 600000,
    ),
  ],
);

DashboardBalanceLinkedPresentation _linked({
  DashboardBalancePrimaryPresentation? cashflow,
  DashboardBalanceClosingsPresentation? closings,
  DashboardBalanceRetentionPresentation? retention,
  DashboardBalanceCategoryMoversPresentation? categoryMovers,
  List<DashboardBalanceRankedItem>? topCategories,
}) {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense',
    indexGeneration: 3,
    coreRevision: 7,
  );
  return DashboardBalanceLinkedPresentation(
    identity: identity,
    timeScope: cashflow?.timeScope ?? const AllTimeScope(),
    selectedDirection: LedgerDirection.income,
    cashflow:
        cashflow ??
        DashboardBalancePrimaryPresentation(
          identity: identity,
          timeScope: const AllTimeScope(),
          mode: DashboardBalancePrimaryMode.sum,
          incomeTotalMinor: 700000,
          expenseTotalMinor: 400000,
          periodPairs: const <DashboardBalancePrimaryPeriodPair>[
            DashboardBalancePrimaryPeriodPair(
              value: 2025,
              incomeMinor: 300000,
              expenseMinor: 200000,
            ),
            DashboardBalancePrimaryPeriodPair(
              value: 2026,
              incomeMinor: 400000,
              expenseMinor: 200000,
            ),
          ],
          dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
        ),
    latestTransactions: const <DashboardBalanceScopedTransaction>[
      DashboardBalanceScopedTransaction(
        entryId: 'latest-in-scope',
        title: 'Piac',
        categoryTitle: 'Élelmiszer',
        categoryColorId: 'color_07',
        categoryIconId: 'icon_17',
        amountMinor: 35000,
        direction: LedgerDirection.expense,
        occurredOrder: 20632 * 1440,
        epochDay: 20632,
        localTimeMinutes: 12 * 60,
      ),
    ],
    topCategories:
        topCategories ??
        const <DashboardBalanceRankedItem>[
          DashboardBalanceRankedItem(
            id: 'salary',
            label: 'Fizetés',
            direction: LedgerDirection.income,
            amountMinor: 700000,
            transactionCount: 2,
            categoryColorId: 'color_07',
            categoryIconId: 'icon_17',
          ),
        ],
    topPartners: const <DashboardBalanceRankedItem>[
      DashboardBalanceRankedItem(
        id: 'employer',
        label: 'Munkahely',
        direction: LedgerDirection.income,
        amountMinor: 700000,
        transactionCount: 2,
        categoryColorId: 'color_07',
        categoryIconId: 'icon_17',
      ),
    ],
    categoryMovers: categoryMovers,
    closings: closings,
    retention: retention,
    categoryInsights: <String, DashboardBalanceCategoryInsight>{
      'salary': _salaryCategoryInsight(),
    },
    partnerInsights: <String, DashboardBalancePartnerInsight>{
      'employer': _employerPartnerInsight(),
    },
  );
}

const _alternativeBalanceIdentity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'income|expense',
  indexGeneration: 3,
  coreRevision: 7,
);

DashboardBalanceLinkedPresentation _richAlternativeMonthLinked() => _linked(
  cashflow: DashboardBalancePrimaryPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
    mode: DashboardBalancePrimaryMode.month,
    incomeTotalMinor: 500000,
    expenseTotalMinor: 200000,
    periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
    dailyPoints: <DashboardBalancePrimaryDayPoint>[
      for (var day = 1; day <= 31; day += 1)
        DashboardBalancePrimaryDayPoint(
          day: day,
          incomeMinor: day == 1 ? 500000 : 0,
          expenseMinor: switch (day % 7) {
            0 => 36000,
            3 => 21000,
            5 => 12000,
            _ => 0,
          },
        ),
    ],
  ),
  retention: DashboardBalanceRetentionPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
    periods: const <DashboardBalanceRetentionPeriod>[
      DashboardBalanceRetentionPeriod(
        id: '2026-07',
        label: 'július',
        incomeMinor: 400000,
        expenseMinor: 250000,
        state: DashboardBalanceRetentionState.value,
        selected: false,
        retentionBasisPoints: 3750,
      ),
      DashboardBalanceRetentionPeriod(
        id: '2026-08',
        label: 'augusztus',
        incomeMinor: 500000,
        expenseMinor: 200000,
        state: DashboardBalanceRetentionState.value,
        selected: true,
        retentionBasisPoints: 6000,
      ),
    ],
  ),
);

DashboardBalanceLinkedPresentation _richAlternativeYearLinked() => _linked(
  cashflow: DashboardBalancePrimaryPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: const YearScope(2026),
    mode: DashboardBalancePrimaryMode.year,
    incomeTotalMinor: 1326000,
    expenseTotalMinor: 858000,
    periodPairs: <DashboardBalancePrimaryPeriodPair>[
      for (var month = 1; month <= 12; month += 1)
        DashboardBalancePrimaryPeriodPair(
          value: month,
          incomeMinor: month * 17000,
          expenseMinor: month * 11000,
        ),
    ],
    dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
  ),
  closings: DashboardBalanceClosingsPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: const YearScope(2026),
    buckets: <DashboardBalanceClosingBucket>[
      for (var month = 1; month <= 12; month += 1)
        DashboardBalanceClosingBucket(
          id: '2026-$month',
          label: 'M$month',
          incomeMinor: month.isEven ? 90000 : 25000,
          expenseMinor: month.isEven ? 30000 : 55000,
        ),
    ],
  ),
  retention: DashboardBalanceRetentionPresentation(
    identity: _alternativeBalanceIdentity,
    timeScope: const YearScope(2026),
    periods: const <DashboardBalanceRetentionPeriod>[
      DashboardBalanceRetentionPeriod(
        id: '2025',
        label: '2025',
        incomeMinor: 1100000,
        expenseMinor: 760000,
        state: DashboardBalanceRetentionState.value,
        selected: false,
        retentionBasisPoints: 3090,
      ),
      DashboardBalanceRetentionPeriod(
        id: '2026',
        label: '2026',
        incomeMinor: 1326000,
        expenseMinor: 858000,
        state: DashboardBalanceRetentionState.value,
        selected: true,
        retentionBasisPoints: 3529,
      ),
    ],
  ),
);

DashboardBalancePrimaryPresentation _alternativeYearCashflow() =>
    DashboardBalancePrimaryPresentation(
      identity: _alternativeBalanceIdentity,
      timeScope: const YearScope(2026),
      mode: DashboardBalancePrimaryMode.year,
      incomeTotalMinor: 780000,
      expenseTotalMinor: 330000,
      periodPairs: <DashboardBalancePrimaryPeriodPair>[
        for (var month = 1; month <= 12; month += 1)
          DashboardBalancePrimaryPeriodPair(
            value: month,
            incomeMinor: month == 12 ? 90000 : 0,
            expenseMinor: month == 1 ? 40000 : 0,
          ),
      ],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );

DashboardBalancePrimaryPresentation _alternativeMonthCashflow() =>
    DashboardBalancePrimaryPresentation(
      identity: _alternativeBalanceIdentity,
      timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
      mode: DashboardBalancePrimaryMode.month,
      incomeTotalMinor: 0,
      expenseTotalMinor: 0,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );

DashboardBalancePrimaryPresentation _alternativeDayCashflow() =>
    DashboardBalancePrimaryPresentation(
      identity: _alternativeBalanceIdentity,
      timeScope: DayScope(const LocalDate(year: 2026, month: 8, day: 7)),
      mode: DashboardBalancePrimaryMode.unsupportedDay,
      incomeTotalMinor: 0,
      expenseTotalMinor: 0,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    );

DashboardBalanceCategoryMoversPresentation _moverPresentation() =>
    DashboardBalanceCategoryMoversPresentation(
      identity: const DashboardBalancePrimaryIdentity(
        upstreamScopeKey: 'income|expense',
        indexGeneration: 3,
        coreRevision: 7,
      ),
      timeScope: const AllTimeScope(),
      selectedDirection: LedgerDirection.income,
      logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 24),
      currentWindow: const DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: 2026, month: 1, day: 1),
        endInclusive: LocalDate(year: 2026, month: 9, day: 24),
      ),
      referenceWindow: const DashboardBalanceCategoryComparisonWindow(
        startInclusive: LocalDate(year: 2025, month: 1, day: 1),
        endInclusive: LocalDate(year: 2025, month: 9, day: 24),
      ),
      movers: <DashboardBalanceCategoryMover>[
        DashboardBalanceCategoryMover(
          id: 'housing',
          label: 'Lakhatás',
          categoryColorId: 'color_07',
          categoryIconId: 'icon_17',
          currentMinor: 260000,
          referenceMinor: 120000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 1,
              currentMinor: 260000,
              referenceMinor: 120000,
            ),
          ],
        ),
        DashboardBalanceCategoryMover(
          id: 'transport',
          label: 'Közlekedés',
          categoryColorId: 'color_03',
          categoryIconId: 'icon_03',
          currentMinor: 220000,
          referenceMinor: 100000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 1,
              currentMinor: 220000,
              referenceMinor: 100000,
            ),
          ],
        ),
        DashboardBalanceCategoryMover(
          id: 'food',
          label: 'Élelmiszer',
          categoryColorId: 'color_08',
          categoryIconId: 'icon_08',
          currentMinor: 180000,
          referenceMinor: 90000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 1,
              currentMinor: 180000,
              referenceMinor: 90000,
            ),
          ],
        ),
        DashboardBalanceCategoryMover(
          id: 'health',
          label: 'Egészség',
          categoryColorId: 'color_05',
          categoryIconId: 'icon_05',
          currentMinor: 150000,
          referenceMinor: 70000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 1,
              currentMinor: 150000,
              referenceMinor: 70000,
            ),
          ],
        ),
        DashboardBalanceCategoryMover(
          id: 'leisure',
          label: 'Szabadidő',
          categoryColorId: 'color_12',
          categoryIconId: 'icon_12',
          currentMinor: 130000,
          referenceMinor: 60000,
          trend: const <DashboardBalanceCategoryMoverTrendPoint>[
            DashboardBalanceCategoryMoverTrendPoint(
              bucket: 1,
              currentMinor: 130000,
              referenceMinor: 60000,
            ),
          ],
        ),
      ],
    );

DashboardBalanceCategoryInsight _salaryCategoryInsight() =>
    DashboardBalanceCategoryInsight(
      id: 'salary',
      label: 'Fizetés',
      direction: LedgerDirection.income,
      amountMinor: 700000,
      activeDirectionScopeAmountMinor: 700000,
      transactionCount: 2,
      activeDayCount: 2,
      medianAmountTimesTwo: 700000,
      temporalBuckets: const <DashboardBalanceEntityTemporalBucket>[
        DashboardBalanceEntityTemporalBucket(
          id: '2026',
          label: '2026',
          value: 700000,
        ),
      ],
      distribution: const DashboardBalanceTransactionSizeDistribution(
        zeroToFiveKCount: 0,
        fiveToTenKCount: 0,
        tenToTwentyKCount: 0,
        twentyKPlusCount: 2,
      ),
      minimumAmountMinor: 350000,
      maximumAmountMinor: 350000,
      dayOccurrences: const <DashboardBalanceEntityOccurrence>[],
      hiddenDayOccurrenceCount: 0,
    );

DashboardBalancePartnerInsight _employerPartnerInsight() {
  const occurrence = DashboardBalanceEntityOccurrence(
    id: 'employer-1',
    epochDay: 20000,
    localTimeMinutes: 12 * 60,
    amountMinor: 350000,
    occurredOrder: 20000 * 1440 + 12 * 60,
  );
  return DashboardBalancePartnerInsight(
    id: 'employer',
    label: 'Munkahely',
    direction: LedgerDirection.income,
    amountMinor: 700000,
    transactionCount: 2,
    activeDayCount: 2,
    latestScopeOccurrence: occurrence,
    temporalBuckets: const <DashboardBalanceEntityTemporalBucket>[
      DashboardBalanceEntityTemporalBucket(id: '2026', label: '2026', value: 2),
    ],
    recentScopeOccurrences: const <DashboardBalanceEntityOccurrence>[
      occurrence,
    ],
    relationship: DashboardBalancePartnerRelationship(
      allHistoryTransactionCount: 3,
      firstOccurrence: occurrence,
      latestOccurrence: occurrence,
      medianAmountTimesTwo: 700000,
      firstQuartileAmountMinor: 350000,
      thirdQuartileAmountMinor: 350000,
      typicalCadenceMinutesTimesTwo: 1440,
      cadenceOccurrences: const <DashboardBalanceEntityOccurrence>[occurrence],
    ),
  );
}

DashboardBalanceLinkedPresentation _linkedReplacement() {
  final initial = _linked();
  return DashboardBalanceLinkedPresentation(
    identity: initial.identity,
    timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
    selectedDirection: LedgerDirection.expense,
    cashflow: DashboardBalancePrimaryPresentation(
      identity: initial.identity,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 8)),
      mode: DashboardBalancePrimaryMode.month,
      incomeTotalMinor: 0,
      expenseTotalMinor: 46000,
      periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
      dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
    ),
    latestTransactions: initial.latestTransactions,
    topCategories: const <DashboardBalanceRankedItem>[
      DashboardBalanceRankedItem(
        id: 'housing',
        label: 'Lakhatás',
        direction: LedgerDirection.expense,
        amountMinor: 46000,
        transactionCount: 1,
        categoryColorId: 'color_07',
        categoryIconId: 'icon_17',
      ),
    ],
    topPartners: initial.topPartners,
  );
}

double _balanceCarouselWaveOpacity(WidgetTester tester, String cardId) {
  final painter = tester
      .widget<CustomPaint>(
        find.byKey(
          ValueKey<String>('balance-carousel-card-reference-wave-$cardId'),
        ),
      )
      .painter!;
  return (painter as dynamic).opacity as double;
}

double _balanceCarouselWavePhase(WidgetTester tester, String cardId) {
  final painter = tester
      .widget<CustomPaint>(
        find.byKey(
          ValueKey<String>('balance-carousel-card-reference-wave-$cardId'),
        ),
      )
      .painter!;
  return (painter as dynamic).phase as double;
}

List<double> _balanceCarouselWaveGeometry(WidgetTester tester, String cardId) {
  final painter =
      tester
              .widget<CustomPaint>(
                find.byKey(
                  ValueKey<String>(
                    'balance-carousel-card-reference-wave-$cardId',
                  ),
                ),
              )
              .painter!
          as dynamic;
  return List<double>.from(
    (painter.geometry as dynamic).normalizedControlPoints as List<double>,
  );
}
