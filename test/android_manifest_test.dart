import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('declares permission to query every installed package', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.QUERY_ALL_PACKAGES'));
  });

  test('declares biometric permission for app unlock', () {
    final manifest = File(
      'android/app/src/main/AndroidManifest.xml',
    ).readAsStringSync();

    expect(manifest, contains('android.permission.USE_BIOMETRIC'));
  });
}
