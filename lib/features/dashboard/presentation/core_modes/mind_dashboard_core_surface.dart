import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../core/diagnostics/fluvi_onscreen_diagnostics.dart';
import '../../query/domain/query_amount_range.dart';
import '../../query/application/dashboard_applied_query_facet_loader.dart';
import '../../query/presentation/query_amount_range_control.dart';
import '../../mind/domain/mind_year_heatmap_projection.dart';
import '../../mind/domain/mind_entry_diagnostic_identity.dart';
import '../../mind/domain/mind_temporal_heatmap_frame.dart';
import '../../mind/domain/mind_temporal_heatmap_projection.dart';
import '../../mind/domain/mind_year_heatmap_presentation_settings.dart';
import '../../mind/domain/mind_behavioral_score_projection.dart';
import '../../mind/domain/mind_header_score_chart_presentation.dart';
import '../../mind/presentation/mind_header_score_chart.dart';
import '../../mind/presentation/mind_year_heatmap_palette_resolver.dart';
import '../../mind/presentation/mind_heatmap_palette_scope.dart';
import '../../mind/presentation/mind_year_heatmap_viewport.dart';
import '../../mind/presentation/mind_temporal_heatmap_viewports.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../widgets/dashboard_header_trend_visual_kernel.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';
import '../dashboard_corner_roundness.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// UI-side acknowledgement of one actually laid-out/painted immutable Mind
/// frame. Core owns the correlation trace; this callback only reports the
/// renderer boundary without accepting input or mutating financial state.
typedef MindTemporalEntryFrameStageReporter =
    void Function({
      required String stage,
      required int frameCoreRevision,
      required String kind,
      required String frameIdentity,
    });

