# 2026-07-09 Design Bugfix Round 2 Checklist

Scope: follow-up bugs and design corrections reported after build `ec0370b` on branch `feature/design-finomitas-2026-07-09`.

Workflow:
- Do not implement or edit app code while the user is still listing bugs.
- Add every reported bug/change request as a separate stable requirement ID.
- Start coding only after the user explicitly says to implement.
- One final commit and one GitHub Actions build after all checklist items are implemented and verified.
- Completion requires every item to be `DONE`, or an explicit user-approved deferral.

Status values: `NOT DONE`, `PARTIAL`, `BLOCKED`, `DONE`.

## Items

### BUG2-001 - Bevétel/kiadás váltás lag mérhető debug logokkal

- Source instruction: "bevétel-kiadás közti váltás nagyon laggol, nem smooth, m@sodpercek telnek el. hogy javítás ut@n ellenőrizhető legyen, kitisztítod az onscreen debug panelt, és debug logokat adsz hozzá."
- Intended code area: transaction home and stats type switch handlers; `TransactionStore.setActiveType`; transaction type pill tap path; on-screen debug console/log panel.
- Acceptance condition: switching between `Bevétel` and `Kiadás` must respond smoothly without multi-second UI freeze in the affected screens.
- Acceptance condition: before verification, the on-screen debug panel/log buffer is cleared so the switch measurement logs are not mixed with old noise.
- Acceptance condition: debug logs are added around the full type-switch path, including tap received, UI state change requested, store/cache work start/end, visible list rebuild/prewarm start/end, and first frame/update completion.
- Acceptance condition: logs include elapsed milliseconds and enough labels to identify whether lag is caused by UI tap handling, store filtering/cache prewarm, rebuild/layout, or post-frame work.
- Acceptance condition: after the fix, the same on-screen debug panel shows a short, readable switch trace that proves the switch completes within an acceptable interactive window.
- Verification method: reproduce the current lag before fixing, collect baseline debug logs, implement the root-cause fix, clear the on-screen debug panel, repeat income/expense switching several times, and compare the new elapsed timings against the baseline; add targeted automated performance/log-path tests where practical.
- Status: DONE

### BUG2-002 - Summary pill neumorphism setting visszaugrik

- Source instruction: "summary pill neumorpismot nem lehet bekapcsolni, visszaugrik"
- Intended code area: theme settings UI for summary pill surface style; `AppThemeSettings.summaryPillSurfaceStyle`; settings store/bridge serialization and hydration; summary pill rendering in transaction home and statistics.
- Acceptance condition: when the user selects the summary pill neumorph/inward press option in theme settings, the selected option remains active in the UI and does not immediately jump back to normal.
- Acceptance condition: the setting persists through settings submenu reopen, bottom-tab navigation, page rebuild, app/settings reload, and native bridge round-trip.
- Acceptance condition: enabling summary pill neumorphism affects only the summary pill tap surface behavior and remains independent from the global button neumorph setting.
- Acceptance condition: transaction home and statistics summary pills both use the saved summary pill setting consistently.
- Verification method: add/update settings UI and settings store/bridge tests that select summary pill neumorph, assert the UI selection stays active, serialize/deserialize the setting, reload settings, and verify both summary pill widgets receive/use the saved surface style.
- Status: DONE

### BUG2-003 - Log/kategória ikon flicker régi gyári ikon fallback miatt

