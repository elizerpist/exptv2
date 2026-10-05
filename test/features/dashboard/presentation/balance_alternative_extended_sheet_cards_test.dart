import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_extended_sheet_cards.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_visual_tokens.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_extended_sheet_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/fluvi_topographic_wave_chart.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'BAL-YEAR-02: annual income/expense pairs reserve ten percent more breathing room while labels remain readable',
    () {
      expect(
        BalanceAlternativeHtmlTokens.annualLegendSize,
        greaterThan(BalanceAlternativeHtmlTokens.logical(15)),
      );
      expect(
        BalanceAlternativeHtmlTokens.annualClosingBarWidthFor(
          plotWidth: 360,
          bucketCount: 12,
        ),
        greaterThan(BalanceAlternativeHtmlTokens.logical(16)),
      );
      expect(
        BalanceAlternativeHtmlTokens.annualIncomeExpenseBarWidthFor(
          plotWidth: 360,
          bucketCount: 12,
        ),
        closeTo(
          (360 / 12 * .756 -
                  BalanceAlternativeHtmlTokens.annualIncomeExpenseBarGap) /
              2,
          .001,
        ),
        reason:
            'The pair fraction is exactly 10% narrower than the earlier .84 '
            'allocation, leaving deliberate month-to-month space.',
      );
      expect(
        2 *
                BalanceAlternativeHtmlTokens.annualIncomeExpenseBarWidthFor(
                  plotWidth: 360,
                  bucketCount: 12,
                ) +
            BalanceAlternativeHtmlTokens.annualIncomeExpenseBarGap,
        lessThanOrEqualTo(360 / 12),
        reason: 'Wider paired columns must still stay within one month step.',
      );
      expect(
        BalanceAlternativeHtmlTokens.annualIncomeExpenseMonthLabelSize,
        greaterThan(BalanceAlternativeHtmlTokens.logical(20)),
      );
    },
  );

  testWidgets(
    'MTC-02/06: only the monthly Költés child receives the three additive terrain renderers',
    (tester) async {
      for (final chartPresentation in <BalanceMonthlySpendingChartPresentation>[
        BalanceMonthlySpendingChartPresentation.topographic,
        BalanceMonthlySpendingChartPresentation.reactiveSvg,
        BalanceMonthlySpendingChartPresentation.shaderAtmosphere,
      ]) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: SizedBox(
                width: 500,
                height: 420,
                child: BalanceAlternativeDailySpendCard(
                  timeScope: MonthScope(const YearMonth(year: 2026, month: 3)),
                  chartPresentation: chartPresentation,
                  presentation: BalanceAlternativeMonthlySpendPresentation(
                    points: const <BalanceAlternativeDailySpendPoint>[
                      BalanceAlternativeDailySpendPoint(
                        day: 1,
                        expenseMinor: 12000,
                      ),
                      BalanceAlternativeDailySpendPoint(
                        day: 2,
                        expenseMinor: 42000,
                      ),
                      BalanceAlternativeDailySpendPoint(
                        day: 3,
                        expenseMinor: 18000,
                      ),
                    ],
                    currentExpenseMinor: 72000,
                    previousExpenseMinor: 64000,
                  ),
                ),
              ),
            ),
          ),
        );

        expect(
          find.byKey(
            ValueKey<String>(
              'balance-monthly-spending-wave-${switch (chartPresentation) {
                BalanceMonthlySpendingChartPresentation.topographic => FluviTopographicWaveStyle.terrain.name,
                BalanceMonthlySpendingChartPresentation.reactiveSvg => FluviTopographicWaveStyle.svgReference.name,
                BalanceMonthlySpendingChartPresentation.shaderAtmosphere => FluviTopographicWaveStyle.shaderAtmosphere.name,
                BalanceMonthlySpendingChartPresentation.current => throw StateError('Current is excluded.'),
              }}',
            ),
          ),
          findsOneWidget,
        );
      }
    },
  );

  testWidgets(
    'BMR-01/02: Month savings uses a centred large metric without a separator and the Költés chart keeps the recovered insight height',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 500,
              height: 440,
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: BalanceAlternativeDailySpendCard(
                      timeScope: MonthScope(
                        const YearMonth(year: 2026, month: 8),
                      ),
                      chartPresentation:
                          BalanceMonthlySpendingChartPresentation.topographic,
                      presentation: _monthlySpendForTerrainGolden(),
                    ),
                  ),
                  const SizedBox(width: 12),
                  SizedBox(
                    width: 170,
                    child: BalanceAlternativeSavingsRingCard(
                      expandedRingMaximum: 150,
                      expandedRingHorizontalInset: 0,
                      expandedPercentageFontSize:
                          BalanceAlternativeSavingsRingCard
                              .monthYearPercentageFontSize,
                      presentation:
                          BalanceAlternativeSavingsPresentation.fromTotals(
                            incomeMinor: 500000,
                            expenseMinor: 200000,
                            retentionBasisPoints: 6000,
                          ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Javuló tendencia'), findsNothing);
      expect(find.byType(Divider), findsNothing);
      final amount = tester.widget<Text>(
        find.byKey(
          const ValueKey<String>('balance-alternative-savings-amount'),
        ),
      );
      expect(amount.style?.fontSize, greaterThanOrEqualTo(16));
      expect(
        find.byKey(const ValueKey<String>('balance-alternative-savings-ring')),
        findsOneWidget,
      );
      final chart = find.byKey(
        const ValueKey<String>('balance-monthly-spending-wave-terrain'),
      );
      expect(tester.getSize(chart).height, greaterThan(180));
    },
  );

  testWidgets(
    'BMR-03: the Monthly income/expense strip has no explanatory copy, aligns the expense metric to its end, and reuses Budget 3D chrome at the partition',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 440,
              height: 300,
              child: BalanceAlternativeIncomeExpenseStripCard(
                presentation: BalanceAlternativeIncomeExpenseStripPresentation(
                  incomeMinor: 250000,
                  expenseMinor: 750000,
                ),
              ),
            ),
          ),
        ),
      );

      expect(find.textContaining('Ebben a hónapban'), findsNothing);
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-alternative-income-expense-3d-switch',
          ),
        ),
        findsOneWidget,
      );
      final expensePanel = find.byKey(
        const ValueKey<String>('balance-alternative-expense-panel'),
      );
      final expenseAmount = find.byKey(
        const ValueKey<String>('balance-alternative-expense-amount'),
      );
      expect(
        tester.getTopRight(expenseAmount).dx,
        closeTo(tester.getTopRight(expensePanel).dx, 14),
      );
      expect(
        tester.widget<Text>(expenseAmount).style?.fontSize,
        greaterThanOrEqualTo(BalanceAlternativeHtmlTokens.logical(27)),
      );
    },
  );

  testWidgets(
    'MTC-07 visual: the original and all three additive monthly spending choices remain phone-safe and visibly distinct',
    (tester) async {
      for (final chartPresentation
          in BalanceMonthlySpendingChartPresentation.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              backgroundColor: const Color(0xfff7f8fe),
              body: Align(
                alignment: Alignment.topLeft,
                child: RepaintBoundary(
                  key: ValueKey<String>(
                    'balance-monthly-spending-${chartPresentation.name}-golden',
                  ),
                  child: SizedBox(
                    width: 360,
                    height: 360,
                    child: BalanceAlternativeDailySpendCard(
                      timeScope: MonthScope(
                        const YearMonth(year: 2026, month: 6),
                      ),
                      chartPresentation: chartPresentation,
                      presentation: _monthlySpendForTerrainGolden(),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
        await tester.pump();

        await expectLater(
          find.byKey(
            ValueKey<String>(
              'balance-monthly-spending-${chartPresentation.name}-golden',
            ),
          ),
          matchesGoldenFile(
            '../../../goldens/balance_monthly_spending_${chartPresentation.name}.png',
          ),
        );
      }
    },
  );

  testWidgets(
    'ALT-HAVI2-UI-RED: month card renders real daily, no-spend, savings and strip data',
    (tester) async {
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
                      timeScope: MonthScope(
                        const YearMonth(year: 2026, month: 3),
                      ),
                      presentation: BalanceAlternativeMonthlySpendPresentation(
                        points: const <BalanceAlternativeDailySpendPoint>[
                          BalanceAlternativeDailySpendPoint(
                            day: 1,
                            expenseMinor: 0,
                          ),
                          BalanceAlternativeDailySpendPoint(
                            day: 2,
                            expenseMinor: 22000,
                          ),
                          BalanceAlternativeDailySpendPoint(
                            day: 3,
                            expenseMinor: 0,
                          ),
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
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-month-daily-spend-plot'),
        ),
        findsOneWidget,
      );
      expect(find.text('Költésmentes'), findsOneWidget);
      expect(find.text('2'), findsOneWidget);
    },
  );

  testWidgets(
    'ALT-EVES-UI-RED: annual cards expose real closing chart and live bar/line switch',
    (tester) async {
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
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-year-closings-plot'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-alternative-year-income-expense-bars',
          ),
        ),
        findsOneWidget,
      );

      await tester.tap(
        find.byKey(
          const ValueKey<String>('balance-alternative-year-chart-mode-toggle'),
        ),
      );
      await tester.pump();
      expect(
        find.byKey(
          const ValueKey<String>(
            'balance-alternative-year-income-expense-line',
          ),
        ),
        findsOneWidget,
      );
    },
  );

  testWidgets(
    'ALT-HAVI2-UI-RED: income and expense strip retains the HTML fixed row height',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 380,
              height: 250,
              child: BalanceAlternativeIncomeExpenseStripCard(
                presentation: BalanceAlternativeIncomeExpenseStripPresentation(
                  incomeMinor: 500000,
                  expenseMinor: 200000,
                ),
              ),
            ),
          ),
        ),
      );

      final strip = find
          .descendant(
            of: find.byType(BalanceAlternativeIncomeExpenseStripCard),
            matching: find.byType(LayoutBuilder),
          )
          .last;

      expect(
        tester.getSize(strip).height,
        closeTo(BalanceAlternativeHtmlTokens.incomeExpenseStripHeight, .001),
      );
    },
  );

  testWidgets(
    'ALT-VISUAL: Havi 2 extended sheet keeps its HTML-derived card proportions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const sheet = Rect.fromLTWH(12, 12, 388, 620);
      final layout = BalanceExtendedSheetLayout.resolve(sheet);
      final mergedSavings = Rect.fromLTRB(
        layout.card4.left,
        layout.card4.top,
        layout.card5.right,
        layout.card5.bottom,
      );
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
                      layout.childInsetsFor(layout.card3),
                      BalanceAlternativeDailySpendCard(
                        timeScope: MonthScope(
                          const YearMonth(year: 2026, month: 8),
                        ),
                        presentation:
                            BalanceAlternativeMonthlySpendPresentation(
                              points: const <BalanceAlternativeDailySpendPoint>[
                                BalanceAlternativeDailySpendPoint(
                                  day: 1,
                                  expenseMinor: 0,
                                ),
                                BalanceAlternativeDailySpendPoint(
                                  day: 5,
                                  expenseMinor: 28000,
                                ),
                                BalanceAlternativeDailySpendPoint(
                                  day: 10,
                                  expenseMinor: 9000,
                                ),
                                BalanceAlternativeDailySpendPoint(
                                  day: 15,
                                  expenseMinor: 42000,
                                ),
                                BalanceAlternativeDailySpendPoint(
                                  day: 20,
                                  expenseMinor: 19000,
                                ),
                                BalanceAlternativeDailySpendPoint(
                                  day: 25,
                                  expenseMinor: 47000,
                                ),
                                BalanceAlternativeDailySpendPoint(
                                  day: 31,
                                  expenseMinor: 25000,
                                ),
                              ],
                              currentExpenseMinor: 200000,
                              previousExpenseMinor: 250000,
                            ),
                      ),
                    ),
                    _slot(
                      mergedSavings,
                      layout.childInsetsFor(mergedSavings),
                      BalanceAlternativeSavingsRingCard(
                        expandedRingMaximum: 132,
                        expandedRingHorizontalInset: 0,
                        expandedPercentageFontSize:
                            BalanceAlternativeSavingsRingCard
                                .monthYearPercentageFontSize,
                        presentation:
                            BalanceAlternativeSavingsPresentation.fromTotals(
                              incomeMinor: 500000,
                              expenseMinor: 200000,
                              retentionBasisPoints: 6000,
                            ),
                      ),
                    ),
                    _slot(
                      layout.combined,
                      layout.childInsetsFor(layout.combined),
                      BalanceAlternativeIncomeExpenseStripCard(
                        presentation:
                            BalanceAlternativeIncomeExpenseStripPresentation(
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
        matchesGoldenFile(
          '../../../goldens/balance_alternative_havi2_cards.png',
        ),
      );
    },
  );

  testWidgets(
    'ALT-VISUAL: Éves extended sheet keeps its HTML-derived card proportions',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 700));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      const sheet = Rect.fromLTWH(12, 12, 388, 620);
      final layout = BalanceExtendedSheetLayout.resolve(sheet);
      final mergedSavings = Rect.fromLTRB(
        layout.card4.left,
        layout.card4.top,
        layout.card5.right,
        layout.card5.bottom,
      );
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
                      layout.childInsetsFor(layout.card3),
                      BalanceAlternativeAnnualClosingsCard(
                        timeScope: const YearScope(2026),
                        presentation: closings,
                      ),
                    ),
                    _slot(
                      mergedSavings,
                      layout.childInsetsFor(mergedSavings),
                      BalanceAlternativeSavingsRingCard(
                        expandedRingMaximum: 132,
                        expandedRingHorizontalInset: 0,
                        expandedPercentageFontSize:
                            BalanceAlternativeSavingsRingCard
                                .monthYearPercentageFontSize,
                        presentation:
                            BalanceAlternativeSavingsPresentation.fromTotals(
                              incomeMinor: incomeExpense.incomeTotalMinor,
                              expenseMinor: incomeExpense.expenseTotalMinor,
                              retentionBasisPoints: null,
                            ),
                      ),
                    ),
                    _slot(
                      layout.combined,
                      layout.childInsetsFor(layout.combined),
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
        matchesGoldenFile(
          '../../../goldens/balance_alternative_eves_cards.png',
        ),
      );
    },
  );
}

