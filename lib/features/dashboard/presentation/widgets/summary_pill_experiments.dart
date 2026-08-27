import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../shared/motion/centered_carousel/centered_carousel.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../time_navigation/application/dashboard_time_navigation_controller.dart';
import '../../time_navigation/application/dashboard_time_navigation_state.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../summary_pill_variant.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../dashboard_summary_presentation.dart';
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
    required Map<int, Rect> sectionRects,
    required Map<int, Rect> visualContentRects,
  }) : _sectionRects = sectionRects,
       _visualContentRects = visualContentRects;

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
    // The component Rect is the hit, semantics and clipping owner. It has a
    // reasonable touch envelope while the authored content remains centred
    // within it. Expand toward 44dp only as far as actual neighbour Rects
    // remain disjoint; this never reintroduces hidden quarter-width lanes.
    var touchWidth = 44.0;
    for (var index = 0; index < activeTrackIndices.length - 1; index += 1) {
      final firstWidth = metrics.widthForTrack(activeTrackIndices[index]);
      final secondWidth = metrics.widthForTrack(activeTrackIndices[index + 1]);
      final smaller = math.min(firstWidth, secondWidth);
      final larger = math.max(firstWidth, secondWidth);
      final maximumWithoutOverlap = smaller + gap * 2 <= larger
          ? smaller + gap * 2
          : (firstWidth + secondWidth) / 2 + gap;
      touchWidth = math.min(touchWidth, maximumWithoutOverlap);
    }
    final sectionRects = <int, Rect>{};
    final visualContentRects = <int, Rect>{};
    // The large mode visual itself—not the padded gesture owner—uses the same
    // left inset as its top inset.
    var nextVisualLeft = (height - metrics.modeVisualSize) / 2;
    for (final track in activeTrackIndices) {
      final contentWidth = metrics.widthForTrack(track);
      final sectionWidth = math.max(contentWidth, touchWidth);
      final visualLeft = nextVisualLeft;
      final ownerLeft = visualLeft - (sectionWidth - contentWidth) / 2;
      sectionRects[track] = Rect.fromLTWH(ownerLeft, 0, sectionWidth, height);
      visualContentRects[track] = Rect.fromLTWH(
        visualLeft,
        (height - metrics.modeVisualSize) / 2,
        contentWidth,
        metrics.modeVisualSize,
      );
      nextVisualLeft += contentWidth + gap;
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
      sectionRects: Map<int, Rect>.unmodifiable(sectionRects),
      visualContentRects: Map<int, Rect>.unmodifiable(visualContentRects),
    );
  }

  final double width;
  final double height;
  final List<int> activeTrackIndices;
  final SummarySegmentedContentMetrics contentMetrics;
  final double preRegressionContentEdgeGap;
  final double segmentedSectionGap;
  final Map<int, Rect> _sectionRects;
  final Map<int, Rect> _visualContentRects;

  Rect semanticRectForTrack(int track) => _rectForTrack(track);

  double semanticCenterForTrack(int track) => _rectForTrack(track).center.dx;

  /// The painted content is centred within the exact same owning interaction
  /// Rect; this catches any future return of a visual-only translation.
  double visualCenterForTrack(int track) =>
      visualContentRectForTrack(track).center.dx;

  /// Authored glyph/badge bounds within the one owning semantic Rect.
  Rect visualContentRectForTrack(int track) =>
      _visualContentRects[track] ??
      (throw ArgumentError.value(track, 'track', 'Inactive Summary track.'));

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
    this.componentCandidateProjector,
    this.performanceCounters,
    this.onAmountMotionActiveChanged,
    this.onSelectorMotionActiveChanged,
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
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onAmountMotionActiveChanged;
  final ValueChanged<bool>? onSelectorMotionActiveChanged;
  final DashboardSummaryPresentationSettings presentation;

  @override
  Widget build(BuildContext context) => ListenableBuilder(
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
          // The amount zone preserves its existing right edge and start. The
          // navigation surface begins at the Summary's actual left edge so
          // the mode badge can use the same left and top visual inset.
          final navigationWidth = constraints.maxWidth - amountWidth - inset;
          return Row(
            children: <Widget>[
              SizedBox(
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
                  componentCandidateProjector: componentCandidateProjector,
                  onSelectorMotionActiveChanged: onSelectorMotionActiveChanged,
                ),
              ),
              SizedBox(
                key: const ValueKey<String>(
                  'summary-pill-experiment-amount-zone',
                ),
                width: amountWidth,
                height: bounds.height,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: SummaryPillPreparedAmountSlot(
                    visibleFrames: visibleFrames,
                    performanceCounters: performanceCounters,
                    onMotionActiveChanged: onAmountMotionActiveChanged,
                  ),
                ),
              ),
              SizedBox(width: inset),
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
  );
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
    this.componentCandidateProjector,
    this.onSelectorMotionActiveChanged,
  });

  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final double preRegressionNavigationWidth;
  final DashboardNavigationController navigation;
  final DashboardSummaryPresentationSettings presentation;
  final _LevelCrossed onLevelCrossed;
  final _ComponentCrossed onComponentCrossed;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final ValueChanged<bool>? onSelectorMotionActiveChanged;

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
      onMotionActiveChanged: onSelectorMotionActiveChanged,
    ),
    onComponentCrossed: onComponentCrossed,
    componentCandidateProjector: componentCandidateProjector,
    onSelectorMotionActiveChanged: onSelectorMotionActiveChanged,
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
    this.componentCandidateProjector,
    this.onSelectorMotionActiveChanged,
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
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final ValueChanged<bool>? onSelectorMotionActiveChanged;

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
              onCrossed: (candidate) => onComponentCrossed(
                candidate,
                DashboardTemporalAnchorComponent.year,
              ),
              onMotionActiveChanged: onSelectorMotionActiveChanged,
              presentation: presentation.temporalFlingPresentation,
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
              onCrossed: (candidate) => onComponentCrossed(
                candidate,
                DashboardTemporalAnchorComponent.month,
              ),
              onMotionActiveChanged: onSelectorMotionActiveChanged,
              presentation: presentation.temporalFlingPresentation,
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
              onCrossed: (candidate) => onComponentCrossed(
                candidate,
                DashboardTemporalAnchorComponent.day,
              ),
              onMotionActiveChanged: onSelectorMotionActiveChanged,
              presentation: presentation.temporalFlingPresentation,
            ),
          ),
        if (presentation.showSeparators &&
            level == SummaryPillExperimentLevel.day &&
            dayTrack > monthTrack)
          _separator(geometry, afterTrack: monthTrack, boundaryKey: dayTrack),
      ],
    );
  }

  Widget _track(Rect rect, Widget child) =>
      Positioned.fromRect(rect: rect, child: child);

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
  });

  final double height;
  final SummaryPillExperimentLevel level;
  final _LevelCrossed onCrossed;
  final ValueChanged<bool>? onMotionActiveChanged;

  @override
  State<_ModeSelector> createState() => _ModeSelectorState();
}

