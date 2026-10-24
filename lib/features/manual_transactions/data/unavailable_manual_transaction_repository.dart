import '../domain/manual_transaction_models.dart';
import '../domain/manual_transaction_repository.dart';
import '../../dashboard/query/domain/ledger_direction.dart';

final class UnavailableManualTransactionRepository
    implements ManualTransactionRepository {
  const UnavailableManualTransactionRepository();
  Never _unavailable() => throw UnsupportedError(
    'A manuális tranzakciók ezen a platformon nem érhetők el.',
  );
  @override
  Future<List<PartnerDirectoryEntry>> listPartners() async => _unavailable();
  @override
  Future<PartnerDirectoryEntry?> getPartnerById(String partnerId) async =>
      _unavailable();
  @override
  Future<PartnerDirectoryEntry?> resolvePartner(String partnerId) async =>
      _unavailable();
  @override
  Future<LedgerEntryDetail> getLedgerEntryById(String entryId) async =>
      _unavailable();
  @override
  Future<LedgerEntryDetail> createManualTransaction({
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required LedgerDirection direction,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  }) async => _unavailable();
  @override
  Future<LedgerEntryDetail> updateTransaction({
    required String entryId,
    required int expectedRevision,
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  }) async => _unavailable();
  @override
  Future<PartnerDirectoryEntry> updatePartner({
    required String partnerId,
    required String? displayNameOverride,
    required String defaultCategoryId,
  }) async => _unavailable();
}
