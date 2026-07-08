# 2026-07-08 FAB Shape And Size Checklist

| ID | Source instruction | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| FSS-01 | "legyen opció, hogy a fab kör vagy rounded square" | `AppThemeSettings`, settings theme options, `ExptFab`, shell, `ExpenseSettingsStore` | Settings exposes a persisted FAB shape choice independent of A/B navigation layout, and shell renders the chosen shape. | RED: missing `FabShape`/`fabShape`; GREEN: `flutter test test/settings/expense_theme_test.dart test/settings/settings_page_test.dart test/widget_test.dart`, exact B layout widget test; Android unit test added, local Gradle blocked by missing Android SDK. | DONE |
| FSS-02 | "legyen egy slider ami méretállító" | Settings theme options, `ExptFab`, shell layout/debug offsets | Settings exposes a FAB size slider; shell FAB size and icon scale follow the saved value; debug button/log offsets use chosen size. | RED: missing `ExptFab.size`; GREEN: Flutter tests above plus `flutter analyze`. | DONE |
| FSS-03 | "slider mellett text input box, hogy számmal is lehessen" | Settings theme options | Numeric pill/input next to the slider edits the same FAB size value and clamps invalid/out-of-range values. | GREEN: settings panel widget test verifies slider range and numeric input updates `fabSize`; model test verifies clamp. | DONE |
