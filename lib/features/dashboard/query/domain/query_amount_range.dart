import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import 'current_ledger_query_scope.dart';
import 'query_menu_data.dart';

/// The one canonical two-ended amount refinement used by every Query host.
///
/// Amount values are scaled HUF. The floor, dynamic maximum, clamping and
/// immutable Query mutation live here so a renderer can never create a
/// Mind-only filtering policy.
abstract final class QueryAmountRange {
  static const String minimumRefinementKey = 'minimumAmountScaled100';
  static const String maximumRefinementKey = 'maximumAmountScaled100';
  static const int minimumScaled100 = 100000; // 1000 HUF
  static const int _minimumInteractionStepScaled100 = 1000; // 10 HUF

  /// Canonical data identity for the range controlled by this refinement.
  /// The control's own bounds cannot recursively redefine its source domain;
  /// every other semantic filter remains part of the identity.
  static CurrentLedgerQueryScope domainScope(CurrentLedgerQueryScope scope) {
    if (!scope.refinements.containsKey(minimumRefinementKey) &&
        !scope.refinements.containsKey(maximumRefinementKey)) {
      return scope;
    }
    final refinements = <String, Object?>{...scope.refinements}
      ..remove(minimumRefinementKey)
      ..remove(maximumRefinementKey);
    return scope.copyWith(refinements: refinements);
  }

  static bool hasSameDomainIdentity(
    CurrentLedgerQueryScope first,
    CurrentLedgerQueryScope second,
  ) => domainScope(first) == domainScope(second);

  static QueryAmountRangeValues resolve({
    required Map<String, Object?> refinements,
    required QueryMenuAmountDomain? amountDomain,
  }) {
    // `amountDomain` is calculated by the native Query boundary from
    // `domainScope(scope)`: it retains every current filter except this
    // control's own two endpoints. Its maximum is therefore the one physical
    // slider ceiling. Do not manufacture the old 1,000-HUF ceiling when an
    // exact one-value/small-value domain is supplied.
    final domainMaximum = amountDomain?.maximumAmountScaled100;
    final maximum = domainMaximum == null
        ? minimumScaled100
        : math.max(0, domainMaximum);
    final minimum = minimumScaled100.clamp(0, maximum).toInt();
    final requestedLower =
        _refinement(refinements, minimumRefinementKey) ?? minimum;
    final lower = requestedLower.clamp(minimum, maximum).toInt();
    final requestedUpper =
        _refinement(refinements, maximumRefinementKey) ?? maximum;
    final upper = requestedUpper.clamp(lower, maximum).toInt();
    return QueryAmountRangeValues(
      minimumScaled100: minimum,
      maximumScaled100: maximum,
      lowerScaled100: lower,
      upperScaled100: upper,
    );
  }

  /// Returns a stable 1/2/5 × 10^n money step for the current right-thumb
  /// amount. The input/output use Fluvi's scaled-HUF representation; the
  /// calculation itself is deliberately in whole HUF so a large slider never
  /// exposes cent-like raw resolution.
  static int niceMonetaryStepScaled100ForUpper(int upperScaled100) {
    final effectiveUpperHuf = (upperScaled100 / 100).clamp(0, double.infinity);
    final rawTargetHuf = math.max(1, (effectiveUpperHuf / 100).round());
    var magnitude = 1;
    while (rawTargetHuf >= magnitude * 10) {
      magnitude *= 10;
    }
    final normalized = rawTargetHuf / magnitude;
    final multiplier = switch (normalized) {
      < 1.5 => 1,
      < 3.5 => 2,
      < 7.5 => 5,
      _ => 10,
    };
    final stepHuf = math.max(10, multiplier * magnitude);
    return math.max(_minimumInteractionStepScaled100, stepHuf * 100);
  }

