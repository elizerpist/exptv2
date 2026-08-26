import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../budget_content_card_style.dart';

/// The one physical Card2 surface used by both lazily built page items. It is
/// deliberately inside the PageView so radius and shadow travel with the
/// semantic Category/Partner page instead of leaving a stationary white card
/// behind it.
class BudgetDistributionPageCard extends StatelessWidget {
  const BudgetDistributionPageCard({
    super.key,
    required this.cardKey,
    required this.child,
    this.contentCardStyle,
  });

  final Key cardKey;
  final Widget child;
  final ValueListenable<BudgetContentLayout>? contentCardStyle;

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    key: cardKey,
    child: Stack(
      fit: StackFit.expand,
      clipBehavior: Clip.none,
      children: <Widget>[
        ValueListenableBuilder<BudgetContentLayout>(
          valueListenable: contentCardStyle ?? _alwaysSplitBudgetContent,
          builder: (context, layout, _) => layout == BudgetContentLayout.split
              ? LayoutBuilder(
                  builder: (context, constraints) {
                    final depth = DashboardShadowStyleScope.profileOf(context)
                        .depthFor(
                          DashboardCornerSurfaceFamily.budgetDistributionCard,
                        );
                    return FluviRoundedBox(
                      key: const ValueKey(
                        'budget-distribution-page-card-surface',
                      ),
                      color: depth.surfaceColor ?? FluviVisualTokens.surface,
                      border:
                          depth.border ??
                          Border.all(color: FluviVisualTokens.border),
                      borderRadius:
                          DashboardCornerRoundnessScope.profileOf(
                            context,
                          ).borderRadiusFor(
                            DashboardCornerSurfaceFamily.budgetDistributionCard,
                            size: constraints.biggest,
                          ),
                      boxShadow: depth.shadows,
                      child: const SizedBox.expand(),
                    );
                  },
                )
              : const SizedBox.shrink(),
        ),
        Positioned.fill(child: child),
      ],
    ),
  );
}

final ValueListenable<BudgetContentLayout> _alwaysSplitBudgetContent =
    ValueNotifier<BudgetContentLayout>(BudgetContentLayout.split);

/// Shared Card2 page geometry. Category and Partner supply only their exact
/// prepared donut, heading and rows; padding, flexes, list ownership and row
/// appearance stay one production contract.
class BudgetDistributionPageSurface extends StatelessWidget {
  const BudgetDistributionPageSurface({
    super.key,
    required this.heading,
    required this.donut,
    required this.rightHeading,
    required this.rows,
    required this.listKey,
    required this.emptyLabel,
    this.donutDiameter = 150,
    this.expandDonutToFit = false,
    this.leftFooter,
    this.leftFooterMinimumHeight = 0,
  });

  final Widget heading;
  final Widget donut;
  final String rightHeading;
  final List<Widget> rows;
  final Key listKey;
  final String emptyLabel;

  /// Category analysis may reserve a local footer below a smaller donut;
  /// Partner retains the original full-height donut/list geometry.
  final double donutDiameter;

  /// Legacy preserves its accepted authored diameter. Experimental lower
  /// cards opt into their real padded constraints, so their added height can
  /// increase the useful square without an arbitrary scale transform.
  final bool expandDonutToFit;
  final Widget? leftFooter;

  /// A footer such as the existing partner rhythm chart keeps a real minimum
  /// readable height. The constraint-driven donut consumes only the leftover
  /// card height, rather than forcing that chart to overflow on an
  /// intermediate dashboard geometry.
  final double leftFooterMinimumHeight;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(10),
    child: Column(
      children: <Widget>[
        SizedBox(height: 23, child: heading),
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                flex: 188,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final footerHeight = leftFooter == null
                        ? 0.0
                        : leftFooterMinimumHeight + 3;
                    final availableHeight =
                        (constraints.maxHeight - footerHeight)
                            .clamp(0.0, double.infinity)
                            .toDouble();
                    final available =
                        ((constraints.maxWidth < availableHeight
                                    ? constraints.maxWidth
                                    : availableHeight) -
                                8)
                            .clamp(0.0, double.infinity)
                            .toDouble();
                    final diameter = expandDonutToFit
                        ? available
                        : donutDiameter.clamp(0.0, available).toDouble();
                    final donutBox = SizedBox(
                      key: ValueKey(
                        'budget-distribution-donut-${diameter.toInt()}',
                      ),
                      width: diameter,
                      height: diameter,
                      child: donut,
                    );
                    return leftFooter == null
                        ? Center(child: donutBox)
                        : Column(
                            children: <Widget>[
                              Center(child: donutBox),
                              const SizedBox(height: 3),
                              Expanded(child: leftFooter!),
                            ],
                          );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 160,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: <Widget>[
                    Text(
                      rightHeading,
                      style: const TextStyle(
                        color: Color(0xff51617f),
                        fontSize: 9,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Expanded(
                      child: rows.isEmpty
                          ? Center(
                              child: Text(
                                emptyLabel,
                                style: const TextStyle(
                                  color: Color(0xff66738d),
                                  fontSize: 8,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            )
                          : ListView.builder(
                              key: listKey,
                              primary: false,
                              padding: EdgeInsets.zero,
                              itemCount: rows.length,
                              itemBuilder: (_, index) => rows[index],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

/// Shared readable reference-derived legend row. Selection is an immediate
/// direct-manipulation state; the semantic command owner decides separately
/// when a tap becomes authoritative application focus.
class BudgetDistributionLegendRow extends StatelessWidget {
  const BudgetDistributionLegendRow({
    super.key,
    required this.id,
    required this.title,
    required this.color,
    required this.roundedPercent,
    required this.selected,
    this.stateKey,
    this.onTap,
  });

  final String id;
  final String title;
  final Color color;
  final int roundedPercent;
  final bool selected;
  final Key? stateKey;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => GestureDetector(
    behavior: HitTestBehavior.opaque,
    onTap: onTap,
    child: Container(
      key:
          stateKey ??
          ValueKey(
            'budget-distribution-row-${selected ? 'selected' : 'idle'}-$id',
          ),
      height: 22,
      padding: const EdgeInsets.symmetric(horizontal: 3),
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: .13) : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          DecoratedBox(
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: const SizedBox(width: 8, height: 8),
          ),
          const SizedBox(width: 5),
          Expanded(
            child: Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Color(0xff66738d),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 3),
          Text(
            '$roundedPercent%',
            style: const TextStyle(
              color: Color(0xff25365c),
              fontSize: 8.2,
              height: 1,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    ),
  );
}
