import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_rhythm_bar_chart.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/dashboard_temporal_anchor.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  testWidgets(
    'renders the prepared seven-bar rhythm with the target gradient',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 120,
            height: 80,
            child: BudgetRhythmBarChart(state: _state()),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('budget-rhythm-month')), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-rhythm-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-rhythm-bar-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-rhythm-bar-6')), findsOneWidget);
      expect(find.text('7 napos ritmus'), findsOneWidget);
    },
  );
}

DashboardBudgetRhythmState _state() => DashboardBudgetRhythmState(
  projection: DashboardBudgetRhythmProjection(
    coreRevision: 7,
    direction: LedgerDirection.expense,
    targetHandle: 1,
    plane: TimePlane.month,
    anchor: DashboardTemporalAnchor(
      visibleYear: 2026,
      visibleMonth: 7,
      visibleDay: 1,
      sourcePlane: TimePlane.month,
      sourceParentQueryKey: const LedgerQueryKey('rhythm-chart'),
      sourceChildQueryKey: const LedgerQueryKey('rhythm-chart'),
      sourceChildOrdinal: 0,
      direction: LedgerDirection.expense,
      filtersRefinementsIdentity: '',
      revision: 7,
      navigationEpoch: 1,
    ),
    title: '7 napos ritmus',
    bars: <DashboardBudgetRhythmBar>[
      for (var index = 0; index < 7; index += 1)
        DashboardBudgetRhythmBar(
          label: '$index',
          actualScaled100: index + 1,
          visualFraction: (index + 1) / 7,
        ),
    ],
  ),
  startColorArgb: 0xff112233,
  middleColorArgb: 0xff223344,
  endColorArgb: 0xff334455,
);
