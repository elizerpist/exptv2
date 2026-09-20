import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import '../../presentation/dashboard_vertical_scroll_boundary_handoff.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/mind_temporal_heatmap_frame.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_monthly_overlay_series.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_year_heatmap_palette_resolver.dart';
import 'mind_anchored_info_card.dart';
import 'mind_detailed_sum_chart.dart';
import 'mind_monthly_overlay_bar_chart.dart';
import 'mind_temporal_secondary_cards.dart';

@visibleForTesting
const mindMonthHeatmapCellCornerRadius = 6.0;

/// B3M-MYS-inspired all-time month grid. It is a compact presentation over
/// Core's immutable Sum frame; the ListView is the sole scroll owner for a
/// real multi-year history.
final class MindSumHeatmapViewport extends StatelessWidget {
  const MindSumHeatmapViewport({
    super.key,
    required this.frameListenable,
    this.presentationSettings,
    this.upperVerticalGestures,
  });

  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  presentationSettings;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

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
            scaleResolution:
                presentationSettings?.value.scaleResolution ??
                MindHeatmapScaleResolution.ten,
            sumYearRowLayout:
                presentationSettings?.value.sumYearRowLayout ??
                MindSumYearRowLayout.twoRowExpanded,
            sumMonthLabelPlacement:
                presentationSettings?.value.sumMonthLabelPlacement ??
                MindSumMonthLabelPlacement.none,
            upperVerticalGestures: upperVerticalGestures,
          );
          final settings = presentationSettings;
          if (settings == null) return content;
          return ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
            valueListenable: settings,
            builder: (context, value, _) => _MindSumHeatmapContent(
              frame: frame,
              paletteStyle: value.paletteStyle,
              scaleResolution: value.scaleResolution,
              sumYearRowLayout: value.sumYearRowLayout,
              sumMonthLabelPlacement: value.sumMonthLabelPlacement,
              upperVerticalGestures: upperVerticalGestures,
            ),
          );
        },
      );
}

final class _MindSumHeatmapContent extends StatefulWidget {
  const _MindSumHeatmapContent({
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.sumYearRowLayout,
    required this.sumMonthLabelPlacement,
    this.upperVerticalGestures,
  });

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindSumYearRowLayout sumYearRowLayout;
  final MindSumMonthLabelPlacement sumMonthLabelPlacement;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<_MindSumHeatmapContent> createState() => _MindSumHeatmapContentState();
}

/// Format a whole-forint annual total for the compact, read-only Mind year
/// chip. Query's canonical full-money formatter remains the owner for Query.
@visibleForTesting
String formatMindCompactForints(int forints) {
  final absolute = forints.abs();
  final sign = forints < 0 ? '-' : '';
  if (absolute >= 1000000) {
    final millions = (absolute / 1000000)
        .toStringAsFixed(2)
        .replaceAll('.', ',');
    return '$sign$millions M Ft';
  }
  if (absolute >= 1000) return '$sign${(absolute / 1000).round()} k Ft';
  return '$forints Ft';
}

final class _MindSumHeatmapContentState extends State<_MindSumHeatmapContent> {
  late final ScrollController _heatmapScrollController;
  late final ScrollController _lineScrollController;
  late final ScrollController _barScrollController;
  var _visualization = _MindSumVisualization.heatmap;

  @override
  void initState() {
    super.initState();
    _heatmapScrollController = ScrollController();
    _lineScrollController = ScrollController();
    _barScrollController = ScrollController();
    _logVisualization(reason: 'initial');
  }

  @override
  void didUpdateWidget(covariant _MindSumHeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A range preview keeps the same immutable identity and therefore keeps
    // the locally selected surface and both scroll positions. A new admitted
    // identity starts on the heatmap without writing Query, Time or prepared
    // data.
    if (oldWidget.frame.identity != widget.frame.identity) {
      _visualization = _MindSumVisualization.heatmap;
      _logVisualization(reason: 'frameIdentityReset');
    }
  }

  @override
  void dispose() {
    _heatmapScrollController.dispose();
    _lineScrollController.dispose();
    _barScrollController.dispose();
    super.dispose();
  }

