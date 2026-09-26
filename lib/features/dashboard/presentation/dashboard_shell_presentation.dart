import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';

import '../../../core/design/dashboard_layout_metrics.dart';
import '../../../core/design/dashboard_mode_palette.dart';

enum DashboardBottomNavEdgeShape { rounded, straight }

enum DashboardBottomNavTopBorder { off, thinGrey }

/// Selects between the unchanged BNB-03 raised centre and the contained,
/// horizontal-top alternative. This remains shell-local presentation state;
/// it has no navigation or destination authority.
enum DashboardBottomNavLayoutStyle { raisedFab, containedFlat }

/// Selects where reclaimed flat-navigation body extent is assigned. The
/// stored choice is intentionally retained while its BottomNav is ineligible.
enum DashboardFlatBottomNavBodyStretch { off, expandedHeader, modeContent }

/// Pure bridge between shell BottomNav geometry and the dashboard's existing
/// resolved Ledger origin. This centralizes different shell/dashboard scales
/// without a render-object measurement loop.
@immutable
final class DashboardFlatBottomNavStretchLayout {
  const DashboardFlatBottomNavStretchLayout._({
    required this.isEligible,
    required this.physicalBottomNavTop,
    required this.releasedFlatBottomNavEnvelopeGain,
    required this.countSafeGain,
    required this.availableGain,
    required this.desiredGain,
    required this.delta,
    required this.scaledLedgerHeaderTopInset,
    required this.scaledLedgerCountHeight,
    required this.scaledCountToSearchGap,
    required this.scaledMinimumCountToNavClearance,
  });

  static const referenceBottomNavWidth = 428.0;
  static const referenceContainedBarHeight = 75.0;
  static const referenceRaisedFabOverflowTop = 24.0;

  final bool isEligible;
  final double physicalBottomNavTop;

  /// The exact vertical envelope released by replacing the raised BNB FAB
  /// with the contained-flat FAB at this physical BottomNav width.
  ///
  /// It is zero while the shell configuration is ineligible, so a stored
  /// target cannot move the body outside the straight + contained-flat mode.
  final double releasedFlatBottomNavEnvelopeGain;

  /// The greatest downstream gain that keeps the rendered Ledger count and
  /// its required breathing clearance above the physical navigation edge.
  final double countSafeGain;

  /// The usable gain: the smaller of the actually released Flat BottomNav
  /// envelope and the count-safe gain. This prevents the Dashboard from
  /// consuming arbitrary remaining viewport space merely because it happens
  /// to be free below the Ledger.
  final double availableGain;

  /// The gain that would place the real SearchPill origin at the nav edge.
  final double desiredGain;

  /// The safe gain applied to Dashboard geometry: never more than both the
  /// released envelope and the count-safe extent. On constrained viewports
  /// this intentionally prefers a small SearchPill remainder over clipping
  /// the count row.
  final double delta;
  final double scaledLedgerHeaderTopInset;
  final double scaledLedgerCountHeight;
  final double scaledCountToSearchGap;

  /// The count text owns at least one whole rendered count-lane of clearance
  /// above a flat navigation bar. This makes the physical count row more
  /// important than perfect SearchPill occlusion on constrained viewports.
  final double scaledMinimumCountToNavClearance;

  double searchPillTopFor({required double logBoxHeaderTop}) =>
      logBoxHeaderTop +
      scaledLedgerHeaderTopInset +
      scaledLedgerCountHeight +
      scaledCountToSearchGap;

  double countBottomFor({required double logBoxHeaderTop}) =>
      logBoxHeaderTop + scaledLedgerHeaderTopInset + scaledLedgerCountHeight;

