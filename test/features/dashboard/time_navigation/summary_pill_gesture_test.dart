import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_summary_pill.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/time_plane.dart';
import 'package:fluvi/features/dashboard/time_navigation/presentation/summary_pill_view_model.dart';

const _bounds = DashboardBounds(
  left: 0,
  top: 0,
  width: 378,
  height: 59,
);

SummaryPillViewModel _viewModel() => const SummaryPillViewModel(
  plane: TimePlane.year,
  periodLabel: '2026',
  planeLabel: 'Év',
  amountText: '123,45 Ft',
  isRailOpen: false,
  isLoading: false,
  hasError: false,
);

Widget _host({
  required VoidCallback onToggle,
  required VoidCallback onFiner,
  required VoidCallback onBroader,
  required VoidCallback onPrevious,
  required VoidCallback onNext,
}) {
  return MaterialApp(
    home: Scaffold(
      body: DashboardSummaryPill(
        bounds: _bounds,
        viewModel: _viewModel(),
        onToggleRail: onToggle,
        onMoveFiner: onFiner,
        onMoveBroader: onBroader,
        onMovePrevious: onPrevious,
        onMoveNext: onNext,
      ),
    ),
  );
}

void main() {
  testWidgets('vertical swipe changes the plane and does not move parent', (
    tester,
  ) async {
    var finer = 0;
    var next = 0;
    await tester.pumpWidget(
      _host(
        onToggle: () {},
        onFiner: () => finer += 1,
        onBroader: () {},
        onPrevious: () {},
        onNext: () => next += 1,
      ),
    );

    await tester.drag(find.byType(DashboardSummaryPill), const Offset(0, -80));

    expect(finer, 1);
    expect(next, 0);
  });

  testWidgets('horizontal swipe changes parent and does not change plane', (
    tester,
  ) async {
    var finer = 0;
    var next = 0;
    await tester.pumpWidget(
      _host(
        onToggle: () {},
        onFiner: () => finer += 1,
        onBroader: () {},
        onPrevious: () {},
        onNext: () => next += 1,
      ),
    );

    await tester.drag(find.byType(DashboardSummaryPill), const Offset(-80, 0));

    expect(next, 1);
    expect(finer, 0);
  });

  testWidgets('chevron tap only toggles the rail', (tester) async {
    var toggles = 0;
    var finer = 0;
    await tester.pumpWidget(
      _host(
        onToggle: () => toggles += 1,
        onFiner: () => finer += 1,
        onBroader: () {},
        onPrevious: () {},
        onNext: () {},
      ),
    );

    await tester.tap(find.byKey(const ValueKey('dashboard-summary-chevron')));

    expect(toggles, 1);
    expect(finer, 0);
  });
}