  static CurrentLedgerQueryScope apply(
    CurrentLedgerQueryScope scope, {
    required QueryAmountRangeValues values,
    required QueryMenuAmountDomain? amountDomain,
  }) {
    final canonical = resolve(
      refinements: <String, Object?>{
        ...scope.refinements,
        minimumRefinementKey: values.lowerScaled100,
        maximumRefinementKey: values.upperScaled100,
      },
      amountDomain: amountDomain,
    );
    final refinements = <String, Object?>{...scope.refinements}
      ..[minimumRefinementKey] = canonical.lowerScaled100;
    if (canonical.upperScaled100 >= canonical.maximumScaled100) {
      refinements.remove(maximumRefinementKey);
    } else {
      refinements[maximumRefinementKey] = canonical.upperScaled100;
    }
    return scope.copyWith(refinements: refinements);
  }

  static int? _refinement(Map<String, Object?> refinements, String key) {
    final value = refinements[key];
    return value is num ? value.toInt() : null;
  }
}

/// One ready binding between an immutable Query and the exact Query-menu data
/// revision that owns its amount domain. Hosts may choose placement only; they
/// cannot separately resolve maxima, clamp values, or mutate refinements.
/// A missing binding means *not ready*, never a fabricated 1,000/1,000 range.
@immutable
final class QueryAmountRangeBinding {
  const QueryAmountRangeBinding._({
    required this.scope,
    required this.amountDomain,
    required this.values,
  });

  static QueryAmountRangeBinding? ready({
    required CurrentLedgerQueryScope scope,
    required QueryMenuAmountDomain? amountDomain,
  }) {
    if (amountDomain == null) return null;
    return QueryAmountRangeBinding._(
      scope: scope,
      amountDomain: amountDomain,
      values: QueryAmountRange.resolve(
        refinements: scope.refinements,
        amountDomain: amountDomain,
      ),
    );
  }

  final CurrentLedgerQueryScope scope;
  final QueryMenuAmountDomain amountDomain;
  final QueryAmountRangeValues values;

  CurrentLedgerQueryScope apply(QueryAmountRangeValues next) =>
      QueryAmountRange.apply(scope, values: next, amountDomain: amountDomain);
}

/// A finite ordered view of the current Query amount domain.
@immutable
final class QueryAmountRangeValues {
  const QueryAmountRangeValues({
    required this.minimumScaled100,
    required this.maximumScaled100,
    required this.lowerScaled100,
    required this.upperScaled100,
  }) : assert(minimumScaled100 <= maximumScaled100),
       assert(lowerScaled100 >= minimumScaled100),
       assert(upperScaled100 >= lowerScaled100),
       assert(upperScaled100 <= maximumScaled100);

  final int minimumScaled100;
  final int maximumScaled100;
  final int lowerScaled100;
  final int upperScaled100;

  bool get isActionable => maximumScaled100 > minimumScaled100;

  QueryAmountRangeValues fromRawRange({
    required int lower,
    required int upper,
  }) {
    final rawUpper = upper.clamp(minimumScaled100, maximumScaled100).toInt();
    final step = QueryAmountRange.niceMonetaryStepScaled100ForUpper(rawUpper);
    int snap(int value) {
      final bounded = value.clamp(minimumScaled100, maximumScaled100).toInt();
      // Exact source-domain endpoints stay reachable even when their distance
      // from the floor is not a multiple of the current nice step.
      if (bounded == minimumScaled100 || bounded == maximumScaled100) {
        return bounded;
      }
      return (minimumScaled100 +
              ((bounded - minimumScaled100) / step).round() * step)
          .clamp(minimumScaled100, maximumScaled100)
          .toInt();
    }

    final resolvedUpper = snap(rawUpper);
    final resolvedLower = snap(
      lower,
    ).clamp(minimumScaled100, resolvedUpper).toInt();
    return QueryAmountRangeValues(
      minimumScaled100: minimumScaled100,
      maximumScaled100: maximumScaled100,
      lowerScaled100: resolvedLower,
      upperScaled100: resolvedUpper,
    );
  }

  @override
  bool operator ==(Object other) =>
      other is QueryAmountRangeValues &&
      minimumScaled100 == other.minimumScaled100 &&
      maximumScaled100 == other.maximumScaled100 &&
      lowerScaled100 == other.lowerScaled100 &&
      upperScaled100 == other.upperScaled100;

  @override
  int get hashCode => Object.hash(
    minimumScaled100,
    maximumScaled100,
    lowerScaled100,
    upperScaled100,
  );
}
