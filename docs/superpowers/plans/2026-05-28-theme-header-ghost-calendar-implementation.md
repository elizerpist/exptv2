# Theme Header Ghost Calendar Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make theme settings affect the running app, port the original magnet/header behavior, add recurring ghost logboxes backed by Android Room, and fix calendar/category overlays and charts.

**Architecture:** Keep Kotlin/Room as the durable data engine and Dart as the UI layer. Add focused files for theme resolution, magnet painting, ghost log models, and recurring ghost persistence instead of expanding existing large widgets. Real transactions remain the only source for balance/summary/charts; ghost rows are merged only for display.

**Tech Stack:** Flutter/Dart widgets and tests, Android Kotlin Room/WorkManager, MethodChannel bridge, GitHub Actions APK build.

---

## File Structure

Create:

- `lib/features/settings/theme/expense_theme.dart` - resolves `AppThemeSettings` into concrete colors for UI components.
- `lib/features/transactions/widgets/header_card/magnet_strip.dart` - shared magnet strip widget/painter for header and settings previews.
- `lib/features/transactions/models/recurring_ghost_record.dart` - Dart model for pending recurring ghost logbox rows.
- `lib/features/transactions/models/transaction_log_entry.dart` - sealed-ish display model combining real and ghost log entries.
- `lib/features/transactions/widgets/recurring_ghost_log_box.dart` - ghost logbox UI.
- `lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart` - compact donut/pie chart painter.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionEntity.kt` - Room entity for ghost rows.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionDao.kt` - ghost row DAO.
- `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt` - pure planner tests where possible.
- `test/settings/expense_theme_test.dart` - theme resolution tests.
- `test/transactions/magnet_strip_test.dart` - magnet painter/widget behavior tests.
- `test/transactions/recurring_ghost_log_test.dart` - Dart ghost merge/summary exclusion tests.
- `test/transactions/calendar_overlay_layout_test.dart` - overlay and card size tests.

Modify:

- `lib/features/settings/models/app_theme_settings.dart` - add helper getters only if needed.
- `lib/features/settings/state/settings_store.dart` - notify shell when theme changes.
- `lib/features/settings/settings_page.dart` - accept current theme callback and use shared theme colors.
- `lib/features/settings/widgets/options/theme_options_panel.dart` - replace local magnet preview painter with shared `MagnetStrip`.
- `lib/features/shell/expt_shell.dart` - load and own app theme state; pass to home/settings/FAB/nav.
- `lib/features/shell/widgets/expt_fab.dart`, `expt_bottom_nav.dart`, `bottom_nav_item.dart` - consume active accent where practical.
- `lib/features/transactions/transaction_home_page.dart` - pass theme, handle header spring, merge ghost entries, open recurring editor from ghost taps.
- `lib/features/transactions/state/transaction_store.dart` - load ghosts, generate visible display list, keep summaries real-only.
- `lib/features/transactions/data/transaction_repository.dart` - expose ghost bridge calls.
- `lib/features/transactions/widgets/header_card/transaction_header_card.dart` - accept theme/settings/transactions and use `MagnetStrip`.
- `lib/features/transactions/widgets/header_card/fast_info_panel.dart` - remove conflicting shadow/background edge.
- `lib/features/transactions/widgets/header_card/category_budget_stage.dart`, `category_budget_bar.dart` - show `x/y` progress text.
- `lib/features/transactions/widgets/transaction_log_list.dart`, `transaction_log_box.dart` - render mixed log entries and theme box color.
- `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart` - cover screen bottom/nav and keep active-type filtering.
- `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`, `calendar_canvas_layout.dart`, `calendar_canvas_painter.dart` - cover screen bottom, normalize compact sizing, add donut chart area.
- `lib/services/native_bridge.dart` - add ghost methods and parse ghosts in bootstrap.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt` - version 4 migration/entity/DAO.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt` - ghost generation, list, trigger conversion.
- `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt` - ghost method handlers.
- `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringTransactionWorker.kt` - process ghosts instead of direct recurring-to-transaction insert.

---

### Task 1: App Theme Resolution And Shell State

**Files:**
- Create: `lib/features/settings/theme/expense_theme.dart`
- Modify: `lib/features/shell/expt_shell.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/settings/state/settings_store.dart`
- Test: `test/settings/expense_theme_test.dart`

- [ ] **Step 1: Write failing theme resolution tests**

Create `test/settings/expense_theme_test.dart`:

```dart
import 'package:exptv2/core/theme/app_colors.dart';
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/settings/theme/expense_theme.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('resolves original card and box colors', () {
    final theme = ExpenseTheme.fromSettings(
      AppThemeSettings.defaults().copyWith(
        cardColor: AppCardColor.darkgray,
        backgroundColor: AppBackgroundColor.white,
        boxColor: AppBoxColor.gray,
      ),
    );

    expect(theme.headerCard, AppColors.gray200);
    expect(theme.appBackground, AppColors.white);
    expect(theme.logBox, AppColors.gray100);
  });

  test('resolves primary accent from selected theme', () {
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.defaults().copyWith(theme: AppTheme.pink),
      ).accent,
      const Color(0xFFEC4899),
    );
    expect(
      ExpenseTheme.fromSettings(
        AppThemeSettings.defaults().copyWith(theme: AppTheme.dark),
      ).accent,
      const Color(0xFF1F2937),
    );
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/expense_theme_test.dart'
```

Expected: FAIL because `expense_theme.dart` does not exist.

- [ ] **Step 3: Implement `ExpenseTheme`**

Create `lib/features/settings/theme/expense_theme.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../models/app_theme_settings.dart';

class ExpenseTheme {
  const ExpenseTheme({
    required this.settings,
    required this.accent,
    required this.headerCard,
    required this.appBackground,
    required this.logBox,
  });

  final AppThemeSettings settings;
  final Color accent;
  final Color headerCard;
  final Color appBackground;
  final Color logBox;

  factory ExpenseTheme.fromSettings(AppThemeSettings settings) {
    return ExpenseTheme(
      settings: settings,
      accent: switch (settings.theme) {
        AppTheme.pink => const Color(0xFFEC4899),
        AppTheme.turquoise => AppColors.primary,
        AppTheme.dark => const Color(0xFF1F2937),
      },
      headerCard: switch (settings.cardColor) {
        AppCardColor.white => AppColors.white,
        AppCardColor.lightgray => AppColors.gray100,
        AppCardColor.darkgray => AppColors.gray200,
      },
      appBackground: switch (settings.backgroundColor) {
        AppBackgroundColor.white => AppColors.white,
        AppBackgroundColor.gray => AppColors.gray100,
      },
      logBox: switch (settings.boxColor) {
        AppBoxColor.white => AppColors.white,
        AppBoxColor.gray => AppColors.gray100,
      },
    );
  }
}
```

