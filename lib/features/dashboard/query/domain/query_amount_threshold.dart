import 'current_ledger_query_scope.dart';
import 'query_menu_data.dart';

/// Canonical lower amount filter shared by every direct-manipulation surface.
///
/// Amounts are stored in scaled HUF minor units. This owner deliberately
/// writes the existing Query refinement rather than introducing a Mind-only
/// filtering field, predicate or cache identity.
abstract final class QueryAmountThreshold {
  static const String refinementKey = 'minimumAmountScaled100';
  static const int minimumScaled100 = 100000; // 1000 HUF

  static QueryAmountThresholdBounds resolve({
    required CurrentLedgerQueryScope scope,
    required QueryMenuAmountDomain? amountDomain,
  }) {
    final domainMaximum =
        amountDomain?.maximumAmountScaled100 ?? minimumScaled100;
    final maximum = domainMaximum < minimumScaled100
        ? minimumScaled100
        : domainMaximum;
    final raw = scope.refinements[refinementKey];
    final requested = raw is num ? raw.toInt() : minimumScaled100;
    return QueryAmountThresholdBounds._(
      minimumScaled100: minimumScaled100,
      maximumScaled100: maximum,
      valueScaled100: requested.clamp(minimumScaled100, maximum).toInt(),
    );
  }

  /// Returns the canonical immutable scope for a semantic slider tick. The
  /// existing Query key/equality/cache machinery sees the refinement change.
  static CurrentLedgerQueryScope apply(
    CurrentLedgerQueryScope scope, {
    required int valueScaled100,
    required QueryMenuAmountDomain? amountDomain,
  }) {
    final bounds = resolve(scope: scope, amountDomain: amountDomain);
    final value = valueScaled100
        .clamp(bounds.minimumScaled100, bounds.maximumScaled100)
        .toInt();
    final refinements = <String, Object?>{...scope.refinements}
      ..[refinementKey] = value;
    return scope.copyWith(refinements: refinements);
  }
}

/// Finite, ordered UI values derived from the existing Query facet domain.
final class QueryAmountThresholdBounds {
  const QueryAmountThresholdBounds._({
    required this.minimumScaled100,
    required this.maximumScaled100,
    required this.valueScaled100,
  });

  final int minimumScaled100;
  final int maximumScaled100;
  final int valueScaled100;
}
