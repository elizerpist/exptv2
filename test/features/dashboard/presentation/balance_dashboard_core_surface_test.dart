import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_closings_momentum_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_entity_insights_projection.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_border_style.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_shadow_style.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
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
          formattedNetTotal: '1 000,00 Ft',
          presentationId: 1,
          latestTransaction: DashboardBalanceLatestTransactionPresentation(
            entryId: 'latest',
            title: 'Teszt',
            formattedAmount: '1 000,00 Ft',
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
        typography: DashboardHeaderTypographyProfile.colorLab,
      );
      await tester.pump();
      final colorLabAmount = tester.widget<Text>(
        find.byKey(const ValueKey<String>('balance-header-net-amount')),
      );
      expect(colorLabAmount.style!.color, const Color(0xD114213A));
      expect(colorLabAmount.style!.fontFamily, 'FluviColorLabInter');
      expect(
        Theme.of(
          tester.element(
            find.byKey(const ValueKey<String>('balance-header-net-amount')),
          ),
        ).textTheme.titleMedium!.fontFamily,
        'Roboto',
        reason: 'Color Lab must not mutate the app-wide Material typography.',
      );
      expect(balance.value, same(before));
      await tester.pumpWidget(const SizedBox.shrink());
      visual.dispose();
      frame.dispose();
      balance.dispose();
    },
  );

  test('BX1 RED: Balance has ten real linked topics and no prototype', () {
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
        BalanceCarouselCardKind.topCategory,
        BalanceCarouselCardKind.topPartner,
      ],
    );
  });

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
        find.byKey(const ValueKey<String>('balance-carousel-latest-topic-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-carousel-latest-primary-row'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-carousel-latest-date-row')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-carousel-latest-avatar')),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(
            const ValueKey<String>('balance-carousel-card-latest-transaction'),
          ),
          matching: find.text('350,00 Ft'),
        ),
        findsNothing,
      );
      carousel.controller.jumpToIndex(8);
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
      carousel.controller.jumpToIndex(9);
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
      expect(source.items, hasLength(10));
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
        '-460,00 Ft',
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

      expectSurface('cashflow');
      expectSurface('closings');
      expectSurface('momentum');
      carousel.controller.jumpToIndex(4);
      await tester.pump();
      expectSurface('retention');
      expectSurface('stability');
      expectSurface('ghost');
      carousel.controller.jumpToIndex(6);
      await tester.pump();
      expectSurface('forecast');
      expectSurface('latest-transaction');
      carousel.controller.jumpToIndex(8);
      await tester.pump();
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
              const ValueKey<String>('balance-carousel-card-cashflow'),
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
        find.byKey(const ValueKey<String>('balance-carousel-card-cashflow')),
      );
      final left = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-top-partner')),
      );
      final right = tester.getRect(
        find.byKey(const ValueKey<String>('balance-carousel-card-closings')),
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
        categoryColorId: 'color_07',
        categoryIconId: 'icon_17',
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
    categoryInsights: <String, DashboardBalanceCategoryInsight>{
      'salary': _salaryCategoryInsight(),
    },
    partnerInsights: <String, DashboardBalancePartnerInsight>{
      'employer': _employerPartnerInsight(),
    },
  );
}

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
