import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/catalog/category_color_catalog.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_event.dart';
import '../../../../core/diagnostics/fluvi_diagnostic_logger.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_spending_rhythm_controller.dart';
import '../../application/dashboard_budget_logbox_drilldown_coordinator.dart';
import '../../application/dashboard_budget_partner_distribution_controller.dart';
import '../../application/dashboard_ephemeral_focus_controller.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_distribution_page_surface.dart';
import 'spending_rhythm_bar_chart.dart';
import 'budget_clay_donut_scene.dart';
import 'budget_partner_distribution_visual_bank.dart';
import 'budget_partner_visual_intent.dart';
import '../dashboard_upper_vertical_gesture_coordinator.dart';

typedef BudgetPartnerFocusCommit =
    Future<bool> Function({
      required DashboardFocusFacet partner,
      required String source,
      required int targetHandle,
    });

/// Pure vertical allocation for the Partner-only Card2 composition. The
/// Rhythm footer receives its meaningful plot lane first; donut and legend
/// intentionally consume only the remaining upper section. Category Card2
/// does not use this resolver.
@immutable
final class BudgetPartnerDistributionLayout {
  const BudgetPartnerDistributionLayout._({
    required this.rhythmFooterHeight,
    required this.plotLaneHeight,
    required this.upperSectionHeight,
    required this.donutDiameter,
    required this.legendRowHeight,
  });

  // At the 217dp reference Card2, the extra 4.4dp belongs to Rhythm, leaving
  // the Partner donut at 101.6dp. The list remains the flexible consumer.
  static const double dividerGap = 2;
  static const double upperDonutBreathingRoom = 0;
  static const double targetDonutDiameter = 120;
  // These are the previous accepted plot allocations. Resolve that exact
  // baseline first, then scale the *actual* allocation by 1.10 so the new
  // Rhythm lane takes space only from the upper Partner region at every
  // reference Card2 geometry.
  static const double preferredDonutDiameter = 105;
  static const double compactLegendRowHeight = 20;
  static const double _previousMinimumPlotLaneHeight = 35.2;
  static const double _previousTargetPlotLaneHeight = 44;
  static const double _rhythmPlotScale = 1.10;

  final double rhythmFooterHeight;
  final double plotLaneHeight;
  final double upperSectionHeight;
  final double donutDiameter;
  final double legendRowHeight;

  factory BudgetPartnerDistributionLayout.resolve({
    required Size availableSize,
  }) {
    final contentHeight =
        (availableSize.height -
                BudgetDistributionPageSurface.outerPadding * 2 -
                BudgetDistributionPageSurface.headingHeight)
            .clamp(0.0, double.infinity)
            .toDouble();
    const nonPlotHeight =
        SpendingRhythmBarChart.titleLaneHeight +
        SpendingRhythmBarChart.titleToPlotGap +
        SpendingRhythmBarChart.plotToAxisGap +
        SpendingRhythmBarChart.axisLaneHeight;
    final previousPlotBudget =
        (contentHeight - dividerGap - preferredDonutDiameter - nonPlotHeight)
            .clamp(
              _previousMinimumPlotLaneHeight,
              _previousTargetPlotLaneHeight,
            )
            .toDouble();
    final plotBudget = previousPlotBudget * _rhythmPlotScale;
    final footerHeight = nonPlotHeight + plotBudget;
    final upperHeight = (contentHeight - dividerGap - footerHeight)
        .clamp(0.0, double.infinity)
        .toDouble();
    final donutDiameter = (upperHeight - upperDonutBreathingRoom)
        .clamp(0.0, targetDonutDiameter)
        .toDouble();
    return BudgetPartnerDistributionLayout._(
      rhythmFooterHeight: footerHeight,
      plotLaneHeight: plotBudget,
      upperSectionHeight: upperHeight,
      donutDiameter: donutDiameter,
      legendRowHeight: compactLegendRowHeight,
    );
  }
}

