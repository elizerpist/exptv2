# Fluvi Core Dashboard UI design

**Status:** Accepted by the user on 2026-07-31. This document remains the
visual source of truth for the first runnable Flutter slice. The dashboard now
has a typed, read-only query bridge for its committed time scope; the full
Query menu, saved queries, and write/sync UI remain out of scope.

## Scope and sources

### User requirement

Build a clean, standalone Fluvi Flutter application in the dedicated Fluvi
worktree. Its first visible screen is a reusable core dashboard, initially
rendered with Balance as the active mode. Balance, Budget, and Mind share one
layout and interaction core; a mode may change its header tone and the content
inside a slot, but it must not fork the dashboard shell, gesture logic, or
layout geometry.

The initial shell has three visual navigation positions: Dashboard on the left,
a centered FAB, and Settings on the right. Dashboard is the only enabled item
in this slice; FAB and Settings are intentionally non-tappable placeholders.

The initial dashboard has no data. It contains the Fluvi mark, wordmark and
motto; a Grey 100 background; empty header, subheader-one and Zone2 surfaces;
placeholder dots; the real interactive income/expense switch; summary pill;
search and filter placeholders; an expandable time rail; and a functioning
collapse handle. A logbox is explicitly out of scope.

### Accepted reference paths

The following files are geometry and behaviour references only. Fluvi must not
import, copy, or depend on them at runtime.

- /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/balance/spendee_balance_visual_spec.dart
- /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/balance/spendee_balance_collapse_controller.dart
- /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/balance/spendee_balance_post_content.dart
- /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart
- /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/superpowers/evidence/screenshots/b3ma3-reference-expanded.png
- /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/superpowers/evidence/screenshots/b3ma3-reference-collapsed.png

### Existing Fluvi implementation paths

- android/fluvi-core/ is the independently tested Kotlin/Room core.
- README.md currently documents the intentionally UI-free foundation.
- There is no existing Fluvi Dart presentation code to reuse or preserve.

## Architecture card

### Single source and write path

The Flutter dashboard owns presentation state and a typed read-query scope. No
interaction in this slice writes to the database or owns Room state. The
query scope is assembled centrally so a future Query menu can add facets
without changing SummaryPill or TimeRail.

    Flutter gesture or tap
      -> headless dashboard controller
      -> immutable presentation state
      -> DashboardMotionHost
      -> DashboardLayoutFrame
      -> CoreDashboard rendering widgets

DashboardLayoutMetrics is the single source for shared dashboard dimensions.
DashboardGeometryResolver is the sole writer of screen geometry. It derives the
lower stack positions from upstream section heights instead of storing unrelated
absolute positions in individual widgets. Therefore changing Zone2 height moves
the action row, summary, search, rail and handle for every mode.

### State ownership

| State | Owner | Consumers | Persistence |
| --- | --- | --- | --- |
| Active dashboard mode | DashboardModeSpec supplied by the shell | CoreDashboard, palette resolver, slot renderer | None in this slice |
| Collapse drag progress and snap target | DashboardExpansionController | DashboardMotionHost, geometry resolver | None |
| Time rail visibility | DashboardRailController | motion host, rail widget | None |
| Time plane, parent cursor and child selection | DashboardTimeNavigationController | SummaryPill, TimeRefinementRail, CurrentQueryController | None |
| Direction + time scope + future facets | CurrentQueryController | query bridge, summary projection, future transaction list | Read-only core query |
| Active income/expense presentation and pulse request | TransactionDirectionController | motion host, action toggle | None |
| Flutter animation tickers and reduced-motion adaptation | DashboardMotionHost | immutable visual frame only | None |
| Selected bottom navigation visual state | FluviAppShell | bottom navigation | Fixed Dashboard in this slice |

Controllers are headless: they do not receive BuildContext, own widget layout,
use Room, or construct AnimationController instances. The motion host is the
only presentation layer that owns Flutter tickers. Leaf widgets collect intents
and render a supplied visual state; they do not decide a multi-step workflow or
calculate shared geometry.

### Reuse and centralization decisions

CoreDashboard is configured with immutable DashboardModeSpec values for Balance,
Budget, and Mind. The default screen uses Balance. Budget and Mind
specifications exist and are unit tested but do not receive a mode-switching UI
yet.

