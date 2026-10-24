import 'dart:async';

import 'package:flutter/foundation.dart'
    show ValueListenable, immutable, kDebugMode, listEquals;
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/header_cascade_motion.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../core/design/fluvi_global_appearance.dart';
import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/categories/domain/category_repository.dart';
import '../../../../core/categories/domain/fluvi_category.dart';
import '../../../../core/categories/presentation/category_avatar_palette_catalog.dart';
import '../../../../core/categories/presentation/category_avatar_palette_scope.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_spending_rhythm_controller.dart';
import '../../application/dashboard_budget_limit_edit_controller.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../widgets/dashboard_placeholder_card.dart';
import '../widgets/dashboard_render_diagnostic_probe.dart';
import '../widgets/dashboard_render_phase_probe.dart';
import '../budget_content_card_style.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import 'budget_unified_mother_card_geometry.dart';
import 'dashboard_unified_mother_card_motion.dart';
import '../budget_section_order.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';
import '../dashboard_budget_header_presentation.dart';
import 'budget_category_avatar_rail.dart';
import 'budget_limit_manager.dart';
import 'dashboard_partition_lane_geometry.dart';
import 'budget_allocation_partition_lane.dart';
import 'dashboard_header_contrast_text.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_pager.dart';
import 'budget_distribution_page_surface.dart';
import 'budget_target_avatar_rail_controller.dart';
import 'dashboard_core_mode_presentation.dart';
import 'dashboard_core_mode_surface_primitives.dart';
import 'dashboard_header_visual_engine.dart';

// In the production diagnostic route, DashboardHeaderContrastText keeps its
// existing identity-sensitive foreground painter so the outer phase probe can
// observe the corresponding whole-subtree paint after it completes.
void _acknowledgeHeaderPaintForDurationProbe() {}

/// Budget owns its header and two future data-card presentation slots.
class BudgetDashboardCoreSurface extends StatelessWidget {
  static const _collectBudgetPaintDiagnostics =
      bool.fromEnvironment('FLUVI_PHYSICAL_RAIL_DIAGNOSTICS') || kDebugMode;

  const BudgetDashboardCoreSurface({
    super.key,
    required this.presentation,
    this.avatarContentStyle = BudgetAvatarContentStyle.separate,
    this.presentationController,
    this.categoryCollection,
    this.categoryRepository,
    this.limitEditController,
    this.distributionDrawables,
    this.avatarRailController,
    this.distributionPageController,
    this.contentCardStyle,
    this.sectionOrder,
    this.rhythm,
    this.drilldown,
    this.performanceCounters,
    this.onAvatarDirectInputStarted,
    this.onAvatarMotionActiveChanged,
    this.headerVisualController,
    this.headerVisualFrame,
    this.upperVerticalGestures,
  });

