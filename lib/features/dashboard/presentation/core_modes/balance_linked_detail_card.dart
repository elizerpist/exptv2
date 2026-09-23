import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_visual_badge.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../application/dashboard_balance_entity_insights_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/domain/ledger_direction.dart';
import 'balance_closings_card.dart';
import 'balance_cashflow_stability_card.dart';
import 'balance_future_placeholder_card.dart';
import 'balance_momentum_card.dart';
import 'balance_primary_chart_card.dart';
import 'balance_retention_card.dart';

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
    BalanceLinkedDetailTopic.retention => BalanceRetentionCard(
      presentation: presentation.retention,
    ),
    BalanceLinkedDetailTopic.stability => BalanceCashflowStabilityCard(
      presentation: presentation.stability,
    ),
    BalanceLinkedDetailTopic.ghost =>
      const BalanceFuturePlaceholderCard.ghost(),
    BalanceLinkedDetailTopic.forecast =>
      const BalanceFuturePlaceholderCard.forecast(),
    BalanceLinkedDetailTopic.latestTransaction => _LatestTransactionsDetail(
      transactions: presentation.latestTransactions,
    ),
    BalanceLinkedDetailTopic.topCategory => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-category'),
      title: 'Top 5 kategória',
      ranks: presentation.topCategories,
      metric: _RankMetric.amount,
      kind: _RankDetailKind.category,
      categoryInsights: presentation.categoryInsights,
    ),
    BalanceLinkedDetailTopic.topPartner => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-partner'),
      title: 'Top 5 partner',
      ranks: presentation.topPartners,
      metric: _RankMetric.count,
      kind: _RankDetailKind.partner,
      partnerInsights: presentation.partnerInsights,
    ),
  };
}

/// Balance-local master/detail topics. The existing shared carousel maps its
/// finite logical items to this enum and remains the sole motion owner.
enum BalanceLinkedDetailTopic {
  cashflow,
  closings,
  momentum,
  retention,
  stability,
  ghost,
  forecast,
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

enum _RankDetailKind { category, partner }

/// The master/detail state intentionally lives only in this lower-card
/// renderer.  Its selected ID is never published to Core, Summary or Query.
final class _RankedDetail extends StatefulWidget {
  const _RankedDetail({
    super.key,
    required this.title,
    required this.ranks,
    required this.metric,
    required this.kind,
    this.categoryInsights = const <String, DashboardBalanceCategoryInsight>{},
    this.partnerInsights = const <String, DashboardBalancePartnerInsight>{},
  });

  final String title;
  final List<DashboardBalanceRankedItem> ranks;
  final _RankMetric metric;
  final _RankDetailKind kind;
  final Map<String, DashboardBalanceCategoryInsight> categoryInsights;
  final Map<String, DashboardBalancePartnerInsight> partnerInsights;

  @override
  State<_RankedDetail> createState() => _RankedDetailState();
}

final class _RankedDetailState extends State<_RankedDetail> {
  String? _selectedEntityId;