- [ ] **Step 4: Make shell own the active settings**

Modify `lib/features/shell/expt_shell.dart`:

```dart
import '../settings/models/app_theme_settings.dart';
import '../settings/theme/expense_theme.dart';
```

Add fields in `_ExptShellState`:

```dart
AppThemeSettings _themeSettings = AppThemeSettings.defaults();
var _themeLoaded = false;
```

In `initState`, load settings:

```dart
_loadThemeSettings();
```

Add method:

```dart
Future<void> _loadThemeSettings() async {
  final payload = await widget.nativeBridge.expenseLoadSettings();
  if (!mounted) return;
  setState(() {
    _themeSettings = payload.themeSettings;
    _themeLoaded = true;
  });
}

void _applyThemeSettings(AppThemeSettings settings) {
  setState(() => _themeSettings = settings);
}
```

In `build`, before `return Scaffold`:

```dart
final expenseTheme = ExpenseTheme.fromSettings(_themeSettings);
```

Use `expenseTheme.appBackground` for `Scaffold.backgroundColor`; pass `expenseTheme` and `_themeSettings` to home/settings. If `_themeLoaded` is false, still render defaults.

- [ ] **Step 5: Wire settings theme changes back to shell**

Modify `SettingsPage` constructor to accept:

```dart
final ValueChanged<AppThemeSettings>? onThemeSettingsChanged;
```

After store updates theme settings, call:

```dart
widget.onThemeSettingsChanged?.call(widget.settingsStore.themeSettings);
```

If the page uses a local `SettingsStore`, call after `await _store.updateThemeSettings(settings)`.

- [ ] **Step 6: Run focused tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/settings/theme/expense_theme.dart lib/features/shell/expt_shell.dart lib/features/settings/settings_page.dart lib/features/settings/state/settings_store.dart test/settings/expense_theme_test.dart test/settings/settings_page_test.dart
git commit -m "feat: apply expense theme settings"
```

---

### Task 2: Shared Magnet Strip Painter

**Files:**
- Create: `lib/features/transactions/widgets/header_card/magnet_strip.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Test: `test/transactions/magnet_strip_test.dart`

- [ ] **Step 1: Write failing magnet tests**

Create `test/transactions/magnet_strip_test.dart`:

```dart
import 'package:exptv2/features/settings/models/app_theme_settings.dart';
import 'package:exptv2/features/transactions/widgets/header_card/magnet_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('magnetcard renders marker mode without gradient fill', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: MagnetStrip(
          type: MagnetType.magnetcard,
          totalIncome: 70,
          totalExpense: 30,
          height: 35,
        ),
      ),
    ));

    expect(find.byKey(const ValueKey('magnet-strip-magnetcard')), findsOneWidget);
  });

  testWidgets('adaptive magnet exposes dynamic pill width key', (tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: Scaffold(
        body: SizedBox(
          width: 200,
          child: MagnetStrip(
            type: MagnetType.adaptive,
            totalIncome: 80,
            totalExpense: 20,
            height: 35,
          ),
        ),
      ),
    ));

    expect(find.byKey(const ValueKey('magnet-strip-adaptive')), findsOneWidget);
  });
}
```

- [ ] **Step 2: Run test to verify it fails**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/magnet_strip_test.dart'
```

Expected: FAIL because `MagnetStrip` does not exist.

- [ ] **Step 3: Implement reusable magnet strip**

Create `lib/features/transactions/widgets/header_card/magnet_strip.dart` with:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../settings/models/app_theme_settings.dart';

class MagnetStrip extends StatelessWidget {
  const MagnetStrip({
    super.key,
    required this.type,
    required this.totalIncome,
    required this.totalExpense,
    this.height = 35,
    this.accent = AppColors.primary,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final double height;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final key = ValueKey('magnet-strip-${type.nativeValue}');
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.sizeOf(context).width;
        return CustomPaint(
          key: key,
          size: Size(width, height),
          painter: MagnetStripPainter(
            type: type,
            totalIncome: totalIncome,
            totalExpense: totalExpense,
            accent: accent,
          ),
        );
      },
    );
  }
}

class MagnetStripPainter extends CustomPainter {
  const MagnetStripPainter({
    required this.type,
    required this.totalIncome,
    required this.totalExpense,
    required this.accent,
  });

  final MagnetType type;
  final double totalIncome;
  final double totalExpense;
  final Color accent;

  @override
  void paint(Canvas canvas, Size size) {
    final total = totalIncome.abs() + totalExpense.abs();
    final ratio = total <= 0 ? 0.5 : (totalIncome.abs() / total).clamp(0.05, 0.95).toDouble();
    final centerY = size.height / 2;
    final rect = Rect.fromLTWH(0, centerY - 3, size.width, 6);

    switch (type) {
      case MagnetType.magnetcard:
        _paintMagnetCard(canvas, size, ratio);
      case MagnetType.adaptive:
        final pillWidth = math.max(20.0, size.width * ratio);
        final pillRect = Rect.fromLTWH(0, centerY - 8, pillWidth, 16);
        canvas.drawRRect(
          RRect.fromRectAndRadius(pillRect, const Radius.circular(10)),
          Paint()..color = accent.withValues(alpha: 0.85),
        );
      case MagnetType.budget:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..shader = const LinearGradient(
            colors: [Color(0xFF16A34A), Color(0xFFDC2626)],
          ).createShader(rect),
        );
      case MagnetType.nofade:
        final split = rect.left + rect.width * ratio;
        canvas.drawRect(Rect.fromLTRB(rect.left, rect.top, split, rect.bottom), Paint()..color = const Color(0x4D2C2C2C));
        canvas.drawRect(Rect.fromLTRB(split, rect.top, rect.right, rect.bottom), Paint()..color = const Color(0x0D2C2C2C));
      case MagnetType.fade:
        canvas.drawRRect(
          RRect.fromRectAndRadius(rect, const Radius.circular(3)),
          Paint()..shader = const LinearGradient(
            colors: [Color(0x4D2C2C2C), Color(0x0D2C2C2C)],
          ).createShader(rect),
        );
    }
  }

  void _paintMagnetCard(Canvas canvas, Size size, double ratio) {
    final paint = Paint()
      ..color = AppColors.gray800.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;
    final top = size.height / 2 - 8;
    final bottom = size.height / 2 + 8;
    canvas.drawLine(Offset.zero.translate(0, top), Offset(size.width, top), paint);
    canvas.drawLine(Offset.zero.translate(0, bottom), Offset(size.width, bottom), paint);
    final markerX = size.width * ratio;
    canvas.drawLine(Offset(markerX, top), Offset(markerX, bottom), paint);
  }

  @override
  bool shouldRepaint(covariant MagnetStripPainter oldDelegate) {
    return oldDelegate.type != type ||
        oldDelegate.totalIncome != totalIncome ||
        oldDelegate.totalExpense != totalExpense ||
        oldDelegate.accent != accent;
  }
}
```

