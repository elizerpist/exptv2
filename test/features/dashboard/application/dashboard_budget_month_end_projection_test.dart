import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_month_end_projection.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';

void main() {
  group('DashboardBudgetMonthEndProjection', () {
    test('projects current-month pace with integer half-up money rounding', () {
      final projection = DashboardBudgetMonthEndProjection.derive(
        coreRevision: 7,
        direction: LedgerDirection.expense,
        targetHandle: 1,
        year: 2026,
        month: 8,
        logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 10),
        monthToDateActualScaled100: 8000000,
        finalMonthActualScaled100: 0,
        effectiveMonthlyLimitScaled100: 20000000,
      );

      expect(projection.isAvailable, isTrue);
      expect(projection.monthToDateActualScaled100, 8000000);
      expect(projection.elapsedCalendarDays, 10);
      expect(projection.daysInMonth, 31);
      expect(projection.projectedMonthEndScaled100, 24800000);
      expect(projection.projectionRatio, 1.24);
      expect(projection.gaugeFillRatio, closeTo(.93, 1e-12));
      expect(projection.healthBand, DashboardBudgetProjectionHealthBand.danger);
      expect(projection.breakEvenGaugeRatio, .75);
    });

    test(
      'uses calendar days, including a zero-spend day, in the denominator',
      () {
        final dayTen = DashboardBudgetMonthEndProjection.derive(
          coreRevision: 7,
          direction: LedgerDirection.expense,
          targetHandle: 0,
          year: 2026,
          month: 4,
          logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 10),
          monthToDateActualScaled100: 8000000,
          finalMonthActualScaled100: 0,
          effectiveMonthlyLimitScaled100: 20000000,
        );
        final dayEleven = DashboardBudgetMonthEndProjection.derive(
          coreRevision: 7,
          direction: LedgerDirection.expense,
          targetHandle: 0,
          year: 2026,
          month: 4,
          logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 11),
          monthToDateActualScaled100: 8000000,
          finalMonthActualScaled100: 0,
          effectiveMonthlyLimitScaled100: 20000000,
        );

        expect(dayTen.elapsedCalendarDays, 10);
        expect(dayEleven.elapsedCalendarDays, 11);
        expect(
          dayEleven.projectedMonthEndScaled100,
          lessThan(dayTen.projectedMonthEndScaled100),
        );
      },
    );

    test('projects the product 80k-on-day-10 April example to 240k', () {
      final projection = DashboardBudgetMonthEndProjection.derive(
        coreRevision: 7,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        year: 2026,
        month: 4,
        logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 10),
        monthToDateActualScaled100: 8000000,
        finalMonthActualScaled100: 0,
        effectiveMonthlyLimitScaled100: 20000000,
      );

      expect(projection.projectedMonthEndScaled100, 24000000);
      expect(projection.projectionRatio, 1.2);
      expect(projection.gaugeFillRatio, closeTo(.9, 1e-12));
      expect(projection.healthBand, DashboardBudgetProjectionHealthBand.danger);
    });

    test(
      'models daily pace explicitly instead of naming projection as pace',
      () {
        final projection = DashboardBudgetMonthEndProjection.derive(
          coreRevision: 7,
          direction: LedgerDirection.expense,
          targetHandle: 0,
          year: 2026,
          month: 4,
          logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 10),
          monthToDateActualScaled100: 12000000,
          finalMonthActualScaled100: 0,
          effectiveMonthlyLimitScaled100: 30000000,
        );

        // The MONTH product is 120k / 300k == 40%, whereas DAY is a pace:
        // 12k/day / 10k/day == 120%. These must remain distinct concepts even
        // though projected month end / monthly limit has the same raw ratio.
        expect(projection.actualDailyAverageScaled100, 1200000);
        expect(projection.allowedDailyAverageScaled100, 1000000);
        expect(projection.paceRatio, 1.2);
        expect(projection.projectedMonthEndScaled100, 36000000);
        expect(projection.projectionRatio, projection.paceRatio);
        expect(projection.gaugeFillRatio, closeTo(.9, .000000001));
      },
    );

    test('handles leap-month length, past final actual and future safely', () {
      final leap = DashboardBudgetMonthEndProjection.derive(
        coreRevision: 7,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        year: 2024,
        month: 2,
        logicalAsOfDate: const LocalDate(year: 2024, month: 2, day: 10),
        monthToDateActualScaled100: 10000,
        finalMonthActualScaled100: 0,
        effectiveMonthlyLimitScaled100: 10000,
      );
      final past = DashboardBudgetMonthEndProjection.derive(
        coreRevision: 7,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        year: 2026,
        month: 7,
        logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 10),
        monthToDateActualScaled100: 1,
        finalMonthActualScaled100: 12345,
        effectiveMonthlyLimitScaled100: 10000,
      );
      final future = DashboardBudgetMonthEndProjection.derive(
        coreRevision: 7,
        direction: LedgerDirection.expense,
        targetHandle: 0,
        year: 2026,
        month: 9,
        logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 10),
        monthToDateActualScaled100: 99999,
        finalMonthActualScaled100: 0,
        effectiveMonthlyLimitScaled100: 10000,
      );

      expect(leap.daysInMonth, 29);
      expect(past.elapsedCalendarDays, 31);
      expect(past.projectedMonthEndScaled100, 12345);
      expect(future.isAvailable, isFalse);
      expect(future.elapsedCalendarDays, 0);
      expect(future.projectedMonthEndScaled100, 0);
      expect(future.actualDailyAverageScaled100, isNull);
      expect(future.allowedDailyAverageScaled100, isNull);
      expect(future.projectionRatio.isFinite, isTrue);
      expect(future.paceRatio.isFinite, isTrue);
      expect(future.gaugeFillRatio, 0);
    });

    test(
      'retains unbounded forecast semantics while clamping only the gauge',
      () {
        final projection = DashboardBudgetMonthEndProjection.derive(
          coreRevision: 7,
          direction: LedgerDirection.expense,
          targetHandle: 0,
          year: 2026,
          month: 8,
          logicalAsOfDate: const LocalDate(year: 2026, month: 8, day: 1),
          monthToDateActualScaled100: 150000,
          finalMonthActualScaled100: 0,
          effectiveMonthlyLimitScaled100: 100000,
        );

        expect(projection.projectionRatio, 46.5);
        expect(projection.gaugeFillRatio, 1);
        expect(
          projection.healthBand,
          DashboardBudgetProjectionHealthBand.danger,
        );
      },
    );

    test('maps raw forecast ratio to the fixed vertical-gauge scale', () {
      DashboardBudgetMonthEndProjection projectionFor(int actual) =>
          DashboardBudgetMonthEndProjection.derive(
            coreRevision: 7,
            direction: LedgerDirection.expense,
            targetHandle: 0,
            year: 2026,
            month: 4,
            logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 30),
            monthToDateActualScaled100: actual,
            finalMonthActualScaled100: 0,
            effectiveMonthlyLimitScaled100: 100000,
          );

      expect(projectionFor(50000).gaugeFillRatio, .375);
      expect(projectionFor(75000).gaugeFillRatio, .5625);
      expect(projectionFor(90000).gaugeFillRatio, .675);
      expect(projectionFor(100000).gaugeFillRatio, .75);
      expect(projectionFor(120000).gaugeFillRatio, closeTo(.9, 1e-12));
      final breakEvenTop = projectionFor(133333);
      expect(breakEvenTop.gaugeFillRatio, closeTo(1, 1e-5));
      final beyondTop = projectionFor(150000);
      expect(beyondTop.gaugeFillRatio, 1);
      expect(beyondTop.projectionRatio, 1.5);
    });

    test('resolves health from the raw forecast rather than gauge fill', () {
      DashboardBudgetMonthEndProjection projectionFor(int actual) =>
          DashboardBudgetMonthEndProjection.derive(
            coreRevision: 7,
            direction: LedgerDirection.expense,
            targetHandle: 0,
            year: 2026,
            month: 4,
            logicalAsOfDate: const LocalDate(year: 2026, month: 4, day: 30),
            monthToDateActualScaled100: actual,
            finalMonthActualScaled100: 0,
            effectiveMonthlyLimitScaled100: 100000,
          );

      expect(
        projectionFor(74999).healthBand,
        DashboardBudgetProjectionHealthBand.targetAccent,
      );
      expect(
        projectionFor(75000).healthBand,
        DashboardBudgetProjectionHealthBand.warning,
      );
      expect(
        projectionFor(90000).healthBand,
        DashboardBudgetProjectionHealthBand.warning,
      );
      expect(
        projectionFor(90001).healthBand,
        DashboardBudgetProjectionHealthBand.danger,
      );
    });
  });
}
