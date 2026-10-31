import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../application/dashboard_presentation_preferences.dart';
import '../../query/domain/ghost_filter_mode.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_segmented_target_acceptance.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../summary_pill_variant.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../dashboard_summary_presentation.dart';
import '../dashboard_summary_auto_reset_controller.dart';
import 'dashboard_summary_pill.dart';
import 'dashboard_temporal_component_carousel.dart';
import 'dashboard_ghost_quick_filter.dart';

typedef SummaryPillComponentCandidateProjector =
    DashboardNavigationState? Function({
      required DashboardNavigationState base,
      required TimePlane plane,
      required bool isRailOpen,
      required DashboardTemporalAnchorComponent component,
      required int offset,
    });

/// Stable authored content requirements for the segmented Summary.
///
/// This measurement runs once, not in a carousel item builder, so a fling
/// cannot introduce `TextPainter` work in the rendering hot path. The widest
/// localized month label is reserved before the first layout.
@immutable
final class SummarySegmentedContentMetrics {
  const SummarySegmentedContentMetrics._({
    required this.modeVisualSize,
    required this.yearWidth,
    required this.monthWidth,
    required this.dayWidth,
  });

  static final SummarySegmentedContentMetrics authored =
      SummarySegmentedContentMetrics._(
        modeVisualSize: DashboardLogBoxTokens.avatarSize,
        yearWidth: _textWidth('2026'),
        monthWidth: List<double>.generate(
          12,
          (index) => _textWidth(_monthLabelFor(index + 1)),
        ).reduce(math.max),
        dayWidth: _textWidth('31'),
      );

  /// The pre-regression product used the compact 25px mode badge. It is
  /// evidence only: the final product always renders [authored]'s large badge.
  /// Keeping this separate makes the requested half-gap compare actual old
  /// content bounds instead of accidentally measuring the new large icon.
  static final SummarySegmentedContentMetrics preRegression =
      SummarySegmentedContentMetrics._(
        modeVisualSize: 25,
        yearWidth: _textWidth('2026'),
        monthWidth: List<double>.generate(
          12,
          (index) => _textWidth(_monthLabelFor(index + 1)),
        ).reduce(math.max),
        dayWidth: _textWidth('31'),
      );

  final double modeVisualSize;
  final double yearWidth;
  final double monthWidth;
  final double dayWidth;

  double widthForTrack(int track) => switch (track) {
    0 => modeVisualSize,
    1 => yearWidth,
    2 => monthWidth,
    3 => dayWidth,
    _ => throw ArgumentError.value(track, 'track', 'Unknown Summary track.'),
  };

  static double _textWidth(String value) {
    final painter = TextPainter(
      text: TextSpan(
        text: value,
        style: FluviVisualTokens.summaryTitleTextStyle,
      ),
      textDirection: TextDirection.ltr,
      maxLines: 1,
    )..layout();
    // Two safety pixels retain anti-aliased glyph edges inside their owner
    // Rect without changing authored typography.
    return painter.width.ceilToDouble() + 2;
  }

  static String _monthLabelFor(int month) =>
      DashboardTimeLabelFormatter.monthName(
        month,
      ).substring(0, 3).toUpperCase();
}

/// Geometry authority for each active segmented Summary component.
///
/// The authored visual Rect remains glyph/content-sized. Its interaction and
/// semantics cell is derived from neighbouring selector midpoints and the
/// navigation-zone edges, so a user can start a swipe anywhere in the visibly
/// attributable selector cell without allowing one selector to overlap another
/// or consume the amount zone. The background owns the amount zone and any
/// Summary surface outside the navigation zone.
@immutable
final class SummarySegmentedTrackGeometry {
  const SummarySegmentedTrackGeometry._({
    required this.width,
    required this.height,
    required this.activeTrackIndices,
    required this.contentMetrics,
    required this.preRegressionContentEdgeGap,
    required this.segmentedSectionGap,
    required this.orientation,
    required Map<int, Rect> sectionRects,
  }) : _sectionRects = sectionRects;

  /// The old unshifted four-track layout is the comparison baseline. Its mode
  /// and year content bounds yield one concrete empty content-edge distance.
  static double preRegressionContentEdgeGapFor({
    required double preRegressionNavigationWidth,
    SummarySegmentedContentMetrics? contentMetrics,
  }) {
    final metrics =
        contentMetrics ?? SummarySegmentedContentMetrics.preRegression;
    return preRegressionNavigationWidth / 4 -
        (metrics.modeVisualSize + metrics.yearWidth) / 2;
  }

  /// Smallest navigation lane that can retain the authored selectors and the
  /// pre-regression half-gap rule. The surrounding Summary may give an amount
  /// slot its preferred 40% width only while this lower bound is satisfied.
  static double minimumWidthFor({
    required List<int> activeTrackIndices,
    required double preRegressionInset,
    double height = 59,
    SummarySegmentedContentMetrics? contentMetrics,
  }) {
    if (height <= 0 || preRegressionInset < 0 || activeTrackIndices.isEmpty) {
      throw ArgumentError(
        'Segmented track minimum width needs a positive height and tracks.',
      );
    }
    var previous = -1;
    for (final track in activeTrackIndices) {
      if (track < 0 || track > 3 || track <= previous) {
        throw ArgumentError('Active tracks must be ascending Summary tracks.');
      }
      previous = track;
    }
    final metrics = contentMetrics ?? SummarySegmentedContentMetrics.authored;
    final preRegression = SummarySegmentedContentMetrics.preRegression;
    final trackCount = activeTrackIndices.length;
    final contentWidth = activeTrackIndices.fold<double>(
      0,
      (sum, track) => sum + metrics.widthForTrack(track),
    );
    final modeInset = (height - metrics.modeVisualSize) / 2;
    final preRegressionPair =
        preRegression.modeVisualSize + preRegression.yearWidth;
    // `gap = (width - inset) / 8 - preRegressionPair / 4` and every
    // selector after the first consumes that gap. Solve the final selector's
    // right edge against the navigation lane directly instead of shrinking
    // any authored visual content.
    final gapCount = trackCount - 1;
    final widthForVisuals =
        (modeInset +
            contentWidth -
            gapCount * preRegressionInset / 8 -
            gapCount * preRegressionPair / 4) /
        (1 - gapCount / 8);
    final widthForNonnegativeBaselineGap =
        preRegressionInset + preRegressionPair * 2;
    return math.max(widthForVisuals, widthForNonnegativeBaselineGap).toDouble();
  }

