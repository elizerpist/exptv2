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
  });

  final MindBehavioralScoreIdentity projection;
  final int targetEpochDay;
  final int navigationEpoch;

  @override
  bool operator ==(Object other) =>
      other is MindBehavioralScorePublicationIdentity &&
      other.projection == projection &&
      other.targetEpochDay == targetEpochDay &&
      other.navigationEpoch == navigationEpoch;

  @override
  int get hashCode => Object.hash(projection, targetEpochDay, navigationEpoch);
}

/// One generation-checked publication path from prepared score input to the
/// semantic Header. It has no query mutation capability and rejects delayed
/// range/time/focus completions deterministically.
final class MindBehavioralScoreLiveProjection
    extends ValueNotifier<MindBehavioralScoreFrame?> {
  MindBehavioralScoreLiveProjection() : super(null);

  MindBehavioralScoreProjection? _projection;
  MindBehavioralScorePublicationIdentity? _identity;
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
  }) {
    _projection = projection;
    _identity = identity;
    value = projection.preview(
      range: range,
      targetEpochDay: identity.targetEpochDay,
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
    value = projection.preview(
      range: range,
      targetEpochDay: expectedIdentity.targetEpochDay,
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
  }) {
    final projection = _projection;
    if (projection == null ||
        projection.identity != expectedProjectionIdentity) {
      stalePublicationRejectCount += 1;
      return false;
    }
    final next = MindBehavioralScorePublicationIdentity(
      projection: expectedProjectionIdentity,
      targetEpochDay: targetEpochDay,
      navigationEpoch: navigationEpoch,
    );
    if (_identity == next && value?.range == range) return true;
    _identity = next;
    value = projection.preview(range: range, targetEpochDay: targetEpochDay);
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
    value = null;
  }
}
