import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_month_spending_level_projection.dart';
import 'package:fluvi/features/dashboard/application/dashboard_balance_primary_identity.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_month_spending_level_gauge.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_clay_semicircle_gauge.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';

DashboardBalanceMonthSpendingLevelPresentation data({
  int expense = 153,
  DashboardBalanceMonthSpendingLevelStatus status =
      DashboardBalanceMonthSpendingLevelStatus.available,
}) => DashboardBalanceMonthSpendingLevelPresentation(
  identity: const DashboardBalancePrimaryIdentity(
    upstreamScopeKey: 'month',
    indexGeneration: 1,
    coreRevision: 1,
  ),
  currentExpenseMinor: expense,
  referenceExpenseTimesTwo:
      status == DashboardBalanceMonthSpendingLevelStatus.zeroReference
      ? 0
      : 200,
  comparableMonthCount: 3,
  status: status,
);

void main() {
  testWidgets(
    'Balance is pixel-identical to direct Budget with raw overshoot',
    (tester) async {
      const capture = ValueKey('capture');
      Future<void> pump(bool balance) => tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: RepaintBoundary(
              key: capture,
              child: SizedBox(
                width: 340,
                height: 210,
                child: Builder(
                  builder: (context) => balance
                      ? BalanceMonthSpendingLevelGauge(presentation: data())
                      : BudgetSemicircleGauge(
                          presentation:
                              BudgetSemicircleMaterialPresentation.resolve(
                                rawRatio: 1.53,
                                direction: LedgerDirection.expense,
                                activeGradient:
                                    BudgetClayGaugeAccentResolver.resolve(
                                      context,
                                      direction: LedgerDirection.expense,
                                    ),
                              ),
                          primaryLabel: '153%',
                          secondaryLabel: 'Megszokott kiadási szint',
                        ),
                ),
              ),
            ),
          ),
        ),
      );
      Future<List<int>> pixels() async {
        final boundary = tester.renderObject<RenderRepaintBoundary>(
          find.byKey(capture),
        );
        return (await tester.runAsync(() async {
          final image = await boundary.toImage(pixelRatio: 1);
          final bytes = await image.toByteData(
            format: ui.ImageByteFormat.rawRgba,
          );
          final result = bytes!.buffer.asUint8List().toList();
          image.dispose();
          return result;
        }))!;
      }

      await pump(true);
      await tester.pumpAndSettle();
      expect(find.text('153%'), findsOneWidget);
      final gauge = tester.widget<BudgetSemicircleGauge>(
        find.byType(BudgetSemicircleGauge),
      );
      expect(gauge.presentation.rawRatio, 1.53);
      expect(gauge.presentation.hasVisualOverflow, isTrue);
      await expectLater(
        find.byKey(capture),
        matchesGoldenFile(
          '../../../goldens/balance_month_spending_level_153.png',
        ),
      );
      final balance = await pixels();
      await pump(false);
      await tester.pumpAndSettle();
      expect(await pixels(), orderedEquals(balance));
    },
  );

  testWidgets('compact bounds retain canonical gauge and fit text', (
    tester,
  ) async {
    for (final size in [const Size(160, 85), const Size(220, 65)]) {
      await tester.pumpWidget(
        MaterialApp(
          home: Center(
            child: SizedBox.fromSize(
              size: size,
              child: BalanceMonthSpendingLevelGauge(presentation: data()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BudgetSemicircleGauge), findsOneWidget);
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('unavailable reference never renders fake zero gauge', (
    tester,
  ) async {
    for (final status in DashboardBalanceMonthSpendingLevelStatus.values.where(
      (s) => s != DashboardBalanceMonthSpendingLevelStatus.available,
    )) {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 300,
            height: 160,
            child: BalanceMonthSpendingLevelGauge(
              presentation: data(status: status),
            ),
          ),
        ),
      );
      expect(find.byType(BudgetSemicircleGauge), findsNothing);
      expect(find.text('0%'), findsNothing);
      expect(tester.takeException(), isNull);
    }
  });
}
