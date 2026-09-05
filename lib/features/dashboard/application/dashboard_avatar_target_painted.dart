import 'package:flutter/foundation.dart';

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

  bool get hasReadablePhaseAPaint =>
      exactEmpty || readablePhaseARowsPainted > 0;

  bool get hasRichPhaseBPaint => richPhaseBRowsPainted > 0;
}
