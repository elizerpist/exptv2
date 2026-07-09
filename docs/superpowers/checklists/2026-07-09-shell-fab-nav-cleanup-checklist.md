# Shell FAB/Nav Cleanup Acceptance Checklist

| ID | Source instruction | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| SFN-001 | User: "a beallitasokban lehet valasztani, hogy a fab gomb jobb oldalt legyen ... szedd ki a beallitasokbol" | `lib/features/settings/widgets/options/theme_options_panel.dart` | Settings no longer exposes shell navigation layout choices. | Widget test verifies old shell navigation option keys are absent. | DONE |
| SFN-002 | User: "rounded square legyen ... szedd ki a beallitasokbol" | `lib/features/settings/widgets/options/theme_options_panel.dart`, `lib/features/settings/models/app_theme_settings.dart` | Settings no longer exposes FAB shape choices, and theme settings no longer stores/copies/parses a selectable FAB shape. | Widget/model tests verify old shape option keys and map keys are absent. | DONE |
| SFN-003 | User: "jobb oldalt legyen, rounded square legyen, es alul a bottom navban csak 3 menu legyen. ez legyen az alapertelmezett" | `lib/features/shell/expt_shell.dart`, `lib/features/shell/widgets/expt_bottom_nav.dart`, `lib/features/shell/widgets/expt_fab.dart` | Shell always renders right-side rounded-square FAB and bottom nav only contains Home, Stats, Settings. | Shell/bottom-nav widget tests inspect nav items and FAB decoration. | DONE |
| SFN-004 | User: "egyedul a fab meretallitast tartsd meg" | `lib/features/settings/models/app_theme_settings.dart`, `theme_options_panel.dart`, native settings store | FAB size remains configurable, persists through settings maps/native store, and still clamps to min/max. | Existing and updated model/settings/native tests verify `fabSize`. | PARTIAL |
| SFN-005 | User: "torold ezt a kodreszletet, nincs ra szukseg, ne legyen kod zaj" | Dart settings model, shell widgets, native settings store, tests | Removed obsolete `ShellNavigationLayout`, `FabShape`, selectable layout plumbing, native keys, and stale tests/fixtures. | `rg` finds no stale layout/shape symbols in production code. | DONE |

## Verification Notes

- `flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/shell/bottom_nav_item_test.dart test/widget_test.dart`: passed.
- `flutter analyze`: passed with no issues.
- `git diff --check`: passed.
- Production stale-symbol search for `shellNavigationLayout`, `fabShape`, `ShellNavigationLayout`, `FabShape`, `rightRoundedFab`, `theme-shell-navigation`, and `theme-fab-shape`: no matches in `lib` or `android/app/src/main`.
- Native Gradle test command was attempted in Ubuntu/proot, but blocked before tests by AAPT2 daemon startup failures during `:app:processDebugResources`.
