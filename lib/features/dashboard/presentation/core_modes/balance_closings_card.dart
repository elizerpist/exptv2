import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_closings_momentum_projection.dart';
import '../../application/dashboard_mode_spec.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';

/// The Balance lower-card renderer for discrete, zero-centred period results.
/// It consumes the immutable Core DTO and owns only the local bucket selection.
class BalanceClosingsCard extends StatefulWidget {
  const BalanceClosingsCard({super.key, required this.presentation});

  final DashboardBalanceClosingsPresentation presentation;

  @override
  State<BalanceClosingsCard> createState() => _BalanceClosingsCardState();
}

final class _BalanceClosingsCardState extends State<BalanceClosingsCard> {
  String? _selectedBucketId;

  @override
  void didUpdateWidget(covariant BalanceClosingsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation.presentationId !=
        widget.presentation.presentationId) {
      _selectedBucketId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final buckets = widget.presentation.buckets;
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 168 || constraints.maxHeight < 132) {
          return const Center(
            key: ValueKey<String>('balance-closings-compact-surface'),
            child: Text('Zárások'),
          );
        }
        if (buckets.isEmpty) {
          return const _BalanceClosingsEmpty();
        }
        final selected = buckets
            .where((bucket) => bucket.id == _selectedBucketId)
            .firstOrNull;
        final palette = DashboardModePaletteResolver.resolve(
          DashboardModeSpec.balance,
        );
        return KeyedSubtree(
          key: const ValueKey<String>('balance-linked-detail-closings'),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Zárások',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: FluviVisualTokens.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${widget.presentation.positiveBucketCount} / ${buckets.length} pozitív',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: FluviVisualTokens.textSecondary,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Semantics(
                    label: 'Zárások, középre igazított nulla tengely',
                    child: LayoutBuilder(
                      builder: (context, chartConstraints) => GestureDetector(
                        key: const ValueKey<String>('balance-closings-chart'),
                        behavior: HitTestBehavior.opaque,
                        onTapDown: (details) {
                          final index =
                              (details.localPosition.dx /
                                      chartConstraints.maxWidth *
                                      buckets.length)
                                  .floor()
                                  .clamp(0, buckets.length - 1);
                          setState(() => _selectedBucketId = buckets[index].id);
                        },
                        child: CustomPaint(
                          painter: _ClosingsPainter(
                            buckets: buckets,
                            positiveColor: palette.incomeGradient.colors.first,
                            negativeColor: palette.expenseGradient.colors.first,
                          ),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 3),
                _ClosingBucketLabels(buckets: buckets),
                if (selected != null) _ClosingInspection(bucket: selected),
              ],
            ),
          ),
        );
      },
    );
  }
}

final class _ClosingBucketLabels extends StatelessWidget {
  const _ClosingBucketLabels({required this.buckets});

  final List<DashboardBalanceClosingBucket> buckets;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 14,
    child: Row(
      children: <Widget>[
        for (final bucket in buckets)
          Expanded(
            child: Text(
              bucket.label,
              key: ValueKey<String>('balance-closing-label-${bucket.id}'),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: FluviVisualTokens.textSecondary,
                fontSize: 8,
                letterSpacing: 0,
              ),
            ),
          ),
      ],
    ),
  );
}

final class _BalanceClosingsEmpty extends StatelessWidget {
  const _BalanceClosingsEmpty();

  @override
  Widget build(BuildContext context) => const KeyedSubtree(
    key: ValueKey<String>('balance-linked-detail-closings'),
    child: Center(child: Text('Nincs zárási adat')),
  );
}

final class _ClosingInspection extends StatelessWidget {
  const _ClosingInspection({required this.bucket});

  final DashboardBalanceClosingBucket bucket;

  @override
  Widget build(BuildContext context) => Semantics(
    label:
        '${bucket.label}, Bevétel ${DashboardPreparedFormatter.amountMinor(bucket.incomeMinor)}, Kiadás ${DashboardPreparedFormatter.amountMinor(bucket.expenseMinor)}, Egyenleg ${DashboardPreparedFormatter.amountMinor(bucket.netMinor)}',
    child: Container(
      key: const ValueKey<String>('balance-closing-inspection'),
      margin: const EdgeInsets.only(top: 6),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: FluviVisualTokens.surface,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        '${bucket.label} · Bevétel ${DashboardPreparedFormatter.amountMinor(bucket.incomeMinor)} · Kiadás ${DashboardPreparedFormatter.amountMinor(bucket.expenseMinor)} · Nettó ${DashboardPreparedFormatter.amountMinor(bucket.netMinor)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(
          context,
        ).textTheme.labelSmall?.copyWith(color: FluviVisualTokens.textPrimary),
      ),
    ),
  );
}

/// Bounded renderer geometry for the diverging bars. This is presentation
/// geometry only: financial values remain in the immutable Core DTO.
@visibleForTesting
List<Rect?> balanceClosingBarRectsFor({
  required Size size,
  required List<DashboardBalanceClosingBucket> buckets,
}) {
  if (buckets.isEmpty || size.isEmpty) return const <Rect?>[];
  final axisY = size.height / 2;
  final maximum = buckets
      .map((bucket) => bucket.netMinor.abs())
      .fold<int>(1, math.max);
  final slot = size.width / buckets.length;
  final barWidth = math.max(1.0, slot * .62);
  return List<Rect?>.unmodifiable(<Rect?>[
    for (var index = 0; index < buckets.length; index += 1)
      if (buckets[index].netMinor == 0)
        null
      else
        Rect.fromLTWH(
          index * slot + (slot - barWidth) / 2,
          buckets[index].netMinor > 0
              ? axisY -
                    (size.height * .43) *
                        buckets[index].netMinor.abs() /
                        maximum
              : axisY,
          barWidth,
          (size.height * .43) * buckets[index].netMinor.abs() / maximum,
        ),
  ]);
}

final class _ClosingsPainter extends CustomPainter {
  const _ClosingsPainter({
    required this.buckets,
    required this.positiveColor,
    required this.negativeColor,
  });

  final List<DashboardBalanceClosingBucket> buckets;
  final Color positiveColor;
  final Color negativeColor;

  @override
  void paint(Canvas canvas, Size size) {
    final axisY = size.height / 2;
    final axis = Paint()
      ..color = FluviVisualTokens.textSecondary.withValues(alpha: .42)
      ..strokeWidth = 1;
    canvas.drawLine(
      Offset.zero + Offset(0, axisY),
      Offset(size.width, axisY),
      axis,
    );
    final rects = balanceClosingBarRectsFor(size: size, buckets: buckets);
    for (var index = 0; index < buckets.length; index += 1) {
      final net = buckets[index].netMinor;
      final rect = rects[index];
      if (rect == null) continue;
      canvas.drawRect(
        rect,
        Paint()..color = net > 0 ? positiveColor : negativeColor,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ClosingsPainter oldDelegate) =>
      oldDelegate.buckets != buckets ||
      oldDelegate.positiveColor != positiveColor ||
      oldDelegate.negativeColor != negativeColor;
}
