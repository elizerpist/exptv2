import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../../core/design/dashboard_mode_palette.dart';
import '../../application/dashboard_budget_presentation_controller.dart';
import '../../application/dashboard_budget_secondary_analysis.dart';
import '../../prepared/data/dashboard_prepared_formatter.dart';
import 'budget_category_distribution_visual_bank.dart';

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
  });

  final DashboardBudgetPresentationController presentation;
  final ValueListenable<DashboardBudgetDistributionDrawableFrame?>
  drawableFrames;

  @override
  State<BudgetSecondaryAnalysisCard> createState() =>
      _BudgetSecondaryAnalysisCardState();
}

final class _RenderedAnalysisFrame {
  const _RenderedAnalysisFrame({
    required this.frame,
    required this.targetTitle,
    required this.scopeLabel,
  });

  final DashboardBudgetSecondaryAnalysisFrame frame;
  final String targetTitle;
  final String scopeLabel;
}

class _BudgetSecondaryAnalysisCardState
    extends State<BudgetSecondaryAnalysisCard>
    with SingleTickerProviderStateMixin {
  _RenderedAnalysisFrame? _rendered;
  late final AnimationController _transition;

  @override
  void initState() {
    super.initState();
    _transition = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
    )..value = 1;
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
    _transition.dispose();
    super.dispose();
  }

  void _onSourceChanged() {
    final changed = _resolveAtomicFrame();
    if (changed && mounted) {
      _transition.forward(from: 0);
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
    );
    final old = _rendered;
    if (old != null &&
        identical(old.frame, next.frame) &&
        old.targetTitle == next.targetTitle &&
        old.scopeLabel == next.scopeLabel) {
      return false;
    }
    _rendered = next;
    return true;
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
    return FadeTransition(
      opacity: CurvedAnimation(parent: _transition, curve: Curves.easeOut),
      child: BudgetSecondaryAnalysisPreparedCard(
        frame: rendered.frame,
        targetTitle: rendered.targetTitle,
        scopeLabel: rendered.scopeLabel,
      ),
    );
  }
}

/// Paint-only entry point used by the production pager after its atomic frame
/// has been selected. It is intentionally useful to widget tests without
/// exposing any ledger/controller dependency.
final class BudgetSecondaryAnalysisPreparedCard extends StatelessWidget {
  const BudgetSecondaryAnalysisPreparedCard({
    super.key,
    required this.frame,
    required this.targetTitle,
    required this.scopeLabel,
  });

  final DashboardBudgetSecondaryAnalysisFrame frame;
  final String targetTitle;
  final String scopeLabel;

