# Wave recovery evidence

## Resumed final visual candidate (2026-10-05)

The latest user instruction explicitly authorizes completion and makes the
desired screenshot the visual authority, accepting a substantially similar
result. `material-final/` is the final software-rendered comparison set. Both
original phone captures listed in the acceptance plan were reopened; the target
crop is `reference-crop.png`. No reference image or synthetic dataset is bundled
as production chart content.

### What changed, and what did not

The identified baseline's below-zero surface collapse was repaired in the
earlier geometry unit. This completion replaces post-evaluation clamping (which
flattened isolated peaks) with bounded cubic controls. The existing Mind Sum
mechanism is extracted into `lib/core/design/fluvi_bounded_curve.dart`; its
default preserves even the original floating-point operation order. The Month
renderer uses wider handles and evaluates both x and y along the same cubic.
Exact financial endpoints, calendar days, minor units and a linear y scale are
unchanged. No smoothing of daily amounts or redistribution to adjacent dates
occurs.

The material uses an analytic rounded height field with normals varying across
and down the body, an upper-left light, lavender/periwinkle highlights and a
foreground fade. CPU vertices and the fragment route share palette/light
uniforms and the same equations. Two independent rear surfaces and a subdued
foreground surface establish depth; they carry no financial markers. The real
ridge alone owns selection, the spherical marker and its white tooltip. The
financial zero is at 70% of the plot height, above the calm material foot.

The existing chart State remains the sole local selection/resource owner; its
single-entry geometry cache is reused. The resource owner binds a texture only
to its exact terrain identity and disposes obsolete async results. No database,
query, persistence, financial projection, new controller, engine dependency,
image-based chart, global Stack or secondary state machine was introduced.
Three.js was unnecessary: both native routes demonstrably render a volume.
Material, lookup and diagnostics already have separate chart-local parts; the
remaining geometry/painter library is intentionally cohesive, not duplicated.

Protected Current/SUM/Year/Day routing, Header, Savings, lower strip, Budget and
financial production sources are unchanged by the completion diff. The only
Mind production change is the exact-output neutral curve extraction. Unrelated
concurrent FAB cyan work and pre-existing failure images remain outside wave
commits. The `6e962187` physical performance anchor is not replaced by software
timing claims.

### Visual inspection and limits

Opened final scenes include reference-shaped mesh/shader, full actual Month
parent with Savings beside it, sparse full parent, body only, no glow, no
contours, zero, first/last peaks and narrow width. The reference-shaped case is
explicitly synthetic; the sparse case is a complete 31-day stress month with
26,800,000 minor units at day 2 (268 k Ft), not the user's ledger export.

Compared with v3, abrupt dark columns, clipped peak plateaus and the solid-looking
foreground were softened. v4 established rounded lighting; v5 failed the sparse
body coverage gate; v6 resolved the curve/lighting relationship; v7's lighter
material was just below that gate. The final foreground reserve retains a
substantial body without weakening the threshold. The body remains recognizable
without contours, glow or decoration. Substantial-violet coverage of the whole
chart crop is 24.38% (reference mesh), 24.45% (reference shader), 13.87% (sparse
mesh); same-data shader/mesh mean channel difference is 0.1581/255. These are
regression measurements, not an objective similarity score or visual approval.

Assessment after opening the renders: the requested rounded lavender landscape,
dimensional shading, overlapping depth, soft foreground, pearl ridge and
spherical marker are substantially reproduced. It is not pixel-identical: the
reference has softer/wider photographic transitions; real daily distributions
and the protected production card proportions differ. A genuine isolated large
daily amount remains a narrow peak; widening it into other days would falsify
the data. No claim is made that the physical Android backend already matches.

### Verification and performance evidence

Tests observe the real retained production owners, not a test-only cache:
28/29/30/31-day exact values/dates/linear positions; positive same-x depth;
pixel-tested lookup error below 0.015 px (observed 0.000672 px); actual shader
paint identity; controlled shader-load failure with same-data fallback;
A→B→C completion reordering; zero/style/disposal cleanup; actual painted labels
and edge bounds; 30 selections in the real Dashboard host; vertical gesture
ownership; data/size invalidation and exact Mind control compatibility.

