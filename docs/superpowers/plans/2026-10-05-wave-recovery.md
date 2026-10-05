# Balance Month wave recovery: implementation and acceptance record

## Resumed visual completion — 2026-10-05

The user explicitly requests completion, with the desired screenshot as the
visual source of truth and a substantially similar result as the acceptance
target. Both original local phone captures and the `material-v3` reference and
sparse parent renders were reopened. The current render still has abrupt dark
vertical bands, a block-like foreground and repetitive disconnected background
hills. Successful pixel coverage tests alone do not satisfy WR-10/11/18.

Continue the existing inline plan in the existing linked `3d-linechart`
worktree. The rendering/inspection steps share one material and geometry owner
and are sequential. Preserve the independently owned uncommitted FAB cyan
changes and all pre-existing failure images; do not stage them in wave commits.
The bounded-curve extraction belongs to this task and retains Mind output.

Next gates: (1) correct the form-lighting/foreground composition and open the
reference-shaped and sparse render; (2) strengthen boundary, material, actual
parent gestures, cache/async/error and financial mapping coverage; (3) measure
bounded render resources, run targeted/curated regressions and analyzer;
(4) reconcile each checklist item, commit/journal/push, deliver the normal
Human APK, and regenerate the final-source graph on its separate tooling line.
Historical installed identity and physical FrameTiming remain unavailable and
must not be inferred from software raster evidence.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| WR-27 | Reopened desired screenshot; latest user instruction | Material and atmospheric composition | Broad rounded lavender bodies, soft upper-left light, recognizable overlapping depth and pale foreground; no slab-like base | Open final reference/sparse/body/ablation renders side-by-side with desired crop | DONE |
| WR-28 | Ownership/reuse gate | Chart geometry/material and shared bounded curve | One material/palette and interpolation mechanism; UI only owns ephemeral selection/resources; protected Mind output identical | Boundary suite and exact-control regression | DONE |

Execution: inline, explicitly requested by the user. The later instruction
`3d linechart` means the valid Git branch `3d-linechart`; it supersedes both
the original no-branch instruction and the pasted handoff's `3d-chart` name.
Routine diagnostic, repair, visual and delivery iterations are pre-authorized.

## Scope and architecture

Only the Month spending terrain, its render resources, local bounds, tests and
diagnostics may change. The financial authority is
`DashboardBalancePrimaryProjection._month` -> cumulative `dailyPoints` ->
`BalanceAlternativeMonthlySpendPresentation.fromPrimary` -> immutable individual
daily values -> `BalanceAlternativeDailySpendCard` -> `_DailySpendChart` ->
`FluviTopographicWaveChart`. The projection includes every calendar day. Units
are minor HUF: `26_800_000` becomes `268 k Ft` through the existing formatter.
No financial/persistence/query/controller owner is added or replaced.

The existing chart State owns ephemeral selection, the single-entry geometry
cache and async shader resources. The terrain owns data projection, interpolation,
body geometry and cached mesh. Both renderer routes must share this geometry,
material policy and identities. Extract chart-internal geometry/material/resource
responsibilities only where this makes their existing ownership testable; do not
copy a second algorithm. The 1127-line original chart mixes these responsibilities.

