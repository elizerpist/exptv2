import 'dart:math' as math;

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
    this.rankedListExtraHeight = 0,
  }) : assert(rankedListExtraHeight >= 0);

  final DashboardBalanceLinkedPresentation presentation;
  final BalanceLinkedDetailTopic topic;
  final double rankedListExtraHeight;

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
      rankedListExtraHeight: rankedListExtraHeight,
    ),
    BalanceLinkedDetailTopic.topPartner => _RankedDetail(
      key: const ValueKey<String>('balance-linked-detail-top-partner'),
      title: 'Top 5 partner',
      ranks: presentation.topPartners,
      kind: _RankDetailKind.partner,
      partnerInsights: presentation.partnerInsights,
      rankedListExtraHeight: rankedListExtraHeight,
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
    required this.rankedListExtraHeight,
    this.categoryInsights = const <String, DashboardBalanceCategoryInsight>{},
    this.partnerInsights = const <String, DashboardBalancePartnerInsight>{},
  });

  final String title;
  final List<DashboardBalanceRankedItem> ranks;
  final _RankDetailKind kind;
  final double rankedListExtraHeight;
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
          visual: widget.ranks.firstWhere((item) => item.id == selected),
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
                    rankedListExtraHeight: widget.rankedListExtraHeight,
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
    required this.rankedListExtraHeight,
    required this.hasCurrentInsight,
    required this.onRankTap,
  });

  final List<DashboardBalanceRankedItem> ranks;
  final _RankDetailKind kind;
  final double rankedListExtraHeight;
  final bool Function(DashboardBalanceRankedItem item) hasCurrentInsight;
  final ValueChanged<DashboardBalanceRankedItem> onRankTap;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final layout = _RankedOverviewLayout.resolve(
        availableHeight: constraints.maxHeight,
        rankedListExtraHeight: rankedListExtraHeight,
      );
      final leader = ranks.first;
      final followers = ranks.skip(1).toList(growable: false);
      return Column(
        key: ValueKey<String>('balance-linked-rank-list-${kind.name}'),
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          _RankedLeaderRow(
            item: leader,
            kind: kind,
            layout: layout,
            onTap: hasCurrentInsight(leader) ? () => onRankTap(leader) : null,
          ),
          Padding(
            padding: EdgeInsets.symmetric(vertical: layout.dividerVerticalGap),
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
              layout: layout,
              onTap: hasCurrentInsight(followers[index])
                  ? () => onRankTap(followers[index])
                  : null,
            ),
            if (index < followers.length - 1)
              SizedBox(height: layout.followerGap),
          ],
        ],
      );
    },
  );
}

abstract final class _RankedOverviewVisualSpec {
  static const leaderAmount = Color(0xFFFB4276);
  static const followerAmount = Color(0xFF26355A);
  static const leaderCopy = Color(0xFF1D2B50);
  static const secondaryCopy = Color(0xFF77829D);
  static const leaderHeight = 52.0;
  static const followerHeight = 28.0;
  static const compactLeaderHeight = 44.0;
  static const compactFollowerHeight = 23.0;
  static const leaderAvatar = 46.0;
  static const compactLeaderAvatar = 40.0;
  static const followerAvatar = 26.0;
  static const compactFollowerAvatar = 22.0;
  static const followerGap = 4.0;
  static const compactFollowerGap = 1.0;
  static const dividerVerticalGap = 6.0;
  static const compactDividerVerticalGap = 2.0;
}

/// The canonical first-page ranked-list geometry for both categories and
/// partners. The lower-card host supplies only already-existing extra height;
/// this resolver never participates in outer card layout.
@immutable
final class _RankedOverviewLayout {
  const _RankedOverviewLayout._({
    required this.compact,
    required this.leaderHeight,
    required this.leaderAvatarSize,
    required this.followerRowHeight,
    required this.followerAvatarSize,
    required this.followerIconSize,
    required this.dividerVerticalGap,
    required this.followerGap,
  });

  final bool compact;
  final double leaderHeight;
  final double leaderAvatarSize;
  final double followerRowHeight;
  final double followerAvatarSize;
  final double followerIconSize;
  final double dividerVerticalGap;
  final double followerGap;