  @override
  Widget build(BuildContext context) {
    final payload = frame.payload;
    final copy = _copyFor(payload);
    return Semantics(
      label: '$targetTitle: ${copy.title}, $scopeLabel',
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        child: Column(
          children: <Widget>[
            _AnalysisHeader(copy: copy, scopeLabel: scopeLabel),
            const SizedBox(height: 4),
            Expanded(child: _Hero(payload: payload)),
            const SizedBox(height: 6),
            SizedBox(height: 43, child: _KpiRow(payload: payload)),
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
        title: 'Időarányos felhasználás',
        subtitle: 'Hol tartasz ebben a hónapban?',
        icon: Icons.timelapse_rounded,
      ),
      DashboardBudgetDaySecondaryAnalysis() => const _AnalysisCopy(
        title: 'A mai költés hatása',
        subtitle: 'Hogyan változott a havi mozgástér?',
        icon: Icons.compare_arrows_rounded,
      ),
    };

final class _AnalysisHeader extends StatelessWidget {
  const _AnalysisHeader({required this.copy, required this.scopeLabel});

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
  const _Hero({required this.payload});

  final DashboardBudgetSecondaryAnalysisPayload payload;

  @override
  Widget build(BuildContext context) => switch (payload) {
    DashboardBudgetSumAnalysis() => _SumHero(
      payload: payload as DashboardBudgetSumAnalysis,
    ),
    DashboardBudgetYearAnalysis() => _YearHero(
      payload: payload as DashboardBudgetYearAnalysis,
    ),
    DashboardBudgetMonthSecondaryAnalysis() => _MonthHero(
      payload: payload as DashboardBudgetMonthSecondaryAnalysis,
    ),
    DashboardBudgetDaySecondaryAnalysis() => _DayHero(
      payload: payload as DashboardBudgetDaySecondaryAnalysis,
    ),
  };
}

final class _SumHero extends StatelessWidget {
  const _SumHero({required this.payload});
  final DashboardBudgetSumAnalysis payload;

  @override
  Widget build(BuildContext context) {
    final ratio = payload.averageUtilization;
    if (ratio == null) return const _UnavailableHero();
    return Stack(
      alignment: Alignment.center,
      children: <Widget>[
        _SemiGauge(
          key: const ValueKey<String>('budget-analysis-sum-semicircle'),
          ratio: ratio,
          primary: FluviVisualTokens.appHighlightGradient.colors.first,
          overflow: FluviVisualTokens.budgetProgressDanger,
          healthScale: true,
        ),
        Padding(
          padding: const EdgeInsets.only(top: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                '${(ratio * 100).round()}%',
                style: const TextStyle(
                  color: FluviVisualTokens.textPrimary,
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const Text(
                'átlagos\nkeretkihasználás',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: FluviVisualTokens.textSecondary,
                  fontSize: 7.2,
                  height: 1.1,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const Positioned(
          left: 10,
          bottom: 0,
          child: Text('0%', style: _endpointStyle),
        ),
        const Positioned(
          right: 5,
          bottom: 0,
          child: Text('100%+', style: _endpointStyle),
        ),
      ],
    );
  }
}

const _endpointStyle = TextStyle(
  color: FluviVisualTokens.textSecondary,
  fontSize: 6.5,
  fontWeight: FontWeight.w700,
);

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
  const _MonthHero({required this.payload});
  final DashboardBudgetMonthSecondaryAnalysis payload;

  @override
  Widget build(BuildContext context) {
    if (!payload.isAvailable ||
        payload.elapsedRatio == null ||
        payload.budgetUsedRatio == null) {
      return const _UnavailableHero();
    }
    final pace = payload.paceDifferencePercentagePoints!;
    final paceColor = pace > .5
        ? FluviVisualTokens.budgetProgressDanger
        : pace < -.5
        ? FluviVisualTokens.budgetProgressHealthy
        : FluviVisualTokens.textSecondary;
    return Column(
      children: <Widget>[
        Expanded(
          child: Row(
            children: <Widget>[
              Expanded(
                child: _GaugeMetric(
                  key: const ValueKey<String>(
                    'budget-analysis-month-elapsed-semicircle',
                  ),
                  label: 'ELTELT IDŐ',
                  ratio: payload.elapsedRatio!,
                  detail:
                      '${payload.elapsedCalendarDays} / ${payload.daysInMonth} nap',
                  primary: FluviVisualTokens.appHighlightGradient.colors.first,
                ),
              ),
              Expanded(
                child: _GaugeMetric(
                  key: const ValueKey<String>(
                    'budget-analysis-month-used-semicircle',
                  ),
                  label: 'FELHASZNÁLT KERET',
                  ratio: payload.budgetUsedRatio!,
                  detail:
                      '${_money(payload.monthActualScaled100)} / ${_money(payload.monthlyLimitScaled100)}',
                  primary: FluviVisualTokens.budgetProgressDanger,
                ),
              ),
            ],
          ),
        ),
        Text(
          '${_signedPp(pace)} pp',
          style: TextStyle(
            color: paceColor,
            fontSize: 12,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        Text(
          pace > .5
              ? 'előrébb jár a költés'
              : pace < -.5
              ? 'lassabban fogy a keret'
              : 'egy ütemben halad',
          style: const TextStyle(
            color: FluviVisualTokens.textSecondary,
            fontSize: 7,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

final class _GaugeMetric extends StatelessWidget {
  const _GaugeMetric({
    super.key,
    required this.label,
    required this.ratio,
    required this.detail,
    required this.primary,
  });
  final String label;
  final double ratio;
  final String detail;
  final Color primary;

  @override
  Widget build(BuildContext context) => Stack(
    alignment: Alignment.center,
    children: <Widget>[
      _SemiGauge(
        ratio: ratio,
        primary: primary,
        overflow: FluviVisualTokens.budgetProgressDanger,
      ),
      Padding(
        padding: const EdgeInsets.only(top: 19),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Text(
              label,
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 6.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              '${(ratio * 100).round()}%',
              style: const TextStyle(
                color: FluviVisualTokens.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w900,
                height: 1.05,
              ),
            ),
            Text(
              detail,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: FluviVisualTokens.textSecondary,
                fontSize: 6.2,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    ],
  );
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
  const _KpiRow({required this.payload});
  final DashboardBudgetSecondaryAnalysisPayload payload;

  @override
  Widget build(BuildContext context) {
    final kpis = switch (payload) {
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
              usesForecast
                  ? expectedDeltaScaled100
                  : closingBudgetDeltaScaled100,
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
          _Kpi(
            'Ma még elkölthető',
            _money(remainingSpendableTodayScaled100),
            '',
          ),
          _Kpi(
            usesForecast ? 'Várható havi eltérés' : 'Havi eltérés',
            _signedMoney(monthlyDeltaScaled100),
            '',
          ),
        ],
    };
    return Row(
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
}

final class _Kpi {
  const _Kpi(this.label, this.value, this.detail);
  final String label;
  final String value;
  final String detail;
}

final class _KpiBlock extends StatelessWidget {
  const _KpiBlock({required this.kpi});
  final _Kpi kpi;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: FluviVisualTokens.surfaceMuted,
      borderRadius: BorderRadius.circular(8),
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
              fontSize: 6.2,
              fontWeight: FontWeight.w700,
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
              fontSize: 8.4,
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

final class _SemiGauge extends StatelessWidget {
  const _SemiGauge({
    super.key,
    required this.ratio,
    required this.primary,
    required this.overflow,
    this.healthScale = false,
  });
  final double ratio;
  final Color primary;
  final Color overflow;
  final bool healthScale;
  @override
  Widget build(BuildContext context) => CustomPaint(
    painter: _SemiGaugePainter(
      ratio: ratio,
      primary: primary,
      overflow: overflow,
      healthScale: healthScale,
    ),
    child: const SizedBox.expand(),
  );
}

final class _SemiGaugePainter extends CustomPainter {
  const _SemiGaugePainter({
    required this.ratio,
    required this.primary,
    required this.overflow,
    required this.healthScale,
  });
  final double ratio;
  final Color primary;
  final Color overflow;
  final bool healthScale;
  @override
  void paint(Canvas canvas, Size size) {
    final diameter = math.min(size.width * .90, size.height * 1.62);
    final rect = Rect.fromCenter(
      center: Offset(size.width / 2, size.height - 3),
      width: diameter,
      height: diameter,
    );
    final track = Paint()
      ..color = FluviVisualTokens.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = math.max(6, diameter * .10)
      ..strokeCap = StrokeCap.round;
    canvas.drawArc(rect, math.pi, math.pi, false, track);
    final normalized = ratio.isFinite ? ratio.clamp(0.0, 1.20).toDouble() : 0.0;
    final progress = Paint()
      ..color = ratio > 1 ? overflow : primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = track.strokeWidth
      ..strokeCap = StrokeCap.round;
    if (healthScale) {
      const bands = <(double, Color)>[
        (.75, FluviVisualTokens.budgetProgressHealthy),
        (.15, FluviVisualTokens.budgetProgressWarning),
        (.30, FluviVisualTokens.budgetProgressDanger),
      ];
      var start = 0.0;
      for (final band in bands) {
        final end = math.min(start + band.$1, normalized);
        if (end > start) {
          progress.color = band.$2;
          canvas.drawArc(
            rect,
            math.pi + math.pi * (start / 1.20),
            math.pi * ((end - start) / 1.20),
            false,
            progress,
          );
        }
        start += band.$1;
      }
    } else {
      canvas.drawArc(
        rect,
        math.pi,
        math.pi * (normalized / 1.20),
        false,
        progress,
      );
    }
    final angle = math.pi + math.pi * (normalized / 1.20);
    final radius = diameter / 2;
    final marker = Offset(
      rect.center.dx + math.cos(angle) * radius,
      rect.center.dy + math.sin(angle) * radius,
    );
    canvas.drawCircle(
      marker,
      track.strokeWidth * .33,
      Paint()..color = FluviVisualTokens.surface,
    );
    canvas.drawCircle(
      marker,
      track.strokeWidth * .20,
      Paint()
        ..color = healthScale && ratio <= 1
            ? (ratio < .75
                  ? FluviVisualTokens.budgetProgressHealthy
                  : ratio <= .90
                  ? FluviVisualTokens.budgetProgressWarning
                  : overflow)
            : progress.color,
    );
  }

  @override
  bool shouldRepaint(covariant _SemiGaugePainter old) =>
      old.ratio != ratio ||
      old.primary != primary ||
      old.overflow != overflow ||
      old.healthScale != healthScale;
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
String _signedPp(double value) =>
    '${value < 0 ? '−' : '+'}${value.abs().round()}';
