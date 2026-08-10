import 'package:flutter/foundation.dart';

import '../application/dashboard_time_navigation_state.dart';
import '../domain/ledger_time_scope.dart';
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
  /// Formats the currently rendered rail child from its typed visible scope.
  ///
  /// The navigation state intentionally retains the last settled child while
  /// a rail preview is moving. Summary copy must instead describe the child
  /// which is actually on screen, without parsing a query key or changing
  /// navigation ownership.
  static String liveRailChildSubtitle({
    required TimePlane plane,
    required LedgerTimeScope visibleChildScope,
    required String fallback,
  }) => switch ((plane, visibleChildScope)) {
    (TimePlane.year, MonthScope(:final value)) =>
      '${value.year} ${DashboardTimeLabelFormatter.monthName(value.month)}',
    (TimePlane.month, DayScope(:final date)) =>
      '${date.year} ${DashboardTimeLabelFormatter.monthName(date.month)} ${date.day}',
    _ => fallback,
  };

  static SummaryNavigationPresentation project(
    DashboardNavigationState state, {
    bool? isPreview,
  }) {
    final titleAndSubtitle = switch (state.plane) {
      TimePlane.sum => (
        title: 'Összesen',
        subtitle: state.isRailOpen
            ? state.retainedSemanticChild.toString()
            : 'Minden időszak',
      ),
      TimePlane.year => (
        title: 'Éves',
        subtitle: state.isRailOpen
            ? DashboardTimeLabelFormatter.yearMonth(
                YearMonth(
                  year: state.yearCursor,
                  month: state.retainedSemanticChild,
                ),
              )
            : state.yearCursor.toString(),
      ),
      TimePlane.month => (
        title: 'Havi',
        subtitle: state.isRailOpen
            ? DashboardTimeLabelFormatter.date(
                state.monthCursor,
                state.retainedSemanticChild,
              )
            : DashboardTimeLabelFormatter.yearMonth(state.monthCursor),
      ),
    };

    final change = state.lastChange;
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
      DashboardTimeNavigationChangeKind.retainedChild =>
        SummaryContentChangeReason.childSettled,
      DashboardTimeNavigationChangeKind.direction =>
        SummaryContentChangeReason.initial,
      DashboardTimeNavigationChangeKind.query =>
        SummaryContentChangeReason.initial,
    };

    return SummaryNavigationPresentation(
      plane: state.plane,
      planeTitle: titleAndSubtitle.title,
      subtitle: titleAndSubtitle.subtitle,
      isRailOpen: state.isRailOpen,
      revision: state.navigationEpoch,
      changeReason: committedReason,
      direction:
          change.direction == DashboardTimeNavigationChangeDirection.backward
          ? SummaryTransitionDirection.backward
          : SummaryTransitionDirection.forward,
      isPreview: isPreview ?? false,
    );
  }
}
