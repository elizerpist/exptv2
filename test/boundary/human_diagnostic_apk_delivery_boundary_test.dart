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

  test('human job contract is scoped and rejects dependency or diagnostic mutations', () {
    final workflow = File(
      '${Directory.current.path}/.github/workflows/fluvi-core.yml',
    ).readAsStringSync();
    expect(_hasHumanDeliveryContract(workflow), isTrue);

    final humanJob = _job(workflow, 'build-human-diagnostic-apk');
    final missingNative = workflow.replaceFirst(
      humanJob,
      humanJob.replaceFirst(
        'needs: [test-core, test-flutter, test-keyguard-material-runtime]',
        'needs: [test-core, test-flutter]',
      ),
    );
    expect(_hasHumanDeliveryContract(missingNative), isFalse);
    final missingDiagnosticGuard = workflow.replaceFirst(
      humanJob,
      humanJob.replaceFirst(
        '!(github.event_name == \'workflow_dispatch\' && inputs.native_diagnostic)',
        'true',
      ),
    );
    expect(_hasHumanDeliveryContract(missingDiagnosticGuard), isFalse);
  });
}

String _job(String workflow, String name) {
  final start = workflow.indexOf('  $name:\n');
  expect(start, greaterThanOrEqualTo(0), reason: 'workflow must contain $name');
  final end = workflow.indexOf(RegExp(r'^  [A-Za-z0-9_-]+:', multiLine: true), start + 1);
  return workflow.substring(start, end == -1 ? workflow.length : end);
}

bool _hasHumanDeliveryContract(String workflow) {
  final matches = RegExp(r'^  build-human-diagnostic-apk:$', multiLine: true)
      .allMatches(workflow)
      .toList();
  if (matches.length != 1) return false;
  final job = _job(workflow, 'build-human-diagnostic-apk');
  return job.contains('needs: [test-core, test-flutter, test-keyguard-material-runtime]') &&
      job.contains("needs.test-core.result == 'success'") &&
      job.contains("needs.test-flutter.result == 'success'") &&
      job.contains("needs.test-keyguard-material-runtime.result == 'success'") &&
      job.contains("!(github.event_name == 'workflow_dispatch' && inputs.native_diagnostic)") &&
      job.contains('runs-on: ubuntu-latest');
}