The existing monthly card, Savings slot and lower strip stay in their actual
`BalanceDashboardCoreSurface` composition. The chart owns its clip and
RepaintBoundary and tap recognizer; decoration is paint-only/IgnorePointer.
The original Current option, settings/persistence, Header line chart, Savings
asset/allocation, lower bar, global Stack, Mind, Budget, Avatar and financial
pipeline are protected. Performance anchor: `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.

## References and provenance (re-read before visual changes)

- Canonical worktree: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi-balance-wave-defaults`.
- Initial local HEAD: `90d633a64ead9cd685ed9f9ed647a0c0a009f43b`.
- Fetched development base: `75e4e158f340ae1d2da9493fb5c53b4361f80057`.
- Last application source / isolated reproduction: `f34d6afb6ee7475864f36075395c505126b37758`, parent `5f568fb618901e3128c26d24480a1557e80ea500`.
- Base differs from application source in documentation only. Remote: `https://github.com/elizerpist/exptv2.git`.
- Desired full phone capture, opened: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261005-021521.png`, SHA-256 `58626ddb0bccb9c09ffd49a1b7015b60be6fb541e9bc7d8d6ebaf74ae65dac77`.
- Rejected full phone capture, opened: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261005-074605.png`, SHA-256 `433ab105def35c13c428ba9bde4f53b9ec9e5769210436ca42e05dc31ee31634`.
- The handoff's 690x1536 `1000125266.png` and `1000125268.png` bytes/hashes were not found. The opened local captures show the same described wave scenes, at a different resolution. Do not claim byte identity. Gallery controls are excluded from comparison crops. The Mind heatmap is not a reference.
- Earlier style input: `/storage/emulated/0/spendee/asset/fluvi_3d_wave_chart_asset.svg`; no static illustration may enter production.
- Local rules read completely: `/storage/emulated/0/Download/FLUVI_PROMPT_WRITER_RULES.md` (1135 lines); numbered `(1)` file unavailable. Its prompt-writer-only role is superseded by the user's explicit implementation request; its evidence contracts apply.
- Shared evidence: `docs/FLUVI_ENGINEERING_JOURNAL.md`, including 2026-10-04 Header attempt, 2026-10-05 monthly variants, refinement and rejected-result review; `MILESTONE_COMMITS.md`; `docs/superpowers/plans/2026-10-05-balance-month-surface-refinement.md`.
- Available normal APK: `/storage/emulated/0/Download/fluvi/fluvi_HUMAN_DIAGNOSTIC_f34d6af.apk`; independent local SHA-256 equals release digest `780e0544c866600154aac688c7e9edeae2fc594a1d921402ca4631b8e6cc3d2d`, size 93543367. Installed historical APK remains UNKNOWN.
- `adb devices -l`: no device. No on-device backend or installed-source claim.
- CI 37251032162 independently read: Flutter/core/Human APK PASS; overall FAIL, dashboard profile FAIL. This does not authorize a Mind repair.
- Drive discovery: `Fluvi` + modified after `2026-10-04T00:00:00` returned no results. Broader search found only September documents (latest log: `Fluvi alllogs`, 2026-09-20). No current wave session was found. No current retained sequence, frozen runtime log or backend evidence exists; old sessions are not substituted.
- Initial graph: tooling `1782078bd90c8457d3ee5a727f5f02f431d0104f` indexes `0b82b8c78b438b91e49e93eb3f397c4c78caf61a`: STALE. Generate/query exact source before production changes.

## Acceptance inventory

Sources below refer to the user's full evidence-gated handoff unless stated otherwise.
Statuses are implementation/evidence status, never physical acceptance.

