# PIN and Biometric Authentication Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build working PIN and biometric app-entry authentication for `exptv2`, configurable from Settings and enforced on cold entry plus background resume.

**Architecture:** Keep Flutter responsible for UI, app lifecycle, and lock-gate state. Keep Android responsible for persisted auth settings, PIN hashing/verification, biometric availability, and biometric prompt execution through the existing `pushparser/methods` MethodChannel.

**Tech Stack:** Flutter/Dart, MethodChannel, Android Kotlin, AndroidX Biometric `1.1.0`, SharedPreferences, Flutter widget tests, Kotlin JUnit tests.

---

## File Structure

- Create `lib/features/settings/models/security_settings.dart`
  - Parses `securitySettings` payloads and exposes `pinEnabled`,
    `biometricEnabled`, `biometricAvailable`, and `biometricLabel`.
- Create `lib/features/settings/widgets/security/pin_settings_panel.dart`
  - PIN setup/change/remove submenu.
- Create `lib/features/settings/widgets/security/biometric_settings_panel.dart`
  - Biometric status/toggle submenu.
- Create `lib/features/security/security_gate.dart`
  - App-level lock overlay and lifecycle locking.
- Create `lib/features/security/security_controller.dart`
  - Loads settings, verifies PIN, triggers biometric auth, tracks locked state.
- Modify `lib/services/native_bridge.dart`
  - Add security payload parsing and MethodChannel methods.
- Modify `lib/features/settings/data/settings_repository.dart`
  - Expose security methods.
- Modify `lib/features/settings/state/settings_store.dart`
  - Hold `securitySettings` and update methods.
- Modify `lib/features/settings/settings_page.dart`
  - Wire the current inactive security rows to PIN and biometric panels.
- Modify `lib/exptv2_app.dart`
  - Wrap `ExptShell` in `SecurityGate`.
- Modify `android/app/build.gradle.kts`
  - Add AndroidX Biometric plus local JVM test dependencies for Android
    SharedPreferences tests.
- Modify `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
  - Make the activity a `FragmentActivity` compatible Flutter activity and pass it to the auth channel.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
  - Persist security settings, salted PIN hash, and biometric enablement.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
  - Add security MethodChannel cases and UI-thread biometric prompt support.
- Test `test/settings/security_settings_test.dart`
- Test `test/settings/settings_bridge_test.dart`
- Test `test/settings/settings_store_test.dart`
- Test `test/settings/settings_page_test.dart`
- Test `test/security/security_gate_test.dart`
- Test `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`

## Task 1: Dart Security Model and NativeBridge Contract

**Files:**
- Create: `lib/features/settings/models/security_settings.dart`
- Modify: `lib/services/native_bridge.dart`
- Test: `test/settings/security_settings_test.dart`
- Test: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Write failing `SecuritySettings` model tests**

Add `test/settings/security_settings_test.dart`:

```dart
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
```

- [ ] **Step 2: Run model test and verify it fails**

Run:

```bash
flutter test test/settings/security_settings_test.dart
```

Expected: FAIL because `security_settings.dart` does not exist.

- [ ] **Step 3: Implement `SecuritySettings`**

Create `lib/features/settings/models/security_settings.dart`:

```dart
class SecuritySettings {
  const SecuritySettings({
    required this.pinEnabled,
    required this.biometricEnabled,
    required this.biometricAvailable,
    required this.biometricLabel,
  });

  factory SecuritySettings.defaults() {
    return const SecuritySettings(
      pinEnabled: false,
      biometricEnabled: false,
      biometricAvailable: false,
      biometricLabel: 'Nem elerheto',
    );
  }

  factory SecuritySettings.fromMap(Map<dynamic, dynamic> map) {
    final pinEnabled = map['pinEnabled'] == true;
    final biometricAvailable = map['biometricAvailable'] == true;
    final biometricEnabled = pinEnabled && map['biometricEnabled'] == true;
    final label = map['biometricLabel']?.toString().trim();
    return SecuritySettings(
      pinEnabled: pinEnabled,
      biometricEnabled: biometricEnabled,
      biometricAvailable: biometricAvailable,
      biometricLabel: label == null || label.isEmpty ? 'Nem elerheto' : label,
    );
  }

  final bool pinEnabled;
  final bool biometricEnabled;
  final bool biometricAvailable;
  final String biometricLabel;

  bool get authEnabled => pinEnabled || biometricEnabled;
  bool get biometricReady => pinEnabled && biometricEnabled && biometricAvailable;