  static DashboardFlatBottomNavStretchLayout resolve({
    required Size viewport,
    required double safeBottomInset,
    required DashboardLayoutMetrics metrics,
    required double logBoxHeaderTop,
    required DashboardShellPresentationSettings settings,
  }) {
    final eligible =
        settings.bottomNavEdgeShape == DashboardBottomNavEdgeShape.straight &&
        settings.bottomNavLayoutStyle ==
            DashboardBottomNavLayoutStyle.containedFlat;
    final bottomNavScale = viewport.width / referenceBottomNavWidth;
    final releasedEnvelope = referenceRaisedFabOverflowTop * bottomNavScale;
    final physicalTop =
        viewport.height -
        safeBottomInset -
        referenceContainedBarHeight * bottomNavScale;
    final dashboardScale =
        metrics.standardGap / DashboardLayoutMetrics.referenceStandardGap;
    final inset = DashboardLogBoxTokens.ledgerHeaderTopInset * dashboardScale;
    final count = DashboardLogBoxTokens.ledgerCountHeight * dashboardScale;
    final gap = DashboardLogBoxTokens.ledgerCountToSearchGap * dashboardScale;
    final currentSearchTop = logBoxHeaderTop + inset + count + gap;
    final desiredGain = math.max(0.0, physicalTop - currentSearchTop);
    // SearchPill begins after the count's authored gap. Keeping its top flush
    // with the navigation edge therefore puts the count just one small gap
    // above the bar, which is too fragile on physical devices. The count owns
    // a full lane clearance; if that conflicts with SearchPill occlusion, the
    // latter is allowed to retain only the minimal visible remainder.
    final minimumCountToNavClearance = math.max(gap, count);
    final countSafeGain = math.max(
      0.0,
      physicalTop -
          (logBoxHeaderTop + inset + count) -
          minimumCountToNavClearance,
    );
    final effectiveReleasedEnvelope = eligible ? releasedEnvelope : 0.0;
    final effectiveCountSafeGain = eligible ? countSafeGain : 0.0;
    final availableGain = math.min(
      effectiveReleasedEnvelope,
      effectiveCountSafeGain,
    );
    return DashboardFlatBottomNavStretchLayout._(
      isEligible: eligible,
      physicalBottomNavTop: physicalTop,
      releasedFlatBottomNavEnvelopeGain: effectiveReleasedEnvelope,
      countSafeGain: effectiveCountSafeGain,
      availableGain: availableGain,
      desiredGain: eligible ? desiredGain : 0,
      delta: eligible ? math.min(availableGain, desiredGain) : 0,
      scaledLedgerHeaderTopInset: inset,
      scaledLedgerCountHeight: count,
      scaledCountToSearchGap: gap,
      scaledMinimumCountToNavClearance: minimumCountToNavClearance,
    );
  }
}

@immutable
final class DashboardShellPresentationSettings {
  const DashboardShellPresentationSettings({
    this.bottomNavEdgeShape = DashboardBottomNavEdgeShape.rounded,
    this.bottomNavTopBorder = DashboardBottomNavTopBorder.off,
    this.bottomNavLayoutStyle = DashboardBottomNavLayoutStyle.raisedFab,
    this.flatBottomNavBodyStretch = DashboardFlatBottomNavBodyStretch.off,
  });

  static const defaults = DashboardShellPresentationSettings();

  final DashboardBottomNavEdgeShape bottomNavEdgeShape;
  final DashboardBottomNavTopBorder bottomNavTopBorder;
  final DashboardBottomNavLayoutStyle bottomNavLayoutStyle;
  final DashboardFlatBottomNavBodyStretch flatBottomNavBodyStretch;

  DashboardShellPresentationSettings copyWith({
    DashboardBottomNavEdgeShape? bottomNavEdgeShape,
    DashboardBottomNavTopBorder? bottomNavTopBorder,
    DashboardBottomNavLayoutStyle? bottomNavLayoutStyle,
    DashboardFlatBottomNavBodyStretch? flatBottomNavBodyStretch,
  }) => DashboardShellPresentationSettings(
    bottomNavEdgeShape: bottomNavEdgeShape ?? this.bottomNavEdgeShape,
    bottomNavTopBorder: bottomNavTopBorder ?? this.bottomNavTopBorder,
    bottomNavLayoutStyle: bottomNavLayoutStyle ?? this.bottomNavLayoutStyle,
    flatBottomNavBodyStretch:
        flatBottomNavBodyStretch ?? this.flatBottomNavBodyStretch,
  );

  @override
  bool operator ==(Object other) =>
      other is DashboardShellPresentationSettings &&
      other.bottomNavEdgeShape == bottomNavEdgeShape &&
      other.bottomNavTopBorder == bottomNavTopBorder &&
      other.bottomNavLayoutStyle == bottomNavLayoutStyle &&
      other.flatBottomNavBodyStretch == flatBottomNavBodyStretch;

  @override
  int get hashCode => Object.hash(
    bottomNavEdgeShape,
    bottomNavTopBorder,
    bottomNavLayoutStyle,
    flatBottomNavBodyStretch,
  );
}

final class DashboardShellPresentationController
    extends ValueNotifier<DashboardShellPresentationSettings> {
  DashboardShellPresentationController()
    : super(DashboardShellPresentationSettings.defaults);

  void selectBottomNavEdgeShape(DashboardBottomNavEdgeShape shape) {
    final next = value.copyWith(bottomNavEdgeShape: shape);
    if (next != value) value = next;
  }

  void selectBottomNavTopBorder(DashboardBottomNavTopBorder border) {
    final next = value.copyWith(bottomNavTopBorder: border);
    if (next != value) value = next;
  }

  void selectBottomNavLayoutStyle(DashboardBottomNavLayoutStyle style) {
    final next = value.copyWith(bottomNavLayoutStyle: style);
    if (next != value) value = next;
  }

  void selectFlatBottomNavBodyStretch(
    DashboardFlatBottomNavBodyStretch stretch,
  ) {
    final next = value.copyWith(flatBottomNavBodyStretch: stretch);
    if (next != value) value = next;
  }

  void reset() => value = DashboardShellPresentationSettings.defaults;
}
