import 'package:exptv2/features/transactions/data/limit_slider_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('unconstrained slider defaults to 100000 with 1000 steps', () {
    final range = LimitSliderRange.unconstrained(
      amount: 0,
      rememberedMax: 0,
    );

    expect(range.max, 100000);
    expect(range.divisions, 100);
    expect(range.value, 0);
  });

  test('manual high value keeps a high water max after amount is reduced', () {
    final high = LimitSliderRange.unconstrained(
      amount: 250000,
      rememberedMax: 100000,
    );
    expect(high.max, 250000);

    final reduced = LimitSliderRange.unconstrained(
      amount: 50000,
      rememberedMax: high.max,
    );

    expect(reduced.max, 250000);
    expect(reduced.value, 50000);
  });

  test('constrained range disables empty category when no free budget remains', () {
    final range = LimitSliderRange.constrained(
      amount: 0,
      rememberedMax: 0,
      maxAllowed: 0,
      hasExistingLimit: false,
    );

    expect(range.enabled, isFalse);
    expect(range.max, 1);
    expect(range.value, 0);
  });
}
