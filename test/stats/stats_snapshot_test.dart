import 'dart:async';

import 'package:exptv2/features/stats/data/stats_snapshot.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('snapshot include mask applies only checked fields on recall', () {
    final current = const StatsSnapshotState(
      categoryScopeIds: {1, 2},
      vendorScopeNames: {'Spar'},
      activeType: TransactionType.expense,
      threshold: 5000,
      layoutMode: StatsLayoutMode.year,
      activeYear: 2026,
      activeMonth: 7,
      pageIndex: 0,
    );
    final snapshot = StatsSnapshot(
      id: 'income-focus',
      name: 'Bevétel fókusz',
      createdAt: DateTime(2026, 7, 11, 10),
      updatedAt: DateTime(2026, 7, 11, 10),
      includeCategoryScope: false,
      includeVendorScope: true,
      includeActiveType: true,
      includeThreshold: false,
      includeLayoutMode: true,
      includePageIndex: true,
      categoryScopeIds: const {9},
      vendorScopeNames: const {'BKK'},
      activeType: TransactionType.income,
      threshold: 25000,
      layoutMode: StatsLayoutMode.month,
      activeYear: 2025,
      activeMonth: 3,
      pageIndex: 1,
    );

    final applied = snapshot.applyTo(current);

    expect(applied.categoryScopeIds, {1, 2});
    expect(applied.vendorScopeNames, {'BKK'});
    expect(applied.activeType, TransactionType.income);
    expect(applied.threshold, 5000);
    expect(applied.layoutMode, StatsLayoutMode.month);
    expect(applied.activeYear, 2025);
    expect(applied.activeMonth, 3);
    expect(applied.pageIndex, 0);
  });

  test('in-memory repository upserts include mask snapshots', () async {
    final repository = InMemoryStatsSnapshotRepository();
    final snapshot = StatsSnapshot(
      id: 's1',
      name: 'Munka',
      createdAt: DateTime(2026, 7, 11, 10),
      updatedAt: DateTime(2026, 7, 11, 11),
      includeCategoryScope: true,
      includeVendorScope: true,
      includeActiveType: true,
      includeThreshold: true,
      includeLayoutMode: true,
      includePageIndex: true,
      categoryScopeIds: const {1, 3},
      vendorScopeNames: const {'Teszt'},
      activeType: TransactionType.expense,
      threshold: 15000,
      layoutMode: StatsLayoutMode.sum,
      activeYear: 2026,
      activeMonth: 7,
      pageIndex: 0,
    );

    await repository.upsert(snapshot);
    final reloaded = await repository.load();

    expect(reloaded, hasLength(1));
    expect(reloaded.single.id, 's1');
    expect(reloaded.single.name, 'Munka');
    expect(reloaded.single.categoryScopeIds, {1, 3});
    expect(reloaded.single.vendorScopeNames, {'Teszt'});
    expect(reloaded.single.threshold, 15000);
    expect(reloaded.single.layoutMode, StatsLayoutMode.sum);
  });

  test('snapshot recall preserves the current chevron page', () {
    const current = StatsSnapshotState(
      categoryScopeIds: {},
      vendorScopeNames: {},
      activeType: TransactionType.expense,
      threshold: 5000,
      layoutMode: StatsLayoutMode.year,
      activeYear: 2026,
      activeMonth: 7,
      pageIndex: 0,
    );
    final snapshot = StatsSnapshot(
      id: 'legacy-page-two',
      name: 'Legacy',
      createdAt: DateTime(2026, 7, 11),
      updatedAt: DateTime(2026, 7, 11),
      includeCategoryScope: false,
      includeVendorScope: false,
      includeActiveType: false,
      includeThreshold: false,
      includeLayoutMode: false,
      includePageIndex: true,
      pageIndex: 1,
    );

    expect(snapshot.applyTo(current).pageIndex, 0);
    expect(snapshot.toJson()['pageIndex'], 1);
  });

  test('in-memory repository edit replaces the same snapshot row', () async {
    final createdAt = DateTime(2026, 7, 11, 10);
    final repository = InMemoryStatsSnapshotRepository([
      StatsSnapshot(
        id: 'same-id',
        name: 'Before',
        createdAt: createdAt,
        updatedAt: createdAt,
        includeCategoryScope: false,
        includeVendorScope: false,
        includeActiveType: false,
        includeThreshold: false,
        includeLayoutMode: false,
        includePageIndex: false,
      ),
    ]);

    await repository.upsert(
      StatsSnapshot(
        id: 'same-id',
        name: 'After',
        createdAt: createdAt,
        updatedAt: createdAt.add(const Duration(minutes: 1)),
        includeCategoryScope: true,
        includeVendorScope: false,
        includeActiveType: false,
        includeThreshold: false,
        includeLayoutMode: false,
        includePageIndex: false,
        categoryScopeIds: const {2, 3},
      ),
    );

    final rows = await repository.load();
    expect(rows, hasLength(1));
    expect(rows.single.id, 'same-id');
    expect(rows.single.name, 'After');
    expect(rows.single.createdAt, createdAt);
    expect(rows.single.categoryScopeIds, {2, 3});
  });

  test(
    'snapshot recall generation allows only the latest async result',
    () async {
      final guard = StatsSnapshotRecallGeneration();
      final first = guard.begin();
      final second = guard.begin();
      final firstResult = Completer<String>();
      final secondResult = Completer<String>();
      final committed = <String>[];

      Future<void> commitLatest(
        StatsSnapshotRecallToken token,
        Future<String> result,
      ) async {
        final value = await result;
        if (token.isLatest) committed.add(value);
      }

      final firstRecall = commitLatest(first, firstResult.future);
      final secondRecall = commitLatest(second, secondResult.future);
      secondResult.complete('B');
      await secondRecall;
      firstResult.complete('A');
      await firstRecall;

      expect(first.isLatest, isFalse);
      expect(second.isLatest, isTrue);
      expect(second.value, greaterThan(first.value));
      expect(committed, ['B']);
    },
  );
}
