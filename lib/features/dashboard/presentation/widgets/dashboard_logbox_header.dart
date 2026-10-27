import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/dashboard_border_profile.dart';
import '../../../../core/design/dashboard_corner_profile.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../query/application/current_query_controller.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_query_facet_chips.dart';
import '../dashboard_corner_roundness.dart';
import '../dashboard_shadow_style.dart';
import '../dashboard_border_style.dart';
import '../dashboard_logbox_search_pill_visibility.dart';

/// Stable Ledger chrome above the sole LogBox scroll surface.
///
/// The typed count lane binds the same complete accepted projection as the
/// LogBoxes below. During a live interaction it intentionally remains on the
/// exact Phase-A preview while the structural frame stays committed; matching
/// canonical publication then reconciles the lane without a header-only
/// rollback. The SummaryPill remains the sole visible transaction-result
/// amount during this staged migration.
final class DashboardLogBoxHeader extends StatelessWidget {
  const DashboardLogBoxHeader({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    this.layoutScale,
    this.showsSearchPill = true,
    this.performanceCounters,
    this.currentQuery,
    this.onRemoveCategory,
    this.onRemovePartner,
    this.onClear,
    this.focus,
    this.onClearFocusCategory,
    this.onClearFocusPartner,
    this.onClearFocusSearch,
    this.onClearFocus,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onOpenQueryMenu,
    this.showExternalFacets = true,
    this.showInsideFacets = false,
    this.queryFacetStyle = DashboardQueryFacetPillStyle.current,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final double? layoutScale;
  final bool showsSearchPill;
  final DashboardPerformanceCounters? performanceCounters;
  final CurrentQueryController? currentQuery;
  final ValueChanged<String>? onRemoveCategory;
  final ValueChanged<String>? onRemovePartner;
  final VoidCallback? onClear;
  final DashboardEphemeralFocusController? focus;
  final VoidCallback? onClearFocusCategory;
  final VoidCallback? onClearFocusPartner;
  final VoidCallback? onClearFocusSearch;
  final VoidCallback? onClearFocus;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onOpenQueryMenu;
  final bool showExternalFacets;
  final bool showInsideFacets;
  final DashboardQueryFacetPillStyle queryFacetStyle;

  @override
  Widget build(BuildContext context) {
    performanceCounters?.increment(
      DashboardPerformanceMetric.headerSubtreeBuild,
    );
    return RepaintBoundary(
      key: const ValueKey('dashboard-logbox-header-repaint-boundary'),
      child: SizedBox(
        key: const ValueKey('dashboard-logbox-header'),
        width: bounds.width,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _DashboardLedgerHeaderControls(
              bounds: bounds,
              visibleFrames: visibleFrames,
              layoutScale: layoutScale,
              showsSearchPill: showsSearchPill,
              performanceCounters: performanceCounters,
              searchController: searchController,
              searchFocusNode: searchFocusNode,
              onSearchChanged: onSearchChanged,
              onOpenQueryMenu: onOpenQueryMenu,
              insideFacetChips:
                  showInsideFacets &&
                      currentQuery != null &&
                      onRemoveCategory != null &&
                      onRemovePartner != null &&
                      onClear != null
                  ? DashboardQueryFacetChips(
                      currentQuery: currentQuery!,
                      visibleFrames: visibleFrames,
                      focus: focus,
                      onRemoveCategory: onRemoveCategory!,
                      onRemovePartner: onRemovePartner!,
                      onClear: onClear!,
                      onClearFocusCategory: onClearFocusCategory,
                      onClearFocusPartner: onClearFocusPartner,
                      onClearFocusSearch: onClearFocusSearch,
                      onClearFocus: onClearFocus,
                      style: queryFacetStyle,
                      compact: true,
                      showSearchFacet: false,
                    )
                  : null,
            ),
            if (showExternalFacets &&
                currentQuery != null &&
                onRemoveCategory != null &&
                onRemovePartner != null &&
                onClear != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: DashboardQueryFacetChips(
                  currentQuery: currentQuery!,
                  visibleFrames: visibleFrames,
                  focus: focus,
                  onRemoveCategory: onRemoveCategory!,
                  onRemovePartner: onRemovePartner!,
                  onClear: onClear!,
                  onClearFocusCategory: onClearFocusCategory,
                  onClearFocusPartner: onClearFocusPartner,
                  onClearFocusSearch: onClearFocusSearch,
                  onClearFocus: onClearFocus,
                  style: queryFacetStyle,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

final class _DashboardLedgerHeaderControls extends StatelessWidget {
  const _DashboardLedgerHeaderControls({
    required this.bounds,
    required this.visibleFrames,
    this.layoutScale,
    required this.showsSearchPill,
    required this.performanceCounters,
    this.searchController,
    this.searchFocusNode,
    this.onSearchChanged,
    this.onOpenQueryMenu,
    this.insideFacetChips,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final double? layoutScale;
  final bool showsSearchPill;
  final DashboardPerformanceCounters? performanceCounters;
  final TextEditingController? searchController;
  final FocusNode? searchFocusNode;
  final ValueChanged<String>? onSearchChanged;
  final VoidCallback? onOpenQueryMenu;
  final Widget? insideFacetChips;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardVisibleFrame?>(
      valueListenable: visibleFrames.countLane,
      builder: (context, frame, _) {
        final measure = performanceCounters?.measuresDurations ?? false;
        final started = measure ? developer.Timeline.now : 0;
        performanceCounters?.increment(DashboardPerformanceMetric.countBuild);
        final scale =
            layoutScale ??
            bounds.height / DashboardLogBoxTokens.summaryHeaderHeight;
        // Pending ghosts are deliberately excluded from the financial count,
        // but they are real rows in this LogBox projection. The header says
        // "listázva", so it must reflect the display cardinality rather than
        // the booked-only summary count.
        final count = frame?.presentationEntryCount.toString() ?? '0';
        final result = SizedBox(
          height: bounds.height,
          child: Column(
            children: [
              SizedBox(
                height: DashboardLogBoxTokens.ledgerHeaderTopInset * scale,
              ),
              SizedBox(
                height: DashboardLogBoxTokens.ledgerCountHeight * scale,
                width: double.infinity,
                child: Row(
                  children: [
                    Expanded(
                      child: Semantics(
                        label: '$count tranzakció listázva',
                        child: ExcludeSemantics(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal:
                                  FluviVisualTokens.controlHorizontalInset *
                                  scale,
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              alignment: Alignment.centerLeft,
                              child: Text(
                                '$count tranzakció listázva',
                                key: const ValueKey(
                                  'dashboard-logbox-entry-count',
                                ),
                                maxLines: 1,
                                style: FluviVisualTokens.logBoxHeaderTextStyle,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    if (!showsSearchPill && onOpenQueryMenu != null)
                      _DashboardLogBoxFilterButton(
                        scale: scale,
                        compact: true,
                        onTap: onOpenQueryMenu!,
                      ),
                  ],
                ),
              ),
              if (showsSearchPill) ...<Widget>[
                SizedBox(
                  height: DashboardLogBoxTokens.ledgerCountToSearchGap * scale,
                ),
                SizedBox(
                  height: DashboardLogBoxTokens.ledgerSearchPillHeight * scale,
                  width: double.infinity,
                  child: _DashboardLogBoxSearchAndFilterRow(
                    scale: scale,
                    bounds: bounds,
                    controller: searchController,
                    focusNode: searchFocusNode,
                    onChanged: onSearchChanged,
                    onOpenQueryMenu: onOpenQueryMenu,
                    insideFacetChips: insideFacetChips,
                  ),
                ),
                SizedBox(
                  height: DashboardLogBoxTokens.ledgerSearchToListGap * scale,
                ),
              ],
            ],
          ),
        );
        if (measure) {
          performanceCounters!.increment(
            DashboardPerformanceMetric.countBindMicros,
            by: developer.Timeline.now - started,
          );
        }
        return result;
      },
    );
  }
}

final class _DashboardLogBoxSearchAndFilterRow extends StatelessWidget {
  const _DashboardLogBoxSearchAndFilterRow({
    required this.scale,
    required this.bounds,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.onOpenQueryMenu,
    this.insideFacetChips,
  });

  final double scale;
  final DashboardBounds bounds;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final VoidCallback? onOpenQueryMenu;
  final Widget? insideFacetChips;

  @override
  Widget build(BuildContext context) => Row(
    // The fixed-height parent is the source of truth for both controls.  A
    // centered Row would let the SearchPill choose its intrinsic height while
    // the filter button fills the lane, making the controls look misaligned
    // and leaving a phantom gap before the LogBox list.
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Expanded(
        child: _DashboardLogBoxSearchPill(
          scale: scale,
          bounds: DashboardBounds(
            left: bounds.left,
            top: bounds.top,
            width: (bounds.width - 56 * scale)
                .clamp(0.0, bounds.width)
                .toDouble(),
            height: bounds.height,
          ),
          controller: controller,
          focusNode: focusNode,
          onChanged: onChanged,
          insideFacetChips: insideFacetChips,
        ),
      ),
      SizedBox(width: 8 * scale),
      _DashboardLogBoxFilterButton(scale: scale, onTap: onOpenQueryMenu),
    ],
  );
}

final class _DashboardLogBoxFilterButton extends StatelessWidget {
  const _DashboardLogBoxFilterButton({
    required this.scale,
    required this.onTap,
    this.compact = false,
  });
  final double scale;
  final VoidCallback? onTap;
  final bool compact;
  @override
  Widget build(BuildContext context) {
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.searchPill);
    final size = compact
        ? DashboardLogBoxTokens.ledgerCountHeight * scale
        : DashboardLogBoxTokens.ledgerSearchPillHeight * scale;
    return Semantics(
      button: true,
      label: 'Tranzakciók szűrése',
      child: SizedBox(
        key: const ValueKey('dashboard-logbox-filter-button'),
        width: compact ? size : 48 * scale,
        height: size,
        child: FluviRoundedBox(
          color: depth.surfaceColor ?? FluviVisualTokens.surface,
          border: DashboardBorderScope.profileOf(
            context,
          ).borderFor(DashboardBorderSurface.searchPill),
          borderRadius: BorderRadius.circular(14 * scale),
          boxShadow: depth.shadows,
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(14 * scale),
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(14 * scale),
              child: Icon(Icons.tune_rounded, size: 22 * scale),
            ),
          ),
        ),
      ),
    );
  }
}

final class _DashboardLogBoxSearchPill extends StatelessWidget {
  const _DashboardLogBoxSearchPill({
    required this.scale,
    required this.bounds,
    this.controller,
    this.focusNode,
    this.onChanged,
    this.insideFacetChips,
  });

  final double scale;
  final DashboardBounds bounds;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final ValueChanged<String>? onChanged;
  final Widget? insideFacetChips;

  @override
  Widget build(BuildContext context) {
    final depth = DashboardShadowStyleScope.profileOf(
      context,
    ).depthFor(DashboardCornerSurfaceFamily.searchPill);
    return Semantics(
      key: const ValueKey('dashboard-logbox-search-pill'),
      textField: controller != null,
      enabled: controller != null,
      label: 'Keresés a tranzakciókban',
      child: FluviRoundedBox(
        color: depth.surfaceColor ?? FluviVisualTokens.surface,
        border: DashboardBorderScope.profileOf(
          context,
        ).borderFor(DashboardBorderSurface.searchPill),
        borderRadius: DashboardCornerRoundnessScope.profileOf(context)
            .borderRadiusFor(
              DashboardCornerSurfaceFamily.searchPill,
              size: Size(
                bounds.width,
                DashboardLogBoxTokens.ledgerSearchPillHeight * scale,
              ),
            ),
        boxShadow: depth.shadows,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: FluviVisualTokens.controlHorizontalInset * scale,
          ),
          child: Row(
            children: [
              Icon(
                Icons.search_rounded,
                color: FluviVisualTokens.textSecondary,
                size: FluviVisualTokens.iconSize * scale,
              ),
              SizedBox(width: FluviVisualTokens.controlInnerGap * scale),
              if (insideFacetChips != null)
                SizedBox(
                  key: const ValueKey('dashboard-query-facets-inside-search'),
                  width: bounds.width * .43,
                  child: insideFacetChips,
                ),
              if (insideFacetChips != null)
                SizedBox(width: FluviVisualTokens.controlInnerGap * scale),
              Expanded(
                child: Material(
                  type: MaterialType.transparency,
                  child: TextField(
                    key: const ValueKey('dashboard-logbox-search-input'),
                    controller: controller,
                    focusNode: focusNode,
                    enabled: controller != null,
                    onChanged: onChanged,
                    onTapOutside: (_) => focusNode?.unfocus(),
                    maxLines: 1,
                    textAlignVertical: TextAlignVertical.center,
                    style: FluviVisualTokens.logBoxSearchTextStyle.copyWith(
                      fontSize: FluviVisualTokens.bodyFontSize * scale,
                    ),
                    decoration: InputDecoration(
                      isDense: true,
                      border: InputBorder.none,
                      hintText: 'Keresés a tranzakciókban',
                      hintStyle: FluviVisualTokens.logBoxSearchTextStyle
                          .copyWith(
                            fontSize: FluviVisualTokens.bodyFontSize * scale,
                          ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