/// Mind owns one merged body surface spanning the central unified envelope.
class MindDashboardCoreSurface extends StatelessWidget {
  const MindDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.expandedSurfaceStyle = MindExpandedSurfaceStyle.separateCards,
    this.queryAmountRange,
    this.queryAmountRangeChanges,
    this.queryAmountRangeLifecycleChanges,
    this.queryAmountRangeState,
    this.queryAmountRangeError,
    this.yearHeatmap,
    this.temporalHeatmap,
    this.temporalPlane,
    this.yearHeatmapPresentation,
    this.showYearHeatmap = false,
    this.showTemporalHeatmap = false,
    this.showTemporalDayHeatmap = false,
    this.onQueryAmountRangeRetry,
    this.onQueryAmountRangeCommitted,
    this.onQueryAmountRangePreviewChanged,
    this.onQueryAmountRangeInteractionStarted,
    this.onQueryAmountRangeInteractionEnded,
    this.onQueryAmountRangeInteractionSummary,
    this.onContentVerticalDragStart,
    this.onContentVerticalDragUpdate,
    this.onContentVerticalDragEnd,
    this.onContentVerticalDragCancel,
    this.upperVerticalGestures,
    this.headerVisualController,
    this.headerVisualFrame,
    this.behavioralScore,
    this.headerScoreChartPresentation,
    this.headerScoreChartPointerObserver,
    this.onTemporalEntryFrameStage,
  });

  final DashboardCoreModePresentation presentation;
  final MindExpandedSurfaceStyle expandedSurfaceStyle;
  final QueryAmountRangeValues? Function()? queryAmountRange;
  final Listenable? queryAmountRangeChanges;
  final Listenable? queryAmountRangeLifecycleChanges;
  final DashboardAppliedQueryFacetLoadState Function()? queryAmountRangeState;
  final Object? Function()? queryAmountRangeError;
  final ValueListenable<MindYearHeatmapFrame?>? yearHeatmap;
  final ValueListenable<MindTemporalHeatmapFrame?>? temporalHeatmap;
  final TimePlane? temporalPlane;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  yearHeatmapPresentation;
  final bool showYearHeatmap;
  final bool showTemporalHeatmap;
  final bool showTemporalDayHeatmap;
  final VoidCallback? onQueryAmountRangeRetry;
  final ValueChanged<QueryAmountRangeValues>? onQueryAmountRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onQueryAmountRangePreviewChanged;
  final VoidCallback? onQueryAmountRangeInteractionStarted;
  final VoidCallback? onQueryAmountRangeInteractionEnded;
  final ValueChanged<QueryAmountRangeInteractionSummary>?
  onQueryAmountRangeInteractionSummary;
  final GestureDragStartCallback? onContentVerticalDragStart;
  final GestureDragUpdateCallback? onContentVerticalDragUpdate;
  final GestureDragEndCallback? onContentVerticalDragEnd;
  final GestureDragCancelCallback? onContentVerticalDragCancel;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final ValueListenable<MindBehavioralScoreFrame?>? behavioralScore;
  final ValueListenable<MindHeaderScoreChartPresentationSettings>?
  headerScoreChartPresentation;
  final MindHeaderScoreChartPointerObserver? headerScoreChartPointerObserver;
  final MindTemporalEntryFrameStageReporter? onTemporalEntryFrameStage;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    final bodyBounds = geometry.unifiedSubheaderBounds!;
    final isSeamless =
        expandedSurfaceStyle == MindExpandedSurfaceStyle.seamlessCard &&
        geometry.seamlessHeaderContent;
    final headerRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.header,
          size: Size(geometry.headerBounds.width, geometry.headerBounds.height),
        );
    final contentRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.contentCard,
          size: Size(bodyBounds.width, bodyBounds.height),
        );
    final surfaceShape = MindExpandedSurfaceShape.resolve(
      seamless: isSeamless,
      headerRadius: headerRadius,
      contentRadius: contentRadius,
      expansionProgress: geometry.headerExpansionProgress,
    );
    final combinedBounds = DashboardBounds(
      left: geometry.headerBounds.left,
      top: geometry.headerBounds.top,
      width: geometry.headerBounds.width,
      height:
          geometry.headerBounds.height +
          bodyBounds.height * geometry.headerExpansionProgress,
    );
    final header = DashboardCoreModeHeaderScaffold(
      bounds: geometry.headerBounds,
      surfaceColor: presentation.palette.upcomingHeaderTone,
      headerKey: const ValueKey('dashboard-core-mode-mind-header'),
      labelKey: const ValueKey('dashboard-core-mode-label-mind'),
      label: 'mind',
      showModeLabel: false,
      visualController: headerVisualController,
      visualFrameListenable: headerVisualFrame,
      usesVisualForeground: true,
      detailLeft: 0,
      detailTop: 0,
      detailRight: 0,
      detailBottom: 0,
      borderRadiusOverride: surfaceShape.headerRadius,
      showsDepth: !isSeamless,
      showsBorder: !isSeamless,
      detail: behavioralScore == null
          ? null
          : _MindHeaderScoreDetail(
              score: behavioralScore!,
              headerVisualFrame: headerVisualFrame,
              expansionProgress: geometry.headerExpansionProgress,
              expandedHeaderExtraHeight: geometry.expandedHeaderExtraHeight,
              chartPresentation: headerScoreChartPresentation,
              temporalContext: _headerScoreChartTemporalContext,
              pointerObserver: headerScoreChartPointerObserver,
              reporter: onTemporalEntryFrameStage,
            ),
    );
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-mind'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          if (isSeamless)
            DashboardCoreModeFramePosition(
              bounds: combinedBounds,
              child: DashboardPlaceholderCard(
                bounds: combinedBounds,
                fillParent: true,
                semanticKey: const ValueKey(
                  'dashboard-core-mode-mind-seamless-surface',
                ),
                cornerFamily: DashboardCornerSurfaceFamily.contentCard,
                borderSurface: DashboardBorderSurface.mindContent,
                borderRadiusOverride: surfaceShape.outerRadius,
              ),
            ),
          if (isSeamless)
            DashboardCoreModeTopReveal(
              bounds: bodyBounds,
              reveal: geometry.headerExpansionProgress,
              child: _MindSeamlessBodySurface(
                bounds: bodyBounds,
                dotsBounds: geometry.zone2IndicatorBounds,
                borderRadius: surfaceShape.contentRadius,
                headerVisualFrame: headerVisualFrame,
                body: _bodyChild(),
              ),
            )
          else
            DashboardCoreModeOpacityPosition(
              bounds: bodyBounds,
              opacity: geometry.zone2Opacity,
              offset: Offset(0, geometry.zone2Shift),
              scale: geometry.zone2Scale,
              child: DashboardPlaceholderCard(
                bounds: bodyBounds,
                fillParent: true,
                semanticKey: const ValueKey('dashboard-core-mode-mind-body'),
                borderSurface: DashboardBorderSurface.mindContent,
                child: _bodyChild(),
              ),
            ),
          if (!isSeamless)
            DashboardCoreModeOpacityPosition(
              bounds: geometry.zone2IndicatorBounds,
              opacity: geometry.zone2Opacity,
              offset: Offset(0, geometry.zone2Shift),
              child: DashboardPlaceholderDots(
                bounds: geometry.zone2IndicatorBounds,
                semanticKey: const ValueKey('dashboard-core-mode-mind-dots'),
              ),
            ),
          header,
        ],
      ),
    );
  }

  MindHeaderScoreChartTemporalContext get _headerScoreChartTemporalContext =>
      switch (temporalPlane) {
        TimePlane.sum => MindHeaderScoreChartTemporalContext.sum,
        TimePlane.month when showTemporalDayHeatmap =>
          MindHeaderScoreChartTemporalContext.day,
        TimePlane.month => MindHeaderScoreChartTemporalContext.month,
        TimePlane.year || null => MindHeaderScoreChartTemporalContext.year,
      };

  Widget? _bodyChild() {
    if (queryAmountRange == null ||
        queryAmountRangeChanges == null ||
        onQueryAmountRangeCommitted == null) {
      return null;
    }
    final heatmap = yearHeatmap;
    // Existing isolated Mind surface callers only supplied the Year flag.
    // Preserve that source-compatible Year default while CoreDashboard now
    // supplies the explicit temporal plane for Sum/Month.
    final resolvedPlane =
        temporalPlane ?? (showYearHeatmap ? TimePlane.year : null);
    final temporalViewportOwnsVerticalDrag =
        (resolvedPlane == TimePlane.year &&
            showYearHeatmap &&
            heatmap != null) ||
        ((resolvedPlane == TimePlane.sum || resolvedPlane == TimePlane.month) &&
            showTemporalHeatmap &&
            temporalHeatmap != null &&
            !showTemporalDayHeatmap);
    final temporalContent = switch (resolvedPlane) {
      TimePlane.year when showYearHeatmap && heatmap != null =>
        MindYearHeatmapViewport(
          frameListenable: heatmap,
          presentationSettings: yearHeatmapPresentation,
          upperVerticalGestures: upperVerticalGestures,
        ),
      TimePlane.sum when showTemporalHeatmap && temporalHeatmap != null =>
        MindSumHeatmapViewport(
          frameListenable: temporalHeatmap!,
          presentationSettings: yearHeatmapPresentation,
          upperVerticalGestures: upperVerticalGestures,
        ),
      TimePlane.month when showTemporalHeatmap && temporalHeatmap != null =>
        showTemporalDayHeatmap
            ? MindDayHeatmapViewport(
                frameListenable: temporalHeatmap!,
                presentationSettings: yearHeatmapPresentation,
              )
            : MindMonthHeatmapViewport(
                frameListenable: temporalHeatmap!,
                presentationSettings: yearHeatmapPresentation,
                upperVerticalGestures: upperVerticalGestures,
              ),
      _ => const SizedBox.expand(
        key: ValueKey<String>('mind-temporal-content-unavailable'),
      ),
    };
    final probedTemporalContent = switch (resolvedPlane) {
      TimePlane.year when showYearHeatmap && heatmap != null =>
        _MindTemporalEntryFrameProbe<MindYearHeatmapFrame>(
          frameListenable: heatmap,
          descriptorFor: (frame) => (
            kind: 'year',
            coreRevision: frame.identity.coreRevision,
            identity: mindTemporalEntryBodyFrameIdentity(frame),
          ),
          reporter: onTemporalEntryFrameStage,
          child: temporalContent,
        ),
      TimePlane.sum || TimePlane.month when temporalHeatmap != null =>
        _MindTemporalEntryFrameProbe<MindTemporalHeatmapFrame>(
          frameListenable: temporalHeatmap!,
          descriptorFor: (frame) => switch (frame) {
            MindSumHeatmapFrame(:final identity) => (
              kind: 'sum',
              coreRevision: identity.coreRevision,
              identity: mindTemporalEntryBodyFrameIdentity(frame),
            ),
            MindMonthHeatmapFrame(:final identity) => (
              kind: 'month',
              coreRevision: identity.coreRevision,
              identity: mindTemporalEntryBodyFrameIdentity(frame),
            ),
            MindDayHeatmapFrame(:final identity) => (
              kind: 'day',
              coreRevision: identity.coreRevision,
              identity: mindTemporalEntryBodyFrameIdentity(frame),
            ),
            _ => (kind: 'unknown', coreRevision: 0, identity: 'unsupported'),
          },
          reporter: onTemporalEntryFrameStage,
          child: temporalContent,
        ),
      _ => temporalContent,
    };
    final guardedTemporalContent = temporalViewportOwnsVerticalDrag
        ? probedTemporalContent
        : GestureDetector(
            key: const ValueKey('dashboard-core-mode-content-gesture-region'),
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: onContentVerticalDragStart,
            onVerticalDragUpdate: onContentVerticalDragUpdate,
            onVerticalDragEnd: onContentVerticalDragEnd,
            onVerticalDragCancel: onContentVerticalDragCancel,
            child: probedTemporalContent,
          );
    Widget bodyFor(MindYearHeatmapPresentationSettings? settings) {
      final paletteStyle =
          settings?.paletteStyle ?? MindYearHeatmapPaletteStyle.fluvi;
      final scaleResolution =
          settings?.scaleResolution ?? MindHeatmapScaleResolution.ten;
      final scaleMode = settings?.scaleMode ?? MindHeatmapScaleMode.existing;
      final sliderHandleSize =
          settings?.sliderHandleSize ?? MindSliderHandleSize.normal;
      Widget bodyForScore(double score) {
        final resolvedScale = MindYearHeatmapPaletteResolver.resolveScale(
          style: paletteStyle,
          scaleResolution: scaleResolution,
          scaleMode: scaleMode,
          score: score,
        );
        final range = _MindQueryAmountRangeListener(
          valuesFor: queryAmountRange!,
          valuesChanges: queryAmountRangeChanges!,
          lifecycleChanges: queryAmountRangeLifecycleChanges,
          stateFor: queryAmountRangeState,
          errorFor: queryAmountRangeError,
          onRetry: onQueryAmountRangeRetry,
          onRangeCommitted: onQueryAmountRangeCommitted!,
          onRangePreviewChanged: onQueryAmountRangePreviewChanged,
          onInteractionStarted: onQueryAmountRangeInteractionStarted,
          onInteractionEnded: onQueryAmountRangeInteractionEnded,
          onInteractionSummary: onQueryAmountRangeInteractionSummary,
          // Mind has one physical range owner across Sum/Year/Month/Day. The
          // temporal content may vary, but its range must never fall back to the
          // standard Query-menu geometry on another TimePlane.
          compactPresentation: true,
          compactMindCenterAccessory: _MindHeatmapInlineLegend(
            style: paletteStyle,
            scaleResolution: scaleResolution,
          ),
          compactMindGradientVisualStyleFor: (context) {
            final current =
                MindHeatmapPaletteScope.maybeOf(context) ?? resolvedScale;
            return QueryAmountRangeGradientVisualStyle(
              stops: current.stops,
              visibleThumbRadius:
                  QueryAmountRangeHandleGeometry.visibleDiameterFor(
                    tenPercentSmaller:
                        sliderHandleSize ==
                        MindSliderHandleSize.tenPercentSmaller,
                  ) /
                  2,
            );
          },
        );
        return MindHeatmapPaletteTransition(
          target: resolvedScale,
          animates: scaleMode == MindHeatmapScaleMode.dynamicMixed,
          child: _MindTemporalBody(
            temporalContent: guardedTemporalContent,
            range: range,
          ),
        );
      }

      final score = behavioralScore;
      if (scaleMode != MindHeatmapScaleMode.dynamicMixed || score == null) {
        return bodyForScore(50);
      }
      return ValueListenableBuilder<MindBehavioralScoreFrame?>(
        valueListenable: score,
        builder: (context, frame, _) => bodyForScore(frame?.point.score ?? 50),
      );
    }

    final settings = yearHeatmapPresentation;
    if (settings == null) return bodyFor(null);
    return ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
      valueListenable: settings,
      builder: (context, value, _) => bodyFor(value),
    );
  }
}

