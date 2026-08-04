import 'package:flutter/foundation.dart';

import '../application/dashboard_time_navigation_state.dart';
import '../application/summary_timing_debug.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';
import 'time_label_formatter.dart';

enum SummaryContentChangeReason {
  initial,
  railPreviewTick,
  verticalPlaneForward,
  verticalPlaneBackward,
  horizontalParentForward,
  horizontalParentBackward,
  railOpened,
  railClosed,
  childSettled,
}

enum SummaryTransitionAxis { none, horizontal, vertical }

enum SummaryTransitionDirection { forward, backward }

@immutable
class SummaryNavigationPresentation {
  const SummaryNavigationPresentation({
    required this.plane,
    required this.planeTitle,
    required this.subtitle,
    required this.isRailOpen,
    required this.revision,
    required this.changeReason,
    required this.direction,
    this.isPreview = false,
  });

  final TimePlane plane;
  final String planeTitle;
  final String subtitle;
  final bool isRailOpen;
  final int revision;
  final SummaryContentChangeReason changeReason;
  final SummaryTransitionDirection direction;
  final bool isPreview;

  SummaryTransitionAxis get transitionAxis => switch (changeReason) {
    SummaryContentChangeReason.verticalPlaneForward ||
    SummaryContentChangeReason.verticalPlaneBackward =>
      SummaryTransitionAxis.vertical,
    SummaryContentChangeReason.horizontalParentForward ||
    SummaryContentChangeReason.horizontalParentBackward =>
      SummaryTransitionAxis.horizontal,
    SummaryContentChangeReason.railOpened ||
    SummaryContentChangeReason.railClosed ||
    SummaryContentChangeReason.childSettled => SummaryTransitionAxis.vertical,
    SummaryContentChangeReason.initial ||
    SummaryContentChangeReason.railPreviewTick => SummaryTransitionAxis.none,
  };
}

abstract final class SummaryNavigationProjector {
  static SummaryNavigationPresentation project(
    DashboardTimeNavigationState state, {
    bool? isPreview,
  }) {
    final titleAndSubtitle = switch (state.plane) {
      TimePlane.sum => (
        title: 'Összesen',
        subtitle: state.isRailOpen
            ? state.displayedChild.toString()
            : 'Minden időszak',
      ),
      TimePlane.year => (
        title: 'Éves',
        subtitle: state.isRailOpen
            ? DashboardTimeLabelFormatter.yearMonth(
                YearMonth(year: state.yearCursor, month: state.displayedChild),
              )
            : state.yearCursor.toString(),
      ),
      TimePlane.month => (
        title: 'Havi',
        subtitle: state.isRailOpen
            ? DashboardTimeLabelFormatter.date(
                state.monthCursor,
                state.displayedChild,
              )
            : DashboardTimeLabelFormatter.yearMonth(state.monthCursor),
      ),
    };

    final change = state.lastChange;
    if (state.previewChild != null) {
      DashboardSummaryTimingDebug.mark(
        'P2 previewNavigationProjectionBuilt',
        value: titleAndSubtitle.subtitle,
      );
    } else if (change.kind == DashboardTimeNavigationChangeKind.child) {
      DashboardSummaryTimingDebug.mark(
        'S6 committedNavigationProjectionBuilt',
        value: titleAndSubtitle.subtitle,
      );
    }
    final committedReason = switch (change.kind) {
      DashboardTimeNavigationChangeKind.initial =>
        SummaryContentChangeReason.initial,
      DashboardTimeNavigationChangeKind.plane =>
        change.direction == DashboardTimeNavigationChangeDirection.forward
            ? SummaryContentChangeReason.verticalPlaneForward
            : SummaryContentChangeReason.verticalPlaneBackward,
      DashboardTimeNavigationChangeKind.parent =>
        change.direction == DashboardTimeNavigationChangeDirection.forward
            ? SummaryContentChangeReason.horizontalParentForward
            : SummaryContentChangeReason.horizontalParentBackward,
      DashboardTimeNavigationChangeKind.parentWhileRailOpen =>
        change.direction == DashboardTimeNavigationChangeDirection.forward
            ? SummaryContentChangeReason.horizontalParentForward
            : SummaryContentChangeReason.horizontalParentBackward,
      DashboardTimeNavigationChangeKind.rail =>
        state.isRailOpen
            ? SummaryContentChangeReason.railOpened
            : SummaryContentChangeReason.railClosed,
      DashboardTimeNavigationChangeKind.child =>
        SummaryContentChangeReason.childSettled,
    };
    final reason = state.previewChild != null
        ? SummaryContentChangeReason.railPreviewTick
        : committedReason;

    return SummaryNavigationPresentation(
      plane: state.plane,
      planeTitle: titleAndSubtitle.title,
      subtitle: titleAndSubtitle.subtitle,
      isRailOpen: state.isRailOpen,
      revision: state.navigationRevision,
      changeReason: reason,
      direction:
          change.direction == DashboardTimeNavigationChangeDirection.backward
          ? SummaryTransitionDirection.backward
          : SummaryTransitionDirection.forward,
      isPreview: isPreview ?? state.previewChild != null,
    );
  }
}
