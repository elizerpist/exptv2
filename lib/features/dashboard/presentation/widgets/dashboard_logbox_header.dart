import 'dart:developer' as developer;

import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_layout_frame.dart';
import '../../../../core/design/fluvi_rounded_box.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../application/dashboard_performance_counters.dart';
import '../../query/application/current_query_controller.dart';
import '../../visible/application/dashboard_visible_frame_store.dart';
import '../../visible/domain/dashboard_visible_frame.dart';
import 'dashboard_query_facet_chips.dart';

/// Stable Ledger chrome above the sole LogBox scroll surface.
///
/// The committed count binds one complete frame, so it retains the same
/// Query/revision identity as the LogBoxes below. The SummaryPill remains the
/// sole visible transaction-result amount during this staged migration.
final class DashboardLogBoxHeader extends StatelessWidget {
  const DashboardLogBoxHeader({
    super.key,
    required this.bounds,
    required this.visibleFrames,
    this.performanceCounters,
    this.currentQuery,
    this.onRemoveCategory,
    this.onRemovePartner,
    this.onClear,
    this.focus,
    this.onClearFocusCategory,
    this.onClearFocusPartner,
    this.onClearFocus,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;
  final CurrentQueryController? currentQuery;
  final ValueChanged<String>? onRemoveCategory;
  final ValueChanged<String>? onRemovePartner;
  final VoidCallback? onClear;
  final DashboardEphemeralFocusController? focus;
  final VoidCallback? onClearFocusCategory;
  final VoidCallback? onClearFocusPartner;
  final VoidCallback? onClearFocus;

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
              performanceCounters: performanceCounters,
            ),
            if (currentQuery != null &&
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
                  onClearFocus: onClearFocus,
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
    required this.performanceCounters,
  });

  final DashboardBounds bounds;
  final DashboardVisibleFrameStore visibleFrames;
  final DashboardPerformanceCounters? performanceCounters;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<DashboardVisibleFrame?>(
      valueListenable: visibleFrames,
      builder: (context, frame, _) {
        final measure = performanceCounters?.measuresDurations ?? false;
        final started = measure ? developer.Timeline.now : 0;
        performanceCounters?.increment(DashboardPerformanceMetric.countBuild);
        final scale = bounds.height / DashboardLogBoxTokens.summaryHeaderHeight;
        final count = frame?.count.formattedEntryCount ?? '0';
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
                child: Semantics(
                  label: '$count tranzakció listázva',
                  child: ExcludeSemantics(
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        horizontal:
                            FluviVisualTokens.controlHorizontalInset * scale,
                      ),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '$count tranzakció listázva',
                          key: const ValueKey('dashboard-logbox-entry-count'),
                          maxLines: 1,
                          style: FluviVisualTokens.logBoxHeaderTextStyle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              SizedBox(
                height: DashboardLogBoxTokens.ledgerCountToSearchGap * scale,
              ),
              SizedBox(
                height: DashboardLogBoxTokens.ledgerSearchPillHeight * scale,
                width: double.infinity,
                child: _DashboardLogBoxSearchPill(scale: scale),
              ),
              SizedBox(
                height: DashboardLogBoxTokens.ledgerSearchToListGap * scale,
              ),
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

/// Presentation scaffold for a later dedicated transaction-search flow.
///
/// It intentionally owns no editable state or query action: the existing
/// Query Menu search edits a different draft-note field and must not be wired
/// into the committed Ledger pipeline here.
final class _DashboardLogBoxSearchPill extends StatelessWidget {
  const _DashboardLogBoxSearchPill({required this.scale});

  final double scale;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      key: const ValueKey('dashboard-logbox-search-pill'),
      button: true,
      enabled: false,
      label: 'Keresés a tranzakciókban. A keresés hamarosan elérhető.',
      child: ExcludeSemantics(
        child: FluviRoundedBox(
          color: FluviVisualTokens.surface,
          border: Border.all(color: FluviVisualTokens.border),
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
                Expanded(
                  child: FittedBox(
                    alignment: Alignment.centerLeft,
                    fit: BoxFit.scaleDown,
                    child: Text(
                      'Keresés a tranzakciókban',
                      maxLines: 1,
                      style: FluviVisualTokens.logBoxSearchTextStyle.copyWith(
                        fontSize: FluviVisualTokens.bodyFontSize * scale,
                      ),
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
