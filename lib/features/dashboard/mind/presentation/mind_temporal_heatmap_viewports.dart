import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/mind_temporal_heatmap_frame.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import 'mind_year_heatmap_palette_resolver.dart';

/// B3M-MYS-inspired all-time month grid. It is a compact presentation over
/// Core's immutable Sum frame; the ListView is the sole scroll owner for a
/// real multi-year history.
final class MindSumHeatmapViewport extends StatelessWidget {
  const MindSumHeatmapViewport({
    super.key,
    required this.frameListenable,
    this.presentationSettings,
  });

  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  presentationSettings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MindTemporalHeatmapFrame?>(
        valueListenable: frameListenable,
        builder: (context, current, _) {
          final frame = current is MindSumHeatmapFrame ? current : null;
          if (frame == null) {
            return const SizedBox(
              key: ValueKey<String>('mind-sum-heatmap-unavailable'),
            );
          }
          final content = _MindSumHeatmapContent(
            frame: frame,
            paletteStyle:
                presentationSettings?.value.paletteStyle ??
                MindYearHeatmapPaletteStyle.fluvi,
          );
          final settings = presentationSettings;
          if (settings == null) return content;
          return ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
            valueListenable: settings,
            builder: (context, value, _) => _MindSumHeatmapContent(
              frame: frame,
              paletteStyle: value.paletteStyle,
            ),
          );
        },
      );
}

final class _MindSumHeatmapContent extends StatelessWidget {
  const _MindSumHeatmapContent({
    required this.frame,
    required this.paletteStyle,
  });

