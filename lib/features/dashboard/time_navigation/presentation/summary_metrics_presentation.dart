import 'package:flutter/foundation.dart';

import '../../query/domain/scope_summary_metrics.dart';

/// The sole formatted snapshot rendered by SummaryPill and LogBox.
@immutable
class SummaryMetricsPresentation {
  const SummaryMetricsPresentation._({
    required this.metrics,
    required this.formattedAmount,
    required this.formattedEntryCount,
    required this.presentationEpoch,
  });

  factory SummaryMetricsPresentation.fromMetrics(
    ScopeSummaryMetrics metrics, {
    String Function(int totalMinor)? amountFormatter,
    String Function(int entryCount)? entryCountFormatter,
    int presentationEpoch = 0,
  }) {
    final totalMinor = metrics.totalMinor;
    final entryCount = metrics.entryCount;
    return SummaryMetricsPresentation._(
      metrics: metrics,
      formattedAmount: totalMinor == null
          ? '— Ft'
          : (amountFormatter ?? formatTotalMinor)(totalMinor),
      formattedEntryCount: entryCount == null
          ? '—'
          : (entryCountFormatter ?? _formatEntryCount)(entryCount),
      presentationEpoch: presentationEpoch,
    );
  }

  final ScopeSummaryMetrics metrics;
  final String formattedAmount;
  final String formattedEntryCount;
  final int presentationEpoch;

  String get scopeKey => metrics.canonicalQueryKey;
  bool get isLoading => metrics.isLoading;
  bool get isStale => metrics.isStale;
  bool get hasError => metrics.hasError;
  int? get entryCount => metrics.entryCount;
  int? get coreRevision => metrics.coreRevision;
  int? get totalMinor => metrics.totalMinor;
  String get flowId => 'Q-${metrics.canonicalQueryKey}';
  bool get isPreview =>
      metrics.source == SummaryMetricsSource.childPreviewIndex;
  SummaryMetricsSource get source => metrics.source;

  static String formatTotalMinor(int totalMinor) {
    if (totalMinor == 0) return '0 Ft';
    final sign = totalMinor < 0 ? '-' : '';
    final absolute = totalMinor.abs();
    final major = absolute ~/ 100;
    final minor = (absolute % 100).toString().padLeft(2, '0');
    return '$sign$major,$minor Ft';
  }

  static String _formatEntryCount(int entryCount) => entryCount.toString();
}
