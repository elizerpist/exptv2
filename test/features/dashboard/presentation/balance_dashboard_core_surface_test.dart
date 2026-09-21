import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_border_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_header_trend_visual_kernel.dart';
import 'package:fluvi/core/design/dashboard_border_profile.dart';
import 'package:fluvi/core/design/dashboard_corner_profile.dart';
import 'package:fluvi/core/design/dashboard_shadow_profile.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

void main() {
  testWidgets(
    'BALANCE-HEADER/CAROUSEL RED: prepared net uses the Header detail seam and the upper card owns one shared-engine five-card rail',
    (tester) async {
      final presentation = ValueNotifier<DashboardBalancePresentation?>(
        const DashboardBalancePresentation(
          scopeKey: 'income|all',
          coreRevision: 7,
          incomeTotalMinor: 150000,
          expenseTotalMinor: 210000,
          netTotalMinor: -60000,
          formattedNetTotal: '-600,00 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'expense-latest',
            title: 'Piac',
            formattedAmount: '-30,00 Ft',
            direction: LedgerDirection.expense,
            occurredOrder: 42,
          ),
        ),
      );
      addTearDown(presentation.dispose);
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
                  onCarouselMotionInterrupted: () => interruptionCount += 1,
                ),
              ],
            ),
          ),
        ),
      );

      await pump();
      await tester.pumpAndSettle();
      expect(find.text('-600,00 Ft'), findsOneWidget);
      expect(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
        findsOneWidget,
      );

      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final source =
          carousel.dataSource! as CyclicCarouselDataSource<BalanceCarouselCard>;
      expect(source.items, hasLength(5));
      expect(
        source.items.first.kind,
        BalanceCarouselCardKind.latestTransaction,
      );
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
      expect(find.text('Piac'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('dashboard-core-mode-balance-card-2'),
        ),
        findsOneWidget,
        reason: 'The lower structural card remains the unchanged placeholder.',
      );

      final selectedSemantics = tester
          .widgetList<Semantics>(find.byType(Semantics))
          .where((semantics) => semantics.properties.selected == true)
          .toList(growable: false);
      expect(selectedSemantics, hasLength(1));
      expect(
        selectedSemantics.single.properties.label,
        'Legutóbbi tranzakció: Piac, -30,00 Ft',
      );

      final viewport = find.byKey(
        const ValueKey<String>('balance-carousel-viewport'),
      );
      final centerCard = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-carousel-card-latest-transaction'),
        ),
      );
      final leftCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-4')),
      );
      final rightCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-1')),
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
      expect(source.itemAtLogicalIndex(-1).id, 'prototype-4');
      carousel.controller.jumpToIndex(0);
      await tester.pump();

      final controllerIdentity = identityHashCode(carousel.controller);
      final scrollPosition = carousel.controller.scrollController.position;
      presentation.value = presentation.value!.copyWith(presentationId: 2);
      await tester.pump();
      final rebuilt = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      expect(identityHashCode(rebuilt.controller), controllerIdentity);
      expect(
        identical(rebuilt.controller.scrollController.position, scrollPosition),
        isTrue,
      );
      expect(rebuilt.controller.selectedLogicalIndex, 0);

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
          formattedNetTotal: '-600,00 Ft',
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
      expect(amount.data, '-600,00 Ft');
      expect(amount.style?.color, FluviVisualTokens.textOnAction);
      expect(
        amount.style?.color,
        isNot(modePresentation.palette.upcomingHeaderTone),
        reason: 'Widget presence alone is not evidence of visible contrast.',
      );

      balance.value = balance.value!.copyWith(
        netTotalMinor: 60000,
        formattedNetTotal: '600,00 Ft',
        presentationId: 2,
      );
      await tester.pump();
      expect(find.text('600,00 Ft'), findsOneWidget);
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
          formattedNetTotal: '6 000,00 Ft',
          presentationId: 7,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'latest',
            title: 'Latest',
            formattedAmount: '100,00 Ft',
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

      // The centered initial triad covers latest/1/4; index two covers the
      // remaining logical prototypes without changing the cyclic domain.
      expectSurface('latest-transaction');
      expectSurface('prototype-1');
      expectSurface('prototype-4');
      carousel.controller.jumpToIndex(2);
      await tester.pump();
      expectSurface('prototype-1');
      expectSurface('prototype-2');
      expectSurface('prototype-3');
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
          formattedNetTotal: '-600,00 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'expense-latest',
            title: 'Piac',
            formattedAmount: '-30,00 Ft',
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
      expect(lower.showPlaceholderSurface, isTrue);

      final center = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-carousel-card-latest-transaction'),
        ),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-4')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-1')),
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
          formattedNetTotal: '6 000,00 Ft',
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
                const ValueKey<String>(
                  'balance-carousel-card-latest-transaction',
                ),
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
                        'balance-carousel-card-surface-latest-transaction',
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
                        'balance-carousel-card-surface-latest-transaction',
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
    'BALANCE-CHART-LABELS/CAROUSEL-CONTROLS RED: Balance-only settings hide static labels and keep the shared rail identity at safe extremes',
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
        findsOneWidget,
      );
      final initial = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final controller = initial.controller;
      final position = controller.scrollController.position;
      final initialWidth = tester
          .getSize(
            find.byKey(
              const ValueKey<String>(
                'balance-carousel-card-latest-transaction',
              ),
            ),
          )
          .width;
      final neutralExtent = initial.spec.itemExtent;

      settings.setTimeLabels(BalanceHeaderChartTimeLabels.hidden);
      settings.setCardWidthBoost(.30);
      settings.setCarouselSpacingAdjustment(.12);
      await tester.pump();
      final expanded = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      final selected = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-carousel-card-latest-transaction'),
        ),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-4')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-1')),
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-header-history-chart-time-label-0'),
        ),
        findsNothing,
      );
      expect(selected.width, closeTo(initialWidth * 1.30, .01));
      expect(expanded.spec.itemExtent, greaterThan(neutralExtent));
      expect(expanded.spec.visibleItemCount, 3);
      expect(expanded.spec.itemExtent, greaterThanOrEqualTo(selected.width));
      expect(selected.overlaps(left), isFalse);
      expect(selected.overlaps(right), isFalse);
      expect(identical(expanded.controller, controller), isTrue);
      expect(
        identical(expanded.controller.scrollController.position, position),
        isTrue,
      );
      expect(
        identical(
          expanded.spec.motionProfile,
          CenteredCarouselMotionProfiles.timeRefinementRail,
        ),
        isTrue,
      );
    },
  );
}

DashboardCoreModePresentation _balanceModePresentation() =>
    DashboardCoreModePresentation(
      geometry: DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.balance,
        collapseProgress: 0,
        isRailExpanded: false,
      ),
      palette: DashboardModePaletteResolver.resolve(DashboardModeSpec.balance),
    );

DashboardBalancePresentation _balance() => const DashboardBalancePresentation(
  scopeKey: 'income|all|expense|all',
  coreRevision: 7,
  incomeTotalMinor: 1000000,
  expenseTotalMinor: 400000,
  netTotalMinor: 600000,
  formattedNetTotal: '6 000,00 Ft',
  presentationId: 7,
  latestTransaction: DashboardBalanceLatestTransactionPresentation(
    entryId: 'latest',
    title: 'Latest',
    formattedAmount: '100,00 Ft',
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
