import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import 'mind_sum_year_band_header.dart';
import 'mind_temporal_content_header.dart';

/// Reference-led SUM-A / SUM-B renderer.
///
/// Both styles use the exact resident [MindSumHeatmapFrame].  This renderer is
/// deliberately presentation-only: its gradients, layout selector and range
/// rail neither recalculate totals nor alter Query/time navigation.
final class MindSumReferenceSurface extends StatelessWidget {
  const MindSumReferenceSurface({
    super.key,
    required this.frame,
    required this.visualStyle,
    required this.showLayoutChooser,
  });

  final MindSumHeatmapFrame frame;
  final MindSumVisualStyle visualStyle;
  final bool showLayoutChooser;

  bool get _isSumB => visualStyle == MindSumVisualStyle.sumB;

  @override
  Widget build(BuildContext context) {
    final years = frame.years;
    final period = years.isEmpty
        ? '— · 0 hónap'
        : '${years.first}–${years.last} · ${years.length * 12} hónap';
    return DecoratedBox(
      key: ValueKey<String>('mind-sum-reference-${visualStyle.name}'),
      decoration: BoxDecoration(
        color: _isSumB ? const Color(0xfffdfbff) : const Color(0xfffffeff),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0x11879ab6)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x246078a2),
            offset: Offset(0, 7),
            blurRadius: 1,
          ),
          BoxShadow(
            color: Color(0x163e547a),
            offset: Offset(0, 15),
            blurRadius: 22,
          ),
          BoxShadow(color: Color(0x88ffffff), offset: Offset(-1, -1)),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 13),
        child: Column(
          children: <Widget>[
            MindTemporalContentHeader(
              title: 'SUM aktivitás',
              subtitle: period,
              titleKey: const ValueKey<String>('mind-sum-heatmap-title'),
              subtitleKey: const ValueKey<String>('mind-sum-heatmap-period'),
              trailing: showLayoutChooser
                  ? _SumReferenceLayoutChooser(sumB: _isSumB)
                  : null,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: years.length <= 2
                  ? Column(
                      key: const ValueKey<String>(
                        'mind-sum-reference-year-list',
                      ),
                      children: <Widget>[
                        for (
                          var index = 0;
                          index < years.length;
                          index++
                        ) ...<Widget>[
                          Expanded(
                            child: _yearBand(
                              years[index],
                              fillsAvailableHeight: true,
                            ),
                          ),
                          if (index != years.length - 1)
                            const SizedBox(height: 9),
                        ],
                      ],
                    )
                  : ListView.separated(
                      key: const ValueKey<String>(
                        'mind-sum-reference-year-list',
                      ),
                      padding: EdgeInsets.zero,
                      physics: const AlwaysScrollableScrollPhysics(),
                      itemCount: years.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 9),
                      itemBuilder: (context, index) => _yearBand(years[index]),
                    ),
            ),
            const SizedBox(height: 9),
            _SumReferenceRangeRail(frame: frame),
          ],
        ),
      ),
    );
  }

  Widget _yearBand(int year, {bool fillsAvailableHeight = false}) => _isSumB
      ? _SumBYearBand(
          frame: frame,
          year: year,
          fillsAvailableHeight: fillsAvailableHeight,
        )
      : _SumAYearBand(
          frame: frame,
          year: year,
          fillsAvailableHeight: fillsAvailableHeight,
        );
}

final class _SumReferenceLayoutChooser extends StatelessWidget {
  const _SumReferenceLayoutChooser({required this.sumB});

  final bool sumB;

  @override
  Widget build(BuildContext context) => sumB
      ? DecoratedBox(
          key: const ValueKey<String>('mind-sum-detail-mode-toggle'),
          decoration: BoxDecoration(
            color: const Color(0xffedf1fa),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x13758ba8)),
          ),
          child: const Padding(
            padding: EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SumReferenceIconChoice(
                  icon: Icons.calendar_today_rounded,
                  selected: true,
                ),
                _SumReferenceIconChoice(icon: Icons.bar_chart_rounded),
                _SumReferenceIconChoice(icon: Icons.grid_view_rounded),
              ],
            ),
          ),
        )
      : Row(
          key: const ValueKey<String>('mind-sum-detail-mode-toggle'),
          mainAxisSize: MainAxisSize.min,
          children: const <Widget>[
            _SumReferenceTextChoice(label: '3×4', selected: true),
            SizedBox(width: 4),
            _SumReferenceTextChoice(label: '4×3'),
            SizedBox(width: 4),
            _SumReferenceTextChoice(label: '2×6'),
          ],
        );
}

final class _SumReferenceTextChoice extends StatelessWidget {
  const _SumReferenceTextChoice({required this.label, this.selected = false});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: selected ? const Color(0xfff8fbff) : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      border: Border.all(
        color: selected ? const Color(0xff354a70) : const Color(0x337489a9),
        width: selected ? 1.2 : 1,
      ),
    ),
    child: SizedBox(
      width: 48,
      height: 24,
      child: Center(
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xff34476a),
            fontSize: 9,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ),
  );
}

final class _SumReferenceIconChoice extends StatelessWidget {
  const _SumReferenceIconChoice({required this.icon, this.selected = false});

  final IconData icon;
  final bool selected;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      gradient: selected
          ? const LinearGradient(
              colors: <Color>[Color(0xff7559f3), Color(0xffb08cf8)],
            )
          : null,
      borderRadius: BorderRadius.circular(12),
    ),
    child: SizedBox(
      width: 30,
      height: 25,
      child: Icon(
        icon,
        size: 13,
        color: selected ? Colors.white : const Color(0xff637796),
      ),
    ),
  );
}

