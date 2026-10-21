import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/fluvi_clay_active_material.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_presentation_settings.dart';

/// Source-locked Card 3 renderer shared by alternative Balance SUM and YEAR.
/// It owns only the optional historical plot scroll; all financial values have
/// already been prepared by the canonical Balance primary projection.
final class BalanceAlternativeIncomeExpenseBarCard extends StatefulWidget {
  const BalanceAlternativeIncomeExpenseBarCard({
    super.key,
    required this.presentation,
    this.yearBarPresentation = BalanceYearBarPresentation.current,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation presentation;
  final BalanceYearBarPresentation yearBarPresentation;

  @override
  State<BalanceAlternativeIncomeExpenseBarCard> createState() =>
      _BalanceAlternativeIncomeExpenseBarCardState();
}

final class _BalanceAlternativeIncomeExpenseBarCardState
    extends State<BalanceAlternativeIncomeExpenseBarCard> {
  static const _minimumYearGroupWidth = 36.0;
  final ScrollController _sumScrollController = ScrollController();
  bool _initialisedSumScroll = false;

  @override
  void didUpdateWidget(
    covariant BalanceAlternativeIncomeExpenseBarCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.domain != widget.presentation.domain) {
      _initialisedSumScroll = false;
    }
  }

  @override
  void dispose() {
    _sumScrollController.dispose();
    super.dispose();
  }

  void _initialiseSumScrollAtRecentEnd() {
    final presentation = widget.presentation;
    if (presentation.domain != BalanceAlternativeBarDomain.years ||
        _initialisedSumScroll) {
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted ||
          _initialisedSumScroll ||
          !_sumScrollController.hasClients) {
        return;
      }
      final position = _sumScrollController.position;
      if (position.maxScrollExtent > 0) {
        _initialisedSumScroll = true;
        position.jumpTo(position.maxScrollExtent);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    _initialiseSumScrollAtRecentEnd();
    final presentation = widget.presentation;
    return DecoratedBox(
      key: const ValueKey<String>(
        'balance-alternative-income-expense-bar-card',
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFFEFEFE),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFE8ECF4)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x120A2040),
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(13, 12, 13, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            _BalanceAlternativeCard3Heading(presentation: presentation),
            const SizedBox(height: 9),
            Expanded(
              child: _BalanceAlternativeBarPlot(
                presentation: presentation,
                yearBarPresentation: widget.yearBarPresentation,
                sumScrollController: _sumScrollController,
                minimumYearGroupWidth: _minimumYearGroupWidth,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _BalanceAlternativeCard3Heading extends StatelessWidget {
  const _BalanceAlternativeCard3Heading({required this.presentation});

  final BalanceAlternativeIncomeExpenseBarPresentation presentation;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Expanded(
            child: Text(
              'Bevétel / Kiadás',
              style: TextStyle(
                color: Color(0xFF020336),
                fontSize: 16,
                height: 1.15,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          _BalanceAlternativeNetMetric(value: presentation.netTotalMinor),
        ],
      ),
      const SizedBox(height: 5),
      Row(
        children: <Widget>[
          Expanded(
            child: _BalanceAlternativeDirectionMetric(
              color: _BalanceAlternativeChartTokens.incomeBottom,
              label: 'Bevétel',
              value: presentation.incomeTotalMinor,
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _BalanceAlternativeDirectionMetric(
              color: _BalanceAlternativeChartTokens.expenseBottom,
              label: 'Kiadás',
              value: presentation.expenseTotalMinor,
            ),
          ),
        ],
      ),
    ],
  );
}

final class _BalanceAlternativeNetMetric extends StatelessWidget {
  const _BalanceAlternativeNetMetric({required this.value});

  final int value;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.end,
    children: <Widget>[
      const Text(
        'Egyenleg',
        style: TextStyle(
          color: Color(0xFF66789A),
          fontSize: 10,
          height: 1.1,
          fontWeight: FontWeight.w500,
        ),
      ),
      const SizedBox(height: 2),
      FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerRight,
        child: Text(
          DashboardPreparedFormatter.amountMinor(value),
          maxLines: 1,
          style: const TextStyle(
            color: Color(0xFF2026D0),
            fontSize: 12,
            height: 1.1,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    ],
  );
}

final class _BalanceAlternativeDirectionMetric extends StatelessWidget {
  const _BalanceAlternativeDirectionMetric({
    required this.color,
    required this.label,
    required this.value,
  });

  final Color color;
  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: 9,
        height: 9,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      ),
      const SizedBox(width: 4),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                DashboardPreparedFormatter.amountMinor(value),
                maxLines: 1,
                style: const TextStyle(
                  color: Color(0xFF101B4E),
                  fontSize: 11,
                  height: 1.1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: const TextStyle(
                color: Color(0xFF66789A),
                fontSize: 9.5,
                height: 1.1,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}

final class _BalanceAlternativeBarPlot extends StatelessWidget {
  const _BalanceAlternativeBarPlot({
    required this.presentation,
    required this.yearBarPresentation,
    required this.sumScrollController,
    required this.minimumYearGroupWidth,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation presentation;
  final BalanceYearBarPresentation yearBarPresentation;
  final ScrollController sumScrollController;
  final double minimumYearGroupWidth;

  @override
  Widget build(BuildContext context) {
    if (presentation.groups.isEmpty) {
      return Center(
        child: Text(
          'Nincs adat',
          style: TextStyle(color: FluviVisualTokens.textSecondary),
        ),
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        const axisWidth = 23.0;
        final plotWidth = math.max(0.0, constraints.maxWidth - axisWidth);
        final intrinsicWidth = math.max(
          plotWidth,
          presentation.domain == BalanceAlternativeBarDomain.years
              ? presentation.groups.length * minimumYearGroupWidth
              : 0.0,
        );
        final lane = SizedBox(
          width: intrinsicWidth,
          height: constraints.maxHeight,
          child: _BalanceAlternativeBarGroupsLane(
            presentation: presentation,
            yearBarPresentation: yearBarPresentation,
          ),
        );
        final scrolls =
            presentation.domain == BalanceAlternativeBarDomain.years &&
            intrinsicWidth > plotWidth;
        return Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            SizedBox(
              width: axisWidth,
              child: _BalanceAlternativeYAxis(
                maximum: presentation.maximumMinor,
              ),
            ),
            Expanded(
              key: const ValueKey<String>('balance-alternative-chart-plot'),
              child: scrolls
                  ? SingleChildScrollView(
                      key: const ValueKey<String>(
                        'balance-alternative-sum-plot-scroll',
                      ),
                      controller: sumScrollController,
                      scrollDirection: Axis.horizontal,
                      child: lane,
                    )
                  : lane,
            ),
          ],
        );
      },
    );
  }
}

final class _BalanceAlternativeYAxis extends StatelessWidget {
  const _BalanceAlternativeYAxis({required this.maximum});

  final int maximum;

  @override
  Widget build(BuildContext context) {
    final top = maximum <= 0 ? 0 : maximum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: <Widget>[_label(top), _label(top ~/ 2), _label(0)],
      ),
    );
  }

  Widget _label(int value) => Text(
    value == 0 ? '0' : DashboardPreparedFormatter.compactAmountMinor(value),
    maxLines: 1,
    overflow: TextOverflow.clip,
    style: const TextStyle(
      color: Color(0xFF73809A),
      fontSize: 7.5,
      height: 1,
      fontWeight: FontWeight.w600,
    ),
  );
}

final class _BalanceAlternativeBarGroupsLane extends StatelessWidget {
  const _BalanceAlternativeBarGroupsLane({
    required this.presentation,
    required this.yearBarPresentation,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation presentation;
  final BalanceYearBarPresentation yearBarPresentation;

  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: const _BalanceAlternativeGridPainter(),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        for (final group in presentation.groups)
          Expanded(
            child: _BalanceAlternativeBarGroup(
              group: group,
              maximum: math.max(1, presentation.maximumMinor),
              usesClayMaterial:
                  presentation.domain == BalanceAlternativeBarDomain.months &&
                  yearBarPresentation == BalanceYearBarPresentation.clay3d,
            ),
          ),
      ],
    ),
  );
}

final class _BalanceAlternativeBarGroup extends StatelessWidget {
  const _BalanceAlternativeBarGroup({
    required this.group,
    required this.maximum,
    required this.usesClayMaterial,
  });

  final BalanceAlternativeIncomeExpenseBarGroup group;
  final int maximum;
  final bool usesClayMaterial;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    key: ValueKey<String>('balance-alternative-bar-group-${group.key}'),
    builder: (context, constraints) {
      const labelHeight = 16.0;
      final barHeight = math.max(0.0, constraints.maxHeight - labelHeight);
      final maxBarWidth = math.max(2.0, (constraints.maxWidth - 3) / 2);
      final barWidth = math.min(7.0, maxBarWidth);
      return Column(
        children: <Widget>[
          SizedBox(
            height: barHeight,
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: <Widget>[
                  _BalanceAlternativeBar(
                    heightFactor: group.incomeMinor / maximum,
                    width: barWidth,
                    gradient: _BalanceAlternativeChartTokens.incomeGradient,
                    clayMaterial: usesClayMaterial
                        ? _BalanceAlternativeChartTokens.incomeClayMaterial
                        : null,
                    semanticKey: 'income-${group.key}',
                  ),
                  const SizedBox(width: 3),
                  _BalanceAlternativeBar(
                    heightFactor: group.expenseMinor / maximum,
                    width: barWidth,
                    gradient: _BalanceAlternativeChartTokens.expenseGradient,
                    clayMaterial: usesClayMaterial
                        ? _BalanceAlternativeChartTokens.expenseClayMaterial
                        : null,
                    semanticKey: 'expense-${group.key}',
                  ),
                ],
              ),
            ),
          ),
          SizedBox(
            height: labelHeight,
            child: Center(
              child: Text(
                group.label,
                maxLines: 1,
                overflow: TextOverflow.clip,
                style: const TextStyle(
                  color: Color(0xFF66789A),
                  fontSize: 7.5,
                  height: 1,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      );
    },
  );
}

final class _BalanceAlternativeBar extends StatelessWidget {
  const _BalanceAlternativeBar({
    required this.heightFactor,
    required this.width,
    required this.gradient,
    required this.clayMaterial,
    required this.semanticKey,
  });

  final double heightFactor;
  final double width;
  final Gradient gradient;
  final FluviClayActiveMaterial? clayMaterial;
  final String semanticKey;

  @override
  Widget build(BuildContext context) => FractionallySizedBox(
    heightFactor: heightFactor.clamp(0.0, 1.0),
    alignment: Alignment.bottomCenter,
    child: SizedBox(
      width: width,
      child: clayMaterial == null
          ? DecoratedBox(
              decoration: BoxDecoration(
                gradient: gradient,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(3),
                ),
              ),
            )
          : RepaintBoundary(
              key: ValueKey<String>(
                'balance-alternative-clay-bar-$semanticKey',
              ),
              child: CustomPaint(
                painter: _BalanceAlternativeClayBarPainter(
                  material: clayMaterial!,
                ),
              ),
            ),
    ),
  );
}

/// Material-only alternative for the monthly Balance pair. Its parent still
/// owns the exact data height, grouping, baseline and labels.
final class _BalanceAlternativeClayBarPainter extends CustomPainter {
  const _BalanceAlternativeClayBarPainter({required this.material});

  final FluviClayActiveMaterial material;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final depthOffset = math.min(1.6, size.width * .22);
    final bodyHeight = math.max(1.0, size.height - depthOffset);
    final body = Rect.fromLTWH(0, 0, size.width, bodyHeight);
    final radius = Radius.circular(math.min(size.width / 2, body.height / 2));
    final clay = RRect.fromRectAndCorners(
      body,
      topLeft: radius,
      topRight: radius,
      bottomLeft: Radius.circular(math.min(2, radius.x)),
      bottomRight: Radius.circular(math.min(2, radius.x)),
    );
    canvas.drawRRect(
      clay.shift(Offset(0, depthOffset)),
      Paint()
        ..color = material.shadow
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 1.4),
    );
    canvas.drawRRect(
      clay.shift(Offset(0, depthOffset * .72)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: material.depthColors,
          stops: material.stops,
        ).createShader(body),
    );
    canvas.drawRRect(
      clay,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: material.colors,
          stops: material.stops,
        ).createShader(body),
    );
    final glossHeight = math.min(math.max(1.1, size.height * .10), 2.2);
    final gloss = Rect.fromLTWH(
      size.width * .22,
      math.min(size.height * .16, 1.2),
      size.width * .52,
      glossHeight,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(gloss, Radius.circular(glossHeight)),
      Paint()..color = material.highlight.withValues(alpha: .62),
    );
  }

  @override
  bool shouldRepaint(covariant _BalanceAlternativeClayBarPainter oldDelegate) =>
      !material.sameVisualAs(oldDelegate.material);
}

final class _BalanceAlternativeGridPainter extends CustomPainter {
  const _BalanceAlternativeGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFE7EDF2)
      ..strokeWidth = 1;
    for (final fraction in <double>[0, .5, 1]) {
      final y = (size.height - 16) * fraction;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BalanceAlternativeGridPainter oldDelegate) =>
      false;
}

abstract final class _BalanceAlternativeChartTokens {
  // Directly sampled from the reference Card 3's mint/coral bar ramps.
  static const incomeBottom = Color(0xFF20CA97);
  static const expenseBottom = Color(0xFFED5377);
  static final incomeClayMaterial = FluviClayActiveMaterial.forBase(
    incomeBottom,
  );
  static final expenseClayMaterial = FluviClayActiveMaterial.forBase(
    expenseBottom,
  );
  static const incomeGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFF78E2C3), incomeBottom],
  );
  static const expenseGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: <Color>[Color(0xFFF37092), expenseBottom],
  );
}
