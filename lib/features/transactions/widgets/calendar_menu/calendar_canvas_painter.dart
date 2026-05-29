import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/calendar_menu_mode.dart';
import '../../models/calendar_render_models.dart';
import '../../models/transaction_record.dart';
import 'calendar_canvas_layout.dart';

class CalendarCanvasPainter extends CustomPainter {
  CalendarCanvasPainter({
    required this.data,
    required this.mode,
    required this.layout,
  });

  final CalendarYearRenderData data;
  final CalendarMenuMode mode;
  final CalendarCanvasLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < data.months.length; i += 1) {
      _drawMonth(canvas, layout.monthRects[i], data.months[i]);
    }
  }

  void _drawMonth(Canvas canvas, Rect rect, CalendarMonthRenderData month) {
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
    if (mode == CalendarMenuMode.summary && month.hasTransactions) {
      final overlay = month.balance >= 0 ? AppColors.income : AppColors.expense;
      canvas.drawRRect(rrect, Paint()..color = overlay.withValues(alpha: 0.1));
    }
    _drawCenteredText(
      canvas,
      month.name,
      Offset(rect.center.dx, rect.top + 14),
      12,
      FontWeight.w600,
      AppColors.gray800,
    );
    if (mode == CalendarMenuMode.summary && month.hasTransactions) {
      final balanceColor = month.balance >= 0
          ? const Color(0xFF059669)
          : const Color(0xFFDC2626);
      final prefix = month.balance >= 0 ? '+' : '-';
      _drawCenteredText(
        canvas,
        '$prefix${formatHuf(month.balance.abs())}',
        Offset(rect.center.dx, rect.top + 30),
        10,
        FontWeight.w700,
        balanceColor,
      );
    }
    _drawWeekdays(canvas, rect, month);
    _drawDays(canvas, rect, month);
    canvas.restore();
  }

  void _drawWeekdays(Canvas canvas, Rect rect, CalendarMonthRenderData month) {
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

  void _drawDays(Canvas canvas, Rect rect, CalendarMonthRenderData month) {
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

  void _drawDayCell(Canvas canvas, Rect cell, CalendarDayRenderData day) {
    final center = cell.center;
    final shortestSide = math.min(cell.width, cell.height);
    final radius = (shortestSide * 0.38).clamp(3, 11).toDouble();
    var textColor = AppColors.gray500;
    if ((mode == CalendarMenuMode.normal || mode == CalendarMenuMode.summary) &&
        day.isToday) {
      canvas.drawCircle(center, radius, Paint()..color = AppColors.primary);
      textColor = AppColors.white;
    } else if (mode == CalendarMenuMode.normal && day.meetsThreshold) {
      canvas.drawCircle(
        center,
        radius,
        Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1
          ..color = const Color(0xFF9CA3AF),
      );
    } else if (mode == CalendarMenuMode.category &&
        day.dominantCategoryId != null) {
      canvas.drawCircle(center, radius, Paint()..color = day.dominantCategoryColor);
      textColor = AppColors.white;
    } else if (mode == CalendarMenuMode.heatmap &&
        day.heatmapPercentage > 0) {
      final overlay = RRect.fromRectAndRadius(
        cell.deflate(2),
        const Radius.circular(3),
      );
      final percentage = day.heatmapPercentage;
      if (percentage <= 0.15) {
        canvas.drawRRect(overlay, Paint()..color = AppColors.white);
      } else {
        canvas.drawRRect(
          overlay,
          Paint()..color = AppColors.primary.withValues(alpha: percentage * 0.8),
        );
        canvas.drawRRect(
          overlay,
          Paint()
            ..color = AppColors.white.withValues(alpha: (1 - percentage) * 0.4),
        );
      }
    }
    if (mode == CalendarMenuMode.summary && !day.isToday) {
      if (day.hasIncome) {
        canvas.drawCircle(
          Offset(cell.left + 4, cell.top + 1),
          2.5,
          Paint()..color = AppColors.income,
        );
      }
      if (day.hasExpense) {
        canvas.drawCircle(
          Offset(cell.right - 4, cell.top + 1),
          2.5,
          Paint()..color = AppColors.expense,
        );
      }
    }
    _drawCenteredText(
      canvas,
      day.day.toString(),
      center,
      10,
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
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(CalendarCanvasPainter oldDelegate) {
    return oldDelegate.data != data ||
        oldDelegate.mode != mode ||
        oldDelegate.layout.size != layout.size;
  }
}
