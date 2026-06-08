# Neumorphism Night Theme Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace manual surface style choices with normal/neumorphism profiles, add pink day color plus two independent night palettes, and apply the resolved design consistently to home, sheets, category flows, and primary controls.

**Architecture:** Extend the existing `AppThemeSettings` and `ExpenseTheme` layers instead of adding a parallel theme system. Keep `ExpenseSurface` as the shared depth primitive, add role-based theme tokens and reusable profile-aware controls, then fan those tokens into existing widgets. Persist new settings through the current Kotlin `ExpenseSettingsStore` map contract with legacy migration defaults.

**Tech Stack:** Flutter/Dart widget and unit tests, Kotlin Android settings store tests, existing MethodChannel settings bridge, existing `ExpenseSurface` neumorphism primitive, GitHub Actions for APK builds.

---

## Scope Check

This spec spans settings, theme tokens, home widgets, sheets, category flows, and final verification. These are connected by one shared theme model, so a single plan is acceptable. Implementation can still be split across subagents after Task 2 because home, sheets, and category fanout become mostly independent once the new settings and `ExpenseTheme` tokens exist.

## File Structure

- Modify `lib/features/settings/models/app_theme_settings.dart`: add `AppDesignProfile`, `AppNightMode`, `AppColorMode`, parse/serialize new keys, keep legacy `theme`, `buttonSurfaceStyle`, and `contentSurfaceStyle` compatibility.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`: persist `designProfile`, `nightMode`, and `appColor`, and migrate missing values from old keys.
- Modify `lib/features/settings/theme/expense_theme.dart`: resolve day/night palettes, primary role tokens, text/border tokens, and surface styles by role.
- Modify `lib/features/settings/theme/expense_surface.dart`: add transparent Material feedback helpers and reusable `ExpenseSurfaceButton`.
- Modify `lib/features/settings/widgets/options/theme_options_panel.dart`: replace manual surface choice sections with profile, night mode, and app color choices.
- Modify `lib/features/shell/expt_shell.dart`, `lib/features/shell/widgets/expt_bottom_nav.dart`, `lib/features/shell/widgets/bottom_nav_item.dart`, `lib/features/shell/widgets/expt_fab.dart`: pass resolved theme tokens, keep active bottom nav inset, and remove double feedback in neumorphism.
- Modify `lib/features/transactions/transaction_home_page.dart`, `lib/features/transactions/widgets/search_pill.dart`, `summary_pill.dart`, `transaction_type_pills.dart`, `transaction_log_box.dart`, `transaction_log_list.dart`, and header widgets under `lib/features/transactions/widgets/header_card/`: apply role-based surface styles and primary colors.
- Create `lib/features/transactions/widgets/themed_pill_field.dart`: shared neumorphic wrapper for transaction/category/limit text fields.
- Modify `lib/features/transactions/widgets/amount_field.dart`, `category_selector_field.dart`, `date_time_fields.dart`, `add_transaction_sheet.dart`, `recurring_manager_sheet.dart`, and `header_card/budget_target_editor_sheet.dart`: use themed pill fields and raised save buttons.
- Modify `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`, `category_menu_panel.dart`, `category_card.dart`, `category_icon_badge.dart`, `category_editor_sheet.dart`, `category_editor_panel.dart`, `category_slot_grid.dart`, and `category_preview_pill.dart`: apply category menu/editor neumorphism and overlay layering.
- Modify tests in `test/settings/expense_theme_test.dart`, `test/settings/settings_bridge_test.dart`, `test/settings/expense_surface_test.dart`, `test/settings/settings_page_test.dart`, `test/shell/bottom_nav_item_test.dart`, `test/transactions/transaction_widgets_test.dart`, `test/transactions/category_menu_test.dart`, `test/transactions/category_editor_test.dart`, and `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`.

## Preflight

- [ ] **Step 1: Confirm branch and worktree**

Run:

```bash
git status --short --branch
```

Expected: branch contains commit `2072af6 docs: design neumorphism night theme`; no unstaged implementation files. If unrelated user changes appear, do not revert them.

- [ ] **Step 2: Create implementation branch**

Run:

```bash
git switch -c feature/neumorphism-night-theme
```

Expected: `Switched to a new branch 'feature/neumorphism-night-theme'`.

---

### Task 1: Settings Model And Persistence

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Test: `test/settings/settings_bridge_test.dart`
- Test: `test/settings/expense_theme_test.dart`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`

- [ ] **Step 1: Add failing Dart settings tests**

Append these tests to `test/settings/expense_theme_test.dart`:

```dart
  test('theme settings default to normal day turquoise profile', () {
    final settings = AppThemeSettings.defaults();

    expect(settings.designProfile, AppDesignProfile.normal);
    expect(settings.nightMode, AppNightMode.off);
    expect(settings.appColor, AppColorMode.turquoise);
    expect(settings.toMap()['designProfile'], 'normal');
    expect(settings.toMap()['nightMode'], 'off');
    expect(settings.toMap()['appColor'], 'turquoise');
  });

  test('legacy non-neutral surface values migrate to neumorphism profile', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Pink',
      'buttonSurfaceStyle': 'raisedInset',
      'contentSurfaceStyle': 'neutralNeutral',
    });

    expect(settings.designProfile, AppDesignProfile.neumorphism);
    expect(settings.nightMode, AppNightMode.off);
    expect(settings.appColor, AppColorMode.pink);
  });

  test('legacy dark theme migrates to night cyan', () {
    final settings = AppThemeSettings.fromMap(const <String, Object?>{
      'theme': 'Sötét',
    });

    expect(settings.designProfile, AppDesignProfile.normal);
    expect(settings.nightMode, AppNightMode.cyan);
    expect(settings.appColor, AppColorMode.turquoise);
  });
```

Update `test/settings/settings_bridge_test.dart` in `updates theme settings through native bridge` so the constructed settings include the new fields:

```dart
        designProfile: AppDesignProfile.neumorphism,
        nightMode: AppNightMode.amber,
        appColor: AppColorMode.pink,
```

Add expectations after the existing payload checks:

```dart
    expect(payload['designProfile'], 'neumorphism');
    expect(payload['nightMode'], 'amber');
    expect(payload['appColor'], 'pink');
```

- [ ] **Step 2: Run Dart tests to verify they fail**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart
```

Expected: FAIL with missing `AppDesignProfile`, `AppNightMode`, `AppColorMode`, or constructor parameters.

- [ ] **Step 3: Add failing Kotlin persistence test**

Append this test to `android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt`:

```kotlin
    @Test
    fun themeSettingsPersistProfileNightModeAndAppColor() {
        val updated = store.updateThemeSettings(
            mapOf(
                "magnetType" to "adaptive",
                "cardColor" to "darkgray",
                "theme" to "Türkiz",
                "backgroundColor" to "white",
                "boxColor" to "gray",
                "buttonSurfaceStyle" to "neutralNeutral",
                "contentSurfaceStyle" to "neutralNeutral",
                "backheaderStyle" to "orbitBudget",
                "designProfile" to "neumorphism",
                "nightMode" to "amber",
                "appColor" to "pink",
            )
        )

        assertEquals("neumorphism", updated["designProfile"])
        assertEquals("amber", updated["nightMode"])
        assertEquals("pink", updated["appColor"])
        assertEquals("neumorphism", store.loadThemeSettings()["designProfile"])
    }

    @Test
    fun legacyThemeSettingsMigrateMissingProfileValues() {
        val prefs = context.getSharedPreferences("expense_settings", Context.MODE_PRIVATE)
        prefs.edit()
            .putString("theme", "Sötét")
            .putString("buttonSurfaceStyle", "raisedInset")
            .putString("contentSurfaceStyle", "neutralNeutral")
            .commit()

        val settings = store.loadThemeSettings()

        assertEquals("neumorphism", settings["designProfile"])
        assertEquals("cyan", settings["nightMode"])
        assertEquals("turquoise", settings["appColor"])
    }
