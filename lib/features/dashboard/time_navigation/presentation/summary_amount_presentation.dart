import 'package:flutter/foundation.dart';

@immutable
class SummaryAmountPresentation {
  const SummaryAmountPresentation({
    required this.formattedAmount,
    required this.scopeKey,
    required this.isLoading,
    required this.isStale,
    required this.hasError,
    this.entryCount = 0,
    this.coreRevision,
    this.totalMinor,
  });

  final String formattedAmount;
  final String scopeKey;
  final bool isLoading;
  final bool isStale;
  final bool hasError;
  final int entryCount;
  final int? coreRevision;
  final int? totalMinor;
}
