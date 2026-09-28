import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_extended_sheet_layout.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ALT-HAVI2-UI-RED: month card renders real daily, no-spend, savings and strip data', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 600,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: BalanceAlternativeDailySpendCard(
                    timeScope: MonthScope(const YearMonth(year: 2026, month: 3)),
                    presentation: BalanceAlternativeMonthlySpendPresentation(
                      points: const <BalanceAlternativeDailySpendPoint>[
                        BalanceAlternativeDailySpendPoint(day: 1, expenseMinor: 0),
                        BalanceAlternativeDailySpendPoint(day: 2, expenseMinor: 22000),
                        BalanceAlternativeDailySpendPoint(day: 3, expenseMinor: 0),
                      ],
                      currentExpenseMinor: 22000,
                      previousExpenseMinor: 44000,
                    ),
                  ),
                ),
                const SizedBox(
                  height: 150,
                  child: BalanceAlternativeNoSpendCard(noSpendDayCount: 2),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Költés'), findsOneWidget);
    expect(find.text('március'), findsOneWidget);
    expect(find.text('↓ 50%'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('balance-alternative-month-daily-spend-plot')), findsOneWidget);
    expect(find.text('Költésmentes'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('ALT-EVES-UI-RED: annual cards expose real closing chart and live bar/line switch', (
    tester,
  ) async {
    final incomeExpense = BalanceAlternativeIncomeExpenseBarPresentation(
      domain: BalanceAlternativeBarDomain.months,
      groups: <BalanceAlternativeIncomeExpenseBarGroup>[
        for (var month = 1; month <= 12; month += 1)
          BalanceAlternativeIncomeExpenseBarGroup(
            key: month,
            label: 'M$month',
            incomeMinor: month * 10000,
            expenseMinor: month * 5000,
          ),
      ],
      incomeTotalMinor: 780000,
      expenseTotalMinor: 330000,
      sourcePresentationId: 1,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 500,
            height: 500,
            child: Column(
              children: <Widget>[
                Expanded(
                  child: BalanceAlternativeAnnualClosingsCard(
                    timeScope: const YearScope(2026),
                    presentation: BalanceAlternativeYearClosingsPresentation(
                      buckets: <BalanceAlternativeYearClosingBucket>[
                        for (var month = 1; month <= 12; month += 1)
                          BalanceAlternativeYearClosingBucket(
                            label: 'M$month',
                            incomeMinor: month * 10000,
                            expenseMinor: month.isEven ? 60000 : 5000,
                          ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  height: 210,
                  child: BalanceAlternativeAnnualIncomeExpenseCard(
                    presentation: incomeExpense,
                    timeScope: const YearScope(2026),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    expect(find.text('Éves alakulás'), findsOneWidget);
    expect(find.text('Havi zárások • 2026'), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('balance-alternative-year-closings-plot')), findsOneWidget);
    expect(find.byKey(const ValueKey<String>('balance-alternative-year-income-expense-bars')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey<String>('balance-alternative-year-chart-mode-toggle')));
    await tester.pump();
    expect(find.byKey(const ValueKey<String>('balance-alternative-year-income-expense-line')), findsOneWidget);
  });

  testWidgets('ALT-VISUAL: Havi 2 extended sheet keeps its HTML-derived card proportions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sheet = Rect.fromLTWH(12, 12, 388, 620);
    final layout = BalanceExtendedSheetLayout.resolve(sheet);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey<String>('balance-havi2-golden'),
            child: SizedBox(
              width: 412,
              height: 700,
              child: Stack(
                children: <Widget>[
                  _slot(
                    layout.card3,
                    BalanceAlternativeDailySpendCard(
                      timeScope: MonthScope(const YearMonth(year: 2026, month: 8)),
                      presentation: BalanceAlternativeMonthlySpendPresentation(
                        points: const <BalanceAlternativeDailySpendPoint>[
                          BalanceAlternativeDailySpendPoint(day: 1, expenseMinor: 0),
                          BalanceAlternativeDailySpendPoint(day: 5, expenseMinor: 28000),
                          BalanceAlternativeDailySpendPoint(day: 10, expenseMinor: 9000),
                          BalanceAlternativeDailySpendPoint(day: 15, expenseMinor: 42000),
                          BalanceAlternativeDailySpendPoint(day: 20, expenseMinor: 19000),
                          BalanceAlternativeDailySpendPoint(day: 25, expenseMinor: 47000),
                          BalanceAlternativeDailySpendPoint(day: 31, expenseMinor: 25000),
                        ],
                        currentExpenseMinor: 200000,
                        previousExpenseMinor: 250000,
                      ),
                    ),
                  ),
                  _slot(layout.card4, const BalanceAlternativeNoSpendCard(noSpendDayCount: 9)),
                  _slot(
                    layout.card5,
                    BalanceAlternativeSavingsRingCard(
                      presentation: BalanceAlternativeSavingsPresentation.fromTotals(
                        incomeMinor: 500000,
                        expenseMinor: 200000,
                        retentionBasisPoints: 6000,
                      ),
                    ),
                  ),
                  _slot(
                    layout.combined,
                    BalanceAlternativeIncomeExpenseStripCard(
                      presentation: BalanceAlternativeIncomeExpenseStripPresentation(
                        incomeMinor: 500000,
                        expenseMinor: 200000,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey<String>('balance-havi2-golden')),
      matchesGoldenFile('../../../goldens/balance_alternative_havi2_cards.png'),
    );
  });

  testWidgets('ALT-VISUAL: Éves extended sheet keeps its HTML-derived card proportions', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(412, 700));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    const sheet = Rect.fromLTWH(12, 12, 388, 620);
    final layout = BalanceExtendedSheetLayout.resolve(sheet);
    final closings = BalanceAlternativeYearClosingsPresentation(
      buckets: <BalanceAlternativeYearClosingBucket>[
        for (var month = 1; month <= 12; month += 1)
          BalanceAlternativeYearClosingBucket(
            label: 'M$month',
            incomeMinor: month.isEven ? 90000 : 25000,
            expenseMinor: month.isEven ? 30000 : 55000,
          ),
      ],
    );
    final incomeExpense = BalanceAlternativeIncomeExpenseBarPresentation(
      domain: BalanceAlternativeBarDomain.months,
      groups: <BalanceAlternativeIncomeExpenseBarGroup>[
        for (var month = 1; month <= 12; month += 1)
          BalanceAlternativeIncomeExpenseBarGroup(
            key: month,
            label: 'M$month',
            incomeMinor: month * 17000,
            expenseMinor: month * 11000,
          ),
      ],
      incomeTotalMinor: 1326000,
      expenseTotalMinor: 858000,
      sourcePresentationId: 12,
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: RepaintBoundary(
            key: const ValueKey<String>('balance-eves-golden'),
            child: SizedBox(
              width: 412,
              height: 700,
              child: Stack(
                children: <Widget>[
                  _slot(
                    layout.card3,
                    BalanceAlternativeAnnualClosingsCard(
                      timeScope: const YearScope(2026),
                      presentation: closings,
                    ),
                  ),
                  _slot(
                    layout.card4,
                    BalanceAlternativePositiveCloseCard(
                      positiveBucketCount: closings.positiveBucketCount,
                    ),
                  ),
                  _slot(
                    layout.card5,
                    BalanceAlternativeAnnualSavingsCard(
                      presentation: BalanceAlternativeSavingsPresentation.fromTotals(
                        incomeMinor: incomeExpense.incomeTotalMinor,
                        expenseMinor: incomeExpense.expenseTotalMinor,
                        retentionBasisPoints: null,
                      ),
                    ),
                  ),
                  _slot(
                    layout.combined,
                    BalanceAlternativeAnnualIncomeExpenseCard(
                      presentation: incomeExpense,
                      timeScope: const YearScope(2026),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    await expectLater(
      find.byKey(const ValueKey<String>('balance-eves-golden')),
      matchesGoldenFile('../../../goldens/balance_alternative_eves_cards.png'),
    );
  });
}

Widget _slot(Rect rect, Widget child) => Positioned.fromRect(
  rect: rect,
  child: Padding(padding: const EdgeInsets.all(3), child: child),
);