```

- [ ] **Step 4: Run Kotlin test to verify it fails**

Run:

```bash
./gradlew :app:testDebugUnitTest --tests com.exptv2.app.expense.ExpenseSettingsStoreSecurityTest
```

Expected: FAIL because `designProfile`, `nightMode`, and `appColor` are not persisted.

- [ ] **Step 5: Implement Dart model enums and migration**

In `lib/features/settings/models/app_theme_settings.dart`, add:

```dart
enum AppDesignProfile {
  normal('normal'),
  neumorphism('neumorphism');

  const AppDesignProfile(this.nativeValue);
  final String nativeValue;

  static AppDesignProfile fromAny(Object? value) {
    final raw = value?.toString();
    return AppDesignProfile.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppDesignProfile.normal,
    );
  }
}

enum AppNightMode {
  off('off'),
  cyan('cyan'),
  amber('amber');

  const AppNightMode(this.nativeValue);
  final String nativeValue;

  static AppNightMode fromAny(Object? value) {
    final raw = value?.toString();
    return AppNightMode.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppNightMode.off,
    );
  }
}

enum AppColorMode {
  turquoise('turquoise'),
  pink('pink');

  const AppColorMode(this.nativeValue);
  final String nativeValue;

  static AppColorMode fromAny(Object? value) {
    final raw = value?.toString();
    if (raw == AppTheme.pink.nativeValue || raw == 'pink') {
      return AppColorMode.pink;
    }
    return AppColorMode.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => AppColorMode.turquoise,
    );
  }
}
```

Extend `AppThemeSettings` constructor, fields, `defaults`, `fromMap`, `toMap`, and `copyWith` with:

```dart
    required this.designProfile,
    required this.nightMode,
    required this.appColor,
```

Add private migration helpers inside `AppThemeSettings`:

```dart
  static AppDesignProfile _profileFromMap(Map<dynamic, dynamic> map) {
    if (map.containsKey('designProfile')) {
      return AppDesignProfile.fromAny(map['designProfile']);
    }
    final button = ExpenseSurfaceInteraction.fromAny(map['buttonSurfaceStyle']);
    final content = ExpenseSurfaceInteraction.fromAny(
      map['contentSurfaceStyle'],
    );
    if (button != ExpenseSurfaceInteraction.neutralNeutral ||
        content != ExpenseSurfaceInteraction.neutralNeutral) {
      return AppDesignProfile.neumorphism;
    }
    return AppDesignProfile.normal;
  }

  static AppNightMode _nightModeFromMap(Map<dynamic, dynamic> map) {
    if (map.containsKey('nightMode')) {
      return AppNightMode.fromAny(map['nightMode']);
    }
    return AppTheme.fromAny(map['theme']) == AppTheme.dark
        ? AppNightMode.cyan
        : AppNightMode.off;
  }

  static AppColorMode _appColorFromMap(Map<dynamic, dynamic> map) {
    if (map.containsKey('appColor')) {
      return AppColorMode.fromAny(map['appColor']);
    }
    return AppColorMode.fromAny(map['theme']);
  }
```

Use those helpers from `fromMap`.

- [ ] **Step 6: Implement Kotlin persistence**

In `ExpenseSettingsStore.kt`, add keys:

```kotlin
        private const val KEY_DESIGN_PROFILE = "designProfile"
        private const val KEY_NIGHT_MODE = "nightMode"
        private const val KEY_APP_COLOR = "appColor"
```

Add helper methods above `defaultFastInfoConfig()`:

```kotlin
    private fun legacyDesignProfile(): String {
        val button = prefs.getString(KEY_BUTTON_SURFACE_STYLE, "neutralNeutral")
        val content = prefs.getString(KEY_CONTENT_SURFACE_STYLE, "neutralNeutral")
        return if (button != "neutralNeutral" || content != "neutralNeutral") {
            "neumorphism"
        } else {
            "normal"
        }
    }

    private fun legacyNightMode(): String {
        return if (prefs.getString(KEY_THEME, "Türkiz") == "Sötét") "cyan" else "off"
    }

    private fun legacyAppColor(): String {
        return if (prefs.getString(KEY_THEME, "Türkiz") == "Pink") "pink" else "turquoise"
    }
```

Update `loadThemeSettings()` map with:

```kotlin
            "designProfile" to prefs.getString(KEY_DESIGN_PROFILE, null).orEmpty().ifBlank { legacyDesignProfile() },
            "nightMode" to prefs.getString(KEY_NIGHT_MODE, null).orEmpty().ifBlank { legacyNightMode() },
            "appColor" to prefs.getString(KEY_APP_COLOR, null).orEmpty().ifBlank { legacyAppColor() },
```

Update `updateThemeSettings()` editor chain with:

```kotlin
            .putString(KEY_DESIGN_PROFILE, args["designProfile"]?.toString() ?: "normal")
            .putString(KEY_NIGHT_MODE, args["nightMode"]?.toString() ?: "off")
            .putString(KEY_APP_COLOR, args["appColor"]?.toString() ?: "turquoise")
```

- [ ] **Step 7: Run tests**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart
./gradlew :app:testDebugUnitTest --tests com.exptv2.app.expense.ExpenseSettingsStoreSecurityTest
```

Expected: PASS.

- [ ] **Step 8: Commit**

Run:

```bash
git add lib/features/settings/models/app_theme_settings.dart android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart android/app/src/test/kotlin/com/exptv2/app/expense/ExpenseSettingsStoreSecurityTest.kt
git commit -m "feat: add theme profile settings"
```

---

### Task 2: Role-Based Theme Tokens And Surface Helpers

**Files:**
- Modify: `lib/features/settings/theme/expense_theme.dart`
- Modify: `lib/features/settings/theme/expense_surface.dart`
- Test: `test/settings/expense_theme_test.dart`
- Test: `test/settings/expense_surface_test.dart`

- [ ] **Step 1: Add failing theme token tests**

Append to `test/settings/expense_theme_test.dart`:

