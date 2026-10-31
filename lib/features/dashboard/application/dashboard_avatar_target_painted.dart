import 'package:flutter/foundation.dart';

/// The production surface whose real canvas paint acknowledged an Avatar
/// target.  A Budget Avatar is visibly complete when its selected chrome has
/// painted; the LogBox can legitimately be outside the active Budget surface
/// and must not be made a prerequisite for that visible result.
enum DashboardAvatarTargetPaintSource { logBox, selectedAvatarProgress }

/// Immutable evidence emitted by the selected Budget Avatar's progress
/// painter.  It intentionally contains only the presentation identity that
/// the painter received, never mutable selection or row data.
@immutable
final class DashboardAvatarSelectedVisualPainted {
  const DashboardAvatarSelectedVisualPainted({
    required this.targetHandle,
    required this.coreRevision,
    required this.presentationEpoch,
    required this.frameGeneration,
  });

  final int targetHandle;
  final int coreRevision;
  final int presentationEpoch;
  final int frameGeneration;
}

/// Bounded post-paint evidence for one exact, accepted Avatar target.
///
/// This metadata crosses the Core-to-rail composition boundary only for
/// diagnostic accounting. It neither owns rows nor changes the visible-frame,
/// Budget-selection, or canonical-settle authority.
@immutable
final class DashboardAvatarTargetPainted {
  const DashboardAvatarTargetPainted({
    required this.targetHandle,
    required this.focusGeneration,
    required this.queryKey,
    required this.coreRevision,
    required this.presentationEpoch,
    required this.frameGeneration,
    required this.exactEmpty,
    required this.readablePhaseARowsPainted,
    required this.richPhaseBRowsPainted,
    this.source = DashboardAvatarTargetPaintSource.logBox,
  });

  final int targetHandle;
  final int focusGeneration;
  final String queryKey;
  final int coreRevision;
  final int presentationEpoch;
  final int frameGeneration;
  final bool exactEmpty;
  final int readablePhaseARowsPainted;
  final int richPhaseBRowsPainted;
  final DashboardAvatarTargetPaintSource source;

  bool get hasReadablePhaseAPaint =>
      exactEmpty || readablePhaseARowsPainted > 0;

  bool get hasRichPhaseBPaint => richPhaseBRowsPainted > 0;
}