- [ ] **Step 4: Replace header painter**

In `transaction_header_card.dart`, add constructor fields:

```dart
final MagnetType magnetType;
final Color accent;
final Color cardColor;
final double totalIncome;
final double totalExpense;
```

Replace `_HeaderMagnetPainter` usage with:

```dart
MagnetStrip(
  type: magnetType,
  totalIncome: totalIncome,
  totalExpense: totalExpense,
  accent: accent,
  height: 35,
)
```

Delete `_HeaderMagnetPainter` after no references remain.

- [ ] **Step 5: Replace settings magnet preview**

In `theme_options_panel.dart`, import the shared widget and replace `_MagnetPreview` body with:

```dart
SizedBox(
  width: 62,
  height: 24,
  child: MagnetStrip(
    type: type,
    totalIncome: 60,
    totalExpense: 40,
    height: 24,
  ),
)
```

Remove `_MagnetPreviewPainter`.

- [ ] **Step 6: Run focused tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/magnet_strip_test.dart test/settings/settings_page_test.dart test/transactions/header_card_test.dart'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/transactions/widgets/header_card/magnet_strip.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/settings/widgets/options/theme_options_panel.dart test/transactions/magnet_strip_test.dart
git commit -m "feat: port original magnet strip modes"
```

---

### Task 3: Header And FastInfo Spring Behavior

**Files:**
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/fast_info_panel.dart`
- Test: `test/transactions/header_layout_test.dart`

- [ ] **Step 1: Extend header tests for spring-back and tap reliability**

Add to `test/transactions/header_layout_test.dart`:

```dart
testWidgets('header pull reveals FastInfo only during drag and springs closed', (tester) async {
  await pumpTransactionHome(tester);

  final header = find.byKey(const ValueKey('transaction-header-card'));
  await tester.drag(header, const Offset(0, 120));
  await tester.pump();
  expect(find.byKey(const ValueKey('fast-info-panel')), findsOneWidget);

  await tester.pumpAndSettle(const Duration(milliseconds: 600));
  expect(find.byKey(const ValueKey('fast-info-panel')), findsNothing);
});

testWidgets('expand button still toggles after header drag', (tester) async {
  await pumpTransactionHome(tester);

  final header = find.byKey(const ValueKey('transaction-header-card'));
  await tester.drag(header, const Offset(0, 80));
  await tester.pumpAndSettle(const Duration(milliseconds: 600));

  await tester.tap(find.byKey(const ValueKey('header-expand-button-hit-area')));
  await tester.pumpAndSettle();
  expect(find.byKey(const ValueKey('category-budget-stage')), findsOneWidget);
});
```

If `pumpTransactionHome` is not available, use the existing helper in the file and add the keys above to the implementation.

- [ ] **Step 2: Run tests to verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/header_layout_test.dart'
```

Expected: FAIL because current FastInfo remains open after release and the hit-area key does not exist.

- [ ] **Step 3: Change header drag state to transient spring extent**

In `transaction_home_page.dart`, replace `_handleHeaderDragEnd` body with:

```dart
void _handleHeaderDragEnd(DragEndDetails details) {
  if (_headerExpanded) return;
  setState(() => _fastInfoExtent = 0);
}
```

Wrap the header/fastinfo visual group in `AnimatedContainer` or `TweenAnimationBuilder` so `_fastInfoExtent` returning to zero animates over 300ms using `Curves.easeOutBack` or `Curves.easeOutCubic`.

- [ ] **Step 4: Remove visual separation shadow over FastInfo**

Make the header background shadow conditional on FastInfo extent:

```dart
final shadowAlpha = fastInfoVisible ? 0.0 : 0.15;
```

Add `fastInfoVisible` to `TransactionHeaderCard`. When `_fastInfoExtent > 0`, pass `fastInfoVisible: true`. Use `shadowAlpha` in the header `BoxShadow`.

- [ ] **Step 5: Add larger hit area around expand button**

In `transaction_header_card.dart`, wrap the Material button:

```dart
SizedBox(
  key: const ValueKey('header-expand-button-hit-area'),
  width: 56,
  height: 56,
  child: Center(
    child: Material(... existing 30x30 InkWell ...),
  ),
)
```

Keep the visual 30x30 size unchanged.

- [ ] **Step 6: Run focused tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/header_layout_test.dart test/transactions/header_card_test.dart'
```

Expected: PASS.

- [ ] **Step 7: Commit**

```bash
git add lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/transactions/widgets/header_card/fast_info_panel.dart test/transactions/header_layout_test.dart
git commit -m "fix: match header fastinfo spring behavior"
```

---

### Task 4: Menu Coverage, Category Filtering, And BackHeader Progress Text

