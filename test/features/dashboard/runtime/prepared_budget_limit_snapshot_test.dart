import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PreparedBudgetLimitSnapshot', () {
    test('keeps category handles local to each direction bank', () {
      final snapshot = PreparedBudgetLimitSnapshot(
        coreRevision: 41,
        yearWindowStart: 2026,
        yearWindowEndInclusive: 2026,
        incomeBank: PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>['salary', 'other-income'],
          cells: List<PreparedBudgetLimitCell>.filled(
            42,
            const PreparedBudgetLimitCell(
              actualScaled100: 0,
              limitScaled100: null,
            ),
          ),
        ),
        expenseBank: PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>['rent', 'food', 'travel'],
          cells: List<PreparedBudgetLimitCell>.filled(
            56,
            const PreparedBudgetLimitCell(
              actualScaled100: 0,
              limitScaled100: null,
            ),
          ),
        ),
      );

      expect(
        snapshot.directionBank(LedgerDirection.income).orderedCategoryIds,
        const <String>['salary', 'other-income'],
      );
      expect(
        snapshot.directionBank(LedgerDirection.expense).orderedCategoryIds,
        const <String>['rent', 'food', 'travel'],
      );
      expect(snapshot.targetCountFor(LedgerDirection.income), 3);
      expect(snapshot.targetCountFor(LedgerDirection.expense), 4);
    });

    test('uses dense arithmetic slices and preserves missing versus zero', () {
      final snapshot = PreparedBudgetLimitSnapshot(
        coreRevision: 41,
        yearWindowStart: 2025,
        yearWindowEndInclusive: 2026,
        incomeBank: PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>['food'],
          cells: List<PreparedBudgetLimitCell>.generate(
            54,
            (index) => PreparedBudgetLimitCell(
              actualScaled100: index == 0 ? 100 : index * 100,
              limitScaled100: index == 0
                  ? null
                  : index == 1
                  ? 0
                  : index * 100 + 100,
            ),
          ),
        ),
        expenseBank: PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>['food'],
          cells: List<PreparedBudgetLimitCell>.generate(
            54,
            (index) => PreparedBudgetLimitCell(
              actualScaled100: index == 0 ? 100 : index * 100,
              limitScaled100: index == 0
                  ? null
                  : index == 1
                  ? 0
                  : index * 100 + 100,
            ),
          ),
        ),
      );

      expect(snapshot.targetCountFor(LedgerDirection.income), 2);
      expect(snapshot.sliceIndexFor(const BudgetLimitPeriod.sum()), 0);
      expect(snapshot.sliceIndexFor(const BudgetLimitPeriod.year(2025)), 1);
      expect(
        snapshot.sliceIndexFor(const BudgetLimitPeriod.month(2026, 12)),
        1 + 2 + 12 + 11,
      );
      expect(
        snapshot
            .cellAt(
              direction: LedgerDirection.income,
              period: const BudgetLimitPeriod.sum(),
              targetHandle: 0,
            )
            .hasLimit,
        isFalse,
      );
      expect(
        snapshot
            .cellAt(
              direction: LedgerDirection.income,
              period: const BudgetLimitPeriod.sum(),
              targetHandle: 1,
            )
            .limitScaled100,
        0,
      );
    });

    test(
      'prepares one positive category-allocation total per period slice',
      () {
        final cells = _emptyCells(periodSliceCount: 14, targetCount: 3);
        _setLimit(cells, targetCount: 3, slice: 0, handle: 0, amount: 100000);
        _setLimit(cells, targetCount: 3, slice: 0, handle: 1, amount: 25000);
        _setLimit(cells, targetCount: 3, slice: 0, handle: 2, amount: 50000);
        final dynamic bank = PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>['food', 'health'],
          cells: cells,
        );

        expect(bank.allocatedCategoryLimitTotalScaled100ByPeriodSlice, <int>[
          75000,
          ...List<int>.filled(13, 0),
        ]);
      },
    );

    test(
      'keeps prepared allocation totals isolated by period and direction',
      () {
        final incomeCells = _emptyCells(periodSliceCount: 14, targetCount: 2);
        _setLimit(
          incomeCells,
          targetCount: 2,
          slice: 2,
          handle: 1,
          amount: 12000,
        );
        final expenseCells = _emptyCells(periodSliceCount: 14, targetCount: 2);
        _setLimit(
          expenseCells,
          targetCount: 2,
          slice: 2,
          handle: 1,
          amount: 34000,
        );
        _setLimit(
          expenseCells,
          targetCount: 2,
          slice: 13,
          handle: 1,
          amount: 56000,
        );
        final snapshot = PreparedBudgetLimitSnapshot(
          coreRevision: 41,
          yearWindowStart: 2026,
          yearWindowEndInclusive: 2026,
          incomeBank: PreparedBudgetLimitDirectionBank(
            orderedCategoryIds: const <String>['salary'],
            cells: incomeCells,
          ),
          expenseBank: PreparedBudgetLimitDirectionBank(
            orderedCategoryIds: const <String>['food'],
            cells: expenseCells,
          ),
        );
        final dynamic income = snapshot.directionBank(LedgerDirection.income);
        final dynamic expense = snapshot.directionBank(LedgerDirection.expense);

        expect(income.allocatedCategoryLimitTotalScaled100ByPeriodSlice, <int>[
          0,
          0,
          12000,
          ...List<int>.filled(11, 0),
        ]);
        expect(expense.allocatedCategoryLimitTotalScaled100ByPeriodSlice, <int>[
          0,
          0,
          34000,
          ...List<int>.filled(10, 0),
          56000,
        ]);
      },
    );

    test(
      'prepared allocation ignores aggregate, null, and zero category limits',
      () {
        final cells = _emptyCells(periodSliceCount: 14, targetCount: 4);
        _setLimit(cells, targetCount: 4, slice: 0, handle: 0, amount: 100000);
        _setLimit(cells, targetCount: 4, slice: 0, handle: 1, amount: null);
        _setLimit(cells, targetCount: 4, slice: 0, handle: 2, amount: 0);
        _setLimit(cells, targetCount: 4, slice: 0, handle: 3, amount: 12500);
        final dynamic bank = PreparedBudgetLimitDirectionBank(
          orderedCategoryIds: const <String>['food', 'health', 'travel'],
          cells: cells,
        );

        expect(
          bank.allocatedCategoryLimitTotalScaled100ByPeriodSlice.first,
          12500,
        );
      },
    );
  });
}

List<PreparedBudgetLimitCell> _emptyCells({
  required int periodSliceCount,
  required int targetCount,
}) => List<PreparedBudgetLimitCell>.filled(
  periodSliceCount * targetCount,
  const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
);

void _setLimit(
  List<PreparedBudgetLimitCell> cells, {
  required int targetCount,
  required int slice,
  required int handle,
  required int? amount,
}) {
  final index = slice * targetCount + handle;
  cells[index] = PreparedBudgetLimitCell(
    actualScaled100: cells[index].actualScaled100,
    limitScaled100: amount,
  );
}
