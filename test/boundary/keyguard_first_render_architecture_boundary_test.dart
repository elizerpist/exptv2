import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('R12 standalone surface has one platform queue and no extra window', () {
    final directory = Directory(
      'android/app/src/main/kotlin/com/fluvi/app/lockscreen/material',
    );
    final presenter = File('${directory.path}/KeyguardOrbSurfacePresenter.kt');
    final worker = File('${directory.path}/KeyguardOrbSurfaceWorker.kt');
    expect(presenter.existsSync(), isTrue, reason: 'R12 presenter is required');
    expect(worker.existsSync(), isTrue, reason: 'R12 worker is required');
    final presenterSource = presenter.readAsStringSync();
    final workerSource = worker.readAsStringSync();
    expect(presenterSource, contains('SurfaceView'));
    expect(presenterSource, contains('SurfaceHolder.Callback2'));
    expect(workerSource, contains('lockHardwareCanvas'));
    for (final source in [presenterSource, workerSource]) {
      expect(source, isNot(contains('SurfaceControl.Builder(')));
      expect(source, isNot(contains('HardwareBufferRenderer')));
      expect(source, isNot(contains('setZOrderOnTop')));
      expect(source, isNot(contains('TYPE_ACCESSIBILITY_OVERLAY')));
    }
  });

  test('R12 diagnostic routes retain the legacy comparison path', () {
    final root = Directory('android/app/src/main/kotlin/com/fluvi/app/lockscreen');
    final source = root.listSync(recursive: true).whereType<File>()
        .where((file) => file.path.endsWith('.kt'))
        .map((file) => file.readAsStringSync()).join('\n');
    for (final mode in ['SURFACE_LIVE', 'SURFACE_STATIC', 'LEGACY_R11']) {
      expect(source.contains(mode), isTrue, reason: 'R12 must expose $mode');
    }
    expect(File('${root.path}/material/KeyguardOrbBufferRenderer.kt').existsSync(), isTrue,
        reason: 'the R11 legacy comparison remains available');
  });

  test('the keyguard bounds child surface owners and keeps one window admission', () {
    final root = Directory('android/app/src/main/kotlin/com/fluvi/app/lockscreen');
    expect(root.existsSync(), isTrue);
    final kotlin = root.listSync(recursive: true).whereType<File>()
        .where((file) => file.path.endsWith('.kt')).toList();
    final builders = kotlin.where((file) => file.readAsStringSync()
        .contains('SurfaceControl.Builder()')).map((file) => file.path).toList();
    expect(builders, hasLength(2));
    expect(builders.where((path) => path.endsWith('/material/KeyguardOrbBufferRenderer.kt')), hasLength(1));
    expect(builders.where((path) => path.endsWith('/material/KeyguardOrbOwnedOutput.kt')), hasLength(1));
    final owned = File('${root.path}/material/KeyguardOrbOwnedOutput.kt').readAsStringSync();
    expect(owned, contains('.setParent(parent)'));
    expect(owned, contains('.setVisibility(child, false)'));
    expect(owned, isNot(contains('.setVisibility(parent')));
    expect(owned, isNot(contains('TYPE_ACCESSIBILITY_OVERLAY')));
    for (final file in kotlin) {
      final source = file.readAsStringSync();
      expect(source, isNot(contains('import com.fluvi.app.features.dashboard')),
          reason: '${file.path} must not acquire a dashboard dependency');
      if (file.path.endsWith('/material/KeyguardOrbBufferRenderer.kt')) {
        expect(source, isNot(contains('WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY')),
            reason: 'the buffer producer may not introduce another input window');
      }
    }
  });

  test('the Human delivery gate keeps native verification mandatory', () {
    final workflow = File('.github/workflows/fluvi-core.yml').readAsStringSync();
    final start = workflow.indexOf('  build-human-diagnostic-apk:\n');
    expect(start, greaterThanOrEqualTo(0));
    final end = workflow.indexOf(RegExp(r'^  [A-Za-z0-9_-]+:', multiLine: true), start + 1);
    final job = workflow.substring(start, end < 0 ? workflow.length : end);
    expect(job, contains('needs: [test-core, test-flutter, test-keyguard-material-runtime]'));
    expect(job, contains("needs.test-keyguard-material-runtime.result == 'success'"));
  });
}
