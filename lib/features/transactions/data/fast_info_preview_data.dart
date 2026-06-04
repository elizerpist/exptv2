import '../state/fast_info_metrics_resolver.dart';

Map<String, FastInfoMetricResult> buildFastInfoPreviewMetrics() {
  return FastInfoMetricsResolver.preview();
}
