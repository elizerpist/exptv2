import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  test(
    'canonicalizes one multi-period time group independently of navigation',
    () {
      final scope = CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
        temporalFilter: QueryTemporalFilter.periods(<QueryPeriodSelection>{
          QueryPeriodSelection.month(2026, 8),
          QueryPeriodSelection.year(2024),
          QueryPeriodSelection.month(2026, 2),
        }),
      );

      expect(scope.temporalFilter.isRestrictive, isTrue);
      expect(
        scope.key.value,
        contains('periods:time=year:2024,month:2026-02,month:2026-08'),
      );
      expect(
        scope.copyWith(timeScope: const YearScope(2026)).temporalFilter,
        same(scope.temporalFilter),
        reason: 'dashboard navigation must not erase the applied time filter',
      );
    },
  );

  test('all time remains a non-restrictive canonical filter', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const AllTimeScope(),
    );

    expect(scope.temporalFilter, const QueryTemporalFilter.allTime());
    expect(scope.temporalFilter.isRestrictive, isFalse);
    expect(scope.key.value, isNot(contains('periods:')));
  });
}
