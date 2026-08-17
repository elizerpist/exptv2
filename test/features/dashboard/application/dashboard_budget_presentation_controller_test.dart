import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  test(
    'semantic target and direction ticks bind dense header cells immediately',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      final preparedItems = presentation.value.items;
      presentation.setTargetHandle(1);

      expect(presentation.value.header.actualScaled100, 330);
      expect(presentation.value.header.limitScaled100, 660);
      expect(identical(presentation.value.items, preparedItems), isTrue);

      direction.select(TransactionDirection.income);

      expect(presentation.value.header.actualScaled100, 50);
      expect(presentation.value.header.limitScaled100, 100);
      expect(identical(presentation.value.items, preparedItems), isFalse);
      expect(presentation.value.items.first.title, 'Összbevételi cél');
    },
  );

  test('an out-of-window period fails closed without a repair path', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(
      _visibleFrame(year: 2030),
    );
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _snapshot,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    expect(presentation.value.header.isAvailable, isFalse);
    expect(presentation.value.header.actualScaled100, isNull);
  });

  test(
    'time-plane semantic ticks bind retained dense cells without rebuilding targets',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final snapshot = _snapshot();
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final items = presentation.value.items;
      expect(presentation.value.header.actualScaled100, 330); // month/food

      visible.value = _visibleFrame(scope: const YearScope(2026));
      expect(presentation.value.header.actualScaled100, 310); // year/food
      expect(identical(presentation.value.items, items), isTrue);

      visible.value = _visibleFrame(scope: const AllTimeScope());
      expect(presentation.value.header.actualScaled100, 290); // sum/food
      expect(identical(presentation.value.items, items), isTrue);
    },
  );
}

FluviCategory _category(String id) => FluviCategory(
  id: id,
  name: 'Food',
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

PreparedBudgetLimitSnapshot _snapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  orderedCategoryIds: const <String>['food'],
  cells: List<PreparedBudgetLimitCell>.generate(
    56,
    (index) => PreparedBudgetLimitCell(
      actualScaled100: index * 10,
      limitScaled100: index * 20,
    ),
  ),
);

DashboardVisibleFrame _visibleFrame({int year = 2026, LedgerTimeScope? scope}) {
  final effectiveScope = scope ?? MonthScope(YearMonth(year: year, month: 1));
  final queryScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: effectiveScope,
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
