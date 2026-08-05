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
    this.categoryDisplayName,
    this.categoryColorId,
    this.categoryIconId,
    this.assignmentMode,
    this.originKind,
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
  final String? categoryDisplayName;
  final String? categoryColorId;
  final String? categoryIconId;
  final String? assignmentMode;
  final String? originKind;
}
