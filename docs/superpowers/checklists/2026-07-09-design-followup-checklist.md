# 2026-07-09 Design Follow-Up Checklist

Scope: user will list checklist items one by one. Do not implement, commit, push, or build until the user explicitly says to start coding. Final implementation must be one commit and one build at the end.

## Items

### CHK-001 - Mentos skin header card yellow veil

- Source instruction: "a mentős skin esetében a header k@rtya legyen s@rga, 0,5 opacityvel. azaz legyen fehér, felette egy sárga fátyol, ambulance rikítósárga"
- Intended code area: main transaction header card; ambulance/mentos skin theme-magnet rendering.
- Acceptance condition: when the ambulance/mentos magnet skin is active, the header card keeps a white base and renders a vivid ambulance-yellow overlay/veil above it with 0.5 opacity; it must not be a solid yellow card.
- Verification method: inspect header card rendering; add or update widget/screenshot verification for ambulance skin card color layering.
- Status: DONE
- Verification evidence: `AmbulanceHeaderVeil` renders the vivid yellow veil at 0.5 opacity over a white header base for the ambulance skin; covered by `test/transactions/header_card_test.dart`.

### CHK-002 - Add transaction spacing above save button

- Source instruction: "last screenshot: a mentés gomb és time/date picker pillek közt nincs padding. legyen, akkora mint a név és összeg közt."
- Approved reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260709-171214.png`
- Intended code area: add-new-transaction sheet lower layout; date/time picker row; save button footer spacing.
- Acceptance condition: the vertical padding between the date/time picker pills and the `Mentés` button equals the padding between the `Név` and `Összeg` fields.
- Verification method: inspect add transaction sheet layout constants; compare screenshot geometry or widget layout measurements for the two spacings.
- Status: DONE
- Verification evidence: add transaction spacing is covered by `test/widget_test.dart` checks for `transaction editor keeps save button close to date row` and `transaction editor save button aligns with category filter action`; full `flutter test` passed after the final branch move.

### CHK-003 - Notification menu header back button

- Source instruction: "a notification menu headerben legyen vissza gomb"
- Intended code area: notification log/menu sheet header.
- Acceptance condition: the notification menu header shows a back button on the left side; tapping it closes the notification menu or returns to the previous sheet state according to the existing app flow.
- Verification method: inspect notification menu header implementation; add or update widget/manual UI verification that the button is visible and tap works.
- Status: DONE
- Verification evidence: `NotificationsPage` has `notification-menu-back-button`, wired from shell back to home; covered by `test/notifications/notifications_page_test.dart`.

### CHK-004 - Bottom nav background always white

- Source instruction: "a bottom nav háttere kizárólag fehér lehet, a témabeállít@stól függetlenül"
- Intended code area: app shell bottom navigation container/background rendering.
- Acceptance condition: the bottom navigation background is fixed white for every theme, card, surface, and background setting; no theme setting can override it.
- Verification method: inspect shell bottom navigation rendering; verify with a non-white theme through widget or screenshot check.
- Status: DONE
- Verification evidence: `ExptBottomNav` forces white background independently of theme input; covered by `test/shell/bottom_nav_item_test.dart`.

### CHK-005 - Logbox surface fixed normal, no theme option

- Source instruction: "logboxok felülete csak normál lehet, ne legyen ilyen opció a témabeállításokban"
- Intended code area: logbox rendering components; theme settings model/options UI for logbox surface style.
- Acceptance condition: every logbox renders with the normal surface style only; the user cannot choose a logbox surface/neumorphism style in theme settings; any previous setting value must not affect logbox rendering.
- Verification method: inspect logbox widget rendering and theme settings options; add or update widget/settings tests to confirm the option is absent and logbox style remains normal under non-normal theme settings.
- Status: DONE
- Verification evidence: theme UI no longer exposes `Logboxok felülete`, and `ExpenseTheme` forces logbox/content log surfaces to normal; covered by `test/settings/settings_page_test.dart`, `test/settings/expense_theme_test.dart`, and related settings serialization tests.

### CHK-006 - Unified button neumorph behavior and separate summary pill setting

- Source instruction: "az appban javítsd át a neumorph vs normál viselkedést. ez csak a gombokra vonatkozik..." and "ha a kategória sheetben a user a normált válasssza akkor van highlight keret, ha neumorphot, akkor nincs. továbbá a summary pill is tappelhető, ennek külön beállítás kell, nem része a globálisnak, ez is normál/befele domborodó/ momentary"
- Intended code area: theme settings model/options UI for button surface behavior; shared button/press surface components; FAB; add transaction sheet save button; recurring sheet add/save button; budget/limit sheet save button; category sheet apply button and cards; income/expense selectors; bottom navigation; header card category button and chips; logbox avatar filter tap; stats summary pill tap behavior/settings.
- Acceptance condition: theme settings exposes only one global button surface option with `Normál` and `Neumorph`; there are no separate neumorph options for each button/component; this global option applies only to buttons and must not affect logbox surfaces from CHK-005.
- Acceptance condition: `Neumorph` always means the default/resting state is visually normal, and tap/press renders an inward/pressed effect; it must not mean a permanently raised/default neumorph surface.
- Acceptance condition: momentary inward press behavior is used for FAB, add transaction `Mentés`, recurring sheet `Szabály hozzáadása`/save, budget/limit sheet save, category sheet `Szűrőbeállítás`, header card category button, header card chip buttons, and logbox avatar filter taps.
- Acceptance condition: permanent inward/selected behavior is used for income/expense buttons and bottom navigation.
- Acceptance condition: category menu cards use permanent selected behavior when the button setting is `Neumorph`: selected cards remain inward until filter acceptance/change; selected category card avatars also appear inward; this applies to all category menu cards including `Minden kategória`, `Új kategória`, and category cards.
- Acceptance condition: category menu highlighting differs by button setting: with `Normál`, selected/highlighted cards show a highlight border; with `Neumorph`, selected/highlighted cards show no highlight border and rely on the permanent inward card/avatar state.
- Acceptance condition: stats summary pill tap behavior has its own separate setting, independent of the global button setting; it supports normal versus inward neumorph momentary tap behavior.
- Verification method: inspect theme settings to confirm only the global button option remains plus a separate summary pill option; add/update widget tests for momentary press, permanent selected states, category menu border/no-border split, logbox avatar momentary behavior, and summary pill independent setting.
- Status: DONE
- Verification evidence: global button style maps `Neumorph` to normal-resting/pressed-inset behavior, summary pill has independent surface style, category neumorph selection stays inset with no border, and normal mode keeps border highlighting; covered by settings, category menu, transaction widget, and bottom-nav tests.

### CHK-007 - Ambulance header yellow veil visible in resting state

- Source instruction: "jelenleg a header card csak akkor sárga ha felslideol, ezt a bugot oldd meg"
- Intended code area: transaction header card ambulance/mentos skin rendering; expanded/collapsed/slide state header background layering.
- Acceptance condition: when the ambulance/mentos skin is active, the header card shows the white base plus 0.5 opacity vivid yellow veil in the normal resting header state and during slide/expanded states; the yellow veil must not appear only after the header slides up.
- Verification method: add or update widget test that renders the header card with `MagnetType.ambulanceSkin` in the resting state and finds/verifies the ambulance yellow veil layer; inspect code to confirm the yellow veil is tied to the skin setting, not the slide/expanded state.
- Status: DONE
- Verification evidence: root cause was the resting header path using `HeaderFastInfoSurface` with `drawSurface: false`, so the ambulance color only appeared when the sliding `TransactionHeaderCard` surface was drawn; added shared `AmbulanceHeaderVeil`, passed `ambulanceSkin` into the resting fast-info surface, kept the base color white, and verified both direct and resting paths with `flutter test test/transactions/header_card_test.dart --plain-name ambulance`, full `flutter test test/transactions/header_card_test.dart`, `flutter analyze`, and `git diff --check`.

### CHK-008 - Statistics month card color persists

- Source instruction: "statisztika monthcard színét nem lehet állítani, visszaáll fehérre"
- Intended code area: statistics screen month card rendering; month card color setting model/storage/options; settings persistence and hydration path.
- Acceptance condition: when the user changes the statistics month card color, the selected color is applied to month cards and remains applied after navigating away/back, reopening settings, and app/settings reload; it must not reset to white unless the user explicitly selects white.
- Verification method: inspect stats month card color source and settings persistence path; add or update widget/settings tests that change the month card color, verify the rendered month card color, serialize/deserialize settings, and confirm the color does not fall back to white.
- Status: DONE
- Verification evidence: stats month card color is passed from `ExpenseTheme.statsMonthCard` into `StatsYearCalendar` and remains serialized in settings; covered by `test/stats/stats_page_test.dart` and settings store/bridge tests.

### CHK-009 - Summary pill app-designed year/month scope picker

- Source instruction: "a summary pillen a tap előhozza az év és hónap pickert a koncepció jó, de semmi köze az app designhoz. az ötlet jó, de mindkét oldalt lehessen aktiválni deaktiválni. ha mindkettő inaktív, akkor sum mode, ha csak év aktív, akkor egész év, ha hónap is aktív, akkor konkrét hónap. swipepal is lehessen le fel draggolni ne csak plus minus gombokkal"
- Intended code area: statistics summary pill tap interaction; year/month picker sheet/dialog; statistics scope state and filtering; summary pill display text; picker gesture handling.
- Acceptance condition: tapping the summary pill opens an app-designed year/month scope picker that matches the app visual language; it must not look like a foreign/native Android picker disconnected from the app design.
- Acceptance condition: the picker has independent active/inactive controls for the year side and month side; both can be activated and deactivated by the user.
- Acceptance condition: if year and month are both inactive, statistics uses `sum mode`; if only year is active, statistics scope is the whole selected year; if year and month are both active, statistics scope is the selected concrete month.
- Acceptance condition: month-active mode requires an active year context; if the user activates month while year is inactive, implementation must either activate year automatically or prevent month activation with clear in-app state behavior.
- Acceptance condition: year and month values can be changed by vertical swipe/drag up and down on the picker controls, not only with plus/minus buttons.
- Verification method: inspect summary pill tap and stats scope state transitions; add or update widget tests for the three modes, independent activation/deactivation, summary pill label/state, plus/minus controls, and vertical drag changes for year/month values.
- Status: DONE
- Verification evidence: `SummaryScopePickerSheet` is app-designed, supports independent year/month toggles, auto-enables year for month, vertical drag value changes, and applies all-time/year/month scopes through `StatsSummaryScope`; covered by `test/transactions/transaction_widgets_test.dart` and `test/stats/stats_year_data_test.dart`.

### CHK-010 - Search pill transaction count text only ellipsizes at real edge

- Source instruction: "ha szűrünk, akkor a searchpillben a capsula mellett megjelenik a tranzakciószám, de ezt úgy rajzolod ki, hogy kiférne a szöveg, mert elég széles a searchpill, de csak ennyit látók: 34560 tr.... tehát a három pont tényleg csak akkor legyen ha nem fér ki, azaz a szélénél."
- Intended code area: transaction search pill filtered-state layout; capsule/chip row; transaction count label sizing and overflow behavior.
- Acceptance condition: when filtering is active and the transaction count appears beside the capsule, the full transaction count label is shown whenever it fits inside the available search pill width.
- Acceptance condition: ellipsis/truncation is used only when the text reaches the actual right edge/available boundary and genuinely cannot fit; it must not truncate early while visible unused width remains.
- Acceptance condition: the capsule and transaction count label share horizontal space predictably without forcing the count label into an artificially narrow width.
- Verification method: inspect search pill layout constraints; add or update widget/layout tests with a long count such as `34560 tranzakció` to confirm full text is visible when the pill has enough width and ellipsis appears only in a deliberately narrow width.
- Status: DONE
- Verification evidence: `SearchPill` now separates horizontally scrollable capsules from the filtered count label, with a wider count constraint and ellipsis only on actual overflow; covered by `test/transactions/transaction_widgets_test.dart`.

### CHK-011 - Search pill shows one removable capsule per filtered category

- Source instruction: "ha a user több kategóriát is szűr, akkor jelenleg csak 1 capsula jelenik meg a searchpillben. ehelyett annyi capsulabjelenjen meg, ahányat szűrt, és egyesével be lehessen zárni. ha nem férnek ki a capsulák, akkor lehessen a searxhpillen belül oldalra draggolni a capsulákat, azaz scrollozni"
- Intended code area: transaction search pill filtered-state category capsule row; multi-category filter display; per-category filter removal behavior; horizontal capsule scrolling.
- Acceptance condition: when multiple categories are active in the filter, the search pill renders one capsule for each selected category, not a single combined capsule.
- Acceptance condition: each category capsule has its own close/remove affordance; tapping a capsule close removes only that category from the active filter and leaves the remaining category filters active.
- Acceptance condition: if all selected category capsules do not fit inside the search pill width, the capsule area is horizontally draggable/scrollable within the search pill.
- Acceptance condition: horizontal capsule scrolling must not break search pill tap behavior, transaction count display from CHK-010, or vertical page scrolling.
- Verification method: add or update widget tests for multi-category filter display count, per-capsule removal, remaining active filters after removal, and horizontal drag/scroll behavior when the capsule row overflows.
- Status: DONE
- Verification evidence: `SearchPill` renders one capsule per active category filter, each with its own close callback, inside a horizontal scroll area; store removal keeps remaining filters active; covered by `test/transactions/transaction_widgets_test.dart` and `test/transactions/transaction_store_test.dart`.

### CHK-012 - Summary pill compact feedback for multi-category filter

- Source instruction: "ha a user több elemet jelöl ki szűrésre, akkor a summarypillben legyen feedback, de ne egyesével kiírva, hanem csak annyi, hogy \"x kategória\""
- Intended code area: summary pill filtered-state label/feedback; category filter state display; interaction with multi-category filters from CHK-011.
- Acceptance condition: when multiple category filter items are selected, the summary pill shows compact feedback in the format `x kategória`, where `x` is the number of selected categories.
- Acceptance condition: the summary pill must not list category names one by one in the multi-category state.
- Acceptance condition: the count updates when the user adds or removes category filters, including per-capsule removal from CHK-011.
- Verification method: add or update widget tests for summary pill text with two or more selected categories, verify that individual category names are absent, and verify that the count updates after a category is removed.
- Status: DONE
- Verification evidence: `TransactionStore.activeSummaryTitle` reports multi-category filters as `x kategória` and updates from the active category id set; covered by store/widget filtering tests and the full suite.

### CHK-013 - Search pill magnifier opens multi-vendor filter sheet

- Source instruction: "a search pillben a nagyító ikon gomb legyen, azaz tappelhető legyen, ez egy új funkció: vendor list. egy slide up sheet, az adott időszak vendorjait listázza ki. a sheet magassága a summary pill tetejéig ér. a sheetben a vendorok, a logboxok designját kapják meg, azaz avatar, vendor neve, sum összeg az adott időszakban (adott év, adott hónap etc.)  a vendorboxok tappelhetőek, olyankor a vendort kijelöli. több vendor is kijelölhető. a sheet alján legyen egy kék szűrőbeállít@s gomb, amire ha a user tapoel a kiválasztás után, akkor a sheet bezár és az összes adott vendor tranzakciót kilistázza (kék capsula a search pillben) ez ugyanolyan funkció mint a fastfilter, azaz hasonló, csak multivendor. a lista scrollozható, de a scroll ne interferáljon a sheet draggel, sheet drag csak akkor van, ha a scroll legfelül van"
- Intended code area: search pill magnifier icon; transaction home filter state; vendor aggregation for the active period/scope; vendor list slide-up sheet; vendor box rendering; multi-vendor filter capsules in search pill; sheet drag/scroll coordination.
- Acceptance condition: the magnifier icon inside the search pill is a tappable button, not just decoration.
- Acceptance condition: tapping the magnifier opens a slide-up vendor list sheet whose top reaches the summary pill top; it must not cover above that boundary.
- Acceptance condition: the sheet lists vendors from the currently active period/scope, including year/month/sum modes from CHK-009; each vendor row/box shows an avatar, vendor name, and summed amount for that same active period/scope.
- Acceptance condition: vendor boxes visually follow the logbox design language, including avatar and text/amount hierarchy.
- Acceptance condition: tapping a vendor box toggles that vendor selected; multiple vendors can be selected at the same time.
- Acceptance condition: the sheet footer has a blue `Szűrőbeállítás` button fixed at the bottom; tapping it applies the selected vendors, closes the sheet, and filters the transaction list to all transactions from the selected vendors.
- Acceptance condition: applied vendor filters appear in the search pill as blue vendor capsules; this behaves like fastfilter conceptually, but supports multiple vendors.
- Acceptance condition: vendor capsules can coexist predictably with category capsules from CHK-011 and transaction count behavior from CHK-010.
- Acceptance condition: the vendor list is vertically scrollable; vertical scroll inside the list must not interfere with sheet dragging; sheet drag is allowed only when the list scroll position is at the top.
- Verification method: add or update widget tests for magnifier tap opening the sheet, sheet height boundary at summary pill top, vendor aggregation by active period/scope, multi-select toggling, apply button closing and filtering transactions, blue vendor capsules in the search pill, and scroll-vs-sheet-drag behavior when the vendor list is scrolled versus at top.
- Status: DONE
- Verification evidence: search icon is `search-pill-vendor-button`; vendor sheet lists period vendors with avatar/name/sum rows, multi-selects vendors, applies via blue `Szűrőbeállítás`, produces blue merchant capsules, and gates sheet drag by vendor list top offset; covered by `test/transactions/category_menu_test.dart`, `test/transactions/transaction_store_test.dart`, and `test/transactions/transaction_widgets_test.dart`.
