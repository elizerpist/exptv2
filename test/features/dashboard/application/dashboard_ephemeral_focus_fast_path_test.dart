import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('RED: a prepared focus hit has no isolate-worker derivation path', () {
    final controller = File(
      'lib/features/dashboard/application/dashboard_core_controller.dart',
    ).readAsStringSync();

    expect(
      controller,
      isNot(contains('Isolate.run(')),
      reason:
          'Sending the complete prepared base index to an isolate makes a '
          'prepared membership hit pay serialization/projection latency.',
    );
    expect(controller, isNot(contains('_runEphemeralFocusDerivation(')));
  });
}
