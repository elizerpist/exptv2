# PIN and Biometric Authentication Design

Date: 2026-06-07
Project: `exptv2`

## Context

The Settings page currently shows `PIN kod beallitasa` and
`Biometrikus azonositas` as placeholder rows in the `Adatvedelem es biztonsag`
section. They do not open a real screen, persist state, or gate app entry.

`exptv2` already stores user settings through a Flutter `NativeBridge`, a
Kotlin `ExpenseMethodChannel`, and `ExpenseSettingsStore` backed by Android
`SharedPreferences`. The app shell is Flutter-first, while Android-specific
features are exposed through MethodChannel calls. The authentication feature
should follow this pattern instead of adding a Flutter auth plugin.

## Goals

1. Let the user set, change, and remove an app PIN from Settings.
2. Let the user enable or disable biometric sign-in from Settings.
3. Require authentication on every cold app entry when auth is configured.
4. Require authentication after the app is backgrounded and later resumed,
   including switching to another app or Android Home.
5. Avoid timed lockouts while the user is actively using the foreground app.
6. Keep PIN fallback available when biometric sign-in is enabled.
7. Store PIN data without persisting the raw PIN.
8. Keep behavior testable with Flutter widget and store tests.

## Non-Goals

- No inactivity timer inside the foreground app.
- No remote account login, reset email, or cloud recovery.
- No encrypted database migration.
- No hardware-backed secret storage in this iteration.
- No iOS implementation; this project targets the existing Android app path.
- No visual browser or Excalidraw companion for this design.

## Recommended Approach

Use the existing MethodChannel architecture:

- Flutter renders the PIN setup, PIN entry, biometric settings, and lock gate.
- Kotlin persists auth settings in `ExpenseSettingsStore`.
- Kotlin verifies PIN hashes and triggers AndroidX Biometric authentication.
- Flutter listens to app lifecycle changes and locks on cold start and resume
  after backgrounding.

AndroidX Biometric stable `androidx.biometric:biometric:1.1.0` is the target
dependency. It supports `BiometricPrompt` compatibility back to API 23, which
matches this app's current `minSdk`.

## Auth Settings Model

Flutter model: `SecuritySettings`

Fields:

- `pinEnabled`: true when a PIN hash exists.
- `biometricEnabled`: true when biometric sign-in is enabled by the user.
- `biometricAvailable`: true when Android reports an available authenticator.
- `biometricLabel`: short user-facing availability/status label.

Native stored values:

- `securityPinHash`: salted SHA-256 hash of the PIN.
- `securityPinSalt`: per-device random salt for the current PIN.
- `securityBiometricEnabled`: boolean.

The raw PIN is never sent back to Flutter from native storage and is never
persisted. PIN verification is done through MethodChannel by sending the typed
PIN to native code for comparison.

Biometric enablement depends on a configured PIN. If the PIN is removed,
biometric sign-in is removed too.

## Native Methods

Add these calls to `NativeBridge` and `ExpenseMethodChannel`:

- `expenseLoadSettings`: include `securitySettings`.
- `expenseSetSecurityPin`: accepts `pin`, stores salt/hash, returns settings.
- `expenseChangeSecurityPin`: accepts `currentPin` and `newPin`.
- `expenseClearSecurityPin`: accepts `currentPin`, clears PIN and biometric.
- `expenseVerifySecurityPin`: accepts `pin`, returns `true` or `false`.
- `expenseSetBiometricEnabled`: accepts `enabled`; enabling first verifies that
  a PIN exists and biometric auth is available.
- `expenseGetBiometricAvailability`: returns native availability metadata.
- `expenseAuthenticateBiometric`: opens the Android biometric/device credential
  prompt and returns success or failure.

Validation errors should use MethodChannel error codes that Flutter can map to
short Hungarian UI messages:

- `PIN_REQUIRED`
- `PIN_INVALID`
- `PIN_NOT_CONFIGURED`
- `BIOMETRIC_UNAVAILABLE`
- `BIOMETRIC_AUTH_FAILED`

## Settings UI

The root Settings section keeps the existing two rows, but they become active:

- `PIN kod beallitasa`: opens a PIN management submenu.
- `Biometrikus azonositas`: opens a biometric submenu.

PIN submenu states:

- No PIN: show new PIN and confirmation inputs, then enable.
- PIN exists: show status, change PIN flow, and remove PIN action.
- Change/removal requires the current PIN.
- PIN length accepts 4 to 6 numeric digits.
- Mismatched confirmation and invalid current PIN show inline errors.

Biometric submenu states:

- No PIN: explain that PIN must be configured first and offer navigation to PIN.
- PIN exists, biometric unavailable: show unavailable status and keep toggle off.
- PIN exists, biometric available: allow enabling after successful native
  biometric prompt.
- Enabled: allow disabling without a biometric prompt, while keeping PIN active.

## Entry Lock Flow

`Exptv2App` owns a security gate around `ExptShell`.

Startup:

1. Load security settings.
2. If neither PIN nor biometric is enabled, show the app normally.
3. If auth is enabled, show a full-screen lock gate before app content can be
   used.
4. If biometric is enabled and available, trigger biometric authentication.
5. If biometric succeeds, unlock.
6. If biometric fails, is cancelled, or is unavailable, keep the PIN entry
   fallback visible.

Resume from background:

1. Track lifecycle with `WidgetsBindingObserver`.
2. Mark the app as requiring auth when it enters `paused`, `inactive`, or
   `detached` after being foregrounded.
3. On `resumed`, reload security settings and lock if auth is configured.
4. Do not use a foreground inactivity timer.

The lock gate remains in Flutter so tests can assert the visible UI without
needing an Android biometric runtime.

## Error Handling

- Wrong PIN keeps the lock gate open and clears the typed PIN.
- MethodChannel failures keep the app locked when auth is configured.
- If biometric is enabled but Android reports it unavailable on a later run,
  the app falls back to PIN.
- Removing PIN also disables biometric sign-in.
- Settings changes notify the app-level auth controller so lock behavior updates
  without a restart.

## Testing Plan

Flutter tests:

- `SecuritySettings` parses defaults and native payloads.
- `NativeBridge` sends and parses security MethodChannel calls.
- `SettingsStore` loads and updates security settings.
- `SettingsPage` opens PIN and biometric submenus and updates state.
- Lock gate appears on startup when auth is enabled.
- Lock gate appears after simulated lifecycle background/resume.
- No lock appears during ordinary foreground pumping without lifecycle changes.
- Biometric failure falls back to PIN.

Android unit tests:

- PIN hashing creates different hashes for different salts.
- Correct PIN verifies; wrong PIN fails.
- Clearing PIN clears biometric enablement.
- Biometric cannot be enabled without PIN.

Manual Android verification:

- Set PIN, close app, reopen, unlock with PIN.
- Background to Android Home, return, unlock again.
- Switch to another app, return, unlock again.
- Enable biometric, relaunch, unlock via biometric.
- Cancel biometric prompt, unlock with PIN fallback.
- Remove PIN, relaunch, confirm no lock gate appears.