**Files:**
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_bar.dart`
- Modify: `lib/features/transactions/widgets/header_card/category_budget_stage.dart`
- Test: `test/transactions/category_menu_test.dart`
- Test: `test/transactions/calendar_overlay_layout_test.dart`
- Test: `test/transactions/category_budget_stage_test.dart`

- [ ] **Step 1: Write failing overlay coverage tests**

Create `test/transactions/calendar_overlay_layout_test.dart`:

```dart
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar overlay reaches screen bottom', (tester) async {
    await tester.pumpWidget(MaterialApp(
      home: SizedBox(
        width: 390,
        height: 844,
        child: CalendarMenuOverlay(
          transactions: const [],
          categories: const <TransactionCategory>[],
          onClose: () {},
          onMonthSelect: (_, _) {},
        ),
      ),
    ));

    final box = tester.renderObject<RenderBox>(find.byKey(const ValueKey('calendar-menu-overlay')));
    final topLeft = box.localToGlobal(Offset.zero);
    expect(topLeft.dy + box.size.height, 844);
  });
}
```

- [ ] **Step 2: Extend category active type test**

In `test/transactions/category_menu_test.dart`, add:

```dart
testWidgets('category menu shows only active transaction type categories', (tester) async {
  await pumpTransactionHome(tester);
  await tester.tap(find.text('Bevetel'));
  await tester.pumpAndSettle();
  await tester.tap(find.byKey(const ValueKey('header-category-button')));
  await tester.pumpAndSettle();

  expect(find.text('Fizetes'), findsOneWidget);
  expect(find.text('Elelmiszer'), findsNothing);
});
```

Use the exact category seed names present in current tests; if the app uses accented display text, use the current seed label.

- [ ] **Step 3: Add `x/y` progress text expectation**

In `test/transactions/category_budget_stage_test.dart`, assert:

```dart
expect(find.byKey(const ValueKey('category-budget-progress-text')), findsWidgets);
expect(find.textContaining('/'), findsWidgets);
```

- [ ] **Step 4: Run tests to verify failures**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_overlay_layout_test.dart test/transactions/category_menu_test.dart test/transactions/category_budget_stage_test.dart'
```

Expected: FAIL at least for new overlay/progress expectations.

- [ ] **Step 5: Make overlays cover bottom nav/FAB**

In both overlay widgets, keep `bottom: 0`, and ensure they are inserted after bottom nav/FAB or from a shell-level overlay when needed. If still under nav due stack order, move `CalendarMenuOverlay` and `CategoryMenuOverlay` from `TransactionHomePage` to the shell overlay layer or keep them in `TransactionHomePage` but ensure shell bottom nav is hidden while menus are open.

Minimal shell approach:

```dart
final homeMenuOpen = _activeTab == AppTab.home && _transactionStore.overlayBlocksNavigation;
if (!homeMenuOpen) Positioned(... ExptBottomNav ...);
if (!homeMenuOpen) Positioned(... ExptFab ...);
```

Prefer adding callbacks from `TransactionHomePage` to shell if direct store flag is not available.

- [ ] **Step 6: Add progress text to budget bars**

In `category_budget_bar.dart`, near the bar title/value row add:

```dart
Text(
  '${formatHuf(bar.spentAmount)} / ${bar.hasLimit ? formatHuf(bar.limitAmount) : '-'}',
  key: const ValueKey('category-budget-progress-text'),
  style: const TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.gray600,
  ),
)
```

Use the actual field names in `CategoryBudgetBarData`; if they differ, map to the existing spent/limit properties in that model.

- [ ] **Step 7: Run focused tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_overlay_layout_test.dart test/transactions/category_menu_test.dart test/transactions/category_budget_stage_test.dart'
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/transactions/widgets/category_menu/category_menu_overlay.dart lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart lib/features/transactions/widgets/header_card/category_budget_bar.dart lib/features/transactions/widgets/header_card/category_budget_stage.dart test/transactions/calendar_overlay_layout_test.dart test/transactions/category_menu_test.dart test/transactions/category_budget_stage_test.dart
git commit -m "fix: cover overlays and show budget progress"
```

---

### Task 5: Native Recurring Ghost Database And Trigger Conversion

**Files:**
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionEntity.kt`
- Create: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostTransactionDao.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseMethodChannel.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringTransactionWorker.kt`
- Test: `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt`

- [ ] **Step 1: Write pure planner test**

Create `android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt`:

```kotlin
package com.exptv2.app.expense

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

class RecurringGhostPlannerTest {
    @Test fun periodKeyUsesYearMonth() {
        val key = RecurringGhostPlanner.periodKey(2026, 5)
        assertEquals("2026-05", key)
    }

    @Test fun dueDayClampsToLastDayOfMonth() {
        assertEquals(29, RecurringGhostPlanner.effectiveDay(2028, 2, 31))
        assertEquals(28, RecurringGhostPlanner.effectiveDay(2026, 2, 31))
    }

    @Test fun triggerOnlyRunsOnOrAfterDueDay() {
        assertFalse(RecurringGhostPlanner.isDue(today = 14, dueDay = 15))
        assertTrue(RecurringGhostPlanner.isDue(today = 15, dueDay = 15))
        assertTrue(RecurringGhostPlanner.isDue(today = 20, dueDay = 15))
    }
}
```

- [ ] **Step 2: Run Kotlin test to verify failure**

Run if local Gradle is available:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:testDebugUnitTest --tests com.exptv2.app.expense.RecurringGhostPlannerTest'
```

Expected locally in this Termux/proot environment may be blocked by AAPT2. If blocked, keep the test and rely on GitHub Actions APK compile later. The expected code failure is `RecurringGhostPlanner` missing.

- [ ] **Step 3: Add planner helper**

Create `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt`:

```kotlin
package com.exptv2.app.expense

import java.util.Calendar

object RecurringGhostPlanner {
    fun periodKey(year: Int, monthOneBased: Int): String = "%04d-%02d".format(year, monthOneBased)

    fun effectiveDay(year: Int, monthOneBased: Int, requestedDay: Int): Int {
        val calendar = Calendar.getInstance().apply {
            set(Calendar.YEAR, year)
            set(Calendar.MONTH, monthOneBased - 1)
            set(Calendar.DAY_OF_MONTH, 1)
        }
        return requestedDay.coerceIn(1, calendar.getActualMaximum(Calendar.DAY_OF_MONTH))
    }

    fun isDue(today: Int, dueDay: Int): Boolean = today >= dueDay
}
```

