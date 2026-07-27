import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../state/balance_frame.dart';
import 'spendee_balance_b3ma3_manifest.dart';
import 'spendee_balance_card_painters.dart';
import 'spendee_balance_ticking_carousel.dart';
import 'spendee_balance_visual_spec.dart';

export 'spendee_balance_card_painters.dart'
    show SpendeeBalanceDailyChartPainter;

typedef SpendeeBalanceGhostChanged =
    void Function(String cardId, bool includeGhostTransactions);

const _traditionalFocusOutlineColor = Color(0x6B7D8798);

enum SpendeeBalanceFastInfoKind {
  noSpend,
  categoryChange,
  latestTransaction,
  trendComparison,
  upcomingRecurring,
}

enum SpendeeBalanceTrendDirection { up, down, flat }

@immutable
sealed class SpendeeBalanceFastInfoCardModel {
  const SpendeeBalanceFastInfoCardModel({
    required this.id,
    required this.title,
    required this.kind,
    required this.includeGhostTransactions,
  });

  final String id;
  final String title;
  final SpendeeBalanceFastInfoKind kind;
  final bool includeGhostTransactions;
}

@immutable
final class SpendeeBalanceNoSpendCardModel
    extends SpendeeBalanceFastInfoCardModel {
  const SpendeeBalanceNoSpendCardModel({
    required super.id,
    required super.title,
    required this.value,
    required this.secondary,
    this.dimension = SpendeeBalanceNoSpendDimension.week,
    this.dimensionLabel = 'Heti',
    required super.includeGhostTransactions,
  }) : super(kind: SpendeeBalanceFastInfoKind.noSpend);

  final String value;
  final String secondary;
  final SpendeeBalanceNoSpendDimension dimension;
  final String dimensionLabel;
}

@immutable
final class SpendeeBalanceCategoryChangeCardModel
    extends SpendeeBalanceFastInfoCardModel {
  const SpendeeBalanceCategoryChangeCardModel({
    required super.id,
    required super.title,
    required this.value,
    required this.category,
    required this.secondary,
    required this.iconAsset,
    required super.includeGhostTransactions,
  }) : super(kind: SpendeeBalanceFastInfoKind.categoryChange);

  final String value;
  final String category;
  final String secondary;
  final String iconAsset;
}

@immutable
final class SpendeeBalanceLatestTransactionCardModel
    extends SpendeeBalanceFastInfoCardModel {
  const SpendeeBalanceLatestTransactionCardModel({
    required super.id,
    required super.title,
    required this.amount,
    required this.merchantAndTime,
    required this.iconAsset,
    required super.includeGhostTransactions,
  }) : super(kind: SpendeeBalanceFastInfoKind.latestTransaction);

  final String amount;
  final String merchantAndTime;
  final String iconAsset;
}

@immutable
final class SpendeeBalanceTrendComparisonCardModel
    extends SpendeeBalanceFastInfoCardModel {
  const SpendeeBalanceTrendComparisonCardModel({
    required super.id,
    required super.title,
    required this.percentage,
    required this.secondary,
    required this.direction,
    required this.iconAsset,
    required super.includeGhostTransactions,
  }) : super(kind: SpendeeBalanceFastInfoKind.trendComparison);

  final String percentage;
  final String secondary;
  final SpendeeBalanceTrendDirection direction;
  final String iconAsset;
}

@immutable
final class SpendeeBalanceUpcomingRecurringCardModel
    extends SpendeeBalanceFastInfoCardModel {
  const SpendeeBalanceUpcomingRecurringCardModel({
    required super.id,
    required super.title,
    required this.name,
    required this.amount,
    required this.dueText,
    required this.categoryIconAsset,
    required this.categoryColor,
    required super.includeGhostTransactions,
  }) : super(kind: SpendeeBalanceFastInfoKind.upcomingRecurring);

  final String name;
  final String amount;
  final String dueText;
  final String categoryIconAsset;
  final Color categoryColor;
}

/// The compact B3M-A3 belt. Its page extent is one third of the authored
/// 380px content width plus the final 6px inter-card gap, so three complete
/// cards are visible with no pagination indicator.
class SpendeeBalanceFastInfoBelt extends StatelessWidget {
  const SpendeeBalanceFastInfoBelt({
    super.key,
    required this.cards,
    required this.onGhostChanged,
    this.onNoSpendCycle,
    this.initialIndex = 0,
    this.onIndexChanged,
  }) : assert(cards.length == 5),
       assert(initialIndex >= 0 && initialIndex < 5);

  final List<SpendeeBalanceFastInfoCardModel> cards;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final VoidCallback? onNoSpendCycle;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;

  static double cardWidthFor(double beltWidth) {
    return (beltWidth - 2 * SpendeeBalanceVisualSpec.insightGap) / 3;
  }

  static double viewportFractionFor(double beltWidth) {
    return (cardWidthFor(beltWidth) + SpendeeBalanceVisualSpec.insightGap) /
        beltWidth;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('spendee-balance-fast-info-belt'),
      height: SpendeeBalanceVisualSpec.insightHeight,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth.isFinite
              ? constraints.maxWidth
              : SpendeeBalanceVisualSpec.contentWidth;
          return _FastInfoPager(
            key: ValueKey(width),
            width: width,
            cards: cards,
            initialIndex: initialIndex,
            onIndexChanged: onIndexChanged,
            onGhostChanged: onGhostChanged,
            onNoSpendCycle: onNoSpendCycle,
          );
        },
      ),
    );
  }
}

class _FastInfoPager extends StatefulWidget {
  const _FastInfoPager({
    super.key,
    required this.width,
    required this.cards,
    required this.initialIndex,
    required this.onIndexChanged,
    required this.onGhostChanged,
    required this.onNoSpendCycle,
  });

  final double width;
  final List<SpendeeBalanceFastInfoCardModel> cards;
  final int initialIndex;
  final ValueChanged<int>? onIndexChanged;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final VoidCallback? onNoSpendCycle;

  @override
  State<_FastInfoPager> createState() => _FastInfoPagerState();
}

class _FastInfoPagerState extends State<_FastInfoPager> {
  @override
  Widget build(BuildContext context) {
    final cardWidth = SpendeeBalanceFastInfoBelt.cardWidthFor(widget.width);
    final slotDistance = cardWidth + SpendeeBalanceVisualSpec.insightGap;
    return SpendeeBalanceTickingViewport(
      key: const ValueKey('spendee-balance-fast-info-ticking-viewport'),
      width: widget.width,
      height: SpendeeBalanceVisualSpec.insightHeight,
      itemCount: widget.cards.length,
      slotDistance: slotDistance,
      centerAnchor: cardWidth / 2,
      initialIndex: widget.initialIndex,
      onIndexChanged: widget.onIndexChanged,
      semanticLabel: 'Balance gyorsinformációk',
      clipToViewport: true,
      itemSizeBuilder: (_, _) =>
          Size(cardWidth, SpendeeBalanceVisualSpec.insightHeight),
      itemBuilder: (context, index, selected, select) {
        return GestureDetector(
          key: ValueKey('spendee-balance-fast-info-page-$index'),
          behavior: HitTestBehavior.opaque,
          onTap: select,
          child: SpendeeBalanceFastInfoCard(
            model: widget.cards[index],
            onGhostChanged: widget.onGhostChanged,
            onNoSpendCycle: widget.onNoSpendCycle,
          ),
        );
      },
    );
  }
}

class SpendeeBalanceFastInfoCard extends StatelessWidget {
  const SpendeeBalanceFastInfoCard({
    super.key,
    required this.model,
    required this.onGhostChanged,
    this.onNoSpendCycle,
  });

  final SpendeeBalanceFastInfoCardModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final VoidCallback? onNoSpendCycle;