/// Resolved physical silhouette for Mind's two presentation choices. Keeping
/// the seam radii explicit makes it impossible for seamless mode to devolve
/// into two independently rounded cards merely moved together.
@immutable
final class MindExpandedSurfaceShape {
  const MindExpandedSurfaceShape({
    required this.headerRadius,
    required this.contentRadius,
    required this.outerRadius,
  });

  final BorderRadius headerRadius;
  final BorderRadius contentRadius;
  final BorderRadius outerRadius;

  static MindExpandedSurfaceShape resolve({
    required bool seamless,
    required BorderRadius headerRadius,
    required BorderRadius contentRadius,
    required double expansionProgress,
  }) {
    if (!seamless) {
      return MindExpandedSurfaceShape(
        headerRadius: headerRadius,
        contentRadius: contentRadius,
        outerRadius: contentRadius,
      );
    }
    final reveal = expansionProgress.clamp(0.0, 1.0).toDouble();
    final headerTopOnly = BorderRadius.only(
      topLeft: headerRadius.topLeft,
      topRight: headerRadius.topRight,
    );
    final contentBottomOnly = BorderRadius.only(
      bottomLeft: contentRadius.bottomLeft,
      bottomRight: contentRadius.bottomRight,
    );
    return MindExpandedSurfaceShape(
      // The continuous interpolation removes the lower Header corners as its
      // second section grows, so no one-frame radius pop can expose a slit.
      headerRadius: BorderRadius.lerp(headerRadius, headerTopOnly, reveal)!,
      contentRadius: BorderRadius.lerp(
        contentRadius,
        contentBottomOnly,
        reveal,
      )!,
      outerRadius: BorderRadius.lerp(
        headerRadius,
        BorderRadius.only(
          topLeft: headerRadius.topLeft,
          topRight: headerRadius.topRight,
          bottomLeft: contentRadius.bottomLeft,
          bottomRight: contentRadius.bottomRight,
        ),
        reveal,
      )!,
    );
  }
}