```dart
  test('pink day mode resolves pink accent family', () {
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(appColor: AppColorMode.pink),
    );

    expect(theme.accent, const Color(0xFFEC4899));
    expect(theme.accentDark, const Color(0xFFBE185D));
    expect(theme.accentLight, const Color(0xFFF9A8D4));
    expect(theme.activeBackground, const Color(0x15EC4899));
  });

  test('night palettes ignore day app color', () {
    final cyan = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        appColor: AppColorMode.pink,
        nightMode: AppNightMode.cyan,
      ),
    );
    final amber = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        appColor: AppColorMode.pink,
        nightMode: AppNightMode.amber,
      ),
    );

    expect(cyan.isNight, isTrue);
    expect(cyan.accent, const Color(0xFF19BFDC));
    expect(cyan.appBackground, const Color(0xFF0B1420));
    expect(cyan.logBox, const Color(0xFF152231));
    expect(amber.accent, const Color(0xFFF0A646));
    expect(amber.appBackground, const Color(0xFF15120F));
    expect(amber.logBox, const Color(0xFF231D17));
  });

  test('profile resolves component surface roles', () {
    final normal = ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    final neu = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        designProfile: AppDesignProfile.neumorphism,
      ),
    );

    expect(normal.contentSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(normal.buttonSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(normal.bottomNavSurfaceStyle, ExpenseSurfaceInteraction.neutralNeutral);
    expect(neu.contentSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
    expect(neu.buttonSurfaceStyle, ExpenseSurfaceInteraction.raisedInset);
    expect(neu.bottomNavSurfaceStyle, ExpenseSurfaceInteraction.neutralInset);
    expect(neu.forcedInsetSurfaceStyle, ExpenseSurfaceInteraction.insetInset);
  });
```

- [ ] **Step 2: Add failing no-double-feedback helper test**

Append to `test/settings/expense_surface_test.dart`:

```dart
  test('material feedback is disabled when neumorphic press feedback is active', () {
    expect(
      ExpenseSurface.materialFeedbackEnabled(
        ExpenseSurfaceInteraction.neutralNeutral,
      ),
      isTrue,
    );
    expect(
      ExpenseSurface.materialFeedbackEnabled(
        ExpenseSurfaceInteraction.insetInset,
      ),
      isFalse,
    );
    expect(
      ExpenseSurface.transparentOverlayColor.resolve({WidgetState.pressed}),
      Colors.transparent,
    );
  });
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/settings/expense_surface_test.dart
```

Expected: FAIL with missing token getters and `materialFeedbackEnabled`.

- [ ] **Step 4: Implement `ExpenseTheme` role tokens**

Replace `ExpenseTheme` constructor and factory body in `lib/features/settings/theme/expense_theme.dart` with a version that includes:

```dart
  final Color accentDark;
  final Color accentLight;
  final Color activeBackground;
  final Color fieldSurface;
  final Color textPrimary;
  final Color textSecondary;
  final Color textMuted;
  final Color border;
  final ExpenseSurfaceInteraction bottomNavSurfaceStyle;
  final ExpenseSurfaceInteraction forcedInsetSurfaceStyle;

  bool get isNeumorphism =>
      settings.designProfile == AppDesignProfile.neumorphism;
  bool get isNight => settings.nightMode != AppNightMode.off;
```

Use these exact day and night token values:

```dart
const pink = Color(0xFFEC4899);
const pinkDark = Color(0xFFBE185D);
const pinkLight = Color(0xFFF9A8D4);
const nightCyanAccent = Color(0xFF19BFDC);
const nightCyanBackground = Color(0xFF0B1420);
const nightCyanCard = Color(0xFF162333);
const nightCyanSurface = Color(0xFF152231);
const nightAmberAccent = Color(0xFFF0A646);
const nightAmberBackground = Color(0xFF15120F);
const nightAmberCard = Color(0xFF292118);
const nightAmberSurface = Color(0xFF231D17);
```

Resolve surface styles with:

```dart
final neumorphism = settings.designProfile == AppDesignProfile.neumorphism;
buttonSurfaceStyle: neumorphism
    ? ExpenseSurfaceInteraction.raisedInset
    : ExpenseSurfaceInteraction.neutralNeutral,
contentSurfaceStyle: neumorphism
    ? ExpenseSurfaceInteraction.insetInset
    : ExpenseSurfaceInteraction.neutralNeutral,
bottomNavSurfaceStyle: neumorphism
    ? ExpenseSurfaceInteraction.neutralInset
    : ExpenseSurfaceInteraction.neutralNeutral,
forcedInsetSurfaceStyle: neumorphism
    ? ExpenseSurfaceInteraction.insetInset
    : ExpenseSurfaceInteraction.neutralNeutral,
```

- [ ] **Step 5: Implement Material feedback helpers**

In `ExpenseSurface`, add:

```dart
  static bool materialFeedbackEnabled(ExpenseSurfaceInteraction style) {
    return !style.hasPressEffect;
  }

  static const MaterialStateProperty<Color?> transparentMaterialOverlayColor =
      WidgetStatePropertyAll<Color?>(Colors.transparent);

  static const WidgetStateProperty<Color?> transparentOverlayColor =
      WidgetStatePropertyAll<Color?>(Colors.transparent);
```

Use `transparentOverlayColor` for `InkWell.overlayColor` and `transparentMaterialOverlayColor` for older analyzer sites if the compiler requires `MaterialStateProperty<Color?>`.

- [ ] **Step 6: Run tests**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/settings/expense_surface_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add lib/features/settings/theme/expense_theme.dart lib/features/settings/theme/expense_surface.dart test/settings/expense_theme_test.dart test/settings/expense_surface_test.dart
git commit -m "feat: resolve theme profile tokens"
```

---

### Task 3: Theme Options UI

**Files:**
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Test: `test/settings/settings_page_test.dart`

- [ ] **Step 1: Add failing settings UI test**

In `test/settings/settings_page_test.dart`, add a widget test near existing theme submenu tests:

```dart
  testWidgets('theme menu exposes profile app color and night mode choices', (
    tester,
  ) async {
    final updated = <AppThemeSettings>[];
    await tester.pumpWidget(
      MaterialApp(
        home: ThemeOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: updated.add,
        ),
      ),
    );

    expect(find.text('Design profil'), findsOneWidget);
    expect(find.text('Normál (jelenlegi)'), findsOneWidget);
    expect(find.text('Neumorphism'), findsOneWidget);
    expect(find.text('App színe'), findsOneWidget);
    expect(find.text('Türkiz (jelenlegi)'), findsOneWidget);
    expect(find.text('Pink'), findsOneWidget);
    expect(find.text('Éjszakai mód'), findsOneWidget);
    expect(find.text('Kikapcsolva (jelenlegi)'), findsOneWidget);
    expect(find.text('Éjszaka Cyan'), findsOneWidget);
    expect(find.text('Éjszaka Amber'), findsOneWidget);
    expect(find.text('Gomb design'), findsNothing);
    expect(find.text('Logbox / search / summary design'), findsNothing);

    await tester.tap(find.text('Neumorphism'));
    expect(updated.last.designProfile, AppDesignProfile.neumorphism);
    await tester.tap(find.text('Pink'));
    expect(updated.last.appColor, AppColorMode.pink);
    await tester.tap(find.text('Éjszaka Amber'));
    expect(updated.last.nightMode, AppNightMode.amber);
  });
```

If `settings_page_test.dart` contains unrelated local edits during execution, preserve them and append this test without rewriting surrounding changed expectations.

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/settings/settings_page_test.dart
```

Expected: FAIL because new option labels are missing.

- [ ] **Step 3: Replace manual surface sections in `ThemeOptionsPanel`**

In `theme_options_panel.dart`, remove the two sections titled `Gomb design` and `Logbox / search / summary design`. Add these sections after `Témaszín`:

