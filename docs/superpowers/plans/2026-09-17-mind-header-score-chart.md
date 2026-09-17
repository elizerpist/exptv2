# Mind Header Score Chart Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add the reference-faithful, expanded-only Mind score-history line chart without adding a score authority, header ticker, or independent reveal animation.

**Architecture:** The existing prepared `MindBehavioralScoreProjection` remains the only financial-score authority. Its live publication creates a compact immutable visual history from the same canonical daily point calculation; the Mind surface supplies that view data to a semantic Header overlay. A chart-only custom painter consumes immutable score samples and expansion progress to draw the white line, endpoint and white vertical fade; it never reads ledger/query data and owns no animation.

**Tech Stack:** Flutter/Dart, existing `ValueListenable` score publication, `CustomPainter`, shared `DashboardCoreModeHeaderScaffold` and `DashboardHeaderVisualController`.

## Global Constraints

- Reference authority: `/storage/emulated/0/spendee/mind score Reference .png` (the on-device spelling includes capital `Reference` and a space before `.png`).
- Work directly on `fix/mind-year-heatmap-calendar-direction-fluvi-20260913`; preserve existing untracked paths exactly.
- Use the existing Header expansion progress and physical Header shell; no second ticker/controller, entrance animation, overlay hit-test owner, Query state, score algorithm, repository call, Room access, index build, or rich-scene/TextPainter work on the Header drag or painter path.
- Keep the score semantic text in the Header content lane and the existing physical palette/effect engine intact.
- The visual history must come from the existing canonical daily score mathematics, scoped by the visible time selection and current range/filter identity.
- The score/chart/frame publication must be generation-checked/latest-wins and atomic from the semantic Header consumer's perspective.
- Validate in Ubuntu proot; normal human APK delivery is GitHub Actions only.

## Mind Header chart architecture card

### Scope and sources

- User requirement: strict expanded Mind Header chart, continuous pull-down reveal, top-left score text, one white line/endpoint and white under-line fade.
- Accepted reference: `/storage/emulated/0/spendee/mind score Reference .png`, inspected at 941×1663 px. Its Header maps to the Fluvi reference canvas as score origin `(16, 16)`, plot bounds approximately `(16, 48, 346, 60)`, with the white endpoint at the plot's right edge.
- Existing owners: `MindBehavioralScoreProjection`, `MindBehavioralScoreLiveProjection`, `DashboardCoreController.ensureMindBehavioralScoreProjection`, `MindDashboardCoreSurface`, and `DashboardCoreModeHeaderScaffold`.

### Single source and write path

- Source of truth: immutable prepared Mind contributions and canonical `MindBehavioralScoreProjection` daily point formula.
- Read model: `MindBehavioralScoreFrame`, extended with an immutable, bounded chart-series value carrying daily score samples and its scope provenance.
- Only write path: `MindBehavioralScoreLiveProjection.install/publishTarget`, called from the existing Core semantic scope/range publication path.
- Error/retry owner: existing Core prepared-base/score projection admission; the chart never retries or performs I/O.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Daily score/score history | `MindBehavioralScoreProjection` | prepared score identity | Pure resident read only |
| Visible score/chart frame | `MindBehavioralScoreLiveProjection` | active semantic Mind scope | One identity/range/scope generation-checked publication |
| Expansion reveal | `DashboardGeometryResolver` / existing collapse controller | existing Header gesture | Header surface only reads `headerExpansionProgress` |
| Line/fade paint | chart `CustomPainter` | one paint | Receives immutable samples; no state or ticker |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- |
| Daily score mathematics | `MindBehavioralScoreProjection` | exact canonical daily score | Extend projection with chart sampling | Unit tests compare samples with `preview` |
| Header pull-down | `DashboardGeometryResolver` | one physical expansion progress | Consume it through current Mind surface | Widget test covers 0/intermediate/1 reveal |
| Header visual effects/ticker | `DashboardHeaderVisualController` | one visual clock | Leave untouched | Controller identity widget test |
| Header physical card/bounds | `DashboardCoreModeHeaderScaffold` | clip, paint, depth and border ordering | Add semantic overlay slot, not another card | source and widget checks |

### Layer flow

Prepared score contributions → `MindBehavioralScoreProjection` → `MindBehavioralScoreLiveProjection` → `MindDashboardCoreSurface` semantic overlay → chart painter.

### Verification

- Domain/unit: sampled history is bounded, chronological, canonical-point equivalent and range-aware.
- Widget/integration: expanded-only clipping, continuous intermediate reveal, top-left score anchor, no score rebuild from Header visual ticker, controller identity stable.
- Screenshot/reference: render representative expanded Mind Header and compare plot placement, score placement, line, endpoint and white fade directly against the accepted PNG.
- Performance: score-chart samples are produced only by semantic score publications; painter does no financial work and profile counters show no repository/index/source-row preview work.

