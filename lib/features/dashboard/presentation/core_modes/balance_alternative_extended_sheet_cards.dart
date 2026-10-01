import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../prepared/data/dashboard_prepared_formatter.dart';
import '../../time_navigation/domain/ledger_time_scope.dart';
import '../../time_navigation/presentation/time_label_formatter.dart';
import 'balance_alternative_scope_presentation.dart';
import 'balance_alternative_visual_tokens.dart';

/// Shared render-only switch for the Balance extended-sheet child shells.
/// The scope deliberately owns no financial data or layout geometry: turning
/// chrome off keeps every card allocation and its content in the Mother Card.
final class BalanceAlternativeChildCardScope extends InheritedWidget {
  const BalanceAlternativeChildCardScope({
    super.key,
    required this.usesChildCards,
    required super.child,
  });

  final bool usesChildCards;

  static bool usesChildCardsOf(BuildContext context) =>
      context
          .dependOnInheritedWidgetOfExactType<
            BalanceAlternativeChildCardScope
          >()
          ?.usesChildCards ??
      true;

  @override
  bool updateShouldNotify(BalanceAlternativeChildCardScope oldWidget) =>
      oldWidget.usesChildCards != usesChildCards;
}

/// Shared exact child shell from Havi 2 / Éves in the canonical HTML. The
/// child renderers below own data binding only; bounds/gutters remain owned by
/// the alternative Balance body layout.
final class BalanceAlternativeHtmlCardSurface extends StatelessWidget {
  const BalanceAlternativeHtmlCardSurface({
    super.key,
    required this.child,
    this.minimumContentSize,
  });

  final Widget child;
  final Size? minimumContentSize;

  @override
  Widget build(BuildContext context) {
    final content = LayoutBuilder(
      builder: (context, constraints) {
        final minimum = minimumContentSize;
        if (minimum == null ||
            (constraints.maxWidth +
                        BalanceAlternativeHtmlTokens
                            .directContentMinimumTolerance >=
                    minimum.width &&
                constraints.maxHeight +
                        BalanceAlternativeHtmlTokens
                            .directContentMinimumTolerance >=
                    minimum.height)) {
          return child;
        }
        // Test/preview hosts can deliberately provide a smaller-than-device
        // content body. Preserve the authored visual hierarchy by scaling a
        // complete source-faithful composition rather than overflowing,
        // while production-size cards continue through the direct path.
        return FittedBox(
          fit: BoxFit.contain,
          alignment: Alignment.center,
          child: SizedBox(
            width: minimum.width,
            height: minimum.height,
            child: child,
          ),
        );
      },
    );
    if (!BalanceAlternativeChildCardScope.usesChildCardsOf(context)) {
      return content;
    }
    return DecoratedBox(
      key: const ValueKey<String>('balance-alternative-child-card-shell'),
      decoration: BalanceAlternativeHtmlTokens.childCardDecoration(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(
          BalanceAlternativeHtmlTokens.childBorderRadius,
        ),
        child: content,
      ),
    );
  }
}

/// Havi 2's dominant, data-driven daily-spend time chart.
final class BalanceAlternativeDailySpendCard extends StatelessWidget {
  const BalanceAlternativeDailySpendCard({
    super.key,
    required this.presentation,
    required this.timeScope,
  });

  final BalanceAlternativeMonthlySpendPresentation presentation;
  final LedgerTimeScope timeScope;

