import 'dart:async';

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

      // Direction-local selection has no previous Income target yet, so the
      // aggregate is restored instead of reinterpreting Expense handle 1.
      expect(presentation.value.header.actualScaled100, 40);
      expect(presentation.value.header.limitScaled100, 80);
      expect(presentation.value.header.title, 'Összbevételi cél');
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
      expect(full.visualProgress, 1);

      presentation.setTargetHandle(2);
      final partial = presentation.value.selectedLimitVisual;
      expect(presentation.value.header.title, 'Travel');
      expect(partial.targetHandle, 2);
      expect(
        partial.limitKey!.target,
        const FinancialLimitCategoryTarget('travel'),
      );
      expect(partial.rawProgress, .25);
      expect(partial.visualProgress, .25);
      expect(partial.visualProgress, isNot(full.visualProgress));

      presentation.setTargetHandle(1);
      expect(presentation.value.selectedLimitVisual.visualProgress, 1);
      expect(presentation.value.selectedLimitVisual.targetHandle, 1);
    },
  );

  test(
    'direction-local banks keep catalogs, handles and restored selection separate',
    () {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _namedCategory('salary', 'Salary'),
        _namedCategory('rent', 'Rent'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.income,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _directionalSnapshot,
      );
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      expect(presentation.value.items.map((item) => item.title), [
        'Összbevételi cél',
        'Salary',
      ]);
      presentation.setTargetHandle(1);
      expect(presentation.value.liveSelection.target.category!.id, 'salary');
      expect(presentation.value.liveSelection.visual.visualProgress, .2);

      direction.select(TransactionDirection.expense);
      expect(presentation.value.items.map((item) => item.title), [
        'Budget',
        'Rent',
      ]);
      expect(presentation.value.liveSelection.target.isAggregate, isTrue);
      presentation.setTargetHandle(1);
      // Handle 1 is now Rent, never the old Income Salary visual.
      expect(presentation.value.liveSelection.target.category!.id, 'rent');
      expect(presentation.value.liveSelection.visual.visualProgress, .8);

      direction.select(TransactionDirection.income);
      expect(presentation.value.liveSelection.target.category!.id, 'salary');
      expect(presentation.value.liveSelection.visual.visualProgress, .2);
      direction.select(TransactionDirection.expense);
      expect(presentation.value.liveSelection.target.category!.id, 'rent');
      expect(
        identical(
          presentation.value.liveSelection.visual,
          presentation.value.selectedLimitVisual,
        ),
        isTrue,
      );
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
    expect(presentation.value.selectedLimitVisual.visualProgress, 0);
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
    expect(state.visualProgress, .99);
    expect(state.visualProgress, isNot(1));
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
      state.visualProgress,
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
      expect(
        presentation.value.selectedLimitVisual.visualProgress,
        330 / 100660,
      );
      expect(identical(presentation.value.items, items), isTrue);
    },
  );

  test(
    'an explicit active no-limit overlay survives the presentation boundary',
    () {
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
        snapshotForCurrentFrame: _confirmedLimitSnapshot,
        limitEditController: edits,
      );
      addTearDown(presentation.dispose);
      addTearDown(edits.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      expect(presentation.value.header.limitScaled100, 88375000);

      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      expect(edits.clearDraft(session), isTrue);

      // An active overlay's null is semantic data: it means no limit, not
      // "fall back to the prepared cell".
      expect(presentation.value.header.limitScaled100, isNull);
      expect(presentation.value.header.hasLimit, isFalse);
      expect(presentation.value.selectedLimitVisual.hasPositiveLimit, isFalse);
    },
  );

  test('a positive active overlay replaces the prepared limit', () {
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
      snapshotForCurrentFrame: _confirmedLimitSnapshot,
      limitEditController: edits,
    );
    addTearDown(presentation.dispose);
    addTearDown(edits.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    presentation.setTargetHandle(1);
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

    expect(presentation.value.header.limitScaled100, 88475000);
    expect(
      presentation.value.selectedLimitVisual.effectiveLimitScaled100,
      88475000,
    );
  });

  test('without an overlay the confirmed prepared limit remains visible', () {
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
      snapshotForCurrentFrame: _confirmedLimitSnapshot,
    );
    addTearDown(presentation.dispose);
    addTearDown(categories.dispose);
    addTearDown(direction.dispose);
    addTearDown(visible.dispose);

    presentation.setTargetHandle(1);

    expect(presentation.value.header.limitScaled100, 88375000);
    expect(
      presentation.value.selectedLimitVisual.effectiveLimitScaled100,
      88375000,
    );
  });

  test(
    'a pending delete keeps its explicit no-limit overlay through the stale prepared revision',
    () async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      var snapshot = _confirmedLimitSnapshot();
      final repository = _DeferredDeleteFinancialLimitRepository();
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: repository,
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
      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      edits.clearDraft(session);
      final release = edits.finishEdit(session);

      expect(repository.deleteCalls, 1);
      expect(presentation.value.header.limitScaled100, isNull);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isFalse,
      );

      repository.completeDelete();
      await release;
      // Persistence completion does not make the stale prepared 88,375,000
      // limit authoritative again.
      expect(presentation.value.header.limitScaled100, isNull);

      snapshot = _confirmedLimitSnapshot(coreRevision: 8, limitScaled100: null);
      visible.value = _visibleFrame(coreRevision: 8);

      expect(edits.hasOverlayFor(presentation.value.header.limitKey!), isFalse);
      expect(presentation.value.header.limitScaled100, isNull);
    },
  );

  test(
    'a failed pending delete restores its authoritative prepared limit',
    () async {
      final categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
        _category('food'),
      ]);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame());
      final repository = _DeferredDeleteFinancialLimitRepository();
      late final DashboardBudgetPresentationController presentation;
      final edits = DashboardBudgetLimitEditController(
        repository: repository,
        isKeyCurrent: (key) => presentation.value.header.limitKey == key,
      );
      presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _confirmedLimitSnapshot,
        limitEditController: edits,
      );
      addTearDown(presentation.dispose);
      addTearDown(edits.dispose);
      addTearDown(categories.dispose);
      addTearDown(direction.dispose);
      addTearDown(visible.dispose);

      presentation.setTargetHandle(1);
      final session = edits.startEdit(
        presentation.value.header.limitEditContext!,
      )!;
      edits.clearDraft(session);
      final release = edits.finishEdit(session);
      expect(presentation.value.header.limitScaled100, isNull);

      repository.failDelete(StateError('delete failed'));
      await release;

      expect(edits.hasOverlayFor(presentation.value.header.limitKey!), isFalse);
      expect(presentation.value.header.limitScaled100, 88375000);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isTrue,
      );
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
      expect(presentation.value.selectedLimitVisual.visualProgress, .42);

      expect(edits.clearDraft(session), isTrue);
      expect(presentation.value.header.limitScaled100, isNull);
      expect(
        presentation.value.selectedLimitVisual.paintsProgressChrome,
        isFalse,
      );
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

