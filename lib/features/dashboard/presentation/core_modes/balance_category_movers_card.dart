import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_category_movers_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'balance_category_visual_badge.dart';
import 'balance_category_movers_presentation.dart';

/// Presentation-local Movers overview/detail state. It inspects only the
/// Core-owned immutable payload; selecting or returning never changes Query,
/// Summary, the upper carousel, or any data authority.
final class BalanceCategoryMoversCard extends StatefulWidget {
  const BalanceCategoryMoversCard({super.key, required this.presentation});

  final DashboardBalanceCategoryMoversPresentation? presentation;

  @override
  State<BalanceCategoryMoversCard> createState() =>
      _BalanceCategoryMoversCardState();
}

final class _BalanceCategoryMoversCardState
    extends State<BalanceCategoryMoversCard> {
  String? _selectedCategoryId;

  @override
  void didUpdateWidget(covariant BalanceCategoryMoversCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.presentation?.presentationId ==
        widget.presentation?.presentationId) {
      return;
    }
    final selected = _selectedCategoryId;
    if (selected != null &&
        !(widget.presentation?.movers.any((mover) => mover.id == selected) ??
            false)) {
      _selectedCategoryId = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final presentation = widget.presentation;
    if (presentation == null || presentation.isNoChange) {
      return const Center(
        key: ValueKey<String>('balance-linked-detail-category-movers-empty'),
        child: Text('Nincs kategóriaváltozás'),
      );
    }
    final selectedId = _selectedCategoryId;
    final selected = selectedId == null
        ? null
        : presentation.movers
              .where((mover) => mover.id == selectedId)
              .firstOrNull;
    return selected == null
        ? _CategoryMoversOverview(
            presentation: presentation,
            onSelected: (mover) =>
                setState(() => _selectedCategoryId = mover.id),
          )
        : _CategoryMoverTrendDetail(
            mover: selected,
            onBack: () => setState(() => _selectedCategoryId = null),
          );
  }
}

final class _CategoryMoversOverview extends StatelessWidget {
  const _CategoryMoversOverview({
    required this.presentation,
    required this.onSelected,
  });

  final DashboardBalanceCategoryMoversPresentation presentation;
  final ValueChanged<DashboardBalanceCategoryMover> onSelected;