```dart
        _sectionTitle('Design profil', 'Az app interakciós stílusa:'),
        _profileOption('Normál', 'Eredeti app design, gyári tap visszajelzés', AppDesignProfile.normal),
        _profileOption('Neumorphism', '3D felületek, shadow-only tap animáció', AppDesignProfile.neumorphism),
        _sectionTitle('App színe', 'Nappali módban használt fő szín:'),
        _appColorOption('Türkiz', 'Jelenlegi türkiz appszín', AppColorMode.turquoise, AppColors.primary),
        _appColorOption('Pink', 'Pink appszín nappali módhoz', AppColorMode.pink, const Color(0xFFEC4899)),
        _sectionTitle('Éjszakai mód', 'Saját, app színtől független éjszakai paletták:'),
        _nightOption('Kikapcsolva', 'Nappali háttér és app szín', AppNightMode.off, AppColors.gray100),
        _nightOption('Éjszaka Cyan', 'Hideg navy-cyan éjszakai mód', AppNightMode.cyan, const Color(0xFF19BFDC)),
        _nightOption('Éjszaka Amber', 'Meleg amber éjszakai mód', AppNightMode.amber, const Color(0xFFF0A646)),
```

Add helper methods:

```dart
  Widget _profileOption(String title, String description, AppDesignProfile value) {
    return SettingsRadioOption(
      title: '$title${settings.designProfile == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.designProfile == value,
      onTap: () => onChanged(settings.copyWith(designProfile: value)),
      preview: _SurfacePreview(
        style: value == AppDesignProfile.neumorphism
            ? ExpenseSurfaceInteraction.raisedInset
            : ExpenseSurfaceInteraction.neutralNeutral,
      ),
    );
  }

  Widget _appColorOption(String title, String description, AppColorMode value, Color color) {
    return SettingsRadioOption(
      title: '$title${settings.appColor == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.appColor == value,
      onTap: () => onChanged(settings.copyWith(appColor: value)),
      preview: _ColorPreview(color: color),
    );
  }

  Widget _nightOption(String title, String description, AppNightMode value, Color color) {
    return SettingsRadioOption(
      title: '$title${settings.nightMode == value ? ' (jelenlegi)' : ''}',
      description: description,
      selected: settings.nightMode == value,
      onTap: () => onChanged(settings.copyWith(nightMode: value)),
      preview: _ColorPreview(color: color),
    );
  }
```

- [ ] **Step 4: Run test**

Run:

```bash
flutter test test/settings/settings_page_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/features/settings/widgets/options/theme_options_panel.dart test/settings/settings_page_test.dart
git commit -m "feat: simplify theme profile options"
```

---

### Task 4: Shell, FAB, Bottom Nav, And Home Fanout

**Files:**
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/shell/widgets/expt_bottom_nav.dart`
- Modify: `lib/features/shell/widgets/bottom_nav_item.dart`
- Modify: `lib/features/shell/widgets/expt_fab.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/search_pill.dart`
- Modify: `lib/features/transactions/widgets/summary_pill.dart`
- Modify: `lib/features/transactions/widgets/transaction_type_pills.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/header_fast_info_surface.dart`
- Test: `test/shell/bottom_nav_item_test.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Test: `test/transactions/header_card_test.dart`

- [ ] **Step 1: Add failing bottom nav active inset test**

Append to `test/shell/bottom_nav_item_test.dart`:

```dart
  testWidgets('active bottom nav item remains inset for neutral-inset nav style', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          bottomNavigationBar: ExptBottomNav(
            activeTab: AppTab.home,
            surfaceStyle: ExpenseSurfaceInteraction.neutralInset,
            onTabSelected: (_) {},
          ),
        ),
      ),
    );

    final activeSurface = tester.widget<Container>(
      find.byKey(const ValueKey('bottom-nav-home-surface')),
    );
    final inactiveSurface = tester.widget<Container>(
      find.byKey(const ValueKey('bottom-nav-settings-surface')),
    );
    final activeDecoration = activeSurface.decoration! as BoxDecoration;
    final inactiveDecoration = inactiveSurface.decoration! as BoxDecoration;

    expect(activeDecoration.gradient, isA<LinearGradient>());
    expect(inactiveDecoration.gradient, isNull);
  });
```

- [ ] **Step 2: Add failing search wrapper transparency and logbox tap tests**

In `test/transactions/transaction_widgets_test.dart`, replace the old test named `search pill text wrapper uses the configured surface color` with:

```dart
  testWidgets('search pill text wrapper is transparent for inset profile', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: SearchPill(
          query: '',
          onQueryChanged: (_) {},
          filteredCount: 0,
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.insetInset,
        ),
      ),
    );

    final wrapper = tester.widget<Container>(
      find.byKey(const ValueKey('search-pill-text-wrapper')),
    );
    final decoration = wrapper.decoration! as BoxDecoration;
    expect(decoration.color, Colors.transparent);
    final textField = tester.widget<TextField>(find.byType(TextField));
    expect(textField.decoration?.filled, isTrue);
    expect(textField.decoration?.fillColor, Colors.transparent);
  });
```

Append:

```dart
  testWidgets('transaction logbox merchant name opens edit transaction not rename dialog', (
    tester,
  ) async {
    final record = sampleRecord();
    final category = sampleCategory();
    TransactionRecord? edited;
    var renamed = false;

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionLogBox(
          record: record,
          category: category,
          surfaceStyle: ExpenseSurfaceInteraction.insetInset,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
          onTap: (value) => edited = value,
          onRenameMerchant: (_, __) async => renamed = true,
          onCategoryFilter: (_) {},
        ),
      ),
    );

    await tester.tap(
      find.byKey(ValueKey('transaction-logbox-name-${record.id}')),
      warnIfMissed: false,
    );
    await tester.pump();

    expect(edited?.id, record.id);
    expect(renamed, isFalse);
    expect(find.byKey(const ValueKey('transaction-name-editor-field')), findsNothing);
  });
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/shell/bottom_nav_item_test.dart test/transactions/transaction_widgets_test.dart
```

Expected: FAIL because active nav is not forced inset and search wrapper is not transparent.

- [ ] **Step 4: Implement bottom nav forced inset and transparent Material feedback**

In `BottomNavItem`, compute:

```dart
    final activeSurfaceStyle =
        active && surfaceStyle == ExpenseSurfaceInteraction.neutralInset
        ? ExpenseSurfaceInteraction.insetInset
        : surfaceStyle;
```

Use `activeSurfaceStyle` for `ExpensePressable.enabled`, `ExpenseSurfaceContainer.style`, `ExpenseSurfaceContainer.pressed`, `onHighlightChanged`, and color tint checks. Set `InkWell`:

```dart
                    overlayColor: ExpenseSurface.materialFeedbackEnabled(
                      activeSurfaceStyle,
                    )
                        ? null
                        : ExpenseSurface.transparentOverlayColor,
                    splashColor: ExpenseSurface.materialFeedbackEnabled(
                      activeSurfaceStyle,
                    )
                        ? null
                        : Colors.transparent,
                    highlightColor: ExpenseSurface.materialFeedbackEnabled(
                      activeSurfaceStyle,
                    )
                        ? null
                        : Colors.transparent,
```

In `ExptBottomNav`, use `expenseTheme.bottomNavSurfaceStyle` from shell instead of `buttonSurfaceStyle`.

- [ ] **Step 5: Implement FAB and type pill Material feedback suppression**

In `ExptFab`, pass `primaryColor` and use transparent overlay when neumorphic:

