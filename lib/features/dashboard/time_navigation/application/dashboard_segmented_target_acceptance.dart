import 'package:flutter/foundation.dart';

import 'dashboard_time_navigation_controller.dart';
import 'dashboard_time_navigation_state.dart';

/// The synchronous outcome of asking the Dashboard coordinator to make one
/// Segmented Summary target visible.
///
/// A selector may emit many physical candidates while a finger or ballistic
/// simulation moves.  Emission alone is not an ownership transfer: only an
/// exact prepared target accepted by the coordinator may later be settled.
enum DashboardSegmentedTargetAcceptance {
  acceptedExact,
  acceptedExactEmpty,
  acceptedDeferredForPainterResource,
  rejectedDisposed,
  rejectedNotPrepared,
  rejectedStaleGeneration,
  rejectedRevisionMismatch;

  /// Exact accepted values identify a complete, atomically selected visible
  /// frame. Empty is a valid exact result, never a loading surrogate. The
  /// deferred value is accepted semantic intent whose visible frame is held
  /// until the exact painter resource is ready.
  bool get isExactLivePublication => switch (this) {
    DashboardSegmentedTargetAcceptance.acceptedExact ||
    DashboardSegmentedTargetAcceptance.acceptedExactEmpty => true,
    DashboardSegmentedTargetAcceptance.acceptedDeferredForPainterResource ||
    DashboardSegmentedTargetAcceptance.rejectedDisposed ||
    DashboardSegmentedTargetAcceptance.rejectedNotPrepared ||
    DashboardSegmentedTargetAcceptance.rejectedStaleGeneration ||
    DashboardSegmentedTargetAcceptance.rejectedRevisionMismatch => false,
  };

  /// A deferred target remains the latest physical semantic intent, but has
  /// not yet been given visible authority. The selector may retain it for
  /// release settlement; Core promotes it only after its exact Phase-A
  /// resource binds and paints.
  bool get isAcceptedSemanticIntent => switch (this) {
    DashboardSegmentedTargetAcceptance.acceptedExact ||
    DashboardSegmentedTargetAcceptance.acceptedExactEmpty ||
    DashboardSegmentedTargetAcceptance.acceptedDeferredForPainterResource =>
      true,
    DashboardSegmentedTargetAcceptance.rejectedDisposed ||
    DashboardSegmentedTargetAcceptance.rejectedNotPrepared ||
    DashboardSegmentedTargetAcceptance.rejectedStaleGeneration ||
    DashboardSegmentedTargetAcceptance.rejectedRevisionMismatch => false,
  };
}

/// Bounded post-paint evidence for one accepted Segmented target.
///
/// The coordinator emits this only after the matching LogBox render surface
/// reports an exact drawable/painted state.  It is intentionally metadata
/// only: the visible-frame store remains the sole owner of rows and data.
@immutable
final class DashboardSegmentedTargetPainted {
  const DashboardSegmentedTargetPainted({
    required this.target,
    required this.component,
    required this.interactionGeneration,
    required this.queryKey,
    required this.coreRevision,
    required this.exactEmpty,
  });

  final DashboardNavigationState target;
  final DashboardTemporalAnchorComponent component;
  final int interactionGeneration;
  final String queryKey;
  final int coreRevision;
  final bool exactEmpty;
}
