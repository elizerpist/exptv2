import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_rhythm_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_category_distribution_svg.dart';
import 'budget_distribution_page_surface.dart';
import 'budget_rhythm_bar_chart.dart';

/// Partner page for Budget Card2. It renders the exact prepared target frame
/// and forwards only explicit partner intents to the existing ephemeral-focus
/// owner; it owns neither Query nor Budget-target selection.
class BudgetPartnerDistributionCard extends StatefulWidget {
  const BudgetPartnerDistributionCard({
    super.key,
    required this.presentation,
    required this.drawableFrames,
    this.rhythm,
    this.drilldown,
  });

  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;
  final ValueListenable<DashboardBudgetRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;

  @override
  State<BudgetPartnerDistributionCard> createState() =>
      _BudgetPartnerDistributionCardState();
}

class _BudgetPartnerDistributionCardState
    extends State<BudgetPartnerDistributionCard> {
  late LedgerDirection _direction;
  late int _targetHandle;
  DashboardEphemeralFocusController? _focus;

  @override
  void initState() {
    super.initState();
    _direction = widget.presentation.value.liveSelection.direction;
    _targetHandle = widget.presentation.value.selectedHandle;
    widget.presentation.addListener(_onPresentationChanged);
    widget.drawableFrames.addListener(_onDrawableChanged);
    _attachFocus();
  }

  @override
  void didUpdateWidget(covariant BudgetPartnerDistributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.presentation, widget.presentation)) {
      oldWidget.presentation.removeListener(_onPresentationChanged);
      widget.presentation.addListener(_onPresentationChanged);
      _direction = widget.presentation.value.liveSelection.direction;
      _targetHandle = widget.presentation.value.selectedHandle;
    }
    if (!identical(oldWidget.drawableFrames, widget.drawableFrames)) {
      oldWidget.drawableFrames.removeListener(_onDrawableChanged);
      widget.drawableFrames.addListener(_onDrawableChanged);
    }
    if (!identical(oldWidget.drilldown, widget.drilldown)) {
      _detachFocus(oldWidget.drilldown?.core.focus);
      _attachFocus();
    }
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onPresentationChanged);
    widget.drawableFrames.removeListener(_onDrawableChanged);
    _detachFocus(_focus);
    super.dispose();
  }

  void _onPresentationChanged() {
    final presentation = widget.presentation.value;
    final next = presentation.liveSelection.direction;
    final nextTargetHandle = presentation.selectedHandle;
    if (next == _direction && nextTargetHandle == _targetHandle) return;
    _direction = next;
    _targetHandle = nextTargetHandle;
    if (mounted) setState(() {});
  }

  void _onDrawableChanged() {
    if (mounted) setState(() {});
  }

  void _attachFocus() {
    final next = widget.drilldown?.core.focus;
    if (identical(_focus, next)) return;
    _detachFocus(_focus);
    _focus = next;
    _focus?.addListener(_onFocusChanged);
  }

  void _detachFocus(DashboardEphemeralFocusController? focus) {
    focus?.removeListener(_onFocusChanged);
    if (identical(_focus, focus)) _focus = null;
  }

  void _onFocusChanged() {
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
    final visualFrame = bank.frameFor(_direction, targetHandle: _targetHandle);
    final frame = visualFrame.semanticFrame;
    final selectedPartnerId = _focus?.state?.partner?.id;
    final svg = visualFrame.svgForPartnerHandle(selectedPartnerId);
    return BudgetDistributionPageSurface(
      heading: const _PartnerDistributionHeading(),
      donut: _InteractivePartnerDistributionDonut(
        svg: svg,
        values: frame.positiveValues,
        onSliceTap: (index) {
          if (index < 0 || index >= frame.entries.length) return;
          final entry = frame.entries[index];
          final drilldown = widget.drilldown;
          if (drilldown == null) return;
          unawaited(
            drilldown.commitPartner(
              source: 'partnerPie',
              targetHandle: _targetHandle,
              partner: DashboardFocusFacet(
                id: entry.partnerId,
                displayName: entry.title,
                colorId: entry.colorId,
              ),
            ),
          );
        },
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
            selected: entry.partnerId == selectedPartnerId,
            onTap: widget.drilldown == null
                ? null
                : () => unawaited(
                    widget.drilldown!.commitPartner(
                      source: 'partnerList',
                      targetHandle: _targetHandle,
                      partner: DashboardFocusFacet(
                        id: entry.partnerId,
                        displayName: entry.title,
                        colorId: entry.colorId,
                      ),
                    ),
                  ),
          ),
      ],
      donutDiameter: widget.rhythm == null ? 150 : 104,
      leftFooter: widget.rhythm == null
          ? null
          : ValueListenableBuilder<DashboardBudgetRhythmState?>(
              valueListenable: widget.rhythm!,
              builder: (context, rhythm, child) => rhythm == null
                  ? const SizedBox.shrink()
                  : BudgetRhythmBarChart(state: rhythm),
            ),
    );
  }
}

class _InteractivePartnerDistributionDonut extends StatelessWidget {
  const _InteractivePartnerDistributionDonut({
    required this.svg,
    required this.values,
    required this.onSliceTap,
  });

  final String svg;
  final List<int> values;
  final ValueChanged<int> onSliceTap;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      RepaintBoundary(
        child: SvgPicture.string(
          svg,
          key: ValueKey('budget-partner-distribution-donut-$svg'),
          fit: BoxFit.contain,
          errorBuilder: (_, _, _) => const SizedBox.expand(),
        ),
      ),
      Positioned.fill(
        child: GestureDetector(
          key: const ValueKey('budget-partner-distribution-donut-interaction'),
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final target = BudgetCategoryDistributionDonutHitTest.resolve(
              localPosition: details.localPosition,
              size: renderBox.size,
              values: values,
            );
            if (target.target ==
                    BudgetCategoryDistributionDonutTapTarget.slice &&
                target.index != null) {
              onSliceTap(target.index!);
            }
          },
        ),
      ),
    ],
  );
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
