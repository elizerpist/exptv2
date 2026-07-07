import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../transactions/models/calendar_menu_mode.dart';
import '../../transactions/models/transaction_category.dart';
import '../../transactions/models/transaction_record.dart';
import '../../transactions/widgets/calendar_menu/calendar_canvas_layout.dart';
import '../data/stats_year_data.dart';

class StatsYearCalendar extends StatelessWidget {
  const StatsYearCalendar({
    super.key,
    required this.data,
    this.onMonthSelected,
  });

  final StatsYearData data;
  final ValueChanged<StatsMonthData>? onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.of(context).size.width;
        final layout = CalendarCanvasLayout.calculate(
          width: width,
          mode: CalendarMenuMode.summary,
        );
        return SingleChildScrollView(
          key: const ValueKey('stats-year-calendar-scroll'),
          child: SizedBox(
            key: const ValueKey('stats-year-calendar'),
            width: layout.size.width,
            height: layout.size.height,
            child: Stack(
              children: [
                RepaintBoundary(
                  child: CustomPaint(
                    key: const ValueKey('stats-year-calendar-paint'),
                    size: layout.size,
                    painter: _StatsYearCalendarPainter(
                      data: data,
                      layout: layout,
                    ),
                  ),
                ),
                for (var i = 0; i < layout.monthRects.length; i += 1)
                  Positioned.fromRect(
                    rect: layout.monthRects[i],
                    child: GestureDetector(
                      key: ValueKey('stats-month-hit-${i + 1}'),
                      behavior: HitTestBehavior.opaque,
                      onTap: onMonthSelected == null
                          ? null
                          : () => onMonthSelected!(data.months[i]),
                      child: const SizedBox.expand(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _StatsYearCalendarPainter extends CustomPainter {
  const _StatsYearCalendarPainter({required this.data, required this.layout});

  final StatsYearData data;
  final CalendarCanvasLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < data.months.length; i += 1) {
      _drawMonth(canvas, layout.monthRects[i], data.months[i]);
    }
  }

  void _drawMonth(Canvas canvas, Rect rect, StatsMonthData month) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    canvas.drawShadow(
      Path()..addRRect(rrect),
      Colors.black.withValues(alpha: 0.1),
      3,
      true,
    );
    canvas.drawRRect(rrect, Paint()..color = AppColors.gray50);
    canvas.drawRRect(
      rrect,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1
        ..color = AppColors.gray200,
    );
    canvas.save();
    canvas.clipRRect(rrect);
    if (data.mode == StatsRenderMode.closing && month.hasTransactions) {
      final overlay = data.activeType == TransactionType.income
          ? AppColors.income
          : AppColors.expense;
      canvas.drawRRect(rrect, Paint()..color = overlay.withValues(alpha: 0.08));
    }
    _drawCenteredText(
      canvas,
      month.name,
      Offset(rect.center.dx, rect.top + 14),
      12,
      FontWeight.w600,
      AppColors.gray800,
    );
    if (data.mode == StatsRenderMode.closing && month.hasTransactions) {
      final prefix = data.activeType == TransactionType.income ? '+' : '-';
      final color = data.activeType == TransactionType.income
          ? const Color(0xFF059669)
          : const Color(0xFFDC2626);
      _drawCenteredText(
        canvas,
        '$prefix${formatHuf(month.closingAmount)}',
        Offset(rect.center.dx, rect.top + 30),
        10,
        FontWeight.w700,
        color,
      );
    }
    _drawWeekdays(canvas, rect, month);
    _drawDays(canvas, rect, month);
    canvas.restore();
  }

  void _drawWeekdays(Canvas canvas, Rect rect, StatsMonthData month) {
    final top = rect.top + 44;
    final cellWidth = rect.width / 7;
    for (var i = 0; i < month.weekdayLabels.length; i += 1) {
      _drawCenteredText(
        canvas,
        month.weekdayLabels[i],
        Offset(rect.left + cellWidth * i + cellWidth / 2, top),
        8,
        FontWeight.w600,
        AppColors.gray500,
      );
    }
  }

  void _drawDays(Canvas canvas, Rect rect, StatsMonthData month) {
    final gridTop = rect.top + 54;
    final cellWidth = rect.width / 7;
    final cellHeight = (rect.bottom - gridTop - 8) / 6;
    for (final day in month.days) {
      final index = month.leadingBlankDays + day.day - 1;
      final column = index % 7;
      final row = index ~/ 7;
      final cell = Rect.fromLTWH(
        rect.left + column * cellWidth,
        gridTop + row * cellHeight,
        cellWidth,
        cellHeight,
      );
      _drawDayCell(canvas, cell, day);
    }
  }

  void _drawDayCell(Canvas canvas, Rect cell, StatsDayData day) {
    final center = cell.center;
    final shortestSide = math.min(cell.width, cell.height);
    final radius = (shortestSide * 0.38).clamp(3, 11).toDouble();
    final dayFontSize = (shortestSide * 0.34).clamp(10, 10).toDouble();
    var textColor = AppColors.gray500;

    if (data.mode == StatsRenderMode.categoryScope &&
        day.dominantCategoryId != null &&
        day.meetsThreshold) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = day.dominantCategoryColor,
      );
      textColor = AppColors.white;
    } else if (data.mode == StatsRenderMode.heatmap) {
      final percentage = day.heatmapIntensity;
      if (percentage > 0) {
        final overlay = RRect.fromRectAndRadius(
          cell.deflate(2),
          const Radius.circular(3),
        );
        final color = data.activeType == TransactionType.income
            ? AppColors.income
            : AppColors.primary;
        canvas.drawRRect(
          overlay,
          Paint()..color = color.withValues(alpha: percentage * 0.8),
        );
        canvas.drawRRect(
          overlay,
          Paint()
            ..color = AppColors.white.withValues(alpha: (1 - percentage) * 0.4),
        );
      }
    }

    if (data.mode == StatsRenderMode.closing && day.meetsThreshold) {
      final color = data.activeType == TransactionType.income
          ? AppColors.income
          : AppColors.expense;
      canvas.drawCircle(
        Offset(cell.center.dx, cell.top + 1),
        2.5,
        Paint()..color = color,
      );
    }

    _drawCenteredText(
      canvas,
      day.day.toString(),
      center,
      dayFontSize,
      FontWeight.w600,
      textColor,
    );
  }

  void _drawCenteredText(
    Canvas canvas,
    String text,
    Offset center,
    double fontSize,
    FontWeight weight,
    Color color,
  ) {
    final painter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color),
      ),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(
      canvas,
      center - Offset(painter.width / 2, painter.height / 2),
    );
  }

  @override
  bool shouldRepaint(_StatsYearCalendarPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.layout.size != layout.size;
  }
}