  @override
  Widget build(BuildContext context) {
    final style = SpendeeBalanceFastInfoVisualStyle.resolve(model.kind, model);
    final decoration = _fastInfoDecoration(style);
    final surface = SizedBox(
      height: SpendeeBalanceVisualSpec.insightHeight,
      child: DecoratedBox(
        key: ValueKey('spendee-balance-fast-info-surface-${model.kind.name}'),
        decoration: decoration,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(
            SpendeeBalanceB3mA3Manifest.fastInfoCardRadius,
          ),
          child: Stack(
            clipBehavior: Clip.hardEdge,
            children: [
              Positioned.fill(
                child: Padding(
                  padding: _FastInfoLayout.padding,
                  child: switch (model) {
                    final SpendeeBalanceNoSpendCardModel value =>
                      _NoSpendFastInfo(model: value, style: style),
                    final SpendeeBalanceCategoryChangeCardModel value =>
                      _CategoryChangeFastInfo(model: value, style: style),
                    final SpendeeBalanceLatestTransactionCardModel value =>
                      _LatestTransactionFastInfo(model: value, style: style),
                    final SpendeeBalanceTrendComparisonCardModel value =>
                      _TrendComparisonFastInfo(model: value, style: style),
                    final SpendeeBalanceUpcomingRecurringCardModel value =>
                      _UpcomingRecurringFastInfo(model: value, style: style),
                  },
                ),
              ),
              if (model case final SpendeeBalanceNoSpendCardModel noSpend)
                Positioned(
                  left: 9,
                  right: 9,
                  bottom:
                      _FastInfoLayout.ghostBottom +
                      _FastInfoLayout.ghostSize +
                      2,
                  child: Text(
                    noSpend.dimensionLabel,
                    key: const ValueKey('spendee-balance-no-spend-view-label'),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Color(0xFF7A86A3),
                      fontSize: 6.5,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              Positioned(
                right: _FastInfoLayout.ghostRight,
                bottom: _FastInfoLayout.ghostBottom,
                child: _GhostToggle(
                  key: ValueKey('spendee-balance-fast-info-ghost-${model.id}'),
                  included: model.includeGhostTransactions,
                  size: _FastInfoLayout.ghostSize,
                  radius: _FastInfoLayout.ghostSize / 2,
                  iconSize: _FastInfoLayout.ghostIconSize,
                  circular: true,
                  onTap: () =>
                      onGhostChanged(model.id, !model.includeGhostTransactions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
    if (model case final SpendeeBalanceNoSpendCardModel noSpend
        when onNoSpendCycle != null) {
      return Semantics(
        button: true,
        label:
            'No-spend napok, ${noSpend.dimensionLabel}: ${noSpend.value}. Tap a következő nézethez.',
        onTap: onNoSpendCycle,
        child: GestureDetector(
          key: const ValueKey('spendee-balance-no-spend-cycle'),
          behavior: HitTestBehavior.opaque,
          onTap: onNoSpendCycle,
          child: surface,
        ),
      );
    }
    return surface;
  }
}

class _NoSpendFastInfo extends StatelessWidget {
  const _NoSpendFastInfo({required this.model, required this.style});

  final SpendeeBalanceNoSpendCardModel model;
  final SpendeeBalanceFastInfoVisualStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('spendee-balance-fast-info-noSpend'),
      children: [
        _FastInfoHeader(
          title: model.title,
          kind: model.kind,
          iconBackground: style.iconBackground,
          icon: CustomPaint(
            key: ValueKey('spendee-balance-no-spend-moon'),
            painter: SpendeeBalanceMoonPainter(moonColor: style.iconHue),
            size: const Size.square(15),
          ),
        ),
        const SizedBox(height: _FastInfoLayout.headerBodyGap),
        Expanded(
          child: _FastInfoValueBody(
            value: model.value,
            secondary: model.secondary,
            showSecondary: false,
          ),
        ),
      ],
    );
  }
}

class _CategoryChangeFastInfo extends StatelessWidget {
  const _CategoryChangeFastInfo({required this.model, required this.style});

  final SpendeeBalanceCategoryChangeCardModel model;
  final SpendeeBalanceFastInfoVisualStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('spendee-balance-fast-info-categoryChange'),
      children: [
        _FastInfoHeader(
          title: model.title,
          kind: model.kind,
          iconBackground: style.iconBackground,
          icon: _LucideIcon(
            asset: model.iconAsset,
            color: style.iconHue,
            size: _FastInfoLayout.iconSize,
          ),
        ),
        const SizedBox(height: _FastInfoLayout.headerBodyGap),
        Expanded(
          child: _FastInfoValueBody(
            value: model.value,
            secondary: model.secondary,
            valueColor: style.iconHue,
            valueSize: _FastInfoLayout.valueSize,
            valueKey: const ValueKey('spendee-balance-category-change-value'),
          ),
        ),
      ],
    );
  }
}

class _LatestTransactionFastInfo extends StatelessWidget {
  const _LatestTransactionFastInfo({required this.model, required this.style});

  final SpendeeBalanceLatestTransactionCardModel model;
  final SpendeeBalanceFastInfoVisualStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('spendee-balance-fast-info-latestTransaction'),
      children: [
        _FastInfoHeader(
          title: model.title,
          kind: model.kind,
          iconBackground: style.iconBackground,
          icon: _LucideIcon(
            asset: model.iconAsset,
            color: style.iconHue,
            size: _FastInfoLayout.iconSize,
          ),
        ),
        const SizedBox(height: _FastInfoLayout.headerBodyGap),
        Expanded(
          child: _FastInfoValueBody(
            value: model.amount,
            valueColor: const Color(0xFF526FC5),
            valueSize: _FastInfoLayout.valueSize,
            valueKey: const ValueKey(
              'spendee-balance-latest-transaction-value',
            ),
            secondary: model.merchantAndTime,
          ),
        ),
      ],
    );
  }
}

class _TrendComparisonFastInfo extends StatelessWidget {
  const _TrendComparisonFastInfo({required this.model, required this.style});

  final SpendeeBalanceTrendComparisonCardModel model;
  final SpendeeBalanceFastInfoVisualStyle style;

  Color get _color => switch (model.direction) {
    SpendeeBalanceTrendDirection.up => const Color(0xFFEF4173),
    SpendeeBalanceTrendDirection.down => const Color(0xFF16A36A),
    SpendeeBalanceTrendDirection.flat => const Color(0xFF65718E),
  };

  String get _directionGlyph => switch (model.direction) {
    SpendeeBalanceTrendDirection.up => '↑',
    SpendeeBalanceTrendDirection.down => '↓',
    SpendeeBalanceTrendDirection.flat => '→',
  };

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('spendee-balance-fast-info-trendComparison'),
      children: [
        _FastInfoHeader(
          title: model.title,
          kind: model.kind,
          iconBackground: style.iconBackground,
          icon: _LucideIcon(
            asset: model.iconAsset,
            color: style.iconHue,
            size: _FastInfoLayout.iconSize,
          ),
        ),
        const SizedBox(height: _FastInfoLayout.headerBodyGap),
        Expanded(
          child: _FastInfoValueBody(
            value: model.percentage,
            valueColor: _color,
            valueSize: _FastInfoLayout.trendValueSize,
            valueLineHeight: 1,
            valueKey: const ValueKey('spendee-balance-trend-comparison-value'),
            showSecondary: false,
            leading: Text(
              _directionGlyph,
              style: TextStyle(
                color: _color,
                fontSize: _FastInfoLayout.trendGlyphSize,
                height: 1,
                fontWeight: FontWeight.w900,
                fontVariations: SpendeeBalanceVisualSpec.weight950,
              ),
            ),
            secondary: model.secondary,
          ),
        ),
      ],
    );
  }
}

class _UpcomingRecurringFastInfo extends StatelessWidget {
  const _UpcomingRecurringFastInfo({required this.model, required this.style});

  final SpendeeBalanceUpcomingRecurringCardModel model;
  final SpendeeBalanceFastInfoVisualStyle style;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('spendee-balance-fast-info-upcomingRecurring'),
      children: [
        _FastInfoHeader(
          title: model.title,
          kind: model.kind,
          iconBackground: style.iconBackground,
          icon: Text(
            '↻',
            key: ValueKey('spendee-balance-upcoming-recurring-glyph'),
            style: TextStyle(
              color: style.iconHue,
              fontSize: 17,
              height: 1,
              fontWeight: FontWeight.w900,
              fontVariations: SpendeeBalanceVisualSpec.weight950,
            ),
          ),
        ),
        const SizedBox(height: _FastInfoLayout.headerBodyGap),
        Expanded(
          child: _FastInfoValueBody(
            value: model.name,
            secondary: '${model.amount} · ${model.dueText}',
          ),
        ),
      ],
    );
  }
}

class _FastInfoHeader extends StatelessWidget {
  const _FastInfoHeader({
    required this.title,
    required this.kind,
    required this.icon,
    this.iconBackground = const Color(0xFFF0EFFF),
  });