  @override
  void didUpdateWidget(covariant _RankedDetail oldWidget) {
    super.didUpdateWidget(oldWidget);
    final selected = _selectedEntityId;
    if (selected == null) return;
    final stillExists = switch (widget.kind) {
      _RankDetailKind.category => widget.categoryInsights.containsKey(selected),
      _RankDetailKind.partner => widget.partnerInsights.containsKey(selected),
    };
    // Never render a DTO retained from a previous Summary/direction identity.
    if (!stillExists) _selectedEntityId = null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntityId;
    if (selected != null) {
      return switch (widget.kind) {
        _RankDetailKind.category => _CategoryInsightDetail(
          insight: widget.categoryInsights[selected]!,
          onBack: _clearSelection,
        ),
        _RankDetailKind.partner => _PartnerInsightDetail(
          insight: widget.partnerInsights[selected]!,
          onBack: _clearSelection,
        ),
      };
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            widget.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: FluviVisualTokens.textPrimary,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: widget.ranks.isEmpty
                ? const _BalanceDetailEmpty(label: 'Nincs rangsorolható adat')
                : ListView.separated(
                    key: ValueKey<String>(
                      'balance-linked-rank-list-${widget.kind.name}',
                    ),
                    padding: EdgeInsets.zero,
                    itemCount: widget.ranks.length,
                    separatorBuilder: (_, _) => const SizedBox(height: 3),
                    itemBuilder: (context, index) {
                      final item = widget.ranks[index];
                      final hasCurrentInsight = switch (widget.kind) {
                        _RankDetailKind.category => widget.categoryInsights
                            .containsKey(item.id),
                        _RankDetailKind.partner => widget.partnerInsights
                            .containsKey(item.id),
                      };
                      return _RankedRow(
                        item: item,
                        rank: index + 1,
                        featured: index == 0,
                        metric: widget.metric,
                        // A rank must never open an absent/stale DTO.  The
                        // production projection publishes these maps together,
                        // while this guard also keeps partial test fixtures and
                        // a transitional publication truthful.
                        onTap: hasCurrentInsight
                            ? () => setState(
                                () => _selectedEntityId = item.id,
                              )
                            : null,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  void _clearSelection() => setState(() => _selectedEntityId = null);
}

final class _RankedRow extends StatelessWidget {
  const _RankedRow({
    required this.item,
    required this.rank,
    required this.featured,
    required this.metric,
    required this.onTap,
  });

  final DashboardBalanceRankedItem item;
  final int rank;
  final bool featured;
  final _RankMetric metric;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final value = switch (metric) {
      _RankMetric.amount => DashboardPreparedFormatter.amountMinor(
        item.amountMinor.abs(),
      ),
      _RankMetric.count => '${item.transactionCount} tranzakció',
    };
    return Semantics(
      button: onTap != null,
      label: '$rank. ${item.label}, $value',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('balance-linked-rank-${item.id}'),
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
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
        ),
      ),
    );
  }
}

final class _CategoryInsightDetail extends StatelessWidget {
  const _CategoryInsightDetail({required this.insight, required this.onBack});

  final DashboardBalanceCategoryInsight insight;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => _EntityDetailScaffold(
    listKey: const ValueKey<String>('balance-category-insight-detail'),
    backKey: const ValueKey<String>('balance-category-insight-back'),
    onBack: onBack,
    title: insight.label,
    children: <Widget>[
      _DetailHero(
        amountMinor: insight.amountMinor,
        subtitle:
            '${_formatBasisPoints(insight.shareBasisPoints)} ${insight.direction == LedgerDirection.expense ? 'a kiadásokból' : 'a bevételekből'}',
      ),
      _MetricLine(
        key: const ValueKey<String>('balance-category-insight-metrics'),
        text:
            '${insight.transactionCount} tranzakció · ${insight.activeDayCount} aktív nap · medián ${DashboardPreparedFormatter.amountMinor(insight.roundedMedianAmountMinor)}',
      ),
      const SizedBox(height: 14),
      const _DetailSectionTitle('Időbeli profil'),
      _TemporalProfile(buckets: insight.temporalBuckets, money: true),
      const SizedBox(height: 14),
      const _DetailSectionTitle('Tipikus tranzakcióméret'),
      if (insight.temporalBuckets.isEmpty && insight.usesDayLowSampleFallback)
        _MetricLine(
          key: const ValueKey<String>('balance-category-insight-day-fallback'),
          text:
              'Min. ${DashboardPreparedFormatter.amountMinor(insight.minimumAmountMinor)} · Medián ${DashboardPreparedFormatter.amountMinor(insight.roundedMedianAmountMinor)} · Max. ${DashboardPreparedFormatter.amountMinor(insight.maximumAmountMinor)}',
        )
      else
        _TransactionSizeDistribution(distribution: insight.distribution),
      if (insight.temporalBuckets.isEmpty) ...<Widget>[
        const SizedBox(height: 14),
        const _DetailSectionTitle('Mai előfordulások'),
        _OccurrenceList(
          occurrences: insight.dayOccurrences,
          oldestFirst: true,
          hiddenCount: insight.hiddenDayOccurrenceCount,
        ),
      ],
    ],
  );
}

final class _PartnerInsightDetail extends StatelessWidget {
  const _PartnerInsightDetail({required this.insight, required this.onBack});

  final DashboardBalancePartnerInsight insight;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final relationship = insight.relationship;
    final cadence = relationship.roundedTypicalCadenceMinutes;
    return _EntityDetailScaffold(
      listKey: const ValueKey<String>('balance-partner-insight-detail'),
      backKey: const ValueKey<String>('balance-partner-insight-back'),
      onBack: onBack,
      title: insight.label,
      children: <Widget>[
        _DetailHero(
          amountMinor: insight.amountMinor,
          subtitle: '${insight.transactionCount} tranzakció',
        ),
        _MetricLine(
          key: const ValueKey<String>('balance-partner-insight-metrics'),
          text:
              '${insight.activeDayCount} aktív nap · Legutóbbi: ${_formatOccurrenceDate(insight.latestScopeOccurrence)}',
        ),
        const SizedBox(height: 14),
        const _DetailSectionTitle('Aktivitás az időszakban'),
        _TemporalProfile(buckets: insight.temporalBuckets, money: false),
        const SizedBox(height: 14),
        const _DetailSectionTitle('Tipikus idő két tranzakció között'),
        _MetricLine(
          key: const ValueKey<String>('balance-partner-insight-cadence'),
          text: cadence == null
              ? 'Nincs elég ritmusadat'
              : _formatCadence(cadence),
        ),
        if (relationship.cadenceOccurrences.isNotEmpty)
          _CadenceStrip(occurrences: relationship.cadenceOccurrences),
        const SizedBox(height: 14),
        const _DetailSectionTitle('Tipikus tranzakció'),
        _MetricLine(
          key: const ValueKey<String>('balance-partner-insight-amount-band'),
          text:
              '${DashboardPreparedFormatter.amountMinor(relationship.firstQuartileAmountMinor)} — ${DashboardPreparedFormatter.amountMinor(relationship.thirdQuartileAmountMinor)} · medián ${DashboardPreparedFormatter.amountMinor(relationship.roundedMedianAmountMinor)}',
        ),
        const SizedBox(height: 14),
        const _DetailSectionTitle('Kapcsolati előzmény · teljes időszak'),
        _MetricLine(
          key: const ValueKey<String>('balance-partner-insight-history'),
          text:
              'Első: ${_formatOccurrenceDate(relationship.firstOccurrence)} · Legutóbbi: ${_formatOccurrenceDate(relationship.latestOccurrence)} · Összesen: ${relationship.allHistoryTransactionCount} tranzakció',
        ),
        const SizedBox(height: 14),
        const _DetailSectionTitle('Legutóbbi előfordulások'),
        _OccurrenceList(
          occurrences: insight.recentScopeOccurrences,
          oldestFirst: false,
        ),
      ],
    );
  }
}

final class _EntityDetailScaffold extends StatelessWidget {
  const _EntityDetailScaffold({
    required this.listKey,
    required this.backKey,
    required this.onBack,
    required this.title,
    required this.children,
  });

