# Backheader Style Selector Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add a global Settings -> Backheader selector that switches the transaction home backheader between the current bar system and experimental A-F layouts while preserving tap, swipe, long-press, active dots, and editor synchronization.

**Architecture:** Store the selected style in the existing `AppThemeSettings` payload and Android SharedPreferences path, because the shell already loads and propagates that settings object. Keep `CategoryBudgetStage` as the state/gesture owner, and make classic plus A-F renderers presentational so visual experiments do not fork the active-item state machine.

**Tech Stack:** Flutter, Dart widget tests, Android Kotlin SharedPreferences, existing MethodChannel settings bridge.

---

## File Structure

- Modify `lib/features/settings/models/app_theme_settings.dart`: add `BackheaderStyle`, default/fallback parsing, `toMap`, and `copyWith` support.
- Modify `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`: persist `backheaderStyle` in the existing theme settings map.
- Modify `lib/features/settings/settings_page.dart`: add a `Backheader` root menu item and submenu route under display settings.
- Create `lib/features/settings/widgets/options/backheader_style_options_panel.dart`: radio-list settings UI for `classic` plus A-F.
- Create `lib/features/settings/widgets/options/backheader_style_preview.dart`: compact previews for settings radio rows.
- Modify `lib/features/shell/expt_shell.dart`: no new state field; continue applying `AppThemeSettings`, which now includes `backheaderStyle`.
- Modify `lib/features/transactions/widgets/header_card/category_budget_stage.dart`: accept a `backheaderStyle` parameter and route rendering.
- Create `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`: presentational A-F surfaces and shared dots/partition helpers.
- Test `test/settings/settings_bridge_test.dart`: settings bridge model/native payload behavior.
- Test `test/settings/backheader_style_options_panel_test.dart`: direct Backheader panel behavior.
- Test `test/widget_test.dart`: settings menu integration and MethodChannel payload from real app shell.
- Test `test/transactions/category_budget_stage_test.dart`: style rendering and preserved interactions.

---

### Task 1: Settings Model and Native Persistence

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Test: `test/settings/settings_bridge_test.dart`

- [ ] **Step 1: Write failing bridge/model tests**

In `test/settings/settings_bridge_test.dart`, update the mocked `themeSettings` map in `expenseLoadSettings` to include:

```dart
'backheaderStyle': 'partitionDashboard',
```

In the test `loads app theme and FastInfo settings`, add:

```dart
expect(settings.themeSettings.backheaderStyle, BackheaderStyle.partitionDashboard);
```

In the test `updates theme settings through native bridge`, update the `AppThemeSettings` constructor:

```dart
const AppThemeSettings(
  magnetType: MagnetType.adaptive,
  cardColor: AppCardColor.darkgray,
  theme: AppTheme.turquoise,
  backgroundColor: AppBackgroundColor.white,
  boxColor: AppBoxColor.gray,
  backheaderStyle: BackheaderStyle.orbitBudget,
)
```

Then add this payload assertion:

```dart
expect(payload['backheaderStyle'], 'orbitBudget');
```

Add this new unit test after the update test:

```dart
test('backheader style defaults to classic for missing or unknown values', () {
  expect(
    AppThemeSettings.fromMap(const <String, Object?>{}).backheaderStyle,
    BackheaderStyle.classic,
  );
  expect(
    AppThemeSettings.fromMap(const <String, Object?>{
      'backheaderStyle': 'not-a-style',
    }).backheaderStyle,
    BackheaderStyle.classic,
  );
});
```

- [ ] **Step 2: Run the settings bridge test and verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/settings_bridge_test.dart'
```

Expected: FAIL with errors that `BackheaderStyle` and `backheaderStyle` do not exist.

- [ ] **Step 3: Implement `BackheaderStyle` in Dart settings model**

In `lib/features/settings/models/app_theme_settings.dart`, add this enum after `MagnetType`:

```dart
enum BackheaderStyle {
  classic('classic'),
  colorFieldPartition('colorFieldPartition'),
  partitionDashboard('partitionDashboard'),
  heroToken('heroToken'),
  orbitBudget('orbitBudget'),
  mosaicBudget('mosaicBudget'),
  ledgerStrip('ledgerStrip');

  const BackheaderStyle(this.nativeValue);
  final String nativeValue;

  static BackheaderStyle fromAny(Object? value) {
    final raw = value?.toString();
    return BackheaderStyle.values.firstWhere(
      (item) => item.nativeValue == raw,
      orElse: () => BackheaderStyle.classic,
    );
  }

  String get displayTitle => switch (this) {
    BackheaderStyle.classic => 'Jelenlegi bar rendszer',
    BackheaderStyle.colorFieldPartition => 'A - Color Field Partition',
    BackheaderStyle.partitionDashboard => 'B - Partition Dashboard',
    BackheaderStyle.heroToken => 'C - Hero Token',
    BackheaderStyle.orbitBudget => 'D - Orbit Budget',
    BackheaderStyle.mosaicBudget => 'E - Mosaic Budget',
    BackheaderStyle.ledgerStrip => 'F - Ledger Strip',
  };

