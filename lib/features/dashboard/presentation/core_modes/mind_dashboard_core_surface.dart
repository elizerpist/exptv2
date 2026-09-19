import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../core/diagnostics/fluvi_onscreen_diagnostics.dart';
import '../../query/domain/query_amount_range.dart';
import '../../query/application/dashboard_applied_query_facet_loader.dart';
import '../../query/presentation/query_amount_range_control.dart';
import '../../mind/domain/mind_year_heatmap_projection.dart';
import '../../mind/domain/mind_temporal_heatmap_frame.dart';
import '../../mind/domain/mind_year_heatmap_presentation_settings.dart';
import '../../mind/domain/mind_behavioral_score_projection.dart';
import '../../mind/domain/mind_header_score_chart_presentation.dart';
import '../../mind/presentation/mind_header_score_chart.dart';
import '../../mind/presentation/mind_year_heatmap_palette_resolver.dart';
import '../../mind/presentation/mind_year_heatmap_viewport.dart';
import '../../mind/presentation/mind_temporal_heatmap_viewports.dart';
import '../../time_navigation/domain/time_plane.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

/// Mind owns one merged body surface spanning the central unified envelope.
class MindDashboardCoreSurface extends StatelessWidget {
  const MindDashboardCoreSurface({
    super.key,
    required this.presentation,
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
  });

