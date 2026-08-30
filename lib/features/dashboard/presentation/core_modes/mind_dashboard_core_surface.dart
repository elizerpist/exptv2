import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../../../core/diagnostics/fluvi_onscreen_diagnostics.dart';
import '../../query/domain/query_amount_range.dart';
import '../../query/application/dashboard_applied_query_facet_loader.dart';
import '../../query/presentation/query_amount_range_control.dart';
import '../widgets/dashboard_placeholder_card.dart';
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
    this.onQueryAmountRangeRetry,
    this.onQueryAmountRangeCommitted,
    this.onQueryAmountRangePreviewChanged,
    this.onQueryAmountRangeInteractionStarted,
    this.onQueryAmountRangeInteractionEnded,
    this.headerVisualController,
    this.headerVisualFrame,
  });

  final DashboardCoreModePresentation presentation;
  final QueryAmountRangeValues? Function()? queryAmountRange;
  final Listenable? queryAmountRangeChanges;
  final Listenable? queryAmountRangeLifecycleChanges;
  final DashboardAppliedQueryFacetLoadState Function()? queryAmountRangeState;
  final Object? Function()? queryAmountRangeError;
  final VoidCallback? onQueryAmountRangeRetry;
  final ValueChanged<QueryAmountRangeValues>? onQueryAmountRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onQueryAmountRangePreviewChanged;
  final VoidCallback? onQueryAmountRangeInteractionStarted;
  final VoidCallback? onQueryAmountRangeInteractionEnded;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

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
              child:
                  queryAmountRange == null ||
                      queryAmountRangeChanges == null ||
                      onQueryAmountRangeCommitted == null
                  ? null
                  : Align(
                      alignment: Alignment.bottomCenter,
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(18, 12, 18, 16),
                        child: _MindQueryAmountRangeListener(
                          valuesFor: queryAmountRange!,
                          valuesChanges: queryAmountRangeChanges!,
                          lifecycleChanges: queryAmountRangeLifecycleChanges,
                          stateFor: queryAmountRangeState,
                          errorFor: queryAmountRangeError,
                          onRetry: onQueryAmountRangeRetry,
                          onRangeCommitted: onQueryAmountRangeCommitted!,
                          onRangePreviewChanged:
                              onQueryAmountRangePreviewChanged,
                          onInteractionStarted:
                              onQueryAmountRangeInteractionStarted,
                          onInteractionEnded:
                              onQueryAmountRangeInteractionEnded,
                        ),
                      ),
                    ),
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
          ),
        ],
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
  });

  final QueryAmountRangeValues? Function() valuesFor;
  final DashboardAppliedQueryFacetLoadState Function()? stateFor;
  final Object? Function()? errorFor;
  final VoidCallback? onRetry;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onRangePreviewChanged;
  final VoidCallback? onInteractionStarted;
  final VoidCallback? onInteractionEnded;

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