  String get description => switch (this) {
    BackheaderStyle.classic => 'A mostani kategória/overview bar rendszer',
    BackheaderStyle.colorFieldPartition => 'Kategóriaszínű felület közös partition strippel',
    BackheaderStyle.partitionDashboard => 'Sötét budget map partition blokkokkal',
    BackheaderStyle.heroToken => 'Nagy aktív kategória token mini partitionnel',
    BackheaderStyle.orbitBudget => 'Kategóriaszínű orbit/ring budget nézet',
    BackheaderStyle.mosaicBudget => 'Treemap jellegű budget mosaic',
    BackheaderStyle.ledgerStrip => 'Pénzügyi segment strip aktív labellel',
  };
}
```

Update the `AppThemeSettings` constructor, defaults, fields, `fromMap`, `toMap`, and `copyWith`:

```dart
class AppThemeSettings {
  const AppThemeSettings({
    required this.magnetType,
    required this.cardColor,
    required this.theme,
    required this.backgroundColor,
    required this.boxColor,
    required this.backheaderStyle,
  });

  factory AppThemeSettings.defaults() {
    return const AppThemeSettings(
      magnetType: MagnetType.fade,
      cardColor: AppCardColor.lightgray,
      theme: AppTheme.turquoise,
      backgroundColor: AppBackgroundColor.gray,
      boxColor: AppBoxColor.gray,
      backheaderStyle: BackheaderStyle.classic,
    );
  }

  factory AppThemeSettings.fromMap(Map<dynamic, dynamic> map) {
    return AppThemeSettings(
      magnetType: MagnetType.fromAny(map['magnetType']),
      cardColor: AppCardColor.fromAny(map['cardColor']),
      theme: AppTheme.fromAny(map['theme']),
      backgroundColor: AppBackgroundColor.fromAny(map['backgroundColor']),
      boxColor: AppBoxColor.fromAny(map['boxColor']),
      backheaderStyle: BackheaderStyle.fromAny(map['backheaderStyle']),
    );
  }

  final MagnetType magnetType;
  final AppCardColor cardColor;
  final AppTheme theme;
  final AppBackgroundColor backgroundColor;
  final AppBoxColor boxColor;
  final BackheaderStyle backheaderStyle;

  Map<String, Object?> toMap() {
    return <String, Object?>{
      'magnetType': magnetType.nativeValue,
      'cardColor': cardColor.nativeValue,
      'theme': theme.nativeValue,
      'backgroundColor': backgroundColor.nativeValue,
      'boxColor': boxColor.nativeValue,
      'backheaderStyle': backheaderStyle.nativeValue,
    };
  }

  AppThemeSettings copyWith({
    MagnetType? magnetType,
    AppCardColor? cardColor,
    AppTheme? theme,
    AppBackgroundColor? backgroundColor,
    AppBoxColor? boxColor,
    BackheaderStyle? backheaderStyle,
  }) {
    return AppThemeSettings(
      magnetType: magnetType ?? this.magnetType,
      cardColor: cardColor ?? this.cardColor,
      theme: theme ?? this.theme,
      backgroundColor: backgroundColor ?? this.backgroundColor,
      boxColor: boxColor ?? this.boxColor,
      backheaderStyle: backheaderStyle ?? this.backheaderStyle,
    );
  }
}
```

- [ ] **Step 4: Persist the value in Android settings store**

In `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`, add `backheaderStyle` to `loadThemeSettings()`:

```kotlin
"backheaderStyle" to prefs.getString(KEY_BACKHEADER_STYLE, "classic"),
```

Add it to `updateThemeSettings(args)` before `.apply()`:

```kotlin
.putString(KEY_BACKHEADER_STYLE, args["backheaderStyle"]?.toString() ?: "classic")
```

Add the key in the companion object:

```kotlin
private const val KEY_BACKHEADER_STYLE = "backheaderStyle"
```

- [ ] **Step 5: Run the settings bridge test and commit**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/settings_bridge_test.dart'
```

Expected: PASS.

Commit:

```bash
git add lib/features/settings/models/app_theme_settings.dart android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt test/settings/settings_bridge_test.dart
git commit -m "Add backheader style setting model"
```

---

### Task 2: Backheader Settings Menu and Previews

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Create: `lib/features/settings/widgets/options/backheader_style_options_panel.dart`
- Create: `lib/features/settings/widgets/options/backheader_style_preview.dart`
- Test: `test/settings/backheader_style_options_panel_test.dart`
- Test: `test/widget_test.dart`

- [ ] **Step 1: Write failing direct panel tests**

Create `test/settings/backheader_style_options_panel_test.dart`:

