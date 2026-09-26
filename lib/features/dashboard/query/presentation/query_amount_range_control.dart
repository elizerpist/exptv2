import 'package:flutter/material.dart';

import '../../../../core/diagnostics/fluvi_onscreen_diagnostics.dart';
import '../../motion/dashboard_display_frame_coalescer.dart';
import '../domain/query_amount_range.dart';
import 'query_menu_formatters.dart';
import 'query_menu_tokens.dart';

/// One bounded, per-drag input-to-preview timing record.
///
/// This belongs to the reusable Range control because it observes the raw
/// pointer, RangeSlider recognizer and display-frame coalescer without making
/// a Dashboard controller own a second gesture path. Hosts may correlate the
/// record with their own publication/paint diagnostics; this model carries no
/// query or transaction data.
@immutable
final class QueryAmountRangeInteractionSummary {
  const QueryAmountRangeInteractionSummary({
    required this.pointerId,
    required this.rawPointerObserved,
    required this.pointerToRecognizerMicros,
    required this.pointerToFirstValueChangeMicros,
    required this.pointerToFirstPreviewPublicationMicros,
    required this.interactionMicros,
    required this.valueChangeCount,
    required this.unchangedValueCount,
    required this.previewRequestCount,
    required this.previewPublicationCount,
    required this.coalescedPreviewCount,
    required this.finalValues,
  });

  final int? pointerId;
  final bool rawPointerObserved;
  final int? pointerToRecognizerMicros;
  final int? pointerToFirstValueChangeMicros;
  final int? pointerToFirstPreviewPublicationMicros;
  final int interactionMicros;
  final int valueChangeCount;
  final int unchangedValueCount;
  final int previewRequestCount;
  final int previewPublicationCount;
  final int coalescedPreviewCount;
  final QueryAmountRangeValues finalValues;
}

/// Placement-only presentation choice for the one shared range authority.
///
/// Query Menu retains [standard]. Mind uses [compactMind] inside its fixed
/// footer; neither presentation owns separate range or commit semantics.
enum QueryAmountRangePresentation { standard, compactMind }

/// Paint-only gradient treatment for the compact Mind host. The reusable
/// control stays unaware of score/heatmap/domain semantics.
@immutable
final class QueryAmountRangeGradientVisualStyle {
  const QueryAmountRangeGradientVisualStyle({
    required this.stops,
    required this.visibleThumbRadius,
  }) : assert(stops.length >= 2);

  final List<Color> stops;
  final double visibleThumbRadius;
}

/// One normalized active-segment geometry. A palette percentage belongs to
/// this rect, never to an absolute screen x-coordinate.
@immutable
final class QueryAmountRangeGradientGeometry {
  const QueryAmountRangeGradientGeometry._({
    required this.activeRect,
    required this.gradientRect,
    required this.startHandleColor,
    required this.endHandleColor,
  });

  final Rect activeRect;
  final Rect gradientRect;
  final Color startHandleColor;
  final Color endHandleColor;

  static QueryAmountRangeGradientGeometry resolve({
    required Rect trackRect,
    required double startFraction,
    required double endFraction,
    required List<Color> stops,
  }) {
    final start = startFraction.clamp(0.0, 1.0).toDouble();
    final end = endFraction.clamp(start, 1.0).toDouble();
    final active = Rect.fromLTRB(
      trackRect.left + trackRect.width * start,
      trackRect.top,
      trackRect.left + trackRect.width * end,
      trackRect.bottom,
    );
    return QueryAmountRangeGradientGeometry._(
      activeRect: active,
      gradientRect: active,
      startHandleColor: stops.first,
      endHandleColor: stops.last,
    );
  }
}

abstract final class QueryAmountRangeHandleGeometry {
  static const normalVisibleDiameter = 20.0;
  static const minimumHitDiameter = normalVisibleDiameter;

  static double visibleDiameterFor({required bool tenPercentSmaller}) =>
      tenPercentSmaller ? normalVisibleDiameter * .9 : normalVisibleDiameter;
}

