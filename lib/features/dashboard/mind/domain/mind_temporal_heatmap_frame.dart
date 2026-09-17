import '../../query/domain/query_amount_range.dart';

/// Read-only result of Mind's single temporal heatmap publication lane.
///
/// Individual renderers retain their strongly typed payloads, while Core uses
/// this small common contract to publish exactly one current Sum/Year/Month
/// heatmap target. It is presentation data only and cannot mutate Query.
abstract interface class MindTemporalHeatmapFrame {
  Object get identity;

  QueryAmountRangeValues get range;
}
