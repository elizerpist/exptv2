import 'mind_behavioral_score_projection.dart';
import 'mind_temporal_heatmap_frame.dart';
import 'mind_temporal_heatmap_projection.dart';
import 'mind_year_heatmap_projection.dart';

/// Stable, non-financial identities shared by Mind-entry diagnostics.
///
/// Core owns entry correlation and the renderers only acknowledge the same
/// immutable publication. Keeping the string construction here prevents a
/// Header/body acknowledgement from silently using a different identity than
/// the one Core published.
String mindTemporalEntryBodyFrameIdentity(
  MindTemporalHeatmapFrame frame,
) => switch (frame) {
  MindYearHeatmapFrame(:final identity) =>
    '${identity.year}:${identity.indexGeneration}:${identity.navigationEpoch}',
  MindSumHeatmapFrame(:final identity) ||
  MindMonthHeatmapFrame(:final identity) ||
  MindDayHeatmapFrame(:final identity) =>
    '${identity.timeScopeKey}:${identity.indexGeneration}:${identity.navigationEpoch}',
  MindTemporalHeatmapFrame() => 'unsupported:${frame.identity}',
};

/// Stable identity for the Header score content belonging to one Mind entry.
String mindTemporalEntryHeaderFrameIdentity(MindBehavioralScoreFrame frame) {
  final identity = frame.identity;
  return '${identity.upstreamScopeKey}:${identity.indexGeneration}:'
      '${identity.coreRevision}:${identity.direction.name}:'
      '${frame.range.lowerScaled100}:${frame.range.upperScaled100}';
}
