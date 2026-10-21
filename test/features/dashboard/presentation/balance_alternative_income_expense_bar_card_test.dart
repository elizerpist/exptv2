import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/fluvi_clay_active_material.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_income_expense_bar_card.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_presentation_settings.dart';

void main() {
  test('Balance clay light strip is vertical and omits tiny bar nubs', () {
    final strip = FluviClayCapsulePainter.lightStripRectFor(
      const Rect.fromLTWH(0, 0, 10, 40),
    );
    expect(strip, isNotNull);
    expect(strip!.height, greaterThan(strip.width));
    expect(
      FluviClayCapsulePainter.lightStripRectFor(
        const Rect.fromLTWH(0, 0, 10, 3),
      ),
      isNull,
    );
  });

  test('Balance clay materials retain the canonical mint and coral bodies', () {
    final income = FluviClayActiveMaterial.forGradient(
      highlight: const Color(0xFF78E2C3),
      body: const Color(0xFF20CA97),
    );
    final expense = FluviClayActiveMaterial.forGradient(
      highlight: const Color(0xFFF37092),
      body: const Color(0xFFED5377),
    );
    expect(income.body, const Color(0xFF20CA97));
    expect(expense.body, const Color(0xFFED5377));
  });

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
    BalanceAlternativeIncomeExpenseBarPresentation presentation, {
    BalanceYearBarPresentation yearBarPresentation =
        BalanceYearBarPresentation.current,
  }) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: SizedBox(
            width: 282,
            height: 250,
            child: BalanceAlternativeIncomeExpenseBarCard(
              presentation: presentation,
              yearBarPresentation: yearBarPresentation,
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

  testWidgets(
    'Balance YEAR clay changes only monthly bar material and preserves group geometry',
    (tester) async {
      final presentation = chart(
        domain: BalanceAlternativeBarDomain.months,
        count: 12,
      );
      await pumpCard(tester, presentation);
      final currentFirst = tester.getRect(
        find.byKey(const ValueKey<String>('balance-alternative-bar-group-1')),
      );
      final currentLast = tester.getRect(
        find.byKey(const ValueKey<String>('balance-alternative-bar-group-12')),
      );

      await pumpCard(
        tester,
        presentation,
        yearBarPresentation: BalanceYearBarPresentation.clay3d,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-clay-bar-income-1'),
        ),
        findsOneWidget,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-clay-bar-expense-12'),
        ),
        findsOneWidget,
      );
      final clayFirst = tester.getRect(
        find.byKey(const ValueKey<String>('balance-alternative-bar-group-1')),
      );
      final clayLast = tester.getRect(
        find.byKey(const ValueKey<String>('balance-alternative-bar-group-12')),
      );
      expect(clayFirst, currentFirst);
      expect(clayLast, currentLast);
      await expectLater(
        find.byKey(
          const ValueKey<String>('balance-alternative-income-expense-bar-card'),
        ),
        matchesGoldenFile(
          '../../../goldens/balance_alternative_card3_year_clay3d.png',
        ),
      );
    },
  );

  testWidgets(
    'Balance SUM historical plot stays current when clay is selected',
    (tester) async {
      await pumpCard(
        tester,
        chart(domain: BalanceAlternativeBarDomain.years, count: 12),
        yearBarPresentation: BalanceYearBarPresentation.clay3d,
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('balance-alternative-clay-bar-income-2014')),
        findsNothing,
      );
      expect(
        find.byKey(
          const ValueKey<String>('balance-alternative-sum-plot-scroll'),
        ),
        findsOneWidget,
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
