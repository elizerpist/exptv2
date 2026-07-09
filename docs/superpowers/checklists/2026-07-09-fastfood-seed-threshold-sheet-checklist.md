# Fastfood Seed And Stats Threshold Sheet Checklist

Source: user request on 2026-07-09:
- Build an APK that contains a new 2025 expense category named `Gyorsétterem`.
- Add McDonald's and similar fast-food transaction logs spread randomly across 2025.
- First third of 2025: frequent, around 5000 HUF.
- Middle third of 2025: less frequent than the first third, but more expensive.
- End of 2025: even rarer and cheaper.
- When the user taps the stats joystick, the bottom sheet must include a slider for the amount and a text input pill for manual amount entry.

| ID | Source Instruction | Code Area | Acceptance Condition | Verification Method | Status |
| --- | --- | --- | --- | --- | --- |
| FST-001 | "2025-os évben csinálsz egy új kategóriát: gyorsétterem" | `android/app/src/main/kotlin/com/exptv2/app/expense/ExpenseSeedData.kt` | Demo seed categories include an expense category named `Gyorsétterem` with a stable new ID and normal category limit coverage. | RED/GREEN source test in `test/android_seed_data_test.dart`; code inspection. | DONE |
| FST-002 | "teszel bele logokat, mcdonalds etc. ezeket random elszórod az egész évben" | `ExpenseSeedData.kt` | 2025 seed transactions include deterministic random fast-food rows with merchants including `McDonald's`, `Burger King`, `KFC`, and `Subway`, distributed across all three four-month periods. | RED/GREEN source test checks helper, merchants, year, and periods. | DONE |
| FST-003 | "év első harmadában gyakori de kb 5k huf körüli összeg" | `ExpenseSeedData.kt` | January-April 2025 fast-food seed rows use the highest monthly count range and amounts around 5000 HUF. | RED/GREEN source test checks count/amount constants. | DONE |
| FST-004 | "év középső harmadában ritkább ... de drágább" | `ExpenseSeedData.kt` | May-August 2025 fast-food seed rows use a lower count range than Jan-April and a higher amount range. | RED/GREEN source test checks count/amount constants. | DONE |
| FST-005 | "év végén pedig még ritkább és még olcsóbb" | `ExpenseSeedData.kt` | September-December 2025 fast-food seed rows use the lowest count range and the cheapest amount range. | RED/GREEN source test checks count/amount constants. | DONE |
| FST-006 | "ha a user a joystickot tappeli, az alsó sheetben legyen egy slider" | `lib/features/stats/stats_page.dart` | Tapping the stats threshold joystick opens a bottom sheet containing a threshold slider that updates the stats threshold live. | RED/GREEN widget test in `test/stats/stats_page_test.dart`. | DONE |
| FST-007 | "és egy text input pill, ahol manuálisan is be lehet írni" | `stats_page.dart`, `CalendarJoystickRange` | The same bottom sheet contains a pill-styled numeric text input; submitting manual HUF value snaps/clamps and updates the threshold, with sparse data still allowing at least the 50 000 HUF fallback ceiling. | RED/GREEN widget test verifies `12000` updates to `12 000 Ft`; range unit test verifies fallback ceiling. | DONE |
| FST-008 | Existing stats joystick role | `stats_page.dart` | The previous render mode selector remains available from the joystick sheet, so category scope, heatmap, and closing can still be selected. | Existing/updated stats widget test selects heatmap and closing from the new sheet. | DONE |
| FST-009 | Build request | GitHub Actions and `/storage/emulated/0/Download/exptv2` | After tests/analyze pass and branch is pushed, build debug APK online and download it without deleting existing APK files. | GitHub Actions run `29000173177` completed successfully for `ca1735e`; release asset and local APK both measured `154896339` bytes. | DONE |