  final DashboardCoreModePresentation presentation;
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

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    final bodyBounds = geometry.unifiedSubheaderBounds!;
    return KeyedSubtree(
      key: const ValueKey('dashboard-core-mode-mind'),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
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
          DashboardCoreModeOpacityPosition(
            bounds: geometry.zone2IndicatorBounds,
            opacity: geometry.zone2Opacity,
            offset: Offset(0, geometry.zone2Shift),
            child: DashboardPlaceholderDots(
              bounds: geometry.zone2IndicatorBounds,
              semanticKey: const ValueKey('dashboard-core-mode-mind-dots'),
            ),
          ),
          DashboardCoreModeHeaderScaffold(
            bounds: geometry.headerBounds,
            surfaceColor: presentation.palette.upcomingHeaderTone,
            headerKey: const ValueKey('dashboard-core-mode-mind-header'),
            labelKey: const ValueKey('dashboard-core-mode-label-mind'),
            label: 'mind',
            visualController: headerVisualController,
            visualFrameListenable: headerVisualFrame,
            detailLeft: 0,
            detailTop: 0,
            detailRight: 0,
            detailBottom: 0,
            detail: behavioralScore == null
                ? null
                : _MindHeaderScoreDetail(
                    score: behavioralScore!,
                    expansionProgress: geometry.headerExpansionProgress,
                    chartPresentation: headerScoreChartPresentation,
                  ),
          ),
        ],
      ),
    );
  }

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
    final guardedTemporalContent = temporalViewportOwnsVerticalDrag
        ? temporalContent
        : GestureDetector(
            key: const ValueKey('dashboard-core-mode-content-gesture-region'),
            behavior: HitTestBehavior.translucent,
            dragStartBehavior: DragStartBehavior.down,
            onVerticalDragStart: onContentVerticalDragStart,
            onVerticalDragUpdate: onContentVerticalDragUpdate,
            onVerticalDragEnd: onContentVerticalDragEnd,
            onVerticalDragCancel: onContentVerticalDragCancel,
            child: temporalContent,
          );
    Widget bodyFor(MindYearHeatmapPresentationSettings? settings) {
      final showInlineLegend =
          settings?.showHeatmapLegend == true &&
          settings?.legendPlacement ==
              MindHeatmapLegendPlacement.inlineBetweenRangeValues;
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
        compactMindCenterAccessory: showInlineLegend
            ? _MindHeatmapInlineLegend(
                style: settings!.paletteStyle,
                scaleResolution: settings.scaleResolution,
              )
            : null,
      );
      return _MindTemporalBody(
        temporalContent: guardedTemporalContent,
        range: range,
        presentationSettings: settings,
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

/// Semantic Header content only. It listens to score publications, never the
/// Header phase ticker, so a visual effect cannot rebuild financial text.
final class _MindHeaderScoreDetail extends StatelessWidget {
  const _MindHeaderScoreDetail({
    required this.score,
    required this.expansionProgress,
    this.chartPresentation,
  });

  final ValueListenable<MindBehavioralScoreFrame?> score;
  final double expansionProgress;
  final ValueListenable<MindHeaderScoreChartPresentationSettings>?
  chartPresentation;

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<MindBehavioralScoreFrame?>(
    valueListenable: score,
    builder: (context, frame, _) {
      Widget contentFor(bool showTimeLabels) => Stack(
        fit: StackFit.expand,
        children: <Widget>[
          if (frame?.chartSeries case final chartSeries?)
            MindHeaderScoreChart(
              series: chartSeries,
              expansionProgress: expansionProgress,
              showTimeLabels: showTimeLabels,
            ),
          Positioned(
            left: 16,
            top: 16,
            child: Text(
              '${frame?.point.roundedScore ?? 50}/100',
              key: const ValueKey<String>('mind-header-score-text'),
              style: DefaultTextStyle.of(context).style.copyWith(
                color: FluviVisualTokens.textOnAction,
                fontSize: 19,
                height: .96,
                letterSpacing: -.76,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      );
      final presentation = chartPresentation;
      if (presentation == null) return contentFor(false);
      return ValueListenableBuilder<MindHeaderScoreChartPresentationSettings>(
        valueListenable: presentation,
        builder: (context, settings, _) => contentFor(settings.showsTimeLabels),
      );
    },
  );
}

/// Structural Mind topology: one clipped vertical viewport followed by an
/// independent footer. The slider never overlays scroll content.
final class _MindTemporalBody extends StatelessWidget {
  const _MindTemporalBody({
    required this.temporalContent,
    required this.range,
    this.presentationSettings,
  });

  // The compact shared slider keeps its existing touch geometry inside this
  // measured footer. The above-slider legend is intentionally a separate,
  // smaller presentation lane; inline mode reserves none here.
  static const _footerHeight = 68.0;
  static const _legendHeight = 16.0;

  final Widget temporalContent;
  final Widget range;
  final MindYearHeatmapPresentationSettings? presentationSettings;

  @override
  Widget build(BuildContext context) {
    final settings = presentationSettings;
    final showAboveLegend =
        (settings?.showHeatmapLegend ?? true) &&
        (settings?.legendPlacement ?? MindHeatmapLegendPlacement.aboveSlider) ==
            MindHeatmapLegendPlacement.aboveSlider;
    return Column(
      children: <Widget>[
        Expanded(
          key: const ValueKey<String>('mind-temporal-content-viewport'),
          child: ClipRect(child: temporalContent),
        ),
        if (showAboveLegend)
          SizedBox(
            key: const ValueKey<String>('mind-heatmap-legend-lane'),
            height: _legendHeight,
            child: _MindHeatmapPaletteLegend(
              style:
                  settings?.paletteStyle ?? MindYearHeatmapPaletteStyle.fluvi,
              scaleResolution:
                  settings?.scaleResolution ?? MindHeatmapScaleResolution.ten,
            ),
          ),
        KeyedSubtree(
          key: const ValueKey('mind-year-heatmap-fixed-footer'),
          child: SizedBox(height: _footerHeight, child: range),
        ),
      ],
    );
  }
}

/// Fixed, quiet presentation of the selected authored palette positions.
/// It sits outside the temporal viewport and delegates every color choice to
/// the same resolver that paints heatmap cells.
final class _MindHeatmapPaletteLegend extends StatelessWidget {
  const _MindHeatmapPaletteLegend({
    required this.style,
    required this.scaleResolution,
  });

  final MindYearHeatmapPaletteStyle style;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) {
    final samples = MindYearHeatmapPaletteResolver.legendSamples(
      style,
      scaleResolution: scaleResolution,
    );
    return Semantics(
      label: 'Heatmap intenzitás, alacsonytól magasig',
      readOnly: true,
      child: ExcludeSemantics(
        child: Align(
          alignment: Alignment.center,
          child: SizedBox(
            key: const ValueKey<String>('mind-heatmap-palette-legend'),
            height: 10,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List<Widget>.generate(
                samples.length,
                (index) => Padding(
                  padding: EdgeInsets.only(
                    right: index == samples.length - 1 ? 0 : 2,
                  ),
                  child: DecoratedBox(
                    key: ValueKey<String>('mind-heatmap-palette-swatch-$index'),
                    decoration: BoxDecoration(
                      color: samples[index].background,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: const SizedBox(width: 12, height: 10),
                  ),
                ),
                growable: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
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
    final samples = MindYearHeatmapPaletteResolver.legendSamples(
      style,
      scaleResolution: scaleResolution,
    );
    final extent = scaleResolution == MindHeatmapScaleResolution.ten
        ? 6.0
        : 4.0;
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
