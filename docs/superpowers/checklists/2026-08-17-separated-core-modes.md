# Separated core modes acceptance checklist

> **2026-08-17 correction:** This checklist supersedes the committed
> drag-following/two-surface interpretation. Core-mode navigation is one
> header-swipe intent and one immediate semantic mode replacement; no core-mode
> transition is rendered or animated.

## Atomic dashboard core modes architecture card

### Scope and sources

- User requirement: the original `separated-core-modes` functional
  specification as corrected by the 2026-08-17 **IMPORTANT CORRECTION TO THE
  CORE-MODE INTERACTION CONTRACT**.
- Accepted reference: `MILESTONE_COMMITS.md`, top 2026-08-17 section;
  behavioural baseline `8d559cfbb9c31bbe6d6e89b32cf036be3ed94b91`.
- Existing implementation: `dashboard_mode_spec.dart`,
  `dashboard_geometry_resolver.dart`, `dashboard_motion_host.dart`,
  `core_dashboard.dart`, and `fluvi_app_shell.dart`.

### Single source and write path

- Source of truth: `DashboardModeSpec.values` is the only ordered three-mode
  ring; `DashboardCoreModeController` is the only runtime owner of committed
  mode.
- Read model: one committed `DashboardModeSpec` and centrally resolved,
  immutable `DashboardCoreModePresentation` layout/palette inputs.
- Only write path: after `GestureDirectionArbiter` chooses horizontal header
  intent, `DashboardCoreModeHost` calls the controller's one-shot
  next/previous switch exactly once for that pointer sequence. Shell
  configuration may explicitly program the committed mode.
- Error and retry owner: none; core-mode navigation is presentation-only and
  must not initiate data work.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Committed core mode | `DashboardCoreModeController` | Shell | One atomic next/previous/programmatic publication |
| Header axis and one-shot horizontal latch | `DashboardCoreModeHost` header interaction boundary | One pointer sequence | Immutable after `GestureDirectionArbiter` picks an axis; reset only at up/cancel |
| Resolved card/header geometry and palette | `DashboardMotionHost` via `DashboardGeometryResolver` | Structural-frame build | Mode roots only receive immutable presentation inputs |
| Query, LogBox, paging, cache, rail and vertical-scroll state | Existing protected owners | Existing lifetimes | Never written or recreated by core-mode navigation |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Mode identity / ordered ring | `DashboardModeSpec.values` | Three semantic modes and split/unified composition | Reuse; no new enum or registry | Mode-controller unit tests |
| Geometry / unified body envelope | `DashboardGeometryResolver` | Mind body starts at split card1 top and ends at split card2 bottom | Reuse; no mode-local coordinates | Direct geometry test |
| Axis arbitration | `GestureDirectionArbiter` | Touch slop, dominance, irreversible winning axis | Reuse in header owner | Header widget and arbiter tests |
| Structural ticker lifecycle | `DashboardMotionHost` | Shared dashboard expansion/rail motion keeps its existing one-owner lifecycle | Do not extend for core modes | Source boundary and no-ticker test |
| Placeholder cards and visual tokens | Existing placeholder / palette primitives | Shared low-level visual roles | Reuse below separate mode roots | Mode-root widget tests |

### Layer flow

Header input → `GestureDirectionArbiter` → one-shot
`DashboardCoreModeController` publication → `DashboardCoreModeHost` selects one
isolated root. `DashboardMotionHost` provides only its existing structural
presentation inputs.
There is intentionally no repository, use-case, runtime, Query, paging or
LogBox step in this flow.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCM-01 | correction: revised ownership | application mode controller | Headless controller owns only committed three-node cyclic mode state and one-shot next/previous/programmatic writes; no target, phase, progress, page index or ticker | RED/GREEN unit suite | DONE — controller RED then 8 targeted unit assertions green |
| SCM-02 | correction: one-shot header contract | app shell / CoreDashboard wiring | Shell keeps one stable mode controller and an accepted horizontal intent atomically replaces mode without recreating protected owners | Widget identity test and inspection | DONE — 30 widget-driven cycles retain the dashboard, Query and LogBox owners |
| SCM-03 | original §8.3, corrected mode content | mode-root presentation files | Distinct Balance, Budget and Mind roots render their own header/body placeholders and labels | Widget semantics/key test | DONE — distinct roots/keys and labels verified |
| SCM-04 | correction: harder render domain | mode host | Exactly one mode root is mounted before, during and after every gesture; no target Stack, neighbour, retained third root, PageView or IndexedStack | Mounted-widget and boundary tests | DONE — host tests and source boundary prove one root only |
| SCM-05 | protected milestone | CoreDashboard composition | Exactly one shared LogBox/runtime remains outside the selected mode root | Widget singleton test and source inspection | DONE — same `DashboardLogBoxViewport` state survives 30 switches |
| SCM-06 | original §8.7 | geometry resolver / mode inputs | Mind unified body uses central envelope with exact split-card top/bottom | Direct resolver test | DONE — direct endpoint contract is green |
| SCM-07 | correction: one-shot header input | header interaction owner | Header-only horizontal switches exactly once after arbiter acceptance; vertical expansion survives; cards cannot navigate modes | Gesture widget tests | DONE — left/right, one-long-swipe, vertical, diagonal and card-region tests green |
| SCM-08 | correction: stationary visual contract | mode host | Header/cards never translate, scale, fade or reveal a neighbour while horizontal input moves | Bounds/no-neighbour widget tests and source inspection | DONE — bounds and no-neighbour tests plus no-translation boundary assertion green |
| SCM-09 | correction: no mode motion owner | controller / host / motion host | No core-mode `AnimationController`, progress, settle frame, PageController, horizontal ScrollController or added DashboardMotionHost lane exists | Boundary/source test and rebuild counter | DONE — source boundary and no-trailing-frame counter test green |
| SCM-10 | corrected mode content | mode roots | Only neutral existing surfaces plus top-right `balance` / `budget` / `mind` labels; no business content | Widget test / inspection | DONE — mode-root semantic/key assertions green |
| SCM-11 | protected milestone | controller/host boundaries | Header mode swipe starts no dashboard/query/paging/cache data acquisition and mutates no Query/time/direction state | Counting/no-I/O widget test | DONE — counting repository remains unchanged across 30 switches |
| SCM-12 | correction: structural continuity | mode host / motion frame | Atomic mode replacement preserves current expansion progress | Widget expansion-continuity test | DONE — expanded header geometry remains unchanged after switch |
| SCM-13 | correction: repeated input | controller / widget host | Thirty independent completed swipes follow the modulo-three ring, with no orphan state, animation or runtime replacement | Unit and widget test | DONE — controller and real-header widget cycles green |
| SCM-14 | diagnostics | shell diagnostic adapter | One low-volume atomic mode-switch diagnostic records from-mode, to-mode and direction; no per-pointer-frame spam | Controller observer test and source inspection | DONE — `CORE_MODE_SWITCHED` sends one semantic event with from/to/direction |
| SCM-15 | protected regression suite | boundary / regression tests | Dependency direction and all protected ownership contracts remain true | Focused and complete boundary suites | PARTIAL — all mode/protected focused suites green; full suite retains four unchanged baseline failures outside this scope |
| SCM-16 | delivery | commit / online human APK | One coherent production commit, clean scoped diff, online normal `lib/main.dart` APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256 | GitHub Actions and local hash | PARTIAL — pending commit, exact-SHA online build and APK download |
| SCM-17 | human Android device | physical acceptance | Physical stationary-card/instant-swap/gesture-smoothness acceptance is explicitly pending human test | User verification | NOT DONE — requires human Android verification |
