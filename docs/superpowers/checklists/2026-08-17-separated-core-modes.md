# Separated core modes acceptance checklist

## Separated dashboard core modes architecture card

### Scope and sources

- User requirement: the `separated-core-modes` functional specification in the
  2026-08-17 handoff.
- Accepted reference: `MILESTONE_COMMITS.md`, top 2026-08-17 section;
  behavioural baseline `8d559cfbb9c31bbe6d6e89b32cf036be3ed94b91`.
- Existing implementation: `dashboard_mode_spec.dart`,
  `dashboard_geometry_resolver.dart`, `dashboard_motion_host.dart`,
  `core_dashboard.dart`, and `fluvi_app_shell.dart`.

### Single source and write path

- Source of truth: `DashboardModeSpec.values` is the only ordered three-mode
  ring; `DashboardCoreModeController` is the only runtime owner of committed
  mode and semantic transition state.
- Read model: immutable `DashboardCoreModeTransition` snapshots and centrally
  resolved `DashboardCoreModePresentation` layout/palette inputs.
- Only write path: the header interaction boundary calls the controller's
  start/commit/cancel APIs; shell configuration may explicitly program the
  committed mode.
- Error and retry owner: none; core-mode navigation is presentation-only and
  must not initiate data work.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Committed core mode / target / direction / phase | `DashboardCoreModeController` | Shell | Semantic start, commit, cancel and completion only |
| Drag-following horizontal progress / settle ticker | `DashboardMotionHost` mode-motion lane | Core dashboard mount | Local mode-host `AnimatedBuilder`; never parent dashboard rebuild per frame |
| Header axis commitment | `DashboardCoreModeHost` header interaction boundary | One pointer sequence | Immutable after `GestureDirectionArbiter` picks an axis |
| Resolved card/header geometry and palette | `DashboardMotionHost` via `DashboardGeometryResolver` | Structural-frame build | Mode roots only receive immutable presentation inputs |
| Query, LogBox, paging, cache, rail and vertical-scroll state | Existing protected owners | Existing lifetimes | Never written or recreated by core-mode navigation |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Mode identity / ordered ring | `DashboardModeSpec.values` | Three semantic modes and split/unified composition | Reuse; no new enum or registry | Mode-controller unit tests |
| Geometry / unified body envelope | `DashboardGeometryResolver` | Mind body starts at split card1 top and ends at split card2 bottom | Reuse; no mode-local coordinates | Direct geometry test |
| Axis arbitration | `GestureDirectionArbiter` | Touch slop, dominance, irreversible winning axis | Reuse in header owner | Header widget and arbiter tests |
| Structural ticker lifecycle | `DashboardMotionHost` | Shared dashboard structural motion has one Flutter ticker owner | Extend with mode transition motion, consumed locally | Rebuild-isolation test |
| Placeholder cards and visual tokens | Existing placeholder / palette primitives | Shared low-level visual roles | Reuse below separate mode roots | Mode-root widget tests |

### Layer flow

`DashboardCoreModeHost` input → `DashboardCoreModeController` semantic state;
`DashboardMotionHost` provides presentation inputs → isolated mode roots.
There is intentionally no repository, use-case, runtime, Query, paging or
LogBox step in this flow.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCM-01 | §8.1, §10.1–10.2 | application mode controller | One headless controller owns three-node cyclic mode state, one target, direction, phase, commit and cancel; no fake page index | RED/GREEN unit suite | DONE |
| SCM-02 | §8.2 | app shell / CoreDashboard wiring | Shell keeps one stable mode controller and a switch does not recreate protected dashboard owners | Widget identity test and inspection | DONE |
| SCM-03 | §8.3, §12 | mode-root presentation files | Distinct Balance, Budget and Mind roots render their own header/body placeholders and labels | Widget semantics/key test | DONE |
| SCM-04 | §8.4–8.5, §10.9 | mode host | Host mounts one settled surface, at most current+target while moving, then one; never an `IndexedStack`, PageView or retained third root | Mounted-widget test and boundary test | DONE |
| SCM-05 | §8.6, protected milestone | CoreDashboard composition | Exactly one shared LogBox/runtime remains outside the mode transition domain | Widget singleton test and source inspection | DONE |
| SCM-06 | §8.7, §10.4 | geometry resolver / mode inputs | Mind unified body uses central envelope with exact split-card top/bottom | Direct resolver test | DONE |
| SCM-07 | §8.8–8.9, §10.5–10.8 | header interaction owner | Header-only global horizontal ring navigation; vertical expansion survives; axes commit after shared arbiter; cards cannot navigate modes | Gesture widget tests | DONE |
| SCM-08 | §8.10 | mode motion | Drag-following two-surface translation uses viewport width; one central settle policy commits/cancels without fake velocity/delays | Widget transition test and source inspection | DONE |
| SCM-09 | §8.11 | motion host / mode host | Per-frame horizontal progress rebuilds only the mode host, not LogBox/rail/summary parent tree | Rebuild-isolation counter test | DONE |
| SCM-10 | §8.12 | mode roots | Only neutral existing surfaces plus top-right `balance` / `budget` / `mind` labels; no business content | Widget test / inspection | DONE |
| SCM-11 | §8.13, protected milestone | controller/host boundaries | Header mode swipe starts no dashboard/query/paging/cache data acquisition and mutates no Query/time/direction state | Counting/no-I/O widget test | DONE |
| SCM-12 | §10.12 | mode host / motion frame | Target surface receives unchanged expansion progress | Widget expansion-continuity test | DONE |
| SCM-13 | §10.14 | controller / widget host | Repeated 30-cycle ring navigation leaves no orphan target, no third root and no runtime replacement | Unit and widget test | DONE |
| SCM-14 | §12 | shell diagnostic adapter | Low-volume STARTED / COMMITTED / CANCELLED diagnostics include semantic mode and direction fields only | Controller observer test and source inspection | DONE |
| SCM-15 | §13 | boundary / regression tests | Dependency direction and all existing protected ownership contracts remain true | Focused and complete boundary suites | PARTIAL — targeted protected suite: 110 passed; full suite: 647 passed, 4 pre-existing non-mode failures (two pending Query scheduler timers, one retained-focus diagnostic key, one missing LogBox performance summary). |
| SCM-16 | §15 | commit / online human APK | One coherent production commit, clean scoped diff, online normal `lib/main.dart` APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256 | GitHub Actions and local hash | NOT DONE |
| SCM-17 | §14 | human Android device | Physical gesture/smoothness acceptance is explicitly pending human test | User verification | NOT DONE |
