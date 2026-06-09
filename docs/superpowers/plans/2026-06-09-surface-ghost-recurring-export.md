# Surface Ghost Recurring Export Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Adjust neumorph/surface behavior, simplify ghost logboxes, improve recurring trigger UI, theme the category menu, and integrate Google export/sign-in without losing any current `main` functionality.

**Architecture:** Keep `main` as the base. Implement surface and ghost changes in existing theme/rendering layers, add only focused model fields needed for category and recurring controls, and cherry-pick Google export/sync files rather than merging the old branch. Rendering decisions come from `AppThemeSettings` and `ExpenseTheme` so the UI stays consistent.

**Tech Stack:** Flutter/Dart, Android Kotlin/Room, GitHub Actions for APK build, `google_sign_in`, `googleapis`, `http`, `shared_preferences`, `url_launcher`.

---

### Task 1: Spec And Plan Commit

**Files:**
- Create: `docs/superpowers/specs/2026-06-09-surface-ghost-recurring-export-design.md`
- Create: `docs/superpowers/plans/2026-06-09-surface-ghost-recurring-export.md`

- [ ] Commit the approved spec and plan.

Run:
```bash
git add docs/superpowers/specs/2026-06-09-surface-ghost-recurring-export-design.md docs/superpowers/plans/2026-06-09-surface-ghost-recurring-export.md
git commit -m "docs: plan surface ghost recurring export work"
```

Expected: one docs commit on `main`.

### Task 2: Surface Settings Tests

**Files:**
- Modify: `test/settings/expense_theme_test.dart`
- Modify: `test/settings/settings_page_test.dart`
- Modify: `test/shell/bottom_nav_item_test.dart`

- [ ] Add a test that button surface can select `neutralInset`, `raisedInset`, and `neutralNeutral` from theme settings.
- [ ] Add a test that `ExpenseTheme.bottomNavSurfaceStyle` follows `buttonSurfaceStyle` instead of always returning `neutralNeutral`.
- [ ] Add/update bottom nav tests so `neutralInset` gives inactive items neutral-at-rest and active items `insetInset` when active.

Run:
```bash
flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/shell/bottom_nav_item_test.dart
```

Expected before implementation in CI-capable environment: failures showing missing neutral-inset UI option and bottom nav mapping.

### Task 3: Surface Settings Implementation

**Files:**
- Modify: `lib/features/settings/theme/expense_theme.dart`
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Modify: `lib/features/shell/widgets/expt_bottom_nav.dart`
- Modify: `lib/features/shell/widgets/bottom_nav_item.dart`
- Modify: `lib/features/transactions/widgets/search_pill.dart`

- [ ] Set `ExpenseTheme.bottomNavSurfaceStyle = settings.buttonSurfaceStyle`.
- [ ] Add a `Gombok: Neutralis-befele` radio option that writes `ExpenseSurfaceInteraction.neutralInset`.
- [ ] Keep `Normál` as `neutralNeutral` and `Neumorph` as `raisedInset`.
- [ ] Pass button surface to search filter capsules and keep search container behavior stable.
- [ ] Replace blue/cyan primary neumorph shadow tokens with black/gray shadow tones in `ExpenseSurface`.

Run:
```bash
git diff --check
flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/shell/bottom_nav_item_test.dart
```

Expected: tests pass on CI-capable environment; local Flutter may be unavailable.

Commit:
```bash
git add lib/features/settings/theme/expense_theme.dart lib/features/settings/widgets/options/theme_options_panel.dart lib/features/shell/widgets/expt_bottom_nav.dart lib/features/shell/widgets/bottom_nav_item.dart lib/features/transactions/widgets/search_pill.dart test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/shell/bottom_nav_item_test.dart
git commit -m "feat: restore button neutral inset surfaces"
```

### Task 4: Ghost Fixed Design Tests

