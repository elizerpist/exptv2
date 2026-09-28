import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_four_section_layout.dart';

void main() {
  test('TET-02: four-section allocation uses the exact authored ratios', () {
    final layout = BalanceFourSectionLayout.resolve(
      const Rect.fromLTWH(0, 0, 1000, 1000),
    );

    expect(layout.card1, const Rect.fromLTWH(0, 600, 500, 400));
    expect(layout.card2, const Rect.fromLTWH(500, 600, 500, 400));
    expect(layout.card3, const Rect.fromLTWH(0, 0, 700, 600));
    expect(layout.card4, const Rect.fromLTWH(700, 0, 300, 600));
  });

  test('TET-02: translated live body bounds remain gapless allocations', () {
    final body = const Rect.fromLTWH(14, 120, 378, 440);
    final layout = BalanceFourSectionLayout.resolve(body);

    expect(layout.card3.left, body.left);
    expect(layout.card3.top, body.top);
    expect(layout.card4.right, body.right);
    expect(layout.card1.left, body.left);
    expect(layout.card2.right, body.right);
    expect(layout.card1.bottom, body.bottom);
    expect(layout.card2.bottom, body.bottom);
    expect(layout.card3.bottom, closeTo(body.top + body.height * .6, .0001));
    expect(layout.card4.bottom, closeTo(body.top + body.height * .6, .0001));
    expect(layout.card1.top, closeTo(body.top + body.height * .6, .0001));
    expect(layout.card2.top, closeTo(body.top + body.height * .6, .0001));
  });
}