## Feature acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MHC-01 | User §1–5 | Mind Header overlay | Chart exists only while Header has positive expansion reveal and is clipped by it continuously | Widget test at 0/.5/1 | DONE |
| MHC-02 | PNG | Mind Header layout | Score is anchored upper-left at `(16,16)` Header coordinates, matching Budget amount lane | Production-host rect test + inspected golden/reference | DONE |
| MHC-03 | PNG | chart painter | Plot uses approximate `(16,48,346,60)` logical bounds, thin white line and small outlined endpoint | Painter/widget geometry + inspected golden/reference | DONE |
| MHC-04 | PNG/user §10 | chart painter | White vertical fade exists underneath the line; it is not opaque or another color | Painter specification + inspected golden/reference | DONE |
| MHC-05 | User behavior | Header/chart overlay | Reveal is an existing Header-expansion clip, with no independent slide/fade/ticker | Widget test + source inspection | DONE |
| MHC-06 | User behavior | score projection/live publication | History uses canonical daily points for current time/filter/range scope | Domain/live/Core tests | DONE |
| MHC-07 | User quality | domain/painter | Chart sample work is bounded and painter has no finance/query/repository work | Resident-index one-pass test + source inspection | DONE |
| MHC-08 | Architecture guardrail | Header engine | Existing shared Header controller/effects/palette stay the only visual engine/ticker | Header engine/color/tuner tests | DONE |
| MHC-09 | User quality | Header semantic layer | Score text and chart redraw from score publication, never ticker frames | Host widget and source-boundary tests | DONE |
| MHC-10 | User requirement | test boundary suite | Presentation has no repository/score-formula ownership; Core/live path remains sole write path | Dependency/source boundary test | DONE |
| MHC-11 | Delivery | app branch | Focused tests, analysis, Actions human APK and matching SCIP are recorded honestly | command output, CI, manifest | PARTIAL — commit/push, Actions APK and matching SCIP pending |
| MHC-12 | User acceptance | physical device | Physical visual acceptance is user-only | APK handoff | PENDING — USER ONLY |

---

### Task 1: Canonical chart-series domain

**Files:**

- Modify: `lib/features/dashboard/mind/domain/mind_behavioral_score_projection.dart`
- Modify: `lib/features/dashboard/mind/domain/mind_behavioral_score_live_projection.dart`
- Test: `test/features/dashboard/mind/domain/mind_behavioral_score_chart_series_test.dart`

- [x] Write RED tests for chronological bounded samples, inclusive range membership, and equality of each sampled score with the existing `preview` point.
- [x] Run the test and record the expected missing chart-series API failure.
- [x] Add immutable `MindBehavioralScoreChartSeries` and scope provenance, sampled exclusively through canonical daily mathematics.
- [x] Extend live install/target/preview publication to carry history bounds and atomically replace point plus chart series.
- [x] Run the domain tests green.

### Task 2: Core scope binding and boundary checks

**Files:**

- Modify: `lib/features/dashboard/application/dashboard_core_controller.dart`
- Modify: `test/features/dashboard/application/dashboard_core_ephemeral_focus_test.dart`
- Test: `test/features/dashboard/presentation/mind_header_chart_boundary_test.dart`

- [x] Write RED tests proving visible Month bounds flow into the single score publication and a range preview replaces its chart series without source-row/repository/index work.
- [x] Run RED focused tests.
- [x] Add one scope-bound resolver to the existing score Core path; use actual data limits for Sum and existing selected boundaries otherwise.
- [x] Add the production-source dependency/ownership assertions and run focused green tests.

### Task 3: Reference-faithful semantic Header chart

**Files:**

- Create: `lib/features/dashboard/mind/presentation/mind_header_score_chart.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/mind_dashboard_core_surface.dart`
- Modify: `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`
- Test: `test/features/dashboard/presentation/mind_header_score_chart_test.dart`

- [x] Write RED widget/painter tests for zero/intermediate/full reveal, score rect, plot rect, endpoint and white gradient paint specification.
- [x] Run RED test.
- [x] Add the semantic overlay slot to the existing Header scaffold and render the immutable series through a no-state `CustomPainter`; use a direct `ClipRect` reveal derived from `headerExpansionProgress` rather than an animation.
- [x] Move Mind score text into the reference top-left lane and run widget tests green.

### Task 4: Visual, performance and delivery evidence

**Files:**

- Modify: `docs/superpowers/plans/2026-09-17-mind-header-score-chart.md`
- Modify: `docs/FLUVI_ENGINEERING_JOURNAL.md` in a separate `[skip ci]` commit after the application commit

- [x] Run focused and protected Ubuntu-proot tests, formatting, analyzer and `git diff --check`.
- [x] Generate/inspect a representative expanded-header golden against the PNG and record the five required self-checks: upper-left score, `(16,48,346×60)` chart geometry, thin smooth white line/endpoint, white under-line fade, physical progressive clip.
- [ ] Commit/push the atomic application feature; monitor/download the exact Actions human diagnostic APK and record its SHA-256.
- [ ] Regenerate matching SCIP on `tooling/scip-codegraph-v1`, push it, then append factual journal evidence separately.
- [ ] Re-read this checklist; set every factual status and leave physical validation `PENDING — USER ONLY`.
