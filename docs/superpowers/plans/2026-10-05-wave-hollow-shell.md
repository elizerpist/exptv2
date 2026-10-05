# Oblique hollow spending shell implementation plan

> For agentic workers: use `executing-plans` inline. These tasks share geometry,
> material, render evidence and resource state; delegation would add coupling.

Goal: implement the user's corrected, chart-only hollow oblique shell contract,
not the rejected frontal curtain or independent landscape requirement.

Architecture: retain the existing chart State, selection and one-entry cache.
The terrain is the only geometry authority. A chart-local parametric shell
maps (financial-curve position, visual depth) into projected surface vertices;
the same vertices and surface normals feed the fallback and shader lookup.
No financial, persistence, Header, gesture or surrounding-card owner changes.

Tech stack: existing Flutter Canvas/Vertices, FragmentProgram, Flutter tests in
Ubuntu proot. No new package, web renderer, bundled chart bitmap or production
synthetic data. Normal APK builds run only on GitHub.

## Execution checkpoint: concurrent branch movement

While this task was running, another session committed and pushed
`c85cbde62b6bec4ea8ec5f3999ce21db2b739d7f` (Budget analysis and FAB changes), then
`829588c972a7064cf1c15048e9249958ea5a6d59` (Budget test warning), onto the SAME
`3d-linechart` branch in this worktree. This task did not stage, commit, push or
remove that work. The user subsequently explicitly authorized continuing
`829588c972a7` on this same 3D branch. Budget/FAB are preserved as committed base.
HEAD `8a1f3ea51d803ad332d8dd9e4ac58d27f411b9d6` adds documentation only above
that application source. No reset, rebase or replacement application worktree.

At the first checkpoint, atmosphere generation and Aurora were removed and
12 focused boundary/widget tests passed; both new geometry contracts were RED.
At that checkpoint the projected-shell implementation was uncommitted alongside
its shared material, projected-attribute atlas and correctness/visual tests.
Iteration-10 passed 20 shell/recovery/production-parent visual checks. It meets
the structural shell contract, but the side-by-side reference comparison still
shows excessive lower scalloping. Iterations 11/12 reduce that foreground
prominence while retaining the full returned mountain. No final APK exists yet.
The early inferred half-height assertion for EVERY intermediate section was
over-specific: the reference's foreground turn is low and broad. Half-height
is now checked on the returned mountain; the intermediate turn still must
retain ordered, distinguishable peaks (> one logical pixel), actual right/down
continuation, curved normals and bounded geometry. This is not permission to
accept a flat floor or to judge completion from tests instead of opened images.
The tooling worktree graph was regenerated from a clean exact 829588c source;
raw index SHA-256 `6d850ede58284220be6deb0da8ff81c2eb1e37d8fd481c449722fbdc3e7ff45c`.
Chart and terrain graph queries again identify only `_DailySpendChart` as the
external production construction site, verified in source. The removed
atmosphere unit is committed locally as 50e34a51 (12 fresh tests PASS); no push
or APK build yet. Final graph will follow the completed application SHA.

## Final delivery checkpoint

Application `c3e62bb0835456601d7c6036715b31bb5cec4fd2` is pushed on
`3d-linechart`; its normal Human APK is downloaded to the requested Android
folder and size/hash/three-ABI source identity are verified. Core, Flutter and
Human jobs PASS in run 37314421778; the independent profile job remains in
progress at the evidence snapshot, not claimed green. Tooling graph
`0c8a188b2bf0ee28e82daff76beaadde27798cd4` is pushed, matching the exact source.
Journal and all evidence are a separate `[skip ci]` documentation unit.
Physical validation remains PENDING, USER ONLY; visual similarity is the
implementer's/reviewer's assessment, not user acceptance.

## Frozen pre-delivery implementation checkpoint

Iteration-12 is the final visual candidate. Full/body-only/shader/fallback,
sparse, zero, first/last and narrow renders were opened; independent read-only
review found no material/source-safety blocker for the close form contract.
Remaining stronger diagonal segmentation and less diffuse foreground are
explicitly disclosed, not called pixel equality or user acceptance. The 85
chart/protected tests PASS. The full fast suite PASS (462), analyzer PASS
(0 issues), boundaries PASS and staged diff check PASS. APK/final
graph delivery remain NOT DONE until their exact artifacts are verified.
`adb devices -l` returned no attached device. See the evidence README for
source hashes, reviewed images and exact validation outcomes.

## Sources and preflight (initial chronology)

- Latest user clarification authorizes the Android Screenshots directory as
  the physical reference source. Both full images and matching media-ID
  thumbnails were opened. The downloaded 690x1536 attachment bytes are not
  present; their hashes are not attributed to the larger local files.
