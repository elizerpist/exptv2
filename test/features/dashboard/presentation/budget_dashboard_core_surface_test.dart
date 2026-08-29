import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/design/dashboard_core_mode_presentation.dart';
import 'package:fluvi/core/design/dashboard_geometry_resolver.dart';
import 'package:fluvi/core/design/dashboard_layout_metrics.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_allocation_partition_lane.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_dashboard_core_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_distribution_page_surface.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart';
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/presentation/budget_section_order.dart';
import 'package:fluvi/features/dashboard/presentation/dashboard_budget_header_presentation.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_spending_rhythm_snapshot.dart';
import 'package:fluvi/features/dashboard/prepared/data/dashboard_prepared_formatter.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  testWidgets(
    'DAY Budget Header binds daily pace rather than month projection',
    (tester) async {
      final harness = _BudgetHeaderHarness(
        initialFrame: _dayVisibleFrame(),
        snapshotForCurrentFrame: _dayHeaderSnapshot,
      );
      addTearDown(harness.dispose);

      await tester.pumpWidget(_host(harness, collapseProgress: 180));
      await tester.pump();

      final amount = tester.widget<Text>(
        find.byKey(const ValueKey('budget-header-actual-limit')),
      );
      expect(
        amount.data,
        '${DashboardPreparedFormatter.amountMinorPerDay(120000)} / '
        '${DashboardPreparedFormatter.amountMinorPerDay(96774)}',
      );
      expect(amount.data, isNot(contains('12000,00 Ft / 30000,00 Ft')));
      expect(find.text('Napi tempó'), findsOneWidget);
      expect(find.text('tempó'), findsOneWidget);
    },
  );

  testWidgets(
    'Budget header anchors title/value while its existing expansion reveals the allocation lane',
    (tester) async {
      final harness = _BudgetHeaderHarness();
      addTearDown(harness.dispose);

      await tester.pumpWidget(_host(harness, collapseProgress: 180));
      await tester.pump();

      final collapsedHeader = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-budget-header')),
      );
      final collapsedTitle = tester.getRect(
        find.byKey(const ValueKey('budget-header-target-title')),
      );
      expect(
        find.byKey(const ValueKey('budget-header-actual-limit')),
        findsOneWidget,
      );
      expect(collapsedTitle.left, greaterThanOrEqualTo(collapsedHeader.left));
      expect(collapsedTitle.left, collapsedHeader.left + 20);
      expect(collapsedTitle.top, collapsedHeader.top + 16);
      final titleText = tester.widget<Text>(
        find.byKey(const ValueKey('budget-header-target-title')),
      );
      expect(titleText.style!.fontSize, 10);
      expect(titleText.style!.fontWeight, FontWeight.w900);
      expect(titleText.style!.height, 1);
      final amountText = tester.widget<Text>(
        find.byKey(const ValueKey('budget-header-actual-limit')),
      );
      expect(amountText.style!.fontSize, 19);
      expect(amountText.style!.fontWeight, FontWeight.w900);
      expect(amountText.style!.height, .96);
      expect(amountText.style!.letterSpacing, -.76);
      expect(
        collapsedTitle.top,
        lessThan(collapsedHeader.top + collapsedHeader.height / 2),
      );
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('budget-header-partition-reveal')),
            )
            .opacity,
        0,
      );

      await tester.pumpWidget(_host(harness, collapseProgress: 90));
      await tester.pump();
      final intermediateTitle = tester.getRect(
        find.byKey(const ValueKey('budget-header-target-title')),
      );
      final intermediateReveal = tester
          .widget<Opacity>(
            find.byKey(const ValueKey('budget-header-partition-reveal')),
          )
          .opacity;
      expect(intermediateTitle.top, collapsedTitle.top);
      expect(intermediateReveal, greaterThan(0));
      expect(intermediateReveal, lessThan(1));

      await tester.pumpWidget(_host(harness, collapseProgress: 0));
      await tester.pump();

      final expandedHeader = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-budget-header')),
      );
      final expandedTitle = tester.getRect(
        find.byKey(const ValueKey('budget-header-target-title')),
      );
      final partition = tester.getRect(
        find.byKey(const ValueKey('budget-header-allocation-partition')),
      );
      final modeLabel = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-label-budget')),
      );
      final partitionPainter = tester
          .widget<CustomPaint>(
            find.byKey(const ValueKey('budget-header-allocation-partition')),
          )
          .painter;

      expect(expandedTitle.top, collapsedTitle.top);
      expect(
        tester
            .widget<Opacity>(
              find.byKey(const ValueKey('budget-header-partition-reveal')),
            )
            .opacity,
        1,
      );
      expect(
        find.byKey(const ValueKey('budget-header-allocation-percent')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-header-remaining-status')),
        findsOneWidget,
      );
      expect(partition.height, 7);
      expect(partition.left - expandedHeader.left, 16);
      expect(expandedHeader.right - partition.right, 16);
      expect(partition.left, greaterThanOrEqualTo(expandedHeader.left));
      expect(partition.right, lessThanOrEqualTo(expandedHeader.right));
      expect(partition.bottom, lessThanOrEqualTo(expandedHeader.bottom));
      expect(expandedTitle.right, lessThan(modeLabel.left));
      expect(partitionPainter, isA<BudgetAllocationPartitionPainter>());
    },
  );

  testWidgets(
    'Unified Budget composition uses the central mode-content envelope only once',
    (tester) async {
      final cardStyle = BudgetContentCardStyleController();
      addTearDown(cardStyle.dispose);
      final geometry = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.budget,
        collapseProgress: 0,
        isRailExpanded: false,
        hasPhysicalRail: false,
      );
      final presentation = DashboardCoreModePresentation(
        geometry: geometry,
        palette: DashboardModePaletteResolver.resolve(DashboardModeSpec.budget),
      );

      Future<void> pumpSurface() => tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                BudgetDashboardCoreSurface(
                  presentation: presentation,
                  contentCardStyle: cardStyle,
                ),
              ],
            ),
          ),
        ),
      );

      await pumpSurface();
      expect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
        findsNothing,
      );

      cardStyle.select(BudgetContentLayout.unifiedCard);
      await tester.pump();
      final unified = find.byKey(
        const ValueKey('budget-unified-content-card-surface'),
      );
      expect(unified, findsOneWidget);
      expect(
        tester.getRect(unified),
        Rect.fromLTWH(
          geometry.modeContentBounds.left,
          geometry.modeContentBounds.top,
          geometry.modeContentBounds.width,
          geometry.modeContentBounds.height,
        ),
      );
      expect(
        find.byKey(const ValueKey('budget-distribution-card-shell')),
        findsNothing,
      );
    },
  );

  testWidgets(
    'production Budget Card2 keeps one stable cascade subtree for every '
    'reveal state',
    (tester) async {
      final geometry = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.budget,
        collapseProgress: 90,
        isRailExpanded: false,
        hasPhysicalRail: false,
      );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Stack(
              children: <Widget>[
                BudgetDashboardCoreSurface(
                  presentation: DashboardCoreModePresentation(
                    geometry: geometry,
                    palette: DashboardModePaletteResolver.resolve(
                      DashboardModeSpec.budget,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      final card2 = tester.widget<DashboardCoreModeCascadeCard>(
        find.ancestor(
          of: find.byKey(const ValueKey('dashboard-core-mode-budget-card-2')),
          matching: find.byType(DashboardCoreModeCascadeCard),
        ),
      );
      expect(card2.showPlaceholderSurface, isFalse);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('dashboard-core-mode-budget-card-2')),
          matching: find.byType(ClipRect),
        ),
        findsNothing,
        reason:
            'A progress-dependent ClipRect would reparent the persistent '
            'PageView as collapse starts and expose the dashboard background '
            'through Card2.',
      );
    },
  );

  testWidgets('Budget Header foreground selection recolors only its text', (
    tester,
  ) async {
    final harness = _BudgetHeaderHarness();
    final headerPresentation = DashboardBudgetHeaderPresentationController()
      ..selectForeground(DashboardBudgetHeaderForeground.white);
    addTearDown(harness.dispose);
    addTearDown(headerPresentation.dispose);

    await tester.pumpWidget(
      _host(
        harness,
        collapseProgress: 180,
        headerPresentation: headerPresentation,
      ),
    );
    Text title() => tester.widget<Text>(
      find.byKey(const ValueKey('budget-header-target-title')),
    );
    Text amount() => tester.widget<Text>(
      find.byKey(const ValueKey('budget-header-actual-limit')),
    );
    expect(title().style!.color, FluviVisualTokens.textOnAction);
    expect(amount().style!.color, FluviVisualTokens.textOnAction);

    headerPresentation.selectForeground(DashboardBudgetHeaderForeground.black);
    await tester.pump();
    expect(title().style!.color, FluviVisualTokens.textPrimary);
    expect(amount().style!.color, FluviVisualTokens.textPrimary);
  });

  testWidgets('Budget Header partition slider keeps the authored centerline', (
    tester,
  ) async {
    final harness = _BudgetHeaderHarness();
    final headerPresentation = DashboardBudgetHeaderPresentationController();
    addTearDown(harness.dispose);
    addTearDown(headerPresentation.dispose);

    Future<void> pump() => tester.pumpWidget(
      _host(
        harness,
        collapseProgress: 0,
        headerPresentation: headerPresentation,
      ),
    );

    await pump();
    final baseline = tester.getRect(
      find.byKey(const ValueKey('budget-header-allocation-partition')),
    );
    final header = tester.getRect(
      find.byKey(const ValueKey('dashboard-core-mode-budget-header')),
    );

    headerPresentation.setPartitionHeightPercent(100);
    await tester.pump();
    final doubled = tester.getRect(
      find.byKey(const ValueKey('budget-header-allocation-partition')),
    );
    expect(doubled.height, 14);
    expect(doubled.center.dy, baseline.center.dy);
    expect(doubled.top, greaterThanOrEqualTo(header.top));
    expect(doubled.bottom, lessThanOrEqualTo(header.bottom));
  });

  testWidgets(
    'partition contour changes only the painter contract, not its bounds',
    (tester) async {
      final harness = _BudgetHeaderHarness();
      final headerPresentation = DashboardBudgetHeaderPresentationController();
      addTearDown(harness.dispose);
      addTearDown(headerPresentation.dispose);

      await tester.pumpWidget(
        _host(
          harness,
          collapseProgress: 0,
          headerPresentation: headerPresentation,
        ),
      );
      final lane = find.byKey(
        const ValueKey('budget-header-allocation-partition'),
      );
      final bounds = tester.getRect(lane);
      expect(
        tester.widget<CustomPaint>(lane).painter,
        isA<BudgetAllocationPartitionPainter>().having(
          (painter) => painter.showOuterContour,
          'contour',
          isFalse,
        ),
      );

      headerPresentation.setPartitionContour(true);
      await tester.pump();
      expect(tester.getRect(lane), bounds);
      expect(
        tester.widget<CustomPaint>(lane).painter,
        isA<BudgetAllocationPartitionPainter>().having(
          (painter) => painter.showOuterContour,
          'contour',
          isTrue,
        ),
      );
    },
  );

  testWidgets(
    'Unified Budget can translate the full selected-avatar input into its common-card envelope while Split keeps the baseline rail origin',
    (tester) async {
      final geometry = DashboardGeometryResolver.resolve(
        metrics: DashboardLayoutMetrics.reference,
        mode: DashboardModeSpec.budget,
        collapseProgress: 0,
        isRailExpanded: false,
        hasPhysicalRail: false,
      );
      Future<Rect> pumpRail(double contentVerticalOffset) async {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  DashboardCoreModeCascadeCard(
                    bounds: geometry.subheaderOneBounds,
                    motion: geometry.upperCardMotion!,
                    semanticKey: const ValueKey('budget-test-avatar-rail'),
                    showPlaceholderSurface: false,
                    contentVerticalInputOverflow: 20,
                    contentVerticalOffset: contentVerticalOffset,
                    content: const SizedBox.expand(
                      key: ValueKey('budget-test-avatar-rail-content'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
        await tester.pump();
        return tester.getRect(
          find.byKey(const ValueKey('budget-test-avatar-rail-content')),
        );
      }

      final splitRail = await pumpRail(0);
      expect(splitRail.top, geometry.modeContentBounds.top - 20);

      final unifiedRail = await pumpRail(20);
      expect(unifiedRail.top, geometry.modeContentBounds.top);
      expect(
        unifiedRail.bottom,
        lessThanOrEqualTo(geometry.modeContentBounds.top + 116),
      );
    },
  );

  testWidgets(
    'Budget section order covers Split and Unified without adding a second common shell',
    (tester) async {
      final composition = BudgetContentCardStyleController();
      final order = BudgetSectionOrderController();
      addTearDown(composition.dispose);
      addTearDown(order.dispose);

      Future<void> pumpSurface() {
        final chartFirst = order.value == BudgetSectionOrder.chartThenAvatars;
        final geometry = DashboardGeometryResolver.resolve(
          metrics: DashboardLayoutMetrics.reference,
          mode: DashboardModeSpec.budget,
          collapseProgress: 0,
          isRailExpanded: false,
          hasPhysicalRail: false,
          modeContentExtraHeight: chartFirst
              ? BudgetSectionOrder.chartThenAvatarsExtraModeContentHeight
              : 0,
        );
        return tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Stack(
                children: <Widget>[
                  BudgetDashboardCoreSurface(
                    presentation: DashboardCoreModePresentation(
                      geometry: geometry,
                      palette: DashboardModePaletteResolver.resolve(
                        DashboardModeSpec.budget,
                      ),
                    ),
                    contentCardStyle: composition,
                    sectionOrder: order,
                  ),
                ],
              ),
            ),
          ),
        );
      }

      await pumpSurface();
      final avatar = find.byKey(
        const ValueKey('dashboard-core-mode-budget-card-1'),
      );
      final chart = find.byKey(
        const ValueKey('dashboard-core-mode-budget-card-2'),
      );
      expect(tester.getRect(avatar).top, lessThan(tester.getRect(chart).top));
      expect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
        findsNothing,
      );

      order.select(BudgetSectionOrder.chartThenAvatars);
      await pumpSurface();
      expect(tester.getRect(chart).top, lessThan(tester.getRect(avatar).top));
      expect(
        tester.getRect(avatar).bottom,
        lessThanOrEqualTo(
          tester
              .getRect(
                find.byKey(const ValueKey('dashboard-core-mode-budget-dots')),
              )
              .top,
        ),
      );

      composition.select(BudgetContentLayout.unifiedCard);
      await pumpSurface();
      expect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
        findsOneWidget,
      );
      expect(tester.getRect(chart).top, lessThan(tester.getRect(avatar).top));
      final unified = tester.getRect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
      );
      final selectedAvatarInput = tester.getRect(
        find.byKey(const ValueKey('budget-target-avatar-rail')),
      );
      expect(selectedAvatarInput.top, greaterThan(unified.top));
      expect(selectedAvatarInput.bottom, lessThan(unified.bottom));
      expect(tester.getRect(chart).bottom, lessThan(selectedAvatarInput.top));

      order.select(BudgetSectionOrder.avatarsThenChart);
      await pumpSurface();
      expect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
        findsOneWidget,
      );
      expect(tester.getRect(avatar).top, lessThan(tester.getRect(chart).top));
      final avatarsFirstUnified = tester.getRect(
        find.byKey(const ValueKey('budget-unified-content-card-surface')),
      );
      final avatarsFirstInput = tester.getRect(
        find.byKey(const ValueKey('budget-target-avatar-rail')),
      );
      expect(
        avatarsFirstInput.top,
        greaterThanOrEqualTo(avatarsFirstUnified.top),
      );
      expect(avatarsFirstInput.bottom, lessThan(avatarsFirstUnified.bottom));
      expect(
        avatarsFirstInput.bottom,
        lessThan(
          tester.getRect(chart).top +
              BudgetDistributionPageSurface.firstChartVisualOffset,
        ),
        reason:
            'The selected avatar chrome clears the actual donut/list region; '
            'the preceding padded heading lane is intentionally shared.',
      );
      final dots = tester.getRect(
        find.byKey(const ValueKey('dashboard-core-mode-budget-dots')),
      );
      expect(
        avatarsFirstUnified.bottom - dots.bottom,
        closeTo(DashboardLayoutMetrics.reference.dotGap, .001),
        reason:
            'The lower Unified chart indicators retain the shared card but '
            'now own the authored 4px physical bottom gap.',
      );
    },
  );
}

