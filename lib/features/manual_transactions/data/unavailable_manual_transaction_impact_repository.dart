import '../domain/manual_transaction_impact_repository.dart';
import '../../dashboard/query/domain/ledger_direction.dart';

final class UnavailableManualTransactionImpactRepository
    implements ManualTransactionImpactRepository {
  const UnavailableManualTransactionImpactRepository();

  @override
  Future<ManualTransactionMonthImpact> loadMonthImpact({
    required LedgerDirection direction,
    required String? categoryId,
    required int year,
    required int month,
    String? excludedEntryId,
  }) => Future<ManualTransactionMonthImpact>.error(
    UnsupportedError('A tranzakcióhatás ezen a platformon nem érhető el.'),
  );
}
