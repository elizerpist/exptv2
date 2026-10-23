import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_projection.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_alternative_scope_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_focused_chart_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_focused_layout.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_net_margin_gauge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_net_margin_presentation.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/query/data/dashboard_ledger_entry.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/local_date.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/year_month.dart';

const identity = DashboardBalancePrimaryIdentity(
  upstreamScopeKey: 'margin',
  indexGeneration: 1,
  coreRevision: 1,
);
const now = LocalDate(year: 2026, month: 10, day: 15);
DashboardLedgerEntry row(bool income, int amount, int day, int month) =>
    DashboardLedgerEntry(
      bookedLocalTimeMinutes: 0,
      id: '$income-$day-$month',
      categoryId: 'fixture',
      partnerId: 'fixture',
      direction: income ? 'income' : 'expense',
      amountMinor: amount,
      bookedLocalEpochDay: LocalDate(
        year: 2026,
        month: month,
        day: day,
      ).epochDay,
    );
BalanceAlternativeMonthPresentation source({
  int income = 60000000,
  int expense = 48000000,
  int month = 9,
  int futureIncome = 0,
  int futureExpense = 0,
}) =>
    BalanceAlternativeScopePresentation.fromLinked(
          DashboardBalanceLinkedProjection.build(
            identity: identity,
            timeScope: MonthScope(YearMonth(year: 2026, month: month)),
            selectedDirection: LedgerDirection.expense,
            logicalAsOfDate: now,
            incomeEntries: [
              row(true, income, 1, month),
              if (futureIncome != 0) row(true, futureIncome, 28, month),
            ],
            expenseEntries: [
              row(false, expense, 1, month),
              if (futureExpense != 0) row(false, futureExpense, 28, month),
            ],
          ),
        )
        as BalanceAlternativeMonthPresentation;
