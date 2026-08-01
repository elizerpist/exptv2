import 'package:flutter/foundation.dart';

@immutable
class SummaryAmountPresentation {
  const SummaryAmountPresentation({
    required this.formattedAmount,
    required this.scopeKey,
    required this.isLoading,
    required this.isStale,
    required this.hasError,
  });

  final String formattedAmount;
  final String scopeKey;
  final bool isLoading;
  final bool isStale;
  final bool hasError;
}