```dart
              overlayColor: ExpenseSurface.materialFeedbackEnabled(
                widget.surfaceStyle,
              )
                  ? null
                  : ExpenseSurface.transparentOverlayColor,
              splashColor: ExpenseSurface.materialFeedbackEnabled(
                widget.surfaceStyle,
              )
                  ? null
                  : Colors.transparent,
              highlightColor: ExpenseSurface.materialFeedbackEnabled(
                widget.surfaceStyle,
              )
                  ? Colors.white30
                  : Colors.transparent,
```

Add `primaryColor` to `ExptFab` defaulting to `AppColors.primary`, and use it in `ExpenseSurfaceContainer.color`, `primaryColor`, and icon button color roles.

Apply the same overlay suppression pattern to `TransactionTypePills` `_TransactionTypePill` `InkWell`.

- [ ] **Step 6: Implement home fanout**

In `ExptShell._buildShellNavigation`, pass:

```dart
          surfaceStyle: expenseTheme.bottomNavSurfaceStyle,
```

for `ExptBottomNav`, and:

```dart
            primaryColor: expenseTheme.accent,
            surfaceStyle: expenseTheme.buttonSurfaceStyle,
```

for `ExptFab`.

In `TransactionHomePage`, pass:

```dart
surfaceStyle: expenseTheme.buttonSurfaceStyle
```

only to raised controls, and:

```dart
surfaceStyle: expenseTheme.contentSurfaceStyle
```

to search, summary, header content, and logbox body. Change:

```dart
avatarSurfaceStyle: expenseTheme.contentSurfaceStyle,
```

to:

```dart
avatarSurfaceStyle: expenseTheme.buttonSurfaceStyle,
```

- [ ] **Step 7: Implement search wrapper transparency**

In `SearchPill`, compute:

```dart
    final transparentInnerField = widget.surfaceStyle.hasPressEffect;
    final innerFillColor = transparentInnerField
        ? Colors.transparent
        : widget.surfaceColor;
```

Use `innerFillColor` for `search-pill-text-wrapper` decoration and `InputDecoration.fillColor`.

- [ ] **Step 8: Remove merchant-name rename tap**

In `TransactionLogBox._nameBlock`, remove `onTap: _openNameEditor` from the name `GestureDetector` and replace it with:

```dart
            onTap: () => widget.onTap?.call(widget.record),
```

Keep reset-name icon behavior for records with a custom name.

- [ ] **Step 9: Run tests**

Run:

```bash
flutter test test/shell/bottom_nav_item_test.dart test/transactions/transaction_widgets_test.dart test/transactions/header_card_test.dart
```

Expected: PASS.

- [ ] **Step 10: Commit**

Run:

```bash
git add lib/features/shell/expt_shell.dart lib/features/shell/widgets/expt_bottom_nav.dart lib/features/shell/widgets/bottom_nav_item.dart lib/features/shell/widgets/expt_fab.dart lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/search_pill.dart lib/features/transactions/widgets/summary_pill.dart lib/features/transactions/widgets/transaction_type_pills.dart lib/features/transactions/widgets/transaction_log_box.dart lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/transactions/widgets/header_card/header_fast_info_surface.dart test/shell/bottom_nav_item_test.dart test/transactions/transaction_widgets_test.dart test/transactions/header_card_test.dart
git commit -m "feat: apply neumorphism home profile"
```

---

### Task 5: Shared Pill Fields And Action Buttons For Sheets

**Files:**
- Create: `lib/features/transactions/widgets/themed_pill_field.dart`
- Modify: `lib/features/transactions/widgets/amount_field.dart`
- Modify: `lib/features/transactions/widgets/category_selector_field.dart`
- Modify: `lib/features/transactions/widgets/date_time_fields.dart`
- Modify: `lib/features/transactions/widgets/add_transaction_sheet.dart`
- Modify: `lib/features/transactions/widgets/recurring_manager_sheet.dart`
- Modify: `lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart`
- Test: `test/transactions/slide_up_menu_card_test.dart`
- Test: `test/transactions/transaction_widgets_test.dart`
- Test: `test/transactions/transaction_home_limits_test.dart`

- [ ] **Step 1: Add failing field helper test**

Append to `test/transactions/transaction_widgets_test.dart`:

```dart
  testWidgets('themed pill field renders inset surface in neumorphism', (
    tester,
  ) async {
    final controller = TextEditingController(text: '1200');
    addTearDown(controller.dispose);

    await tester.pumpWidget(
      MaterialApp(
        home: ThemedPillField(
          fieldKey: const ValueKey('test-themed-pill-field'),
          debugLabel: 'Test.amount',
          controller: controller,
          label: 'Összeg',
          surfaceColor: AppColors.gray200,
          surfaceStyle: ExpenseSurfaceInteraction.insetInset,
        ),
      ),
    );

    final surface = tester.widget<Container>(
      find.byKey(const ValueKey('test-themed-pill-field-surface')),
    );
    final decoration = surface.decoration! as BoxDecoration;
    expect(decoration.color, AppColors.gray200);
    expect(decoration.boxShadow, isNull);
  });
```

Add import:

```dart
import 'package:exptv2/features/transactions/widgets/themed_pill_field.dart';
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/transactions/transaction_widgets_test.dart --plain-name "themed pill field renders inset surface in neumorphism"
```

Expected: FAIL because `ThemedPillField` does not exist.

- [ ] **Step 3: Create `ThemedPillField`**

Create `lib/features/transactions/widgets/themed_pill_field.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/debug/debug_text_input.dart';
import '../../../core/theme/app_colors.dart';
import '../../settings/models/app_theme_settings.dart';

class ThemedPillField extends StatelessWidget {
  const ThemedPillField({
    super.key,
    required this.debugLabel,
    required this.controller,
    required this.label,
    this.fieldKey,
    this.focusNode,
    this.keyboardType,
    this.onChanged,
    this.suffixText,
    this.suffixIcon,
    this.surfaceColor = AppColors.gray50,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  });

  final Key? fieldKey;
  final String debugLabel;
  final TextEditingController controller;
  final String label;
  final FocusNode? focusNode;
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final String? suffixText;
  final Widget? suffixIcon;
  final Color surfaceColor;
  final ExpenseSurfaceInteraction surfaceStyle;

  @override
  Widget build(BuildContext context) {
    if (!surfaceStyle.hasPressEffect) {
      return DebugTextField(
        fieldKey: fieldKey,
        debugLabel: debugLabel,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: transactionFieldDecoration(label).copyWith(
          suffixText: suffixText,
          suffixIcon: suffixIcon,
        ),
      );
    }
    final radius = BorderRadius.circular(25);
    return ExpenseSurfaceContainer(
      surfaceKey: ValueKey('${(fieldKey as ValueKey?)?.value ?? debugLabel}-surface'),
      style: surfaceStyle,
      color: surfaceColor,
      borderRadius: radius,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
      neutralBorder: Border.all(color: AppColors.gray200),
      child: DebugTextField(
        fieldKey: fieldKey,
        debugLabel: debugLabel,
        controller: controller,
        focusNode: focusNode,
        keyboardType: keyboardType,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: Colors.transparent,
          suffixText: suffixText,
          suffixIcon: suffixIcon,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          errorBorder: InputBorder.none,
          focusedErrorBorder: InputBorder.none,
          contentPadding: EdgeInsets.zero,
        ),
      ),
    );
  }
}

InputDecoration transactionFieldDecoration(String label) {
  return InputDecoration(
    labelText: label,
    filled: true,
    fillColor: AppColors.gray50,
    contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: AppColors.gray200),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(25),
      borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
    ),
  );
}
```

