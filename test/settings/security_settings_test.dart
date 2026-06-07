import 'package:exptv2/features/settings/models/security_settings.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('defaults to disabled security', () {
    final settings = SecuritySettings.fromMap(const <String, Object?>{});

    expect(settings.pinEnabled, isFalse);
    expect(settings.biometricEnabled, isFalse);
    expect(settings.biometricAvailable, isFalse);
    expect(settings.biometricLabel, 'Nem elerheto');
    expect(settings.authEnabled, isFalse);
  });

  test('parses native security payload', () {
    final settings = SecuritySettings.fromMap(const <String, Object?>{
      'pinEnabled': true,
      'biometricEnabled': true,
      'biometricAvailable': true,
      'biometricLabel': 'Ujjlenyomat elerheto',
    });

    expect(settings.pinEnabled, isTrue);
    expect(settings.biometricEnabled, isTrue);
    expect(settings.biometricAvailable, isTrue);
    expect(settings.biometricLabel, 'Ujjlenyomat elerheto');
    expect(settings.authEnabled, isTrue);
  });

  test('disables biometric auth when no pin exists', () {
    final settings = SecuritySettings.fromMap(const <String, Object?>{
      'pinEnabled': false,
      'biometricEnabled': true,
      'biometricAvailable': true,
      'biometricLabel': 'Ujjlenyomat elerheto',
    });

    expect(settings.pinEnabled, isFalse);
    expect(settings.biometricEnabled, isFalse);
    expect(settings.authEnabled, isFalse);
  });

  test('serializes update payload', () {
    const settings = SecuritySettings(
      pinEnabled: true,
      biometricEnabled: true,
      biometricAvailable: true,
      biometricLabel: 'OK',
    );

    expect(settings.toMap(), <String, Object?>{
      'pinEnabled': true,
      'biometricEnabled': true,
      'biometricAvailable': true,
      'biometricLabel': 'OK',
    });
  });
}