  factory _RankedOverviewLayout.resolve({
    required double availableHeight,
    required double rankedListExtraHeight,
  }) {
    // Use the height before the existing stretch to retain the approved
    // compact/noncompact baseline decision. Stretch must enrich a list, not
    // accidentally switch it to a different visual system.
    final baselineAvailableHeight = math.max(
      0.0,
      availableHeight - rankedListExtraHeight,
    );
    final compact = baselineAvailableHeight < 170;
    final leaderHeight = compact
        ? _RankedOverviewVisualSpec.compactLeaderHeight
        : _RankedOverviewVisualSpec.leaderHeight;
    final leaderAvatar = compact
        ? _RankedOverviewVisualSpec.compactLeaderAvatar
        : _RankedOverviewVisualSpec.leaderAvatar;
    final baselineFollowerHeight = compact
        ? _RankedOverviewVisualSpec.compactFollowerHeight
        : _RankedOverviewVisualSpec.followerHeight;
    final baselineFollowerAvatar = compact
        ? _RankedOverviewVisualSpec.compactFollowerAvatar
        : _RankedOverviewVisualSpec.followerAvatar;
    final baselineDividerGap = compact
        ? _RankedOverviewVisualSpec.compactDividerVerticalGap
        : _RankedOverviewVisualSpec.dividerVerticalGap;
    final baselineFollowerGap = compact
        ? _RankedOverviewVisualSpec.compactFollowerGap
        : _RankedOverviewVisualSpec.followerGap;
    final baselineContentHeight =
        leaderHeight +
        1 +
        baselineDividerGap * 2 +
        baselineFollowerHeight * 4 +
        baselineFollowerGap * 3;
    final availableStretchCapacity = math.max(
      0.0,
      availableHeight - baselineContentHeight,
    );
    // A modest share of pre-existing bottom whitespace is intentionally
    // reclaimed only in the stretched state. This makes the generous card
    // fuller without moving the accepted compact baseline.
    final reclaimedWhitespace = math.min(
      24.0,
      math.min(
        rankedListExtraHeight * .24,
        math.max(0.0, availableStretchCapacity - rankedListExtraHeight),
      ),
    );
    final stretchBudget = math.min(
      availableStretchCapacity,
      rankedListExtraHeight + reclaimedWhitespace,
    );
    // Followers grow uniformly, but the retained rank-one anchor remains
    // clearly dominant at every stretch amount.
    final followerAvatarSize = math.min(
      leaderAvatar - 5,
      baselineFollowerAvatar + stretchBudget * .12,
    );
    final followerRowHeight = math.max(
      baselineFollowerHeight,
      followerAvatarSize,
    );
    final avatarConsumed = (followerRowHeight - baselineFollowerHeight) * 4;
    final spacingExtra = math.max(0.0, stretchBudget - avatarConsumed) / 5;
    return _RankedOverviewLayout._(
      compact: compact,
      leaderHeight: leaderHeight,
      leaderAvatarSize: leaderAvatar,
      followerRowHeight: followerRowHeight,
      followerAvatarSize: followerAvatarSize,
      followerIconSize: followerAvatarSize * (compact ? 12 / 22 : 14 / 26),
      dividerVerticalGap: baselineDividerGap + spacingExtra,
      followerGap: baselineFollowerGap + spacingExtra,
    );
  }
}

final class _RankedLeaderRow extends StatelessWidget {
  const _RankedLeaderRow({
    required this.item,
    required this.kind,
    required this.layout,
    required this.onTap,
  });

