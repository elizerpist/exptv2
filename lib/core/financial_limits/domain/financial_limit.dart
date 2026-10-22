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

/// A base monthly limit is effective-dated rather than timeless.  A revision
/// applies from its calendar month through the next revision (or indefinitely
/// when it is the latest one).  This is deliberately persisted truth: using a
/// single mutable base record would retroactively rewrite historical Budget
/// denominators when a user changes today's limit.
final class FinancialLimitBaseMonthlyRevisionPeriod
    extends FinancialLimitPeriod {
  const FinancialLimitBaseMonthlyRevisionPeriod(
    this.effectiveFromYear,
    this.effectiveFromMonth,
  ) : assert(effectiveFromYear > 0),
      assert(effectiveFromMonth >= 1 && effectiveFromMonth <= 12);

  final int effectiveFromYear;
  final int effectiveFromMonth;

  @override
  bool operator ==(Object other) =>
      other is FinancialLimitBaseMonthlyRevisionPeriod &&
      other.effectiveFromYear == effectiveFromYear &&
      other.effectiveFromMonth == effectiveFromMonth;

  @override
  int get hashCode => Object.hash(
    FinancialLimitBaseMonthlyRevisionPeriod,
    effectiveFromYear,
    effectiveFromMonth,
  );
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

  /// A persisted zero is an intentional no-limit marker.  It must not be
  /// shown as a usable `0 Ft` denominator or allowed to reveal an older base
  /// revision through accidental deletion.
  bool get hasPositiveAmount => amountScaled100 > 0;

  int? get positiveAmountScaled100 =>
      hasPositiveAmount ? amountScaled100 : null;
}

/// The one UI-facing interpretation of persisted FinancialLimit amounts.
///
/// FinancialLimit itself deliberately permits zero: effective-dated base and
/// exact-month records use it to express an explicit no-limit decision.  All
/// consumer presentation should use this boundary instead of scattering
/// `== 0` checks and accidentally treating a no-limit marker as money.
abstract final class FinancialLimitAvailability {
  static bool isPositive(int? amountScaled100) =>
      amountScaled100 != null && amountScaled100 > 0;

  static int? positiveOrNull(int? amountScaled100) =>
      isPositive(amountScaled100) ? amountScaled100 : null;
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
