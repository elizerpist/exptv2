import 'package:fluvi/features/dashboard/application/dashboard_balance_monthly_net_distribution_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_retention_stability_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_sum_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_extended_sheet_layout.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'sum-widget',
  indexGeneration: 9,
  coreRevision: 3,
);

void main() {
  testWidgets(
    'SUM-UI: source-truth histogram, streak and stability cards render immutable live models in neutral child shells',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 760));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final distribution =
          DashboardBalanceMonthlyNetDistributionProjection.build(
            stability: _stability(),
          );
      const sheet = Rect.fromLTWH(12, 12, 388, 736);
      final layout = BalanceExtendedSheetLayout.resolve(sheet);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RepaintBoundary(
              key: const ValueKey<String>('balance-sum-cards-golden'),
              child: SizedBox(
                width: 412,
                height: 760,
                child: Stack(
                  children: <Widget>[
                    _slot(
                      layout.card3,
                      BalanceAlternativeSumHistogramCard(
                        presentation: distribution.histogram,
                      ),
                    ),
                    _slot(
                      layout.card4,
                      BalanceAlternativePositiveStreakCard(
                        presentation: distribution.longestPositiveStreak,
                      ),
                    ),
                    _slot(
                      layout.card5,
                      const BalanceAlternativeSavingsRingCard(
                        presentation: BalanceAlternativeSavingsPresentation(
                          netMinor: 620000,
                          retentionBasisPoints: 6200,
                        ),
                      ),
                    ),
                    _slot(
                      layout.combined,
                      BalanceAlternativeCashflowStabilityBandCard(
                        presentation: distribution.cashflowBand,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Havi eredmények eloszlása'), findsOneWidget);
      expect(find.text('Minden lezárt hónap nettó eredménye'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-histogram-plot'),
        ),
        findsOneWidget,
      );
      expect(find.text('A legtöbb hónap 0 Ft felett zár.'), findsOneWidget);
      expect(find.text('Leghosszabb pozitív széria'), findsOneWidget);
      expect(find.text('3'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-streak-plot'),
        ),
        findsOneWidget,
      );
      expect(find.text('Megtakarítás'), findsOneWidget);
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('Cashflow stabilitás'), findsOneWidget);
      expect(find.text('8 lezárt hónap'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-stability-band'),
        ),
        findsOneWidget,
      );
      expect(
        find.text('A havi eredményeid jellemzően ebben a sávban mozognak.'),
        findsOneWidget,
      );
      expect(
        find.text('Minden pont egy lezárt hónapot jelöl.'),
        findsOneWidget,
      );
      expect(find.byType(BalanceAlternativeHtmlCardSurface), findsNWidgets(4));

      await expectLater(
        find.byKey(const ValueKey<String>('balance-sum-cards-golden')),
        matchesGoldenFile('../../../goldens/balance_alternative_sum_cards.png'),
      );
    },
  );

  test(
    'SUM-UI: standard child shell remains neutral rather than prototype-purple',
    () {
      final decoration = BalanceAlternativeHtmlTokens.childCardDecoration();
      final border = decoration.border! as Border;
      expect(border.top.color, BalanceAlternativeHtmlTokens.childBorder);
      expect(border.top.color, isNot(const Color(0xFFA879FF)));
    },
  );

  testWidgets(
    'SUM-UI: physically constrained side and lower slots use a complete-card scale fallback without overflow',
    (tester) async {
      final distribution =
          DashboardBalanceMonthlyNetDistributionProjection.build(
            stability: _stability(),
          );
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: <Widget>[
                const SizedBox(
                  width: 86,
                  height: 61,
                  child: BalanceAlternativeSavingsRingCard(
                    minimumContentSize: Size(113, 135),
                    presentation: BalanceAlternativeSavingsPresentation(
                      netMinor: 620000,
                      retentionBasisPoints: 6200,
                    ),
                  ),
                ),
                SizedBox(
                  width: 328,
                  height: 112,
                  child: BalanceAlternativeCashflowStabilityBandCard(
                    presentation: distribution.cashflowBand,
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.text('62%'), findsOneWidget);
      expect(find.text('Cashflow stabilitás'), findsOneWidget);
    },
  );
}

DashboardBalanceStabilityPresentation _stability() =>
    DashboardBalanceStabilityPresentation(
      identity: _identity,
      timeScope: const AllTimeScope(),
      observations: <DashboardBalanceMonthlyNetObservation>[
        _observation(1, -300000),
        _observation(2, 100000),
        _observation(3, 200000),
        _observation(4, 300000),
        _observation(5, 0),
        _observation(6, -100000),
        _observation(7, 900000),
        _observation(8, 500000),
      ],
      medianNetTimesTwo: 300000,
      typicalDeviationTimesTwo: 400000,
    );

DashboardBalanceMonthlyNetObservation _observation(int month, int netMinor) =>
    DashboardBalanceMonthlyNetObservation(
      id: 'month:2025-$month',
      label: '2025 M$month',
      month: YearMonth(year: 2025, month: month),
      incomeMinor: netMinor > 0 ? netMinor : 0,
      expenseMinor: netMinor < 0 ? -netMinor : 0,
    );

Widget _slot(Rect rect, Widget child) =>
    Positioned.fromRect(rect: rect, child: child);
