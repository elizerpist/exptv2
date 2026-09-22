import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';

/// The lower Balance card's local chart and inspection surface.
///
/// All financial values arrive in [presentation]. Pointer input only selects
/// an already-projected pair/day and cannot navigate Summary or acquire data.
class BalancePrimaryChartCard extends StatefulWidget {
  const BalancePrimaryChartCard({super.key, required this.presentation});

  final DashboardBalancePrimaryPresentation presentation;

  @override
  State<BalancePrimaryChartCard> createState() =>
      _BalancePrimaryChartCardState();
}

class _BalancePrimaryChartCardState extends State<BalancePrimaryChartCard> {
  int? _selectedValue;

  @override
  void didUpdateWidget(covariant BalancePrimaryChartCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.presentationId !=
        widget.presentation.presentationId) {
      _selectedValue = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    if (presentation.mode == DashboardBalancePrimaryMode.unsupportedDay) {
      return const SizedBox.expand();
    }
    final palette = DashboardModePaletteResolver.resolve(
      DashboardModeSpec.balance,
    );
    final incomeColor = palette.incomeGradient.colors.first;
    final expenseColor = palette.expenseGradient.colors.first;
    return LayoutBuilder(
      builder: (context, constraints) {
        // The cascade can deliberately collapse zone2 below a truthful chart
        // surface.  Do not paint or expose a clipped interactive chart there.
        if (constraints.maxWidth < 168 || constraints.maxHeight < 144) {
          return const SizedBox.expand(
            key: ValueKey<String>('balance-primary-compact-surface'),
          );
        }
        return Semantics(
          label: 'Balance elsődleges pénzügyi diagram',
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  _titleFor(presentation.timeScope),
                  key: const ValueKey<String>('balance-primary-title'),
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: FluviVisualTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                _PrimaryMetrics(presentation: presentation),
                const SizedBox(height: 8),
                Expanded(
                  child: switch (presentation.mode) {
                    DashboardBalancePrimaryMode.sum ||
                    DashboardBalancePrimaryMode.year => _BalancePairedBars(
                      presentation: presentation,
                      incomeColor: incomeColor,
                      expenseColor: expenseColor,
                      selectedValue: _selectedValue,
                      onSelected: (value) =>
                          setState(() => _selectedValue = value),
                    ),
                    DashboardBalancePrimaryMode.month => _BalanceMonthlySteps(
                      presentation: presentation,
                      incomeColor: incomeColor,
                      expenseColor: expenseColor,
                      selectedDay: _selectedValue,
                      onSelected: (day) => setState(() => _selectedValue = day),
                    ),
                    DashboardBalancePrimaryMode.unsupportedDay =>
                      const SizedBox.expand(),
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _PrimaryMetrics extends StatelessWidget {
  const _PrimaryMetrics({required this.presentation});

  final DashboardBalancePrimaryPresentation presentation;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _metric(context, 'Bevétel', presentation.incomeTotalMinor),
      const SizedBox(width: 12),
      _metric(context, 'Kiadás', presentation.expenseTotalMinor),
      const SizedBox(width: 12),
      _metric(context, 'Egyenleg', presentation.netTotalMinor),
    ],
  );

  Widget _metric(BuildContext context, String label, int value) => Expanded(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: FluviVisualTokens.textSecondary,
          ),
        ),
        Text(
          _compactAmount(value),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    ),
  );
}

final class _BalancePairedBars extends StatelessWidget {
  const _BalancePairedBars({
    required this.presentation,
    required this.incomeColor,
    required this.expenseColor,
    required this.selectedValue,
    required this.onSelected,
  });

  final DashboardBalancePrimaryPresentation presentation;
  final Color incomeColor;
  final Color expenseColor;
  final int? selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final pairs = presentation.periodPairs;
    if (pairs.isEmpty) return const _BalancePrimaryEmptyChart();
    return LayoutBuilder(
      builder: (context, constraints) {
        final minimumGroupWidth =
            presentation.mode == DashboardBalancePrimaryMode.sum ? 58.0 : 1.0;
        final intrinsicWidth = math.max(
          constraints.maxWidth,
          pairs.length * minimumGroupWidth,
        );
        final chart = SizedBox(
          width: intrinsicWidth,
          height: constraints.maxHeight,
          child: _BalancePairChartSurface(
            presentation: presentation,
            incomeColor: incomeColor,
            expenseColor: expenseColor,
            selectedValue: selectedValue,
            onSelected: onSelected,
          ),
        );
        return presentation.mode == DashboardBalancePrimaryMode.sum &&
                intrinsicWidth > constraints.maxWidth
            ? SingleChildScrollView(
                key: const ValueKey<String>('balance-primary-sum-scroll'),
                scrollDirection: Axis.horizontal,
                child: chart,
              )
            : chart;
      },
    );
  }
}

final class _BalancePairChartSurface extends StatelessWidget {
  const _BalancePairChartSurface({
    required this.presentation,
    required this.incomeColor,
    required this.expenseColor,
    required this.selectedValue,
    required this.onSelected,
  });

  final DashboardBalancePrimaryPresentation presentation;
  final Color incomeColor;
  final Color expenseColor;
  final int? selectedValue;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final pairs = presentation.periodPairs;
      return Stack(
        children: <Widget>[
          Semantics(
            button: true,
            label: 'Éves vagy havi Bevétel és Kiadás párok',
            child: GestureDetector(
              key: const ValueKey<String>('balance-primary-pair-chart'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) {
                final width = constraints.maxWidth;
                final index = (details.localPosition.dx / width * pairs.length)
                    .floor()
                    .clamp(0, pairs.length - 1)
                    .toInt();
                onSelected(pairs[index].value);
              },
              child: CustomPaint(
                size: Size.infinite,
                painter: _BalancePairChartPainter(
                  pairs: pairs,
                  isYear: presentation.mode == DashboardBalancePrimaryMode.year,
                  incomeColor: incomeColor,
                  expenseColor: expenseColor,
                  selectedValue: selectedValue,
                ),
              ),
            ),
          ),
          if (selectedValue case final value?)
            _BalancePairInfocard(
              presentation: presentation,
              pair: pairs.firstWhere((pair) => pair.value == value),
            ),
        ],
      );
    },
  );
}

