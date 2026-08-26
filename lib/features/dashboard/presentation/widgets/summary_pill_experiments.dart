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
          final navigationWidth =
              constraints.maxWidth - amountWidth - inset * 2;
          return Row(
            children: <Widget>[
              SizedBox(width: inset),
              SizedBox(
                width: navigationWidth,
                height: bounds.height,
                child: _SegmentedNavigationSurface(
                  level: level,
                  height: bounds.height,
                  width: navigationWidth,
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
      layout: presentation.modeSelectorLayout,
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
    required this.navigation,
    required this.presentation,
    required this.trackCount,
    this.modeTrack,
    required this.yearTrack,
    required this.monthTrack,
    required this.dayTrack,
    this.modeSelector,
    required this.onComponentCrossed,
    this.componentCandidateProjector,
    this.onSelectorMotionActiveChanged,
  });

  final String keyPrefix;
  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final DashboardNavigationController navigation;
  final DashboardSummaryPresentationSettings presentation;
  final int trackCount;
  final int? modeTrack;
  final int yearTrack;
  final int monthTrack;
  final int dayTrack;
  final Widget? modeSelector;
  final _ComponentCrossed onComponentCrossed;
  final SummaryPillComponentCandidateProjector? componentCandidateProjector;
  final ValueChanged<bool>? onSelectorMotionActiveChanged;

  @override
  Widget build(BuildContext context) {
    final trackWidth = width / trackCount;
    return Stack(
      children: <Widget>[
        if (modeSelector case final selector?)
          _track(trackWidth, modeTrack!, selector),
        if (presentation.showSeparators &&
            modeTrack != null &&
            level != SummaryPillExperimentLevel.sum)
          _separator(trackWidth, modeTrack! + 1),
        if (level != SummaryPillExperimentLevel.sum)
          _track(
            trackWidth,
            yearTrack,
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
          _separator(trackWidth, monthTrack),
        if (level == SummaryPillExperimentLevel.month ||
            level == SummaryPillExperimentLevel.day)
          _track(
            trackWidth,
            monthTrack,
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
            trackWidth,
            dayTrack,
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
          _separator(trackWidth, dayTrack),
      ],
    );
  }

  Widget _track(double trackWidth, int index, Widget child) => Positioned(
    left: trackWidth * index,
    width: trackWidth,
    top: 0,
    bottom: 0,
    child: child,
  );

  Widget _separator(double trackWidth, int boundary) => Positioned(
    key: ValueKey<String>('summary-pill-$keyPrefix-separator-$boundary'),
    left: trackWidth * boundary,
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
    required this.layout,
    required this.onCrossed,
    this.onMotionActiveChanged,
  });

  final double height;
  final SummaryPillExperimentLevel level;
  final SummaryModeSelectorLayout layout;
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
      itemBuilder: (context, item, _) => ExcludeSemantics(
        child: _ModeBadge(item: item, layout: widget.layout),
      ),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

final class _ModeBadge extends StatelessWidget {
  const _ModeBadge({required this.item, required this.layout});

  final SummaryPillExperimentLevel item;
  final SummaryModeSelectorLayout layout;

  @override
  Widget build(BuildContext context) {
    final large = layout == SummaryModeSelectorLayout.largeIcon;
    final badgeSize = large ? DashboardLogBoxTokens.avatarSize : 25.0;
    final badge = Container(
      key: ValueKey<String>('summary-pill-segmented-mode-badge-${item.name}'),
      width: badgeSize,
      height: badgeSize,
      padding: EdgeInsets.all(large ? 7 : 5),
      decoration: BoxDecoration(
        color: const Color(0xFFF1EFFF),
        borderRadius: BorderRadius.circular(9),
      ),
      child: Icon(
        item.icon,
        color: const Color(0xFF7564F5),
        size: large ? 20 : 15,
      ),
    );
    if (layout != SummaryModeSelectorLayout.iconWithLabel) return badge;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        badge,
        const SizedBox(height: 2),
        Text(
          item.shortLabel,
          maxLines: 1,
          style: const TextStyle(
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w700,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
    );
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

extension on SummaryPillExperimentLevel {
  String get shortLabel => switch (this) {
    SummaryPillExperimentLevel.sum => 'ÖSSZ',
    SummaryPillExperimentLevel.year => 'ÉV',
    SummaryPillExperimentLevel.month => 'HÓ',
    SummaryPillExperimentLevel.day => 'NAP',
  };
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
