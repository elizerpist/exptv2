import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_distribution_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_category_distribution_visual_bank.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_donut_scene.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_target_avatar_rail_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  testWidgets(
    'donut and list are rail command sources while selected row follows Budget selection',
    (tester) async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('a', 'A', 'color_01'),
        _category('b', 'B', 'color_02'),
        _category('zero', 'Zero', 'color_03'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visible());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final drawableController = DashboardBudgetDistributionDrawableController(
        categories: categories,
        snapshot: snapshot,
      );
      final prepared = await drawableController.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      final drawableFrames =
          ValueNotifier<DashboardBudgetDistributionDrawableFrame?>(prepared);
      final delegate = _FakeRailDelegate(targetCount: 4);
      final rail = BudgetTargetAvatarRailController()..attach(delegate);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);
      addTearDown(drawableFrames.dispose);
      addTearDown(drawableController.dispose);
      addTearDown(rail.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 378,
                height: 208,
                child: BudgetCategoryDistributionCard(
                  presentation: presentation,
                  drawableFrames: drawableFrames,
                  avatarRailController: rail,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Kategóriák eloszlása'), findsOneWidget);
      expect(find.text('Kategóriák'), findsOneWidget);
      expect(
        find.text('7 napos ritmus'),
        findsNothing,
        reason: 'Rhythm belongs to the Partner analysis page, not Category.',
      );
      expect(
        tester.getSize(
          find.byKey(const ValueKey('budget-distribution-donut-150')),
        ),
        const Size(150, 150),
      );
      expect(
        find.byKey(const ValueKey('budget-category-distribution-row-a')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-category-distribution-row-b')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('budget-category-distribution-row-zero')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey('budget-category-distribution-row-selected-a'),
        ),
        findsNothing,
      );

      final interaction = find.byKey(
        const ValueKey('budget-category-distribution-donut-interaction'),
      );
      await tester.tapAt(tester.getCenter(interaction));
      await tester.pump();
      expect(delegate.requests, <int>[0]);
      expect(
        presentation.value.selectedHandle,
        0,
        reason: 'center command never teleports selection',
      );

      await tester.tap(
        find.byKey(const ValueKey('budget-category-distribution-row-a')),
      );
      await tester.pump();
      expect(delegate.requests, <int>[0, 1]);
      expect(
        presentation.value.selectedHandle,
        0,
        reason: 'list command uses the rail seam',
      );

      presentation.setTargetHandle(1);
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey('budget-category-distribution-row-selected-a'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey('budget-category-distribution-row-selected-b'),
        ),
        findsNothing,
      );

      await tester.tapAt(tester.getCenter(interaction) + const Offset(0, -50));
      await tester.pump();
      expect(
        delegate.requests.last,
        1,
        reason: 'slice order maps directly to its target handle',
      );
    },
  );

  testWidgets(
    'retains one coherent drawable card while a cold target period prewarms',
    (tester) async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('a', 'A', 'color_01'),
        _category('b', 'B', 'color_02'),
        _category('zero', 'Zero', 'color_03'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visible());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final month = DashboardBudgetCategoryDistributionProjector.project(
        snapshot: snapshot,
        categories: categories.value,
        period: const BudgetLimitPeriod.month(2026, 1),
      );
      final coldYear = DashboardBudgetCategoryDistributionProjector.project(
        snapshot: snapshot,
        categories: categories.value,
        period: const BudgetLimitPeriod.year(2026),
      );
      final drawableFrames =
          ValueNotifier<DashboardBudgetDistributionDrawableFrame?>(
            DashboardBudgetDistributionDrawableFrame(
              semanticBundle: month,
              visualBank: DashboardBudgetCategoryDistributionVisualBank.prepare(
                semanticBundle: month,
              ),
            ),
          );
      final rail = BudgetTargetAvatarRailController()
        ..attach(_FakeRailDelegate(targetCount: 4));
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);
      addTearDown(drawableFrames.dispose);
      addTearDown(rail.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: 208,
              child: BudgetCategoryDistributionCard(
                presentation: presentation,
                drawableFrames: drawableFrames,
                avatarRailController: rail,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      // A semantic time change is invisible to Card2 until its matching
      // immutable SVG bank can travel with it as one drawable frame.
      expect(coldYear.key.diagnosticLabel, 'year:2026');
      await tester.pump();

      expect(
        find.byKey(const ValueKey('budget-category-distribution-preparing')),
        findsNothing,
        reason: 'A cold target must not turn an already drawable card blank.',
      );
      expect(
        find.byKey(
          const ValueKey('budget-category-distribution-donut-interaction'),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'retained Category clay scene does not create source-backed SVG on selection',
    (tester) async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('a', 'A', 'color_01'),
        _category('b', 'B', 'color_02'),
        _category('zero', 'Zero', 'color_03'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visible());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      );
      final drawableController = DashboardBudgetDistributionDrawableController(
        categories: categories,
        snapshot: snapshot,
      );
      final prepared = await drawableController.prepare(
        const BudgetLimitPeriod.month(2026, 1),
      );
      final drawableFrames =
          ValueNotifier<DashboardBudgetDistributionDrawableFrame?>(prepared);
      final rail = BudgetTargetAvatarRailController()
        ..attach(_FakeRailDelegate(targetCount: 3));
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);
      addTearDown(presentation.dispose);
      addTearDown(drawableFrames.dispose);
      addTearDown(drawableController.dispose);
      addTearDown(rail.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 378,
              height: 208,
              child: BudgetCategoryDistributionCard(
                presentation: presentation,
                drawableFrames: drawableFrames,
                avatarRailController: rail,
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      presentation.setTargetHandle(1);
      await tester.pump();

      expect(
        find.byType(BudgetClayDonutView),
        findsOneWidget,
        reason: 'The Card paints the retained geometry scene directly.',
      );
      expect(
        find.textContaining('<svg'),
        findsNothing,
        reason:
            'A semantic selection never creates a source-backed SVG widget.',
      );
    },
  );
}

final class _FakeRailDelegate implements BudgetTargetAvatarRailCommandDelegate {
  _FakeRailDelegate({required this.targetCount});

  @override
  var logicalIndex = 0;

  @override
  final int targetCount;

  final List<int> requests = <int>[];

  @override
  Future<void> animateToLogicalIndex(int logicalIndex) async {
    requests.add(logicalIndex);
    this.logicalIndex = logicalIndex;
  }
}

FluviCategory _category(String id, String name, String color) => FluviCategory(
  id: id,
  name: name,
  colorId: color,
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

PreparedBudgetLimitSnapshot _snapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  incomeBank: _bank(const <String>[], const <int>[0]),
  expenseBank: _bank(
    const <String>['a', 'b', 'zero'],
    const <int>[100, 60, 40, 0],
  ),
);

PreparedBudgetLimitDirectionBank _bank(List<String> ids, List<int> month) {
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
