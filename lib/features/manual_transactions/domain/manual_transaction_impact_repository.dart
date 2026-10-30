import '../../dashboard/query/domain/ledger_direction.dart';

/// One immutable read from the Core-owned Budget/Ledger calculation path.
///
/// Amounts are always scaled by 100.  The values exclude [excludedEntryId]
/// when an existing entry is being edited, so the editor can add its current
/// draft without counting the old entry twice.
final class ManualTransactionMonthImpact {
  const ManualTransactionMonthImpact({
    required this.categoryActualScaled100,
    required this.categoryLimitScaled100,
    required this.monthIncomeScaled100,
    required this.monthExpenseScaled100,
  });

  final int categoryActualScaled100;

  /// Null means that this category has no effective monthly limit. Zero is a
  /// valid resolved limit and must remain visible as an overrun.
  final int? categoryLimitScaled100;
  final int monthIncomeScaled100;
  final int monthExpenseScaled100;
}

/// Narrow, read-only editor dependency.  The native implementation delegates
/// to the same prepared Budget snapshot used by the dashboard rather than
/// recreating limit resolution in the widget tree.
abstract interface class ManualTransactionImpactRepository {
  Future<ManualTransactionMonthImpact> loadMonthImpact({
    required LedgerDirection direction,
    required String? categoryId,
    required int year,
    required int month,
    String? excludedEntryId,
  });
}
