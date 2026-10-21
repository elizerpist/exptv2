import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/categories/domain/fluvi_category.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_repository.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_limit_edit_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_presentation_controller.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_target.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_limit_manager.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_budget_limit_snapshot.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/visible/domain/dashboard_visible_frame.dart';

void main() {
  testWidgets(
    'fullscreen manager renders the canonical base editor, metrics and 4x3 month overview',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final repository = _TimelineRepository(_timeline());
      final edits = DashboardBudgetLimitEditController(
        repository: repository,
        isKeyCurrent: (_) => true,
      );
      final categories = ValueNotifier<List<FluviCategory>>(
        const <FluviCategory>[],
      );
      final visible = ValueNotifier<DashboardVisibleFrame?>(null);
      final direction = TransactionDirectionController(
        initialDirection: TransactionDirection.expense,
      );
      final presentation = DashboardBudgetPresentationController(
        categoryCollection: categories,
        visibleFrame: visible,
        transactionDirection: direction,
        snapshotForCurrentFrame: _snapshot,
        logicalAsOfDate: const LocalDate(year: 2026, month: 10, day: 21),
        limitEditController: edits,
      );
      addTearDown(edits.dispose);
      addTearDown(presentation.dispose);
      addTearDown(categories.dispose);
      addTearDown(visible.dispose);
      addTearDown(direction.dispose);

      await tester.pumpWidget(
        MaterialApp(
          home: BudgetLimitManager(
            request: const BudgetLimitManagerRequest(
              direction: LedgerDirection.expense,
              target: DashboardBudgetTarget.aggregate(),
              targetHandle: 0,
              title: 'Összes kiadás',
              accent: Color(0xff7863c9),
              avatar: Icon(Icons.account_balance_wallet_rounded),
              coreRevision: 41,
            ),
            presentation: presentation,
            limitEdits: edits,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey<String>('budget-limit-manager-base-editor')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('budget-limit-manager-metrics')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('budget-limit-manager-month-grid')),
        findsOneWidget,
      );
      expect(find.text('180 000 Ft'), findsWidgets);
      expect(find.text('Egyedi'), findsOneWidget);
      expect(find.text('Folyamatban'), findsOneWidget);
      expect(find.text('Nincs keret'), findsNothing);

      await expectLater(
        find.byType(BudgetLimitManager),
        matchesGoldenFile('../../../goldens/budget_limit_manager.png'),
      );

      // A base edit writes the revision anchored at logical-current October;
      // it does not mutate the March historical base used by the sheet below.
      await tester.tap(
        find.byKey(const ValueKey<String>('budget-limit-manager-base-editor')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('+10000'));
      await tester.tap(find.text('Mentés'));
      await tester.pumpAndSettle();
      expect(
        repository.amountFor(
          const FinancialLimitBaseMonthlyRevisionPeriod(2026, 10),
        ),
        21000000,
      );
      expect(
        repository.revisionCount(
          const FinancialLimitBaseMonthlyRevisionPeriod(2026, 10),
        ),
        1,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('budget-limit-manager-month-card-2026-3'),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Vissza az alapértékhez'), findsOneWidget);
      expect(find.text('Alap havi keret: 160 000 Ft'), findsOneWidget);
    },
  );
}

List<FinancialLimit> _timeline() => <FinancialLimit>[
  _limit(const FinancialLimitBaseMonthlyRevisionPeriod(2025, 1), 16000000),
  _limit(const FinancialLimitBaseMonthlyRevisionPeriod(2026, 4), 18000000),
  _limit(const FinancialLimitBaseMonthlyRevisionPeriod(2026, 10), 20000000),
  _limit(const FinancialLimitMonthOverridePeriod(2026, 3), 22000000),
];

FinancialLimit _limit(FinancialLimitPeriod period, int amountScaled100) =>
    FinancialLimit(
      key: FinancialLimitKey(
        direction: FinancialLimitDirection.expense,
        target: const FinancialLimitAggregateTarget(),
        period: period,
      ),
      amountScaled100: amountScaled100,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );

PreparedBudgetLimitSnapshot _snapshot() {
  const targetCount = 1;
  const periodSliceCount = 14; // SUM + YEAR + Jan..Dec
  final List<PreparedBudgetLimitCell> cells =
      List<PreparedBudgetLimitCell>.filled(
        periodSliceCount * targetCount,
        const PreparedBudgetLimitCell(actualScaled100: 0, limitScaled100: null),
      );
  var annualActual = 0;
  var annualLimit = 0;
  for (var month = 1; month <= 12; month += 1) {
    final limit = month <= 3
        ? 16000000
        : month < 10
        ? 18000000
        : 20000000;
    final actual = month <= 9 ? (month.isEven ? 15000000 : 19000000) : 0;
    cells[1 + 1 + month - 1] = PreparedBudgetLimitCell(
      actualScaled100: actual,
      limitScaled100: limit,
      limitSource: PreparedBudgetLimitSource.base,
    );
    annualActual += actual;
    annualLimit += limit;
  }
  cells[0] = const PreparedBudgetLimitCell(
    actualScaled100: 0,
    limitScaled100: 20000000,
    limitSource: PreparedBudgetLimitSource.base,
  );
  cells[1] = PreparedBudgetLimitCell(
    actualScaled100: annualActual,
    limitScaled100: annualLimit,
  );
  final populated = PreparedBudgetLimitDirectionBank(
    orderedCategoryIds: const <String>[],
    cells: cells,
  );
  return PreparedBudgetLimitSnapshot(
    coreRevision: 41,
    yearWindowStart: 2026,
    yearWindowEndInclusive: 2026,
    incomeBank: populated,
    expenseBank: populated,
  );
}

final class _TimelineRepository implements FinancialLimitRepository {
  _TimelineRepository(this._values);

  final List<FinancialLimit> _values;

  int? amountFor(FinancialLimitPeriod period) {
    for (final value in _values) {
      if (value.key.period == period) return value.amountScaled100;
    }
    return null;
  }

  int revisionCount(FinancialLimitPeriod period) =>
      _values.where((value) => value.key.period == period).length;

  @override
  Future<bool> delete(FinancialLimitKey key) async {
    final existing = _values.any((value) => value.key == key);
    _values.removeWhere((value) => value.key == key);
    return existing;
  }

  @override
  Future<FinancialLimit?> get(FinancialLimitKey key) async {
    for (final value in _values) {
      if (value.key == key) return value;
    }
    return null;
  }

  @override
  Future<List<FinancialLimit>> list() async => List<FinancialLimit>.of(_values);

  @override
  Future<FinancialLimit> upsert(
    FinancialLimitKey key,
    int amountScaled100,
  ) async {
    final value = FinancialLimit(
      key: key,
      amountScaled100: amountScaled100,
      createdAtUtcMs: 1,
      updatedAtUtcMs: 1,
    );
    _values.removeWhere((current) => current.key == key);
    _values.add(value);
    return value;
  }

  @override
  Future<List<FinancialLimit>> upsertBatch(
    List<FinancialLimitMutation> values,
  ) => Future.wait(
    values.map((value) => upsert(value.key, value.amountScaled100)),
  );
}
