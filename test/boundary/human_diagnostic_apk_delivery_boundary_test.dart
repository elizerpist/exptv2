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
    final humanJob = _job(workflow, 'build-human-diagnostic-apk');
    expect(humanJob, contains('needs: [test-core, test-flutter, test-keyguard-material-runtime]'));
    expect(humanJob, contains("needs.test-core.result == 'success'"));
    expect(humanJob, contains("needs.test-flutter.result == 'success'"));
    expect(humanJob, contains("needs.test-keyguard-material-runtime.result == 'success'"));
    expect(humanJob, contains('inputs.native_diagnostic'));
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

String _job(String workflow, String name) {
  final start = workflow.indexOf('  $name:\n');
  expect(start, greaterThanOrEqualTo(0), reason: 'workflow must contain $name');
  final end = workflow.indexOf(RegExp(r'^  [A-Za-z0-9_-]+:', multiLine: true), start + 1);
  return workflow.substring(start, end == -1 ? workflow.length : end);
}