/// Mind's existing analytical body rendered inside the seamless outer shell.
/// It retains the original body widget and dot content; only the container
/// relationship changes. The small gradient is a shallow, non-interactive
/// connection cue from the reactive Header to the otherwise white body.
final class _MindSeamlessBodySurface extends StatelessWidget {
  const _MindSeamlessBodySurface({
    required this.bounds,
    required this.dotsBounds,
    required this.borderRadius,
    required this.headerVisualFrame,
    this.body,
  });

  final DashboardBounds bounds;
  final DashboardBounds dotsBounds;
  final BorderRadius borderRadius;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final Widget? body;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      DashboardPlaceholderCard(
        bounds: bounds,
        fillParent: true,
        semanticKey: const ValueKey('dashboard-core-mode-mind-body'),
        borderSurface: DashboardBorderSurface.mindContent,
        borderRadiusOverride: borderRadius,
        showsDepth: false,
        showsBorder: false,
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (headerVisualFrame case final frames?)
              ValueListenableBuilder<DashboardHeaderVisualFrame>(
                valueListenable: frames,
                builder: (context, frame, _) => IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 34,
                      child: DecoratedBox(
                        key: const ValueKey('mind-seamless-header-color-bleed'),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              frame.colorB.withValues(alpha: .14),
                              frame.colorA.withValues(alpha: .04),
                              Colors.white.withValues(alpha: 0),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            body ?? const SizedBox.expand(),
          ],
        ),
      ),
      Positioned(
        left: dotsBounds.left - bounds.left,
        top: dotsBounds.top - bounds.top,
        width: dotsBounds.width,
        height: dotsBounds.height,
        child: DashboardPlaceholderDots(
          bounds: dotsBounds,
          semanticKey: const ValueKey('dashboard-core-mode-mind-dots'),
        ),
      ),
    ],
  );
}

