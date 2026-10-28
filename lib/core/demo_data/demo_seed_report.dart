import 'package:flutter/foundation.dart';

@immutable
class DemoMonthReport {
  const DemoMonthReport({
    required this.year,
    required this.month,
    required this.entryCount,
    required this.incomeCount,
    required this.expenseCount,
    required this.incomeTargetMinor,
    required this.expenseTargetMinor,
    required this.incomeTotalMinor,
    required this.expenseTotalMinor,
  });

  final int year;
  final int month;
  final int entryCount;
  final int incomeCount;
  final int expenseCount;
  final int incomeTargetMinor;
  final int expenseTargetMinor;
  final int incomeTotalMinor;
  final int expenseTotalMinor;
}

@immutable
class DemoSeedReport {
  const DemoSeedReport({
    required this.seedVersion,
    required this.prngSeed,
    required this.createdCategoryCount,
    required this.createdPartnerCount,
    required this.createdEntryCount,
    required this.monthlyReports,
    required this.earliestEntryAtUtcMs,
    required this.latestEntryAtUtcMs,
    required this.alreadySeeded,
    required this.durationMs,
    this.createdGhostCategoryCount = 0,
    this.createdGhostPartnerCount = 0,
    this.createdGhostRuleCount = 0,
    this.createdGhostOccurrenceCount = 0,
    this.createdGhostLedgerEntryCount = 0,
    this.ghostOccurrenceCount = 0,
    this.ghostPendingOccurrenceCount = 0,
    this.ghostRealizedOccurrenceCount = 0,
    this.ghostLedgerEntryCount = 0,
  });

  final int seedVersion;
  final int prngSeed;
  final int createdCategoryCount;
  final int createdPartnerCount;
  final int createdEntryCount;
  final List<DemoMonthReport> monthlyReports;
  final int? earliestEntryAtUtcMs;
  final int? latestEntryAtUtcMs;
  final bool alreadySeeded;
  final int durationMs;
  final int createdGhostCategoryCount;
  final int createdGhostPartnerCount;
  final int createdGhostRuleCount;
  final int createdGhostOccurrenceCount;
  final int createdGhostLedgerEntryCount;
  final int ghostOccurrenceCount;
  final int ghostPendingOccurrenceCount;
  final int ghostRealizedOccurrenceCount;
  final int ghostLedgerEntryCount;
}