FluviCategory _namedCategory(String id, String name) => FluviCategory(
  id: id,
  name: name,
  colorId: 'color_01',
  iconId: 'icon_01',
  isSystemUncategorized: false,
  createdAtUtcMs: 1,
  updatedAtUtcMs: 1,
);

PreparedBudgetLimitSnapshot _snapshot() => _snapshotFromLegacy(
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
  return _snapshotFromLegacy(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    orderedCategoryIds: const <String>['food', 'travel'],
    cells: cells,
  );
}

PreparedBudgetLimitSnapshot _noLimitSnapshot() => _snapshotFromLegacy(
  coreRevision: 7,
  yearWindowStart: 2026,
  yearWindowEndInclusive: 2026,
  orderedCategoryIds: const <String>['food'],
  cells: List<PreparedBudgetLimitCell>.filled(
    56,
    const PreparedBudgetLimitCell(actualScaled100: 42, limitScaled100: null),
  ),
);

PreparedBudgetLimitSnapshot _confirmedLimitSnapshot({
  int coreRevision = 7,
  int? limitScaled100 = 88375000,
}) {
  final cells = List<PreparedBudgetLimitCell>.filled(
    56,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  // Expense / January / category handle 1 for a two-target direction bank.
  cells[33] = PreparedBudgetLimitCell(
    actualScaled100: 70707780,
    limitScaled100: limitScaled100,
  );
  return _snapshotFromLegacy(
    coreRevision: coreRevision,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    orderedCategoryIds: const <String>['food'],
    cells: cells,
  );
}

PreparedBudgetLimitSnapshot _directionalSnapshot() {
  List<PreparedBudgetLimitCell> cells(int actual) {
    final values = List<PreparedBudgetLimitCell>.filled(
      28,
      const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
    );
    values[5] = PreparedBudgetLimitCell(
      actualScaled100: actual,
      limitScaled100: 100,
    );
    return values;
  }

  return PreparedBudgetLimitSnapshot(
    coreRevision: 7,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: const ['salary'],
      cells: cells(20),
    ),
    expenseBank: PreparedBudgetLimitDirectionBank(
      orderedCategoryIds: const ['rent'],
      cells: cells(80),
    ),
  );
}

