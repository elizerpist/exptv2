import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../domain/mind_monthly_overlay_series.dart';

/// Reusable paint implementation for the immutable monthly full/current-scope
/// comparison series. Month labels intentionally remain the page owner's
/// responsibility so every card can compose its own vertical rhythm.
class MindMonthlyOverlayBarPainter extends CustomPainter {
  MindMonthlyOverlayBarPainter({
    required this.series,
    required this.foregroundForValue,
    required this.paintIdentity,
    this.typography = FluviTypographyProfile.app,
  });

  final MindMonthlyOverlaySeries series;
  final Color Function(MindMonthlyOverlayValue value) foregroundForValue;
  final Object paintIdentity;
  final FluviTypographyProfile typography;

  @override
  void paint(Canvas canvas, Size size) {
    const left = 30.0;
    const top = 6.0;
    const right = 4.0;
    const bottom = 4.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    final grid = Paint()
      ..color = FluviVisualTokens.surfaceMuted
      ..strokeWidth = .75;
    const baseLabelStyle = TextStyle(
      color: FluviVisualTokens.textSecondary,
      fontSize: 7,
    );
    final labelStyle = typography.applyTo(baseLabelStyle);
    for (final level in series.scale.levels) {
      final fraction = series.scale.top == 0 ? 0.0 : level / series.scale.top;
      final y = plot.bottom - plot.height * fraction;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
      final text = TextPainter(
        text: TextSpan(
          text: QueryMenuFormatters.money(level),
          style: labelStyle,
        ),
        textDirection: TextDirection.ltr,
        maxLines: 1,
      )..layout(maxWidth: left - 3);
      text.paint(canvas, Offset(0, y - text.height / 2));
    }
    if (series.scale.top == 0 || plot.width <= 0 || plot.height <= 0) return;
    final unit = plot.width / series.values.length;
    final barWidth = math.min(14, unit * .56).toDouble();
    final background = Paint()..color = const Color(0xFFD4D7DC);
    for (var index = 0; index < series.values.length; index += 1) {
      final value = series.values[index];
      final x = plot.left + unit * index + (unit - barWidth) / 2;
      final fullHeight = plot.height * value.fullAmount / series.scale.top;
      final filteredHeight =
          plot.height * value.filteredAmount / series.scale.top;
      final fullRect = Rect.fromLTWH(
        x,
        plot.bottom - fullHeight,
        barWidth,
        fullHeight,
      );
      final filteredRect = Rect.fromLTWH(
        x,
        plot.bottom - filteredHeight,
        barWidth,
        filteredHeight,
      );
      canvas.drawRRect(
        RRect.fromRectAndRadius(fullRect, const Radius.circular(2)),
        background,
      );
      final foregroundPaint = Paint()..color = foregroundForValue(value);
      canvas.drawRRect(
        RRect.fromRectAndRadius(filteredRect, const Radius.circular(2)),
        foregroundPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant MindMonthlyOverlayBarPainter oldDelegate) =>
      series != oldDelegate.series ||
      paintIdentity != oldDelegate.paintIdentity ||
      typography != oldDelegate.typography;
}
