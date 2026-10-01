import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import 'mind_sum_year_band_header.dart';
import 'mind_temporal_content_header.dart';

/// SUM-A/SUM-B presentation surfaces reconstructed from the supplied visual
/// references. They consume only the existing live [MindSumHeatmapFrame].
/// The canonical amount range control stays outside this surface, so this
/// class deliberately never renders a second decorative or inactive rail.
final class MindSumReferenceSurface extends StatefulWidget {
  const MindSumReferenceSurface({
    super.key,
    required this.frame,
    required this.visualStyle,
    required this.showLayoutChooser,
  });

  final MindSumHeatmapFrame frame;
  final MindSumVisualStyle visualStyle;
  final bool showLayoutChooser;

  @override
  State<MindSumReferenceSurface> createState() =>
      _MindSumReferenceSurfaceState();
}

final class _MindSumReferenceSurfaceState
    extends State<MindSumReferenceSurface> {
  // The SUM-A reference starts with three rows and four month cards per row.
  var _layout = MindYearHeatmapGridLayout.threeByFour;

  bool get _isSumB => widget.visualStyle == MindSumVisualStyle.sumB;

  int get _columns => switch (_layout) {
    MindYearHeatmapGridLayout.threeByFour => 4,
    MindYearHeatmapGridLayout.fourByThree => 3,
    MindYearHeatmapGridLayout.twoBySix => 6,
  };

  void _selectLayout(MindYearHeatmapGridLayout layout) {
    if (_layout == layout) return;
    setState(() => _layout = layout);
  }

  @override
  Widget build(BuildContext context) {
    final years = widget.frame.years;
    final period = years.isEmpty
        ? '— · 0 hónap'
        : '${years.first}–${years.last} · ${years.length * 12} hónap';
    return DecoratedBox(
      key: ValueKey<String>('mind-sum-reference-${widget.visualStyle.name}'),
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
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            MindTemporalContentHeader(
              title: 'SUM aktivitás',
              subtitle: period,
              titleKey: const ValueKey<String>('mind-sum-heatmap-title'),
              subtitleKey: const ValueKey<String>('mind-sum-heatmap-period'),
              trailing: widget.showLayoutChooser
                  ? _SumReferenceLayoutChooser(
                      sumB: _isSumB,
                      selectedLayout: _layout,
                      onSelected: _selectLayout,
                    )
                  : null,
            ),
            const SizedBox(height: 8),
            Expanded(
              child: ListView.separated(
                key: const ValueKey<String>('mind-sum-reference-year-list'),
                padding: EdgeInsets.zero,
                physics: const AlwaysScrollableScrollPhysics(),
                itemCount: years.length,
                separatorBuilder: (_, _) => const SizedBox(height: 9),
                itemBuilder: (context, index) => _isSumB
                    ? _SumBYearBand(
                        frame: widget.frame,
                        year: years[index],
                        columns: _columns,
                      )
                    : _SumAYearBand(
                        frame: widget.frame,
                        year: years[index],
                        columns: _columns,
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _SumReferenceLayoutChooser extends StatelessWidget {
  const _SumReferenceLayoutChooser({
    required this.sumB,
    required this.selectedLayout,
    required this.onSelected,
  });

  final bool sumB;
  final MindYearHeatmapGridLayout selectedLayout;
  final ValueChanged<MindYearHeatmapGridLayout> onSelected;

  @override
  Widget build(BuildContext context) => sumB
      ? DecoratedBox(
          key: const ValueKey<String>('mind-sum-detail-mode-toggle'),
          decoration: BoxDecoration(
            color: const Color(0xffedf1fa),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: const Color(0x13758ba8)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                _SumIconChoice(
                  key: const ValueKey<String>('mind-sum-layout-three-by-four'),
                  icon: Icons.calendar_today_rounded,
                  selected:
                      selectedLayout == MindYearHeatmapGridLayout.threeByFour,
                  onPressed: () =>
                      onSelected(MindYearHeatmapGridLayout.threeByFour),
                ),
                _SumIconChoice(
                  key: const ValueKey<String>('mind-sum-layout-four-by-three'),
                  icon: Icons.bar_chart_rounded,
                  selected:
                      selectedLayout == MindYearHeatmapGridLayout.fourByThree,
                  onPressed: () =>
                      onSelected(MindYearHeatmapGridLayout.fourByThree),
                ),
                _SumIconChoice(
                  key: const ValueKey<String>('mind-sum-layout-two-by-six'),
                  icon: Icons.grid_view_rounded,
                  selected:
                      selectedLayout == MindYearHeatmapGridLayout.twoBySix,
                  onPressed: () =>
                      onSelected(MindYearHeatmapGridLayout.twoBySix),
                ),
              ],
            ),
          ),
        )
      : Row(
          key: const ValueKey<String>('mind-sum-detail-mode-toggle'),
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            _SumTextChoice(
              key: const ValueKey<String>('mind-sum-layout-three-by-four'),
              label: '3×4',
              selected: selectedLayout == MindYearHeatmapGridLayout.threeByFour,
              onPressed: () =>
                  onSelected(MindYearHeatmapGridLayout.threeByFour),
            ),
            const SizedBox(width: 4),
            _SumTextChoice(
              key: const ValueKey<String>('mind-sum-layout-four-by-three'),
              label: '4×3',
              selected: selectedLayout == MindYearHeatmapGridLayout.fourByThree,
              onPressed: () =>
                  onSelected(MindYearHeatmapGridLayout.fourByThree),
            ),
            const SizedBox(width: 4),
            _SumTextChoice(
              key: const ValueKey<String>('mind-sum-layout-two-by-six'),
              label: '2×6',
              selected: selectedLayout == MindYearHeatmapGridLayout.twoBySix,
              onPressed: () => onSelected(MindYearHeatmapGridLayout.twoBySix),
            ),
          ],
        );
}

final class _SumTextChoice extends StatelessWidget {
  const _SumTextChoice({
    super.key,
    required this.label,
    required this.onPressed,
    this.selected = false,
  });

  final String label;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(13),
    child: DecoratedBox(
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
    ),
  );
}

final class _SumIconChoice extends StatelessWidget {
  const _SumIconChoice({
    super.key,
    required this.icon,
    required this.onPressed,
    this.selected = false,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onPressed,
    borderRadius: BorderRadius.circular(12),
    child: DecoratedBox(
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
    ),
  );
}

final class _SumAYearBand extends StatelessWidget {
  const _SumAYearBand({
    required this.frame,
    required this.year,
    required this.columns,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final int columns;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey<String>('mind-sum-a-year-$year'),
    height: switch (columns) {
      3 => 142,
      4 => 124,
      _ => 102,
    },
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
          child: _SumMonthGrid(frame: frame, year: year, columns: columns),
        ),
      ],
    ),
  );
}

final class _SumBYearBand extends StatelessWidget {
  const _SumBYearBand({
    required this.frame,
    required this.year,
    required this.columns,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final int columns;

  @override
  Widget build(BuildContext context) => Container(
    key: ValueKey<String>('mind-sum-b-mother-card-$year'),
    height: switch (columns) {
      3 => 142,
      4 => 116,
      _ => 102,
    },
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
                child: _SumMonthGrid(
                  frame: frame,
                  year: year,
                  columns: columns,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _SumBYearIdentity extends StatelessWidget {
  const _SumBYearIdentity({required this.frame, required this.year});
  final MindSumHeatmapFrame frame;
  final int year;

  @override
  Widget build(BuildContext context) {
    final intensity = _yearIntensity(frame, year);
    final colors = year.isEven
        ? <Color>[
            Color.lerp(
              const Color(0xff8166ef),
              const Color(0xff3d209b),
              intensity,
            )!,
            Color.lerp(
              const Color(0xffbd9af7),
              const Color(0xff7650e6),
              intensity,
            )!,
          ]
        : <Color>[
            Color.lerp(
              const Color(0xffff9da0),
              const Color(0xffde3159),
              intensity,
            )!,
            Color.lerp(
              const Color(0xffff7679),
              const Color(0xffff5661),
              intensity,
            )!,
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

final class _SumMonthGrid extends StatelessWidget {
  const _SumMonthGrid({
    required this.frame,
    required this.year,
    required this.columns,
  });
  final MindSumHeatmapFrame frame;
  final int year;
  final int columns;

  @override
  Widget build(BuildContext context) => GridView.builder(
    key: ValueKey<String>('mind-sum-month-grid-$year-$columns'),
    physics: const NeverScrollableScrollPhysics(),
    itemCount: 12,
    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
      crossAxisCount: columns,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      childAspectRatio: columns == 6 ? 1.15 : 1.7,
    ),
    itemBuilder: (context, index) {
      final month = frame.month(year: year, month: index + 1);
      final intensity = month.total == null ? 0.0 : month.intensity;
      final background = Color.lerp(
        const Color(0xfffff2ed),
        const Color(0xffd62d78),
        intensity,
      )!;
      final foreground = intensity > .55
          ? Colors.white
          : const Color(0xff07194d);
      return DecoratedBox(
        key: ValueKey<String>('mind-sum-heatmap-cell-$year-${index + 1}'),
        decoration: BoxDecoration(
          color: background,
          borderRadius: BorderRadius.circular(columns == 6 ? 13 : 8),
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
                  style: TextStyle(color: foreground, fontSize: 8),
                ),
                Text(
                  formatMindCompactForints((month.total ?? 0) ~/ 100),
                  style: TextStyle(
                    color: foreground,
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