BalanceAlternativeMonthlySpendPresentation _monthlySpendForTerrainGolden() =>
    BalanceAlternativeMonthlySpendPresentation(
      points: const <BalanceAlternativeDailySpendPoint>[
        BalanceAlternativeDailySpendPoint(day: 1, expenseMinor: 4000),
        BalanceAlternativeDailySpendPoint(day: 4, expenseMinor: 17000),
        BalanceAlternativeDailySpendPoint(day: 7, expenseMinor: 6200),
        BalanceAlternativeDailySpendPoint(day: 10, expenseMinor: 11000),
        BalanceAlternativeDailySpendPoint(day: 13, expenseMinor: 7600),
        BalanceAlternativeDailySpendPoint(day: 16, expenseMinor: 29000),
        BalanceAlternativeDailySpendPoint(day: 19, expenseMinor: 8300),
        BalanceAlternativeDailySpendPoint(day: 22, expenseMinor: 14500),
        BalanceAlternativeDailySpendPoint(day: 25, expenseMinor: 5700),
        BalanceAlternativeDailySpendPoint(day: 28, expenseMinor: 21000),
        BalanceAlternativeDailySpendPoint(day: 30, expenseMinor: 12000),
      ],
      currentExpenseMinor: 146300,
      previousExpenseMinor: 132000,
    );

Widget _slot(Rect rect, EdgeInsets padding, Widget child) =>
    Positioned.fromRect(
      rect: rect,
      child: Padding(padding: padding, child: child),
    );