```dart
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/widgets/options/backheader_style_options_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('backheader style panel lists classic and experimental styles', (tester) async {
    var settings = AppThemeSettings.defaults();
    await tester.pumpWidget(
      MaterialApp(
        home: BackheaderStyleOptionsPanel(
          settings: settings,
          onChanged: (next) => settings = next,
        ),
      ),
    );

    expect(find.text('Jelenlegi bar rendszer (jelenlegi)'), findsOneWidget);
    expect(find.text('A - Color Field Partition'), findsOneWidget);
    expect(find.text('B - Partition Dashboard'), findsOneWidget);
    expect(find.text('C - Hero Token'), findsOneWidget);
    expect(find.text('D - Orbit Budget'), findsOneWidget);
    expect(find.text('E - Mosaic Budget'), findsOneWidget);
    expect(find.text('F - Ledger Strip'), findsOneWidget);
    expect(find.byKey(const ValueKey('backheader-style-preview-classic')), findsOneWidget);
    expect(find.byKey(const ValueKey('backheader-style-preview-ledgerStrip')), findsOneWidget);
  });

  testWidgets('backheader style panel updates selected style', (tester) async {
    AppThemeSettings? updated;
    await tester.pumpWidget(
      MaterialApp(
        home: BackheaderStyleOptionsPanel(
          settings: AppThemeSettings.defaults(),
          onChanged: (next) => updated = next,
        ),
      ),
    );

    await tester.tap(find.text('D - Orbit Budget'));
    await tester.pump();

    expect(updated?.backheaderStyle, BackheaderStyle.orbitBudget);
  });
}
```

- [ ] **Step 2: Write failing app integration test**

In `test/widget_test.dart`, add this global list near the other saved payload lists:

```dart
final updatedThemeSettings = <Map<dynamic, dynamic>>[];
```

In `setUp`, clear it:

```dart
updatedThemeSettings.clear();
```

In the MethodChannel handler, include `backheaderStyle` in the `expenseLoadSettings` theme map:

```dart
'backheaderStyle': 'classic',
```

Add this handler before `return null`:

```dart
if (call.method == 'expenseUpdateThemeSettings') {
  final payload = Map<dynamic, dynamic>.from(
    call.arguments as Map<dynamic, dynamic>,
  );
  updatedThemeSettings.add(payload);
  return payload;
}
```

Add this widget test after the existing settings test:

```dart
testWidgets('settings contains Backheader style selector', (tester) async {
  await tester.pumpWidget(buildApp());
  await tester.pumpAndSettle();

  await tester.tap(find.text('Beállítások'));
  await tester.pumpAndSettle();

  expect(find.text('Backheader'), findsOneWidget);
  await tester.tap(find.text('Backheader'));
  await tester.pumpAndSettle();

  expect(find.text('Jelenlegi bar rendszer (jelenlegi)'), findsOneWidget);
  expect(find.text('A - Color Field Partition'), findsOneWidget);
  expect(find.text('F - Ledger Strip'), findsOneWidget);

  await tester.tap(find.text('E - Mosaic Budget'));
  await tester.pumpAndSettle();

  expect(updatedThemeSettings.single['backheaderStyle'], 'mosaicBudget');
});
```

- [ ] **Step 3: Run tests and verify failures**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/backheader_style_options_panel_test.dart test/widget_test.dart --plain-name Backheader'
```

Expected: FAIL because `BackheaderStyleOptionsPanel` does not exist and Settings has no Backheader menu.

- [ ] **Step 4: Create the preview widget**

Create `lib/features/settings/widgets/options/backheader_style_preview.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/app_theme_settings.dart';

class BackheaderStylePreview extends StatelessWidget {
  const BackheaderStylePreview({super.key, required this.style});

  final BackheaderStyle style;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      key: ValueKey('backheader-style-preview-${style.nativeValue}'),
      width: 76,
      height: 44,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: _background,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.gray200),
        ),
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: _content(),
        ),
      ),
    );
  }

  Color get _background {
    return switch (style) {
      BackheaderStyle.partitionDashboard => const Color(0xFF111827),
      BackheaderStyle.colorFieldPartition || BackheaderStyle.orbitBudget => const Color(0xFF22C55E),
      BackheaderStyle.ledgerStrip => const Color(0xFF0F766E),
      _ => AppColors.gray100,
    };
  }

  Widget _content() {
    return switch (style) {
      BackheaderStyle.heroToken => Row(
        children: [
          const CircleAvatar(radius: 13, backgroundColor: Color(0xFF22C55E)),
          const SizedBox(width: 5),
          Expanded(child: _miniStrip()),
        ],
      ),
      BackheaderStyle.orbitBudget => Center(
        child: Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.white, width: 5),
          ),
        ),
      ),
      BackheaderStyle.mosaicBudget => Wrap(
        spacing: 4,
        runSpacing: 4,
        children: const [
          _Tile(width: 30, color: Color(0xFF22C55E)),
          _Tile(width: 18, color: Color(0xFFF59E0B)),
          _Tile(width: 22, color: Color(0xFFEF4444)),
          _Tile(width: 42, color: Color(0xFF3B82F6)),
        ],
      ),
      BackheaderStyle.ledgerStrip => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_miniStrip(), const SizedBox(height: 5), _line(AppColors.white)],
      ),
      _ => Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [_line(_foreground), const SizedBox(height: 6), _miniStrip()],
      ),
    };
  }

  Color get _foreground => style == BackheaderStyle.partitionDashboard ? AppColors.white : AppColors.gray800;

  Widget _line(Color color) => Container(width: 44, height: 5, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)));

  Widget _miniStrip() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(7),
      child: Row(
        children: const [
          Expanded(flex: 3, child: ColoredBox(color: Color(0xFF22C55E))),
          Expanded(flex: 2, child: ColoredBox(color: Color(0xFFF59E0B))),
          Expanded(flex: 2, child: ColoredBox(color: Color(0xFFEF4444))),
          Expanded(flex: 3, child: ColoredBox(color: Color(0xFF3B82F6))),
        ],
      ),
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({required this.width, required this.color});
  final double width;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(width: width, height: 11, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)));
  }
}
```

- [ ] **Step 5: Create the Backheader options panel**

Create `lib/features/settings/widgets/options/backheader_style_options_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/app_theme_settings.dart';
import 'backheader_style_preview.dart';
import 'settings_option_widgets.dart';

