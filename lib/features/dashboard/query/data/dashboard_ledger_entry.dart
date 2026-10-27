import 'package:flutter/foundation.dart';

/// Immutable transport row decoded by a background prepared-frame worker.
@immutable
final class DashboardLedgerEntry {
  const DashboardLedgerEntry({
    required this.id,
    required this.partnerId,
    required this.categoryId,
    required this.direction,
    required this.amountMinor,
    required this.bookedLocalEpochDay,
    required this.bookedLocalTimeMinutes,
    this.note,
    this.occurredAtUtcMs,
    this.partnerDisplayName,
    this.partnerAvatarCategoryId,
    this.partnerAvatarColorId,
    this.partnerAvatarIconId,
    this.categoryDisplayName,
    this.categoryColorId,
    this.categoryIconId,
    this.assignmentMode,
    this.originKind,
    this.isPendingGhost = false,
    this.recurrenceOccurrenceId,
    this.amountIsUnknown = false,
  });

  final String id;
  final String partnerId;
  final String categoryId;
  final String direction;
  final int amountMinor;
  final int bookedLocalEpochDay;
  final int bookedLocalTimeMinutes;
  final String? note;
  final int? occurredAtUtcMs;
  final String? partnerDisplayName;

  /// Stable partner-default visual source. Transaction category overrides do
  /// not affect this avatar.
  final String? partnerAvatarCategoryId;
  final String? partnerAvatarColorId;
  final String? partnerAvatarIconId;
  final String? categoryDisplayName;
  final String? categoryColorId;
  final String? categoryIconId;
  final String? assignmentMode;
  final String? originKind;
  final bool isPendingGhost;
  final String? recurrenceOccurrenceId;
  final bool amountIsUnknown;

  /// Returns the same financial transport row with only its resolved visual
  /// metadata replaced.  A successful editor mutation uses this narrow
  /// projection while the authoritative revision rebuild is in flight: money,
  /// ordering and membership continue to belong to the native Core snapshot.
  DashboardLedgerEntry withVisualPatch(DashboardLedgerVisualPatch patch) {
    if (patch.entryId != id) {
      throw ArgumentError.value(patch.entryId, 'patch.entryId');
    }
    return DashboardLedgerEntry(
      id: id,
      partnerId: partnerId,
      categoryId: patch.categoryId,
      direction: direction,
      amountMinor: amountMinor,
      bookedLocalEpochDay: bookedLocalEpochDay,
      bookedLocalTimeMinutes: bookedLocalTimeMinutes,
      note: note,
      occurredAtUtcMs: occurredAtUtcMs,
      partnerDisplayName: patch.partnerDisplayName,
      partnerAvatarCategoryId: patch.partnerAvatarCategoryId,
      partnerAvatarColorId: patch.partnerAvatarColorId,
      partnerAvatarIconId: patch.partnerAvatarIconId,
      categoryDisplayName: patch.categoryDisplayName,
      categoryColorId: patch.categoryColorId,
      categoryIconId: patch.categoryIconId,
      assignmentMode: patch.assignmentMode,
      originKind: originKind,
      isPendingGhost: isPendingGhost,
      recurrenceOccurrenceId: recurrenceOccurrenceId,
      amountIsUnknown: amountIsUnknown,
    );
  }
}

/// Typed visual information returned by a successful editor save.  It is not
/// a financial snapshot and may update only an already visible row while the
/// revision-owned index, aggregates and memberships rebuild normally.
@immutable
final class DashboardLedgerVisualPatch {
  const DashboardLedgerVisualPatch({
    required this.entryId,
    required this.partnerId,
    required this.direction,
    required this.amountMinor,
    required this.bookedLocalEpochDay,
    required this.bookedLocalTimeMinutes,
    required this.partnerDisplayName,
    required this.partnerAvatarCategoryId,
    required this.partnerAvatarColorId,
    required this.partnerAvatarIconId,
    required this.categoryId,
    required this.categoryDisplayName,
    required this.categoryColorId,
    required this.categoryIconId,
    required this.assignmentMode,
    required this.entryRevision,
  });

  final String entryId;
  final String partnerId;
  final String direction;
  final int amountMinor;
  final int bookedLocalEpochDay;
  final int bookedLocalTimeMinutes;
  final String partnerDisplayName;
  final String partnerAvatarCategoryId;
  final String partnerAvatarColorId;
  final String partnerAvatarIconId;
  final String categoryId;
  final String categoryDisplayName;
  final String categoryColorId;
  final String categoryIconId;
  final String assignmentMode;
  final int entryRevision;

  int get visualIdentity => Object.hash(
    entryId,
    partnerId,
    direction,
    amountMinor,
    bookedLocalEpochDay,
    bookedLocalTimeMinutes,
    partnerDisplayName,
    partnerAvatarCategoryId,
    partnerAvatarColorId,
    partnerAvatarIconId,
    categoryId,
    categoryDisplayName,
    categoryColorId,
    categoryIconId,
    assignmentMode,
    entryRevision,
  );
}
