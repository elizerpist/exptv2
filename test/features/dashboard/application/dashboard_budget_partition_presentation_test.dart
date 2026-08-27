import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/categories/presentation/budget_category_avatar_artwork.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
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
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  group('DashboardBudgetPresentationController partition', () {
    test('projects a 25 percent translucent Food allocation', () {
      final harness = _Harness(
        snapshot: _snapshot(
          budgetLimitScaled100: 10000000,
          foodLimitScaled100: 2500000,
          foodActualScaled100: 0,
        ),
      );
      addTearDown(harness.dispose);

      final dynamic state = harness.presentation.value;
      final dynamic partition = state.partition;
      final dynamic food = partition.segmentForCategoryHandle(1);

      expect(partition.liveAllocatedTotalScaled100, 2500000);
      expect(partition.allocationRawRatio, .25);
      expect(partition.allocationVisualCoverage, .25);
      expect(food.opaqueRatio, 0);
      expect(food.translucentRatio, .25);
    });

    test('splits spent and unspent category allocation in canonical order', () {
      final harness = _Harness(
        snapshot: _snapshot(
          budgetLimitScaled100: 10000000,
          foodLimitScaled100: 2500000,
          foodActualScaled100: 1000000,
          healthLimitScaled100: 5000000,
          healthActualScaled100: 0,
        ),
      );
      addTearDown(harness.dispose);

      final dynamic state = harness.presentation.value;
      final dynamic partition = state.partition;
      final dynamic food = partition.segmentForCategoryHandle(1);
      final dynamic health = partition.segmentForCategoryHandle(2);

      expect(partition.liveAllocatedTotalScaled100, 7500000);
      expect(partition.allocationRawRatio, .75);
      expect(partition.allocationVisualCoverage, .75);
      expect(food.opaqueRatio, .10);
      expect(food.translucentRatio, .15);
      expect(health.opaqueRatio, 0);
      expect(health.translucentRatio, .50);
    });

    test('keeps exact and over capacity visually full without wrapping', () {
      final exact = _Harness(
        snapshot: _snapshot(
          budgetLimitScaled100: 10000000,
          foodLimitScaled100: 2500000,
          healthLimitScaled100: 7500000,
        ),
      );
      final over = _Harness(
        snapshot: _snapshot(
          budgetLimitScaled100: 10000000,
          foodLimitScaled100: 2500000,
          healthLimitScaled100: 10000000,
        ),
      );
      addTearDown(exact.dispose);
      addTearDown(over.dispose);

      final dynamic exactState = exact.presentation.value;
      final dynamic overState = over.presentation.value;
      final dynamic exactPartition = exactState.partition;
      final dynamic overPartition = overState.partition;

      expect(exactPartition.allocationRawRatio, 1);
      expect(exactPartition.allocationVisualCoverage, 1);
      expect(exactPartition.allocationVisualCoverage, isNot(0));
      expect(overPartition.allocationRawRatio, 1.25);
      expect(overPartition.allocationVisualCoverage, 1);
    });

    test('caps category overspend at its allocated segment width', () {
      final harness = _Harness(
        snapshot: _snapshot(
          budgetLimitScaled100: 10000000,
          foodLimitScaled100: 2500000,
          foodActualScaled100: 4000000,
        ),
      );
      addTearDown(harness.dispose);

      final dynamic state = harness.presentation.value;
      final dynamic partition = state.partition;
      final dynamic food = partition.segmentForCategoryHandle(1);

      expect(food.opaqueRatio, .25);
      expect(food.translucentRatio, 0);
      expect(food.totalRatio, .25);
    });

    test('keeps a missing aggregate denominator finite and disabled', () {
      final harness = _Harness(
        snapshot: _snapshot(
          budgetLimitScaled100: null,
          foodLimitScaled100: 2500000,
        ),
      );
      addTearDown(harness.dispose);

      final dynamic state = harness.presentation.value;
      final dynamic partition = state.partition;

      expect(partition.hasPositiveAggregateLimit, isFalse);
      expect(partition.allocationRawRatio.isFinite, isTrue);
      expect(partition.allocationVisualCoverage.isFinite, isTrue);
      expect(partition.allocationVisualCoverage, 0);
    });

    test(
      'one active category tick updates header ring and partition before release',
      () {
        final repository = _CountingRepository();
        final harness = _Harness(
          repository: repository,
          snapshot: _snapshot(
            budgetLimitScaled100: 10000000,
            foodLimitScaled100: 2500000,
            foodActualScaled100: 1000000,
          ),
        );
        addTearDown(harness.dispose);
        harness.presentation.setTargetHandle(1);
        final beforeItems = harness.presentation.value.items;
        final dynamic beforePartition = harness.presentation.value.partition;
        final session = harness.edits.startEdit(
          harness.presentation.value.header.limitEditContext!,
        )!;

        harness.edits.applySemanticTick(
          session,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );

        final dynamic state = harness.presentation.value;
        final dynamic partition = state.partition;
        final dynamic food = partition.segmentForCategoryHandle(1);
        expect(state.header.limitScaled100, 2600000);
        expect(state.selectedLimitVisual.effectiveLimitScaled100, 2600000);
        expect(partition.liveAllocatedTotalScaled100, 2600000);
        expect(food.totalRatio, .26);
        expect(identical(state.items, beforeItems), isTrue);
        expect(identical(partition.bank, beforePartition.bank), isTrue);
        expect(repository.upsertCalls, 0);
        expect(repository.deleteCalls, 0);
      },
    );

    test('an active aggregate tick changes only the partition denominator', () {
      final repository = _CountingRepository();
      final harness = _Harness(
        repository: repository,
        snapshot: _snapshot(
          budgetLimitScaled100: 10000000,
          foodLimitScaled100: 2500000,
        ),
      );
      addTearDown(harness.dispose);
      final session = harness.edits.startEdit(
        harness.presentation.value.header.limitEditContext!,
      )!;

      harness.edits.applySemanticTick(
        session,
        direction: 1,
        amountStepScaled100: 10000000,
        tickCount: 1,
        source: DashboardBudgetLimitEditSource.drag,
      );

      final dynamic state = harness.presentation.value;
      final dynamic partition = state.partition;
      final dynamic food = partition.segmentForCategoryHandle(1);
      expect(partition.effectiveAggregateLimitScaled100, 20000000);
      expect(partition.liveAllocatedTotalScaled100, 2500000);
      expect(food.totalRatio, .125);
      expect(repository.upsertCalls, 0);
    });

    test(
      'pending category allocation stays live through a stale snapshot and reconciles once',
      () async {
        final harness = _Harness(
          snapshot: _snapshot(
            budgetLimitScaled100: 10000000,
            foodLimitScaled100: 2500000,
          ),
        );
        addTearDown(harness.dispose);
        harness.presentation.setTargetHandle(1);
        final session = harness.edits.startEdit(
          harness.presentation.value.header.limitEditContext!,
        )!;
        harness.edits.applySemanticTick(
          session,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        await harness.edits.finishEdit(session);

        harness.visible.notifyListeners();
        dynamic partition = harness.presentation.value.partition;
        expect(partition.liveAllocatedTotalScaled100, 2600000);
        expect(partition.optimisticAllocationDeltaScaled100, 100000);

        harness.publishSnapshot(
          _snapshot(
            coreRevision: 8,
            budgetLimitScaled100: 10000000,
            foodLimitScaled100: 2600000,
          ),
        );
        partition = harness.presentation.value.partition;
        expect(harness.presentation.value.header.limitScaled100, 2600000);
        expect(partition.liveAllocatedTotalScaled100, 2600000);
        expect(partition.optimisticAllocationDeltaScaled100, 0);

        harness.visible.notifyListeners();
        expect(
          (harness.presentation.value.partition as dynamic)
              .optimisticAllocationDeltaScaled100,
          0,
        );
      },
    );

    test(
      'multiple pending category mutations retain both effective segment limits',
      () async {
        final harness = _Harness(
          snapshot: _snapshot(
            budgetLimitScaled100: 10000000,
            foodLimitScaled100: 2500000,
            healthLimitScaled100: 5000000,
          ),
        );
        addTearDown(harness.dispose);

        harness.presentation.setTargetHandle(1);
        final food = harness.edits.startEdit(
          harness.presentation.value.header.limitEditContext!,
        )!;
        harness.edits.applySemanticTick(
          food,
          direction: 1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        await harness.edits.finishEdit(food);

        harness.presentation.setTargetHandle(2);
        final health = harness.edits.startEdit(
          harness.presentation.value.header.limitEditContext!,
        )!;
        harness.edits.applySemanticTick(
          health,
          direction: -1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        await harness.edits.finishEdit(health);

        final dynamic partition = harness.presentation.value.partition;
        final dynamic foodSegment = partition.segmentForCategoryHandle(1);
        final dynamic healthSegment = partition.segmentForCategoryHandle(2);
        expect(partition.liveAllocatedTotalScaled100, 7500000);
        expect(foodSegment.totalRatio, .26);
        expect(healthSegment.totalRatio, .49);

        // Health is selected, but Food is not. One exact newer prepared
        // revision must reconcile both pending mutations before the prepared
        // total replaces their incremental allocation delta.
        harness.publishSnapshot(
          _snapshot(
            coreRevision: 8,
            budgetLimitScaled100: 10000000,
            foodLimitScaled100: 2600000,
            healthLimitScaled100: 4900000,
          ),
        );
        final dynamic reconciled = harness.presentation.value.partition;
        expect(reconciled.liveAllocatedTotalScaled100, 7500000);
        expect(reconciled.optimisticAllocationDeltaScaled100, 0);
      },
    );

    test(
      'an active limit edit changes the selected warning tone before release',
      () {
        const accent = Color(0xff2374ab);
        final repository = _CountingRepository();
        final harness = _Harness(
          repository: repository,
          snapshot: _snapshot(
            budgetLimitScaled100: 10000000,
            foodLimitScaled100: 10000000,
            foodActualScaled100: 7499900,
          ),
        );
        addTearDown(harness.dispose);
        harness.presentation.setTargetHandle(1);
        final session = harness.edits.startEdit(
          harness.presentation.value.header.limitEditContext!,
        )!;

        Color tone() => BudgetLimitProgressToneResolver.resolve(
          rawProgress:
              harness.presentation.value.selectedLimitVisual.rawProgress,
          targetAccent: accent,
        );

        expect(tone(), accent);
        harness.edits.applySemanticTick(
          session,
          direction: -1,
          amountStepScaled100: 100000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        expect(tone(), FluviVisualTokens.budgetProgressWarning);
        harness.edits.applySemanticTick(
          session,
          direction: -1,
          amountStepScaled100: 2000000,
          tickCount: 1,
          source: DashboardBudgetLimitEditSource.drag,
        );
        expect(tone(), FluviVisualTokens.budgetProgressDanger);
        expect(repository.upsertCalls, 0);
      },
    );
  });
}

final class _Harness {
  _Harness({
    required PreparedBudgetLimitSnapshot snapshot,
    _CountingRepository? repository,
  }) : _snapshot = snapshot,
       repository = repository ?? _CountingRepository(),
       categories = ValueNotifier<List<FluviCategory>>(<FluviCategory>[
         _category('food', 'Food', 'color_01'),
         _category('health', 'Health', 'color_06'),
       ]),
       visible = ValueNotifier<DashboardVisibleFrame?>(_visibleFrame()),
       direction = TransactionDirectionController(
         initialDirection: TransactionDirection.expense,
       ) {
    late final DashboardBudgetPresentationController presentation;
    edits = DashboardBudgetLimitEditController(
      repository: this.repository,
      isKeyCurrent: (key) => presentation.value.header.limitKey == key,
    );
    presentation = DashboardBudgetPresentationController(
      categoryCollection: categories,
      visibleFrame: visible,
      transactionDirection: direction,
      snapshotForCurrentFrame: () => _snapshot,
      logicalAsOfDate: const LocalDate(year: 2026, month: 1, day: 10),
      limitEditController: edits,
    );
    this.presentation = presentation;
  }

  PreparedBudgetLimitSnapshot _snapshot;
  final _CountingRepository repository;
  final ValueNotifier<List<FluviCategory>> categories;
  final ValueNotifier<DashboardVisibleFrame?> visible;
  final TransactionDirectionController direction;
  late final DashboardBudgetLimitEditController edits;
  late final DashboardBudgetPresentationController presentation;

  void publishSnapshot(PreparedBudgetLimitSnapshot snapshot) {
    _snapshot = snapshot;
    visible.value = _visibleFrame(coreRevision: snapshot.coreRevision);
  }

  void dispose() {
    presentation.dispose();
    edits.dispose();
    categories.dispose();
    visible.dispose();
    direction.dispose();
  }
}

PreparedBudgetLimitSnapshot _snapshot({
  int coreRevision = 7,
  required int? budgetLimitScaled100,
  int budgetActualScaled100 = 0,
  int? foodLimitScaled100,
  int foodActualScaled100 = 0,
  int? healthLimitScaled100,
  int healthActualScaled100 = 0,
}) {
  final cells = List<PreparedBudgetLimitCell>.filled(
    42,
    const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
  );
  const targetCount = 3;
  const januarySlice = 2;
  void set(int handle, int actual, int? limit) {
    cells[januarySlice * targetCount + handle] = PreparedBudgetLimitCell(
      actualScaled100: actual,
      limitScaled100: limit,
    );
  }

  set(0, budgetActualScaled100, budgetLimitScaled100);
  set(1, foodActualScaled100, foodLimitScaled100);
  set(2, healthActualScaled100, healthLimitScaled100);
  PreparedBudgetLimitDirectionBank bank() => PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>['food', 'health'],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: coreRevision,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: bank(),
    expenseBank: bank(),
  );
}

FluviCategory _category(String id, String name, String colorId) =>
    FluviCategory(
      id: id,
      name: name,
      colorId: colorId,
      iconId: 'icon_01',
      isSystemUncategorized: false,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );

DashboardVisibleFrame _visibleFrame({int coreRevision = 7}) {
  const scope = MonthScope(YearMonth(year: 2026, month: 1));
  final queryScope = CurrentLedgerQueryScope(
    direction: LedgerDirection.expense,
    timeScope: scope,
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

final class _CountingRepository implements FinancialLimitRepository {
  var upsertCalls = 0;
  var deleteCalls = 0;

  @override
  Future<bool> delete(FinancialLimitKey key) {
    deleteCalls += 1;
    return Future<bool>.value(true);
  }

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) =>
      Future<FinancialLimit?>.value(null);

  @override
  Future<List<FinancialLimit>> list() =>
      Future<List<FinancialLimit>>.value(const <FinancialLimit>[]);

  @override
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100) {
    upsertCalls += 1;
    return Future<FinancialLimit>.value(
      FinancialLimit(
        key: key,
        amountScaled100: amountScaled100,
        createdAtUtcMs: 1,
        updatedAtUtcMs: 1,
      ),
    );
  }
}