| ID | Source instruction/reference | Intended code/evidence area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| WR-01 | Latest branch instruction + preflight | Git/worktree | `3d-linechart` from verified base; preserve both untracked failures directories; no reset/rebase | Git ref/status/diff inventory | DONE |
| WR-02 | Hard preflight, commit/agent audit | Source/tests/history/journal | Audit relevant bodies, actual diffs, complete affected source/tests, prior claims and milestone; disclose absent reports | Source inventory and final report | DONE |
| WR-03 | Physical source of truth | Reference captures/crops | Open correct desired/rejected scenes, preserve originals, record discovered paths/hashes and missing original-byte identity | Opened images, hash manifest | DONE |
| WR-04 | Physical build/Drive audit | Audit report | Separate released, installed, source identities; discover current logs, fully audit any found; disclose absences | ADB, Drive search, release/hash, CI | DONE |
| WR-05 | Matching graph/impact | Tooling graph | Exact investigated-source manifest; definitions, families, direct prod/test refs and impact verified in current source | SCIP generation + queries | DONE |
| WR-06 | Forensic gate | Actual monthly surface test | Complete-calendar deterministic production-parent reproduction; identify first failing boundary | Baseline render, same-x red test, pixel probes | DONE |
| WR-07 | Body diagnostics | Chart + existing diagnostic sink | Opt-in bounded bounds/baseline/ridge/foot/fill/style/route/load/identity facts; default UI unchanged | Diagnostic fixture, route evidence | DONE |
| WR-08 | Geometry contract | Terrain | Separate zero baseline and clip bottom; positive same-x depth on all nonempty samples, calmer broader foot | 28/29/30/31 days, sparse/zero/edge/narrow tests | DONE |
| WR-09 | Financial truth | Existing adapter/projection + terrain | Linear exact amount/date projection, no invented days/peaks; exact highest/selected datum and tooltip | Producer and projection tests | DONE |
| WR-10 | Material reference | Shared material + Canvas/shader | Rounded substantially colored body; normals vary in both spatial directions; upper-left light, restrained highlight, lower fade | Opened body/no-glow/no-contour renders and pixels | DONE |
| WR-11 | Depth composition | Chart decoration | 3–4 recognizable overlapping lower-landscape surfaces, independent peaks; no financial markers | Opened reference-shaped/sparse renders | DONE |
| WR-12 | Renderer correctness | Canvas/shader | Verify vertex blend, actual shader load AND paint, coordinate/precision/edge alignment; genuine same-data fallback | Minimal pixel probe, route/pixel tests | DONE |
| WR-13 | Async identity | Chart resource owner | Texture only shades its own geometry; cold/warm A→B→C, stale completion, zero/style/disposal safe | Retained-state delayed-completion tests | DONE |
| WR-14 | Real cache/performance | Production cache/lifecycle | Selection does not regenerate terrain/lookup; size/data invalidate; resources bounded/disposed | Real instance counters and timings | DONE |
| WR-15 | Bounds/gestures | Chart + actual parent | Marker/bubble contained at edges, production scale measured, decoration non-intercepting, parent gestures preserved | Same retained instance widget tests + bounds | DONE |
| WR-16 | False-green removal | Chart/card/boundary tests | Replace 5-point, mismatched-x, fake-cache and callback-only claims; verify Canvas labels through painter evidence | Tests audited and strengthened | DONE |
| WR-17 | Scope lock/architecture | Chart boundary suite | Original Current/Header/settings/Savings/bar/Mind/Budget/financial owners protected; one geometry/material policy | Source hashes/diff + boundary/regression tests | DONE |
| WR-18 | Visual loop | Render evidence | Render OPEN compare label dataset/source/route/dimensions; reference-shaped + sparse actual parent + body/no-glow/no-contour + zero/edges/narrow + fallback/shader | Evidence manifest and per-iteration observations | DONE |
| WR-19 | Performance gate | Production parent/runtime diagnostics | Count generation/publications/paint, resource duration/latency; report FrameTiming availability honestly; no FPS from counters | Measured reports, bounded diagnostics | DONE |
| WR-20 | Verification | Focused + curated + boundary gates | Exact PASS/FAIL/NOT RUN commands; classify baseline Mind failure; no build substituted for visual requirements | Saved command outcomes | DONE |
| WR-21 | Commit/journal | Git + engineering journal | Atomic application commits with full required body; journal after each app commit in separate skip-ci commit | SHA/parent/diff audit | NOT DONE |
| WR-22 | Build delivery | GitHub Human APK | Push final source, monitor exact run, download normal main.dart APK; verify size/hash/embedded SHA | Release, ZIP, payload identity | NOT DONE |
| WR-23 | Graph regeneration | Separate tooling branch | Final application source graph, deterministic manifest/index hash and tooling commit | Final generation/query/hash/remote | NOT DONE |
| WR-24 | Completion | Report/checklist/final git | Honest full evidence report and all outstanding requirements disclosed | Final checklist reread | NOT DONE |
| WR-25 | Physical acceptance | User only | Exact APK physically accepted by user | User Android test | BLOCKED |
| WR-26 | Newer global mandatory reuse rule; WR-08 rounded peaks | Neutral bounded-curve helper + existing Mind adapter + monthly sampler | Reuse existing monotone-control mechanism without duplicating it; preserve Mind constructor/output/behaviour exactly | b0e503ee matching impact graph, frozen Mind control fixture, monthly clipped-peak red test, Mind regressions | DONE |