final class _SumAYearBand extends StatelessWidget {
  const _SumAYearBand({
    required this.frame,
    required this.year,
    this.fillsAvailableHeight = false,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final bool fillsAvailableHeight;

  @override
  Widget build(BuildContext context) => Column(
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
      if (fillsAvailableHeight)
        Expanded(
          child: _SumMonthGrid(frame: frame, year: year, columns: 4),
        )
      else
        SizedBox(
          height: 92,
          child: _SumMonthGrid(frame: frame, year: year, columns: 4),
        ),
    ],
  );
}

final class _SumBYearBand extends StatelessWidget {
  const _SumBYearBand({
    required this.frame,
    required this.year,
    this.fillsAvailableHeight = false,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final bool fillsAvailableHeight;

  @override
  Widget build(BuildContext context) {
    final content = Container(
      key: ValueKey<String>('mind-sum-b-mother-card-$year'),
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: year.isEven
              ? const <Color>[Color(0xfff4eeff), Color(0xffece8ff)]
              : const <Color>[Color(0xfffff2ed), Color(0xffffe7e7)],
        ),
        borderRadius: BorderRadius.circular(17),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _SumBYearIdentity(frame: frame, year: year),
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
                  child: _SumMonthGrid(frame: frame, year: year, columns: 6),
                ),
              ],
            ),
          ),
        ],
      ),
    );
    return fillsAvailableHeight
        ? SizedBox.expand(child: content)
        : SizedBox(height: 116, child: content);
  }
}

final class _SumBYearIdentity extends StatelessWidget {
  const _SumBYearIdentity({required this.frame, required this.year});

  final MindSumHeatmapFrame frame;
  final int year;

  @override
  Widget build(BuildContext context) {
    final warm = !year.isEven;
    final colors = warm
        ? const <Color>[Color(0xffff9191), Color(0xffff6f70)]
        : const <Color>[Color(0xff7255ee), Color(0xffb385f4)];
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

final class _SumMonthGrid extends StatelessWidget {
  const _SumMonthGrid({
    required this.frame,
    required this.year,
    required this.columns,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final int columns;

  static const _monthNames = <String>[
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
  ];

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const gap = 5.0;
      final rows = 12 ~/ columns;
      final width = math.max(
        0.0,
        (constraints.maxWidth - gap * (columns - 1)) / columns,
      );
      final height = math.max(
        0.0,
        (constraints.maxHeight - gap * (rows - 1)) / rows,
      );
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: List<Widget>.generate(12, (index) {
          final item = frame.month(year: year, month: index + 1);
          return SizedBox(
            width: width,
            height: height,
            child: _SumMonthTile(
              item: item,
              label: _monthNames[index],
              dense: columns == 6,
            ),
          );
        }, growable: false),
      );
    },
  );
}

final class _SumMonthTile extends StatelessWidget {
  const _SumMonthTile({
    required this.item,
    required this.label,
    required this.dense,
  });

  final MindSumHeatmapMonth item;
  final String label;
  final bool dense;

  @override
  Widget build(BuildContext context) {
    final intensity = item.intensity.clamp(0.0, 1.0).toDouble();
    final low = const Color(0xfffff4ef);
    final high = const Color(0xfff86f88);
    final fill = Color.lerp(low, high, intensity)!;
    final foreground = intensity > .55 ? Colors.white : const Color(0xff09215c);
    return DecoratedBox(
      key: ValueKey<String>('mind-sum-heatmap-cell-${item.year}-${item.month}'),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[fill.withValues(alpha: .9), fill],
        ),
        borderRadius: BorderRadius.circular(dense ? 14 : 9),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x0f6d5975),
            offset: Offset(0, 2),
            blurRadius: 3,
          ),
          BoxShadow(
            color: Color(0x55ffffff),
            offset: Offset(-1, -1),
            blurRadius: 2,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: dense ? 4 : 8,
          vertical: dense ? 1 : 2,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: dense ? 7 : 9,
                height: 1.05,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              formatMindCompactForints((item.total ?? 0) ~/ 100),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: foreground,
                fontSize: dense ? 8 : 11,
                height: 1.05,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SumReferenceRangeRail extends StatelessWidget {
  const _SumReferenceRangeRail({required this.frame});

  final MindSumHeatmapFrame frame;

  @override
  Widget build(BuildContext context) {
    final minimum = frame.minimumNonEmptyTotal ?? 0;
    final maximum = frame.maximumNonEmptyTotal ?? 0;
    return Column(
      children: <Widget>[
        SizedBox(
          height: 21,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              Container(
                height: 5,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: <Color>[
                      Color(0xffffe8d8),
                      Color(0xffff7776),
                      Color(0xffa01b6b),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              const Align(
                alignment: Alignment.centerLeft,
                child: _SumRangeKnob(color: Color(0xffffead8)),
              ),
              const Align(
                alignment: Alignment.centerRight,
                child: _SumRangeKnob(color: Color(0xffa32170)),
              ),
            ],
          ),
        ),
        Row(
          children: <Widget>[
            Text(
              'Min. ${formatMindCompactForints(minimum ~/ 100)}',
              style: const TextStyle(
                color: Color(0xff607391),
                fontSize: 9,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            Text(
              'Max. ${formatMindCompactForints(maximum ~/ 100)}',
              style: const TextStyle(
                color: Color(0xff06194f),
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

final class _SumRangeKnob extends StatelessWidget {
  const _SumRangeKnob({required this.color});
  final Color color;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: color,
      shape: BoxShape.circle,
      boxShadow: const <BoxShadow>[
        BoxShadow(
          color: Color(0x33546884),
          offset: Offset(0, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Color(0x66ffffff),
          offset: Offset(-1, -1),
          blurRadius: 2,
        ),
      ],
    ),
    child: const SizedBox(width: 19, height: 19),
  );
}
