import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/categories/presentation/budget_category_avatar_artwork.dart';
import '../../../../core/design/dashboard_mode_palette.dart';
import '../../../../core/financial_limits/presentation/budget_ring_presentation.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_secondary_analysis.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../query/domain/ledger_direction.dart';
import 'budget_category_distribution_visual_bank.dart';
import 'budget_clay_semicircle_gauge.dart';
import 'budget_content_title_layout.dart';

/// Third semantic page of the existing Budget distribution pager.
///
/// It owns no query, calculation or selection state. Its only mutable state is
/// the last complete atomic publication, retained while a newer scope is being
/// prepared by the existing drawable controller. This prevents a new title
/// from ever pairing with an older target's chart.
final class BudgetSecondaryAnalysisCard extends StatefulWidget {
  const BudgetSecondaryAnalysisCard({
    super.key,
    required this.presentation,
    required this.drawableFrames,
    this.analysisPageActive,
  });

  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;
  final ValueListenable<bool>? analysisPageActive;

  @override
  State<BudgetSecondaryAnalysisCard> createState() =>
      _BudgetSecondaryAnalysisCardState();
}

final class _RenderedAnalysisFrame {
  const _RenderedAnalysisFrame({
    required this.frame,
    required this.targetTitle,
    required this.scopeLabel,
    required this.targetVisual,
  });

  final DashboardBudgetSecondaryAnalysisFrame frame;
  final String targetTitle;
  final String scopeLabel;
  final DashboardBudgetTargetPresentationItem? targetVisual;
}

class _BudgetSecondaryAnalysisCardState
    extends State<BudgetSecondaryAnalysisCard> {
  _RenderedAnalysisFrame? _rendered;

  @override
  void initState() {
    super.initState();
    widget.presentation.addListener(_onSourceChanged);
    widget.drawableFrames.addListener(_onSourceChanged);
    _resolveAtomicFrame();
  }

  @override
  void didUpdateWidget(covariant BudgetSecondaryAnalysisCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.presentation, widget.presentation)) {
      oldWidget.presentation.removeListener(_onSourceChanged);
      widget.presentation.addListener(_onSourceChanged);
    }
    if (!identical(oldWidget.drawableFrames, widget.drawableFrames)) {
      oldWidget.drawableFrames.removeListener(_onSourceChanged);
      widget.drawableFrames.addListener(_onSourceChanged);
    }
    _resolveAtomicFrame();
  }

  @override
  void dispose() {
    widget.presentation.removeListener(_onSourceChanged);
    widget.drawableFrames.removeListener(_onSourceChanged);
    super.dispose();
  }

  void _onSourceChanged() {
    final changed = _resolveAtomicFrame();
    if (changed && mounted) {
      setState(() {});
    }
  }

  bool _resolveAtomicFrame() {
    final state = widget.presentation.value;
    final selection = state.liveSelection;
    final scope = state.liveAnalysis.scope;
    final revision = selection.coreRevision;
    final candidate = widget.drawableFrames.value?.analysisBank?.frameFor(
      direction: selection.direction,
      targetHandle: state.selectedHandle,
    );
    if (candidate == null ||
        scope == null ||
        revision == null ||
        !candidate.matches(
          coreRevision: revision,
          direction: selection.direction,
          targetHandle: state.selectedHandle,
          scope: scope,
        )) {
      return false;
    }
    final next = _RenderedAnalysisFrame(
      frame: candidate,
      targetTitle: selection.title,
      scopeLabel: selection.analysisScopeLabel,
      targetVisual: _targetVisualFor(state),
    );
    final old = _rendered;
    if (old != null &&
        identical(old.frame, next.frame) &&
        old.targetTitle == next.targetTitle &&
        old.scopeLabel == next.scopeLabel &&
        identical(old.targetVisual, next.targetVisual)) {
      return false;
    }
    _rendered = next;
    return true;
  }

  DashboardBudgetTargetPresentationItem? _targetVisualFor(
    DashboardBudgetPresentationState state,
  ) {
    for (final item in state.items) {
      if (item.target.handle == state.selectedHandle) return item;
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    _resolveAtomicFrame();
    final rendered = _rendered;
    if (rendered == null) {
      return const SizedBox.expand(
        key: ValueKey<String>('budget-secondary-analysis-preparing'),
      );
    }
    return BudgetSecondaryAnalysisPreparedCard(
      frame: rendered.frame,
      targetTitle: rendered.targetTitle,
      scopeLabel: rendered.scopeLabel,
      targetVisual: rendered.targetVisual,
      analysisPageActive: widget.analysisPageActive,
    );
  }
}

/// Paint-only entry point used by the production pager after its atomic frame
/// has been selected. It is intentionally useful to widget tests without
/// exposing any ledger/controller dependency.
final class BudgetSecondaryAnalysisPreparedCard extends StatefulWidget {
  const BudgetSecondaryAnalysisPreparedCard({
    super.key,
    required this.frame,
    required this.targetTitle,
    required this.scopeLabel,
    this.targetVisual,
    this.analysisPageActive,
  });

  final DashboardBudgetSecondaryAnalysisFrame frame;
  final String targetTitle;
  final String scopeLabel;
  final DashboardBudgetTargetPresentationItem? targetVisual;
  final ValueListenable<bool>? analysisPageActive;

