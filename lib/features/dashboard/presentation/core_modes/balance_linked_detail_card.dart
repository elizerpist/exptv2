import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_category_movers_projection.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/domain/ledger_direction.dart';
import 'balance_primary_chart_card.dart';

/// The lower Balance card's topic-specific body.
///
/// Financial values arrive in [presentation] from the Core-owned linked
/// presentation. This widget only renders those immutable values and keeps its
/// local selection entirely independent from Summary navigation.
class BalanceLinkedDetailCard extends StatelessWidget {
  const BalanceLinkedDetailCard({
    super.key,
    required this.presentation,
    required this.topic,
  });

  final DashboardBalanceLinkedPresentation presentation;
  final BalanceLinkedDetailTopic topic;

  @override
  Widget build(BuildContext context) => switch (topic) {
    BalanceLinkedDetailTopic.cashflow => KeyedSubtree(
      key: const ValueKey<String>('balance-linked-detail-cashflow'),
      child: BalancePrimaryChartCard(presentation: presentation.cashflow),
    ),
    BalanceLinkedDetailTopic.categoryMovers => _CategoryMoversDetail(
      presentation: presentation.categoryMovers,
    ),
    BalanceLinkedDetailTopic.latestTransaction => _LatestTransactionsDetail(
      transactions: presentation.latestTransactions,
    ),
    BalanceLinkedDetailTopic.topCategory => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-category'),
      title: 'Top 5 kategória',
      ranks: presentation.topCategories,
      metric: _RankMetric.amount,
    ),
    BalanceLinkedDetailTopic.topPartner => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-partner'),
      title: 'Top 5 partner',
      ranks: presentation.topPartners,
      metric: _RankMetric.count,
    ),
    BalanceLinkedDetailTopic.prototype => const _PrototypeDetail(),
  };
}

/// Balance-local master/detail topics. The carousel maps its finite logical
/// items to this enum, but its shared controller remains the sole motion owner.
enum BalanceLinkedDetailTopic {
  categoryMovers,
  cashflow,
  latestTransaction,
  topCategory,
  topPartner,
  prototype,
}

/// Presentation-local overview/detail state for the selected immutable Movers
/// payload. Tapping never changes a Query, Summary target or LogBox owner.
final class _CategoryMoversDetail extends StatefulWidget {
  const _CategoryMoversDetail({required this.presentation});

  final DashboardBalanceCategoryMoversPresentation? presentation;

  @override
  State<_CategoryMoversDetail> createState() => _CategoryMoversDetailState();
}

final class _CategoryMoversDetailState extends State<_CategoryMoversDetail> {
  String? _selectedCategoryId;

  @override
  void didUpdateWidget(covariant _CategoryMoversDetail oldWidget) {
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
      return const _BalanceDetailEmpty(label: 'Nincs kategóriaváltozás');
    }
    final selected = _selectedCategoryId == null
        ? null
        : presentation.movers
              .where((mover) => mover.id == _selectedCategoryId)
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
              'Largest category changes',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: FluviVisualTokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              _comparisonLabel(presentation),
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
          '${mover.label}, ${_percentageLabel(mover)}, ${_signedAmountLabel(mover.deltaMinor)}',
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
                    _percentageLabel(mover),
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: positive ? color : FluviVisualTokens.textSecondary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 7),
                  Text(
                    _signedAmountLabel(mover.deltaMinor),
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
            child: Text(
              '← ${mover.label}',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                color: FluviVisualTokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
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
      _metric(context, 'Current', mover.currentMinor),
      _metric(context, 'Previous', mover.referenceMinor),
      _metric(context, 'Change', _percentageLabel(mover)),
      _metric(context, 'Delta', _signedAmountLabel(mover.deltaMinor)),
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

String _percentageLabel(DashboardBalanceCategoryMover mover) {
  if (mover.isNew) return 'New';
  final basisPoints = mover.percentageBasisPoints;
  if (basisPoints == null) return '0%';
  final rounded = (basisPoints / 100).round();
  return '${rounded > 0 ? '+' : ''}$rounded%';
}

String _signedAmountLabel(int amountMinor) =>
    '${amountMinor < 0 ? '-' : '+'}${DashboardPreparedFormatter.amountMinor(amountMinor.abs())}';

String _comparisonLabel(DashboardBalanceCategoryMoversPresentation value) =>
    '${value.currentWindow.startInclusive.isoString} – '
    '${value.currentWindow.endInclusive.isoString} vs '
    '${value.referenceWindow.startInclusive.isoString} – '
    '${value.referenceWindow.endInclusive.isoString}';

final class _LatestTransactionsDetail extends StatelessWidget {
  const _LatestTransactionsDetail({required this.transactions});

  final List<DashboardBalanceScopedTransaction> transactions;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const ValueKey<String>('balance-linked-detail-latest'),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Legutóbbi tranzakciók',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: FluviVisualTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: transactions.isEmpty
                ? const _BalanceDetailEmpty(
                    label: 'Nincs tétel ebben az időszakban',
                  )
                : ListView.separated(
                    key: const ValueKey<String>('balance-linked-latest-list'),
                    padding: EdgeInsets.zero,
                    itemCount: transactions.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final transaction = transactions[index];
                      final signedAmount =
                          transaction.direction == LedgerDirection.expense
                          ? -transaction.amountMinor.abs()
                          : transaction.amountMinor.abs();
                      return Semantics(
                        label:
                            '${transaction.title}, ${DashboardPreparedFormatter.amountMinor(signedAmount)}',
                        child: ListTile(
                          key: ValueKey<String>(
                            'balance-linked-latest-${transaction.entryId}',
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 2,
                          ),
                          dense: true,
                          title: Text(
                            transaction.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(
                                  color: FluviVisualTokens.textPrimary,
                                  fontWeight: FontWeight.w600,
                                ),
                          ),
                          subtitle: Text(
                            transaction.categoryTitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelSmall
                                ?.copyWith(
                                  color: FluviVisualTokens.textSecondary,
                                ),
                          ),
                          trailing: Text(
                            DashboardPreparedFormatter.amountMinor(
                              signedAmount,
                            ),
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color:
                                      transaction.direction ==
                                          LedgerDirection.income
                                      ? FluviVisualTokens.textPrimary
                                      : FluviVisualTokens.textSecondary,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    ),
  );
}

enum _RankMetric { amount, count }

final class _RankedDetail extends StatelessWidget {
  const _RankedDetail({
    super.key,
    required this.title,
    required this.ranks,
    required this.metric,
  });

  final String title;
  final List<DashboardBalanceRankedItem> ranks;
  final _RankMetric metric;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: ranks.isEmpty
              ? const _BalanceDetailEmpty(label: 'Nincs rangsorolható adat')
              : ListView.separated(
                  padding: EdgeInsets.zero,
                  itemCount: ranks.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 3),
                  itemBuilder: (context, index) => _RankedRow(
                    item: ranks[index],
                    rank: index + 1,
                    featured: index == 0,
                    metric: metric,
                  ),
                ),
        ),
      ],
    ),
  );
}