  @override
  Widget build(BuildContext context) {
    final movers = presentation.movers.take(5).toList(growable: false);
    final maximumImpact = movers
        .map((mover) => mover.impactMinor)
        .fold<int>(1, math.max);
    return KeyedSubtree(
      key: const ValueKey<String>('balance-linked-detail-category-movers'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Legnagyobb kategóriaváltozás',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: FluviVisualTokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              balanceCategoryMoverComparisonLabel(presentation),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: FluviVisualTokens.textSecondary,
              ),
            ),
            const SizedBox(height: 5),
            const _DivergingAxisLegend(),
            const SizedBox(height: 2),
            Expanded(
              child: ListView.separated(
                key: const ValueKey<String>('balance-category-movers-list'),
                padding: EdgeInsets.zero,
                itemCount: movers.length,
                separatorBuilder: (_, _) => const SizedBox(height: 3),
                itemBuilder: (context, index) => _CategoryMoverRow(
                  mover: movers[index],
                  maximumImpact: maximumImpact,
                  onTap: () => onSelected(movers[index]),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _DivergingAxisLegend extends StatelessWidget {
  const _DivergingAxisLegend();

  @override
  Widget build(BuildContext context) => SizedBox(
    height: 14,
    child: Row(
      children: <Widget>[
        Expanded(
          child: Text(
            'csökkenés',
            textAlign: TextAlign.right,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ),
        Container(width: 1, color: FluviVisualTokens.textSecondary),
        Expanded(
          child: Text(
            'növekedés',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textSecondary,
            ),
          ),
        ),
      ],
    ),
  );
}

final class _CategoryMoverRow extends StatelessWidget {
  const _CategoryMoverRow({
    required this.mover,
    required this.maximumImpact,
    required this.onTap,
  });

  final DashboardBalanceCategoryMover mover;
  final int maximumImpact;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final positive = mover.deltaMinor >= 0;
    final intensity = maximumImpact == 0
        ? 0.0
        : mover.impactMinor / maximumImpact;
    final color = CategoryColorCatalog.resolve(
      mover.categoryColorId,
    ).middleColor;
    return Semantics(
      button: true,
      label:
          '${mover.label}, ${balanceCategoryMoverPercentageLabel(mover)}, ${balanceCategoryMoverSignedAmountLabel(mover.deltaMinor)}',
      child: GestureDetector(
        key: ValueKey<String>('balance-category-mover-${mover.id}'),
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            children: <Widget>[
              Row(
                children: <Widget>[
                  BalanceCategoryVisualBadge(
                    semanticLabel: mover.label,
                    categoryColorId: mover.categoryColorId,
                    categoryIconId: mover.categoryIconId,
                    size: 22,
                    iconSize: 13,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      mover.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: FluviVisualTokens.textPrimary,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    balanceCategoryMoverPercentageLabel(mover),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: positive ? color : FluviVisualTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    balanceCategoryMoverSignedAmountLabel(mover.deltaMinor),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 3),
              SizedBox(
                height: 7,
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerRight,
                        child: positive
                            ? null
                            : FractionallySizedBox(
                                widthFactor: intensity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: color.withValues(alpha: .65),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                      ),
                    ),
                    Container(width: 1, color: FluviVisualTokens.textSecondary),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: !positive
                            ? null
                            : FractionallySizedBox(
                                widthFactor: intensity,
                                child: DecoratedBox(
                                  decoration: BoxDecoration(
                                    color: color,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _CategoryMoverTrendDetail extends StatelessWidget {
  const _CategoryMoverTrendDetail({required this.mover, required this.onBack});

  final DashboardBalanceCategoryMover mover;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const ValueKey<String>('balance-category-movers-detail'),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 8, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          TextButton(
            key: const ValueKey<String>('balance-category-movers-back'),
            onPressed: onBack,
            style: TextButton.styleFrom(padding: EdgeInsets.zero),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.arrow_back, size: 18),
                const SizedBox(width: 5),
                BalanceCategoryVisualBadge(
                  semanticLabel: mover.label,
                  categoryColorId: mover.categoryColorId,
                  categoryIconId: mover.categoryIconId,
                  size: 26,
                  iconSize: 15,
                ),
                const SizedBox(width: 7),
                Flexible(
                  child: Text(
                    mover.label,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: FluviVisualTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          _CategoryMoverMetrics(mover: mover),
          const SizedBox(height: 8),
          Expanded(
            child: CustomPaint(
              key: const ValueKey<String>('balance-category-movers-trend'),
              painter: _CategoryMoverTrendPainter(
                trend: mover.trend,
                currentColor: CategoryColorCatalog.resolve(
                  mover.categoryColorId,
                ).middleColor,
              ),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    ),
  );
}

final class _CategoryMoverMetrics extends StatelessWidget {
  const _CategoryMoverMetrics({required this.mover});

  final DashboardBalanceCategoryMover mover;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _metric(context, 'Most', mover.currentMinor),
      _metric(context, 'Előző', mover.referenceMinor),
      _metric(context, 'Változás', balanceCategoryMoverPercentageLabel(mover)),
      _metric(
        context,
        'Eltérés',
        balanceCategoryMoverSignedAmountLabel(mover.deltaMinor),
      ),
    ],
  );

  Widget _metric(BuildContext context, String label, Object value) => Expanded(
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
          value is int
              ? DashboardPreparedFormatter.amountMinor(value)
              : '$value',
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

final class _CategoryMoverTrendPainter extends CustomPainter {
  const _CategoryMoverTrendPainter({
    required this.trend,
    required this.currentColor,
  });

  final List<DashboardBalanceCategoryMoverTrendPoint> trend;
  final Color currentColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (trend.isEmpty || size.isEmpty) return;
    final maximum = trend.fold<int>(
      0,
      (value, point) =>
          math.max(value, math.max(point.currentMinor, point.referenceMinor)),
    );
    final safeMaximum = math.max(1, maximum);
    final current = Path();
    final reference = Path();
    for (var index = 0; index < trend.length; index += 1) {
      final x = trend.length == 1
          ? size.width / 2
          : size.width * index / (trend.length - 1);
      final currentY =
          size.height - size.height * trend[index].currentMinor / safeMaximum;
      final referenceY =
          size.height - size.height * trend[index].referenceMinor / safeMaximum;
      if (index == 0) {
        current.moveTo(x, currentY);
        reference.moveTo(x, referenceY);
      } else {
        current.lineTo(x, currentY);
        reference.lineTo(x, referenceY);
      }
    }
    canvas.drawLine(
      Offset(0, size.height),
      Offset(size.width, size.height),
      Paint()..color = FluviVisualTokens.textSecondary.withValues(alpha: .35),
    );
    canvas.drawPath(
      reference,
      Paint()
        ..color = FluviVisualTokens.textSecondary.withValues(alpha: .65)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.4,
    );
    canvas.drawPath(
      current,
      Paint()
        ..color = currentColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );
  }

  @override
  bool shouldRepaint(covariant _CategoryMoverTrendPainter oldDelegate) =>
      oldDelegate.trend != trend || oldDelegate.currentColor != currentColor;
}
