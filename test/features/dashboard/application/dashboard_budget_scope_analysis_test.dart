import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_scope_analysis.dart';

void main() {
  group('resolved monthly Budget limits', () {
    test('a concrete month override wins over the base monthly limit', () {
      const resolver = DashboardBudgetResolvedMonthlyLimitResolver();

      expect(
        resolver.resolve(
          baseMonthlyLimitScaled100: 20000,
          overrideScaled100: 26000,
        ),
        const DashboardBudgetResolvedMonthlyLimit.available(
          amountScaled100: 26000,
          source: DashboardBudgetMonthlyLimitSource.override,
        ),
      );
    });

    test('an absent override inherits the base and no base is unavailable', () {
      const resolver = DashboardBudgetResolvedMonthlyLimitResolver();

      expect(
        resolver.resolve(
          baseMonthlyLimitScaled100: 20000,
          overrideScaled100: null,
        ),
        const DashboardBudgetResolvedMonthlyLimit.available(
          amountScaled100: 20000,
          source: DashboardBudgetMonthlyLimitSource.base,
        ),
      );
      expect(
        resolver.resolve(
          baseMonthlyLimitScaled100: null,
          overrideScaled100: null,
        ),
        const DashboardBudgetResolvedMonthlyLimit.unavailable(),
      );
    });

    test('a SUM base edit changes only inherited months', () {
      const resolver = DashboardBudgetResolvedMonthlyLimitResolver();

      final inheritedAfterBaseEdit = resolver.resolve(
        baseMonthlyLimitScaled100: 22000,
        overrideScaled100: null,
      );
      final explicitAfterBaseEdit = resolver.resolve(
        baseMonthlyLimitScaled100: 22000,
        overrideScaled100: 26000,
      );

      expect(inheritedAfterBaseEdit.amountScaled100, 22000);
      expect(
        inheritedAfterBaseEdit.source,
        DashboardBudgetMonthlyLimitSource.base,
      );
      expect(explicitAfterBaseEdit.amountScaled100, 26000);
      expect(
        explicitAfterBaseEdit.source,
        DashboardBudgetMonthlyLimitSource.override,
      );
    });
  });

  group('derived annual edits', () {
    test(
      'proportional scaled-integer allocation preserves exact requested sum',
      () {
        final allocation = DashboardBudgetYearLimitAllocator.allocate(
          currentMonthlyLimitsScaled100: const <int>[180, 180, 230, 350],
          requestedAnnualLimitScaled100: 1001,
        );

        expect(allocation.monthlyLimitsScaled100, hasLength(4));
        expect(
          allocation.monthlyLimitsScaled100.reduce(
            (left, right) => left + right,
          ),
          1001,
        );
        expect(
          allocation.monthlyLimitsScaled100[3],
          greaterThan(allocation.monthlyLimitsScaled100[0]),
        );
      },
    );

    test('zero annual basis distributes deterministically and exactly', () {
      final allocation = DashboardBudgetYearLimitAllocator.allocate(
        currentMonthlyLimitsScaled100: List<int>.filled(12, 0),
        requestedAnnualLimitScaled100: 25,
      );

      expect(
        allocation.monthlyLimitsScaled100.reduce((left, right) => left + right),
        25,
      );
      expect(allocation.monthlyLimitsScaled100.take(1), <int>[3]);
      expect(allocation.monthlyLimitsScaled100.skip(1), everyElement(2));
    });
  });

  test('typical month includes zero completed calendar months', () {
    final average = DashboardBudgetTypicalMonthAverage.resolve(
      completedMonthSpendScaled100: 60000,
      completedMonthCount: 3,
    );
    expect(average.isAvailable, isTrue);
    expect(average.averageMonthlySpendScaled100, 20000);
  });
}
