import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_year_clay_capsule_painter.dart';
import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_focused_layout_geometry.dart';
import 'balance_month_focused_chart_presentation.dart';
import 'balance_month_spending_level_gauge.dart';
import 'budget_clay_semicircle_gauge.dart';

enum BalanceMonthPerspective {
  balanceTrend,
  swings,
  spendingLevel;

  String get label => switch (this) {
    balanceTrend => 'Egyenleg alakulása',
    swings => 'Kilengések',
    spendingLevel => 'Kiadási szint',
  };
  String get subtitle => switch (this) {
    balanceTrend => 'A havi nettó eredmény felhalmozódása',
    swings => 'A hónap legnagyobb napi elmozdulásai',
    spendingLevel => 'Összevetés a korábbi hónapok tipikus kiadásával',
  };
  IconData get icon => switch (this) {
    balanceTrend => Icons.show_chart_rounded,
    swings => Icons.bar_chart_rounded,
    spendingLevel => Icons.speed_rounded,
  };
}

/// Monthly content only. Selection stays local; the parent remembers it while
/// the existing collapse owner temporarily removes the content subtree.
final class BalanceMonthFocusedLayout extends StatefulWidget {
  const BalanceMonthFocusedLayout({
    super.key,
    required this.presentation,
    this.initialPerspective = BalanceMonthPerspective.balanceTrend,
    this.onPerspectiveChanged,
  });
  final BalanceAlternativeMonthPresentation presentation;
  final BalanceMonthPerspective initialPerspective;
  final ValueChanged<BalanceMonthPerspective>? onPerspectiveChanged;
  @override
  State<BalanceMonthFocusedLayout> createState() =>
      _BalanceMonthFocusedLayoutState();
}

class _BalanceMonthFocusedLayoutState extends State<BalanceMonthFocusedLayout> {
  late BalanceMonthPerspective _perspective;
  BalanceMonthFocusedChartPresentation? _chart;
  @override
  void initState() {
    super.initState();
    _perspective = widget.initialPerspective;
    _prepare();
  }