  factory SummarySegmentedTrackGeometry.resolve({
    required double width,
    required List<int> activeTrackIndices,
    double height = 59,
    SummarySegmentedContentMetrics? contentMetrics,
    double? preRegressionNavigationWidth,
    SummarySegmentedOrientation orientation =
        SummarySegmentedOrientation.normal,
  }) {
    if (width <= 0 || height <= 0 || activeTrackIndices.isEmpty) {
      throw ArgumentError(
        'Segmented track geometry needs active positive width and height.',
      );
    }
    var previous = -1;
    for (final track in activeTrackIndices) {
      if (track < 0 || track > 3 || track <= previous) {
        throw ArgumentError('Active tracks must be ascending Summary tracks.');
      }
      previous = track;
    }
    final metrics = contentMetrics ?? SummarySegmentedContentMetrics.authored;
    final baselineWidth = preRegressionNavigationWidth ?? width;
    final baselineGap = preRegressionContentEdgeGapFor(
      preRegressionNavigationWidth: baselineWidth,
    );
    if (baselineGap < 0) {
      throw ArgumentError.value(
        width,
        'width',
        'Segmented Summary cannot fit its authored content.',
      );
    }
    final gap = baselineGap / 2;
    final sectionRects = <int, Rect>{};
    // The large mode component itself—not an old padded lane—uses its top
    // inset on the outer normal/mirrored edge. Every item receives the one
    // Rect later used for its paint, clip, semantics and gesture surface.
    final modeInset = (height - metrics.modeVisualSize) / 2;
    var nextEdge = switch (orientation) {
      SummarySegmentedOrientation.normal => modeInset,
      SummarySegmentedOrientation.mirrored => width - modeInset,
    };
    for (final track in activeTrackIndices) {
      final contentWidth = metrics.widthForTrack(track);
      sectionRects[track] = switch (orientation) {
        SummarySegmentedOrientation.normal => Rect.fromLTWH(
          nextEdge,
          0,
          contentWidth,
          height,
        ),
        SummarySegmentedOrientation.mirrored => Rect.fromLTWH(
          nextEdge - contentWidth,
          0,
          contentWidth,
          height,
        ),
      };
      nextEdge += switch (orientation) {
        SummarySegmentedOrientation.normal => contentWidth + gap,
        SummarySegmentedOrientation.mirrored => -(contentWidth + gap),
      };
    }
    final exceedsBounds = sectionRects.values.any(
      (rect) => rect.left < 0 || rect.right > width,
    );
    final overlaps = activeTrackIndices.indexed.any(
      (entry) =>
          entry.$1 > 0 &&
          sectionRects[activeTrackIndices[entry.$1 - 1]]!.overlaps(
            sectionRects[entry.$2]!,
          ),
    );
    if (exceedsBounds || overlaps) {
      throw ArgumentError.value(
        width,
        'width',
        'Segmented Summary cannot fit active authored sections.',
      );
    }
    return SummarySegmentedTrackGeometry._(
      width: width,
      height: height,
      activeTrackIndices: List<int>.unmodifiable(activeTrackIndices),
      contentMetrics: metrics,
      preRegressionContentEdgeGap: baselineGap,
      segmentedSectionGap: gap,
      orientation: orientation,
      sectionRects: Map<int, Rect>.unmodifiable(sectionRects),
    );
  }

  final double width;
  final double height;
  final List<int> activeTrackIndices;
  final SummarySegmentedContentMetrics contentMetrics;
  final double preRegressionContentEdgeGap;
  final double segmentedSectionGap;
  final SummarySegmentedOrientation orientation;
  final Map<int, Rect> _sectionRects;

  /// The accessibility cell deliberately follows the usable interaction cell,
  /// not the narrower authored glyph/content Rect.
  Rect semanticRectForTrack(int track) => interactionCellRectForTrack(track);

  double semanticCenterForTrack(int track) =>
      interactionCellRectForTrack(track).center.dx;

  /// The bounded, non-overlapping pointer owner for this selector. Adjacent
  /// cells meet exactly at their visual separator midpoint. Outer cells reach
  /// the navigation-zone edge, never the adjacent amount zone, so there is no
  /// glyph-sized dead strip inside a visible first/last selector section.
  Rect interactionCellRectForTrack(int track) {
    final visual = _rectForTrack(track);
    final spatialTracks = activeTrackIndices.toList(growable: false)
      ..sort(
        (left, right) =>
            _rectForTrack(left).left.compareTo(_rectForTrack(right).left),
      );
    final spatialIndex = spatialTracks.indexOf(track);
    assert(spatialIndex >= 0);
    final previous = spatialIndex == 0
        ? null
        : _rectForTrack(spatialTracks[spatialIndex - 1]);
    final next = spatialIndex == spatialTracks.length - 1
        ? null
        : _rectForTrack(spatialTracks[spatialIndex + 1]);
    return Rect.fromLTRB(
      previous == null ? 0 : (previous.right + visual.left) / 2,
      0,
      next == null ? width : (visual.right + next.left) / 2,
      height,
    );
  }

  /// The painted selector remains at the exact authored content Rect.
  double visualCenterForTrack(int track) =>
      visualContentRectForTrack(track).center.dx;

  /// This stays deliberately separate from interaction and semantics cells.
  /// It is the visual placement contract, not a glyph-sized touch target.
  Rect visualContentRectForTrack(int track) => _rectForTrack(track);

  double separatorCenterAfterTrack(int leadingTrack) {
    final leadingIndex = activeTrackIndices.indexOf(leadingTrack);
    if (leadingIndex < 0 || leadingIndex == activeTrackIndices.length - 1) {
      throw ArgumentError.value(
        leadingTrack,
        'leadingTrack',
        'A separator needs a following active track.',
      );
    }
    final leading = visualContentRectForTrack(leadingTrack);
    final following = visualContentRectForTrack(
      activeTrackIndices[leadingIndex + 1],
    );
    return (leading.right + following.left) / 2;
  }

  Rect _rectForTrack(int track) {
    final rect = _sectionRects[track];
    if (rect == null) {
      throw ArgumentError.value(track, 'track', 'Track is not active.');
    }
    return rect;
  }
}

/// One passive, bounded raw-pointer classification from the segmented Summary
/// surface. It has no recognizer or motion authority: selector and background
/// gestures retain their existing owners. The record lets a physical trace
/// distinguish an interaction-cell miss from a later arena/lifecycle failure.
@immutable
final class SummarySegmentedPointerHit {
  const SummarySegmentedPointerHit({
    required this.pointerId,
    required this.globalPosition,
    required this.localPosition,
    required this.level,
    required this.selectorTrack,
    required this.trackRects,
  });

  final int pointerId;
  final Offset globalPosition;
  final Offset localPosition;
  final SummaryPillExperimentLevel level;

  /// Null when the raw point belongs to genuine Summary background.
  final int? selectorTrack;

  /// Summary-local visual, interaction and semantics authorities for every
  /// active selector at this pointer boundary.
  final Map<int, SummarySegmentedTrackRects> trackRects;
}

@immutable
final class SummarySegmentedTrackRects {
  const SummarySegmentedTrackRects({
    required this.visualContent,
    required this.interactionCell,
    required this.semantics,
  });

  final Rect visualContent;
  final Rect interactionCell;
  final Rect semantics;
}