/// Partner page for Budget Card2. It renders the exact prepared target frame
/// and forwards only explicit partner intents to the existing ephemeral-focus
/// owner; it owns neither Query nor Budget-target selection.
class BudgetPartnerDistributionCard extends StatefulWidget {
  const BudgetPartnerDistributionCard({
    super.key,
    required this.presentation,
    required this.drawableFrames,
    this.expandDonutToFit = false,
    this.rhythm,
    this.drilldown,
    this.partnerFocusCommit,
    this.focusController,
    this.upperVerticalGestures,
  });

  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;
  final bool expandDonutToFit;
  final ValueListenable<DashboardSpendingRhythmState?>? rhythm;
  final DashboardBudgetLogboxDrilldownCoordinator? drilldown;

  /// Narrow test/presentation seam. Production takes the existing
  /// [drilldown] path; this callback never replaces Core focus ownership.
  @visibleForTesting
  final BudgetPartnerFocusCommit? partnerFocusCommit;

  /// Production reads `drilldown.core.focus`. A direct injected owner lets
  /// focused widget tests verify acknowledgement without a repository setup.
  @visibleForTesting
  final DashboardEphemeralFocusController? focusController;
  final DashboardUpperVerticalGestureCoordinator? upperVerticalGestures;

  @override
  State<BudgetPartnerDistributionCard> createState() =>
      _BudgetPartnerDistributionCardState();
}

