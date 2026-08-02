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
    this.flowId,
    this.isPreview = false,
  });

  final String formattedAmount;
  final String scopeKey;
  final bool isLoading;
  final bool isStale;
  final bool hasError;
  final int entryCount;
  final int? coreRevision;
  final int? totalMinor;
  final String? flowId;

  /// True while the rail is moving across a transient child selection.
  ///
  /// Preview values must stay on the carousel hot path: they replace the
  /// displayed text directly and never start an amount transition.
  final bool isPreview;
}