- Source instruction: "ha az app betölt vagy frissül a log area, a korábbi ikonokat megkapják a logok, nem a custom ikonokat, a rendes custom ikonok csak később renderelnek, ez villanást okoz. ellenőrizd miért nem törölted belőle a korábbi gyári ikonokat. azokat szedd ki, az appban custom ikonok vannak, amiket az ikonslotmanager rendel hozzá logokhoz/kategóriákhoz"
- Intended code area: logbox/category avatar icon rendering; category icon badge; category menu cards; transaction log list; IconSlotManager/custom icon resolution path; any legacy built-in/material/factory icon fallback used before custom icons load.
- Acceptance condition: transaction logs and category cards must render the custom icon assigned by `IconSlotManager` from the first visible frame after app load or log area refresh.
- Acceptance condition: old built-in/factory/default category icons must not render as an intermediate fallback for categories/logs that have a custom icon slot assignment.
- Acceptance condition: if an icon slot is still loading or unavailable, the UI must use a non-conflicting stable placeholder or delay icon paint in a way that prevents flashing the wrong old icon.
- Acceptance condition: remove unused legacy factory icon mapping/render code from the affected log/category path so there is no code noise or accidental fallback to old icons.
- Acceptance condition: refreshing the log area, switching income/expense, changing filters, and reopening the app must not show a one-frame flash of old icons before custom icons appear.
- Verification method: inspect all log/category icon resolution paths for legacy fallback usage; add/update widget tests that pump initial load and refresh states with custom icon slots and assert no legacy icon widget/path appears before or after settle; manually verify with debug logs or frame-by-frame observation if needed.
- Status: DONE

### BUG2-004 - Vendor list gomb ne fókuszálja a search text area-t

- Source instruction: "ha a user a vendor listet triggereki, akkor a searchpill text area is triggerel, fekeslegesen felugrik a billentyűzet. ha tappeli a gombot a search text area ne triggereljen, csak ha kifejezetten oda tappel"
- Intended code area: `SearchPill` hit testing and focus handling; magnifier/vendor list icon button; search `TextField`/focus node; keyboard open behavior.
- Acceptance condition: tapping the search pill magnifier/vendor list button opens only the vendor list sheet.
- Acceptance condition: tapping the vendor list button must not focus the search text field, must not call the search focus request path, and must not open the keyboard.
- Acceptance condition: tapping inside the actual search text input area still focuses the field and opens the keyboard as before.
- Acceptance condition: closing/applying the vendor sheet must not leave the search text field focused unless it was explicitly focused before by tapping the text area.
- Verification method: add/update widget tests that tap `search-pill-vendor-button`, assert vendor sheet callback fires while search focus/keyboard state remains inactive, then tap the text input area and assert focus behavior still works.
- Status: DONE

### BUG2-005 - Tranzakciószám kikerül a search pillből és log headerbe kerül

- Source instruction: "a tranzakciószámot szedd ki a searchpillből. innentől kezdve az mindig látható, ha van category scope, ha nincs, mindegyik nézetben a listázott tranzakciókat mutassa. helye a searchpill alatti terület a tranzakció \"header\" legyen pl 2026 05 31. ez van bal oldalt, a tranzakciószám \"x tranzakció\" középen. a betűméret ugyanakkora legyen mint a dátum."
- Intended code area: `SearchPill` filtered-state layout; transaction log header/date row below search pill; visible transaction count source from `TransactionStore`; all list/filter/scope views.
- Acceptance condition: transaction count text is removed completely from inside `SearchPill`, including filtered category/vendor/search states.
- Acceptance condition: transaction count is always visible in the transaction/log header area below the search pill, regardless of whether a category scope/filter/vendor/search is active.
- Acceptance condition: the count reflects the currently listed/visible transactions in the active view, not total database transactions and not only category-filtered transactions.
- Acceptance condition: the header row keeps the date such as `2026 05 31` on the left, and shows `x tranzakció` centered horizontally in the same row.
- Acceptance condition: the transaction count font size matches the date font size.
- Acceptance condition: after removing the count from `SearchPill`, no empty reserved area remains where the count used to be.
- Acceptance condition: when multiple category/vendor capsules are visible, the capsule horizontal scroll area expands to fill the search pill up to the right edge.
- Acceptance condition: the layout works across all relevant views/states: no filter, category filter, multi-category filter, vendor filter, search query, income/expense type switch, and month/year/sum scopes if they affect the listed transactions.
- Verification method: add/update widget tests that assert `SearchPill` no longer contains `x tranzakció`, the log header contains centered `x tranzakció`, the count updates with filters/removals/type switches, date/count text styles use the same font size, and the capsule scroll area reaches the right side without a blank count gap.
- Status: DONE

### BUG2-006 - Vendor sheet fedje a bottom navot és FAB-ot, ne tüntesse el őket

