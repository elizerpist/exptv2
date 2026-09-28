import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_five_section_layout.dart';

void main() {
  test('ALT2-02: five-section allocation preserves exact authored ratios', () {
    final layout = BalanceFiveSectionLayout.resolve(
      const Rect.fromLTWH(0, 0, 1000, 1000),
    );

    expect(layout.card3, const Rect.fromLTWH(0, 0, 700, 600));
    expect(layout.card4, const Rect.fromLTWH(700, 0, 300, 300));
    expect(layout.card5, const Rect.fromLTWH(700, 300, 300, 300));
    expect(layout.card1, const Rect.fromLTWH(0, 600, 500, 400));
    expect(layout.card2, const Rect.fromLTWH(500, 600, 500, 400));
  });

  test(
    'ALT2-02: five-section allocation translates without changing seams',
    () {
      const body = Rect.fromLTWH(17, 29, 311, 487);
      final layout = BalanceFiveSectionLayout.resolve(body);

      expect(layout.card3.left, body.left);
      expect(layout.card3.top, body.top);
      expect(layout.card4.right, body.right);
      expect(layout.card5.right, body.right);
      expect(layout.card1.bottom, body.bottom);
      expect(layout.card2.bottom, body.bottom);
      expect(layout.card3.bottom, closeTo(layout.card5.bottom, .0001));
      expect(layout.card4.bottom, closeTo(layout.card5.top, .0001));
      expect(layout.card5.bottom, closeTo(layout.card1.top, .0001));
      expect(layout.card5.bottom, closeTo(layout.card2.top, .0001));
    },
  );
}
