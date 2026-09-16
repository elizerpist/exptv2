# Mind behavioral score and Header palette — inline execution plan

No approval pause applies: the user supplied the complete product and
mathematics specification and explicitly directed inline implementation.

## Architecture card

| Decision | Owner / boundary |
| --- | --- |
| Financial mathematics | A new immutable `mind/domain` daily-score projection. It receives only prepared day contributions and a canonical range; widgets and Header paint do not calculate financial values. |
| Filter authority | `CurrentLedgerQueryScope` and `QueryAmountRange` remain the only scope/range authority. The latter remains an inclusive transaction-membership filter. |
| Prepared data | Extend the existing Mind prepared-membership lane, which is populated when the resident non-amount base is admitted. Preview derives from compact daily sorted amount/prefix indexes; it never reads a repository or rich LogBox scene. |
| Publication | `DashboardCoreController` owns one generation-checked `MindBehavioralScoreLiveProjection`, installed and previewed alongside the existing Mind heatmap. The visible Header consumes only its immutable frame. |
| Header visual material | A new independent `DashboardMindHeaderColorPolicy`, modelled after Budget's policy, samples the score-centered traffic scale and feeds the existing `DashboardHeaderVisualFrame` lane. It owns no Budget state. |
| Header content | `MindDashboardCoreSurface` receives the score frame and renders `x/100` through `DashboardCoreModeHeaderScaffold.detail`; it does not rebuild from the Header ticker. |
| Tuning | `DashboardHeaderVisualTuning` owns only Mind window width (10–100%, default 28%), separate from Budget. The center is always the score. |
| Animation | The existing dashboard-lifetime `DashboardHeaderVisualController` remains the sole ticker/controller. Score changes change semantic frame material only. |

## Acceptance checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MBS-01 | §§4–5, 8–10, 15–16 | Mind domain/controller | The immutable frame carries prepared scope/revision, direction, range and target-day provenance; all canonical facets and inclusive range membership apply once; daily points are view invariant and latest-wins. | Pure + production-controller tests, diagnostics | DONE |
| MBS-02 | §6 | Mind domain | Expense uses causal trailing 31-day context; sparse `<=12` active days is amount-dominant; dense score uses dynamic EMA, causal deterministic normalization and 50/50 pressure without a fixed HUF threshold. | Numerical tests incl. future-invariance | DONE |
| MBS-03 | §7 | Mind domain | Income uses daily R, prior 1–3 meaningful samples, median baseline and capped ±30 trend; `noSignal` remains distinct from a signalled numeric 50. | Numerical tests | DONE |
| MBS-04 | §§8–10, 16 | Prepared projection/live controller | Day/Month/Year/Sum selects points from one daily series. Slider previews update score synchronously from resident indexes with no row/repository/index/scene work. | Live/prod-controller tests + fail-closed profile counters | DONE |
| MBS-05 | §§11, 14 | Header engine | A deterministic seven-anchor traffic scale samples independently clamped left/center/right score window into the existing frame engine, for static and animated effects, without a second ticker. | Header policy tests | DONE |
| MBS-06 | §12 | Header tuner | Existing tuner exposes independent Mind `Ablakszélesség` 10–100%; it changes palette only, not score/Budget state. | Tuner test | DONE |
| MBS-07 | §13 | Mind surface/header scaffold | Semantic Mind Header displays rounded `x/100`; no score text in painter or ticker-based rebuild. | Widget test | DONE |
| MBS-08 | §§17–20 | Tests/diagnostics | Required math, palette, liveness and bounded profile evidence is present; protected physics/query/LogBox ownership remains intact. | Focused suites + analyzer pass; physical Android profile pending CI | PARTIAL |
| MBS-09 | §§22–25 | Git/tooling/docs | One atomic app commit/push on mandated branch; human APK delivery, matching SCIP on tooling branch, then separate `[skip ci]` factual journal commit. | Git/GitHub/SCIP/journal checks | NOT DONE |

## Execution order

1. Add RED numerical tests for the pure daily score and score-window samples.
2. Implement the immutable prepared score domain and run its tests.
3. Bind it to the existing resident Mind membership and the controller's range
   preview/commit and semantic scope paths with stale identity guards.
4. Add the independent Mind Header color policy and tuning state, then test
   it separately from Budget.
5. Bind semantic score text to the Mind Header and validate production-parent
   direction/time/focus/range behavior.
6. Collect bounded profile counters, analyze and protected suites; re-read the
   checklist and prototype; commit/push/app-deliver, regenerate exact SCIP,
   append the separate factual journal entry and report every command honestly.
