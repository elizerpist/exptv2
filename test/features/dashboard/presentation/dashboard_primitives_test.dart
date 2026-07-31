import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/core/design/dashboard_layout_frame.dart';
import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:fluvi/features/dashboard/application/dashboard_mode_spec.dart';
import 'package:fluvi/features/dashboard/application/transaction_direction_controller.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/dashboard_collapse_handle.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/fluvi_brand_lockup.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/time_refinement_rail.dart';
import 'package:fluvi/features/dashboard/presentation/widgets/transaction_direction_toggle.dart';

const _bounds = DashboardBounds(left: 0, top: 0, width: 378, height: 48);

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('brand lockup renders its semantic brand parts', (tester) async {
    await tester.pumpWidget(_host(const FluviBrandLockup(bounds: _bounds)));

    expect(find.byKey(const ValueKey('fluvi-brand-mark')), findsOneWidget);
    expect(find.byKey(const ValueKey('fluvi-wordmark')), findsOneWidget);
    expect(find.byKey(const ValueKey('fluvi-motto')), findsOneWidget);
  });

  testWidgets('expense direction shows the selected local action asset', (
    tester,
  ) async {
    await tester.pumpWidget(
      _host(
        TransactionDirectionToggle(
          bounds: _bounds,
          palette: DashboardModePaletteResolver.resolve(
            DashboardModeSpec.balance,
          ),
          selectedDirection: TransactionDirection.expense,
          incomeIconScale: 1,
          expenseIconScale: 1.12,
          onSelected: (_) {},
        ),
      ),
    );

    expect(find.byKey(const ValueKey('fluvi-income-wallet')), findsOneWidget);
    expect(find.byKey(const ValueKey('fluvi-expense-bag')), findsOneWidget);
    expect(find.text('Kiadás'), findsOneWidget);
  });

  testWidgets('brand lockup uses semantic typography tokens', (tester) async {
    await tester.pumpWidget(_host(const FluviBrandLockup(bounds: _bounds)));

    expect(
      tester.widget<Text>(find.byKey(const ValueKey('fluvi-wordmark'))).style,
      FluviVisualTokens.brandWordmarkTextStyle,
    );
    expect(
      tester.widget<Text>(find.byKey(const ValueKey('fluvi-motto'))).style,
      FluviVisualTokens.brandMottoTextStyle,
    );
  });

  testWidgets('collapse handle forwards a tap intent', (tester) async {
    var taps = 0;
    await tester.pumpWidget(
      _host(DashboardCollapseHandle(bounds: _bounds, onTap: () => taps += 1)),
    );

    await tester.tap(find.byKey(const ValueKey('dashboard-collapse-handle')));
    expect(taps, 1);
  });

  testWidgets('time refinement rail exposes five static pills horizontally', (
    tester,
  ) async {
    await tester.pumpWidget(_host(const TimeRefinementRail(bounds: _bounds)));

    expect(find.byType(Scrollable), findsOneWidget);
    expect(
      tester.widget<Scrollable>(find.byType(Scrollable)).axisDirection,
      AxisDirection.right,
    );
    expect(find.byKey(const ValueKey('fluvi-time-pill')), findsNWidgets(5));
  });
}