- Source instruction: "ha a vendor sheet fekslideol, akkor a háttérben maradjon ott a bottom nav, és a fab, ezek ne slideoljanak le, eg,edül arra figyelj, hogy a vendorsheet fedje ezeket. (a category sheet is így működik, ott tudod ellenőrizni)"
- Intended code area: vendor sheet overlay host in `TransactionHomePage`; shell blocking overlay notification; FAB/bottom navigation visibility and z-order; `SlideUpMenuCard` placement; category sheet behavior as reference.
- Acceptance condition: opening the vendor sheet must not hide, slide down, remove, or re-layout the bottom navigation or FAB in the background.
- Acceptance condition: bottom navigation and FAB remain present in the widget tree/background while the vendor sheet is open.
- Acceptance condition: the vendor sheet visually covers the bottom navigation and FAB, so they are underneath the sheet and not interactable through it.
- Acceptance condition: vendor sheet open/close animation affects only the vendor sheet; FAB and bottom navigation must not run their own hide/show slide animation in response.
- Acceptance condition: vendor sheet overlay behavior matches the existing category sheet behavior for background FAB/bottom nav retention and coverage.
- Verification method: inspect category sheet overlay implementation and mirror the relevant shell/overlay handling; add/update widget tests that open vendor sheet, assert bottom nav and FAB are still present, assert vendor sheet bottom covers their hit area/rect, and assert shell nav/FAB transforms do not move during vendor sheet open/close.
- Status: DONE

### BUG2-007 - Vendor sheet saját search pill és keyboard-safe fixed card layout

- Source instruction: "a vendor lista tetején legyen egy searchpill. ha a keyboard feljön az ne az egész k@rtyát tolja fel, csak a beállít@s gombot, a kártya mérete fix marad. a vendorsearchpill tartalmazza hány vendor van, (hasonlóképp mint jelenleg a tranzakciószám a logsearchpillben) fontos hogy ne csak a beállítás gomb menjen fel, hanem a fehér paddingja is, tehát úgy fog viselkesni a card scroll area, mintha annyival kisebb lenne a hasznos területének a magassága amennyivel a keyboard felslideolt"
- Intended code area: vendor filter sheet panel; vendor list header/search pill; vendor search/filter state; keyboard inset handling inside vendor sheet; fixed sheet card sizing; bottom `Szűrőbeállítás` footer/padding; vendor list scroll area constraints.
- Acceptance condition: the top of the vendor sheet contains a vendor search pill above the vendor list.
- Acceptance condition: the vendor search pill can focus text input and filter/search the visible vendor rows if search text is entered.
- Acceptance condition: the vendor search pill displays the vendor count, e.g. `x vendor`, using the vendor list count for the active period/scope and current vendor search query.
- Acceptance condition: when the keyboard appears, the vendor sheet/card outer size and top position remain fixed; the whole card must not be translated upward.
- Acceptance condition: when the keyboard appears, only the bottom `Szűrőbeállítás` button area moves above the keyboard.
- Acceptance condition: the white bottom padding/footer background moves together with the `Szűrőbeállítás` button, not just the button itself.
- Acceptance condition: while the keyboard is visible, the vendor list scroll area's usable height is reduced by the same keyboard inset so list content is not covered by the moved footer.
- Acceptance condition: the vendor search pill, list, footer, and keyboard behavior must not break the vendor sheet drag/scroll rule from BUG2-006/BUG2-013: list scroll remains independent and sheet drag is allowed only from the top state/handle as specified.
- Verification method: add/update widget tests that open vendor sheet, assert vendor search pill and `x vendor` count are visible, enter text and verify vendor rows/count filter, simulate keyboard/viewInsets and assert the sheet card top/height are unchanged while footer button and white padding move above keyboard and list viewport bottom stops above the moved footer.
- Status: DONE

### BUG2-008 - Vendor cardok ABC szerinti tagolása

