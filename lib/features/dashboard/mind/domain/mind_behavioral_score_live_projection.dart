import 'package:flutter/foundation.dart';

import '../../query/domain/query_amount_range.dart';
import 'mind_behavioral_score_projection.dart';

/// Publication identity for a visible Mind Header score. The prepared
/// projection identity is insufficient by itself because Summary navigation
/// can select another canonical daily point without changing the base.
@immutable
final class MindBehavioralScorePublicationIdentity {
  const MindBehavioralScorePublicationIdentity({
    required this.projection,
    required this.targetEpochDay,
    required this.navigationEpoch,
    this.seriesRequest,
  });

  final MindBehavioralScoreIdentity projection;
  final int targetEpochDay;
  final int navigationEpoch;
  final MindBehavioralScoreSeriesRequest? seriesRequest;

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScorePublicationIdentity &&
      other.projection == projection &&
      other.targetEpochDay == targetEpochDay &&
      other.navigationEpoch == navigationEpoch &&
      other.seriesRequest == seriesRequest;

  @override
  int get hashCode =>
      Object.hash(projection, targetEpochDay, navigationEpoch, seriesRequest);
}

/// One generation-checked publication path from prepared score input to the
/// semantic Header. It has no query mutation capability and rejects delayed
/// range/time/focus completions deterministically.
final class MindBehavioralScoreLiveProjection
    extends ValueNotifier<MindBehavioralScoreFrame?> {
  MindBehavioralScoreLiveProjection() : super(null);

  MindBehavioralScoreProjection? _projection;
  MindBehavioralScorePublicationIdentity? _identity;
  MindBehavioralScoreSeriesRequest? _seriesRequest;
  int stalePublicationRejectCount = 0;
  int publicationCount = 0;

  MindBehavioralScorePublicationIdentity? get identity => _identity;
  MindBehavioralScoreProjection? get projection => _projection;
  MindBehavioralScoreSourceWorkCounter? get sourceWorkCounter =>
      _projection?.sourceWorkCounter;

  void install({
    required MindBehavioralScoreProjection projection,
    required MindBehavioralScorePublicationIdentity identity,
    required QueryAmountRangeValues range,
    MindBehavioralScoreSeriesRequest? seriesRequest,
    int? chartStartEpochDay,
  }) {
    final resolvedRequest =
        seriesRequest ??
        identity.seriesRequest ??
        MindBehavioralScoreSeriesRequest(
          analyticStartInclusiveEpochDay:
              chartStartEpochDay ?? identity.targetEpochDay,
          analyticEndInclusiveEpochDay: identity.targetEpochDay,
          chartStartInclusiveEpochDay:
              chartStartEpochDay ?? identity.targetEpochDay,
          targetEpochDay: identity.targetEpochDay,
        );
    _projection = projection;
    _identity = identity;
    _seriesRequest = resolvedRequest;
    value = _frameFor(
      projection: projection,
      identity: identity,
      range: range,
      request: resolvedRequest,
    );
    publicationCount += 1;
  }

  bool publishPreview({
    required MindBehavioralScorePublicationIdentity expectedIdentity,
    required QueryAmountRangeValues range,
  }) {
    final projection = _projection;
    if (projection == null || _identity != expectedIdentity) {
      stalePublicationRejectCount += 1;
      return false;
    }
    if (value?.range == range) return true;
    value = _frameFor(
      projection: projection,
      identity: expectedIdentity,
      range: range,
      request:
          _seriesRequest ??
          MindBehavioralScoreSeriesRequest(
            analyticStartInclusiveEpochDay: expectedIdentity.targetEpochDay,
            analyticEndInclusiveEpochDay: expectedIdentity.targetEpochDay,
            chartStartInclusiveEpochDay: expectedIdentity.targetEpochDay,
            targetEpochDay: expectedIdentity.targetEpochDay,
          ),
    );
    publicationCount += 1;
    return true;
  }

  /// Changes the visible canonical day within the same immutable prepared
  /// universe. Summary Time transitions use this rather than rebuilding the
  /// score projection from source contributions.
  bool publishTarget({
    required MindBehavioralScoreIdentity expectedProjectionIdentity,
    required int targetEpochDay,
    required int navigationEpoch,
    required QueryAmountRangeValues range,
    MindBehavioralScoreSeriesRequest? seriesRequest,
    int? chartStartEpochDay,
  }) {
    final projection = _projection;
    if (projection == null ||
        projection.identity != expectedProjectionIdentity) {
      stalePublicationRejectCount += 1;
      return false;
    }
    final resolvedRequest =
        seriesRequest ??
        MindBehavioralScoreSeriesRequest(
          analyticStartInclusiveEpochDay: chartStartEpochDay ?? targetEpochDay,
          analyticEndInclusiveEpochDay: targetEpochDay,
          chartStartInclusiveEpochDay: chartStartEpochDay ?? targetEpochDay,
          targetEpochDay: targetEpochDay,
        );
    final next = MindBehavioralScorePublicationIdentity(
      projection: expectedProjectionIdentity,
      targetEpochDay: targetEpochDay,
      navigationEpoch: navigationEpoch,
      seriesRequest: seriesRequest,
    );
    if (_identity == next &&
        value?.range == range &&
        _seriesRequest == resolvedRequest) {
      return true;
    }
    _identity = next;
    _seriesRequest = resolvedRequest;
    value = _frameFor(
      projection: projection,
      identity: next,
      range: range,
      request: resolvedRequest,
    );
    publicationCount += 1;
    return true;
  }

  bool rejectStalePublication() {
    stalePublicationRejectCount += 1;
    return false;
  }

  void clear() {
    _projection = null;
    _identity = null;
    _seriesRequest = null;
    value = null;
  }

  MindBehavioralScoreFrame _frameFor({
    required MindBehavioralScoreProjection projection,
    required MindBehavioralScorePublicationIdentity identity,
    required QueryAmountRangeValues range,
    required MindBehavioralScoreSeriesRequest request,
  }) => projection.resolve(range: range, request: request);
}