  final String title;
  final SpendeeBalanceFastInfoKind kind;
  final Widget icon;
  final Color iconBackground;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _FastInfoLayout.headerSize,
      child: Row(
        children: [
          Container(
            key: ValueKey('spendee-balance-fast-info-header-disc-${kind.name}'),
            width: _FastInfoLayout.headerSize,
            height: _FastInfoLayout.headerSize,
            decoration: BoxDecoration(
              color: iconBackground,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: icon,
          ),
          const SizedBox(width: _FastInfoLayout.headerGap),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                color: Color(0xFF1B294D),
                fontSize: SpendeeBalanceB3mA3Manifest.fastInfoTitleSize,
                height: SpendeeBalanceB3mA3Manifest.fastInfoTitleLineHeight,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FastInfoValueBody extends StatelessWidget {
  const _FastInfoValueBody({
    required this.value,
    required this.secondary,
    this.valueColor = const Color(0xFF19274C),
    this.leading,
    this.valueSize = _FastInfoLayout.valueSize,
    this.valueLineHeight = _FastInfoLayout.valueLineHeight,
    this.valueKey,
    this.showSecondary = true,
  });

  final String value;
  final String secondary;
  final Color valueColor;
  final Widget? leading;
  final double valueSize;
  final double valueLineHeight;
  final Key? valueKey;
  final bool showSecondary;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (showSecondary)
          SizedBox(
            height: SpendeeBalanceB3mA3Manifest.fastInfoBodyValueRowHeight,
            child: Center(
              child: _FastInfoValue(
                key: valueKey,
                value: value,
                valueColor: valueColor,
                valueSize: valueSize,
                valueLineHeight: valueLineHeight,
                leading: leading,
              ),
            ),
          ),
        if (showSecondary)
          Expanded(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: Text(
                secondary,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF65718E),
                  fontSize: _FastInfoLayout.metaSize,
                  height: _FastInfoLayout.metaLineHeight,
                  fontWeight: FontWeight.w700,
                  fontVariations: SpendeeBalanceVisualSpec.weight750,
                ),
              ),
            ),
          ),
        if (!showSecondary)
          Expanded(
            child: Center(
              child: _FastInfoValue(
                key: valueKey,
                value: value,
                valueColor: valueColor,
                valueSize: valueSize,
                valueLineHeight: valueLineHeight,
                leading: leading,
              ),
            ),
          ),
      ],
    );
  }
}

class _FastInfoValue extends StatelessWidget {
  const _FastInfoValue({
    super.key,
    required this.value,
    required this.valueColor,
    required this.valueSize,
    required this.valueLineHeight,
    required this.leading,
  });

  final String value;
  final Color valueColor;
  final double valueSize;
  final double valueLineHeight;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leading case final leading?) ...[leading, const SizedBox(width: 4)],
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: valueColor,
              fontSize: valueSize,
              height: valueLineHeight,
              fontWeight: FontWeight.w900,
              fontVariations: SpendeeBalanceVisualSpec.weight950,
            ),
          ),
        ),
      ],
    );
  }
}

abstract final class _FastInfoLayout {
  static const padding = SpendeeBalanceB3mA3Manifest.fastInfoPadding;
  static const headerSize = SpendeeBalanceB3mA3Manifest.fastInfoHeaderSize;
  static const headerGap = SpendeeBalanceB3mA3Manifest.fastInfoHeaderGap;
  static const headerBodyGap = 3.0;
  static const iconSize = SpendeeBalanceB3mA3Manifest.fastInfoIconSize;
  static const valueSize = SpendeeBalanceB3mA3Manifest.fastInfoValueSize;
  static const valueLineHeight =
      SpendeeBalanceB3mA3Manifest.fastInfoValueLineHeight;
  static const metaSize = SpendeeBalanceB3mA3Manifest.fastInfoMetaSize;
  static const metaLineHeight = 1.1;
  static const trendValueSize =
      SpendeeBalanceB3mA3Manifest.fastInfoTrendValueSize;
  static const trendGlyphSize =
      SpendeeBalanceB3mA3Manifest.fastInfoTrendGlyphSize;
  static const ghostSize = SpendeeBalanceB3mA3Manifest.fastInfoGhostSize;
  static const ghostIconSize =
      SpendeeBalanceB3mA3Manifest.fastInfoGhostIconSize;
  static const ghostRight = SpendeeBalanceB3mA3Manifest.fastInfoGhostRight;
  static const ghostBottom = SpendeeBalanceB3mA3Manifest.fastInfoGhostBottom;
}

@immutable
class SpendeeBalanceFastInfoVisualStyle {
  const SpendeeBalanceFastInfoVisualStyle({
    required this.iconHue,
    required this.iconBackground,
    required this.inset,
    this.gradient,
  });

  final Color iconHue;
  final Color iconBackground;
  final Color inset;
  final Gradient? gradient;

  Color get edge => iconHue.withValues(alpha: 0x30 / 0xFF);
  Color get glow => iconHue.withValues(alpha: 0x1F / 0xFF);

  static SpendeeBalanceFastInfoVisualStyle resolve(
    SpendeeBalanceFastInfoKind kind,
    SpendeeBalanceFastInfoCardModel model,
  ) {
    return switch (kind) {
      SpendeeBalanceFastInfoKind.categoryChange =>
        const SpendeeBalanceFastInfoVisualStyle(
          iconHue: Color(0xFFEF4173),
          iconBackground: Color(0xFFFFF0F4),
          inset: Color(0xF5FFFFFF),
        ),
      SpendeeBalanceFastInfoKind.latestTransaction =>
        const SpendeeBalanceFastInfoVisualStyle(
          iconHue: Color(0xFF5277D3),
          iconBackground: Color(0xFFEDF3FF),
          inset: Color(0xF5FFFFFF),
        ),
      SpendeeBalanceFastInfoKind.trendComparison =>
        const SpendeeBalanceFastInfoVisualStyle(
          iconHue: Color(0xFF7657D9),
          iconBackground: Color(0xFFEEEAFF),
          inset: Color(0xF5FFFFFF),
          gradient: CssLinearGradient(
            cssDegrees: 145,
            colors: [Color(0xFFFAF8F6), Color(0xFFFFFFFF)],
          ),
        ),
      SpendeeBalanceFastInfoKind.upcomingRecurring =>
        const SpendeeBalanceFastInfoVisualStyle(
          iconHue: Color(0xFF8B5CF6),
          iconBackground: Color(0xFFF0EFFF),
          inset: Color(0xF5FFFFFF),
          gradient: CssLinearGradient(
            cssDegrees: 145,
            colors: [Color(0xFFFAF9F7), Color(0xFFFFFFFF)],
          ),
        ),
      SpendeeBalanceFastInfoKind.noSpend =>
        const SpendeeBalanceFastInfoVisualStyle(
          iconHue: Color(0xFF5F55EC),
          iconBackground: Color(0xFFF0EFFF),
          inset: Color(0xF5FFFFFF),
        ),
    };
  }
}

BoxDecoration _fastInfoDecoration(SpendeeBalanceFastInfoVisualStyle style) {
  return BoxDecoration(
    color: style.gradient == null ? const Color(0xFFFEFEFF) : null,
    gradient: style.gradient,
    border: Border.all(color: style.edge),
    borderRadius: BorderRadius.circular(26),
    boxShadow: [
      BoxShadow(color: style.glow, offset: const Offset(0, 12), blurRadius: 25),
      BoxShadow(
        color: style.inset,
        offset: const Offset(0, 1),
        blurStyle: BlurStyle.inner,
      ),
    ],
  );
}

enum SpendeeBalanceBudgetDimension { day, week, month }

extension SpendeeBalanceBudgetDimensionLabel on SpendeeBalanceBudgetDimension {
  String get label => switch (this) {
    SpendeeBalanceBudgetDimension.day => 'Napi',
    SpendeeBalanceBudgetDimension.week => 'Heti',
    SpendeeBalanceBudgetDimension.month => 'Havi',
  };
}

enum SpendeeBalanceMerchantDimension { year, month, all }

extension SpendeeBalanceMerchantDimensionLabel
    on SpendeeBalanceMerchantDimension {
  String get label => switch (this) {
    SpendeeBalanceMerchantDimension.year => 'Éves',
    SpendeeBalanceMerchantDimension.month => 'Havi',
    SpendeeBalanceMerchantDimension.all => 'Összes',
  };
}

extension SpendeeBalanceRankDimensionLabel on SpendeeBalanceRankDimension {
  String get label => switch (this) {
    SpendeeBalanceRankDimension.month => 'Havi',
    SpendeeBalanceRankDimension.year => 'Éves',
    SpendeeBalanceRankDimension.all => 'Össz.',
  };
}

extension SpendeeBalanceAverageDimensionLabel
    on SpendeeBalanceAverageDimension {
  String get label => switch (this) {
    SpendeeBalanceAverageDimension.day => 'Napi',
    SpendeeBalanceAverageDimension.week => 'Heti',
    SpendeeBalanceAverageDimension.month => 'Havi',
    SpendeeBalanceAverageDimension.year => 'Éves',
  };
}

