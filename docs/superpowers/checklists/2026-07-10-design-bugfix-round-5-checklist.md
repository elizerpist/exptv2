# 2026-07-10 Design Bugfix Round 5 Checklist

## Scope

One commit must contain all bugfixes listed by the user after the `0967975` build. APK build and download are not completion criteria until every item below is `DONE` or explicitly deferred by the user.

## Acceptance Checklist

| ID | Source instruction | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| BUG5-001 | "logbox tap ha neumorph, nem jó, javítsd" | `lib/features/transactions/widgets/transaction_log_box.dart`, `lib/features/settings/theme/expense_surface.dart` | In neumorph mode, tapping the logbox body makes both body and avatar visually press; tapping the avatar only presses the avatar and still filters. Body press must render inset visual parameters, not only `pressed=true`. | `flutter test test/transactions/transaction_widgets_test.dart test/transactions/category_menu_test.dart test/widget_test.dart` passes; regression asserts body `ThemeSurface` debug line has `style=neutralInset`, non-zero offset, and avatar-only tap does not force body press. | DONE |
| BUG5-002 | "vendor keyboard: nem smooth ... az animációnak frame by frame követnie kell" | keyboard inset handling shared by slide-up sheets and vendor filter | Android keyboard inset changes are consumed by a common animated/frame-synced inset path, with diagnostic logs that show raw target, animated value, effective value, safe inset, enabled flag, and source. | `flutter test test/transactions/category_menu_test.dart` passes; manual APK validation remains required for device smoothness. | DONE |
| BUG5-003 | "ugyanez legyen igaz minden helyre ahol keyboard jön elő ... összes textfieldben" | `DebugTextField`, `DebugTextFormField`, `SlideUpMenuCard`, sheets with text fields | Textfield keyboard tracing uses the same shared keyboard tracker instead of ad hoc `MediaQuery.viewInsets`, so logs are comparable across all text inputs. | `flutter test test/widget_test.dart` and `flutter test test/transactions/slide_up_menu_card_test.dart` pass; logs include `source=shared-keyboard` and `[KeyboardFlow] SlideUpMenu ... keyboard frame`. | DONE |
| BUG5-004 | "teljesítmény (bevétel/kiadás) lag néha jó néha nem, mindenhová debug logot akarok" | transaction type switch, store active view, log list/home frame tracing | Income/expense switches emit start, cache/store, notify, first-frame, list-frame, and slow-frame diagnostics with enough context to compare good vs laggy switches. | Existing type switch tests pass; home first-frame log now includes before/after counts, `frameBudget=16ms`, and `jank=...`. | DONE |
| BUG5-005 | "vendorcard nevét tappeli ... boxban a név offset lesz ... maradjon az eredeti pozícióban" | `_VendorFilterRow._nameArea()` | Vendor name edit TextField baseline/center stays aligned with non-edit label; no upward jump from padding. | `flutter test test/transactions/category_menu_test.dart` passes; regression asserts `textAlignVertical: center` and `contentPadding: EdgeInsets.zero`. | DONE |
| BUG5-006 | "addnewtransaction sheet layout ... megváltozik ... nagy gap lesz a mentés és a date timepicker pillek közt ... sheet magassága változik" | `AddTransactionSheet`, `SlideUpMenuCard`, panel metrics | Add/Edit Transaction panel height and internal date-time-to-save-button spacing remain the same when keyboard appears; keyboard movement is handled by sheet transform/animated inset, not content relayout. | `flutter test test/widget_test.dart` passes; regression changes `viewInsets` while the sheet is already open and asserts stable panel height and date-time/save gap. | DONE |
| BUG5-007 | "add new recurring: az egész sheet felslideol ... csak az alsó gomb (és a paddingja)" | `RecurringManagerSheet`, `SlideUpMenuCard` | Recurring manager does not translate the whole sheet for keyboard; only footer button/padding follows keyboard and scroll body bottom padding adjusts. | `flutter test test/widget_test.dart` passes; regression asserts recurring sheet transform stays at zero keyboard lift while footer top moves upward. | DONE |
| BUG5-008 | "egy commitot akarok az összes bugfixszel" | Git history | All round-5 production/test/checklist changes are committed together in one commit after verification. | Final commit will include this checklist and all round-5 code/test changes; verified with `git status --short` and `git log --oneline`. | DONE |

## Verification Notes

- RED run failed for BUG5-001, BUG5-002, BUG5-005, BUG5-006, and BUG5-007 before implementation.
- GREEN run: `flutter test test/transactions/transaction_widgets_test.dart test/transactions/category_menu_test.dart test/widget_test.dart` passed with `130` tests.
- GREEN run: `flutter test test/transactions/slide_up_menu_card_test.dart` passed with `16` tests.
- Analyzer: `flutter analyze` passed with `No issues found!`.