  SecuritySettings copyWith({
    bool? pinEnabled,
    bool? biometricEnabled,
    bool? biometricAvailable,
    String? biometricLabel,
  }) {
    return SecuritySettings(
      pinEnabled: pinEnabled ?? this.pinEnabled,
      biometricEnabled: biometricEnabled ?? this.biometricEnabled,
      biometricAvailable: biometricAvailable ?? this.biometricAvailable,
      biometricLabel: biometricLabel ?? this.biometricLabel,
    );
  }

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'pinEnabled': pinEnabled,
      'biometricEnabled': biometricEnabled,
      'biometricAvailable': biometricAvailable,
      'biometricLabel': biometricLabel,
    };
  }
}
```

- [ ] **Step 4: Run model test and verify it passes**

Run:

```bash
flutter test test/settings/security_settings_test.dart
```

Expected: PASS.

- [ ] **Step 5: Write failing NativeBridge security tests**

In `test/settings/settings_bridge_test.dart`:

Add import:

```dart
import 'package:exptv2/features/settings/models/security_settings.dart';
```

In the existing `expenseLoadSettings` mock payload, add:

```dart
'securitySettings': <String, Object?>{
  'pinEnabled': true,
  'biometricEnabled': false,
  'biometricAvailable': true,
  'biometricLabel': 'Ujjlenyomat elerheto',
},
```

Add expectations to the `loads app theme and FastInfo settings` test:

```dart
expect(settings.securitySettings.pinEnabled, isTrue);
expect(settings.securitySettings.biometricAvailable, isTrue);
```

Add cases to the mock handler:

```dart
case 'expenseSetSecurityPin':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseChangeSecurityPin':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseClearSecurityPin':
  return <String, Object?>{
    'pinEnabled': false,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseVerifySecurityPin':
  return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
case 'expenseSetBiometricEnabled':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled':
        (call.arguments as Map<dynamic, dynamic>)['enabled'] == true,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseGetBiometricAvailability':
  return <String, Object?>{
    'pinEnabled': false,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseAuthenticateBiometric':
  return true;
```

Add tests:

```dart
test('updates security pin through native bridge', () async {
  final updated = await bridge.expenseSetSecurityPin('1234');

  expect(updated.pinEnabled, isTrue);
  expect(calls.single.method, 'expenseSetSecurityPin');
  final payload = calls.single.arguments as Map<dynamic, dynamic>;
  expect(payload['pin'], '1234');
});

test('changes security pin through native bridge', () async {
  final updated = await bridge.expenseChangeSecurityPin(
    currentPin: '1234',
    newPin: '4567',
  );

  expect(updated.pinEnabled, isTrue);
  expect(calls.single.method, 'expenseChangeSecurityPin');
  final payload = calls.single.arguments as Map<dynamic, dynamic>;
  expect(payload['currentPin'], '1234');
  expect(payload['newPin'], '4567');
});

test('clears security pin through native bridge', () async {
  final updated = await bridge.expenseClearSecurityPin('1234');

  expect(updated.pinEnabled, isFalse);
  expect(updated.biometricEnabled, isFalse);
  expect(calls.single.method, 'expenseClearSecurityPin');
});

test('verifies security pin through native bridge', () async {
  expect(await bridge.expenseVerifySecurityPin('1234'), isTrue);
  expect(await bridge.expenseVerifySecurityPin('0000'), isFalse);
});

test('updates biometric setting through native bridge', () async {
  final updated = await bridge.expenseSetBiometricEnabled(true);

  expect(updated.biometricEnabled, isTrue);
  expect(calls.single.method, 'expenseSetBiometricEnabled');
});

test('loads biometric availability and authenticates through native bridge', () async {
  final availability = await bridge.expenseGetBiometricAvailability();
  final authenticated = await bridge.expenseAuthenticateBiometric();

  expect(availability.biometricAvailable, isTrue);
  expect(authenticated, isTrue);
  expect(calls.map((call) => call.method), <String>[
    'expenseGetBiometricAvailability',
    'expenseAuthenticateBiometric',
  ]);
});
```

- [ ] **Step 6: Run NativeBridge tests and verify failure**

Run:

```bash
flutter test test/settings/settings_bridge_test.dart
```

Expected: FAIL because the bridge payload and methods do not exist.

- [ ] **Step 7: Implement NativeBridge contract**

In `lib/services/native_bridge.dart`, add import:

```dart
import '../features/settings/models/security_settings.dart';
```

Update `ExpenseSettingsPayload`:

```dart
class ExpenseSettingsPayload {
  const ExpenseSettingsPayload({
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.pushRecurringSettings,
    required this.securitySettings,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
  final PushRecurringSettings pushRecurringSettings;
  final SecuritySettings securitySettings;
}
```

Update `expenseLoadSettings()`:

```dart
final security = payload['securitySettings'];
return ExpenseSettingsPayload(
  themeSettings: theme is Map<dynamic, dynamic>
      ? AppThemeSettings.fromMap(theme)
      : AppThemeSettings.defaults(),
  fastInfoConfig: fastInfo is Map<dynamic, dynamic>
      ? FastInfoConfig.fromMap(fastInfo)
      : FastInfoConfig.defaults(),
  pushRecurringSettings: pushRecurring is Map<dynamic, dynamic>
      ? PushRecurringSettings.fromMap(pushRecurring)
      : PushRecurringSettings.defaults(),
  securitySettings: security is Map<dynamic, dynamic>
      ? SecuritySettings.fromMap(security)
      : SecuritySettings.defaults(),
);
```

Add methods:

```dart
Future<SecuritySettings> expenseSetSecurityPin(String pin) async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseSetSecurityPin',
    {'pin': pin},
  );
  return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
}

Future<SecuritySettings> expenseChangeSecurityPin({
  required String currentPin,
  required String newPin,
}) async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseChangeSecurityPin',
    {'currentPin': currentPin, 'newPin': newPin},
  );
  return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
}

Future<SecuritySettings> expenseClearSecurityPin(String currentPin) async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseClearSecurityPin',
    {'currentPin': currentPin},
  );
  return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
}

Future<bool> expenseVerifySecurityPin(String pin) async {
  final verified = await _methodChannel.invokeMethod<bool>(
    'expenseVerifySecurityPin',
    {'pin': pin},
  );
  return verified ?? false;
}

Future<SecuritySettings> expenseSetBiometricEnabled(bool enabled) async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseSetBiometricEnabled',
    {'enabled': enabled},
  );
  return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
}

Future<SecuritySettings> expenseGetBiometricAvailability() async {
  final row = await _methodChannel.invokeMapMethod<dynamic, dynamic>(
    'expenseGetBiometricAvailability',
  );
  return SecuritySettings.fromMap(row ?? <dynamic, dynamic>{});
}

