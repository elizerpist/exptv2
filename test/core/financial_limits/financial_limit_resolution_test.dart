import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit.dart';
import 'package:fluvi/core/financial_limits/domain/financial_limit_resolution.dart';

void main() {
  const direction = FinancialLimitDirection.expense;
  const target = FinancialLimitAggregateTarget();

  FinancialLimit record(FinancialLimitPeriod period, int amount) =>
      FinancialLimit(
        key: FinancialLimitKey(
          direction: direction,
          target: target,
          period: period,
        ),
        amountScaled100: amount,
        createdAtUtcMs: 1,
        updatedAtUtcMs: 1,
      );

  test(
    'effective base history preserves past months and exact override wins',
    () {
      final limits = <FinancialLimit>[
        record(const FinancialLimitBaseMonthlyRevisionPeriod(2025, 1), 16000),
        record(const FinancialLimitBaseMonthlyRevisionPeriod(2026, 4), 18000),
        record(const FinancialLimitBaseMonthlyRevisionPeriod(2026, 10), 20000),
        record(const FinancialLimitMonthOverridePeriod(2026, 3), 23000),
        record(const FinancialLimitMonthOverridePeriod(2026, 12), 26000),
      ];

      int? amount(int year, int month) => FinancialLimitResolution.resolve(
        limits: limits,
        direction: direction,
        target: target,
        year: year,
        month: month,
      )?.amountScaled100;

      expect(amount(2026, 2), 16000);
      expect(amount(2026, 3), 23000);
      expect(amount(2026, 4), 18000);
      expect(amount(2026, 9), 18000);
      expect(amount(2026, 10), 20000);
      expect(amount(2026, 12), 26000);
    },
  );

  test(
    'deleting a historical override restores that month historical base',
    () {
      final historicalBase = record(
        const FinancialLimitBaseMonthlyRevisionPeriod(2026, 1),
        18000,
      );
      final currentBase = record(
        const FinancialLimitBaseMonthlyRevisionPeriod(2026, 10),
        20000,
      );
      final historicalOverride = record(
        const FinancialLimitMonthOverridePeriod(2026, 3),
        22000,
      );

      expect(
        FinancialLimitResolution.resolve(
          limits: <FinancialLimit>[
            historicalBase,
            currentBase,
            historicalOverride,
          ],
          direction: direction,
          target: target,
          year: 2026,
          month: 3,
        )?.amountScaled100,
        22000,
      );
      expect(
        FinancialLimitResolution.resolve(
          limits: <FinancialLimit>[historicalBase, currentBase],
          direction: direction,
          target: target,
          year: 2026,
          month: 3,
        )?.amountScaled100,
        18000,
      );
    },
  );

  test(
    'a zero revision is no limit while reset restores the inherited base',
    () {
      final historicalBase = record(
        const FinancialLimitBaseMonthlyRevisionPeriod(2026, 1),
        50000,
      );
      final noBaseFromOctober = record(
        const FinancialLimitBaseMonthlyRevisionPeriod(2026, 10),
        0,
      );
      final noLimitOctober = record(
        const FinancialLimitMonthOverridePeriod(2026, 10),
        0,
      );

      int? amount(Iterable<FinancialLimit> limits, int year, int month) =>
          FinancialLimitResolution.resolve(
            limits: limits,
            direction: direction,
            target: target,
            year: year,
            month: month,
          )?.amountScaled100;

      expect(
        amount(<FinancialLimit>[historicalBase, noBaseFromOctober], 2026, 9),
        50000,
      );
      expect(
        amount(<FinancialLimit>[historicalBase, noBaseFromOctober], 2026, 10),
        0,
      );
      expect(
        FinancialLimitAvailability.positiveOrNull(
          amount(<FinancialLimit>[historicalBase, noBaseFromOctober], 2026, 10),
        ),
        isNull,
      );

      // A zero month record means no limit for exactly October. Removing that
      // record is the separate return-to-base operation.
      expect(
        amount(<FinancialLimit>[historicalBase, noLimitOctober], 2026, 10),
        0,
      );
      expect(amount(<FinancialLimit>[historicalBase], 2026, 10), 50000);
    },
  );
}
