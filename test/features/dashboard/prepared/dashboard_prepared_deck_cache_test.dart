import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/prepared/application/dashboard_prepared_deck_cache.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

import 'dashboard_prepared_test_fixtures.dart';

void main() {
  test('lookup is exact and access order drives bounded eviction', () {
    final cache = DashboardPreparedDeckCache(capacity: 4);
    final may = preparedDeckFixture(month: 5);
    final june = preparedDeckFixture(month: 6);
    final july = preparedDeckFixture(month: 7);
    final august = preparedDeckFixture(month: 8);
    final september = preparedDeckFixture(month: 9);

    cache.store(may);
    cache.store(june);
    cache.store(july);
    cache.store(august);
    expect(cache.lookup(may.key).deck, same(may));
    cache.store(september);

    expect(cache.peek(may.key), same(may));
    expect(cache.peek(june.key), isNull);
    expect(cache.peek(july.key), same(july));
    expect(cache.peek(august.key), same(august));
    expect(cache.peek(september.key), same(september));
    expect(cache.evictionCount, 1);
  });

  test('active adjacent and opposite-direction residency is protected', () {
    final cache = DashboardPreparedDeckCache(capacity: 4);
    final active = preparedDeckFixture(month: 6);
    final adjacent = preparedDeckFixture(month: 7);
    final opposite = preparedDeckFixture(
      month: 6,
      direction: LedgerDirection.expense,
    );
    final disposable = preparedDeckFixture(month: 5);
    final incoming = preparedDeckFixture(month: 8);
    cache.updateResidency(
      active: active.key,
      previous: null,
      next: adjacent.key,
      oppositeDirection: opposite.key,
    );

    cache.store(active);
    cache.store(adjacent);
    cache.store(opposite);
    cache.store(disposable);
    cache.store(incoming);

    expect(cache.length, 4);
    expect(cache.peek(active.key), same(active));
    expect(cache.peek(adjacent.key), same(adjacent));
    expect(cache.peek(opposite.key), same(opposite));
    expect(cache.peek(disposable.key), isNull);
    expect(cache.peek(incoming.key), same(incoming));
  });

  test('revision invalidation removes every old deck', () {
    final cache = DashboardPreparedDeckCache(capacity: 4);
    final old = preparedDeckFixture(month: 5, revision: 1);
    final current = preparedDeckFixture(month: 6, revision: 2);
    cache
      ..store(old)
      ..store(current)
      ..retainOnlyRevision(2);

    expect(cache.peek(old.key), isNull);
    expect(cache.peek(current.key), same(current));
    expect(cache.length, 1);
  });
}
