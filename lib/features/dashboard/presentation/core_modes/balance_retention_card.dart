import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_retention_stability_projection.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// Balance-local renderer for the immutable sibling-context Retention DTO.
class BalanceRetentionCard extends StatefulWidget {
  const BalanceRetentionCard({super.key, required this.presentation});

  final DashboardBalanceRetentionPresentation presentation;

  @override
  State<BalanceRetentionCard> createState() => _BalanceRetentionCardState();
}

final class _BalanceRetentionCardState extends State<BalanceRetentionCard> {
  String? _inspectedPeriodId;

  @override
  void didUpdateWidget(covariant BalanceRetentionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.presentationId !=
        widget.presentation.presentationId) {
      _inspectedPeriodId = null;
    }
  }

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth < 168 || constraints.maxHeight < 132) {
        return const Center(
          key: ValueKey<String>('balance-retention-compact-surface'),
          child: Text('Megtartási arány'),
        );
      }
      final periods = widget.presentation.periods;
      if (periods.isEmpty) {
        return const KeyedSubtree(
          key: ValueKey<String>('balance-linked-detail-retention'),
          child: Center(child: Text('Nincs adat')),
        );
      }
      final inspected = periods
          .where((period) => period.id == _inspectedPeriodId)
          .firstOrNull;
      final palette = DashboardModePaletteResolver.resolve(
        DashboardModeSpec.balance,
      );
      return KeyedSubtree(
        key: const ValueKey<String>('balance-linked-detail-retention'),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Megtartási arány',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: FluviVisualTokens.textPrimary,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                formatBalanceRetentionPeriod(
                  widget.presentation.selectedPeriod,
                ),
                key: const ValueKey<String>('balance-retention-hero'),
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: FluviVisualTokens.textSecondary,
                ),
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Semantics(
                  label: 'Megtartási arány, nulla százalék referencia',
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: SizedBox(
                      width: math.max(
                        constraints.maxWidth - 28,
                        periods.length * 42.0,
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: <Widget>[
                          for (final period in periods)
                            Expanded(
                              child: _RetentionPeriodBar(
                                period: period,
                                allPeriods: periods,
                                positiveColor:
                                    palette.incomeGradient.colors.first,
                                negativeColor:
                                    palette.expenseGradient.colors.first,
                                onTap: () => setState(
                                  () => _inspectedPeriodId = period.id,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.presentation.selectedPeriod case final selected?)
                _RetentionMetrics(period: selected),
              if (inspected != null) _RetentionInspection(period: inspected),
            ],
          ),
        ),
      );
    },
  );
}

final class _RetentionMetrics extends StatelessWidget {
  const _RetentionMetrics({required this.period});

  final DashboardBalanceRetentionPeriod period;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _metric(context, 'Bevétel', period.incomeMinor),
      const SizedBox(width: 8),
      _metric(context, 'Megtartott', period.netMinor),
      const SizedBox(width: 8),
      _metric(context, 'Kiadás', period.expenseMinor),
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
          DashboardPreparedFormatter.amountMinor(value),
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

final class _RetentionPeriodBar extends StatelessWidget {
  const _RetentionPeriodBar({
    required this.period,
    required this.allPeriods,
    required this.positiveColor,
    required this.negativeColor,
    required this.onTap,
  });

  final DashboardBalanceRetentionPeriod period;
  final List<DashboardBalanceRetentionPeriod> allPeriods;
  final Color positiveColor;
  final Color negativeColor;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Column(
      children: <Widget>[
        Expanded(
          child: CustomPaint(
            key: ValueKey<String>('balance-retention-bar-${period.id}'),
            painter: _RetentionPainter(
              period: period,
              allPeriods: allPeriods,
              positiveColor: positiveColor,
              negativeColor: negativeColor,
            ),
            child: const SizedBox.expand(),
          ),
        ),
        Text(
          period.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            color: period.selected
                ? FluviVisualTokens.textPrimary
                : FluviVisualTokens.textSecondary,
            fontSize: 8,
            fontWeight: period.selected ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
      ],
    ),
  );
}

final class _RetentionPainter extends CustomPainter {
  const _RetentionPainter({
    required this.period,
    required this.allPeriods,
    required this.positiveColor,
    required this.negativeColor,
  });

  final DashboardBalanceRetentionPeriod period;
  final List<DashboardBalanceRetentionPeriod> allPeriods;
  final Color positiveColor;
  final Color negativeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisY = size.height / 2;
    final axis = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .42)
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, axisY), Offset(size.width, axisY), axis);
    final ratio = period.retentionBasisPoints;
    if (ratio == null) {
      canvas.drawCircle(
        Offset(size.width / 2, axisY),
        2.5,
        Paint()..color = FluviVisualTokens.textSecondary.withValues(alpha: .72),
      );
      return;
    }
    final rect = balanceRetentionBarRectFor(
      size: size,
      basisPoints: ratio,
      allPeriods: allPeriods,
    );
    canvas.drawRect(
      rect,
      Paint()..color = ratio >= 0 ? positiveColor : negativeColor,
    );
  }

  @override
  bool shouldRepaint(covariant _RetentionPainter oldDelegate) =>
      oldDelegate.period != period ||
      oldDelegate.allPeriods != allPeriods ||
      oldDelegate.positiveColor != positiveColor ||
      oldDelegate.negativeColor != negativeColor;
}

/// Pure retention-bar geometry with a stable zero-percent axis.
@visibleForTesting
Rect balanceRetentionBarRectFor({
  required Size size,
  required int basisPoints,
  required List<DashboardBalanceRetentionPeriod> allPeriods,
}) {
  final extent = math.max(
    10000,
    allPeriods
        .map((period) => period.retentionBasisPoints?.abs() ?? 0)
        .fold<int>(0, math.max),
  );
  final axisY = size.height / 2;
  final height = size.height * .42 * basisPoints.abs() / extent;
  return Rect.fromLTWH(
    size.width * .25,
    basisPoints >= 0 ? axisY - height : axisY,
    size.width * .5,
    height,
  );
}

final class _RetentionInspection extends StatelessWidget {
  const _RetentionInspection({required this.period});

  final DashboardBalanceRetentionPeriod period;

  @override
  Widget build(BuildContext context) => Container(
    key: const ValueKey<String>('balance-retention-inspection'),
    margin: const EdgeInsets.only(top: 6),
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
    decoration: BoxDecoration(
      color: FluviVisualTokens.surface,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      '${period.label} · Bevétel ${DashboardPreparedFormatter.amountMinor(period.incomeMinor)} · Nettó ${DashboardPreparedFormatter.amountMinor(period.netMinor)} · ${formatBalanceRetentionPeriod(period)}',
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: Theme.of(
        context,
      ).textTheme.labelSmall?.copyWith(color: FluviVisualTokens.textPrimary),
    ),
  );
}

String formatBalanceRetentionPeriod(DashboardBalanceRetentionPeriod? period) {
  if (period == null) return 'Nincs adat';
  return switch (period.state) {
    DashboardBalanceRetentionState.value => formatBalanceRetentionBasisPoints(
      period.retentionBasisPoints!,
    ),
    DashboardBalanceRetentionState.noIncome => 'Nincs bevétel',
    DashboardBalanceRetentionState.noData => 'Nincs adat',
  };
}

String formatBalanceRetentionBasisPoints(int basisPoints) {
  final sign = basisPoints < 0 ? '−' : '';
  final absolute = basisPoints.abs();
  final whole = absolute ~/ 100;
  final fraction = absolute % 100;
  return fraction == 0
      ? '$sign$whole%'
      : '$sign$whole,${fraction.toString().padLeft(2, '0')}%';
}