- Source instruction: "a log areában tagolva vannak dátum szerint a logcardok. a vendor cardok ugyanígy tagolva legyenek a vendor areában, csak abc szerint. az abc designja (mérete a tagoló titleknek) ugyanakkora legyen, mint a dátumtitle-k"
- Intended code area: vendor filter sheet list rendering; vendor card sort/group helper; alphabetical section headers; shared or reused log date section title text style.
- Acceptance condition: vendor cards in the vendor area are grouped into visible alphabetical sections instead of one untagged continuous list.
- Acceptance condition: each alphabetical section header appears above the first vendor card for that letter and follows the same grouping behavior as date separators do above log cards.
- Acceptance condition: vendor cards are sorted alphabetically by displayed vendor name inside the active period/scope and current vendor search query.
- Acceptance condition: accented names and mixed case are grouped consistently by their display name's first alphabetic character; empty or non-letter vendor names use a stable fallback group.
- Acceptance condition: the ABC separator title text size matches the existing log area date separator title text size.
- Acceptance condition: the ABC separator title spacing/alignment visually follows the log area date separator pattern unless the vendor sheet layout requires only proportional vertical spacing.
- Verification method: add/update widget tests with vendors spanning multiple letters, mixed case, accented names, and non-letter names; assert section headers appear in alphabetical order, cards appear under the correct header, search filtering recomputes visible groups, and the header text style font size equals the log date separator font size.
- Status: DONE

### BUG2-009 - Vendor card színe kövesse a logcard színét

- Source instruction: "a vendorcardok színe egyezzen a logcardok színével, ha a user módosít, ez is módosul"
- Intended code area: vendor card rendering in vendor sheet; log card theme/color token; theme settings store/bridge; live theme rebuild path.
- Acceptance condition: vendor card background color uses the same source/theme token as log card background color.
- Acceptance condition: there is no separate hardcoded vendor card background color that can drift from log card color.
- Acceptance condition: when the user changes the log card color/theme setting, vendor cards update to the same color without requiring a separate vendor-specific setting.
- Acceptance condition: the color match holds after settings close/reopen, page rebuild, app reload, and vendor sheet reopen.
- Acceptance condition: selected/highlighted vendor state may add the existing selected-state treatment, but the base card color must still be derived from the log card color.
- Verification method: add/update widget tests that set a custom log card color, open the vendor sheet, assert vendor card background equals log card background, then change the setting and assert both rebuild to the new color; inspect vendor card code to confirm it reads the shared log card color token rather than a local constant.
- Status: DONE

### BUG2-010 - Vendor card összeg design egyezzen a logcard összeggel

- Source instruction: "a vendorcardok összege ne fekete legyen hanem ugyanaz mint a logcardösszegek designja (zöld vs piros + vs - )"
- Intended code area: vendor card amount text rendering; vendor aggregate amount formatter; shared log card amount text style/color helper; income/expense type context for vendor sums.
- Acceptance condition: vendor card amount text must not use plain black/default text color for amounts.
- Acceptance condition: vendor card amount color follows the same visual rule as log card amounts: income/positive amounts use the log card green/positive style, expense/negative amounts use the log card red/negative style.
- Acceptance condition: vendor card amount sign formatting follows the log card design, including `+` for positive/income and `-` for negative/expense where the log cards show those signs.
- Acceptance condition: vendor aggregated totals use the active transaction type/scope correctly so the shown sign/color matches the listed vendor transactions.
- Acceptance condition: any future log amount color/theme change is picked up by vendor card amounts through the same shared style source, without a separate hardcoded vendor amount style.
- Verification method: add/update widget tests with one income vendor total and one expense vendor total; assert vendor amount text sign and color match corresponding log card amount sign/color; inspect vendor amount code to confirm it uses the shared log amount formatter/style rather than a local black text style.
- Status: DONE

### BUG2-011 - Category card neumorph avatar együtt mozogjon a carddal

