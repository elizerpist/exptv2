import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('keeps human diagnostic and automated profile products hermetic', () {
    final root = Directory.current;
    final workflow = File(
      '${root.path}/.github/workflows/fluvi-core.yml',
    ).readAsStringSync();
    final humanBuildScriptFile = File(
      '${root.path}/scripts/build-human-diagnostic-apk.sh',
    );
    final normalEntrypoint = File(
      '${root.path}/lib/main.dart',
    ).readAsStringSync();

    expect(workflow, contains('build-human-diagnostic-apk:'));
    expect(humanBuildScriptFile.existsSync(), isTrue);
    if (!humanBuildScriptFile.existsSync()) return;
    final humanBuildScript = humanBuildScriptFile.readAsStringSync();
    expect(
      workflow,
      contains('needs: [test-core, test-flutter]'),
      reason: 'The human APK cannot depend on the emulator profile gate.',
    );
    expect(workflow, contains('fluvi_HUMAN_DIAGNOSTIC_'));
    expect(workflow, contains('fluvi_AUTOMATED_TEST_HARNESS_'));
    expect(humanBuildScript, isNot(contains('--target=')));
    expect(humanBuildScript, isNot(contains('integration_test/')));
    expect(humanBuildScript, isNot(contains('test_driver/')));
    expect(humanBuildScript, contains('FLUVI_BUILD_PURPOSE=human_diagnostic'));
    expect(normalEntrypoint, isNot(contains('integration_test')));
    expect(normalEntrypoint, isNot(contains('_ProfileScenario')));
  });
}
