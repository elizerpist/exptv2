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

/// One actual Rect authority for each active segmented Summary component.
///
/// The same section Rect owns painting, clipping, semantics and carousel hit
/// testing. There are no hidden quarter-width gesture tracks and no translated
/// visual contents.
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

  Rect semanticRectForTrack(int track) => _rectForTrack(track);

  double semanticCenterForTrack(int track) => _rectForTrack(track).center.dx;

  /// The painted selector uses the exact owning interaction Rect; this catches
  /// any future return of visual-only translations or separate touch lanes.
  double visualCenterForTrack(int track) =>
      visualContentRectForTrack(track).center.dx;

  /// There is no second visual Rect. This is kept as an explicit API so tests
  /// can pin visual/hit/semantics parity.
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
    this.onComponentSettled,
    this.motionDiagnostics,
    this.componentCandidateProjector,
    this.performanceCounters,
    this.onAmountMotionActiveChanged,
    this.onSelectorMotionActiveChanged,
    this.onSelectorDirectInputStarted,
    this.onSelectorPointerDownDecision,
    this.onBackgroundTap,
    this.onBackgroundVerticalDragStart,
    this.onBackgroundVerticalDragUpdate,
    this.onBackgroundVerticalDragEnd,
    this.autoResetMotionRegistry,
    this.presentation = const DashboardSummaryPresentationSettings.defaults(),
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
  final VoidCallback? onBackgroundTap;
  final GestureDragStartCallback? onBackgroundVerticalDragStart;
  final GestureDragUpdateCallback? onBackgroundVerticalDragUpdate;
  final GestureDragEndCallback? onBackgroundVerticalDragEnd;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final DashboardSummaryPresentationSettings presentation;

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
            final inset = bounds.width <= 320
                ? 6.0
                : FluviVisualTokens.controlHorizontalInset;
            // Keep the pre-existing prepared-amount width contract while
            // turning its remaining area into deterministic fixed tracks.
            final amountWidth = constraints.maxWidth * .40;
            // This is the original quarter-track navigation footprint. It is
            // retained only as the measured pre-regression content-edge baseline
            // for the requested 50% gap—not as a visual or gesture lane.
            final preRegressionNavigationWidth =
                constraints.maxWidth - amountWidth - inset * 2;
            // Normal preserves the existing right-side amount zone; mirrored
            // swaps the two whole zones. In either orientation, navigation's
            // outer edge is the mode badge's equal horizontal/vertical inset.
            final navigationWidth = constraints.maxWidth - amountWidth - inset;
            final activeTracks = <int>[
              0,
              if (level != SummaryPillExperimentLevel.sum) 1,
              if (level == SummaryPillExperimentLevel.month ||
                  level == SummaryPillExperimentLevel.day)
                2,
              if (level == SummaryPillExperimentLevel.day) 3,
            ];
            final selectorGeometry = SummarySegmentedTrackGeometry.resolve(
              width: navigationWidth,
              height: bounds.height,
              activeTrackIndices: activeTracks,
              preRegressionNavigationWidth: preRegressionNavigationWidth,
              orientation: presentation.segmentedOrientation,
            );
            final navigationLeft =
                presentation.segmentedOrientation ==
                    SummarySegmentedOrientation.normal
                ? 0.0
                : inset + amountWidth;
            bool isSelectorPosition(Offset localPosition) => activeTracks.any(
              (track) => selectorGeometry
                  .semanticRectForTrack(track)
                  .shift(Offset(navigationLeft, 0))
                  .contains(localPosition),
            );
            final navigationSurface = SizedBox(
              width: navigationWidth,
              height: bounds.height,
              child: _SegmentedNavigationSurface(
                level: level,
                height: bounds.height,
                width: navigationWidth,
                preRegressionNavigationWidth: preRegressionNavigationWidth,
                navigation: navigation,
                presentation: presentation,
                onLevelCrossed: onLevelCrossed,
                onComponentCrossed: onComponentCrossed,
                onComponentCrossingAccepted: onComponentCrossingAccepted,
                componentPaintedTarget: componentPaintedTarget,
                onComponentSettled: onComponentSettled,
                motionDiagnostics: motionDiagnostics,
                componentCandidateProjector: componentCandidateProjector,
                motionGate: motionGate,
                onSelectorDirectInputStarted: onSelectorDirectInputStarted,
                onSelectorPointerDownDecision: onSelectorPointerDownDecision,
                autoResetMotionRegistry: autoResetMotionRegistry,
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
                    presentation.segmentedOrientation ==
                        SummarySegmentedOrientation.normal
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                child: SummaryPillPreparedAmountSlot(
                  visibleFrames: visibleFrames,
                  performanceCounters: performanceCounters,
                  onMotionActiveChanged: onAmountMotionActiveChanged,
                  slotWidth: amountWidth,
                  alignment:
                      presentation.segmentedOrientation ==
                          SummarySegmentedOrientation.normal
                      ? Alignment.centerRight
                      : Alignment.centerLeft,
                ),
              ),
            );
            final sections = switch (presentation.segmentedOrientation) {
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
            // Selector sections are above this surface in the hit-test tree, so
            // temporal flings retain exact Rect ownership. The exposed surface
            // is the only Summary region that can tap-reset or drag Header.
            return Stack(
              fit: StackFit.expand,
              children: <Widget>[
                GestureDetector(
                  key: const ValueKey<String>(
                    'summary-pill-background-gesture',
                  ),
                  behavior: HitTestBehavior.opaque,
                  onTapUp: (details) {
                    if (!isSelectorPosition(details.localPosition)) {
                      onBackgroundTap?.call();
                    }
                  },
                  onVerticalDragStart: onBackgroundVerticalDragStart,
                  onVerticalDragUpdate: onBackgroundVerticalDragUpdate,
                  onVerticalDragEnd: onBackgroundVerticalDragEnd,
                ),
                sections,
              ],
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
    this.onComponentSettled,
    this.motionDiagnostics,
    this.componentCandidateProjector,
    required this.motionGate,
    this.onSelectorDirectInputStarted,
    this.onSelectorPointerDownDecision,
    this.autoResetMotionRegistry,
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
  final _ComponentCrossed? onComponentSettled;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final _SegmentedMotionGate motionGate;
  final VoidCallback? onSelectorDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onSelectorPointerDownDecision;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;

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
    modeSelector: _ModeSelector(
      key: const ValueKey<String>('summary-pill-segmented-mode-selector'),
      height: height,
      level: level,
      onCrossed: onLevelCrossed,
      onMotionActiveChanged: motionGate.callbackFor(_SegmentedMotionOwner.mode),
      onDirectInputStarted: onSelectorDirectInputStarted,
      onPointerDownDecision: onSelectorPointerDownDecision,
      autoResetMotionRegistry: autoResetMotionRegistry,
      motionDiagnostics: motionDiagnostics,
    ),
    onComponentCrossed: onComponentCrossed,
    onComponentCrossingAccepted: onComponentCrossingAccepted,
    componentPaintedTarget: componentPaintedTarget,
    onComponentSettled: onComponentSettled,
    motionDiagnostics: motionDiagnostics,
    componentCandidateProjector: componentCandidateProjector,
    motionGate: motionGate,
    onSelectorDirectInputStarted: onSelectorDirectInputStarted,
    onSelectorPointerDownDecision: onSelectorPointerDownDecision,
    autoResetMotionRegistry: autoResetMotionRegistry,
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
    this.onComponentSettled,
    this.motionDiagnostics,
    this.componentCandidateProjector,
    required this.motionGate,
    this.onSelectorDirectInputStarted,
    this.onSelectorPointerDownDecision,
    this.autoResetMotionRegistry,
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
  final Widget modeSelector;
  final _ComponentCrossed onComponentCrossed;
  final _ComponentCrossingAccepted? onComponentCrossingAccepted;
  final ValueListenable<DashboardSegmentedTargetPainted?>?
  componentPaintedTarget;
  final _ComponentCrossed? onComponentSettled;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final _SegmentedMotionGate motionGate;
  final VoidCallback? onSelectorDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onSelectorPointerDownDecision;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;

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
    return Stack(
      children: <Widget>[
        _track(geometry.semanticRectForTrack(modeTrack), modeSelector),
        if (presentation.showSeparators &&
            level != SummaryPillExperimentLevel.sum)
          _separator(
            geometry,
            afterTrack: modeTrack,
            boundaryKey: modeTrack + 1,
          ),
        if (level != SummaryPillExperimentLevel.sum)
          _track(
            geometry.semanticRectForTrack(yearTrack),
            _HierarchyValueSelector(
              key: ValueKey<String>('summary-pill-$keyPrefix-year-selector'),
              height: height,
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
            geometry.semanticRectForTrack(monthTrack),
            _HierarchyValueSelector(
              key: ValueKey<String>('summary-pill-$keyPrefix-month-selector'),
              height: height,
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
            ),
          ),
        if (level == SummaryPillExperimentLevel.day)
          _track(
            geometry.semanticRectForTrack(dayTrack),
            _HierarchyValueSelector(
              key: ValueKey<String>('summary-pill-$keyPrefix-day-selector'),
              height: height,
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
    required this.onCrossed,
    this.onMotionActiveChanged,
    this.autoResetMotionRegistry,
    this.onDirectInputStarted,
    this.onPointerDownDecision,
    this.motionDiagnostics,
  });

  final double height;
  final SummaryPillExperimentLevel level;
  final _LevelCrossed onCrossed;
  final ValueChanged<bool>? onMotionActiveChanged;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
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
      onDirectPointerDown: widget.onDirectInputStarted,
      onPointerDownDecision: widget.onPointerDownDecision,
      onMotionStarted: (origin) {
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
      itemBuilder: (context, item, _) =>
          ExcludeSemantics(child: _ModeBadge(item: item)),
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

final class _HierarchyValueSelector extends StatefulWidget {
  const _HierarchyValueSelector({
    super.key,
    required this.height,
    required this.navigation,
    required this.semanticsLabel,
    required this.candidateForOffset,
    required this.labelForCandidate,
    required this.onCrossed,
    this.paintedTargets,
    this.onSettled,
    required this.presentation,
    required this.component,
    this.onMotionActiveChanged,
    this.autoResetMotionRegistry,
    this.onDirectInputStarted,
    this.onPointerDownDecision,
    this.motionDiagnostics,
  });

  final double height;
  final DashboardNavigationController navigation;
  final String semanticsLabel;
  final DashboardNavigationState? Function(
    DashboardNavigationState origin,
    int offset,
  )
  candidateForOffset;
  final String Function(DashboardNavigationState candidate) labelForCandidate;
  final DashboardSegmentedTargetAcceptance Function(
    DashboardNavigationState candidate,
  )
  onCrossed;
  final ValueListenable<DashboardSegmentedTargetPainted?>? paintedTargets;
  final ValueChanged<DashboardNavigationState>? onSettled;
  final SummaryTemporalFlingPresentation presentation;
  final DashboardTemporalAnchorComponent component;
  final ValueChanged<bool>? onMotionActiveChanged;
  final DashboardSummaryAutoResetMotionRegistry? autoResetMotionRegistry;
  final VoidCallback? onDirectInputStarted;
  final ValueChanged<CenteredCarouselPointerDownDecision>?
  onPointerDownDecision;
  final CenteredCarouselMotionDiagnosticSink? motionDiagnostics;

  @override
  State<_HierarchyValueSelector> createState() =>
      _HierarchyValueSelectorState();
}

final class _HierarchyValueSelectorState
    extends State<_HierarchyValueSelector> {
  late final CenteredCarouselController _controller =
      CenteredCarouselController(initialIndex: 0);
  late final DashboardSummaryAutoResetMotionRunner _resetRunner = _runResetStep;
  late final VoidCallback _resetCanceller = _cancelResetMotion;
  DashboardNavigationState? _motionOrigin;
  DashboardNavigationState? _currentSemanticTarget;
  DashboardNavigationState? _lastEmittedTarget;
  DashboardNavigationState? _latestDesiredTarget;
  DashboardNavigationState? _latestAcceptedTarget;
  DashboardNavigationState? _latestPaintSelectedTarget;
  DashboardNavigationState? _settleTarget;
  DashboardSummaryAutoResetMotionRegistry? _attachedRegistry;
  var _motionIdle = false;

  DashboardSummaryAutoResetStepKind get _resetStepKind =>
      switch (widget.component) {
        DashboardTemporalAnchorComponent.year =>
          DashboardSummaryAutoResetStepKind.year,
        DashboardTemporalAnchorComponent.month =>
          DashboardSummaryAutoResetStepKind.month,
        DashboardTemporalAnchorComponent.day => throw StateError(
          'DAY is never a Summary reset target.',
        ),
      };

  @override
  void initState() {
    super.initState();
    _attachResetRunner();
    widget.paintedTargets?.addListener(_onPaintedTargetChanged);
  }

  @override
  void didUpdateWidget(covariant _HierarchyValueSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(
      oldWidget.autoResetMotionRegistry,
      widget.autoResetMotionRegistry,
    )) {
      _detachResetRunner(oldWidget.autoResetMotionRegistry);
      _attachResetRunner();
    }
    if (!identical(oldWidget.paintedTargets, widget.paintedTargets)) {
      oldWidget.paintedTargets?.removeListener(_onPaintedTargetChanged);
      widget.paintedTargets?.addListener(_onPaintedTargetChanged);
    }
  }

  void _onPaintedTargetChanged() {
    final painted = widget.paintedTargets?.value;
    if (painted == null || painted.component != widget.component) return;
    if (!_sameOwnedSemanticTarget(_latestAcceptedTarget, painted.target) ||
        !_sameOwnedSemanticTarget(_latestPaintSelectedTarget, painted.target)) {
      return;
    }
    // Rich paint is Phase-B evidence only.  It may enrich diagnostics, but a
    // delayed/failed scene must not replace the latest accepted month as the
    // release target.
  }

  void _clearMotionTargets() {
    _currentSemanticTarget = null;
    _lastEmittedTarget = null;
    _latestDesiredTarget = null;
    _latestAcceptedTarget = null;
    _latestPaintSelectedTarget = null;
    _settleTarget = null;
    _motionOrigin = null;
    _motionIdle = false;
  }

  bool _trySettleAcceptedTarget() {
    if (!_motionIdle) return false;
    final settled = _settleTarget;
    if (settled == null ||
        !_sameOwnedSemanticTarget(_lastEmittedTarget, settled) ||
        !_sameOwnedSemanticTarget(_latestDesiredTarget, settled) ||
        !_sameOwnedSemanticTarget(_latestAcceptedTarget, settled)) {
      return false;
    }
    widget.onSettled?.call(settled);
    _clearMotionTargets();
    return true;
  }

  void _attachResetRunner() {
    final registry = widget.autoResetMotionRegistry;
    if (registry == null ||
        widget.component == DashboardTemporalAnchorComponent.day) {
      return;
    }
    _attachedRegistry = registry;
    registry.attach(
      kind: _resetStepKind,
      runner: _resetRunner,
      cancelMotion: _resetCanceller,
    );
  }

  void _detachResetRunner(DashboardSummaryAutoResetMotionRegistry? registry) {
    if (widget.component != DashboardTemporalAnchorComponent.day) {
      registry?.detach(
        kind: _resetStepKind,
        runner: _resetRunner,
        cancelMotion: _resetCanceller,
      );
    }
    if (identical(_attachedRegistry, registry)) _attachedRegistry = null;
  }

  Future<void> _runResetStep(DashboardSummaryAutoResetStep step) async {
    if (step.kind != _resetStepKind || step.targetValue == null) return;
    if (widget.component == DashboardTemporalAnchorComponent.day) return;
    final current = switch (widget.component) {
      DashboardTemporalAnchorComponent.year =>
        widget.navigation.state.yearCursor,
      DashboardTemporalAnchorComponent.month =>
        widget.navigation.state.monthCursor.month,
      DashboardTemporalAnchorComponent.day => 0,
    };
    final offset = switch (widget.component) {
      DashboardTemporalAnchorComponent.month => _shortestMonthOffset(
        current: current,
        target: step.targetValue!,
      ),
      DashboardTemporalAnchorComponent.year => _shortestYearOffset(
        current: current,
        target: step.targetValue!,
      ),
      DashboardTemporalAnchorComponent.day => 0,
    };
    if (offset == 0) return;
    await _controller.animateToIndex(
      offset,
      duration: Duration(milliseconds: 95 * offset.abs().clamp(1, 6).toInt()),
      curve: Curves.easeOutCubic,
    );
  }

  void _cancelResetMotion() => _controller.jumpToIndexSilently(0);

  int _shortestMonthOffset({required int current, required int target}) {
    final values =
        widget.navigation.temporalAvailability.monthsForYear(
          widget.navigation.state.yearCursor,
        ) ??
        List<int>.generate(12, (index) => index + 1);
    final currentIndex = values.indexOf(current);
    final targetIndex = values.indexOf(target);
    if (currentIndex < 0 || targetIndex < 0) return 0;
    final forward = (targetIndex - currentIndex) % values.length;
    return forward > values.length / 2 ? forward - values.length : forward;
  }

  int _shortestYearOffset({required int current, required int target}) {
    final values = widget.navigation.temporalAvailability.allowedYears;
    if (values == null) return target - current;
    final currentIndex = values.indexOf(current);
    final targetIndex = values.indexOf(target);
    if (currentIndex < 0 || targetIndex < 0) return 0;
    final forward = (targetIndex - currentIndex) % values.length;
    return forward > values.length / 2 ? forward - values.length : forward;
  }

  @override
  Widget build(BuildContext context) => Semantics(
    label: widget.semanticsLabel,
    child: Stack(
      fit: StackFit.expand,
      children: <Widget>[
        CenteredCarousel<int>(
          dataSource: GeneratedCarouselDataSource<int>((index) => index),
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
          onDirectPointerDown: widget.onDirectInputStarted,
          onPointerDownDecision: widget.onPointerDownDecision,
          onMotionStarted: (origin) {
            final semanticOrigin = widget.navigation.state;
            _motionOrigin = semanticOrigin;
            _currentSemanticTarget = semanticOrigin;
            _lastEmittedTarget = null;
            _latestDesiredTarget = null;
            _latestAcceptedTarget = null;
            _latestPaintSelectedTarget = null;
            _settleTarget = null;
            _motionIdle = false;
            widget.onMotionActiveChanged?.call(true);
          },
          onMotionInterrupted: () {
            _clearMotionTargets();
            widget.onMotionActiveChanged?.call(false);
          },
          onSelectedChanged: (offset) {
            final origin = _motionOrigin ?? widget.navigation.state;
            final candidate = widget.candidateForOffset(origin, offset);
            if (candidate == null ||
                _sameOwnedSemanticTarget(_currentSemanticTarget, candidate)) {
              return;
            }
            _currentSemanticTarget = candidate;
            _lastEmittedTarget = candidate;
            _latestDesiredTarget = candidate;
            final acceptance = widget.onCrossed(candidate);
            if (!acceptance.isExactLivePublication) return;
            // The coordinator has synchronously selected this complete
            // prepared frame into the shared visible lane.  A later paint
            // acknowledgement is diagnostic evidence; an emitted candidate
            // without this acceptance can never own release settlement.
            _latestAcceptedTarget = candidate;
            _latestPaintSelectedTarget = candidate;
            // An accepted exact Phase-A frame owns release settlement. Rich
            // paint remains diagnostic evidence owned by the coordinator.
            _settleTarget = candidate;
          },
          onMotionIdle: (_) {
            _motionIdle = true;
            widget.onMotionActiveChanged?.call(false);
            // Commit semantic ownership before recentering. The old order
            // jumped to zero first, briefly restoring the previous origin
            // while the rich-paint acknowledgement was still pending.
            if (_trySettleAcceptedTarget()) {
              _controller.jumpToIndexSilently(0);
            }
          },
          itemBuilder: (context, offset, metrics) {
            final origin = _motionOrigin ?? widget.navigation.state;
            final candidate =
                widget.candidateForOffset(origin, offset) ?? origin;
            if (widget.presentation ==
                SummaryTemporalFlingPresentation.dynamicTrio) {
              return const SizedBox.shrink();
            }
            return FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                widget.labelForCandidate(candidate),
                maxLines: 1,
                style: FluviVisualTokens.summaryTitleTextStyle.copyWith(
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
            );
          },
        ),
        if (widget.presentation == SummaryTemporalFlingPresentation.dynamicTrio)
          ExcludeSemantics(
            child: ClipRect(
              child: IgnorePointer(
                child: ListenableBuilder(
                  listenable: _controller,
                  builder: (context, _) => _DynamicTrioValues(
                    height: widget.height,
                    rawIndex: _controller.rawCenteredLogicalIndex,
                    isMoving: _controller.hasActiveScrollActivity,
                    origin: _motionOrigin ?? widget.navigation.state,
                    candidateForOffset: widget.candidateForOffset,
                    labelForCandidate: widget.labelForCandidate,
                  ),
                ),
              ),
            ),
          ),
      ],
    ),
  );

  bool _sameOwnedSemanticTarget(
    DashboardNavigationState? left,
    DashboardNavigationState right,
  ) {
    if (left == null) return false;
    return switch (widget.component) {
      DashboardTemporalAnchorComponent.year =>
        left.yearCursor == right.yearCursor,
      DashboardTemporalAnchorComponent.month =>
        left.monthCursor.month == right.monthCursor.month,
      DashboardTemporalAnchorComponent.day => left.dayCursor == right.dayCursor,
    };
  }

  @override
  void dispose() {
    // A hierarchy track can disappear while the persistent mode selector is
    // still dragging across a level. Only that selector owns the segmented
    // adapter's variant-unmount release; clearing here would incorrectly end
    // its shared Summary lane during an in-place track replacement.
    widget.paintedTargets?.removeListener(_onPaintedTargetChanged);
    _detachResetRunner(_attachedRegistry);
    _controller.dispose();
    super.dispose();
  }
}

final class _DynamicTrioValues extends StatelessWidget {
  const _DynamicTrioValues({
    required this.height,
    required this.rawIndex,
    required this.isMoving,
    required this.origin,
    required this.candidateForOffset,
    required this.labelForCandidate,
  });

  final double height;
  final double rawIndex;
  final bool isMoving;
  final DashboardNavigationState origin;
  final DashboardNavigationState? Function(DashboardNavigationState, int)
  candidateForOffset;
  final String Function(DashboardNavigationState) labelForCandidate;

  @override
  Widget build(BuildContext context) {
    final offsets = SummaryDynamicTrioGeometry.offsetsFor(
      rawIndex: rawIndex,
      isMoving: isMoving,
    );
    return Stack(
      clipBehavior: Clip.hardEdge,
      children: <Widget>[for (final offset in offsets) _item(offset)],
    );
  }

  Widget _item(int offset) {
    final candidate = candidateForOffset(origin, offset) ?? origin;
    final geometry = SummaryDynamicTrioGeometry.itemFor(
      height: height,
      offset: offset,
      rawIndex: rawIndex,
    );
    return Positioned(
      left: 0,
      right: 0,
      top: geometry.centerY - 10,
      height: 20,
      child: Transform.scale(
        scale: geometry.scale,
        child: Center(
          child: Text(
            key: ValueKey<String>('summary-pill-dynamic-trio-$offset'),
            labelForCandidate(candidate),
            maxLines: 1,
            style: FluviVisualTokens.summaryTitleTextStyle.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}

int _positiveModulo(int value, int modulus) =>
    ((value % modulus) + modulus) % modulus;