final class _MindTemporalEntryFrameProbe<T> extends StatefulWidget {
  const _MindTemporalEntryFrameProbe({
    required this.frameListenable,
    required this.descriptorFor,
    required this.child,
    this.reporter,
    this.firstLayoutStage = 'FIRST_LAYOUT',
    this.firstPaintStage = 'FIRST_PAINT',
  });

  final ValueListenable<T?> frameListenable;
  final ({String kind, int coreRevision, String identity}) Function(T frame)
  descriptorFor;
  final MindTemporalEntryFrameStageReporter? reporter;
  final String firstLayoutStage;
  final String firstPaintStage;
  final Widget child;

  @override
  State<_MindTemporalEntryFrameProbe<T>> createState() =>
      _MindTemporalEntryFrameProbeState<T>();
}

final class _MindTemporalEntryFrameProbeState<T>
    extends State<_MindTemporalEntryFrameProbe<T>> {
  ({String kind, int coreRevision, String identity})? _lastAcknowledged;

  @override
  void initState() {
    super.initState();
    widget.frameListenable.addListener(_onFrameChanged);
    _scheduleCurrentFrameAcknowledgement();
  }

  @override
  void didUpdateWidget(covariant _MindTemporalEntryFrameProbe<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.frameListenable, widget.frameListenable)) {
      oldWidget.frameListenable.removeListener(_onFrameChanged);
      widget.frameListenable.addListener(_onFrameChanged);
      _lastAcknowledged = null;
    }
    _scheduleCurrentFrameAcknowledgement();
  }

  @override
  void dispose() {
    widget.frameListenable.removeListener(_onFrameChanged);
    super.dispose();
  }

  void _onFrameChanged() => _scheduleCurrentFrameAcknowledgement();

  void _scheduleCurrentFrameAcknowledgement() {
    final reporter = widget.reporter;
    final frame = widget.frameListenable.value;
    if (!mounted || reporter == null || frame == null) return;
    final descriptor = widget.descriptorFor(frame);
    if (_lastAcknowledged == descriptor) return;
    _lastAcknowledged = descriptor;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _currentDescriptor() != descriptor) return;
      reporter(
        stage: widget.firstLayoutStage,
        frameCoreRevision: descriptor.coreRevision,
        kind: descriptor.kind,
        frameIdentity: descriptor.identity,
      );
      // Layout has just completed for this frame. A second post-frame callback
      // acknowledges that its first actual paint opportunity also survived
      // without being replaced by a newer immutable frame.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || _currentDescriptor() != descriptor) return;
        reporter(
          stage: widget.firstPaintStage,
          frameCoreRevision: descriptor.coreRevision,
          kind: descriptor.kind,
          frameIdentity: descriptor.identity,
        );
      });
    });
  }

  ({String kind, int coreRevision, String identity})? _currentDescriptor() {
    final frame = widget.frameListenable.value;
    return frame == null ? null : widget.descriptorFor(frame);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// Semantic Header content only. It listens to score publications, never the
/// Header phase ticker, so a visual effect cannot rebuild financial text.
final class _MindHeaderScoreDetail extends StatelessWidget {
  const _MindHeaderScoreDetail({
    required this.score,
    required this.headerVisualFrame,
    required this.expansionProgress,
    required this.expandedHeaderExtraHeight,
    this.chartPresentation,
    required this.temporalContext,
    this.pointerObserver,
    this.reporter,
  });

  final ValueListenable<MindBehavioralScoreFrame?> score;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final double expansionProgress;
  final double expandedHeaderExtraHeight;
  final ValueListenable<MindHeaderScoreChartPresentationSettings>?
  chartPresentation;
  final MindHeaderScoreChartTemporalContext temporalContext;
  final MindHeaderScoreChartPointerObserver? pointerObserver;
  final MindTemporalEntryFrameStageReporter? reporter;

  @override
  Widget build(
    BuildContext context,
  ) => _MindTemporalEntryFrameProbe<MindBehavioralScoreFrame>(
    frameListenable: score,
    descriptorFor: (frame) => (
      kind: 'header',
      coreRevision: frame.identity.coreRevision,
      identity: mindTemporalEntryHeaderFrameIdentity(frame),
    ),
    reporter: reporter,
    firstLayoutStage: 'HEADER_FIRST_LAYOUT',
    firstPaintStage: 'HEADER_FIRST_PAINT',
    child: ValueListenableBuilder<MindBehavioralScoreFrame?>(
      valueListenable: score,
      builder: (context, frame, _) {
        Widget contentFor(
          bool showTimeLabels,
          DashboardHeaderVisualFrame? headerFrame,
        ) {
          final typography =
              headerFrame?.typography ?? FluviTypographyProfile.app;
          final chartLayout = DashboardHeaderTrendChartLayout(
            showsModeLabelAboveValue:
                headerFrame?.showsHeaderModeLabelAboveValue ?? false,
            extraPlotHeight: expandedHeaderExtraHeight,
          );
          final foreground =
              headerFrame?.foregroundTextColor ??
              FluviVisualTokens.textOnAction;
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (frame?.chartSeries case final chartSeries?)
                MindHeaderScoreChart(
                  series: chartSeries,
                  expansionProgress: expansionProgress,
                  showTimeLabels: showTimeLabels,
                  lineColor:
                      headerFrame?.chartColor ??
                      MindHeaderScoreChartStyle.lineColor,
                  areaFadeColor:
                      headerFrame?.chartVeilColor ??
                      MindHeaderScoreChartStyle.lineColor,
                  showsAreaFade: headerFrame?.showsChartVeil ?? true,
                  temporalContext: temporalContext,
                  pointerObserver: pointerObserver,
                  layout: chartLayout,
                ),
              if (chartLayout.showsModeLabelAboveValue)
                Positioned(
                  left: DashboardHeaderTrendChartStyle.detailLeft,
                  top: DashboardHeaderTrendChartStyle.detailTop,
                  child: Text(
                    'Mind',
                    key: const ValueKey<String>('mind-header-mode-label'),
                    style: typography.applyTo(
                      DashboardHeaderTrendChartLayout.modeLabelTextMetrics
                          .copyWith(color: foreground),
                    ),
                  ),
                ),
              Positioned(
                left: DashboardHeaderTrendChartStyle.detailLeft,
                top: chartLayout.valueTop,
                child: Text(
                  '${frame?.point.roundedScore ?? 50}/100',
                  key: const ValueKey<String>('mind-header-score-text'),
                  style: typography.applyTo(
                    DefaultTextStyle.of(context).style
                        .merge(
                          DashboardHeaderTrendChartStyle
                              .primaryValueTextMetrics,
                        )
                        .copyWith(color: foreground),
                  ),
                ),
              ),
            ],
          );
        }

        final presentation = chartPresentation;
        Widget withVisualFrame(bool showTimeLabels) {
          final frames = headerVisualFrame;
          if (frames == null) return contentFor(showTimeLabels, null);
          return ValueListenableBuilder<DashboardHeaderVisualFrame>(
            valueListenable: frames,
            builder: (context, headerFrame, _) =>
                contentFor(showTimeLabels, headerFrame),
          );
        }

        if (presentation == null) return withVisualFrame(false);
        return ValueListenableBuilder<MindHeaderScoreChartPresentationSettings>(
          valueListenable: presentation,
          builder: (context, settings, _) =>
              withVisualFrame(settings.showsTimeLabels),
        );
      },
    ),
  );
}

