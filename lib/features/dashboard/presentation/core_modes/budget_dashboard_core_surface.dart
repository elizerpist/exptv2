import 'dart:async';

import 'package:flutter/foundation.dart'
    show ValueListenable, immutable, kDebugMode;
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
import '../budget_section_order.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';
import '../dashboard_budget_header_presentation.dart';
import 'budget_category_avatar_rail.dart';
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
                DashboardCoreModeCascadeCard(
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
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable:
                    contentCardStyle ?? _alwaysUnifiedBudgetContent,
                builder: (context, layout, _) => _BudgetUnifiedContentCard(
                  geometry: geometry,
                  section: section,
                  contentLayout: layout,
                  headerVisualFrame: headerVisualFrame,
                ),
              ),
              DashboardRenderDiagnosticProbe(
                candidate: 'budgetChartCascadeCard',
                material: 'contentOnly DashboardCoreModeCascadeCard',
                clip: 'none at cascade; child owns rounded viewport clip',
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
              ValueListenableBuilder<BudgetContentLayout>(
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
                  content: _avatarContent(),
                ),
              ),
              ValueListenableBuilder<BudgetContentLayout>(
                valueListenable:
                    contentCardStyle ?? _alwaysUnifiedBudgetContent,
                builder: (context, layout, _) {
                  final contentProgress = geometry.zone2Opacity
                      .clamp(0.0, 1.0)
                      .toDouble();
                  // The existing Budget cascade owns transitional motion. The
                  // shared shell exists only at its settled endpoint so it
                  // cannot become a full-height opaque slab while Card2 is
                  // still translating/scaling through the legacy path.
                  final isHeaderLinked =
                      layout == BudgetContentLayout.unifiedCard &&
                      contentProgress >= .999 &&
                      geometry.collapseProgress <= .001;
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
                    seamless: isHeaderLinked,
                    headerRadius: headerRadius,
                    contentRadius: contentRadius,
                    expansionProgress: contentProgress,
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
                    showsDepth: !isHeaderLinked,
                    showsBorder: !isHeaderLinked,
                    // The source title starts at x=20/y=16. Text keeps the
                    // existing tuner/menu clearance internally; the partition
                    // lane itself now owns equal 16px physical insets.
                    detailLeft: 16,
                    detailTop: 16,
                    detailRight: 16,
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
                                  const titleAndValueHeight = 36.0;
                                  final partitionHeight =
                                      13.0 + headerProfile.partitionThickness;
                                  final roomReveal =
                                      ((constraints.maxHeight -
                                                  titleAndValueHeight) /
                                              partitionHeight)
                                          .clamp(0.0, 1.0)
                                          .toDouble();
                                  final partitionReveal = expansion < roomReveal
                                      ? expansion
                                      : roomReveal;
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
                                            child:
                                                _BudgetHeaderAllocationDetail(
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
      rhythm: rhythm,
      drilldown: drilldown,
      upperVerticalGestures: upperVerticalGestures,
      surfaceOwner: surfaceOwner,
      topGlowColor: topGlowColor,
    );
  }

  Widget _avatarContent() => presentationController == null
      ? const SizedBox(key: ValueKey<String>('budget-target-avatar-rail'))
      : BudgetTargetAvatarRail(
          presentation: presentationController!,
          limitEditController: limitEditController,
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
        );

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

/// Unified Budget uses the same shared Header/content seam primitive as Mind.
/// It connects the existing physical bounds without changing Budget section
/// order, selected avatar, page-controller, query, or financial ownership.
final class _BudgetUnifiedContentCard extends StatelessWidget {
  const _BudgetUnifiedContentCard({
    required this.geometry,
    required this.section,
    required this.contentLayout,
    required this.headerVisualFrame,
  });

  final DashboardLayoutFrame geometry;
  final _BudgetSectionLayout section;
  final BudgetContentLayout contentLayout;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

  @override
  Widget build(BuildContext context) {
    if (contentLayout != BudgetContentLayout.unifiedCard) {
      return const SizedBox.shrink();
    }
    final contentProgress = geometry.zone2Opacity.clamp(0.0, 1.0).toDouble();
    // Preserve the proven Budget cascade during an in-flight collapse. The
    // linked Header/body physical shell is a settled presentation state; a
    // static combined rectangle during the existing transform would paint an
    // opaque slab across its otherwise transparent transition lane. Keeping
    // the surface mounted but transparent preserves the existing structural
    // topology and controller lifecycle until the settled shell takes over.
    final showsLinkedSurface =
        contentProgress >= .999 && geometry.collapseProgress <= .001;
    if (!showsLinkedSurface) {
      return _BudgetUnifiedTransitionSurface(
        geometry: geometry,
        section: section,
      );
    }
    final headerRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.header,
          size: Size(geometry.headerBounds.width, geometry.headerBounds.height),
        );
    final contentRadius = DashboardCornerRoundnessScope.profileOf(context)
        .borderRadiusFor(
          DashboardCornerSurfaceFamily.budgetDistributionCard,
          size: Size(
            geometry.modeContentBounds.width,
            geometry.modeContentBounds.height,
          ),
        );
    final seamShape = DashboardHeaderContentSeamShape.resolve(
      seamless: true,
      headerRadius: headerRadius,
      contentRadius: contentRadius,
      expansionProgress: 1,
    );
    final combinedBounds = DashboardHeaderContentMotherCardBounds.resolve(
      geometry: geometry,
    );
    final bridgeHeight =
        (geometry.modeContentBounds.top - geometry.headerBounds.bottom + 34)
            .clamp(0.0, combinedBounds.height - geometry.headerBounds.height)
            .toDouble();
    return DashboardCoreModeFramePosition(
      bounds: combinedBounds,
      child: Opacity(
        opacity: showsLinkedSurface ? 1 : 0,
        child: LayoutBuilder(
          builder: (context, _) => DashboardRenderDiagnosticProbe(
            candidate: 'budgetUnifiedHeaderContentSurface',
            material: 'surface=DashboardPlaceholderCard header+content',
            clip:
                'none; descendant BudgetDistributionCardShell owns viewport clip',
            zOrder: 'unifiedHeaderSurface<header<chartCascade<avatarCascade',
            child: DashboardPlaceholderCard(
              bounds: combinedBounds,
              fillParent: true,
              semanticKey: const ValueKey<String>(
                'budget-unified-header-content-surface',
              ),
              cornerFamily: DashboardCornerSurfaceFamily.budgetDistributionCard,
              borderSurface: DashboardBorderSurface.budgetContent,
              borderRadiusOverride: seamShape.outerRadius,
              child: _BudgetUnifiedHeaderContentBridge(
                headerHeight: geometry.headerBounds.height,
                bridgeHeight: bridgeHeight,
                headerVisualFrame: headerVisualFrame,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Keeps Budget's established lower-card cascade as the physical owner during
/// an in-flight collapse. The Header/content shell replaces it only at the
/// fully expanded unified endpoint, so a transparent parent never exposes an
/// unowned neutral slab between the two representations.
final class _BudgetUnifiedTransitionSurface extends StatelessWidget {
  const _BudgetUnifiedTransitionSurface({
    required this.geometry,
    required this.section,
  });

  final DashboardLayoutFrame geometry;
  final _BudgetSectionLayout section;

  @override
  Widget build(BuildContext context) {
    final bounds = geometry.modeContentBounds;
    final motion = section.motionFor(
      geometry.lowerCardMotion!,
      from: geometry.zone2Bounds,
      to: bounds,
    );
    return DashboardCoreModeOpacityPosition(
      bounds: bounds,
      opacity: motion.opacity,
      offset: Offset(0, motion.top - bounds.top),
      scale: motion.scale,
      child: DashboardRenderDiagnosticProbe(
        candidate: 'budgetUnifiedTransitionSurface',
        material: 'settledHeaderContentShell=off; lowerCascade=on',
        clip: 'none; descendant BudgetDistributionCardShell owns viewport clip',
        zOrder: 'transitionSurface<chartCascade<avatarCascade',
        child: DashboardPlaceholderCard(
          bounds: bounds,
          fillParent: true,
          semanticKey: const ValueKey<String>(
            'budget-unified-header-content-surface',
          ),
          cornerFamily: DashboardCornerSurfaceFamily.budgetDistributionCard,
          borderSurface: DashboardBorderSurface.budgetContent,
        ),
      ),
    );
  }
}

/// The shared card stays white like Budget's existing body. This shallow,
/// non-interactive bridge carries only a small amount of the live Header
/// colour past the radius-free seam, mirroring Mind's seamless language.
final class _BudgetUnifiedHeaderContentBridge extends StatelessWidget {
  const _BudgetUnifiedHeaderContentBridge({
    required this.headerHeight,
    required this.bridgeHeight,
    required this.headerVisualFrame,
  });

  final double headerHeight;
  final double bridgeHeight;
  final ValueListenable<DashboardHeaderVisualFrame>? headerVisualFrame;

  @override
  Widget build(BuildContext context) {
    final frames = headerVisualFrame;
    if (frames == null || bridgeHeight <= 0) return const SizedBox.expand();
    return Stack(
      fit: StackFit.expand,
      children: <Widget>[
        Positioned(
          left: 0,
          right: 0,
          top: headerHeight,
          height: bridgeHeight,
          child: IgnorePointer(
            child: ValueListenableBuilder<DashboardHeaderVisualFrame>(
              valueListenable: frames,
              builder: (context, frame, _) => DecoratedBox(
                key: const ValueKey('budget-unified-header-color-bleed'),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: <Color>[
                      frame.colorB.withValues(alpha: .14),
                      frame.colorA.withValues(alpha: .04),
                      Colors.white.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
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

final class _BudgetHeaderAllocationDetail extends StatelessWidget {
  const _BudgetHeaderAllocationDetail({
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