/// Fixed-height presentation experiments over the existing dashboard time
/// state. They intentionally contain no query or temporal state of their own.
final class SummaryPillExperiment extends StatelessWidget {
  const SummaryPillExperiment({
    super.key,
    required this.variant,
    required this.bounds,
    required this.navigation,
    required this.visibleFrames,
    required this.onLevelCrossed,
    required this.onComponentCrossed,
    this.onComponentCrossingAccepted,
    this.componentPaintedTarget,
    this.onComponentVisualTargetPainted,
    this.onComponentSettled,
    this.motionDiagnostics,
    this.componentCandidateProjector,
    this.performanceCounters,
    this.onAmountMotionActiveChanged,
    this.onSelectorMotionActiveChanged,
    this.onSelectorDirectInputStarted,
    this.onSelectorPointerDownDecision,
    this.onPointerHitClassified,
    this.onBackgroundTap,
    this.onBackgroundVerticalDragStart,
    this.onBackgroundVerticalDragUpdate,
    this.onBackgroundVerticalDragEnd,
    this.autoResetMotionRegistry,
    this.temporalCarouselCoordinator,
    this.presentation = const DashboardSummaryPresentationSettings.defaults(),
    this.ghostPresentation = DashboardGhostQuickFilterPresentation.current,
    this.ghostMode = GhostFilterMode.both,
    this.onGhostModeSelected,
  }) : assert(variant == SummaryPillVariant.segmented);

  final SummaryPillVariant variant;
  final DashboardBounds bounds;
  final DashboardNavigationController navigation;
  final DashboardVisibleFrameStore visibleFrames;
  final void Function(TimePlane plane, bool isRailOpen) onLevelCrossed;
  final void Function(
    DashboardNavigationState candidate,
    DashboardTemporalAnchorComponent component,
  )
  onComponentCrossed;

  /// The production coordinator returns this synchronously after it has
  /// selected one complete prepared frame for the candidate.  The legacy
  /// notification remains for narrow presentation-only consumers, but it is
  /// never enough to make a target own settlement.
  final DashboardSegmentedTargetAcceptance Function(
    DashboardNavigationState candidate,
    DashboardTemporalAnchorComponent component,
  )?
  onComponentCrossingAccepted;

  /// Production-only post-paint acknowledgement for a previously accepted
  /// component target. It enriches rich-scene diagnostics only; exact Phase-A
  /// acceptance remains the semantic settlement authority.
  final ValueListenable<DashboardSegmentedTargetPainted?>?
  componentPaintedTarget;

  /// Frame-local renderer acknowledgement for one exact component target.
  /// It contains no state mutation: the renderer only reports that the
  /// accepted label has crossed the Flutter render boundary. The application
  /// coordinator owns every derived publication that follows.
  final void Function(
    DashboardNavigationState candidate,
    DashboardTemporalAnchorComponent component,
  )?
  onComponentVisualTargetPainted;
  final void Function(
    DashboardNavigationState candidate,
    DashboardTemporalAnchorComponent component,
  )?
  onComponentSettled;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onAmountMotionActiveChanged;
  final ValueChanged<bool>? onSelectorMotionActiveChanged;
  final VoidCallback? onSelectorDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onSelectorPointerDownDecision;
  final ValueChanged<SummarySegmentedPointerHit>? onPointerHitClassified;
  final VoidCallback? onBackgroundTap;
  final GestureDragStartCallback? onBackgroundVerticalDragStart;
  final GestureDragUpdateCallback? onBackgroundVerticalDragUpdate;
  final GestureDragEndCallback? onBackgroundVerticalDragEnd;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final DashboardTemporalCarouselCoordinator? temporalCarouselCoordinator;
  final DashboardSummaryPresentationSettings presentation;
  final DashboardGhostQuickFilterPresentation ghostPresentation;
  final GhostFilterMode ghostMode;
  final Future<bool> Function(GhostFilterMode mode)? onGhostModeSelected;

