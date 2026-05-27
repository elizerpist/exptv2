import 'package:flutter/material.dart';

import '../../models/calendar_menu_mode.dart';
import '../../models/calendar_render_models.dart';
import 'calendar_canvas_layout.dart';
import 'calendar_canvas_painter.dart';

class CalendarCanvas extends StatelessWidget {
  const CalendarCanvas({
    super.key,
    required this.data,
    required this.mode,
    required this.thresholdValue,
    required this.heatmapMinValue,
    required this.heatmapCurrentValue,
    required this.onMonthSelected,
  });

  final CalendarYearRenderData data;
  final CalendarMenuMode mode;
  final double thresholdValue;
  final double heatmapMinValue;
  final double heatmapCurrentValue;
  final void Function(int year, int month) onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final layout = CalendarCanvasLayout.calculate(
          width: width,
          mode: mode,
        );
        return SingleChildScrollView(
          key: const ValueKey('calendar-canvas-scroll'),
          child: GestureDetector(
            key: const ValueKey('calendar-canvas'),
            onTapUp: (details) {
              for (var i = 0; i < layout.monthRects.length; i += 1) {
                if (layout.monthRects[i].contains(details.localPosition)) {
                  onMonthSelected(data.year, i + 1);
                  return;
                }
              }
            },
            child: RepaintBoundary(
              child: CustomPaint(
                key: const ValueKey('calendar-canvas-paint'),
                size: layout.size,
                painter: CalendarCanvasPainter(
                  data: data,
                  mode: mode,
                  layout: layout,
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