final class _BalanceMonthlySteps extends StatelessWidget {
  const _BalanceMonthlySteps({
    required this.presentation,
    required this.incomeColor,
    required this.expenseColor,
    required this.selectedDay,
    required this.onSelected,
  });

  final DashboardBalancePrimaryPresentation presentation;
  final Color incomeColor;
  final Color expenseColor;
  final int? selectedDay;
  final ValueChanged<int> onSelected;

  @override
  Widget build(BuildContext context) {
    final points = presentation.dailyPoints;
    if (points.isEmpty) return const _BalancePrimaryEmptyChart();
    return LayoutBuilder(
      builder: (context, constraints) => Stack(
        children: <Widget>[
          Semantics(
            button: true,
            label: 'Havi kumulált Bevétel és Kiadás lépcsődiagram',
            child: GestureDetector(
              key: const ValueKey<String>('balance-primary-month-chart'),
              behavior: HitTestBehavior.opaque,
              onTapUp: (details) => onSelected(
                _dayForOffset(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  points.length,
                ),
              ),
              onHorizontalDragUpdate: (details) => onSelected(
                _dayForOffset(
                  details.localPosition.dx,
                  constraints.maxWidth,
                  points.length,
                ),
              ),
              child: CustomPaint(
                size: Size.infinite,
                painter: _BalanceStepChartPainter(
                  points: points,
                  incomeColor: incomeColor,
                  expenseColor: expenseColor,
                  selectedDay: selectedDay,
                ),
              ),
            ),
          ),
          if (selectedDay case final day?)
            _BalanceDayInfocard(
              timeScope: presentation.timeScope as MonthScope,
              point: points[day - 1],
            ),
        ],
      ),
    );
  }
}

final class _BalancePairInfocard extends StatelessWidget {
  const _BalancePairInfocard({required this.presentation, required this.pair});

  final DashboardBalancePrimaryPresentation presentation;
  final DashboardBalancePrimaryPeriodPair pair;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 4,
    left: 4,
    child: _BalanceInfocard(
      title: presentation.mode == DashboardBalancePrimaryMode.sum
          ? '${pair.value}'
          : '${DashboardTimeLabelFormatter.monthName(pair.value)} '
                '${(presentation.timeScope as YearScope).year}',
      incomeLabel: 'Bevétel',
      incomeMinor: pair.incomeMinor,
      expenseLabel: 'Kiadás',
      expenseMinor: pair.expenseMinor,
    ),
  );
}

final class _BalanceDayInfocard extends StatelessWidget {
  const _BalanceDayInfocard({required this.timeScope, required this.point});

