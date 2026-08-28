import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../budget_content_card_style.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';

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
                      border: DashboardBorderScope.profileOf(
                        context,
                      ).borderFor(DashboardBorderSurface.budgetContent),
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
    this.donutScale = 1,
    this.expandDonutToFit = false,
    this.leftFooter,
    this.leftFooterMinimumHeight = 0,
    this.fullWidthFooter,
    this.fullWidthFooterMinimumHeight = 0,
    this.fullWidthFooterDividerGap = 3,
    this.donutVerticalInset = 8,
    this.upperVerticalGestures,
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

  /// Presentation-only diameter factor. Partner uses .90 so the existing
  /// Column gives the exact reclaimed vertical delta to its rhythm footer.
  final double donutScale;

  /// Legacy preserves its accepted authored diameter. Experimental lower
  /// cards opt into their real padded constraints, so their added height can
  /// increase the useful square without an arbitrary scale transform.
  final bool expandDonutToFit;
  final Widget? leftFooter;

  /// Partner-only lower section. It is deliberately separate from
  /// [leftFooter]: Category keeps the original two-column geometry.
  final Widget? fullWidthFooter;

  /// A footer such as the existing partner rhythm chart keeps a real minimum
  /// readable height. The constraint-driven donut consumes only the leftover
  /// card height, rather than forcing that chart to overflow on an
  /// intermediate dashboard geometry.
  final double leftFooterMinimumHeight;
  final double fullWidthFooterMinimumHeight;

  /// Shared default preserves Category's accepted Card2 geometry. Partner's
  /// Rhythm-first layout supplies its own measured divider and intentionally
  /// gives the reclaimed upper lane to its donut instead of a hidden inset.
  final double fullWidthFooterDividerGap;
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
  bool _isBoundaryHandoff = false;

  @override
  void dispose() {
    if (_isBoundaryHandoff) widget.upperVerticalGestures?.end();
    _legendScrollController.dispose();
    super.dispose();
  }

  bool _handleScrollNotification(ScrollNotification notification) {
    final coordinator = widget.upperVerticalGestures;
    if (coordinator == null) return false;
    if (notification is ScrollStartNotification &&
        notification.dragDetails != null) {
      coordinator.onForegroundInteraction?.call();
      if (_isBoundaryHandoff) {
        // The child regained a real scrollable range; it again owns this drag.
        coordinator.end();
        _isBoundaryHandoff = false;
      }
    }
    if (notification is OverscrollNotification &&
        notification.dragDetails != null) {
      coordinator.consumeBoundaryOverscroll(notification.overscroll);
      _isBoundaryHandoff = true;
    }
    if (notification is ScrollEndNotification && _isBoundaryHandoff) {
      coordinator.end();
      _isBoundaryHandoff = false;
    }
    return false;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(BudgetDistributionPageSurface.outerPadding),
    child: Column(
      children: <Widget>[
        SizedBox(
          height: BudgetDistributionPageSurface.headingHeight,
          child: widget.heading,
        ),
        Expanded(
          child: widget.fullWidthFooter == null
              ? _buildUpperRow()
              : Column(
                  children: <Widget>[
                    Expanded(child: _buildUpperRow()),
                    SizedBox(height: widget.fullWidthFooterDividerGap),
                    SizedBox(
                      height: widget.fullWidthFooterMinimumHeight,
                      child: widget.fullWidthFooter,
                    ),
                  ],
                ),
        ),
      ],
    ),
  );

  Widget _buildUpperRow() => Row(
    children: <Widget>[
      Expanded(
        flex: 188,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final footerHeight = widget.leftFooter == null
                ? 0.0
                : widget.leftFooterMinimumHeight + 3;
            final availableHeight = (constraints.maxHeight - footerHeight)
                .clamp(0.0, double.infinity)
                .toDouble();
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
            final diameter = baselineDiameter * widget.donutScale;
            final donutBox = SizedBox(
              key: ValueKey('budget-distribution-donut-${diameter.toInt()}'),
              width: diameter,
              height: diameter,
              child: widget.donut,
            );
            return widget.leftFooter == null
                ? Center(child: donutBox)
                : Column(
                    children: <Widget>[
                      Center(child: donutBox),
                      const SizedBox(height: 3),
                      Expanded(child: widget.leftFooter!),
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
              widget.rightHeading,
              style: const TextStyle(
                color: Color(0xff51617f),
                fontSize: 9,
                height: 1,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 7),
            Expanded(
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
                  : NotificationListener<ScrollNotification>(
                      onNotification: _handleScrollNotification,
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
    required this.roundedPercent,
    required this.selected,
    this.height = 22,
    this.stateKey,
    this.onTap,
  });

  final String id;
  final String title;
  final Color color;
  final int roundedPercent;
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