/// Structural Mind topology: one clipped vertical viewport followed by an
/// independent footer. The slider never overlays scroll content.
final class _MindTemporalBody extends StatelessWidget {
  const _MindTemporalBody({required this.temporalContent, required this.range});

  // The compact shared slider keeps its existing touch geometry inside this
  // measured footer. The palette legend is permanently inline between Min.
  // and Max., so the visualization has no separate legend lane.
  static const _footerHeight = 68.0;

  final Widget temporalContent;
  final Widget range;

  @override
  Widget build(BuildContext context) => Column(
    children: <Widget>[
      Expanded(
        key: const ValueKey<String>('mind-temporal-content-viewport'),
        child: ClipRect(child: temporalContent),
      ),
      KeyedSubtree(
        key: const ValueKey('mind-year-heatmap-fixed-footer'),
        child: SizedBox(height: _footerHeight, child: range),
      ),
    ],
  );
}

/// A Mind-supplied, read-only center accessory. QueryAmountRangeControl owns
/// layout and all slider behavior; it receives no palette setting or legend
/// decision, only this already-rendered presentation child.
final class _MindHeatmapInlineLegend extends StatelessWidget {
  const _MindHeatmapInlineLegend({
    required this.style,
    required this.scaleResolution,
  });

  final MindYearHeatmapPaletteStyle style;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) {
    final dynamicScale = MindHeatmapPaletteScope.maybeOf(context);
    final samples = MindYearHeatmapPaletteResolver.legendSamples(
      style,
      scaleResolution: scaleResolution,
      dynamicScale: dynamicScale,
    );
    final extent = samples.length == 10 ? 6.0 : 4.0;
    const gap = 1.0;
    final width = extent * samples.length + gap * (samples.length - 1);
    return Semantics(
      label: 'Heatmap intenzitás, alacsonytól magasig',
      readOnly: true,
      child: ExcludeSemantics(
        child: SizedBox(
          key: const ValueKey<String>('mind-heatmap-inline-legend'),
          width: width,
          height: extent,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(
              samples.length,
              (index) => Padding(
                padding: EdgeInsets.only(
                  right: index == samples.length - 1 ? 0 : gap,
                ),
                child: DecoratedBox(
                  key: ValueKey<String>('mind-heatmap-inline-swatch-$index'),
                  decoration: BoxDecoration(
                    color: samples[index].background,
                    borderRadius: BorderRadius.circular(1),
                  ),
                  child: SizedBox(width: extent, height: extent),
                ),
              ),
              growable: false,
            ),
          ),
        ),
      ),
    );
  }
}