  final MonthScope timeScope;
  final DashboardBalancePrimaryDayPoint point;

  @override
  Widget build(BuildContext context) => Positioned(
    top: 4,
    left: 4,
    child: _BalanceInfocard(
      title:
          '${DashboardTimeLabelFormatter.shortMonthName(timeScope.value.month)}. '
          '${point.day}.',
      incomeLabel: 'Bevétel eddig',
      incomeMinor: point.incomeMinor,
      expenseLabel: 'Kiadás eddig',
      expenseMinor: point.expenseMinor,
    ),
  );
}

final class _BalanceInfocard extends StatelessWidget {
  const _BalanceInfocard({
    required this.title,
    required this.incomeLabel,
    required this.incomeMinor,
    required this.expenseLabel,
    required this.expenseMinor,
  });

  final String title;
  final String incomeLabel;
  final int incomeMinor;
  final String expenseLabel;
  final int expenseMinor;

  @override
  Widget build(BuildContext context) => Semantics(
    liveRegion: true,
    label:
        '$title, $incomeLabel ${DashboardPreparedFormatter.amountMinor(incomeMinor)}, '
        '$expenseLabel ${DashboardPreparedFormatter.amountMinor(expenseMinor)}, '
        'Egyenleg ${DashboardPreparedFormatter.amountMinor(incomeMinor - expenseMinor)}',
    child: DecoratedBox(
      decoration: BoxDecoration(
        color: FluviVisualTokens.surface.withValues(alpha: .96),
        border: Border.all(color: FluviVisualTokens.border),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const <BoxShadow>[FluviVisualTokens.cardFootShadow],
      ),
      child: Padding(
        padding: const EdgeInsets.all(7),
        child: DefaultTextStyle(
          style: Theme.of(context).textTheme.labelSmall!.copyWith(
            color: FluviVisualTokens.textPrimary,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(
                '$incomeLabel  ${DashboardPreparedFormatter.amountMinor(incomeMinor)}',
              ),
              Text(
                '$expenseLabel  ${DashboardPreparedFormatter.amountMinor(expenseMinor)}',
              ),
              Text(
                'Egyenleg  ${DashboardPreparedFormatter.amountMinor(incomeMinor - expenseMinor)}',
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

final class _BalancePrimaryEmptyChart extends StatelessWidget {
  const _BalancePrimaryEmptyChart();

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      'Nincs megjeleníthető pénzügyi adat',
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: FluviVisualTokens.textSecondary),
    ),
  );
}

final class _BalancePairChartPainter extends CustomPainter {
  _BalancePairChartPainter({
    required this.pairs,
    required this.isYear,
    required this.incomeColor,
    required this.expenseColor,
    required this.selectedValue,
  });

  final List<DashboardBalancePrimaryPeriodPair> pairs;
  final bool isYear;
  final Color incomeColor;
  final Color expenseColor;
  final int? selectedValue;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabels = 16.0;
    final plot = Rect.fromLTWH(
      4,
      4,
      size.width - 8,
      size.height - bottomLabels - 6,
    );
    final maximum = math.max(
      1,
      pairs.fold<int>(
        0,
        (maxValue, pair) =>
            math.max(maxValue, math.max(pair.incomeMinor, pair.expenseMinor)),
      ),
    );
    final grid = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index += 1) {
      final y = plot.top + plot.height * index / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    final groupWidth = plot.width / pairs.length;
    final barWidth = math.min(14.0, math.max(3.0, groupWidth * .28));
    for (var index = 0; index < pairs.length; index += 1) {
      final pair = pairs[index];
      final center = plot.left + groupWidth * (index + .5);
      if (pair.value == selectedValue) {
        canvas.drawRRect(
          RRect.fromRectAndRadius(
            Rect.fromLTWH(
              plot.left + groupWidth * index + 1,
              plot.top,
              groupWidth - 2,
              plot.height,
            ),
            const Radius.circular(5),
          ),
          Paint()..color = FluviVisualTokens.surfaceInactive,
        );
      }
      _bar(
        canvas,
        plot,
        center - barWidth - 1,
        barWidth,
        pair.incomeMinor,
        maximum,
        incomeColor,
      );
      _bar(
        canvas,
        plot,
        center + 1,
        barWidth,
        pair.expenseMinor,
        maximum,
        expenseColor,
      );
      final label = isYear
          ? const <String>[
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
            ][pair.value - 1]
          : '${pair.value}';
      _paintLabel(canvas, label, Offset(center, plot.bottom + 3));
    }
  }

  void _bar(
    Canvas canvas,
    Rect plot,
    double left,
    double width,
    int value,
    int maximum,
    Color color,
  ) {
    final height = plot.height * value / maximum;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, plot.bottom - height, width, height),
        const Radius.circular(3),
      ),
      Paint()..color = color,
    );
  }

