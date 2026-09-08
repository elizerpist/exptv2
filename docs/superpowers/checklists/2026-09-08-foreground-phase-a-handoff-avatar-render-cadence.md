# Foreground Phase-A handoff and Avatar render cadence — acceptance checklist

Status key: `DONE`, `PARTIAL`, `BLOCKED`, `NOT DONE`.

This repair is based exactly on application commit `fc35c1bbe280fdcecb262960eefd1e282595f7b6`.
The frozen 2026-09-08 Drive evidence is recorded in
`docs/superpowers/evidence/2026-09-08-foreground-phase-a-handoff-avatar-render-cadence/manifest.md`.
The Avatar and Time documents are separate sessions and are never treated as
one timeline.

| ID | Source | Intended ownership / code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| FPA-01 | User §7.1; `fc35` evidence | Avatar `DashboardCoreController` Phase-A candidate | The accepted Avatar Phase-A transaction from `fc35` remains intact: one coherent target drives Header, progress, Summary and LogBox without settle. | Existing fc35 production-parent regressions plus new cross-producer regression. | DONE |
| FPA-02 | User §9; Time trace seq 2177–2387 | `DashboardCoreController` foreground ownership and motion lanes | A raw Time/Summary pointer claims foreground ownership before the gesture arena completes, supersedes obsolete Avatar callbacks and releases its foreground preparation lease without recreating physics/controller. | Real Core/cache/store Avatar-active → Time-takeover red/green test; source consumer audit. | DONE |
| FPA-03 | User §9 reverse path | Same shared foreground mechanism | A raw Avatar pointer symmetrically supersedes obsolete Time callbacks; the current valid Time frame remains until Avatar exact Phase A is ready. | Real Core/cache/store Time-active → Avatar-takeover regression. | DONE |
| FPA-04 | User §10; Time trace 8 misses/one paint | Time `timePreview` lane, prepared scene cache and presentation path | A non-empty Time semantic target never obtains visible authority without its exact readable Phase-A resource. It retains the previous valid visual while cold. | Cold real-cache red/green test checks no `readableResourceMissing`, no 13 px non-empty surface and actual exact paint. | DONE |
| FPA-05 | User §10C | Time pending candidate / display coalescer | Cold targets are latest-wins; every accepted intent has an explicit terminal visual outcome, and only the latest same-vsync survivor must paint. | Multiple-target production-parent regression and diagnostics assertions. | DONE |
| FPA-06 | User §15 | Cache completion → Time bind/repaint boundary | Resource completion publishes and paints the current exact Time target without Header collapse, and collapse/expand cannot promote stale work or duplicate paint. | Deterministic no-collapse / post-collapse no-op regression. | DONE |
| FPA-07 | User §11; Time trace retained Avatar flight | Pointer/gesture/scroll/semantic/presentation diagnostics | The first Avatar interaction has bounded, target-correlated measurements from pointer down through raster; no semantic threshold is changed to conceal a delay. | Focused diagnostics test/source audit and profile harness output. | PARTIAL |
| FPA-08 | User §12 | Actual Budget progress widget/painter | Every accepted Avatar target receives a target/generation-correlated progress paint acknowledgement; model bind alone is insufficient. | Widget/paint acknowledgement regression for two targets. | DONE |
| FPA-09 | User §13; Time trace FrameTiming | Avatar presentation consumers | Measure rebuild/layout/repaint/raster cost after the fast semantic store path, then implement only a measured isolation. | Instrumented profile/device comparison; focused structural test. | PARTIAL |
| FPA-10 | User §13–14 | Carousel controllers and physics | No controller recreation, physics retune, threshold/spacing/velocity change, or dropped target is used to improve cadence. | Diff audit, existing carousel tests, source inspection. | DONE |
| FPA-11 | User §16–17 | Core/store/cache/LogBox/Mind-Slider surfaces | One Core, store, cache, viewport and LogBox remain; Mind/Slider production source is unchanged. | `git diff --name-only`, protected tests, direct owner audit. | DONE |
| FPA-12 | User §21 | Semantic crossing hot path | No repository/index/query commit/rich-scene/TextPainter work is added at Avatar or Time crossings. | Existing counters plus new takeover/cold-path diagnostics. | DONE |
| FPA-13 | User §25 | Flutter validation in Ubuntu proot | Focused regressions, dashboard application/presentation suites, fast suite, analyzer and protected Slider tests are honestly recorded. | Exact commands and normalized outputs. | DONE |
| FPA-14 | User §26 and global delivery rule | App delivery + SCIP tooling | Each production app commit is pushed, its exact online human APK is downloaded and hashed, and a separately committed SCIP graph indexes the final app SHA. | GitHub Actions evidence, APK SHA-256, final graph manifest and deterministic regeneration. | NOT DONE |
| FPA-15 | User §21 / §28 | Physical device | Physical correctness and performance are not claimed by the agent. | User-only physical validation. | PENDING — USER ONLY |
| FPA-16 | User §25; delivery profile artifact audit | `integration_test/dashboard_interaction_profile_test.dart` | The online profile matrix includes a real production-composition Avatar crossing with an accepted exact publication and records its bounded pipeline/paint evidence. | A dedicated profile artifact plus source-level integration test assertions. | PARTIAL |
| FPA-17 | CI run `34259701012`; User §10 and §15 | Initial LogBox render/readiness boundary | A cold non-empty Time payload never reaches a LogBox paint attempt without exact readable Phase A, including while the normal startup readiness layer is mounted. | New production-shell regression with a populated prepared index; online A–K profile rerun. | PARTIAL |

