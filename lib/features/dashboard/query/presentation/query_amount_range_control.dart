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
    this.enableInteractionDiagnostics = kFluviOnscreenDiagnosticsEnabled,
    this.previewScheduler,
  });

  final QueryAmountRangeValues values;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;
  final ValueChanged<QueryAmountRangeValues>? onRangePreviewChanged;
  final VoidCallback? onInteractionStarted;
  final VoidCallback? onInteractionEnded;
  final ValueChanged<QueryAmountRangeInteractionSummary>? onInteractionSummary;

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
              setState(() => _localValues = next);
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
    return Material(
      type: MaterialType.transparency,
      child: Container(
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
                    value: QueryMenuFormatters.money(local.start.round()),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AmountValue(
                    label: 'Maximum',
                    value: QueryMenuFormatters.money(local.end.round()),
                    alignEnd: true,
                  ),
                ),
              ],
            ),
            SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: QueryMenuTokens.selectionEnd,
                inactiveTrackColor: QueryMenuTokens.controlSurface,
                rangeThumbShape: const RoundRangeSliderThumbShape(
                  enabledThumbRadius: 10,
                ),
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
              ),
              child: _buildRangeSlider(
                values: values,
                local: local,
                maximum: maximum,
              ),
            ),
          ],
        ),
      ),
    );
  }
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
