import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_batch_metrics.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_bounded_cache.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_stress_fixture.dart';

void main() {
  test(
    'seeded stress fixtures are deterministic and cover both directions',
    () {
      final first = DashboardStressFixtureGenerator.generate(
        transactionCount: 200,
        seed: 42,
      );
      final second = DashboardStressFixtureGenerator.generate(
        transactionCount: 200,
        seed: 42,
      );

      expect(
        first.entries.map((entry) => entry.id),
        orderedEquals(second.entries.map((entry) => entry.id)),
      );
      expect(
        first.entries.map((entry) => entry.direction).toSet(),
        containsAll(<String>{'income', 'expense'}),
      );
      expect(first.emptyChildKeys, isNotEmpty);
    },
  );

  test('preview row budget is bounded while aggregate count stays exact', () {
    final fixture = DashboardStressFixtureGenerator.generate(
      transactionCount: 1000,
      seed: 7,
    );
    final bounded = DashboardStressFixtureGenerator.firstPreviewRows(
      fixture.entries,
      rowBudget: 24,
    );

    expect(bounded.length, lessThanOrEqualTo(24));
    expect(fixture.entries.length, 1000);
  });

  test('10k, 50k and 100k fixtures stay seeded and bounded', () {
    for (final count in <int>[10000, 50000, 100000]) {
      final fixture = DashboardStressFixtureGenerator.generate(
        transactionCount: count,
        seed: count,
        emptyChildCount: 3,
      );
      final previewRows = DashboardStressFixtureGenerator.firstPreviewRows(
        fixture.entries,
        rowBudget: 24,
      );

      expect(fixture.entries, hasLength(count));
      expect(fixture.emptyChildKeys.length, greaterThanOrEqualTo(3));
      expect(previewRows.length, lessThanOrEqualTo(24));
      expect(
        fixture.entries.map((entry) => entry.direction).toSet(),
        containsAll(<String>{'income', 'expense'}),
      );
    }
  });

  test(
    'bounded cache reports weight and evicts least recently used values',
    () {
      final cache = DashboardBoundedCache<String, String>(
        capacity: 2,
        weightOf: (value) => value.length,
      );

      cache.put('a', '123');
      cache.put('b', '4567');
      expect(cache.estimatedWeight, 7);
      expect(cache.get('a'), '123');
      cache.put('c', '89');

      expect(cache.get('b'), isNull);
      expect(cache.evictionCount, 1);
      expect(cache.hitCount, 1);
      expect(cache.missCount, 1);
      expect(cache.length, 2);
    },
  );

  test('bounded cache exposes a separate estimated byte budget', () {
    final cache = DashboardBoundedCache<String, String>(
      capacity: 2,
      weightOf: (value) => value.length,
      byteWeightOf: (value) => value.length * 10,
    );

    cache.put('a', '123');
    cache.put('b', '4567');

    expect(cache.estimatedWeight, 7);
    expect(cache.estimatedBytes, 70);
  });

  test('batch metrics retain structured read and projection timings', () {
    const metrics = DashboardBatchMetrics(
      sqlMs: 12,
      nativeProjectionMs: 3,
      payloadBytes: 4096,
      dartDecodeMs: 2,
      dartProjectionMs: 1,
      cacheInsertionMs: 1,
      snapshotCount: 31,
      rowCount: 24,
    );

    expect(metrics.totalMeasuredMs, 19);
    expect(metrics.snapshotCount, 31);
    expect(metrics.rowCount, 24);
  });
}
