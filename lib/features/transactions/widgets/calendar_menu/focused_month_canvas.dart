import 'package:flutter/material.dart';

import '../../models/calendar_menu_mode.dart';
import '../../models/calendar_render_models.dart';
import 'calendar_canvas_layout.dart';
import 'calendar_canvas_painter.dart';

class FocusedMonthCanvas extends StatelessWidget {
  const FocusedMonthCanvas({
    super.key,
    required this.month,
    required this.mode,
  });

  final CalendarMonthRenderData month;
  final CalendarMenuMode mode;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final layout = CalendarCanvasLayout.focusedMonth(width: width);
        return RepaintBoundary(
          child: CustomPaint(
            key: const ValueKey('calendar-focus-month-canvas'),
            size: layout.size,
            painter: CalendarCanvasPainter(
              data: CalendarYearRenderData(
                year: month.year,
                months: [month],
                thresholdRange: const CalendarThresholdRange(min: 0, max: 0),
              ),
              mode: mode,
              layout: layout,
            ),
          ),
        );
      },
    );
  }
}