Remove the duplicate `transactionFieldDecoration` from `amount_field.dart` and import it from `themed_pill_field.dart`.

- [ ] **Step 4: Add reusable surface button**

In `expense_surface.dart`, add `ExpenseSurfaceButton`:

```dart
class ExpenseSurfaceButton extends StatelessWidget {
  const ExpenseSurfaceButton({
    super.key,
    required this.buttonKey,
    required this.label,
    required this.onPressed,
    this.icon,
    this.saving = false,
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.color = AppColors.primary,
    this.foregroundColor = AppColors.white,
  });

  final Key buttonKey;
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool saving;
  final ExpenseSurfaceInteraction surfaceStyle;
  final Color color;
  final Color foregroundColor;

  @override
  Widget build(BuildContext context) {
    if (!surfaceStyle.hasPressEffect) {
      return icon == null
          ? FilledButton(
              key: buttonKey,
              onPressed: saving ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: foregroundColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
              child: Text(saving ? 'Mentés...' : label),
            )
          : FilledButton.icon(
              key: buttonKey,
              onPressed: saving ? null : onPressed,
              icon: Icon(icon, size: 19),
              label: Text(saving ? 'Mentés...' : label),
              style: FilledButton.styleFrom(
                backgroundColor: color,
                foregroundColor: foregroundColor,
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(25),
                ),
              ),
            );
    }
    return ExpensePressable(
      enabled: onPressed != null && !saving,
      builder: (context, pressed) {
        return GestureDetector(
          key: buttonKey,
          behavior: HitTestBehavior.opaque,
          onTap: saving ? null : onPressed,
          child: ExpenseSurfaceContainer(
            style: surfaceStyle,
            color: color,
            primary: true,
            primaryColor: color,
            borderRadius: BorderRadius.circular(25),
            pressed: pressed,
            height: 50,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (icon != null) ...[
                  Icon(icon, size: 19, color: foregroundColor),
                  const SizedBox(width: 8),
                ],
                Text(
                  saving ? 'Mentés...' : label,
                  style: TextStyle(
                    color: foregroundColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
```

- [ ] **Step 5: Thread theme into sheet widgets**

Add `ExpenseTheme? expenseTheme` to `AddTransactionSheet`, `RecurringManagerSheet`, and `BudgetTargetEditorSheet`. In shell sheet slots, pass `ExpenseTheme.fromSettings(_themeSettings)` into each sheet. In `TransactionHomePage`, when it hosts `BudgetTargetEditorSheet` internally, pass the local `expenseTheme`.

Update `AmountField`, `CategorySelectorField`, and `DateTimeFields` constructors to accept `surfaceColor` and `surfaceStyle`; use `ThemedPillField` for text fields and an `ExpenseSurfaceContainer` wrapper for `CategorySelectorField` in neumorphism.

Replace existing save `FilledButton` calls in add transaction, recurring manager, and budget target editor with `ExpenseSurfaceButton` using:

```dart
surfaceStyle: expenseTheme.buttonSurfaceStyle,
color: expenseTheme.accent,
```

- [ ] **Step 6: Run tests**

Run:

```bash
flutter test test/transactions/transaction_widgets_test.dart test/transactions/slide_up_menu_card_test.dart test/transactions/transaction_home_limits_test.dart
```

Expected: PASS.

- [ ] **Step 7: Commit**

Run:

```bash
git add lib/features/transactions/widgets/themed_pill_field.dart lib/features/transactions/widgets/amount_field.dart lib/features/transactions/widgets/category_selector_field.dart lib/features/transactions/widgets/date_time_fields.dart lib/features/transactions/widgets/add_transaction_sheet.dart lib/features/transactions/widgets/recurring_manager_sheet.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart lib/features/settings/theme/expense_surface.dart test/transactions/transaction_widgets_test.dart test/transactions/slide_up_menu_card_test.dart test/transactions/transaction_home_limits_test.dart
git commit -m "feat: theme transaction sheet surfaces"
```

---

### Task 6: Category Menu, Editor Overlay, Slots, And Preview

**Files:**
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_card.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_icon_badge.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_sheet.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_editor_panel.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_slot_grid.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_preview_pill.dart`
- Test: `test/transactions/category_menu_test.dart`
- Test: `test/transactions/category_editor_test.dart`

- [ ] **Step 1: Add failing category card surface test**

Append to `test/transactions/category_menu_test.dart`:

```dart
  testWidgets('category cards use inset body and raised avatar in neumorphism', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategoryMenuPanel(
            activeType: TransactionType.expense,
            categories: categoryFixtures,
            categoryTransactionCounts: const {6: 3},
            activeCategory: categoryFixtures.last,
            surfaceColor: AppColors.gray200,
            cardSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
            avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onSelect: (_) {},
            onModify: (_) {},
            onDelete: (_) {},
            onAdd: () {},
            onClose: () {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('category-card-surface-6')), findsOneWidget);
    expect(find.byKey(const ValueKey('category-icon-surface-6')), findsOneWidget);
    final card = tester.widget<Container>(
      find.byKey(const ValueKey('category-card-surface-6')),
    );
    expect((card.decoration! as BoxDecoration).boxShadow, isNull);
  });
```

Add imports for `AppColors` and `AppThemeSettings` if missing.

- [ ] **Step 2: Add failing slot and preview tests**

Append to `test/transactions/category_editor_test.dart`:

```dart
  testWidgets('category slots keep selected item inset in neumorphism', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CategorySlotGrid.colors(
            selectedSlot: 9,
            surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            selectedSurfaceStyle: ExpenseSurfaceInteraction.insetInset,
            onSelected: (_) {},
          ),
        ),
      ),
    );

    final selected = tester.widget<Container>(
      find.byKey(const ValueKey('color-slot-surface-9')),
    );
    final unselected = tester.widget<Container>(
      find.byKey(const ValueKey('color-slot-surface-8')),
    );
    expect((selected.decoration! as BoxDecoration).boxShadow, isNull);
    expect((unselected.decoration! as BoxDecoration).boxShadow, isNotNull);
  });

  testWidgets('category preview uses inset log body and raised avatar', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: CategoryPreviewPill(
          name: 'Travel',
          colorSlot: 9,
          iconSlot: 4,
          surfaceColor: AppColors.gray200,
          bodySurfaceStyle: ExpenseSurfaceInteraction.insetInset,
          avatarSurfaceStyle: ExpenseSurfaceInteraction.raisedInset,
        ),
      ),
    );

    expect(find.byKey(const ValueKey('category-preview-pill-surface')), findsOneWidget);
    expect(find.byKey(const ValueKey('category-preview-avatar-surface')), findsOneWidget);
  });
```

Add imports:

```dart
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_preview_pill.dart';
import 'package:exptv2/features/transactions/widgets/category_menu/category_slot_grid.dart';
```

- [ ] **Step 3: Run tests to verify they fail**

Run:

```bash
flutter test test/transactions/category_menu_test.dart test/transactions/category_editor_test.dart
```

Expected: FAIL because category widgets do not accept surface parameters.

- [ ] **Step 4: Implement category menu surface parameters**

Add to `CategoryMenuOverlay`, `CategoryMenuPanel`, and `CategoryCard`:

```dart
  final Color surfaceColor;
  final ExpenseSurfaceInteraction cardSurfaceStyle;
  final ExpenseSurfaceInteraction avatarSurfaceStyle;