Future<bool> expenseAuthenticateBiometric() async {
  final authenticated = await _methodChannel.invokeMethod<bool>(
    'expenseAuthenticateBiometric',
  );
  return authenticated ?? false;
}
```

- [ ] **Step 8: Run Task 1 tests**

Run:

```bash
flutter test test/settings/security_settings_test.dart test/settings/settings_bridge_test.dart
```

Expected: PASS.

- [ ] **Step 9: Commit Task 1**

Run:

```bash
git add lib/features/settings/models/security_settings.dart lib/services/native_bridge.dart test/settings/security_settings_test.dart test/settings/settings_bridge_test.dart
git commit -m "feat: add security settings bridge"
```

## Task 2: Settings Repository and Store Security State

**Files:**
- Modify: `lib/features/settings/data/settings_repository.dart`
- Modify: `lib/features/settings/state/settings_store.dart`
- Test: `test/settings/settings_store_test.dart`

- [ ] **Step 1: Write failing store test coverage**

In `test/settings/settings_store_test.dart`, update the `expenseLoadSettings`
mock payload:

```dart
'securitySettings': <String, Object?>{
  'pinEnabled': false,
  'biometricEnabled': false,
  'biometricAvailable': true,
  'biometricLabel': 'Ujjlenyomat elerheto',
},
```

Add mock cases:

```dart
case 'expenseSetSecurityPin':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseChangeSecurityPin':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseClearSecurityPin':
  return <String, Object?>{
    'pinEnabled': false,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseVerifySecurityPin':
  return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
case 'expenseSetBiometricEnabled':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled':
        (call.arguments as Map<dynamic, dynamic>)['enabled'] == true,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseGetBiometricAvailability':
  return <String, Object?>{
    'pinEnabled': store.securitySettings.pinEnabled,
    'biometricEnabled': store.securitySettings.biometricEnabled,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
```

Add tests:

```dart
test('loads security settings', () async {
  await store.start();

  expect(store.securitySettings.pinEnabled, isFalse);
  expect(store.securitySettings.biometricAvailable, isTrue);
});

test('updates pin and biometric settings', () async {
  await store.start();

  await store.setSecurityPin('1234');
  expect(store.securitySettings.pinEnabled, isTrue);

  expect(await store.verifySecurityPin('1234'), isTrue);
  expect(await store.verifySecurityPin('0000'), isFalse);

  await store.setBiometricEnabled(true);
  expect(store.securitySettings.biometricEnabled, isTrue);

  await store.clearSecurityPin('1234');
  expect(store.securitySettings.pinEnabled, isFalse);
  expect(store.securitySettings.biometricEnabled, isFalse);

  expect(methods, contains('expenseSetSecurityPin'));
  expect(methods, contains('expenseVerifySecurityPin'));
  expect(methods, contains('expenseSetBiometricEnabled'));
  expect(methods, contains('expenseClearSecurityPin'));
});
```

- [ ] **Step 2: Run store tests and verify failure**

Run:

```bash
flutter test test/settings/settings_store_test.dart
```

Expected: FAIL because repository/store security methods do not exist.

- [ ] **Step 3: Implement repository methods**

In `lib/features/settings/data/settings_repository.dart`, import:

```dart
import '../models/security_settings.dart';
```

Update `SettingsBootstrap`:

```dart
class SettingsBootstrap {
  const SettingsBootstrap({
    required this.themeSettings,
    required this.fastInfoConfig,
    required this.securitySettings,
    required this.categories,
  });

  final AppThemeSettings themeSettings;
  final FastInfoConfig fastInfoConfig;
  final SecuritySettings securitySettings;
  final List<TransactionCategory> categories;
}
```

Update `loadBootstrap()` return:

```dart
return SettingsBootstrap(
  themeSettings: settings.themeSettings,
  fastInfoConfig: settings.fastInfoConfig,
  securitySettings: settings.securitySettings,
  categories: categories,
);
```

Add methods:

```dart
Future<SecuritySettings> setSecurityPin(String pin) {
  return _bridge.expenseSetSecurityPin(pin);
}

Future<SecuritySettings> changeSecurityPin({
  required String currentPin,
  required String newPin,
}) {
  return _bridge.expenseChangeSecurityPin(
    currentPin: currentPin,
    newPin: newPin,
  );
}

Future<SecuritySettings> clearSecurityPin(String currentPin) {
  return _bridge.expenseClearSecurityPin(currentPin);
}

Future<bool> verifySecurityPin(String pin) {
  return _bridge.expenseVerifySecurityPin(pin);
}

Future<SecuritySettings> setBiometricEnabled(bool enabled) {
  return _bridge.expenseSetBiometricEnabled(enabled);
}

Future<SecuritySettings> loadBiometricAvailability() {
  return _bridge.expenseGetBiometricAvailability();
}
```

- [ ] **Step 4: Implement store methods**

In `lib/features/settings/state/settings_store.dart`, import:

```dart
import '../models/security_settings.dart';
```

Add field and getter:

```dart
SecuritySettings _securitySettings = SecuritySettings.defaults();
SecuritySettings get securitySettings => _securitySettings;
```

Update `start()` after payload load:

```dart
_securitySettings = payload.securitySettings;
```

Add methods:

```dart
Future<void> setSecurityPin(String pin) async {
  _securitySettings = await _repository.setSecurityPin(pin);
  notifyListeners();
}

Future<void> changeSecurityPin({
  required String currentPin,
  required String newPin,
}) async {
  _securitySettings = await _repository.changeSecurityPin(
    currentPin: currentPin,
    newPin: newPin,
  );
  notifyListeners();
}

Future<void> clearSecurityPin(String currentPin) async {
  _securitySettings = await _repository.clearSecurityPin(currentPin);
  notifyListeners();
}

Future<bool> verifySecurityPin(String pin) {
  return _repository.verifySecurityPin(pin);
}

Future<void> setBiometricEnabled(bool enabled) async {
  _securitySettings = await _repository.setBiometricEnabled(enabled);
  notifyListeners();
}

Future<void> refreshBiometricAvailability() async {
  _securitySettings = await _repository.loadBiometricAvailability();
  notifyListeners();
}
```

- [ ] **Step 5: Run Task 2 tests**

Run:

```bash
flutter test test/settings/settings_store_test.dart
```

Expected: PASS.

- [ ] **Step 6: Commit Task 2**

Run:

```bash
git add lib/features/settings/data/settings_repository.dart lib/features/settings/state/settings_store.dart test/settings/settings_store_test.dart
git commit -m "feat: store security settings state"
```

## Task 3: Android PIN Storage and Hash Verification

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`

- [ ] **Step 1: Write failing Kotlin security tests**

Create `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`:

```kotlin
package com.exptv2.app.expense

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

class ExpenseSettingsStoreSecurityTest {
    private lateinit var context: Context
    private lateinit var store: ExpenseSettingsStore

    @Before
    fun setUp() {
        context = ApplicationProvider.getApplicationContext()
        context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)
            .edit()
            .clear()
            .commit()
        store = ExpenseSettingsStore(context)
    }

    @Test
    fun securitySettingsDefaultToDisabled() {
        val settings = store.loadSecuritySettings()

        assertEquals(false, settings["pinEnabled"])
        assertEquals(false, settings["biometricEnabled"])
    }

    @Test
    fun setSecurityPinStoresHashAndVerifiesPin() {
        store.setSecurityPin("1234")

        val settings = store.loadSecuritySettings()
        assertEquals(true, settings["pinEnabled"])
        assertTrue(store.verifySecurityPin("1234"))
        assertFalse(store.verifySecurityPin("0000"))
    }

    @Test
    fun changingPinRequiresCurrentPin() {
        store.setSecurityPin("1234")
        val changed = store.changeSecurityPin("1234", "4567")

        assertEquals(true, changed["pinEnabled"])
        assertFalse(store.verifySecurityPin("1234"))
        assertTrue(store.verifySecurityPin("4567"))
    }

    @Test(expected = ExpenseValidationException::class)
    fun changingPinRejectsWrongCurrentPin() {
        store.setSecurityPin("1234")

        store.changeSecurityPin("0000", "4567")
    }

    @Test
    fun clearingPinAlsoClearsBiometric() {
        store.setSecurityPin("1234")
        store.setBiometricEnabledForTest(true)

        val settings = store.clearSecurityPin("1234")

        assertEquals(false, settings["pinEnabled"])
        assertEquals(false, settings["biometricEnabled"])
        assertFalse(store.verifySecurityPin("1234"))
    }

    @Test
    fun saltChangesHashForSamePin() {
        val first = ExpenseSettingsStore.hashPinForTest("1234", "salt-a")
        val second = ExpenseSettingsStore.hashPinForTest("1234", "salt-b")

        assertNotEquals(first, second)
    }
}
```

Add local JVM Android test dependencies to `android/app/build.gradle.kts`:

```kotlin
testImplementation("androidx.test:core:1.6.1")
testImplementation("org.robolectric:robolectric:4.13")
```

Add Android unit test resource support inside the `android { ... }` block:

```kotlin
testOptions {
    unitTests.isIncludeAndroidResources = true
}
```

- [ ] **Step 2: Run Kotlin test and verify failure**

Run:

```bash
./gradlew -p android app:testDebugUnitTest --tests com.exptv2.app.expense.ExpenseSettingsStoreSecurityTest
```

Expected: FAIL because security methods do not exist.

- [ ] **Step 3: Implement PIN storage methods**

In `ExpenseSettingsStore.kt`, add imports:

```kotlin
import android.util.Base64
import java.security.MessageDigest
import java.security.SecureRandom
```

Add to `loadSettings()`:

```kotlin
"securitySettings" to loadSecuritySettings(),
```

Add methods:

```kotlin
fun loadSecuritySettings(): Map<String, Any?> {
    val pinEnabled = prefs.getString(KEY_SECURITY_PIN_HASH, null).isNullOrBlank().not()
    val biometricEnabled = pinEnabled && prefs.getBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
    return mapOf(
        "pinEnabled" to pinEnabled,
        "biometricEnabled" to biometricEnabled,
        "biometricAvailable" to false,
        "biometricLabel" to "Nem elerheto",
    )
}

fun setSecurityPin(pin: String): Map<String, Any?> {
    validatePin(pin)
    val salt = newSalt()
    prefs.edit()
        .putString(KEY_SECURITY_PIN_SALT, salt)
        .putString(KEY_SECURITY_PIN_HASH, hashPin(pin, salt))
        .putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
        .apply()
    return loadSecuritySettings()
}

fun changeSecurityPin(currentPin: String, newPin: String): Map<String, Any?> {
    if (!verifySecurityPin(currentPin)) {
        throw ExpenseValidationException("PIN_INVALID", "Invalid PIN")
    }
    return setSecurityPin(newPin)
}

fun clearSecurityPin(currentPin: String): Map<String, Any?> {
    if (!verifySecurityPin(currentPin)) {
        throw ExpenseValidationException("PIN_INVALID", "Invalid PIN")
    }
    prefs.edit()
        .remove(KEY_SECURITY_PIN_SALT)
        .remove(KEY_SECURITY_PIN_HASH)
        .putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
        .apply()
    return loadSecuritySettings()
}

fun verifySecurityPin(pin: String): Boolean {
    val salt = prefs.getString(KEY_SECURITY_PIN_SALT, null) ?: return false
    val storedHash = prefs.getString(KEY_SECURITY_PIN_HASH, null) ?: return false
    return hashPin(pin, salt) == storedHash
}

fun setBiometricEnabledForTest(enabled: Boolean): Map<String, Any?> {
    if (enabled && prefs.getString(KEY_SECURITY_PIN_HASH, null).isNullOrBlank()) {
        throw ExpenseValidationException("PIN_NOT_CONFIGURED", "PIN is required")
    }
    prefs.edit().putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, enabled).apply()
    return loadSecuritySettings()
}

private fun validatePin(pin: String) {
    if (!pin.matches(Regex("\\d{4,6}"))) {
        throw ExpenseValidationException("PIN_REQUIRED", "PIN must be 4 to 6 digits")
    }
}

private fun newSalt(): String {
    val bytes = ByteArray(16)
    SecureRandom().nextBytes(bytes)
    return Base64.encodeToString(bytes, Base64.NO_WRAP)
}

private fun hashPin(pin: String, salt: String): String = hashPinStatic(pin, salt)
```

Add companion keys and helpers:

```kotlin
private const val KEY_SECURITY_PIN_SALT = "securityPinSalt"
private const val KEY_SECURITY_PIN_HASH = "securityPinHash"
private const val KEY_SECURITY_BIOMETRIC_ENABLED = "securityBiometricEnabled"

fun hashPinForTest(pin: String, salt: String): String = hashPinStatic(pin, salt)

private fun hashPinStatic(pin: String, salt: String): String {
    val digest = MessageDigest.getInstance("SHA-256")
    val bytes = digest.digest("$salt:$pin".toByteArray(Charsets.UTF_8))
    return Base64.encodeToString(bytes, Base64.NO_WRAP)
}
```

- [ ] **Step 4: Add MethodChannel PIN cases**

In `ExpenseMethodChannel.kt`, add cases before `else`:

```kotlin
"expenseSetSecurityPin" -> scope.launchResult(result) {
    val pin = call.argumentsMap()["pin"]?.toString()
        ?: throw ExpenseValidationException("PIN_REQUIRED", "PIN is required")
    repository.settingsStoreForSecurity().setSecurityPin(pin)
}
"expenseChangeSecurityPin" -> scope.launchResult(result) {
    val args = call.argumentsMap()
    repository.settingsStoreForSecurity().changeSecurityPin(
        args["currentPin"]?.toString() ?: "",
        args["newPin"]?.toString() ?: "",
    )
}
"expenseClearSecurityPin" -> scope.launchResult(result) {
    repository.settingsStoreForSecurity().clearSecurityPin(
        call.argumentsMap()["currentPin"]?.toString() ?: "",
    )
}
"expenseVerifySecurityPin" -> scope.launchResult(result) {
    repository.settingsStoreForSecurity().verifySecurityPin(
        call.argumentsMap()["pin"]?.toString() ?: "",
    )
}
```

If `ExpenseRepository` does not expose its settings store, add this focused
method in `ExpenseRepository.kt`:

```kotlin
fun settingsStoreForSecurity(): ExpenseSettingsStore = settingsStore
```

- [ ] **Step 5: Run Kotlin PIN tests**

Run:

```bash
./gradlew -p android app:testDebugUnitTest --tests com.exptv2.app.expense.ExpenseSettingsStoreSecurityTest
```

Expected: PASS.

- [ ] **Step 6: Commit Task 3**

Run:

```bash
git add android/app/build.gradle.kts android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt
git commit -m "feat: persist security pin"
```

## Task 4: AndroidX Biometric Prompt Integration

**Files:**
- Modify: `android/app/build.gradle.kts`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`

- [ ] **Step 1: Add AndroidX Biometric dependency**

In `android/app/build.gradle.kts`, add:

```kotlin
implementation("androidx.biometric:biometric:1.1.0")
```

- [ ] **Step 2: Make `MainActivity` compatible with BiometricPrompt**

In `MainActivity.kt`, replace:

```kotlin
import io.flutter.embedding.android.FlutterActivity
```

with:

```kotlin
import io.flutter.embedding.android.FlutterFragmentActivity
```

Change:

```kotlin
class MainActivity : FlutterActivity() {
```

to:

```kotlin
class MainActivity : FlutterFragmentActivity() {
```

Keep the existing `configureFlutterEngine` body. `FlutterFragmentActivity` is
required because `BiometricPrompt` needs a `FragmentActivity`.

- [ ] **Step 3: Add biometric availability helpers**

In `ExpenseSettingsStore.kt`, add:

```kotlin
fun loadSecuritySettings(
    biometricAvailable: Boolean = false,
    biometricLabel: String = "Nem elerheto",
): Map<String, Any?> {
    val pinEnabled = prefs.getString(KEY_SECURITY_PIN_HASH, null).isNullOrBlank().not()
    val biometricEnabled = pinEnabled && prefs.getBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, false)
    return mapOf(
        "pinEnabled" to pinEnabled,
        "biometricEnabled" to biometricEnabled,
        "biometricAvailable" to biometricAvailable,
        "biometricLabel" to biometricLabel,
    )
}

fun setBiometricEnabled(enabled: Boolean, biometricAvailable: Boolean): Map<String, Any?> {
    val pinEnabled = prefs.getString(KEY_SECURITY_PIN_HASH, null).isNullOrBlank().not()
    if (enabled && !pinEnabled) {
        throw ExpenseValidationException("PIN_NOT_CONFIGURED", "PIN is required")
    }
    if (enabled && !biometricAvailable) {
        throw ExpenseValidationException("BIOMETRIC_UNAVAILABLE", "Biometric authentication is unavailable")
    }
    prefs.edit().putBoolean(KEY_SECURITY_BIOMETRIC_ENABLED, enabled).apply()
    return loadSecuritySettings(
        biometricAvailable = biometricAvailable,
        biometricLabel = if (biometricAvailable) "Biometria elerheto" else "Nem elerheto",
    )
}
```

Update the old no-arg `loadSecuritySettings()` from Task 3 instead of
duplicating it.

- [ ] **Step 4: Add biometric support to `ExpenseMethodChannel`**

Change constructor:

```kotlin
class ExpenseMethodChannel(
    private val activity: FragmentActivity,
    context: Context,
    private val scope: CoroutineScope,
) {
```

Add imports:

```kotlin
import androidx.biometric.BiometricManager
import androidx.biometric.BiometricPrompt
import androidx.core.content.ContextCompat
import androidx.fragment.app.FragmentActivity
import kotlin.coroutines.resume
import kotlinx.coroutines.suspendCancellableCoroutine
```

Add constants/properties:

```kotlin
private val authenticators = BiometricManager.Authenticators.BIOMETRIC_WEAK
```

Add helpers:

```kotlin
private fun biometricAvailable(): Boolean {
    val manager = BiometricManager.from(activity)
    return manager.canAuthenticate(authenticators) == BiometricManager.BIOMETRIC_SUCCESS
}

private fun biometricLabel(): String {
    return if (biometricAvailable()) "Biometria elerheto" else "Nem elerheto"
}

private suspend fun authenticateBiometric(): Boolean = suspendCancellableCoroutine { continuation ->
    val executor = ContextCompat.getMainExecutor(activity)
    val prompt = BiometricPrompt(
        activity,
        executor,
        object : BiometricPrompt.AuthenticationCallback() {
            override fun onAuthenticationSucceeded(result: BiometricPrompt.AuthenticationResult) {
                if (continuation.isActive) continuation.resume(true)
            }

            override fun onAuthenticationError(errorCode: Int, errString: CharSequence) {
                if (continuation.isActive) continuation.resume(false)
            }

            override fun onAuthenticationFailed() {
                if (continuation.isActive) continuation.resume(false)
            }
        },
    )
    val info = BiometricPrompt.PromptInfo.Builder()
        .setTitle("Exptv2 belepes")
        .setSubtitle("Azonositsd magad az alkalmazas megnyitasahoz")
        .setNegativeButtonText("PIN hasznalata")
        .setAllowedAuthenticators(authenticators)
        .build()
    prompt.authenticate(info)
    continuation.invokeOnCancellation { prompt.cancelAuthentication() }
}
```

Add MethodChannel cases:

```kotlin
"expenseSetBiometricEnabled" -> scope.launchResult(result) {
    val enabled = call.argumentsMap()["enabled"] == true
    repository.settingsStoreForSecurity().setBiometricEnabled(
        enabled = enabled,
        biometricAvailable = biometricAvailable(),
    )
}
"expenseGetBiometricAvailability" -> scope.launchResult(result) {
    repository.settingsStoreForSecurity().loadSecuritySettings(
        biometricAvailable = biometricAvailable(),
        biometricLabel = biometricLabel(),
    )
}
"expenseAuthenticateBiometric" -> scope.launchResult(result) {
    withContext(Dispatchers.Main) { authenticateBiometric() }
}
```

Update `MainActivity.kt` construction:

```kotlin
val expenseChannel = ExpenseMethodChannel(this, this, scope)
```

- [ ] **Step 5: Run Android compile/test check**

Run:

```bash
./gradlew -p android app:testDebugUnitTest
```

Expected: PASS or existing unrelated failures only. If Kotlin compilation fails
around `setAllowedAuthenticators`, keep `setNegativeButtonText` and remove
`setAllowedAuthenticators` for Biometric 1.1.0 compatibility.

- [ ] **Step 6: Commit Task 4**

Run:

```bash
git add android/app/build.gradle.kts android/app/src/main/kotlin/com/exptv2/app/MainActivity.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt
git commit -m "feat: add biometric authentication bridge"
```

## Task 5: Settings PIN and Biometric Panels

**Files:**
- Create: `lib/features/settings/widgets/security/pin_settings_panel.dart`
- Create: `lib/features/settings/widgets/security/biometric_settings_panel.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Write failing Settings page tests**

In `test/settings/settings_page_test.dart`, add `securitySettings` to the
`expenseLoadSettings` mock:

```dart
'securitySettings': <String, Object?>{
  'pinEnabled': false,
  'biometricEnabled': false,
  'biometricAvailable': true,
  'biometricLabel': 'Ujjlenyomat elerheto',
},
```

Add mock cases:

```dart
case 'expenseSetSecurityPin':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseVerifySecurityPin':
  return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
case 'expenseClearSecurityPin':
  return <String, Object?>{
    'pinEnabled': false,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseSetBiometricEnabled':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled':
        (call.arguments as Map<dynamic, dynamic>)['enabled'] == true,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
case 'expenseAuthenticateBiometric':
  return true;
case 'expenseGetBiometricAvailability':
  return <String, Object?>{
    'pinEnabled': true,
    'biometricEnabled': false,
    'biometricAvailable': true,
    'biometricLabel': 'Ujjlenyomat elerheto',
  };
```

Add test:

```dart
testWidgets('sets security pin from settings', (tester) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(buildSubject());
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(find.text('PIN kod beallitasa'), 160);
  await tester.tap(find.text('PIN kod beallitasa'));
  await tester.pumpAndSettle();

  expect(find.text('PIN beallitasa'), findsOneWidget);
  await tester.enterText(find.byKey(const ValueKey('pin-new-input')), '1234');
  await tester.enterText(
    find.byKey(const ValueKey('pin-confirm-input')),
    '1234',
  );
  await tester.tap(find.byKey(const ValueKey('pin-save-button')));
  await tester.pumpAndSettle();

  expect(find.text('PIN aktiv'), findsOneWidget);
  expect(calls, contains('expenseSetSecurityPin'));
});

testWidgets('biometric setting requires pin first', (tester) async {
  tester.view.physicalSize = const Size(800, 1200);
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.resetPhysicalSize);
  addTearDown(tester.view.resetDevicePixelRatio);

  await tester.pumpWidget(buildSubject());
  await tester.pumpAndSettle();

  await tester.scrollUntilVisible(find.text('Biometrikus azonositas'), 160);
  await tester.tap(find.text('Biometrikus azonositas'));
  await tester.pumpAndSettle();

  expect(find.text('PIN szukseges'), findsOneWidget);
  expect(find.byKey(const ValueKey('biometric-enable-switch')), findsNothing);
});
```

- [ ] **Step 2: Run Settings page tests and verify failure**

Run:

```bash
flutter test test/settings/settings_page_test.dart
```

Expected: FAIL because PIN/biometric submenus do not exist.

- [ ] **Step 3: Implement PIN panel**

Create `lib/features/settings/widgets/security/pin_settings_panel.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/security_settings.dart';
import '../options/settings_option_widgets.dart';

class PinSettingsPanel extends StatefulWidget {
  const PinSettingsPanel({
    super.key,
    required this.settings,
    required this.onSetPin,
    required this.onChangePin,
    required this.onClearPin,
  });

  final SecuritySettings settings;
  final Future<void> Function(String pin) onSetPin;
  final Future<void> Function(String currentPin, String newPin) onChangePin;
  final Future<void> Function(String currentPin) onClearPin;

  @override
  State<PinSettingsPanel> createState() => _PinSettingsPanelState();
}

class _PinSettingsPanelState extends State<PinSettingsPanel> {
  final _current = TextEditingController();
  final _newPin = TextEditingController();
  final _confirm = TextEditingController();
  var _busy = false;
  String? _error;

  @override
  void dispose() {
    _current.dispose();
    _newPin.dispose();
    _confirm.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('pin-settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: 'PIN beallitasa',
          children: [
            SettingsOptionItem(
              title: widget.settings.pinEnabled ? 'PIN aktiv' : 'Nincs PIN',
              trailing: Icon(
                widget.settings.pinEnabled ? Icons.lock : Icons.lock_open,
                color: widget.settings.pinEnabled
                    ? AppColors.primary
                    : AppColors.gray400,
              ),
              isLast: true,
            ),
          ],
        ),
        if (widget.settings.pinEnabled)
          _pinField(_current, 'Jelenlegi PIN', const ValueKey('pin-current-input')),
        _pinField(_newPin, 'Uj PIN', const ValueKey('pin-new-input')),
        _pinField(_confirm, 'PIN megerositese', const ValueKey('pin-confirm-input')),
        if (_error != null) ...[
          const SizedBox(height: 10),
          Text(_error!, style: const TextStyle(color: Colors.red)),
        ],
        const SizedBox(height: 16),
        FilledButton(
          key: const ValueKey('pin-save-button'),
          onPressed: _busy ? null : _save,
          child: Text(widget.settings.pinEnabled ? 'PIN modositasa' : 'PIN bekapcsolasa'),
        ),
        if (widget.settings.pinEnabled) ...[
          const SizedBox(height: 10),
          OutlinedButton(
            key: const ValueKey('pin-clear-button'),
            onPressed: _busy ? null : _clear,
            child: const Text('PIN kikapcsolasa'),
          ),
        ],
      ],
    );
  }

  Widget _pinField(TextEditingController controller, String label, Key key) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        key: key,
        controller: controller,
        obscureText: true,
        keyboardType: TextInputType.number,
        inputFormatters: [
          FilteringTextInputFormatter.digitsOnly,
          LengthLimitingTextInputFormatter(6),
        ],
        decoration: InputDecoration(labelText: label, border: const OutlineInputBorder()),
      ),
    );
  }

  Future<void> _save() async {
    final next = _newPin.text;
    final confirm = _confirm.text;
    if (!_validPin(next)) {
      setState(() => _error = 'A PIN 4-6 szamjegy legyen.');
      return;
    }
    if (next != confirm) {
      setState(() => _error = 'A ket PIN nem egyezik.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (widget.settings.pinEnabled) {
        await widget.onChangePin(_current.text, next);
      } else {
        await widget.onSetPin(next);
      }
      _current.clear();
      _newPin.clear();
      _confirm.clear();
    } catch (_) {
      setState(() => _error = 'A PIN muvelet nem sikerult.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clear() async {
    if (!_validPin(_current.text)) {
      setState(() => _error = 'Add meg a jelenlegi PIN-t.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await widget.onClearPin(_current.text);
      _current.clear();
      _newPin.clear();
      _confirm.clear();
    } catch (_) {
      setState(() => _error = 'A PIN kikapcsolasa nem sikerult.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  bool _validPin(String value) => RegExp(r'^\d{4,6}$').hasMatch(value);
}
```

- [ ] **Step 4: Implement biometric panel**

Create `lib/features/settings/widgets/security/biometric_settings_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/security_settings.dart';
import '../options/settings_option_widgets.dart';

class BiometricSettingsPanel extends StatefulWidget {
  const BiometricSettingsPanel({
    super.key,
    required this.settings,
    required this.onRefreshAvailability,
    required this.onAuthenticate,
    required this.onSetEnabled,
    required this.onOpenPinSettings,
  });

  final SecuritySettings settings;
  final Future<void> Function() onRefreshAvailability;
  final Future<bool> Function() onAuthenticate;
  final Future<void> Function(bool enabled) onSetEnabled;
  final VoidCallback onOpenPinSettings;

  @override
  State<BiometricSettingsPanel> createState() => _BiometricSettingsPanelState();
}

class _BiometricSettingsPanelState extends State<BiometricSettingsPanel> {
  var _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onRefreshAvailability();
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.settings.pinEnabled) {
      return ListView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        children: [
          const SettingsSection(
            title: 'PIN szukseges',
            children: [
              SettingsOptionItem(
                title: 'Biometria csak PIN utan kapcsolhato be',
                trailing: Icon(Icons.info_outline, color: AppColors.gray400),
                isLast: true,
              ),
            ],
          ),
          FilledButton(
            key: const ValueKey('biometric-open-pin-button'),
            onPressed: widget.onOpenPinSettings,
            child: const Text('PIN beallitasa'),
          ),
        ],
      );
    }

    return ListView(
      key: const ValueKey('biometric-settings-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        SettingsSection(
          title: 'Biometrikus azonositas',
          children: [
            SettingsOptionItem(
              title: widget.settings.biometricLabel,
              trailing: Switch(
                key: const ValueKey('biometric-enable-switch'),
                value: widget.settings.biometricEnabled,
                onChanged: _busy || !widget.settings.biometricAvailable
                    ? null
                    : _toggle,
              ),
              isLast: true,
            ),
          ],
        ),
        if (_error != null)
          Text(_error!, style: const TextStyle(color: Colors.red)),
      ],
    );
  }

  Future<void> _toggle(bool enabled) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (enabled) {
        final ok = await widget.onAuthenticate();
        if (!ok) {
          setState(() => _error = 'A biometrikus azonositas nem sikerult.');
          return;
        }
      }
      await widget.onSetEnabled(enabled);
    } catch (_) {
      setState(() => _error = 'A biometrikus beallitas nem sikerult.');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }
}
```

- [ ] **Step 5: Wire settings page**

In `settings_page.dart`, add enum values:

```dart
pinSecurity,
biometricSecurity,
```

Add imports:

```dart
import 'widgets/security/biometric_settings_panel.dart';
import 'widgets/security/pin_settings_panel.dart';
```

Replace the security section:

```dart
SettingsSection(
  title: 'Adatvedelem es biztonsag',
  children: [
    SettingsOptionItem(
      title: 'PIN kod beallitasa',
      onTap: () => _open(_SettingsMenu.pinSecurity),
    ),
    SettingsOptionItem(
      title: 'Biometrikus azonositas',
      onTap: () => _open(_SettingsMenu.biometricSecurity),
    ),
    const SettingsOptionItem(
      title: 'Adatvedelmi szabalyzat',
      isLast: true,
    ),
  ],
),
```

Add submenu bodies:

```dart
_SettingsMenu.pinSecurity => PinSettingsPanel(
  settings: _settingsStore.securitySettings,
  onSetPin: _settingsStore.setSecurityPin,
  onChangePin: (currentPin, newPin) => _settingsStore.changeSecurityPin(
    currentPin: currentPin,
    newPin: newPin,
  ),
  onClearPin: _settingsStore.clearSecurityPin,
),
_SettingsMenu.biometricSecurity => BiometricSettingsPanel(
  settings: _settingsStore.securitySettings,
  onRefreshAvailability: _settingsStore.refreshBiometricAvailability,
  onAuthenticate: widget.nativeBridge.expenseAuthenticateBiometric,
  onSetEnabled: _settingsStore.setBiometricEnabled,
  onOpenPinSettings: () => setState(() => _activeMenu = _SettingsMenu.pinSecurity),
),
```

Add menu titles:

```dart
_SettingsMenu.pinSecurity => 'PIN kod beallitasa',
_SettingsMenu.biometricSecurity => 'Biometrikus azonositas',
```

- [ ] **Step 6: Run Settings UI tests**

Run:

```bash
flutter test test/settings/settings_page_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit Task 5**

Run:

```bash
git add lib/features/settings/settings_page.dart lib/features/settings/widgets/security/pin_settings_panel.dart lib/features/settings/widgets/security/biometric_settings_panel.dart test/settings/settings_page_test.dart
git commit -m "feat: add security settings panels"
```

## Task 6: App Lock Gate and Lifecycle Locking

**Files:**
- Create: `lib/features/security/security_controller.dart`
- Create: `lib/features/security/security_gate.dart`
- Modify: `lib/exptv2_app.dart`
- Test: `test/security/security_gate_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing lock gate tests**

Create `test/security/security_gate_test.dart`:

```dart
import 'package:exptv2/features/security/security_gate.dart';
import 'package:exptv2/services/native_bridge.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('test/security_gate_methods');
  final calls = <String>[];
  var pinEnabled = true;
  var biometricEnabled = false;
  var biometricResult = false;

  setUp(() {
    calls.clear();
    pinEnabled = true;
    biometricEnabled = false;
    biometricResult = false;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          calls.add(call.method);
          switch (call.method) {
            case 'expenseLoadSettings':
              return <String, Object?>{
                'themeSettings': <String, Object?>{},
                'fastInfoConfig': <String, Object?>{},
                'pushRecurringSettings': <String, Object?>{},
                'securitySettings': <String, Object?>{
                  'pinEnabled': pinEnabled,
                  'biometricEnabled': biometricEnabled,
                  'biometricAvailable': true,
                  'biometricLabel': 'Ujjlenyomat elerheto',
                },
              };
            case 'expenseVerifySecurityPin':
              return (call.arguments as Map<dynamic, dynamic>)['pin'] == '1234';
            case 'expenseAuthenticateBiometric':
              return biometricResult;
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  Widget subject() {
    return MaterialApp(
      home: SecurityGate(
        nativeBridge: NativeBridge(
          methodChannel: channel,
          eventChannel: const EventChannel('test/security_gate_events'),
        ),
        child: const Text('Unlocked app'),
      ),
    );
  }

  testWidgets('locks on startup when pin is enabled', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(find.text('Feloldas'), findsOneWidget);
    expect(find.text('Unlocked app'), findsNothing);

    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();

    expect(find.text('Unlocked app'), findsOneWidget);
  });

  testWidgets('locks again after background resume', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();
    expect(find.text('Unlocked app'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    await tester.pump();
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(find.text('Feloldas'), findsOneWidget);
    expect(find.text('Unlocked app'), findsNothing);
  });

  testWidgets('does not lock during ordinary foreground pumping', (tester) async {
    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();
    await tester.enterText(find.byKey(const ValueKey('lock-pin-input')), '1234');
    await tester.tap(find.byKey(const ValueKey('lock-unlock-button')));
    await tester.pumpAndSettle();

    await tester.pump(const Duration(minutes: 30));

    expect(find.text('Unlocked app'), findsOneWidget);
    expect(find.text('Feloldas'), findsNothing);
  });

  testWidgets('biometric failure keeps pin fallback visible', (tester) async {
    biometricEnabled = true;
    biometricResult = false;

    await tester.pumpWidget(subject());
    await tester.pumpAndSettle();

    expect(calls, contains('expenseAuthenticateBiometric'));
    expect(find.byKey(const ValueKey('lock-pin-input')), findsOneWidget);
  });
}
```

In `test/widget_test.dart`, add `securitySettings` to every mocked
`expenseLoadSettings` payload:

```dart
'securitySettings': <String, Object?>{
  'pinEnabled': false,
  'biometricEnabled': false,
  'biometricAvailable': false,
  'biometricLabel': 'Nem elerheto',
},
```

- [ ] **Step 2: Run lock tests and verify failure**

Run:

```bash
flutter test test/security/security_gate_test.dart
```

Expected: FAIL because `SecurityGate` does not exist.

- [ ] **Step 3: Implement `SecurityController`**

Create `lib/features/security/security_controller.dart`:

```dart
import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../services/native_bridge.dart';
import '../settings/models/security_settings.dart';

class SecurityController extends ChangeNotifier {
  SecurityController(this._nativeBridge);

  final NativeBridge _nativeBridge;
  SecuritySettings _settings = SecuritySettings.defaults();
  var _loading = true;
  var _locked = false;
  var _authenticatingBiometric = false;
  String? _error;

  SecuritySettings get settings => _settings;
  bool get loading => _loading;
  bool get locked => _locked;
  bool get authenticatingBiometric => _authenticatingBiometric;
  String? get error => _error;

  Future<void> start() async {
    await _load(lockIfEnabled: true);
  }

  Future<void> lockForResume() async {
    await _load(lockIfEnabled: true);
  }

  Future<void> refreshSettings() async {
    await _load(lockIfEnabled: false);
  }

  Future<void> _load({required bool lockIfEnabled}) async {
    _loading = true;
    _error = null;
    notifyListeners();
    try {
      final payload = await _nativeBridge.expenseLoadSettings();
      _settings = payload.securitySettings;
      if (lockIfEnabled && _settings.authEnabled) {
        _locked = true;
        if (_settings.biometricReady) {
          unawaited(authenticateBiometric());
        }
      } else if (!_settings.authEnabled) {
        _locked = false;
      }
    } catch (error) {
      _error = error.toString();
      _locked = true;
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> authenticateBiometric() async {
    if (!_settings.biometricReady || _authenticatingBiometric) return;
    _authenticatingBiometric = true;
    _error = null;
    notifyListeners();
    try {
      final ok = await _nativeBridge.expenseAuthenticateBiometric();
      if (ok) _locked = false;
    } catch (error) {
      _error = error.toString();
    } finally {
      _authenticatingBiometric = false;
      notifyListeners();
    }
  }

  Future<void> unlockWithPin(String pin) async {
    final ok = await _nativeBridge.expenseVerifySecurityPin(pin);
    if (ok) {
      _locked = false;
      _error = null;
    } else {
      _error = 'Hibas PIN.';
    }
    notifyListeners();
  }
}
```

- [ ] **Step 4: Implement `SecurityGate`**

Create `lib/features/security/security_gate.dart`:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/theme/app_colors.dart';
import '../../services/native_bridge.dart';
import 'security_controller.dart';

class SecurityGate extends StatefulWidget {
  const SecurityGate({
    super.key,
    required this.nativeBridge,
    required this.child,
  });

  final NativeBridge nativeBridge;
  final Widget child;

  @override
  State<SecurityGate> createState() => _SecurityGateState();
}

class _SecurityGateState extends State<SecurityGate> with WidgetsBindingObserver {
  late SecurityController _controller;
  final _pinController = TextEditingController();
  var _wasBackgrounded = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _controller = SecurityController(widget.nativeBridge);
    _controller.addListener(_onChanged);
    unawaited(_controller.start());
  }

  @override
  void didUpdateWidget(covariant SecurityGate oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.nativeBridge == widget.nativeBridge) return;
    _controller.removeListener(_onChanged);
    _controller = SecurityController(widget.nativeBridge);
    _controller.addListener(_onChanged);
    unawaited(_controller.start());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.removeListener(_onChanged);
    _controller.dispose();
    _pinController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive ||
        state == AppLifecycleState.detached) {
      _wasBackgrounded = true;
      return;
    }
    if (state == AppLifecycleState.resumed && _wasBackgrounded) {
      _wasBackgrounded = false;
      unawaited(_controller.lockForResume());
    }
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_controller.loading) {
      return const ColoredBox(
        color: AppColors.gray100,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    if (!_controller.locked) return widget.child;
    return _LockScreen(
      controller: _pinController,
      error: _controller.error,
      biometricReady: _controller.settings.biometricReady,
      authenticatingBiometric: _controller.authenticatingBiometric,
      onUnlock: _unlock,
      onBiometric: _controller.authenticateBiometric,
    );
  }

  Future<void> _unlock() async {
    await _controller.unlockWithPin(_pinController.text);
    if (!_controller.locked) _pinController.clear();
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({
    required this.controller,
    required this.error,
    required this.biometricReady,
    required this.authenticatingBiometric,
    required this.onUnlock,
    required this.onBiometric,
  });

  final TextEditingController controller;
  final String? error;
  final bool biometricReady;
  final bool authenticatingBiometric;
  final Future<void> Function() onUnlock;
  final Future<void> Function() onBiometric;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.gray100,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 360),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock, size: 42, color: AppColors.gray800),
                  const SizedBox(height: 18),
                  const Text(
                    'Feloldas',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: AppColors.gray800,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    key: const ValueKey('lock-pin-input'),
                    controller: controller,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(6),
                    ],
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (error != null) ...[
                    const SizedBox(height: 10),
                    Text(error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 14),
                  FilledButton(
                    key: const ValueKey('lock-unlock-button'),
                    onPressed: onUnlock,
                    child: const Text('Belepes'),
                  ),
                  if (biometricReady) ...[
                    const SizedBox(height: 8),
                    OutlinedButton.icon(
                      key: const ValueKey('lock-biometric-button'),
                      onPressed: authenticatingBiometric ? null : onBiometric,
                      icon: const Icon(Icons.fingerprint),
                      label: const Text('Biometria'),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
```

- [ ] **Step 5: Wrap app with SecurityGate**

In `lib/exptv2_app.dart`, add import:

```dart
import 'features/security/security_gate.dart';
```

Change `home`:

```dart
home: SecurityGate(
  nativeBridge: nativeBridge,
  child: ExptShell(store: store, nativeBridge: nativeBridge),
),
```

- [ ] **Step 6: Run lock and widget tests**

Run:

```bash
flutter test test/security/security_gate_test.dart test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit Task 6**

Run:

```bash
git add lib/features/security/security_controller.dart lib/features/security/security_gate.dart lib/exptv2_app.dart test/security/security_gate_test.dart test/widget_test.dart
git commit -m "feat: require auth on app entry"
```

## Task 7: Full Verification and Push

**Files:**
- Modify only files needed to fix issues from verification.

- [ ] **Step 1: Run Dart analyzer**

Run:

```bash
flutter analyze
```

Expected: no new issues.

- [ ] **Step 2: Run focused Flutter tests**

Run:

```bash
flutter test test/settings/security_settings_test.dart test/settings/settings_bridge_test.dart test/settings/settings_store_test.dart test/settings/settings_page_test.dart test/security/security_gate_test.dart test/widget_test.dart
```

Expected: PASS.

- [ ] **Step 3: Run Android unit tests**

Run:

```bash
./gradlew -p android app:testDebugUnitTest
```

Expected: PASS or report exact pre-existing unrelated failures with evidence.

- [ ] **Step 4: Inspect git status**

Run:

```bash
git status --short --branch
git log --oneline --decorate -8
```

Expected: branch is `feature/pin-biometric-login`, worktree clean after final commit, commit stack includes spec plus feature commits.

- [ ] **Step 5: Push branch**

Run:

```bash
git push -u origin feature/pin-biometric-login
```

Expected: branch is pushed to the user's GitHub remote.

## Self-Review

Spec coverage:

- PIN set/change/remove: Task 2, Task 3, Task 5.
- Biometric enable/disable: Task 1, Task 2, Task 4, Task 5.
- Cold entry lock: Task 6.
- Background/resume lock: Task 6.
- No foreground inactivity timer: Task 6 test `does not lock during ordinary foreground pumping`.
- PIN fallback when biometric enabled: Task 6 biometric failure test.
- No raw PIN persistence: Task 3 salted hash implementation.
- Existing MethodChannel architecture: all tasks keep the existing bridge pattern.

Open-item scan:

- The plan contains no open stand-in text, deferred implementation, or
  undefined detail steps.

Type consistency:

- Dart model name is consistently `SecuritySettings`.
- Native method names match `NativeBridge`, `SettingsRepository`, and `ExpenseMethodChannel`.
- Settings store method names match the panel callback names.