class BackheaderStyleOptionsPanel extends StatelessWidget {
  const BackheaderStyleOptionsPanel({
    super.key,
    required this.settings,
    required this.onChanged,
  });

  final AppThemeSettings settings;
  final ValueChanged<AppThemeSettings> onChanged;

  @override
  Widget build(BuildContext context) {
    return ListView(
      key: const ValueKey('settings-backheader-style-scroll'),
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        for (final style in BackheaderStyle.values)
          SettingsRadioOption(
            title: '${style.displayTitle}${settings.backheaderStyle == style ? ' (jelenlegi)' : ''}',
            description: style.description,
            selected: settings.backheaderStyle == style,
            onTap: () => onChanged(settings.copyWith(backheaderStyle: style)),
            preview: BackheaderStylePreview(style: style),
          ),
      ],
    );
  }
}
```

- [ ] **Step 6: Add the Settings page route**

In `lib/features/settings/settings_page.dart`, import the new panel:

```dart
import 'widgets/options/backheader_style_options_panel.dart';
```

Add enum value:

```dart
backheader,
```

Under `Megjelenítési beállítások`, insert between `Nyelv` and `Téma`:

```dart
SettingsOptionItem(
  title: 'Backheader',
  onTap: () => _open(_SettingsMenu.backheader),
),
```

Remove `isLast: true` from `Nyelv` if it was moved onto the wrong item, and keep `isLast: true` on `Téma`.

In `_submenuBody`, add:

```dart
_SettingsMenu.backheader => BackheaderStyleOptionsPanel(
  settings: _settingsStore.themeSettings,
  onChanged: _updateThemeSettings,
),
```

In `_menuTitle`, add:

```dart
_SettingsMenu.backheader => 'Backheader',
```

- [ ] **Step 7: Run tests and commit**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/backheader_style_options_panel_test.dart test/widget_test.dart --plain-name Backheader'
```

Expected: PASS.

Commit:

```bash
git add lib/features/settings/settings_page.dart lib/features/settings/widgets/options/backheader_style_options_panel.dart lib/features/settings/widgets/options/backheader_style_preview.dart test/settings/backheader_style_options_panel_test.dart test/widget_test.dart
git commit -m "Add backheader style settings menu"
```

---

### Task 3: Route Style Into CategoryBudgetStage

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Write failing stage parameter tests**

In `test/transactions/category_budget_stage_test.dart`, add `AppThemeSettings` import:

```dart
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
```

Add this test near the existing `category budget stage shows labels and swipes category bars` test:

```dart
testWidgets('classic backheader style keeps current bar renderer', (tester) async {
  final bars = [barFixture(6, 'Food', 100, 150)];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            backheaderStyle: BackheaderStyle.classic,
            items: bars.map(BackheaderBudgetItem.category).toList(),
            categoryBars: bars,
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );

  expect(find.byKey(const ValueKey('category-budget-bar')), findsOneWidget);
  expect(find.byKey(const ValueKey('backheader-experimental-surface')), findsNothing);
});
```

Add this test after it:

```dart
testWidgets('experimental backheader style uses experimental surface', (tester) async {
  BackheaderBudgetItem? tapped;
  final bars = [barFixture(6, 'Food', 100, 150)];
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            backheaderStyle: BackheaderStyle.colorFieldPartition,
            items: bars.map(BackheaderBudgetItem.category).toList(),
            categoryBars: bars,
            onItemTap: (item) => tapped = item,
          ),
        ),
      ),
    ),
  );

  expect(find.byKey(const ValueKey('backheader-experimental-surface')), findsOneWidget);
  expect(find.byKey(const ValueKey('backheader-style-colorFieldPartition')), findsOneWidget);
  expect(find.byKey(const ValueKey('category-budget-bar')), findsNothing);

  await tester.tap(find.byKey(const ValueKey('backheader-experimental-surface')));
  expect(tapped?.category?.title, 'Food');
});
```