final class _ModeSelectorState extends State<_ModeSelector> {
  late final CenteredCarouselController _controller =
      CenteredCarouselController(initialIndex: widget.level.index);

  @override
  void didUpdateWidget(covariant _ModeSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.level != widget.level &&
        !_controller.hasActiveScrollActivity) {
      _controller.jumpToIndexSilently(widget.level.index);
    }
  }

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
      onMotionStarted: (_) => widget.onMotionActiveChanged?.call(true),
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
    required this.presentation,
    this.onMotionActiveChanged,
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
  final ValueChanged<DashboardNavigationState> onCrossed;
  final SummaryTemporalFlingPresentation presentation;
  final ValueChanged<bool>? onMotionActiveChanged;

  @override
  State<_HierarchyValueSelector> createState() =>
      _HierarchyValueSelectorState();
}

final class _HierarchyValueSelectorState
    extends State<_HierarchyValueSelector> {
  late final CenteredCarouselController _controller =
      CenteredCarouselController(initialIndex: 0);
  DashboardNavigationState? _motionOrigin;

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
          onMotionStarted: (_) {
            _motionOrigin = widget.navigation.state;
            widget.onMotionActiveChanged?.call(true);
          },
          onSelectedChanged: (offset) {
            if (offset == 0) return;
            final origin = _motionOrigin ?? widget.navigation.state;
            final candidate = widget.candidateForOffset(origin, offset);
            if (candidate != null) widget.onCrossed(candidate);
          },
          onMotionIdle: (_) {
            _motionOrigin = null;
            _controller.jumpToIndexSilently(0);
            widget.onMotionActiveChanged?.call(false);
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
      ],
    ),
  );

  @override
  void dispose() {
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