All three modes share one external subheader envelope. Balance and Budget use
the 72 px first slot plus the 208 px Zone2 slot. Mind may paint one larger
surface inside the same envelope. It cannot change the envelope's collapse
start position, end position, lower-stack anchor, or gesture controller.

Visual decisions are centralised as FluviVisualTokens,
DashboardLayoutMetrics, DashboardMotionTokens, and
DashboardModePaletteResolver. No leaf widget may duplicate a radius, colour,
gap, reference dimension, or active/inactive action treatment.

### Layer flow

    FluviAppShell
      -> DashboardModeSpec + static placeholder slot content
      -> CoreDashboard
      -> DashboardGestureRegion / controls
      -> headless controllers
      -> DashboardMotionHost
      -> DashboardGeometryResolver
      -> DashboardLayoutFrame
      -> visual leaf widgets

The handle and the header/subheader vertical gesture region send intents to the
same DashboardExpansionController. The time rail has its own horizontal
scrolling layer and cannot directly change collapse state. The summary chevron
only toggles time-rail visibility. Income/expense tap changes direction in the
current query scope and requests a pulse.

## SummaryPill, Time Planes, and Child TimeRail

The time-navigation subsystem has three parent planes:

    SUM
     └── years
          └── months
               └── days

`SummaryPill` is a presentation projection and navigation entry point. It does
not own query state. `TimeRefinementRail` edits the direct children of the
active plane, and does not know about Room, SQL, repositories, or saved-query
state.

| Active plane | Parent scope | Child rail | Rail closed | Rail open |
| --- | --- | --- | --- | --- |
| SUM | `AllTimeScope` | generated years | all time | selected `YearScope` |
| YEAR | `YearScope(year)` | cyclic months | selected year | selected `MonthScope` |
| MONTH | `MonthScope(year, month)` | cyclic days | selected month | selected `DayScope` |

`DashboardTimeNavigationController` owns the immutable plane, parent cursors,
committed child selection, preview selection, and rail visibility. Its derived
`parentScope`, `childScope`, and `effectiveScope` are:

    effectiveScope = isRailOpen ? childScope : parentScope

Vertical SummaryPill swipes move between the non-cyclic planes
`SUM → YEAR → MONTH` and back. Horizontal SummaryPill swipes move one parent
unit only: years in YEAR, calendar months in MONTH, and nothing in SUM. An
axis lock prevents one gesture from activating both directions. The chevron
sends only `toggleRail()`; it does not change plane or perform a query itself.

The same canonical `MonthScope(2026-05)` is produced whether the user reaches
it from MONTH with the rail closed or from YEAR with May selected in the open
child rail. This canonical scope is what the query layer and cache key see.

The current query flow is:

    direction + effective TimeScope + future facets
      → CurrentLedgerQueryScope
      → CurrentQueryController (distinct, latest-wins)
      → MethodChannelDashboardLedgerRepository
      → FluviLedgerReadService
      ├── bounded transaction timeline
      └── SQL aggregate total

Preview rail movement updates highlight and haptic state only. A settled child,
rail open/close, parent movement, or direction change commits a new query
scope. Summary amount and transaction data therefore come from the same
immutable key; while a new committed read is loading, the previous amount may
remain stale-but-visible rather than flashing as zero.

The query controller retains the latest 36 scope-key results for fast
back-navigation. An explicit core refresh clears that cache before reading;
the Android result carries the core revision so later invalidation can be
connected without changing the scope or widget APIs.

The full Query menu, category/partner pickers, saved-query snapshots, and query
history are future consumers of the `facets` fields. They must extend
`CurrentLedgerQueryScope`, not create a second SummaryPill or TimeRail state
owner.

## Reference geometry contract

The reference design canvas is 412 x 892 logical pixels. The renderer must
preserve this geometry at that viewport and adapt through the central layout
resolver on other viewport sizes.