  final Key listKey;
  final Key backKey;
  final VoidCallback onBack;
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.fromLTRB(10, 6, 10, 8),
    child: ListView(
      key: listKey,
      padding: EdgeInsets.zero,
      children: <Widget>[
        Align(
          alignment: Alignment.centerLeft,
          child: TextButton.icon(
            key: backKey,
            onPressed: onBack,
            icon: const Icon(Icons.arrow_back_rounded, size: 17),
            label: const Text('Vissza'),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: FluviVisualTokens.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: children,
          ),
        ),
      ],
    ),
  );
}

final class _DetailHero extends StatelessWidget {
  const _DetailHero({required this.amountMinor, required this.subtitle});

  final int amountMinor;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Semantics(
    label: '${DashboardPreparedFormatter.amountMinor(amountMinor)}, $subtitle',
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          DashboardPreparedFormatter.amountMinor(amountMinor),
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: FluviVisualTokens.textPrimary,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.labelMedium?.copyWith(
            color: FluviVisualTokens.textSecondary,
          ),
        ),
      ],
    ),
  );
}

final class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle(this.title);

  final String title;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style: Theme.of(context).textTheme.labelLarge?.copyWith(
      color: FluviVisualTokens.textPrimary,
      fontWeight: FontWeight.w800,
    ),
  );
}

final class _MetricLine extends StatelessWidget {
  const _MetricLine({super.key, required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(top: 4),
    child: Text(
      text,
      style: Theme.of(
        context,
      ).textTheme.labelMedium?.copyWith(color: FluviVisualTokens.textSecondary),
    ),
  );
}

final class _TemporalProfile extends StatelessWidget {
  const _TemporalProfile({required this.buckets, required this.money});