  @override
  Widget build(BuildContext context) => _SegmentedMotionGateHost(
    onMotionActiveChanged: onSelectorMotionActiveChanged,
    builder: (context, motionGate) => ListenableBuilder(
      listenable: Listenable.merge(<Listenable>[
        navigation,
        visibleFrames.navigationLane,
      ]),
      builder: (context, _) {
        performanceCounters?.increment(
          DashboardPerformanceMetric.summaryPillBuild,
        );
        final level = SummaryPillExperimentLevel.fromNavigation(navigation);
        final depth = DashboardShadowStyleScope.profileOf(
          context,
        ).depthFor(DashboardCornerSurfaceFamily.summaryPill);
        final borderRadius = DashboardCornerRoundnessScope.profileOf(context)
            .borderRadiusFor(
              DashboardCornerSurfaceFamily.summaryPill,
              size: Size(bounds.width, bounds.height),
            );
        final content = LayoutBuilder(
          builder: (context, constraints) {
            final hasSummaryGhost =
                ghostPresentation ==
                    DashboardGhostQuickFilterPresentation
                        .summaryPillLeadingFling ||
                ghostPresentation ==
                    DashboardGhostQuickFilterPresentation
                        .summaryPillTrailingFling;
            final ghostLeading =
                ghostPresentation ==
                DashboardGhostQuickFilterPresentation.summaryPillLeadingFling;
            // Summary ghost positions have a documented physical ordering.
            // Keep the user's normal/mirrored choice stored unchanged, but
            // use the amount-first geometry locally while either cell is on.
            final effectivePresentation = hasSummaryGhost
                ? presentation.copyWith(
                    segmentedOrientation: SummarySegmentedOrientation.mirrored,
                  )
                : presentation;
            const ghostCellWidth = 48.0;
            final contentWidth = math.max(
              0.0,
              constraints.maxWidth - (hasSummaryGhost ? ghostCellWidth : 0),
            );
            final inset = bounds.width <= 320
                ? 6.0
                : FluviVisualTokens.controlHorizontalInset;
            final activeTracks = <int>[
              0,
              if (level != SummaryPillExperimentLevel.sum) 1,
              if (level == SummaryPillExperimentLevel.month ||
                  level == SummaryPillExperimentLevel.day)
                2,
              if (level == SummaryPillExperimentLevel.day) 3,
            ];
            // Keep the pre-existing prepared-amount 40% preference unless it
            // would steal an authored selector's required visual/semantic
            // lane. This is a narrow-host redistribution only: neither the
            // selectors nor the normal-width amount envelope are resized.
            final minimumNavigationWidth =
                SummarySegmentedTrackGeometry.minimumWidthFor(
                  activeTrackIndices: activeTracks,
                  height: bounds.height,
                  preRegressionInset: inset,
                );
            final preferredAmountWidth = contentWidth * .40;
            final maximumAmountWidth = math
                .max(0, contentWidth - inset - minimumNavigationWidth)
                .toDouble();
            final amountWidth = math
                .min(preferredAmountWidth, maximumAmountWidth)
                .toDouble();
            // This is the original quarter-track navigation footprint. It is
            // retained only as the measured pre-regression content-edge baseline
            // for the requested 50% gap—not as a visual or gesture lane.
            final preRegressionNavigationWidth =
                contentWidth - amountWidth - inset * 2;
            // Normal preserves the existing right-side amount zone; mirrored
            // swaps the two whole zones. In either orientation, navigation's
            // outer edge is the mode badge's equal horizontal/vertical inset.
            final navigationWidth = contentWidth - amountWidth - inset;
            final selectorGeometry = SummarySegmentedTrackGeometry.resolve(
              width: navigationWidth,
              height: bounds.height,
              activeTrackIndices: activeTracks,
              preRegressionNavigationWidth: preRegressionNavigationWidth,
              orientation: effectivePresentation.segmentedOrientation,
            );
            final contentOffset = hasSummaryGhost && ghostLeading
                ? ghostCellWidth
                : 0.0;
            final navigationLeft =
                contentOffset +
                (effectivePresentation.segmentedOrientation ==
                        SummarySegmentedOrientation.normal
                    ? 0.0
                    : inset + amountWidth);
            final ghostRect = hasSummaryGhost
                ? Rect.fromLTWH(
                    ghostLeading ? 0 : contentWidth,
                    0,
                    ghostCellWidth,
                    bounds.height,
                  )
                : null;
            bool isSelectorPosition(Offset localPosition) =>
                activeTracks.any(
                  (track) => selectorGeometry
                      .interactionCellRectForTrack(track)
                      .shift(Offset(navigationLeft, 0))
                      .contains(localPosition),
                ) ||
                (ghostRect?.contains(localPosition) ?? false);
            void classifyPointer(PointerDownEvent event) {
              final trackRects = <int, SummarySegmentedTrackRects>{
                for (final track in activeTracks)
                  track: SummarySegmentedTrackRects(
                    visualContent: selectorGeometry
                        .visualContentRectForTrack(track)
                        .shift(Offset(navigationLeft, 0)),
                    interactionCell: selectorGeometry
                        .interactionCellRectForTrack(track)
                        .shift(Offset(navigationLeft, 0)),
                    semantics: selectorGeometry
                        .semanticRectForTrack(track)
                        .shift(Offset(navigationLeft, 0)),
                  ),
              };
              final selectorTrack = activeTracks.cast<int?>().firstWhere(
                (track) => trackRects[track]!.interactionCell.contains(
                  event.localPosition,
                ),
                orElse: () => null,
              );
              onPointerHitClassified?.call(
                SummarySegmentedPointerHit(
                  pointerId: event.pointer,
                  globalPosition: event.position,
                  localPosition: event.localPosition,
                  level: level,
                  selectorTrack: selectorTrack,
                  trackRects: Map<int, SummarySegmentedTrackRects>.unmodifiable(
                    trackRects,
                  ),
                ),
              );
            }

            final navigationSurface = SizedBox(
              width: navigationWidth,
              height: bounds.height,
              child: _SegmentedNavigationSurface(
                level: level,
                height: bounds.height,
                width: navigationWidth,
                preRegressionNavigationWidth: preRegressionNavigationWidth,
                navigation: navigation,
                presentation: effectivePresentation,
                onLevelCrossed: onLevelCrossed,
                onComponentCrossed: onComponentCrossed,
                onComponentCrossingAccepted: onComponentCrossingAccepted,
                componentPaintedTarget: componentPaintedTarget,
                onComponentVisualTargetPainted: onComponentVisualTargetPainted,
                onComponentSettled: onComponentSettled,
                motionDiagnostics: motionDiagnostics,
                componentCandidateProjector: componentCandidateProjector,
                motionGate: motionGate,
                onSelectorDirectInputStarted: onSelectorDirectInputStarted,
                onSelectorPointerDownDecision: onSelectorPointerDownDecision,
                autoResetMotionRegistry: autoResetMotionRegistry,
                temporalCarouselCoordinator: temporalCarouselCoordinator,
              ),
            );
            final amountZone = SizedBox(
              key: const ValueKey<String>(
                'summary-pill-experiment-amount-zone',
              ),
              width: amountWidth,
              height: bounds.height,
              child: Align(
                alignment:
                    effectivePresentation.segmentedOrientation ==
                        SummarySegmentedOrientation.normal
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: SummaryPillPreparedAmountSlot(
                  visibleFrames: visibleFrames,
                  performanceCounters: performanceCounters,
                  onMotionActiveChanged: onAmountMotionActiveChanged,
                  slotWidth: amountWidth,
                  alignment:
                      effectivePresentation.segmentedOrientation ==
                          SummarySegmentedOrientation.normal
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                ),
              ),
            );
            final contentSections =
                switch (effectivePresentation.segmentedOrientation) {
                  SummarySegmentedOrientation.normal => Row(
                    children: <Widget>[
                      navigationSurface,
                      amountZone,
                      SizedBox(width: inset),
                    ],
                  ),
                  SummarySegmentedOrientation.mirrored => Row(
                    children: <Widget>[
                      SizedBox(width: inset),
                      amountZone,
                      navigationSurface,
                    ],
                  ),
                };
            final ghostSelector = hasSummaryGhost
                ? SizedBox(
                    width: ghostCellWidth,
                    height: bounds.height,
                    child: DashboardGhostFlingSelector(
                      mode: ghostMode,
                      onModeSelected: onGhostModeSelected ?? (_) async => false,
                      semanticsKey: ValueKey<String>(
                        'dashboard-ghost-summary-${ghostLeading ? 'leading' : 'trailing'}-semantics',
                      ),
                      viewportKey: ValueKey<String>(
                        'dashboard-ghost-summary-${ghostLeading ? 'leading' : 'trailing'}-viewport',
                      ),
                      iconKeyPrefix:
                          'dashboard-ghost-summary-${ghostLeading ? 'leading' : 'trailing'}-icon',
                    ),
                  )
                : null;
            final sections = hasSummaryGhost
                ? Row(
                    children: <Widget>[
                      if (ghostLeading) ghostSelector!,
                      SizedBox(width: contentWidth, child: contentSections),
                      if (!ghostLeading) ghostSelector!,
                    ],
                  )
                : contentSections;
            // Selector sections are above this surface in the hit-test tree, so
            // temporal flings retain exact Rect ownership. The exposed surface
            // is the only Summary region that can tap-reset or drag Header.
            return Listener(
              // This listener is deliberately passive. The opaque background
              // already guarantees a child hit for every Summary point, so
              // defer-to-child records the real route without enlarging a hit
              // target or adding a competing gesture recognizer.
              onPointerDown: classifyPointer,
              child: Stack(
                fit: StackFit.expand,
                children: <Widget>[
                  Positioned(
                    left: hasSummaryGhost && ghostLeading ? ghostCellWidth : 0,
                    right: hasSummaryGhost && !ghostLeading
                        ? ghostCellWidth
                        : 0,
                    top: 0,
                    bottom: 0,
                    child: GestureDetector(
                      key: const ValueKey<String>(
                        'summary-pill-background-gesture',
                      ),
                      behavior: HitTestBehavior.opaque,
                      onTapUp: (details) {
                        if (!isSelectorPosition(
                          details.localPosition +
                              Offset(
                                hasSummaryGhost && ghostLeading
                                    ? ghostCellWidth
                                    : 0,
                                0,
                              ),
                        )) {
                          onBackgroundTap?.call();
                        }
                      },
                      onVerticalDragStart: onBackgroundVerticalDragStart,
                      onVerticalDragUpdate: onBackgroundVerticalDragUpdate,
                      onVerticalDragEnd: onBackgroundVerticalDragEnd,
                    ),
                  ),
                  sections,
                ],
              ),
            );
          },
        );
        return SizedBox(
          key: ValueKey<String>('summary-pill-experiment-${variant.name}'),
          width: bounds.width,
          height: bounds.height,
          child: FluviRoundedBox(
            color: depth.surfaceColor ?? FluviVisualTokens.surface,
            border: DashboardBorderScope.profileOf(
              context,
            ).borderFor(DashboardBorderSurface.summary),
            borderRadius: borderRadius,
            boxShadow: depth.shadows,
            child:
                presentation.temporalFlingPresentation ==
                    SummaryTemporalFlingPresentation.dynamicTrio
                ? ClipRRect(borderRadius: borderRadius, child: content)
                : content,
          ),
        );
      },
    ),
  );
}

