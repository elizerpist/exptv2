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
}