PreparedBudgetLimitSnapshot _snapshotFromLegacy({
  required int coreRevision,
  required int yearWindowStart,
  required int yearWindowEndInclusive,
  required List<String> orderedCategoryIds,
  required List<PreparedBudgetLimitCell> cells,
}) {
  final yearCount = yearWindowEndInclusive - yearWindowStart + 1;
  final periodSliceCount = 1 + yearCount + yearCount * 12;
  final targetCount = orderedCategoryIds.length + 1;
  final cellsPerDirection = periodSliceCount * targetCount;
  PreparedBudgetLimitDirectionBank bankFor(LedgerDirection direction) =>
      PreparedBudgetLimitDirectionBank(
        orderedCategoryIds: orderedCategoryIds,
        cells: cells
            .skip(direction.index * cellsPerDirection)
            .take(cellsPerDirection)
            .toList(growable: false),
      );
  return PreparedBudgetLimitSnapshot(
    coreRevision: coreRevision,
    yearWindowStart: yearWindowStart,
    yearWindowEndInclusive: yearWindowEndInclusive,
    incomeBank: bankFor(LedgerDirection.income),
    expenseBank: bankFor(LedgerDirection.expense),
  );
}

DashboardVisibleFrame _visibleFrame({
  int year = 2026,
  LedgerTimeScope? scope,
  int coreRevision = 7,
}) {
  final effectiveScope = scope ?? MonthScope(YearMonth(year: year, month: 1));
  final queryScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: effectiveScope,
  );
  final prepared = DashboardPreparedFrame.complete(
    scope: queryScope,
    parentQueryKey: queryScope.copyWith(timeScope: const YearScope(2026)).key,
    coreRevision: coreRevision,
    totalMinor: 0,
    formattedAmount: '0 Ft',
    entryCount: 0,
    formattedEntryCount: '0',
    logBox: DashboardLogViewportState(
      queryKey: queryScope.key,
      revision: coreRevision,
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

final class _DeferredDeleteFinancialLimitRepository
    implements FinancialLimitRepository {
  final Completer<bool> _delete = Completer<bool>();
  var deleteCalls = 0;

  @override
  Future<bool> delete(FinancialLimitKey key) {
    deleteCalls += 1;
    return _delete.future;
  }

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) =>
      Future<FinancialLimit?>.value(null);

  @override
  Future<List<FinancialLimit>> list() =>
      Future<List<FinancialLimit>>.value(const <FinancialLimit>[]);

  @override
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100) =>
      Future<FinancialLimit>.error(StateError('not used'));

  void completeDelete() => _delete.complete(true);

  void failDelete(Object error) => _delete.completeError(error);
}