```

Default values:

```dart
  this.surfaceColor = AppColors.white,
  this.cardSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
  this.avatarSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
```

Replace `CategoryCard` `Material` body with `ExpensePressable` + `ExpenseSurfaceContainer` keyed:

```dart
surfaceKey: ValueKey('category-card-surface-${category.transactionCategoryID}'),
style: cardSurfaceStyle,
color: active ? AppColors.primaryActiveBackground : surfaceColor,
borderRadius: BorderRadius.circular(18),
```

Wrap `CategoryIconBadge` with `ExpensePressable` + `ExpenseSurfaceContainer` keyed:

```dart
surfaceKey: ValueKey('category-icon-surface-${category.transactionCategoryID}'),
style: avatarSurfaceStyle,
color: category.slotColor,
primary: true,
primaryColor: category.slotColor,
borderRadius: BorderRadius.circular(32.5),
```

Keep `onLongPress: () => onModify(category)` on the avatar and card.

- [ ] **Step 5: Keep edit category overlay above menu and bottom nav**

In `TransactionHomePage`, add a callback prop:

```dart
  final ValueChanged<TransactionCategory>? onEditCategoryEditorRequested;
```

Use it in `_openModifyCategory`:

```dart
  void _openModifyCategory(TransactionCategory category) {
    if (widget.onEditCategoryEditorRequested != null) {
      widget.onEditCategoryEditorRequested!(category);
      return;
    }
    setState(() {
      _editingCategory = category;
      _categoryEditorOpen = true;
    });
  }
```

In `ExptShell._buildTransactionHomePage`, pass:

```dart
      onEditCategoryEditorRequested: (category) {
        _sheetHostKey.currentState?.openCategory(initialCategory: category);
      },
```

Update `_CategorySheetSlot.open` to accept `TransactionCategory? initialCategory`, store it, and pass it to `CategoryEditorSheet`. Do not call `_categorySlotKey.currentState?.close()` when opening edit category from the category menu; only close transaction, recurring, and budget sheets.

- [ ] **Step 6: Implement editor slot and preview surfaces**

Add surface parameters to `CategoryEditorSheet` and `CategoryEditorPanel`:

```dart
  final Color surfaceColor;
  final ExpenseSurfaceInteraction bodySurfaceStyle;
  final ExpenseSurfaceInteraction buttonSurfaceStyle;
  final ExpenseSurfaceInteraction selectedSurfaceStyle;
```

Default normal values are `AppColors.white` and `neutralNeutral`. In shell, pass `expenseTheme.logBox`, `expenseTheme.contentSurfaceStyle`, `expenseTheme.buttonSurfaceStyle`, and `expenseTheme.forcedInsetSurfaceStyle`.

Update `CategorySlotGrid` constructors to accept:

```dart
    this.surfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
    this.selectedSurfaceStyle = ExpenseSurfaceInteraction.neutralNeutral,
```

In `_ColorSlot` and `_IconSlot`, use `ExpenseSurfaceContainer` when `surfaceStyle.hasPressEffect || selectedSurfaceStyle.hasPressEffect`; selected slots use `selectedSurfaceStyle`, unselected slots use `surfaceStyle`. Keep the old border selected UI only when both styles are `neutralNeutral`.

Update `CategoryPreviewPill` to wrap the body and avatar in surface containers with keys:

```dart
const ValueKey('category-preview-pill-surface')
const ValueKey('category-preview-avatar-surface')
```

- [ ] **Step 7: Run tests**

Run:

```bash
flutter test test/transactions/category_menu_test.dart test/transactions/category_editor_test.dart
```

Expected: PASS.

- [ ] **Step 8: Commit**

Run:

```bash
git add lib/features/shell/expt_shell.dart lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/category_menu/category_menu_overlay.dart lib/features/transactions/widgets/category_menu/category_menu_panel.dart lib/features/transactions/widgets/category_menu/category_card.dart lib/features/transactions/widgets/category_menu/category_icon_badge.dart lib/features/transactions/widgets/category_menu/category_editor_sheet.dart lib/features/transactions/widgets/category_menu/category_editor_panel.dart lib/features/transactions/widgets/category_menu/category_slot_grid.dart lib/features/transactions/widgets/category_menu/category_preview_pill.dart test/transactions/category_menu_test.dart test/transactions/category_editor_test.dart
git commit -m "feat: theme category neumorphism flows"
```

---

### Task 7: Pink And Night Primary Color Rollout

**Files:**
- Modify: `lib/core/theme/app_colors.dart`
- Modify: `lib/features/security/security_gate.dart`
- Modify: `lib/features/stats/stats_page.dart`
- Modify: `lib/features/notifications/notifications_page.dart`
- Modify: `lib/features/notifications/widgets/notification_log_box.dart`
- Modify: `lib/features/notifications/widgets/notification_month_header.dart`
- Modify: files already touched in Tasks 3-6 where `AppColors.primary` still controls app-level highlight.
- Test: `test/settings/expense_theme_test.dart`
- Test: `test/widget_test.dart`
- Test: `test/notifications/notification_widgets_test.dart`

- [ ] **Step 1: Add failing primary rollout test**

Append to `test/settings/expense_theme_test.dart`:

```dart
  test('accent helpers resolve active background for all palettes', () {
    final turquoise = ExpenseTheme.fromSettings(AppThemeSettings.defaults());
    final pink = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(appColor: AppColorMode.pink),
    );
    final cyan = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(nightMode: AppNightMode.cyan),
    );
    final amber = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(nightMode: AppNightMode.amber),
    );

    expect(turquoise.resolvePrimary(AppColors.primary), AppColors.primary);
    expect(pink.resolvePrimary(AppColors.primary), pink.accent);
    expect(cyan.resolvePrimary(AppColors.primary), cyan.accent);
    expect(amber.resolvePrimary(AppColors.primary), amber.accent);
    expect(pink.resolvePrimary(AppColors.primaryActiveBackground), pink.activeBackground);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/settings/expense_theme_test.dart
```

Expected: FAIL because `resolvePrimary` is missing.

- [ ] **Step 3: Add primary resolver**

In `ExpenseTheme`, add:

```dart
  Color resolvePrimary(Color color) {
    if (color == AppColors.primary) return accent;
    if (color == AppColors.primaryDark) return accentDark;
    if (color == AppColors.primaryLight) return accentLight;
    if (color == AppColors.primaryActiveBackground) return activeBackground;
    return color;
  }
