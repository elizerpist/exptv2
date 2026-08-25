import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
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
import 'dashboard_summary_pill.dart';

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
    this.performanceCounters,
    this.onAmountMotionActiveChanged,
  }) : assert(variant != SummaryPillVariant.legacy);

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
  final DashboardPerformanceCounters? performanceCounters;
  final ValueChanged<bool>? onAmountMotionActiveChanged;

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
      return SizedBox(
        key: ValueKey<String>('summary-pill-experiment-${variant.name}'),
        width: bounds.width,
        height: bounds.height,
        child: FluviRoundedBox(
          color: FluviVisualTokens.surface,
          child: LayoutBuilder(
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
                    child: variant == SummaryPillVariant.segmented
                        ? _SegmentedNavigationSurface(
                            level: level,
                            height: bounds.height,
                            width: navigationWidth,
                            navigation: navigation,
                            onLevelCrossed: onLevelCrossed,
                            onComponentCrossed: onComponentCrossed,
                          )
                        : _SwipeModeNavigationSurface(
                            level: level,
                            height: bounds.height,
                            width: navigationWidth,
                            navigation: navigation,
                            onLevelCrossed: onLevelCrossed,
                            onComponentCrossed: onComponentCrossed,
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
          ),
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
    required this.onLevelCrossed,
    required this.onComponentCrossed,
  });

  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final DashboardNavigationController navigation;
  final _LevelCrossed onLevelCrossed;
  final _ComponentCrossed onComponentCrossed;

  @override
  Widget build(BuildContext context) => _FixedHierarchyTracks(
    keyPrefix: 'segmented',
    level: level,
    height: height,
    width: width,
    navigation: navigation,
    trackCount: 4,
    modeTrack: 0,
    yearTrack: 1,
    monthTrack: 2,
    dayTrack: 3,
    modeSelector: _ModeSelector(
      key: const ValueKey<String>('summary-pill-segmented-mode-selector'),
      height: height,
      direction: Axis.vertical,
      level: level,
      onCrossed: onLevelCrossed,
    ),
    onComponentCrossed: onComponentCrossed,
  );
}

final class _SwipeModeNavigationSurface extends StatelessWidget {
  const _SwipeModeNavigationSurface({
    required this.level,
    required this.height,
    required this.width,
    required this.navigation,
    required this.onLevelCrossed,
    required this.onComponentCrossed,
  });

  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final DashboardNavigationController navigation;
  final _LevelCrossed onLevelCrossed;
  final _ComponentCrossed onComponentCrossed;

  @override
  Widget build(BuildContext context) => Semantics(
    key: const ValueKey<String>('summary-pill-swipe-mode-semantics'),
    label:
        'Időszint: ${level.semanticsLabel}. Vízszintesen húzva válthat időszintet.',
    onIncrease: () => _selectLevel(1),
    onDecrease: () => _selectLevel(-1),
    // The horizontal carousel owns the parent hit-test surface. Visible
    // hierarchy carousels live inside its item, so Flutter's gesture arena
    // receives both recognizers and resolves horizontal versus vertical
    // intent instead of a later Stack child blocking the mode surface.
    child: ExcludeSemantics(
      child: _ModeSelector(
        key: const ValueKey<String>('summary-pill-swipe-mode-surface'),
        height: height,
        width: width,
        direction: Axis.horizontal,
        level: level,
        onCrossed: onLevelCrossed,
        itemChildBuilder: (context, item, _) => _FixedHierarchyTracks(
          keyPrefix: 'swipe',
          level: item,
          height: height,
          width: width,
          navigation: navigation,
          trackCount: 3,
          yearTrack: 0,
          monthTrack: 1,
          dayTrack: 2,
          onComponentCrossed: onComponentCrossed,
        ),
      ),
    ),
  );

  void _selectLevel(int delta) {
    final target =
        SummaryPillExperimentLevel.values[_positiveModulo(
          level.index + delta,
          SummaryPillExperimentLevel.values.length,
        )];
    onLevelCrossed(target.plane, target.isRailOpen);
  }
}

