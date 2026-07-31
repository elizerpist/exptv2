# Fluvi Core Dashboard UI design

**Status:** Accepted by the user on 2026-07-31. This document defines the
first runnable Flutter slice only. It does not connect any dashboard element
to the Fluvi Kotlin/Room core, a query, a repository, a logbox, or a sync
service.

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

The Flutter dashboard owns only temporary presentation state. No interaction in
this slice writes to the database or a future query state.

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
only toggles time-rail visibility. Income/expense tap only changes local
presentation state and requests a pulse.

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
- No other application screen, route, database adapter, query, logbox, or
  business calculation is introduced in this slice.

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CORE-UI-01 | User request: minimal runnable Flutter application | Flutter root, Android host, lib/app | Flutter starts into the Fluvi shell and Dashboard screen. | flutter test, flutter analyze, GitHub Android build. | NOT DONE |
| CORE-UI-02 | User request: left Dashboard, center FAB, right Settings | lib/app/shell | Dashboard is active; FAB and Settings render as non-tappable placeholders. | Widget test and screenshot. | NOT DONE |
| CORE-UI-03 | User request: Balance/Budget/Mind one core | features/dashboard/presentation | Exactly one CoreDashboard renders all three DashboardModeSpec variants. | Unit/widget test of all specs and source review. | NOT DONE |
| CORE-UI-04 | Structuring-apps: shared decisions have one source | core/design | Dimensions, colours, radii, gaps, palettes and geometry resolver are centralised. | Architecture test/source review. | NOT DONE |
| CORE-UI-05 | Balance visual reference | core/design, dashboard widgets | 412 x 892 expanded geometry matches the listed reference contract. | Golden screenshot and layout-frame unit test. | NOT DONE |
| CORE-UI-06 | User request: common expandable/collapsible header and cards | application controllers, motion host | Header and subheader envelope use one expansion progress, react to vertical drag and handle tap, and snap predictably. | Controller and widget gesture tests; screenshots. | NOT DONE |
| CORE-UI-07 | User request: local Fluvi icon, brand, motto and action SVGs | assets/fluvi, brand/action widgets | Mark, wordmark, motto, wallet and bag are local Fluvi assets with no runtime external or Spendee reference. | Asset manifest/source scan and screenshot. | NOT DONE |
| CORE-UI-08 | User request: exact interactive income/expense controls | action controller, motion host, action widget | Tap switches active side, colour treatment and central 420 ms icon pulse. | Controller/widget animation test. | NOT DONE |
| CORE-UI-09 | User request: summary chevron, rail, handler | rail controller, rail, handle widgets | Chevron expands/collapses rail; rail responds horizontally; handle controls common vertical collapse. | Widget gesture test. | NOT DONE |
| CORE-UI-10 | User request: no data binding or logbox | dashboard boundaries | Dashboard imports no Room, repository, query or logbox code. | Boundary scan and source review. | NOT DONE |
| CORE-UI-11 | User request: shared geometry must move every mode | geometry resolver and all specs | A changed Zone2 metric shifts the lower stack identically for Balance, Budget and Mind. | Parameterized geometry unit test. | NOT DONE |
| CORE-UI-12 | User request: brand, dots and handler are central layout | geometry resolver and CoreDashboard | Brand lockup, Zone2 indicator strip, and rail/handle relationship come from the shared frame rather than leaf coordinates. | Layout-frame test, widget gesture test and golden screenshot. | NOT DONE |

## Verification strategy

Pure controller and geometry tests run before widget tests. Widget tests verify
the nav placeholders, action state, chevron/rail, and collapse handle. Two
412 x 892 screenshots, one expanded and one collapsed, serve as visual
evidence. Flutter analysis and tests run in Ubuntu/proot; Android APK build is
run by GitHub Actions, never by local Termux Flutter.
