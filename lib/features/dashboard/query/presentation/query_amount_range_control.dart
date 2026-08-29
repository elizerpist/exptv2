import 'package:flutter/material.dart';

import '../domain/query_amount_range.dart';
import 'query_menu_formatters.dart';
import 'query_menu_tokens.dart';

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
  });

  final QueryAmountRangeValues values;
  final ValueChanged<QueryAmountRangeValues> onRangeCommitted;

  @override
  State<QueryAmountRangeControl> createState() =>
      _QueryAmountRangeControlState();
}

final class _QueryAmountRangeControlState
    extends State<QueryAmountRangeControl> {
  late RangeValues _localValues;
  var _dragActive = false;

  @override
  void initState() {
    super.initState();
    _localValues = _initialValues(widget.values);
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
              child: RangeSlider(
                key: const ValueKey('query-amount-range-slider'),
                values: local,
                min: values.minimumScaled100.toDouble(),
                max: maximum,
                onChangeStart: values.isActionable
                    ? (_) => _dragActive = true
                    : null,
                onChanged: values.isActionable
                    ? (next) => setState(() => _localValues = next)
                    : null,
                onChangeEnd: values.isActionable
                    ? (next) {
                        _dragActive = false;
                        widget.onRangeCommitted(
                          values.fromRawRange(
                            lower: next.start.round(),
                            upper: next.end.round(),
                          ),
                        );
                      }
                    : null,
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
