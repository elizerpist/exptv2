import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../domain/mind_day_hourly_comparison_projection.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_heatmap_palette_scope.dart';
import 'mind_full_vs_filtered_bar_geometry.dart';
import 'mind_temporal_content_header.dart';
import 'mind_year_heatmap_palette_resolver.dart';

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
    this.paletteStyle = MindYearHeatmapPaletteStyle.fluvi,
    this.scaleResolution = MindHeatmapScaleResolution.ten,
    this.onTimelineRequested,
  });

  final MindDayHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final VoidCallback? onTimelineRequested;

  @override
  Widget build(BuildContext context) {
    final comparison = MindDayHourlyComparisonProjection.build(
      fullEvents: frame.fullTimelineEvents,
      selectedEvents: frame.timelineEvents,
    );
    final range = MindDayRangeFooterScope.maybeRangeOf(context);
    final dynamicScale = MindHeatmapPaletteScope.maybeOf(context);
    // The seamless Mind body already owns the white card and its bottom
    // corners. This is content only, so Day cannot introduce a second false
    // card edge beneath the canonical range footer.
    return KeyedSubtree(
      key: const ValueKey<String>('mind-day-all-slider-card'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 0),
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
            Expanded(
              child: _MindDayHourlyBars(
                comparison: comparison,
                paletteStyle: paletteStyle,
                scaleResolution: scaleResolution,
                dynamicScale: dynamicScale,
              ),
            ),
            const SizedBox(height: 12),
            _MindDayComparisonLegend(
              paletteStyle: paletteStyle,
              scaleResolution: scaleResolution,
              dynamicScale: dynamicScale,
            ),
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
  Widget build(BuildContext context) => SizedBox(
    width: 54,
    height: 26,
    child: DecoratedBox(
      key: const ValueKey<String>('mind-day-content-view-toggle'),
      decoration: BoxDecoration(
        color: const Color(0xfff4f0ff),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0x177c90b5)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(2),
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
    child: GestureDetector(
      onTap: onPressed,
      behavior: HitTestBehavior.opaque,
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
  const _MindDayHourlyBars({
    required this.comparison,
    required this.paletteStyle,
    required this.scaleResolution,
    this.dynamicScale,
  });

  final MindDayHourlyComparisonProjection comparison;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  // A non-empty hour must remain visible even if another hour contains a much
  // larger transaction. This is a rendering floor only: the immutable hourly
  // totals and their common maximum remain the sole data/scale authority.
  static const _minimumVisibleAmountBarHeight = 4.0;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const labelHeight = 15.0;
      const gap = 4.0;
      final plotHeight = math.max(0.0, constraints.maxHeight - labelHeight);
      return Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: comparison.hours
            .map((hour) {
              final fullHeight =
                  MindFullVsFilteredBarGeometry.heightForFraction(
                    plotHeight: plotHeight,
                    fraction: hour.fullFraction,
                    hasAmount: MindFullVsFilteredBarGeometry.hasReference(
                      hour.fullTotal,
                    ),
                    minimumVisibleHeight: _minimumVisibleAmountBarHeight,
                  );
              final selectedHeight =
                  MindFullVsFilteredBarGeometry.heightForFraction(
                    plotHeight: plotHeight,
                    fraction: hour.selectedFraction,
                    hasAmount: MindFullVsFilteredBarGeometry.hasForeground(
                      hour.selectedTotal,
                    ),
                    minimumVisibleHeight: _minimumVisibleAmountBarHeight,
                  );
              final selectedPalette = _paletteFor(
                style: paletteStyle,
                scaleResolution: scaleResolution,
                dynamicScale: dynamicScale,
                fraction: hour.selectedFraction,
                isEmpty: hour.selectedTotal == 0,
              );
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
                            height: math.max(5.0, plotHeight),
                            child:
                                MindFullVsFilteredBarGeometry.hasReference(
                                  hour.fullTotal,
                                )
                                ? Stack(
                                    fit: StackFit.expand,
                                    children: <Widget>[
                                      Align(
                                        alignment: Alignment.bottomCenter,
                                        child: SizedBox(
                                          height: fullHeight,
                                          width: double.infinity,
                                          child: DecoratedBox(
                                            key: ValueKey<String>(
                                              'mind-day-all-slider-reference-${hour.hour.toString().padLeft(2, '0')}',
                                            ),
                                            decoration: BoxDecoration(
                                              color: const Color(0xffd4d7dc),
                                              borderRadius:
                                                  BorderRadius.circular(6),
                                            ),
                                          ),
                                        ),
                                      ),
                                      if (MindFullVsFilteredBarGeometry.hasForeground(
                                        hour.selectedTotal,
                                      ))
                                        Align(
                                          alignment: Alignment.bottomCenter,
                                          child: SizedBox(
                                            height: selectedHeight,
                                            width: double.infinity,
                                            child: DecoratedBox(
                                              key: ValueKey<String>(
                                                'mind-day-all-slider-selected-${hour.hour.toString().padLeft(2, '0')}',
                                              ),
                                              decoration: BoxDecoration(
                                                color:
                                                    selectedPalette.background,
                                                borderRadius:
                                                    BorderRadius.circular(6),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  )
                                : const SizedBox.shrink(),
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
  const _MindDayComparisonLegend({
    required this.paletteStyle,
    required this.scaleResolution,
    this.dynamicScale,
  });

  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindHeatmapResolvedScale? dynamicScale;

  @override
  Widget build(BuildContext context) {
    final selected = _paletteFor(
      style: paletteStyle,
      scaleResolution: scaleResolution,
      dynamicScale: dynamicScale,
      fraction: .88,
      isEmpty: false,
    ).background;
    return Row(
      children: <Widget>[
        _MindDayLegendCopy(
          color: const Color(0xffd4d7dc),
          title: 'Teljes nap',
          subtitle: 'Az adott órában elköltött teljes összeg',
        ),
        SizedBox(width: 12),
        _MindDayLegendCopy(
          color: selected,
          title: 'Aktuális szűrő',
          subtitle: 'A kiválasztott idősáv összege az adott órában',
        ),
      ],
    );
  }
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

MindYearHeatmapPaletteSample _paletteFor({
  required MindYearHeatmapPaletteStyle style,
  required MindHeatmapScaleResolution scaleResolution,
  required double fraction,
  required bool isEmpty,
  MindHeatmapResolvedScale? dynamicScale,
}) => MindYearHeatmapPaletteResolver.resolveTile(
  style: style,
  isEmpty: isEmpty,
  intensity: fraction,
  paletteIntensity: fraction <= 0
      ? MindYearHeatmapPaletteIntensity.minimum
      : fraction >= 1
      ? MindYearHeatmapPaletteIntensity.maximum
      : MindYearHeatmapPaletteIntensity.interpolated,
  scaleResolution: scaleResolution,
  dynamicScale: dynamicScale,
);