- [ ] **Step 2: Run the category stage test and verify it fails**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name backheader'
```

Expected: FAIL because `backheaderStyle` parameter and experimental surface do not exist.

- [ ] **Step 3: Add `backheaderStyle` to `CategoryBudgetStage`**

In `lib/features/transactions/widgets/header_card/category_budget_stage.dart`, import settings model:

```dart
import '../../../settings/models/app_theme_settings.dart';
```

Add constructor parameter and field:

```dart
this.backheaderStyle = BackheaderStyle.classic,
```

```dart
final BackheaderStyle backheaderStyle;
```

In `build`, route rendering after `frameProgress` is computed:

```dart
if (widget.backheaderStyle != BackheaderStyle.classic) {
  return _buildExperimentalStage(
    current: current,
    items: items,
    frameProgress: frameProgress,
    frameOverview: frameOverview,
  );
}
```

Add a temporary private method in the same file so tests pass before the full renderer task:

```dart
Widget _buildExperimentalStage({
  required BackheaderBudgetItem current,
  required List<BackheaderBudgetItem> items,
  required BudgetProgressData? frameProgress,
  required OverviewBudgetData? frameOverview,
}) {
  return SizedBox(
    key: const ValueKey('category-budget-stage'),
    height: TransactionHeaderMetrics.cardHeight,
    width: double.infinity,
    child: Stack(
      children: [
        Positioned.fill(
          child: GestureDetector(
            key: const ValueKey('backheader-experimental-surface'),
            behavior: HitTestBehavior.opaque,
            onTap: () => _tap(current),
            onHorizontalDragStart: (_) {
              _slideController.stop();
              _settling = false;
            },
            onHorizontalDragUpdate: (details) {
              if (_settling) return;
              final nextDx = (_dragDx + details.delta.dx)
                  .clamp(-_maxVisualDrag, _maxVisualDrag)
                  .toDouble();
              setState(() => _dragDx = nextDx);
            },
            onHorizontalDragCancel: () => _animateDragTo(0),
            onHorizontalDragEnd: (_) => _settleDrag(),
            onLongPress: _jumpToOverviewForCurrent,
            child: DecoratedBox(
              key: ValueKey('backheader-style-${widget.backheaderStyle.nativeValue}'),
              decoration: const BoxDecoration(
                color: AppColors.gray100,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
              child: Center(child: Text(current.title)),
            ),
          ),
        ),
      ],
    ),
  );
}
```

This temporary method is replaced by Task 4.

- [ ] **Step 4: Pass style from transaction home**

In `lib/features/transactions/transaction_home_page.dart`, update the `CategoryBudgetStage` construction:

```dart
backheaderStyle: expenseTheme.settings.backheaderStyle,
```

Place it alongside `items`, `categoryBars`, and `periodLabel`.

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name backheader'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart test/transactions/category_budget_stage_test.dart
git commit -m "Route backheader style to stage"
```

---

### Task 4: Functional A-F Backheader Renderers

**Files:**
- Create: `lib/features/transactions/widgets/header_card/backheader_style_surface.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Write failing tests for all experimental styles and gestures**

In `test/transactions/category_budget_stage_test.dart`, add this test:

```dart
testWidgets('experimental backheader styles render distinct surfaces', (tester) async {
  final bars = [barFixture(6, 'Food', 100, 150)];
  for (final style in BackheaderStyle.values.where((style) => style != BackheaderStyle.classic)) {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 260,
            child: CategoryBudgetStage(
              backheaderStyle: style,
              items: bars.map(BackheaderBudgetItem.category).toList(),
              categoryBars: bars,
              onItemTap: (_) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(ValueKey('backheader-style-${style.nativeValue}')), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('100 Ft / 150 Ft'), findsOneWidget);
  }
});
```

Add this gesture test:

```dart
testWidgets('experimental backheader preserves swipe and long press behavior', (tester) async {
  BackheaderBudgetItem? activeItem;
  final food = barFixture(6, 'Food', 100, 150);
  final travel = barFixture(7, 'Travel', 40, 0);
  final overview = BackheaderBudgetItem.overview(
    overviewFixture(BudgetGoalKind.expenseBudget, 100, 300),
  );

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 390,
          height: 260,
          child: CategoryBudgetStage(
            backheaderStyle: BackheaderStyle.mosaicBudget,
            items: [overview, BackheaderBudgetItem.category(food), BackheaderBudgetItem.category(travel)],
            categoryBars: [food, travel],
            activeKey: BackheaderBudgetItem.category(food).key,
            onActiveItemChanged: (item) => activeItem = item,
            onItemTap: (_) {},
          ),
        ),
      ),
    ),
  );

  await tester.drag(find.byKey(const ValueKey('backheader-experimental-surface')), const Offset(-180, 0));
  await tester.pumpAndSettle();
  expect(activeItem?.category?.title, 'Travel');

  await tester.longPress(find.byKey(const ValueKey('backheader-experimental-surface')));
  await tester.pumpAndSettle();
  expect(activeItem?.overview?.kind, BudgetGoalKind.expenseBudget);
});
```

- [ ] **Step 2: Run tests and verify failures**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name experimental'
```

Expected: FAIL because all experimental styles still render the temporary same surface.

- [ ] **Step 3: Create presentational renderer file**