  final DashboardCoreModePresentation presentation;
  final BudgetAvatarContentStyle avatarContentStyle;
  final DashboardBudgetPresentationController? presentationController;
  final ValueListenable<List<FluviCategory>>? categoryCollection;
  final CategoryRepository? categoryRepository;
  final DashboardBudgetLimitEditController? limitEditController;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>?
  distributionDrawables;
  final BudgetTargetAvatarRailController? avatarRailController;
  final BudgetDistributionPageController? distributionPageController;
  final ValueListenable<BudgetContentLayout>? contentCardStyle;
  final ValueListenable<BudgetSectionOrder>? sectionOrder;
  final ValueListenable<DashboardSpendingRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;
  final DashboardPerformanceCounters? performanceCounters;
  final VoidCallback? onAvatarDirectInputStarted;
  final ValueChanged<bool>? onAvatarMotionActiveChanged;
  final DashboardHeaderVisualController? headerVisualController;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  Widget build(BuildContext context) {
    final geometry = presentation.geometry;
    final headerProfile = DashboardBudgetHeaderPresentationScope.profileOf(
      context,
    );
    return ValueListenableBuilder<BudgetSectionOrder>(
      valueListenable: sectionOrder ?? _alwaysAvatarsThenChart,
      builder: (context, order, _) {
        final section = _BudgetSectionLayout.resolve(geometry, order);
        final relationship = BudgetAvatarContentRelationship.resolve(
          avatarBounds: section.avatarBounds,
          chartBounds: section.chartBounds,
          style: avatarContentStyle,
          avatarsLeadContent: order == BudgetSectionOrder.avatarsThenChart,
        );
        final selectedAvatarAccent =
            avatarContentStyle == BudgetAvatarContentStyle.overlappingGlow
            ? _selectedAvatarAccent(context)
            : null;
        return KeyedSubtree(
          key: const ValueKey('dashboard-core-mode-budget'),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Preserve the original StackFill sizing contract. The optional
              // unified shell is a positioned dashboard surface when enabled and
              // a zero-size leaf when Split is selected; it must not become the
              // only non-positioned child and collapse the Budget stack.
              const SizedBox.expand(),
              if (avatarContentStyle == BudgetAvatarContentStyle.avatarRail)
                _BudgetMotherCardContentClip(
                  geometry: geometry,
                  contentCardStyle: contentCardStyle,
                  child: DashboardCoreModeCascadeCard(
                    bounds: section.avatarBounds,
                    motion: section.motionFor(
                      geometry.upperCardMotion!,
                      from: geometry.subheaderOneBounds,
                      to: section.avatarBounds,
                    ),
                    semanticKey: const ValueKey(
                      'budget-avatar-content-rail-backplate',
                    ),
                    showPlaceholderSurface: false,
                    content: const _BudgetAvatarRailBackplate(),
                  ),
                ),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable:
                    contentCardStyle ?? _alwaysUnifiedBudgetContent,
                builder: (context, layout, _) => _BudgetUnifiedContentCard(
                  geometry: geometry,
                  contentLayout: layout,
                ),
              ),
              _BudgetMotherCardContentClip(
                geometry: geometry,
                contentCardStyle: contentCardStyle,
                fadeTrailingEdge: true,
                child: DashboardRenderDiagnosticProbe(
                  candidate: 'budgetChartCascadeCard',
                  material: 'contentOnly DashboardCoreModeCascadeCard',
                  clip:
                      'shared physical viewport unified; child viewport split',
                  zOrder: 'unifiedSurface<chartCascade<avatarCascade',
                  child: DashboardCoreModeCascadeCard(
                    bounds: relationship.chartBounds,
                    motion: section.motionFor(
                      geometry.lowerCardMotion!,
                      from: geometry.zone2Bounds,
                      to: relationship.chartBounds,
                    ),
                    semanticKey: const ValueKey(
                      'dashboard-core-mode-budget-card-2',
                    ),
                    showPlaceholderSurface: false,
                    content: ValueListenableBuilder<BudgetContentLayout>(
                      valueListenable:
                          contentCardStyle ?? _alwaysUnifiedBudgetContent,
                      builder: (context, layout, _) => _distributionContent(
                        surfaceOwner: layout == BudgetContentLayout.unifiedCard
                            ? BudgetDistributionSurfaceOwner.unifiedParent
                            : BudgetDistributionSurfaceOwner.splitCard2,
                        topGlowColor: selectedAvatarAccent,
                      ),
                    ),
                  ),
                ),
              ),
              _BudgetMotherCardContentClip(
                geometry: geometry,
                contentCardStyle: contentCardStyle,
                child: ValueListenableBuilder<BudgetContentLayout>(
                  valueListenable:
                      contentCardStyle ?? _alwaysUnifiedBudgetContent,
                  builder: (context, layout, _) => DashboardCoreModeCascadeCard(
                    bounds: section.avatarBounds,
                    motion: section.motionFor(
                      geometry.upperCardMotion!,
                      from: geometry.subheaderOneBounds,
                      to: section.avatarBounds,
                    ),
                    semanticKey: const ValueKey(
                      'dashboard-core-mode-budget-card-1',
                    ),
                    showPlaceholderSurface: false,
                    contentVerticalInputOverflow:
                        BudgetTargetAvatarRail.selectedInputVerticalOverflow,
                    // The shared card starts at the authored mode-content top.
                    // Moving this full input parent down exactly one existing
                    // overflow clears the selected 112px chrome without changing
                    // Split's baseline rail position, hit bounds or carousel state.
                    contentVerticalOffset:
                        layout == BudgetContentLayout.unifiedCard ||
                            order == BudgetSectionOrder.chartThenAvatars
                        ? BudgetTargetAvatarRail.selectedInputVerticalOverflow
                        : 0,
                    content: _avatarContent(context),
                  ),
                ),
              ),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable:
                    contentCardStyle ?? _alwaysUnifiedBudgetContent,
                builder: (context, layout, _) {
                  final unified = layout == BudgetContentLayout.unifiedCard;
                  final separation = (1 - geometry.headerExpansionProgress)
                      .clamp(0.0, 1.0)
                      .toDouble();
                  final headerRadius =
                      DashboardCornerRoundnessScope.profileOf(
                        context,
                      ).borderRadiusFor(
                        DashboardCornerSurfaceFamily.header,
                        size: Size(
                          geometry.headerBounds.width,
                          geometry.headerBounds.height,
                        ),
                      );
                  final contentRadius =
                      DashboardCornerRoundnessScope.profileOf(
                        context,
                      ).borderRadiusFor(
                        DashboardCornerSurfaceFamily.budgetDistributionCard,
                        size: Size(
                          geometry.modeContentBounds.width,
                          geometry.modeContentBounds.height,
                        ),
                      );
                  final seamShape = DashboardHeaderContentSeamShape.resolve(
                    seamless: unified,
                    headerRadius: headerRadius,
                    contentRadius: contentRadius,
                    expansionProgress: geometry.headerExpansionProgress,
                  );
                  return DashboardCoreModeHeaderScaffold(
                    bounds: geometry.headerBounds,
                    surfaceColor: presentation.palette.upcomingHeaderTone,
                    headerKey: const ValueKey(
                      'dashboard-core-mode-budget-header',
                    ),
                    labelKey: const ValueKey(
                      'dashboard-core-mode-label-budget',
                    ),
                    label: 'budget',
                    showModeLabel: false,
                    labelContent: presentationController == null
                        ? null
                        : ValueListenableBuilder<
                            DashboardBudgetPresentationState
                          >(
                            valueListenable: presentationController!,
                            builder: (context, state, _) =>
                                DashboardHeaderContrastText(
                                  data: state.header.metric.modeLabel,
                                  key: const ValueKey(
                                    'dashboard-core-mode-label-budget',
                                  ),
                                  style:
                                      Theme.of(context).textTheme.labelSmall ??
                                      const TextStyle(),
                                  foreground: headerProfile.foreground,
                                  contrastStyle:
                                      headerProfile.settings.textContrastStyle,
                                ),
                          ),
                    visualController: headerVisualController,
                    visualFrameListenable: headerVisualFrame,
                    borderRadiusOverride: seamShape.headerRadius,
                    showsDepth: true,
                    showsBorder: true,
                    depthProgress: unified ? separation : 1,
                    borderProgress: unified ? separation : 1,
                    borderSurface: DashboardBorderSurface.header,
                    visualInset: EdgeInsets.zero,
                    // The source title starts at x=20/y=16. Text keeps the
                    // existing tuner/menu clearance internally; the partition
                    // lane itself now owns equal 16px physical insets.
                    detailLeft:
                        DashboardPartitionLaneGeometry.headerHorizontalInset,
                    detailTop: DashboardPartitionLaneGeometry.headerDetailTop,
                    detailRight:
                        DashboardPartitionLaneGeometry.headerHorizontalInset,
                    detailBottom: headerProfile.partitionBottomInset,
                    detail: presentationController == null
                        ? null
                        : ValueListenableBuilder<
                            DashboardBudgetPresentationState
                          >(
                            valueListenable: presentationController!,
                            builder: (context, state, child) {
                              final controller = presentationController!;
                              if (_collectBudgetPaintDiagnostics) {
                                controller.recordHeaderWidgetBuilt(
                                  state,
                                  buildVsyncMicros: SchedulerBinding
                                      .instance
                                      .currentSystemFrameTimeStamp
                                      .inMicroseconds,
                                );
                              }
                              final header = state.header;
                              final metric = header.metric;
                              final amount = header.isAvailable
                                  ? '${metric.usesPerDayAmounts ? DashboardPreparedFormatter.amountMinorPerDay(header.displayNumeratorScaled100!) : DashboardPreparedFormatter.amountMinor(header.displayNumeratorScaled100!)} / '
                                        '${header.displayDenominatorScaled100 == null
                                            ? '—'
                                            : metric.usesPerDayAmounts
                                            ? DashboardPreparedFormatter.amountMinorPerDay(header.displayDenominatorScaled100!)
                                            : DashboardPreparedFormatter.amountMinor(header.displayDenominatorScaled100!)}'
                                  : '— / —';
                              final partition = state.partition;
                              final expansion =
                                  geometry.headerExpansionProgress;
                              return LayoutBuilder(
                                builder: (context, constraints) {
                                  // The lower lane consumes only the room made by the
                                  // existing header expansion. This preserves the
                                  // title/value anchor at every intermediate height
                                  // without a feature-local layout threshold or
                                  // animation owner.
                                  final partitionReveal =
                                      DashboardPartitionLaneGeometry.headerRevealFor(
                                        availableHeight: constraints.maxHeight,
                                        thickness:
                                            headerProfile.partitionThickness,
                                        expansionProgress: expansion,
                                      );
                                  return Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Padding(
                                        padding: const EdgeInsets.only(
                                          left: 4,
                                          right: 44,
                                        ),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: <Widget>[
                                            DashboardHeaderContrastText(
                                              data: header.title,
                                              key: const ValueKey(
                                                'budget-header-target-title',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                fontSize: 10,
                                                height: 1,
                                                fontWeight: FontWeight.w900,
                                              ),
                                              foreground:
                                                  headerProfile.foreground,
                                              contrastStyle: headerProfile
                                                  .settings
                                                  .textContrastStyle,
                                            ),
                                            DashboardHeaderContrastText(
                                              data: metric.metricLabel,
                                              key: const ValueKey(
                                                'budget-header-metric-label',
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: const TextStyle(
                                                // The fixed Header already has a
                                                // seven-source-pixel interline
                                                // lane between target and amount.
                                                // The metric owns that existing
                                                // lane, retaining the accepted
                                                // Header/partition geometry even
                                                // at its collapsed height.
                                                fontSize: 7,
                                                height: 1,
                                                fontWeight: FontWeight.w700,
                                              ),
                                              foreground: headerProfile
                                                  .foreground
                                                  .withValues(alpha: .72),
                                              contrastStyle: headerProfile
                                                  .settings
                                                  .textContrastStyle,
                                            ),
                                            _headerAmountPaintProbe(
                                              state: state,
                                              controller: controller,
                                              child: FittedBox(
                                                fit: BoxFit.scaleDown,
                                                alignment: Alignment.centerLeft,
                                                child: DashboardHeaderContrastText(
                                                  data: amount,
                                                  key: const ValueKey(
                                                    'budget-header-actual-limit',
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 19,
                                                    height: .96,
                                                    letterSpacing: -.76,
                                                    fontWeight: FontWeight.w900,
                                                  ),
                                                  foreground:
                                                      headerProfile.foreground,
                                                  contrastStyle: headerProfile
                                                      .settings
                                                      .textContrastStyle,
                                                  // Unit-level surface hosts do not
                                                  // own the Core's shared counters.
                                                  // Retain their existing
                                                  // paint-acknowledgement contract;
                                                  // only a production Core host can
                                                  // report an exact subtree duration.
                                                  paintIdentity:
                                                      _collectBudgetPaintDiagnostics
                                                      ? state
                                                      : null,
                                                  onPainted:
                                                      !_collectBudgetPaintDiagnostics
                                                      ? null
                                                      : performanceCounters !=
                                                            null
                                                      ? _acknowledgeHeaderPaintForDurationProbe
                                                      : () => controller.recordHeaderPainted(
                                                          state,
                                                          paintVsyncMicros:
                                                              SchedulerBinding
                                                                  .instance
                                                                  .currentSystemFrameTimeStamp
                                                                  .inMicroseconds,
                                                          headerSubtreePaintMicros:
                                                              0,
                                                        ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Spacer(),
                                      ClipRect(
                                        child: Align(
                                          alignment: Alignment.bottomCenter,
                                          heightFactor: partitionReveal,
                                          child: Opacity(
                                            key: const ValueKey(
                                              'budget-header-partition-reveal',
                                            ),
                                            opacity: partitionReveal,
                                            child: BudgetHeaderAllocationDetail(
                                              partition: partition,
                                              thickness: headerProfile
                                                  .partitionThickness,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  );
                                },
                              );
                            },
                          ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  /// Reuses the dashboard's existing render-phase probe to time the actual
  /// amount subtree paint. It is constructed only for the same bounded
  /// debug/profile diagnostic mode as the existing Header acknowledgement.
  Widget _headerAmountPaintProbe({
    required DashboardBudgetPresentationState state,
    required DashboardBudgetPresentationController controller,
    required Widget child,
  }) {
    final counters = performanceCounters;
    if (!_collectBudgetPaintDiagnostics || counters == null) return child;
    return DashboardRenderPhaseProbe(
      counters: counters,
      layoutMetric: DashboardPerformanceMetric.budgetHeaderLayout,
      paintMetric: DashboardPerformanceMetric.budgetHeaderPaint,
      layoutDurationMetric: DashboardPerformanceMetric.budgetHeaderLayoutMicros,
      paintDurationMetric: DashboardPerformanceMetric.budgetHeaderPaintMicros,
      onPaintDuration: (headerSubtreePaintMicros) =>
          controller.recordHeaderPainted(
            state,
            paintVsyncMicros: SchedulerBinding
                .instance
                .currentSystemFrameTimeStamp
                .inMicroseconds,
            headerSubtreePaintMicros: headerSubtreePaintMicros,
          ),
      child: child,
    );
  }

  Widget _distributionContent({
    required BudgetDistributionSurfaceOwner surfaceOwner,
    Color? topGlowColor,
  }) {
    if (presentationController == null ||
        distributionDrawables == null ||
        avatarRailController == null ||
        distributionPageController == null) {
      return switch (surfaceOwner) {
        BudgetDistributionSurfaceOwner.splitCard2 =>
          BudgetDistributionCardShell(
            topGlowColor: topGlowColor,
            child: const SizedBox.expand(),
          ),
        BudgetDistributionSurfaceOwner.unifiedParent =>
          BudgetDistributionCardShell(
            surfaceOwner: BudgetDistributionSurfaceOwner.unifiedParent,
            topGlowColor: topGlowColor,
            child: SizedBox.expand(),
          ),
      };
    }
    return BudgetDistributionPager(
      controller: distributionPageController!,
      presentation: presentationController!,
      drawableFrames: distributionDrawables!,
      avatarRailController: avatarRailController!,
      expandCategoryDonutToFit: !presentation.geometry.hasPhysicalRail,
      drilldown: drilldown,
      upperVerticalGestures: upperVerticalGestures,
      surfaceOwner: surfaceOwner,
      topGlowColor: topGlowColor,
    );
  }

  Widget _avatarContent(BuildContext context) => presentationController == null
      ? const SizedBox(key: ValueKey<String>('budget-target-avatar-rail'))
      : BudgetTargetAvatarRail(
          presentation: presentationController!,
          limitEditController: limitEditController,
          enableQuickLimitEdit: true,
          navigationController: avatarRailController,
          onTargetPreviewAccepted: drilldown == null
              ? null
              : (targetHandle) =>
                    drilldown!.previewBudgetTarget(targetHandle: targetHandle),
          onTargetSettled: drilldown == null
              ? null
              : (targetHandle) => unawaited(
                  drilldown!.commitBudgetTargetHandle(
                    targetHandle: targetHandle,
                    source: 'avatarSettled',
                  ),
                ),
          onPreparedTargetHotsetRequested: drilldown?.primeBudgetTargetHotset,
          liveTargetReadiness: drilldown?.liveTargetReadiness,
          liveTargetPainted: drilldown?.liveTargetPainted,
          onMotionActiveChanged: onAvatarMotionActiveChanged,
          onDirectInputStarted: onAvatarDirectInputStarted,
          onSelectedBudgetTargetManagerRequested: limitEditController == null
              ? null
              : (request) => _openLimitManager(context, request),
        );

  void _openLimitManager(
    BuildContext context,
    BudgetLimitManagerRequest request,
  ) {
    final controller = presentationController;
    final edits = limitEditController;
    if (controller == null || edits == null) return;
    showDialog<void>(
      context: context,
      useSafeArea: false,
      builder: (context) => Dialog.fullscreen(
        child: BudgetLimitManager(
          request: request,
          presentation: controller,
          limitEdits: edits,
          categoryCollection: categoryCollection,
          categoryRepository: categoryRepository,
        ),
      ),
    );
  }

  /// Resolves the selected avatar's existing presentation colour, never a new
  /// category mapping. This lets the overlap cue follow the current global
  /// avatar palette without touching Budget target identity or selection.
  Color? _selectedAvatarAccent(BuildContext context) {
    final state = presentationController?.value;
    if (state == null) return null;
    DashboardBudgetTargetPresentationItem? selected;
    for (final item in state.items) {
      if (item.target.handle == state.selectedHandle) {
        selected = item;
        break;
      }
    }
    if (selected == null) return null;
    final colorId = selected.colorId;
    if (colorId != null) {
      return CategoryAvatarPaletteCatalog.tokenFor(
        CategoryAvatarColorProfileScope.profileOf(context),
        CategoryColorCatalog.handleOf(colorId),
      ).middleColor;
    }
    return selected.baseColorArgb == 0 ? null : Color(selected.baseColorArgb);
  }
}

/// A stable viewport clip around each existing interactive cascade layer.
/// Layout and gesture transforms remain owned by the original CascadeCard.
final class _BudgetMotherCardContentClip extends StatelessWidget {
  const _BudgetMotherCardContentClip({
    required this.geometry,
    required this.contentCardStyle,
    required this.child,
    this.fadeTrailingEdge = false,
  });
  final bool fadeTrailingEdge;
  final DashboardLayoutFrame geometry;
  final ValueListenable<BudgetContentLayout>? contentCardStyle;
  final Widget child;
  @override
  Widget build(BuildContext context) =>
      ValueListenableBuilder<BudgetContentLayout>(
        valueListenable: contentCardStyle ?? _alwaysUnifiedBudgetContent,
        child: child,
        builder: (context, layout, child) {
          final corners = DashboardCornerRoundnessScope.profileOf(context);
          final transition = BudgetUnifiedMotherCardGeometry.resolve(
            frame: geometry,
            headerRadius: corners.borderRadiusFor(
              DashboardCornerSurfaceFamily.header,
              size: Size(
                geometry.headerBounds.width,
                geometry.headerBounds.height,
              ),
            ),
            contentRadius: corners.borderRadiusFor(
              DashboardCornerSurfaceFamily.budgetDistributionCard,
              size: Size(
                geometry.modeContentBounds.width,
                geometry.modeContentBounds.height,
              ),
            ),
          );
          return DashboardMotherCardContentClip(
            bounds: transition.visibleBodyBounds,
            radius: transition.shape.contentRadius,
            enabled: layout == BudgetContentLayout.unifiedCard,
            // Four existing gap units form a continuous, density-independent
            // trailing fade. At expansion the exact original paint path runs.
            trailingFadeExtent: fadeTrailingEdge
                ? geometry.motherCardGap * 4 * transition.separation
                : 0,
            child: child!,
          );
        },
      );
}

/// One persistent material composition. Neither PageView nor avatar input is
/// a child of this decorative surface, so vertical frames cannot reparent them.
final class _BudgetUnifiedContentCard extends StatelessWidget {
  const _BudgetUnifiedContentCard({
    required this.geometry,
    required this.contentLayout,
  });
  final DashboardLayoutFrame geometry;
  final BudgetContentLayout contentLayout;

  @override
  Widget build(BuildContext context) {
    if (contentLayout != BudgetContentLayout.unifiedCard) {
      return const SizedBox.shrink();
    }
    final corners = DashboardCornerRoundnessScope.profileOf(context);
    final transition = BudgetUnifiedMotherCardGeometry.resolve(
      frame: geometry,
      headerRadius: corners.borderRadiusFor(
        DashboardCornerSurfaceFamily.header,
        size: Size(geometry.headerBounds.width, geometry.headerBounds.height),
      ),
      contentRadius: corners.borderRadiusFor(
        DashboardCornerSurfaceFamily.budgetDistributionCard,
        size: Size(
          geometry.modeContentBounds.width,
          geometry.modeContentBounds.height,
        ),
      ),
    );
    final bounds = transition.paintBounds;
    final body = transition.visibleBodyBounds.shift(-bounds.topLeft);
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.budgetDistributionCard);
    final border = DashboardBorderScope.profileOf(
      context,
    ).borderFor(DashboardBorderSurface.budgetContent);
    return DashboardCoreModeFramePosition(
      bounds: DashboardBounds(
        left: bounds.left,
        top: bounds.top,
        width: bounds.width,
        height: bounds.height,
      ),
      child: IgnorePointer(
        child: SizedBox.expand(
          key: const ValueKey('budget-unified-header-content-surface'),
          child: DashboardRenderDiagnosticProbe(
            candidate: 'budgetUnifiedHeaderContentSurface',
            material: 'persistent compound perimeter + one moving body',
            clip: 'body decoration only; PageView owns its unchanged viewport',
            zOrder: 'unifiedSurface<chartCascade<avatarCascade<header',
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    key: const ValueKey('budget-unified-perimeter'),
                    painter: _BudgetJoinedPerimeterPainter(
                      transition: transition,
                      shadows: depth.shadows,
                      headerBase:
                          depth.surfaceColor ?? FluviVisualTokens.surface,
                      border: null,
                    ),
                  ),
                ),
                Positioned(
                  left: body.left,
                  top: body.top,
                  width: body.width,
                  height: body.height,
                  child: Opacity(
                    opacity: transition.opacity,
                    child: DashboardPlaceholderCard(
                      bounds: DashboardBounds(
                        left: 0,
                        top: 0,
                        width: body.width,
                        height: body.height,
                      ),
                      fillParent: true,
                      semanticKey: const ValueKey('budget-unified-moving-body'),
                      cornerFamily:
                          DashboardCornerSurfaceFamily.budgetDistributionCard,
                      borderSurface: DashboardBorderSurface.budgetContent,
                      borderRadiusOverride: transition.shape.contentRadius,
                      depthProgress: transition.separation,
                      borderProgress: transition.separation,
                    ),
                  ),
                ),
                Positioned.fill(
                  child: CustomPaint(
                    painter: _BudgetJoinedPerimeterPainter(
                      transition: transition,
                      shadows: const [],
                      border: border,
                    ),
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

/// A perimeter has no opaque fill. Its path follows the two actual surfaces,
/// so an opened gap never retains the former full-height white backplate.
final class _BudgetJoinedPerimeterPainter extends CustomPainter {
  const _BudgetJoinedPerimeterPainter({
    required this.transition,
    required this.shadows,
    required this.border,
    this.headerBase,
  });
  final Color? headerBase;
  final BudgetUnifiedMotherCardGeometry transition;
  final List<BoxShadow> shadows;
  final BoxBorder? border;

  @override
  void paint(Canvas canvas, Size size) {
    final t = transition;
    final origin = -t.paintBounds.topLeft;
    final header = t.headerBounds.shift(origin);
    final body = t.visibleBodyBounds.shift(origin);
    final alpha = (1 - t.separation) * t.opacity;
    Path contour({Offset offset = Offset.zero, double spread = 0}) =>
        Path.combine(
          PathOperation.union,
          Path()..addRRect(
            t.shape.headerRadius.toRRect(header.shift(offset).inflate(spread)),
          ),
          Path()..addRRect(
            t.shape.contentRadius.toRRect(body.shift(offset).inflate(spread)),
          ),
        );
    for (final shadow in shadows) {
      final paint = shadow
          .copyWith(
            color: shadow.color.withValues(alpha: shadow.color.a * alpha),
          )
          .toPaint();
      if (t.separation == 0) {
        // Exact authored BoxDecoration endpoint, including its shadow raster.
        canvas.drawRRect(
          t.shape.outerRadius.toRRect(
            (Offset.zero & size)
                .shift(shadow.offset)
                .inflate(shadow.spreadRadius),
          ),
          paint,
        );
      } else {
        canvas.drawPath(
          contour(offset: shadow.offset, spread: shadow.spreadRadius),
          paint,
        );
      }
    }
    final base = headerBase;
    if (base != null) {
      canvas.drawRRect(
        t.shape.headerRadius.toRRect(header),
        Paint()..color = base.withValues(alpha: base.a * (1 - t.separation)),
      );
    }
    final outline = border;
    if (outline != null) {
      if (t.separation == 0) {
        outline.paint(
          canvas,
          Offset.zero & size,
          borderRadius: t.shape.outerRadius,
        );
      } else {
        final paint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = outline.top.width
          ..color = outline.top.color.withValues(
            alpha: outline.top.color.a * alpha,
          );
        // A joined outline owns only outer edges. New contact-edge borders
        // belong to the independently interpolated Header/body, never a
        // full-strength compound-path stroke on the first fractional frame.
        final headerCut =
            header.bottom -
            t.shape.headerRadius.bottomLeft.y -
            outline.top.width;
        final bodyCut =
            body.top + t.shape.contentRadius.topLeft.y + outline.top.width;
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, 0, size.width, headerCut));
        canvas.drawRRect(t.shape.headerRadius.toRRect(header), paint);
        canvas.restore();
        canvas.save();
        canvas.clipRect(Rect.fromLTRB(0, bodyCut, size.width, size.height));
        canvas.drawRRect(t.shape.contentRadius.toRRect(body), paint);
        canvas.restore();
      }
    }
  }

  @override
  bool shouldRepaint(covariant _BudgetJoinedPerimeterPainter old) =>
      old.transition.visibleBodyBounds != transition.visibleBodyBounds ||
      old.transition.headerBounds != transition.headerBounds ||
      old.transition.paintBounds != transition.paintBounds ||
      old.transition.separation != transition.separation ||
      old.transition.opacity != transition.opacity ||
      old.transition.shape.headerRadius != transition.shape.headerRadius ||
      old.transition.shape.contentRadius != transition.shape.contentRadius ||
      !listEquals(old.shadows, shadows) ||
      old.border != border ||
      old.headerBase != headerBase;
}

final ValueListenable<BudgetContentLayout> _alwaysUnifiedBudgetContent =
    ValueNotifier<BudgetContentLayout>(BudgetContentLayout.unifiedCard);
final ValueListenable<BudgetSectionOrder> _alwaysAvatarsThenChart =
    ValueNotifier<BudgetSectionOrder>(BudgetSectionOrder.avatarsThenChart);

@immutable
final class _BudgetSectionLayout {
  const _BudgetSectionLayout({
    required this.avatarBounds,
    required this.chartBounds,
  });

  final DashboardBounds avatarBounds;
  final DashboardBounds chartBounds;

  static _BudgetSectionLayout resolve(
    DashboardLayoutFrame geometry,
    BudgetSectionOrder order,
  ) {
    if (order == BudgetSectionOrder.avatarsThenChart) {
      return _BudgetSectionLayout(
        avatarBounds: geometry.subheaderOneBounds,
        chartBounds: geometry.zone2Bounds,
      );
    }
    final gap = geometry.zone2Bounds.top - geometry.subheaderOneBounds.bottom;
    // The selected Avatar has a 112px interactive shell while the structural
    // subheader lane is 72px. In the reverse composition, reserve its existing
    // 20px top/bottom input overhang from the flexible chart canvas instead of
    // extending the shared Mother Card below the SUM-derived frame.
    final chartHeight =
        geometry.zone2Bounds.height -
        BudgetTargetAvatarRail.selectedInputVerticalOverflow * 2;
    final chart = DashboardBounds(
      left: geometry.zone2Bounds.left,
      top: geometry.subheaderOneBounds.top,
      width: geometry.zone2Bounds.width,
      height: chartHeight,
    );
    final avatars = DashboardBounds(
      left: geometry.subheaderOneBounds.left,
      top: chart.bottom + gap,
      width: geometry.subheaderOneBounds.width,
      height: geometry.subheaderOneBounds.height,
    );
    return _BudgetSectionLayout(avatarBounds: avatars, chartBounds: chart);
  }

  CascadedCardMotion motionFor(
    CascadedCardMotion motion, {
    required DashboardBounds from,
    required DashboardBounds to,
  }) => CascadedCardMotion(
    top: motion.top + to.top - from.top,
    left: motion.left,
    right: motion.right,
    opacity: motion.opacity,
    scale: motion.scale,
    progress: motion.progress,
  );
}

/// Budget-local relationship adapter. It deliberately leaves [avatarBounds]
/// untouched for every variant: only Card2's physical relationship changes.
@immutable
final class BudgetAvatarContentRelationship {
  const BudgetAvatarContentRelationship({
    required this.avatarBounds,
    required this.chartBounds,
  });

  static const double _overlapShift = 28;

  final DashboardBounds avatarBounds;
  final DashboardBounds chartBounds;

  static BudgetAvatarContentRelationship resolve({
    required DashboardBounds avatarBounds,
    required DashboardBounds chartBounds,
    required BudgetAvatarContentStyle style,
    required bool avatarsLeadContent,
  }) {
    // The current default ordering is Avatar -> Card2. In the optional reverse
    // order the selected target is intentionally below Card2, so forcing a
    // top-edge overlap would invert that separate user composition. Keep that
    // non-default topology safe.
    final movesCard =
        style == BudgetAvatarContentStyle.overlappingGlow && avatarsLeadContent;
    if (!movesCard) {
      return BudgetAvatarContentRelationship(
        avatarBounds: avatarBounds,
        chartBounds: chartBounds,
      );
    }
    DashboardBounds shiftUp(DashboardBounds bounds) => DashboardBounds(
      left: bounds.left,
      top: bounds.top - _overlapShift,
      width: bounds.width,
      height: bounds.height,
    );
    return BudgetAvatarContentRelationship(
      avatarBounds: avatarBounds,
      chartBounds: shiftUp(chartBounds),
    );
  }
}

/// A soft selector surface placed behind the unchanged avatar carousel. The
/// selected 112px shell already extends much farther above this 52px rail than
/// its neighbours, so it visibly pops out without a second carousel or any
/// avatar translation.
final class _BudgetAvatarRailBackplate extends StatelessWidget {
  const _BudgetAvatarRailBackplate();

  @override
  Widget build(BuildContext context) => SizedBox.expand(
    child: Center(
      child: FractionallySizedBox(
        widthFactor: .94,
        heightFactor: .72,
        child: FluviRoundedBox(
          key: const ValueKey('budget-avatar-content-rail-surface'),
          color: Colors.white.withValues(alpha: .88),
          borderRadius: BorderRadius.circular(26),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: FluviVisualTokens.textPrimary.withValues(alpha: .06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
          child: const SizedBox.expand(),
        ),
      ),
    ),
  );
}

final class BudgetHeaderAllocationDetail extends StatelessWidget {
  const BudgetHeaderAllocationDetail({
    super.key,
    required this.partition,
    required this.thickness,
  });

  final DashboardBudgetPartitionPresentation partition;
  final double thickness;

  @override
  Widget build(BuildContext context) {
    final profile = DashboardBudgetHeaderPresentationScope.profileOf(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            DashboardHeaderContrastText(
              data: _allocationLabel(partition),
              key: const ValueKey('budget-header-allocation-percent'),
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              foreground: profile.foreground.withValues(alpha: .78),
              contrastStyle: profile.settings.textContrastStyle,
            ),
            DashboardHeaderContrastText(
              data: _remainingStatusLabel(partition),
              key: const ValueKey('budget-header-remaining-status'),
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700),
              foreground: profile.foreground.withValues(alpha: .78),
              contrastStyle: profile.settings.textContrastStyle,
            ),
          ],
        ),
        const SizedBox(height: 4),
        SizedBox(
          height: thickness,
          width: double.infinity,
          child: BudgetAllocationPartitionLane(partition: partition),
        ),
      ],
    );
  }

  static String _allocationLabel(DashboardBudgetPartitionPresentation value) {
    if (!value.hasPositiveAggregateLimit) return '—';
    final percentage = value.allocationRawRatio * 100;
    final decimal = percentage == percentage.roundToDouble()
        ? percentage.toStringAsFixed(0)
        : percentage.toStringAsFixed(1);
    return '$decimal% lefoglalva';
  }

  static String _remainingStatusLabel(
    DashboardBudgetPartitionPresentation value,
  ) {
    final limit = value.effectiveAggregateLimitScaled100;
    final actual = value.aggregateActualScaled100;
    if (limit == null || limit <= 0 || actual == null) return '—';
    final remaining = limit - actual;
    final amount = DashboardPreparedFormatter.amountMinor(remaining.abs());
    return remaining >= 0 ? '$amount maradt' : '$amount túlköltés';
  }
}
