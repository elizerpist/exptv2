import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../../../core/assets/prepared_vector_asset_atlas.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/catalog/category_icon_catalog.dart';
import '../../../../core/categories/presentation/category_icon_view.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_category_distribution_controller.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_target.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_svg.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_target_avatar_rail_controller.dart';

/// Budget card2's category-distribution page. It receives already-prepared
/// semantic and vector banks; it is only a renderer plus command source.
class BudgetCategoryDistributionCard extends StatefulWidget {
  const BudgetCategoryDistributionCard({
    super.key,
    required this.presentation,
    required this.semanticBundles,
    required this.visualBanks,
    required this.avatarRailController,
  });

  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetCategoryDistributionBundle?>
  semanticBundles;
  final ValueListenable<DashboardBudgetCategoryDistributionVisualBank?>
  visualBanks;
  final BudgetTargetAvatarRailController avatarRailController;

  @override
  State<BudgetCategoryDistributionCard> createState() =>
      _BudgetCategoryDistributionCardState();
}

class _BudgetCategoryDistributionCardState
    extends State<BudgetCategoryDistributionCard> {
  late LedgerDirection _direction;
  int? _lastSelectionHandle;
  LedgerDirection? _lastSelectionDirection;

  @override
  void initState() {
    super.initState();
    _direction = widget.presentation.value.liveSelection.direction;
    _lastSelectionHandle = widget.presentation.value.selectedHandle;
    _lastSelectionDirection = _direction;
    widget.presentation.addListener(_onPresentationChanged);
    widget.semanticBundles.addListener(_onStructuralInputChanged);
    widget.visualBanks.addListener(_onStructuralInputChanged);
  }

  @override
  void didUpdateWidget(covariant BudgetCategoryDistributionCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.presentation, widget.presentation)) {
      oldWidget.presentation.removeListener(_onPresentationChanged);
      widget.presentation.addListener(_onPresentationChanged);
      _direction = widget.presentation.value.liveSelection.direction;
    }
    if (!identical(oldWidget.semanticBundles, widget.semanticBundles)) {
      oldWidget.semanticBundles.removeListener(_onStructuralInputChanged);
      widget.semanticBundles.addListener(_onStructuralInputChanged);
    }
    if (!identical(oldWidget.visualBanks, widget.visualBanks)) {
      oldWidget.visualBanks.removeListener(_onStructuralInputChanged);
      widget.visualBanks.addListener(_onStructuralInputChanged);
    }
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onPresentationChanged);
    widget.semanticBundles.removeListener(_onStructuralInputChanged);
    widget.visualBanks.removeListener(_onStructuralInputChanged);
    super.dispose();
  }

  void _onPresentationChanged() {
    final presentation = widget.presentation.value;
    final nextDirection = presentation.liveSelection.direction;
    final targetHandle = presentation.selectedHandle;
    if (targetHandle != _lastSelectionHandle ||
        nextDirection != _lastSelectionDirection) {
      _lastSelectionHandle = targetHandle;
      _lastSelectionDirection = nextDirection;
      final visualBank = widget.visualBanks.value;
      final visualFrame = visualBank == null
          ? null
          : visualBank.frameFor(nextDirection);
      final sliceIndex = visualFrame?.semanticFrame.sliceIndexForTargetHandle(
        targetHandle,
      );
      FluviDiagnosticLogger.log(
        FluviDiagnosticEvent(
          stage: 'BUDGET_DISTRIBUTION_SELECTION_BOUND',
          scope:
              'direction=${nextDirection.name} '
              'period=${visualBank?.semanticBundle.key.diagnosticLabel ?? '-'} '
              'targetHandle=$targetHandle '
              'slice=${sliceIndex == null || sliceIndex < 0 ? 'aggregate' : sliceIndex}',
        ),
      );
    }
    if (nextDirection == _direction) return;
    _direction = nextDirection;
    if (mounted) setState(() {});
  }

  void _onStructuralInputChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final visualBank = widget.visualBanks.value;
    final semanticBundle = widget.semanticBundles.value;
    // Never show an old period while the new exact RAM bundle is being
    // prepared for flutter_svg's public source cache.
    if (visualBank == null ||
        !identical(visualBank.semanticBundle, semanticBundle)) {
      return const SizedBox.expand(
        key: ValueKey('budget-category-distribution-preparing'),
      );
    }
    final direction = _direction;
    final visualFrame = visualBank.frameFor(direction);
    final frame = visualFrame.semanticFrame;
    return Padding(
      padding: const EdgeInsets.all(10),
      child: Column(
        children: <Widget>[
          SizedBox(
            height: 23,
            child: _DistributionHeading(presentation: widget.presentation),
          ),
          Expanded(
            child: Row(
              children: <Widget>[
                Expanded(
                  flex: 188,
                  child: Center(
                    child: SizedBox(
                      width: 150,
                      height: 150,
                      child: _InteractiveDistributionDonut(
                        presentation: widget.presentation,
                        visualFrame: visualFrame,
                        values: frame.positiveValues,
                        onSliceTap: (sliceIndex) {
                          if (sliceIndex < 0 ||
                              sliceIndex >= frame.entries.length) {
                            return;
                          }
                          unawaited(
                            widget.avatarRailController.animateToTargetHandle(
                              frame.entries[sliceIndex].targetHandle,
                              source: BudgetTargetNavigationSource.pieSlice,
                            ),
                          );
                        },
                        onCenterTap: () => unawaited(
                          widget.avatarRailController.animateToTargetHandle(
                            0,
                            source: BudgetTargetNavigationSource.pieCenter,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 160,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      const Text(
                        'Kategóriák',
                        style: TextStyle(
                          color: Color(0xff51617f),
                          fontSize: 9,
                          height: 1,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 7),
                      Expanded(
                        child: frame.entries.isEmpty
                            ? Center(
                                child: Text(
                                  direction == LedgerDirection.income
                                      ? 'Nincs bevétel'
                                      : 'Nincs költés',
                                  style: const TextStyle(
                                    color: Color(0xff66738d),
                                    fontSize: 8,
                                    height: 1,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              )
                            : ListView.builder(
                                key: const ValueKey(
                                  'budget-category-distribution-list',
                                ),
                                primary: false,
                                padding: EdgeInsets.zero,
                                itemCount: frame.entries.length,
                                itemBuilder: (context, index) {
                                  final entry = frame.entries[index];
                                  return _DistributionLegendRow(
                                    key: ValueKey(
                                      'budget-category-distribution-row-${entry.categoryId}',
                                    ),
                                    entry: entry,
                                    presentation: widget.presentation,
                                    onTap: () => unawaited(
                                      widget.avatarRailController
                                          .animateToTargetHandle(
                                            entry.targetHandle,
                                            source: BudgetTargetNavigationSource
                                                .categoryList,
                                          ),
                                    ),
                                  );
                                },
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
}

class _InteractiveDistributionDonut extends StatelessWidget {
  const _InteractiveDistributionDonut({
    required this.presentation,
    required this.visualFrame,
    required this.values,
    required this.onSliceTap,
    required this.onCenterTap,
  });

  final DashboardBudgetPresentationController presentation;
  final DashboardBudgetCategoryDistributionVisualFrame visualFrame;
  final List<int> values;
  final ValueChanged<int> onSliceTap;
  final VoidCallback onCenterTap;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      ValueListenableBuilder<DashboardBudgetPresentationState>(
        valueListenable: presentation,
        builder: (context, state, child) {
          final svg = visualFrame.svgForTargetHandle(state.selectedHandle);
          return RepaintBoundary(
            child: SvgPicture.string(
              svg,
              key: ValueKey('budget-category-distribution-donut-$svg'),
              fit: BoxFit.contain,
              errorBuilder: (_, _, _) => const SizedBox.expand(),
            ),
          );
        },
      ),
      Positioned.fill(
        child: GestureDetector(
          key: const ValueKey('budget-category-distribution-donut-interaction'),
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final target = BudgetCategoryDistributionDonutHitTest.resolve(
              localPosition: details.localPosition,
              size: renderBox.size,
              values: values,
            );
            switch (target.target) {
              case BudgetCategoryDistributionDonutTapTarget.center:
                onCenterTap();
              case BudgetCategoryDistributionDonutTapTarget.slice:
                final index = target.index;
                if (index != null) onSliceTap(index);
              case BudgetCategoryDistributionDonutTapTarget.outside:
                break;
            }
          },
        ),
      ),
    ],
  );
}

class _DistributionHeading extends StatelessWidget {
  const _DistributionHeading({required this.presentation});

  final DashboardBudgetPresentationController presentation;

  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<DashboardBudgetPresentationState>(
        valueListenable: presentation,
        builder: (context, state, child) => _content(state.liveSelection),
      );

  Widget _content(DashboardBudgetLiveSelectionState selection) {
    final target = selection.target;
    final color = target.isAggregate
        ? Color(
            DashboardBudgetAggregateVisual.forDirection(
              selection.direction,
            ).middleColorArgb,
          )
        : CategoryColorCatalog.resolve(target.category!.colorId).middleColor;
    final icon = _preparedIconFor(selection);
    return Row(
      children: <Widget>[
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: SizedBox(
            width: 16,
            height: 16,
            child: icon == null
                ? const SizedBox.shrink()
                : Center(
                    child: CategoryIconView(
                      picture: icon,
                      size: 10,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
        const SizedBox(width: 6),
        const Expanded(
          child: Text(
            'Kategóriák eloszlása',
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

  PreparedVectorPicture? _preparedIconFor(
    DashboardBudgetLiveSelectionState selection,
  ) {
    final atlas = PreparedVectorAssetAtlas.instance;
    if (!atlas.isReady) return null;
    final target = selection.target;
    if (!target.isAggregate) {
      return atlas.categoryIcon(
        CategoryIconCatalog.handleOf(target.category!.iconId),
      );
    }
    return switch (selection.direction) {
      LedgerDirection.expense => atlas.categoryIcon(
        CategoryIconCatalog.handleOf('icon_17'),
      ),
      LedgerDirection.income => atlas.picture(
        PreparedVectorAssetAtlas.budgetIncomeGoalBanknoteHandle,
      ),
    };
  }
}

class _DistributionLegendRow extends StatefulWidget {
  const _DistributionLegendRow({
    super.key,
    required this.entry,
    required this.presentation,
    required this.onTap,
  });

  final DashboardBudgetCategoryDistributionEntry entry;
  final DashboardBudgetPresentationController presentation;
  final VoidCallback onTap;

  @override
  State<_DistributionLegendRow> createState() => _DistributionLegendRowState();
}

class _DistributionLegendRowState extends State<_DistributionLegendRow> {
  late bool _selected;

  @override
  void initState() {
    super.initState();
    _selected = _isSelected;
    widget.presentation.addListener(_onSelectionChanged);
  }

  @override
  void didUpdateWidget(covariant _DistributionLegendRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.presentation, widget.presentation)) {
      oldWidget.presentation.removeListener(_onSelectionChanged);
      widget.presentation.addListener(_onSelectionChanged);
    }
    _selected = _isSelected;
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onSelectionChanged);
    super.dispose();
  }

  bool get _isSelected =>
      widget.presentation.value.selectedHandle == widget.entry.targetHandle;

  void _onSelectionChanged() {
    final next = _isSelected;
    if (next == _selected) return;
    setState(() => _selected = next);
  }

  @override
  Widget build(BuildContext context) {
    final entry = widget.entry;
    final color = CategoryColorCatalog.resolve(entry.colorId).middleColor;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onTap,
      child: AnimatedContainer(
        key: ValueKey(
          'budget-category-distribution-row-${_selected ? 'selected' : 'idle'}-${entry.categoryId}',
        ),
        duration: const Duration(milliseconds: 120),
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 3),
        decoration: BoxDecoration(
          color: _selected ? color.withValues(alpha: .13) : Colors.transparent,
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
                entry.title,
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
              '${entry.roundedPercent}%',
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
}
