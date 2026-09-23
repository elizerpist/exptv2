import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/domain/ledger_direction.dart';
import 'balance_closings_card.dart';
import 'balance_momentum_card.dart';
import 'balance_primary_chart_card.dart';

/// The single lower Balance card's topic-specific body.
///
/// Financial values arrive in [presentation] from the Core-owned linked
/// presentation. This widget only renders those immutable values and keeps any
/// local inspection independent from Summary navigation.
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
    BalanceLinkedDetailTopic.closings => BalanceClosingsCard(
      presentation: presentation.closings,
    ),
    BalanceLinkedDetailTopic.momentum => BalanceMomentumCard(
      presentation: presentation.momentum,
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
  };
}

/// Balance-local master/detail topics. The existing shared carousel maps its
/// finite logical items to this enum and remains the sole motion owner.
enum BalanceLinkedDetailTopic {
  cashflow,
  closings,
  momentum,
  latestTransaction,
  topCategory,
  topPartner,
}

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