extension SpendeeBalanceNoSpendDimensionLabel
    on SpendeeBalanceNoSpendDimension {
  String get label => switch (this) {
    SpendeeBalanceNoSpendDimension.week => 'Heti',
    SpendeeBalanceNoSpendDimension.month => 'Havi',
    SpendeeBalanceNoSpendDimension.year => 'Éves',
    SpendeeBalanceNoSpendDimension.all => 'Össz.',
  };

  String get fastInfoViewLabel => switch (this) {
    SpendeeBalanceNoSpendDimension.week => '7 napos nézet',
    SpendeeBalanceNoSpendDimension.month => 'Havi nézet',
    SpendeeBalanceNoSpendDimension.year => 'Éves nézet',
    SpendeeBalanceNoSpendDimension.all => 'Összes nézet',
  };
}

@immutable
sealed class SpendeeBalanceDetailPageModel {
  const SpendeeBalanceDetailPageModel({
    required this.id,
    required this.title,
    required this.includeGhostTransactions,
  });

  final String id;
  final String title;
  final bool includeGhostTransactions;
}

@immutable
class SpendeeBalanceBudgetDimensionModel {
  const SpendeeBalanceBudgetDimensionModel({
    required this.dimension,
    required this.remainingLabel,
    required this.remaining,
    required this.spentLabel,
    required this.spent,
    required this.transactionLabel,
    required this.transactionCount,
    required this.thresholdLabel,
    required this.budgetLabel,
    required this.referenceLabel,
    required this.progress,
  }) : assert(progress >= 0 && progress <= 1);

  final SpendeeBalanceBudgetDimension dimension;
  final String remainingLabel;
  final String remaining;
  final String spentLabel;
  final String spent;
  final String transactionLabel;
  final String transactionCount;
  final String thresholdLabel;
  final String budgetLabel;
  final String referenceLabel;
  final double progress;
}

@immutable
final class SpendeeBalanceVariableBudgetModel
    extends SpendeeBalanceDetailPageModel {
  SpendeeBalanceVariableBudgetModel({
    required super.id,
    required super.title,
    required this.selectedDimension,
    required this.dimensions,
    required super.includeGhostTransactions,
  }) : assert(dimensions.length == 3),
       assert(dimensions.containsKey(selectedDimension));

  final SpendeeBalanceBudgetDimension selectedDimension;
  final Map<SpendeeBalanceBudgetDimension, SpendeeBalanceBudgetDimensionModel>
  dimensions;
}

@immutable
class SpendeeBalanceTopCategoryRowModel {
  const SpendeeBalanceTopCategoryRowModel({
    required this.scope,
    required this.category,
    required this.amount,
    required this.iconAsset,
    required this.color,
  });

  final String scope;
  final String category;
  final String amount;
  final String iconAsset;
  final Color color;
}

@immutable
final class SpendeeBalanceTopCategoriesModel
    extends SpendeeBalanceDetailPageModel {
  const SpendeeBalanceTopCategoriesModel({
    required super.id,
    required super.title,
    required this.featuredCategory,
    required this.featuredMeta,
    required this.featuredAmount,
    required this.featuredIconAsset,
    required this.rows,
    this.rankDimension,
    required super.includeGhostTransactions,
  });

  final String featuredCategory;
  final String featuredMeta;
  final String featuredAmount;
  final String featuredIconAsset;
  final List<SpendeeBalanceTopCategoryRowModel> rows;
  final SpendeeBalanceRankDimension? rankDimension;
}

@immutable
class SpendeeBalanceMerchantRowModel {
  const SpendeeBalanceMerchantRowModel({
    required this.merchant,
    required this.transactionCount,
    required this.amount,
    required this.iconAsset,
    required this.color,
  });

  final String merchant;
  final String transactionCount;
  final String amount;
  final String iconAsset;
  final Color color;
}

@immutable
final class SpendeeBalanceTopMerchantsModel
    extends SpendeeBalanceDetailPageModel {
  const SpendeeBalanceTopMerchantsModel({
    required super.id,
    required super.title,
    required this.selectedDimension,
    required this.rows,
    this.rankDimension,
    required super.includeGhostTransactions,
  });

  final SpendeeBalanceMerchantDimension selectedDimension;
  final List<SpendeeBalanceMerchantRowModel> rows;
  final SpendeeBalanceRankDimension? rankDimension;
}