Widget _host(
  _BudgetHeaderHarness harness, {
  required double collapseProgress,
  DashboardBudgetHeaderPresentationController? headerPresentation,
}) {
  final surface = Scaffold(
    body: Stack(
      children: <Widget>[
        BudgetDashboardCoreSurface(
          presentation: DashboardCoreModePresentation(
            geometry: DashboardGeometryResolver.resolve(
              metrics: DashboardLayoutMetrics.reference,
              mode: DashboardModeSpec.budget,
              collapseProgress: collapseProgress,
              isRailExpanded: false,
            ),
            palette: DashboardModePaletteResolver.resolve(
              DashboardModeSpec.budget,
            ),
          ),
          presentationController: harness.presentation,
        ),
      ],
    ),
  );
  return MaterialApp(
    home: headerPresentation == null
        ? surface
        : DashboardBudgetHeaderPresentationScope(
            controller: headerPresentation,
            child: surface,
          ),
  );
}

final class _BudgetHeaderHarness {
  _BudgetHeaderHarness({
    DashboardVisibleFrame? initialFrame,
    PreparedBudgetLimitSnapshot Function()? snapshotForCurrentFrame,
  }) : _snapshotForCurrentFrame = snapshotForCurrentFrame ?? _snapshot,
       categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
         const FluviCategory(
           id: 'food',
           name: 'Food',
           colorId: 'color_13',
           iconId: 'icon_01',
           isSystemUncategorized: false,
           createdAtUtcMs: 1,
           updatedAtUtcMs: 1,
         ),
       ]),
       visible = ValueNotifier<DashboardVisibleFrame?>(
         initialFrame ?? _visibleFrame(),
       ),
       direction = TransactionDirectionController(
         initialDirection: TransactionDirection.expense,
       ) {
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _snapshotForCurrentFrame,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
    );
  }

  final ValueNotifier<List<FluviCategory>> categories;
  final ValueNotifier<DashboardVisibleFrame?> visible;
  final TransactionDirectionController direction;
  final PreparedBudgetLimitSnapshot Function() _snapshotForCurrentFrame;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    categories.dispose();
    visible.dispose();
    direction.dispose();
  }
}

