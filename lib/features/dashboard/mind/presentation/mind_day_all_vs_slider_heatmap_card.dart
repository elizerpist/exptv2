import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/mind_day_hourly_comparison_projection.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import 'mind_temporal_content_header.dart';

/// Places the one canonical Mind amount-range control inside the active Day
/// content card.  It is a location-only scope: the control's controller,
/// preview and Query write path continue to be owned by Core.
final class MindDayRangeFooterScope extends InheritedWidget {
  const MindDayRangeFooterScope({
    super.key,
    required this.range,
    required super.child,
  });

  final Widget range;

  static Widget? maybeRangeOf(BuildContext context) => context
      .dependOnInheritedWidgetOfExactType<MindDayRangeFooterScope>()
      ?.range;

  @override
  bool updateShouldNotify(MindDayRangeFooterScope oldWidget) =>
      oldWidget.range != range;
}

/// Native counterpart of the Day reference's two-layer activity heatmap.
///
/// The pale column is the entire selected calendar day's resident amount. The
/// magenta foreground is the amount-range subset. Neither layer owns the
/// canonical range slider or triggers financial/data work.
final class MindDayAllVsSliderHeatmapCard extends StatelessWidget {
  const MindDayAllVsSliderHeatmapCard({
    super.key,
    required this.frame,
    this.onTimelineRequested,
  });

  final MindDayHeatmapFrame frame;
  final VoidCallback? onTimelineRequested;

  @override
  Widget build(BuildContext context) {
    final comparison = MindDayHourlyComparisonProjection.build(
      fullEvents: frame.fullTimelineEvents,
      selectedEvents: frame.timelineEvents,
    );
    final range = MindDayRangeFooterScope.maybeRangeOf(context);
    return DecoratedBox(
      key: const ValueKey<String>('mind-day-all-slider-card'),
      decoration: BoxDecoration(
        color: const Color(0xfffeffff),
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: const Color(0x128195b5)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x285e759d),
            offset: Offset(0, 7),
            blurRadius: 1,
          ),
          BoxShadow(
            color: Color(0x173d5579),
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
              title: 'Napi aktivitás',
              subtitle: _dateLabel(frame),
              titleKey: const ValueKey<String>('mind-day-all-slider-title'),
              subtitleKey: const ValueKey<String>('mind-day-all-slider-period'),
              trailing: onTimelineRequested == null
                  ? null
                  : MindDayContentViewChooser(
                      selected: MindDayContentView.allVsSliderHeatmap,
                      onTimelineRequested: onTimelineRequested,
                    ),
            ),
            const SizedBox(height: 8),
            Expanded(child: _MindDayHourlyBars(comparison: comparison)),
            const SizedBox(height: 12),
            const _MindDayComparisonLegend(),
            const SizedBox(height: 12),
            const _MindDayHeatmapScaleLegend(),
            if (range != null) ...<Widget>[
              const SizedBox(height: 5),
              SizedBox(
                key: const ValueKey<String>('mind-day-heatmap-range-footer'),
                height: 68,
                child: range,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

String _dateLabel(MindDayHeatmapFrame frame) {
  const months = <String>[
    'jan.',
    'febr.',
    'márc.',
    'ápr.',
    'máj.',
    'jún.',
    'júl.',
    'aug.',
    'szept.',
    'okt.',
    'nov.',
    'dec.',
  ];
  const weekdays = <String>[
    'Hétfő',
    'Kedd',
    'Szerda',
    'Csütörtök',
    'Péntek',
    'Szombat',
    'Vasárnap',
  ];
  final date = DateTime.utc(frame.date.year, frame.date.month, frame.date.day);
  return '${frame.date.year}. ${months[frame.date.month - 1]} ${frame.date.day}. · ${weekdays[date.weekday - 1]}';
}

/// Shared two-view switcher for the two Day surfaces. Its owner is the Mind
/// presentation controller; this widget only forwards the selected intent.
final class MindDayContentViewChooser extends StatelessWidget {
  const MindDayContentViewChooser({
    super.key,
    required this.selected,
    this.onHeatmapRequested,
    this.onTimelineRequested,
  });

  final MindDayContentView selected;
  final VoidCallback? onHeatmapRequested;
  final VoidCallback? onTimelineRequested;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('mind-day-content-view-toggle'),
    decoration: BoxDecoration(
      color: const Color(0xfff4f0ff),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: const Color(0x177c90b5)),
    ),
    child: Padding(
      padding: EdgeInsets.all(2),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          _MindDayViewChoice(
            key: const ValueKey<String>('mind-day-timeline-view-heatmap'),
            icon: Icons.grid_view_rounded,
            selected: selected == MindDayContentView.allVsSliderHeatmap,
            onPressed: onHeatmapRequested,
          ),
          _MindDayViewChoice(
            key: const ValueKey<String>('mind-day-all-slider-view-timeline'),
            icon: Icons.show_chart_rounded,
            selected: selected == MindDayContentView.timeline,
            onPressed: onTimelineRequested,
          ),
        ],
      ),
    ),
  );
}

