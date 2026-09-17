# Mind adaptive amount domain, Fastfood mirror and perceptual palette Implementation Plan

> **For agentic workers:** Execute inline on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`; the user explicitly forbids a new application branch or worktree. Each implementation task follows RED → GREEN → focused verification.

**Goal:** Refine the production Mind score experience with an exact non-recursive amount domain, adaptive monetary slider snapping, a deterministic 2027 Fastfood mirror, and the approved perceptual score palette without changing the accepted expanded Header chart.

**Architecture:** `QueryAmountRange.domainScope` remains the sole boundary between canonical non-amount scope and the amount filter. The native `FluviLedgerReadService.queryMenuFacets()` computes its maximum from that exact scope; `CurrentQueryController` caches the immutable presentation by that identity. The shared range renderer receives only the bound immutable range and locally snaps preview values; only the existing Core commit lane mutates canonical Query state. The native demo generator appends a static source-verified Fastfood list to the deterministic manifest for 2027. A shared Header perceptual-color utility is extracted from the established Category scale and sampled by the Mind-only score color policy.

**Tech stack:** Flutter/Dart, Kotlin/Room deterministic demo seed, existing Android method-channel Query boundary, Flutter widget/unit/golden tests, Kotlin/JUnit/Robolectric tests, SCIP tooling.

## Global constraints

- Current remote baseline is journal-only `95cf88fc`; accepted chart runtime baseline is `505e6873`.
- Reference image: `/storage/emulated/0/spendee/mind score Reference .png`.
- Fastfood source authority: `f332b7128db300f5b0d38065eb0a124dc5bbf56b:docs/prototypes/stats_fastfood_2025_sim.html`.
- The accepted chart geometry, score lane, white line/fade/endpoint, pull-down clipping, Menu, visual controller and one Header ticker are no-touch.
- No new Query/filter controller, no pointer-path Room/repository/index/row scan, no timer/debounce/remount/cache flush, and no Budget behavior change.
- Preserve every pre-existing tracked/untracked user file unrelated to this delivery exactly as found.

## Mind refinement architecture card

### Scope and sources

- User requirement: adaptive domain/step/layout, exact 2027 Fastfood mirror, approved 8-anchor perceptual Mind palette.
- Accepted reference paths: device PNG above; app chart at `lib/features/dashboard/mind/presentation/mind_header_score_chart.dart` from `505e6873`.
- Existing owners: `QueryAmountRange`, `CurrentQueryController`, `DashboardAppliedQueryFacetLoader`, `QueryAmountRangeControl`, `FluviLedgerReadService`, `DemoDatasetGenerator`, `MindHeaderTrafficLightScale`, and `DashboardMindHeaderColorPolicy`.

### Single source and write path

- Amount-domain truth: native `FluviLedgerReadService.amountDomain(rangeScope)`; it removes only minimum/maximum amount refinements before SQL aggregation.
- Amount-preview truth: the shared `QueryAmountRangeControl` display-frame coalescer; it only publishes immutable range values.
- Canonical range write path: existing `DashboardCoreController.commitMindAmountRange` → `QueryAmountRange.apply`.
- Fastfood source truth: a static normalized 2025 source-row list with verified count/digest; demo generator maps it to the real deterministic category/partner IDs and appends 2027 entries.
- Mind palette truth: `MindHeaderTrafficLightScale` samples the shared perceptual utility; Header window remains `MindHeaderScoreWindowSampler`.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Non-amount domain maximum | native query result cached by `CurrentQueryController` | exact directional domain identity | replaced only by exact facets result |
| Drag preview/snapped step | `QueryAmountRangeControl` | physical pointer interaction | coalesced semantic preview; never persistent |
| Canonical amount refinement | `CurrentQueryController` through Core | dashboard/query lifetime | existing final commit boundary only |
| Fastfood 2027 manifest | `DemoDatasetGenerator` | deterministic seed plan | append-only deterministic IDs; seed-version reset retains idempotence |
| Score palette/window | `DashboardMindHeaderColorPolicy` / existing tuning | dashboard lifetime | semantic score/tuner update only, never ticker frame |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Query domain identity | `QueryAmountRange.domainScope` | Extend range resolution only; no Mind state | domain identity/unit/loader tests |
| Slider preview/commit | `QueryAmountRangeControl` + Core | Add local snapping to the shared control | widget preview/final parity tests |
| Perceptual interpolation | private Category Header OKLCH math | Extract neutral shared Header utility, migrate Category and Mind | Category regression plus Mind palette tests |
| Header motion | `DashboardHeaderVisualController` | Do not change | chart boundary/controller identity tests |
| Seed persistence | `SeedFluviDemoDatasetUseCase` / `DemoDatasetGenerator` | Append deterministic manifest entries | Room query/idempotence mirror test |

### Layer flow

`RangeSlider UI → QueryAmountRangeControl preview/intent → DashboardCoreController → CurrentQueryController → QueryMenuRepository bridge → FluviLedgerReadService/Room`.

`DemoDatasetGenerator → SeedFluviDemoDatasetUseCase → Room → existing query/read path`.

`Mind score frame + Header tuning → DashboardMindHeaderColorPolicy → DashboardHeaderVisualFrame → existing shared visual controller`.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MRA-01 | §§4–6 | Query range + native facets | exact maximum belongs to non-amount domain; right-thumb filtering cannot shrink it | Dart/native domain tests | DONE — Dart range tests pass; exact x86 CI Room/facet suite is green in run `35196364731`. |
| MRA-02 | §§7–8 | shared range control | 1/2/5 monetary step is deterministic, monotonic, preview/final snapped parity and no pointer I/O | pure + widget/live tests | DONE — focused domain/control tests pass, including 260k/100k/20k/5k and terminal preview flush. |
| MRA-03 | §9 | compact Mind range surface | slider precedes exactly one caption/value row without footer/layout regression | widget/layout test | DONE — compact layout test passes with one Slider and the caption row below it. |
| MRA-04 | §§10–12 | static demo source fixture | source-list count is 100 and normalized SHA-256 is `cd8ec0a6bb2e5558a11e3dddd7aa6a087d9edde897b13fceea1da4eb82e5a65e` | generator test | DONE — direct committed-prototype extraction, Kotlin fixture comparison and x86 CI core suite are green. |
| MRA-05 | §§11–14 | generator/use case/Room | real `Gyorsétterem` category and six partners map exact semantic 2027 rows; idempotent normal query path | Kotlin Room test | DONE — real seed/Room query/idempotence tests pass in the x86 CI core suite. |
| MRA-06 | §§15–17 | Mind palette + shared Header color utility | exact 8 anchors, OKLab/OKLCH interpolation, unchanged window/tuner, Budget unaffected | pure/policy tests | DONE — 8-anchor/clamp/non-RGB/window/Budget tests pass; Category regression stays green. |
| MRA-07 | §§1,18,22 | Mind Header chart/surface | chart baseline geometry, line/fade/endpoint/reveal/controller remain unchanged and readable | existing chart golden/boundary tests + source inspection | DONE — chart source is untouched; reference geometry/boundary tests and refreshed palette-following golden pass after direct reference inspection. |
| MRA-08 | §§8,21 | query/controller/header paths | domain refresh occurs only on domain identity; drag reuses cached max and does no DB/index/row work | source-boundary + live tests | DONE — existing loader's amount-only-domain no-refetch and Core live-preview suites pass; only immutable local snapping runs during drag. |
| MRA-09 | §§19–24 | test suites | required adaptive, query, heatmap/score, chart, color, Budget, DB-mirror tests and analyzer/diff check have evidence | exact command log | PARTIAL — focused Flutter suites/analyzer and x86 native suites pass; the broad local Flutter suite retains its inherited 30-second scene-window timeout, and CI profile FrameTiming is separately red. |
| MRA-10 | §§23–27 | GitHub/tooling | feature commit/push, matching SCIP and human APK delivery if CI supports it; profile result remains honest | GitHub/tooling evidence | PARTIAL — application/tests and exact SCIP/APK are pushed/delivered; CI profile remains the inherited null-FrameTiming failure. |
| MRA-11 | §26 | physical device | user-only physical acceptance | user verification | PENDING — USER ONLY |

## Tasks

### Task 1: Lock existing query and chart contracts

**Files:**
- Modify: this checklist only before production code.
- Test: existing `query_amount_range_test.dart`, range-control/heatmap/live/chart suites.

- [x] Add RED domain/step/compact-order assertions, including degenerate domains and preview/final parity.
- [x] Run their exact Flutter test commands and record expected failures.
- [x] Implement only shared range-domain resolution and local snapping/layout.
- [x] Run focused green tests.

### Task 2: Add the source-verified Fastfood 2027 manifest

**Files:**
- Create: `android/fluvi-core/src/main/kotlin/com/fluvi/core/demo/FastfoodPrototype2025Rows.kt`.
- Modify: `DemoDatasetGenerator.kt`, `DemoDatasetVersion.kt`, Kotlin generator/seed tests.

- [x] Add RED source-count/digest/semantic-mirror and normal Room query tests.
- [x] Run native test; it is blocked before Kotlin test execution by the documented local AAPT2 daemon startup failure.
- [x] Add the static 100-row source list, append stable real category/partners and 2027 entry IDs, bump seed version/window contracts.
- [x] Run generator/use-case tests through normal Room/query machinery in x86 CI.

### Task 3: Replace the Mind scale through a shared perceptual utility

**Files:**
- Create: `lib/features/dashboard/presentation/core_modes/dashboard_header_perceptual_color.dart`.
- Modify: `dashboard_header_category_scale.dart`, `dashboard_header_mind_score_color.dart`, Mind palette and Category regression tests.

- [x] Add RED exact-anchor, clamp, non-encoded-midpoint, window and Budget-isolation assertions.
- [x] Run RED focused palette tests.
- [x] Extract existing validated OKLCH math and migrate both consumers; install approved anchors.
- [x] Run palette, Budget and chart golden/boundary green tests.

### Task 4: Production integration and delivery

- [x] Run protected query, heatmap, score-live, compact-range, chart, palette/Budget and changed-source analysis suites; Kotlin demo/Room waits for CI.
- [x] Reinspect reference PNG and chart golden; re-read this checklist and update every status truthfully.
- [x] Commit the application feature on the mandatory branch, push, deliver the human APK, and generate source-matching SCIP separately. The inherited CI profile FrameTiming failure remains recorded as a non-green gate.
- [ ] Append final factual journal evidence in a separate `[skip ci]` commit if requested by the repository delivery protocol.