/// The shared Query-menu/Mind amount range renderer.
///
/// Raw pointer feedback belongs to this narrow local state. A canonical Query
/// mutation occurs only at [onRangeCommitted], exactly once per completed
/// drag, so neither host can put repository work on the move path.
final class QueryAmountRangeControl extends StatefulWidget {
  const QueryAmountRangeControl({
    super.key,
    required this.values,
    required this.onRangeCommitted,
    this.onRangePreviewChanged,
    this.onInteractionStarted,
    this.onInteractionEnded,
    this.onInteractionSummary,
    this.presentation = QueryAmountRangePresentation.standard,
    this.compactMindCenterAccessory,
    this.compactMindGradientVisualStyle,
    this.enableInteractionDiagnostics = kFluviOnscreenDiagnosticsEnabled,
    this.previewScheduler,
  });

  final QueryAmountRangeValues values;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onRangePreviewChanged;
  final VoidCallback? onInteractionStarted;
  final VoidCallback? onInteractionEnded;
  final ValueChanged<QueryAmountRangeInteractionSummary>? onInteractionSummary;
  final QueryAmountRangePresentation presentation;

  /// An inert Mind-owned visual placed between compact Min./Max. values.
  /// Standard Query rendering deliberately ignores this presentation hook.
  final Widget? compactMindCenterAccessory;
  final QueryAmountRangeGradientVisualStyle? compactMindGradientVisualStyle;

  /// The physical diagnostic APK opts in to the bounded pointer pipeline.
  /// A normal release keeps the established RangeSlider path free of its
  /// passive Listener, Stopwatch and per-drag accounting.
  final bool enableInteractionDiagnostics;

  /// Testable pre-display-frame scheduler. Production defaults to the shared
  /// Dashboard scheduler; this is not a widget-local timer or post-frame lane.
  final DashboardDisplayFrameScheduler? previewScheduler;

  @override
  State<QueryAmountRangeControl> createState() =>
      _QueryAmountRangeControlState();
}