- RECEIVED: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261005-113934.png`,
  1084x2412, SHA-256 `ecf8b60e4abc39e8080687807dce319049b2fbe481f00f99ff069a66c705bbd9`.
  Corresponding media thumbnail: `.thumbnails/1000125283.jpg`.
- EXPECTED: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261005-021521.png`,
  1084x2412, SHA-256 `58626ddb0bccb9c09ffd49a1b7015b60be6fb541e9bc7d8d6ebaf74ae65dac77`.
  Corresponding media thumbnail: `.thumbnails/1000125266.jpg`.
- Handoff attachment hashes, retained as separate identities:
  `1000125283.png`: `d96963d741f430bd12324fd10c4ec684ea40c5965229dc58db41167b67a2fc68`;
  `1000125266.png`: `fe12efe695a5c6bd67673982be9309eb8ce3a14634dae672130018324a4c2211`.
- Compare ONLY the purple spending chart. Ignore gallery controls, other cards,
  the unrelated Mind image and the illustrative amounts/peak positions.
- Existing worktree `fluvi-balance-wave-defaults`, branch `3d-linechart`.
  Initial HEAD `91f8006729d613fc5eb01d3f520ca6046a2c28c3`; parent
  `3c7157a3b2b9c7fbca23b2298de60564c00107fa`. Fetched remote
  `e887b5912a7a3db509c438b5fad119d27a3fbe62` adds only journal entries;
  fast-forwarded without changing production source or unrelated WIP.
- At the initial preflight application source was `6df3abe533964507638a48c4743e733cd22bbc52`,
  application parent `0b5982ffaaaf6d209c2d2d101e6f788c8ada464c`.
  Hard preflight commands ran. Index was empty; local FAB/Budget files and
  untracked evidence/failures existed and must remain unstaged/unmodified.
- Graph `tooling/3d-linechart-final-graph` at `73f239be15ed5982c21ba926b99deb41c5106cd0`
  indexes exactly 6df3abe, raw index hash
  `8c406b642bf62af6d53f6ff25fc7b6cca9e41eaa801f71d6e6244e0a307482cd`.
  It describes committed application source, not unrelated local Budget WIP.
- Prior delivery's WR-08 same-x depth, WR-11/27 independent landscapes, zero
  scenery, Aurora and visual-completion claims are SUPERSEDED by this request.
- CI 37288361696: core, Flutter, dashboard paths and Human APK PASS; profile
  FAIL at `_profileMindYearHeatmapSlider.dragThumb`, line 1701, live canonical
  range equality before pointer release. Current job log inspected; no fresh
  baseline reproduction or causal classification as wave-related/inherited.
- Installed screenshot APK, physical renderer and fresh device FrameTiming
  remain MISSING. Published APK identity does not establish installation.

## Architecture card

Financial source: existing projection -> monthly presentation -> `_DailySpendChart`
-> immutable day/minor-unit values. No write path to financial data is introduced.

| State/mechanism | Sole owner | Decision and verification |
| --- | --- | --- |
| True ridge/calendar/linear scale | existing terrain from immutable values | keep exact bounded helper and Mind unchanged; calendar tests |
| Projected outer/inner surface | chart-local shell geometry | one parametric surface, normals from its tangents; geometry and opened renders |
| Selection | existing chart State | preserve callback/tap semantics; exact datum/edge tests |
| Geometry cache | existing one-entry cache | data/size invalidation only; 30 selections preserve identity |
| Shader/lookup lifecycle | existing chart State | terrain-identity publication, stale disposal, cold fallback; A-B-C tests |
| Material/palette | existing material/palette | CPU/GPU share constants and normals; rendered route comparison |
| Vertical gestures | existing DashboardCoreModeHost | chart adds no recognizer; production-parent drag test |

The current >800-line chart mixes UI/lifecycle with a large geometry renderer.
Extract the chart-local parametric shell into its own focused part if necessary;
do not create another cache, selection owner or shared interpolation algorithm.
The remaining library is presentation-only, with no I/O/domain workflow.

Rejected approaches: stronger lighting on the same-x curtain cannot satisfy
projection; uniformly translated curve copies cannot establish a curved shell.
Chosen approach: continuous right/down projected depth with a rounded turn and
lighter inner return. Internal safe padding reserves depth at the last day;
the parent allocation and exact uniformly spaced financial plot remain stable.

## Acceptance checklist

