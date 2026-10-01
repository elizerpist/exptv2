import 'package:flutter/material.dart';

import 'budget_distribution_ranking.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';
import '../dashboard_vertical_scroll_boundary_handoff.dart';
import '../widgets/dashboard_render_diagnostic_probe.dart';

/// Explicitly separates physical material from PageView clipping ownership.
enum BudgetDistributionSurfaceOwner { splitCard2, unifiedParent }

/// The one physical Card2 surface around the persistent PageView. Category and
/// Partner pages supply only their interior content, so no sibling can own a
/// competing shadow, border, radius, or opaque material during collapse.
class BudgetDistributionCardShell extends StatelessWidget {
  const BudgetDistributionCardShell({
    super.key,
    required this.child,
    this.surfaceOwner = BudgetDistributionSurfaceOwner.splitCard2,
    this.topGlowColor,
  });

  final Widget child;
  final BudgetDistributionSurfaceOwner surfaceOwner;
  final Color? topGlowColor;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final depth = DashboardShadowStyleScope.profileOf(
        context,
      ).depthFor(DashboardCornerSurfaceFamily.budgetDistributionCard);
      final borderRadius = DashboardCornerRoundnessScope.profileOf(context)
          .borderRadiusFor(
            DashboardCornerSurfaceFamily.budgetDistributionCard,
            size: constraints.biggest,
          );
      return DashboardRenderDiagnosticProbe(
        candidate: 'budgetDistributionViewport',
        material: surfaceOwner == BudgetDistributionSurfaceOwner.splitCard2
            ? 'surfaceOwner=splitCard2 physicalMaterial=FluviRoundedBox '
                  'surface=${depth.surfaceColor ?? FluviVisualTokens.surface} '
                  'shadowCount=${depth.shadows.length}'
            : 'surfaceOwner=unifiedParent '
                  'physicalMaterial=BudgetUnifiedContentCard',
        clip: 'ClipRRect',
        zOrder: 'physicalMaterial<viewportClip<PageView',
        child: Stack(
          fit: StackFit.expand,
          children: <Widget>[
            if (surfaceOwner == BudgetDistributionSurfaceOwner.splitCard2)
              FluviRoundedBox(
                key: const ValueKey('budget-distribution-card-shell'),
                color: depth.surfaceColor ?? FluviVisualTokens.surface,
                border: DashboardBorderScope.profileOf(
                  context,
                ).borderFor(DashboardBorderSurface.budgetContent),
                borderRadius: borderRadius,
                boxShadow: depth.shadows,
                child: const SizedBox.expand(),
              ),
            if (topGlowColor case final color?)
              ClipRRect(
                borderRadius: borderRadius,
                child: IgnorePointer(
                  child: Align(
                    alignment: Alignment.topCenter,
                    child: SizedBox(
                      height: 58,
                      child: DecoratedBox(
                        key: const ValueKey(
                          'budget-selected-avatar-content-glow',
                        ),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: <Color>[
                              color.withValues(alpha: .20),
                              color.withValues(alpha: .06),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ClipRRect(borderRadius: borderRadius, child: child),
          ],
        ),
      );
    },
  );
}

/// Shared Card2 page geometry. Category and Partner supply only their exact
/// prepared donut, heading and rows; padding, flexes, list ownership and row
/// appearance stay one production contract.
class BudgetDistributionPageSurface extends StatefulWidget {
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
    this.donutVerticalInset = 8,
    this.rightHeaderTrailing,
    this.upperVerticalGestures,
  });

  final Widget heading;
  final Widget donut;
  final String rightHeading;
  final Widget? rightHeaderTrailing;
  final List<Widget> rows;
  final Key listKey;
  final String emptyLabel;

  /// One shared Category/Partner base diameter under ordinary Card2 bounds.
  final double donutDiameter;

  /// Legacy preserves its accepted authored diameter. Experimental lower
  /// cards opt into their real padded constraints, so their added height can
  /// increase the useful square without an arbitrary scale transform.
  final bool expandDonutToFit;
  final double donutVerticalInset;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  /// The first donut/list visual region begins only after this authored
  /// padding-and-heading lane. Budget's selected avatar shell may occupy the
  /// preceding shared-card overlap without colliding with the actual chart.
  static const double outerPadding = 10;
  static const double headingHeight = 23;
  static const double firstChartVisualOffset = outerPadding + headingHeight;

  @override
  State<BudgetDistributionPageSurface> createState() =>
      _BudgetDistributionPageSurfaceState();
}

final class _BudgetDistributionPageSurfaceState
    extends State<BudgetDistributionPageSurface> {
  late final ScrollController _legendScrollController = ScrollController();

  @override
  void dispose() {
    _legendScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => DashboardRenderDiagnosticProbe(
    candidate: 'budgetDistributionPageContent',
    material: 'transparent page content',
    clip: 'inherited BudgetDistributionCardShell.ClipRRect',
    zOrder: 'viewportClip<PageView>pageContent',
    child: Padding(
      padding: const EdgeInsets.all(BudgetDistributionPageSurface.outerPadding),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: BudgetDistributionPageSurface.headingHeight,
            child: _buildTitleRow(),
          ),
          Expanded(child: _buildUpperRow()),
        ],
      ),
    ),
  );