final class _QueryAmountRangeControlState
    extends State<QueryAmountRangeControl> {
  late RangeValues _localValues;
  late final DashboardDisplayFrameCoalescer<QueryAmountRangeValues>
  _previewCoalescer;
  var _dragActive = false;
  Stopwatch? _interactionStopwatch;
  int? _pointerId;
  var _rawPointerObserved = false;
  int? _recognizerMicros;
  int? _firstValueChangeMicros;
  int? _firstPreviewPublicationMicros;
  QueryAmountRangeValues? _lastChangedValues;
  var _valueChangeCount = 0;
  var _unchangedValueCount = 0;
  var _previewRequestCountAtStart = 0;
  var _previewPublicationCountAtStart = 0;
  var _coalescedPreviewCountAtStart = 0;

  bool get _collectInteractionDiagnostics =>
      widget.enableInteractionDiagnostics &&
      widget.onInteractionSummary != null;

  @override
  void initState() {
    super.initState();
    _localValues = _initialValues(widget.values);
    _previewCoalescer = DashboardDisplayFrameCoalescer<QueryAmountRangeValues>(
      scheduler:
          widget.previewScheduler ?? FlutterDashboardDisplayFrameScheduler(),
      publish: (values) {
        if (!mounted) return;
        if (_collectInteractionDiagnostics) {
          _firstPreviewPublicationMicros ??= _elapsedMicros;
        }
        widget.onRangePreviewChanged?.call(values);
      },
    );
  }

  @override
  void didUpdateWidget(covariant QueryAmountRangeControl oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragActive && oldWidget.values != widget.values) {
      _localValues = _initialValues(widget.values);
    }
  }

  static RangeValues _initialValues(QueryAmountRangeValues values) =>
      RangeValues(
        values.lowerScaled100.toDouble(),
        values.upperScaled100.toDouble(),
      );

  int get _elapsedMicros => _interactionStopwatch?.elapsedMicroseconds ?? 0;

  void _beginInteractionTrace({int? pointerId, required bool rawPointer}) {
    if (!_collectInteractionDiagnostics) return;
    _interactionStopwatch = Stopwatch()..start();
    _pointerId = pointerId;
    _rawPointerObserved = rawPointer;
    _recognizerMicros = null;
    _firstValueChangeMicros = null;
    _firstPreviewPublicationMicros = null;
    _lastChangedValues = null;
    _valueChangeCount = 0;
    _unchangedValueCount = 0;
    _previewRequestCountAtStart = _previewCoalescer.requestCount;
    _previewPublicationCountAtStart = _previewCoalescer.publishCount;
    _coalescedPreviewCountAtStart = _previewCoalescer.coalescedTargetCount;
  }

  void _onRawPointerDown(PointerDownEvent event) {
    if (!_collectInteractionDiagnostics || _dragActive) return;
    _beginInteractionTrace(pointerId: event.pointer, rawPointer: true);
  }

  void _emitInteractionSummary(QueryAmountRangeValues finalValues) {
    if (!_collectInteractionDiagnostics) return;
    final stopwatch = _interactionStopwatch;
    if (stopwatch == null) return;
    stopwatch.stop();
    widget.onInteractionSummary?.call(
      QueryAmountRangeInteractionSummary(
        pointerId: _pointerId,
        rawPointerObserved: _rawPointerObserved,
        pointerToRecognizerMicros: _recognizerMicros,
        pointerToFirstValueChangeMicros: _firstValueChangeMicros,
        pointerToFirstPreviewPublicationMicros: _firstPreviewPublicationMicros,
        interactionMicros: stopwatch.elapsedMicroseconds,
        valueChangeCount: _valueChangeCount,
        unchangedValueCount: _unchangedValueCount,
        previewRequestCount:
            _previewCoalescer.requestCount - _previewRequestCountAtStart,
        previewPublicationCount:
            _previewCoalescer.publishCount - _previewPublicationCountAtStart,
        coalescedPreviewCount:
            _previewCoalescer.coalescedTargetCount -
            _coalescedPreviewCountAtStart,
        finalValues: finalValues,
      ),
    );
    _interactionStopwatch = null;
    _pointerId = null;
  }

  void _schedulePreview(QueryAmountRangeValues values) {
    if (widget.onRangePreviewChanged == null) return;
    _previewCoalescer.request(values);
  }

  void _flushPreview() => _previewCoalescer.flush();

  Widget _buildRangeSlider({
    required QueryAmountRangeValues values,
    required RangeValues local,
    required double maximum,
  }) {
    final slider = RangeSlider(
      key: const ValueKey('query-amount-range-slider'),
      values: local,
      min: values.minimumScaled100.toDouble(),
      max: maximum,
      onChangeStart: values.isActionable
          ? (_) {
              if (_collectInteractionDiagnostics &&
                  _interactionStopwatch == null) {
                _beginInteractionTrace(pointerId: null, rawPointer: false);
              }
              if (_collectInteractionDiagnostics) {
                _recognizerMicros ??= _elapsedMicros;
              }
              _dragActive = true;
              widget.onInteractionStarted?.call();
            }
          : null,
      onChanged: values.isActionable
          ? (next) {
              final normalized = values.fromRawRange(
                lower: next.start.round(),
                upper: next.end.round(),
              );
              if (_collectInteractionDiagnostics) {
                if (_lastChangedValues == normalized) {
                  _unchangedValueCount += 1;
                } else {
                  _lastChangedValues = normalized;
                  _valueChangeCount += 1;
                  _firstValueChangeMicros ??= _elapsedMicros;
                }
              }
              // Both visible thumbs use the exact value emitted to the live
              // preview/terminal commit lanes. This keeps the adaptive nice
              // monetary snap physically honest while the pointer is down.
              setState(
                () => _localValues = RangeValues(
                  normalized.lowerScaled100.toDouble(),
                  normalized.upperScaled100.toDouble(),
                ),
              );
              _schedulePreview(normalized);
            }
          : null,
      onChangeEnd: values.isActionable
          ? (next) {
              _dragActive = false;
              final committed = values.fromRawRange(
                lower: next.start.round(),
                upper: next.end.round(),
              );
              _flushPreview();
              _emitInteractionSummary(committed);
              widget.onInteractionEnded?.call();
              widget.onRangeCommitted(committed);
            }
          : null,
    );
    if (!_collectInteractionDiagnostics) return slider;
    return Listener(
      key: const ValueKey('query-amount-range-pointer-probe'),
      behavior: HitTestBehavior.deferToChild,
      onPointerDown: _onRawPointerDown,
      child: slider,
    );
  }

  @override
  void dispose() {
    _previewCoalescer.discardPendingTarget();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final values = widget.values;
    final maximum = values.isActionable
        ? values.maximumScaled100.toDouble()
        : values.minimumScaled100.toDouble() + 1;
    final local = RangeValues(
      _localValues.start.clamp(values.minimumScaled100.toDouble(), maximum),
      _localValues.end.clamp(
        _localValues.start.clamp(values.minimumScaled100.toDouble(), maximum),
        maximum,
      ),
    );
    final gradientStyle =
        widget.presentation == QueryAmountRangePresentation.compactMind
        ? widget.compactMindGradientVisualStyle
        : null;
    final sliderTheme = SliderTheme.of(context).copyWith(
      activeTrackColor: QueryMenuTokens.selectionEnd,
      inactiveTrackColor: QueryMenuTokens.controlSurface,
      rangeThumbShape: gradientStyle == null
          ? const RoundRangeSliderThumbShape(enabledThumbRadius: 10)
          : QueryAmountRangeGradientThumbShape(
              startColor: gradientStyle.stops.first,
              endColor: gradientStyle.stops.last,
              enabledThumbRadius: gradientStyle.visibleThumbRadius,
            ),
      rangeTrackShape: gradientStyle == null
          ? const RoundedRectRangeSliderTrackShape()
          : QueryAmountRangeGradientTrackShape(stops: gradientStyle.stops),
      overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
    );
    final slider = _buildRangeSlider(
      values: values,
      local: local,
      maximum: maximum,
    );
    return Material(
      type: MaterialType.transparency,
      child: switch (widget.presentation) {
        QueryAmountRangePresentation.standard => _StandardAmountRangeSurface(
          sliderTheme: sliderTheme,
          slider: slider,
          lower: local.start.round(),
          upper: local.end.round(),
        ),
        QueryAmountRangePresentation.compactMind =>
          _CompactMindAmountRangeSurface(
            sliderTheme: sliderTheme,
            slider: slider,
            lower: local.start.round(),
            upper: local.end.round(),
            centerAccessory: widget.compactMindCenterAccessory,
          ),
      },
    );
  }
}

