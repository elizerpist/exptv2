import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_income_expense_bar_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';

void main() {
  BalanceAlternativeIncomeExpenseBarPresentation chart({
    required BalanceAlternativeBarDomain domain,
    required int count,
    int sourcePresentationId = 17,
  }) => BalanceAlternativeIncomeExpenseBarPresentation(
    domain: domain,
    sourcePresentationId: sourcePresentationId,
    incomeTotalMinor: 70125000,
    expenseTotalMinor: 73542000,
    groups: <BalanceAlternativeIncomeExpenseBarGroup>[
      for (var index = 0; index < count; index += 1)
        BalanceAlternativeIncomeExpenseBarGroup(
          key: domain == BalanceAlternativeBarDomain.years
              ? 2014 + index
              : index + 1,
          label: domain == BalanceAlternativeBarDomain.years
              ? '${2014 + index}'
              : <String>[
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
                ][index],
          incomeMinor: (index + 2) * 700000,
          expenseMinor: (index + 1) * 600000,
        ),
    ],
  );

  Future<void> pumpCard(
    WidgetTester tester,
    BalanceAlternativeIncomeExpenseBarPresentation presentation,
  ) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 282,
            height: 250,
            child: BalanceAlternativeIncomeExpenseBarCard(
              presentation: presentation,
            ),
          ),
        ),
      ),
    ),
  );

  testWidgets(
    'ALT2-03/04: YEAR Card 3 keeps all twelve groups inside one fixed plot',
    (tester) async {
      await pumpCard(
        tester,
        chart(domain: BalanceAlternativeBarDomain.months, count: 12),
      );

      expect(find.text('Bevétel / Kiadás'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-plot-scroll'),
        ),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-alternative-bar-group-1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey<String>('balance-alternative-bar-group-12')),
        findsOneWidget,
      );
      for (final label in <String>[
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
      ]) {
        expect(find.text(label), findsOneWidget);
      }
      final plot = tester.getRect(
        find.byKey(const ValueKey<String>('balance-alternative-chart-plot')),
      );
      expect(
        tester
            .getRect(
              find.byKey(
                const ValueKey<String>('balance-alternative-bar-group-1'),
              ),
            )
            .left,
        greaterThanOrEqualTo(plot.left),
      );
      expect(
        tester
            .getRect(
              find.byKey(
                const ValueKey<String>('balance-alternative-bar-group-12'),
              ),
            )
            .right,
        lessThanOrEqualTo(plot.right),
      );
      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_card3_year.png',
        ),
      );
    },
  );

  testWidgets(
    'ALT2-05: SUM scrolls only overflowing plot chrome and keeps newest years reachable',
    (tester) async {
      await pumpCard(
        tester,
        chart(domain: BalanceAlternativeBarDomain.years, count: 12),
      );
      await tester.pump();

      final scroll = find.byKey(
        const ValueKey<String>('balance-alternative-sum-plot-scroll'),
      );
      expect(scroll, findsOneWidget);
      expect(
        find.descendant(of: scroll, matching: find.text('Bevétel / Kiadás')),
        findsNothing,
      );
      final position = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position;
      expect(position.maxScrollExtent, greaterThan(0));
      expect(
        position.pixels,
        closeTo(position.maxScrollExtent, 0.01),
        reason: 'First overflow binding starts at the newest established year.',
      );
      expect(find.text('2025'), findsOneWidget);
      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        matchesGoldenFile('../../../goldens/balance_alternative_card3_sum.png'),
      );
    },
  );

  testWidgets('ALT2-05: SUM keeps the fixed lane when all years fit', (
    tester,
  ) async {
    await pumpCard(
      tester,
      chart(domain: BalanceAlternativeBarDomain.years, count: 2),
    );

    expect(
      find.byKey(const ValueKey<String>('balance-alternative-sum-plot-scroll')),
      findsNothing,
    );
    expect(find.text('2014'), findsOneWidget);
    expect(find.text('2015'), findsOneWidget);
  });

  testWidgets(
    'ALT2-05: a harmless SUM presentation refresh preserves user history position',
    (tester) async {
      await pumpCard(
        tester,
        chart(domain: BalanceAlternativeBarDomain.years, count: 12),
      );
      await tester.pump();
      final scroll = find.byKey(
        const ValueKey<String>('balance-alternative-sum-plot-scroll'),
      );
      await tester.drag(scroll, const Offset(40, 0));
      await tester.pump();
      final positionBefore = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;

      await pumpCard(
        tester,
        chart(
          domain: BalanceAlternativeBarDomain.years,
          count: 12,
          sourcePresentationId: 18,
        ),
      );
      await tester.pump();

      final positionAfter = tester
          .state<ScrollableState>(find.byType(Scrollable))
          .position
          .pixels;
      expect(positionAfter, closeTo(positionBefore, 0.01));
    },
  );
}
