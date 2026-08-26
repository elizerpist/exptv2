import 'package:fluvi/core/design/dashboard_mode_palette.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'Summary prepared amount text has stronger hierarchy than baseline body',
    () {
      expect(
        FluviVisualTokens.summaryAmountTextStyle.fontSize,
        greaterThan(13),
      );
      expect(FluviVisualTokens.summaryAmountTextStyle.height, greaterThan(1.2));
    },
  );
}