## Inline implementation sequence

1. Finish evidence inventory and matching graph, then capture production-parent
   baseline and isolated same-x geometry / vertex-color probes without changing
   the production recipe. Record each hypothesis independently.
2. Add opt-in diagnostics using existing logging infrastructure and controlled
   render fixtures; record load/route/resource identity and real parent bounds.
3. Add and observe corresponding red tests, repair the first proven geometry or
   binding boundary, run focused tests, commit that validated unit and append a
   journal-only record. Do not push intermediate production commits: the user
   requested one final all-inclusive APK.
4. Establish the broad opaque body, then form lighting and overlapping decorative
   depth in the same renderer; inspect actual Flutter output between changes.
   Three.js is conditional on a demonstrated remaining native renderer limitation.
5. Verify real sparse and reference-shaped inputs, ablations, async/selection/cache
   behavior and protected regressions. Measure available timings without claiming
   physical-device performance from software test rasterization.
6. Commit final app unit, append journal, push exact app source and run existing
   Human APK workflow. Deliver exact normal APK to `/storage/emulated/0/Download/fluvi`.
   Regenerate graph for final application SHA on separate tooling branch and
   complete evidence report. Physical validation remains PENDING — USER ONLY.

## Current evidence classification

PROVEN: visible result rejected; correct local reference opened; baseline/source
clips zero-day feet above their ridge; only one preset requests surface shader;
calendar producer includes all days; old cache test is a duplicate test-only
implementation; local APK matches available release; graph initially stale.

UNPROVEN: photographed renderer/APK/backend; dominant contribution of blending,
async stale resources, parent scale or shader behavior to that photograph;
necessity of a new engine; device frame performance.

MISSING: historical installed identity and wave session trace; original 690x1536
image bytes; independent previous completion-report file; fresh parent rendering,
matching impact graph, actual route evidence and device timing (pending work).

## Unit 1 gate update

The exact f34d6af graph was generated and queried (see evidence README and query
log). Production-parent and opaque-body renders were generated AND opened.
Four complete-calendar same-x tests failed before repair, minimum depth -1.2 px;
after separating the financial baseline from clipping, all six focused tests
pass and minimum depth is 20.446 px. Vertex-color probe rejected mandatory blend
replacement on the measured backend. Bounds measured at scale 1.0.
This isolated geometry repair is NOT a completed visual package: foot silhouette,
lighting, async binding, shader route, final regressions/build remain pending.
Unrelated concurrent FAB/Header working changes are preserved and excluded from
chart commits. The historical installed APK/backend remains UNKNOWN.

## Shared mechanism gate for the observed clipped peaks

The new isolated-peak red test fails on day 5: a neighbouring sample equals
the peak because Catmull-Rom is clamped after evaluation. Existing Mind Sum
already bounds cubic controls before evaluation. The newer global reuse gate
requires a neutral extraction instead of a sibling copy. Only that pure
algorithm moves; the existing Mind segment class/constructor, selection,
financial projection, gestures, rendering and defaults remain unchanged.
Use a generic segment factory so Mind gains no intermediate wrapper objects.
Matching graph: source `b0e503ee8dd5a7606dcd701b8967902950f7f4b0`, raw index
`331b3660b805cd12a87dcfa53e3cb1bda673cd3cafc71b7be4f3e7d6c3d285c4`.
Function has one production paint caller and one test caller; segment family
stays inside the Mind file. Its widget consumer in the Sum viewport and current
curve/viewport tests were opened. No Mind canonical-range profile repair is
part of this extraction. Query evidence: `graph-impact-b0e503ee.log`.