final class _MindQueryAmountRangeListener extends StatelessWidget {
  const _MindQueryAmountRangeListener({
    required this.valuesFor,
    required this.valuesChanges,
    required this.lifecycleChanges,
    required this.stateFor,
    required this.errorFor,
    required this.onRetry,
    required this.onRangeCommitted,
    required this.onRangePreviewChanged,
    required this.onInteractionStarted,
    required this.onInteractionEnded,
    required this.onInteractionSummary,
    required this.compactPresentation,
    this.compactMindCenterAccessory,
    this.compactMindGradientVisualStyleFor,
  });

  final QueryAmountRangeValues? Function() valuesFor;
  final Listenable valuesChanges;
  final Listenable? lifecycleChanges;
  final DashboardAppliedQueryFacetLoadState Function()? stateFor;
  final Object? Function()? errorFor;
  final VoidCallback? onRetry;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onRangePreviewChanged;
  final VoidCallback? onInteractionStarted;
  final VoidCallback? onInteractionEnded;
  final ValueChanged<QueryAmountRangeInteractionSummary>? onInteractionSummary;
  final bool compactPresentation;
  final Widget? compactMindCenterAccessory;
  final QueryAmountRangeGradientVisualStyle Function(BuildContext context)?
  compactMindGradientVisualStyleFor;

  @override
  Widget build(BuildContext context) {
    Widget binding(BuildContext context) => _MindQueryAmountRangeBinding(
      valuesFor: valuesFor,
      stateFor: stateFor,
      errorFor: errorFor,
      onRetry: onRetry,
      onRangeCommitted: onRangeCommitted,
      onRangePreviewChanged: onRangePreviewChanged,
      onInteractionStarted: onInteractionStarted,
      onInteractionEnded: onInteractionEnded,
      onInteractionSummary: onInteractionSummary,
      compactPresentation: compactPresentation,
      compactMindCenterAccessory: compactMindCenterAccessory,
      compactMindGradientVisualStyleFor: compactMindGradientVisualStyleFor,
    );
    final lifecycle = lifecycleChanges;
    if (lifecycle == null) {
      return AnimatedBuilder(
        animation: valuesChanges,
        builder: (context, _) => binding(context),
      );
    }
    return AnimatedBuilder(
      animation: lifecycle,
      builder: (context, _) => AnimatedBuilder(
        animation: valuesChanges,
        builder: (context, _) => binding(context),
      ),
    );
  }
}

final class _MindQueryAmountRangeBinding extends StatefulWidget {
  const _MindQueryAmountRangeBinding({
    required this.valuesFor,
    required this.stateFor,
    required this.errorFor,
    required this.onRetry,
    required this.onRangeCommitted,
    required this.onRangePreviewChanged,
    required this.onInteractionStarted,
    required this.onInteractionEnded,
    required this.onInteractionSummary,
    required this.compactPresentation,
    this.compactMindCenterAccessory,
    this.compactMindGradientVisualStyleFor,
  });

  final QueryAmountRangeValues? Function() valuesFor;
  final DashboardAppliedQueryFacetLoadState Function()? stateFor;
  final Object? Function()? errorFor;
  final VoidCallback? onRetry;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onRangePreviewChanged;
  final VoidCallback? onInteractionStarted;
  final VoidCallback? onInteractionEnded;
  final ValueChanged<QueryAmountRangeInteractionSummary>? onInteractionSummary;
  final bool compactPresentation;
  final Widget? compactMindCenterAccessory;
  final QueryAmountRangeGradientVisualStyle Function(BuildContext context)?
  compactMindGradientVisualStyleFor;