  @override
  State<BudgetSecondaryAnalysisPreparedCard> createState() =>
      _BudgetSecondaryAnalysisPreparedCardState();
}

final class _BudgetSecondaryAnalysisPreparedCardState
    extends State<BudgetSecondaryAnalysisPreparedCard> {
  bool _detailsOpen = false;
  BudgetRingPresentationController? _ringPresentation;
  bool _showInfoCards = true;

  @override
  void initState() {
    super.initState();
    widget.analysisPageActive?.addListener(_closeDetailsWhenPageLeaves);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final next = BudgetRingPresentationScope.controllerOf(context);
    if (identical(next, _ringPresentation)) return;
    _ringPresentation?.removeListener(_onRingPresentationChanged);
    _ringPresentation = next;
    _ringPresentation?.addListener(_onRingPresentationChanged);
    _showInfoCards =
        _ringPresentation?.value.showBudgetAnalysisInfoCards ?? true;
  }

  @override
  void didUpdateWidget(
    covariant BudgetSecondaryAnalysisPreparedCard oldWidget,
  ) {
    super.didUpdateWidget(oldWidget);
    if (!identical(oldWidget.analysisPageActive, widget.analysisPageActive)) {
      oldWidget.analysisPageActive?.removeListener(_closeDetailsWhenPageLeaves);
      widget.analysisPageActive?.addListener(_closeDetailsWhenPageLeaves);
    }
    if (!_sameFrameIdentity(oldWidget.frame, widget.frame)) {
      _detailsOpen = false;
    }
  }

  @override
  void dispose() {
    widget.analysisPageActive?.removeListener(_closeDetailsWhenPageLeaves);
    _ringPresentation?.removeListener(_onRingPresentationChanged);
    super.dispose();
  }

  void _onRingPresentationChanged() {
    final next = _ringPresentation?.value.showBudgetAnalysisInfoCards ?? true;
    if (next == _showInfoCards) return;
    setState(() {
      _showInfoCards = next;
      if (next) _detailsOpen = false;
    });
  }

  void _closeDetailsWhenPageLeaves() {
    if ((widget.analysisPageActive?.value ?? true) || !_detailsOpen) return;
    if (mounted) setState(() => _detailsOpen = false);
  }

  bool _sameFrameIdentity(
    DashboardBudgetSecondaryAnalysisFrame left,
    DashboardBudgetSecondaryAnalysisFrame right,
  ) =>
      left.coreRevision == right.coreRevision &&
      left.direction == right.direction &&
      left.targetHandle == right.targetHandle &&
      left.scope == right.scope;

  @override
  Widget build(BuildContext context) {
    final payload = widget.frame.payload;
    final copy = _copyFor(payload);
    final showInfoCards = _showInfoCards;
    final kpis = _kpisFor(payload);
    return Semantics(
      label: '${widget.targetTitle}: ${copy.title}, ${widget.scopeLabel}',
      // The parent Card2 owns the one white analysis surface. In particular,
      // the footer has no painted slab: the gauge can visually continue into
      // the shared surface behind its three independent KPI cards.
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          12,
          BudgetContentTitleLayout.topInset,
          12,
          BudgetContentTitleLayout.bottomInset,
        ),
        child: Column(
          children: <Widget>[
            _AnalysisHeader(
              key: const ValueKey<String>(
                'budget-secondary-analysis-title-row',
              ),
              copy: copy,
              scopeLabel: widget.scopeLabel,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Semantics(
                button: !showInfoCards,
                toggled: !showInfoCards ? _detailsOpen : null,
                label: !showInfoCards ? 'Koppints a részletekhez' : null,
                child: GestureDetector(
                  behavior: HitTestBehavior.translucent,
                  onTap: showInfoCards
                      ? null
                      : () => setState(() => _detailsOpen = !_detailsOpen),
                  child: Stack(
                    fit: StackFit.expand,
                    children: <Widget>[
                      _Hero(
                        payload: payload,
                        direction: widget.frame.direction,
                        targetVisual: widget.targetVisual,
                      ),
                      if (!showInfoCards && _detailsOpen)
                        _AnalysisKpiPopup(kpis: kpis),
                    ],
                  ),
                ),
              ),
            ),
            // The hero owns one canonical viewport irrespective of the
            // optional KPI cards below it. Keeping this endpoint/footer lane
            // in both modes prevents the expanded hero from growing by 49 px
            // and pulling the shared SUM/MONTH gauge down with it.
            const SizedBox(height: 6),
            if (showInfoCards)
              SizedBox(
                key: const ValueKey<String>('budget-analysis-kpi-row'),
                height: 43,
                child: _KpiRow(kpis: kpis),
              )
            else
              const SizedBox(
                key: ValueKey<String>('budget-analysis-endpoint-lane'),
                height: 43,
              ),
          ],
        ),
      ),
    );
  }
}

