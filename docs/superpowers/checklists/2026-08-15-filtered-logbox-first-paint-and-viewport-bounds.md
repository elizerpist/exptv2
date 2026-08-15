# Filtered LogBox first paint and viewport bounds — acceptance checklist

## Architecture card

### Scope and sources

- User requirement: make a prepared, non-empty Query LogBox paint in
  `railPreview` without input; then bound the one existing LogBox viewport
  between its header/facets and the shell-owned bottom navigation.
- Accepted physical reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260815-031551.png`.
- Protected interaction reference: `155f18b62da6fd894f2992567a6d8dd25042f3a9`.
- Existing implementation: `dashboard_logbox_render_surface.dart`,
  `dashboard_logbox_viewport.dart`, `core_dashboard.dart`, and
  `fluvi_app_shell.dart`.

### Single source and write path

- Rail-preview visibility: one render-domain-aware window calculation owned by
  `_DashboardLogBoxSurfacePainter`; it is read by both paint and semantics.
- Committed virtual geometry and page readiness: existing
  `CommittedLogViewportCache` / `ExplicitCommittedPagingController` ownership;
  this work has no write path into either owner.
- Header/facet height: existing `DashboardLogBoxHeader` and query-facet
  geometry; it remains the sole source of dynamic header height.
- Bottom-navigation exclusion: the app shell owns the body bounds; the LogBox
  consumes parent constraints and owns only its small visual clearance token.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Rail-preview visibility window | Surface painter | One paint/semantics pass | Top-anchored; never reads committed pixels |
| Committed visible window | Surface painter + stable ScrollPosition | Active committed interaction | Reads raw content-local pixels |
| Query/scope reset | `DashboardLogBoxViewport` | Structural presentation transition | Retains controller/position/physics identity |
| Header/facet height | `DashboardLogBoxHeader` | Current presentation | Structural sibling above scroll viewport |
| Bottom body bound | `FluviAppShell` | Shell lifetime | Layout constraint supplied to dashboard |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Preview paint and semantics culling | `_DashboardLogBoxSurfacePainter` | One private shared visible-window helper | Focused paint/semantics regression |
| Scroll interaction state machine | `DashboardLogBoxViewport` | Preserve; do not fork or add controller | Milestone identity regressions |
| Header/facet layout policy | `DashboardLogBoxHeader` | Reuse; do not duplicate chip height policy | Layout geometry tests |
| Bottom navigation sizing | `FluviAppShell` / Scaffold | Shell layout only; no LogBox BNB constants | App-shell geometry test |

### Layer flow

`Query publication → DashboardVisibleFrameStore → prepared scene cache →
DashboardLogBoxViewport → DashboardLogBoxRenderSurface`.

The UI only renders immutable prepared scene/page data and forwards gestures
to the existing viewport/controller. It neither acquires data nor owns paging.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FP-01 | Query trace and screenshot | `dashboard_logbox_render_surface.dart` | A non-empty prepared Query B paints on its first `railPreview` frame after A was scrolled non-zero; no pointer input | New deterministic widget regression | DONE |
| FP-02 | User root-cause contract | Surface painter | `railPreview` uses a top-anchored bounded window; paint and semantics share it | Focused paint/semantics test + inspection | DONE |
| FP-03 | Chip-removal trace | Query/viewport tests | Successive prepared category removals from a non-zero old scope each paint their first preview frame | Existing actual prepared-chip hotset/removal tests plus new successive render-domain scope regression | DONE |
| FP-04 | Scope transition contract | Viewport tests | Old active/recent scroll is invalidated; stable position resets, new preview paints without input | Historical no-input Query Apply test and successive old-offset scope regression | DONE |
| LP-01 | Layout requirement | `dashboard_logbox_viewport.dart` | Header/facets structurally precede one scroll viewport; no overlay spacer remains | New no-facet and facet RenderBox geometry tests | DONE |
| LP-02 | Layout requirement | Shell + dashboard viewport | Scroll viewport is bounded above the actual bottom navigation with a small tokenized clearance | New app-shell RenderBox geometry test | DONE |
| LP-03 | Virtual geometry contract | Render surface/viewport | Content-local offset begins at 0; resource publication remains geometry-neutral | Rebased signed-scroll test + approved scroll milestone regressions | DONE |
| PR-01 | 155f18b protected milestone | Existing regression suite | Vertical/horizontal controller, position, physics, geometry and cache invariants remain unchanged | `dashboard_scroll_milestone_test.dart` | DONE |
| PR-02 | Query + avatar non-regression | Existing focused tests | Directional Query atomicity and vector-sharp LogBox avatars remain intact | Query and vector/atlas suites | DONE |
| DL-01 | AGENTS.md delivery rule | GitHub Actions / APK | Final normal `lib/main.dart` human APK downloaded to `/storage/emulated/0/Download/fluvi` with SHA-256 | Exact pushed SHA action result + local hash | NOT DONE |
| HV-01 | Human Android acceptance | Normal APK | First paint, bounds, smooth scroll and avatar fidelity manually checked | Human device checklist | NOT DONE |

## Automation evidence — 2026-08-15

- Focused Query preview, LogBox surface/viewport, visible-scene continuity,
  app-shell geometry, avatar-vector, Query controller, and approved-scroll
  milestone suites: 78 passing tests.
- `./scripts/test-fluvi-fast.sh`: 178 passing tests.
- `./scripts/verify-fluvi-boundaries.sh`: passed.
- `flutter analyze --no-pub`: no issues.

`DL-01` and `HV-01` remain deliberately open until the exact pushed normal
human APK is downloaded and physically exercised on Android.
