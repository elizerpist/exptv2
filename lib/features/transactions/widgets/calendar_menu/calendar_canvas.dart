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
          child: SizedBox(
            key: const ValueKey('calendar-canvas'),
            width: layout.size.width,
            height: layout.size.height,
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey('calendar-canvas-paint'),
                    size: layout.size,
                    painter: CalendarCanvasPainter(
                      data: data,
                      mode: mode,
                      layout: layout,
                      thresholdValue: thresholdValue,
                      heatmapMinValue: heatmapMinValue,
                      heatmapCurrentValue: heatmapCurrentValue,
                    ),
                  ),
                ),
                for (var i = 0; i < layout.monthRects.length; i += 1)
                  _MonthHitTarget(
                    rect: layout.monthRects[i],
                    year: data.year,
                    month: i + 1,
                    onMonthSelected: onMonthSelected,
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MonthHitTarget extends StatelessWidget {
  const _MonthHitTarget({
    required this.rect,
    required this.year,
    required this.month,
    required this.onMonthSelected,
  });

  final Rect rect;
  final int year;
  final int month;
  final void Function(int year, int month) onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: rect.left,
      top: rect.top,
      width: rect.width,
      height: rect.height,
      child: GestureDetector(
        key: ValueKey('calendar-month-hit-$month'),
        behavior: HitTestBehavior.opaque,
        onTap: () => onMonthSelected(year, month),
        child: const SizedBox.expand(),
      ),
    );
  }
}