@immutable
class SpendeeBalanceDailyFactModel {
  const SpendeeBalanceDailyFactModel({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

@immutable
final class SpendeeBalanceAverageDailyModel
    extends SpendeeBalanceDetailPageModel {
  const SpendeeBalanceAverageDailyModel({
    required super.id,
    required super.title,
    required this.periodLabel,
    required this.rollingTotalLabel,
    required this.averageLabel,
    required this.dailyValues,
    required this.facts,
    this.selectedDimension,
    required this.iconAsset,
    required super.includeGhostTransactions,
  });

  final String periodLabel;
  final String rollingTotalLabel;
  final String averageLabel;
  final List<double> dailyValues;
  final List<SpendeeBalanceDailyFactModel> facts;
  final SpendeeBalanceAverageDimension? selectedDimension;
  final String iconAsset;
}

class SpendeeBalanceDetailCarousel extends StatefulWidget {
  const SpendeeBalanceDetailCarousel({
    super.key,
    required this.pages,
    required this.onGhostChanged,
    required this.onBudgetDimensionChanged,
    required this.onMerchantDimensionChanged,
    this.onCategoryRankDimensionChanged,
    this.onVendorRankDimensionChanged,
    this.onAverageDimensionChanged,
    this.initialPage = 0,
    this.onPageChanged,
  }) : assert(pages.length == 4),
       assert(initialPage >= 0 && initialPage < 4);

  final List<SpendeeBalanceDetailPageModel> pages;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final ValueChanged<SpendeeBalanceBudgetDimension> onBudgetDimensionChanged;
  final ValueChanged<SpendeeBalanceMerchantDimension>
  onMerchantDimensionChanged;
  final ValueChanged<SpendeeBalanceRankDimension>?
  onCategoryRankDimensionChanged;
  final ValueChanged<SpendeeBalanceRankDimension>? onVendorRankDimensionChanged;
  final ValueChanged<SpendeeBalanceAverageDimension>? onAverageDimensionChanged;
  final int initialPage;
  final ValueChanged<int>? onPageChanged;

  @override
  State<SpendeeBalanceDetailCarousel> createState() =>
      _SpendeeBalanceDetailCarouselState();
}

class _SpendeeBalanceDetailCarouselState
    extends State<SpendeeBalanceDetailCarousel> {
  late int _activePage;

  @override
  void initState() {
    super.initState();
    _activePage = widget.initialPage;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: const ValueKey('spendee-balance-detail-stage'),
      height: SpendeeBalanceVisualSpec.detailStageHeight,
      child: Column(
        children: [
          SizedBox(
            height: SpendeeBalanceVisualSpec.detailCardHeight,
            child: SpendeeBalanceTickingViewport(
              key: const ValueKey('spendee-balance-detail-ticking-viewport'),
              width: SpendeeBalanceVisualSpec.contentWidth,
              height: SpendeeBalanceVisualSpec.detailCardHeight,
              itemCount: widget.pages.length,
              slotDistance:
                  SpendeeBalanceVisualSpec.contentWidth +
                  SpendeeBalanceVisualSpec.stackGap,
              centerAnchor: SpendeeBalanceVisualSpec.contentWidth / 2,
              initialIndex: widget.initialPage,
              onIndexChanged: (logicalIndex) {
                setState(() => _activePage = logicalIndex);
                widget.onPageChanged?.call(logicalIndex);
              },
              semanticLabel: 'Balance részletkártyák',
              clipToViewport: true,
              itemSizeBuilder: (_, _) => const Size(
                SpendeeBalanceVisualSpec.contentWidth,
                SpendeeBalanceVisualSpec.detailCardHeight,
              ),
              itemBuilder: (context, index, selected, select) {
                return GestureDetector(
                  key: ValueKey('spendee-balance-detail-virtual-$index'),
                  behavior: HitTestBehavior.opaque,
                  onTap: select,
                  child: ExcludeFocus(
                    excluding: !selected,
                    child: ExcludeSemantics(
                      excluding: !selected,
                      child: SpendeeBalanceDetailPage(
                        model: widget.pages[index],
                        onGhostChanged: widget.onGhostChanged,
                        onBudgetDimensionChanged:
                            widget.onBudgetDimensionChanged,
                        onMerchantDimensionChanged:
                            widget.onMerchantDimensionChanged,
                        onCategoryRankDimensionChanged:
                            widget.onCategoryRankDimensionChanged,
                        onVendorRankDimensionChanged:
                            widget.onVendorRankDimensionChanged,
                        onAverageDimensionChanged:
                            widget.onAverageDimensionChanged,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 4),
          SizedBox(
            height: SpendeeBalanceVisualSpec.detailPaginationHeight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List<Widget>.generate(widget.pages.length * 2 - 1, (
                index,
              ) {
                if (index.isOdd) {
                  return const SizedBox(
                    width: SpendeeBalanceVisualSpec.detailPaginationGap,
                  );
                }
                final dotIndex = index ~/ 2;
                final active = dotIndex == _activePage;
                final size = active
                    ? SpendeeBalanceVisualSpec.detailDotActive
                    : SpendeeBalanceVisualSpec.detailDotInactive;
                return AnimatedContainer(
                  key: ValueKey('spendee-balance-detail-dot-$dotIndex'),
                  width: size,
                  height: size,
                  duration:
                      MediaQuery.maybeOf(context)?.disableAnimations ?? false
                      ? Duration.zero
                      : const Duration(milliseconds: 80),
                  decoration: BoxDecoration(
                    color: active
                        ? SpendeeBalanceVisualSpec.detailDotActiveColor
                        : const Color(0x57808FAB),
                    shape: BoxShape.circle,
                    boxShadow: active
                        ? const [
                            BoxShadow(
                              color: Color(0x4DE84CAE),
                              offset: Offset(0, 2),
                              blurRadius: 5,
                            ),
                          ]
                        : null,
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

class SpendeeBalanceDetailPage extends StatelessWidget {
  const SpendeeBalanceDetailPage({
    super.key,
    required this.model,
    required this.onGhostChanged,
    required this.onBudgetDimensionChanged,
    required this.onMerchantDimensionChanged,
    this.onCategoryRankDimensionChanged,
    this.onVendorRankDimensionChanged,
    this.onAverageDimensionChanged,
  });

  final SpendeeBalanceDetailPageModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final ValueChanged<SpendeeBalanceBudgetDimension> onBudgetDimensionChanged;
  final ValueChanged<SpendeeBalanceMerchantDimension>
  onMerchantDimensionChanged;
  final ValueChanged<SpendeeBalanceRankDimension>?
  onCategoryRankDimensionChanged;
  final ValueChanged<SpendeeBalanceRankDimension>? onVendorRankDimensionChanged;
  final ValueChanged<SpendeeBalanceAverageDimension>? onAverageDimensionChanged;

  @override
  Widget build(BuildContext context) {
    return switch (model) {
      final SpendeeBalanceVariableBudgetModel value => _VariableBudgetDetail(
        model: value,
        onGhostChanged: onGhostChanged,
        onDimensionChanged: onBudgetDimensionChanged,
      ),
      final SpendeeBalanceTopCategoriesModel value => _TopCategoriesDetail(
        model: value,
        onGhostChanged: onGhostChanged,
        onDimensionChanged: onCategoryRankDimensionChanged,
      ),
      final SpendeeBalanceTopMerchantsModel value => _TopMerchantsDetail(
        model: value,
        onGhostChanged: onGhostChanged,
        onDimensionChanged: onMerchantDimensionChanged,
        onRankDimensionChanged: onVendorRankDimensionChanged,
      ),
      final SpendeeBalanceAverageDailyModel value => _AverageDailyDetail(
        model: value,
        onGhostChanged: onGhostChanged,
        onDimensionChanged: onAverageDimensionChanged,
      ),
    };
  }
}

class _VariableBudgetDetail extends StatelessWidget {
  const _VariableBudgetDetail({
    required this.model,
    required this.onGhostChanged,
    required this.onDimensionChanged,
  });

  final SpendeeBalanceVariableBudgetModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final ValueChanged<SpendeeBalanceBudgetDimension> onDimensionChanged;

  @override
  Widget build(BuildContext context) {
    final selected = model.dimensions[model.selectedDimension]!;
    return _DetailCardShell(
      model: model,
      onGhostChanged: onGhostChanged,
      child: Column(
        children: [
          _DetailHeader(
            id: model.id,
            title: model.title,
            selector: _BudgetDimensionSelector(
              selected: model.selectedDimension,
              onChanged: onDimensionChanged,
            ),
          ),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                const _LucideTile(
                  key: ValueKey('spendee-balance-variable-budget-tile'),
                  size: 46,
                  radius: 14,
                  iconSize: 24,
                  iconAsset: 'assets/icons/lucide/shopping-cart.svg',
                  colors: [Color(0xFFFF4C79), Color(0xFFFB3D76)],
                  shadowColor: Color(0x3DFB3D76),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _DetailMainCopy(
                    title: selected.remainingLabel,
                    subtitle: 'Fix tételek kizárva',
                  ),
                ),
                const SizedBox(width: 11),
                _DetailAmount(selected.remaining),
              ],
            ),
          ),
          const _DetailDivider(),
          SizedBox(
            height: 47,
            child: Row(
              children: [
                Expanded(
                  child: _BudgetFact(
                    label: selected.spentLabel,
                    value: selected.spent,
                    color: const Color(0xFFFF4677),
                  ),
                ),
                const VerticalDivider(
                  width: 1,
                  thickness: 1,
                  color: Color(0xFFEDF0F6),
                ),
                Expanded(
                  child: _BudgetFact(
                    label: selected.transactionLabel,
                    value: selected.transactionCount,
                    color: const Color(0xFF19C793),
                  ),
                ),
              ],
            ),
          ),
          const _DetailDivider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(right: 25),
              child: Column(
                children: [
                  SizedBox(
                    height: 20,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Flexible(
                          child: Text(
                            selected.thresholdLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF1D2B50),
                              fontSize: 10,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              fontVariations:
                                  SpendeeBalanceVisualSpec.weight950,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          selected.budgetLabel,
                          style: const TextStyle(
                            color: Color(0xFF8791AA),
                            fontSize: 7.6,
                            height: 1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 22,
                    child: CustomPaint(
                      key: const ValueKey('spendee-balance-budget-progress'),
                      painter: SpendeeBalanceBudgetProgressPainter(
                        progress: selected.progress,
                      ),
                      size: const Size(double.infinity, 22),
                    ),
                  ),
                  Expanded(
                    child: Align(
                      alignment: Alignment.topRight,
                      child: Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          selected.referenceLabel,
                          maxLines: 1,
                          style: const TextStyle(
                            color: Color(0xFF7F8BA5),
                            fontSize: 7.6,
                            height: 1.1,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopCategoriesDetail extends StatelessWidget {
  const _TopCategoriesDetail({
    required this.model,
    required this.onGhostChanged,
    required this.onDimensionChanged,
  });

  final SpendeeBalanceTopCategoriesModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final ValueChanged<SpendeeBalanceRankDimension>? onDimensionChanged;

  @override
  Widget build(BuildContext context) {
    // The HTML card has one featured category plus exactly three following
    // rows. Keeping that bound prevents a fourth row from overflowing the
    // 208px visible carousel viewport.
    final rankedRows = model.rows.take(3).toList(growable: false);
    return _DetailCardShell(
      model: model,
      onGhostChanged: onGhostChanged,
      child: Column(
        children: [
          _DetailHeader(
            id: model.id,
            title: model.title,
            selector: switch (model.rankDimension) {
              final selected? => _RankDimensionSelector(
                keyPrefix: 'spendee-balance-top-category-dimension',
                selected: selected,
                onChanged: onDimensionChanged ?? (_) {},
              ),
              null => null,
            },
          ),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                _LucideTile(
                  size: 46,
                  radius: 14,
                  iconSize: 24,
                  iconAsset: model.featuredIconAsset,
                  colors: const [Color(0xFF31CE91), Color(0xFF1FBF86)],
                  shadowColor: const Color(0x381FBF86),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _DetailMainCopy(
                    title: model.featuredCategory,
                    subtitle: model.featuredMeta,
                  ),
                ),
                const SizedBox(width: 11),
                _DetailAmount(model.featuredAmount),
              ],
            ),
          ),
          const _DetailDivider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: rankedRows.isEmpty
                  ? const SizedBox.shrink()
                  : Column(
                      children: List<Widget>.generate(
                        rankedRows.length * 2 - 1,
                        (index) {
                          if (index.isOdd) {
                            return const SizedBox(height: 4);
                          }
                          final rowIndex = index ~/ 2;
                          return SizedBox(
                            height: 28,
                            child: _TopCategoryRow(
                              key: ValueKey(
                                'spendee-balance-top-category-row-$rowIndex',
                              ),
                              model: rankedRows[rowIndex],
                            ),
                          );
                        },
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TopMerchantsDetail extends StatelessWidget {
  const _TopMerchantsDetail({
    required this.model,
    required this.onGhostChanged,
    required this.onDimensionChanged,
    required this.onRankDimensionChanged,
  });

  final SpendeeBalanceTopMerchantsModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final ValueChanged<SpendeeBalanceMerchantDimension> onDimensionChanged;
  final ValueChanged<SpendeeBalanceRankDimension>? onRankDimensionChanged;

  @override
  Widget build(BuildContext context) {
    final rankDimension = model.rankDimension;
    if (rankDimension != null) {
      final rankedRows = model.rows.take(4).toList(growable: false);
      final leader = rankedRows.isEmpty
          ? const SpendeeBalanceMerchantRowModel(
              merchant: 'Nincs adat',
              transactionCount: '0 tranzakció',
              amount: '0 Ft',
              iconAsset: 'assets/icons/lucide/store.svg',
              color: Color(0xFFF24CAE),
            )
          : rankedRows.first;
      final following = rankedRows.skip(1).toList(growable: false);
      return _DetailCardShell(
        model: model,
        onGhostChanged: onGhostChanged,
        child: Column(
          children: [
            _DetailHeader(
              id: model.id,
              title: 'Top 4 kereskedő',
              selector: _RankDimensionSelector(
                keyPrefix: 'spendee-balance-top-vendor-dimension',
                selected: rankDimension,
                onChanged: onRankDimensionChanged ?? (_) {},
              ),
            ),
            SizedBox(
              height: 52,
              child: Row(
                key: const ValueKey('spendee-balance-top-merchant-row-0'),
                children: [
                  _LucideTile(
                    size: 46,
                    radius: 14,
                    iconSize: 24,
                    iconAsset: leader.iconAsset,
                    colors: const [Color(0xFFF571B8), Color(0xFFF24CAE)],
                    shadowColor: const Color(0x3DF24CAE),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: _DetailMainCopy(
                      title: leader.merchant,
                      subtitle: '${leader.transactionCount} · 1. hely',
                    ),
                  ),
                  const SizedBox(width: 11),
                  _DetailAmount(leader.amount),
                ],
              ),
            ),
            const _DetailDivider(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  children: [
                    for (var index = 0; index < following.length; index++) ...[
                      SizedBox(
                        height: 28,
                        child: _TopMerchantRow(
                          key: ValueKey(
                            'spendee-balance-top-merchant-row-${index + 1}',
                          ),
                          model: following[index],
                        ),
                      ),
                      if (index < following.length - 1)
                        const SizedBox(height: 4),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }
    final rankedRows = model.rows.take(4).toList(growable: false);
    final leader = rankedRows.isEmpty
        ? const SpendeeBalanceMerchantRowModel(
            merchant: 'Nincs adat',
            transactionCount: '0 tranzakció',
            amount: '0 Ft',
            iconAsset: 'assets/icons/lucide/store.svg',
            color: Color(0xFFF24CAE),
          )
        : rankedRows.first;
    final following = rankedRows.skip(1).toList(growable: false);
    return _DetailCardShell(
      model: model,
      onGhostChanged: onGhostChanged,
      child: Column(
        children: [
          _DetailHeader(
            id: model.id,
            title: 'Top 4 kereskedő',
            selector: _MerchantDimensionSelector(
              selected: model.selectedDimension,
              onChanged: onDimensionChanged,
            ),
          ),
          SizedBox(
            height: 52,
            child: Row(
              key: const ValueKey('spendee-balance-top-merchant-row-0'),
              children: [
                _LucideTile(
                  size: 46,
                  radius: 14,
                  iconSize: 24,
                  iconAsset: leader.iconAsset,
                  colors: const [Color(0xFFF571B8), Color(0xFFF24CAE)],
                  shadowColor: const Color(0x3DF24CAE),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _DetailMainCopy(
                    title: leader.merchant,
                    subtitle: '${leader.transactionCount} · 1. hely',
                  ),
                ),
                const SizedBox(width: 11),
                _DetailAmount(leader.amount),
              ],
            ),
          ),
          const _DetailDivider(),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Column(
                children: [
                  for (var index = 0; index < following.length; index++) ...[
                    SizedBox(
                      height: 28,
                      child: _TopMerchantRow(
                        key: ValueKey(
                          'spendee-balance-top-merchant-row-${index + 1}',
                        ),
                        model: following[index],
                      ),
                    ),
                    if (index < following.length - 1) const SizedBox(height: 4),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AverageDailyDetail extends StatelessWidget {
  const _AverageDailyDetail({
    required this.model,
    required this.onGhostChanged,
    required this.onDimensionChanged,
  });

  final SpendeeBalanceAverageDailyModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final ValueChanged<SpendeeBalanceAverageDimension>? onDimensionChanged;

  @override
  Widget build(BuildContext context) {
    return _DetailCardShell(
      model: model,
      onGhostChanged: onGhostChanged,
      child: Column(
        children: [
          _DetailHeader(
            id: model.id,
            title: model.title,
            selector: switch (model.selectedDimension) {
              final selected? => _AverageDimensionSelector(
                selected: selected,
                onChanged: onDimensionChanged ?? (_) {},
              ),
              null => null,
            },
          ),
          SizedBox(
            height: 52,
            child: Row(
              children: [
                _LucideTile(
                  size: 46,
                  radius: 14,
                  iconSize: 24,
                  iconAsset: model.iconAsset,
                  colors: const [Color(0xFF9B8FFF), Color(0xFF8B7DFA)],
                  shadowColor: const Color(0x388B7DFA),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: _AverageDailyCopy(
                    title: model.periodLabel,
                    subtitle: model.rollingTotalLabel,
                  ),
                ),
                const SizedBox(width: 11),
                Flexible(
                  child: Text(
                    model.averageLabel,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Color(0xFF8B7DFA),
                      fontSize: 21,
                      height: 1,
                      fontWeight: FontWeight.w900,
                      fontVariations: SpendeeBalanceVisualSpec.weight950,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const _DetailDivider(),
          SizedBox(
            height: 72,
            child: Align(
              alignment: Alignment.topCenter,
              child: SizedBox(
                height: 64,
                child: CustomPaint(
                  key: const ValueKey('spendee-balance-average-daily-chart'),
                  painter: SpendeeBalanceDailyChartPainter(
                    dailyValues: _thirtyColumnChartValues(model.dailyValues),
                  ),
                  size: const Size(double.infinity, 64),
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, right: 25),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: List<Widget>.generate(model.facts.length * 2 - 1, (
                  index,
                ) {
                  if (index.isOdd) {
                    return const VerticalDivider(
                      width: 1,
                      thickness: 1,
                      color: Color(0xFFEDF0F6),
                    );
                  }
                  final fact = model.facts[index ~/ 2];
                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 7),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            fact.label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF7A859F),
                              fontSize: 6.5,
                              height: 1.08,
                              fontWeight: FontWeight.w800,
                              fontVariations:
                                  SpendeeBalanceVisualSpec.weight850,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            fact.value,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Color(0xFF26355A),
                              fontSize: 9,
                              height: 1.08,
                              fontWeight: FontWeight.w900,
                              fontVariations:
                                  SpendeeBalanceVisualSpec.weight950,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

List<double> _thirtyColumnChartValues(List<double> values) {
  if (values.length == 30) return values;
  final latest = values.length > 30
      ? values.sublist(values.length - 30)
      : values;
  return <double>[...List<double>.filled(30 - latest.length, 0), ...latest];
}

class _DetailHeader extends StatelessWidget {
  const _DetailHeader({required this.id, required this.title, this.selector});

  final String id;
  final String title;
  final Widget? selector;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('spendee-balance-detail-header-$id'),
      height: SpendeeBalanceB3mA3Manifest.detailTitleRowHeight,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Align(alignment: Alignment.topLeft, child: _DetailTitle(title)),
          if (selector case final selector?)
            Positioned(top: 0, right: 0, height: 26, child: selector),
        ],
      ),
    );
  }
}

class _DetailCardShell extends StatelessWidget {
  const _DetailCardShell({
    required this.model,
    required this.onGhostChanged,
    required this.child,
  });

  final SpendeeBalanceDetailPageModel model;
  final SpendeeBalanceGhostChanged onGhostChanged;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('spendee-balance-detail-page-${model.id}'),
      height: SpendeeBalanceVisualSpec.detailCardHeight,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xFFFEFEFF),
          border: Border.all(color: const Color(0x1C666FAB)),
          borderRadius: BorderRadius.circular(26),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1F534B96),
              offset: Offset(0, 15),
              blurRadius: 30,
            ),
            BoxShadow(
              color: Color(0xF5FFFFFF),
              offset: Offset(0, 1),
              blurStyle: BlurStyle.inner,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(26),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding: SpendeeBalanceB3mA3Manifest.detailPadding,
                  child: child,
                ),
              ),
              Positioned(
                right: 8,
                bottom: 7,
                child: _GhostToggle(
                  key: ValueKey('spendee-balance-detail-ghost-${model.id}'),
                  included: model.includeGhostTransactions,
                  size: 17,
                  radius: 6,
                  iconSize: 9,
                  circular: false,
                  onTap: () =>
                      onGhostChanged(model.id, !model.includeGhostTransactions),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _BudgetDimensionSelector extends StatelessWidget {
  const _BudgetDimensionSelector({
    required this.selected,
    required this.onChanged,
  });

  final SpendeeBalanceBudgetDimension selected;
  final ValueChanged<SpendeeBalanceBudgetDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DimensionRail(
      gap: 3,
      padding: 2,
      radius: 9,
      chipMinHeight: 20,
      chipHorizontalPadding: 7,
      chipRadius: 8,
      fontSize: 7.2,
      children: [
        for (final dimension in SpendeeBalanceBudgetDimension.values)
          _DimensionChip(
            key: ValueKey('spendee-balance-budget-dimension-${dimension.name}'),
            label: dimension.label,
            selected: dimension == selected,
            onTap: () => onChanged(dimension),
          ),
      ],
    );
  }
}

class _MerchantDimensionSelector extends StatelessWidget {
  const _MerchantDimensionSelector({
    required this.selected,
    required this.onChanged,
  });

  final SpendeeBalanceMerchantDimension selected;
  final ValueChanged<SpendeeBalanceMerchantDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DimensionRail(
      gap: 3,
      padding: 2,
      radius: 9,
      chipMinHeight: 20,
      chipHorizontalPadding: 7,
      chipRadius: 8,
      fontSize: 7.2,
      children: [
        for (final dimension in SpendeeBalanceMerchantDimension.values)
          _DimensionChip(
            key: ValueKey(
              'spendee-balance-merchant-dimension-${dimension.name}',
            ),
            label: dimension.label,
            selected: dimension == selected,
            onTap: () => onChanged(dimension),
          ),
      ],
    );
  }
}

class _RankDimensionSelector extends StatelessWidget {
  const _RankDimensionSelector({
    required this.keyPrefix,
    required this.selected,
    required this.onChanged,
  });

  final String keyPrefix;
  final SpendeeBalanceRankDimension selected;
  final ValueChanged<SpendeeBalanceRankDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DimensionRail(
      gap: 3,
      padding: 2,
      radius: 9,
      chipMinHeight: 20,
      chipHorizontalPadding: 7,
      chipRadius: 8,
      fontSize: 7.2,
      children: [
        for (final dimension in SpendeeBalanceRankDimension.values)
          _DimensionChip(
            key: ValueKey('$keyPrefix-${dimension.name}'),
            label: dimension.label,
            selected: dimension == selected,
            onTap: () => onChanged(dimension),
          ),
      ],
    );
  }
}

class _AverageDimensionSelector extends StatelessWidget {
  const _AverageDimensionSelector({
    required this.selected,
    required this.onChanged,
  });

  final SpendeeBalanceAverageDimension selected;
  final ValueChanged<SpendeeBalanceAverageDimension> onChanged;

  @override
  Widget build(BuildContext context) {
    return _DimensionRail(
      gap: 2,
      padding: 2,
      radius: 9,
      chipMinHeight: 20,
      chipHorizontalPadding: 5,
      chipRadius: 8,
      fontSize: 6.8,
      children: [
        for (final dimension in SpendeeBalanceAverageDimension.values)
          _DimensionChip(
            key: ValueKey(
              'spendee-balance-average-dimension-${dimension.name}',
            ),
            label: dimension.label,
            selected: dimension == selected,
            onTap: () => onChanged(dimension),
          ),
      ],
    );
  }
}

class _DimensionRail extends StatelessWidget {
  const _DimensionRail({
    required this.children,
    required this.gap,
    required this.padding,
    required this.radius,
    required this.chipMinHeight,
    required this.chipHorizontalPadding,
    required this.chipRadius,
    required this.fontSize,
  });

  final List<Widget> children;
  final double gap;
  final double padding;
  final double radius;
  final double chipMinHeight;
  final double chipHorizontalPadding;
  final double chipRadius;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: const Color(0xEBF8F9FD),
        border: Border.all(color: const Color(0xFFEDF0F6)),
        borderRadius: BorderRadius.circular(radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var index = 0; index < children.length; index++) ...[
            if (index > 0) SizedBox(width: gap),
            _DimensionChip(
              key: children[index].key,
              label: (children[index] as _DimensionChip).label,
              selected: (children[index] as _DimensionChip).selected,
              onTap: (children[index] as _DimensionChip).onTap,
              minHeight: chipMinHeight,
              horizontalPadding: chipHorizontalPadding,
              radius: chipRadius,
              fontSize: fontSize,
            ),
          ],
        ],
      ),
    );
  }
}

class _DimensionChip extends StatefulWidget {
  const _DimensionChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.minHeight = 11,
    this.horizontalPadding = 4,
    this.radius = 5,
    this.fontSize = 5.2,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double minHeight;
  final double horizontalPadding;
  final double radius;
  final double fontSize;

  @override
  State<_DimensionChip> createState() => _DimensionChipState();
}

class _DimensionChipState extends State<_DimensionChip> {
  var _showFocusOutline = false;
  var _pointerActivated = false;

  void _handlePointerDown(PointerDownEvent event) {
    if (_pointerActivated) return;
    _pointerActivated = true;
    widget.onTap();
  }

  void _handleTap() {
    if (_pointerActivated) {
      _pointerActivated = false;
      return;
    }
    widget.onTap();
  }

  void _handlePointerCancel(PointerCancelEvent event) {
    _pointerActivated = false;
  }

  void _handleFocusChange(bool focused) {
    final show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_showFocusOutline == show) return;
    setState(() => _showFocusOutline = show);
  }

  @override
  Widget build(BuildContext context) {
    final ownKey = widget.key;
    final outlineKey = ownKey is ValueKey<String>
        ? ValueKey('${ownKey.value}-focus-outline')
        : null;
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      selected: widget.selected,
      label: widget.label,
      onTap: widget.onTap,
      child: Listener(
        behavior: HitTestBehavior.opaque,
        onPointerDown: _handlePointerDown,
        onPointerCancel: _handlePointerCancel,
        child: InkWell(
          excludeFromSemantics: true,
          splashFactory: NoSplash.splashFactory,
          overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
          onFocusChange: _handleFocusChange,
          onTap: _handleTap,
          borderRadius: BorderRadius.circular(widget.radius),
          child: Stack(
            children: [
              Container(
                constraints: BoxConstraints(minHeight: widget.minHeight),
                padding: EdgeInsets.symmetric(
                  horizontal: widget.horizontalPadding,
                ),
                decoration: BoxDecoration(
                  color: widget.selected
                      ? const Color(0xFFF24CAE)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(widget.radius),
                  boxShadow: widget.selected
                      ? const [
                          BoxShadow(
                            color: Color(0x3DF24CAE),
                            offset: Offset(0, 3),
                            blurRadius: 6,
                          ),
                        ]
                      : null,
                ),
                alignment: Alignment.center,
                child: ExcludeSemantics(
                  child: Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.selected
                          ? Colors.white
                          : const Color(0xFF7D88A2),
                      fontSize: widget.fontSize,
                      height: 1,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              if (_showFocusOutline)
                Positioned.fill(
                  child: _TraditionalFocusOutline(
                    outlineKey: outlineKey,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TopCategoryRow extends StatelessWidget {
  const _TopCategoryRow({super.key, required this.model});

  final SpendeeBalanceTopCategoryRowModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundAvatar(color: model.color, iconAsset: model.iconAsset),
        const SizedBox(width: 9),
        Expanded(
          child: _RankedCopy(
            primary: model.category,
            secondary: model.scope,
            primaryFirst: false,
          ),
        ),
        Text(model.amount, style: _rankedAmountStyle),
      ],
    );
  }
}

class _TopMerchantRow extends StatelessWidget {
  const _TopMerchantRow({super.key, required this.model});

  final SpendeeBalanceMerchantRowModel model;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        _RoundAvatar(color: model.color, iconAsset: model.iconAsset),
        const SizedBox(width: 9),
        Expanded(
          child: _RankedCopy(
            primary: model.merchant,
            secondary: model.transactionCount,
            primaryFirst: false,
          ),
        ),
        Text(model.amount, style: _rankedAmountStyle),
      ],
    );
  }
}

class _RoundAvatar extends StatelessWidget {
  const _RoundAvatar({required this.color, required this.iconAsset});

  final Color color;
  final String iconAsset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 26,
      height: 26,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        boxShadow: const [
          BoxShadow(
            color: Color(0x57FFFFFF),
            offset: Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: _LucideIcon(asset: iconAsset, color: Colors.white, size: 14),
    );
  }
}

class _RankedCopy extends StatelessWidget {
  const _RankedCopy({
    required this.primary,
    required this.secondary,
    required this.primaryFirst,
  });

  final String primary;
  final String secondary;
  final bool primaryFirst;

  @override
  Widget build(BuildContext context) {
    final primaryWidget = Text(
      primary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: primaryFirst ? const Color(0xFF7D88A2) : const Color(0xFF26355A),
        fontSize: 11.5,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
    final secondaryWidget = Text(
      secondary,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: TextStyle(
        color: primaryFirst ? const Color(0xFF26355A) : const Color(0xFF7D88A2),
        fontSize: 8.2,
        height: 1,
        fontWeight: FontWeight.w900,
      ),
    );
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [primaryWidget, const SizedBox(height: 2), secondaryWidget],
    );
  }
}

class _BudgetFact extends StatelessWidget {
  const _BudgetFact({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 5,
                height: 5,
                decoration: BoxDecoration(color: color, shape: BoxShape.circle),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xFF6F7B97),
                    fontSize: 7.6,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Padding(
            padding: const EdgeInsets.only(left: 12),
            child: Text(
              value,
              maxLines: 1,
              style: const TextStyle(
                color: Color(0xFF1D2B50),
                fontSize: 11,
                height: 1,
                fontWeight: FontWeight.w900,
                fontVariations: SpendeeBalanceVisualSpec.weight950,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailTitle extends StatelessWidget {
  const _DetailTitle(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFF5E6B9D),
        fontSize: 12,
        height: 1,
        fontWeight: FontWeight.w900,
        fontVariations: SpendeeBalanceVisualSpec.weight950,
      ),
    );
  }
}

class _DetailMainCopy extends StatelessWidget {
  const _DetailMainCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1D2B50),
            fontSize: 13,
            height: 1.05,
            fontWeight: FontWeight.w900,
            fontVariations: SpendeeBalanceVisualSpec.weight950,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF77829D),
            fontSize: 8,
            height: 1.08,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _AverageDailyCopy extends StatelessWidget {
  const _AverageDailyCopy({required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF1D2B50),
            fontSize: 13,
            height: 1,
            fontWeight: FontWeight.w900,
            fontVariations: SpendeeBalanceVisualSpec.weight950,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Color(0xFF77829D),
            fontSize: 8,
            height: 1,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }
}

class _DetailAmount extends StatelessWidget {
  const _DetailAmount(this.value);

  final String value;

  @override
  Widget build(BuildContext context) {
    return Text(
      value,
      maxLines: 1,
      style: const TextStyle(
        color: Color(0xFFFB4276),
        fontSize: 21,
        height: 1,
        fontWeight: FontWeight.w900,
        fontVariations: SpendeeBalanceVisualSpec.weight950,
      ),
    );
  }
}

class _DetailDivider extends StatelessWidget {
  const _DetailDivider();

  @override
  Widget build(BuildContext context) {
    return const SizedBox(
      height: 1,
      child: ColoredBox(color: Color(0xFFE9EBF3)),
    );
  }
}

class _LucideTile extends StatelessWidget {
  const _LucideTile({
    super.key,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.iconAsset,
    required this.colors,
    required this.shadowColor,
  });

  final double size;
  final double radius;
  final double iconSize;
  final String iconAsset;
  final List<Color> colors;
  final Color shadowColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        gradient: CssLinearGradient(cssDegrees: 145, colors: colors),
        borderRadius: BorderRadius.circular(radius),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            offset: const Offset(0, 8),
            blurRadius: 13,
          ),
          const BoxShadow(
            color: Color(0x6BFFFFFF),
            offset: Offset(0, 1),
            blurStyle: BlurStyle.inner,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: _LucideIcon(asset: iconAsset, color: Colors.white, size: iconSize),
    );
  }
}

class _LucideIcon extends StatelessWidget {
  const _LucideIcon({
    required this.asset,
    required this.color,
    required this.size,
  });

  final String asset;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SvgPicture.asset(
      asset,
      width: size,
      height: size,
      fit: BoxFit.contain,
      excludeFromSemantics: true,
      colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
    );
  }
}

class _GhostToggle extends StatefulWidget {
  const _GhostToggle({
    super.key,
    required this.included,
    required this.size,
    required this.radius,
    required this.iconSize,
    required this.circular,
    required this.onTap,
  });

  final bool included;
  final double size;
  final double radius;
  final double iconSize;
  final bool circular;
  final VoidCallback onTap;

  @override
  State<_GhostToggle> createState() => _GhostToggleState();
}

class _GhostToggleState extends State<_GhostToggle> {
  var _showFocusOutline = false;

  void _handleFocusChange(bool focused) {
    final show =
        focused &&
        FocusManager.instance.highlightMode == FocusHighlightMode.traditional;
    if (_showFocusOutline == show) return;
    setState(() => _showFocusOutline = show);
  }

  @override
  Widget build(BuildContext context) {
    final label = widget.included
        ? 'Ghost tranzakciók beleszámítanak. Kikapcsolás.'
        : 'Ghost tranzakciók kizárva. Bekapcsolás.';
    final ownKey = widget.key;
    final outlineKey = ownKey is ValueKey<String>
        ? ValueKey('${ownKey.value}-focus-outline')
        : null;
    return Semantics(
      container: true,
      excludeSemantics: true,
      button: true,
      toggled: widget.included,
      label: label,
      onTap: widget.onTap,
      child: InkWell(
        excludeFromSemantics: true,
        splashFactory: NoSplash.splashFactory,
        overlayColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        onFocusChange: _handleFocusChange,
        onTap: widget.onTap,
        borderRadius: widget.circular
            ? null
            : BorderRadius.circular(widget.radius),
        customBorder: widget.circular ? const CircleBorder() : null,
        child: Stack(
          children: [
            Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                color: widget.circular
                    ? widget.included
                          ? const Color(0xEBF0EFFF)
                          : const Color(0x1F94A3B8)
                    : widget.included
                    ? const Color(0xFFF0EFFF)
                    : const Color(0xC7FFFFFF),
                shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
                borderRadius: widget.circular
                    ? null
                    : BorderRadius.circular(widget.radius),
                border: widget.circular
                    ? null
                    : Border.all(
                        color: widget.included
                            ? const Color(0x387165EF)
                            : const Color(0x338089AA),
                      ),
                boxShadow: widget.circular
                    ? null
                    : const [
                        BoxShadow(
                          color: Color(0x144C5580),
                          offset: Offset(0, 3),
                          blurRadius: 7,
                        ),
                      ],
              ),
              alignment: Alignment.center,
              child: ExcludeSemantics(
                child: _LucideIcon(
                  asset: 'assets/icons/lucide/ghost.svg',
                  color: widget.included
                      ? widget.circular
                            ? const Color(0xFF5F55EC)
                            : const Color(0xFF7165EF)
                      : widget.circular
                      ? const Color(0xFF94A3B8)
                      : const Color(0xFF9CA6BC),
                  size: widget.iconSize,
                ),
              ),
            ),
            if (_showFocusOutline)
              Positioned.fill(
                child: _TraditionalFocusOutline(
                  outlineKey: outlineKey,
                  shape: widget.circular ? BoxShape.circle : BoxShape.rectangle,
                  borderRadius: widget.circular
                      ? null
                      : BorderRadius.circular(widget.radius - 1),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TraditionalFocusOutline extends StatelessWidget {
  const _TraditionalFocusOutline({
    required this.outlineKey,
    this.shape = BoxShape.rectangle,
    this.borderRadius,
  });

  final Key? outlineKey;
  final BoxShape shape;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(1),
      child: IgnorePointer(
        child: DecoratedBox(
          key: outlineKey,
          decoration: BoxDecoration(
            shape: shape,
            borderRadius: shape == BoxShape.circle ? null : borderRadius,
            border: Border.all(color: _traditionalFocusOutlineColor, width: 2),
          ),
        ),
      ),
    );
  }
}

const _rankedAmountStyle = TextStyle(
  color: Color(0xFF26355A),
  fontSize: 12.5,
  height: 1,
  fontWeight: FontWeight.w900,
  fontVariations: SpendeeBalanceVisualSpec.weight950,
);
