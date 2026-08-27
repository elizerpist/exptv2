import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/core/design/fluvi_rounded_box.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_partner_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_pager.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_distribution_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_partner_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_rail_controller.dart';
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_partner_distribution_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  testWidgets(
    'category donut derives its useful diameter from the lower-card constraints',
    (tester) async {
      Future<Size> pumpCard(double height) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 378,
                height: height,
                child: BudgetDistributionPageSurface(
                  heading: const SizedBox(),
                  donut: const SizedBox(
                    key: ValueKey<String>('constraint-driven-donut'),
                  ),
                  rightHeading: '',
                  rows: const <Widget>[],
                  listKey: const ValueKey<String>('constraint-driven-list'),
                  emptyLabel: '',
                  expandDonutToFit: true,
                ),
              ),
            ),
          ),
        );
        return tester.getSize(
          find.byKey(const ValueKey<String>('constraint-driven-donut')),
        );
      }

      final legacyLowerCard = await pumpCard(208);
      final experimentalLowerCard = await pumpCard(266);

      expect(legacyLowerCard, const Size(157, 157));
      expect(experimentalLowerCard, const Size(180, 180));
      expect(
        experimentalLowerCard.height,
        greaterThan(legacyLowerCard.height),
        reason:
            'The reclaimed lower-card space is consumed only up to the '
            'existing padded card width; no fixed donut transform is involved.',
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'owns one stable infinite two-page domain while partner list keeps vertical scrolling local',
    (tester) async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food', 'Food', 'color_01'),
        _category('rent', 'Rent', 'color_02'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visible());
      final budgetSnapshot = _budgetSnapshot();
      final partnerSnapshot = _partnerSnapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => budgetSnapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final categoryBundle =
          DashboardBudgetCategoryDistributionProjector.project(
            snapshot: budgetSnapshot,
            categories: categories.value,
            period: const BudgetLimitPeriod.month(2026, 1),
          );
      final partnerBundle = DashboardBudgetPartnerDistributionProjector.project(
        snapshot: partnerSnapshot,
        categories: categories.value,
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      final drawables =
          ValueNotifier<DashboardBudgetDistributionDrawableFrame?>(
            DashboardBudgetDistributionDrawableFrame(
              semanticBundle: categoryBundle,
              visualBank: DashboardBudgetCategoryDistributionVisualBank.prepare(
                semanticBundle: categoryBundle,
              ),
              partnerSemanticBundle: partnerBundle,
              partnerVisualBank:
                  DashboardBudgetPartnerDistributionVisualBank.prepare(
                    semanticBundle: partnerBundle,
                  ),
            ),
          );
      final rail = BudgetTargetAvatarRailController()
        ..attach(_FakeRailDelegate(targetCount: 3));
      final pages = BudgetDistributionPageController();
      final cardStyle = BudgetContentCardStyleController();
      final rhythm = ValueNotifier<DashboardBudgetRhythmState?>(_rhythm());
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);
      addTearDown(drawables.dispose);
      addTearDown(rail.dispose);
      addTearDown(pages.dispose);
      addTearDown(cardStyle.dispose);
      addTearDown(rhythm.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: 208,
              child: BudgetDistributionPager(
                controller: pages,
                presentation: presentation,
                drawableFrames: drawables,
                avatarRailController: rail,
                expandCategoryDonutToFit: true,
                contentCardStyle: cardStyle,
                rhythm: rhythm,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final pageView = tester.widget<PageView>(
        find.byKey(const ValueKey('budget-distribution-pager')),
      );
      final stablePageController = pageView.controller;
      final categoryCardBounds = tester.getRect(
        find.byKey(const ValueKey('budget-category-distribution-card')),
      );
      expect(
        pageView.clipBehavior,
        Clip.none,
        reason:
            'The travelling FluviRoundedBox owns an elevation shadow outside '
            'its page slot, so the pager itself must not expose a rectangular '
            'viewport clip.',
      );
      expect(pages.value, BudgetDistributionPage.category);
      expect(find.text('Kategóriák eloszlása'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget-distribution-donut-157')),
        findsOneWidget,
      );
      expect(find.text('7 napos ritmus'), findsNothing);
      expect(
        find.byKey(const ValueKey('budget-category-distribution-card')),
        findsOneWidget,
        reason:
            'The Category physical surface must travel with its PageView page.',
      );
      final categorySurface = tester.widget<FluviRoundedBox>(
        find.descendant(
          of: find.byKey(const ValueKey('budget-category-distribution-card')),
          matching: find.byType(FluviRoundedBox),
        ),
      );
      expect(categorySurface.color, FluviVisualTokens.surface);
      expect(
        categorySurface.border,
        Border.all(color: FluviVisualTokens.border),
      );
      expect(categorySurface.boxShadow, FluviVisualTokens.cardSurfaceShadows);
      expect(
        categorySurface.decoration.boxShadow,
        FluviVisualTokens.cardSurfaceShadows,
        reason:
            'The travelling page must keep the standard Fluvi elevation and '
            'foot shadows; the pager becomes transparent, not a replacement '
            'card treatment.',
      );
      expect(
        categorySurface.decoration.borderRadius,
        FluviVisualTokens.roundedBoxRadius,
      );

      cardStyle.select(BudgetContentLayout.unifiedCard);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('budget-distribution-page-card-surface')),
        findsNothing,
        reason: 'Unified composition suppresses the nested Card2 shell.',
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('budget-category-distribution-card')),
        ),
        categoryCardBounds,
        reason: 'The presentation switch must not change Card2 bounds.',
      );
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('budget-distribution-pager')),
            )
            .controller,
        same(stablePageController),
        reason: 'Changing Card2 chrome must retain the PageController.',
      );

      cardStyle.select(BudgetContentLayout.split);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('budget-distribution-page-card-surface')),
        findsOneWidget,
      );

      presentation.setTargetHandle(1);
      await tester.pump();
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('budget-distribution-pager')),
            )
            .controller,
        same(stablePageController),
        reason: 'an avatar semantic tick may not recreate the local pager',
      );

      await tester.drag(
        find.byKey(const ValueKey('budget-distribution-pager')),
        const Offset(-420, 0),
      );
      await tester.pumpAndSettle();
      expect(pages.value, BudgetDistributionPage.partner);
      expect(find.text('Partnerek eloszlása'), findsOneWidget);
      expect(find.text('Partnerek'), findsOneWidget);
      final partnerDonut = find.byWidgetPredicate(
        (widget) =>
            widget is SizedBox &&
            (widget.key?.toString().contains('budget-distribution-donut-') ??
                false),
      );
      expect(partnerDonut, findsOneWidget);
      expect(tester.getSize(partnerDonut).height, greaterThan(104));
      expect(find.text('7 napos ritmus'), findsOneWidget);
      expect(
        tester
            .widget<BudgetPartnerDistributionCard>(
              find.byType(BudgetPartnerDistributionCard),
            )
            .expandDonutToFit,
        isTrue,
        reason:
            'The experimental lower-card constraint must reach both Budget '
            'distribution pages, not only the category donut.',
      );
      expect(
        find.byKey(const ValueKey('budget-partner-distribution-card')),
        findsOneWidget,
        reason:
            'The Partner physical surface must travel with its PageView page.',
      );
      final partnerCardBounds = tester.getRect(
        find.byKey(const ValueKey('budget-partner-distribution-card')),
      );
      cardStyle.select(BudgetContentLayout.unifiedCard);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('budget-distribution-page-card-surface')),
        findsNothing,
        reason: 'Unified composition suppresses both nested page shells.',
      );
      expect(
        tester.getRect(
          find.byKey(const ValueKey('budget-partner-distribution-card')),
        ),
        partnerCardBounds,
      );
      cardStyle.select(BudgetContentLayout.split);
      await tester.pump();
      expect(
        find.byKey(const ValueKey('budget-partner-distribution-row-partner-0')),
        findsOneWidget,
      );

      presentation.setTargetHandle(0);
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('budget-partner-distribution-row-partner-0')),
      );
      await tester.pump();
      expect(
        presentation.value.selectedHandle,
        0,
        reason: 'Partner rows are explicitly read-only command-wise.',
      );

      final partnerList = find.byKey(
        const ValueKey('budget-partner-distribution-list'),
      );
      final listScrollable = tester.state<ScrollableState>(
        find.descendant(of: partnerList, matching: find.byType(Scrollable)),
      );
      await tester.drag(partnerList, const Offset(0, -110));
      await tester.pumpAndSettle();
      expect(listScrollable.position.pixels, greaterThan(0));
      expect(pages.value, BudgetDistributionPage.partner);

      await tester.drag(partnerList, const Offset(420, 0));
      await tester.pumpAndSettle();
      expect(pages.value, BudgetDistributionPage.category);

      final categoryVirtualIndex = pages.virtualIndex;
      for (var index = 0; index < 100; index += 1) {
        pages.pageController.jumpToPage(pages.virtualIndex + 1);
      }
      await tester.pump();
      expect(pages.value, BudgetDistributionPage.category);
      expect(pages.virtualIndex, categoryVirtualIndex + 100);
      for (var index = 0; index < 100; index += 1) {
        pages.pageController.jumpToPage(pages.virtualIndex - 1);
      }
      await tester.pump();
      expect(pages.value, BudgetDistributionPage.category);
      expect(pages.virtualIndex, categoryVirtualIndex);
      expect(
        tester
            .widget<PageView>(
              find.byKey(const ValueKey('budget-distribution-pager')),
            )
            .controller,
        same(stablePageController),
      );
    },
  );

  testWidgets(
    'rebases an idle lower-bound virtual page without changing parity or controller identity',
    (tester) async {
      final pages = BudgetDistributionPageController(initialVirtualIndex: 2);
      addTearDown(pages.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 200,
            height: 120,
            child: PageView.builder(
              controller: pages.pageController,
              onPageChanged: pages.bindVirtualIndex,
              itemBuilder: (_, index) => Text('page-$index'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final stableController = pages.pageController;

      pages.bindVirtualIndex(1);
      pages.pageController.jumpToPage(1);
      await tester.pumpAndSettle();

      expect(pages.value, BudgetDistributionPage.partner);
      expect(pages.rebaseAtIdleIfNeeded(), isTrue);
      await tester.pump();

      expect(pages.value, BudgetDistributionPage.partner);
      expect(pages.virtualIndex, greaterThan(100000));
      expect(pages.pageController, same(stableController));
      expect(pages.pageController.page!.round().isOdd, isTrue);
    },
  );
}

DashboardBudgetRhythmState _rhythm() => DashboardBudgetRhythmState(
  projection: DashboardBudgetRhythmProjection(
    coreRevision: 7,
    direction: LedgerDirection.expense,
    targetHandle: 0,
    plane: TimePlane.month,
    windowStart: DateTime.utc(2026, 8, 13),
    windowEnd: DateTime.utc(2026, 8, 19),
    title: '7 napos ritmus',
    bars: <DashboardBudgetRhythmBar>[
      for (var index = 0; index < 7; index += 1)
        DashboardBudgetRhythmBar(
          label: '$index',
          actualScaled100: index,
          visualFraction: index / 6,
        ),
    ],
  ),
  startColorArgb: 0xff000001,
  middleColorArgb: 0xff000002,
  endColorArgb: 0xff000003,
);

final class _FakeRailDelegate implements BudgetTargetAvatarRailCommandDelegate {
  _FakeRailDelegate({required this.targetCount});

  @override
  var logicalIndex = 0;

  @override
  final int targetCount;

  @override
  Future<void> animateToLogicalIndex(int logicalIndex) async {
    this.logicalIndex = logicalIndex;
  }
}

FluviCategory _category(String id, String title, String colorId) =>
    FluviCategory(
      id: id,
      name: title,
      colorId: colorId,
      iconId: 'icon_01',
      isSystemUncategorized: false,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );

PreparedBudgetLimitSnapshot _budgetSnapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  incomeBank: _budgetBank(const <String>[], const <int>[0]),
  expenseBank: _budgetBank(
    const <String>['food', 'rent'],
    const <int>[100, 60, 40],
  ),
);

PreparedBudgetLimitDirectionBank _budgetBank(
  List<String> ids,
  List<int> month,
) {
  final count = ids.length + 1;
  final cells = List<PreparedBudgetLimitCell>.filled(
    14 * count,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  for (var handle = 0; handle < count; handle += 1) {
    cells[2 * count + handle] = PreparedBudgetLimitCell(
      actualScaled100: month[handle],
      limitScaled100: null,
    );
  }
  return PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: ids,
    cells: cells,
  );
}

PreparedBudgetPartnerDistributionSnapshot _partnerSnapshot() {
  const count = 10;
  final ids = List<String>.generate(count, (index) => 'partner-$index');
  final titles = List<String>.generate(count, (index) => 'Partner $index');
  PreparedBudgetPartnerDistributionDirectionBank bank() {
    final cells = List<PreparedBudgetPartnerDistributionCell>.filled(
      14 * count,
      const PreparedBudgetPartnerDistributionCell(
        actualScaled100: 0,
        dominantCategoryId: '',
      ),
    );
    for (var index = 0; index < count; index += 1) {
      cells[2 * count + index] = PreparedBudgetPartnerDistributionCell(
        actualScaled100: 100 - index,
        dominantCategoryId: index.isEven ? 'food' : 'rent',
      );
    }
    final offsets = <int>[0];
    final contributions = <PreparedBudgetPartnerCategoryContribution>[];
    for (var slice = 0; slice < 14; slice += 1) {
      for (var category = 0; category < 2; category += 1) {
        if (slice == 2) {
          for (var partner = category; partner < count; partner += 2) {
            contributions.add(
              PreparedBudgetPartnerCategoryContribution(
                partnerHandle: partner,
                actualScaled100: 100 - partner,
              ),
            );
          }
        }
        offsets.add(contributions.length);
      }
    }
    return PreparedBudgetPartnerDistributionDirectionBank(
      orderedPartnerIds: ids,
      orderedPartnerTitles: titles,
      cells: cells,
      orderedCategoryIds: const <String>['food', 'rent'],
      categoryContributionOffsets: offsets,
      categoryContributions: contributions,
    );
  }

  return PreparedBudgetPartnerDistributionSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

DashboardVisibleFrame _visible() {
  const timeScope = MonthScope(YearMonth(year: 2026, month: 1));
  final scope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: timeScope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: scope,
    parentQueryKey: scope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: 7,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: scope.key,
      revision: 7,
      groups: const [],
      entryCount: 0,
      nextCursor: null,
      direction: LedgerDirection.expense,
    ),
    presentationDigest: 1,
  );
  return DashboardVisibleFrame.fromPrepared(
    prepared,
    parentQueryKey: prepared.parentQueryKey,
    plane: TimePlane.month,
    railOpen: false,
    semanticIndex: 0,
    childLabel: 'January',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}
