import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/logbox/application/dashboard_log_viewport_state.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_presentation_frame.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/dashboard_directional_query_set.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/runtime/domain/prepared_dashboard_index.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('prepared index identity owns both independent directional filters', () {
    CurrentLedgerQueryScope template(
      LedgerDirection direction, {
      Set<String> categories = const <String>{},
    }) => CurrentLedgerQueryScope(
      direction: direction,
      timeScope: const AllTimeScope(),
      categoryIds: categories,
    );

    final first = DashboardDirectionalQuerySet(
      income: template(LedgerDirection.income),
      expense: template(LedgerDirection.expense, categories: const <String>{'food'}),
    );
    final changedIncome = first.replaceDirection(
      LedgerDirection.income,
      template(LedgerDirection.income, categories: const <String>{'salary'}),
    );
    final changedExpense = first.replaceDirection(
      LedgerDirection.expense,
      template(LedgerDirection.expense, categories: const <String>{'travel'}),
    );

    PreparedDashboardIndexKey keyFor(DashboardDirectionalQuerySet queries) =>
        PreparedDashboardIndexKey.fromDirectionalQuerySet(
          queries: queries,
          coreRevision: 3,
          pageSize: 24,
          yearWindowStart: 2014,
          yearWindowEndInclusive: 2038,
        );

    final firstKey = keyFor(first);
    expect(firstKey, isNot(keyFor(changedIncome)));
    expect(firstKey, isNot(keyFor(changedExpense)));
    expect(firstKey.matchesScope(first.income), isTrue);
    expect(firstKey.matchesScope(first.expense), isTrue);
    expect(firstKey.matchesScope(changedIncome.income), isFalse);
    expect(firstKey.matchesScope(changedExpense.expense), isFalse);
  });

  test('zero universe derives each direction from its own query template', () {
    final income = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const AllTimeScope(),
    );
    final expense = CurrentLedgerQueryScope(
      direction: LedgerDirection.expense,
      timeScope: const AllTimeScope(),
      temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 6),
        QueryPeriodSelection.month(2026, 8),
      }),
      categoryIds: const <String>{'food'},
    );
    final queries = DashboardDirectionalQuerySet(
      income: income,
      expense: expense,
    );
    final key = PreparedDashboardIndexKey.fromDirectionalQuerySet(
      queries: queries,
      coreRevision: 3,
      pageSize: 24,
      yearWindowStart: 2025,
      yearWindowEndInclusive: 2027,
    );

    final universe = PreparedDashboardIndexAssembly.zeroUniverse(
      key: key,
      directionalQueries: queries,
      initialYear: 2026,
    );

    expect(universe.catalogs[income.key]!.values, <int>[2025, 2026, 2027]);
    expect(universe.catalogs[expense.key]!.values, <int>[2026]);
    expect(
      universe.catalogs[
              expense.copyWith(timeScope: const YearScope(2026)).key]!
          .values,
      <int>[6, 8],
    );
    expect(
      universe.scopes.values
          .where((scope) => scope.direction == LedgerDirection.expense)
          .every((scope) => scope.categoryIds.contains('food')),
      isTrue,
    );
  });

  test('acquisition reasons expose no navigation-triggered capability', () {
    expect(DataAcquisitionReason.values, <DataAcquisitionReason>[
      DataAcquisitionReason.bootstrap,
      DataAcquisitionReason.databaseRevision,
      DataAcquisitionReason.query,
      DataAcquisitionReason.explicitCommittedVerticalPaging,
    ]);
  });

  test('one immutable index serves both directions by exact RAM lookup', () {
    final index = _index();
    final incomeDay = _scope(
      LedgerDirection.income,
      DayScope(const LocalDate(year: 2026, month: 7, day: 19)),
    );
    final expenseDay = _scope(
      LedgerDirection.expense,
      DayScope(const LocalDate(year: 2026, month: 7, day: 19)),
    );

    expect(index.frameFor(incomeDay).queryKey, incomeDay.key);
    expect(
      index.frameFor(incomeDay).parentQueryKey,
      _scope(
        LedgerDirection.income,
        MonthScope(const YearMonth(year: 2026, month: 7)),
      ).key,
    );
    expect(index.frameForKey(incomeDay.key), same(index.frames[incomeDay.key]));
    expect(index.frameFor(incomeDay).amount.totalMinor, 1900);
    expect(index.frameFor(expenseDay).queryKey, expenseDay.key);
    expect(index.frameFor(expenseDay).amount.totalMinor, 3800);
    expect(index.coreRevision, 7);
    expect(index.frames, isA<Map<LedgerQueryKey, DashboardPreparedFrame>>());
  });

  test('missing periods resolve to a deterministic synchronous zero frame', () {
    final index = _index();
    final missing = _scope(
      LedgerDirection.income,
      DayScope(const LocalDate(year: 2039, month: 2, day: 3)),
    );

    final first = index.frameFor(missing);
    final second = index.frameFor(missing);

    expect(first.queryKey, missing.key);
    expect(first.coreRevision, 7);
    expect(first.totalMinor, 0);
    expect(first.entryCount, 0);
    expect(first.amount.formattedAmount, '0 Ft');
    expect(() => index.frameForKey(missing.key), throwsStateError);
    expect(first.logBox.groups, isEmpty);
    expect(index.originFor(missing.key), DashboardDataOrigin.deterministicZero);
    expect(second.presentationDigest, first.presentationDigest);
  });

  test('catalog selection is an exact prebuilt parent lookup', () {
    final index = _index();
    final parent = _scope(
      LedgerDirection.income,
      MonthScope(const YearMonth(year: 2026, month: 7)),
    );

    final catalog = index.catalogFor(parent);

    expect(catalog.parentScope.key, parent.key);
    expect(
      index.catalogForIdentity(
        direction: parent.direction,
        timeScope: parent.timeScope,
      ),
      same(catalog),
    );
    expect(catalog.childKind, DashboardChildKind.day);
    expect(catalog.length, 31);
    expect(
      catalog.entryAtLogicalIndex(18).queryKey.value,
      contains('2026-07-19'),
    );
  });

  test(
    'filter identity mismatch fails closed instead of returning stale data',
    () {
      final index = _index();
      final mismatched = CurrentLedgerQueryScope(
        direction: LedgerDirection.income,
        timeScope: DayScope(const LocalDate(year: 2026, month: 7, day: 19)),
        categoryIds: const {'different-category'},
      );

      expect(() => index.frameFor(mismatched), throwsStateError);
    },
  );
}

