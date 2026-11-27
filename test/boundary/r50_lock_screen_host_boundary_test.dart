import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  const native = 'android/app/src/main/kotlin/com/fluvi/app';

  test(
    'the Fluvi AppWidget delivers content with no overlay or old presenter',
    () {
      expect(Directory('$native/lockscreen').existsSync(), isFalse);
      final orb = File(
        '$native/widget/orb/FluviHeaderOrbWidgetProvider.kt',
      ).readAsStringSync();
      expect(orb, contains('AppWidgetProvider'));
      expect(orb, contains('.updateAppWidget('));
      expect(orb, contains('AtomicFile'));
      expect(orb, contains('noBackupFilesDir'));
      for (final forbidden in [
        'WindowManager',
        'SurfaceControl',
        'TYPE_ACCESSIBILITY_OVERLAY',
        'FLUVI_STREAM',
        'WIDGETS_ANYWHERE',
        'OrbCompatibilityFrameRenderer.sequenceFor',
      ]) {
        expect(orb, isNot(contains(forbidden)));
      }
    },
  );

  test(
    'the source manifest setup preserves both independent launcher providers',
    () {
      final manifest = File(
        'android/app/src/main/AndroidManifest.xml',
      ).readAsStringSync();
      for (final provider in [
        'FluviOrbWidgetProvider',
        'FluviFinancialSnapshotWidgetProvider',
        'FluviHeaderOrbWidgetProvider',
      ]) {
        expect(manifest, contains(provider));
      }
      expect(manifest, contains('BIND_ACCESSIBILITY_SERVICE'));
      expect(
        manifest,
        contains('tk.zwander.lockscreenwidgets.services.Accessibility'),
      );
      expect(manifest, isNot(contains('FluviOrbLockscreenTrialProvider')));
      final product = File(
        'android/r50-product/app/build.gradle.kts',
      ).readAsStringSync();
      expect(product, contains('com.fluvi.native:fluvi-native:1.0'));
      expect(product, contains('targetSdk = 37'));
      expect(Directory('third_party/widgets-anywhere').existsSync(), isFalse);
      final host = File(
        'android/wa-lockscreen/src/main/kotlin/com/fluvi/wa/WaOrbHost.kt',
      ).readAsStringSync();
      expect(host, contains('HOST_ID = 1003'));
      expect(host, contains('AppWidgetHostView'));
    },
  );
}
