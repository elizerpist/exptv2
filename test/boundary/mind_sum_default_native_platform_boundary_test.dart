import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'MIND-INIT-02 RED: a missing Android dashboard SUM preference is SUM-A, not Current',
    () {
      final source = File(
        '${Directory.current.path}/android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt',
      ).readAsStringSync();

      expect(
        source,
        contains('preferences.getInt("sumVisualStyle", 1)'),
        reason:
            'The Android method-channel read must use the existing SUM-A enum '
            'index only when SharedPreferences has no stored choice.',
      );
    },
  );
}