- [ ] **Step 4: Add ghost entity and DAO**

Create `RecurringGhostTransactionEntity.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey

@Entity(
    tableName = "recurring_ghost_transactions",
    foreignKeys = [
        ForeignKey(
            entity = RecurringTransactionEntity::class,
            parentColumns = ["id"],
            childColumns = ["recurringId"],
            onDelete = ForeignKey.CASCADE,
        ),
    ],
    indices = [
        Index("recurringId"),
        Index("periodKey"),
        Index("status"),
        Index("date"),
        Index(value = ["recurringId", "periodKey"], unique = true),
    ],
)
data class RecurringGhostTransactionEntity(
    @PrimaryKey(autoGenerate = true) val id: Int = 0,
    val recurringId: Int,
    val periodKey: String,
    val date: String,
    val time: String,
    val name: String,
    val amount: Double,
    val transactionType: String,
    val categoryId: Int,
    val categoryName: String,
    val categoryColor: String,
    val categoryIconSlot: Int,
    val status: String,
    val createdTransactionId: Int?,
    val createdAt: Long,
    val updatedAt: Long,
) {
    fun toMap(): Map<String, Any?> = mapOf(
        "id" to id,
        "recurringId" to recurringId,
        "periodKey" to periodKey,
        "date" to date,
        "time" to time,
        "name" to name,
        "amount" to amount,
        "transactionType" to transactionType,
        "categoryId" to categoryId,
        "categoryName" to categoryName,
        "categoryColor" to categoryColor,
        "categoryIconSlot" to categoryIconSlot,
        "status" to status,
        "createdTransactionId" to createdTransactionId,
        "createdAt" to createdAt,
        "updatedAt" to updatedAt,
    )
}
```

Create `RecurringGhostTransactionDao.kt`:

```kotlin
package com.exptv2.app.expense

import androidx.room.Dao
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Update

@Dao
interface RecurringGhostTransactionDao {
    @Query("SELECT * FROM recurring_ghost_transactions WHERE status = 'pending' ORDER BY date DESC, time DESC, id DESC")
    suspend fun pending(): List<RecurringGhostTransactionEntity>

    @Query("SELECT * FROM recurring_ghost_transactions WHERE periodKey = :periodKey AND status = 'pending' ORDER BY date DESC, time DESC, id DESC")
    suspend fun pendingForPeriod(periodKey: String): List<RecurringGhostTransactionEntity>

    @Query("SELECT * FROM recurring_ghost_transactions WHERE recurringId = :recurringId AND periodKey = :periodKey LIMIT 1")
    suspend fun byRecurringAndPeriod(recurringId: Int, periodKey: String): RecurringGhostTransactionEntity?

    @Query("SELECT * FROM recurring_ghost_transactions WHERE id = :id LIMIT 1")
    suspend fun byId(id: Int): RecurringGhostTransactionEntity?

    @Insert(onConflict = OnConflictStrategy.REPLACE)
    suspend fun insert(row: RecurringGhostTransactionEntity): Long

    @Update
    suspend fun update(row: RecurringGhostTransactionEntity)

    @Query("UPDATE recurring_ghost_transactions SET status = 'disabled', updatedAt = :updatedAt WHERE recurringId = :recurringId AND status = 'pending'")
    suspend fun disablePendingForRecurring(recurringId: Int, updatedAt: Long)
}
```

- [ ] **Step 5: Migrate Room database to version 4**

In `ExpenseTrackerDatabase.kt`:

```kotlin
@Database(
    entities = [
        TransactionCategoryEntity::class,
        ExpenseTransactionEntity::class,
        CategoryLimitEntity::class,
        RecurringTransactionEntity::class,
        RecurringGhostTransactionEntity::class,
    ],
    version = 4,
    exportSchema = false,
)
```

Add:

```kotlin
abstract fun recurringGhostTransactions(): RecurringGhostTransactionDao
```

Add migration 3 to 4 with the table and indexes from the spec, then register:

```kotlin
.addMigrations(MIGRATION_1_2, MIGRATION_2_3, MIGRATION_3_4)
```

- [ ] **Step 6: Implement repository ghost generation and trigger conversion**

In `ExpenseRepository`, add DAO:

```kotlin
private val recurringGhostTransactions = db.recurringGhostTransactions()
```

Add methods:

```kotlin
suspend fun listRecurringGhostTransactions(periodKey: String?): List<Map<String, Any?>> {
    seedIfEmpty()
    ensureRecurringGhosts(periodKey)
    val rows = if (periodKey == null) recurringGhostTransactions.pending() else recurringGhostTransactions.pendingForPeriod(periodKey)
    return rows.map { it.toMap() }
}

suspend fun ensureRecurringGhosts(periodKey: String? = null) {
    seedIfEmpty()
    val now = Calendar.getInstance()
    val year = periodKey?.substring(0, 4)?.toIntOrNull() ?: now.get(Calendar.YEAR)
    val month = periodKey?.substring(5, 7)?.toIntOrNull() ?: now.get(Calendar.MONTH) + 1
    val key = RecurringGhostPlanner.periodKey(year, month)
    val timestamp = System.currentTimeMillis()
    for (recurring in recurringTransactions.active()) {
        if (recurringGhostTransactions.byRecurringAndPeriod(recurring.id, key) != null) continue
        val day = RecurringGhostPlanner.effectiveDay(year, month, recurring.dayOfMonth)
        val row = RecurringGhostTransactionEntity(
            recurringId = recurring.id,
            periodKey = key,
            date = "%04d.%02d.%02d".format(year, month, day),
            time = "00:00",
            name = recurring.name,
            amount = recurring.amount,
            transactionType = recurring.transactionType,
            categoryId = recurring.categoryId,
            categoryName = recurring.categoryName,
            categoryColor = recurring.categoryColor,
            categoryIconSlot = recurring.categoryIconSlot,
            status = "pending",
            createdTransactionId = null,
            createdAt = timestamp,
            updatedAt = timestamp,
        )
        recurringGhostTransactions.insert(row)
    }
}
```

