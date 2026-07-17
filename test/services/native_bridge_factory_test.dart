import 'package:exptv2/services/native_bridge.dart';
import 'package:exptv2/services/native_bridge_factory_native.dart' as native;
import 'package:exptv2/services/native_bridge_factory_web.dart' as web;
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('native factory preserves the default NativeBridge type', () {
    expect(native.createNativeBridge(), isA<NativeBridge>());
  });

  test('web factory decodes seeded preview data without channels', () async {
    final bridge = web.createNativeBridge();

    final bootstrap = await bridge.expenseLoadBootstrap();
    final settings = await bridge.expenseLoadSettings();

    expect(bootstrap.categories, hasLength(8));
    expect(bootstrap.transactions, hasLength(20));
    expect(settings.securitySettings.authEnabled, isFalse);
  });
}
