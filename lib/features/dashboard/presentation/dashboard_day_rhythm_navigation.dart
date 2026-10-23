import 'package:flutter/foundation.dart';
import '../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../time_navigation/application/dashboard_segmented_target_acceptance.dart';
import '../time_navigation/application/dashboard_time_navigation_state.dart';
import 'widgets/dashboard_temporal_component_carousel.dart';

/// Core-owned temporal acceptance capabilities exposed to the visual day rail.
/// Contains no ledger data and creates no navigation or animation owner.
@immutable
final class DashboardDayRhythmNavigation {
  const DashboardDayRhythmNavigation({
    required this.navigation,
    required this.candidateForOffset,
    required this.onCrossed,
    this.paintedTargets,
    this.onVisualTargetPainted,
    this.onSettled,
    this.onMotionActiveChanged,
    this.onDirectInputStarted,
    this.onPointerDownDecision,
    this.motionDiagnostics,
    this.coordinator,
  });
  final DashboardNavigationController navigation;
  final DashboardNavigationState? Function(
    DashboardNavigationState origin,
    int offset,
  )
  candidateForOffset;
  final DashboardSegmentedTargetAcceptance Function(
    DashboardNavigationState candidate,
  )
  onCrossed;
  final ValueListenable<DashboardSegmentedTargetPainted?>? paintedTargets;
  final ValueChanged<DashboardNavigationState>? onVisualTargetPainted;
  final ValueChanged<DashboardNavigationState>? onSettled;
  final ValueChanged<bool>? onMotionActiveChanged;
  final VoidCallback? onDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onPointerDownDecision;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;
  final DashboardTemporalCarouselCoordinator? coordinator;
}
