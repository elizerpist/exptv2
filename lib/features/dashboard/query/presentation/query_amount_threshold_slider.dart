import 'package:flutter/material.dart';

import '../domain/query_amount_threshold.dart';
import 'query_menu_formatters.dart';
import 'query_menu_tokens.dart';

/// Reusable direct-manipulation view for the one canonical Query threshold.
///
/// Pixel motion is local to this state object. Only [onValueCommitted] crosses
/// the semantic Query boundary, preserving the existing Query-menu policy of
/// one resolution at the end of a slider gesture.
final class QueryAmountThresholdSlider extends StatefulWidget {
  const QueryAmountThresholdSlider({
    super.key,
    required this.bounds,
    required this.onValueCommitted,
    this.semanticPrefix = 'Összegküszöb',
  });

  final QueryAmountThresholdBounds bounds;
  final ValueChanged<int> onValueCommitted;
  final String semanticPrefix;

  @override
  State<QueryAmountThresholdSlider> createState() =>
      _QueryAmountThresholdSliderState();
}

final class _QueryAmountThresholdSliderState
    extends State<QueryAmountThresholdSlider> {
  late double _localValue;
  var _dragActive = false;

  @override
  void initState() {
    super.initState();
    _localValue = widget.bounds.valueScaled100.toDouble();
  }

  @override
  void didUpdateWidget(covariant QueryAmountThresholdSlider oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_dragActive &&
        (oldWidget.bounds.minimumScaled100 != widget.bounds.minimumScaled100 ||
            oldWidget.bounds.maximumScaled100 !=
                widget.bounds.maximumScaled100 ||
            oldWidget.bounds.valueScaled100 != widget.bounds.valueScaled100)) {
      _localValue = widget.bounds.valueScaled100.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final bounds = widget.bounds;
    final minimum = bounds.minimumScaled100.toDouble();
    // Flutter's Slider needs a non-zero numeric interval even when the
    // canonical data domain has no amount above the 1000 HUF floor. Keep the
    // semantic bound unchanged and simply render a disabled single-position
    // control in that state.
    final maximum = bounds.maximumScaled100 <= bounds.minimumScaled100
        ? minimum + 1
        : bounds.maximumScaled100.toDouble();
    final value = _localValue.clamp(minimum, maximum).toDouble();
    return Semantics(
      label:
          '${widget.semanticPrefix}: ${QueryMenuFormatters.money(value.round())}',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              const Text(
                'Összegküszöb',
                style: TextStyle(
                  color: QueryMenuTokens.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                QueryMenuFormatters.money(value.round()),
                key: const ValueKey('query-amount-threshold-value'),
                style: const TextStyle(
                  color: QueryMenuTokens.selectionEnd,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          Material(
            color: Colors.transparent,
            child: SliderTheme(
              data: SliderTheme.of(context).copyWith(
                activeTrackColor: QueryMenuTokens.selectionEnd,
                inactiveTrackColor: QueryMenuTokens.controlSurface,
                thumbColor: QueryMenuTokens.selectionEnd,
                overlayShape: const RoundSliderOverlayShape(overlayRadius: 18),
                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
              ),
              child: Slider(
                key: const ValueKey('query-amount-threshold-slider'),
                value: value,
                min: minimum,
                max: maximum,
                onChangeStart:
                    bounds.maximumScaled100 <= bounds.minimumScaled100
                    ? null
                    : (_) => _dragActive = true,
                onChanged: bounds.maximumScaled100 <= bounds.minimumScaled100
                    ? null
                    : (next) => setState(() => _localValue = next),
                onChangeEnd: bounds.maximumScaled100 <= bounds.minimumScaled100
                    ? null
                    : (next) {
                        _dragActive = false;
                        final resolved = next.round().clamp(
                          bounds.minimumScaled100,
                          bounds.maximumScaled100,
                        );
                        widget.onValueCommitted(resolved);
                      },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