```

- [ ] **Step 4: Replace app-level primary references in touched UI**

Run:

```bash
rg -n "AppColors\\.primary|primaryDark|primaryLight|primaryActiveBackground" lib/features lib/core/theme/app_colors.dart
```

For every reference in these files, replace app-level usage with the local `ExpenseTheme` token or `expenseTheme.resolvePrimary(...)`:

```text
lib/features/security/security_gate.dart
lib/features/stats/stats_page.dart
lib/features/notifications/notifications_page.dart
lib/features/notifications/widgets/notification_log_box.dart
lib/features/notifications/widgets/notification_month_header.dart
lib/features/settings/widgets/options/theme_options_panel.dart
lib/features/shell/widgets/expt_fab.dart
lib/features/shell/widgets/bottom_nav_item.dart
lib/features/transactions/transaction_home_page.dart
lib/features/transactions/widgets/search_pill.dart
lib/features/transactions/widgets/summary_pill.dart
lib/features/transactions/widgets/transaction_type_pills.dart
lib/features/transactions/widgets/add_transaction_sheet.dart
lib/features/transactions/widgets/recurring_manager_sheet.dart
lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart
lib/features/transactions/widgets/category_menu/category_editor_panel.dart
lib/features/transactions/widgets/category_menu/category_menu_panel.dart
```

Do not replace:

```text
AppColors.income
AppColors.expense
CategoryColorManager.color(...)
category.slotColor
AppColors.fromHex(...)
```

- [ ] **Step 5: Run focused tests**

Run:

```bash
flutter test test/settings/expense_theme_test.dart test/widget_test.dart test/notifications/notification_widgets_test.dart
```

Expected: PASS. If existing snapshots or text expectations still use turquoise for normal day mode, keep turquoise expectations for default settings and add pink/night-specific expectations only where the test injects those settings.

- [ ] **Step 6: Commit**

Run:

```bash
git add lib/core/theme/app_colors.dart lib/features/security/security_gate.dart lib/features/stats/stats_page.dart lib/features/notifications/notifications_page.dart lib/features/notifications/widgets/notification_log_box.dart lib/features/notifications/widgets/notification_month_header.dart lib/features/settings/widgets/options/theme_options_panel.dart lib/features/shell/widgets/expt_fab.dart lib/features/shell/widgets/bottom_nav_item.dart lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/search_pill.dart lib/features/transactions/widgets/summary_pill.dart lib/features/transactions/widgets/transaction_type_pills.dart lib/features/transactions/widgets/add_transaction_sheet.dart lib/features/transactions/widgets/recurring_manager_sheet.dart lib/features/transactions/widgets/header_card/budget_target_editor_sheet.dart lib/features/transactions/widgets/category_menu/category_editor_panel.dart lib/features/transactions/widgets/category_menu/category_menu_panel.dart test/settings/expense_theme_test.dart test/widget_test.dart test/notifications/notification_widgets_test.dart
git commit -m "feat: roll out pink and night primary tokens"
```

---

### Task 8: Backheader Bars And Final Surface Coverage

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Modify: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_progress_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_summary_outline_bar.dart`
- Test: `test/transactions/category_budget_stage_test.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] **Step 1: Add failing backheader surface test**

Append to `test/transactions/category_budget_stage_test.dart`:

```dart
  testWidgets('backheader colored bars use raised surfaces in neumorphism', (
    tester,
  ) async {
    final bars = [barFixture(6, 'Food', 100, 150)];
    await tester.pumpWidget(
      MaterialApp(
        home: SizedBox(
          width: 390,
          height: 300,
          child: CategoryBudgetStage(
            items: bars.map(BackheaderBudgetItem.category).toList(),
            categoryBars: bars,
            periodLabel: 'Június',
            activeKey: null,
            surfaceStyle: ExpenseSurfaceInteraction.raisedInset,
            onActiveItemChanged: (_) {},
            onItemTap: (_) {},
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('backheader-bar-surface-0')), findsOneWidget);
  });
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart --plain-name "backheader colored bars use raised surfaces in neumorphism"
```

Expected: FAIL because `CategoryBudgetStage.surfaceStyle` and keyed bar surfaces do not exist.

- [ ] **Step 3: Thread surface style into backheader bars**

Add `surfaceStyle` to `CategoryBudgetStage`, pass it from `TransactionHomePage`:

```dart
surfaceStyle: expenseTheme.buttonSurfaceStyle,
```

In the colored bar widget that paints each tappable/swipable bar, wrap the colored segment in:

```dart
ExpensePressable(
  enabled: surfaceStyle.hasPressEffect,
  builder: (context, pressed) {
    return ExpenseSurfaceContainer(
      surfaceKey: ValueKey('backheader-bar-surface-$index'),
      style: surfaceStyle,
      color: bar.color,
      primary: true,
      primaryColor: bar.color,
      borderRadius: BorderRadius.circular(999),
      pressed: pressed,
      child: existingBarChild,
    );
  },
)
```

Keep existing swipe/tap callbacks and budget calculations unchanged.

- [ ] **Step 4: Run tests**

Run:

```bash
flutter test test/transactions/category_budget_stage_test.dart test/transactions/header_layout_test.dart
```

Expected: PASS.

- [ ] **Step 5: Commit**

Run:

```bash
git add lib/features/transactions/widgets/header_card/category_budget_stage.dart lib/features/transactions/widgets/header_card/backheader_style_surface.dart lib/features/transactions/widgets/header_card/category_budget_bar.dart lib/features/transactions/widgets/header_card/category_progress_bar.dart lib/features/transactions/widgets/header_card/category_summary_outline_bar.dart test/transactions/category_budget_stage_test.dart test/transactions/header_layout_test.dart
git commit -m "feat: theme backheader bar surfaces"
```

---

### Task 9: Final Verification, Branch Push, And APK Link

**Files:**
- No source edits expected unless tests expose a regression.

- [ ] **Step 1: Run full Flutter test suite**

Run:

```bash
flutter test
```

Expected: PASS. If this environment hits a known Flutter/Termux runtime issue unrelated to tests, capture the exact error and still run the focused suites from Tasks 1-8.

- [ ] **Step 2: Run Android unit tests**

Run:

```bash
./gradlew :app:testDebugUnitTest
```

Expected: PASS.

- [ ] **Step 3: Confirm no local APK build was run**

Do not run:

```bash
flutter build apk
```

Reason: local Flutter APK builds are not expected to work in this Termux Android ARM64 environment.

- [ ] **Step 4: Inspect status**

Run:

```bash
git status --short --branch
```

Expected: clean working tree on `feature/neumorphism-night-theme`, ahead of remote.

- [ ] **Step 5: Push implementation branch**

Run:

```bash
git push -u origin feature/neumorphism-night-theme
```

Expected: branch pushed to GitHub.

- [ ] **Step 6: Trigger or locate GitHub Actions build**

Run:

```bash
gh run list --branch feature/neumorphism-night-theme --limit 5
```

Expected: a workflow run appears for the pushed branch. If no run appears, use the existing repo workflow trigger command shown by `gh workflow list` and `gh workflow run <workflow-name> --ref feature/neumorphism-night-theme`.

- [ ] **Step 7: Wait for online APK build and produce download link**

Run:

```bash
gh run watch --exit-status
gh run view --json url,conclusion,artifacts
```

Expected: conclusion is `success`. Provide the workflow URL and direct APK artifact or release download link produced by the repo workflow.

---

## Self-Review Checklist

- Settings model and Kotlin persistence are covered by Task 1.
- Night cyan and night amber palette resolution are covered by Task 2.
- Theme menu profile/night/app color UI is covered by Task 3.
- Normal versus neumorphism no-double-trigger behavior is covered by Tasks 2 and 4.
- Home screen log/search/summary/type/header/FAB/bottom nav fanout is covered by Task 4.
- Add/edit transaction, recurring, and limit input/save surfaces are covered by Task 5.
- Category menu, editor sheet layering, slots, and preview are covered by Task 6.
- Pink and night primary rollout is covered by Task 7.
- Backheader colored bar surfaces are covered by Task 8.
- Verification, branch push, online build, and APK link are covered by Task 9.