- Source instruction: "neumorphism: a vendorcardok permanens benyomása jól működik (avatar együtt mozog a carddal) de a categorycardok neumorphismusa nem jó, az avatar nem mozog együtt. ugyanezt a stílust akarom ide is, mozogjanak együtt"
- Intended code area: category sheet/category card pressed and selected neumorph rendering; category avatar wrapper; shared press transform/depth widget used by vendor cards; all/select-all/add-new category cards.
- Acceptance condition: in neumorph mode, selected category cards use the same permanent inward-pressed visual behavior as selected vendor cards.
- Acceptance condition: the category avatar moves visually together with the category card body during the permanent pressed/selected state.
- Acceptance condition: there is no mismatch where the card surface appears pressed but the avatar remains at the normal depth/position.
- Acceptance condition: the behavior applies to regular category cards, the `All`/select-all card, and the add-new-category card if it participates in the same card style.
- Acceptance condition: normal mode behavior remains unchanged: normal selected category cards use the configured highlight border rule, while neumorph selected category cards use permanent inward press without highlight border.
- Verification method: reuse or mirror the vendor card pressed-state implementation for category cards; add/update widget or golden-style tests that compare avatar/card transform/depth state for selected neumorph category cards and assert avatar wrapper receives the pressed state together with the card.
- Status: DONE

### BUG2-012 - Logcard neumorph momentary tap és avatar-only filter tap szétválasztása

- Source instruction: "neumorphism2: a logcardok tapje is legyen momentary reaktív. ilyenkor az avatar együtt mozog a logcarddal (hasonlóan mint a vendorcardok, csak momentary) azonban itt van külön avatar tap-filter feature. ha a user csak az avatart tappeli, akkor csak az avatar nyomódik be, a card nem."
- Intended code area: log card gesture handling; log card neumorph pressed state; log avatar filter button gesture handling; shared pressed-state/depth widget; hit testing between avatar and card body.
- Acceptance condition: in neumorph button mode, tapping the log card body triggers a momentary inward press animation on the whole log card.
- Acceptance condition: during a full log card tap, the avatar moves visually together with the log card body, matching the vendor card pressed-together style but momentary instead of permanent.
- Acceptance condition: tapping only the log card avatar for the avatar filter feature triggers only the avatar's momentary inward press animation.
- Acceptance condition: avatar-only tap must not press, animate, or trigger the full log card tap surface.
- Acceptance condition: the avatar filter behavior remains functional: tapping the avatar still applies the category/vendor filter behavior currently assigned to the avatar.
- Acceptance condition: gesture hit areas do not conflict; taps on avatar are consumed by the avatar path, taps outside avatar on the card body are consumed by the card path.
- Verification method: add/update widget tests that tap the log card body and assert card plus avatar pressed state are active momentarily, then tap the avatar and assert only avatar pressed state and avatar filter callback fire while full card press/callback stays inactive.
- Status: DONE

### BUG2-013 - Header card category gomb animációja egyezzen az add-new-category avatar tappal

- Source instruction: "neumoephism3: a kategory gomb a header cardban m@shogy reagál, van egy fehér outer glowja, ez nem jó, az animáció ugyanolyan legyen, mint az addnewcategory kerek avatar tap"
- Intended code area: header card category button; category quick filter/open button pressed-state styling; add-new-category round avatar tap animation component; shared neumorph momentary button style.
- Acceptance condition: the category button in the header card must not show a white outer glow during tap/pressed animation.
- Acceptance condition: in neumorph mode, the header card category button tap animation matches the add-new-category round avatar tap animation.
- Acceptance condition: the button uses the same momentary inward press timing/depth behavior as the add-new-category round avatar tap.
- Acceptance condition: the visual response remains momentary only and returns to normal after tap release.
- Acceptance condition: normal/non-neumorph button mode still uses the normal button response without introducing the white outer glow.
- Verification method: inspect and reuse/extract the add-new-category round avatar tap style for the header category button; add/update widget or golden-style tests that tap the header category button and assert no white glow decoration is applied while the shared pressed-state style is active.
- Status: DONE

### BUG2-014 - Add/Edit transaction mentés gomb és date/time pillek közti padding root-cause elemzéssel

