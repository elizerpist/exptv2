import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_presentation.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_presentation.dart';
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
}
