# Ghost Logbox And Surface Controls Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build monthly pinned/stable ghost transaction rows and replace the global neumorphism profile with component-level button, logbox, and ghost-logbox controls.

**Architecture:** Keep recurring ghost data in `TransactionStore`, but change display-row construction so monthly ghost rows render as a top block without date headers. Keep the existing surface rendering engine, but map explicit component choices to the correct `ExpenseSurfaceInteraction` values: buttons use `raisedInset`, logboxes and ghost logboxes use `insetInset`. Add a focused `GhostLogboxSettings` model and pass it through the theme, settings bridge, Android settings store, and `RecurringGhostLogBox`.

**Tech Stack:** Flutter/Dart, Kotlin Android MethodChannel settings store, Flutter widget/unit tests, Android unit tests via Gradle/GitHub Actions.

---

## File Structure

- `lib/features/settings/models/app_theme_settings.dart`
  - Add `GhostLogboxSettings`, `GhostLogboxBorderStyle`, and `GhostLogboxTextTone`.
  - Remove `designProfile` as a user-facing stored field from new `toMap()` output.
  - Keep `designProfile` only as `fromMap()` legacy migration input.
  - Add `ghostLogboxSurfaceStyle` with legacy fallback.

- `lib/features/settings/theme/expense_theme.dart`
  - Stop deriving component surfaces from one global profile.
  - Resolve button, content/logbox, bottom nav, and ghost logbox styles from explicit settings.

- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
  - Persist `ghostLogboxSurfaceStyle` and nested ghost logbox visual settings.
  - Keep `designProfile` read support only for old installs.

- `lib/features/settings/widgets/options/theme_options_panel.dart`
  - Remove the global `Design profil` section.
  - Add component surface choices: buttons and logboxes.

- `lib/features/settings/widgets/options/ghost_logbox_options_panel.dart`
  - New submenu panel for ghost-only visual controls.

- `lib/features/settings/settings_page.dart`
  - Add `Ghost logbox` as a theme/settings submenu entry.

- `lib/features/transactions/state/transaction_store.dart`
  - Make monthly ghost rows top-pinned.
  - Stop yearly/all-time ghost rows.
  - Preserve visible ghost rows during projection/reload gaps.

- `lib/features/transactions/widgets/transaction_log_list.dart`
  - Pass ghost surface/settings into `RecurringGhostLogBox`.

