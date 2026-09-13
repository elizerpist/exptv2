import 'package:flutter/foundation.dart';

import '../../query/domain/query_amount_range.dart';
import 'mind_year_heatmap_projection.dart';

/// One active, generation-safe publication lane for the Mind annual read
/// model. It owns no query/filter state: Core installs an immutable projection
/// only after the existing canonical upstream identity is ready.
final class MindYearHeatmapLiveProjection
    extends ValueNotifier<MindYearHeatmapFrame?> {
  MindYearHeatmapLiveProjection() : super(null);

  MindYearHeatmapProjection? _projection;
  int stalePublicationRejectCount = 0;
  int publicationCount = 0;

  MindYearHeatmapIdentity? get identity => _projection?.identity;

  /// Bounded hot-path evidence exposed to focused tests/profile harnesses.
  /// This never exposes mutable ledger data to a rendering consumer.
  MindYearHeatmapSourceWorkCounter? get sourceWorkCounter =>
      _projection?.sourceWorkCounter;

  void install(
    MindYearHeatmapProjection projection,
    QueryAmountRangeValues initialRange,
  ) {
    _projection = projection;
    value = projection.preview(initialRange);
    publicationCount += 1;
  }

  /// Accepts a coalesced preview only when its captured upstream identity is
  /// still the active projection. A pending callback after a year/filter/data
  /// replacement therefore cannot flash an old heatmap into the new surface.
  bool publishPreview(
    MindYearHeatmapIdentity expectedIdentity,
    QueryAmountRangeValues range,
  ) {
    final projection = _projection;
    if (projection == null || projection.identity != expectedIdentity) {
      stalePublicationRejectCount += 1;
      return false;
    }
    value = projection.preview(range);
    publicationCount += 1;
    return true;
  }

  bool rejectStalePublication() {
    stalePublicationRejectCount += 1;
    return false;
  }

  /// The existing shared RangeSlider flushes its coalescer before canonical
  /// commit. This explicit terminal entry point makes the matching heatmap
  /// publication synchronous under the same generation guard.
  bool flushTerminalPreview(
    MindYearHeatmapIdentity expectedIdentity,
    QueryAmountRangeValues range,
  ) => publishPreview(expectedIdentity, range);

  void clear() {
    _projection = null;
    value = null;
  }
}
