import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/shared/motion/centered_carousel/centered_carousel_data_source.dart';
import 'package:fluvi/features/dashboard/motion/dashboard_semantic_catalog.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_temporal_filter.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_availability.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  test('memoizes the exact canonical QueryKey object', () {
    final scope = CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: const MonthScope(YearMonth(year: 2026, month: 6)),
      categoryIds: const {'b', 'a'},
      partnerIds: const {'p2', 'p1'},
      refinements: const {'z': 2, 'a': 1},
    );

    expect(
      scope.key.value,
      'income|month:2026-06|categories:a,b|partners:p1,p2|'
      'refinements:a=1,z=2',
    );
    expect(identical(scope.key, scope.key), isTrue);
  });

  test('month parent catalog precomputes exact day keys and labels', () {
    final parent = _scope(const MonthScope(YearMonth(year: 2026, month: 6)));
    final catalog = DashboardSemanticCatalog.forParent(
      parentScope: parent,
      childKind: DashboardChildKind.day,
    );

    expect(catalog.length, 30);
    expect(
      catalog.values,
      orderedEquals(List.generate(30, (index) => index + 1)),
    );
    expect(catalog[29].logicalIndex, 29);
    expect(catalog[29].label, '30');
    expect(catalog[29].semanticLabel, 'Nap 30');
    expect(
      catalog[29].queryKey.value,
      'income|day:2026-06-30|categories:|partners:|refinements:',
    );
    expect(identical(catalog[29], catalog.entryAtLogicalIndex(29)), isTrue);
    expect(catalog.entryForQueryKey(catalog[29].queryKey), same(catalog[29]));
    expect(catalog.windowIdentity, 'days:2026-06');
  });

  test('year parent catalog preserves Hungarian month labels', () {
    final catalog = DashboardSemanticCatalog.forParent(
      parentScope: _scope(const YearScope(2026)),
      childKind: DashboardChildKind.month,
    );

    expect(catalog.length, 12);
    expect(catalog[4].value, 5);
    expect(catalog[4].label, 'május');
    expect(catalog[4].semanticLabel, 'Hónap május');
    expect(catalog[4].queryKey.value, contains('month:2026-05'));
    expect(catalog.windowIdentity, 'months:2026');
  });

  test('SUM catalog is an explicit retained year plus-minus twelve window', () {
    final catalog = DashboardSemanticCatalog.forParent(
      parentScope: _scope(const AllTimeScope()),
      childKind: DashboardChildKind.year,
      retainedYear: 2026,
    );

    expect(catalog.length, 25);
    expect(
      catalog.values,
      orderedEquals(List.generate(25, (index) => 2014 + index)),
    );
    expect(catalog[12].value, 2026);
    expect(catalog[12].queryKey.value, contains('year:2026'));
    expect(catalog.windowIdentity, 'years:2014-2038');
  });

  test(
    'restricted availability removes excluded years and months from rail data',
    () {
      final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.year(2024),
        QueryPeriodSelection.month(2026, 2),
        QueryPeriodSelection.month(2026, 8),
      });
      final availability = DashboardTemporalAvailability.fromTemporalFilter(
        filter,
      );
      final sum = DashboardSemanticCatalog.forParent(
        parentScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const AllTimeScope(),
          temporalFilter: filter,
        ),
        childKind: DashboardChildKind.year,
        retainedYear: 2026,
        availability: availability,
      );
      final months = DashboardSemanticCatalog.forParent(
        parentScope: CurrentLedgerQueryScope(
          direction: LedgerDirection.income,
          timeScope: const YearScope(2026),
          temporalFilter: filter,
        ),
        childKind: DashboardChildKind.month,
        availability: availability,
      );

      expect(sum.values, orderedEquals(<int>[2024, 2026]));
      expect(sum.mode, CenteredCarouselDataMode.cyclic);
      expect(sum.entryAtLogicalIndex(-1).value, 2026);
      expect(sum.entryAtLogicalIndex(2).value, 2024);
      expect(months.values, orderedEquals(<int>[2, 8]));
      expect(months.mode, CenteredCarouselDataMode.cyclic);
      expect(months.entryAtLogicalIndex(-1).value, 8);
      expect(months.entryAtLogicalIndex(2).value, 2);
    },
  );

  test(
    'a single restricted value remains stationary instead of duplicating',
    () {
      final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.year(2025),
      });
      final availability = DashboardTemporalAvailability.fromTemporalFilter(
        filter,
      );
      final years = DashboardSemanticCatalog.forParent(
        parentScope: _scope(
          const AllTimeScope(),
        ).copyWith(temporalFilter: filter),
        childKind: DashboardChildKind.year,
        retainedYear: 2025,
        availability: availability,
      );

      expect(years.values, <int>[2025]);
      expect(years.mode, CenteredCarouselDataMode.bounded);
    },
  );

  test(
    'three consecutive restricted months wrap in both logical directions',
    () {
      final filter = QueryTemporalFilter.periods(<QueryPeriodSelection>{
        QueryPeriodSelection.month(2026, 1),
        QueryPeriodSelection.month(2026, 2),
        QueryPeriodSelection.month(2026, 3),
      });
      final catalog = DashboardSemanticCatalog.forParent(
        parentScope: _scope(
          const YearScope(2026),
        ).copyWith(temporalFilter: filter),
        childKind: DashboardChildKind.month,
        availability: DashboardTemporalAvailability.fromTemporalFilter(filter),
      );

      expect(catalog.mode, CenteredCarouselDataMode.cyclic);
      expect(catalog.entryAtLogicalIndex(-2).value, 2);
      expect(catalog.entryAtLogicalIndex(-1).value, 3);
      expect(catalog.entryAtLogicalIndex(0).value, 1);
      expect(catalog.entryAtLogicalIndex(1).value, 2);
      expect(catalog.entryAtLogicalIndex(2).value, 3);
      expect(catalog.entryAtLogicalIndex(3).value, 1);
    },
  );

  test('rejects an incompatible parent and child kind', () {
    expect(
      () => DashboardSemanticCatalog.forParent(
        parentScope: _scope(const YearScope(2026)),
        childKind: DashboardChildKind.day,
      ),
      throwsArgumentError,
    );
  });
}

CurrentLedgerQueryScope _scope(LedgerTimeScope timeScope) =>
    CurrentLedgerQueryScope(
      direction: LedgerDirection.income,
      timeScope: timeScope,
    );