The retained async sequence requests six textures, publishes two and disposes
all six, including stale completions. Thirty real-host selections preserve one
geometry build, no texture request and the same State/terrain identity; vertical
drag invokes the existing parent's start/update/end without changing selection.
`material-final/*.json` and command logs contain measured geometry/texture and
lookup-request-to-first-shader-paint microseconds. These are debug software
raster/proot measurements, affected by compilation and concurrent analysis,
not Android frame costs. No physical `FrameTiming`, GPU, FPS, retained device
trace or current installed-build evidence is available. Physical acceptance
remains PENDING — USER ONLY, as the original delivery contract specifies.

An old native boundary test incorrectly rejected `MediaQuery` because it banned
the substring `Query`. `native-boundary-red.log` records that failure; the check
now rejects actual query-domain identifiers/imports and explicitly tests both
positive and negative matches. The production reduced-motion behavior is not
removed to satisfy a string test. Old chart/variant goldens were refreshed only
after the final actual-parent render was opened; Current's golden is unchanged.

The final command outcomes, application/journal SHA, CI/APK identity and final
tooling graph are recorded below after those delivery gates actually finish.
Historical installed identity, original 690×1536 attachment byte identity and
the absent October Drive trace remain UNKNOWN/MISSING, not retrospectively
inferred from the new identified reproduction.

Final normal-animation review exposed an additional grey background wash from
the optional third-preset Aurora overlay (the reduced-motion comparison alone
could not detect it). The installed package shader was read directly; its
low-intensity premultiplied output explains the dark veil. The existing overlay
intensity is reduced from .055 to .006, without adding a compositor, shader copy
or timer. `atmosphere-red.log` records background RGB [235,235,236] failing the
white-background gate; `final-focused.log` records [253,253,253] passing. The
normal-motion `reference-animated-shader-full-412.png` was generated and opened,
and its actual surface route/texture identity is still checked.

Inline review (user-requested execution mode): checked the completion diff
against WR-01…28, the actual source call sites, float/uniform ordering, control
compatibility, async stale-result paths, cache ownership, edge selection and
production parent gestures. No blocking code defect remains in that inspected
scope. Independent-agent review was not performed. The explicit remaining
acceptance limit is physical Android rendering/performance and user approval,
not hidden behind test/golden success.

### Local gate results before delivery

All Flutter/Dart commands ran in Ubuntu proot with the project's Flutter SDK;
no local APK build was attempted. Test assets were compiled by Flutter, then
reused via the isolated `build/` bind and `--no-pub --no-test-assets` for the
iterations. The changed fragment was explicitly compiled with the same SDK's
`impellerc`; shader tests observe actual painting, not compilation alone.

| Gate | Result | Evidence |
| --- | --- | --- |
| Core curve + both Month boundaries + recovery + visual | PASS, 20 tests after final overlay attenuation | `final-focused.log` |
| Chart/cache/style/three refreshed chart goldens | PASS, 11 tests | `final-goldens.log` |
| Four-choice monthly card visual (Current unchanged) | PASS after final attenuation | `final-card-goldens.log` |
| Scope adapter/cards/primary projection/real mode host | PASS, 48 tests | `final-protected.log` |
| Existing protected Mind interpolation | PASS, `SUM-CURVE-02` | `final-mind-controls.log` |
| SUM/Year/Month/Day production routing | PASS, `ALT2-04/06` | `final-production-routing.log` |
| Canonical `scripts/test-fluvi-fast.sh` suite | PASS, 454 tests; concurrency 2, expanded output | `final-curated.log` |
| Full analyzer | PASS, zero issues | `final-analyze.log` |
| Final changed-source/test analyzer | PASS, zero issues | `final-scoped-analyze.log` |
| `bash scripts/verify-fluvi-boundaries.sh` | PASS | Terminal output: Flutter/core boundaries verified |
| Whitespace and final evidence/source hashes | PASS | `git diff --check`; `final-sha256.txt` |