| ID | Source | Code/evidence area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| HS-01 | Hard preflight/latest clarification | Git/references | existing 3D branch, reviewed local images, unrelated work preserved | ref/status/diff/hash/opened images | DONE |
| HS-02 | Audit/graph | graph and current source | matching source families/direct consumers verified | 6df3 and 829588c matching graphs queried and source verified; final graph is HS-16 | DONE |
| HS-03 | Baseline/failing contract | visual/recovery/boundary tests | before images through actual Month parent, child chrome on; meaningful red contract | run/open baseline and red logs | DONE |
| HS-04 | Form/perspective | terrain/shell | one curved open surface; corresponding features visibly right/down, nonrigid depth, inner return | geometry landmarks + opened no-detail render | DONE |
| HS-05 | No atmosphere | chart/terrain | no independent profiles/Aurora/ticker or zero scenery | boundary/widget PASS; empty zero render opened | DONE |
| HS-06 | Light material | material/shader | thin pearl rim, lavender turn, pale recessed return, gentle nonrectangular termination | reference-sized crops and ablations | DONE |
| HS-07 | All routes | shader/lookup/fallback | projected-shell parameterization shared; no same-screen-x depth reconstruction | actual routes, lookup and raster comparison | DONE |
| HS-08 | Exact data | preserved producer/terrain | exact 28/29/30/31 days, minor units, real zeros, bounded interpolation | financial/calendar tests | DONE |
| HS-09 | Bounds/selection | chart/parent | exact selected datum and contained edges; last-day depth safe; narrow card | edge tests/renders | DONE |
| HS-10 | Cache/async | existing State/cache | no selection regeneration; size/data invalidate; stale/disposal safe | retained owner tests | DONE |
| HS-11 | Scope/gestures | protected sources/parent | unchanged Header/Current/cards/Savings/bar/Mind/Budget/FAB and vertical gestures | scoped diff, boundary/protected tests | DONE |
| HS-12 | Visual review | evidence | opened before/after parent, expected comparison, reference/sparse/zero/edge/narrow/shader/fallback/no-detail | PNG + route/source sidecars + written observations | DONE |
| HS-13 | Performance | diagnostics | bounded cached geometry/resources; no animation/debounce/stale data | counters and publication/paint evidence; no physical FPS claim | DONE |
| HS-14 | Validation | tests/analyzer/scripts | exact commands/outcomes recorded; no green-by-golden-only claim | focused/protected/fast/boundary/analyzer logs | DONE |
| HS-15 | Delivery | Git/CI/APK | atomic app commits; exact-source normal Human APK downloaded/hash/embedded SHA | exact SHA/run/release/local verification | DONE |
| HS-16 | Journal/graph | documentation/tooling branch | separate skip-ci journal, final-source graph queried, no docs build | commits/manifests/remote checks | DONE |
| HS-17 | Evidence limits | final report | physical validation pending user only; no acceptance/device-cause claim | explicit final limitations | DONE |

## Verified increments

1. Baseline and red contract. Change visual-test settings to `usesChildCards:
   true`, keeping all existing datasets. Run the production-parent visual test
   with `FLUVI_WAVE_EVIDENCE=docs/superpowers/evidence/2026-10-05-wave-hollow-shell/before`.
   Open reference and sparse parent/crops. Add red assertions `foot.dx > ridge.dx`,
   no atmosphere/Aurora and exact data preservation. New detailed shell tests
   inspect projected vertices/normals and non-affine depth, not arbitrary colour
   coverage or a refreshed golden.
2. Remove chart atmosphere and its generation work. Retain the persisted style
   identifier. Run zero and boundary checks; commit this validated coherent unit.
3. Replace same-x surface construction with one parametric projected shell;
   adapt contours to the same samples. Reserve safe right/down chart-local
   space, no parent resize. Feed computed normals/depth to both materials.
4. Adapt the shader lookup to the actual projected surface attributes. Do not
   infer depth between two same-x Y boundaries. Preserve async terrain guards
   and exact-data mesh fallback. Verify actual shader paint, stale completion
   and resources before visual tuning.
5. Open actual parent and chart crops against expected at uniform scale.
   Inspect geometry without contours/glow, synthetic reference/sparse, zero,
   edge and narrow cases. Iterate projection before material if still frontal.
6. Run correctness and protected gates, update all checklist statuses honestly,
   commit app with Why/Evidence/Changed/Validation/Known limitations/Physical
   validation. Push final app source and monitor/download its normal Human APK.
7. Record journal separately with `[skip ci]`, regenerate/query final-source
   graph on tooling branch, verify no docs-only build; report identities and
   PHYSICAL VALIDATION — PENDING, USER ONLY.

## Commands

All Flutter commands run inside Ubuntu proot, SDK `/home/flutteruser/flutter/bin`.
Reuse the isolated build directory `fluvi-wave-build.pcugrC`, bound to this
worktree's build, while rendering; never run concurrent compilers there.

```sh
flutter test --no-pub --no-test-assets test/features/dashboard/presentation/fluvi_wave_visual_test.dart --concurrency=1 --reporter expanded --dart-define=FLUVI_WAVE_EVIDENCE=docs/superpowers/evidence/2026-10-05-wave-hollow-shell/before
flutter test --no-pub test/features/dashboard/presentation/fluvi_wave_recovery_test.dart test/features/dashboard/presentation/fluvi_topographic_wave_chart_test.dart test/boundary/balance_monthly_topographic_chart_boundary_test.dart --concurrency=1 --reporter expanded
flutter analyze --no-pub
bash scripts/test-fluvi-fast.sh
bash scripts/verify-fluvi-boundaries.sh
git diff --check
```

Expected baseline: prior renderer renders (not visual acceptance). Expected red:
same-x displacement and present atmosphere violate HS-04/05. Expected final:
all required checks pass; physical evidence remains explicitly unavailable.