  void _selectVisualization(_MindSumVisualization target) {
    if (_visualization == target) return;
    setState(() => _visualization = target);
    _logVisualization(reason: 'topToggle');
  }

  void _logVisualization({required String reason}) {
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'MIND_SUM|MODE',
        scope:
            'mode=${_visualization.name} reason=$reason '
            'visibleYears=${widget.frame.years.length} '
            'renderedBands=${widget.frame.years.length}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final years = widget.frame.years;
    final period = years.isEmpty
        ? '— · 0 hónap'
        : '${years.first}–${years.last} · ${years.length * 12} hónap';
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      'Többéves aktivitás',
                      key: ValueKey<String>('mind-sum-heatmap-title'),
                      style: TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      period,
                      key: const ValueKey<String>('mind-sum-heatmap-period'),
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 9,
                      ),
                    ),
                  ],
                ),
              ),
              ToggleButtons(
                key: const ValueKey<String>('mind-sum-detail-mode-toggle'),
                constraints: const BoxConstraints.tightFor(
                  width: 42,
                  height: 22,
                ),
                borderRadius: BorderRadius.circular(8),
                isSelected: <bool>[
                  _visualization == _MindSumVisualization.heatmap,
                  _visualization == _MindSumVisualization.detailed,
                  _visualization == _MindSumVisualization.monthlyOverlay,
                ],
                onPressed: (index) => _selectVisualization(switch (index) {
                  0 => _MindSumVisualization.heatmap,
                  1 => _MindSumVisualization.detailed,
                  _ => _MindSumVisualization.monthlyOverlay,
                }),
                children: const <Widget>[
                  Tooltip(
                    key: ValueKey<String>('mind-sum-detail-toggle-heatmap'),
                    message: 'Hőtérkép',
                    child: Icon(Icons.grid_view_rounded, size: 13),
                  ),
                  Tooltip(
                    key: ValueKey<String>('mind-sum-detail-toggle-line'),
                    message: 'Vonal',
                    child: Icon(Icons.show_chart, size: 13),
                  ),
                  Tooltip(
                    key: ValueKey<String>('mind-sum-detail-toggle-bars'),
                    message: 'Havi összevetés',
                    child: Icon(Icons.bar_chart_rounded, size: 13),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 5),
          Expanded(
            child: switch (_visualization) {
              _MindSumVisualization.heatmap =>
                DashboardVerticalScrollBoundaryHandoff(
                  upperVerticalGestures: widget.upperVerticalGestures,
                  child: _MindSumHeatmapPage(
                    key: const ValueKey<String>('mind-sum-heatmap-surface'),
                    frame: widget.frame,
                    paletteStyle: widget.paletteStyle,
                    scaleResolution: widget.scaleResolution,
                    layout: widget.sumYearRowLayout,
                    labelPlacement: widget.sumMonthLabelPlacement,
                    scrollController: _heatmapScrollController,
                  ),
                ),
              _MindSumVisualization.detailed => _MindSumLinePage(
                key: const ValueKey<String>('mind-sum-detailed-surface'),
                frame: widget.frame,
                paletteStyle: widget.paletteStyle,
                scaleResolution: widget.scaleResolution,
                scrollController: _lineScrollController,
                upperVerticalGestures: widget.upperVerticalGestures,
              ),
              _MindSumVisualization.monthlyOverlay =>
                _MindSumMonthlyOverlayPage(
                  key: const ValueKey<String>(
                    'mind-sum-monthly-overlay-surface',
                  ),
                  frame: widget.frame,
                  paletteStyle: widget.paletteStyle,
                  scaleResolution: widget.scaleResolution,
                  scrollController: _barScrollController,
                  upperVerticalGestures: widget.upperVerticalGestures,
                ),
            },
          ),
        ],
      ),
    );
  }
}

enum _MindSumVisualization { heatmap, detailed, monthlyOverlay }

