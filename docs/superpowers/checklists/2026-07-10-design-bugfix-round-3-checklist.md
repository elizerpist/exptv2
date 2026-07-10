# 2026-07-10 Design Bugfix Round 3 Checklist

Scope: follow-up bugs and design corrections reported after build `4e9ed54` on branch `feature/design-finomitas-2026-07-09`.

Workflow:
- Do not implement or edit app code while the user is still listing bugs.
- Add every reported bug/change request as a separate stable requirement ID.
- Start coding only after the user explicitly says to implement.
- Commit each completed checklist item separately after its verification passes.
- Push only once after all checklist items are implemented, verified, and committed.
- Run one final GitHub Actions Android build after the final push, not after each small change.
- Download the final APK to `/storage/emulated/0/Download/exptv2`.
- Completion requires every item to be `DONE`, or an explicit user-approved deferral.

Status values: `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`.

## Items

### BUG3-001 - Add/Edit transaction sheet egyenletes mezőközi padding

- Source instruction: "last screenshot: addnew (edit) transaction sheet: a mentés gomb és a date/timepicker pillek közt lett padding, amit úgy oldottál meg, hogy lejjebb vitted, de most túl nagy gap lett a category selector, és a date/timepicker pillek közt. ezért a tranzakció meve pillet, az összeg pillt, és a category selector pillt lejjebb kell helyezned, mert azt akarom hogy mindenhol ugyanannyi legyen a padding. tehát lejjebb viszed a date/time picker feletti contentet. hogy elkerüljük, hogy emiatt a gap megjelenik a névpill és a sheet teteje közt, azért a sheet magasságát annyival csökkentsd, mert a sheet teteje és a névpill közti padding jó"
- Approved screenshot/reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260710-083039.png`
- Intended code area: add/edit transaction sheet shared layout in `AddTransactionSheet`; transaction sheet closed height in `SlideUpPanelMetrics`; form body `Spacer()`/field spacing; date/time row; save footer positioning.
- Acceptance condition: the vertical padding between `Tranzakció neve`, `Összeg`, `Kategória`, date/time picker row, and `Mentés` must use the same visual spacing rhythm throughout the add/edit transaction sheet.
- Acceptance condition: the oversized gap between the category selector pill and the date/time picker pills must be removed by moving the content above the date/time row downward toward the date/time row.
- Acceptance condition: the existing correct gap between the sheet top/title area and the `Tranzakció neve` pill must not grow; if content is moved downward, the sheet closed height must be reduced by the same amount needed to preserve that top spacing.
- Acceptance condition: the `Mentés` button must keep the clear padding above it that was fixed in BUG2-014 and must remain directly above the bottom safe zone/footer.
- Acceptance condition: the fix must apply to both add-new and edit transaction sheets, income and expense modes, with and without keyboard visible.
- Acceptance condition: the fix must not reintroduce overflow, clipping, or full-sheet scrolling in the closed transaction editor layout.
- Verification method: inspect the approved screenshot and current layout; update/add widget tests that measure top/title-to-name spacing, name-to-amount spacing, amount-to-category spacing, category-to-date/time spacing, and date/time-to-save spacing; verify the form keeps consistent spacing and the closed panel height change preserves the top gap; run transaction editor and slide-up sheet regression tests.
- Status: DONE

### BUG3-002 - Logbox header bal oldali felesleges dátum eltávolítása

- Source instruction: "a logbox area tetején van a tranzakciószám középen. ez jó, azonban bal oldalra raktál egy felesleges 2026 05 22 dátumot, azt szedd ki"
- Approved screenshot/reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260710-083039.png`
- Intended code area: transaction list/logbox header row below the search pill; `_TransactionListHeader`; transaction count/date header layout tests.
- Acceptance condition: the centered transaction count in the logbox header area remains visible and centered.
- Acceptance condition: the extra left-side date label such as `2026 05 22` above the logbox area is removed.
- Acceptance condition: real per-group/date separators inside the transaction log list, such as transaction date section titles above log cards, must remain unchanged.
- Acceptance condition: removing the left label must not shift the centered transaction count away from the horizontal center.
- Acceptance condition: all filter/scope states that show the transaction count header must keep the same centered count behavior without rendering the removed left date placeholder.
- Verification method: add/update widget tests that assert `transaction-list-header-count` is centered and visible while the header date placeholder is absent; verify real log date section headers still render where transactions are grouped by date.
- Status: DONE

### BUG3-003 - Logbox fehér ikon villanás és külön újrarender megszüntetése

