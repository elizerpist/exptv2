import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_sum_year_band_header.dart';
import 'mind_temporal_content_header.dart';
import 'mind_heatmap_palette_scope.dart';
import 'mind_year_heatmap_palette_resolver.dart';

/// SUM-A/SUM-B presentation surfaces reconstructed from the supplied visual
/// references. They consume only the existing live [MindSumHeatmapFrame].
/// The canonical amount range control stays outside this surface, so this
/// class deliberately never renders a second decorative or inactive rail.
final class MindSumReferenceSurface extends StatelessWidget {
  const MindSumReferenceSurface({
    super.key,
    required this.frame,
    required this.visualStyle,
    this.paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
    this.scaleResolution = MindHeatmapScaleResolution.ten,
    // Kept as an accepted input for persisted earlier preference state. The
    // source-of-truth SUM layout is now deliberately fixed to 4×3 and never
    // exposes a second layout selector.
    this.showLayoutChooser = false,
  });

  final MindSumHeatmapFrame frame;
  final MindSumVisualStyle visualStyle;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final bool showLayoutChooser;

  @override
  Widget build(BuildContext context) {
    final years = frame.years;
    final period = years.isEmpty
        ? '— · 0 hónap'
        : '${years.first}–${years.last} · ${years.length * 12} hónap';
    final dynamicScale = MindHeatmapPaletteScope.maybeOf(context);
    final isSumB = visualStyle == MindSumVisualStyle.sumB;
    // The surrounding Mind seamless body owns the only actual content-card
    // shell. This surface supplies body content only, preventing a second
    // rounded bottom from appearing above the fixed slider footer.
    return KeyedSubtree(
      key: ValueKey<String>('mind-sum-reference-${visualStyle.name}'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MindTemporalContentHeader(
              title: 'SUM aktivitás',
              subtitle: period,
              titleKey: const ValueKey<String>('mind-sum-heatmap-title'),
              subtitleKey: const ValueKey<String>('mind-sum-heatmap-period'),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                key: const ValueKey<String>('mind-sum-reference-year-list'),
                padding: const EdgeInsets.only(bottom: 4),
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: years.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, index) => isSumB
                    ? _SumBYearBand(
                        frame: frame,
                        year: years[index],
                        paletteStyle: paletteStyle,
                        scaleResolution: scaleResolution,
                        dynamicScale: dynamicScale,
                      )
                    : _SumAYearBand(
                        frame: frame,
                        year: years[index],
                        paletteStyle: paletteStyle,
                        scaleResolution: scaleResolution,
                        dynamicScale: dynamicScale,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SumAYearBand extends StatelessWidget {
  const _SumAYearBand({
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    this.dynamicScale,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey<String>('mind-sum-a-year-$year'),
    // Header (23) + gap (5) + three real, source-proportioned month rows.
    // The fixed geometry deliberately does not infer a second layout from
    // screen size. At the reference width this produces 4×3 cards instead of
    // making the slider/footer compete with a vertically oversized year band.
    height: 154,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        Row(
          children: <Widget>[
            Text(
              '$year',
              key: ValueKey<String>('mind-sum-heatmap-year-label-$year'),
              style: const TextStyle(
                color: Color(0xff06194f),
                fontSize: 16,
                fontWeight: FontWeight.w900,
              ),
            ),
            const Spacer(),
            const Text(
              'Összesen:',
              style: TextStyle(
                color: Color(0xff607391),
                fontSize: 10,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 5),
            Text(
              formatMindCompactForints(frame.yearTotal(year) ~/ 100),
              key: ValueKey<String>('mind-sum-heatmap-total-$year'),
              style: const TextStyle(
                color: Color(0xff06194f),
                fontSize: 13,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        Expanded(
          child: _SumMonthGrid(
            frame: frame,
            year: year,
            paletteStyle: paletteStyle,
            scaleResolution: scaleResolution,
            dynamicScale: dynamicScale,
          ),
        ),
      ],
    ),
  );
}

final class _SumBYearBand extends StatelessWidget {
  const _SumBYearBand({
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    this.dynamicScale,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  @override
  Widget build(BuildContext context) {
    final palette = _sumYearPalette(
      frame: frame,
      year: year,
      paletteStyle: paletteStyle,
      scaleResolution: scaleResolution,
      dynamicScale: dynamicScale,
    );
    // SUM-B keeps its very pale mother surface, but that surface is still a
    // live heatmap consumer. It must not remain a static parity-coloured card
    // while its own year identity and month cells react to the range slider.
    final motherColors = <Color>[
      Color.lerp(palette.background, Colors.white, .84)!,
      Color.lerp(palette.background, Colors.white, .69)!,
    ];
    return Container(
      key: ValueKey<String>('mind-sum-b-mother-card-$year'),
      height: 162,
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: motherColors,
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        children: <Widget>[
          _SumBYearIdentity(
            frame: frame,
            year: year,
            paletteStyle: paletteStyle,
            scaleResolution: scaleResolution,
            dynamicScale: dynamicScale,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    'Éves összeg: ${formatMindCompactForints(frame.yearTotal(year) ~/ 100)}',
                    key: ValueKey<String>('mind-sum-heatmap-total-$year'),
                    style: const TextStyle(
                      color: Color(0xff122a74),
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: _SumMonthGrid(
                    frame: frame,
                    year: year,
                    paletteStyle: paletteStyle,
                    scaleResolution: scaleResolution,
                    dynamicScale: dynamicScale,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final class _SumBYearIdentity extends StatelessWidget {
  const _SumBYearIdentity({
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    this.dynamicScale,
  });
  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  @override
  Widget build(BuildContext context) {
    final palette = _sumYearPalette(
      frame: frame,
      year: year,
      paletteStyle: paletteStyle,
      scaleResolution: scaleResolution,
      dynamicScale: dynamicScale,
    );
    final colors = <Color>[
      Color.lerp(palette.background, const Color(0xff06194f), .18)!,
      Color.lerp(palette.background, Colors.white, .17)!,
    ];
    return Container(
      key: ValueKey<String>('mind-sum-b-year-card-$year'),
      width: 72,
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x33784d8d),
            offset: Offset(0, 5),
            blurRadius: 7,
          ),
          BoxShadow(
            color: Color(0x66ffffff),
            offset: Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$year',
            key: ValueKey<String>('mind-sum-heatmap-year-label-$year'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 17,
              fontWeight: FontWeight.w900,
            ),
          ),
          const Spacer(),
          const Icon(Icons.bar_chart_rounded, color: Colors.white, size: 14),
          const SizedBox(height: 2),
          const Text(
            'Összesen',
            style: TextStyle(color: Color(0xddffffff), fontSize: 7),
          ),
          Text(
            formatMindCompactForints(frame.yearTotal(year) ~/ 100),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

MindYearHeatmapPaletteSample _sumYearPalette({
  required MindSumHeatmapFrame frame,
  required int year,
  required MindYearHeatmapPaletteStyle paletteStyle,
  required MindHeatmapScaleResolution scaleResolution,
  MindHeatmapResolvedScale? dynamicScale,
}) => MindYearHeatmapPaletteResolver.resolveTile(
  style: paletteStyle,
  isEmpty: frame.yearTotal(year) == 0,
  intensity: _yearIntensity(frame, year),
  paletteIntensity: MindYearHeatmapPaletteIntensity.interpolated,
  scaleResolution: scaleResolution,
  dynamicScale: dynamicScale,
);

final class _SumMonthGrid extends StatelessWidget {
  const _SumMonthGrid({
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    this.dynamicScale,
  });
  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: ValueKey<String>('mind-sum-month-grid-$year-4'),
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 12,
    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: 4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      // The SUM-A reference cards are intentionally wide and shallow: their
      // visual rhythm is 4 columns × 3 rows, not a generic square heatmap.
      childAspectRatio: 2.25,
    ),
    itemBuilder: (context, index) {
      final month = frame.month(year: year, month: index + 1);
      final palette = MindYearHeatmapPaletteResolver.resolveTile(
        style: paletteStyle,
        isEmpty: month.isEmpty,
        intensity: month.intensity,
        paletteIntensity: month.paletteIntensity,
        scaleResolution: scaleResolution,
        dynamicScale: dynamicScale,
      );
      return DecoratedBox(
        key: ValueKey<String>('mind-sum-heatmap-cell-$year-${index + 1}'),
        decoration: BoxDecoration(
          color: palette.background,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Padding(
          padding: const EdgeInsets.all(4),
          child: FittedBox(
            alignment: Alignment.centerLeft,
            fit: BoxFit.scaleDown,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  _monthName(index + 1),
                  style: TextStyle(color: palette.foreground, fontSize: 8),
                ),
                Text(
                  formatMindCompactForints((month.total ?? 0) ~/ 100),
                  style: TextStyle(
                    color: palette.foreground,
                    fontSize: 9,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}

double _yearIntensity(MindSumHeatmapFrame frame, int year) {
  final maximum = frame.years.fold<int>(
    0,
    (value, candidate) => math.max(value, frame.yearTotal(candidate)),
  );
  return maximum == 0
      ? 0
      : (frame.yearTotal(year) / maximum).clamp(0, 1).toDouble();
}

String _monthName(int month) => const <String>[
  'január',
  'február',
  'március',
  'április',
  'május',
  'június',
  'július',
  'augusztus',
  'szeptember',
  'október',
  'november',
  'december',
][month - 1];
