import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_category_movers_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
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
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel.dart';

void main() {
  testWidgets(
    'MOVERS-PRODUCTION-PARENT RED: the existing Balance zone2 envelope hosts the selected Movers detail without moving its geometry',
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
      expect(
        find.byKey(const ValueKey<String>('balance-primary-card')),
        findsOneWidget,
      );
      expect(find.text('Nincs kategóriaváltozás'), findsOneWidget);

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
      expect(
        find.byKey(const ValueKey<String>('balance-primary-card')),
        findsOneWidget,
      );
      expect(find.text('Nincs kategóriaváltozás'), findsOneWidget);
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
        find.byKey(
          const ValueKey<String>('balance-linked-detail-category-movers'),
        ),
        findsOneWidget,
      );
      final carousel = tester.widget<CenteredCarousel<BalanceCarouselCard>>(
        find.byType(CenteredCarousel<BalanceCarouselCard>),
      );
      carousel.controller.jumpToIndex(1);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-cashflow')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(2);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-latest')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(3);
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
      carousel.controller.jumpToIndex(4);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-top-partner')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-linked-rank-employer')),
        findsOneWidget,
      );
      carousel.controller.jumpToIndex(5);
      await tester.pump();
      expect(
        find.byKey(const ValueKey<String>('balance-linked-detail-prototype')),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'BALANCE-HEADER/CAROUSEL RED: prepared net uses the Header detail seam and the upper card owns one shared-engine six-card rail',
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
      expect(source.items, hasLength(6));
      expect(source.items.first.kind, BalanceCarouselCardKind.categoryMovers);
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
      expect(find.text('előző időszakhoz képest'), findsOneWidget);
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
                semantics.properties.label ==
                    'Legnagyobb kategóriaváltozás: RESTAURANTS',
          )
          .toList(growable: false);
      expect(selectedSemantics, hasLength(1));
      expect(
        selectedSemantics.single.properties.label,
        'Legnagyobb kategóriaváltozás: RESTAURANTS',
      );

      final viewport = find.byKey(
        const ValueKey<String>('balance-carousel-viewport'),
      );
      final centerCard = tester.getRect(
        find.byKey(
          const ValueKey<String>('balance-carousel-card-category-movers'),
        ),
      );
      final leftCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-1')),
      );
      final rightCard = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
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
      expect(source.itemAtLogicalIndex(-1).id, 'prototype-1');
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
        'Lakhatás',
        reason:
            'A scope/direction linked payload frissíti a Movers hőskártyát '
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

      // The centered initial triad covers prototype/Movers/Cashflow; index
      // three covers latest plus the two ranked topics without changing the
      // cyclic domain.
      expectSurface('prototype-1');
      expectSurface('category-movers');
      expectSurface('cashflow');
      carousel.controller.jumpToIndex(3);
      await tester.pump();
      expectSurface('latest-transaction');
      expectSurface('top-category');
      expectSurface('top-partner');
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
        find.byKey(
          const ValueKey<String>('balance-carousel-card-category-movers'),
        ),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-1')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
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
              const ValueKey<String>('balance-carousel-card-category-movers'),
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
          const ValueKey<String>('balance-carousel-card-category-movers'),
        ),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-prototype-1')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
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

  testWidgets(
    'MOVERS-INDICATORS RED: Zone2 indicators reflect the one shared Balance insight selection',
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
          const ValueKey<String>('balance-insight-indicator-category-movers'),
        ),
        findsOneWidget,
      );
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
                          'balance-insight-indicator-cashflow',
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

DashboardBalanceLinkedPresentation _linked() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense',
    indexGeneration: 3,
    coreRevision: 7,
  );
  return DashboardBalanceLinkedPresentation(
    identity: identity,
    timeScope: const AllTimeScope(),
    selectedDirection: LedgerDirection.income,
    cashflow: DashboardBalancePrimaryPresentation(
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
        amountMinor: 35000,
        direction: LedgerDirection.expense,
        occurredOrder: 20632 * 1440,
        epochDay: 20632,
      ),
    ],
    topCategories: const <DashboardBalanceRankedItem>[
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
    categoryMovers: _movers(
      identity: identity,
      label: 'RESTAURANTS',
      categoryId: 'restaurants',
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
    categoryMovers: _movers(
      identity: initial.identity,
      label: 'Lakhatás',
      categoryId: 'housing',
    ),
  );
}

DashboardBalanceCategoryMoversPresentation _movers({
  required DashboardBalancePrimaryIdentity identity,
  required String label,
  required String categoryId,
}) => DashboardBalanceCategoryMoversPresentation(
  identity: identity,
  timeScope: const AllTimeScope(),
  selectedDirection: LedgerDirection.income,
  logicalAsOfDate: const LocalDate(year: 2026, month: 9, day: 23),
  currentWindow: const DashboardBalanceCategoryComparisonWindow(
    startInclusive: LocalDate(year: 2026, month: 1, day: 1),
    endInclusive: LocalDate(year: 2026, month: 9, day: 23),
  ),
  referenceWindow: const DashboardBalanceCategoryComparisonWindow(
    startInclusive: LocalDate(year: 2025, month: 1, day: 1),
    endInclusive: LocalDate(year: 2025, month: 9, day: 23),
  ),
  movers: <DashboardBalanceCategoryMover>[
    DashboardBalanceCategoryMover(
      id: categoryId,
      label: label,
      categoryColorId: 'color_07',
      categoryIconId: 'icon_17',
      currentMinor: 7240000,
      referenceMinor: 5398000,
      trend: const <DashboardBalanceCategoryMoverTrendPoint>[
        DashboardBalanceCategoryMoverTrendPoint(
          bucket: 1,
          currentMinor: 12000,
          referenceMinor: 9000,
        ),
      ],
    ),
  ],
);