- Source instruction: "a logboxok fehér ikonjai minden frissítéskor, töltéskor villannak, valószínűleg újrarenderelnek, ezeknek csak 1x kell renderelniük, az app betöltésekor, ugyanúgy ahogy a logboxok, azokkal együtt kell renderelniük 1x. ne legyen villanás. logbox render logika=ikon render logika, no rerender"
- Approved screenshot/reference:
- Intended code area: transaction logbox rendering; logbox avatar/icon widget; category custom icon resolution/cache; `CategoryIconBadge`/icon slot manager; transaction list refresh/rebuild path; keys and repaint/rebuild boundaries around logbox/avatar.
- Acceptance condition: white logbox icons must not flash/flicker during app load, transaction list refresh, filter changes, scope changes, or type switches.
- Acceptance condition: logbox icon render lifecycle must be tied to the logbox render lifecycle; icons must not use a separate delayed or repeated render path that paints after the logbox body.
- Acceptance condition: each visible logbox icon should render with its logbox on the first visible frame for that logbox, not as a second-phase update.
- Acceptance condition: refreshing or rebuilding the transaction list must not unnecessarily recreate/repaint stable white icon widgets when the underlying logbox/category/icon slot data did not change.
- Acceptance condition: custom category icon resolution remains correct and does not fall back to blank/old/default icons to avoid flicker.
- Acceptance condition: any memoization/cache introduced must invalidate correctly when category icon slot data, category color/icon assignment, or the represented transaction changes.
- Verification method: inspect the full logbox and icon render path; add debug/test instrumentation or widget tests that pump list load and refresh states and assert the icon widget path is present together with the logbox on the first frame, does not switch from placeholder to final icon, and is not rebuilt/recreated on unrelated refreshes; manually verify the affected screen for no white icon flicker.
- Status: DONE

### BUG3-004 - Vendor selector category card szerű grid design

- Source instruction: "vendor selector menu: át kell tervezned a vendorcardok designját. miután itt is permanens select van, ezért a logika inkább a category menu categorycardok logikájával azonos, ezért a design category card szerű design legyen. a vendorcardok színe pedig mindig a categorycardok színével egyezzen. azaz ne széles legyen, és grid szerű felsorolás legyen. az abc tagolás maradjon"
- Approved screenshot/reference:
- Intended code area: vendor selector sheet/panel; vendor card widget/layout; vendor selected-state neumorph/permanent press behavior; category menu `CategoryCard`/grid layout as design reference; vendor ABC section grouping; theme color mapping for category card surface.
- Acceptance condition: vendor cards in the vendor selector menu must no longer use the current wide row/card layout.
- Acceptance condition: vendor cards must use a category-card-like compact card design and be arranged in a grid-style listing.
- Acceptance condition: vendor permanent selected state must follow the same design logic as selected category cards, including neumorph permanent pressed behavior when the relevant surface style is active.
- Acceptance condition: vendor card base/background color must always use the same source/theme token as category cards, not log cards and not a separate vendor-specific color.
- Acceptance condition: vendor cards must continue to show the vendor amount using the previously requested log-card amount sign/color design, even after the card layout changes to grid/category-card style.
- Acceptance condition: the existing ABC grouping/tagolás remains visible and functional above the grid groups.
- Acceptance condition: vendor sorting, search filtering, selection toggling, selected count/apply behavior, and keyboard-safe footer behavior from previous fixes must continue to work.
- Acceptance condition: the grid layout must work on mobile widths without text overflow, card overlap, or footer/list clipping.
- Verification method: inspect category menu card/grid implementation and reuse/mirror the relevant design logic where appropriate; add/update widget tests that open the vendor selector, assert vendor cards render as grid tiles under ABC headers, assert card color equals category card color, assert selected vendor uses the category-card-like permanent selected style, and verify search/filter/apply/keyboard footer regressions still pass.
- Status: DONE

### BUG3-005 - Summary pill neumorph beolvad a globális neumorph beállításba

- Source instruction: "a summarypill neumorph tulajdonsága a globális neumorph beállításba kerüljön, ne külön opció legyen a témabeállításokban"
- Approved screenshot/reference:
- Intended code area: theme settings UI; `AppThemeSettings` summary pill surface setting; `ExpenseTheme` surface style mapping; transaction home and stats summary pill rendering; settings serialization/hydration tests.
- Acceptance condition: the theme settings UI must no longer expose a separate summary pill neumorph option.
- Acceptance condition: summary pill neumorph behavior must be controlled by the global neumorph/button surface setting.
- Acceptance condition: when global neumorph is enabled, transaction home and stats summary pills use the neumorph/press behavior consistently.
- Acceptance condition: when global neumorph is disabled, transaction home and stats summary pills use the normal/non-neumorph behavior.
- Acceptance condition: removing the separate summary pill option must not break loading old persisted settings that still contain `summaryPillSurfaceStyle`; old saved values should be ignored, migrated, or safely tolerated.
- Acceptance condition: settings round-trip/serialization must not reintroduce an independent user-facing summary pill neumorph choice.
- Verification method: update settings UI and settings store/serialization tests to assert the separate summary pill option is absent, global neumorph changes summary pill surface behavior, old settings payloads with summary pill fields hydrate safely, and both home/stats summary pills follow the global setting.
- Status: DONE

