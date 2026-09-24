import 'package:flutter/material.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_balance_primary_projection.dart';
import '../../application/dashboard_balance_entity_insights_projection.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/domain/ledger_direction.dart';
import 'balance_closings_card.dart';
import 'balance_cashflow_stability_card.dart';
import 'balance_category_visual_badge.dart';
import 'balance_category_movers_card.dart';
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
    BalanceLinkedDetailTopic.categoryMovers => BalanceCategoryMoversCard(
      presentation: presentation.categoryMovers,
    ),
    BalanceLinkedDetailTopic.latestTransaction => _LatestTransactionsDetail(
      transactions: presentation.latestTransactions,
    ),
    BalanceLinkedDetailTopic.topCategory => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-category'),
      title: 'Top 5 kategória',
      ranks: presentation.topCategories,
      kind: _RankDetailKind.category,
      categoryInsights: presentation.categoryInsights,
    ),
    BalanceLinkedDetailTopic.topPartner => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-partner'),
      title: 'Top 5 partner',
      ranks: presentation.topPartners,
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
  categoryMovers,
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
                : Column(
                    children: <Widget>[
                      for (final transaction in transactions)
                        Expanded(
                          child: _LatestTransactionRow(
                            transaction: transaction,
                          ),
                        ),
                    ],
                  ),
          ),
        ],
      ),
    ),
  );
}

final class _LatestTransactionRow extends StatelessWidget {
  const _LatestTransactionRow({required this.transaction});

  final DashboardBalanceScopedTransaction transaction;