BalanceMonthNetMarginPresentation margin(
  BalanceAlternativeMonthPresentation source,
) => BalanceMonthNetMarginPresentation.fromChart(
  BalanceMonthFocusedChartPresentation.fromPrimary(
    source.primary!,
    logicalAsOfDate: source.logicalAsOfDate,
  ),
);
Future<void> pump(
  WidgetTester tester,
  BalanceAlternativeMonthPresentation source, {
  Size size = const Size(390, 360),
}) => tester.pumpWidget(
  MaterialApp(
    theme: ThemeData(fontFamily: 'Inter'),
    home: Scaffold(
      body: Center(
        child: RepaintBoundary(
          key: const ValueKey('month-margin-capture'),
          child: SizedBox.fromSize(
            size: size,
            child: ColoredBox(
              color: Colors.white,
              child: BalanceMonthFocusedLayout(
                presentation: source,
                initialPerspective: BalanceMonthPerspective.spendingLevel,
              ),
            ),
          ),
        ),
      ),
    ),
  ),
);
void main() {
  setUpAll(() async {
    await (FontLoader(
      'Inter',
    )..addFont(rootBundle.load('assets/fonts/inter/InterVariable.ttf'))).load();
    await (FontLoader(
      'MaterialIcons',
    )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
  });
  for (final entry in [
    (48000000, 20.0, '+20,0%'),
    (72000000, -20.0, '−20,0%'),
    (60000000, 0.0, '0,0%'),
    (0, 100.0, '+100,0%'),
    (150000000, -150.0, '−150,0%'),
  ]) {
    test(
      'monthly expense ${entry.$1} maps signed net margin on shared scale',
      () {
        final model = margin(source(expense: entry.$1));
        expect(model.incomeMinor, 60000000);
        expect(model.expenseMinor, entry.$1);
        expect(model.netMinor, 60000000 - entry.$1);
        expect(model.netMarginPercent, entry.$2);
        expect(model.primaryLabel, entry.$3);
        expect(
          model.scale.visualProgress,
          ((entry.$2 + 100) / 200).clamp(0, 1),
        );
        expect(model.scale.neutralProgress, .5);
        expect(model.hasVisualOverflow, entry.$2 < -100);
        expect(model.isPositive, entry.$2 > 0);
        expect(model.isNegative, entry.$2 < 0);
        expect(model.isNeutral, entry.$2 == 0);
      },
    );
  }
  test('zero revenue, no flow, future and absent date remain explicit', () {
    expect(margin(source(income: 0)).primaryLabel, 'Nincs bevétel');
    expect(margin(source(income: 0)).netMarginPercent, isNull);
    expect(
      margin(source(income: 0, expense: 0)).primaryLabel,
      'Nincs pénzmozgás',
    );
    expect(
      margin(source(month: 11)).primaryLabel,
      'A hónap még nem kezdődött el',
    );
    final missing = BalanceMonthNetMarginPresentation.fromChart(
      BalanceMonthFocusedChartPresentation.fromPrimary(source().primary!),
    );
    expect(missing.primaryLabel, 'Nincs hiteles havi adat');
    expect(missing.netMarginPercent, isNull);
  });
  test(
    'current month uses cumulative as-of point; closed month keeps full totals',
    () {
      final current = source(
        month: 10,
        income: 40000000,
        expense: 25000000,
        futureIncome: 90000000,
        futureExpense: 80000000,
      );
      expect(current.primary!.incomeTotalMinor, 130000000);
      final model = margin(current);
      expect(model.incomeMinor, 40000000);
      expect(model.expenseMinor, 25000000);
      expect(model.netMarginPercent, 37.5);
      final closed = margin(
        source(
          month: 9,
          income: 40000000,
          expense: 25000000,
          futureIncome: 90000000,
          futureExpense: 80000000,
        ),
      );
      expect(closed.incomeMinor, 130000000);
      expect(closed.expenseMinor, 105000000);
      // A current-month ratio never mutates the other two prepared perspectives.
      final chart = BalanceMonthFocusedChartPresentation.fromPrimary(
        current.primary!,
        logicalAsOfDate: now,
      );
      BalanceMonthNetMarginPresentation.fromChart(chart);
      expect(chart.trend.last.incomeMinor, 130000000);
      expect(chart.swings.any((p) => p.day == 28), isTrue);
    },
  );
  test(
    'no three-month reference is required and interpretation is monthly only',
    () {
      final input = source();
      expect(input.spendingLevel!.ratio, isNull);
      final model = margin(input);
      expect(model.isAvailable, isTrue);
      expect(model.interpretation, 'A bevétel 20%-a megmaradt.');
      expect(model.netLabel, contains('120'));
      expect(
        margin(source(expense: 72000000)).interpretation,
        'A kiadás 20%-kal meghaladta a bevételt.',
      );
    },
  );
  testWidgets('five monthly net margin golden endpoints use canonical gauge', (
    tester,
  ) async {
    for (final entry in [
      ('positive', source(), const Size(390, 360)),
      ('negative', source(expense: 72000000), const Size(390, 360)),
      ('zero', source(expense: 60000000), const Size(390, 360)),
      ('unavailable', source(income: 0), const Size(390, 360)),
      ('compact', source(expense: 72000000), const Size(280, 210)),
    ]) {
      await pump(tester, entry.$2, size: entry.$3);
      await tester.pumpAndSettle();
      expect(find.byType(BudgetSemicircleGauge), findsOneWidget);
      expect(find.byType(BalanceMonthNetMarginGauge), findsOneWidget);
      expect(find.text('Kiadási szint'), findsNothing);
      expect(find.textContaining('Referencia:'), findsNothing);
      expect(find.text('Havi nettóarány'), findsNWidgets(2));
      expect(tester.takeException(), isNull);
      await expectLater(
        find.byKey(const ValueKey('month-margin-capture')),
        matchesGoldenFile(
          '../../../goldens/balance_month_net_margin_${entry.$1}.png',
        ),
      );
    }
  });
  testWidgets('month replacement retargets same gauge without changing frame', (
    tester,
  ) async {
    await pump(tester, source());
    await tester.pumpAndSettle();
    const key = ValueKey('balance-month-net-margin-gauge');
    final state = tester.state(find.byKey(key));
    final rect = tester.getRect(find.byKey(key));
    BudgetSemicircleMaterial material() => tester.widget(
      find.descendant(
        of: find.byKey(key),
        matching: find.byType(BudgetSemicircleMaterial),
      ),
    );
    expect(material().progress, .6);
    await pump(tester, source(month: 8, expense: 72000000));
    await tester.pump(const Duration(milliseconds: 80));
    expect(tester.state(find.byKey(key)), same(state));
    expect(tester.getRect(find.byKey(key)), rect);
    expect(material().progress, lessThan(.6));
    expect(material().progress, greaterThan(.4));
    await tester.pumpAndSettle();
    expect(material().progress, .4);
    expect(find.text('−20,0%'), findsOneWidget);
    expect(find.textContaining('Havi nettó:'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'negative overflow retains actual value; undefined ratios hide marker',
    (tester) async {
      await pump(tester, source(expense: 150000000));
      await tester.pumpAndSettle();
      expect(find.text('−150,0%'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('budget-semicircle-scale-overflow')),
        findsOneWidget,
      );
      for (final input in [
        source(income: 0),
        source(income: 0, expense: 0),
        source(month: 11),
      ]) {
        await pump(tester, input);
        await tester.pumpAndSettle();
        expect(
          tester
              .widget<BudgetSemicircleGauge>(
                find.byKey(const ValueKey('balance-month-net-margin-gauge')),
              )
              .showMarker,
          isFalse,
        );
        expect(tester.takeException(), isNull);
      }
    },
  );
}