PreparedDashboardIndex _index() {
  final frames = <LedgerQueryKey, DashboardPreparedFrame>{};
  final catalogs = <LedgerQueryKey, DashboardSemanticCatalog>{};
  for (final direction in LedgerDirection.values) {
    final parent = _scope(
      direction,
      MonthScope(const YearMonth(year: 2026, month: 7)),
    );
    final catalog = DashboardSemanticCatalog.forParent(
      parentScope: parent,
      childKind: DashboardChildKind.day,
    );
    catalogs[parent.key] = catalog;
    frames[parent.key] = _frame(
      parent,
      totalMinor: direction == LedgerDirection.income ? 49600 : 99200,
    );
    for (final entry in catalog.entries) {
      frames[entry.queryKey] = _frame(
        entry.scope,
        totalMinor:
            entry.value * (direction == LedgerDirection.income ? 100 : 200),
      );
    }
  }
  return PreparedDashboardIndex.complete(
    key: const PreparedDashboardIndexKey(
      modelVersion: 2,
      coreRevision: 7,
      categoryIdsKey: '',
      partnerIdsKey: '',
      refinementsKey: '',
      temporalFilterKey: 'all',
      pageSize: 24,
      yearWindowStart: 2014,
      yearWindowEndInclusive: 2038,
    ),
    frames: frames,
    catalogs: catalogs,
    generation: 3,
    contentDigest: 991,
    preparedAt: DateTime.utc(2026, 8, 6),
    buildMetrics: const PreparedDashboardIndexBuildMetrics.synthetic(),
  );
}

CurrentLedgerQueryScope _scope(
  LedgerDirection direction,
  LedgerTimeScope timeScope,
) => CurrentLedgerQueryScope(direction: direction, timeScope: timeScope);

DashboardPreparedFrame _frame(
  CurrentLedgerQueryScope scope, {
  required int totalMinor,
}) => DashboardPreparedFrame.complete(
  scope: scope,
  parentQueryKey: dashboardPreparedParentQueryKey(scope),
  coreRevision: 7,
  totalMinor: totalMinor,
  formattedAmount: '$totalMinor Ft',
  entryCount: totalMinor == 0 ? 0 : 1,
  formattedEntryCount: totalMinor == 0 ? '0' : '1',
  logBox: DashboardLogViewportState(
    queryKey: scope.key,
    revision: 7,
    groups: const [],
    entryCount: totalMinor == 0 ? 0 : 1,
    nextCursor: null,
    direction: scope.direction,
  ),
  presentationDigest: Object.hash(scope.key, totalMinor, 7),
);