Create `lib/features/transactions/widgets/header_card/backheader_style_surface.dart` with this complete content:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';
import '../../models/backheader_budget_item.dart';
import '../../models/budget_progress_segment.dart';
import '../../models/category_budget_bar_data.dart';
import '../../models/overview_budget_data.dart';

class BackheaderStyleSurface extends StatelessWidget {
  const BackheaderStyleSurface({
    super.key,
    required this.style,
    required this.current,
    required this.items,
    required this.categoryBars,
    required this.frameProgress,
    required this.frameOverview,
    required this.activeIndex,
  });

  final BackheaderStyle style;
  final BackheaderBudgetItem current;
  final List<BackheaderBudgetItem> items;
  final List<CategoryBudgetBarData> categoryBars;
  final BudgetProgressData? frameProgress;
  final OverviewBudgetData? frameOverview;
  final int activeIndex;

  @override
  Widget build(BuildContext context) {
    final color = current.category?.color ?? _overviewColor;
    final amountText = current.amountText;
    final segments = _segmentColors;
    return DecoratedBox(
      key: ValueKey('backheader-style-${style.nativeValue}'),
      decoration: BoxDecoration(
        color: _background(color),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Stack(
        children: [
          switch (style) {
            BackheaderStyle.colorFieldPartition => _ColorField(
              current: current,
              amountText: amountText,
              color: color,
              segments: segments,
            ),
            BackheaderStyle.partitionDashboard => _PartitionDashboard(
              current: current,
              amountText: amountText,
              segments: segments,
            ),
            BackheaderStyle.heroToken => _HeroToken(
              current: current,
              amountText: amountText,
              color: color,
              segments: segments,
            ),
            BackheaderStyle.orbitBudget => _OrbitBudget(
              current: current,
              amountText: amountText,
              color: color,
              segments: segments,
            ),
            BackheaderStyle.mosaicBudget => _MosaicBudget(
              current: current,
              amountText: amountText,
              segments: segments,
            ),
            BackheaderStyle.ledgerStrip => _LedgerStrip(
              current: current,
              amountText: amountText,
              segments: segments,
            ),
            BackheaderStyle.classic => const SizedBox.shrink(),
          },
          if (items.length > 1)
            Positioned(
              left: 0,
              right: 0,
              bottom: 18,
              child: _Dots(
                count: items.length,
                activeIndex: activeIndex,
                onDark: _usesLightDots,
              ),
            ),
        ],
      ),
    );
  }

  Color get _overviewColor => switch (current.overview?.kind.name) {
    'incomeGoal' => AppColors.income,
    'savingGoal' => const Color(0xFF3B82F6),
    _ => AppColors.primary,
  };

  bool get _usesLightDots => style == BackheaderStyle.partitionDashboard ||
      style == BackheaderStyle.colorFieldPartition ||
      style == BackheaderStyle.orbitBudget ||
      style == BackheaderStyle.ledgerStrip;

  Color _background(Color color) => switch (style) {
    BackheaderStyle.colorFieldPartition || BackheaderStyle.orbitBudget => color,
    BackheaderStyle.partitionDashboard => const Color(0xFF111827),
    BackheaderStyle.ledgerStrip => const Color(0xFF0F766E),
    _ => AppColors.gray100,
  };

  List<Color> get _segmentColors {
    final colors = <Color>[for (final bar in categoryBars) bar.color];
    if (colors.isEmpty) {
      return const [
        AppColors.primary,
        Color(0xFFF59E0B),
        Color(0xFFEF4444),
        Color(0xFF3B82F6),
      ];
    }
    return colors.take(6).toList();
  }
}

class _ColorField extends StatelessWidget {
  const _ColorField({
    required this.current,
    required this.amountText,
    required this.color,
    required this.segments,
  });

  final BackheaderBudgetItem current;
  final String amountText;
  final Color color;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-colorFieldPartition-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _Avatar(color: AppColors.white.withValues(alpha: 0.18), textColor: AppColors.white, title: current.title),
              const SizedBox(width: 12),
              Expanded(child: _TitleBlock(title: current.title, subtitle: 'AKTÍV KATEGÓRIA', light: true)),
              _AmountBlock(amountText: amountText, light: true),
            ],
          ),
          const SizedBox(height: 24),
          const Text('Közös budget partition', style: TextStyle(color: Color(0xCCFFFFFF), fontSize: 12, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          _PartitionStrip(colors: segments, height: 28, activeColor: color),
        ],
      ),
    );
  }
}

class _PartitionDashboard extends StatelessWidget {
  const _PartitionDashboard({required this.current, required this.amountText, required this.segments});
  final BackheaderBudgetItem current;
  final String amountText;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-partitionDashboard-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _TitleBlock(title: current.title, subtitle: 'BUDGET MAP', light: true)),
              _AmountBlock(amountText: amountText, light: true, secondary: 'maradék fókusz'),
            ],
          ),
          const SizedBox(height: 20),
          DecoratedBox(
            decoration: BoxDecoration(color: const Color(0xFF1F2937), borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: _PartitionStrip(colors: segments, height: 44, activeColor: AppColors.white),
            ),
          ),
        ],
      ),
    );
  }
}