**Files:**
- Modify: `test/transactions/recurring_ghost_log_box_test.dart`
- Modify: `test/transactions/recurring_ghost_log_test.dart`
- Modify: `test/settings/settings_page_test.dart`

- [ ] Add a widget test that a ghost logbox always renders `Varhato`, one trigger icon, a `GhostBadge`, gray merchant/amount text, and text opacity.
- [ ] Add a widget test that normal ghost logbox surface uses dashed border and neumorph ghost logbox surface omits dashed border.
- [ ] Add a settings page test that `Ghost logbox` submenu is no longer present.
- [ ] Update monthly display test so pinned ghost rows include a date header before ghost rows, and normal rows can repeat the same date header later.

Run:
```bash
flutter test test/transactions/recurring_ghost_log_box_test.dart test/transactions/recurring_ghost_log_test.dart test/settings/settings_page_test.dart
```

Expected before implementation: failures for removed/fixed ghost UI behavior.

### Task 5: Ghost Fixed Design Implementation

**Files:**
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/features/settings/widgets/options/ghost_logbox_options_panel.dart` or remove from navigation only
- Modify: `lib/features/transactions/widgets/recurring_ghost_log_box.dart`
- Modify: `lib/features/transactions/widgets/transaction_log_list.dart`
- Modify: `lib/features/transactions/state/transaction_store.dart`
- Modify: `lib/features/transactions/models/transaction_log_entry.dart` if a pinned-section marker is needed

- [ ] Remove the ghost settings submenu from settings root and submenu routing.
- [ ] Keep ghost settings model/native persistence untouched for compatibility unless tests require otherwise.
- [ ] Compute ghost visual behavior from `surfaceStyle` and button/avatar surface style: normal = dashed border, neumorph = no border.
- [ ] Always show ghost badge, `Varhato`, trigger icon, gray text, and opacity.
- [ ] Add date headers for pinned ghost section without suppressing later normal date headers.

Run:
```bash
git diff --check
flutter test test/transactions/recurring_ghost_log_box_test.dart test/transactions/recurring_ghost_log_test.dart test/settings/settings_page_test.dart
```

Commit:
```bash
git add lib/features/settings/settings_page.dart lib/features/transactions/widgets/recurring_ghost_log_box.dart lib/features/transactions/widgets/transaction_log_list.dart lib/features/transactions/state/transaction_store.dart lib/features/transactions/models/transaction_log_entry.dart test/transactions/recurring_ghost_log_box_test.dart test/transactions/recurring_ghost_log_test.dart test/settings/settings_page_test.dart
git commit -m "feat: simplify ghost logbox design"
```

### Task 6: Recurring Date And Push Pill Tests

**Files:**
- Modify: `test/transactions/recurring_ghost_log_test.dart`
- Modify: `test/widget_test.dart` or add focused recurring manager widget test if existing helpers support it
- Modify: `test/transactions/transaction_models_test.dart`
- Modify: Android recurring tests if native expected time fields are added

- [ ] Add test that recurring manager date trigger shows date and time picker fields instead of raw day text.
- [ ] Add test that push trigger shows expected date pill and app selector pill.
- [ ] Add test that selected app pill can render an installed app icon.
- [ ] Add model/native tests for expected time persistence if new fields are added.

Run:
```bash
flutter test test/widget_test.dart test/transactions/transaction_models_test.dart
```

### Task 7: Recurring Date And Push Pill Implementation

**Files:**
- Modify: `lib/features/transactions/widgets/recurring_manager_sheet.dart`
- Modify: `lib/features/transactions/models/recurring_rule.dart`
- Modify: `lib/services/native_bridge.dart`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleEntity.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlanner.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt`
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt` if schema changes

- [ ] Replace raw day text in date-trigger UI with `DateTimeFields`.
- [ ] Store expected day from selected date for compatibility.
- [ ] Persist expected time for date-trigger rules and use it in ghost `time` and `triggerMillis`.
- [ ] For push trigger, render date pill + app selector pill; app pill includes selected app icon.
- [ ] Keep push trigger time optional/ignored.

Run:
```bash
git diff --check
flutter test test/widget_test.dart test/transactions/transaction_models_test.dart
```

Commit:
```bash
git add lib/features/transactions/widgets/recurring_manager_sheet.dart lib/features/transactions/models/recurring_rule.dart lib/services/native_bridge.dart android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleEntity.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringGhostPlanner.kt android/app/src/main/kotlin/com/exptv2/app/expense/RecurringRuleInstancePlanner.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseRepository.kt android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseTrackerDatabase.kt test/widget_test.dart test/transactions/transaction_models_test.dart
git commit -m "feat: add recurring date and time trigger controls"
```

### Task 8: Category Menu Theme Tests

**Files:**
- Modify: `test/settings/expense_theme_test.dart`
- Modify: `test/settings/settings_page_test.dart`
- Modify: `test/transactions/category_menu_test.dart`
- Modify: `test/transactions/header_layout_test.dart`

- [ ] Add tests for category menu background color and surface style settings.
- [ ] Add tests for category card color and surface style settings.
- [ ] Add test that category menu open does not prevent header downward drag.
- [ ] Add test that header category button does not use a white top glow token.

Run:
```bash
flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/transactions/category_menu_test.dart test/transactions/header_layout_test.dart
```

### Task 9: Category Menu Theme Implementation

**Files:**
- Modify: `lib/features/settings/models/app_theme_settings.dart`
- Modify: `lib/features/settings/theme/expense_theme.dart`
- Modify: `lib/features/settings/widgets/options/theme_options_panel.dart`
- Modify: `lib/features/settings/state/settings_store.dart` if serialization tests require it
- Modify: `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_overlay.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`
- Modify: `lib/features/transactions/widgets/category_menu/category_card.dart`
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`