final class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.item,
    required this.rank,
    required this.featured,
    required this.metric,
  });

  final DashboardBalanceRankedItem item;
  final int rank;
  final bool featured;
  final _RankMetric metric;

  @override
  Widget build(BuildContext context) {
    final value = switch (metric) {
      _RankMetric.amount => DashboardPreparedFormatter.amountMinor(
        item.amountMinor.abs(),
      ),
      _RankMetric.count => '${item.transactionCount} tranzakció',
    };
    return Semantics(
      label: '$rank. ${item.label}, $value',
      child: Container(
        key: ValueKey<String>('balance-linked-rank-${item.id}'),
        height: featured ? 58 : 42,
        padding: EdgeInsets.symmetric(
          horizontal: featured ? 10 : 6,
          vertical: featured ? 8 : 4,
        ),
        decoration: featured
            ? BoxDecoration(
                color: CategoryColorCatalog.resolve(
                  item.categoryColorId,
                ).middleColor.withValues(alpha: .10),
                borderRadius: BorderRadius.circular(14),
              )
            : null,
        child: Row(
          children: <Widget>[
            SizedBox(
              width: 20,
              child: Text(
                '$rank.',
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: FluviVisualTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            _RankAvatar(item: item, featured: featured),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: FluviVisualTokens.textPrimary,
                  fontWeight: featured ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              value,
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                color: FluviVisualTokens.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Category art is normally delivered by the prepared vector atlas. Balance
/// must not turn a late atlas into a loading dependency, so its first frame
/// retains the same canonical category color with a small neutral icon until
/// the shared atlas is ready.
final class _RankAvatar extends StatelessWidget {
  const _RankAvatar({required this.item, required this.featured});

  final DashboardBalanceRankedItem item;
  final bool featured;

  @override
  Widget build(BuildContext context) {
    final size = featured ? 42.0 : 30.0;
    final atlas = PreparedVectorAssetAtlas.instance;
    if (atlas.isReady) {
      return CategoryVisualBadge(
        colorHandle: CategoryColorCatalog.handleOf(item.categoryColorId),
        iconHandle: CategoryIconCatalog.handleOf(item.categoryIconId),
        size: size,
        iconSize: featured ? 20 : 15,
        selected: featured,
      );
    }
    return Semantics(
      label: item.label,
      selected: featured,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          gradient: CategoryColorCatalog.resolve(item.categoryColorId).gradient,
          borderRadius: BorderRadius.circular(size * .28),
        ),
        alignment: Alignment.center,
        child: Icon(
          Icons.category_rounded,
          size: featured ? 20 : 15,
          color: Colors.white,
        ),
      ),
    );
  }
}

final class _PrototypeDetail extends StatelessWidget {
  const _PrototypeDetail();

  @override
  Widget build(BuildContext context) => const Center(
    key: ValueKey<String>('balance-linked-detail-prototype'),
    child: Text('Prototípus'),
  );
}

final class _BalanceDetailEmpty extends StatelessWidget {
  const _BalanceDetailEmpty({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) => Center(
    child: Text(
      label,
      textAlign: TextAlign.center,
      style: Theme.of(
        context,
      ).textTheme.bodySmall?.copyWith(color: FluviVisualTokens.textSecondary),
    ),
  );
}