- Source instruction: "utolsó screenshot: edit transaction/addnew transaction menuben még mindig nincs padding a mentés gomb és a date/timepicker pillek közt. ezt sokadjára nem tudod megoldani, ide deep analyse kell, hogy megértsd mért, ne csak a releváns kódot olvasd el, \"you must see the big picture\""
- Approved screenshot/reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-233614.png`
- Intended code area: add transaction sheet and edit transaction sheet shared form layout; date/time picker pill row; save button/footer positioning; sheet card height constraints; scrollable content area; safe area/inset handling; any wrapper that computes available height or bottom padding for transaction form sheets.
- Acceptance condition: before changing code, perform and document root-cause analysis of the full layout chain, including sheet host constraints, outer card height, scroll/content column, date/time row, save button/footer, safe area, keyboard/viewInsets, and whether add/edit transaction sheets share or duplicate layout code.
- Acceptance condition: identify why previous padding attempts did not affect the visible gap, including whether padding was applied inside a clipped/overlapped scroll area, overridden by footer positioning, removed by constrained height, or applied to only one of add/edit transaction paths.
- Acceptance condition: both add-new transaction and edit transaction sheets show a clear vertical gap between the date/time picker pill row and the `Mentés` button.
- Acceptance condition: the vertical gap matches the visual rhythm of the form, specifically the spacing between the `Tranzakció neve` and `Összeg` fields unless a shared spacing token proves the app uses a different canonical field gap.
- Acceptance condition: the `Mentés` button remains directly above the bottom safe zone/footer position requested earlier, without being pushed too high.
- Acceptance condition: the fix must work in both income and expense transaction forms, add and edit modes, with and without keyboard visible.
- Acceptance condition: the fix must not reduce or break the required bottom safety-zone behavior for category sheet, recurring sheet, budget/limit sheet, or other slide-up sheets.
- Verification method: inspect the approved screenshot and current app layout; trace the full widget/layout chain from sheet host to form footer before coding; add/update widget tests for add and edit transaction sheets that measure the vertical distance between the date/time row bottom and save button top; verify the distance equals the chosen shared spacing token; manually verify with screenshots after implementation.
- Root-cause analysis: inspected `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-233614.png`; add and edit both render through `_TransactionSheetSlot` and the shared `AddTransactionSheet`. `SlideUpMenuCard` fixes the panel to `SlideUpPanelMetrics.transactionHeight`, then `AddTransactionSheet` splits the layout into an `Expanded` form body and a separate save footer. Inside the body, `Spacer()` pushes `DateTimeFields` to the body bottom; the footer keeps `transaction-save-button` bottom-aligned to `MediaQuery.padding.bottom + 8`. Previous padding attempts inside the footer or safe-zone area could not create visible space above the save button because they changed the area below/inside the footer while the body still ended exactly at `transaction-save-footer.top`; the measured date/time-to-save gap was 0px. The fix adds the same 12px form field spacing token between the body and footer, and raises the closed transaction panel height from 417px to 434px so the fixed-height body can hold that gap without overflow; the footer/safe-zone position remains unchanged.
- Status: DONE

### BUG2-015 - Header chip momentary neumorph tap effect

- Source instruction: "a header chip tap is kapjon normál/befele momentary neumorphism effwctet ha a neumorphism actív a beállításokban"
- Intended code area: header card chip widgets; global button neumorphism setting; shared momentary inward press component/style; header chip tap gesture handling.
- Acceptance condition: when global button neumorphism is active in settings, tapping a header chip shows a momentary inward-pressed neumorph effect.
- Acceptance condition: the header chip is normal/unpressed by default and returns to normal after tap release.
- Acceptance condition: the effect uses the same normal-to-inward momentary neumorph behavior as other momentary buttons, without separate chip-specific neumorph settings.
- Acceptance condition: when global button neumorphism is inactive, header chip tap keeps the normal non-neumorph visual behavior.
- Acceptance condition: the tap action assigned to the header chip still fires exactly once and is not delayed or swallowed by the press animation.
- Verification method: add/update widget tests that enable global button neumorphism, tap a header chip, assert the momentary pressed state/style is applied and then released, then disable neumorphism and assert the chip uses the normal tap style.
- Status: NOT DONE

## Template

### BUG2-000 - Short Title

- Source instruction: ""
- Intended code area:
- Acceptance condition:
- Verification method:
- Status: NOT DONE