### BUG3-006 - Vendor card inline név szerkesztés, log átnevezés és reset

- Source instruction: "a vendorcardokból elfelejtettem írni, hogy attól függetlenül, hogy a design változik, a többi nem. azaz összeget továbbra is írni kell a megadott módon. azonban adj hozzá új feature-t: ha a user a vendor nevére tappel, akkor a név változtatható, ezt nem kell külön sheetben megoldani, annyi vizuál kell hozzá, hogy a név area kap egy highlight keretet, amiben villog a cursor a név utolsó betűjénél. user ezt editálhatja. a keyboard slide up logika nem változik ilyenkor sem, de arra felhívom figyelmed, hogy a vendor sheetben amikor a keyboard felslideol laggol az alsó gomb felslideolása, nem követi natívan a keyboardot. ha a user vendor nevet változtat, akkor az összes adott tranzakció logban is megváltozik a név. és a vendorcatdban megjelenik ugyanaz a revert original vendor name ikon, amivel ezt resetelheti"
- Approved screenshot/reference:
- Intended code area: vendor selector card/name area; vendor sheet keyboard/footer animation; transaction store/repository vendor rename path; logbox display merchant/user-assigned vendor name logic; vendor card reset/revert icon; native bridge/database update path for affected transactions.
- Acceptance condition: changing vendor card design must not remove the vendor amount; amount sign/color formatting from previous vendor amount fix remains visible and correct.
- Acceptance condition: tapping the vendor name area in a vendor card enters inline edit mode on that card without opening a separate sheet.
- Acceptance condition: inline edit visual state shows a highlight border around the name area and a text cursor positioned at the end of the current vendor name.
- Acceptance condition: the user can edit the vendor name directly from the vendor card, using the keyboard.
- Acceptance condition: keyboard behavior in the vendor sheet remains fixed-card/keyboard-safe; the lower apply/settings button and its white footer area must follow the keyboard natively/smoothly without visible lag.
- Acceptance condition: committing a vendor rename updates the displayed vendor name for every transaction log belonging to that original vendor.
- Acceptance condition: after a vendor rename, affected logboxes and vendor cards show the renamed vendor consistently across refreshes, filters, search, type switches, and sheet reopen.
- Acceptance condition: renamed vendor cards show the same revert-original-vendor-name icon/action used elsewhere in the app for resetting a user-assigned vendor name.
- Acceptance condition: tapping the revert icon resets the vendor name back to the original vendor name for all affected transaction logs and removes the renamed state from the vendor card.
- Acceptance condition: rename and revert operations must not break vendor selection/filtering state, ABC grouping, vendor search, or amount aggregation.
- Verification method: inspected existing log rename/user-assigned vendor name and revert icon implementation; added/updated widget tests that tap a vendor card name, assert inline edit cursor/focus, enter a new name, verify affected logboxes and vendor cards update, then tap revert and verify original names return; verified vendor amount/grid/search/ABC and keyboard-inset footer regressions still pass; verified store bulk rename/reset tests still pass. Full keyboard slide lag deep analysis remains tracked separately under BUG3-009.
- Status: DONE

### BUG3-007 - Transaction logbox body momentary neumorph press regresszió