class _HeroToken extends StatelessWidget {
  const _HeroToken({required this.current, required this.amountText, required this.color, required this.segments});
  final BackheaderBudgetItem current;
  final String amountText;
  final Color color;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-heroToken-content'),
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 0),
      child: Column(
        children: [
          Row(
            children: [
              _Token(color: color, title: current.title),
              const SizedBox(width: 18),
              Expanded(child: _TitleBlock(title: current.title, subtitle: 'CATEGORY TOKEN')),
              _AmountBlock(amountText: amountText),
            ],
          ),
          const SizedBox(height: 16),
          _PartitionStrip(colors: segments, height: 16, activeColor: color),
        ],
      ),
    );
  }
}

class _OrbitBudget extends StatelessWidget {
  const _OrbitBudget({required this.current, required this.amountText, required this.color, required this.segments});
  final BackheaderBudgetItem current;
  final String amountText;
  final Color color;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-orbitBudget-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Row(
        children: [
          Expanded(child: _TitleBlock(title: current.title, subtitle: amountText, light: true)),
          SizedBox(
            width: 96,
            height: 96,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(size: const Size.square(86), painter: _OrbitPainter(segments)),
                _Avatar(color: AppColors.white.withValues(alpha: 0.18), textColor: AppColors.white, title: current.title),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MosaicBudget extends StatelessWidget {
  const _MosaicBudget({required this.current, required this.amountText, required this.segments});
  final BackheaderBudgetItem current;
  final String amountText;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-mosaicBudget-content'),
      padding: const EdgeInsets.fromLTRB(30, 28, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _TitleBlock(title: current.title, subtitle: 'PARTITION MOSAIC')),
              _AmountBlock(amountText: amountText),
            ],
          ),
          const SizedBox(height: 14),
          _MosaicTiles(colors: segments, title: current.title),
        ],
      ),
    );
  }
}

class _LedgerStrip extends StatelessWidget {
  const _LedgerStrip({required this.current, required this.amountText, required this.segments});
  final BackheaderBudgetItem current;
  final String amountText;
  final List<Color> segments;

  @override
  Widget build(BuildContext context) {
    return Padding(
      key: const ValueKey('backheader-style-ledgerStrip-content'),
      padding: const EdgeInsets.fromLTRB(30, 34, 30, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(child: _TitleBlock(title: current.title, subtitle: 'LEDGER STRIP', light: true)),
              _AmountBlock(amountText: amountText, light: true),
            ],
          ),
          const SizedBox(height: 26),
          _PartitionStrip(colors: segments, height: 22, activeColor: AppColors.white),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: DecoratedBox(
              decoration: BoxDecoration(color: AppColors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.white.withValues(alpha: 0.44))),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                child: Text('${_initial(current.title)} active', style: const TextStyle(color: AppColors.white, fontSize: 10, fontWeight: FontWeight.w800)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.title, required this.subtitle, this.light = false});
  final String title;
  final String subtitle;
  final bool light;

  @override
  Widget build(BuildContext context) {
    final titleColor = light ? AppColors.white : AppColors.gray800;
    final subColor = light ? AppColors.white.withValues(alpha: 0.72) : AppColors.gray600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: subColor, fontSize: 10, fontWeight: FontWeight.w800)),
        const SizedBox(height: 4),
        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: titleColor, fontSize: 21, fontWeight: FontWeight.w800)),
      ],
    );
  }
}

class _AmountBlock extends StatelessWidget {
  const _AmountBlock({required this.amountText, this.light = false, this.secondary});
  final String amountText;
  final bool light;
  final String? secondary;

  @override
  Widget build(BuildContext context) {
    final color = light ? AppColors.white : AppColors.gray800;
    final subColor = light ? AppColors.white.withValues(alpha: 0.70) : AppColors.gray600;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(amountText, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(color: color, fontSize: 13, fontWeight: FontWeight.w800)),
        if (secondary != null) ...[
          const SizedBox(height: 3),
          Text(secondary!, maxLines: 1, overflow: TextOverflow.ellipsis, textAlign: TextAlign.right, style: TextStyle(color: subColor, fontSize: 10)),
        ],
      ],
    );
  }
}

class _Avatar extends StatelessWidget {
  const _Avatar({required this.color, required this.textColor, required this.title});
  final Color color;
  final Color textColor;
  final String title;

  @override
  Widget build(BuildContext context) {
    return CircleAvatar(
      radius: 20,
      backgroundColor: color,
      child: Text(_initial(title), style: TextStyle(color: textColor, fontWeight: FontWeight.w900)),
    );
  }
}

class _Token extends StatelessWidget {
  const _Token({required this.color, required this.title});
  final Color color;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      height: 70,
      child: DecoratedBox(
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Center(child: Text(_initial(title), style: const TextStyle(color: AppColors.white, fontSize: 20, fontWeight: FontWeight.w900))),
      ),
    );
  }
}

