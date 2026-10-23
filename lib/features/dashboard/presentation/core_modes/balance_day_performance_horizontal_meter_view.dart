import 'package:flutter/material.dart';
import 'balance_alternative_visual_tokens.dart';
import 'balance_day_performance_index_presentation.dart';
import 'balance_impact_meter.dart';

/// A passive, responsive visualization of the same accepted performance model.
final class BalanceDayPerformanceHorizontalMeterView extends StatefulWidget {
  const BalanceDayPerformanceHorizontalMeterView({
    super.key,
    required this.presentation,
  });
  final BalanceDayPerformanceIndexPresentation presentation;
  @override
  State<BalanceDayPerformanceHorizontalMeterView> createState() =>
      _MeterState();
}

class _MeterState extends State<BalanceDayPerformanceHorizontalMeterView>
    with SingleTickerProviderStateMixin {
  late final AnimationController _motion;
  late final Animation<double> _curve;
  late double _from, _to;
  double get _visible => _from + (_to - _from) * _curve.value;
  @override
  void initState() {
    super.initState();
    _from = _to = widget.presentation.scale.visualProgress;
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    )..value = 1;
    _curve = CurvedAnimation(parent: _motion, curve: Curves.easeOutCubic);
  }

  @override
  void didUpdateWidget(
    covariant BalanceDayPerformanceHorizontalMeterView oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    final next = widget.presentation.scale.visualProgress;
    if (next == _to) return;
    _from = _visible;
    _to = next;
    _motion.forward(from: 0);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, bounds) {
      final model = widget.presentation;
      final compact = bounds.maxHeight < 230;
      final color = model.isImproving
          ? BalanceAlternativeHtmlTokens.dailyMomentumMint
          : model.isWorsening
          ? BalanceAlternativeHtmlTokens.dailyMomentumCoral
          : BalanceAlternativeHtmlTokens.dailyMomentumPurple;
      // All dimensions derive from the real main-visual constraints, bypassing
      // the legacy minimum-height/FittedBox scene only for this alternative.
      final thickness = (bounds.maxHeight * .26).clamp(0.0, 64.0);
      final compression = (bounds.maxHeight / 145).clamp(.1, 1.0);
      final width = bounds.maxWidth * .93;
      return Column(
        children: [
          SizedBox(
            height: (compact ? 16.0 : 22.0) * compression,
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                '30 napos teljesítmény',
                style: TextStyle(
                  fontSize: compact ? 13 : 17,
                  fontWeight: FontWeight.w700,
                  color: BalanceAlternativeHtmlTokens.textPrimary,
                ),
              ),
            ),
          ),
          Expanded(
            flex: 3,
            child: Center(
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  model.primaryLabel,
                  style: TextStyle(
                    fontSize: model.isAvailable ? (compact ? 30 : 40) : 18,
                    fontWeight: FontWeight.w900,
                    height: 1,
                    color: color,
                  ),
                ),
              ),
            ),
          ),
          SizedBox(
            width: width,
            child: Column(
              children: [
                AnimatedBuilder(
                  animation: _motion,
                  builder: (context, child) => BalanceImpactMeter(
                    key: const ValueKey('balance-day-horizontal-meter-track'),
                    orientation: Axis.horizontal,
                    height: thickness,
                    markerFraction: _visible,
                    markerColor: color,
                    showMarker: model.isAvailable,
                  ),
                ),
                SizedBox(height: (compact ? 4.0 : 7.0) * compression),
                SizedBox(
                  height: (compact ? 12.0 : 18.0) * compression,
                  child: LayoutBuilder(
                    builder: (context, labels) {
                      // Container's one-pixel border is padding; match the material's child
                      // coordinates, including half-marker endpoint insets.
                      final geometry = BalanceImpactMeterGeometry(
                        Size(width - 2, thickness - 2),
                      );
                      return Stack(
                        clipBehavior: Clip.none,
                        children: [
                          for (final value
                              in (bounds.maxWidth < 330
                                  ? [0, 100, 200]
                                  : [0, 50, 100, 150, 200]))
                            Positioned(
                              left: 1 + geometry.centerAt(value / 200) - 23,
                              width: 46,
                              child: Text(
                                '$value%',
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: compact ? 9 : 11,
                                  fontWeight: value == 100
                                      ? FontWeight.w800
                                      : FontWeight.w600,
                                  color: BalanceAlternativeHtmlTokens
                                      .dailyMomentumAxis,
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            height:
                ((compact ? 44.0 : 64.0) +
                    (model.hasVisualOverflow ? 14.0 : 0)) *
                compression,
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (model.hasVisualOverflow)
                    Text(
                      'Skálán túl ›',
                      key: const ValueKey(
                        'balance-day-horizontal-meter-overflow',
                      ),
                      style: TextStyle(color: color, fontSize: 10),
                    ),
                  Text(
                    'Előző 30 nap = 100%',
                    style: TextStyle(
                      fontSize: compact ? 10 : 12,
                      color: BalanceAlternativeHtmlTokens.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Flexible(
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        model.interpretation,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: compact ? 11 : 14,
                          height: 1.15,
                          color: BalanceAlternativeHtmlTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    },
  );
}
