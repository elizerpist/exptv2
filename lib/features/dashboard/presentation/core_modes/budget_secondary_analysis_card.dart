import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

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
            if (showInfoCards) ...<Widget>[
              const SizedBox(height: 6),
              SizedBox(
                key: const ValueKey<String>('budget-analysis-kpi-row'),
                height: 43,
                child: _KpiRow(kpis: kpis),
              ),
            ],
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
  Widget build(BuildContext context) => Stack(
    children: <Widget>[
      Positioned.fill(
        child: CustomPaint(
          key: const ValueKey<String>('budget-analysis-year-zero-axis-bars'),
          painter: _YearBarsPainter(payload.months),
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
                    fontSize: 5.5,
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
  Widget build(BuildContext context) {
    if (!payload.isAvailable || payload.budgetUsedRatio == null) {
      return const _UnavailableHero();
    }
    return _BudgetUtilizationHero(
      ratio: payload.budgetUsedRatio,
      secondaryLabel: 'havi keretkihasználás',
      gaugeKey: const ValueKey<String>('budget-analysis-month-semicircle'),
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
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: _DayRoomBlock(
                  label: 'Reggel még\nelérhető volt',
                  amount: payload.dailyRoomBeforeScaled100!,
                  tint: FluviVisualTokens.appHighlightGradient.colors.first,
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 5),
                child: Icon(
                  Icons.arrow_forward_rounded,
                  color: FluviVisualTokens.textSecondary,
                  size: 18,
                ),
              ),
              Expanded(
                child: _DayRoomBlock(
                  label: 'Mostantól\nelérhető',
                  amount: payload.dailyRoomAfterScaled100,
                  unavailable: payload.isTerminalDay,
                  tint: FluviVisualTokens.budgetProgressDanger,
                ),
              ),
            ],
          ),
        ),
        Container(
          key: const ValueKey<String>('budget-analysis-day-impact-band'),
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 7),
          decoration: BoxDecoration(
            color: color.withValues(alpha: .10),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            change == null
                ? 'Ma zárul a hónap'
                : '${_signedMoney(change)} / nap · ennyivel ${change < 0 ? 'csökkent' : 'nőtt'} a hátralévő napi mozgástér',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 6.8,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
      ],
    );
  }
}

final class _DayRoomBlock extends StatelessWidget {
  const _DayRoomBlock({
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
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: tint.withValues(alpha: .10),
      borderRadius: BorderRadius.circular(10),
      border: Border.all(color: FluviVisualTokens.border),
    ),
    child: Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 6.8,
              height: 1.1,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            unavailable ? '—' : _money(amount),
            style: const TextStyle(
              color: FluviVisualTokens.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          const Text(
            '/ nap',
            style: TextStyle(
              color: FluviVisualTokens.textSecondary,
              fontSize: 6,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
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
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 11),
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
                  if (index != kpis.length - 1) const SizedBox(height: 8),
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
          fontSize: 7,
          height: 1,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        kpi.value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          height: 1,
          fontWeight: FontWeight.w900,
        ),
      ),
      if (kpi.detail.isNotEmpty) ...<Widget>[
        const SizedBox(height: 1),
        Text(
          kpi.detail,
          style: const TextStyle(
            color: Color(0xB3FFFFFF),
            fontSize: 6.5,
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

final class _YearBarsPainter extends CustomPainter {
  const _YearBarsPainter(this.months);
  final List<DashboardBudgetYearMonthAnalysis> months;
  @override
  void paint(Canvas canvas, Size size) {
    final axis = size.height * .51;
    final axisPaint = Paint()
      ..color = FluviVisualTokens.border
      ..strokeWidth = 1;
    canvas.drawLine(Offset(2, axis), Offset(size.width - 2, axis), axisPaint);
    final maxValue = months.fold<int>(
      1,
      (current, month) =>
          math.max(current, month.budgetDeltaScaled100?.abs() ?? 0),
    );
    final slot = size.width / 12;
    for (var index = 0; index < months.length; index += 1) {
      final month = months[index];
      final delta = month.budgetDeltaScaled100;
      final center = slot * (index + .5);
      if (delta != null) {
        final height = (delta.abs() / maxValue) * (size.height * .40);
        final rect = delta < 0
            ? Rect.fromLTWH(
                center - slot * .24,
                axis - height,
                slot * .48,
                height,
              )
            : Rect.fromLTWH(center - slot * .24, axis, slot * .48, height);
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(2)),
          Paint()
            ..color = delta < 0
                ? FluviVisualTokens.budgetProgressDanger
                : FluviVisualTokens.budgetProgressHealthy,
        );
      } else if (month.availability == BudgetAnalysisAvailability.future) {
        canvas.drawCircle(
          Offset(center, axis),
          1.4,
          Paint()..color = FluviVisualTokens.placeholderDotInactive,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _YearBarsPainter old) => old.months != months;
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
