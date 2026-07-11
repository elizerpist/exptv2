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
    expect(applied.pageIndex, 1);
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
}
