import '../../dashboard/query/domain/ledger_direction.dart';
import '../../../core/categories/domain/fluvi_category.dart';

enum ManualCategoryAssignmentMode { partnerDefault, entryOverride }

final class PartnerDirectoryEntry {
  const PartnerDirectoryEntry({
    required this.partnerId,
    required this.displayName,
    required this.originalName,
    required this.defaultCategoryId,
    required this.defaultCategoryName,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.isUncategorized,
    required this.searchNames,
  });

  final String partnerId;
  final String displayName;
  final String originalName;
  final String defaultCategoryId;
  final String defaultCategoryName;
  final String categoryColorId;
  final String categoryIconId;
  final bool isUncategorized;
  final List<String> searchNames;

  factory PartnerDirectoryEntry.fromMap(Map<Object?, Object?> value) =>
      PartnerDirectoryEntry(
        partnerId: _string(value, 'partnerId'),
        displayName: _string(value, 'displayName'),
        originalName: _string(value, 'originalName'),
        defaultCategoryId: _string(value, 'defaultCategoryId'),
        defaultCategoryName: _string(value, 'defaultCategoryName'),
        categoryColorId: _string(value, 'categoryColorId'),
        categoryIconId: _string(value, 'categoryIconId'),
        isUncategorized: value['isUncategorized'] == true,
        searchNames: _strings(value['searchNames']),
      );
}

final class LedgerEntryDetail {
  const LedgerEntryDetail({
    required this.entryId,
    required this.partnerId,
    required this.categoryId,
    required this.categoryAssignmentMode,
    required this.direction,
    required this.amountScaled100,
    required this.bookedLocalEpochDay,
    required this.bookedLocalTimeMinutes,
    required this.occurredAtUtcMs,
    required this.note,
    required this.originKind,
    required this.notificationInboxId,
    this.recurrenceOccurrenceId,
    this.coreRevision,
    required this.revision,
  });

  final String entryId;
  final String partnerId;
  final String categoryId;
  final ManualCategoryAssignmentMode categoryAssignmentMode;
  final LedgerDirection direction;
  final int amountScaled100;
  final int bookedLocalEpochDay;
  final int bookedLocalTimeMinutes;
  final int occurredAtUtcMs;
  final String? note;
  final String originKind;
  final String? notificationInboxId;
  final String? recurrenceOccurrenceId;

  /// Global financial-Core revision returned only by successful save commands.
  /// This is intentionally distinct from the per-entry [revision].
  final int? coreRevision;
  final int revision;

  factory LedgerEntryDetail.fromMap(
    Map<Object?, Object?> value,
  ) => LedgerEntryDetail(
    entryId: _string(value, 'entryId'),
    partnerId: _string(value, 'partnerId'),
    categoryId: _string(value, 'categoryId'),
    categoryAssignmentMode: switch (_string(value, 'categoryAssignmentMode')) {
      'partnerDefault' => ManualCategoryAssignmentMode.partnerDefault,
      'entryOverride' => ManualCategoryAssignmentMode.entryOverride,
      final mode => throw FormatException('Unknown category mode $mode.'),
    },
    direction: switch (_string(value, 'direction')) {
      'income' => LedgerDirection.income,
      'expense' => LedgerDirection.expense,
      final direction => throw FormatException('Unknown direction $direction.'),
    },
    amountScaled100: _int(value, 'amountScaled100'),
    bookedLocalEpochDay: _int(value, 'bookedLocalEpochDay'),
    bookedLocalTimeMinutes: _int(value, 'bookedLocalTimeMinutes'),
    occurredAtUtcMs: _int(value, 'occurredAtUtcMs'),
    note: value['note'] as String?,
    originKind: _string(value, 'originKind'),
    notificationInboxId: value['notificationInboxId'] as String?,
    recurrenceOccurrenceId: value['recurrenceOccurrenceId'] as String?,
    coreRevision: _optionalInt(value['coreRevision']),
    revision: _int(value, 'revision'),
  );
}

/// The typed hand-off from the editor to the Core-owned dashboard runtime.
/// It carries the persisted entry, its independently versioned Core mutation,
/// and the already-resolved display inputs needed by a receiving surface.
final class ManualTransactionSaveResult {
  const ManualTransactionSaveResult({
    required this.entry,
    required this.partner,
    required this.effectiveCategory,
    required this.globalCoreRevision,
  });

  final LedgerEntryDetail entry;
  final PartnerDirectoryEntry partner;
  final FluviCategory? effectiveCategory;
  final int? globalCoreRevision;
}

sealed class ManualPartnerSelection {
  const ManualPartnerSelection();

  Map<String, Object?> toMap();
}

final class ExistingManualPartner extends ManualPartnerSelection {
  const ExistingManualPartner(this.partnerId, {this.directoryEntry});
  final String partnerId;

  /// The selector already owns this immutable visual snapshot. Retaining it
  /// lets normal and recurring editors render the selected partner without a
  /// second directory read on every selection.
  final PartnerDirectoryEntry? directoryEntry;
  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': 'existing',
    'partnerId': partnerId,
  };
}

final class NewManualPartner extends ManualPartnerSelection {
  const NewManualPartner({
    required this.displayName,
    required this.defaultCategoryId,
  });
  final String displayName;
  final String defaultCategoryId;
  @override
  Map<String, Object?> toMap() => <String, Object?>{
    'kind': 'new',
    'displayName': displayName,
    'defaultCategoryId': defaultCategoryId,
  };
}

final class ManualCategorySelection {
  const ManualCategorySelection.partnerDefault()
    : mode = ManualCategoryAssignmentMode.partnerDefault,
      categoryId = null;
  const ManualCategorySelection.entryOverride(this.categoryId)
    : mode = ManualCategoryAssignmentMode.entryOverride;

  final ManualCategoryAssignmentMode mode;
  final String? categoryId;

  Map<String, Object?> toMap() => <String, Object?>{
    'mode': mode.name,
    if (categoryId != null) 'categoryId': categoryId,
  };
}

String _string(Map<Object?, Object?> value, String key) {
  final result = value[key];
  if (result is String && result.isNotEmpty) return result;
  throw FormatException('Missing $key in manual transaction payload.');
}

int _int(Map<Object?, Object?> value, String key) {
  final result = value[key];
  if (result is int) return result;
  if (result is num) return result.toInt();
  throw FormatException('Missing $key in manual transaction payload.');
}

int? _optionalInt(Object? value) => switch (value) {
  int value => value,
  num value => value.toInt(),
  _ => null,
};

List<String> _strings(Object? value) {
  if (value is! Iterable) return const <String>[];
  return value
      .whereType<String>()
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}
