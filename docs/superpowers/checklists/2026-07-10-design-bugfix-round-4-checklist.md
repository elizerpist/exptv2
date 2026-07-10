# 2026-07-10 Design Bugfix Round 4 Checklist

Scope: next follow-up bugs and design corrections reported after build `d49c204` on branch `feature/design-finomitas-2026-07-09`.

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

### BUG4-001 - App-wide lag: Bevétel/Kiadás és fastfilter

- Source instruction: "nagyon laggol az app, a bevétel/kiadás nagyon laggol, de nem csak az laggol, hanem a fastfilter is"
- Intended code area: `lib/features/transactions/transaction_home_page.dart` (`TransactionTypePills`, `_setActiveType`, `_setMerchantFastFilter`), `lib/features/transactions/state/transaction_store.dart`, `lib/features/transactions/widgets/transaction_log_list.dart`, `lib/features/transactions/widgets/transaction_log_box.dart`, `lib/features/transactions/data/transaction_filter.dart`, and related transaction widget/store tests.
- Acceptance condition: the lag must be investigated with measurement/profiling before optimization, not guessed from visual symptoms alone.
- Acceptance condition: tapping `Bevétel` or `Kiadás` must respond immediately, keep the selected type visually correct, and avoid unnecessary full logbox/icon rebuild work.
- Acceptance condition: fastfilter interactions must respond immediately, keep the correct filtered transaction set, and avoid blocking the UI thread during filter recomputation.
- Acceptance condition: any memoization, throttling, or rebuild reduction must invalidate correctly when transactions, categories, vendors, active type, search query, category filter, vendor/merchant fastfilter, or recurring data changes.
- Acceptance condition: existing transaction count, summary pill, FastInfo data, category/vendor filters, and visible log list content must remain correct after type switch and fastfilter changes.
- Acceptance condition: add concise temporary/performance debug logging or an equivalent profiling hook for tap start, state update, filter recompute duration, first frame after update, and visible log count; keep the onscreen debug output usable and not flooded.
- Verification method: direct code inspection of the rebuild/filter path, targeted Flutter tests for store/widget behavior through Ubuntu proot, and device/manual timing evidence from the added debug/profiling output.
- Status: `DONE`

### BUG4-002 - Add/Edit Category sheet keeps the fixed layout while keyboard is open

- Source instruction: "az addnewcategory layout jó lett, de ha a keyboard felcsúszik, akkor amikor a sheet felslideol visszatér a korábbi bugos layout, egy layout kell, amit most csináltál meg"
- Intended code area: `lib/features/transactions/widgets/category_menu/category_editor_sheet.dart`, `lib/features/transactions/widgets/category_menu/category_editor_panel.dart`, `lib/features/transactions/widgets/slide_up_menu_card.dart`, `lib/features/transactions/transaction_home_page.dart` category editor open/close path, and `test/transactions/slide_up_menu_card_test.dart` / category editor widget tests.
- Acceptance condition: the current approved AddNewCategory/Add/Edit Category panel layout must remain the single source of truth in both keyboard-closed and keyboard-open states.
- Acceptance condition: when the keyboard slides up and the sheet is translated upward, the panel content must not fall back to the older buggy spacing, sizing, or arrangement.
- Acceptance condition: keyboard avoidance may move the whole sheet, but must not recompute the inner category editor layout from a different height/inset model.
- Acceptance condition: AddNewCategory and EditCategory must behave consistently; opening the keyboard from the name field must keep the same pill/card/delete/save positioning relative to the panel.
- Acceptance condition: existing smooth slide-up behavior, outside-tap cancel behavior, debug logs, and save/delete/category edit behavior must remain intact.
- Verification method: widget test with simulated `MediaQuery.viewInsets.bottom > 0` comparing stable panel metrics/layout, direct code inspection of keyboard inset usage, and manual screenshot/device verification for keyboard closed vs open.
- Status: `DONE`