final class _AnalysisCopy {
  const _AnalysisCopy({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  final String title;
  final String subtitle;
  final IconData icon;
}

_AnalysisCopy _copyFor(DashboardBudgetSecondaryAnalysisPayload payload) =>
    switch (payload) {
      DashboardBudgetSumAnalysis() => const _AnalysisCopy(
        title: 'Hosszú távú keretkihasználás',
        subtitle: 'Az összes vizsgált időszak átlaga',
        icon: Icons.donut_large_outlined,
      ),
      DashboardBudgetYearAnalysis() => const _AnalysisCopy(
        title: 'Havi eltérés a limittől',
        subtitle: 'Mennyivel tértél el havonta?',
        icon: Icons.bar_chart_rounded,
      ),
      DashboardBudgetMonthSecondaryAnalysis() => const _AnalysisCopy(
        title: 'Havi keretkihasználás',
        subtitle: 'Az aktuális hónap állása',
        icon: Icons.donut_large_outlined,
      ),
      DashboardBudgetDaySecondaryAnalysis() => const _AnalysisCopy(
        title: 'A mai költés hatása',
        subtitle: 'Hogyan változott a havi mozgástér?',
        icon: Icons.compare_arrows_rounded,
      ),
    };

final class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({
    super.key,
    required this.copy,
    required this.scopeLabel,
  });

  final _AnalysisCopy copy;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: Icon(
          copy.icon,
          size: 14,
          color: FluviVisualTokens.textSecondary,
        ),
      ),
      const SizedBox(width: 6),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              copy.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FluviVisualTokens.textPrimary,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                height: 1.1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              copy.subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 7.4,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
          ],
        ),
      ),
      const SizedBox(width: 6),
      Text(
        scopeLabel,
        key: const ValueKey<String>('budget-secondary-analysis-scope'),
        style: const TextStyle(
          color: FluviVisualTokens.textSecondary,
          fontSize: 8,
          fontWeight: FontWeight.w800,
          height: 1.1,
        ),
      ),
    ],
  );
}

final class _Hero extends StatelessWidget {
  const _Hero({
    required this.payload,
    required this.direction,
    required this.targetVisual,
  });

  final DashboardBudgetSecondaryAnalysisPayload payload;
  final LedgerDirection direction;
  final DashboardBudgetTargetPresentationItem? targetVisual;

  @override
  Widget build(BuildContext context) => switch (payload) {
    DashboardBudgetSumAnalysis() => _BudgetUtilizationHero(
      ratio: (payload as DashboardBudgetSumAnalysis).averageUtilization,
      secondaryLabel: 'átlagos keretkihasználás',
      gaugeKey: const ValueKey<String>('budget-analysis-sum-semicircle'),
      direction: direction,
      targetVisual: targetVisual,
    ),
    DashboardBudgetYearAnalysis() => _YearHero(
      payload: payload as DashboardBudgetYearAnalysis,
    ),
    DashboardBudgetMonthSecondaryAnalysis() => _MonthHero(
      payload: payload as DashboardBudgetMonthSecondaryAnalysis,
      direction: direction,
      targetVisual: targetVisual,
    ),
    DashboardBudgetDaySecondaryAnalysis() => _DayHero(
      payload: payload as DashboardBudgetDaySecondaryAnalysis,
    ),
  };
}

/// The SUM and MONTH adapters intentionally share one physical hero. Their
/// semantics differ, but the bounds, typography, marker, and material scene
/// are the same object at the same place in Card2.
final class _BudgetUtilizationHero extends StatelessWidget {
  const _BudgetUtilizationHero({
    required this.ratio,
    required this.secondaryLabel,
    required this.gaugeKey,
    required this.direction,
    required this.targetVisual,
  });
  final double? ratio;
  final String secondaryLabel;
  final Key gaugeKey;
  final LedgerDirection direction;
  final DashboardBudgetTargetPresentationItem? targetVisual;

  @override
  Widget build(BuildContext context) {
    final value = ratio;
    if (value == null) return const _UnavailableHero();
    final accent = BudgetClayGaugeAccentResolver.resolve(
      context,
      direction: direction,
      targetVisual: targetVisual,
    );
    return BudgetSemicircleGauge(
      key: gaugeKey,
      presentation: BudgetSemicircleMaterialPresentation.resolve(
        rawRatio: value,
        direction: direction,
        activeGradient: accent,
      ),
      primaryLabel: '${(value * 100).round()}%',
      secondaryLabel: secondaryLabel,
    );
  }
}

final class _YearHero extends StatelessWidget {
  const _YearHero({required this.payload});
  final DashboardBudgetYearAnalysis payload;

