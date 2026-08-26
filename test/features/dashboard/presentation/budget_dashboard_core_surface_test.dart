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
import 'package:fluvi/features/dashboard/presentation/budget_content_card_style.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
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
        find.byKey(const ValueKey('budget-distribution-page-card-surface')),
        findsNothing,
      );
    },
  );
}

Widget _host(
  _BudgetHeaderHarness harness, {
  required double collapseProgress,
}) => MaterialApp(
  home: Scaffold(
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
  ),
);

final class _BudgetHeaderHarness {
  _BudgetHeaderHarness()
    : categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
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
      visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame()),
      direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      ) {
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _snapshot,
    );
  }

  final ValueNotifier<List<FluviCategory>> categories;
  final ValueNotifier<DashboardVisibleFrame?> visible;
  final TransactionDirectionController direction;
  late final DashboardBudgetPresentationController presentation;

  void dispose() {
    presentation.dispose();
    categories.dispose();
    visible.dispose();
    direction.dispose();
  }
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
