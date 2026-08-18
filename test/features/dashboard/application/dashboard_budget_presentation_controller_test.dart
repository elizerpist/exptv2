import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';
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
      expect(presentation.value.header.title, 'Budget');
      presentation.setTargetHandle(1);

      expect(presentation.value.header.actualScaled100, 330);
      expect(presentation.value.header.limitScaled100, 660);
      expect(presentation.value.header.title, 'Food');
      expect(identical(presentation.value.items, preparedItems), isTrue);

      direction.select(TransactionDirection.income);

      expect(presentation.value.header.actualScaled100, 50);
      expect(presentation.value.header.limitScaled100, 100);
      expect(presentation.value.header.title, 'Food');
      expect(identical(presentation.value.items, preparedItems), isFalse);
      expect(presentation.value.items.first.title, 'Összbevételi cél');
    },
  );

  test(
    'one target-bound visual state keeps a partial target from inheriting a full ring',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
        _category('travel'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _handoffSnapshot,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final full = presentation.value.selectedLimitVisual;
      expect(full.targetHandle, 1);
      expect(full.limitKey!.target, const FinancialLimitCategoryTarget('food'));
      expect(full.rawProgress, 1);
      expect(full.sourceProgress, 1);

      presentation.setTargetHandle(2);
      final partial = presentation.value.selectedLimitVisual;
      expect(presentation.value.header.title, 'Travel');
      expect(partial.targetHandle, 2);
      expect(
        partial.limitKey!.target,
        const FinancialLimitCategoryTarget('travel'),
      );
      expect(partial.rawProgress, .25);
      expect(partial.sourceProgress, .25);
      expect(partial.sourceProgress, isNot(full.sourceProgress));

      presentation.setTargetHandle(1);
      expect(presentation.value.selectedLimitVisual.sourceProgress, 1);
      expect(presentation.value.selectedLimitVisual.targetHandle, 1);
    },
  );

  test('non-positive limits publish no chrome and never a placeholder arc', () {
    final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
      _category('food'),
    ]);
    final direction = TransactionDirectionController(
      initialDirection: TransactionDirection.expense,
    );
    final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
    final presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: _noLimitSnapshot,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    expect(presentation.value.header.limitScaled100, isNull);
    expect(
      presentation.value.selectedLimitVisual.paintsProgressChrome,
      isFalse,
    );
    expect(presentation.value.selectedLimitVisual.sourceProgress, 0);
  });

  test('99 percent visual state cannot be published as a full ring', () {
    const key = FinancialLimitKey(
      direction: FinancialLimitDirection.expense,
      target: FinancialLimitCategoryTarget('food'),
      period: FinancialLimitMonthPeriod(2026, 1),
    );
    final state = BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: 1,
      limitKey: key,
      actualScaled100: 99,
      effectiveLimitScaled100: 100,
    );

    expect(state.rawProgress, .99);
    expect(state.sourceProgress, .99);
    expect(state.sourceProgress, isNot(1));
  });

  test('a raw progress below one cannot round into a full ring', () {
    const key = FinancialLimitKey(
      direction: FinancialLimitDirection.expense,
      target: FinancialLimitCategoryTarget('food'),
      period: FinancialLimitMonthPeriod(2026, 1),
    );
    final state = BudgetCategoryAvatarSelectedLimitVisualState.available(
      targetHandle: 1,
      limitKey: key,
      actualScaled100: 9999,
      effectiveLimitScaled100: 10000,
    );

    expect(state.rawProgress, .9999);
    expect(
      state.sourceProgress,
      isNot(1),
      reason: 'A visual full ring is valid only for rawProgress >= 1.',
    );
  });

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

  test(
    'one optimistic effective limit drives the selected header atomically',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final snapshot = _snapshot();
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoReadFinancialLimitRepository(),
        isKeyCurrent: (key) => presentation.value.header.limitKey == key,
      );
      presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: () => snapshot,
        limitEditController: edits,
      );
      addTearDown(presentation.dispose);
      addTearDown(edits.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final items = presentation.value.items;
      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      edits.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100000,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );

      expect(presentation.value.header.title, 'Food');
      expect(presentation.value.header.actualScaled100, 330);
      expect(presentation.value.header.limitScaled100, 100660);
      expect(presentation.value.selectedLimitVisual.targetHandle, 1);
      expect(
        presentation.value.selectedLimitVisual.effectiveLimitScaled100,
        100660,
      );
      expect(presentation.value.selectedLimitVisual.sourceProgress, .01);
      expect(identical(presentation.value.items, items), isTrue);
    },
  );

  test(
    'first optimistic limit tick and delete update header and ring together',
    () async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: const _NoReadFinancialLimitRepository(),
        isKeyCurrent: (key) => presentation.value.header.limitKey == key,
      );
      presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _noLimitSnapshot,
        limitEditController: edits,
      );
      addTearDown(presentation.dispose);
      addTearDown(edits.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      expect(presentation.value.header.limitScaled100, isNull);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isFalse,
      );

      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      edits.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 100,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );
      expect(presentation.value.header.limitScaled100, 100);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isTrue,
      );
      expect(presentation.value.selectedLimitVisual.sourceProgress, .42);

      final delete = edits.deleteLimit(session);
      expect(presentation.value.header.limitScaled100, isNull);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isFalse,
      );
      await delete;
    },
  );
}

final class _NoReadFinancialLimitRepository
    implements FinancialLimitRepository {
  const _NoReadFinancialLimitRepository();

  @override
  Future<bool> delete(FinancialLimitKey key) =>
      Future<bool>.error(StateError('not used'));

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) =>
      Future<FinancialLimit?>.error(StateError('not used'));

  @override
  Future<List<FinancialLimit>> list() =>
      Future<List<FinancialLimit>>.error(StateError('not used'));

  @override
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100) =>
      Future<FinancialLimit>.error(StateError('not used'));
}

FluviCategory _category(String id) => FluviCategory(
  id: id,
  name: id == 'travel' ? 'Travel' : 'Food',
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

PreparedBudgetLimitSnapshot _handoffSnapshot() {
  final cells = List<PreparedBudgetLimitCell>.filled(
    84,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Expense / January / food and travel. The dense bank is
  // direction * 14 slices * 3 targets + month-1 slice offset * 3 + handle.
  cells[49] = const PreparedBudgetLimitCell(
    actualScaled100: 100,
    limitScaled100: 100,
  );
  cells[50] = const PreparedBudgetLimitCell(
    actualScaled100: 25,
    limitScaled100: 100,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    orderedCategoryIds: const <String>['food', 'travel'],
    cells: cells,
  );
}

PreparedBudgetLimitSnapshot _noLimitSnapshot() => PreparedBudgetLimitSnapshot(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  orderedCategoryIds: const <String>['food'],
  cells: List<PreparedBudgetLimitCell>.filled(
    56,
    const PreparedBudgetLimitCell(actualScaled100: 42, limitScaled100: null),
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
