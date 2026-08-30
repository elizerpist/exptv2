import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/current_query_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  CurrentLedgerQueryScope scope(
    LedgerDirection direction, {
    Set<String> categories = const <String>{},
    QueryTemporalFilter temporalFilter = const QueryTemporalFilter.allTime(),
  }) => CurrentLedgerQueryScope(
    direction: direction,
    timeScope: const AllTimeScope(),
    categoryIds: categories,
    temporalFilter: temporalFilter,
  );

  test('applied query retains independent income and expense templates', () {
    final controller = CurrentQueryController(
      initialScope: scope(LedgerDirection.income),
    );
    addTearDown(controller.dispose);

    final incomeBefore = controller.scopeFor(LedgerDirection.income);
    final expenseFood = scope(
      LedgerDirection.expense,
      categories: const <String>{'food'},
    );
    controller.replaceDirection(LedgerDirection.expense, expenseFood);

    expect(controller.scopeFor(LedgerDirection.income), incomeBefore);
    expect(controller.scopeFor(LedgerDirection.expense), expenseFood);

    final incomeMonth = scope(
      LedgerDirection.income,
      temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 7),
      }),
    );
    controller.replaceDirection(LedgerDirection.income, incomeMonth);

    expect(controller.scopeFor(LedgerDirection.income), incomeMonth);
    expect(controller.scopeFor(LedgerDirection.expense), expenseFood);
  });

  test(
    'reading another direction never mutates the applied query generation',
    () {
      final controller = CurrentQueryController(
        initialScope: scope(LedgerDirection.expense),
      );
      addTearDown(controller.dispose);

      final before = controller.generation;
      expect(
        controller.scopeFor(LedgerDirection.income).direction,
        LedgerDirection.income,
      );
      expect(
        controller.scopeFor(LedgerDirection.expense).direction,
        LedgerDirection.expense,
      );

      expect(controller.generation, before);
    },
  );

  test(
    'RG-G5: a transient unavailable projection cannot erase the exact applied amount domain',
    () {
      final expense = scope(LedgerDirection.expense);
      final controller = CurrentQueryController(initialScope: expense);
      addTearDown(controller.dispose);
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 18, amountScaled100: 0),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 0,
          maximumAmountScaled100: 8500000,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );

      controller.replaceDirection(
        LedgerDirection.expense,
        expense,
        facetPresentation: facets,
      );
      controller.replaceDirection(LedgerDirection.expense, expense);

      expect(
        controller.facetPresentationFor(LedgerDirection.expense)?.amountDomain,
        facets.amountDomain,
        reason:
            'Mind and Query Menu must retain the same exact QueryMenuData '
            'domain during a transient renderer/projection gap.',
      );
    },
  );

  test(
    'amount-only replacement retains its canonical domain while other facets may refresh',
    () {
      final expense = scope(LedgerDirection.expense);
      final controller = CurrentQueryController(initialScope: expense);
      addTearDown(controller.dispose);
      const facets = QueryMenuData(
        result: QueryMenuResultSummary(entryCount: 18, amountScaled100: 0),
        amountDomain: QueryMenuAmountDomain(
          minimumAmountScaled100: 50000,
          maximumAmountScaled100: 26000000,
        ),
        availableMonths: <QueryMenuAvailableMonth>[],
        categories: <QueryMenuCategoryFacet>[],
        partners: <QueryMenuPartnerFacet>[],
      );
      controller.replaceDirection(
        LedgerDirection.expense,
        expense,
        facetPresentation: facets,
      );

      final narrowed = expense.copyWith(
        refinements: const <String, Object?>{
          QueryAmountRange.minimumRefinementKey: 400000,
          QueryAmountRange.maximumRefinementKey: 900000,
        },
      );
      controller.replaceDirection(LedgerDirection.expense, narrowed);

      expect(
        controller.amountDomainFor(LedgerDirection.expense),
        same(facets.amountDomain),
      );
      controller.replaceDirection(
        LedgerDirection.expense,
        narrowed.copyWith(categoryIds: const <String>{'food'}),
      );
      expect(controller.amountDomainFor(LedgerDirection.expense), isNull);
    },
  );
}
