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
      final previews = <QueryAmountRangeValues>[];
      var starts = 0;
      var ends = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryAmountRangeControl(
              values: range,
              onRangeCommitted: committed.add,
              onRangePreviewChanged: previews.add,
              onInteractionStarted: () => starts += 1,
              onInteractionEnded: () => ends += 1,
            ),
          ),
        ),
      );

      final slider = tester.widget<RangeSlider>(
        find.byKey(const ValueKey('query-amount-range-slider')),
      );
      expect(slider.values, const RangeValues(200000, 700000));
      slider.onChangeStart!(const RangeValues(200000, 700000));
      slider.onChanged!(const RangeValues(300000, 600000));
      slider.onChanged!(const RangeValues(400000, 500000));
      expect(previews, isEmpty);
      await tester.pump();
      expect(previews, const <QueryAmountRangeValues>[
        QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 900000,
          lowerScaled100: 400000,
          upperScaled100: 500000,
        ),
      ]);
      expect(committed, isEmpty);

      slider.onChangeEnd!(const RangeValues(400000, 500000));
      expect(starts, 1);
      expect(ends, 1);
      expect(committed, const <QueryAmountRangeValues>[
        QueryAmountRangeValues(
          minimumScaled100: 100000,
          maximumScaled100: 900000,
          lowerScaled100: 400000,
          upperScaled100: 500000,
        ),
      ]);
    },
  );

  testWidgets(
    'RED REENTRANT-MIND: twenty next-frame drags reuse one mounted slider state',
    (tester) async {
      const range = QueryAmountRangeValues(
        minimumScaled100: 100000,
        maximumScaled100: 900000,
        lowerScaled100: 200000,
        upperScaled100: 700000,
      );
      var starts = 0;
      var ends = 0;
      final previews = <QueryAmountRangeValues>[];
      final commits = <QueryAmountRangeValues>[];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: QueryAmountRangeControl(
              values: range,
              onRangePreviewChanged: previews.add,
              onRangeCommitted: commits.add,
              onInteractionStarted: () => starts += 1,
              onInteractionEnded: () => ends += 1,
            ),
          ),
        ),
      );
      final control = find.byKey(const ValueKey('query-amount-range-control'));
      final originalElement = tester.element(control);

      for (var interaction = 0; interaction < 20; interaction += 1) {
        final slider = tester.widget<RangeSlider>(
          find.byKey(const ValueKey('query-amount-range-slider')),
        );
        final next = interaction.isEven
            ? const RangeValues(300000, 600000)
            : const RangeValues(400000, 800000);
        slider.onChangeStart!(slider.values);
        slider.onChanged!(next);
        await tester.pump();
        expect(previews, hasLength(interaction + 1));
        slider.onChangeEnd!(next);
        await tester.pump();
        expect(tester.element(control), same(originalElement));
      }

      expect(starts, 20);
      expect(ends, 20);
      expect(commits, hasLength(20));
      expect(previews, hasLength(20));
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