  final List<DashboardBalanceEntityTemporalBucket> buckets;
  final bool money;

  @override
  Widget build(BuildContext context) {
    if (buckets.isEmpty) {
      return const _MetricLine(text: 'Nincs külön periódusos bontás');
    }
    final extent = buckets.fold<int>(
      0,
      (max, item) => item.value > max ? item.value : max,
    );
    return Column(
      children: <Widget>[
        for (final bucket in buckets)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Row(
              children: <Widget>[
                SizedBox(
                  width: 36,
                  child: Text(
                    bucket.label,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(99),
                    child: LinearProgressIndicator(
                      minHeight: 5,
                      value: extent == 0 ? 0 : bucket.value / extent,
                      backgroundColor: FluviVisualTokens.border.withValues(
                        alpha: .45,
                      ),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        FluviVisualTokens.textPrimary.withValues(alpha: .58),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 68,
                  child: Text(
                    money
                        ? DashboardPreparedFormatter.amountMinor(bucket.value)
                        : '${bucket.value} db',
                    textAlign: TextAlign.end,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

final class _TransactionSizeDistribution extends StatelessWidget {
  const _TransactionSizeDistribution({required this.distribution});

  final DashboardBalanceTransactionSizeDistribution distribution;

  @override
  Widget build(BuildContext context) {
    const labels = <String>['0–5k', '5–10k', '10–20k', '20k+'];
    final counts = distribution.counts;
    final total = distribution.totalCount;
    return Semantics(
      label: 'Tranzakcióméret eloszlás: ${counts.join(', ')}',
      child: Column(
        children: <Widget>[
          Row(
            children: <Widget>[
              for (var index = 0; index < counts.length; index += 1)
                Expanded(
                  flex: counts[index] == 0 ? 1 : counts[index],
                  child: Container(
                    height: 12,
                    margin: EdgeInsets.only(
                      right: index == counts.length - 1 ? 0 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: index == distribution.dominantBucketIndex
                          ? FluviVisualTokens.textPrimary.withValues(alpha: .70)
                          : FluviVisualTokens.textSecondary.withValues(
                              alpha: .32,
                            ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              for (final label in labels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          if (total > 0)
            _MetricLine(
              text:
                  '${(counts[distribution.dominantBucketIndex] * 100 ~/ total)}% a domináns sávban',
            ),
        ],
      ),
    );
  }
}

final class _OccurrenceList extends StatelessWidget {
  const _OccurrenceList({
    required this.occurrences,
    required this.oldestFirst,
    this.hiddenCount = 0,
  });

  final List<DashboardBalanceEntityOccurrence> occurrences;
  final bool oldestFirst;
  final int hiddenCount;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (final occurrence in occurrences)
        _MetricLine(
          text:
              '${_formatOccurrenceDate(occurrence)} · ${_formatClock(occurrence.localTimeMinutes)} · ${DashboardPreparedFormatter.amountMinor(occurrence.amountMinor)}',
        ),
      if (hiddenCount > 0) _MetricLine(text: '+$hiddenCount további'),
    ],
  );
}

final class _CadenceStrip extends StatelessWidget {
  const _CadenceStrip({required this.occurrences});

  final List<DashboardBalanceEntityOccurrence> occurrences;

  @override
  Widget build(BuildContext context) => Wrap(
    spacing: 4,
    runSpacing: 3,
    children: <Widget>[
      for (final occurrence in occurrences)
        Chip(
          visualDensity: VisualDensity.compact,
          label: Text(
            '${_formatOccurrenceDate(occurrence)} ${_formatClock(occurrence.localTimeMinutes)}',
          ),
        ),
    ],
  );
}

String _formatBasisPoints(int basisPoints) {
  final sign = basisPoints < 0 ? '-' : '';
  final absolute = basisPoints.abs();
  return '$sign${(absolute / 100).toStringAsFixed(2).replaceAll('.', ',')}%';
}

String _formatOccurrenceDate(DashboardBalanceEntityOccurrence occurrence) {
  final date = DateTime.utc(1970).add(Duration(days: occurrence.epochDay));
  return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
}

String _formatClock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

String _formatCadence(int minutes) {
  if (minutes >= 24 * 60) {
    return '${(minutes / (24 * 60)).toStringAsFixed(1).replaceAll('.', ',')} nap';
  }
  return '$minutes perc';
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
