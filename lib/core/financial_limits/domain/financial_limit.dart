import 'package:flutter/foundation.dart';

enum FinancialLimitDirection { income, expense }

sealed class FinancialLimitTarget {
  const FinancialLimitTarget();
}

final class FinancialLimitAggregateTarget extends FinancialLimitTarget {
  const FinancialLimitAggregateTarget();

  @override
  bool operator ==(Object other) => other is FinancialLimitAggregateTarget;

  @override
  int get hashCode => Object.hash(FinancialLimitAggregateTarget, 0);
}

final class FinancialLimitCategoryTarget extends FinancialLimitTarget {
  const FinancialLimitCategoryTarget(this.categoryId)
    : assert(categoryId != 'aggregate');

  final String categoryId;

  @override
  bool operator ==(Object other) =>
      other is FinancialLimitCategoryTarget && other.categoryId == categoryId;

  @override
  int get hashCode => Object.hash(FinancialLimitCategoryTarget, categoryId);
}

/// The only persisted Budget limit scopes. Global SUM/YEAR/DAY are derived
/// presentation analyses and cannot be represented as independent records.
sealed class FinancialLimitPeriod {
  const FinancialLimitPeriod();
}

final class FinancialLimitBaseMonthlyPeriod extends FinancialLimitPeriod {
  const FinancialLimitBaseMonthlyPeriod();

  @override
  bool operator ==(Object other) => other is FinancialLimitBaseMonthlyPeriod;

  @override
  int get hashCode => Object.hash(FinancialLimitBaseMonthlyPeriod, 0);
}

final class FinancialLimitMonthOverridePeriod extends FinancialLimitPeriod {
  const FinancialLimitMonthOverridePeriod(this.year, this.month)
    : assert(year > 0),
      assert(month >= 1 && month <= 12);

  final int year;
  final int month;

  @override
  bool operator ==(Object other) =>
      other is FinancialLimitMonthOverridePeriod &&
      other.year == year &&
      other.month == month;

  @override
  int get hashCode =>
      Object.hash(FinancialLimitMonthOverridePeriod, year, month);
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

  @override
  bool operator ==(Object other) =>
      other is FinancialLimitKey &&
      other.direction == direction &&
      other.target == target &&
      other.period == period;

  @override
  int get hashCode => Object.hash(FinancialLimitKey, direction, target, period);
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

/// One member of an atomic semantic mutation. YEAR editing writes the twelve
/// resolved monthly values together; callers must not emulate that operation
/// with twelve independently visible repository writes.
@immutable
final class FinancialLimitMutation {
  const FinancialLimitMutation({
    required this.key,
    required this.amountScaled100,
  }) : assert(amountScaled100 >= 0);

  final FinancialLimitKey key;
  final int amountScaled100;
}