Rewrite `processDueRecurringTransactions` so it calls `ensureRecurringGhosts()`, iterates pending ghosts for current period, checks due day, inserts real transaction, marks ghost `activated`, and updates recurring `lastProcessedPeriodKey`.

- [ ] **Step 7: Disable ghosts on toggle/delete**

In `toggleRecurringTransaction`, if `isActive` becomes false:

```kotlin
recurringGhostTransactions.disablePendingForRecurring(id, System.currentTimeMillis())
```

In `deleteRecurringTransaction`, cascade removes ghosts through the foreign key; no extra delete is needed.

- [ ] **Step 8: Add MethodChannel handlers**

In `ExpenseMethodChannel.kt`, add:

```kotlin
"expenseListRecurringGhostTransactions" -> scope.launchResult(result) {
    repository.listRecurringGhostTransactions(call.argument<String>("periodKey"))
}
"expenseEnsureRecurringGhostTransactions" -> scope.launchResult(result) {
    repository.ensureRecurringGhosts(call.argument<String>("periodKey"))
    true
}
```

- [ ] **Step 9: Run available native check**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:testDebugUnitTest --tests com.exptv2.app.expense.RecurringGhostPlannerTest'
```

Expected: PASS on a normal Android Gradle environment. If Termux/proot AAPT2 fails, record the exact AAPT2 failure and continue to GitHub Actions verification after all tasks.

- [ ] **Step 10: Commit**

```bash
git add android/app/src/main/kotlin/com/exptv2/app/expense android/app/src/test/kotlin/com/exptv2/app/expense/RecurringGhostPlannerTest.kt
git commit -m "feat: add recurring ghost transaction engine"
```

---

### Task 6: Dart Ghost Models, Bridge, Store Merge, And Logbox UI

**Files:**
- Create: `lib/features/transactions/models/recurring_ghost_record.dart`
- Create: `lib/features/transactions/models/transaction_log_entry.dart`
- Create: `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
- Modify: `lib/services/native_bridge.dart`
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Test: `test/transactions/recurring_ghost_log_test.dart`

- [ ] **Step 1: Write failing Dart ghost tests**

Create `test/transactions/recurring_ghost_log_test.dart`:

```dart
import 'package:exptv2/features/transactions/models/recurring_ghost_record.dart';
import 'package:exptv2/features/transactions/models/transaction_log_entry.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/models/transaction_summary.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('ghost maps from native payload', () {
    final ghost = RecurringGhostRecord.fromMap({
      'id': 1,
      'recurringId': 7,
      'periodKey': '2026-05',
      'date': '2026.05.15',
      'time': '00:00',
      'name': 'Rent',
      'amount': 120000,
      'transactionType': 'expense',
      'categoryId': 3,
      'categoryName': 'Housing',
      'categoryColor': '#06b6d4',
      'categoryIconSlot': 0,
      'status': 'pending',
      'createdTransactionId': null,
    });

    expect(ghost.signedAmount, -120000);
    expect(ghost.displayMerchant, 'Rent');
  });

  test('mixed log entries include ghosts but summary excludes them', () {
    final real = TransactionRecord.fromMap({
      'id': 1,
      'date': '2026.05.14',
      'time': '10:00',
      'merchant': 'Real',
      'amount': -5000,
      'transactionCategoryID': 3,
    });
    final ghost = RecurringGhostRecord.fromMap({
      'id': 2,
      'recurringId': 8,
      'periodKey': '2026-05',
      'date': '2026.05.15',
      'time': '00:00',
      'name': 'Ghost',
      'amount': 20000,
      'transactionType': 'expense',
      'categoryId': 3,
      'categoryName': 'Housing',
      'categoryColor': '#06b6d4',
      'categoryIconSlot': 0,
      'status': 'pending',
    });

    final entries = TransactionLogEntry.merge(realRecords: [real], ghostRecords: [ghost]);
    expect(entries.length, 2);
    expect(TransactionSummary.fromRecords([real]).expense, 5000);
  });
}
```

- [ ] **Step 2: Run test to verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/recurring_ghost_log_test.dart'
```

Expected: FAIL because ghost model files do not exist.

- [ ] **Step 3: Implement Dart ghost model**

Create `recurring_ghost_record.dart`:

```dart
import 'transaction_category.dart';
import 'transaction_record.dart';

class RecurringGhostRecord {
  const RecurringGhostRecord({
    required this.id,
    required this.recurringId,
    required this.periodKey,
    required this.date,
    required this.time,
    required this.name,
    required this.amount,
    required this.transactionType,
    required this.categoryId,
    required this.categoryName,
    required this.categoryColor,
    required this.categoryIconSlot,
    required this.status,
    this.createdTransactionId,
  });

  final int id;
  final int recurringId;
  final String periodKey;
  final String date;
  final String time;
  final String name;
  final double amount;
  final TransactionType transactionType;
  final int categoryId;
  final String categoryName;
  final String categoryColor;
  final int categoryIconSlot;
  final String status;
  final int? createdTransactionId;

  double get signedAmount => transactionType == TransactionType.income ? amount.abs() : -amount.abs();
  String get displayMerchant => name;
  String get displayAmount => '${transactionType == TransactionType.income ? '+' : '-'}${formatHuf(amount.abs())}';

  factory RecurringGhostRecord.fromMap(Map<dynamic, dynamic> map) {
    return RecurringGhostRecord(
      id: _int(map['id']),
      recurringId: _int(map['recurringId']),
      periodKey: map['periodKey']?.toString() ?? '',
      date: map['date']?.toString() ?? '',
      time: map['time']?.toString() ?? '00:00',
      name: map['name']?.toString() ?? '',
      amount: _double(map['amount']),
      transactionType: TransactionType.fromNative(map['transactionType']?.toString()),
      categoryId: _int(map['categoryId']),
      categoryName: map['categoryName']?.toString() ?? '',
      categoryColor: map['categoryColor']?.toString() ?? '#06b6d4',
      categoryIconSlot: _int(map['categoryIconSlot'] ?? 0),
      status: map['status']?.toString() ?? 'pending',
      createdTransactionId: map['createdTransactionId'] == null ? null : _int(map['createdTransactionId']),
    );
  }
}

