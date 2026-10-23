import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_year_clay_capsule_painter.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_focused_layout_geometry.dart';
import 'balance_year_focused_chart_presentation.dart';
import 'budget_clay_semicircle_gauge.dart';

enum BalanceYearPerspective {
  monthlyNet,
  cumulativeNet,
  incomeExpense;

  String get label => switch (this) {
    monthlyNet => 'Havi nettó',
    cumulativeNet => 'Kumulatív',
    incomeExpense => 'Bevétel/Kiadás',
  };
  String get title => switch (this) {
    monthlyNet => 'Havi eredmény',
    cumulativeNet => 'Egyenleg alakulása',
    incomeExpense => 'Bevétel és kiadás',
  };
  String get subtitle => switch (this) {
    monthlyNet => 'Az év nyereséges és veszteséges hónapjai',
    cumulativeNet => 'Az éves nettó eredmény felhalmozódása',
    incomeExpense => 'Havi pénzforgalom összehasonlítása',
  };
  IconData get icon => switch (this) {
    monthlyNet => Icons.bar_chart_rounded,
    cumulativeNet => Icons.show_chart_rounded,
    incomeExpense => Icons.stacked_bar_chart_rounded,
  };
}

/// A local presentation owner: selecting a perspective or month never reaches
/// Query, navigation, the header, or any repository/controller.
final class BalanceYearFocusedLayout extends StatefulWidget {
  const BalanceYearFocusedLayout({
    super.key,
    required this.presentation,
    this.initialPerspective = BalanceYearPerspective.monthlyNet,
    this.onPerspectiveChanged,
  });
  final BalanceAlternativeYearPresentation presentation;
  final BalanceYearPerspective initialPerspective;
  final ValueChanged<BalanceYearPerspective>? onPerspectiveChanged;

  @override
  State<BalanceYearFocusedLayout> createState() =>
      _BalanceYearFocusedLayoutState();
}