  Widget _buildTitleRow() => Row(
    children: <Widget>[
      Expanded(flex: 188, child: widget.heading),
      const SizedBox(width: 10),
      Expanded(
        flex: 160,
        child: Row(
          children: <Widget>[
            Expanded(
              child: Text(
                widget.rightHeading,
                style: const TextStyle(
                  color: Color(0xff51617f),
                  fontSize: 9,
                  height: 1,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            if (widget.rightHeaderTrailing != null) widget.rightHeaderTrailing!,
          ],
        ),
      ),
    ],
  );

  Widget _buildUpperRow() => Row(
    children: <Widget>[
      Expanded(
        flex: 188,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final availableHeight = constraints.maxHeight;
            final available =
                ((constraints.maxWidth < availableHeight
                            ? constraints.maxWidth
                            : availableHeight) -
                        widget.donutVerticalInset)
                    .clamp(0.0, double.infinity)
                    .toDouble();
            final baselineDiameter = widget.expandDonutToFit
                ? available
                : widget.donutDiameter.clamp(0.0, available).toDouble();
            final donutBox = SizedBox(
              key: ValueKey(
                'budget-distribution-donut-${baselineDiameter.toInt()}',
              ),
              width: baselineDiameter,
              height: baselineDiameter,
              child: widget.donut,
            );
            return Center(child: donutBox);
          },
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        flex: 160,
        child: widget.rows.isEmpty
            ? Center(
                child: Text(
                  widget.emptyLabel,
                  style: const TextStyle(
                    color: Color(0xff66738d),
                    fontSize: 8,
                    height: 1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              )
            : DashboardVerticalScrollBoundaryHandoff(
                upperVerticalGestures: widget.upperVerticalGestures,
                child: ListView.builder(
                  key: widget.listKey,
                  controller: _legendScrollController,
                  primary: false,
                  padding: EdgeInsets.zero,
                  itemCount: widget.rows.length,
                  itemBuilder: (_, index) => widget.rows[index],
                ),
              ),
      ),
    ],
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
    required this.trailingMetric,
    required this.selected,
    this.height = 22,
    this.stateKey,
    this.onTap,
  });

  final String id;
  final String title;
  final Color color;
  final BudgetDistributionTrailingMetric trailingMetric;
  final bool selected;
  final double height;
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
      height: height,
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
            trailingMetric.label,
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

/// The right-side legend value is semantic, never a percentage-shaped slot.
sealed class BudgetDistributionTrailingMetric {
  const BudgetDistributionTrailingMetric();

  String get label;

  const factory BudgetDistributionTrailingMetric.sharePercent(int value) =
      _BudgetDistributionSharePercentMetric;
  const factory BudgetDistributionTrailingMetric.transactionCount(int value) =
      _BudgetDistributionTransactionCountMetric;
}

final class _BudgetDistributionSharePercentMetric
    extends BudgetDistributionTrailingMetric {
  const _BudgetDistributionSharePercentMetric(this.value);

  final int value;

  @override
  String get label => '$value%';
}

final class _BudgetDistributionTransactionCountMetric
    extends BudgetDistributionTrailingMetric {
  const _BudgetDistributionTransactionCountMetric(this.value);

  final int value;

  @override
  String get label => '$value';
}

/// Small title-row selector. Its menu selection is a caller-owned local
/// presentation change, so it cannot trigger a dashboard acquisition.
class BudgetDistributionRankingSelector extends StatelessWidget {
  const BudgetDistributionRankingSelector({
    super.key,
    required this.value,
    required this.onChanged,
  });

  final BudgetDistributionRanking value;
  final ValueChanged<BudgetDistributionRanking> onChanged;

  @override
  Widget build(BuildContext context) =>
      PopupMenuButton<BudgetDistributionRanking>(
        key: const ValueKey('budget-distribution-ranking-selector'),
        tooltip: value.label,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(minWidth: 132),
        icon: const Icon(
          Icons.sort_rounded,
          size: 15,
          color: Color(0xff70809a),
        ),
        itemBuilder: (context) => <PopupMenuEntry<BudgetDistributionRanking>>[
          for (final ranking in BudgetDistributionRanking.values)
            CheckedPopupMenuItem<BudgetDistributionRanking>(
              value: ranking,
              checked: ranking == value,
              child: Text(ranking.label),
            ),
        ],
        onSelected: onChanged,
      );
}