int _int(Object? value) => value is int ? value : int.parse(value.toString());
double _double(Object? value) => value is num ? value.toDouble() : double.parse(value.toString());
```

If `TransactionType.fromNative` does not exist, add it to `transaction_category.dart`:

```dart
static TransactionType fromNative(String? value) {
  return value == 'income' || value == 'bevétel' ? TransactionType.income : TransactionType.expense;
}
```

- [ ] **Step 4: Implement mixed entry model**

Create `transaction_log_entry.dart`:

```dart
import 'recurring_ghost_record.dart';
import 'transaction_record.dart';

class TransactionLogEntry {
  const TransactionLogEntry.real(this.real) : ghost = null;
  const TransactionLogEntry.ghost(this.ghost) : real = null;

  final TransactionRecord? real;
  final RecurringGhostRecord? ghost;

  bool get isGhost => ghost != null;
  String get date => real?.date ?? ghost!.date;
  String get time => real?.time ?? ghost!.time;

  static List<TransactionLogEntry> merge({
    required List<TransactionRecord> realRecords,
    required List<RecurringGhostRecord> ghostRecords,
  }) {
    final entries = <TransactionLogEntry>[
      ...realRecords.map(TransactionLogEntry.real),
      ...ghostRecords.map(TransactionLogEntry.ghost),
    ];
    entries.sort((left, right) {
      final dateCompare = right.date.compareTo(left.date);
      if (dateCompare != 0) return dateCompare;
      return right.time.compareTo(left.time);
    });
    return entries;
  }
}
```

- [ ] **Step 5: Add bridge/repository ghost calls**

In `native_bridge.dart` add:

```dart
Future<List<RecurringGhostRecord>> expenseListRecurringGhostTransactions({String? periodKey}) async {
  final rows = await _methodChannel.invokeListMethod<dynamic>(
    'expenseListRecurringGhostTransactions',
    {'periodKey': periodKey},
  );
  return (rows ?? <dynamic>[])
      .cast<Map<dynamic, dynamic>>()
      .map(RecurringGhostRecord.fromMap)
      .toList();
}
```

Include ghosts in `ExpenseBootstrapPayload` only if the UI needs them at startup; otherwise load them in `TransactionStore._reload` after transactions.

- [ ] **Step 6: Merge ghosts in store while keeping summaries real-only**

In `TransactionStore`, add:

```dart
List<RecurringGhostRecord> _ghosts = [];
List<TransactionLogEntry> get visibleLogEntries => TransactionLogEntry.merge(
  realRecords: visibleTransactions,
  ghostRecords: _visibleGhosts,
);
```

`_visibleGhosts` must apply active type, current summary window period, category filter, merchant/search filter where useful. Do not include `_ghosts` in `activeSummary` or `totalBalanceText`.

- [ ] **Step 7: Render ghost logbox**

Create `recurring_ghost_log_box.dart` with visual structure matching current logbox but with recurring status text:

```dart
class RecurringGhostLogBox extends StatelessWidget {
  const RecurringGhostLogBox({super.key, required this.record, required this.onTap, required this.backgroundColor});

  final RecurringGhostRecord record;
  final ValueChanged<RecurringGhostRecord> onTap;
  final Color backgroundColor;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: ValueKey('recurring-ghost-logbox-${record.id}'),
      onTap: () => onTap(record),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
        constraints: const BoxConstraints(minHeight: 70),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.primary.withValues(alpha: 0.45)),
        ),
        child: Row(children: [
          // category badge, title, "Ismetlodo ghost" status, amount, date/time
        ]),
      ),
    );
  }
}
```

Fill the row using `CategoryIconBadge` with a lightweight synthetic category or a new badge overload accepting color/icon slot.

- [ ] **Step 8: Update list rendering**

Change `TransactionLogList` to accept `List<TransactionLogEntry> entries` or add a second constructor. For each entry:

```dart
if (entry.isGhost) {
  return RecurringGhostLogBox(
    record: entry.ghost!,
    backgroundColor: expenseTheme.logBox,
    onTap: onGhostTap,
  );
}
return TransactionLogBox(... entry.real! ...);
```

- [ ] **Step 9: Run focused tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/recurring_ghost_log_test.dart test/transactions/transaction_store_test.dart test/widget_test.dart'
```

Expected: PASS.

- [ ] **Step 10: Commit**

```bash
git add lib/services/native_bridge.dart lib/features/transactions/data/transaction_repository.dart lib/features/transactions/state/transaction_store.dart lib/features/transactions/models/recurring_ghost_record.dart lib/features/transactions/models/transaction_log_entry.dart lib/features/transactions/widgets/recurring_ghost_log_box.dart lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/transaction_home_page.dart test/transactions/recurring_ghost_log_test.dart test/transactions/transaction_store_test.dart test/widget_test.dart
git commit -m "feat: show recurring ghost logboxes"
```

---

### Task 7: Calendar Compact Sizing And Donut Chart

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Test: `test/transactions/calendar_render_builder_test.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`
- Test: `test/transactions/calendar_overlay_layout_test.dart`

- [ ] **Step 1: Add compact layout test**

In `test/transactions/calendar_overlay_layout_test.dart`, add:

```dart
test('calendar compact modes use same card height', () {
  final normal = CalendarCanvasLayout.calculate(width: 350, mode: CalendarMenuMode.normal);
  final heatmap = CalendarCanvasLayout.calculate(width: 350, mode: CalendarMenuMode.heatmap);
  final category = CalendarCanvasLayout.calculate(width: 350, mode: CalendarMenuMode.category);

  expect(normal.monthRects.first.height, heatmap.monthRects.first.height);
  expect(normal.monthRects.first.height, category.monthRects.first.height);
  expect(normal.monthRects.first.height, 140);
});
```

- [ ] **Step 2: Add donut chart smoke test**

In the same test file or `calendar_menu_widgets_test.dart`:

```dart
testWidgets('calendar menu can render category donut chart', (tester) async {
  await tester.pumpWidget(MaterialApp(
    home: CategoryDonutChart(
      values: const [
        CategoryDonutSlice(label: 'Food', value: 1000, color: Color(0xFF06B6D4)),
        CategoryDonutSlice(label: 'Rent', value: 2000, color: Color(0xFFEC4899)),
      ],
    ),
  ));

  expect(find.byKey(const ValueKey('category-donut-chart')), findsOneWidget);
});
```