| Metric | Value |
| --- | ---: |
| Page background | #F1F5F9 (Grey 100) |
| Content inset / width | 17 px / 378 px |
| Brand lockup bounds | left 28 px, top 52 px, 252 x 42 px |
| Header top | 104 px |
| Header expanded / collapsed height | 126 px / 104 px |
| Shared inter-section gap | 11 px |
| First subheader height | 72 px |
| Zone2 card height | 208 px |
| Zone2 dots gap / height | 4 px / 6 px |
| Action row height | 42 px |
| Summary pill height | 59 px |
| Search/filter height | 39 px |
| Time rail viewport height | 37 px |
| Collapse handle hit height | 20 px |
| Collapse travel | 180 px |

At the expanded reference endpoint the derived action-row top is 553 px; the
summary top is 606 px; search top is 676 px; and the time rail begins at
726 px. These are verification values, not independent leaf-widget constants.
The Zone2 indicator strip is likewise resolver-owned at top 536 px with the
content width and 6 px height. With the rail hidden, the collapse handle begins
at the rail's 726 px anchor. With it visible, the handle is placed below the
37 px rail using the shared 11 px gap (774 px). This relationship also applies
at the collapsed endpoint; a leaf must never calculate either position.

## Local Fluvi assets

Fluvi owns and bundles the following local assets, created anew in this
worktree:

    assets/fluvi/brand/fluvi_mark.svg
    assets/fluvi/actions/income_wallet.svg
    assets/fluvi/actions/expense_bag.svg

FluviBrandMark renders the upper-left mark. FluviBrandLockup owns the mark,
the fluvi wordmark, and the "your personal financial trainer" motto as a shared
positioned unit. TransactionActionIcon renders the local wallet or bag SVG
inside the shared action control. There are no URLs, external asset references,
or Spendee runtime imports.

The source action treatment uses the accepted Balance palette: an active income
surface is purple-to-pink, an active expense surface is orange-to-pink, and an
inactive surface is light. The active icon pulse is 0.90 -> 1.12 -> 0.98 ->
1.00 over 420 ms. The motion host supplies the scale; the action button does
not own the animation policy.

## Initial shell contract

- Dashboard is visible and active on launch.
- The centered FAB is visible but has no tap action.
- Settings is visible but has no tap action.
- No full Query menu, saved-query UI, or write/sync screen is introduced in
  this slice. The committed dashboard time scope has a read-only core bridge.

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CORE-UI-01 | User request: minimal runnable Flutter application | Flutter root, Android host, lib/app | Flutter starts into the Fluvi shell and Dashboard screen. | flutter test, flutter analyze, GitHub Android build. | DONE — local Flutter test/analyze and GitHub Actions run 30646812824 are green; its debug APK artifact was downloaded. |
| CORE-UI-02 | User request: left Dashboard, center FAB, right Settings | lib/app/shell | Dashboard is active; FAB and Settings render as non-tappable placeholders. | Widget test and screenshot. | PARTIAL — semantics/tap widget test green; screenshot verification explicitly deferred by the user. |
| CORE-UI-03 | User request: Balance/Budget/Mind one core | features/dashboard/presentation | Exactly one CoreDashboard renders all three DashboardModeSpec variants. | Unit/widget test of all specs and source review. | DONE — all three specs use one tested CoreDashboard. |
| CORE-UI-04 | Structuring-apps: shared decisions have one source | core/design | Dimensions, colours, radii, gaps, palettes and geometry resolver are centralised. | Architecture test/source review. | DONE — metrics, resolver, frame, tokens, and motion host remain the shared owners. |
| CORE-UI-05 | Balance visual reference | core/design, dashboard widgets | 412 x 892 expanded geometry matches the listed reference contract. | Golden screenshot and layout-frame unit test. | PARTIAL — layout-frame contract test green; screenshot verification explicitly deferred by the user. |
| CORE-UI-06 | User request: common expandable/collapsible header and cards | application controllers, motion host | Header and subheader envelope use one expansion progress, react to vertical drag and handle tap, and snap predictably. | Controller and widget gesture tests; screenshots. | PARTIAL — controller/widget gesture tests green; screenshot verification explicitly deferred by the user. |
| CORE-UI-07 | User request: local Fluvi icon, brand, motto and action SVGs | assets/fluvi, brand/action widgets | Mark, wordmark, motto, wallet and bag are local Fluvi assets with no runtime external or Spendee reference. | Asset manifest/source scan and screenshot. | PARTIAL — local assets and source scan green; screenshot verification explicitly deferred by the user. |
| CORE-UI-08 | User request: exact interactive income/expense controls | action controller, motion host, action widget | Tap switches active side, colour treatment and central 420 ms icon pulse. | Controller/widget animation test. | DONE — controller and motion-policy tests cover the active direction and pulse. |
| CORE-UI-09 | User request: summary chevron, rail, handler | rail controller, rail, handle widgets | Chevron expands/collapses rail; rail responds horizontally; handle controls common vertical collapse. | Widget gesture test. | DONE — gesture test covers chevron, horizontal rail isolation, and shared handle collapse. |
| CORE-UI-10 | User request: no Room/logbox in presentation | dashboard boundaries | Dashboard presentation remains Room/SQL-free; committed time reads cross only the typed query adapter. | Boundary scan and source review. | DONE — Flutter/core boundary test and script are green. |
| CORE-UI-11 | User request: shared geometry must move every mode | geometry resolver and all specs | A changed Zone2 metric shifts the lower stack identically for Balance, Budget and Mind. | Parameterized geometry unit test. | DONE — parameterized resolver test covers every mode. |
| CORE-UI-12 | User request: brand, dots and handler are central layout | geometry resolver and CoreDashboard | Brand lockup, Zone2 indicator strip, and rail/handle relationship come from the shared frame rather than leaf coordinates. | Layout-frame test, widget gesture test and golden screenshot. | PARTIAL — layout-frame/gesture tests green; screenshot verification explicitly deferred by the user. |

