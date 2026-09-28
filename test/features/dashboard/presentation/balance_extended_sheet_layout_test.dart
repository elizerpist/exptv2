import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:fluvi/features/dashboard/presentation/core_modes/balance_extended_sheet_layout.dart';

void main() {
  test('ALT-EXTENDED-RED: Havi 2 and Éves share the HTML allocation geometry', () {
    final layout = BalanceExtendedSheetLayout.resolve(
      const Rect.fromLTWH(0, 0, 1000, 1000),
    );

    expect(layout.card3, const Rect.fromLTWH(0, 0, 700, 600));
    expect(layout.card4, const Rect.fromLTWH(700, 0, 300, 300));
    expect(layout.card5, const Rect.fromLTWH(700, 300, 300, 300));
    expect(layout.combined, const Rect.fromLTWH(0, 600, 1000, 400));
  });

  test('ALT-EXTENDED-RED: translated body leaves the Header outside every ratio', () {
    const body = Rect.fromLTWH(12, 172, 378, 420);
    final layout = BalanceExtendedSheetLayout.resolve(body);

    expect(layout.card3.left, body.left);
    expect(layout.card3.top, body.top);
    expect(layout.card4.right, body.right);
    expect(layout.card5.bottom, body.top + body.height * .60);
    expect(layout.combined.top, body.top + body.height * .60);
    expect(layout.combined.bottom, body.bottom);
  });
}