final class _MindSumHeatmapPage extends StatefulWidget {
  const _MindSumHeatmapPage({
    super.key,
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.layout,
    required this.labelPlacement,
    required this.scrollController,
  });

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindSumYearRowLayout layout;
  final MindSumMonthLabelPlacement labelPlacement;
  final ScrollController scrollController;

  @override
  State<_MindSumHeatmapPage> createState() => _MindSumHeatmapPageState();
}

final class _MindSumHeatmapPageState extends State<_MindSumHeatmapPage> {
  final _cardKey = GlobalKey();
  _MindSumMonthSelection? _selectedMonth;

  @override
  void didUpdateWidget(covariant _MindSumHeatmapPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.identity != widget.frame.identity) {
      _selectedMonth = null;
    }
  }

  @override
  Widget build(BuildContext context) => Stack(
    key: _cardKey,
    children: <Widget>[
      ListView.separated(
        key: const ValueKey<String>('mind-sum-heatmap-scroll'),
        controller: widget.scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        padding: EdgeInsets.zero,
        itemCount: widget.frame.years.length,
        separatorBuilder: (_, _) => const SizedBox(height: 8),
        itemBuilder: (context, index) => _MindSumYearHeatmapUnit(
          frame: widget.frame,
          year: widget.frame.years[index],
          paletteStyle: widget.paletteStyle,
          scaleResolution: widget.scaleResolution,
          layout: widget.layout,
          labelPlacement: widget.labelPlacement,
          onMonthTap: (month, anchor) => setState(() {
            final selected = _selectedMonth;
            _selectedMonth =
                selected?.month.year == month.year &&
                    selected?.month.month == month.month
                ? null
                : _MindSumMonthSelection(month, anchor);
          }),
        ),
      ),
      if (_selectedMonth case final selected?)
        MindAnchoredInfoCard(
          globalAnchor: selected.anchor,
          cardKey: _cardKey,
          ignorePointer: true,
          child: _MindSumMonthInfoCard(month: selected.month),
        ),
    ],
  );
}

final class _MindSumMonthSelection {
  const _MindSumMonthSelection(this.month, this.anchor);

  final MindSumHeatmapMonth month;
  final Offset anchor;
}