  @override
  void didUpdateWidget(covariant BalanceMonthFocusedLayout oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.sourcePresentationId !=
            widget.presentation.sourcePresentationId ||
        oldWidget.presentation.timeScope != widget.presentation.timeScope) {
      _prepare();
    }
  }

  void _prepare() {
    final source = widget.presentation;
    final primary = source.primary;
    _chart = primary == null
        ? null
        : BalanceMonthFocusedChartPresentation.fromPrimary(
            primary,
            spendingLevel: source.spendingLevel,
            logicalAsOfDate: source.logicalAsOfDate,
          );
  }

  @override
  Widget build(BuildContext context) {
    final chart = _chart;
    if (chart == null) return const SizedBox.shrink();
    return LayoutBuilder(
      builder: (context, constraints) {
        final selectorHeight = BalanceFocusedLayoutGeometry.topSectionHeight(
          constraints.maxHeight,
        );
        return Padding(
          key: const ValueKey('balance-month-focused-layout'),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Column(
            children: [
              SizedBox(
                key: const ValueKey('balance-month-focused-selector-zone'),
                height: selectorHeight,
                child: _selector(selectorHeight),
              ),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      _perspective.label,
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
                    '${chart.year}.${chart.month.toString().padLeft(2, '0')}',
                    style: const TextStyle(fontSize: 10),
                  ),
                ],
              ),
              Text(
                _perspective.subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 9),
              ),
              const SizedBox(height: 5),
              Expanded(
                child: RepaintBoundary(
                  key: ValueKey('balance-month-chart-${_perspective.name}'),
                  child: _perspective == BalanceMonthPerspective.spendingLevel
                      ? chart.spendingLevel == null
                            ? const Center(
                                child: Text(
                                  'Még nincs összehasonlítható előzmény',
                                  textAlign: TextAlign.center,
                                ),
                              )
                            : BalanceMonthSpendingLevelGauge(
                                presentation: chart.spendingLevel!,
                              )
                      : CustomPaint(
                          painter: BalanceMonthFocusedChartPainter(
                            presentation: chart,
                            perspective: _perspective,
                            labelFontFamily: Theme.of(
                              context,
                            ).textTheme.bodySmall?.fontFamily,
                          ),
                          size: Size.infinite,
                        ),
                ),
              ),
              if (constraints.maxHeight >= 240)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Text(
                    _stats(chart),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 9),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  String _amount(num value) =>
      DashboardPreparedFormatter.compactAmountMinor(value.round());
  String _stats(
    BalanceMonthFocusedChartPresentation c,
  ) => switch (_perspective) {
    BalanceMonthPerspective.balanceTrend =>
      'Legmélyebb: ${_amount(c.minimumNetMinor)}   ·   Legmagasabb: ${_amount(c.maximumNetMinor)}',
    BalanceMonthPerspective.swings =>
      'Legnagyobb plusz: ${_amount(math.max(0, c.bestDay?.netMinor ?? 0))}   ·   Mínusz: ${_amount(math.min(0, c.worstDay?.netMinor ?? 0))}',
    BalanceMonthPerspective.spendingLevel =>
      c.spendingLevel?.referenceExpenseTimesTwo == null
          ? 'Három összehasonlítható lezárt hónap szükséges'
          : 'Referencia: ${_amount(c.spendingLevel!.referenceExpenseTimesTwo! / 2)}   ·   Eltérés: ${_amount(c.spendingLevel!.currentExpenseMinor - c.spendingLevel!.referenceExpenseTimesTwo! / 2)}',
  };
  Widget _selector(double height) {
    final i = _perspective.index;
    final order = [
      BalanceMonthPerspective.values[(i + 2) % 3],
      _perspective,
      BalanceMonthPerspective.values[(i + 1) % 3],
    ];
    final diameter = math.min(56.0, math.max(18.0, height - 24));
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final p in order)
                Semantics(
                  button: true,
                  selected: p == _perspective,
                  label: p.label,
                  child: GestureDetector(
                    key: ValueKey('balance-month-perspective-${p.name}'),
                    onTap: () {
                      setState(() => _perspective = p);
                      widget.onPerspectiveChanged?.call(p);
                    },
                    child: Container(
                      width: p == _perspective ? diameter : diameter * .76,
                      height: p == _perspective ? diameter : diameter * .76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: p == _perspective
                              ? const [
                                  Color(0xfff5f0ff),
                                  Color(0xffd9c9f2),
                                  Color(0xffc7b0e6),
                                ]
                              : const [Color(0xfffaf8ff), Color(0xffeee8f7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff75618e,
                            ).withValues(alpha: p == _perspective ? .18 : .09),
                            blurRadius: 7,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        p.icon,
                        size: diameter * .45,
                        color: p == _perspective
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

/// Pure geometry and painting over already prepared month-local values.
final class BalanceMonthFocusedChartPainter extends CustomPainter {
  BalanceMonthFocusedChartPainter({
    required this.presentation,
    required this.perspective,
    this.labelFontFamily,
  });
  final BalanceMonthFocusedChartPresentation presentation;
  final BalanceMonthPerspective perspective;
  final String? labelFontFamily;
  static final _positive = BudgetClayActiveMaterial.forSemanticBase(
    FluviVisualTokens.budgetProgressHealthy,
  );
  static final _negative = BudgetClayActiveMaterial.forSemanticBase(
    FluviVisualTokens.budgetProgressDanger,
  );
  @override
  void paint(Canvas canvas, Size size) {
    if (size.width < 10 || size.height < 48) return;
    final plot = Rect.fromLTWH(10, 12, size.width - 20, size.height - 36);
    if (perspective == BalanceMonthPerspective.balanceTrend) {
      final minValue = presentation.minimumNetMinor.toDouble();
      final range = math.max(
        1.0,
        (presentation.maximumNetMinor - presentation.minimumNetMinor)
            .toDouble(),
      );
      double y(int v) => plot.bottom - (v - minValue) / range * plot.height;
      final zero = y(0);
      canvas.drawLine(
        Offset(plot.left, zero),
        Offset(plot.right, zero),
        Paint()
          ..color = const Color(0xffebe7f0)
          ..strokeWidth = 1,
      );
      final path = Path();
      for (final point in presentation.trend) {
        final x =
            plot.left +
            point.day / (presentation.trend.length - 1) * plot.width;
        if (point.day == 0) {
          path.moveTo(x, y(point.netMinor));
        } else {
          path.lineTo(x, y(point.netMinor));
        }
      }
      final fill = Path.from(path)
        ..lineTo(plot.right, zero)
        ..lineTo(plot.left, zero)
        ..close();
      canvas.drawPath(
        fill,
        Paint()..color = const Color(0xff9571c6).withValues(alpha: .065),
      );
      canvas.drawPath(
        path,
        Paint()
          ..color = const Color(0xff9068be)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.2
          ..strokeJoin = StrokeJoin.round
          ..strokeCap = StrokeCap.round,
      );
      for (final day in [
        1,
        (presentation.trend.length / 2).floor(),
        presentation.trend.length - 1,
      ]) {
        _label(
          canvas,
          '$day.',
          Offset(
            plot.left + day / (presentation.trend.length - 1) * plot.width,
            plot.bottom + 8,
          ),
        );
      }
    } else {
      final zero = plot.center.dy;
      final source = BudgetProgressRingGeometry.source;
      FluviYearClayCapsulePainter.paintZeroRail(
        canvas,
        rect: Rect.fromLTWH(plot.left, zero - 1.5, plot.width, 3),
        colors: source.trackGradientColors,
        stops: source.trackGradientStops,
        shadowColor: source.trackShadowColor,
        glossColor: source.trackGlossColor,
        showDecorativeStrip: true,
      );
      final points = presentation.swings;
      if (points.isEmpty) {
        _label(
          canvas,
          'Nincs napi nettóváltozás',
          Offset(plot.center.dx, plot.bottom + 8),
        );
        return;
      }
      final slot = plot.width / points.length;
      for (var i = 0; i < points.length; i++) {
        final point = points[i];
        final width = math.min(14.0, slot * .42);
        final h =
            point.netMinor.abs() /
            math.max(1, presentation.maxAbsSwingMinor) *
            (plot.height / 2 - 5);
        final rect = Rect.fromLTWH(
          plot.left + slot * (i + .5) - width / 2,
          point.netMinor > 0 ? zero - h : zero,
          width,
          h,
        );
        final material = point.netMinor > 0 ? _positive : _negative;
        FluviYearClayCapsulePainter.paint(
          canvas,
          rect: rect,
          colors: material.colors,
          depthColors: material.depthColors,
          stops: material.stops,
          showDecorativeStrip: true,
        );
        _label(
          canvas,
          '${point.day}.',
          Offset(plot.left + slot * (i + .5), plot.bottom + 8),
        );
      }
    }
  }

  void _label(Canvas canvas, String label, Offset at) {
    final text = TextPainter(
      text: TextSpan(
        text: label,
        style: TextStyle(
          fontSize: 8,
          color: const Color(0xff93899f),
          fontFamily: labelFontFamily,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();
    text.paint(
      canvas,
      Offset((at.dx - text.width / 2).clamp(0.0, 10000.0), at.dy),
    );
  }

  @override
  bool shouldRepaint(covariant BalanceMonthFocusedChartPainter oldDelegate) =>
      oldDelegate.presentation != presentation ||
      oldDelegate.perspective != perspective ||
      oldDelegate.labelFontFamily != labelFontFamily;
}