  static const _monthAxis = <String>[
    'J',
    'F',
    'M',
    'Á',
    'M',
    'J',
    'J',
    'A',
    'S',
    'O',
    'N',
    'D',
  ];

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Text(
          'Többéves hőtérkép',
          key: const ValueKey<String>('mind-sum-heatmap-title'),
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 1),
        Text(
          '${frame.years.length} év · ${frame.years.length * 12} hónap',
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 9,
          ),
        ),
        const SizedBox(height: 5),
        const Text(
          'Éves aktivitás',
          style: TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 9,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 3),
        Row(
          children: <Widget>[
            const SizedBox(width: 34),
            Expanded(
              child: Row(
                children: List<Widget>.generate(
                  _monthAxis.length,
                  (index) => Expanded(
                    child: Center(
                      child: Text(
                        _monthAxis[index],
                        style: const TextStyle(
                          color: FluviVisualTokens.textSecondary,
                          fontSize: 8,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                  growable: false,
                ),
              ),
            ),
            const SizedBox(width: 58),
          ],
        ),
        const SizedBox(height: 2),
        Expanded(
          child: ListView.separated(
            key: const ValueKey<String>('mind-sum-heatmap-scroll'),
            padding: EdgeInsets.zero,
            itemCount: frame.years.length,
            separatorBuilder: (_, _) => const SizedBox(height: 2),
            itemBuilder: (context, index) {
              final year = frame.years[index];
              return SizedBox(
                key: ValueKey<String>('mind-sum-heatmap-year-$year'),
                height: 29,
                child: Row(
                  children: <Widget>[
                    SizedBox(
                      width: 34,
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          '$year',
                          style: const TextStyle(
                            color: FluviVisualTokens.textSecondary,
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Row(
                        children: List<Widget>.generate(12, (monthIndex) {
                          final item = frame.month(
                            year: year,
                            month: monthIndex + 1,
                          );
                          final palette =
                              MindYearHeatmapPaletteResolver.resolveTile(
                                style: paletteStyle,
                                isEmpty: item.isEmpty,
                                intensity: item.intensity,
                                paletteIntensity: item.paletteIntensity,
                              );
                          return Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(
                                right: monthIndex == 11 ? 0 : 2,
                              ),
                              child: DecoratedBox(
                                key: ValueKey<String>(
                                  'mind-sum-heatmap-cell-$year-${monthIndex + 1}',
                                ),
                                decoration: BoxDecoration(
                                  color: palette.background,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          );
                        }, growable: false),
                      ),
                    ),
                    SizedBox(
                      width: 58,
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          alignment: Alignment.centerRight,
                          child: Text(
                            QueryMenuFormatters.money(frame.yearTotal(year)),
                            key: ValueKey<String>(
                              'mind-sum-heatmap-total-$year',
                            ),
                            style: const TextStyle(
                              color: FluviVisualTokens.textSecondary,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    ),
  );
}

/// B3M-MYM-inspired selected-month day grid. The dynamic tile field repaints
/// from the immutable frame while day numbers remain static semantic widgets;
/// an amount thumb therefore does not create text layout work per preview.
final class MindMonthHeatmapViewport extends StatelessWidget {
  const MindMonthHeatmapViewport({
    super.key,
    required this.frameListenable,
    this.presentationSettings,
  });

  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  presentationSettings;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<MindTemporalHeatmapFrame?>(
        valueListenable: frameListenable,
        builder: (context, current, _) {
          final frame = current is MindMonthHeatmapFrame ? current : null;
          if (frame == null) {
            return const SizedBox(
              key: ValueKey<String>('mind-month-heatmap-unavailable'),
            );
          }
          Widget content(MindYearHeatmapPaletteStyle style) =>
              _MindMonthHeatmapContent(
                frame: frame,
                frameListenable: frameListenable,
                paletteStyle: style,
              );
          final settings = presentationSettings;
          if (settings == null) {
            return content(MindYearHeatmapPaletteStyle.fluvi);
          }
          return ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
            valueListenable: settings,
            builder: (context, value, _) => content(value.paletteStyle),
          );
        },
      );
}

final class _MindMonthHeatmapContent extends StatelessWidget {
  const _MindMonthHeatmapContent({
    required this.frame,
    required this.frameListenable,
    required this.paletteStyle,
  });

  final MindMonthHeatmapFrame frame;
  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;

  @override
  Widget build(BuildContext context) {
    final geometry = MindYearHeatmapCalendarGeometry.forMonth(
      year: frame.year,
      month: frame.month,
    );
    return LayoutBuilder(
      builder: (context, constraints) {
        const horizontalPadding = 12.0;
        const gap = 4.0;
        // Includes the actual two header lines, month summary, footer and
        // outer vertical padding. Keep this explicit so a constrained Month
        // viewport solves its six square rows instead of overflowing.
        const staticChrome = 96.0;
        final width = (constraints.maxWidth - horizontalPadding * 2)
            .clamp(0.0, double.infinity)
            .toDouble();
        final cellByWidth = ((width - gap * 6) / 7)
            .clamp(0.0, double.infinity)
            .toDouble();
        final cellByHeight = constraints.maxHeight.isFinite
            ? ((constraints.maxHeight - staticChrome - gap * 5) / 6)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : cellByWidth;
        final cellExtent = math.min(cellByWidth, cellByHeight);
        final gridHeight = cellExtent * 6 + gap * 5;
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text(
                'Napi aktivitás',
                key: const ValueKey<String>('mind-month-heatmap-title'),
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${frame.days.length} nap',
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${DashboardTimeLabelFormatter.monthName(frame.month)} ${frame.year}',
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                '${frame.activeDayCount} aktív nap',
                key: const ValueKey<String>('mind-month-heatmap-active-days'),
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 9,
                ),
              ),
              const SizedBox(height: 4),
              SizedBox(
                key: const ValueKey<String>('mind-month-heatmap-grid'),
                height: gridHeight,
                child: Stack(
                  fit: StackFit.expand,
                  children: <Widget>[
                    RepaintBoundary(
                      child: CustomPaint(
                        painter: _MindMonthHeatmapPainter(
                          geometry: geometry,
                          frameListenable: frameListenable,
                          paletteStyle: paletteStyle,
                          cellExtent: cellExtent,
                          gap: gap,
                        ),
                      ),
                    ),
                    ...frame.days.map((day) {
                      final slot = geometry.slotIndexForDay(day.date.day);
                      final row = slot ~/ 7;
                      final column = slot % 7;
                      return Positioned(
                        left: column * (cellExtent + gap),
                        top: row * (cellExtent + gap),
                        width: cellExtent,
                        height: cellExtent,
                        child: IgnorePointer(
                          child: Center(
                            child: Text(
                              '${day.date.day}',
                              style: const TextStyle(
                                color: FluviVisualTokens.textSecondary,
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              ),
              const SizedBox(height: 3),
              Row(
                children: <Widget>[
                  const Text(
                    'Összesen',
                    style: TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    QueryMenuFormatters.money(frame.total),
                    key: const ValueKey<String>('mind-month-heatmap-total'),
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

final class _MindMonthHeatmapPainter extends CustomPainter {
  _MindMonthHeatmapPainter({
    required this.geometry,
    required this.frameListenable,
    required this.paletteStyle,
    required this.cellExtent,
    required this.gap,
  }) : super(repaint: frameListenable);

  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final double cellExtent;
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final frame = frameListenable.value;
    if (frame is! MindMonthHeatmapFrame || cellExtent <= 0) return;
    final paint = Paint();
    for (final day in frame.days) {
      final slot = geometry.slotIndexForDay(day.date.day);
      final row = slot ~/ 7;
      final column = slot % 7;
      final palette = MindYearHeatmapPaletteResolver.resolve(
        style: paletteStyle,
        day: day,
      );
      paint.color = palette.background;
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            column * (cellExtent + gap),
            row * (cellExtent + gap),
            cellExtent,
            cellExtent,
          ),
          const Radius.circular(3),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MindMonthHeatmapPainter oldDelegate) =>
      geometry.year != oldDelegate.geometry.year ||
      geometry.month != oldDelegate.geometry.month ||
      !identical(frameListenable, oldDelegate.frameListenable) ||
      paletteStyle != oldDelegate.paletteStyle ||
      cellExtent != oldDelegate.cellExtent ||
      gap != oldDelegate.gap;
}