final class _MindSumYearHeatmapUnit extends StatelessWidget {
  const _MindSumYearHeatmapUnit({
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.layout,
    required this.labelPlacement,
    required this.onMonthTap,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindSumYearRowLayout layout;
  final MindSumMonthLabelPlacement labelPlacement;
  final void Function(MindSumHeatmapMonth month, Offset anchor) onMonthTap;

  @override
  Widget build(BuildContext context) {
    final cells = _MindSumMonthCells(
      frame: frame,
      year: year,
      paletteStyle: paletteStyle,
      scaleResolution: scaleResolution,
      labelPlacement: labelPlacement,
      onMonthTap: onMonthTap,
    );
    if (layout == MindSumYearRowLayout.oneRowCompact) {
      return Row(
        key: ValueKey<String>('mind-sum-heatmap-year-$year'),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            key: ValueKey<String>('mind-sum-heatmap-compact-year-$year'),
            width: 36,
            height: 22,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '$year',
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: KeyedSubtree(
              key: ValueKey<String>('mind-sum-heatmap-compact-cells-$year'),
              child: cells,
            ),
          ),
          const SizedBox(width: 4),
          SizedBox(
            key: ValueKey<String>('mind-sum-heatmap-compact-total-$year'),
            width: 56,
            height: 22,
            child: Align(
              alignment: Alignment.centerRight,
              child: Text(
                formatMindCompactForints(frame.yearTotal(year) ~/ 100),
                textAlign: TextAlign.right,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 8,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
        ],
      );
    }
    return Column(
      key: ValueKey<String>('mind-sum-heatmap-year-$year'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _MindSumYearHeader(frame: frame, year: year, page: 'heatmap'),
        const SizedBox(height: 4),
        cells,
      ],
    );
  }
}

/// The cell strip owns aligned tile and label geometry for both Sum layouts.
/// Every label gets the exact same Expanded/Padding envelope as its month tile;
/// it cannot degrade into one unrelated centred text string.
final class _MindSumMonthCells extends StatelessWidget {
  const _MindSumMonthCells({
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.labelPlacement,
    required this.onMonthTap,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final MindSumMonthLabelPlacement labelPlacement;
  final void Function(MindSumHeatmapMonth month, Offset anchor) onMonthTap;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      SizedBox(
        height: 22,
        child: Row(
          children: List<Widget>.generate(12, (monthIndex) {
            final month = monthIndex + 1;
            final item = frame.month(year: year, month: month);
            final palette = MindYearHeatmapPaletteResolver.resolveTile(
              style: paletteStyle,
              isEmpty: item.isEmpty,
              intensity: item.intensity,
              paletteIntensity: item.paletteIntensity,
              scaleResolution: scaleResolution,
            );
            return Expanded(
              child: Padding(
                padding: EdgeInsets.only(right: month == 12 ? 0 : 2),
                child: Builder(
                  builder: (cellContext) => GestureDetector(
                    key: ValueKey<String>('mind-sum-heatmap-tap-$year-$month'),
                    behavior: HitTestBehavior.opaque,
                    onTap: item.isEmpty
                        ? null
                        : () {
                            final box =
                                cellContext.findRenderObject() as RenderBox?;
                            final anchor = box == null
                                ? Offset.zero
                                : box.localToGlobal(
                                    box.size.center(Offset.zero),
                                  );
                            onMonthTap(item, anchor);
                          },
                    child: DecoratedBox(
                      key: ValueKey<String>(
                        'mind-sum-heatmap-cell-$year-$month',
                      ),
                      decoration: BoxDecoration(
                        color: palette.background,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Center(
                        child:
                            labelPlacement ==
                                MindSumMonthLabelPlacement.insideMonthCells
                            ? Text(
                                _monthInitials[monthIndex],
                                style: const TextStyle(
                                  fontSize: 7,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              )
                            : const SizedBox.expand(),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }, growable: false),
        ),
      ),
      if (labelPlacement == MindSumMonthLabelPlacement.belowEachRow)
        SizedBox(
          height: 10,
          child: Row(
            children: List<Widget>.generate(
              12,
              (monthIndex) => Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: monthIndex == 11 ? 0 : 2),
                  child: Center(
                    child: Text(
                      _monthInitials[monthIndex],
                      key: ValueKey<String>(
                        'mind-sum-heatmap-month-label-$year-${monthIndex + 1}',
                      ),
                      style: const TextStyle(
                        fontSize: 7,
                        color: FluviVisualTokens.textSecondary,
                      ),
                    ),
                  ),
                ),
              ),
              growable: false,
            ),
          ),
        ),
    ],
  );
}

const _monthInitials = <String>[
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

final class _MindSumMonthInfoCard extends StatelessWidget {
  const _MindSumMonthInfoCard({required this.month});

  final MindSumHeatmapMonth month;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: const ValueKey<String>('mind-sum-month-infocard'),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(10),
      boxShadow: const <BoxShadow>[
        BoxShadow(color: Color(0x22000000), blurRadius: 12),
      ],
    ),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(8, 5, 4, 5),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            '${month.year}. ${DashboardTimeLabelFormatter.monthName(month.month)}\n${formatMindCompactForints((month.total ?? 0) ~/ 100)}',
            style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    ),
  );
}

final class _MindSumLinePage extends StatelessWidget {
  const _MindSumLinePage({
    super.key,
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.scrollController,
    this.upperVerticalGestures,
  });

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final ScrollController scrollController;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  Widget build(BuildContext context) => MindDetailedSumChart(
    frame: frame,
    lineColor: MindYearHeatmapPaletteResolver.resolveTile(
      style: paletteStyle,
      isEmpty: false,
      intensity: 1,
      paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
      scaleResolution: scaleResolution,
    ).background,
    scrollController: scrollController,
    upperVerticalGestures: upperVerticalGestures,
  );
}

/// Sum's third presentation surface compares the already-admitted selected
/// scope/range against its full selected-direction months. It is deliberately
/// stacked by year like the detailed chart, but has no separate query or range
/// authority.
final class _MindSumMonthlyOverlayPage extends StatelessWidget {
  const _MindSumMonthlyOverlayPage({
    super.key,
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
    required this.scrollController,
    this.upperVerticalGestures,
  });

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final ScrollController scrollController;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  Widget build(BuildContext context) => DashboardVerticalScrollBoundaryHandoff(
    upperVerticalGestures: upperVerticalGestures,
    child: ListView.separated(
      key: const ValueKey<String>('mind-sum-monthly-overlay-scroll'),
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(2, 1, 2, 4),
      itemCount: frame.years.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final year = frame.years[index];
        return _MindSumMonthlyOverlayYear(
          key: ValueKey<String>('mind-sum-monthly-overlay-year-$year'),
          frame: frame,
          year: year,
          paletteStyle: paletteStyle,
          scaleResolution: scaleResolution,
        );
      },
    ),
  );
}

final class _MindSumMonthlyOverlayYear extends StatelessWidget {
  const _MindSumMonthlyOverlayYear({
    super.key,
    required this.frame,
    required this.year,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) {
    final series = mindSumMonthlyOverlaySeries(frame: frame, year: year);
    Color colorFor(MindMonthlyOverlayValue value) {
      final month = frame.month(year: year, month: value.month);
      return MindYearHeatmapPaletteResolver.resolveTile(
        style: paletteStyle,
        isEmpty: month.isEmpty,
        intensity: month.intensity,
        paletteIntensity: month.paletteIntensity,
        scaleResolution: scaleResolution,
      ).background;
    }

    return SizedBox(
      height: 144,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MindSumYearHeader(frame: frame, year: year, page: 'monthly-overlay'),
          const SizedBox(height: 2),
          Expanded(
            child: CustomPaint(
              key: ValueKey<String>('mind-sum-monthly-overlay-chart-$year'),
              painter: MindMonthlyOverlayBarPainter(
                series: series,
                foregroundForValue: colorFor,
                paintIdentity: Object.hash(
                  frame,
                  paletteStyle,
                  scaleResolution,
                ),
              ),
            ),
          ),
          const SizedBox(height: 2),
          const _MindSumMonthlyOverlayAxis(),
        ],
      ),
    );
  }
}

@visibleForTesting
MindMonthlyOverlaySeries mindSumMonthlyOverlaySeries({
  required MindSumHeatmapFrame frame,
  required int year,
}) => MindMonthlyOverlaySeries.fromTotals(
  fullAmounts: List<int>.generate(
    12,
    (index) => frame.fullMonthTotal(year: year, month: index + 1),
    growable: false,
  ),
  filteredAmounts: List<int>.generate(
    12,
    (index) => frame.month(year: year, month: index + 1).total ?? 0,
    growable: false,
  ),
);

final class _MindSumMonthlyOverlayAxis extends StatelessWidget {
  const _MindSumMonthlyOverlayAxis();

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      const SizedBox(width: 30),
      for (final initial in _mindMonthInitials)
        Expanded(
          child: Center(
            child: Text(
              initial,
              style: TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),
    ],
  );
}

const _mindMonthInitials = <String>[
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

final class _MindSumYearHeader extends StatelessWidget {
  const _MindSumYearHeader({
    required this.frame,
    required this.year,
    required this.page,
  });

  final MindSumHeatmapFrame frame;
  final int year;
  final String page;

  @override
  Widget build(BuildContext context) => SizedBox(
    key: ValueKey<String>('mind-sum-$page-year-header-$year'),
    height: 18,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(
              '$year',
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 10,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ),
        DecoratedBox(
          decoration: BoxDecoration(
            color: FluviVisualTokens.surfaceMuted,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            child: Text(
              formatMindCompactForints(frame.yearTotal(year) ~/ 100),
              key: ValueKey<String>('mind-sum-heatmap-total-$year'),
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 8,
                fontWeight: FontWeight.w800,
              ),
            ),
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
    this.upperVerticalGestures,
  });

  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final ValueListenable<MindYearHeatmapPresentationSettings>?
  presentationSettings;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

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
          Widget content(
            MindYearHeatmapPaletteStyle style,
            MindHeatmapScaleResolution scaleResolution,
          ) => _MindMonthHeatmapContent(
            frame: frame,
            frameListenable: frameListenable,
            paletteStyle: style,
            scaleResolution: scaleResolution,
            upperVerticalGestures: upperVerticalGestures,
          );
          final settings = presentationSettings;
          if (settings == null) {
            return content(
              MindYearHeatmapPaletteStyle.fluvi,
              MindHeatmapScaleResolution.ten,
            );
          }
          return ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
            valueListenable: settings,
            builder: (context, value, _) =>
                content(value.paletteStyle, value.scaleResolution),
          );
        },
      );
}

final class _MindMonthHeatmapContent extends StatefulWidget {
  const _MindMonthHeatmapContent({
    required this.frame,
    required this.frameListenable,
    required this.paletteStyle,
    required this.scaleResolution,
    this.upperVerticalGestures,
  });

  final MindMonthHeatmapFrame frame;
  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<_MindMonthHeatmapContent> createState() =>
      _MindMonthHeatmapContentState();
}

final class _MindMonthHeatmapContentState
    extends State<_MindMonthHeatmapContent> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _MindMonthHeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.identity != widget.frame.identity &&
        _pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DashboardVerticalScrollBoundaryHandoff(
    upperVerticalGestures: widget.upperVerticalGestures,
    handoffOnDirectVerticalDrag: true,
    child: PageView(
      key: const ValueKey<String>('mind-month-heatmap-pager'),
      controller: _pageController,
      children: <Widget>[
        KeyedSubtree(
          key: const ValueKey<String>('mind-month-heatmap-page-0'),
          child: _MindMonthHeatmapPage(
            frame: widget.frame,
            frameListenable: widget.frameListenable,
            paletteStyle: widget.paletteStyle,
            scaleResolution: widget.scaleResolution,
          ),
        ),
        KeyedSubtree(
          key: const ValueKey<String>('mind-month-heatmap-page-1'),
          child: MindMonthDailyRhythmCard(
            frame: widget.frame,
            paletteStyle: widget.paletteStyle,
            scaleResolution: widget.scaleResolution,
          ),
        ),
      ],
    ),
  );
}

final class _MindMonthHeatmapPage extends StatelessWidget {
  const _MindMonthHeatmapPage({
    required this.frame,
    required this.frameListenable,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindMonthHeatmapFrame frame;
  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

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
        const referenceGridWidth = 282.0;
        // The B3M-MYM header has two horizontal information rows plus the
        // compact total/footer and outer padding. Solve only the real
        // calendar row count so a five-row month is never shrunk by a fake
        // sixth presentation row.
        const staticChrome = 77.0;
        final availableGridWidth =
            (constraints.maxWidth - horizontalPadding * 2)
                .clamp(0.0, double.infinity)
                .toDouble();
        final boundedGridWidth = math.min(
          availableGridWidth,
          referenceGridWidth,
        );
        final cellByWidth = ((boundedGridWidth - gap * 6) / 7)
            .clamp(0.0, double.infinity)
            .toDouble();
        final calendarRows = geometry.rowCount;
        final cellByHeight = constraints.maxHeight.isFinite
            ? ((constraints.maxHeight -
                          staticChrome -
                          gap * (calendarRows - 1)) /
                      calendarRows)
                  .clamp(0.0, double.infinity)
                  .toDouble()
            : cellByWidth;
        final cellExtent = math.min(cellByWidth, cellByHeight);
        final gridWidth = cellExtent * 7 + gap * 6;
        final gridHeight = cellExtent * calendarRows + gap * (calendarRows - 1);
        return Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              SizedBox(
                key: const ValueKey<String>('mind-month-heatmap-header-row'),
                height: 20,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text(
                      'Napi aktivitás',
                      key: ValueKey<String>('mind-month-heatmap-title'),
                      style: TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${frame.days.length} nap',
                      key: const ValueKey<String>(
                        'mind-month-heatmap-day-count',
                      ),
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                key: const ValueKey<String>('mind-month-heatmap-summary-row'),
                height: 17,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Text(
                      '${DashboardTimeLabelFormatter.monthName(frame.month)} ${frame.year}',
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    Text(
                      '${frame.activeDayCount} aktív nap',
                      key: const ValueKey<String>(
                        'mind-month-heatmap-active-days',
                      ),
                      style: const TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 8,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 7),
              Align(
                alignment: Alignment.topCenter,
                child: SizedBox(
                  key: const ValueKey<String>('mind-month-heatmap-grid'),
                  width: gridWidth,
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
                            scaleResolution: scaleResolution,
                            cellExtent: cellExtent,
                            gap: gap,
                          ),
                        ),
                      ),
                      ...frame.days.map((day) {
                        final slot = geometry.slotIndexForDay(day.date.day);
                        final row = slot ~/ 7;
                        final column = slot % 7;
                        final palette = MindYearHeatmapPaletteResolver.resolve(
                          style: paletteStyle,
                          day: day,
                          scaleResolution: scaleResolution,
                        );
                        return Positioned(
                          left: column * (cellExtent + gap),
                          top: row * (cellExtent + gap),
                          width: cellExtent,
                          height: cellExtent,
                          child: IgnorePointer(
                            child: Padding(
                              padding: const EdgeInsets.all(3),
                              child: Align(
                                alignment: Alignment.topLeft,
                                child: Text(
                                  '${day.date.day}',
                                  style: TextStyle(
                                    color: palette.foreground,
                                    fontSize: 7,
                                    fontWeight: FontWeight.w900,
                                    height: 1,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        );
                      }),
                    ],
                  ),
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
    required this.scaleResolution,
    required this.cellExtent,
    required this.gap,
  }) : super(repaint: frameListenable);

  final MindYearHeatmapCalendarGeometry geometry;
  final ValueListenable<MindTemporalHeatmapFrame?> frameListenable;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
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
        scaleResolution: scaleResolution,
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
          const Radius.circular(mindMonthHeatmapCellCornerRadius),
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
      scaleResolution != oldDelegate.scaleResolution ||
      cellExtent != oldDelegate.cellExtent ||
      gap != oldDelegate.gap;
}

/// The existing Month-plane [DayScope] has one compact, non-scrollable daily
/// activity surface.  It consumes Core's immutable 24-hour frame and never
/// owns query, score or temporal navigation state.
final class MindDayHeatmapViewport extends StatelessWidget {
  const MindDayHeatmapViewport({
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
          final frame = current is MindDayHeatmapFrame ? current : null;
          if (frame == null) {
            return const SizedBox(
              key: ValueKey<String>('mind-day-heatmap-unavailable'),
            );
          }
          Widget content(
            MindYearHeatmapPaletteStyle style,
            MindHeatmapScaleResolution scaleResolution,
          ) => _MindDayHeatmapContent(
            frame: frame,
            paletteStyle: style,
            scaleResolution: scaleResolution,
          );
          final settings = presentationSettings;
          if (settings == null) {
            return content(
              MindYearHeatmapPaletteStyle.fluvi,
              MindHeatmapScaleResolution.ten,
            );
          }
          return ValueListenableBuilder<MindYearHeatmapPresentationSettings>(
            valueListenable: settings,
            builder: (context, value, _) =>
                content(value.paletteStyle, value.scaleResolution),
          );
        },
      );
}

final class _MindDayHeatmapContent extends StatefulWidget {
  const _MindDayHeatmapContent({
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindDayHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  State<_MindDayHeatmapContent> createState() => _MindDayHeatmapContentState();
}

final class _MindDayHeatmapContentState extends State<_MindDayHeatmapContent> {
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
  }

  @override
  void didUpdateWidget(covariant _MindDayHeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.frame.identity != widget.frame.identity &&
        _pageController.hasClients) {
      _pageController.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => PageView(
    key: const ValueKey<String>('mind-day-heatmap-pager'),
    controller: _pageController,
    children: <Widget>[
      KeyedSubtree(
        key: const ValueKey<String>('mind-day-heatmap-page-0'),
        child: _MindDayHeatmapPage(
          frame: widget.frame,
          paletteStyle: widget.paletteStyle,
          scaleResolution: widget.scaleResolution,
        ),
      ),
      KeyedSubtree(
        key: const ValueKey<String>('mind-day-heatmap-page-1'),
        child: MindDayTransactionTimelineCard(
          frame: widget.frame,
          paletteStyle: widget.paletteStyle,
          scaleResolution: widget.scaleResolution,
        ),
      ),
    ],
  );
}

final class _MindDayHeatmapPage extends StatelessWidget {
  const _MindDayHeatmapPage({
    required this.frame,
    required this.paletteStyle,
    required this.scaleResolution,
  });

  final MindDayHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      const horizontalPadding = 12.0;
      const gap = 4.0;
      const staticChrome = 70.0;
      final gridAvailableWidth = (constraints.maxWidth - horizontalPadding * 2)
          .clamp(0.0, double.infinity)
          .toDouble();
      final cellByWidth = ((gridAvailableWidth - gap * 5) / 6)
          .clamp(0.0, double.infinity)
          .toDouble();
      final cellByHeight = constraints.maxHeight.isFinite
          ? ((constraints.maxHeight - staticChrome - gap * 3) / 4)
                .clamp(0.0, double.infinity)
                .toDouble()
          : cellByWidth;
      final cellExtent = math.min(cellByWidth, cellByHeight);
      final gridWidth = cellExtent * 6 + gap * 5;
      final gridHeight = cellExtent * 4 + gap * 3;
      final date = DashboardTimeLabelFormatter.date(
        YearMonth(year: frame.date.year, month: frame.date.month),
        frame.date.day,
      );
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 6),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              height: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  const Text(
                    'Óránkénti aktivitás',
                    key: ValueKey<String>('mind-day-heatmap-title'),
                    style: TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    '${frame.activeHourCount} aktív óra',
                    key: const ValueKey<String>(
                      'mind-day-heatmap-active-hours',
                    ),
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 17,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: <Widget>[
                  Text(
                    date,
                    key: const ValueKey<String>('mind-day-heatmap-date'),
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  Text(
                    QueryMenuFormatters.money(frame.total),
                    key: const ValueKey<String>(
                      'mind-day-heatmap-summary-total',
                    ),
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 8,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 7),
            Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                key: const ValueKey<String>('mind-day-heatmap-grid'),
                width: gridWidth,
                height: gridHeight,
                child: Column(
                  children: List<Widget>.generate(4, (row) {
                    return Padding(
                      padding: EdgeInsets.only(bottom: row == 3 ? 0 : gap),
                      child: Row(
                        children: List<Widget>.generate(6, (column) {
                          final hour = row * 6 + column;
                          final tile = frame.hour(hour);
                          final palette =
                              MindYearHeatmapPaletteResolver.resolveTile(
                                style: paletteStyle,
                                isEmpty: tile.isEmpty,
                                intensity: tile.intensity,
                                paletteIntensity: tile.paletteIntensity,
                                scaleResolution: scaleResolution,
                              );
                          return Padding(
                            padding: EdgeInsets.only(
                              right: column == 5 ? 0 : gap,
                            ),
                            child: SizedBox(
                              width: cellExtent,
                              height: cellExtent,
                              child: DecoratedBox(
                                key: ValueKey<String>(
                                  'mind-day-heatmap-cell-${hour.toString().padLeft(2, '0')}',
                                ),
                                decoration: BoxDecoration(
                                  color: palette.background,
                                  borderRadius: BorderRadius.circular(
                                    mindMonthHeatmapCellCornerRadius,
                                  ),
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.all(3),
                                  child: Align(
                                    alignment: Alignment.topLeft,
                                    child: Text(
                                      hour.toString().padLeft(2, '0'),
                                      style: TextStyle(
                                        color: palette.foreground,
                                        fontSize: 7,
                                        fontWeight: FontWeight.w900,
                                        height: 1,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          );
                        }, growable: false),
                      ),
                    );
                  }, growable: false),
                ),
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
                  key: const ValueKey<String>('mind-day-heatmap-total'),
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
