import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_category_presentation.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'derives ordered avatar inputs only from the applied active-direction facets',
    () {
      final income = _scope(LedgerDirection.income);
      final query = CurrentQueryController(initialScope: income);
      final direction = TransactionDirectionController();
      final presentation = DashboardBudgetCategoryPresentation(
        currentQuery: query,
        transactionDirection: direction,
      );
      addTearDown(presentation.dispose);
      addTearDown(query.dispose);
      addTearDown(direction.dispose);

      expect(presentation.value, isEmpty);

      query.apply(
        income,
        facetPresentation: _data(const [
          ('groceries', 'Groceries', 'color_08', 'icon_08'),
          ('travel', 'Travel', 'color_13', 'icon_11'),
        ]),
      );

      expect(presentation.value.map((item) => item.id), [
        'groceries',
        'travel',
      ]);
      expect(presentation.value[0].colorId, 'color_08');
      expect(presentation.value[0].iconId, 'icon_08');

      direction.select(TransactionDirection.expense);
      expect(presentation.value, isEmpty);

      final expense = _scope(LedgerDirection.expense);
      query.apply(
        expense,
        facetPresentation: _data(const [
          ('fuel', 'Fuel', 'color_03', 'icon_13'),
        ]),
      );

      expect(presentation.value.single.id, 'fuel');
      expect(presentation.value.single.displayName, 'Fuel');
    },
  );
}

CurrentLedgerQueryScope _scope(LedgerDirection direction) =>
    CurrentLedgerQueryScope(
      direction: direction,
      timeScope: const AllTimeScope(),
    );

QueryMenuData _data(List<(String, String, String, String)> categories) =>
    QueryMenuData(
      result: const QueryMenuResultSummary(entryCount: 0, amountScaled100: 0),
      amountDomain: const QueryMenuAmountDomain(
        minimumAmountScaled100: 0,
        maximumAmountScaled100: 0,
      ),
      availableMonths: const [],
      categories: [
        for (final category in categories)
          QueryMenuCategoryFacet(
            id: category.$1,
            displayName: category.$2,
            colorId: category.$3,
            iconId: category.$4,
            entryCount: 0,
          ),
      ],
      partners: const [],
    );