/// Owns the one presentation-side motion handoff for the complete segmented
/// adapter. Individual hierarchy tracks can appear and disappear as the mode
/// selector crosses a level, so their local idle/dispose callbacks cannot be
/// treated as global Summary-idle events.
final class _SegmentedMotionGateHost extends StatefulWidget {
  const _SegmentedMotionGateHost({
    required this.onMotionActiveChanged,
    required this.builder,
  });

  final ValueChanged<bool>? onMotionActiveChanged;
  final Widget Function(BuildContext context, _SegmentedMotionGate gate)
  builder;

  @override
  State<_SegmentedMotionGateHost> createState() =>
      _SegmentedMotionGateHostState();
}

final class _SegmentedMotionGateHostState
    extends State<_SegmentedMotionGateHost> {
  late final _SegmentedMotionGate _gate = _SegmentedMotionGate(
    widget.onMotionActiveChanged,
  );

  @override
  void didUpdateWidget(covariant _SegmentedMotionGateHost oldWidget) {
    super.didUpdateWidget(oldWidget);
    _gate.updateCallback(widget.onMotionActiveChanged);
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _gate);

  @override
  void dispose() {
    // The host, not a conditionally removed child selector, is the exact
    // segmented-variant unmount boundary.
    _gate.releaseForAdapterUnmount();
    super.dispose();
  }
}

enum _SegmentedMotionOwner { mode, year, month, day }

/// Serializes local selector callbacks into the existing single Summary lane.
///
/// It has no navigation, query, frame, or animation authority. Its only job
/// is to prevent a disposed non-owner (for example Month after a Mode
/// crossing) from ending a direct drag still owned by another selector.
final class _SegmentedMotionGate {
  _SegmentedMotionGate(this._onMotionActiveChanged);

  ValueChanged<bool>? _onMotionActiveChanged;
  _SegmentedMotionOwner? _activeOwner;

  void updateCallback(ValueChanged<bool>? callback) {
    _onMotionActiveChanged = callback;
  }

  ValueChanged<bool> callbackFor(_SegmentedMotionOwner owner) => (active) {
    if (active) {
      if (_activeOwner == owner) return;
      _activeOwner = owner;
      _onMotionActiveChanged?.call(true);
      return;
    }
    if (_activeOwner != owner) return;
    _activeOwner = null;
    _onMotionActiveChanged?.call(false);
  };

  void releaseForAdapterUnmount() {
    if (_activeOwner == null) return;
    _activeOwner = null;
    _onMotionActiveChanged?.call(false);
  }
}

enum SummaryPillExperimentLevel {
  sum,
  year,
  month,
  day;

  static SummaryPillExperimentLevel fromNavigation(
    DashboardNavigationController navigation,
  ) {
    final state = navigation.state;
    if (state.plane == TimePlane.month && state.isRailOpen) {
      return SummaryPillExperimentLevel.day;
    }
    return switch (state.plane) {
      TimePlane.sum => SummaryPillExperimentLevel.sum,
      TimePlane.year => SummaryPillExperimentLevel.year,
      TimePlane.month => SummaryPillExperimentLevel.month,
    };
  }
}

extension SummaryPillExperimentLevelProjection on SummaryPillExperimentLevel {
  TimePlane get plane => switch (this) {
    SummaryPillExperimentLevel.sum => TimePlane.sum,
    SummaryPillExperimentLevel.year => TimePlane.year,
    SummaryPillExperimentLevel.month ||
    SummaryPillExperimentLevel.day => TimePlane.month,
  };

  bool get isRailOpen => this == SummaryPillExperimentLevel.day;

  String get semanticsLabel => switch (this) {
    SummaryPillExperimentLevel.sum => 'Összesen',
    SummaryPillExperimentLevel.year => 'Éves',
    SummaryPillExperimentLevel.month => 'Havi',
    SummaryPillExperimentLevel.day => 'Napi',
  };

  IconData get icon => switch (this) {
    SummaryPillExperimentLevel.sum => Icons.all_inclusive_rounded,
    SummaryPillExperimentLevel.year => Icons.calendar_today_rounded,
    SummaryPillExperimentLevel.month => Icons.calendar_month_rounded,
    SummaryPillExperimentLevel.day => Icons.today_rounded,
  };
}

typedef _LevelCrossed = void Function(TimePlane plane, bool isRailOpen);
typedef _ComponentCrossed =
    void Function(
      DashboardNavigationState candidate,
      DashboardTemporalAnchorComponent component,
    );
typedef _ComponentCrossingAccepted =
    DashboardSegmentedTargetAcceptance Function(
      DashboardNavigationState candidate,
      DashboardTemporalAnchorComponent component,
    );

final class _SegmentedNavigationSurface extends StatelessWidget {
  const _SegmentedNavigationSurface({
    required this.level,
    required this.height,
    required this.width,
    required this.preRegressionNavigationWidth,
    required this.navigation,
    required this.presentation,
    required this.onLevelCrossed,
    required this.onComponentCrossed,
    this.onComponentCrossingAccepted,
    this.componentPaintedTarget,
    this.onComponentVisualTargetPainted,
    this.onComponentSettled,
    this.motionDiagnostics,
    this.componentCandidateProjector,
    required this.motionGate,
    this.onSelectorDirectInputStarted,
    this.onSelectorPointerDownDecision,
    this.autoResetMotionRegistry,
    this.temporalCarouselCoordinator,
  });

  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final double preRegressionNavigationWidth;
  final DashboardNavigationController navigation;
  final DashboardSummaryPresentationSettings presentation;
  final _LevelCrossed onLevelCrossed;
  final _ComponentCrossed onComponentCrossed;
  final _ComponentCrossingAccepted? onComponentCrossingAccepted;
  final ValueListenable<DashboardSegmentedTargetPainted?>?
  componentPaintedTarget;
  final _ComponentCrossed? onComponentVisualTargetPainted;
  final _ComponentCrossed? onComponentSettled;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final _SegmentedMotionGate motionGate;
  final VoidCallback? onSelectorDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onSelectorPointerDownDecision;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final DashboardTemporalCarouselCoordinator? temporalCarouselCoordinator;