  @override
  bool shouldRepaint(covariant _BalancePairChartPainter oldDelegate) =>
      oldDelegate.pairs != pairs ||
      oldDelegate.isYear != isYear ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor ||
      oldDelegate.selectedValue != selectedValue;
}

final class _BalanceStepChartPainter extends CustomPainter {
  _BalanceStepChartPainter({
    required this.points,
    required this.incomeColor,
    required this.expenseColor,
    required this.selectedDay,
  });

  final List<DashboardBalancePrimaryDayPoint> points;
  final Color incomeColor;
  final Color expenseColor;
  final int? selectedDay;

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabels = 16.0;
    final plot = Rect.fromLTWH(
      4,
      4,
      size.width - 8,
      size.height - bottomLabels - 6,
    );
    final maximum = math.max(
      1,
      points.fold<int>(
        0,
        (maxValue, point) =>
            math.max(maxValue, math.max(point.incomeMinor, point.expenseMinor)),
      ),
    );
    final grid = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .13)
      ..strokeWidth = 1;
    for (var index = 0; index < 4; index += 1) {
      final y = plot.top + plot.height * index / 3;
      canvas.drawLine(Offset(plot.left, y), Offset(plot.right, y), grid);
    }
    if (selectedDay case final day?) {
      final x = _xFor(day - 1, points.length, plot);
      canvas.drawLine(
        Offset(x, plot.top),
        Offset(x, plot.bottom),
        Paint()
          ..color = FluviVisualTokens.textSecondary.withValues(alpha: .45)
          ..strokeWidth = 1,
      );
    }
    _stepPath(canvas, plot, maximum, (point) => point.incomeMinor, incomeColor);
    _stepPath(
      canvas,
      plot,
      maximum,
      (point) => point.expenseMinor,
      expenseColor,
    );
    _paintLabel(canvas, '1', Offset(plot.left, plot.bottom + 3));
    _paintLabel(
      canvas,
      '${points.length}',
      Offset(plot.right, plot.bottom + 3),
    );
  }

  void _stepPath(
    Canvas canvas,
    Rect plot,
    int maximum,
    int Function(DashboardBalancePrimaryDayPoint) valueFor,
    Color color,
  ) {
    final path = Path();
    double? previousY;
    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      final x = _xFor(index, points.length, plot);
      final y = plot.bottom - plot.height * valueFor(point) / maximum;
      if (index == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, previousY!);
        path.lineTo(x, y);
      }
      previousY = y;
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceStepChartPainter oldDelegate) =>
      oldDelegate.points != points ||
      oldDelegate.incomeColor != incomeColor ||
      oldDelegate.expenseColor != expenseColor ||
      oldDelegate.selectedDay != selectedDay;
}

double _xFor(int index, int count, Rect plot) =>
    count <= 1 ? plot.center.dx : plot.left + plot.width * index / (count - 1);

int _dayForOffset(double dx, double width, int count) =>
    (dx.clamp(0, width) / math.max(1, width) * (count - 1)).round() + 1;

void _paintLabel(Canvas canvas, String label, Offset anchor) {
  final painter = TextPainter(
    text: TextSpan(
      text: label,
      style: const TextStyle(
        fontSize: 9,
        color: FluviVisualTokens.textSecondary,
      ),
    ),
    textDirection: TextDirection.ltr,
  )..layout();
  painter.paint(canvas, Offset(anchor.dx - painter.width / 2, anchor.dy));
}

String _titleFor(LedgerTimeScope scope) => switch (scope) {
  AllTimeScope() => 'Többéves balance',
  YearScope(:final year) => '$year',
  MonthScope(:final value) => DashboardTimeLabelFormatter.yearMonth(value),
  DayScope() => '',
};

String _compactAmount(int value) {
  final sign = value < 0 ? '-' : '';
  final absolute = value.abs();
  if (absolute >= 100000000) {
    return '$sign${(absolute / 100000000).toStringAsFixed(1).replaceAll('.', ',')} M';
  }
  if (absolute >= 100000) return '$sign${absolute ~/ 100000} k';
  return DashboardPreparedFormatter.amountMinor(value);
}