- `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
  - Render dashed/normal border, opacity controls, gray tone controls, expected label, and avatar badge.

- `lib/features/transactions/widgets/ghost_logbox_visuals.dart`
  - New focused visual helpers: dashed rounded border painter and ghost badge painter.

- Tests:
  - `test/settings/expense_theme_test.dart`
  - `test/settings/settings_bridge_test.dart`
  - `test/settings/settings_page_test.dart`
  - `test/transactions/recurring_ghost_log_test.dart`
  - `test/transactions/recurring_ghost_log_box_test.dart`

---

### Task 1: Theme Model And Migration

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Test: `test/settings/expense_theme_test.dart`
- Test: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Write failing model tests for component-level surfaces**

Add/replace tests in `test/settings/expense_theme_test.dart`:

```dart
test('theme settings default to explicit normal component surfaces', () {
  final settings = AppThemeSettings.defaults();

  expect(settings.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
  expect(settings.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
  expect(
    settings.ghostLogboxSurfaceStyle,
    ExpenseSurfaceInteraction.neutralNeutral,
  );
  expect(settings.toMap().containsKey('designProfile'), isFalse);
  expect(settings.toMap()['ghostLogboxSurfaceStyle'], 'neutralNeutral');
  expect(settings.ghostLogboxSettings.borderStyle, GhostLogboxBorderStyle.dashed);
  expect(settings.ghostLogboxSettings.avatarBadgeEnabled, isTrue);
  expect(settings.ghostLogboxSettings.expectedLabelEnabled, isTrue);
});

test('legacy neumorphism profile migrates to component surfaces', () {
  final settings = AppThemeSettings.fromMap(const <String, Object?>{
    'designProfile': 'neumorphism',
  });

  expect(settings.buttonSurfaceStyle, ExpenseSurfaceInteraction.raisedInset);
  expect(settings.contentSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
  expect(settings.ghostLogboxSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
});

test('explicit component surfaces override legacy design profile', () {
  final settings = AppThemeSettings.fromMap(const <String, Object?>{
    'designProfile': 'neumorphism',
    'buttonSurfaceStyle': 'neutralNeutral',
    'contentSurfaceStyle': 'neutralNeutral',
    'ghostLogboxSurfaceStyle': 'neutralNeutral',
  });

  expect(settings.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
  expect(settings.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
  expect(settings.ghostLogboxSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
});

test('ghost logbox settings parse and serialize visual controls', () {
  final settings = AppThemeSettings.fromMap(const <String, Object?>{
    'ghostLogboxSettings': <String, Object?>{
      'borderStyle': 'normal',
      'backgroundOpacityEnabled': false,
      'avatarOpacityEnabled': true,
      'textOpacityEnabled': true,
      'avatarBadgeEnabled': false,
      'textTone': 'gray',
      'expectedLabelEnabled': false,
    },
  });

  expect(settings.ghostLogboxSettings.borderStyle, GhostLogboxBorderStyle.normal);
  expect(settings.ghostLogboxSettings.backgroundOpacityEnabled, isFalse);
  expect(settings.ghostLogboxSettings.avatarOpacityEnabled, isTrue);
  expect(settings.ghostLogboxSettings.textOpacityEnabled, isTrue);
  expect(settings.ghostLogboxSettings.avatarBadgeEnabled, isFalse);
  expect(settings.ghostLogboxSettings.textTone, GhostLogboxTextTone.gray);
  expect(settings.ghostLogboxSettings.expectedLabelEnabled, isFalse);
  expect(
    settings.ghostLogboxSettings.toMap(),
    containsPair('textTone', 'gray'),
  );
});
```

Update existing tests that still assert `settings.designProfile` or `toMap()['designProfile']`. New expected behavior: `designProfile` is accepted in `fromMap()` but not exposed from `AppThemeSettings` as a current setting.

- [ ] **Step 2: Run tests to verify they fail**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart
```

Expected locally in Termux may be `flutter: not found`; if running in CI/dev machine, expected failures are missing `ghostLogboxSurfaceStyle`, `GhostLogboxSettings`, and old `designProfile` assertions.

- [ ] **Step 3: Implement settings model enums and value class**

In `lib/features/settings/models/app_theme_settings.dart`, add after `AppBoxColor`:

```dart
enum GhostLogboxBorderStyle {
  normal('normal'),
  dashed('dashed');

  const GhostLogboxBorderStyle(this.nativeValue);
  final String nativeValue;

  static GhostLogboxBorderStyle fromAny(Object? value) {
    final raw = value?.toString();
    return GhostLogboxBorderStyle.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => GhostLogboxBorderStyle.dashed,
    );
  }
}

enum GhostLogboxTextTone {
  normal('normal'),
  gray('gray');

  const GhostLogboxTextTone(this.nativeValue);
  final String nativeValue;

  static GhostLogboxTextTone fromAny(Object? value) {
    final raw = value?.toString();
    return GhostLogboxTextTone.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => GhostLogboxTextTone.normal,
    );
  }
}

class GhostLogboxSettings {
  const GhostLogboxSettings({
    required this.borderStyle,
    required this.backgroundOpacityEnabled,
    required this.avatarOpacityEnabled,
    required this.textOpacityEnabled,
    required this.avatarBadgeEnabled,
    required this.textTone,
    required this.expectedLabelEnabled,
  });

  factory GhostLogboxSettings.defaults() {
    return const GhostLogboxSettings(
      borderStyle: GhostLogboxBorderStyle.dashed,
      backgroundOpacityEnabled: true,
      avatarOpacityEnabled: false,
      textOpacityEnabled: false,
      avatarBadgeEnabled: true,
      textTone: GhostLogboxTextTone.normal,
      expectedLabelEnabled: true,
    );
  }

  factory GhostLogboxSettings.fromMap(Map<dynamic, dynamic>? map) {
    final payload = map ?? const <dynamic, dynamic>{};
    final defaults = GhostLogboxSettings.defaults();
    return GhostLogboxSettings(
      borderStyle: GhostLogboxBorderStyle.fromAny(payload['borderStyle']),
      backgroundOpacityEnabled: _bool(
        payload['backgroundOpacityEnabled'],
        defaults.backgroundOpacityEnabled,
      ),
      avatarOpacityEnabled: _bool(
        payload['avatarOpacityEnabled'],
        defaults.avatarOpacityEnabled,
      ),
      textOpacityEnabled: _bool(
        payload['textOpacityEnabled'],
        defaults.textOpacityEnabled,
      ),
      avatarBadgeEnabled: _bool(
        payload['avatarBadgeEnabled'],
        defaults.avatarBadgeEnabled,
      ),
      textTone: GhostLogboxTextTone.fromAny(payload['textTone']),
      expectedLabelEnabled: _bool(
        payload['expectedLabelEnabled'],
        defaults.expectedLabelEnabled,
      ),
    );
  }

  final GhostLogboxBorderStyle borderStyle;
  final bool backgroundOpacityEnabled;
  final bool avatarOpacityEnabled;
  final bool textOpacityEnabled;
  final bool avatarBadgeEnabled;
  final GhostLogboxTextTone textTone;
  final bool expectedLabelEnabled;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'borderStyle': borderStyle.nativeValue,
      'backgroundOpacityEnabled': backgroundOpacityEnabled,
      'avatarOpacityEnabled': avatarOpacityEnabled,
      'textOpacityEnabled': textOpacityEnabled,
      'avatarBadgeEnabled': avatarBadgeEnabled,
      'textTone': textTone.nativeValue,
      'expectedLabelEnabled': expectedLabelEnabled,
    };
  }

  GhostLogboxSettings copyWith({
    GhostLogboxBorderStyle? borderStyle,
    bool? backgroundOpacityEnabled,
    bool? avatarOpacityEnabled,
    bool? textOpacityEnabled,
    bool? avatarBadgeEnabled,
    GhostLogboxTextTone? textTone,
    bool? expectedLabelEnabled,
  }) {
    return GhostLogboxSettings(
      borderStyle: borderStyle ?? this.borderStyle,
      backgroundOpacityEnabled:
          backgroundOpacityEnabled ?? this.backgroundOpacityEnabled,
      avatarOpacityEnabled: avatarOpacityEnabled ?? this.avatarOpacityEnabled,
      textOpacityEnabled: textOpacityEnabled ?? this.textOpacityEnabled,
      avatarBadgeEnabled: avatarBadgeEnabled ?? this.avatarBadgeEnabled,
      textTone: textTone ?? this.textTone,
      expectedLabelEnabled: expectedLabelEnabled ?? this.expectedLabelEnabled,
    );
  }

  static bool _bool(Object? value, bool fallback) {
    if (value is bool) return value;
    if (value is num) return value.toInt() != 0;
    if (value is String) {
      return value == '1' || value.toLowerCase() == 'true';
    }
    return fallback;
  }
}
```

- [ ] **Step 4: Update `AppThemeSettings` fields and parsing**

In `AppThemeSettings`, remove `designProfile` from the constructor, `defaults()`, field list, `toMap()`, and `copyWith()`. Add:

```dart
required this.ghostLogboxSurfaceStyle,
required this.ghostLogboxSettings,
```

Add fields:

```dart
final ExpenseSurfaceInteraction ghostLogboxSurfaceStyle;
final GhostLogboxSettings ghostLogboxSettings;
```

In `defaults()`, set:

```dart
ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
ghostLogboxSettings: GhostLogboxSettings.defaults(),
```

In `fromMap()`, use helpers:

```dart
final legacyProfile = AppDesignProfile.fromAny(map['designProfile']);
return AppThemeSettings(
  magnetType: MagnetType.fromAny(map['magnetType']),
  cardColor: AppCardColor.fromAny(map['cardColor']),
  theme: AppTheme.fromAny(map['theme']),
  backgroundColor: AppBackgroundColor.fromAny(map['backgroundColor']),
  boxColor: AppBoxColor.fromAny(map['boxColor']),
  buttonSurfaceStyle: _surfaceFromMap(
    map,
    'buttonSurfaceStyle',
    legacyProfile == AppDesignProfile.neumorphism
        ? ExpenseSurfaceInteraction.raisedInset
        : ExpenseSurfaceInteraction.neutralNeutral,
  ),
  contentSurfaceStyle: _surfaceFromMap(
    map,
    'contentSurfaceStyle',
    legacyProfile == AppDesignProfile.neumorphism
        ? ExpenseSurfaceInteraction.insetInset
        : ExpenseSurfaceInteraction.neutralNeutral,
  ),
  ghostLogboxSurfaceStyle: _surfaceFromMap(
    map,
    'ghostLogboxSurfaceStyle',
    legacyProfile == AppDesignProfile.neumorphism
        ? ExpenseSurfaceInteraction.insetInset
        : ExpenseSurfaceInteraction.neutralNeutral,
  ),
  ghostLogboxSettings: GhostLogboxSettings.fromMap(
    map['ghostLogboxSettings'] is Map
        ? Map<dynamic, dynamic>.from(map['ghostLogboxSettings'] as Map)
        : null,
  ),
  backheaderStyle: BackheaderStyle.fromAny(map['backheaderStyle']),
  appColor: _appColorFromMap(map),
);
```

Add helper:

```dart
static ExpenseSurfaceInteraction _surfaceFromMap(
  Map<dynamic, dynamic> map,
  String key,
  ExpenseSurfaceInteraction fallback,
) {
  if (!_hasValue(map[key])) return fallback;
  return ExpenseSurfaceInteraction.fromAny(map[key]);
}
```

`toMap()` must include:

```dart
'ghostLogboxSurfaceStyle': ghostLogboxSurfaceStyle.nativeValue,
'ghostLogboxSettings': ghostLogboxSettings.toMap(),
```

and must not include `designProfile`.

- [ ] **Step 5: Run tests to verify model passes**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart
```

Expected: all tests in those files pass on a machine with Flutter.

- [ ] **Step 6: Commit**

```bash
git add lib/features/settings/models/app_theme_settings.dart test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart
git commit -m "Split theme surfaces by component"
```

---

### Task 2: ExpenseTheme Mapping

**Files:**
- Modify: `lib/features/settings/theme/expense_theme.dart`
- Test: `test/settings/expense_theme_test.dart`

- [ ] **Step 1: Write failing theme mapping test**

In `test/settings/expense_theme_test.dart`, replace the existing `profile resolves component surface roles` test with:

```dart
test('component surfaces resolve independently', () {
  final theme = ExpenseTheme.fromSettings(
    AppThemeSettings.defaults().copyWith(
      buttonSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
      contentSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
      ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
    ),
  );

  expect(theme.buttonSurfaceStyle, ExpenseSurfaceInteraction.raisedInset);
  expect(theme.contentSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
  expect(theme.ghostLogboxSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
  expect(theme.bottomNavSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
});
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/settings/expense_theme_test.dart
```

Expected: fails because `ExpenseTheme.ghostLogboxSurfaceStyle` does not exist and `ExpenseTheme` still derives surfaces from `designProfile`.

- [ ] **Step 3: Implement explicit mapping**

In `ExpenseTheme`, add constructor parameter and field:

```dart
required this.ghostLogboxSurfaceStyle,
```

```dart
final ExpenseSurfaceInteraction ghostLogboxSurfaceStyle;
```

In `fromSettings()`, remove `final neumorphism` and `_surfaceStyles(neumorphism)`. Set surface values directly:

```dart
buttonSurfaceStyle: settings.buttonSurfaceStyle,
contentSurfaceStyle: settings.contentSurfaceStyle,
bottomNavSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
forcedInsetSurfaceStyle: settings.contentSurfaceStyle ==
        ExpenseSurfaceInteraction.neutralNeutral
    ? ExpenseSurfaceInteraction.neutralNeutral
    : ExpenseSurfaceInteraction.insetInset,
ghostLogboxSurfaceStyle: settings.ghostLogboxSurfaceStyle,
```

Remove `isNeumorphism`, `_surfaceStyles`, and `_SurfaceStyles` if no longer used.

- [ ] **Step 4: Run test to verify it passes**

Run:

```bash
flutter test test/settings/expense_theme_test.dart
```

Expected: pass.

- [ ] **Step 5: Commit**

```bash
git add lib/features/settings/theme/expense_theme.dart test/settings/expense_theme_test.dart
git commit -m "Resolve theme surfaces independently"
```

---

### Task 3: Native Settings Persistence

**Files:**
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Test: `test/settings/settings_bridge_test.dart`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`

- [ ] **Step 1: Write failing bridge serialization test**

In `test/settings/settings_bridge_test.dart`, extend `expenseLoadSettings` mock `themeSettings` payload with:

```dart
'buttonSurfaceStyle': 'raisedInset',
'contentSurfaceStyle': 'insetInset',
'ghostLogboxSurfaceStyle': 'insetInset',
'ghostLogboxSettings': <String, Object?>{
  'borderStyle': 'dashed',
  'backgroundOpacityEnabled': true,
  'avatarOpacityEnabled': false,
  'textOpacityEnabled': false,
  'avatarBadgeEnabled': true,
  'textTone': 'normal',
  'expectedLabelEnabled': true,
},
```

Add assertions in `loads app theme and FastInfo settings`:

```dart
expect(settings.themeSettings.buttonSurfaceStyle, ExpenseSurfaceInteraction.raisedInset);
expect(settings.themeSettings.contentSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
expect(settings.themeSettings.ghostLogboxSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
expect(settings.themeSettings.ghostLogboxSettings.borderStyle, GhostLogboxBorderStyle.dashed);
```

In `updates theme settings through native bridge`, update the saved settings to include a ghost setting change:

```dart
final updated = await bridge.expenseUpdateThemeSettings(
  AppThemeSettings.defaults().copyWith(
    ghostLogboxSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
    ghostLogboxSettings: GhostLogboxSettings.defaults().copyWith(
      textTone: GhostLogboxTextTone.gray,
      expectedLabelEnabled: false,
    ),
  ),
);

expect(updated.ghostLogboxSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
expect(updated.ghostLogboxSettings.textTone, GhostLogboxTextTone.gray);
expect(updated.ghostLogboxSettings.expectedLabelEnabled, isFalse);
final payload = calls.last.arguments as Map<dynamic, dynamic>;
expect(payload['ghostLogboxSurfaceStyle'], 'insetInset');
expect(
  (payload['ghostLogboxSettings'] as Map<dynamic, dynamic>)['textTone'],
  'gray',
);
```

Add this Android unit test to `ExpenseSettingsStoreSecurityTest`:

```kotlin
@Test
fun themeSettingsPersistGhostLogboxControls() {
    val updated = store.updateThemeSettings(
        mapOf(
            "buttonSurfaceStyle" to "raisedInset",
            "contentSurfaceStyle" to "insetInset",
            "ghostLogboxSurfaceStyle" to "insetInset",
            "ghostLogboxSettings" to mapOf(
                "borderStyle" to "normal",
                "backgroundOpacityEnabled" to false,
                "avatarOpacityEnabled" to true,
                "textOpacityEnabled" to true,
                "avatarBadgeEnabled" to false,
                "textTone" to "gray",
                "expectedLabelEnabled" to false,
            ),
        )
    )

    val nested = updated["ghostLogboxSettings"] as Map<*, *>
    assertEquals("insetInset", updated["ghostLogboxSurfaceStyle"])
    assertEquals("normal", nested["borderStyle"])
    assertEquals(false, nested["backgroundOpacityEnabled"])
    assertEquals(true, nested["avatarOpacityEnabled"])
    assertEquals(true, nested["textOpacityEnabled"])
    assertEquals(false, nested["avatarBadgeEnabled"])
    assertEquals("gray", nested["textTone"])
    assertEquals(false, nested["expectedLabelEnabled"])

    val loaded = store.loadThemeSettings()
    val loadedNested = loaded["ghostLogboxSettings"] as Map<*, *>
    assertEquals("insetInset", loaded["ghostLogboxSurfaceStyle"])
    assertEquals("gray", loadedNested["textTone"])
    assertEquals(false, loadedNested["expectedLabelEnabled"])
}
```

- [ ] **Step 2: Run bridge test to verify it fails**

Run:

```bash
flutter test test/settings/settings_bridge_test.dart
```

Expected: fail until new model fields are implemented and payload parsing works.

- [ ] **Step 3: Implement Android settings keys and payload**

In `ExpenseSettingsStore.kt`, add keys:

```kotlin
private const val KEY_GHOST_LOGBOX_SURFACE_STYLE = "ghostLogboxSurfaceStyle"
private const val KEY_GHOST_LOGBOX_BORDER_STYLE = "ghostLogboxBorderStyle"
private const val KEY_GHOST_LOGBOX_BACKGROUND_OPACITY = "ghostLogboxBackgroundOpacityEnabled"
private const val KEY_GHOST_LOGBOX_AVATAR_OPACITY = "ghostLogboxAvatarOpacityEnabled"
private const val KEY_GHOST_LOGBOX_TEXT_OPACITY = "ghostLogboxTextOpacityEnabled"
private const val KEY_GHOST_LOGBOX_AVATAR_BADGE = "ghostLogboxAvatarBadgeEnabled"
private const val KEY_GHOST_LOGBOX_TEXT_TONE = "ghostLogboxTextTone"
private const val KEY_GHOST_LOGBOX_EXPECTED_LABEL = "ghostLogboxExpectedLabelEnabled"
```

In `loadThemeSettings()`, add:

```kotlin
"ghostLogboxSurfaceStyle" to prefs.getString(
    KEY_GHOST_LOGBOX_SURFACE_STYLE,
    legacyGhostLogboxSurfaceStyle(),
),
"ghostLogboxSettings" to loadGhostLogboxSettings(),
```

Add helper functions:

```kotlin
private fun loadGhostLogboxSettings(): Map<String, Any?> = mapOf(
    "borderStyle" to prefs.getString(KEY_GHOST_LOGBOX_BORDER_STYLE, "dashed"),
    "backgroundOpacityEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_BACKGROUND_OPACITY, true),
    "avatarOpacityEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_AVATAR_OPACITY, false),
    "textOpacityEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_TEXT_OPACITY, false),
    "avatarBadgeEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_AVATAR_BADGE, true),
    "textTone" to prefs.getString(KEY_GHOST_LOGBOX_TEXT_TONE, "normal"),
    "expectedLabelEnabled" to prefs.getBoolean(KEY_GHOST_LOGBOX_EXPECTED_LABEL, true),
)

private fun legacyGhostLogboxSurfaceStyle(): String {
    return if (legacyDesignProfile() == "neumorphism") "insetInset" else "neutralNeutral"
}
```

In `updateThemeSettings(args)`, read nested settings:

```kotlin
val ghostSurfaceStyle = args["ghostLogboxSurfaceStyle"]?.toString() ?: legacyGhostLogboxSurfaceStyle()
val ghostSettings = (args["ghostLogboxSettings"] as? Map<*, *>) ?: emptyMap<Any, Any>()
```

Add to editor chain:

```kotlin
.putString(KEY_GHOST_LOGBOX_SURFACE_STYLE, ghostSurfaceStyle)
.putString(KEY_GHOST_LOGBOX_BORDER_STYLE, ghostSettings["borderStyle"]?.toString() ?: "dashed")
.putBoolean(KEY_GHOST_LOGBOX_BACKGROUND_OPACITY, boolArg(ghostSettings["backgroundOpacityEnabled"], true))
.putBoolean(KEY_GHOST_LOGBOX_AVATAR_OPACITY, boolArg(ghostSettings["avatarOpacityEnabled"], false))
.putBoolean(KEY_GHOST_LOGBOX_TEXT_OPACITY, boolArg(ghostSettings["textOpacityEnabled"], false))
.putBoolean(KEY_GHOST_LOGBOX_AVATAR_BADGE, boolArg(ghostSettings["avatarBadgeEnabled"], true))
.putString(KEY_GHOST_LOGBOX_TEXT_TONE, ghostSettings["textTone"]?.toString() ?: "normal")
.putBoolean(KEY_GHOST_LOGBOX_EXPECTED_LABEL, boolArg(ghostSettings["expectedLabelEnabled"], true))
```

Keep `KEY_DESIGN_PROFILE` for legacy reads, but do not depend on it for new UI decisions.

- [ ] **Step 4: Run tests**

Run:

```bash
flutter test test/settings/settings_bridge_test.dart
cd android && ./gradlew testDebugUnitTest --no-daemon
```

Expected: Dart bridge test passes; Android tests pass on a machine with Java/Gradle.

- [ ] **Step 5: Commit**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt test/settings/settings_bridge_test.dart
git commit -m "Persist ghost logbox theme settings"
```

---

### Task 4: Settings UI For Component Surfaces And Ghost Logbox

**Files:**
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Create: `lib/features/settings/widgets/options/ghost_logbox_options_panel.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Test: `test/settings/settings_page_test.dart`
- Test: new `test/settings/ghost_logbox_options_panel_test.dart`

- [ ] **Step 1: Write failing settings page test**

In `test/settings/settings_page_test.dart`, add:

```dart
testWidgets('theme settings exposes component surface and ghost logbox menus', (tester) async {
  await tester.pumpWidget(buildSubject());
  await tester.pumpAndSettle();

  expect(find.text('Téma'), findsOneWidget);
  expect(find.text('Ghost logbox'), findsOneWidget);

  await tester.tap(find.text('Téma'));
  await tester.pumpAndSettle();

  expect(find.text('Gombok felülete'), findsOneWidget);
  expect(find.text('Logboxok felülete'), findsOneWidget);
  expect(find.text('Design profil'), findsNothing);

  await tester.tap(find.byKey(const ValueKey('settings-submenu-back')));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Ghost logbox'));
  await tester.pumpAndSettle();

  expect(find.text('Szegély'), findsOneWidget);
  expect(find.text('Szaggatott'), findsOneWidget);
  expect(find.text('Várható felirat'), findsOneWidget);
});
```


- [ ] **Step 2: Write focused ghost panel test**

Create `test/settings/ghost_logbox_options_panel_test.dart`:

```dart
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/widgets/options/ghost_logbox_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ghost logbox panel updates visual settings independently', (tester) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: GhostLogboxOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: (settings) => updated = settings,
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('ghost-logbox-border-normal')));
    await tester.pumpAndSettle();

    expect(updated?.ghostLogboxSettings.borderStyle, GhostLogboxBorderStyle.normal);

    await tester.tap(find.byKey(const ValueKey('ghost-logbox-text-gray')));
    await tester.pumpAndSettle();

    expect(updated?.ghostLogboxSettings.textTone, GhostLogboxTextTone.gray);
  });
}
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/settings/settings_page_test.dart test/settings/ghost_logbox_options_panel_test.dart
```

Expected: fail because `GhostLogboxOptionsPanel` and menu entry do not exist.

- [ ] **Step 4: Update `ThemeOptionsPanel`**

Remove the `_sectionTitle` call whose title is `Design profil`, remove the `_profileOption` method, remove the `_withDesignProfile` method, and remove any preview that only served the global profile.

Add two sections:

```dart
_sectionTitle('Gombok felülete', 'A gombok és ikon gombok nyomási stílusa:'),
_surfaceOption(
  key: const ValueKey('theme-button-surface-normal'),
  title: 'Normál',
  selected: settings.buttonSurfaceStyle == ExpenseSurfaceInteraction.neutralNeutral,
  onTap: () => onChanged(
    settings.copyWith(buttonSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral),
  ),
),
_surfaceOption(
  key: const ValueKey('theme-button-surface-neumorph'),
  title: 'Neumorph',
  selected: settings.buttonSurfaceStyle == ExpenseSurfaceInteraction.raisedInset,
  onTap: () => onChanged(
    settings.copyWith(buttonSurfaceStyle: ExpenseSurfaceInteraction.raisedInset),
  ),
),
_sectionTitle('Logboxok felülete', 'A tartalmi kártyák és tranzakció logboxok stílusa:'),
_surfaceOption(
  key: const ValueKey('theme-logbox-surface-normal'),
  title: 'Normál',
  selected: settings.contentSurfaceStyle == ExpenseSurfaceInteraction.neutralNeutral,
  onTap: () => onChanged(
    settings.copyWith(contentSurfaceStyle: ExpenseSurfaceInteraction.neutralNeutral),
  ),
),
_surfaceOption(
  key: const ValueKey('theme-logbox-surface-neumorph'),
  title: 'Neumorph',
  selected: settings.contentSurfaceStyle == ExpenseSurfaceInteraction.insetInset,
  onTap: () => onChanged(
    settings.copyWith(contentSurfaceStyle: ExpenseSurfaceInteraction.insetInset),
  ),
),
```

Add helper:

```dart
Widget _surfaceOption({
  required ValueKey<String> key,
  required String title,
  required bool selected,
  required VoidCallback onTap,
}) {
  return SettingsRadioOption(
    key: key,
    title: '$title${selected ? ' (jelenlegi)' : ''}',
    description: title == 'Neumorph'
        ? '3D felület a komponens saját helyes mélységével'
        : 'Eredeti sík felület',
    selected: selected,
    onTap: onTap,
    preview: _SurfacePreview(
      style: title == 'Neumorph'
          ? ExpenseSurfaceInteraction.raisedInset
          : ExpenseSurfaceInteraction.neutralNeutral,
    ),
  );
}
```

Use `raisedInset` preview for buttons and `insetInset` preview for logboxes if the helper accepts a `previewStyle` argument.

- [ ] **Step 5: Create `GhostLogboxOptionsPanel`**

Create `lib/features/settings/widgets/options/ghost_logbox_options_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_theme_settings.dart';
import 'settings_option_widgets.dart';

class GhostLogboxOptionsPanel extends StatelessWidget {
  const GhostLogboxOptionsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  GhostLogboxSettings get _ghost => settings.ghostLogboxSettings;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      key: const ValueKey('settings-ghost-logbox-scroll'),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _sectionTitle('Felület', 'A ghost logbox saját felületi stílusa:'),
            _surfaceOption('Normál', ExpenseSurfaceInteraction.neutralNeutral),
            _surfaceOption('Neumorph', ExpenseSurfaceInteraction.insetInset),
            _sectionTitle('Szegély', 'A ghost sor körvonala:'),
            _borderOption('Normál', GhostLogboxBorderStyle.normal),
            _borderOption('Szaggatott', GhostLogboxBorderStyle.dashed),
            _switchOption(
              key: const ValueKey('ghost-logbox-background-opacity'),
              title: 'Háttér halványítás',
              value: _ghost.backgroundOpacityEnabled,
              update: (value) => _copyGhost(backgroundOpacityEnabled: value),
            ),
            _switchOption(
              key: const ValueKey('ghost-logbox-avatar-opacity'),
              title: 'Avatar halványítás',
              value: _ghost.avatarOpacityEnabled,
              update: (value) => _copyGhost(avatarOpacityEnabled: value),
            ),
            _switchOption(
              key: const ValueKey('ghost-logbox-text-opacity'),
              title: 'Szöveg halványítás',
              value: _ghost.textOpacityEnabled,
              update: (value) => _copyGhost(textOpacityEnabled: value),
            ),
            _switchOption(
              key: const ValueKey('ghost-logbox-avatar-badge'),
              title: 'Ghost badge',
              value: _ghost.avatarBadgeEnabled,
              update: (value) => _copyGhost(avatarBadgeEnabled: value),
            ),
            _sectionTitle('Szöveg színe', 'A név és összeg tónusa:'),
            _textToneOption('Normál', GhostLogboxTextTone.normal),
            _textToneOption('Szürke', GhostLogboxTextTone.gray),
            _switchOption(
              key: const ValueKey('ghost-logbox-expected-label'),
              title: 'Várható felirat',
              value: _ghost.expectedLabelEnabled,
              update: (value) => _copyGhost(expectedLabelEnabled: value),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionTitle(String title, String subtitle) => Padding(
        padding: const EdgeInsets.only(top: 8, bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.gray800,
              ),
            ),
            const SizedBox(height: 4),
            Text(subtitle, style: const TextStyle(fontSize: 14, color: AppColors.gray600)),
          ],
        ),
      );

  Widget _surfaceOption(String title, ExpenseSurfaceInteraction style) {
    return SettingsRadioOption(
      key: ValueKey('ghost-logbox-surface-${style.nativeValue}'),
      title: '$title${settings.ghostLogboxSurfaceStyle == style ? ' (jelenlegi)' : ''}',
      description: style == ExpenseSurfaceInteraction.insetInset
          ? 'Befelé domborodó ghost logbox'
          : 'Normál ghost logbox felület',
      selected: settings.ghostLogboxSurfaceStyle == style,
      onTap: () => onChanged(settings.copyWith(ghostLogboxSurfaceStyle: style)),
    );
  }

  Widget _borderOption(String title, GhostLogboxBorderStyle style) {
    return SettingsRadioOption(
      key: ValueKey('ghost-logbox-border-${style.nativeValue}'),
      title: '$title${_ghost.borderStyle == style ? ' (jelenlegi)' : ''}',
      description: style == GhostLogboxBorderStyle.dashed
          ? 'Szaggatott körvonal a várható sorokhoz'
          : 'Ugyanolyan körvonal, mint a normál tranzakcióknál',
      selected: _ghost.borderStyle == style,
      onTap: () => _copyGhost(borderStyle: style),
    );
  }

  Widget _textToneOption(String title, GhostLogboxTextTone tone) {
    return SettingsRadioOption(
      key: ValueKey('ghost-logbox-text-${tone.nativeValue}'),
      title: '$title${_ghost.textTone == tone ? ' (jelenlegi)' : ''}',
      description: tone == GhostLogboxTextTone.gray
          ? 'Szürkébb név és összeg'
          : 'A normál tranzakció színeit használja',
      selected: _ghost.textTone == tone,
      onTap: () => _copyGhost(textTone: tone),
    );
  }

  Widget _switchOption({
    required ValueKey<String> key,
    required String title,
    required bool value,
    required ValueChanged<bool> update,
  }) {
    return SwitchListTile.adaptive(
      key: key,
      title: Text(title),
      value: value,
      onChanged: update,
      activeThumbColor: AppColors.primary,
      contentPadding: EdgeInsets.zero,
    );
  }

  void _copyGhost({
    GhostLogboxBorderStyle? borderStyle,
    bool? backgroundOpacityEnabled,
    bool? avatarOpacityEnabled,
    bool? textOpacityEnabled,
    bool? avatarBadgeEnabled,
    GhostLogboxTextTone? textTone,
    bool? expectedLabelEnabled,
  }) {
    onChanged(
      settings.copyWith(
        ghostLogboxSettings: _ghost.copyWith(
          borderStyle: borderStyle,
          backgroundOpacityEnabled: backgroundOpacityEnabled,
          avatarOpacityEnabled: avatarOpacityEnabled,
          textOpacityEnabled: textOpacityEnabled,
          avatarBadgeEnabled: avatarBadgeEnabled,
          textTone: textTone,
          expectedLabelEnabled: expectedLabelEnabled,
        ),
      ),
    );
  }
}
```

- [ ] **Step 6: Add SettingsPage submenu**

In `lib/features/settings/settings_page.dart`:

- Import `ghost_logbox_options_panel.dart`.
- Add `_SettingsMenu.ghostLogbox`.
- Add a root option near theme/backheader:

```dart
SettingsNavigationOption(
  title: 'Ghost logbox',
  description: 'Várható ismétlődő sorok megjelenése',
  onTap: () => _open(_SettingsMenu.ghostLogbox),
),
```

- In submenu switch, return:

```dart
_SettingsMenu.ghostLogbox => GhostLogboxOptionsPanel(
  settings: _settingsStore.themeSettings,
  onChanged: _updateThemeSettings,
),
```

- In title resolver, add:

```dart
_SettingsMenu.ghostLogbox => 'Ghost logbox',
```

- [ ] **Step 7: Run tests**

Run:

```bash
flutter test test/settings/settings_page_test.dart test/settings/ghost_logbox_options_panel_test.dart
```

Expected: pass on Flutter machine.

- [ ] **Step 8: Commit**

```bash
git add lib/features/settings/widgets/options/theme_options_panel.dart lib/features/settings/widgets/options/ghost_logbox_options_panel.dart lib/features/settings/settings_page.dart test/settings/settings_page_test.dart test/settings/ghost_logbox_options_panel_test.dart
git commit -m "Add component surface settings UI"
```

---

### Task 5: Monthly Ghost Ordering And Stability

**Files:**
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Test: `test/transactions/recurring_ghost_log_test.dart`

- [ ] **Step 1: Write failing ghost ordering test**

In `test/transactions/recurring_ghost_log_test.dart`, add:

```dart
test('monthly display pins ghosts above normal date headers', () async {
  final repository = GhostRepository(
    projectedGhosts: [ghostFixture(id: 9, month: 5)],
  );
  final store = TransactionStore(
    repository,
    clock: () => DateTime(2026, 5, 10),
  );
  await store.start();
  await store.cycleSummaryWindow();

  final entries = store.visibleDisplayLogEntries;

  expect(entries.first.isGhost, isTrue);
  expect(entries.first.ghost?.name, 'Rent');
  expect(entries[1].isHeader, isTrue);
  expect(entries[1].header, '2026.05.10');
  expect(entries[2].record?.displayMerchant, 'Real Shop');
});

test('yearly and all-time display do not include ghost rows', () async {
  final repository = GhostRepository(projectedGhosts: [ghostFixture()]);
  final store = TransactionStore(
    repository,
    clock: () => DateTime(2026, 5, 10),
  );
  await store.start();

  expect(store.summaryWindow, SummaryWindow.allTime);
  expect(store.visibleDisplayLogEntries.any((entry) => entry.isGhost), isFalse);

  await store.cycleSummaryWindow();
  expect(store.summaryWindow, SummaryWindow.monthly);
  expect(store.visibleDisplayLogEntries.any((entry) => entry.isGhost), isTrue);

  await store.cycleSummaryWindow();
  expect(store.summaryWindow, SummaryWindow.yearly);
  expect(store.visibleDisplayLogEntries.any((entry) => entry.isGhost), isFalse);
});
```

- [ ] **Step 2: Write failing ghost stability test**

Add a repository with delayed projection:

```dart
class DelayedGhostRepository extends GhostRepository {
  DelayedGhostRepository() : super(projectedGhosts: [ghostFixture(id: 5)]);

  final completers = <String, Completer<List<RecurringGhostRecord>>>{};

  @override
  Future<List<RecurringGhostRecord>> ensureRecurringGhostTransactions({
    DateTime? targetDate,
  }) {
    final target = targetDate ?? DateTime(2026, 5);
    final key = '${target.year}-${target.month}';
    ensureTargets.add(DateTime(target.year, target.month));
    final completer = Completer<List<RecurringGhostRecord>>();
    completers[key] = completer;
    return completer.future;
  }
}
```

Add test:

```dart
test('month shift keeps previous ghost rows until projection completes', () async {
  final repository = DelayedGhostRepository();
  final store = TransactionStore(
    repository,
    clock: () => DateTime(2026, 5, 10),
  );
  await store.start();

  final monthlyFuture = store.cycleSummaryWindow();
  repository.completers['2026-5']!.complete([ghostFixture(id: 5, month: 5)]);
  await monthlyFuture;
  expect(store.visibleGhostTransactions.single.periodKey, '2026-05');

  final shiftFuture = store.shiftSummaryPeriod(1);
  await Future<void>.delayed(Duration.zero);

  expect(store.visibleGhostTransactions.single.periodKey, '2026-05');

  repository.completers['2026-6']!.complete([ghostFixture(id: 6, month: 6)]);
  await shiftFuture;

  expect(store.visibleGhostTransactions.single.periodKey, '2026-06');
});
```

- [ ] **Step 3: Run tests to verify failures**

Run:

```bash
flutter test test/transactions/recurring_ghost_log_test.dart
```

Expected: ordering test fails because current display adds a date header for the ghost; yearly test fails because yearly currently allows ghosts; stability test may fail because caches/views invalidate before projection completes.

- [ ] **Step 4: Implement monthly-only ghost filter**

In `TransactionStore._ghostInActiveWindow`, change yearly branch to `false`:

```dart
bool _ghostInActiveWindow(RecurringGhostRecord ghost) {
  return switch (_summaryWindow) {
    SummaryWindow.allTime => false,
    SummaryWindow.monthly =>
      ghost.yearMonthKey ==
          '${_periodReferenceDate.year.toString().padLeft(4, '0')}-${_periodReferenceDate.month.toString().padLeft(2, '0')}',
    SummaryWindow.yearly => false,
  };
}
```

- [ ] **Step 5: Implement top-pinned display rows without ghost date headers**

In `_visibleLogEntriesFor`, do not combined-sort monthly ghosts with records. Use:

```dart
final records = [
  for (final record in _visibleTransactionsFor(filter))
    TransactionLogEntry.record(record),
];
final ghosts = [
  for (final ghost in _visibleGhostTransactionsFor(filter))
    TransactionLogEntry.ghost(ghost),
];
final entries = _summaryWindow == SummaryWindow.monthly
    ? ghosts.followedBy(records)
    : records;
final rows = List<TransactionLogEntry>.unmodifiable(entries);
```

In `_visibleDisplayLogEntriesFor`, skip date headers for ghosts:

```dart
for (final row in _visibleLogEntriesFor(filter)) {
  if (row.isGhost) {
    entries.add(row);
    continue;
  }
  if (row.date != previousDate) {
    entries.add(TransactionLogEntry.header(row.date));
    previousDate = row.date;
  }
  entries.add(row);
}
```

- [ ] **Step 6: Preserve stable ghost view while projection is in flight**

Add fields near existing ghost fields:

```dart
List<RecurringGhostRecord> _stableRecurringGhostTransactions = const [];
String? _stableGhostPeriodKey;
bool _ghostProjectionInFlight = false;
```

When bootstrap/reload completes, set both raw and stable data:

```dart
_recurringGhostTransactions = _sortGhosts(payload.recurringGhostTransactions);
_stableRecurringGhostTransactions = _recurringGhostTransactions;
_stableGhostPeriodKey = _activePeriodKey;
```

In `_visibleGhostTransactionsFor`, read from stable rows while projection is in flight:

```dart
final source = _ghostProjectionInFlight
    ? _stableRecurringGhostTransactions
    : _recurringGhostTransactions;
final rows = List<RecurringGhostRecord>.unmodifiable(
  source.where((ghost) {
    return _ghostMatchesFilter(ghost, filter);
  }),
);
```

Add a private helper to hold the current ghost filter predicate body:

```dart
bool _ghostMatchesFilter(
  RecurringGhostRecord ghost,
  TransactionLogFilter filter,
) {
  return _ghostInActiveWindow(ghost) && _ghostMatchesActiveType(ghost, filter);
}
```

In `_projectRecurringGhostsForActiveWindow`, set in-flight without clearing rows:

```dart
_ghostProjectionInFlight = true;
final ghosts = await _repository.ensureRecurringGhostTransactions(
  targetDate: targetDate,
);
if (generation != null && generation != _summaryChangeGeneration) return;
_recurringGhostTransactions = _sortGhosts(ghosts);
_stableRecurringGhostTransactions = _recurringGhostTransactions;
_stableGhostPeriodKey = periodKey;
_ghostProjectionInFlight = false;
```

Ensure `_ghostProjectionInFlight = false` is set in a `finally` only if the generation is current. Do not clear `_stableRecurringGhostTransactions` before replacement data is ready.

- [ ] **Step 7: Run recurring ghost tests**

Run:

```bash
flutter test test/transactions/recurring_ghost_log_test.dart
```

Expected: pass.

- [ ] **Step 8: Commit**

```bash
git add lib/features/transactions/state/transaction_store.dart test/transactions/recurring_ghost_log_test.dart
git commit -m "Pin monthly ghost rows"
```

---

### Task 6: Ghost Logbox Visual Rendering

**Files:**
- Create: `lib/features/transactions/widgets/ghost_logbox_visuals.dart`
- Modify: `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/recurring_ghost_log_box_test.dart`
- Test: `test/transactions/recurring_ghost_log_test.dart`

- [ ] **Step 1: Write failing widget test for visual controls**

Create `test/transactions/recurring_ghost_log_box_test.dart`:

```dart
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/widgets/ghost_logbox_visuals.dart';
import 'package:exptv2/features/transactions/widgets/recurring_ghost_log_box.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'recurring_ghost_log_test.dart';

void main() {
  testWidgets('ghost logbox renders badge dashed border and expected label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: RecurringGhostLogBox(
          ghost: ghostFixture(),
          category: categoryFixture(),
          settings: GhostLogboxSettings.defaults(),
          surfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('recurring-ghost-dashed-border-1')), findsOneWidget);
    expect(find.byType(GhostBadge), findsOneWidget);
    expect(find.text('Várható · ismétlődő'), findsOneWidget);
    expect(find.text('Ghost'), findsNothing);
  });

  testWidgets('ghost logbox can hide badge and expected label', (tester) async {
    final settings = GhostLogboxSettings.defaults().copyWith(
      avatarBadgeEnabled: false,
      expectedLabelEnabled: false,
      borderStyle: GhostLogboxBorderStyle.normal,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: RecurringGhostLogBox(
          ghost: ghostFixture(),
          category: categoryFixture(),
          settings: settings,
          surfaceStyle: ExpenseSurfaceInteraction.neutralNeutral,
        ),
      ),
    );

    expect(find.byType(GhostBadge), findsNothing);
    expect(find.text('Várható · ismétlődő'), findsNothing);
    expect(find.byKey(const ValueKey('recurring-ghost-dashed-border-1')), findsNothing);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/transactions/recurring_ghost_log_box_test.dart
```

Expected: fails because `GhostBadge`, `settings`, and dashed border do not exist.

- [ ] **Step 3: Create ghost visual helpers**

Create `lib/features/transactions/widgets/ghost_logbox_visuals.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class GhostBadge extends StatelessWidget {
  const GhostBadge({super.key, this.size = 18});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: AppColors.white,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.gray300),
        ),
        child: CustomPaint(painter: _GhostPainter()),
      ),
    );
  }
}

class DashedRoundedBorder extends StatelessWidget {
  const DashedRoundedBorder({
    super.key,
    required this.borderRadius,
    required this.color,
    required this.child,
  });

  final BorderRadius borderRadius;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      foregroundPainter: DashedRoundedBorderPainter(
        borderRadius: borderRadius,
        color: color,
      ),
      child: child,
    );
  }
}

class DashedRoundedBorderPainter extends CustomPainter {
  const DashedRoundedBorderPainter({
    required this.borderRadius,
    required this.color,
  });

  final BorderRadius borderRadius;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final rrect = borderRadius.toRRect(rect.deflate(0.5));
    final path = Path()..addRRect(rrect);
    final metric = path.computeMetrics().first;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    var distance = 0.0;
    const dash = 7.0;
    const gap = 5.0;
    while (distance < metric.length) {
      final segment = metric.extractPath(distance, distance + dash);
      canvas.drawPath(segment, paint);
      distance += dash + gap;
    }
  }

  @override
  bool shouldRepaint(covariant DashedRoundedBorderPainter oldDelegate) {
    return oldDelegate.borderRadius != borderRadius || oldDelegate.color != color;
  }
}

class _GhostPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.gray700
      ..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(w * 0.25, h * 0.72)
      ..lineTo(w * 0.25, h * 0.42)
      ..quadraticBezierTo(w * 0.25, h * 0.18, w * 0.50, h * 0.18)
      ..quadraticBezierTo(w * 0.75, h * 0.18, w * 0.75, h * 0.42)
      ..lineTo(w * 0.75, h * 0.72)
      ..lineTo(w * 0.62, h * 0.62)
      ..lineTo(w * 0.50, h * 0.74)
      ..lineTo(w * 0.38, h * 0.62)
      ..close();
    canvas.drawPath(path, paint);
    final eyePaint = Paint()..color = AppColors.white;
    canvas.drawCircle(Offset(w * 0.42, h * 0.42), w * 0.055, eyePaint);
    canvas.drawCircle(Offset(w * 0.58, h * 0.42), w * 0.055, eyePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
```

- [ ] **Step 4: Update `RecurringGhostLogBox` API and rendering**

Add imports:

```dart
import '../../settings/models/app_theme_settings.dart';
import 'ghost_logbox_visuals.dart';
```

Add constructor default:

```dart
this.settings = const GhostLogboxSettings(
  borderStyle: GhostLogboxBorderStyle.dashed,
  backgroundOpacityEnabled: true,
  avatarOpacityEnabled: false,
  textOpacityEnabled: false,
  avatarBadgeEnabled: true,
  textTone: GhostLogboxTextTone.normal,
  expectedLabelEnabled: true,
),
```

Add field:

```dart
final GhostLogboxSettings settings;
```

Use `surfaceStyle` from the caller. Calculate visual values:

```dart
final contentOpacity = settings.textOpacityEnabled ? 0.78 : 1.0;
final avatarOpacity = settings.avatarOpacityEnabled ? 0.72 : 1.0;
final surfaceOpacity = settings.backgroundOpacityEnabled ? 0.68 : 1.0;
final textColor = settings.textTone == GhostLogboxTextTone.gray
    ? AppColors.gray500
    : AppColors.gray800;
final valueColor = settings.textTone == GhostLogboxTextTone.gray
    ? AppColors.gray500
    : amountColor;
```

Apply the background opacity directly to the surface color passed into `ExpenseSurfaceContainer` so text and avatar opacity remain independently controlled:

```dart
final effectiveSurfaceColor = surfaceColor.withValues(alpha: surfaceOpacity);
```

Replace label text:

```dart
if (settings.expectedLabelEnabled)
  const Text(
    'Várható · ismétlődő',
    style: TextStyle(
      fontSize: 11,
      fontWeight: FontWeight.w700,
      color: AppColors.gray500,
    ),
  ),
```

Render avatar in a `Stack`:

```dart
Opacity(
  opacity: avatarOpacity,
  child: Stack(
    clipBehavior: Clip.none,
    children: [
      CategoryIconBadge(
        iconId: ghost.category.iconId,
        color: ghost.category.color,
        size: 44,
      ),
      if (settings.avatarBadgeEnabled)
        const Positioned(
          right: -2,
          bottom: -2,
          child: GhostBadge(size: 18),
        ),
    ],
  ),
),
```

For dashed border:

```dart
final content = ExpenseSurfaceContainer(
  key: ValueKey('recurring-ghost-logbox-content-${ghost.id}'),
  surfaceStyle: surfaceStyle,
  surfaceColor: effectiveSurfaceColor,
  borderRadius: BorderRadius.circular(25),
  child: rowContent,
);
return settings.borderStyle == GhostLogboxBorderStyle.dashed
    ? DashedRoundedBorder(
        key: ValueKey('recurring-ghost-dashed-border-${ghost.id}'),
        borderRadius: BorderRadius.circular(25),
        color: AppColors.gray300,
        child: content,
      )
    : content;
```

- [ ] **Step 5: Pass settings through list and home page**

In `TransactionLogList`, add fields:

```dart
this.ghostSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
this.ghostLogboxSettings = const GhostLogboxSettings(
  borderStyle: GhostLogboxBorderStyle.dashed,
  backgroundOpacityEnabled: true,
  avatarOpacityEnabled: false,
  textOpacityEnabled: false,
  avatarBadgeEnabled: true,
  textTone: GhostLogboxTextTone.normal,
  expectedLabelEnabled: true,
),
```

Add explicit fields:

```dart
final ExpenseSurfaceInteraction ghostSurfaceStyle;
final GhostLogboxSettings ghostLogboxSettings;
```

Pass to `RecurringGhostLogBox`:

```dart
surfaceStyle: widget.ghostSurfaceStyle,
settings: widget.ghostLogboxSettings,
```

In `TransactionHomePage`, pass:

```dart
ghostSurfaceStyle: expenseTheme.ghostLogboxSurfaceStyle,
ghostLogboxSettings: expenseTheme.settings.ghostLogboxSettings,
```

- [ ] **Step 6: Run widget tests**

Run:

```bash
flutter test test/transactions/recurring_ghost_log_box_test.dart test/transactions/recurring_ghost_log_test.dart
```

Expected: pass.

- [ ] **Step 7: Commit**

```bash
git add lib/features/transactions/widgets/ghost_logbox_visuals.dart lib/features/transactions/widgets/recurring_ghost_log_box.dart lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/transaction_home_page.dart test/transactions/recurring_ghost_log_box_test.dart test/transactions/recurring_ghost_log_test.dart
git commit -m "Style recurring ghost logboxes"
```

---

### Task 7: Final Verification And Push

**Files:**
- No planned source edits unless verification exposes failures.

- [ ] **Step 1: Run Dart/Flutter checks**

Run:

```bash
flutter analyze
flutter test
```

Expected: pass in GitHub Actions/dev machine. On Termux this may fail with `flutter: not found`; if so, rely on GitHub Actions after push and report the local blocker.

- [ ] **Step 2: Run Android unit tests**

Run:

```bash
cd android && ./gradlew testDebugUnitTest --no-daemon
```

Expected: pass in GitHub Actions/dev machine. On Termux this may fail if `JAVA_HOME`/`java` is unavailable.

- [ ] **Step 3: Run git checks**

Run:

```bash
git diff --check
git status --short --branch
git log --oneline --decorate -n 8
```

Expected:

- `git diff --check` prints nothing.
- working tree is clean after commits.
- branch contains the task commits.

- [ ] **Step 4: Push main**

Run:

```bash
git push origin main
```

Expected: push succeeds and GitHub Actions starts a new APK build.

- [ ] **Step 5: Watch GitHub Actions and report APK link**

Run:

```bash
gh run list --repo elizerpist/exptv2 --branch main --limit 3
gh run watch <run-id> --repo elizerpist/exptv2 --interval 15 --exit-status
gh release view debug-latest --repo elizerpist/exptv2 --json assets,url
```

Expected: workflow succeeds and the direct APK link remains:

```text
https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk
```

Report the run URL, latest commit, and any local verification blockers.

---

## Self-Review

Spec coverage:

- Monthly pinned ghosts: Task 5.
- No yearly/all-time ghosts: Task 5.
- Render stability during projection/reload: Task 5.
- Component-level surface controls and global neumorphism removal: Tasks 1, 2, 3, 4.
- Ghost visual settings: Tasks 1, 3, 4, 6.
- Ghost badge without external icon dependency: Task 6.
- Tests for all requested behavior: Tasks 1-7.

Placeholder scan: no open placeholders are intentionally left. Commands and expected outcomes are explicit.

Type consistency:

- `ghostLogboxSurfaceStyle` is used consistently in settings model, theme, native payload, and widgets.
- `GhostLogboxSettings`, `GhostLogboxBorderStyle`, and `GhostLogboxTextTone` are introduced before use in later tasks.
- Neumorph mapping is explicit: buttons `raisedInset`, logboxes `insetInset`, ghost logboxes `insetInset`.