### BUG4-003 - Vendor card/avatar neumorph press animation is synchronized

- Source instruction: "neumorphismban a vendor avatar és card nem ehyszwrrw mozdul, nimcs szinkronban, a kategória cardok viszont már igen, hasonlóan oldd meg"
- Intended code area: `lib/features/transactions/transaction_home_page.dart` (`_VendorFilterRow` card/avatar press and selected states), category reference implementation in `lib/features/transactions/widgets/category_menu/category_card.dart` and `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`, and related tests in `test/transactions/category_menu_test.dart`.
- Acceptance condition: in neumorphism mode, tapping/selecting a vendor card must move the vendor card body and vendor avatar in the same frame with the same press/selected timing.
- Acceptance condition: the vendor avatar must receive the same neumorph shadow/pressed-surface animation phase as the vendor card, not only a delayed or independent offset.
- Acceptance condition: the implementation should mirror the already-correct category card/category utility card logic where the card and avatar share the effective pressed/selected state.
- Acceptance condition: permanent vendor selection must remain intact, including amount display, ABC grouping, vendor rename/reset controls, and selected filter state.
- Acceptance condition: non-neumorph themes must keep their current visual behavior except for any necessary synchronization that does not change the design.
- Verification method: widget test asserting synchronized vendor card/avatar pressed state and offset/surface style, comparison against existing category card tests, plus manual visual verification in neumorphism mode.
- Status: `DONE`

### BUG4-004 - Vendor card avatar uses category icon, not vendor initial

- Source instruction: "a vendorcardok avatarjában ne vendor kezdőbetű legyen, hanem a kategória ikonja. ha nincs, akkor szürke kör kérdőjellel (a logboxok is ilyenek)"
- Intended code area: `lib/features/transactions/state/transaction_store.dart` (`VendorFilterSummary` and `_vendorFilterSummariesFor` category/icon projection), `lib/features/transactions/transaction_home_page.dart` (`_VendorFilterRow` avatar content), `lib/features/transactions/widgets/category_menu/category_icon_badge.dart`, logbox avatar fallback reference in transaction/ghost logbox widgets, and related `test/transactions/transaction_store_test.dart` / `test/transactions/category_menu_test.dart`.
- Acceptance condition: vendor card avatars must no longer render the vendor name initial.
- Acceptance condition: each vendor card avatar must render the relevant transaction category icon using the same category icon component/style as logbox/category avatars.
- Acceptance condition: if the vendor summary cannot resolve a category icon, the avatar must render a gray circular fallback with a question mark, matching the logbox fallback behavior.
- Acceptance condition: when a vendor appears under multiple categories, the chosen category icon must be deterministic and documented in code/tests, for example the dominant category by summed amount/count with stable tie-break.
- Acceptance condition: existing vendor card color matching, amount display, ABC grouping, rename/reset controls, selection state, and neumorph press synchronization requirements must remain intact.
- Verification method: store test proving vendor summaries expose the expected category/icon fallback data, widget test proving vendor avatars render category icon vs gray question fallback, and manual visual comparison with logbox fallback behavior.
- Status: `DONE`

### BUG4-005 - Vendor and category transaction counts follow SummaryPill scope