final class _MindDayViewChoice extends StatelessWidget {
  const _MindDayViewChoice({
    super.key,
    required this.icon,
    this.selected = false,
    this.onPressed,
  });

  final IconData icon;
  final bool selected;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) => Semantics(
    button: onPressed != null,
    selected: selected,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(7),
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: <Color>[Color(0xff7559f3), Color(0xffb08cf8)],
                )
              : null,
          borderRadius: BorderRadius.circular(7),
        ),
        child: SizedBox(
          width: 23,
          height: 22,
          child: Icon(
            icon,
            size: 12,
            color: selected ? Colors.white : const Color(0xff637796),
          ),
        ),
      ),
    ),
  );
}

final class _MindDayHourlyBars extends StatelessWidget {
  const _MindDayHourlyBars({required this.comparison});

  final MindDayHourlyComparisonProjection comparison;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const labelHeight = 15.0;
      const gap = 4.0;
      final plotHeight = math.max(0, constraints.maxHeight - labelHeight);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: comparison.hours
            .map((hour) {
              final fullHeight = plotHeight * hour.fullFraction;
              final selectedHeight = plotHeight * hour.selectedFraction;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      Expanded(
                        child: Align(
                          alignment: Alignment.bottomCenter,
                          child: SizedBox(
                            key: ValueKey<String>(
                              'mind-day-all-slider-hour-${hour.hour.toString().padLeft(2, '0')}',
                            ),
                            height: math.max(5, fullHeight),
                            child: DecoratedBox(
                              key: ValueKey<String>(
                                'mind-day-all-slider-full-${hour.hour.toString().padLeft(2, '0')}',
                              ),
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: <Color>[
                                    Color(0xfffdf0ec),
                                    Color(0xffffd1c2),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Align(
                                alignment: Alignment.bottomCenter,
                                child: FractionallySizedBox(
                                  heightFactor: hour.fullFraction == 0
                                      ? 0
                                      : (selectedHeight /
                                                math.max(5, fullHeight))
                                            .clamp(0, 1)
                                            .toDouble(),
                                  child: DecoratedBox(
                                    key: ValueKey<String>(
                                      'mind-day-all-slider-selected-${hour.hour.toString().padLeft(2, '0')}',
                                    ),
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(
                                        begin: Alignment.topCenter,
                                        end: Alignment.bottomCenter,
                                        colors: <Color>[
                                          Color(0xfff34c92),
                                          Color(0xff971374),
                                        ],
                                      ),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: gap),
                      SizedBox(
                        height: labelHeight,
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(
                            hour.hour.toString().padLeft(2, '0'),
                            style: const TextStyle(
                              color: Color(0xff6982b2),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            })
            .toList(growable: false),
      );
    },
  );
}

final class _MindDayComparisonLegend extends StatelessWidget {
  const _MindDayComparisonLegend();

  @override
  Widget build(BuildContext context) => const Row(
    children: <Widget>[
      _MindDayLegendCopy(
        color: Color(0xffffe0d3),
        title: 'Teljes nap',
        subtitle: 'Az adott órában elköltött teljes összeg',
      ),
      SizedBox(width: 12),
      _MindDayLegendCopy(
        color: Color(0xffe33f8d),
        title: 'Aktuális szűrő',
        subtitle: 'A kiválasztott idősáv összege az adott órában',
      ),
    ],
  );
}

final class _MindDayLegendCopy extends StatelessWidget {
  const _MindDayLegendCopy({
    required this.color,
    required this.title,
    required this.subtitle,
  });

  final Color color;
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: const TextStyle(
                  color: Color(0xff101b4e),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: const TextStyle(
                  color: Color(0xff8196c1),
                  fontSize: 7,
                  height: 1.2,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

final class _MindDayHeatmapScaleLegend extends StatelessWidget {
  const _MindDayHeatmapScaleLegend();

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const Text(
        'Kisebb összeg',
        style: TextStyle(color: Color(0xff6982b2), fontSize: 8),
      ),
      const Spacer(),
      Row(
        mainAxisSize: MainAxisSize.min,
        children:
            const <Color>[
                  Color(0xffffe9dc),
                  Color(0xffffd8c4),
                  Color(0xffffbc9f),
                  Color(0xffff9474),
                  Color(0xffff6e69),
                  Color(0xfff54c92),
                  Color(0xffd42d82),
                  Color(0xff971374),
                ]
                .map<Widget>(
                  (color) => Padding(
                    padding: const EdgeInsets.only(right: 2),
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: const SizedBox(width: 11, height: 11),
                    ),
                  ),
                )
                .toList(growable: false),
      ),
      const Spacer(),
      const Text(
        'Nagyobb összeg',
        style: TextStyle(color: Color(0xff6982b2), fontSize: 8),
      ),
    ],
  );
}