  @override
  Widget build(BuildContext context) => _FixedHierarchyTracks(
    keyPrefix: 'segmented',
    level: level,
    height: height,
    width: width,
    preRegressionNavigationWidth: preRegressionNavigationWidth,
    navigation: navigation,
    presentation: presentation,
    trackCount: 4,
    modeTrack: 0,
    yearTrack: 1,
    monthTrack: 2,
    dayTrack: 3,
    modeSelector: (visualContentOffset) => _ModeSelector(
      key: const ValueKey<String>('summary-pill-segmented-mode-selector'),
      height: height,
      level: level,
      visualContentOffset: visualContentOffset,
      onCrossed: onLevelCrossed,
      onMotionActiveChanged: motionGate.callbackFor(_SegmentedMotionOwner.mode),
      onDirectInputStarted: onSelectorDirectInputStarted,
      onPointerDownDecision: onSelectorPointerDownDecision,
      autoResetMotionRegistry: autoResetMotionRegistry,
      temporalCarouselCoordinator: temporalCarouselCoordinator,
      motionDiagnostics: motionDiagnostics,
    ),
    onComponentCrossed: onComponentCrossed,
    onComponentCrossingAccepted: onComponentCrossingAccepted,
    componentPaintedTarget: componentPaintedTarget,
    onComponentVisualTargetPainted: onComponentVisualTargetPainted,
    onComponentSettled: onComponentSettled,
    motionDiagnostics: motionDiagnostics,
    componentCandidateProjector: componentCandidateProjector,
    motionGate: motionGate,
    onSelectorDirectInputStarted: onSelectorDirectInputStarted,
    onSelectorPointerDownDecision: onSelectorPointerDownDecision,
    autoResetMotionRegistry: autoResetMotionRegistry,
    temporalCarouselCoordinator: temporalCarouselCoordinator,
  );
}

final class _FixedHierarchyTracks extends StatelessWidget {
  const _FixedHierarchyTracks({
    required this.keyPrefix,
    required this.level,
    required this.height,
    required this.width,
    required this.preRegressionNavigationWidth,
    required this.navigation,
    required this.presentation,
    required this.trackCount,
    required this.modeTrack,
    required this.yearTrack,
    required this.monthTrack,
    required this.dayTrack,
    required this.modeSelector,
    required this.onComponentCrossed,
    this.onComponentCrossingAccepted,
    this.componentPaintedTarget,
    this.onComponentVisualTargetPainted,
    this.onComponentSettled,
    this.motionDiagnostics,
    this.componentCandidateProjector,
    required this.motionGate,
    this.onSelectorDirectInputStarted,
    this.onSelectorPointerDownDecision,
    this.autoResetMotionRegistry,
    this.temporalCarouselCoordinator,
  });

  final String keyPrefix;
  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final double preRegressionNavigationWidth;
  final DashboardNavigationController navigation;
  final DashboardSummaryPresentationSettings presentation;
  final int trackCount;
  final int modeTrack;
  final int yearTrack;
  final int monthTrack;
  final int dayTrack;
  final Widget Function(double visualContentOffset) modeSelector;
  final _ComponentCrossed onComponentCrossed;
  final _ComponentCrossingAccepted? onComponentCrossingAccepted;
  final ValueListenable<DashboardSegmentedTargetPainted?>?
  componentPaintedTarget;
  final _ComponentCrossed? onComponentVisualTargetPainted;
  final _ComponentCrossed? onComponentSettled;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final _SegmentedMotionGate motionGate;
  final VoidCallback? onSelectorDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onSelectorPointerDownDecision;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final DashboardTemporalCarouselCoordinator? temporalCarouselCoordinator;