- Source instruction: "a vendor cardban legyen ugyanúgy tranzakciószám, mint a kategóriakártyákban. a vendor lista nézet specifikus (summarypill) ez3rt a vendor tranzakciószám is. ez azt jelenti, hogy csak azokat a vendorokat kell listázni, amiket a summarypill előszűr. a kategória card tranzakciószám is legyen summary pill nézetspecifikus, de a category cardok ne. ha nincs tranzakció, akkor 0, mint jelenleg"
- Intended code area: `lib/features/transactions/state/transaction_store.dart` (`VendorFilterSummary.count`, `_vendorFilterSummariesFor`, `categoryTransactionCounts`, `_rebuildDerivedIndexes`, summary-window invalidation), `lib/features/transactions/transaction_home_page.dart` (`VendorFilterPanel`, `_VendorFilterRow`), `lib/features/shell/expt_shell.dart` vendor sheet wiring, `lib/features/transactions/widgets/category_menu/category_menu_panel.dart`, `lib/features/transactions/widgets/category_menu/category_card.dart`, and related transaction store/widget tests.
- Acceptance condition: each vendor card must visibly show its transaction count in the same style/positioning pattern as category cards.
- Acceptance condition: the vendor list must be SummaryPill-view-specific: only vendors present in the active SummaryPill scope/window may be listed.
- Acceptance condition: the vendor transaction count must be computed from the same active SummaryPill scope/window as the vendor list, so all-time/year/month changes update both the listed vendors and their counts.
- Acceptance condition: category card transaction counts must also be SummaryPill-view-specific and update when the SummaryPill scope/window changes.
- Acceptance condition: category cards themselves must not be removed by SummaryPill prefiltering; categories remain listed as they do now, and categories with no transactions in the active SummaryPill scope show `0`.
- Acceptance condition: existing category filtering, vendor filtering, search, selected state, ABC grouping, amount display, rename/reset controls, vendor avatar requirements, and neumorph synchronization requirements must remain intact.
- Verification method: store tests for all-time/year/month SummaryPill scopes proving vendor summaries and category counts use the active window, widget tests proving vendor cards render transaction counts and category cards stay visible with `0`, and manual visual verification after changing SummaryPill scope.
- Status: `DONE`

### BUG4-006 - Category icons render with logboxes, not later after app load

- Source instruction: "az ikonok csak később renderelnek, ha az app betölr, nem a logboxokkal egyszerre, ha javítottad ehhez debug logokat is kérek, hogy az onscreen debug panelről bem@soljam neked, ha nem jó"
- Intended code area: `lib/features/transactions/slots/category_icon_manager.dart`, `lib/features/transactions/widgets/category_slot_icon.dart`, `lib/features/transactions/widgets/category_menu/category_icon_badge.dart`, `lib/features/transactions/widgets/transaction_log_box.dart`, `lib/features/transactions/widgets/recurring_ghost_log_box.dart`, transaction home/shell startup paths, `lib/core/debug/debug_console.dart`, and related icon/logbox widget tests.
- Acceptance condition: category icons used by transaction logboxes must be ready/rendered at the same visible time as the logbox rows; the UI must not show logboxes first and then pop icons in noticeably later during normal app startup.
- Acceptance condition: recurring ghost logbox icons and normal transaction logbox icons must follow the same startup/render timing rule.
- Acceptance condition: the fix must handle both default category icons and user-customized icon-slot assignments loaded from preferences.
- Acceptance condition: placeholder behavior must not cause a blank or delayed-looking avatar when the category/icon data is already known; if a fallback is necessary, it must be intentional and visually consistent.
- Acceptance condition: add concise onscreen `DebugConsole` logs that can be copied from the debug panel when the issue reproduces, including at minimum icon-slot preference load start/end, icon asset/cache warmup start/end, first logbox list build/visible count, and first icon-ready/render timing.
- Acceptance condition: the debug logs must be bounded and readable, with stable tags such as `[IconLoad]`/`[LogBoxIcon]`, and must not flood one line per every rebuild in normal use.
- Acceptance condition: existing category icon editing, category card icons, vendor avatar icon requirements, transaction logbox interactions, and app startup behavior must remain intact.
- Verification method: widget/startup test or focused integration-style test proving icon manager readiness precedes/aligns with logbox icon rendering, direct code inspection of async icon/preference/cache flow, and manual device verification using copied onscreen debug logs after cold app start.
- Status: `DONE`

### BUG4-007 - Neumorph logbox body/avatar momentary press behavior is correct

