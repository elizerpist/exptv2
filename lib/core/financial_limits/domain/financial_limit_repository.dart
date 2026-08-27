import 'financial_limit.dart';

/// Future editor boundary. Dashboard rendering never receives this repository.
abstract interface class FinancialLimitRepository {
  Future<FinancialLimit?> get(FinancialLimitKey key);
  Future<List<FinancialLimit>> list();
  Future<FinancialLimit> upsert(FinancialLimitKey key, int amountScaled100);

  /// Persists one semantic collection in one transaction/revision.
  Future<List<FinancialLimit>> upsertBatch(List<FinancialLimitMutation> values);
  Future<bool> delete(FinancialLimitKey key);
}
