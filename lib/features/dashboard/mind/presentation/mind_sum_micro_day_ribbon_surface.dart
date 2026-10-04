import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_heatmap_palette_scope.dart';
import 'mind_sum_micro_day_ribbon_model.dart';
import 'mind_sum_year_band_header.dart';
import 'mind_temporal_content_header.dart';
import 'mind_year_heatmap_palette_resolver.dart';

/// A lightweight, five-row daily field for every resident SUM year. The
/// supplied [frame] is already amount-range filtered; this surface only
/// arranges and paints its daily points.
final class MindSumMicroDayRibbonSurface extends StatelessWidget {
  const MindSumMicroDayRibbonSurface({
    super.key,
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) {
    final model = MindSumMicroDayRibbonModel.fromFrame(frame);
    final years = frame.years;
    final period = years.isEmpty
        ? '— · 0 év'
        : '${years.first}–${years.last} · ${years.length} év';
    return Padding(
      key: const ValueKey<String>('mind-sum-micro-day-ribbon-surface'),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          MindTemporalContentHeader(
            title: 'SUM napi aktivitás',
            subtitle: period,
            titleKey: const ValueKey<String>('mind-sum-micro-day-ribbon-title'),
            subtitleKey: const ValueKey<String>(
              'mind-sum-micro-day-ribbon-period',
            ),
            trailing: MindNoSpendDaysHeaderMetric(
              noSpendDayCount: frame.noSpendDayCount,
              keyPrefix: 'mind-sum-no-spend-days',
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ListView.separated(
              key: const ValueKey<String>('mind-sum-micro-day-ribbon-years'),
              padding: EdgeInsets.zero,
              itemCount: years.length,
              separatorBuilder: (_, _) => const SizedBox(height: 14),
              itemBuilder: (context, index) => _MindSumMicroDayRibbonYearBand(
                year: model.year(years[index]),
                paletteStyle: paletteStyle,
                scaleResolution: scaleResolution,
                dynamicScale: MindHeatmapPaletteScope.maybeOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _MindSumMicroDayRibbonYearBand extends StatelessWidget {
  const _MindSumMicroDayRibbonYearBand({
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.dynamicScale,
  });

  static const _monthLabels = <String>[
    'jan',
    'feb',
    'márc',
    'ápr',
    'máj',
    'jún',
    'júl',
    'aug',
    'szept',
    'okt',
    'nov',
    'dec',
  ];

  final MindSumMicroDayRibbonYear year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  @override
  Widget build(BuildContext context) => Semantics(
    container: true,
    label:
        '${year.year}, ${formatMindCompactForints(year.total ~/ 100)}. '
        'Tizenkét hónap napi hőtérképe.',
    child: Column(
      key: ValueKey<String>('mind-sum-micro-day-ribbon-year-${year.year}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        SizedBox(
          key: ValueKey<String>(
            'mind-sum-micro-day-ribbon-year-header-${year.year}',
          ),
          height: 20,
          child: Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  '${year.year}',
                  key: ValueKey<String>(
                    'mind-sum-micro-day-ribbon-year-label-${year.year}',
                  ),
                  style: const TextStyle(
                    color: FluviVisualTokens.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Text(
                formatMindCompactForints(year.total ~/ 100),
                key: ValueKey<String>(
                  'mind-sum-micro-day-ribbon-year-total-${year.year}',
                ),
                style: const TextStyle(
                  color: FluviVisualTokens.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 3),
        LayoutBuilder(
          builder: (context, constraints) {
            final geometry = MindSumMicroDayRibbonGeometry.resolve(
              availableWidth: constraints.maxWidth,
              totalMicroColumns: year.totalMicroColumns,
            );
            final colors = List<Color>.unmodifiable(
              year.cells.map(
                (cell) => MindYearHeatmapPaletteResolver.resolveTile(
                  style: paletteStyle,
                  isEmpty: cell.isEmpty,
                  intensity: cell.intensity,
                  paletteIntensity: _paletteIntensityFor(cell),
                  scaleResolution: scaleResolution,
                  dynamicScale: dynamicScale,
                ).background,
              ),
            );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  height: 12,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: List<Widget>.generate(year.months.length, (
                      index,
                    ) {
                      final month = year.months[index];
                      // Every internal boundary consumes only the same
                      // micro-gap the painter uses between adjacent columns.
                      final width =
                          month.microColumnCount * geometry.cellExtent +
                          (index == year.months.length - 1
                                  ? month.microColumnCount - 1
                                  : month.microColumnCount) *
                              geometry.microGap;
                      return SizedBox(
                        width: width,
                        child: Center(
                          child: Text(
                            _monthLabels[index],
                            key: ValueKey<String>(
                              'mind-sum-micro-day-ribbon-month-${year.year}-${index + 1}',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.clip,
                            style: const TextStyle(
                              color: FluviVisualTokens.textSecondary,
                              fontSize: 7,
                              height: 1,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
                const SizedBox(height: 2),
                SizedBox(
                  key: ValueKey<String>(
                    'mind-sum-micro-day-ribbon-field-${year.year}',
                  ),
                  height: geometry.fieldHeight,
                  child: ExcludeSemantics(
                    child: RepaintBoundary(
                      child: CustomPaint(
                        painter: _MindSumMicroDayRibbonPainter(
                          year: year,
                          geometry: geometry,
                          colors: colors,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ],
    ),
  );

  MindYearHeatmapPaletteIntensity _paletteIntensityFor(
    MindSumMicroDayRibbonCell cell,
  ) {
    if (cell.isEmpty || cell.intensity <= 0) {
      return MindYearHeatmapPaletteIntensity.minimum;
    }
    if (cell.intensity >= 1) {
      return MindYearHeatmapPaletteIntensity.maximum;
    }
    return MindYearHeatmapPaletteIntensity.interpolated;
  }
}

final class _MindSumMicroDayRibbonPainter extends CustomPainter {
  const _MindSumMicroDayRibbonPainter({
    required this.year,
    required this.geometry,
    required this.colors,
  });

  final MindSumMicroDayRibbonYear year;
  final MindSumMicroDayRibbonGeometry geometry;
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final radius = Radius.circular((geometry.cellExtent * .22).clamp(.5, 1.6));
    for (var index = 0; index < year.cells.length; index += 1) {
      final cell = year.cells[index];
      final left = geometry.xForColumn(cell.column);
      final top = cell.row * (geometry.cellExtent + geometry.microGap);
      paint.color = colors[index];
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, geometry.cellExtent, geometry.cellExtent),
          radius,
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _MindSumMicroDayRibbonPainter oldDelegate) =>
      oldDelegate.year != year ||
      oldDelegate.geometry.cellExtent != geometry.cellExtent ||
      oldDelegate.colors != colors;
}