  @override
  Widget build(BuildContext context) {
    final settings = BudgetRingPresentationScope.settingsOf(context);
    final material = BudgetYearClayDeltaMaterial.resolve(
      showNeutralDecorativeStrip: settings.showBudgetNeutralDecorativeStrip,
      showActiveProgressDecorativeStrip:
          settings.showBudgetActiveProgressDecorativeStrip,
    );
    return Stack(
      children: <Widget>[
        Positioned.fill(
          child: RepaintBoundary(
            child: CustomPaint(
              key: const ValueKey<String>(
                'budget-analysis-year-zero-axis-bars',
              ),
              painter: _YearClayDeltaPainter(
                months: payload.months,
                material: material,
              ),
            ),
          ),
        ),
        Positioned(
          left: 0,
          right: 0,
          bottom: 0,
          child: Row(
            children: <Widget>[
              for (final label in _monthLabels)
                Expanded(
                  child: Text(
                    label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 5.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

final class _MonthHero extends StatelessWidget {
  const _MonthHero({
    required this.payload,
    required this.direction,
    required this.targetVisual,
  });
  final DashboardBudgetMonthSecondaryAnalysis payload;
  final LedgerDirection direction;
  final DashboardBudgetTargetPresentationItem? targetVisual;

  @override
  Widget build(BuildContext context) => BudgetMonthUtilizationHero(
    analysis: payload,
    direction: direction,
    targetVisual: targetVisual,
  );
}

/// Public MONTH adapter for any exact-month Budget surface.
///
/// This is intentionally the physical object used by the secondary analysis
/// card, rather than a look-alike chart for an editor. It therefore inherits
/// the same gauge viewport, 0–120% scale, material settings, marker and
/// retargeting motion from [BudgetSemicircleGauge].
final class BudgetMonthUtilizationHero extends StatelessWidget {
  const BudgetMonthUtilizationHero({
    required this.analysis,
    required this.direction,
    required this.targetVisual,
    this.gaugeKey = const ValueKey<String>('budget-analysis-month-semicircle'),
    super.key,
  });

  final DashboardBudgetMonthSecondaryAnalysis analysis;
  final LedgerDirection direction;
  final DashboardBudgetTargetPresentationItem? targetVisual;
  final Key gaugeKey;

  @override
  Widget build(BuildContext context) {
    if (!analysis.isAvailable || analysis.budgetUsedRatio == null) {
      return const _UnavailableHero();
    }
    return _BudgetUtilizationHero(
      ratio: analysis.budgetUsedRatio,
      secondaryLabel: 'havi keretkihasználás',
      gaugeKey: gaugeKey,
      direction: direction,
      targetVisual: targetVisual,
    );
  }
}

final class _DayHero extends StatelessWidget {
  const _DayHero({required this.payload});
  final DashboardBudgetDaySecondaryAnalysis payload;

  @override
  Widget build(BuildContext context) {
    if (!payload.isAvailable || payload.dailyRoomBeforeScaled100 == null) {
      return const _UnavailableHero();
    }
    final change = payload.dailyRoomChangeScaled100;
    final color = change == null
        ? FluviVisualTokens.textSecondary
        : change < 0
        ? FluviVisualTokens.budgetProgressHealthy
        : FluviVisualTokens.budgetProgressDanger;
    return LayoutBuilder(
      builder: (context, constraints) {
        final comparisonHeight = _BudgetDayComparisonGeometry.cardHeightFor(
          constraints,
        );
        return Column(
          children: <Widget>[
            Expanded(
              child: Center(
                key: const ValueKey<String>(
                  'budget-analysis-day-comparison-placement',
                ),
                child: SizedBox(
                  key: const ValueKey<String>(
                    'budget-analysis-day-comparison-row',
                  ),
                  height: comparisonHeight,
                  child: Row(
                    children: <Widget>[
                      Expanded(
                        child: _BudgetDayClayComparisonCard(
                          key: const ValueKey<String>(
                            'budget-analysis-day-before-card',
                          ),
                          label: 'Reggel még\nelérhető volt',
                          amount: payload.dailyRoomBeforeScaled100!,
                          tint: const Color(0xFF8B9CF5),
                        ),
                      ),
                      const SizedBox(
                        width: 30,
                        child: Center(child: _BudgetDayClayArrow()),
                      ),
                      Expanded(
                        child: _BudgetDayClayComparisonCard(
                          key: const ValueKey<String>(
                            'budget-analysis-day-after-card',
                          ),
                          label: 'Mostantól\nelérhető',
                          amount: payload.dailyRoomAfterScaled100,
                          unavailable: payload.isTerminalDay,
                          tint: const Color(0xFFFB7185),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 7),
            _BudgetDayClayImpactBand(change: change, color: color),
          ],
        );
      },
    );
  }
}

/// Keeps DAY's two comparison slabs proportionate to the canonical hero
/// viewport. The surrounding [Expanded] is a placement region only: the
/// cards never stretch merely because the KPI footer is hidden.
final class _BudgetDayComparisonGeometry {
  const _BudgetDayComparisonGeometry._();

  static double cardHeightFor(BoxConstraints constraints) {
    final availableHeight = constraints.hasBoundedHeight
        ? constraints.maxHeight
        : 0.0;
    final comparisonRegion = math.max(
      0.0,
      availableHeight - _BudgetDayClayImpactBand.height - _impactGap,
    );
    return (comparisonRegion * .76).clamp(52.0, 70.0).toDouble();
  }

  static const double _impactGap = 7;
}

/// A simple native-Flutter clay slab for one side of DAY's before → after
/// comparison. It deliberately owns neither gesture nor financial logic: the
/// parent hero retains the shared popup tap semantics and supplies prepared
/// amounts only.
final class _BudgetDayClayComparisonCard extends StatelessWidget {
  const _BudgetDayClayComparisonCard({
    super.key,
    required this.label,
    required this.amount,
    required this.tint,
    this.unavailable = false,
  });
  final String label;
  final int? amount;
  final Color tint;
  final bool unavailable;

  @override
  Widget build(BuildContext context) {
    final amountLabel = unavailable ? '—' : _money(amount);
    final requestedAmountScale =
        MediaQuery.textScalerOf(context).scale(18) / 18;
    final amountTextScaler = TextScaler.linear(
      math.min(requestedAmountScale, 1.05),
    );
    return Semantics(
      label: unavailable
          ? '$label, nem elérhető naponta'
          : '$label, $amountLabel naponta',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: <Color>[
                Colors.white.withValues(alpha: .96),
                Color.lerp(tint, Colors.white, .70)!,
              ],
            ),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(
              color: Color.lerp(
                tint,
                Colors.white,
                .58,
              )!.withValues(alpha: .76),
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Color.lerp(
                  tint,
                  const Color(0xFF667085),
                  .22,
                )!.withValues(alpha: .21),
                offset: const Offset(2.5, 3.5),
                blurRadius: 9,
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: const TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 8.5,
                      height: 1.05,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 1),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Text(
                      amountLabel,
                      maxLines: 1,
                      textScaler: amountTextScaler,
                      style: const TextStyle(
                        color: FluviVisualTokens.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        height: 1,
                      ),
                    ),
                  ),
                  const Text(
                    '/ nap',
                    textAlign: TextAlign.center,
                    textScaler: TextScaler.noScaling,
                    style: TextStyle(
                      color: FluviVisualTokens.textSecondary,
                      fontSize: 7.5,
                      height: 1,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Decorative only: it is intentionally not an interactive control, so the
/// ancestor can continue to distinguish a clean popup tap from pager swipes.
final class _BudgetDayClayArrow extends StatelessWidget {
  const _BudgetDayClayArrow();

  @override
  Widget build(BuildContext context) => SizedBox.square(
    key: const ValueKey<String>('budget-analysis-day-arrow'),
    dimension: 30,
    child: DecoratedBox(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFFFFFFF), Color(0xFFF0EDF8)],
        ),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xCCFFFFFF)),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x294B556D),
            offset: Offset(1, 2),
            blurRadius: 5,
          ),
        ],
      ),
      child: const Icon(
        Icons.arrow_forward_rounded,
        color: FluviVisualTokens.textSecondary,
        size: 17,
      ),
    ),
  );
}

final class _BudgetDayClayImpactBand extends StatelessWidget {
  const _BudgetDayClayImpactBand({required this.change, required this.color});

  static const double height = 42;

  final int? change;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final resolvedChange = change;
    final terminal = resolvedChange == null;
    final changeValue = resolvedChange ?? 0;
    final primary = terminal
        ? 'Ma zárul a hónap'
        : '${_signedMoney(changeValue)} / nap';
    final secondary = terminal
        ? 'A hátralévő napi mozgástér már nem változik'
        : 'ennyivel ${changeValue < 0 ? 'csökkent' : 'nőtt'} a hátralévő napi mozgástér';
    final icon = terminal
        ? Icons.flag_outlined
        : changeValue < 0
        ? Icons.trending_down_rounded
        : Icons.trending_up_rounded;
    return SizedBox(
      key: const ValueKey<String>('budget-analysis-day-impact-band'),
      height: height,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: <Color>[
              Colors.white.withValues(alpha: .98),
              color.withValues(alpha: .13),
            ],
          ),
          borderRadius: BorderRadius.circular(13),
          border: Border.all(color: color.withValues(alpha: .22)),
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: color.withValues(alpha: .10),
              offset: const Offset(1, 2),
              blurRadius: 5,
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: <Widget>[
              SizedBox.square(
                dimension: 22,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: .13),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, color: color, size: 13),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text(
                      primary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: color,
                        fontSize: 9.2,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      secondary,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: FluviVisualTokens.textSecondary,
                        fontSize: 6.4,
                        height: 1,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

final class _UnavailableHero extends StatelessWidget {
  const _UnavailableHero();
  @override
  Widget build(BuildContext context) => const Center(
    child: Text(
      'Nincs beállított keret ehhez a kategóriához.',
      textAlign: TextAlign.center,
      style: TextStyle(
        color: FluviVisualTokens.textSecondary,
        fontSize: 9,
        fontWeight: FontWeight.w700,
      ),
    ),
  );
}

final class _KpiRow extends StatelessWidget {
  const _KpiRow({required this.kpis});
  final List<_Kpi> kpis;

  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      for (var index = 0; index < kpis.length; index += 1)
        Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == kpis.length - 1 ? 0 : 5),
            child: _KpiBlock(kpi: kpis[index]),
          ),
        ),
    ],
  );
}

List<_Kpi> _kpisFor(
  DashboardBudgetSecondaryAnalysisPayload payload,
) => switch (payload) {
  DashboardBudgetSumAnalysis(
    :final averageBudgetDeltaScaled100,
    :final monthsWithinBudget,
    :final eligibleMonthCount,
    :final utilizationStandardDeviation,
  ) =>
    <_Kpi>[
      _Kpi(
        'Átlagos eltérés',
        _signedMoney(averageBudgetDeltaScaled100),
        'havonta',
      ),
      _Kpi(
        'Keretbetartás',
        '$monthsWithinBudget / $eligibleMonthCount hó',
        'kereten belül',
      ),
      _Kpi(
        'Havi stabilitás',
        utilizationStandardDeviation == null
            ? '—'
            : '±${(utilizationStandardDeviation * 100).round()}%',
        'kihasználás',
      ),
    ],
  DashboardBudgetYearAnalysis(
    :final completedWithinBudgetCount,
    :final completedEligibleMonthCount,
    :final largestOverspendScaled100,
    :final largestReserveScaled100,
  ) =>
    <_Kpi>[
      _Kpi(
        'Keretbetartás',
        '$completedWithinBudgetCount / $completedEligibleMonthCount hó',
        'kereten belül',
      ),
      _Kpi('Legnagyobb túllépés', _money(largestOverspendScaled100), ''),
      _Kpi('Legnagyobb tartalék', _money(largestReserveScaled100), ''),
    ],
  DashboardBudgetMonthSecondaryAnalysis(
    :final usesForecast,
    :final expectedDeltaScaled100,
    :final closingBudgetDeltaScaled100,
    :final remainingDailyRoomScaled100,
    :final historicalDailyAverageScaled100,
    :final projectedMonthEndScaled100,
  ) =>
    <_Kpi>[
      _Kpi(
        usesForecast ? 'Várható eltérés' : 'Záró eltérés',
        _signedMoney(
          usesForecast ? expectedDeltaScaled100 : closingBudgetDeltaScaled100,
        ),
        '',
      ),
      _Kpi(
        usesForecast ? 'Napi mozgástér' : 'Napi átlag',
        _money(
          usesForecast
              ? remainingDailyRoomScaled100
              : historicalDailyAverageScaled100,
        ),
        usesForecast ? '/ nap' : '',
      ),
      _Kpi(
        usesForecast ? 'Várható zárás' : 'Záró összeg',
        _money(projectedMonthEndScaled100),
        '',
      ),
    ],
  DashboardBudgetDaySecondaryAnalysis(
    :final selectedDayActualScaled100,
    :final remainingSpendableTodayScaled100,
    :final monthlyDeltaScaled100,
    :final usesForecast,
  ) =>
    <_Kpi>[
      _Kpi('Mai költés', _money(selectedDayActualScaled100), ''),
      _Kpi('Ma még elkölthető', _money(remainingSpendableTodayScaled100), ''),
      _Kpi(
        usesForecast ? 'Várható havi eltérés' : 'Havi eltérés',
        _signedMoney(monthlyDeltaScaled100),
        '',
      ),
    ],
};

final class _Kpi {
  const _Kpi(this.label, this.value, this.detail);
  final String label;
  final String value;
  final String detail;
}

/// The hidden-footer overlay consumes exactly the same prepared `_Kpi` list as
/// the visible row. It is presentation-only and never recalculates financial
/// values or formats a competing data source.
final class _AnalysisKpiPopup extends StatelessWidget {
  const _AnalysisKpiPopup({required this.kpis});

  final List<_Kpi> kpis;

  @override
  Widget build(BuildContext context) => IgnorePointer(
    child: Align(
      alignment: const Alignment(0, .30),
      child: FractionallySizedBox(
        widthFactor: .58,
        child: DecoratedBox(
          key: const ValueKey<String>('budget-analysis-kpi-popup'),
          decoration: BoxDecoration(
            color: const Color(0xF20B1020),
            borderRadius: BorderRadius.circular(12),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color(0x33000000),
                blurRadius: 12,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                for (
                  var index = 0;
                  index < kpis.length;
                  index += 1
                ) ...<Widget>[
                  _AnalysisKpiPopupSection(kpi: kpis[index]),
                  if (index != kpis.length - 1) const SizedBox(height: 4),
                ],
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

final class _AnalysisKpiPopupSection extends StatelessWidget {
  const _AnalysisKpiPopupSection({required this.kpi});

  final _Kpi kpi;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: <Widget>[
      Text(
        kpi.label,
        style: const TextStyle(
          color: Color(0xCCFFFFFF),
          fontSize: 6.6,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 1),
      Text(
        kpi.value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11.5,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      if (kpi.detail.isNotEmpty) ...<Widget>[
        Text(
          kpi.detail,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 6,
            height: 1,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    ],
  );
}

final class _KpiBlock extends StatelessWidget {
  const _KpiBlock({required this.kpi});
  final _Kpi kpi;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: const Color(0xFFF8F7FC),
      borderRadius: BorderRadius.circular(8),
      border: Border.all(color: const Color(0xFFEDEAF5)),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            kpi.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 6.6,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            kpi.value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FluviVisualTokens.textPrimary,
              fontSize: 9.8,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          if (kpi.detail.isNotEmpty)
            Text(
              kpi.detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 5.8,
                fontWeight: FontWeight.w600,
                height: 1,
              ),
            ),
        ],
      ),
    ),
  );
}

/// Prepared, chart-geometry-independent materials for the annual delta rail.
///
/// Its active families come from [BudgetClayActiveMaterial], the same shared
/// Fluvi Budget factory consumed by the SUM/MONTH semicircle. YEAR deliberately
/// does not inherit the semicircle's continuous colour mapping: each month is
/// already one discrete reserve or overspend semantic outcome.
@immutable
final class BudgetYearClayDeltaMaterial {
  factory BudgetYearClayDeltaMaterial.resolve({
    required bool showNeutralDecorativeStrip,
    required bool showActiveProgressDecorativeStrip,
  }) => BudgetYearClayDeltaMaterial._(
    showNeutralDecorativeStrip: showNeutralDecorativeStrip,
    showActiveProgressDecorativeStrip: showActiveProgressDecorativeStrip,
    overspend: BudgetClayActiveMaterial.forSemanticBase(
      FluviVisualTokens.budgetProgressDanger,
    ),
    reserve: BudgetClayActiveMaterial.forSemanticBase(
      FluviVisualTokens.budgetProgressHealthy,
    ),
    exactZero: BudgetClayActiveMaterial.forSemanticBase(
      BudgetProgressRingGeometry.source.trackGradientColors[1],
    ),
  );

  const BudgetYearClayDeltaMaterial._({
    required this.showNeutralDecorativeStrip,
    required this.showActiveProgressDecorativeStrip,
    required this.overspend,
    required this.reserve,
    required this.exactZero,
  });

  final bool showNeutralDecorativeStrip;
  final bool showActiveProgressDecorativeStrip;
  final BudgetClayActiveMaterial overspend;
  final BudgetClayActiveMaterial reserve;
  final BudgetClayActiveMaterial exactZero;

  bool sameVisualAs(BudgetYearClayDeltaMaterial other) =>
      showNeutralDecorativeStrip == other.showNeutralDecorativeStrip &&
      showActiveProgressDecorativeStrip ==
          other.showActiveProgressDecorativeStrip &&
      overspend.sameVisualAs(other.overspend) &&
      reserve.sameVisualAs(other.reserve) &&
      exactZero.sameVisualAs(other.exactZero);
}

/// Paint-only classification of an already-prepared monthly delta. It does
/// not calculate any financial value: the prepared [budgetDeltaScaled100]
/// remains the sole semantic authority. Keeping completed zero separate from
/// a future month prevents an exact close from looking like missing data.
enum BudgetYearClayDeltaKind {
  overspend,
  reserve,
  exactZero,
  future,
  unavailable,
}

abstract final class BudgetYearClayDeltaKindResolver {
  static BudgetYearClayDeltaKind resolve(
    DashboardBudgetYearMonthAnalysis month,
  ) {
    final delta = month.budgetDeltaScaled100;
    if (delta != null) {
      if (delta < 0) return BudgetYearClayDeltaKind.overspend;
      if (delta > 0) return BudgetYearClayDeltaKind.reserve;
      return BudgetYearClayDeltaKind.exactZero;
    }
    return month.availability == BudgetAnalysisAvailability.future
        ? BudgetYearClayDeltaKind.future
        : BudgetYearClayDeltaKind.unavailable;
  }
}

@immutable
final class _YearClayDeltaGeometry {
  factory _YearClayDeltaGeometry.resolve(Size size) {
    final horizontalInset = math.max(3.0, size.width * .025);
    final slot = (size.width - horizontalInset * 2) / 12;
    final barWidth = (slot * .42).clamp(4.0, 14.0).toDouble();
    final railHeight = math.max(1.6, barWidth * .15);
    final axis = size.height * .51;
    const labelLane = 10.0;
    final verticalHeadroom = railHeight + barWidth * .35;
    final maxBarHeight = math.max(
      0.0,
      math.min(
        size.height * .40,
        math.min(
          axis - verticalHeadroom,
          size.height - labelLane - axis - verticalHeadroom,
        ),
      ),
    );
    return _YearClayDeltaGeometry._(
      axis: axis,
      horizontalInset: horizontalInset,
      slot: slot,
      barWidth: barWidth,
      railRect: Rect.fromCenter(
        center: Offset(size.width / 2, axis),
        width: size.width * .95,
        height: railHeight,
      ),
      maxBarHeight: maxBarHeight,
      futureRadius: math.max(1.0, barWidth * .14),
      exactZeroHeight: math.max(barWidth * .7, railHeight * 2.7),
    );
  }

  const _YearClayDeltaGeometry._({
    required this.axis,
    required this.horizontalInset,
    required this.slot,
    required this.barWidth,
    required this.railRect,
    required this.maxBarHeight,
    required this.futureRadius,
    required this.exactZeroHeight,
  });

  final double axis;
  final double horizontalInset;
  final double slot;
  final double barWidth;
  final Rect railRect;
  final double maxBarHeight;
  final double futureRadius;
  final double exactZeroHeight;

  double centerForMonth(int index) => horizontalInset + slot * (index + .5);

  Rect rectFor({required double center, required int delta, required int max}) {
    if (delta == 0) {
      return Rect.fromCenter(
        center: Offset(center, axis),
        width: barWidth,
        height: exactZeroHeight,
      );
    }
    final height = math.max(barWidth * .5, (delta.abs() / max) * maxBarHeight);
    return delta < 0
        ? Rect.fromLTWH(center - barWidth / 2, axis - height, barWidth, height)
        : Rect.fromLTWH(center - barWidth / 2, axis, barWidth, height);
  }
}

/// Multi-pass painter for the fixed, instant yearly delta scene. It owns no
/// financial calculation and has no animation controller: a new prepared year
/// paints its final twelve capsules on its first exact frame.
final class _YearClayDeltaPainter extends CustomPainter {
  const _YearClayDeltaPainter({required this.months, required this.material});

  final List<DashboardBudgetYearMonthAnalysis> months;
  final BudgetYearClayDeltaMaterial material;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) return;
    final geometry = _YearClayDeltaGeometry.resolve(size);
    final maxValue = months.fold<int>(
      1,
      (current, month) =>
          math.max(current, month.budgetDeltaScaled100?.abs() ?? 0),
    );
    _paintZeroRail(canvas, geometry);
    final limit = math.min(months.length, 12);
    for (var index = 0; index < limit; index += 1) {
      final month = months[index];
      final center = geometry.centerForMonth(index);
      final delta = month.budgetDeltaScaled100;
      final kind = BudgetYearClayDeltaKindResolver.resolve(month);
      switch (kind) {
        case BudgetYearClayDeltaKind.overspend ||
            BudgetYearClayDeltaKind.reserve ||
            BudgetYearClayDeltaKind.exactZero:
          final resolvedDelta = delta!;
          final isExactZero = kind == BudgetYearClayDeltaKind.exactZero;
          _paintClayCapsule(
            canvas,
            rect: geometry.rectFor(
              center: center,
              delta: resolvedDelta,
              max: maxValue,
            ),
            clayMaterial: isExactZero
                ? material.exactZero
                : resolvedDelta < 0
                ? material.overspend
                : material.reserve,
            showDecorativeStrip:
                !isExactZero && material.showActiveProgressDecorativeStrip,
          );
        case BudgetYearClayDeltaKind.future:
          _paintFutureMarker(canvas, Offset(center, geometry.axis), geometry);
        case BudgetYearClayDeltaKind.unavailable:
          break;
      }
    }
  }

  void _paintZeroRail(Canvas canvas, _YearClayDeltaGeometry geometry) {
    final source = BudgetProgressRingGeometry.source;
    final radius = Radius.circular(geometry.railRect.height / 2);
    final rail = RRect.fromRectAndRadius(geometry.railRect, radius);
    canvas.drawRRect(
      rail.shift(Offset(0, geometry.railRect.height * .8)),
      Paint()
        ..color = source.trackShadowColor.withValues(alpha: .52)
        ..maskFilter = MaskFilter.blur(
          BlurStyle.normal,
          geometry.railRect.height * .8,
        ),
    );
    canvas.drawRRect(
      rail.shift(Offset(0, geometry.railRect.height * .36)),
      Paint()..color = source.trackGradientColors.last,
    );
    canvas.drawRRect(
      rail,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: source.trackGradientColors,
          stops: source.trackGradientStops,
        ).createShader(geometry.railRect),
    );
    if (!material.showNeutralDecorativeStrip) return;
    final inset = geometry.railRect.height * .85;
    final glossRect = Rect.fromLTWH(
      geometry.railRect.left + inset,
      geometry.railRect.top + geometry.railRect.height * .18,
      math.max(0, geometry.railRect.width - inset * 2),
      math.max(.5, geometry.railRect.height * .27),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(glossRect, Radius.circular(glossRect.height / 2)),
      Paint()..color = source.trackGlossColor,
    );
  }

  void _paintClayCapsule(
    Canvas canvas, {
    required Rect rect,
    required BudgetClayActiveMaterial clayMaterial,
    required bool showDecorativeStrip,
  }) {
    final radius = Radius.circular(rect.width / 2);
    final capsule = RRect.fromRectAndRadius(rect, radius);
    final depthOffset = Offset(
      rect.width * .10,
      math.max(.8, rect.width * .17),
    );
    canvas.drawRRect(
      capsule.shift(depthOffset),
      Paint()
        ..color = clayMaterial.depthColors.last.withValues(alpha: .34)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, rect.width * .14),
    );
    canvas.drawRRect(
      capsule.shift(Offset(0, rect.width * .10)),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: clayMaterial.depthColors,
          stops: clayMaterial.stops,
        ).createShader(rect),
    );
    canvas.drawRRect(
      capsule,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: clayMaterial.colors,
          stops: clayMaterial.stops,
        ).createShader(rect),
    );
    if (!showDecorativeStrip) return;
    final capInset = math.min(rect.width * .22, rect.height * .22);
    final stripRect = Rect.fromLTWH(
      rect.left + rect.width * .18,
      rect.top + capInset,
      rect.width * .24,
      math.max(0, rect.height - capInset * 2),
    );
    if (stripRect.height <= 0) return;
    canvas.drawRRect(
      RRect.fromRectAndRadius(stripRect, Radius.circular(stripRect.width / 2)),
      Paint()..color = const Color(0x45FFFFFF),
    );
  }

  void _paintFutureMarker(
    Canvas canvas,
    Offset center,
    _YearClayDeltaGeometry geometry,
  ) {
    final source = BudgetProgressRingGeometry.source;
    final radius = geometry.futureRadius;
    canvas.drawCircle(
      center.translate(radius * .28, radius * .4),
      radius,
      Paint()
        ..color = source.trackShadowColor.withValues(alpha: .45)
        ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * .75),
    );
    final dotRect = Rect.fromCircle(center: center, radius: radius);
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..shader = RadialGradient(
          center: const Alignment(-.45, -.5),
          colors: <Color>[
            const Color(0xCCFFFFFF),
            source.trackGradientColors.last.withValues(alpha: .78),
          ],
        ).createShader(dotRect),
    );
  }

  @override
  bool shouldRepaint(covariant _YearClayDeltaPainter old) =>
      old.months != months || !old.material.sameVisualAs(material);
}

const _monthLabels = <String>[
  'JAN',
  'FEB',
  'MÁR',
  'ÁPR',
  'MÁJ',
  'JÚN',
  'JÚL',
  'AUG',
  'SZE',
  'OKT',
  'NOV',
  'DEC',
];

String _money(int? value) =>
    value == null ? '—' : DashboardPreparedFormatter.amountMinor(value);
String _signedMoney(int? value) => value == null
    ? '—'
    : '${value < 0 ? '−' : '+'}${DashboardPreparedFormatter.amountMinor(value.abs())}';