  @override
  State<_MindQueryAmountRangeBinding> createState() =>
      _MindQueryAmountRangeBindingState();
}

final class _MindQueryAmountRangeBindingState
    extends State<_MindQueryAmountRangeBinding> {
  final GlobalKey _sliderKey = GlobalKey(debugLabel: 'mind-range-slider');
  Object? _lastSignature;
  var _sliderWasMounted = false;
  var _layoutToken = 0;

  @override
  Widget build(BuildContext context) {
    final values = widget.valuesFor();
    final lifecycle = widget.stateFor?.call();
    final error = widget.errorFor?.call();
    final signature = Object.hash(values, lifecycle, error);
    if (_lastSignature != signature) {
      _lastSignature = signature;
      _recordTransition(values: values, lifecycle: lifecycle, error: error);
    }
    if (values == null) {
      if (lifecycle == DashboardAppliedQueryFacetLoadState.failed) {
        return SizedBox(
          height: 32,
          child: FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Text(
                  'Az összeg tartomány nem tölthető be',
                  key: ValueKey('mind-query-amount-range-error'),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(width: 8),
                if (widget.onRetry case final onRetry?)
                  Semantics(
                    button: true,
                    child: GestureDetector(
                      key: const ValueKey('mind-query-amount-range-retry'),
                      onTap: onRetry,
                      child: const Text('Újrapróbálás'),
                    ),
                  ),
              ],
            ),
          ),
        );
      }
      return const Text(
        'Az összeg tartomány betöltése folyamatban',
        key: ValueKey('mind-query-amount-range-unavailable'),
      );
    }
    return KeyedSubtree(
      key: _sliderKey,
      child: QueryAmountRangeControl(
        key: const ValueKey('mind-query-amount-range'),
        values: values,
        onRangePreviewChanged: widget.onRangePreviewChanged,
        onInteractionStarted: widget.onInteractionStarted,
        onInteractionEnded: widget.onInteractionEnded,
        onInteractionSummary: widget.onInteractionSummary,
        presentation: widget.compactPresentation
            ? QueryAmountRangePresentation.compactMind
            : QueryAmountRangePresentation.standard,
        compactMindCenterAccessory: widget.compactMindCenterAccessory,
        compactMindGradientVisualStyle: widget.compactMindGradientVisualStyleFor
            ?.call(context),
        onRangeCommitted: widget.onRangeCommitted,
      ),
    );
  }

  void _recordTransition({
    required QueryAmountRangeValues? values,
    required DashboardAppliedQueryFacetLoadState? lifecycle,
    required Object? error,
  }) {
    if (!kFluviOnscreenDiagnosticsEnabled) return;
    if (values == null) {
      if (_sliderWasMounted) {
        _sliderWasMounted = false;
        _layoutToken += 1;
        FluviDiagnosticLogger.log(
          FluviDiagnosticEvent(
            stage: 'MIND|SLIDER_UNMOUNT',
            scope:
                'reason=${lifecycle == DashboardAppliedQueryFacetLoadState.failed ? 'rangeFailed' : 'canonicalDomainUnavailable'} '
                'state=${lifecycle?.name ?? 'unobserved'}',
            error: error == null ? null : '$error',
          ),
        );
      }
      return;
    }
    if (!_sliderWasMounted) {
      _sliderWasMounted = true;
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'MIND|SLIDER_MOUNT',
          scope:
              'minimum=${values.minimumScaled100} '
              'maximum=${values.maximumScaled100} '
              'lower=${values.lowerScaled100} '
              'upper=${values.upperScaled100} '
              'state=${lifecycle?.name ?? 'unobserved'}',
        ),
      );
    }
    final token = ++_layoutToken;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || token != _layoutToken) return;
      final renderObject = _sliderKey.currentContext?.findRenderObject();
      if (renderObject is! RenderBox || !renderObject.hasSize) return;
      final origin = renderObject.localToGlobal(Offset.zero);
      final bounds = origin & renderObject.size;
      final parent = renderObject.parent;
      final parentBounds = parent is RenderBox && parent.hasSize
          ? parent.paintBounds
          : null;
      final scope =
          'bounds=${_rect(bounds)} '
          'paintBounds=${_rect(renderObject.paintBounds.shift(origin))} '
          'parentPaintBounds=${parentBounds == null ? '-' : _rect(parentBounds)} '
          'minimum=${values.minimumScaled100} '
          'maximum=${values.maximumScaled100}';
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(stage: 'MIND|SLIDER_LAYOUT', scope: scope),
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(stage: 'MIND|SLIDER_VISIBLE', scope: scope),
      );
    });
  }

  static String _rect(Rect value) =>
      '${value.left.toStringAsFixed(1)},${value.top.toStringAsFixed(1)} '
      '${value.width.toStringAsFixed(1)}x${value.height.toStringAsFixed(1)}';
}
