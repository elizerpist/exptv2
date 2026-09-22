import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_primary_chart_card.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

void main() {
  const identity = DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'income|expense',
    indexGeneration: 3,
    coreRevision: 7,
  );

  testWidgets(
    'P2-PAIR-SELECTION: either paired-bar surface selects one complete financial period locally',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 260,
              child: BalancePrimaryChartCard(
                presentation: DashboardBalancePrimaryPresentation(
                  identity: identity,
                  timeScope: const AllTimeScope(),
                  mode: DashboardBalancePrimaryMode.sum,
                  incomeTotalMinor: 700000,
                  expenseTotalMinor: 400000,
                  periodPairs: const <DashboardBalancePrimaryPeriodPair>[
                    DashboardBalancePrimaryPeriodPair(
                      value: 2025,
                      incomeMinor: 300000,
                      expenseMinor: 200000,
                    ),
                    DashboardBalancePrimaryPeriodPair(
                      value: 2026,
                      incomeMinor: 400000,
                      expenseMinor: 200000,
                    ),
                  ],
                  dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(
        find.byKey(const ValueKey<String>('balance-primary-pair-chart')),
      );
      await tester.pump();
      expect(find.text('2026'), findsOneWidget);
      expect(find.text('Egyenleg  2000,00 Ft'), findsOneWidget);
    },
  );

  testWidgets(
    'P2-MONTH-SCRUB: local day selection exposes cumulative through-day values without a Summary command',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(440, 800));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final points = <DashboardBalancePrimaryDayPoint>[
        for (var day = 1; day <= 31; day += 1)
          DashboardBalancePrimaryDayPoint(
            day: day,
            incomeMinor: day >= 18 ? 707000 : 0,
            expenseMinor: day >= 18 ? 382460 : 0,
          ),
      ];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 400,
              height: 260,
              child: BalancePrimaryChartCard(
                presentation: DashboardBalancePrimaryPresentation(
                  identity: identity,
                  timeScope: const MonthScope(YearMonth(year: 2026, month: 7)),
                  mode: DashboardBalancePrimaryMode.month,
                  incomeTotalMinor: 707000,
                  expenseTotalMinor: 382460,
                  periodPairs: const <DashboardBalancePrimaryPeriodPair>[],
                  dailyPoints: points,
                ),
              ),
            ),
          ),
        ),
      );

      final chart = tester.getRect(
        find.byKey(const ValueKey<String>('balance-primary-month-chart')),
      );
      await tester.tapAt(
        Offset(chart.left + chart.width * 17 / 30, chart.center.dy),
      );
      await tester.pump();
      expect(find.text('Bevétel eddig  7070,00 Ft'), findsOneWidget);
      expect(find.text('Kiadás eddig  3824,60 Ft'), findsOneWidget);
      expect(find.text('Egyenleg  3245,40 Ft'), findsOneWidget);
    },
  );

  testWidgets(
    'P2-COMPACT-SURFACE: a collapsed zone2 never clips a primary chart or exposes a false hit surface',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 89,
              height: 83,
              child: BalancePrimaryChartCard(
                presentation: DashboardBalancePrimaryPresentation(
                  identity: identity,
                  timeScope: const AllTimeScope(),
                  mode: DashboardBalancePrimaryMode.sum,
                  incomeTotalMinor: 700000,
                  expenseTotalMinor: 400000,
                  periodPairs: const <DashboardBalancePrimaryPeriodPair>[
                    DashboardBalancePrimaryPeriodPair(
                      value: 2026,
                      incomeMinor: 700000,
                      expenseMinor: 400000,
                    ),
                  ],
                  dailyPoints: const <DashboardBalancePrimaryDayPoint>[],
                ),
              ),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey<String>('balance-primary-compact-surface')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
