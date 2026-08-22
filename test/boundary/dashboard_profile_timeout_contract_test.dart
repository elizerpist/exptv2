import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'profile driver watchdog leaves teardown headroom below the 20-minute scenario contract',
    () async {
      final runner = await File('scripts/run-dashboard-profile.sh').readAsString();

      // The A–J integration scenario itself permits 20 minutes. A 12-minute
      // outer shell timeout killed a run that had already reported "All tests
      // passed" while flutter-drive was flushing its final response.
      expect(runner, contains('timeout --foreground --signal=TERM --kill-after=30s 15m'));
    },
  );
}