### Time-navigation acceptance

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DTN-01 | User time-navigation specification | `time_navigation/domain` | SUM, YEAR and MONTH are typed planes with canonical AllTime/Year/Month/Day scopes and half-open boundaries. | Domain unit tests. | DONE — domain transition tests pass. |
| DTN-02 | User time-navigation specification | `DashboardTimeNavigationController` | Parent cursor, child committed/preview selection, rail visibility and plane transitions are centralized. | Controller unit tests. | DONE — promotion, demotion, clamp and rail-preservation tests pass. |
| DTN-03 | User time-navigation specification | `time_rail_data_source_factory`, shared carousel | Years are generated; months and days are cyclic; existing carousel physics is reused unchanged. | Data-source tests and carousel boundary test. | DONE — mapping tests pass; no physics/data-source duplication was added. |
| DTN-04 | User time-navigation specification | `SummaryPill`, gesture adapter | Vertical/horizontal axis lock and chevron-only rail toggle are deterministic. | SummaryPill gesture tests. | DONE — gesture tests pass. |
| DTN-05 | User time-navigation specification | `CurrentQueryController` | Preview does not query; committed scope changes are deduplicated, latest-wins, and cached for short back-navigation. | Query controller tests. | DONE — deduplication, stale-result, bounded-cache and refresh invalidation tests pass. |
| DTN-06 | User time-navigation specification | Flutter query bridge, `FluviLedgerReadService` | Direction, canonical time scope and future facets reach one core read producing bounded entries and SQL total. | Method-channel contract test and Android source/compile verification. | DONE — Dart bridge tests and `:app:compileDebugKotlin` pass; the separate full resource task is unavailable locally because AAPT2 cannot start on this Termux environment. |
| DTN-07 | User time-navigation specification | Summary presenter | Summary labels and amount projection reflect the active plane/scope and loading/error state. | Presenter tests. | DONE — projection tests pass. |
| DTN-08 | User time-navigation specification | docs and architecture boundaries | SummaryPill, TimeRail and future QueryController ownership is documented without a second state owner. | Boundary script/test and document review. | DONE — boundary script/test and Flutter analyze pass; legacy goldens remain intentionally unmodified per user instruction. |

## Verification strategy

Pure controller and geometry tests run before widget tests. Widget tests verify
the nav placeholders, action state, chevron/rail, and collapse handle. On
2026-07-31 the user explicitly deferred screenshot inspection, so this delivery
does not claim screenshot evidence for the marked PARTIAL rows. Flutter analysis
and tests run in Ubuntu/proot; Android APK build is run by GitHub Actions, never
by local Termux Flutter.