final class _FixedHierarchyTracks extends StatelessWidget {
  const _FixedHierarchyTracks({
    required this.keyPrefix,
    required this.level,
    required this.height,
    required this.width,
    required this.navigation,
    required this.trackCount,
    this.modeTrack,
    required this.yearTrack,
    required this.monthTrack,
    required this.dayTrack,
    this.modeSelector,
    required this.onComponentCrossed,
  });

  final String keyPrefix;
  final SummaryPillExperimentLevel level;
  final double height;
  final double width;
  final DashboardNavigationController navigation;
  final int trackCount;
  final int? modeTrack;
  final int yearTrack;
  final int monthTrack;
  final int dayTrack;
  final Widget? modeSelector;
  final _ComponentCrossed onComponentCrossed;

  @override
  Widget build(BuildContext context) {
    final trackWidth = width / trackCount;
    return Stack(
      children: <Widget>[
        if (modeSelector case final selector?)
          _track(trackWidth, modeTrack!, selector),
        if (modeTrack != null && level != SummaryPillExperimentLevel.sum)
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
            ),
          ),
        if ((level == SummaryPillExperimentLevel.month ||
                level == SummaryPillExperimentLevel.day) &&
            monthTrack > yearTrack)
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
            ),
          ),
        if (level == SummaryPillExperimentLevel.day && dayTrack > monthTrack)
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
    this.width,
    required this.direction,
    required this.level,
    required this.onCrossed,
    this.itemChildBuilder,
  }) : assert(direction == Axis.vertical || width != null);

  final double height;
  final double? width;
  final Axis direction;
  final SummaryPillExperimentLevel level;
  final _LevelCrossed onCrossed;
  final Widget Function(
    BuildContext context,
    SummaryPillExperimentLevel item,
    CenteredCarouselItemMetrics metrics,
  )?
  itemChildBuilder;

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
        'Időszint: ${widget.level.semanticsLabel}. ${widget.direction == Axis.vertical ? 'Függőlegesen' : 'Vízszintesen'} húzva válthat.',
    child: CenteredCarousel<SummaryPillExperimentLevel>(
      dataSource: const CyclicCarouselDataSource<SummaryPillExperimentLevel>(
        SummaryPillExperimentLevel.values,
      ),
      controller: _controller,
      spec: CenteredCarouselSpec(
        itemExtent: switch (widget.direction) {
          Axis.vertical => widget.height,
          Axis.horizontal => widget.width!,
        },
        scrollDirection: widget.direction,
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
      itemBuilder: (context, item, metrics) =>
          widget.itemChildBuilder?.call(context, item, metrics) ??
          Icon(
            item.icon,
            color: metrics.isSelected
                ? FluviVisualTokens.textPrimary
                : FluviVisualTokens.textSecondary,
            size: FluviVisualTokens.iconSize,
          ),
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
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
    child: CenteredCarousel<int>(
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
      onMotionStarted: (_) => _motionOrigin = widget.navigation.state,
      onSelectedChanged: (offset) {
        if (offset == 0) return;
        final origin = _motionOrigin ?? widget.navigation.state;
        final candidate = widget.candidateForOffset(origin, offset);
        if (candidate != null) widget.onCrossed(candidate);
      },
      onMotionIdle: (_) {
        _motionOrigin = null;
        _controller.jumpToIndexSilently(0);
      },
      itemBuilder: (context, offset, metrics) {
        final origin = _motionOrigin ?? widget.navigation.state;
        final candidate = widget.candidateForOffset(origin, offset) ?? origin;
        return FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            widget.labelForCandidate(candidate),
            maxLines: 1,
            style: FluviVisualTokens.summaryTitleTextStyle,
          ),
        );
      },
    ),
  );

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}

int _positiveModulo(int value, int modulus) =>
    ((value % modulus) + modulus) % modulus;