  @override
  Widget build(BuildContext context) {
    final signedAmount = transaction.direction == LedgerDirection.expense
        ? -transaction.amountMinor.abs()
        : transaction.amountMinor.abs();
    return Semantics(
      label:
          '${transaction.title}, ${transaction.categoryTitle}, ${_formatEpochDay(transaction.epochDay)}, ${_formatClock(transaction.localTimeMinutes)}, ${DashboardPreparedFormatter.amountMinor(signedAmount)}',
      child: Padding(
        key: ValueKey<String>('balance-linked-latest-${transaction.entryId}'),
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: <Widget>[
            BalanceCategoryVisualBadge(
              key: ValueKey<String>(
                'balance-linked-latest-avatar-${transaction.entryId}',
              ),
              semanticLabel: transaction.categoryTitle,
              categoryColorId: transaction.categoryColorId,
              categoryIconId: transaction.categoryIconId,
              size: 30,
              iconSize: 15,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    transaction.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: FluviVisualTokens.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  Text(
                    '${transaction.categoryTitle} · ${_formatEpochDay(transaction.epochDay)} · ${_formatClock(transaction.localTimeMinutes)}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                      color: FluviVisualTokens.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 82,
              child: Text(
                key: ValueKey<String>(
                  'balance-linked-latest-amount-${transaction.entryId}',
                ),
                DashboardPreparedFormatter.amountMinor(signedAmount),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.end,
                style: Theme.of(context).textTheme.labelMedium?.copyWith(
                  color: transaction.direction == LedgerDirection.income
                      ? FluviVisualTokens.textPrimary
                      : FluviVisualTokens.textSecondary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _RankDetailKind { category, partner }

/// The master/detail state intentionally lives only in this lower-card
/// renderer.  Its selected ID is never published to Core, Summary or Query.
final class _RankedDetail extends StatefulWidget {
  const _RankedDetail({
    super.key,
    required this.title,
    required this.ranks,
    required this.kind,
    this.categoryInsights = const <String, DashboardBalanceCategoryInsight>{},
    this.partnerInsights = const <String, DashboardBalancePartnerInsight>{},
  });

  final String title;
  final List<DashboardBalanceRankedItem> ranks;
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
    final stillRanked = widget.ranks.any((item) => item.id == selected);
    final stillExists = switch (widget.kind) {
      _RankDetailKind.category => widget.categoryInsights.containsKey(selected),
      _RankDetailKind.partner => widget.partnerInsights.containsKey(selected),
    };
    // Never render a DTO retained from a previous Summary/direction identity.
    if (!stillRanked || !stillExists) _selectedEntityId = null;
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selectedEntityId;
    if (selected != null) {
      return switch (widget.kind) {
        _RankDetailKind.category => _CategoryInsightDetail(
          insight: widget.categoryInsights[selected]!,
          visual: widget.ranks.firstWhere((item) => item.id == selected),
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
                : _RankedOverview(
                    key: ValueKey<String>(
                      'balance-linked-ranked-overview-${widget.kind.name}',
                    ),
                    ranks: widget.ranks.take(5).toList(growable: false),
                    kind: widget.kind,
                    hasCurrentInsight: (item) => switch (widget.kind) {
                      _RankDetailKind.category =>
                        widget.categoryInsights.containsKey(item.id),
                      _RankDetailKind.partner =>
                        widget.partnerInsights.containsKey(item.id),
                    },
                    onRankTap: (item) =>
                        setState(() => _selectedEntityId = item.id),
                  ),
          ),
        ],
      ),
    );
  }

  void _clearSelection() => setState(() => _selectedEntityId = null);
}

/// The approved ranked hierarchy adapted to Fluvi's bounded lower-card
/// surface. Both kinds deliberately share one master renderer: only their
/// supporting copy differs, while ranking order remains the immutable input.
final class _RankedOverview extends StatelessWidget {
  const _RankedOverview({
    super.key,
    required this.ranks,
    required this.kind,
    required this.hasCurrentInsight,
    required this.onRankTap,
  });

  final List<DashboardBalanceRankedItem> ranks;
  final _RankDetailKind kind;
  final bool Function(DashboardBalanceRankedItem item) hasCurrentInsight;
  final ValueChanged<DashboardBalanceRankedItem> onRankTap;

  @override
  Widget build(BuildContext context) {
    final leader = ranks.first;
    final followers = ranks.skip(1).toList(growable: false);
    return Column(
      key: ValueKey<String>('balance-linked-rank-list-${kind.name}'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        _RankedLeaderRow(
          item: leader,
          kind: kind,
          onTap: hasCurrentInsight(leader) ? () => onRankTap(leader) : null,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 6),
          child: Divider(
            key: ValueKey<String>('balance-ranked-divider-${kind.name}'),
            height: 1,
            thickness: 1,
            color: const Color(0xFFE5E9F2),
          ),
        ),
        for (var index = 0; index < followers.length; index += 1) ...<Widget>[
          _RankedFollowerRow(
            item: followers[index],
            rank: index + 2,
            kind: kind,
            onTap: hasCurrentInsight(followers[index])
                ? () => onRankTap(followers[index])
                : null,
          ),
          if (index < followers.length - 1) const SizedBox(height: 4),
        ],
      ],
    );
  }
}

abstract final class _RankedOverviewVisualSpec {
  static const leaderAmount = Color(0xFFFB4276);
  static const followerAmount = Color(0xFF26355A);
  static const leaderCopy = Color(0xFF1D2B50);
  static const secondaryCopy = Color(0xFF77829D);
  static const leaderHeight = 52.0;
  static const followerHeight = 28.0;
}

final class _RankedLeaderRow extends StatelessWidget {
  const _RankedLeaderRow({
    required this.item,
    required this.kind,
    required this.onTap,
  });

  final DashboardBalanceRankedItem item;
  final _RankDetailKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    const rank = 1;
    final metadata = _rankMetadata(item: item, rank: rank, kind: kind);
    final amount = DashboardPreparedFormatter.amountMinor(
      item.amountMinor.abs(),
    );
    return Semantics(
      button: onTap != null,
      label: '${item.label}, $metadata, $amount',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('balance-linked-rank-${item.id}'),
          onTap: onTap,
          child: SizedBox(
            height: _RankedOverviewVisualSpec.leaderHeight,
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: BalanceCategoryVisualBadge(
                    key: ValueKey<String>(
                      'balance-ranked-leader-avatar-${item.id}',
                    ),
                    semanticLabel: item.label,
                    categoryColorId: item.categoryColorId,
                    categoryIconId: item.categoryIconId,
                    size: 46,
                    iconSize: 24,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _RankedCopy(
                    primary: item.label,
                    secondary: metadata,
                    leader: true,
                  ),
                ),
                const SizedBox(width: 11),
                _RankedAmount(value: amount, leader: true),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

final class _RankedFollowerRow extends StatelessWidget {
  const _RankedFollowerRow({
    required this.item,
    required this.rank,
    required this.kind,
    required this.onTap,
  });

  final DashboardBalanceRankedItem item;
  final int rank;
  final _RankDetailKind kind;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = _rankMetadata(item: item, rank: rank, kind: kind);
    final amount = DashboardPreparedFormatter.amountMinor(
      item.amountMinor.abs(),
    );
    return Semantics(
      button: onTap != null,
      label: '${item.label}, $metadata, $amount',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          key: ValueKey<String>('balance-linked-rank-${item.id}'),
          onTap: onTap,
          child: SizedBox(
            height: _RankedOverviewVisualSpec.followerHeight,
            child: Row(
              children: <Widget>[
                ExcludeSemantics(child: _RankedFollowerAvatar(item: item)),
                const SizedBox(width: 9),
                Expanded(
                  child: _RankedCopy(
                    primary: item.label,
                    secondary: metadata,
                    leader: false,
                  ),
                ),
                const SizedBox(width: 8),
                _RankedAmount(value: amount, leader: false),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

String _rankMetadata({
  required DashboardBalanceRankedItem item,
  required int rank,
  required _RankDetailKind kind,
}) => switch (kind) {
  _RankDetailKind.category => '$rank. hely',
  _RankDetailKind.partner =>
    '${item.transactionCount} tranzakció · $rank. hely',
};

final class _RankedCopy extends StatelessWidget {
  const _RankedCopy({
    required this.primary,
    required this.secondary,
    required this.leader,
  });

  final String primary;
  final String secondary;
  final bool leader;

  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        primary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: leader
              ? _RankedOverviewVisualSpec.leaderCopy
              : _RankedOverviewVisualSpec.followerAmount,
          fontSize: leader ? 13 : 11.5,
          height: leader ? 1.05 : 1,
          fontWeight: FontWeight.w900,
          fontVariations: leader
              ? const <FontVariation>[FontVariation('wght', 950)]
              : null,
        ),
      ),
      SizedBox(height: leader ? 4 : 2),
      Text(
        secondary,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: _RankedOverviewVisualSpec.secondaryCopy,
          fontSize: leader ? 8 : 8.2,
          height: leader ? 1.08 : 1,
          fontWeight: leader ? FontWeight.w700 : FontWeight.w900,
        ),
      ),
    ],
  );
}

final class _RankedAmount extends StatelessWidget {
  const _RankedAmount({required this.value, required this.leader});

  final String value;
  final bool leader;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: BoxConstraints(maxWidth: leader ? 170 : 96),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        value,
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: leader
              ? _RankedOverviewVisualSpec.leaderAmount
              : _RankedOverviewVisualSpec.followerAmount,
          fontSize: leader ? 21 : 12.5,
          height: 1,
          fontWeight: FontWeight.w900,
          fontVariations: leader
              ? const <FontVariation>[FontVariation('wght', 950)]
              : null,
        ),
      ),
    ),
  );
}

/// A local circle adapter preserves the same category color/icon catalogs used
/// by the rounded-square badge without changing its other consumers.
final class _RankedFollowerAvatar extends StatelessWidget {
  const _RankedFollowerAvatar({required this.item});

  final DashboardBalanceRankedItem item;

  @override
  Widget build(BuildContext context) {
    final atlas = PreparedVectorAssetAtlas.instance;
    final visual = DecoratedBox(
      key: ValueKey<String>('balance-ranked-follower-avatar-${item.id}'),
      decoration: BoxDecoration(
        color: CategoryAvatarPaletteCatalog.tokenFor(
          CategoryAvatarColorProfileScope.profileOf(context),
          CategoryColorCatalog.handleOf(item.categoryColorId),
        ).middleColor,
        shape: BoxShape.circle,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x57FFFFFF),
            offset: Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      child: SizedBox(
        width: 26,
        height: 26,
        child: Center(
          child: atlas.isReady
              ? CategoryIconView(
                  picture: atlas.categoryIcon(
                    CategoryIconCatalog.handleOf(item.categoryIconId),
                  ),
                  size: 14,
                  color: Colors.white,
                )
              : const Icon(
                  Icons.category_rounded,
                  size: 14,
                  color: Colors.white,
                ),
        ),
      ),
    );
    return Semantics(label: item.label, child: visual);
  }
}

final class _CategoryInsightDetail extends StatelessWidget {
  const _CategoryInsightDetail({
    required this.insight,
    required this.visual,
    required this.onBack,
  });

  final DashboardBalanceCategoryInsight insight;
  final DashboardBalanceRankedItem visual;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => KeyedSubtree(
    key: const ValueKey<String>('balance-category-insight-detail'),
    child: Padding(
      padding: const EdgeInsets.fromLTRB(14, 4, 14, 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: TextButton.icon(
              key: const ValueKey<String>('balance-category-insight-back'),
              onPressed: onBack,
              style: TextButton.styleFrom(
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(vertical: 3),
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                visualDensity: VisualDensity.compact,
              ),
              icon: Icon(
                Icons.arrow_back_rounded,
                size: 18,
                color: FluviVisualTokens.appHighlightGradient.colors.first,
              ),
              label: Text(
                'Vissza',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: FluviVisualTokens.appHighlightGradient.colors.first,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
          const SizedBox(height: 1),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              BalanceCategoryVisualBadge(
                key: const ValueKey<String>('balance-category-insight-avatar'),
                semanticLabel: insight.label,
                categoryColorId: visual.categoryColorId,
                categoryIconId: visual.categoryIconId,
                size: 48,
                iconSize: 23,
                selected: true,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      insight.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: FluviVisualTokens.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    _CategoryMedianHero(
                      amountMinor: insight.roundedMedianAmountMinor,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Wrap(
            key: const ValueKey<String>('balance-category-insight-metrics'),
            spacing: 7,
            runSpacing: 4,
            children: <Widget>[
              _CategoryMetricPill(
                text: '${insight.transactionCount} tranzakció',
              ),
              _CategoryMetricPill(text: '${insight.activeDayCount} aktív nap'),
            ],
          ),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 6),
            child: Divider(height: 1),
          ),
          const _DetailSectionTitle('Tipikus tranzakcióméret'),
          const SizedBox(height: 3),
          if (insight.temporalBuckets.isEmpty &&
              insight.usesDayLowSampleFallback)
            _MetricLine(
              key: const ValueKey<String>(
                'balance-category-insight-day-fallback',
              ),
              text:
                  'Min. ${DashboardPreparedFormatter.amountMinor(insight.minimumAmountMinor)} · Medián ${DashboardPreparedFormatter.amountMinor(insight.roundedMedianAmountMinor)} · Max. ${DashboardPreparedFormatter.amountMinor(insight.maximumAmountMinor)}',
            )
          else
            _TransactionSizeDistribution(
              key: const ValueKey<String>(
                'balance-category-insight-distribution',
              ),
              distribution: insight.distribution,
            ),
        ],
      ),
    ),
  );
}

final class _CategoryMedianHero extends StatelessWidget {
  const _CategoryMedianHero({required this.amountMinor});

  final int amountMinor;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          gradient: FluviVisualTokens.appHighlightGradient,
          borderRadius: BorderRadius.circular(99),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: Text(
            'MEDIÁN',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: FluviVisualTokens.textOnAction,
              fontWeight: FontWeight.w800,
              letterSpacing: .4,
            ),
          ),
        ),
      ),
      const SizedBox(height: 1),
      Text(
        key: const ValueKey<String>('balance-category-insight-median'),
        DashboardPreparedFormatter.amountMinor(amountMinor),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: Theme.of(context).textTheme.titleLarge?.copyWith(
          color: FluviVisualTokens.textPrimary,
          fontWeight: FontWeight.w800,
        ),
      ),
    ],
  );
}

final class _CategoryMetricPill extends StatelessWidget {
  const _CategoryMetricPill({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FluviVisualTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      child: Text(
        text,
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          color: FluviVisualTokens.textSecondary,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
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
  const _TransactionSizeDistribution({super.key, required this.distribution});

  final DashboardBalanceTransactionSizeDistribution distribution;

  @override
  Widget build(BuildContext context) {
    const labels = <String>['0–5k', '5–10k', '10–20k', '20k+'];
    final counts = distribution.counts;
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
        ],
      ),
    );
  }
}

final class _OccurrenceList extends StatelessWidget {
  const _OccurrenceList({required this.occurrences, required this.oldestFirst});

  final List<DashboardBalanceEntityOccurrence> occurrences;
  final bool oldestFirst;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      for (final occurrence in occurrences)
        _MetricLine(
          text:
              '${_formatOccurrenceDate(occurrence)} · ${_formatClock(occurrence.localTimeMinutes)} · ${DashboardPreparedFormatter.amountMinor(occurrence.amountMinor)}',
        ),
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

String _formatOccurrenceDate(DashboardBalanceEntityOccurrence occurrence) {
  return _formatEpochDay(occurrence.epochDay);
}

String _formatEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
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