  @override
  Widget build(BuildContext context) {
    final change = presentation.expenseChangeBasisPoints;
    final lowerSpend = change != null && change < 0;
    final percentage = change == null
        ? '—'
        : '${lowerSpend ? '↓' : '↑'} ${(change.abs() / 100).round()}%';
    final scopeLabel = switch (timeScope) {
      MonthScope(:final value) => DashboardTimeLabelFormatter.monthName(
        value.month,
      ),
      _ => '',
    };
    return BalanceAlternativeHtmlCardSurface(
      minimumContentSize:
          BalanceAlternativeHtmlTokens.extendedSheetPrimaryCardMinimumSize,
      child: Padding(
        padding: BalanceAlternativeHtmlTokens.dailyCardPadding,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: BalanceAlternativeHtmlTokens.dailyHeaderHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _AlternativeTallIcon(icon: Icons.trending_down_rounded),
                  SizedBox(width: BalanceAlternativeHtmlTokens.logical(15)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Költés',
                          style: _text(
                            BalanceAlternativeHtmlTokens.dailyTitleSize,
                            BalanceAlternativeHtmlTokens.textPrimary,
                            FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        SizedBox(
                          height: BalanceAlternativeHtmlTokens.logical(9),
                        ),
                        Text(
                          scopeLabel,
                          style: _text(
                            BalanceAlternativeHtmlTokens.dailySubtitleSize,
                            BalanceAlternativeHtmlTokens.textSecondary,
                            FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: BalanceAlternativeHtmlTokens.dailyHeaderHeight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.topRight,
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          maxWidth: BalanceAlternativeHtmlTokens.logical(188),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: <Widget>[
                            Text(
                              percentage,
                              textAlign: TextAlign.right,
                              style: _text(
                                BalanceAlternativeHtmlTokens
                                    .dailyComparisonSize,
                                lowerSpend
                                    ? BalanceAlternativeHtmlTokens.positive
                                    : BalanceAlternativeHtmlTokens.purple,
                                FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            SizedBox(
                              height: BalanceAlternativeHtmlTokens.logical(5),
                            ),
                            Text(
                              change == null
                                  ? 'Nincs összehasonlítható előző időszak'
                                  : lowerSpend
                                  ? 'alacsonyabb, mint az előző hónapban'
                                  : 'magasabb, mint az előző hónapban',
                              textAlign: TextAlign.right,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: _text(
                                BalanceAlternativeHtmlTokens.dailyBodySize,
                                BalanceAlternativeHtmlTokens.textSecondary,
                                FontWeight.w500,
                                height: 1.18,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.dailyGap),
            Expanded(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const ValueKey<String>(
                    'balance-alternative-month-daily-spend-plot',
                  ),
                  painter: _DailySpendPainter(points: presentation.points),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.dailyGap),
            _DailySpendInsight(
              lowerSpend: lowerSpend,
              hasComparison: change != null,
            ),
          ],
        ),
      ),
    );
  }
}

final class _AlternativeTallIcon extends StatelessWidget {
  const _AlternativeTallIcon({required this.icon});

  final IconData icon;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: BalanceAlternativeHtmlTokens.dailyIconWidth,
    height: BalanceAlternativeHtmlTokens.dailyIconHeight,
    child: Align(
      alignment: Alignment.topCenter,
      child: Icon(
        icon,
        size: BalanceAlternativeHtmlTokens.dailyIconWidth,
        color: BalanceAlternativeHtmlTokens.purple,
      ),
    ),
  );
}

final class _DailySpendInsight extends StatelessWidget {
  const _DailySpendInsight({
    required this.lowerSpend,
    required this.hasComparison,
  });

  final bool lowerSpend;
  final bool hasComparison;

  @override
  Widget build(BuildContext context) => SizedBox(
    height: BalanceAlternativeHtmlTokens.dailyInsightHeight,
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(
          BalanceAlternativeHtmlTokens.dailyInsightRadius,
        ),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[Color(0xFFEFFBF5), Color(0xFFE5F8EF)],
        ),
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: BalanceAlternativeHtmlTokens.logical(18),
          vertical: BalanceAlternativeHtmlTokens.logical(15),
        ),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxHeight <
                BalanceAlternativeHtmlTokens.logical(40)) {
              return Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    lowerSpend ? 'Javuló tendencia' : 'Növekvő költés',
                    style: _text(
                      BalanceAlternativeHtmlTokens.dailyInsightTitleSize,
                      BalanceAlternativeHtmlTokens.textPrimary,
                      FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              );
            }
            return Row(
              children: <Widget>[
                DecoratedBox(
                  decoration: const BoxDecoration(
                    color: BalanceAlternativeHtmlTokens.positiveLight,
                    shape: BoxShape.circle,
                  ),
                  child: SizedBox.square(
                    dimension:
                        BalanceAlternativeHtmlTokens.dailyInsightIconExtent,
                    child: Icon(
                      lowerSpend
                          ? Icons.trending_down_rounded
                          : Icons.trending_up_rounded,
                      color: BalanceAlternativeHtmlTokens.positive,
                      size: BalanceAlternativeHtmlTokens.logical(29),
                    ),
                  ),
                ),
                SizedBox(width: BalanceAlternativeHtmlTokens.logical(14)),
                Expanded(
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: BalanceAlternativeHtmlTokens.logical(188),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            !hasComparison
                                ? 'Nincs összehasonlítás'
                                : lowerSpend
                                ? 'Javuló tendencia'
                                : 'Növekvő költés',
                            style: _text(
                              BalanceAlternativeHtmlTokens
                                  .dailyInsightTitleSize,
                              BalanceAlternativeHtmlTokens.textPrimary,
                              FontWeight.w800,
                              height: 1,
                            ),
                          ),
                          SizedBox(
                            height: BalanceAlternativeHtmlTokens.logical(7),
                          ),
                          Text(
                            !hasComparison
                                ? 'A következő összehasonlítható időszakban itt jelenik meg a változás.'
                                : lowerSpend
                                ? 'A napi költésed csökkenő tendenciát mutat az előző időszakhoz képest.'
                                : 'A napi költésed emelkedő tendenciát mutat az előző időszakhoz képest.',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: _text(
                              BalanceAlternativeHtmlTokens.dailyBodySize,
                              BalanceAlternativeHtmlTokens.supportingText,
                              FontWeight.w500,
                              height: 1.23,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}

final class BalanceAlternativeNoSpendCard extends StatelessWidget {
  const BalanceAlternativeNoSpendCard({
    super.key,
    required this.noSpendDayCount,
  });

  final int noSpendDayCount;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.extendedSheetSideCardMinimumSize,
    child: Padding(
      padding: BalanceAlternativeHtmlTokens.smallCardPadding,
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Icon(
                Icons.event_available_rounded,
                size: BalanceAlternativeHtmlTokens.logical(29),
                color: BalanceAlternativeHtmlTokens.purple,
              ),
              SizedBox(width: BalanceAlternativeHtmlTokens.logical(9)),
              Flexible(
                child: Text(
                  'Költésmentes',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    BalanceAlternativeHtmlTokens.smallTitleSize,
                    BalanceAlternativeHtmlTokens.textPrimary,
                    FontWeight.w800,
                    height: 1.05,
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            '$noSpendDayCount',
            style: _text(
              BalanceAlternativeHtmlTokens.noSpendValueSize,
              const Color(0xFF16B981),
              FontWeight.w800,
              height: .86,
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(9)),
          Text(
            'nap',
            style: _text(
              BalanceAlternativeHtmlTokens.smallBodySize,
              BalanceAlternativeHtmlTokens.textSecondary,
              FontWeight.w600,
              height: 1,
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

final class BalanceAlternativeSavingsRingCard extends StatelessWidget {
  const BalanceAlternativeSavingsRingCard({
    super.key,
    required this.presentation,
    this.minimumContentSize,
  });

  final BalanceAlternativeSavingsPresentation presentation;
  final Size? minimumContentSize;

  @override
  Widget build(BuildContext context) {
    final ratio = presentation.retentionBasisPoints;
    final percentage = ratio == null ? null : ratio / 10000;
    final label = ratio == null ? '—' : '${(ratio / 100).round()}%';
    return BalanceAlternativeHtmlCardSurface(
      minimumContentSize:
          minimumContentSize ??
          BalanceAlternativeHtmlTokens.extendedSheetSideCardMinimumSize,
      child: Padding(
        padding: BalanceAlternativeHtmlTokens.smallCardPadding,
        child: Column(
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(
                  Icons.savings_rounded,
                  size: BalanceAlternativeHtmlTokens.logical(29),
                  color: BalanceAlternativeHtmlTokens.purple,
                ),
                SizedBox(width: BalanceAlternativeHtmlTokens.logical(9)),
                Expanded(
                  child: Text(
                    'Megtakarítás',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: _text(
                      BalanceAlternativeHtmlTokens.smallTitleSize,
                      BalanceAlternativeHtmlTokens.textPrimary,
                      FontWeight.w800,
                      height: 1.05,
                    ),
                  ),
                ),
              ],
            ),
            const Spacer(),
            SizedBox.square(
              dimension: BalanceAlternativeHtmlTokens.smallRingSize,
              child: CustomPaint(
                painter: _SavingsRingPainter(value: percentage ?? 0),
                child: Center(
                  child: Text(
                    label,
                    style: _text(
                      BalanceAlternativeHtmlTokens.logical(24),
                      BalanceAlternativeHtmlTokens.purple,
                      FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ),
              ),
            ),
            const Spacer(),
          ],
        ),
      ),
    );
  }
}

final class BalanceAlternativeIncomeExpenseStripCard extends StatelessWidget {
  const BalanceAlternativeIncomeExpenseStripCard({
    super.key,
    required this.presentation,
  });

  final BalanceAlternativeIncomeExpenseStripPresentation presentation;

  @override
  Widget build(BuildContext context) {
    final incomePercent = presentation.incomeBasisPoints / 100;
    final expensePercent = 100 - incomePercent;
    final positive = presentation.incomeMinor >= presentation.expenseMinor;
    return BalanceAlternativeHtmlCardSurface(
      minimumContentSize:
          BalanceAlternativeHtmlTokens.extendedSheetCombinedCardMinimumSize,
      child: Padding(
        padding: BalanceAlternativeHtmlTokens.incomeExpensePadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            SizedBox(
              height: BalanceAlternativeHtmlTokens.incomeExpenseHeadingHeight,
              child: Row(
                children: <Widget>[
                  Icon(
                    Icons.swap_horiz_rounded,
                    size: BalanceAlternativeHtmlTokens.logical(30),
                    color: BalanceAlternativeHtmlTokens.purple,
                  ),
                  SizedBox(width: BalanceAlternativeHtmlTokens.logical(12)),
                  Text(
                    'Bevétel vs. Kiadás',
                    style: _text(
                      BalanceAlternativeHtmlTokens.incomeExpenseTitleSize,
                      BalanceAlternativeHtmlTokens.textPrimary,
                      FontWeight.w800,
                      height: 1,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.incomeExpenseGap),
            SizedBox(
              height: BalanceAlternativeHtmlTokens.incomeExpenseStripHeight,
              child: LayoutBuilder(
                builder: (context, constraints) => Stack(
                  clipBehavior: Clip.none,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Expanded(
                          flex: math.max(1, presentation.incomeBasisPoints),
                          child: _IncomeExpensePanel(
                            income: true,
                            value: presentation.incomeMinor,
                            percentage: incomePercent,
                          ),
                        ),
                        Expanded(
                          flex: math.max(
                            1,
                            10000 - presentation.incomeBasisPoints,
                          ),
                          child: _IncomeExpensePanel(
                            income: false,
                            value: presentation.expenseMinor,
                            percentage: expensePercent,
                          ),
                        ),
                      ],
                    ),
                    Positioned(
                      left:
                          constraints.maxWidth *
                              presentation.incomeBasisPoints /
                              10000 -
                          BalanceAlternativeHtmlTokens
                                  .incomeExpenseSwitchExtent /
                              2,
                      top:
                          (constraints.maxHeight -
                              BalanceAlternativeHtmlTokens
                                  .incomeExpenseSwitchExtent) /
                          2,
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: <BoxShadow>[
                            BoxShadow(
                              color: Color(0x1F14213A),
                              blurRadius: 6,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: SizedBox.square(
                          dimension: BalanceAlternativeHtmlTokens
                              .incomeExpenseSwitchExtent,
                          child: Icon(
                            Icons.swap_horiz_rounded,
                            color: const Color(0xFF52658A),
                            size: BalanceAlternativeHtmlTokens.logical(30),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.incomeExpenseGap),
            Expanded(
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  positive
                      ? 'Ebben a hónapban a bevételed meghaladja a kiadásaidat.'
                      : 'Ebben a hónapban a kiadásaid meghaladják a bevételedet.',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    BalanceAlternativeHtmlTokens.incomeExpenseBodySize,
                    BalanceAlternativeHtmlTokens.supportingText,
                    FontWeight.w500,
                    height: 1.25,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

final class _IncomeExpensePanel extends StatelessWidget {
  const _IncomeExpensePanel({
    required this.income,
    required this.value,
    required this.percentage,
  });

  final bool income;
  final int value;
  final double percentage;

  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      borderRadius: BorderRadius.horizontal(
        left: income
            ? Radius.circular(
                BalanceAlternativeHtmlTokens.incomeExpenseStripRadius,
              )
            : Radius.zero,
        right: income
            ? Radius.zero
            : Radius.circular(
                BalanceAlternativeHtmlTokens.incomeExpenseStripRadius,
              ),
      ),
      border: income
          ? null
          : Border(
              left: BorderSide(
                color: Colors.white,
                width: BalanceAlternativeHtmlTokens.logical(6),
              ),
            ),
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: income
            ? const <Color>[
                BalanceAlternativeHtmlTokens.incomeStripStart,
                BalanceAlternativeHtmlTokens.incomeStripEnd,
              ]
            : const <Color>[
                BalanceAlternativeHtmlTokens.expenseStripStart,
                BalanceAlternativeHtmlTokens.expenseStripEnd,
              ],
      ),
    ),
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        BalanceAlternativeHtmlTokens.logical(13),
        BalanceAlternativeHtmlTokens.logical(18),
        BalanceAlternativeHtmlTokens.logical(13),
        BalanceAlternativeHtmlTokens.logical(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Text(
            income ? 'Bevétel' : 'Kiadás',
            style: _text(
              BalanceAlternativeHtmlTokens.smallBodySize,
              const Color(0xFF1B3560),
              FontWeight.w600,
              height: 1,
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(5)),
          Text(
            DashboardPreparedFormatter.compactAmountMinor(value),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(
              BalanceAlternativeHtmlTokens.incomeExpenseValueSize,
              BalanceAlternativeHtmlTokens.textPrimary,
              FontWeight.w800,
              height: 1,
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(5)),
          Text(
            '${percentage.round()}%',
            style: _text(
              BalanceAlternativeHtmlTokens.smallBodySize,
              const Color(0xFF395A83),
              FontWeight.w600,
              height: 1,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Éves Card 3, with the reference positive/negative monthly close bars and
/// an independently scaled cumulative line from immutable closings buckets.
final class BalanceAlternativeAnnualClosingsCard extends StatelessWidget {
  const BalanceAlternativeAnnualClosingsCard({
    super.key,
    required this.presentation,
    required this.timeScope,
  });

  final BalanceAlternativeYearClosingsPresentation presentation;
  final LedgerTimeScope timeScope;

  @override
  Widget build(BuildContext context) {
    final year = timeScope is YearScope ? (timeScope as YearScope).year : null;
    return BalanceAlternativeHtmlCardSurface(
      minimumContentSize:
          BalanceAlternativeHtmlTokens.extendedSheetPrimaryCardMinimumSize,
      child: Padding(
        padding: BalanceAlternativeHtmlTokens.annualClosingsPadding,
        child: Column(
          children: <Widget>[
            SizedBox(
              height: BalanceAlternativeHtmlTokens.annualClosingsHeadingHeight,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const _AnnualBarsIcon(),
                  SizedBox(width: BalanceAlternativeHtmlTokens.logical(15)),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Éves alakulás',
                          style: _text(
                            BalanceAlternativeHtmlTokens.annualTitleSize,
                            const Color(0xFF090E4C),
                            FontWeight.w800,
                            height: 1,
                          ),
                        ),
                        SizedBox(
                          height: BalanceAlternativeHtmlTokens.logical(8),
                        ),
                        Text(
                          'Havi zárások • ${year ?? '—'}',
                          style: _text(
                            BalanceAlternativeHtmlTokens.annualSubtitleSize,
                            BalanceAlternativeHtmlTokens.textSecondary,
                            FontWeight.w500,
                            height: 1,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.annualGap),
            Expanded(
              child: RepaintBoundary(
                child: CustomPaint(
                  key: const ValueKey<String>(
                    'balance-alternative-year-closings-plot',
                  ),
                  painter: _AnnualClosingsPainter(
                    buckets: presentation.buckets,
                  ),
                  child: const SizedBox.expand(),
                ),
              ),
            ),
            SizedBox(height: BalanceAlternativeHtmlTokens.annualGap),
            _AnnualClosingsLegend(),
          ],
        ),
      ),
    );
  }
}

final class _AnnualBarsIcon extends StatelessWidget {
  const _AnnualBarsIcon();

  @override
  Widget build(BuildContext context) => SizedBox(
    width: BalanceAlternativeHtmlTokens.dailyIconWidth,
    height: BalanceAlternativeHtmlTokens.dailyIconHeight,
    child: Align(
      alignment: Alignment.bottomCenter,
      child: FittedBox(
        fit: BoxFit.scaleDown,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: <Widget>[
            _bar(BalanceAlternativeHtmlTokens.logical(21)),
            SizedBox(width: BalanceAlternativeHtmlTokens.logical(5)),
            _bar(BalanceAlternativeHtmlTokens.logical(42)),
            SizedBox(width: BalanceAlternativeHtmlTokens.logical(5)),
            _bar(BalanceAlternativeHtmlTokens.logical(31)),
          ],
        ),
      ),
    ),
  );

  Widget _bar(double height) => Container(
    width: BalanceAlternativeHtmlTokens.logical(8),
    height: height,
    decoration: BoxDecoration(
      color: const Color(0xFF7C4DED),
      borderRadius: BorderRadius.circular(
        BalanceAlternativeHtmlTokens.logical(6),
      ),
    ),
  );
}

final class _AnnualClosingsLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => SizedBox(
    height: BalanceAlternativeHtmlTokens.annualClosingsLegendHeight,
    child: FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          _key(const Color(0xFF75DCC1), 'Pozitív zárás'),
          SizedBox(width: BalanceAlternativeHtmlTokens.logical(12)),
          _key(const Color(0xFFFF94AF), 'Negatív zárás'),
          SizedBox(width: BalanceAlternativeHtmlTokens.logical(12)),
          _lineKey(),
        ],
      ),
    ),
  );

  Widget _key(Color color, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: SizedBox.square(
          dimension: BalanceAlternativeHtmlTokens.logical(16),
        ),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(8)),
      Text(
        label,
        style: _text(
          BalanceAlternativeHtmlTokens.annualLegendSize,
          BalanceAlternativeHtmlTokens.textSecondary,
          FontWeight.w500,
          height: 1,
        ),
      ),
    ],
  );

  Widget _lineKey() => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      Container(
        width: BalanceAlternativeHtmlTokens.logical(34),
        height: BalanceAlternativeHtmlTokens.logical(6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(99),
          gradient: const LinearGradient(
            colors: <Color>[Color(0xFF8A57F2), Color(0xFF6843E8)],
          ),
        ),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(8)),
      Text(
        'Egyenleg',
        style: _text(
          BalanceAlternativeHtmlTokens.annualLegendSize,
          BalanceAlternativeHtmlTokens.textSecondary,
          FontWeight.w500,
          height: 1,
        ),
      ),
    ],
  );
}

/// Éves Card 4: real positive-close count. It intentionally remains a small
/// factual card; Card 5 owns the savings value in the reference hierarchy.
final class BalanceAlternativePositiveCloseCard extends StatelessWidget {
  const BalanceAlternativePositiveCloseCard({
    super.key,
    required this.positiveBucketCount,
  });

  final int positiveBucketCount;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.extendedSheetSideCardMinimumSize,
    child: Padding(
      padding: BalanceAlternativeHtmlTokens.smallCardPadding,
      child: Column(
        children: <Widget>[
          Icon(
            Icons.event_available_rounded,
            size: BalanceAlternativeHtmlTokens.logical(29),
            color: BalanceAlternativeHtmlTokens.purple,
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(9)),
          Text(
            'Pozitív zárás',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(
              BalanceAlternativeHtmlTokens.smallTitleSize,
              BalanceAlternativeHtmlTokens.textPrimary,
              FontWeight.w800,
              height: 1.05,
            ),
          ),
          const Spacer(),
          Text(
            '$positiveBucketCount',
            style: _text(
              BalanceAlternativeHtmlTokens.noSpendValueSize,
              BalanceAlternativeHtmlTokens.positive,
              FontWeight.w800,
              height: .86,
            ),
          ),
          SizedBox(height: BalanceAlternativeHtmlTokens.logical(9)),
          Text(
            'hónap',
            style: _text(
              BalanceAlternativeHtmlTokens.smallBodySize,
              BalanceAlternativeHtmlTokens.textSecondary,
              FontWeight.w600,
              height: 1,
            ),
          ),
          const Spacer(),
        ],
      ),
    ),
  );
}

final class BalanceAlternativeAnnualSavingsCard extends StatelessWidget {
  const BalanceAlternativeAnnualSavingsCard({
    super.key,
    required this.presentation,
  });

  final BalanceAlternativeSavingsPresentation presentation;

  @override
  Widget build(BuildContext context) => BalanceAlternativeHtmlCardSurface(
    minimumContentSize:
        BalanceAlternativeHtmlTokens.extendedSheetSideCardMinimumSize,
    child: Padding(
      padding: EdgeInsets.fromLTRB(
        BalanceAlternativeHtmlTokens.logical(19),
        BalanceAlternativeHtmlTokens.logical(22),
        BalanceAlternativeHtmlTokens.logical(19),
        BalanceAlternativeHtmlTokens.logical(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Megtakarítások',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: _text(
                    BalanceAlternativeHtmlTokens.annualSavingsTitleSize,
                    BalanceAlternativeHtmlTokens.textPrimary,
                    FontWeight.w800,
                    height: 1.06,
                  ),
                ),
              ),
              DecoratedBox(
                decoration: const BoxDecoration(
                  color: Color(0xFFE0F8EC),
                  shape: BoxShape.circle,
                ),
                child: SizedBox.square(
                  dimension: BalanceAlternativeHtmlTokens
                      .annualIncomeExpenseIconExtent,
                  child: Icon(
                    Icons.savings_rounded,
                    color: BalanceAlternativeHtmlTokens.positive,
                    size: BalanceAlternativeHtmlTokens.logical(25),
                  ),
                ),
              ),
            ],
          ),
          const Spacer(),
          Text(
            DashboardPreparedFormatter.compactAmountMinor(
              presentation.netMinor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: _text(
              BalanceAlternativeHtmlTokens.annualSavingsValueSize,
              presentation.netMinor >= 0
                  ? BalanceAlternativeHtmlTokens.positive
                  : const Color(0xFFFF5F8A),
              FontWeight.w800,
              height: 1,
            ),
          ),
          const Spacer(),
          Text(
            'félretett összeg\nebben az évben',
            style: _text(
              BalanceAlternativeHtmlTokens.smallBodySize,
              BalanceAlternativeHtmlTokens.textSecondary,
              FontWeight.w500,
              height: 1.22,
            ),
          ),
        ],
      ),
    ),
  );
}

/// Éves lower combined Card 1+2. It retains the reference mode switch while
/// mapping both its bar and line alternatives to the same prepared data.
final class BalanceAlternativeAnnualIncomeExpenseCard extends StatefulWidget {
  const BalanceAlternativeAnnualIncomeExpenseCard({
    super.key,
    required this.presentation,
    required this.timeScope,
  });

  final BalanceAlternativeIncomeExpenseBarPresentation presentation;
  final LedgerTimeScope timeScope;

  @override
  State<BalanceAlternativeAnnualIncomeExpenseCard> createState() =>
      _BalanceAlternativeAnnualIncomeExpenseCardState();
}

final class _BalanceAlternativeAnnualIncomeExpenseCardState
    extends State<BalanceAlternativeAnnualIncomeExpenseCard> {
  var _showsLine = false;

  @override
  Widget build(BuildContext context) {
    final year = widget.timeScope is YearScope
        ? (widget.timeScope as YearScope).year
        : null;
    return BalanceAlternativeHtmlCardSurface(
      minimumContentSize:
          BalanceAlternativeHtmlTokens.extendedSheetCombinedCardMinimumSize,
      child: Stack(
        children: <Widget>[
          Padding(
            padding: BalanceAlternativeHtmlTokens.annualIncomeExpensePadding,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                SizedBox(
                  height: BalanceAlternativeHtmlTokens
                      .annualIncomeExpenseHeadingHeight,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Icon(
                        Icons.bar_chart_rounded,
                        color: BalanceAlternativeHtmlTokens.purple,
                        size: BalanceAlternativeHtmlTokens
                            .annualIncomeExpenseIconExtent,
                      ),
                      SizedBox(width: BalanceAlternativeHtmlTokens.logical(15)),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text(
                              'Bevétel / Kiadás',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(
                                BalanceAlternativeHtmlTokens.annualTitleSize,
                                const Color(0xFF090E4C),
                                FontWeight.w800,
                                height: 1,
                              ),
                            ),
                            SizedBox(
                              height: BalanceAlternativeHtmlTokens.logical(8),
                            ),
                            Text(
                              'Havi összehasonlítás • ${year ?? '—'}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: _text(
                                BalanceAlternativeHtmlTokens.annualSubtitleSize,
                                BalanceAlternativeHtmlTokens.textSecondary,
                                FontWeight.w500,
                                height: 1,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(
                  height: BalanceAlternativeHtmlTokens.annualIncomeExpenseGap,
                ),
                _AnnualIncomeExpenseLegend(),
                SizedBox(
                  height: BalanceAlternativeHtmlTokens.annualIncomeExpenseGap,
                ),
                Expanded(
                  child: RepaintBoundary(
                    child: CustomPaint(
                      key: ValueKey<String>(
                        _showsLine
                            ? 'balance-alternative-year-income-expense-line'
                            : 'balance-alternative-year-income-expense-bars',
                      ),
                      painter: _AnnualIncomeExpensePainter(
                        groups: widget.presentation.groups,
                        lineMode: _showsLine,
                      ),
                      child: const SizedBox.expand(),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: BalanceAlternativeHtmlTokens.logical(15),
            right: BalanceAlternativeHtmlTokens.logical(15),
            child: Semantics(
              button: true,
              label: _showsLine
                  ? 'Oszlopdiagram mutatása'
                  : 'Vonaldiagram mutatása',
              child: IconButton(
                key: const ValueKey<String>(
                  'balance-alternative-year-chart-mode-toggle',
                ),
                tooltip: _showsLine ? 'Oszlopdiagram' : 'Vonaldiagram',
                constraints: BoxConstraints.tightFor(
                  width: BalanceAlternativeHtmlTokens
                      .annualIncomeExpenseToggleExtent,
                  height: BalanceAlternativeHtmlTokens
                      .annualIncomeExpenseToggleExtent,
                ),
                padding: EdgeInsets.zero,
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFAF8FF),
                  side: BorderSide(
                    color: BalanceAlternativeHtmlTokens.purple.withValues(
                      alpha: .45,
                    ),
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(
                      BalanceAlternativeHtmlTokens.logical(10),
                    ),
                  ),
                ),
                onPressed: () => setState(() => _showsLine = !_showsLine),
                icon: Icon(
                  _showsLine
                      ? Icons.bar_chart_rounded
                      : Icons.show_chart_rounded,
                  color: const Color(0xFF7146DB),
                  size: BalanceAlternativeHtmlTokens.logical(18),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

final class _AnnualIncomeExpenseLegend extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Row(
    children: <Widget>[
      _legendDot(
        const LinearGradient(
          colors: <Color>[Color(0xFF7C3AED), Color(0xFFA879FF)],
        ),
        'Bevétel',
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(27)),
      _legendDot(
        const LinearGradient(
          colors: <Color>[Color(0xFFFF8638), Color(0xFFF431A0)],
        ),
        'Kiadás',
      ),
    ],
  );

  Widget _legendDot(Gradient gradient, String label) => Row(
    mainAxisSize: MainAxisSize.min,
    children: <Widget>[
      DecoratedBox(
        decoration: BoxDecoration(gradient: gradient, shape: BoxShape.circle),
        child: SizedBox.square(
          dimension: BalanceAlternativeHtmlTokens.logical(18),
        ),
      ),
      SizedBox(width: BalanceAlternativeHtmlTokens.logical(9)),
      Text(
        label,
        style: _text(
          BalanceAlternativeHtmlTokens.annualIncomeExpenseLegendSize,
          BalanceAlternativeHtmlTokens.textSecondary,
          FontWeight.w500,
          height: 1,
        ),
      ),
    ],
  );
}

TextStyle _text(
  double fontSize,
  Color color,
  FontWeight weight, {
  required double height,
}) => TextStyle(
  color: color,
  fontSize: fontSize,
  fontWeight: weight,
  height: height,
  letterSpacing: -.03 * fontSize,
);

final class _DailySpendPainter extends CustomPainter {
  const _DailySpendPainter({required this.points});

  final List<BalanceAlternativeDailySpendPoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || points.isEmpty) return;
    final maxValue = math.max<int>(
      1,
      points.fold<int>(
        0,
        (value, point) => math.max(value, point.expenseMinor),
      ),
    );
    final line = Path();
    final area = Path();
    final coordinates = <Offset>[];
    for (var index = 0; index < points.length; index += 1) {
      final point = points[index];
      final x = points.length == 1
          ? size.width / 2
          : index * size.width / (points.length - 1);
      final y = size.height - point.expenseMinor / maxValue * size.height * .90;
      coordinates.add(Offset(x, y));
    }
    line.moveTo(coordinates.first.dx, coordinates.first.dy);
    for (var index = 1; index < coordinates.length; index += 1) {
      final previous = coordinates[index - 1];
      final current = coordinates[index];
      line.quadraticBezierTo(
        previous.dx + (current.dx - previous.dx) / 2,
        previous.dy,
        current.dx,
        current.dy,
      );
    }
    area
      ..addPath(line, Offset.zero)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    canvas.drawPath(
      area,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            BalanceAlternativeHtmlTokens.dailyAreaStart,
            BalanceAlternativeHtmlTokens.dailyAreaEnd,
          ],
          stops: <double>[0, 1],
        ).createShader(Offset.zero & size),
    );
    canvas.drawPath(
      line,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: <Color>[
            BalanceAlternativeHtmlTokens.purpleLineStart,
            BalanceAlternativeHtmlTokens.purpleLineEnd,
          ],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = BalanceAlternativeHtmlTokens.logical(4)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _DailySpendPainter oldDelegate) =>
      oldDelegate.points != points;
}

final class _SavingsRingPainter extends CustomPainter {
  const _SavingsRingPainter({required this.value});

  final double value;

  @override
  void paint(Canvas canvas, Size size) {
    final stroke = BalanceAlternativeHtmlTokens.logical(13);
    final rect = Offset.zero & size;
    final center = rect.center;
    final radius = (math.min(size.width, size.height) - stroke) / 2;
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = const Color(0xFFECE7FF)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke,
    );
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      math.pi * 2 * value.clamp(-1.0, 1.0),
      false,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF7C3AED), Color(0xFFA879FF)],
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(covariant _SavingsRingPainter oldDelegate) =>
      oldDelegate.value != value;
}

final class _AnnualClosingsPainter extends CustomPainter {
  const _AnnualClosingsPainter({required this.buckets});

  final List<BalanceAlternativeYearClosingBucket> buckets;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || buckets.isEmpty) return;
    final values = buckets
        .map((bucket) => bucket.netMinor)
        .toList(growable: false);
    final maxAbs = math.max(
      1,
      values.fold<int>(0, (max, item) => math.max(max, item.abs())),
    );
    final baseline = size.height * .47;
    final step = size.width / buckets.length;
    final barWidth = math.min(
      BalanceAlternativeHtmlTokens.logical(16),
      step * .54,
    );
    final cumulative = <int>[];
    var running = 0;
    for (final value in values) {
      running += value;
      cumulative.add(running);
    }
    final cumulativeAbs = math.max(
      1,
      cumulative.fold<int>(0, (max, item) => math.max(max, item.abs())),
    );
    final line = Path();
    for (var index = 0; index < values.length; index += 1) {
      final value = values[index];
      final height = value.abs() / maxAbs * size.height * .43;
      final left = index * step + (step - barWidth) / 2;
      final top = value >= 0 ? baseline - height : baseline;
      final rect = Rect.fromLTWH(left, top, barWidth, math.max(1, height));
      canvas.drawRRect(
        RRect.fromRectAndRadius(
          rect,
          Radius.circular(BalanceAlternativeHtmlTokens.logical(4)),
        ),
        Paint()
          ..shader = LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: value >= 0
                ? const <Color>[
                    BalanceAlternativeHtmlTokens.closingPositiveStart,
                    BalanceAlternativeHtmlTokens.closingPositiveEnd,
                  ]
                : const <Color>[
                    BalanceAlternativeHtmlTokens.closingNegativeStart,
                    BalanceAlternativeHtmlTokens.closingNegativeEnd,
                  ],
          ).createShader(rect),
      );
      final x = left + barWidth / 2;
      final y =
          baseline + cumulative[index] / cumulativeAbs * size.height * .38;
      if (index == 0) {
        line.moveTo(x, y);
      } else {
        final previousX = (index - 1) * step + step / 2;
        final previousY =
            baseline +
            cumulative[index - 1] / cumulativeAbs * size.height * .38;
        line.quadraticBezierTo((previousX + x) / 2, previousY, x, y);
      }
    }
    canvas.drawPath(
      line,
      Paint()
        ..shader = const LinearGradient(
          colors: <Color>[Color(0xFF925CF4), Color(0xFF6742E7)],
        ).createShader(Offset.zero & size)
        ..style = PaintingStyle.stroke
        ..strokeWidth = BalanceAlternativeHtmlTokens.logical(4)
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(covariant _AnnualClosingsPainter oldDelegate) =>
      oldDelegate.buckets != buckets;
}

final class _AnnualIncomeExpensePainter extends CustomPainter {
  const _AnnualIncomeExpensePainter({
    required this.groups,
    required this.lineMode,
  });

  final List<BalanceAlternativeIncomeExpenseBarGroup> groups;
  final bool lineMode;

  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty || groups.isEmpty) return;
    final maxValue = math.max<int>(
      1,
      groups.fold<int>(
        0,
        (maximum, group) =>
            math.max(maximum, math.max(group.incomeMinor, group.expenseMinor)),
      ),
    );
    final step = size.width / groups.length;
    final baseline = size.height - BalanceAlternativeHtmlTokens.logical(18);
    final labelPaint = TextPainter(
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    );
    final incomePath = Path();
    final expensePath = Path();
    for (var index = 0; index < groups.length; index += 1) {
      final group = groups[index];
      final xCenter = index * step + step / 2;
      final incomeHeight =
          group.incomeMinor /
          maxValue *
          (baseline - BalanceAlternativeHtmlTokens.logical(6));
      final expenseHeight =
          group.expenseMinor /
          maxValue *
          (baseline - BalanceAlternativeHtmlTokens.logical(6));
      if (lineMode) {
        final incomePoint = Offset(xCenter, baseline - incomeHeight);
        final expensePoint = Offset(xCenter, baseline - expenseHeight);
        if (index == 0) {
          incomePath.moveTo(incomePoint.dx, incomePoint.dy);
          expensePath.moveTo(expensePoint.dx, expensePoint.dy);
        } else {
          incomePath.lineTo(incomePoint.dx, incomePoint.dy);
          expensePath.lineTo(expensePoint.dx, expensePoint.dy);
        }
      } else {
        final width = math.min(
          BalanceAlternativeHtmlTokens.logical(10),
          step * .29,
        );
        _drawGradientBar(
          canvas,
          Rect.fromLTWH(
            xCenter - width - BalanceAlternativeHtmlTokens.logical(2),
            baseline - incomeHeight,
            width,
            math.max(1, incomeHeight),
          ),
          const <Color>[Color(0xFF7C3AED), Color(0xFFA879FF)],
        );
        _drawGradientBar(
          canvas,
          Rect.fromLTWH(
            xCenter + BalanceAlternativeHtmlTokens.logical(2),
            baseline - expenseHeight,
            width,
            math.max(1, expenseHeight),
          ),
          const <Color>[Color(0xFFFF8638), Color(0xFFF431A0)],
        );
      }
      labelPaint.text = TextSpan(
        text: group.label,
        style: _text(
          BalanceAlternativeHtmlTokens.logical(13),
          BalanceAlternativeHtmlTokens.textSecondary,
          FontWeight.w600,
          height: 1,
        ),
      );
      labelPaint.layout(maxWidth: step);
      labelPaint.paint(
        canvas,
        Offset(
          xCenter - labelPaint.width / 2,
          baseline + BalanceAlternativeHtmlTokens.logical(5),
        ),
      );
    }
    if (lineMode) {
      for (final entry in <(Path, Color)>[
        (incomePath, const Color(0xFF7C3AED)),
        (expensePath, const Color(0xFFF431A0)),
      ]) {
        canvas.drawPath(
          entry.$1,
          Paint()
            ..color = entry.$2
            ..style = PaintingStyle.stroke
            ..strokeWidth = BalanceAlternativeHtmlTokens.logical(4)
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round,
        );
      }
    }
  }

  void _drawGradientBar(Canvas canvas, Rect rect, List<Color> colors) {
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        rect,
        Radius.circular(BalanceAlternativeHtmlTokens.logical(4)),
      ),
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: colors,
        ).createShader(rect),
    );
  }

  @override
  bool shouldRepaint(covariant _AnnualIncomeExpensePainter oldDelegate) =>
      oldDelegate.groups != groups || oldDelegate.lineMode != lineMode;
}
