import 'package:flutter/material.dart';
import '../../application/dashboard_balance_daily_insights_projection.dart';
import '../dashboard_day_rhythm_navigation.dart';
import 'balance_day_focused_visuals.dart';
import 'balance_day_momentum_rail.dart';
import 'balance_focused_layout_geometry.dart';
import 'balance_presentation_settings.dart';

/// Day-only content inside the established Mother Card. The rail remains the
/// same element when the lower presentation or compact impact preference changes.
final class BalanceDayFocusedLayout extends StatelessWidget {
  const BalanceDayFocusedLayout({
    super.key,
    required this.presentation,
    required this.focusedPresentation,
    required this.showFocusedDayImpact,
    this.navigation,
  });
  final DashboardBalanceDailyInsightsPresentation presentation;
  final BalanceDayFocusedPresentation focusedPresentation;
  final bool showFocusedDayImpact;
  final DashboardDayRhythmNavigation? navigation;
  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, c) {
      final impactVisible =
          showFocusedDayImpact &&
          focusedPresentation != BalanceDayFocusedPresentation.dailyImpactFocus;
      return Padding(
        key: const ValueKey('balance-day-focused-layout'),
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Column(
          children: [
            SizedBox(
              key: const ValueKey('balance-day-focused-top-section'),
              height: BalanceFocusedLayoutGeometry.topSectionHeight(
                c.maxHeight,
              ),
              child: BalanceDayMomentumRail(
                key: const ValueKey('balance-day-momentum-rail'),
                presentation: presentation,
                navigation: navigation,
              ),
            ),
            Expanded(
              child: Column(
                children: [
                  Expanded(
                    key: const ValueKey('balance-day-main-visual'),
                    child: RepaintBoundary(
                      child: switch (focusedPresentation) {
                        BalanceDayFocusedPresentation.financialCompass =>
                          BalanceDayFinancialCompass(
                            momentum: presentation.momentum,
                          ),
                        BalanceDayFocusedPresentation.financialComparison =>
                          BalanceDayFinancialComparison(
                            momentum: presentation.momentum,
                          ),
                        BalanceDayFocusedPresentation.dailyImpactFocus =>
                          BalanceDayImpactFocus(impact: presentation.impact),
                      },
                    ),
                  ),
                  if (impactVisible)
                    SizedBox(
                      key: const ValueKey('balance-day-compact-impact'),
                      height: (c.maxHeight * .20).clamp(48.0, 92.0),
                      child: BalanceDayCompactImpact(
                        impact: presentation.impact,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}
