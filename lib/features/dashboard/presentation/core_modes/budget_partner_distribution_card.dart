import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_page_surface.dart';

/// Read-only Partner page for Budget Card2. It receives the exact renderer
/// ready partner frame already coupled to Category time publication; it owns
/// neither Query nor Budget-target selection.
class BudgetPartnerDistributionCard extends StatefulWidget {
  const BudgetPartnerDistributionCard({
    super.key,
    required this.presentation,
    required this.drawableFrames,
  });

  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;

  @override
  State<BudgetPartnerDistributionCard> createState() =>
      _BudgetPartnerDistributionCardState();
}

class _BudgetPartnerDistributionCardState
    extends State<BudgetPartnerDistributionCard> {
  late LedgerDirection _direction;

  @override
  void initState() {
    super.initState();
    _direction = widget.presentation.value.liveSelection.direction;
    widget.presentation.addListener(_onPresentationChanged);
    widget.drawableFrames.addListener(_onDrawableChanged);
  }

  @override
  void didUpdateWidget(covariant BudgetPartnerDistributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.presentation, widget.presentation)) {
      oldWidget.presentation.removeListener(_onPresentationChanged);
      widget.presentation.addListener(_onPresentationChanged);
      _direction = widget.presentation.value.liveSelection.direction;
    }
    if (!identical(oldWidget.drawableFrames, widget.drawableFrames)) {
      oldWidget.drawableFrames.removeListener(_onDrawableChanged);
      widget.drawableFrames.addListener(_onDrawableChanged);
    }
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onPresentationChanged);
    widget.drawableFrames.removeListener(_onDrawableChanged);
    super.dispose();
  }

  void _onPresentationChanged() {
    final next = widget.presentation.value.liveSelection.direction;
    if (next == _direction) return;
    _direction = next;
    if (mounted) setState(() {});
  }

  void _onDrawableChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final drawable = widget.drawableFrames.value;
    final bank = drawable?.partnerVisualBank;
    if (drawable == null || bank == null) {
      return const SizedBox.expand(
        key: ValueKey('budget-partner-distribution-preparing'),
      );
    }
    final frame = bank.frameFor(_direction).semanticFrame;
    final svg = bank.frameFor(_direction).svg;
    return BudgetDistributionPageSurface(
      heading: const _PartnerDistributionHeading(),
      donut: RepaintBoundary(
        child: SvgPicture.string(
          svg,
          key: ValueKey('budget-partner-distribution-donut-$svg'),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
      rightHeading: 'Partnerek',
      listKey: const ValueKey('budget-partner-distribution-list'),
      emptyLabel: 'Nincs partner',
      rows: <Widget>[
        for (final entry in frame.entries)
          BudgetDistributionLegendRow(
            key: ValueKey('budget-partner-distribution-row-${entry.partnerId}'),
            id: entry.partnerId,
            title: entry.title,
            color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
            roundedPercent: entry.roundedPercent,
            selected: false,
          ),
      ],
    );
  }
}

class _PartnerDistributionHeading extends StatelessWidget {
  const _PartnerDistributionHeading();

  @override
  Widget build(BuildContext context) => const Row(
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(
          color: Color(0xff8571b1),
          shape: BoxShape.circle,
        ),
        child: SizedBox(
          width: 16,
          height: 16,
          child: Center(
            child: Icon(Icons.people_rounded, size: 10, color: Colors.white),
          ),
        ),
      ),
      SizedBox(width: 6),
      Expanded(
        child: Text(
          'Partnerek eloszlása',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: Color(0xff51617f),
            fontSize: 8.4,
            height: 1,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
    ],
  );
}