The local curated/full-analyzer invocations began before the last overlay-only
intensity adjustment; the final focused, animated-pixel, card-golden and scoped
analyzer gates ran after it. Exact committed-source full CI is a separate
delivery gate, not inferred from that earlier broad invocation. Existing host
tests emit a hit-test warning in an unchanged header gesture case but pass;
the new wave/vertical ownership test hits the actual chart and asserts results.
No native Android test or physical FrameTiming run is claimed locally.

Final PNG/JSON sidecars record precommit HEAD `0b5982ff` plus a dirty-production
flag because this work and unrelated FAB WIP were present. Each records hashes
of the actual chart/material/lookup/probe/curve/shader source; `final-sha256.txt`
pins all final artifacts and source files. The final application commit is
identified in the subsequent journal/delivery record; unrelated WIP is not
silently represented as committed application content.

Application investigation source: `f34d6afb6ee7475864f36075395c505126b37758`.
Development base: `75e4e158f340ae1d2da9493fb5c53b4361f80057` (documentation only
after f34d6af). Branch: `3d-linechart`.

`baseline/` and subsequent iterations are generated by the current Flutter
test rasterizer with the explicitly labelled synthetic complete-calendar
datasets in `test/support/fluvi_wave_fixture.dart`. They are not physical
Android screenshots. JSON sidecars record source HEAD, production-diff state,
dimensions, route and parent geometry. Hash manifests accompany accepted
evidence milestones. Original phone files are preserved at their paths in
the acceptance plan; comparison crops exclude gallery controls.

Runtime device evidence: no ADB device and no current October wave Drive log
found during preflight. Historical installed APK/source/backend remains UNKNOWN.
No source-level reproduction retrospectively identifies that APK.

The available f34d6af Human APK independently matches the published digest.
The prior overall CI run failed in dashboard profile (Mind canonical range),
while normal Flutter/core/Human APK jobs passed.

## Forensic boundary established before recipe changes

`baseline-red.log`: four 28/29/30/31-calendar-day tests FAIL at the same-x
depth invariant (-0.823880597 px at a 1000 Ft day). Production parent at
412x892: chart 240.051x128.250 logical pixels; origin (27.774,308.749), identity
scale (no FittedBox reduction); zero-day minimum -1.2 px. Baseline mesh render
and `diagnostic-before/production-opaque-bounds.png` were generated AND opened.
The opaque, contour/glow/atmosphere-free body still collapses at the baseline.
Thus the first failing boundary of this identified reproduction is CPU geometry.
This is not retrospective proof of the historical installed APK.

Independent pixel probe: `srcOver` AND `dst` produce [150,130,242,255] with
the default unshaded Paint on this Flutter software backend. Rejected hypothesis:
the default Paint necessarily obliterates vertex colours. No speculative blend
change is justified by this experiment.

The exact f34d6af graph was regenerated, manifest source=f34d6afb..., raw SCIP
SHA-256=5157c2f43ab45a6f0493186984480e2b37b24be785b8d0ca82420e322c1aeb18.
`graph-impact-f34d6af.log` contains class/constructor-family queries. Chart has
one external production constructor (monthly card); Terrain is chart-local.
Card's sole production caller is monthly core surface. Selector also reaches
preferences persistence and tuner; those owners are not changed. Relations were
opened in current source, including upstream complete-calendar projection and
minor-unit formatter. The existing tooling branch graph is independently stale;
the fresh investigation graph is at `/data/data/com.termux/files/usr/tmp/fluvi-wave-graph-f34d6af`.

Concurrent unrelated FAB/Header files became dirty during baseline collection.
Sidecars explicitly say production diff nonempty; the original chart, shader,
card, surface and financial adapter were still byte-identical to f34d6af before
instrumentation. These unrelated files are preserved, not staged in chart commits.

Test audit: the earlier 5-point sparse test compares two different x positions;
the fake cache is not production; selected callback range is not marker bounds;
shader compilation is not a paint-route observation; Canvas text is not a Text
widget; line counts/widget counts are structural only. No separate independently
verified previous completion report was discovered. Prior journal/checklist DONE
rows do not establish visual acceptance.
