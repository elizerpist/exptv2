import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/query/domain/query_amount_range.dart';
import 'package:fluvi/features/dashboard/query/domain/query_menu_data.dart';
import 'package:fluvi/features/dashboard/query/presentation/query_amount_range_control.dart';

void main() {
  testWidgets(
    'G3: one reusable two-ended control keeps raw motion local and commits both canonical bounds',
    (tester) async {
      const range = QueryAmountRangeValues(
        minimumScaled100: QueryAmountRange.minimumScaled100,
        maximumScaled100: 900000,
        lowerScaled100: 200000,
        upperScaled100: 700000,
      );
      final committed = <QueryAmountRangeValues>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryAmountRangeControl(
              values: range,
              onRangeCommitted: committed.add,
            ),
          ),
        ),
      );

      final slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      expect(slider.values, const RangeValues(200000, 700000));
      slider.onChanged!(const RangeValues(300000, 600000));
      await tester.pump();
      expect(committed, isEmpty);

      slider.onChangeEnd!(const RangeValues(300000, 600000));
      expect(committed, const <QueryAmountRangeValues>[
        QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 900000,
          lowerScaled100: 300000,
          upperScaled100: 600000,
        ),
      ]);
    },
  );

  test('G3: canonical amount range retains the 1000 HUF floor', () {
    final values = QueryAmountRange.resolve(
      refinements: const <String, Object?>{},
      amountDomain: const QueryMenuAmountDomain(
        minimumAmountScaled100: 0,
        maximumAmountScaled100: 50000,
      ),
    );

    expect(values.minimumScaled100, 100000);
    expect(values.maximumScaled100, 100000);
    expect(values.lowerScaled100, 100000);
    expect(values.upperScaled100, 100000);
  });

  testWidgets(
    'G3: a narrow Mind-card width keeps the amount labels contained',
    (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 180,
              height: 146,
              child: QueryAmountRangeControl(
                values: QueryAmountRangeValues(
                  minimumScaled100: 100000,
                  maximumScaled100: 98765432100,
                  lowerScaled100: 100000,
                  upperScaled100: 98765432100,
                ),
                onRangeCommitted: _discardRange,
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
    },
  );
}

void _discardRange(QueryAmountRangeValues _) {}
