import 'package:flutter/foundation.dart';

enum FinancialLimitDirection { income, expense }

sealed class FinancialLimitTarget {
  const FinancialLimitTarget();
}

final class FinancialLimitAggregateTarget extends FinancialLimitTarget {
  const FinancialLimitAggregateTarget();
}

final class FinancialLimitCategoryTarget extends FinancialLimitTarget {
  const FinancialLimitCategoryTarget(this.categoryId)
    : assert(categoryId != 'aggregate');

  final String categoryId;
}

sealed class FinancialLimitPeriod {
  const FinancialLimitPeriod();
}

final class FinancialLimitSumPeriod extends FinancialLimitPeriod {
  const FinancialLimitSumPeriod();
}

final class FinancialLimitYearPeriod extends FinancialLimitPeriod {
  const FinancialLimitYearPeriod(this.year) : assert(year > 0);

  final int year;
}

final class FinancialLimitMonthPeriod extends FinancialLimitPeriod {
  const FinancialLimitMonthPeriod(this.year, this.month)
    : assert(year > 0),
      assert(month >= 1 && month <= 12);

  final int year;
  final int month;
}

@immutable
final class FinancialLimitKey {
  const FinancialLimitKey({
    required this.direction,
    required this.target,
    required this.period,
  });

  final FinancialLimitDirection direction;
  final FinancialLimitTarget target;
  final FinancialLimitPeriod period;
}

@immutable
final class FinancialLimit {
  const FinancialLimit({
    required this.key,
    required this.amountScaled100,
    required this.createdAtUtcMs,
    required this.updatedAtUtcMs,
  }) : assert(amountScaled100 >= 0);

  final FinancialLimitKey key;
  final int amountScaled100;
  final int createdAtUtcMs;
  final int updatedAtUtcMs;
}