- Source instruction: "neumorph bug: ha a neumorph beállítás aktív, akkor a transaction logbox tap nem kapja meg a kért momentary benyomódást. ilyebkor be kell nyomódnia a transaction cardnak, és az avatarnakbis egyszerre. de az avatar külön is tappelhető (mint jelenleg) az jó. csak a logbox \"body\" neumorph nem működik."
- Approved screenshot/reference:
- Intended code area: `TransactionLogBox` gesture handling; logbox body pressed-state logic; avatar pressed-state/offset coupling; `ExpensePressable`/surface style handling for logbox content; transaction card tap vs avatar-only tap hit testing.
- Acceptance condition: when global/button neumorph mode is active, tapping the transaction logbox body triggers a momentary inward neumorph press on the transaction card body.
- Acceptance condition: during a body tap, the logbox avatar moves/presses visually together with the transaction card body.
- Acceptance condition: the momentary pressed state releases after tap/pointer release and returns to normal.
- Acceptance condition: avatar-only tap behavior remains unchanged: tapping the avatar still triggers only the avatar tap/filter path and must not press the whole logbox body.
- Acceptance condition: body tap still fires the existing transaction open/edit callback exactly once and is not delayed or swallowed by the press animation.
- Acceptance condition: non-neumorph mode keeps the normal current logbox tap behavior.
- Verification method: updated widget tests that enable neumorph press style, press the logbox body and assert the body surface and avatar pressed decoration activate together, then release and assert both return to normal and edit/open fires once; verified avatar-only press/filter still does not press the body. Ran full `test/transactions/transaction_widgets_test.dart`.
- Status: DONE

### BUG3-008 - Category card és add-new avatar neumorph animáció szinkron

- Source instruction: "neumorph bug 2: a category cardokon a tap permanens benyomódást triggerel. ilyebkor be kéne nyomódnia a cardnak és az avatarnak is egyszerre. ez késve történik meg, nem egyszerrw animál. az addnew category card plusz avatar benyomódik egyszerre, de az avatar csak lefele mozog, nem kap árnyék animációt, oldd meg hogy kapjon"
- Approved screenshot/reference:
- Intended code area: category menu `CategoryCard`; category utility/add-new card; selected/permanent pressed state; avatar `ExpenseSurfaceContainer` pressed state; card/avatar animation timing and curves; category card tests.
- Acceptance condition: in active neumorph mode, tapping/selecting a category card triggers the permanent inward pressed state on the card body and avatar at the same time.
- Acceptance condition: the category card body and avatar animation must start together, use matching press duration/curve, and not show a visible delay between body and avatar.
- Acceptance condition: selected category cards keep the intended permanent pressed state after selection until apply/selection changes.
- Acceptance condition: the add-new category card plus avatar must receive the actual avatar surface/shadow pressed animation, not only a downward position offset.
- Acceptance condition: add-new category card avatar offset and shadow/depth animation must be synchronized with the card press animation.
- Acceptance condition: normal/non-neumorph category card selection behavior remains unchanged.
- Verification method: add/update widget tests that select a neumorph category card and assert card surface and avatar surface enter pressed state in the same frame; test the add-new category card press and assert the plus avatar has both offset and pressed decoration/shadow change, then returns after release; verify no active-border regressions in normal mode.
- Status: NOT DONE

### BUG3-009 - Category/vendor sheet keyboard slide lag deep analysis és debug logok

- Source instruction: "az addneecategory/edit category esetében is a keyvoard felfele slideot triggerel. de itt is laggol a felfele slide a sheetnek, nem smooth, nem követi pontosan. oldd meg, hogy pontosan kövesse. ehhez, és a vendor keyboard slide laghoz is debug logokat adj, de ehhez ki kell tisztítanod az onscreen debug screent, mert megtelik hamar. ne csak debug log legyen, hanem deep amalyse, és javítás is"
- Approved screenshot/reference:
- Intended code area: add-new/edit category sheet keyboard handling; vendor sheet keyboard handling; `SlideUpMenuCard` keyboard avoidance/lift path; sheet footer positioning; debug console/log buffer; keyboard inset measurement and animation frame timing.
- Acceptance condition: before measuring or reproducing this bug, the on-screen debug console/log buffer must be cleared so keyboard slide logs are readable and not mixed with old noise.
- Acceptance condition: add-new category sheet and edit category sheet must follow keyboard upward movement smoothly and precisely, without delayed/lagging sheet movement.
- Acceptance condition: vendor sheet keyboard behavior must also be fixed so the bottom button/footer follows the keyboard smoothly and precisely without visible lag.
- Acceptance condition: the fix must be based on documented deep analysis of the full keyboard/layout chain, including `MediaQuery.viewInsets`, shell/scaffold resize behavior, `SlideUpMenuCard` translation, sheet-local footer positioning, animation durations/curves, and any frame-delayed state updates.
- Acceptance condition: debug logs must be added around the keyboard path for category sheets and vendor sheet, including focus request, keyboard inset changes, sheet/card/footer target offset, applied transform/padding, frame timing, and elapsed milliseconds.
- Acceptance condition: debug logs must make it possible to tell whether lag comes from delayed inset propagation, `AnimatedPadding`/implicit animation duration, sheet transform, footer-only movement, focus timing, or setState/post-frame scheduling.
- Acceptance condition: the debug logging must be concise enough not to immediately flood the on-screen debug panel during normal use; repeated inset/frame logs should be throttled or emitted only on meaningful changes.
- Acceptance condition: category editor sheet fixes must not break add/edit category form layout, icon selector flow, save button/footer safety, or sheet drag/dismiss behavior.
- Acceptance condition: vendor sheet fixes must not break vendor search, inline rename from BUG3-006, grid layout from BUG3-004, ABC grouping, selection/apply behavior, or fixed-card keyboard-safe layout.
- Verification method: clear debug console, reproduce category add/edit keyboard slide and vendor keyboard slide, capture readable timing logs, document root cause, implement fix, then repeat and compare logs; add/update widget tests simulating keyboard `viewInsets` for category and vendor sheets to assert card/footer positions update immediately and final offsets match the keyboard inset without card resize regressions.
- Status: NOT DONE