final class _BalanceYearFocusedLayoutState
    extends State<BalanceYearFocusedLayout> {
  late BalanceYearPerspective _perspective;
  int? _selectedMonth;
  late BalanceYearFocusedChartPresentation _chart;

  @override
  void initState() {
    super.initState();
    _perspective = widget.initialPerspective;
    _prepare();
  }

  @override
  void didUpdateWidget(covariant BalanceYearFocusedLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.sourcePresentationId !=
            widget.presentation.sourcePresentationId ||
        oldWidget.presentation.timeScope != widget.presentation.timeScope) {
      _prepare();
      _selectedMonth = null;
    }
  }

  void _prepare() {
    final source = widget.presentation;
    _chart = BalanceYearFocusedChartPresentation.fromIncomeExpense(
      source.incomeExpense,
      year: (source.timeScope as YearScope).year,
      logicalAsOfDate: source.logicalAsOfDate,
      transactionCounts: source.transactionCounts,
    );
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final selectorHeight = BalanceFocusedLayoutGeometry.topSectionHeight(
        constraints.maxHeight,
      );
      final compact = constraints.maxHeight < 240;
      final selected = _selectedMonth == null
          ? null
          : _chart.months[_selectedMonth! - 1];
      return Padding(
        key: const ValueKey('balance-year-focused-layout'),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        child: Column(
          children: [
            SizedBox(
              key: const ValueKey('balance-year-focused-selector-zone'),
              height: selectorHeight,
              child: _selector(selectorHeight),
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          _perspective.title,
                          key: const ValueKey(
                            'balance-year-focused-chart-title',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: FluviVisualTokens.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        '${_chart.year}',
                        style: const TextStyle(
                          fontSize: 10,
                          color: FluviVisualTokens.textSecondary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        _perspective.subtitle,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 9,
                          height: 1.15,
                          color: FluviVisualTokens.textSecondary,
                        ),
                      ),
                    ),
                  const SizedBox(height: 5),
                  Expanded(
                    child: RepaintBoundary(
                      key: const ValueKey(
                        'balance-year-focused-chart-boundary',
                      ),
                      child: LayoutBuilder(
                        builder: (context, box) {
                          final geometry =
                              BalanceYearFocusedChartGeometry.resolve(
                                box.biggest,
                                _chart,
                                _perspective,
                              );
                          return Stack(
                            fit: StackFit.expand,
                            children: [
                              CustomPaint(
                                key: ValueKey(
                                  'balance-year-focused-chart-${_perspective.name}',
                                ),
                                painter: BalanceYearFocusedChartPainter(
                                  presentation: _chart,
                                  perspective: _perspective,
                                  geometry: geometry,
                                  selectedMonth: _selectedMonth,
                                  labelFontFamily: DefaultTextStyle.of(
                                    context,
                                  ).style.fontFamily,
                                ),
                              ),
                              for (final month in _chart.months)
                                Positioned(
                                  left: geometry.slotLeft(month.month),
                                  top: 0,
                                  width: geometry.slot,
                                  bottom: 0,
                                  child: Semantics(
                                    button: true,
                                    selected: _selectedMonth == month.month,
                                    label:
                                        '${month.label}: ${_description(month)}',
                                    child: GestureDetector(
                                      key: ValueKey(
                                        'balance-year-month-${month.month}',
                                      ),
                                      behavior: HitTestBehavior.opaque,
                                      onTap: () => setState(
                                        () => _selectedMonth = month.month,
                                      ),
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                  if (!compact)
                    Padding(
                      padding: const EdgeInsets.only(top: 6, bottom: 9),
                      child: selected == null
                          ? _statistics()
                          : Text(
                              '${selected.label} · ${_description(selected)}',
                              key: const ValueKey(
                                'balance-year-focused-selected-month',
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 9,
                                height: 1.2,
                                color: FluviVisualTokens.textSecondary,
                              ),
                            ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );

  String _description(BalanceYearMonthPoint month) {
    if (month.isFuture && !month.hasRecordedTransactions) {
      return 'Jövőbeli hónap';
    }
    if (month.availability == BalanceYearMonthAvailability.unknown) {
      return 'Nincs elérhető adat';
    }
    if (month.availability == BalanceYearMonthAvailability.noData) {
      return _perspective == BalanceYearPerspective.cumulativeNet
          ? '${_signed(month.cumulativeNetMinor)} · Nincs tranzakció'
          : 'Nincs tranzakció';
    }
    final state = month.isFuture
        ? ' · Előre rögzített'
        : !month.isClosed
        ? ' · Folyamatban'
        : '';
    final value = switch (_perspective) {
      BalanceYearPerspective.monthlyNet => _signed(month.netMinor),
      BalanceYearPerspective.cumulativeNet => _signed(month.cumulativeNetMinor),
      BalanceYearPerspective.incomeExpense =>
        'Bevétel ${DashboardPreparedFormatter.amountMinor(month.incomeMinor)} · Kiadás ${DashboardPreparedFormatter.amountMinor(month.expenseMinor)}',
    };
    return '$value$state';
  }

  Widget _statistics() {
    final best = _chart.bestMonth;
    return Row(
      children: [
        Expanded(
          child: _smallStat(
            'Pozitív hónapok',
            '${_chart.positiveClosedMonthCount} / ${_chart.closedMonthCount} lezárt hónap',
          ),
        ),
        Expanded(
          child: _smallStat(
            'Legjobb hónap',
            best == null ? '—' : '${best.label} · ${_signed(best.netMinor)}',
          ),
        ),
      ],
    );
  }

  Widget _smallStat(String label, String value) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 8,
          color: FluviVisualTokens.textSecondary,
        ),
      ),
      Text(
        value,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: const TextStyle(
          fontSize: 9,
          fontWeight: FontWeight.w700,
          color: FluviVisualTokens.textPrimary,
        ),
      ),
    ],
  );

  Widget _selector(double height) {
    final selectedIndex = _perspective.index;
    final order = [
      BalanceYearPerspective.values[(selectedIndex + 2) % 3],
      _perspective,
      BalanceYearPerspective.values[(selectedIndex + 1) % 3],
    ];
    final diameter = math.min(56.0, math.max(18.0, height - 24));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final perspective in order)
                Semantics(
                  button: true,
                  selected: perspective == _perspective,
                  label: perspective.label,
                  child: GestureDetector(
                    key: ValueKey(
                      'balance-year-perspective-${perspective.name}',
                    ),
                    onTap: () {
                      setState(() {
                        _perspective = perspective;
                        _selectedMonth = null;
                      });
                      widget.onPerspectiveChanged?.call(perspective);
                    },
                    child: Container(
                      width: perspective == _perspective
                          ? diameter
                          : diameter * .76,
                      height: perspective == _perspective
                          ? diameter
                          : diameter * .76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: perspective == _perspective
                              ? const [
                                  Color(0xfff5f0ff),
                                  Color(0xffd9c9f2),
                                  Color(0xffc7b0e6),
                                ]
                              : const [Color(0xfffaf8ff), Color(0xffeee8f7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xff75618e).withValues(
                              alpha: perspective == _perspective ? .18 : .09,
                            ),
                            blurRadius: 7,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        perspective.icon,
                        size: diameter * .45,
                        color: perspective == _perspective
                            ? const Color(0xff6c479f)
                            : const Color(0xffa292ba),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (height >= 42)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 5),
            child: Text(
              _perspective.label,
              maxLines: 1,
              style: const TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: FluviVisualTokens.textPrimary,
              ),
            ),
          ),
      ],
    );
  }
}

String _signed(int minor) =>
    '${minor > 0 ? '+' : ''}${DashboardPreparedFormatter.amountMinor(minor)}';

/// Geometry is resolved before paint. It performs only coordinate mapping of
/// the immutable prepared values, never transaction aggregation.
@immutable
final class BalanceYearFocusedChartGeometry {
  const BalanceYearFocusedChartGeometry._({
    required this.plot,
    required this.slot,
    required this.barWidth,
    required this.axis,
    required this.rail,
    required this.monthlyRects,
    required this.incomeRects,
    required this.expenseRects,
    required this.cumulativePoints,
  });
  final Rect plot;
  final double slot;
  final double barWidth;
  final double axis;
  final Rect rail;
  final List<Rect?> monthlyRects;
  final List<Rect?> incomeRects;
  final List<Rect?> expenseRects;
  final List<Offset?> cumulativePoints;
  double slotLeft(int month) => plot.left + slot * (month - 1);
  double center(int month) => slotLeft(month) + slot / 2;

  factory BalanceYearFocusedChartGeometry.resolve(
    Size size,
    BalanceYearFocusedChartPresentation data,
    BalanceYearPerspective perspective,
  ) {
    final inset = math.max(3.0, size.width * .025);
    final plot = Rect.fromLTRB(
      inset,
      10,
      math.max(inset, size.width - inset),
      math.max(10, size.height - 17),
    );
    final slot = plot.width / 12;
    final width =
        (slot *
                (perspective == BalanceYearPerspective.incomeExpense
                    ? .29
                    : .42))
            .clamp(2.0, 14.0)
            .toDouble();
    final axis = perspective == BalanceYearPerspective.incomeExpense
        ? plot.bottom - 3
        : plot.center.dy;
    final railHeight = math.max(1.6, width * .15);
    final monthly = <Rect?>[];
    final income = <Rect?>[];
    final expense = <Rect?>[];
    final points = <Offset?>[];
    final minCumulative = math.min(0, data.minCumulativeNetMinor);
    final maxCumulative = math.max(0, data.maxCumulativeNetMinor);
    final cumulativeSpan = math.max(1, maxCumulative - minCumulative);
    double yFor(int value) =>
        plot.bottom -
        4 -
        (value - minCumulative) / cumulativeSpan * math.max(0, plot.height - 8);
    if (perspective == BalanceYearPerspective.cumulativeNet) {
      points.add(Offset(plot.left, yFor(0)));
    }
    for (final month in data.months) {
      final x = plot.left + slot * (month.month - .5);
      final known = month.hasRecordedTransactions;
      final height =
          month.netMinor.abs() /
          math.max(1, data.maxAbsNetMinor) *
          math.max(0, plot.height * .44 - width * .35);
      monthly.add(
        !known
            ? null
            : month.netMinor == 0
            ? Rect.fromCenter(
                center: Offset(x, axis),
                width: width,
                height: math.max(width * .7, railHeight * 2.7),
              )
            : Rect.fromLTWH(
                x - width / 2,
                month.netMinor > 0 ? axis - math.max(width * .5, height) : axis,
                width,
                math.max(width * .5, height),
              ),
      );
      final gap = math.min(2.0, slot * .08);
      Rect? flowRect(int value, double center) => value <= 0
          ? null
          : Rect.fromLTWH(
              center - width / 2,
              axis -
                  math.max(
                    width * .5,
                    value /
                        math.max(1, data.maximumFlowMinor) *
                        math.max(0, plot.height - width * .5 - 8),
                  ),
              width,
              math.max(
                width * .5,
                value /
                    math.max(1, data.maximumFlowMinor) *
                    math.max(0, plot.height - width * .5 - 8),
              ),
            );
      income.add(flowRect(month.incomeMinor, x - (width + gap) / 2));
      expense.add(flowRect(month.expenseMinor, x + (width + gap) / 2));
      if (perspective == BalanceYearPerspective.cumulativeNet) {
        points.add(
          month.hasCumulativeClose
              ? Offset(x, yFor(month.cumulativeNetMinor))
              : null,
        );
      }
    }
    final resolvedAxis = perspective == BalanceYearPerspective.cumulativeNet
        ? yFor(0)
        : axis;
    return BalanceYearFocusedChartGeometry._(
      plot: plot,
      slot: slot,
      barWidth: width,
      axis: resolvedAxis,
      rail: Rect.fromCenter(
        center: Offset(plot.center.dx, resolvedAxis),
        width: plot.width,
        height: railHeight,
      ),
      monthlyRects: List.unmodifiable(monthly),
      incomeRects: List.unmodifiable(income),
      expenseRects: List.unmodifiable(expense),
      cumulativePoints: List.unmodifiable(points),
    );
  }
}

final class BalanceYearFocusedChartPainter extends CustomPainter {
  BalanceYearFocusedChartPainter({
    required this.presentation,
    required this.perspective,
    required this.geometry,
    this.selectedMonth,
    this.labelFontFamily,
  });
  final BalanceYearFocusedChartPresentation presentation;
  final BalanceYearPerspective perspective;
  final BalanceYearFocusedChartGeometry geometry;
  final int? selectedMonth;
  final String? labelFontFamily;
  static final _positive = BudgetClayActiveMaterial.forSemanticBase(
    FluviVisualTokens.budgetProgressHealthy,
  );
  static final _negative = BudgetClayActiveMaterial.forSemanticBase(
    FluviVisualTokens.budgetProgressDanger,
  );
  static final _neutral = BudgetClayActiveMaterial.forSemanticBase(
    BudgetProgressRingGeometry.source.trackGradientColors[1],
  );

  static void paintCapsule(
    Canvas canvas,
    Rect rect,
    BudgetClayActiveMaterial material, {
    bool strip = true,
  }) => FluviYearClayCapsulePainter.paint(
    canvas,
    rect: rect,
    colors: material.colors,
    depthColors: material.depthColors,
    stops: material.stops,
    showDecorativeStrip: strip,
  );

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final track = BudgetProgressRingGeometry.source;
    FluviYearClayCapsulePainter.paintZeroRail(
      canvas,
      rect: geometry.rail,
      colors: track.trackGradientColors,
      stops: track.trackGradientStops,
      shadowColor: track.trackShadowColor,
      glossColor: track.trackGlossColor,
      showDecorativeStrip: true,
    );
    if (selectedMonth case final month?) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(
            geometry.slotLeft(month),
            geometry.plot.top,
            geometry.slot,
            geometry.plot.height,
          ),
          const Radius.circular(6),
        ),
        Paint()..color = const Color(0x086f45a0),
      );
    }
    if (perspective == BalanceYearPerspective.cumulativeNet) {
      _line(canvas);
    } else {
      for (var i = 0; i < presentation.months.length; i++) {
        final month = presentation.months[i];
        if (perspective == BalanceYearPerspective.monthlyNet) {
          final rect = geometry.monthlyRects[i];
          if (rect != null) {
            paintCapsule(
              canvas,
              rect,
              month.netMinor == 0
                  ? _neutral
                  : month.netMinor > 0
                  ? _positive
                  : _negative,
              strip: month.netMinor != 0,
            );
          } else {
            _empty(canvas, month);
          }
        } else {
          final income = geometry.incomeRects[i];
          final expense = geometry.expenseRects[i];
          if (income != null) paintCapsule(canvas, income, _positive);
          if (expense != null) paintCapsule(canvas, expense, _negative);
          if (income == null && expense == null) _empty(canvas, month);
        }
      }
    }
    for (final month in presentation.months) {
      final text = TextPainter(
        text: TextSpan(
          text: month.label,
          style: TextStyle(
            fontFamily: labelFontFamily,
            fontSize: math.min(7, geometry.slot * .29),
            fontWeight: FontWeight.w700,
            color: FluviVisualTokens.textSecondary,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      text.paint(
        canvas,
        Offset(geometry.center(month.month) - text.width / 2, size.height - 10),
      );
      text.dispose();
    }
  }

  void _empty(Canvas canvas, BalanceYearMonthPoint month) {
    final center = Offset(geometry.center(month.month), geometry.axis);
    final source = BudgetProgressRingGeometry.source;
    if (month.isFuture) {
      FluviYearClayCapsulePainter.paintFutureMarker(
        canvas,
        center: center,
        radius: math.max(1, geometry.barWidth * .14),
        shadowColor: source.trackShadowColor,
        depthColor: source.trackGradientColors.last,
      );
    } else if (month.availability == BalanceYearMonthAvailability.unknown) {
      canvas.drawLine(
        center.translate(-2, 0),
        center.translate(2, 0),
        Paint()
          ..color = const Color(0xffc8c4ce)
          ..strokeWidth = 1,
      );
    } else {
      canvas.drawCircle(
        center,
        1.5,
        Paint()
          ..color = const Color(0xffbcb5c8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
    }
  }

  void _line(Canvas canvas) {
    final points = geometry.cumulativePoints;
    var path = Path();
    Offset? first;
    Offset? last;
    void paintSegment() {
      if (first == null || last == null) return;
      final fill = Path.from(path)
        ..lineTo(last.dx, geometry.axis)
        ..lineTo(first.dx, geometry.axis)
        ..close();
      canvas.drawPath(
        fill,
        Paint()
          ..shader = const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0x126f45a0), Color(0x016f45a0)],
          ).createShader(geometry.plot),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff8662b0)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.8
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
    }

    for (final point in points) {
      if (point == null) {
        paintSegment();
        path = Path();
        first = null;
        last = null;
        continue;
      }
      if (first == null) {
        path.moveTo(point.dx, point.dy);
        first = point;
      } else {
        path.lineTo(point.dx, point.dy);
      }
      last = point;
    }
    paintSegment();
    for (var i = 0; i < presentation.months.length; i++) {
      final point = points[i + 1];
      if (point == null) continue;
      final month = presentation.months[i];
      if (!month.isClosed || month.month == selectedMonth) {
        canvas.drawCircle(point, 3, Paint()..color = Colors.white);
        canvas.drawCircle(
          point,
          3,
          Paint()
            ..color = const Color(0xff8662b0)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.4,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant BalanceYearFocusedChartPainter old) =>
      old.presentation != presentation ||
      old.perspective != perspective ||
      old.geometry != geometry ||
      old.selectedMonth != selectedMonth ||
      old.labelFontFamily != labelFontFamily;
}