- [ ] Add category menu background/card color enums using the existing white/gray/darkgray pattern.
- [ ] Add category menu background/card surface fields using normal/neumorph options.
- [ ] Persist/load fields in Dart and native settings stores.
- [ ] Pass category theme values from `TransactionHomePage` to overlay/panel/cards.
- [ ] Adjust overlay hit region or stacking so header drag remains possible.
- [ ] Remove distinct white top glow behavior from header category button via surface shadow tuning.

Run:
```bash
git diff --check
flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/transactions/category_menu_test.dart test/transactions/header_layout_test.dart
```

Commit:
```bash
git add lib/features/settings/models/app_theme_settings.dart lib/features/settings/theme/expense_theme.dart lib/features/settings/widgets/options/theme_options_panel.dart android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSettingsStore.kt lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/category_menu/category_menu_overlay.dart lib/features/transactions/widgets/category_menu/category_menu_panel.dart lib/features/transactions/widgets/category_menu/category_card.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/transactions/category_menu_test.dart test/transactions/header_layout_test.dart
git commit -m "feat: add category menu surface controls"
```

### Task 10: Google Export Cherry-Pick Tests

**Files:**
- Add: `test/transactions/transaction_csv_exporter_test.dart`
- Add: `test/transactions/transaction_export_service_test.dart`
- Add: `test/transactions/google_sheets_api_client_test.dart`
- Add: `test/transactions/google_sheets_sync_controller_test.dart`
- Add: `test/transactions/google_sheets_sync_store_test.dart`
- Modify: `test/settings/settings_page_test.dart`

- [ ] Copy/adapt export and Google sync tests from `feature/google-sheets-sync`.
- [ ] Add a settings panel test that Google connect action displays the official Google icon.
- [ ] Ensure tests do not assert deletion of current push log/parser UI.

Run:
```bash
flutter test test/transactions/transaction_csv_exporter_test.dart test/transactions/transaction_export_service_test.dart test/transactions/google_sheets_api_client_test.dart test/transactions/google_sheets_sync_controller_test.dart test/transactions/google_sheets_sync_store_test.dart test/settings/settings_page_test.dart
```