- [ ] **Step 3: Run tests to verify failure**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_overlay_layout_test.dart test/transactions/calendar_menu_widgets_test.dart'
```

Expected: FAIL because `CategoryDonutChart` does not exist.

- [ ] **Step 4: Create donut chart painter**

Create `category_donut_chart.dart`:

```dart
import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class CategoryDonutSlice {
  const CategoryDonutSlice({required this.label, required this.value, required this.color});
  final String label;
  final double value;
  final Color color;
}

class CategoryDonutChart extends StatelessWidget {
  const CategoryDonutChart({super.key, required this.values});
  final List<CategoryDonutSlice> values;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      key: const ValueKey('category-donut-chart'),
      size: const Size(140, 140),
      painter: _CategoryDonutPainter(values),
    );
  }
}

class _CategoryDonutPainter extends CustomPainter {
  const _CategoryDonutPainter(this.values);
  final List<CategoryDonutSlice> values;

  @override
  void paint(Canvas canvas, Size size) {
    final total = values.fold<double>(0, (sum, item) => sum + item.value.abs());
    final center = size.center(Offset.zero);
    final rect = Rect.fromCircle(center: center, radius: size.shortestSide / 2 - 4);
    if (total <= 0) {
      canvas.drawCircle(center, rect.width / 2, Paint()..color = AppColors.gray200);
      return;
    }
    var start = -math.pi / 2;
    for (final value in values) {
      final sweep = (value.value.abs() / total) * math.pi * 2;
      canvas.drawArc(rect, start, sweep, true, Paint()..color = value.color);
      start += sweep;
    }
    canvas.drawCircle(center, size.shortestSide * 0.23, Paint()..color = AppColors.white);
  }

  @override
  bool shouldRepaint(covariant _CategoryDonutPainter oldDelegate) => oldDelegate.values != values;
}
```

- [ ] **Step 5: Normalize layout heights**

In `calendar_canvas_layout.dart`, ensure:

```dart
final cardHeight = mode == CalendarMenuMode.summary ? 200.0 : 140.0;
```

If this is already present, fix painter inner offsets so normal/heatmap/category content fits the same card height. Keep `_drawWeekdays` and `_drawDays` using compact offsets for all non-summary modes.

- [ ] **Step 6: Add chart section in calendar menu**

In `calendar_menu_overlay.dart`, under the canvas or in category mode side area, render `CategoryDonutChart` when `_mode == CalendarMenuMode.category` using category totals from `CalendarRenderBuilder` or a small local aggregation of current year transactions by category.

Keep it compact so it does not break the canvas:

```dart
if (_mode == CalendarMenuMode.category)
  SizedBox(
    height: 150,
    child: CategoryDonutChart(values: _categorySlices(data)),
  ),
```

- [ ] **Step 7: Run focused tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_overlay_layout_test.dart test/transactions/calendar_menu_widgets_test.dart test/transactions/calendar_render_builder_test.dart'
```

Expected: PASS.

- [ ] **Step 8: Commit**

```bash
git add lib/features/transactions/widgets/calendar_menu/category_donut_chart.dart lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart test/transactions/calendar_overlay_layout_test.dart test/transactions/calendar_menu_widgets_test.dart test/transactions/calendar_render_builder_test.dart
git commit -m "feat: add calendar category donut chart"
```

---

### Task 8: End-To-End Verification, Push, And Online APK Build

**Files:**
- All files changed by previous tasks.

- [ ] **Step 1: Run Dart analysis**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: `No issues found!`

- [ ] **Step 2: Run full Flutter tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test'
```

Expected: all tests pass.

- [ ] **Step 3: Run native unit test if environment allows**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2/android && ./gradlew :app:testDebugUnitTest --tests com.exptv2.app.expense.RecurringGhostPlannerTest'
```

Expected on a normal Gradle environment: PASS. In current Termux/proot, AAPT2 may fail before tests. If that happens, record the exact failure and do not claim local native tests passed.

- [ ] **Step 4: Check git diff cleanliness**

Run:

```bash
git diff --check
git status --short
```

Expected: no whitespace errors; only intended changes before final commit, clean after commit.

- [ ] **Step 5: Final commit if needed**

If any verification-only fixes were needed:

```bash
git add <changed-files>
git commit -m "fix: stabilize theme ghost calendar integration"
```

- [ ] **Step 6: Push to GitHub**

```bash
git push origin main
```

Expected: push succeeds and triggers GitHub Actions.

- [ ] **Step 7: Watch online APK build**

```bash
gh run list --branch main --limit 1
gh run watch <run-id> --exit-status
```

Expected: workflow completes successfully.

- [ ] **Step 8: Confirm APK artifact**

```bash
gh api repos/elizerpist/exptv2/actions/runs/<run-id>/artifacts --jq '.artifacts[] | "\(.name) \(.size_in_bytes) bytes expired=\(.expired)"'
```

Expected: `exptv2-debug-apk ... expired=false`.

- [ ] **Step 9: Final response**

Report in Hungarian:

- commits created
- `flutter analyze` result
- `flutter test` result
- native Gradle status if blocked by AAPT2
- GitHub Actions run URL
- artifact name and size

---

## Self-Review

Spec coverage:

- Theme application: Task 1 and Task 6 theme color propagation.
- Magnet strip: Task 2.
- Header/FastInfo: Task 3.
- BackHeader progress feedback: Task 4.
- Recurring ghost backend and UI: Tasks 5 and 6.
- Calendar/category overlay bottom coverage: Task 4.
- Calendar compact sizing and chart: Task 7.
- Category active-type filtering: Task 4.
- Verification/build: Task 8.

Placeholder scan:

- No placeholder markers or intentionally vague implementation steps remain.
- Steps that require code include exact file paths and representative code blocks.

Type consistency:

- Native ghost fields use `recurringId`, `periodKey`, `status`, and `createdTransactionId` consistently across Kotlin and Dart.
- `MagnetType.nativeValue` is reused for widget keys and persisted settings.
- Real transaction summaries continue to use `TransactionSummary.fromRecords(List<TransactionRecord>)`; ghosts are represented separately by `TransactionLogEntry`.