final class QueryAmountRangeGradientTrackShape extends RangeSliderTrackShape
    with BaseRangeSliderTrackShape {
  const QueryAmountRangeGradientTrackShape({required this.stops});

  final List<Color> stops;

  @override
  void paint(
    PaintingContext context,
    Offset offset, {
    required RenderBox parentBox,
    required SliderThemeData sliderTheme,
    required Animation<double> enableAnimation,
    required Offset startThumbCenter,
    required Offset endThumbCenter,
    bool isEnabled = false,
    bool isDiscrete = false,
    required TextDirection textDirection,
  }) {
    final track = getPreferredRect(
      parentBox: parentBox,
      offset: offset,
      sliderTheme: sliderTheme,
      isEnabled: isEnabled,
      isDiscrete: isDiscrete,
    );
    final left = textDirection == TextDirection.ltr
        ? startThumbCenter.dx
        : endThumbCenter.dx;
    final right = textDirection == TextDirection.ltr
        ? endThumbCenter.dx
        : startThumbCenter.dx;
    final inactivePaint = Paint()..color = sliderTheme.inactiveTrackColor!;
    final radius = Radius.circular(track.height / 2);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(track.left, track.top, left, track.bottom),
        radius,
      ),
      inactivePaint,
    );
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTRB(right, track.top, track.right, track.bottom),
        radius,
      ),
      inactivePaint,
    );
    final active = Rect.fromLTRB(left, track.top - 1, right, track.bottom + 1);
    if (active.width <= 0) return;
    final paint = Paint()
      ..shader = LinearGradient(colors: stops).createShader(active);
    context.canvas.drawRRect(
      RRect.fromRectAndRadius(active, Radius.circular(active.height / 2)),
      paint,
    );
  }

  @override
  bool get isRounded => true;
}

final class QueryAmountRangeGradientThumbShape extends RangeSliderThumbShape {
  const QueryAmountRangeGradientThumbShape({
    required this.startColor,
    required this.endColor,
    required this.enabledThumbRadius,
  });

  final Color startColor;
  final Color endColor;
  final double enabledThumbRadius;

