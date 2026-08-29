import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/current_ledger_query_scope.dart';
import 'package:fluvi/features/dashboard/query/domain/ledger_direction.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_threshold.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_threshold_slider.dart';
import 'package:fluvi/features/dashboard/time_navigation/domain/ledger_time_scope.dart';

void main() {
  testWidgets('keeps raw slider motion local and commits one canonical tick', (
    tester,
  ) async {
    final bounds = QueryAmountThreshold.resolve(
      scope: CurrentLedgerQueryScope(
        direction: LedgerDirection.expense,
        timeScope: const AllTimeScope(),
      ),
      amountDomain: const QueryMenuAmountDomain(
        minimumAmountScaled100: 0,
        maximumAmountScaled100: 500000,
      ),
    );
    final committed = <int>[];
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: QueryAmountThresholdSlider(
            bounds: bounds,
            onValueCommitted: committed.add,
          ),
        ),
      ),
    );

    final slider = tester.widget<Slider>(
      find.byKey(const ValueKey('query-amount-threshold-slider')),
    );
    slider.onChangeStart!(100000);
    slider.onChanged!(400000);
    await tester.pump();
    expect(committed, isEmpty);

    slider.onChangeEnd!(400000);
    expect(committed, <int>[400000]);
  });
}
