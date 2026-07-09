# All Design Requests Acceptance Checklist

| ID | Source instruction / reference | Intended code area | Acceptance condition | Verification method | Status |
|---|---|---|---|---|---|
| CAT-001 | User: "a kategória menu innentől kezdve csakis slide up sheet lehet" | category menu entry points in home and stats | Category menu opens only as a slide-up sheet; inline/overlay category menu mode is not selectable or used. | Widget tests + settings/model inspection. | DONE |
| CAT-002 | User: "a kategória sheet legyen ugyanaz, a főmenuben, mint a statisztikában" | shared category sheet/card widgets | Home and stats category selection use the same shared sheet/card implementation. | Code inspection + widget tests for both entry points. | DONE |
| CAT-003 | User correction: "a szín beállítás marad, fehér vagy világosszürke a sheet ... külön" | category theme settings + sheet style | Category sheet background is independently configurable as white or light gray. | Settings/model tests + widget style tests. | DONE |
| CAT-004 | User correction: "a szín beállítás marad ... kategory cardoknál is külön" | category theme settings + card style | Category card background is independently configurable as white or light gray. | Settings/model tests + widget style tests. | DONE |
| CAT-005 | User: "a felesleges kategória design beállít@sokat töröld" and later corrections | category settings UI/model/native store | Only category sheet color, category card color, and category card neumorph normal/on remain; obsolete category design options are removed. | `rg` stale-symbol search + settings tests. | DONE |
| CAT-006 | User: "a sheet nem lehet neumorph" | category sheet style | Category sheet has no neumorph setting/state and never renders as neumorph. | Code inspection + widget test. | DONE |
| CAT-007 | User: "a kártyák lehetnek neumorphak, de normál-be logikával" | category card style | Category cards support normal/on neumorph behavior, shared by home and stats. | Widget tests + settings/model tests. | DONE |
| CAT-008 | User: "az egész kártya reagáljon" | category card gesture handling | The full category card responds to tap/press, not only the avatar. | Widget tap tests. | DONE |
| CAT-009 | User: "azaz multi highlight" | category sheet selection state | Multiple category cards can stay highlighted at once. | Widget state tests. | DONE |
| CAT-010 | User: "multi filter" | home/stats category filtering | Applying the sheet filters by all selected categories in home and stats. | Widget/data tests. | DONE |
| CAT-011 | User: "acceptance gomb neve szűrőbeállítás" | category sheet footer | Bottom acceptance button text is exactly `Szűrőbeállítás` and applies the selected filter. | Widget text/action test. | DONE |
| CAT-012 | User: "select all card az első" | category sheet card order | The first card is the select-all card. | Widget order test. | DONE |
| CAT-013 | User: "az addnewcategory gomb kikerül a headerből" | category sheet header | Add-new-category action is not in the sheet header. | Widget absence test. | DONE |
| CAT-014 | User: "az lesz a m@sodik card, az első cardhoz hasonlóan" | category sheet card order/style | Add-new-category is the second card and visually matches the select-all card pattern. | Widget order/style test. | DONE |
| CAT-015 | User: "ne csak egyszeri tapre adjon benyomást-visszaugrást, hanem addig benyomva marad, még a user el nem fogadja" | category card selected neumorph state | Selected neumorph cards remain pressed/active until `Szűrőbeállítás` is accepted. | Widget interaction test. | DONE |
| CAT-016 | User: "ha a sheet felúszik, akkor a háttérból a fab és bottom nav ne tűnjön el" | shell/category sheet layering | FAB and bottom nav remain mounted/visible behind the category sheet. | Widget layout test. | DONE |
| CAT-017 | User: "ezek legyenek alatta, csak fedésben" | shell/category sheet layering | Category sheet overlays FAB/bottom nav; nav/FAB do not slide with or disappear because of the sheet. | Widget layout/screenshot test. | DONE |
| CAT-018 | User: "szedd ki az árnyékbeállításokat" | theme settings model/UI/native store | All shadow setting controls and persisted shadow toggles are removed. | Settings tests + stale-symbol search. | DONE |
| CAT-019 | User: "highlighted cardok, csak egy keretet mutatnak, veilt nem" | category card selected style | Highlighted category cards show a border only; no veil/overlay is rendered. | Widget style test. | DONE |
| CAT-020 | User: "az all avatar háttérszíne olyan legyen, mint a header chip színe" | select-all card/avatar | Select-all avatar background matches the header chip color. | Widget style test. | DONE |
| CAT-021 | User: "a stat 3s főmenu kategory card ugyanaz legyen" | shared category card widget | Stats and home category cards use the same shared visual component. | Code inspection + widget tests. | DONE |
| CAT-022 | User: "ha valahol a user színt vagy neumorph beállítást módosít, az mindkettőben módosul" | shared category settings | Sheet/card color and card neumorph settings affect both home and stats. | Settings persistence + widget tests. | DONE |
| CAT-023 | User: "a sheet magassága a summary pill tetejéig érhet" | category sheet layout | Category sheet top does not rise above the summary pill top. | Widget layout test. | DONE |
| CAT-024 | User: "a sum gombon a tap hozzon elő egy natív android year és month selectort" | summary pill + native bridge | Single tap on sum opens a native Android year/month selector. | Method channel/native bridge tests + widget test. | DONE |
| CAT-025 | User: "a swipe ... logika maradjon" | summary pill gestures | Existing sum swipe behavior still works. | Existing/updated widget tests. | DONE |
| CAT-026 | User: "double tap logika maradjon" | summary pill gestures | Existing sum double-tap behavior still works. | Existing/updated widget tests. | DONE |
| CAT-027 | User: "minden komponensnek legyen árnyéka" | theme resolution/components | Components affected by removed shadow settings render with shadows enabled. | Widget/theme tests. | DONE |
| CAT-028 | User: "új tranzakció sheeten a mentés gomb ... közvetlen a safety zone tetején legyen" | add transaction sheet layout | Save button is fixed/aligned directly above the safe area, like the category sheet action button. | Widget layout test. | DONE |
| CAT-029 | User: "recurring sheetben a szabály hozzáadása ... ne legyen [scroll része]" | recurring manager sheet | `Szabály hozzáadása` is outside the scroll content and fixed above the safe area. | Widget layout test. | DONE |
| CAT-030 | User: "felette a scroll areát úgy igazítsd, hogy ne fedje az alsó gomb" | recurring manager sheet | Recurring scroll area bottom padding/height prevents content from being covered by the fixed bottom button. | Widget layout/scroll test. | DONE |
| CAT-031 | User: "a notification log menu headerjében legyen egy vissza gomb" | notification log menu/header | Notification log menu header includes a working back button. | Widget navigation test. | DONE |
| CAT-032 | User: "új kártya header card design, választható opció.: mentők skin" | backheader style settings + header card | A selectable `Mentők skin` header card design option exists. | Settings/model/widget tests. | DONE |
| CAT-033 | User + screenshot `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-084623.png` | header card rendering | `Mentők skin` header card uses the ambulance-like yellow base color from the screenshot. | Screenshot/widget style check. | DONE |
| CAT-034 | User + screenshot | magnet strip rendering | `Mentők skin` magnet uses the ambulance-side orange stripe color. | Widget style check. | DONE |
| CAT-035 | User + screenshot | magnet strip decoration | Magnet strip contains repeated tilted yellow parallelograms/blocks like the reference. | Widget/golden-style inspection. | DONE |
| CAT-036 | User: "a magnet strip progress bar szrűen csökken, az legyen mögötte a matek" | magnet strip progress logic | Existing progress math remains the driver behind the ambulance stripe visual. | Existing magnet tests + added style test. | DONE |
| CAT-037 | User: "haptic feedback legyen a longtapen a kategóriakártyákon" | category card long press | Category card long press triggers haptic feedback. | Widget test with haptic channel mock. | DONE |
| CAT-038 | User: "a kuka gomb modify category menuben ... legyen külön komponens, lebegő" | modify category sheet header | Delete button is a separate floating component aligned to the sheet header right edge. | Widget layout test. | DONE |
| SFN-001 | Earlier implemented request: default 3 bottom nav + right rounded FAB | shell navigation | Bottom nav has 3 items and right rounded-square FAB remains default. | Existing tests/build. | DONE |

## Verification Evidence

- Screenshot reference inspected: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-084623.png`.
- `flutter test test/widget_test.dart test/transactions/header_layout_test.dart test/transactions/category_menu_test.dart test/transactions/transaction_home_limits_test.dart test/transactions/transaction_widgets_test.dart test/stats/stats_page_test.dart test/settings/expense_theme_test.dart test/settings/settings_bridge_test.dart test/settings/settings_page_test.dart test/settings/push_notification_log_page_test.dart test/shell/bottom_nav_item_test.dart` -> 220/220 passed.
- `flutter test test/settings/backheader_style_options_panel_test.dart test/transactions/magnet_strip_test.dart test/transactions/header_card_test.dart` -> 32/32 passed.
- `flutter analyze` -> no issues found.
- Local `./gradlew testDebugUnitTest --tests com.exptv2.app.expense.ExpenseSettingsStoreSecurityTest` did not reach tests in this environment: `:app:processDebugResources` failed because AAPT2 daemon startup failed. GitHub Actions build remains required for Android build proof.
- Stale production symbol search run for removed category overlay/presentation/shadow keys; remaining matches are negative/legacy tests only.