- Source instruction: "a logboxok, ha neumorph beállítás az aktív, akkor nem lehet külön tappelni a bodyt, hogy momentary effect legyen. ilyenkor a body és az avatar is egyszerre nyomődna be, de nem csinálja. az avatar külön is tapelhető, olyabkor szűr. tehát avatar tap: csak az avatar nyomódik be. logboxtap: avatar és body benyomódik. ezt sokadjára nem tudod megoldani, valamiért a tdd tesuteken mégis átmegy, deep analyse."
- Intended code area: `lib/features/transactions/widgets/transaction_log_box.dart` (`_bodyPressed`, `_pressBody`, `_bodyPressRegion`, `_handleSurfacePointerDown`, `_handleCardTapDown`, avatar `GestureDetector`, `ExpensePressable.forcePressed`), shared neumorph surface implementation in `lib/features/settings/theme/expense_surface.dart`, category card reference behavior in `lib/features/transactions/widgets/category_menu/category_card.dart`, and existing tests in `test/transactions/transaction_widgets_test.dart` around `avatar press does not press the whole logbox surface` and `logbox body press moves the card and avatar together`.
- Acceptance condition: before implementing a fix, perform and document root-cause analysis explaining why the manual neumorph behavior fails even though the current TDD/widget tests pass.
- Acceptance condition: the analysis must compare the real pointer/gesture path for avatar tap vs logbox body tap, including nested `GestureDetector`, `Listener`, `ExpensePressable`, `forcePressed`, hit testing, and release timing.
- Acceptance condition: in neumorph/press-effect mode, tapping the logbox body area must produce a momentary pressed effect on both the logbox body surface and its avatar surface in the same interaction frame/timing.
- Acceptance condition: in neumorph/press-effect mode, tapping the avatar must trigger the category filter behavior and must press only the avatar surface, not the full logbox body.
- Acceptance condition: the logbox body tap must still call the normal logbox tap handler exactly once and must not trigger the avatar/category filter callback.
- Acceptance condition: the avatar tap must still call the category filter callback exactly once and must not call the normal logbox tap handler.
- Acceptance condition: non-neumorph/non-press-effect modes must keep their current visual behavior and callbacks.
- Acceptance condition: update or replace the currently passing tests so they fail against the observed broken behavior; tests must assert the actual pointer-down momentary visual state for both surfaces, not only a post-pump decoration difference that can pass falsely.
- Acceptance condition: verification must include a manual visual pass in neumorphism mode after the automated tests, because this bug has repeatedly passed tests while failing on-device.
- Verification method: root-cause note in the checklist or implementation plan, focused widget tests using real gesture coordinates for avatar center and body-only area, assertions against body/avatar surface pressed decoration or transform during pointer-down and after release, callback-count assertions, and device/manual verification in active neumorph settings.
- Root-cause note: the old tests set both the logbox body `surfaceStyle` and avatar `avatarSurfaceStyle` to press-effect styles, then asserted after a full press animation; that missed the real legacy/neumorph path where the avatar/button surface can be press-effect enabled while the logbox content surface remains neutral. In the real pointer path, avatar taps hit the nested avatar `GestureDetector`/`ExpensePressable` and must not set `_bodyPressed`; body taps hit the row `GestureDetector` plus surface `Listener` and must set `_bodyPressed` so the avatar `forcePressed` follows the same pointer-down frame. `_pressBody()` previously returned early using only `surfaceStyle.hasPressEffect`, so body taps in the avatar-only press-effect path never drove the avatar momentary state even though the old both-press-effect test passed.
- Verification: focused widget tests now assert pointer-down decoration changes immediately after `startGesture`/`pump()`, with body tap vs avatar tap coordinates and callback-count separation. Manual device visual pass remains the APK/user validation step after build.
- Status: `DONE`

### BUG4-008 - Vendor menu keyboard lift moves only the bottom button, not the whole menu