### Task 11: Google Export Cherry-Pick Implementation

**Files:**
- Add: `lib/features/settings/widgets/options/export_options_panel.dart`
- Add: `lib/features/transactions/export/transaction_csv_exporter.dart`
- Add: `lib/features/transactions/export/transaction_export_row.dart`
- Add: `lib/features/transactions/export/transaction_export_service.dart`
- Add: `lib/features/transactions/sync/google_auth_headers_client.dart`
- Add: `lib/features/transactions/sync/google_sheets_api_client.dart`
- Add: `lib/features/transactions/sync/google_sheets_auth_client.dart`
- Add: `lib/features/transactions/sync/google_sheets_sync_config.dart`
- Add: `lib/features/transactions/sync/google_sheets_sync_controller.dart`
- Add: `lib/features/transactions/sync/google_sheets_sync_models.dart`
- Add: `lib/features/transactions/sync/google_sheets_sync_store.dart`
- Modify: `lib/features/settings/settings_page.dart`
- Modify: `lib/exptv2_app.dart` or shell wiring if controller startup is needed
- Modify: `lib/features/transactions/data/transaction_repository.dart`
- Modify: `lib/services/native_bridge.dart`
- Modify: `android/app/src/main/AndroidManifest.xml`
- Modify: `android/app/build.gradle.kts`
- Modify: `pubspec.yaml`
- Modify: `pubspec.lock`

- [ ] Copy only export/sync source files from `feature/google-sheets-sync`.
- [ ] Wire export submenu into current settings page without removing current menus.
- [ ] Add official Google icon rendering to the connect button.
- [ ] Add required dependencies and Android metadata only; do not delete current notification/parser code.
- [ ] Add repository/native methods needed for paged transaction export.

Run:
```bash
git diff --check
flutter test test/transactions/transaction_csv_exporter_test.dart test/transactions/transaction_export_service_test.dart test/transactions/google_sheets_api_client_test.dart test/transactions/google_sheets_sync_controller_test.dart test/transactions/google_sheets_sync_store_test.dart test/settings/settings_page_test.dart
```

Commit:
```bash
git add lib/features/settings/widgets/options/export_options_panel.dart lib/features/transactions/export lib/features/transactions/sync lib/features/settings/settings_page.dart lib/exptv2_app.dart lib/features/transactions/data/transaction_repository.dart lib/services/native_bridge.dart android/app/src/main/AndroidManifest.xml android/app/build.gradle.kts pubspec.yaml pubspec.lock test/transactions/transaction_csv_exporter_test.dart test/transactions/transaction_export_service_test.dart test/transactions/google_sheets_api_client_test.dart test/transactions/google_sheets_sync_controller_test.dart test/transactions/google_sheets_sync_store_test.dart test/settings/settings_page_test.dart
git commit -m "feat: add google sheets export sync"
```

### Task 12: Final Verification And Push

**Files:**
- No production files expected unless verification exposes a bug.

- [ ] Run local static checks:
```bash
git diff --check
flutter analyze
flutter test
(cd android && ./gradlew testDebugUnitTest --no-daemon)
```

Expected locally on Termux: `flutter` and Java may be unavailable. Record exact failures.

- [ ] Push to GitHub:
```bash
git push origin main
```

- [ ] Watch GitHub Actions:
```bash
gh run list --repo elizerpist/exptv2 --branch main --limit 5
gh run watch <run-id> --repo elizerpist/exptv2 --interval 15 --exit-status
```

Expected: analyzer, Flutter tests, Android unit tests, debug APK build, and release publish succeed.

- [ ] Report APK:
```bash
gh release view debug-latest --repo elizerpist/exptv2 --json assets,url,tagName
```

Expected direct asset URL: `https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk`.
