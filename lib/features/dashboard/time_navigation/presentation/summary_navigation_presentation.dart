import 'package:flutter/foundation.dart';

import '../application/dashboard_time_navigation_state.dart';
import '../domain/time_plane.dart';
import '../domain/year_month.dart';
import 'time_label_formatter.dart';

enum SummaryContentChangeReason {
  initial,
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
  });

  final TimePlane plane;
  final String planeTitle;
  final String subtitle;
  final bool isRailOpen;
  final int revision;
  final SummaryContentChangeReason changeReason;
  final SummaryTransitionDirection direction;

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
    SummaryContentChangeReason.initial => SummaryTransitionAxis.none,
  };
}

abstract final class SummaryNavigationProjector {
  static SummaryNavigationPresentation project(
    DashboardTimeNavigationState state,
  ) {
    final titleAndSubtitle = switch (state.plane) {
      TimePlane.sum => (
        title: 'Összesen',
        subtitle: state.isRailOpen
            ? state.settledChildYear.toString()
            : 'Minden időszak',
      ),
      TimePlane.year => (
        title: 'Éves',
        subtitle: state.isRailOpen
            ? DashboardTimeLabelFormatter.monthName(state.settledChildMonth)
            : state.yearCursor.toString(),
      ),
      TimePlane.month => (
        title: 'Havi',
        subtitle: state.isRailOpen
            ? '${state.monthCursor.clampDay(state.settledChildDay).day}.'
            : _formatYearMonth(state.monthCursor),
      ),
    };

    final change = state.lastChange;
    final reason = switch (change.kind) {
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
      DashboardTimeNavigationChangeKind.rail =>
        state.isRailOpen
            ? SummaryContentChangeReason.railOpened
            : SummaryContentChangeReason.railClosed,
      DashboardTimeNavigationChangeKind.child =>
        SummaryContentChangeReason.childSettled,
    };

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
    );
  }

  static String _formatYearMonth(YearMonth value) {
    return '${value.year}. ${DashboardTimeLabelFormatter.monthName(value.month)}';
  }
}