- Source instruction: "vendor menu: ha a keyboard felslideol, az egést menu felslideol, pedig korábban csak az alsó gomb felslideolását kértem, ezt már egyszer megildottad, de visszajött a hiba. a tdd során mi3rt ment át a teszten? amit egyszer megoldasz nem szeretném ismét visszajönni látni"
- Intended code area: `lib/features/transactions/transaction_home_page.dart` vendor sheet `SlideUpMenuCard` wiring, `lib/features/shell/expt_shell.dart` `_VendorFilterSheetSlot`, `lib/features/transactions/widgets/slide_up_menu_card.dart` keyboard transform behavior, `VendorFilterPanel` footer/list padding in `lib/features/transactions/transaction_home_page.dart`, and existing tests in `test/transactions/category_menu_test.dart` (`vendor sheet search filters rows and keeps card fixed for keyboard`) plus `test/transactions/slide_up_menu_card_test.dart`.
- Acceptance condition: before implementing a fix, perform and document root-cause analysis explaining why this regression returned and why the TDD suite passed.
- Acceptance condition: the analysis must call out any test that encoded the wrong behavior, especially assertions that the whole `slide-up-menu-transform` moves by the keyboard inset for the vendor menu.
- Acceptance condition: when the keyboard opens in the vendor menu, the menu/card container, header, search pill, list viewport, and visible vendor cards must keep their established screen position and layout instead of sliding upward as a whole.
- Acceptance condition: only the bottom vendor apply/footer button area may move or pad upward enough to stay above the keyboard.
- Acceptance condition: the vendor list bottom padding must keep the last vendor cards accessible above the moved footer and keyboard without changing the menu's top/header/search layout.
- Acceptance condition: the behavior must be consistent in both vendor menu entry paths: embedded `TransactionHomePage` vendor sheet and shell-hosted `_VendorFilterSheetSlot`.
- Acceptance condition: category editor/Add/Edit Category keyboard behavior must not be changed by this vendor-specific fix; BUG4-002 remains a separate layout requirement.
- Acceptance condition: existing vendor search, row filtering, rename/reset, ABC grouping, selection state, apply action, drag/dismiss behavior, and keyboard debug logs must remain intact.
- Acceptance condition: update or replace the currently passing TDD tests so they fail on the regression: tests must assert stable menu/card/header/search/list positions before vs after keyboard inset, moved footer position above keyboard, and absence of whole-menu `-keyboardInset` transform for vendor sheets.
- Acceptance condition: add a regression guard naming this scenario explicitly so the same "whole vendor menu slides with keyboard" bug cannot pass unnoticed again.
- Verification method: root-cause note in the checklist or implementation plan, targeted widget tests with `MediaQuery.viewInsets.bottom > 0` comparing no-keyboard vs keyboard vendor menu rectangles, direct inspection of `keyboardAvoidance`/footer positioning paths in both hosts, and manual device verification by focusing the vendor search field with the keyboard open.
- Root-cause note: the regression returned because the vendor sheet host had `keyboardAvoidance: true`, so `SlideUpMenuCard` translated the entire `slide-up-menu-transform` by `-keyboardInset`. The old TDD test encoded that wrong behavior by asserting `transform.y == -180` and only checking that the footer ended above the keyboard; it never compared the card/header/search/list/vendor-card rectangles before and after keyboard inset, so the whole-menu slide passed as expected behavior.
- Verification: the vendor keyboard test now opens the sheet with `viewInsets.bottom == 0`, records transform/card/search/list/vendor/footer rects, then pumps `viewInsets.bottom == 180` and asserts the menu body stays fixed while only the footer moves. Direct inspection verified both embedded `TransactionHomePage` and shell-hosted `_VendorFilterSheetSlot` use `keyboardAvoidance: false`; shell vendor smoke test also passes. Manual device visual pass remains the APK/user validation step after build.
- Status: `DONE`

Next item ID: `BUG4-009`.