## Protected prior work

`fc35` repaired a cold Avatar exact-resource admission bug. Its pending Avatar
candidate, original interaction order, exact `budgetAvatarPreview` binder and
atomic Budget transaction are protected. AVP-04 was `PARTIAL` because physical
hot-path cost was not yet measured; AVP-10 remained `NOT DONE` because device
FrameTiming was pending. This checklist does not reopen either semantic design.

## Implementation and validation record

- `f39091d2` contains the foreground Time Phase-A handoff and exact-cache
  admission; `5b43a647` contains the observational Avatar paint pipeline.
- The current branch adds one typed foreground claim in
  `DashboardCoreController`; it cancels only the obsolete producer's logical
  callbacks and typed live-resource lease. It does not recreate a carousel,
  `ScrollPosition`, cache, store, viewport or LogBox.
- A Summary pointer invokes that claim before arena completion and immediately
  starts its `timePreview` request. The exact baseline control fails on
  `fc35c1b` because that resource is not ready while the Avatar lane remains
  active; it passes after the repair.
- Time cold publication retains only the latest candidate and uses the real
  cache completion boundary. The cache also now treats changed surface metrics
  as a different live resource even when the semantic key is the same.
- Header and Budget-progress measurements are observational only. Pure Dart
  model tests receive a `-1` renderer timestamp when no binding exists; app
  debug/profile builds retain the real vsync timestamp.
- `flutter analyze` passed. Focused FPA/cache/rail/Header tests, dashboard
  application (`286`), fast (`294`), protected Mind/Slider (`16`), profile
  contract (`22`) and centered-carousel (`53`) tests passed.
- The full presentation suite completed with `595` tests and `19` failures.
  The exact same five untouched test files fail with the exact same 19
  failures on `fc35c1b`: six platform/golden diffs, Header parity/deep-drift
  fixture assertions, eight Header ticker-disposal/temporal assertions, and
  the existing multi-`Scrollable` stable-render-surface fixture. No goldens
  were regenerated.
- FPA-07 and FPA-09 remain partial: diagnostics and production-parent
  assertions are present, but no new physical-device FrameTiming run has been
  obtained. A local Termux profile drive is intentionally not substituted for
  the required physical/device CI evidence.
- The first online A–J profile delivery passed but its exported scenarios
  contain no Avatar/Budget Avatar semantic publication. It is therefore not
  evidence for FPA-16 and triggered the dedicated production-profile follow-up.
- The follow-up adds `K_avatar_first_target`: a fresh app mount reaches Budget
  through the production Header gesture, then flings the actual Avatar rail
  without preinstalling a category scene. Its bounded report must contain the
  real Avatar motion-lane claim, semantic crossing, exact Phase-A LogBox
  paint, coherent current visible frame, actual Budget-progress paint and one
  first-target terminal pipeline result. Local report-contract and boundary
  tests pass; the required online profile artifact is still pending, so FPA-16
  remains `PARTIAL`.
- The first A–K profile run (`34259701012`) reached K but failed its final
  report audit because `I_first_fling` recorded one
  `visiblePayloadWithoutDrawable`. Source and timestamp inspection localised
  this to the cold first-render interval: the non-empty payload reaches the
  stable render surface before its exact-width Phase-A warmup completes. The
  startup overlay prevents the user from seeing that frame, but it is still a
  renderer contract violation and must be repaired rather than waived. Until
  its production-parent regression and a new online profile pass, FPA-17
  remains incomplete.
- The FPA-17 production-shell regression was red on `c2a9046f`: its populated
  cold Time payload produced `visiblePayloadWithoutDrawable=1`. The repaired
  path now passes with `0`, waits for the exact `timePreview` readable bank,
  records one bounded initial defer event, and then records actual row paint on
  the same stable surface. The local proof does not replace the required
  online A–K profile rerun, so FPA-17 remains `PARTIAL`.
- Follow-up validation after the FPA-17 repair passed: format check and
  analyzer; FPA-17 (`1`), complete app shell (`17`), LogBox viewport (`32`),
  query-preview paint (`24`), visible-scene continuity (`2`), core ephemeral
  focus (`56`), Avatar rail (`47`), dashboard application (`286`), fast
  suite (`294`), and protected Mind/Slider range/query (`16`). The complete
  presentation command finished `595` tests with the same `19` inherited
  failures already recorded against `fc35c1b`; the generated golden-diff PNGs
  were discarded rather than accepted. This closes the local-validation record
  in FPA-13 but does not close online delivery/profile FPA-14/FPA-16/FPA-17.
