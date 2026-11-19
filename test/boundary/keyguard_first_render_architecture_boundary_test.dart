import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('the keyguard keeps one owner for child surfaces and window admission', () {
    final root = Directory('android/app/src/main/kotlin/com/fluvi/app/lockscreen');
    expect(root.existsSync(), isTrue);
    final kotlin = root.listSync(recursive: true).whereType<File>()
        .where((file) => file.path.endsWith('.kt')).toList();
    final builders = kotlin.where((file) => file.readAsStringSync()
        .contains('SurfaceControl.Builder()')).map((file) => file.path).toList();
    expect(builders, hasLength(1));
    expect(builders.single, endsWith('/material/KeyguardOrbBufferRenderer.kt'));
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