PreparedBudgetLimitSnapshot _dayHeaderSnapshot() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    28,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  cells[4] = const PreparedBudgetLimitCell(
    actualScaled100: 1200000,
    limitScaled100: 3000000,
  );
  cells[5] = const PreparedBudgetLimitCell(
    actualScaled100: 1,
    limitScaled100: 1,
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
  final dayTen = DateTime.utc(
    2026,
    1,
    10,
  ).difference(DateTime.utc(1970)).inDays;
  PreparedSpendingRhythmDirectionBank rhythm() =>
      PreparedSpendingRhythmDirectionBank(
        targetCount: 2,
        targetOffsets: const <int>[0, 1, 2],
        epochDays: <int>[dayTen, dayTen],
        dailyActualScaled100: const <int>[1200000, 1],
        dayPartActualScaled100: const <int>[
          1200000,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
          1,
          0,
          0,
          0,
          0,
          0,
          0,
          0,
        ],
      );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
    spendingRhythmSnapshot: PreparedSpendingRhythmSnapshot(
      coreRevision: 7,
      incomeBank: rhythm(),
      expenseBank: rhythm(),
    ),
  );
}

PreparedBudgetLimitSnapshot _snapshot() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    28,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Month/January is slice 2; handle zero is the aggregate Budget target.
  cells[4] = const PreparedBudgetLimitCell(
    actualScaled100: 2500000,
    limitScaled100: 10000000,
  );
  cells[5] = const PreparedBudgetLimitCell(
    actualScaled100: 1000000,
    limitScaled100: 2500000,
  );
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

DashboardVisibleFrame _visibleFrame() {
  const scope = MonthScope(YearMonth(year: 2026, month: 1));
  final queryScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: scope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: queryScope,
    parentQueryKey: queryScope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: 7,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: queryScope.key,
      revision: 7,
      groups: const <DashboardDayLogGroupViewModel>[],
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

DashboardVisibleFrame _dayVisibleFrame() {
  const scope = DayScope(LocalDate(year: 2026, month: 1, day: 2));
  final queryScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: scope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: queryScope,
    parentQueryKey: queryScope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: 7,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: queryScope.key,
      revision: 7,
      groups: const <DashboardDayLogGroupViewModel>[],
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
    railOpen: true,
    semanticIndex: 0,
    childLabel: '2026. január 2.',
    navigationEpoch: 1,
    presentationEpoch: 1,
    frameGeneration: 1,
    mode: DashboardVisibleMode.committed,
  );
}
