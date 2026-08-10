import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/application/query_menu_data_controller.dart';
import 'package:fluvi/features/dashboard/query/data/query_menu_repository.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'latest draft facet response wins without clearing the prior result',
    () async {
      final repository = _Repository();
      final controller = QueryMenuDataController(repository: repository);
      addTearDown(controller.dispose);
      final income = _scope(LedgerDirection.income);
      final expense = _scope(LedgerDirection.expense);

      final first = controller.refresh(income);
      final second = controller.refresh(expense);
      repository.complete(1, _data(8));
      await second;
      repository.complete(0, _data(3));
      await first;

      expect(controller.data?.result.entryCount, 8);
      expect(controller.lastScope, expense);
      expect(controller.isLoading, isFalse);
    },
  );
}

CurrentLedgerQueryScope _scope(LedgerDirection direction) =>
    CurrentLedgerQueryScope(
      direction: direction,
      timeScope: const AllTimeScope(),
    );

QueryMenuData _data(int count) => QueryMenuData(
  result: QueryMenuResultSummary(entryCount: count, amountScaled100: count),
  amountDomain: const QueryMenuAmountDomain(
    minimumAmountScaled100: 0,
    maximumAmountScaled100: 100,
  ),
  availableMonths: const <QueryMenuAvailableMonth>[],
  categories: const <QueryMenuCategoryFacet>[],
  partners: const <QueryMenuPartnerFacet>[],
);

final class _Repository implements QueryMenuRepository {
  final List<Completer<QueryMenuData>> _pending = <Completer<QueryMenuData>>[];

  @override
  Future<QueryMenuData> readFacets(CurrentLedgerQueryScope draft) {
    final completer = Completer<QueryMenuData>();
    _pending.add(completer);
    return completer.future;
  }

  void complete(int index, QueryMenuData value) =>
      _pending[index].complete(value);

  @override
  Future<SavedLedgerQuery> createSaved({
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => throw UnimplementedError();

  @override
  Future<void> deleteSaved({required String id}) => throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> loadSaved({
    required String id,
    required LedgerDirection activeDirection,
  }) => throw UnimplementedError();

  @override
  Future<List<SavedLedgerQuery>> listSaved(LedgerDirection direction) =>
      throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> renameSaved({
    required String id,
    required String name,
  }) => throw UnimplementedError();

  @override
  Future<SavedLedgerQuery> updateSaved({
    required String id,
    required String name,
    required CurrentLedgerQueryScope scope,
  }) => throw UnimplementedError();
}
