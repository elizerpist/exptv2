import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../presentation/dashboard_paged_vertical_boundary_handoff.dart';
import '../../presentation/dashboard_upper_vertical_gesture_coordinator.dart';
import '../../presentation/dashboard_vertical_scroll_boundary_handoff.dart';
import '../../query/presentation/query_menu_formatters.dart';
import '../../time_navigation/domain/year_month.dart';
import '../../time_navigation/domain/local_date.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import '../domain/mind_temporal_heatmap_frame.dart';
import '../domain/mind_temporal_heatmap_projection.dart';
import '../domain/mind_year_heatmap_calendar_geometry.dart';
import '../domain/mind_year_heatmap_presentation_settings.dart';
import '../domain/mind_year_heatmap_projection.dart';
import 'mind_year_heatmap_palette_resolver.dart';
import 'mind_aggregate_line_chart.dart';

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
  late final PageController _pageController;
  late final ScrollController _heatmapScrollController;
  late final ScrollController _lineScrollController;
  var _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    _heatmapScrollController = ScrollController();
    _lineScrollController = ScrollController();
  }

  @override
  void didUpdateWidget(covariant _MindSumHeatmapContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    // A range preview keeps the same immutable identity and therefore keeps
    // the visual page and both scroll positions. A new admitted identity
    // starts on the heatmap without writing Query, Time or prepared data.
    if (oldWidget.frame.identity != widget.frame.identity &&
        _pageController.hasClients) {
      _pageController.jumpToPage(0);
      _currentPage = 0;
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    _heatmapScrollController.dispose();
    _lineScrollController.dispose();
    super.dispose();
  }

  ScrollController get _activePageScrollController {
    final page = _pageController.hasClients ? _pageController.page : 0;
    return (page ?? 0).round() == 2
        ? _lineScrollController
        : _heatmapScrollController;
  }

  @override
  Widget build(BuildContext context) {
    final years = widget.frame.years;
    final period = years.isEmpty
        ? '— · 0 hónap'
        : '${years.first}–${years.last} · ${years.length * 12} hónap';
    final pageTitle = switch (_currentPage) {
      0 => 'Többéves aktivitás',
      1 => 'Többéves alakulás',
      _ => 'Többéves aktivitás',
    };
    final pagePeriod = _currentPage == 1
        ? (years.isEmpty
              ? '— · 0 év'
              : '${years.first}–${years.last} · ${years.length} év')
        : period;
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            pageTitle,
            key: ValueKey<String>('mind-sum-heatmap-title'),
            style: TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 1),
          Text(
            pagePeriod,
            key: const ValueKey<String>('mind-sum-heatmap-period'),
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: DashboardPagedVerticalBoundaryHandoff(
              upperVerticalGestures: widget.upperVerticalGestures,
              activePageScrollController: () => _activePageScrollController,
              child: PageView(
                key: const ValueKey<String>('mind-sum-heatmap-pager'),
                controller: _pageController,
                onPageChanged: (page) => setState(() => _currentPage = page),
                children: <Widget>[
                  _MindSumHeatmapPage(
                    key: const ValueKey<String>('mind-sum-heatmap-page-0'),
                    frame: widget.frame,
                    paletteStyle: widget.paletteStyle,
                    scaleResolution: widget.scaleResolution,
                    layout: widget.sumYearRowLayout,
                    labelPlacement: widget.sumMonthLabelPlacement,
                    scrollController: _heatmapScrollController,
                  ),
                  _MindSumExactYearPage(
                    key: const ValueKey<String>('mind-sum-heatmap-page-1'),
                    frame: widget.frame,
                    paletteStyle: widget.paletteStyle,
                    scaleResolution: widget.scaleResolution,
                  ),
                  _MindSumLinePage(
                    key: const ValueKey<String>('mind-sum-heatmap-page-2'),
                    frame: widget.frame,
                    paletteStyle: widget.paletteStyle,
                    scaleResolution: widget.scaleResolution,
                    scrollController: _lineScrollController,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

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
    children: <Widget>[
      ListView.separated(
        key: const ValueKey<String>('mind-sum-heatmap-scroll'),
        controller: widget.scrollController,
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
          onMonthTap: (month, anchor) => setState(
            () => _selectedMonth = _MindSumMonthSelection(month, anchor),
          ),
        ),
      ),
      if (_selectedMonth case final selected?)
        Builder(
          builder: (context) {
            final box = context.findRenderObject() as RenderBox?;
            final origin = box?.localToGlobal(Offset.zero) ?? Offset.zero;
            final localAnchor = selected.anchor - origin;
            final left = (localAnchor.dx - 62)
                .clamp(2.0, math.max(2.0, (box?.size.width ?? 128) - 126))
                .toDouble();
            final top = localAnchor.dy < 68
                ? localAnchor.dy + 10
                : localAnchor.dy - 52;
            return Positioned(
              top: top.clamp(2.0, math.max(2.0, (box?.size.height ?? 64) - 48)),
              left: left,
              child: _MindSumMonthInfoCard(
                month: selected.month,
                onDismiss: () => setState(() => _selectedMonth = null),
              ),
            );
          },
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
  Widget build(BuildContext context) => Column(
    key: ValueKey<String>('mind-sum-heatmap-year-$year'),
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: <Widget>[
      if (layout == MindSumYearRowLayout.twoRowExpanded) ...<Widget>[
        _MindSumYearHeader(frame: frame, year: year, page: 'heatmap'),
        const SizedBox(height: 4),
      ],
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
                  builder: (cellContext) {
                    return InkWell(
                      key: ValueKey<String>(
                        'mind-sum-heatmap-tap-$year-$month',
                      ),
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
                    );
                  },
                ),
              ),
            );
          }, growable: false),
        ),
      ),
      if (labelPlacement == MindSumMonthLabelPlacement.belowEachRow)
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Text(
            'J   F   M   Á   M   J   J   A   S   O   N   D',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 7,
              color: FluviVisualTokens.textSecondary,
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

final class _MindSumExactYearPage extends StatelessWidget {
  const _MindSumExactYearPage({
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
    final points = frame.yearlyPoints;
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: MindAggregateLineChart(
        points: points,
        title: '',
        subtitle: '',
        lineColor: const Color(0xff7657c5),
        relativeLabel: 'az előző évhez képest',
      ),
    );
  }
}

final class _MindSumMonthInfoCard extends StatelessWidget {
  const _MindSumMonthInfoCard({required this.month, required this.onDismiss});

  final MindSumHeatmapMonth month;
  final VoidCallback onDismiss;

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
          IconButton(
            key: const ValueKey<String>('mind-sum-month-infocard-dismiss'),
            iconSize: 14,
            visualDensity: VisualDensity.compact,
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
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
  });

  final MindSumHeatmapFrame frame;
  final MindYearHeatmapPaletteStyle paletteStyle;
  final MindHeatmapScaleResolution scaleResolution;
  final ScrollController scrollController;

  @override
  Widget build(BuildContext context) => ListView.separated(
    key: const ValueKey<String>('mind-sum-line-scroll'),
    controller: scrollController,
    padding: EdgeInsets.zero,
    itemCount: frame.years.length,
    separatorBuilder: (_, _) => const SizedBox(height: 8),
    itemBuilder: (context, index) {
      final year = frame.years[index];
      final lineColor = MindYearHeatmapPaletteResolver.resolveTile(
        style: paletteStyle,
        isEmpty: false,
        intensity: 1,
        paletteIntensity: MindYearHeatmapPaletteIntensity.maximum,
        scaleResolution: scaleResolution,
      ).background;
      return Column(
        key: ValueKey<String>('mind-sum-line-year-$year'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _MindSumYearHeader(frame: frame, year: year, page: 'line'),
          const SizedBox(height: 4),
          SizedBox(
            height: 86,
            child: CustomPaint(
              key: ValueKey<String>('mind-sum-line-chart-$year'),
              painter: MindSumYearTrendPainter(
                year: year,
                points: frame.dailyPointsForYear(year),
                lineColor: lineColor,
              ),
            ),
          ),
        ],
      );
    },
  );
}

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

/// Paint-only chart geometry over exact immutable daily anchors. Dashed month
/// boundaries and month-center markers are calendar guides; they do not add
/// financial observations or mutate the admitted Sum frame.
@visibleForTesting
final class MindSumYearTrendPainter extends CustomPainter {
  MindSumYearTrendPainter({
    required this.year,
    required List<MindSumHeatmapDailyPoint> points,
    required this.lineColor,
  }) : points = List<MindSumHeatmapDailyPoint>.unmodifiable(points);

  final int year;
  final List<MindSumHeatmapDailyPoint> points;
  final Color lineColor;

  List<double> get monthBoundaryFractions =>
      List<double>.generate(11, (index) => (index + 1) / 12, growable: false);

  @override
  void paint(Canvas canvas, Size size) {
    if (size.width <= 0 || size.height <= 0) return;
    const left = 5.0;
    const right = 3.0;
    const top = 6.0;
    const bottom = 7.0;
    final plot = Rect.fromLTWH(
      left,
      top,
      math.max(0, size.width - left - right),
      math.max(0, size.height - top - bottom),
    );
    if (plot.width <= 0 || plot.height <= 0) return;

    final guidePaint = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .20)
      ..strokeWidth = 1;
    for (final fraction in monthBoundaryFractions) {
      final x = plot.left + plot.width * fraction;
      for (var y = plot.top; y < plot.bottom; y += 4) {
        canvas.drawLine(
          Offset(x, y),
          Offset(x, math.min(y + 2, plot.bottom)),
          guidePaint,
        );
      }
    }
    for (var month = 0; month < 12; month += 1) {
      final x = plot.left + plot.width * ((month + .5) / 12);
      canvas.drawCircle(Offset(x, plot.bottom), 1.25, guidePaint);
    }
    if (points.isEmpty) return;

    final maximum = points.fold<int>(
      0,
      (current, point) => math.max(current, point.total),
    );
    if (maximum <= 0) return;
    final startEpoch = LocalDate(year: year, month: 1, day: 1).epochDay;
    final endEpoch = LocalDate(year: year, month: 12, day: 31).epochDay;
    Offset pointOffset(MindSumHeatmapDailyPoint point) {
      final fraction = endEpoch == startEpoch
          ? .5
          : ((point.date.epochDay - startEpoch) / (endEpoch - startEpoch))
                .clamp(0.0, 1.0)
                .toDouble();
      final normalized = (point.total / maximum).clamp(0.0, 1.0).toDouble();
      return Offset(
        plot.left + plot.width * fraction,
        plot.bottom - plot.height * normalized,
      );
    }

    final offsets = points.map(pointOffset).toList(growable: false);
    final line = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (final offset in offsets.skip(1)) {
      line.lineTo(offset.dx, offset.dy);
    }
    final fill = Path.from(line)
      ..lineTo(offsets.last.dx, plot.bottom)
      ..lineTo(offsets.first.dx, plot.bottom)
      ..close();
    canvas.drawPath(
      fill,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            lineColor.withValues(alpha: .30),
            lineColor.withValues(alpha: 0),
          ],
        ).createShader(plot),
    );
    canvas.drawPath(
      line,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
    final pointPaint = Paint()..color = lineColor;
    for (final offset in offsets) {
      canvas.drawCircle(offset, 1.75, pointPaint);
    }
  }

  @override
  bool shouldRepaint(covariant MindSumYearTrendPainter oldDelegate) =>
      year != oldDelegate.year ||
      lineColor != oldDelegate.lineColor ||
      !listEquals(points, oldDelegate.points);
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

final class _MindMonthHeatmapContent extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final geometry = MindYearHeatmapCalendarGeometry.forMonth(
      year: frame.year,
      month: frame.month,
    );
    return DashboardVerticalScrollBoundaryHandoff(
      upperVerticalGestures: upperVerticalGestures,
      handoffOnDirectVerticalDrag: true,
      child: LayoutBuilder(
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
          final gridHeight =
              cellExtent * calendarRows + gap * (calendarRows - 1);
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
                          final palette =
                              MindYearHeatmapPaletteResolver.resolve(
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
      ),
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

final class _MindDayHeatmapContent extends StatelessWidget {
  const _MindDayHeatmapContent({
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