  final DashboardBalanceRankedItem item;
  final _RankDetailKind kind;
  final _RankedOverviewLayout layout;
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
            height: layout.leaderHeight,
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
                    size: layout.leaderAvatarSize,
                    iconSize:
                        layout.leaderAvatarSize *
                        (layout.compact ? .5 : 24 / 46),
                  ),
                ),
                SizedBox(width: layout.compact ? 8 : 11),
                Expanded(
                  child: _RankedCopy(
                    primary: item.label,
                    secondary: metadata,
                    leader: true,
                  ),
                ),
                SizedBox(width: layout.compact ? 8 : 11),
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
    required this.layout,
    required this.onTap,
  });

  final DashboardBalanceRankedItem item;
  final int rank;
  final _RankDetailKind kind;
  final _RankedOverviewLayout layout;
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
            height: layout.followerRowHeight,
            child: Row(
              children: <Widget>[
                ExcludeSemantics(
                  child: _RankedFollowerAvatar(
                    item: item,
                    size: layout.followerAvatarSize,
                    iconSize: layout.followerIconSize,
                  ),
                ),
                SizedBox(width: layout.compact ? 7 : 9),
                Expanded(
                  child: _RankedCopy(
                    primary: item.label,
                    secondary: metadata,
                    leader: false,
                  ),
                ),
                SizedBox(width: layout.compact ? 6 : 8),
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
  _RankDetailKind.partner => '$rank. hely',
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
  const _RankedFollowerAvatar({
    required this.item,
    required this.size,
    required this.iconSize,
  });

  final DashboardBalanceRankedItem item;
  final double size;
  final double iconSize;

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
        width: size,
        height: size,
        child: Center(
          child: atlas.isReady
              ? CategoryIconView(
                  picture: atlas.categoryIcon(
                    CategoryIconCatalog.handleOf(item.categoryIconId),
                  ),
                  size: iconSize,
                  color: Colors.white,
                )
              : Icon(
                  Icons.category_rounded,
                  size: iconSize,
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
  Widget build(BuildContext context) => _RankedEntityDetailTemplate(
    entityKey: 'category',
    label: insight.label,
    visual: visual,
    medianAmountMinor: insight.roundedMedianAmountMinor,
    transactionCount: insight.transactionCount,
    activeDayCount: insight.activeDayCount,
    onBack: onBack,
    lowerSectionTitle: 'Tipikus tranzakcióméret',
    lowerContentBuilder: (context, compact, accentColor) =>
        insight.temporalBuckets.isEmpty && insight.usesDayLowSampleFallback
        ? Align(
            alignment: Alignment.topLeft,
            child: _MetricLine(
              key: const ValueKey<String>(
                'balance-category-insight-day-fallback',
              ),
              text:
                  'Min. ${DashboardPreparedFormatter.amountMinor(insight.minimumAmountMinor)} · Medián ${DashboardPreparedFormatter.amountMinor(insight.roundedMedianAmountMinor)} · Max. ${DashboardPreparedFormatter.amountMinor(insight.maximumAmountMinor)}',
            ),
          )
        : _TransactionSizeDistribution(
            distribution: insight.distribution,
            accentColor: accentColor,
          ),
  );
}

typedef _RankedEntityLowerContentBuilder =
    Widget Function(BuildContext context, bool compact, Color accentColor);

/// The sole page-two layout system for both Balance rank concepts. Category
/// and partner values differ, but their local-detail hierarchy and bounds do
/// not: a change here cannot make either topic drift into a second detail UI.
final class _RankedEntityDetailTemplate extends StatelessWidget {
  const _RankedEntityDetailTemplate({
    required this.entityKey,
    required this.label,
    required this.visual,
    required this.medianAmountMinor,
    required this.transactionCount,
    required this.activeDayCount,
    required this.onBack,
    required this.lowerSectionTitle,
    required this.lowerContentBuilder,
  });

  final String entityKey;
  final String label;
  final DashboardBalanceRankedItem visual;
  final int medianAmountMinor;
  final int transactionCount;
  final int activeDayCount;
  final VoidCallback onBack;
  final String lowerSectionTitle;
  final _RankedEntityLowerContentBuilder lowerContentBuilder;

  String _key(String suffix) => 'balance-$entityKey-insight-$suffix';

  @override
  Widget build(BuildContext context) {
    final accentColor = _categoryAccentColor(context, visual.categoryColorId);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight <= 230;
        return KeyedSubtree(
          key: ValueKey<String>(_key('detail')),
          child: Padding(
            padding: EdgeInsets.fromLTRB(14, 12, 14, compact ? 2 : 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  key: ValueKey<String>(_key('return-row')),
                  height: _RankedDetailPageVisualSpec.titleRowHeight,
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      key: ValueKey<String>(_key('back')),
                      onPressed: onBack,
                      style: TextButton.styleFrom(
                        minimumSize: Size.zero,
                        padding: EdgeInsets.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        visualDensity: VisualDensity.compact,
                      ),
                      icon: Icon(
                        Icons.arrow_back_rounded,
                        size: 18,
                        color: accentColor,
                      ),
                      label: Text(
                        'Vissza',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: accentColor,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(
                  height: _RankedDetailPageVisualSpec.titleToHeroGap,
                ),
                SizedBox(
                  key: ValueKey<String>(_key('hero-row')),
                  height: _RankedOverviewVisualSpec.leaderHeight,
                  child: Row(
                    children: <Widget>[
                      BalanceCategoryVisualBadge(
                        key: ValueKey<String>(_key('avatar')),
                        semanticLabel: label,
                        categoryColorId: visual.categoryColorId,
                        categoryIconId: visual.categoryIconId,
                        size: 46,
                        iconSize: 24,
                        selected: true,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleSmall
                                  ?.copyWith(
                                    color: FluviVisualTokens.textPrimary,
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            _EntityMedianPill(
                              pillKey: ValueKey<String>(_key('median-pill')),
                              color: accentColor,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _EntityMedianAmount(
                        textKey: ValueKey<String>(_key('median')),
                        amountMinor: medianAmountMinor,
                        color: accentColor,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: compact ? 3 : 6),
                Wrap(
                  key: ValueKey<String>(_key('metrics')),
                  spacing: 7,
                  runSpacing: 4,
                  children: <Widget>[
                    _EntityMetricPill(
                      text: '$transactionCount tranzakció',
                      compact: compact,
                    ),
                    _EntityMetricPill(
                      text: '$activeDayCount aktív nap',
                      compact: compact,
                    ),
                  ],
                ),
                Padding(
                  padding: EdgeInsets.symmetric(vertical: compact ? 3 : 8),
                  child: const Divider(height: 1),
                ),
                _DetailSectionTitle(lowerSectionTitle, compact: compact),
                SizedBox(height: compact ? 2 : 4),
                Expanded(
                  child: KeyedSubtree(
                    key: ValueKey<String>(_key('distribution')),
                    child: lowerContentBuilder(context, compact, accentColor),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

abstract final class _RankedDetailPageVisualSpec {
  static const titleRowHeight = 20.0;
  static const titleToHeroGap = 8.0;
}

Color _categoryAccentColor(BuildContext context, String categoryColorId) =>
    CategoryAvatarPaletteCatalog.tokenFor(
      CategoryAvatarColorProfileScope.profileOf(context),
      CategoryColorCatalog.handleOf(categoryColorId),
    ).middleColor;

final class _EntityMedianAmount extends StatelessWidget {
  const _EntityMedianAmount({
    required this.textKey,
    required this.amountMinor,
    required this.color,
  });

  final Key textKey;
  final int amountMinor;
  final Color color;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
    constraints: const BoxConstraints(maxWidth: 170),
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerRight,
      child: Text(
        key: textKey,
        DashboardPreparedFormatter.amountMinor(amountMinor),
        maxLines: 1,
        softWrap: false,
        textAlign: TextAlign.end,
        style: TextStyle(
          color: color,
          fontSize: 21,
          height: 1,
          fontWeight: FontWeight.w900,
          fontVariations: const <FontVariation>[FontVariation('wght', 950)],
        ),
      ),
    ),
  );
}

final class _EntityMedianPill extends StatelessWidget {
  const _EntityMedianPill({required this.pillKey, required this.color});

  final Key pillKey;
  final Color color;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    key: pillKey,
    decoration: BoxDecoration(
      color: color,
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
  );
}

final class _EntityMetricPill extends StatelessWidget {
  const _EntityMetricPill({required this.text, this.compact = false});

  final String text;
  final bool compact;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FluviVisualTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(99),
    ),
    child: Padding(
      padding: EdgeInsets.symmetric(horizontal: 9, vertical: compact ? 1 : 3),
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
  const _PartnerInsightDetail({
    required this.insight,
    required this.visual,
    required this.onBack,
  });

  final DashboardBalancePartnerInsight insight;
  final DashboardBalanceRankedItem visual;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => _RankedEntityDetailTemplate(
    entityKey: 'partner',
    label: insight.label,
    visual: visual,
    medianAmountMinor: insight.relationship.roundedMedianAmountMinor,
    transactionCount: insight.transactionCount,
    activeDayCount: insight.activeDayCount,
    onBack: onBack,
    lowerSectionTitle: 'Tipikus tranzakciósáv',
    lowerContentBuilder: (context, compact, accentColor) =>
        _PartnerTransactionRangeDistribution(
          relationship: insight.relationship,
          latestScopeOccurrence: insight.latestScopeOccurrence,
          accentColor: accentColor,
          compact: compact,
        ),
  );
}

/// Partner details do not own the category distribution counts, so they show
/// the already-projected Q1/median/Q3/latest transaction range in the exact
/// same lower template envelope. No value is re-ranked or inferred here.
final class _PartnerTransactionRangeDistribution extends StatelessWidget {
  const _PartnerTransactionRangeDistribution({
    required this.relationship,
    required this.latestScopeOccurrence,
    required this.accentColor,
    required this.compact,
  });

  final DashboardBalancePartnerRelationship relationship;
  final DashboardBalanceEntityOccurrence latestScopeOccurrence;
  final Color accentColor;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final labels = <String>['Q1', 'Medián', 'Q3', 'Utolsó'];
    final values = <int>[
      relationship.firstQuartileAmountMinor,
      relationship.roundedMedianAmountMinor,
      relationship.thirdQuartileAmountMinor,
      latestScopeOccurrence.amountMinor.abs(),
    ];
    final opacities = <double>[.32, .56, .78, .62];
    return Semantics(
      label: 'Partner tipikus tranzakciósáv: ${values.join(', ')}',
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: compact
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (var index = 0; index < values.length; index += 1)
                Expanded(
                  child: Container(
                    height: compact ? 10 : 14,
                    margin: EdgeInsets.only(
                      right: index == values.length - 1 ? 0 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: accentColor.withValues(alpha: opacities[index]),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
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
          if (!compact)
            Row(
              children: <Widget>[
                for (final value in values)
                  Expanded(
                    child: Text(
                      DashboardPreparedFormatter.compactAmountMinor(value),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FluviVisualTokens.textPrimary,
                        fontWeight: FontWeight.w800,
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

final class _DetailSectionTitle extends StatelessWidget {
  const _DetailSectionTitle(this.title, {this.compact = false});

  final String title;
  final bool compact;

  @override
  Widget build(BuildContext context) => Text(
    title,
    style:
        (compact
                ? Theme.of(context).textTheme.labelMedium
                : Theme.of(context).textTheme.labelLarge)
            ?.copyWith(
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

final class _TransactionSizeDistribution extends StatelessWidget {
  const _TransactionSizeDistribution({
    required this.distribution,
    required this.accentColor,
  });

  final DashboardBalanceTransactionSizeDistribution distribution;
  final Color accentColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final compact = constraints.maxHeight < 60;
      return _buildDistribution(context, compact: compact);
    },
  );

  Widget _buildDistribution(BuildContext context, {required bool compact}) {
    const labels = <String>['0–5k', '5–10k', '10–20k', '20k+'];
    final counts = distribution.counts;
    final total = counts.fold<int>(0, (sum, count) => sum + count);
    return Semantics(
      label: 'Tranzakcióméret eloszlás: ${counts.join(', ')}',
      child: Column(
        mainAxisSize: compact ? MainAxisSize.min : MainAxisSize.max,
        mainAxisAlignment: compact
            ? MainAxisAlignment.start
            : MainAxisAlignment.spaceEvenly,
        children: <Widget>[
          Row(
            children: <Widget>[
              for (var index = 0; index < counts.length; index += 1)
                Expanded(
                  flex: counts[index] == 0 ? 1 : counts[index],
                  child: Container(
                    height: compact ? 10 : 14,
                    margin: EdgeInsets.only(
                      right: index == counts.length - 1 ? 0 : 2,
                    ),
                    decoration: BoxDecoration(
                      color: index == distribution.dominantBucketIndex
                          ? accentColor.withValues(alpha: .78)
                          : FluviVisualTokens.textSecondary.withValues(
                              alpha: .32,
                            ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
            ],
          ),
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
          if (!compact)
            Row(
              children: <Widget>[
                for (final count in counts)
                  Expanded(
                    child: Text(
                      total == 0 ? '0%' : '${(count * 100 / total).round()}%',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: FluviVisualTokens.textPrimary,
                        fontWeight: FontWeight.w800,
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

String _formatEpochDay(int epochDay) {
  final date = DateTime.utc(1970).add(Duration(days: epochDay));
  return '${date.year}. ${date.month.toString().padLeft(2, '0')}. ${date.day.toString().padLeft(2, '0')}.';
}

String _formatClock(int minutes) =>
    '${(minutes ~/ 60).toString().padLeft(2, '0')}:${(minutes % 60).toString().padLeft(2, '0')}';

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
