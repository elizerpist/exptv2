import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../dashboard_day_rhythm_navigation.dart';
import 'balance_day_focused_visuals.dart';
import 'balance_daily_month_impact_presentation.dart';
import 'balance_daily_month_impact_ribbon.dart';
import 'balance_day_ratio_comparison.dart';
import 'balance_day_performance_index_presentation.dart';
import 'balance_day_performance_index_view.dart';
import 'balance_day_performance_horizontal_meter_view.dart';
import 'balance_day_ratio_presentation.dart';
import 'balance_day_momentum_rail.dart';
import 'balance_focused_layout_geometry.dart';
import 'balance_focused_cascade.dart';
import 'balance_presentation_settings.dart';

/// Controlled Day content: a shared avatar allocation, one main visual and a
/// stable bottom rhythm element owned by the existing temporal navigator.
final class BalanceDayFocusedLayout extends StatelessWidget {
  const BalanceDayFocusedLayout({
    super.key,
    required this.presentation,
    required this.focusedPresentation,
    required this.showFocusedDayImpact,
    this.ratioPresentation = BalanceDayRatioPresentation.coverage,
    this.ratioViewPresentation = BalanceDayRatioViewPresentation.dualGauge,
    this.performanceVisualPresentation =
        BalanceDayPerformanceVisualPresentation.semicircle,
    this.navigation,
    this.onFocusedPresentationChanged,
  });
  final DashboardBalanceDailyInsightsPresentation presentation;
  final BalanceDayFocusedPresentation focusedPresentation;
  // Retained constructor compatibility; the focused UI no longer uses 7-day impact.
  final bool showFocusedDayImpact;
  final BalanceDayRatioPresentation ratioPresentation;
  final BalanceDayRatioViewPresentation ratioViewPresentation;
  final BalanceDayPerformanceVisualPresentation performanceVisualPresentation;
  final DashboardDayRhythmNavigation? navigation;
  final ValueChanged<BalanceDayFocusedPresentation>?
  onFocusedPresentationChanged;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      return Padding(
        key: const ValueKey('balance-day-focused-layout'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: BalanceFocusedCascadeColumn(
          horizontalPadding: 12,
          children: [
            SizedBox(
              key: const ValueKey('balance-day-focused-top-section'),
              height: BalanceFocusedLayoutGeometry.topSectionHeight(
                c.maxHeight,
              ),
              child: _selector(
                BalanceFocusedLayoutGeometry.topSectionHeight(c.maxHeight),
                c.maxWidth - 24,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    key: const ValueKey('balance-day-main-visual'),
                    child: RepaintBoundary(
                      child: LayoutBuilder(
                        builder: (context, bounds) {
                          late final performancePresentation =
                              BalanceDayPerformanceIndexPresentation.fromMomentum(
                                presentation.momentum,
                              );
                          if (focusedPresentation ==
                              BalanceDayFocusedPresentation
                                  .monthlyNetMarginImpact) {
                            return BalanceDailyMonthImpactView(
                              key: const ValueKey(
                                'balance-day-month-impact-view',
                              ),
                              presentation:
                                  BalanceDailyMonthImpactPresentation.fromData(
                                    presentation.monthImpact,
                                  ),
                            );
                          }
                          if (focusedPresentation ==
                                  BalanceDayFocusedPresentation
                                      .dailyImpactFocus &&
                              ratioViewPresentation ==
                                  BalanceDayRatioViewPresentation
                                      .performanceIndex &&
                              performanceVisualPresentation ==
                                  BalanceDayPerformanceVisualPresentation
                                      .horizontalMeter) {
                            return BalanceDayPerformanceHorizontalMeterView(
                              key: const ValueKey(
                                'balance-day-performance-horizontal-meter',
                              ),
                              presentation: performancePresentation,
                            );
                          }
                          return FittedBox(
                            fit: BoxFit.scaleDown,
                            child: SizedBox(
                              width: bounds.maxWidth,
                              // Preserve the visual's material and typography at
                              // very short phone bounds without clipping it.
                              height: math.max(
                                focusedPresentation ==
                                        BalanceDayFocusedPresentation
                                            .dailyImpactFocus
                                    ? 170.0
                                    : 140.0,
                                bounds.maxHeight,
                              ),
                              child: switch (focusedPresentation) {
                                BalanceDayFocusedPresentation
                                    .monthlyNetMarginImpact =>
                                  BalanceDailyMonthImpactView(
                                    presentation:
                                        BalanceDailyMonthImpactPresentation.fromData(
                                          presentation.monthImpact,
                                        ),
                                  ),
                                BalanceDayFocusedPresentation
                                    .financialCompass =>
                                  BalanceDayFinancialCompass(
                                    momentum: presentation.momentum,
                                  ),
                                BalanceDayFocusedPresentation
                                    .financialComparison =>
                                  BalanceDayFinancialComparison(
                                    momentum: presentation.momentum,
                                  ),
                                BalanceDayFocusedPresentation
                                    .dailyImpactFocus =>
                                  ratioViewPresentation ==
                                          BalanceDayRatioViewPresentation
                                              .performanceIndex
                                      ? BalanceDayPerformanceIndexView(
                                          presentation: performancePresentation,
                                        )
                                      : BalanceDayRatioComparisonView(
                                          presentation:
                                              BalanceDayRatioComparisonPresentation.fromMomentum(
                                                presentation.momentum,
                                                mode: ratioPresentation,
                                              ),
                                        ),
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              key: const ValueKey('balance-day-focused-bottom-section'),
              height: BalanceFocusedLayoutGeometry.dayMomentumRailHeight(
                c.maxHeight,
              ),
              child: BalanceDayMomentumRail(
                key: const ValueKey('balance-day-momentum-rail'),
                presentation: presentation,
                navigation: navigation,
                compact: true,
              ),
            ),
          ],
        ),
      );
    },
  );
  Widget _selector(double height, double width) {
    final selected = focusedPresentation;
    final values = BalanceDayFocusedPresentation.values;
    final selectedSlot = (values.length - 1) ~/ 2;
    final order = List.generate(
      values.length,
      (slot) =>
          values[(selected.index + slot - selectedSlot + values.length) %
              values.length],
    );
    final diameter = math.min(
      math.min(56.0, math.max(18.0, height - 24)),
      width / (1 + .76 * (values.length - 1) + .5),
    );
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Flexible(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final item in order)
                Semantics(
                  button: true,
                  selected: item == selected,
                  label: item.tunerLabel,
                  child: GestureDetector(
                    key: ValueKey('balance-day-perspective-${item.name}'),
                    onTap: onFocusedPresentationChanged == null
                        ? null
                        : () => onFocusedPresentationChanged!(item),
                    child: Container(
                      width: item == selected ? diameter : diameter * .76,
                      height: item == selected ? diameter : diameter * .76,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: item == selected
                              ? const [
                                  Color(0xfff5f0ff),
                                  Color(0xffd9c9f2),
                                  Color(0xffc7b0e6),
                                ]
                              : const [Color(0xfffaf8ff), Color(0xffeee8f7)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(
                              0xff75618e,
                            ).withValues(alpha: item == selected ? .18 : .09),
                            blurRadius: 7,
                            offset: const Offset(1, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        switch (item) {
                          BalanceDayFocusedPresentation.financialCompass =>
                            Icons.my_location_rounded,
                          BalanceDayFocusedPresentation.financialComparison =>
                            Icons.account_balance_wallet_rounded,
                          BalanceDayFocusedPresentation.dailyImpactFocus =>
                            Icons.insights_rounded,
                          BalanceDayFocusedPresentation
                              .monthlyNetMarginImpact =>
                            Icons.swap_horiz_rounded,
                        },
                        size: diameter * .45,
                        color: item == selected
                            ? const Color(0xff6c479f)
                            : const Color(0xffa292ba),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
        if (height >= 42)
          Padding(
            padding: const EdgeInsets.only(top: 6, bottom: 5),
            child: Text(
              selected.tunerLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700),
            ),
          ),
      ],
    );
  }
}
