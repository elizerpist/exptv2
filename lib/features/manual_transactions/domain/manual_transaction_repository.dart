import '../../dashboard/query/domain/ledger_direction.dart';
import 'manual_transaction_models.dart';

abstract interface class ManualTransactionRepository {
  Future<List<PartnerDirectoryEntry>> listPartners();
  Future<PartnerDirectoryEntry?> getPartnerById(String partnerId);
  Future<PartnerDirectoryEntry?> resolvePartner(String partnerId);
  Future<LedgerEntryDetail> getLedgerEntryById(String entryId);
  Future<LedgerEntryDetail> createManualTransaction({
    required ManualPartnerSelection partner,
    required ManualCategorySelection categorySelection,
    required LedgerDirection direction,
    required int amountScaled100,
    required int bookedLocalEpochDay,
    required int bookedLocalTimeMinutes,
    required int occurredAtUtcMs,
    String? note,
  });
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
  });
  Future<PartnerDirectoryEntry> updatePartner({
    required String partnerId,
    required String? displayNameOverride,
    required String defaultCategoryId,
  });
}
