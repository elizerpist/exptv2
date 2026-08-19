import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/application/dashboard_budget_rhythm_controller.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/budget_rhythm_bar_chart.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';

void main() {
  testWidgets(
    'renders prepared non-zero bars as narrow centered pills with a full-width gradient fill',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 140,
            height: 100,
            child: BudgetRhythmBarChart(state: _state()),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('budget-rhythm-month')), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-rhythm-title')), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-rhythm-bar-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('budget-rhythm-bar-6')), findsOneWidget);
      expect(find.text('7 napos ritmus'), findsOneWidget);
      expect(
        find.textContaining('Ft'),
        findsNothing,
        reason:
            'Rhythm conveys relative shape only; monetary labels are noise.',
      );

      final track = find.byKey(const ValueKey('budget-rhythm-track-0'));
      final fill = find.byKey(const ValueKey('budget-rhythm-fill-0'));
      final trackSize = tester.getSize(track);
      final fillSize = tester.getSize(fill);
      expect(trackSize.width, 11);
      expect(trackSize.width.isFinite, isTrue);
      expect(fillSize.width, trackSize.width);
      expect(fillSize.width, greaterThan(0));
      expect(fillSize.height, greaterThan(0));
      expect(trackSize.width * 7, lessThan(140 * .7));

      final trackDecoration = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('budget-rhythm-track-decoration-0')),
      );
      final trackBox = trackDecoration.decoration as BoxDecoration;
      final trackRadius = trackBox.borderRadius! as BorderRadius;
      expect(trackRadius.topLeft.x, 999);

      final fillDecoration = tester.widget<DecoratedBox>(
        find.byKey(const ValueKey('budget-rhythm-fill-decoration-0')),
      );
      final fillBox = fillDecoration.decoration as BoxDecoration;
      final gradient = fillBox.gradient! as LinearGradient;
      expect(gradient.colors, <Color>[
        const Color(0xff112233),
        const Color(0xff223344),
        const Color(0xff334455),
      ]);
      final fillRadius = fillBox.borderRadius! as BorderRadius;
      expect(fillRadius.topLeft.x, 999);
    },
  );

  testWidgets(
    'keeps the narrow neutral pill but gives a zero bar no fill height',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            width: 140,
            height: 100,
            child: BudgetRhythmBarChart(
              state: _state(values: const <int>[0, 0, 0, 0, 0, 0, 0]),
            ),
          ),
        ),
      );

      final track = find.byKey(const ValueKey('budget-rhythm-track-0'));
      final fill = find.byKey(const ValueKey('budget-rhythm-fill-0'));
      expect(tester.getSize(track).width, 11);
      expect(tester.getSize(fill).width, 11);
      expect(tester.getSize(fill).height, 0);
    },
  );
}

DashboardBudgetRhythmState _state({List<int>? values}) {
  final actuals = values ?? <int>[1, 2, 3, 4, 5, 6, 7];
  final max = actuals.fold<int>(
    0,
    (current, value) => value > current ? value : current,
  );
  return DashboardBudgetRhythmState(
    projection: DashboardBudgetRhythmProjection(
      coreRevision: 7,
      direction: LedgerDirection.expense,
      targetHandle: 1,
      plane: TimePlane.month,
      windowStart: DateTime.utc(2026, 8, 13),
      windowEnd: DateTime.utc(2026, 8, 19),
      title: '7 napos ritmus',
      bars: <DashboardBudgetRhythmBar>[
        for (var index = 0; index < actuals.length; index += 1)
          DashboardBudgetRhythmBar(
            label: '$index',
            actualScaled100: actuals[index],
            visualFraction: max == 0 ? 0 : actuals[index] / max,
          ),
      ],
    ),
    startColorArgb: 0xff112233,
    middleColorArgb: 0xff223344,
    endColorArgb: 0xff334455,
  );
}