  @override
  Widget build(BuildContext context) {
    assert(trackCount == 4);
    final activeTracks = <int>[
      modeTrack,
      if (level != SummaryPillExperimentLevel.sum) yearTrack,
      if (level == SummaryPillExperimentLevel.month ||
          level == SummaryPillExperimentLevel.day)
        monthTrack,
      if (level == SummaryPillExperimentLevel.day) dayTrack,
    ];
    final geometry = SummarySegmentedTrackGeometry.resolve(
      width: width,
      height: height,
      activeTrackIndices: activeTracks,
      preRegressionNavigationWidth: preRegressionNavigationWidth,
      orientation: presentation.segmentedOrientation,
    );
    double visualContentOffsetFor(int track) =>
        geometry.visualContentRectForTrack(track).center.dx -
        geometry.interactionCellRectForTrack(track).center.dx;
    return Stack(
      children: <Widget>[
        _track(
          geometry.interactionCellRectForTrack(modeTrack),
          modeSelector(visualContentOffsetFor(modeTrack)),
        ),
        if (presentation.showSeparators &&
            level != SummaryPillExperimentLevel.sum)
          _separator(
            geometry,
            afterTrack: modeTrack,
            boundaryKey: modeTrack + 1,
          ),
        if (level != SummaryPillExperimentLevel.sum)
          _track(
            geometry.interactionCellRectForTrack(yearTrack),
            DashboardTemporalComponentCarousel(
              key: ValueKey<String>('summary-pill-$keyPrefix-year-selector'),
              height: height,
              visualContentOffset: visualContentOffsetFor(yearTrack),
              navigation: navigation,
              semanticsLabel:
                  'Év: ${navigation.state.yearCursor}. Függőlegesen húzva módosítható.',
              candidateForOffset: (origin, offset) =>
                  componentCandidateProjector?.call(
                    base: origin,
                    plane: level.plane,
                    isRailOpen: level.isRailOpen,
                    component: DashboardTemporalAnchorComponent.year,
                    offset: offset,
                  ) ??
                  navigation.temporalComponentOffsetCandidate(
                    plane: level.plane,
                    isRailOpen: level.isRailOpen,
                    component: DashboardTemporalAnchorComponent.year,
                    offset: offset,
                    base: origin,
                  ),
              labelForCandidate: _yearCandidateLabel,
              onCrossed: (candidate) {
                onComponentCrossed(
                  candidate,
                  DashboardTemporalAnchorComponent.year,
                );
                return onComponentCrossingAccepted?.call(
                      candidate,
                      DashboardTemporalAnchorComponent.year,
                    ) ??
                    DashboardSegmentedTargetAcceptance.acceptedExact;
              },
              paintedTargets: componentPaintedTarget,
              onVisualTargetPainted: (candidate) =>
                  onComponentVisualTargetPainted?.call(
                    candidate,
                    DashboardTemporalAnchorComponent.year,
                  ),
              onSettled: (candidate) => onComponentSettled?.call(
                candidate,
                DashboardTemporalAnchorComponent.year,
              ),
              onMotionActiveChanged: motionGate.callbackFor(
                _SegmentedMotionOwner.year,
              ),
              onDirectInputStarted: onSelectorDirectInputStarted,
              onPointerDownDecision: onSelectorPointerDownDecision,
              motionDiagnostics: motionDiagnostics,
              presentation: presentation.temporalFlingPresentation,
              component: DashboardTemporalAnchorComponent.year,
              autoResetMotionRegistry: autoResetMotionRegistry,
              coordinator: temporalCarouselCoordinator,
            ),
          ),
        if ((level == SummaryPillExperimentLevel.month ||
                level == SummaryPillExperimentLevel.day) &&
            monthTrack > yearTrack &&
            presentation.showSeparators)
          _separator(geometry, afterTrack: yearTrack, boundaryKey: monthTrack),
        if (level == SummaryPillExperimentLevel.month ||
            level == SummaryPillExperimentLevel.day)
          _track(
            geometry.interactionCellRectForTrack(monthTrack),
            DashboardTemporalComponentCarousel(
              key: ValueKey<String>('summary-pill-$keyPrefix-month-selector'),
              height: height,
              visualContentOffset: visualContentOffsetFor(monthTrack),
              navigation: navigation,
              semanticsLabel:
                  'Hónap: ${DashboardTimeLabelFormatter.monthName(navigation.state.monthCursor.month)}. Függőlegesen húzva módosítható.',
              candidateForOffset: (origin, offset) =>
                  componentCandidateProjector?.call(
                    base: origin,
                    plane: level.plane,
                    isRailOpen: level.isRailOpen,
                    component: DashboardTemporalAnchorComponent.month,
                    offset: offset,
                  ) ??
                  navigation.temporalComponentOffsetCandidate(
                    plane: level.plane,
                    isRailOpen: level.isRailOpen,
                    component: DashboardTemporalAnchorComponent.month,
                    offset: offset,
                    base: origin,
                  ),
              labelForCandidate: _monthCandidateLabel,
              onCrossed: (candidate) {
                onComponentCrossed(
                  candidate,
                  DashboardTemporalAnchorComponent.month,
                );
                return onComponentCrossingAccepted?.call(
                      candidate,
                      DashboardTemporalAnchorComponent.month,
                    ) ??
                    DashboardSegmentedTargetAcceptance.acceptedExact;
              },
              paintedTargets: componentPaintedTarget,
              onVisualTargetPainted: (candidate) =>
                  onComponentVisualTargetPainted?.call(
                    candidate,
                    DashboardTemporalAnchorComponent.month,
                  ),
              onSettled: (candidate) => onComponentSettled?.call(
                candidate,
                DashboardTemporalAnchorComponent.month,
              ),
              onMotionActiveChanged: motionGate.callbackFor(
                _SegmentedMotionOwner.month,
              ),
              onDirectInputStarted: onSelectorDirectInputStarted,
              onPointerDownDecision: onSelectorPointerDownDecision,
              motionDiagnostics: motionDiagnostics,
              presentation: presentation.temporalFlingPresentation,
              component: DashboardTemporalAnchorComponent.month,
              autoResetMotionRegistry: autoResetMotionRegistry,
              coordinator: temporalCarouselCoordinator,
            ),
          ),
        if (level == SummaryPillExperimentLevel.day)
          _track(
            geometry.interactionCellRectForTrack(dayTrack),
            DashboardTemporalComponentCarousel(
              key: ValueKey<String>('summary-pill-$keyPrefix-day-selector'),
              height: height,
              visualContentOffset: visualContentOffsetFor(dayTrack),
              navigation: navigation,
              semanticsLabel:
                  'Nap: ${navigation.state.dayCursor}. Függőlegesen húzva módosítható.',
              candidateForOffset: (origin, offset) =>
                  componentCandidateProjector?.call(
                    base: origin,
                    plane: level.plane,
                    isRailOpen: level.isRailOpen,
                    component: DashboardTemporalAnchorComponent.day,
                    offset: offset,
                  ) ??
                  navigation.temporalComponentOffsetCandidate(
                    plane: level.plane,
                    isRailOpen: level.isRailOpen,
                    component: DashboardTemporalAnchorComponent.day,
                    offset: offset,
                    base: origin,
                  ),
              labelForCandidate: _dayCandidateLabel,
              onCrossed: (candidate) {
                onComponentCrossed(
                  candidate,
                  DashboardTemporalAnchorComponent.day,
                );
                return onComponentCrossingAccepted?.call(
                      candidate,
                      DashboardTemporalAnchorComponent.day,
                    ) ??
                    DashboardSegmentedTargetAcceptance.acceptedExact;
              },
              paintedTargets: componentPaintedTarget,
              onVisualTargetPainted: (candidate) =>
                  onComponentVisualTargetPainted?.call(
                    candidate,
                    DashboardTemporalAnchorComponent.day,
                  ),
              onSettled: (candidate) => onComponentSettled?.call(
                candidate,
                DashboardTemporalAnchorComponent.day,
              ),
              onMotionActiveChanged: motionGate.callbackFor(
                _SegmentedMotionOwner.day,
              ),
              onDirectInputStarted: onSelectorDirectInputStarted,
              onPointerDownDecision: onSelectorPointerDownDecision,
              motionDiagnostics: motionDiagnostics,
              presentation: presentation.temporalFlingPresentation,
              component: DashboardTemporalAnchorComponent.day,
              autoResetMotionRegistry: autoResetMotionRegistry,
              coordinator: temporalCarouselCoordinator,
            ),
          ),
        if (presentation.showSeparators &&
            level == SummaryPillExperimentLevel.day &&
            dayTrack > monthTrack)
          _separator(geometry, afterTrack: monthTrack, boundaryKey: dayTrack),
      ],
    );
  }

  Widget _track(Rect rect, Widget child) => Positioned.fromRect(
    rect: rect,
    // The real selector Rect is a hard boundary: even an ordinary tap that
    // does not become a fling must not fall through to Summary background
    // reset. The child still owns its vertical carousel recognizer.
    child: GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {},
      child: child,
    ),
  );

  Widget _separator(
    SummarySegmentedTrackGeometry geometry, {
    required int afterTrack,
    required int boundaryKey,
  }) => Positioned(
    key: ValueKey<String>('summary-pill-$keyPrefix-separator-$boundaryKey'),
    left: geometry.separatorCenterAfterTrack(afterTrack) - .5,
    top: FluviVisualTokens.controlInnerGap,
    bottom: FluviVisualTokens.controlInnerGap,
    width: 1,
    child: const ColoredBox(color: FluviVisualTokens.border),
  );
}