class _BudgetPartnerDistributionCardState
    extends State<BudgetPartnerDistributionCard> {
  late LedgerDirection _direction;
  late int _targetHandle;
  DashboardEphemeralFocusController? _focus;
  final BudgetPartnerVisualIntentController _visualIntents =
      BudgetPartnerVisualIntentController();
  Stopwatch? _pendingVisualStopwatch;

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
      _clearPendingVisualIntent();
    }
    if (!identical(oldWidget.drawableFrames, widget.drawableFrames)) {
      oldWidget.drawableFrames.removeListener(_onDrawableChanged);
      widget.drawableFrames.addListener(_onDrawableChanged);
      _clearPendingVisualIntent();
    }
    if (!identical(oldWidget.drilldown, widget.drilldown) ||
        !identical(oldWidget.focusController, widget.focusController)) {
      _detachFocus(
        oldWidget.focusController ?? oldWidget.drilldown?.core.focus,
      );
      _attachFocus();
      _clearPendingVisualIntent();
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
    _invalidatePendingVisualIntent();
    if (mounted) setState(() {});
  }

  void _onDrawableChanged() {
    _invalidatePendingVisualIntent();
    if (mounted) setState(() {});
  }

  void _attachFocus() {
    final next = widget.focusController ?? widget.drilldown?.core.focus;
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
    _acknowledgePendingVisualIntent();
    if (mounted) setState(() {});
  }

  bool get _canCommitPartner =>
      widget.partnerFocusCommit != null || widget.drilldown != null;

  _PartnerVisualContext? _activeVisualContext() {
    final drawable = widget.drawableFrames.value;
    final bank = drawable?.partnerVisualBank;
    final semantic = drawable?.partnerSemanticBundle;
    if (drawable == null || bank == null || semantic == null) return null;
    try {
      final frame = bank.frameFor(_direction, targetHandle: _targetHandle);
      return _PartnerVisualContext(
        identity: BudgetPartnerVisualIdentity(
          coreRevision: semantic.key.coreRevision,
          direction: _direction,
          targetHandle: _targetHandle,
          analysisScope: semantic.analysisScope,
        ),
        frame: frame,
      );
    } on RangeError {
      return null;
    }
  }

  void _invalidatePendingVisualIntent() {
    final context = _activeVisualContext();
    final cleared = context == null
        ? _visualIntents.clear()
        : _visualIntents.invalidateIfIncompatible(
            identity: context.identity,
            availablePartnerIds: <String>{
              for (final entry in context.frame.semanticFrame.entries)
                entry.partnerId,
            },
          );
    if (cleared) _pendingVisualStopwatch = null;
  }

  void _clearPendingVisualIntent() {
    if (_visualIntents.clear()) _pendingVisualStopwatch = null;
  }

  void _acknowledgePendingVisualIntent() {
    final context = _activeVisualContext();
    if (context == null) return;
    final pending = _visualIntents.pending;
    if (pending == null ||
        !_visualIntents.acknowledge(
          identity: context.identity,
          authoritativePartner: _focus?.state?.partner,
        )) {
      return;
    }
    final elapsed = _pendingVisualStopwatch?.elapsedMicroseconds;
    _pendingVisualStopwatch = null;
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PARTNER_VISUAL_ACKNOWLEDGED',
        scope:
            'partnerId=${pending.partner.id} generation=${pending.generation} '
            'intentToAuthoritativeMicros=${elapsed ?? '-'}',
      ),
    );
  }

  void _selectPartner(
    DashboardBudgetPartnerDistributionEntry entry, {
    required String source,
  }) {
    if (!_canCommitPartner) return;
    final context = _activeVisualContext();
    if (context == null) return;
    final partner = DashboardFocusFacet(
      id: entry.partnerId,
      displayName: entry.title,
      colorId: entry.colorId,
    );
    final intent = _visualIntents.begin(
      partner: partner,
      identity: context.identity,
    );
    _pendingVisualStopwatch = Stopwatch()..start();
    FluviDiagnosticLogger.log(
      FluviDiagnosticEvent(
        stage: 'BUDGET_PARTNER_VISUAL_INTENT',
        coreRevision: context.identity.coreRevision,
        scope:
            'source=$source partnerId=${partner.id} '
            'targetHandle=${context.identity.targetHandle} '
            'analysisScope=${context.identity.analysisScope.canonicalKey} '
            'visualGeneration=${intent.generation}',
      ),
    );
    setState(() {});
    unawaited(_completePartnerSelection(intent, source: source));
  }

  Future<void> _completePartnerSelection(
    BudgetPartnerVisualIntent intent, {
    required String source,
  }) async {
    final accepted = await _commitPartner(
      partner: intent.partner,
      source: source,
      targetHandle: intent.identity.targetHandle,
    );
    if (!mounted) return;
    if (_visualIntents.complete(
      generation: intent.generation,
      accepted: accepted,
    )) {
      _pendingVisualStopwatch = null;
      setState(() {});
      return;
    }
    _acknowledgePendingVisualIntent();
    if (mounted) setState(() {});
  }

  Future<bool> _commitPartner({
    required DashboardFocusFacet partner,
    required String source,
    required int targetHandle,
  }) {
    final override = widget.partnerFocusCommit;
    if (override != null) {
      return override(
        partner: partner,
        source: source,
        targetHandle: targetHandle,
      );
    }
    final drilldown = widget.drilldown;
    if (drilldown == null) return Future<bool>.value(false);
    return drilldown.commitPartner(
      source: source,
      targetHandle: targetHandle,
      partner: partner,
    );
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
    final context = _activeVisualContext();
    final selectedPartner = context == null
        ? _focus?.state?.partner
        : _visualIntents.effectivePartner(
            identity: context.identity,
            availablePartnerIds: <String>{
              for (final entry in frame.entries) entry.partnerId,
            },
            authoritativePartner: _focus?.state?.partner,
          );
    final selectedPartnerId = selectedPartner?.id;
    Widget surface(BudgetPartnerDistributionLayout layout) =>
        BudgetDistributionPageSurface(
          heading: const _PartnerDistributionHeading(),
          donut: _InteractivePartnerDistributionDonut(
            scene: visualFrame.scene,
            selectedSliceIndex: visualFrame.selectedSliceIndexForPartnerId(
              selectedPartnerId,
            ),
            absentSelectionLabel: selectedPartnerId == null
                ? null
                : selectedPartner?.displayName,
            onSliceTap: (index) {
              if (index < 0 || index >= frame.entries.length) return;
              _selectPartner(frame.entries[index], source: 'partnerPie');
            },
          ),
          rightHeading: 'Partnerek',
          listKey: const ValueKey('budget-partner-distribution-list'),
          emptyLabel: 'Nincs partner',
          upperVerticalGestures: widget.upperVerticalGestures,
          rows: _legendRows(
            frame.entries,
            selectedPartnerId,
            height: layout.legendRowHeight,
          ),
          donutDiameter: layout.donutDiameter,
          donutScale: 1,
          expandDonutToFit: widget.expandDonutToFit,
          fullWidthFooterDividerGap: BudgetPartnerDistributionLayout.dividerGap,
          donutVerticalInset:
              BudgetPartnerDistributionLayout.upperDonutBreathingRoom,
          fullWidthFooterMinimumHeight: layout.rhythmFooterHeight,
          fullWidthFooter: widget.rhythm == null
              ? null
              : ValueListenableBuilder<DashboardSpendingRhythmState?>(
                  valueListenable: widget.rhythm!,
                  builder: (context, rhythm, child) => rhythm == null
                      ? const SizedBox.shrink()
                      : SpendingRhythmBarChart(
                          key: const ValueKey('partner-spending-rhythm-chart'),
                          state: rhythm,
                        ),
                ),
        );
    // The authored no-Rhythm test/skeleton path remains unchanged. Production
    // Partner Card2 always supplies Rhythm and therefore reserves its plot
    // lane before assigning the upper donut/list space.
    if (widget.rhythm == null) {
      return BudgetDistributionPageSurface(
        heading: const _PartnerDistributionHeading(),
        donut: _InteractivePartnerDistributionDonut(
          scene: visualFrame.scene,
          selectedSliceIndex: visualFrame.selectedSliceIndexForPartnerId(
            selectedPartnerId,
          ),
          absentSelectionLabel: selectedPartnerId == null
              ? null
              : selectedPartner?.displayName,
          onSliceTap: (index) {
            if (index < 0 || index >= frame.entries.length) return;
            _selectPartner(frame.entries[index], source: 'partnerPie');
          },
        ),
        rightHeading: 'Partnerek',
        listKey: const ValueKey('budget-partner-distribution-list'),
        emptyLabel: 'Nincs partner',
        upperVerticalGestures: widget.upperVerticalGestures,
        rows: _legendRows(frame.entries, selectedPartnerId),
        donutDiameter: 150,
        donutScale: .90,
        expandDonutToFit: widget.expandDonutToFit,
      );
    }
    return LayoutBuilder(
      builder: (context, constraints) => surface(
        BudgetPartnerDistributionLayout.resolve(
          availableSize: constraints.biggest,
        ),
      ),
    );
  }

  List<Widget> _legendRows(
    List<DashboardBudgetPartnerDistributionEntry> entries,
    String? selectedPartnerId, {
    double height = 22,
  }) => <Widget>[
    for (final entry in entries)
      BudgetDistributionLegendRow(
        key: ValueKey('budget-partner-distribution-row-${entry.partnerId}'),
        id: entry.partnerId,
        title: entry.title,
        color: CategoryColorCatalog.resolve(entry.colorId).middleColor,
        roundedPercent: entry.roundedPercent,
        selected: entry.partnerId == selectedPartnerId,
        height: height,
        stateKey: ValueKey(
          'budget-partner-distribution-row-'
          '${entry.partnerId == selectedPartnerId ? 'selected' : 'idle'}-'
          '${entry.partnerId}',
        ),
        onTap: _canCommitPartner
            ? () => _selectPartner(entry, source: 'partnerList')
            : null,
      ),
  ];
}