### BUG3-010 - Recurring transaction Idő/Push bináris selector type-pill design

- Source instruction: "add new recurring transaction idő és push pillek egy bináris selector, ezért ugyanazt a adesignt kapja meg, mint a bevétel kiadás gomb (aktív selected színes, inaktív szürke) ez is része kell legyen a globális neumorph designnak"
- Approved screenshot/reference:
- Intended code area: add/edit recurring transaction sheet; recurring trigger type selector (`Idő`/`Push`) pills; shared transaction type pill design; global button neumorph surface style; recurring manager/widget tests.
- Acceptance condition: the recurring transaction `Idő` and `Push` pills must behave visually as a binary selector, not as unrelated buttons.
- Acceptance condition: the active selected pill must use the same selected colorful design as the `Bevétel`/`Kiadás` transaction type selector.
- Acceptance condition: the inactive pill must use the same inactive gray design as the `Bevétel`/`Kiadás` transaction type selector.
- Acceptance condition: the selector must participate in the global neumorph design setting: when global neumorph is active, active/inactive pills use the same neumorph surface behavior as the transaction type selector; when inactive, normal mode remains normal.
- Acceptance condition: switching between `Idő` and `Push` still updates the recurring trigger mode correctly and does not break the recurring form fields tied to each mode.
- Acceptance condition: active/inactive colors, text contrast, sizing, and spacing must match the transaction type pill design closely enough that the two selectors read as the same component family.
- Verification method: inspect/reuse the transaction type pill component or shared style; add/update widget tests that render the recurring sheet in normal and global neumorph modes, assert selected/inactive `Idő`/`Push` pill colors/surface styles match the `Bevétel`/`Kiadás` selector rules, and verify switching trigger modes still changes form state.
- Status: NOT DONE

### BUG3-011 - Category/Vendor sheet külső tap cancel slide-down bezárással

- Source instruction: "categorysheet/vendorsheet: ha a user kitappel a sheeten kívülre az app más felületérw, akkor az cancel, a sheet bezár, ez a bezárás slide downt triggereljen (az addnewcategory logika ilyen)"
- Approved screenshot/reference:
- Intended code area: category sheet shell host; vendor sheet shell host; `SlideUpMenuCard` veil/tap outside dismissal behavior; cancel/apply state handling; add-new-category sheet dismissal behavior as reference.
- Acceptance condition: when category sheet is open and the user taps outside the sheet on another app surface, the sheet cancels and closes.
- Acceptance condition: when vendor sheet is open and the user taps outside the sheet on another app surface, the sheet cancels and closes.
- Acceptance condition: outside-tap close must trigger the normal slide-down dismiss animation, matching add-new-category sheet behavior.
- Acceptance condition: outside-tap cancel must not apply pending category/vendor selections or filters.
- Acceptance condition: explicit apply/select actions still apply as before and are not treated as cancel.
- Acceptance condition: tapping inside the sheet, including search fields, lists, cards, footer buttons, drag handles, and inline edit fields, must not accidentally dismiss the sheet.
- Acceptance condition: bottom nav/FAB/background controls must not receive their action while the outside tap is being used to cancel the open sheet, unless existing add-new-category behavior explicitly allows it after dismissal.
- Verification method: inspect add-new-category outside-tap dismissal implementation and mirror the relevant slide-down/cancel behavior; add/update widget tests that open category and vendor sheets, tap outside, assert slide-down transform/dismiss animation starts, pending selections are discarded, and inside-sheet taps do not dismiss.
- Status: NOT DONE

## Template

### BUG3-000 - Short Title

- Source instruction: ""
- Approved screenshot/reference:
- Intended code area:
- Acceptance condition:
- Verification method:
- Status: NOT DONE
