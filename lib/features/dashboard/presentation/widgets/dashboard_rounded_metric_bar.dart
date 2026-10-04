import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Data-free vertical bar primitive shared by compact dashboard rhythms.
///
/// The caller owns all financial aggregation and normalization. This widget
/// only paints a single reference/foreground pair against those supplied,
/// common-domain fractions, so Mind hourly bars and Balance daily bars cannot
/// drift into two separate rounded-bar geometries.
final class DashboardRoundedMetricBar extends StatelessWidget {
  const DashboardRoundedMetricBar({
    super.key,
    required this.label,
    required this.hasReference,
    required this.referenceFraction,
    required this.hasForeground,
    required this.foregroundFraction,
    required this.foregroundColor,
    this.referenceColor = const Color(0xffd4d7dc),
    this.labelStyle = const TextStyle(
      color: Color(0xff6982b2),
      fontSize: 8,
      fontWeight: FontWeight.w700,
    ),
    this.minimumVisibleHeight = 4,
    this.showLabel = true,
    this.barKey,
    this.referenceKey,
    this.foregroundKey,
  });

  static const labelHeight = 15.0;
  static const labelGap = 4.0;
  static const borderRadius = 6.0;

  final String label;
  final bool hasReference;
  final double referenceFraction;
  final bool hasForeground;
  final double foregroundFraction;
  final Color foregroundColor;
  final Color referenceColor;
  final TextStyle labelStyle;
  final double minimumVisibleHeight;
  final bool showLabel;
  final Key? barKey;
  final Key? referenceKey;
  final Key? foregroundKey;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final labelLane = showLabel ? labelHeight + labelGap : 0.0;
      final plotHeight = math.max(0.0, constraints.maxHeight - labelLane);
      final referenceHeight = _heightFor(
        fraction: referenceFraction,
        hasAmount: hasReference,
        plotHeight: plotHeight,
      );
      final foregroundHeight = _heightFor(
        fraction: foregroundFraction,
        hasAmount: hasForeground,
        plotHeight: plotHeight,
      );
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SizedBox(
                key: barKey,
                height: math.max(5.0, plotHeight),
                child: hasReference || hasForeground
                    ? Stack(
                        fit: StackFit.expand,
                        children: <Widget>[
                          if (hasReference)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                key: referenceKey,
                                height: referenceHeight,
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: referenceColor,
                                    borderRadius: BorderRadius.circular(
                                      borderRadius,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          if (hasForeground)
                            Align(
                              alignment: Alignment.bottomCenter,
                              child: SizedBox(
                                key: foregroundKey,
                                height: foregroundHeight,
                                width: double.infinity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: foregroundColor,
                                    borderRadius: BorderRadius.circular(
                                      borderRadius,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      )
                    : const SizedBox.shrink(),
              ),
            ),
          ),
          if (showLabel) ...<Widget>[
            const SizedBox(height: labelGap),
            SizedBox(
              height: labelHeight,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label, style: labelStyle),
              ),
            ),
          ],
        ],
      );
    },
  );

  double _heightFor({
    required double fraction,
    required bool hasAmount,
    required double plotHeight,
  }) {
    if (!hasAmount || plotHeight <= 0) return 0;
    return (plotHeight * fraction.clamp(0.0, 1.0))
        .clamp(minimumVisibleHeight, plotHeight)
        .toDouble();
  }
}