final class _PartnerVisualContext {
  const _PartnerVisualContext({required this.identity, required this.frame});

  final BudgetPartnerVisualIdentity identity;
  final DashboardBudgetPartnerDistributionVisualFrame frame;
}

class _InteractivePartnerDistributionDonut extends StatelessWidget {
  const _InteractivePartnerDistributionDonut({
    required this.scene,
    required this.selectedSliceIndex,
    required this.absentSelectionLabel,
    required this.onSliceTap,
  });

  final BudgetClayDonutScene scene;
  final int selectedSliceIndex;
  final String? absentSelectionLabel;
  final ValueChanged<int> onSliceTap;

  @override
  Widget build(BuildContext context) => Stack(
    fit: StackFit.expand,
    children: <Widget>[
      RepaintBoundary(
        child: BudgetClayDonutView(
          key: ValueKey(
            'budget-partner-distribution-clay-scene-$selectedSliceIndex',
          ),
          scene: scene,
          selectedSliceIndex: selectedSliceIndex,
          absentSelectionLabel: absentSelectionLabel,
        ),
      ),
      Positioned.fill(
        child: GestureDetector(
          key: const ValueKey('budget-partner-distribution-donut-interaction'),
          behavior: HitTestBehavior.translucent,
          onTapUp: (details) {
            final renderBox = context.findRenderObject() as RenderBox?;
            if (renderBox == null) return;
            final target = scene.hitTest(
              localPosition: details.localPosition,
              size: renderBox.size,
            );
            if (target.target == BudgetClayDonutTapTarget.slice &&
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