  @override
  Size getPreferredSize(bool isEnabled, bool isDiscrete) => Size.fromRadius(
    enabledThumbRadius < QueryAmountRangeHandleGeometry.minimumHitDiameter / 2
        ? QueryAmountRangeHandleGeometry.minimumHitDiameter / 2
        : enabledThumbRadius,
  );

  @override
  void paint(
    PaintingContext context,
    Offset center, {
    required Animation<double> activationAnimation,
    required Animation<double> enableAnimation,
    bool isDiscrete = false,
    bool isEnabled = false,
    bool? isOnTop,
    required SliderThemeData sliderTheme,
    TextDirection? textDirection,
    Thumb? thumb,
    bool? isPressed,
  }) {
    final radius = enabledThumbRadius * enableAnimation.value;
    final color = thumb == Thumb.end ? endColor : startColor;
    final path = Path()
      ..addOval(Rect.fromCircle(center: center, radius: radius));
    context.canvas.drawShadow(
      path,
      Colors.black,
      isPressed == true ? 3 : 1,
      true,
    );
    context.canvas.drawCircle(center, radius, Paint()..color = color);
  }
}

final class _StandardAmountRangeSurface extends StatelessWidget {
  const _StandardAmountRangeSurface({
    required this.sliderTheme,
    required this.slider,
    required this.lower,
    required this.upper,
  });

  final SliderThemeData sliderTheme;
  final Widget slider;
  final int lower;
  final int upper;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('query-amount-range-control'),
    margin: const EdgeInsets.fromLTRB(14, 0, 14, 14),
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(19)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Összeg',
          style: TextStyle(
            color: QueryMenuTokens.textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: <Widget>[
            Expanded(
              child: _AmountValue(
                label: 'Minimum',
                value: QueryMenuFormatters.money(lower),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _AmountValue(
                label: 'Maximum',
                value: QueryMenuFormatters.money(upper),
                alignEnd: true,
              ),
            ),
          ],
        ),
        SliderTheme(data: sliderTheme, child: slider),
      ],
    ),
  );
}

final class _CompactMindAmountRangeSurface extends StatelessWidget {
  const _CompactMindAmountRangeSurface({
    required this.sliderTheme,
    required this.slider,
    required this.lower,
    required this.upper,
    this.centerAccessory,
  });

  final SliderThemeData sliderTheme;
  final Widget slider;
  final int lower;
  final int upper;
  final Widget? centerAccessory;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey('query-amount-range-control'),
    margin: const EdgeInsets.fromLTRB(10, 0, 10, 8),
    padding: const EdgeInsets.fromLTRB(12, 3, 12, 1),
    decoration: const BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        SizedBox(
          height: 34,
          child: SliderTheme(data: sliderTheme, child: slider),
        ),
        Row(
          children: <Widget>[
            Expanded(
              child: _CompactAmountValue(
                label: 'Min.',
                value: QueryMenuFormatters.money(lower),
              ),
            ),
            if (centerAccessory case final accessory?)
              Padding(
                key: const ValueKey<String>(
                  'mind-query-amount-range-center-accessory',
                ),
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: accessory,
              )
            else
              const SizedBox(width: 8),
            Expanded(
              child: _CompactAmountValue(
                label: 'Max.',
                value: QueryMenuFormatters.money(upper),
                alignEnd: true,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

final class _AmountValue extends StatelessWidget {
  const _AmountValue({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: alignEnd
        ? CrossAxisAlignment.end
        : CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(
          color: QueryMenuTokens.textSecondary,
          fontSize: 9,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          color: QueryMenuTokens.textPrimary,
          fontSize: 13,
          fontWeight: FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _CompactAmountValue extends StatelessWidget {
  const _CompactAmountValue({
    required this.label,
    required this.value,
    this.alignEnd = false,
  });

  final String label;
  final String value;
  final bool alignEnd;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    mainAxisAlignment: alignEnd
        ? MainAxisAlignment.end
        : MainAxisAlignment.start,
    children: <Widget>[
      Text(
        label,
        style: const TextStyle(
          color: QueryMenuTokens.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(width: 3),
      Flexible(
        child: Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: alignEnd ? TextAlign.end : TextAlign.start,
          style: const TextStyle(
            color: QueryMenuTokens.textPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}