String _yearCandidateLabel(DashboardNavigationState candidate) =>
    candidate.yearCursor.toString();

String _monthCandidateLabel(DashboardNavigationState candidate) =>
    DashboardTimeLabelFormatter.monthName(
      candidate.monthCursor.month,
    ).substring(0, 3).toUpperCase();

String _dayCandidateLabel(DashboardNavigationState candidate) =>
    candidate.dayCursor.toString();

final class _ModeSelector extends StatefulWidget {
  const _ModeSelector({
    super.key,
    required this.height,
    required this.level,
    required this.visualContentOffset,
    required this.onCrossed,
    this.onMotionActiveChanged,
    this.autoResetMotionRegistry,
    this.temporalCarouselCoordinator,
    this.onDirectInputStarted,
    this.onPointerDownDecision,
    this.motionDiagnostics,
  });

  final double height;
  final SummaryPillExperimentLevel level;
  final double visualContentOffset;
  final _LevelCrossed onCrossed;
  final ValueChanged<bool>? onMotionActiveChanged;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final DashboardTemporalCarouselCoordinator? temporalCarouselCoordinator;
  final VoidCallback? onDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onPointerDownDecision;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;

  @override
  State<_ModeSelector> createState() => _ModeSelectorState();
}

final class _ModeSelectorState extends State<_ModeSelector> {
  late final CenteredCarouselController _controller =
      CenteredCarouselController(initialIndex: widget.level.index);
  late final DashboardSummaryAutoResetMotionRunner _resetRunner = _runResetStep;
  late final VoidCallback _resetCanceller = _cancelResetMotion;

  DashboardSummaryAutoResetMotionRegistry? _attachedRegistry;

  @override
  void initState() {
    super.initState();
    _attachResetRunner();
  }

  @override
  void didUpdateWidget(covariant _ModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level &&
        !_controller.hasActiveScrollActivity) {
      _controller.jumpToIndexSilently(widget.level.index);
    }
    if (!identical(
      oldWidget.autoResetMotionRegistry,
      widget.autoResetMotionRegistry,
    )) {
      _detachResetRunner(oldWidget.autoResetMotionRegistry);
      _attachResetRunner();
    }
  }

  void _attachResetRunner() {
    final registry = widget.autoResetMotionRegistry;
    if (registry == null) return;
    _attachedRegistry = registry;
    registry.attach(
      kind: DashboardSummaryAutoResetStepKind.level,
      runner: _resetRunner,
      cancelMotion: _resetCanceller,
    );
  }

  void _detachResetRunner(DashboardSummaryAutoResetMotionRegistry? registry) {
    registry?.detach(
      kind: DashboardSummaryAutoResetStepKind.level,
      runner: _resetRunner,
      cancelMotion: _resetCanceller,
    );
    if (identical(_attachedRegistry, registry)) _attachedRegistry = null;
  }

  Future<void> _runResetStep(DashboardSummaryAutoResetStep step) async {
    final targetPlane = step.plane;
    final targetRail = step.isRailOpen;
    if (step.kind != DashboardSummaryAutoResetStepKind.level ||
        targetPlane == null ||
        targetRail == null) {
      return;
    }
    final target = SummaryPillExperimentLevel.values.firstWhere(
      (level) => level.plane == targetPlane && level.isRailOpen == targetRail,
    );
    final count = SummaryPillExperimentLevel.values.length;
    final raw = _positiveModulo(
      target.index - _controller.selectedLogicalIndex,
      count,
    );
    final offset = raw > count / 2 ? raw - count : raw;
    if (offset == 0) return;
    await _controller.animateToIndex(
      _controller.selectedLogicalIndex + offset,
      duration: Duration(milliseconds: 130 * offset.abs()),
      curve: Curves.easeOutCubic,
    );
  }

  void _cancelResetMotion() =>
      _controller.jumpToIndexSilently(_controller.selectedLogicalIndex);

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        'Időszint: ${widget.level.semanticsLabel}. Függőlegesen húzva válthat.',
    child: CenteredCarousel<SummaryPillExperimentLevel>(
      dataSource: const CyclicCarouselDataSource<SummaryPillExperimentLevel>(
        SummaryPillExperimentLevel.values,
      ),
      controller: _controller,
      spec: CenteredCarouselSpec(
        itemExtent: widget.height,
        scrollDirection: Axis.vertical,
        visibleItemCount: 1,
        minScale: 1,
        neighborScale: 1,
        outerScale: 1,
        minOpacity: 1,
        neighborOpacity: 1,
        outerOpacity: 1,
        enableHaptics: true,
      ),
      height: widget.height,
      viewportKey: ValueKey<String>('${widget.key}-viewport'),
      motionDiagnostics: widget.motionDiagnostics,
      onDirectPointerDown: () {
        widget.onDirectInputStarted?.call();
        widget.temporalCarouselCoordinator?.claim(this);
      },
      onPointerDownDecision: widget.onPointerDownDecision,
      onMotionStarted: (origin) {
        widget.temporalCarouselCoordinator?.noteMotionStarted();
        widget.onMotionActiveChanged?.call(true);
      },
      onMotionInterrupted: () => widget.onMotionActiveChanged?.call(false),
      onSelectedChanged: (index) {
        final level =
            SummaryPillExperimentLevel.values[_positiveModulo(
              index,
              SummaryPillExperimentLevel.values.length,
            )];
        if (level != widget.level) {
          widget.onCrossed(level.plane, level.isRailOpen);
        }
      },
      onMotionIdle: (_) => widget.onMotionActiveChanged?.call(false),
      itemBuilder: (context, item, _) => Transform.translate(
        offset: Offset(widget.visualContentOffset, 0),
        child: ExcludeSemantics(child: _ModeBadge(item: item)),
      ),
    ),
  );

  @override
  void dispose() {
    // A variant replacement can remove this carousel while a drag or ballistic
    // activity is still active.  Unlike a normal idle/interrupted callback,
    // disposal has no later CenteredCarousel notification, so it must release
    // the shared Summary motion lane explicitly.  Otherwise the removed
    // segmented adapter can keep the core's foreground/paging safety gate
    // active after Classic has become the only visible input surface.
    widget.onMotionActiveChanged?.call(false);
    _detachResetRunner(_attachedRegistry);
    _controller.dispose();
    super.dispose();
  }
}

final class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.item});

  final SummaryPillExperimentLevel item;

  @override
  Widget build(BuildContext context) {
    const badgeSize = DashboardLogBoxTokens.avatarSize;
    final badge = Container(
      key: ValueKey<String>('summary-pill-segmented-mode-badge-${item.name}'),
      width: badgeSize,
      height: badgeSize,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFFF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(item.icon, color: const Color(0xFF7564F5), size: 20),
    );
    return badge;
  }
}

int _positiveModulo(int value, int modulus) =>
    ((value % modulus) + modulus) % modulus;