class _PartitionStrip extends StatelessWidget {
  const _PartitionStrip({required this.colors, required this.activeColor, this.height = 24});
  final List<Color> colors;
  final Color activeColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            for (var i = 0; i < colors.length; i += 1)
              Expanded(
                flex: i == 0 ? 3 : 2,
                child: ColoredBox(color: i == 0 ? activeColor : colors[i]),
              ),
          ],
        ),
      ),
    );
  }
}

class _MosaicTiles extends StatelessWidget {
  const _MosaicTiles({required this.colors, required this.title});
  final List<Color> colors;
  final String title;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 78,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          return Stack(
            children: [
              _tile(0, 0, width * 0.42, 48, colors[0], title: _initial(title), active: true),
              _tile(width * 0.45, 0, width * 0.23, 48, colors.length > 1 ? colors[1] : const Color(0xFFF59E0B)),
              _tile(width * 0.71, 0, width * 0.29, 48, colors.length > 2 ? colors[2] : const Color(0xFFEF4444)),
              _tile(0, 56, width * 0.30, 22, colors.length > 3 ? colors[3] : const Color(0xFF3B82F6)),
              _tile(width * 0.34, 56, width * 0.24, 22, colors.length > 4 ? colors[4] : const Color(0xFFA855F7)),
              _tile(width * 0.62, 56, width * 0.38, 22, AppColors.gray300),
            ],
          );
        },
      ),
    );
  }

  Widget _tile(double x, double y, double width, double height, Color color, {String? title, bool active = false}) {
    return Positioned(
      left: x,
      top: y,
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(14),
          border: active ? Border.all(color: AppColors.white, width: 3) : null,
        ),
        child: title == null ? const SizedBox.shrink() : Center(child: Text(title, style: const TextStyle(color: AppColors.white, fontSize: 18, fontWeight: FontWeight.w900))),
      ),
    );
  }
}

class _Dots extends StatelessWidget {
  const _Dots({required this.count, required this.activeIndex, required this.onDark});
  final int count;
  final int activeIndex;
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < count; i += 1)
          Container(
            key: ValueKey('category-budget-dot-$i'),
            width: 6,
            height: 6,
            margin: const EdgeInsets.symmetric(horizontal: 3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i == activeIndex
                  ? (onDark ? AppColors.white : AppColors.primary)
                  : (onDark ? AppColors.white.withValues(alpha: 0.45) : AppColors.white),
            ),
          ),
      ],
    );
  }
}

class _OrbitPainter extends CustomPainter {
  const _OrbitPainter(this.colors);
  final List<Color> colors;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final base = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..color = AppColors.white.withValues(alpha: 0.22);
    canvas.drawArc(rect.deflate(8), 0, math.pi * 2, false, base);

    var start = -math.pi / 2;
    final sweep = (math.pi * 2) / colors.length;
    for (final color in colors) {
      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 12
        ..strokeCap = StrokeCap.round
        ..color = color == colors.first ? AppColors.white : color;
      canvas.drawArc(rect.deflate(8), start, sweep * 0.78, false, paint);
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitPainter oldDelegate) => oldDelegate.colors != colors;
}

String _initial(String title) {
  final trimmed = title.trim();
  if (trimmed.isEmpty) return '?';
  return trimmed.substring(0, 1).toUpperCase();
}
```

- [ ] **Step 4: Replace temporary experimental stage with renderer**

In `category_budget_stage.dart`, import:

```dart
import 'backheader_style_surface.dart';
```

Replace the temporary `DecoratedBox` child in `_buildExperimentalStage` with:

```dart
BackheaderStyleSurface(
  style: widget.backheaderStyle,
  current: current,
  items: items,
  categoryBars: _categoryBars,
  frameProgress: frameProgress,
  frameOverview: frameOverview,
  activeIndex: _index,
)
```

- [ ] **Step 5: Run tests and commit**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/category_budget_stage_test.dart --plain-name experimental'
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/header_card/backheader_style_surface.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart test/transactions/category_budget_stage_test.dart
git commit -m "Add experimental backheader style surfaces"
```

---

### Task 5: Full Verification and Cleanup

**Files:**
- Verify all changed files from Tasks 1-4
- Do not add `.superpowers/` to the commit

- [ ] **Step 1: Run targeted tests**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/settings_bridge_test.dart test/settings/backheader_style_options_panel_test.dart test/widget_test.dart --plain-name Backheader test/transactions/category_budget_stage_test.dart'
```

Expected: PASS.

- [ ] **Step 2: Run analyzer**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`

- [ ] **Step 3: Run full test suite**

Run:

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all tests pass.

- [ ] **Step 4: Check git state**

Run:

```bash
git status --short --branch
git diff --check
```

Expected: only `.superpowers/` may remain untracked from brainstorming; no unstaged implementation files; `git diff --check` exits cleanly.

- [ ] **Step 5: Final commit if verification required a cleanup change**

If analyzer or full tests required cleanup, commit that cleanup:

```bash
git add <changed implementation/test files>
git commit -m "Polish backheader style selector"
```

Expected: no commit is needed if Tasks 1-4 already passed analyzer and full tests.
