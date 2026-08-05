# Dashboard motion/data isolation refactor – final evidence report

Date: 2026-08-05

Branch: `refactor/dashboard-complete-motion-data-isolation`

Baseline implementation: `16072f0ef633c27fca8f7aeea0c3d0c7305badc4`

Safety milestone: `bb6c294257b94859a902d445113ab3f739db0783`

Final implementation/evidence commit:
`f364bacb79cd24314dc1491474d80cfc4a18df07`

## 1. Exact root cause

The old carousel target calculation itself was deterministic and did not read
ledger data. The failure started immediately after a semantic crossing. A
scroll listener synchronously forwarded the child index into the dashboard
navigation notifier, then into QueryKey construction, bundle lookup,
presentation-store publication, amount/count formatting, LogBox selection or
projection and broad widget notification. Cold structural targets could extend
the same causal chain into repository and native work.

The native “bundle” API was one platform round-trip but not one parent batch:
it executed an aggregate query and then `queryTimelinePage` once per child.
Month→day could therefore execute 30–31 child page queries and year→month 12.
The nested `StandardMessageCodec` payload was then decoded and projected into
short-lived Dart maps, lists, ledger rows and LogBox view models on the UI
isolate.

Consequently populated and cold targets consumed the same UI-isolate time that
had to deliver the next scroll and animation frames. Lost scroll ticks changed
the observed semantic sequence and apparent fling distance even though item
extent, friction, velocity scaling and snap rules were unchanged. Warm caches
only shortened this shared path, so they reduced the probability rather than
fixing ownership.

The concrete pre-refactor graph and every listener/rebuild boundary are in
`docs/dashboard/dashboard-motion-data-root-cause.md`.

## 2. Removed constructions that caused data-dependent motion

The refactor removed the mixed-ownership path rather than wrapping it. The
main causes were:

- `DashboardCoreController` forwarding transient rail, query, summary, store,
  LogBox and background notifications through one aggregate graph;
- `DashboardSummaryMetricsController` owning child lookup, preparation,
  formatting and visual publication at the same time;
- `DashboardPresentationStore` carrying both raw query entries and visible
  presentation lanes;
- `DashboardLogPresentationAdapter` listening to visual and metadata lanes and
  reprojecting or rebinding on preview/settle transitions;
- `CurrentQueryController` and `DashboardLiveQueryLeaseCoordinator` allowing
  preview/settle/navigation paths to share repository/live-query ownership;
- parent bundle/cache coordinators that made warm data a practical motion
  prerequisite;
- an N-child native query implementation hidden behind one method-channel
  invocation;
- a UI-isolate nested codec decode and whole-deck LogBox projection;
- settle-time presentation publication, timer-based live quiescence and
  duplicated visual notifiers;
- QueryKey/child data-source recreation and broad widget rebuild boundaries.

## 3. Canonical replacement architecture

Exactly four runtime owners remain:

1. **Motion Kernel** – gesture, offset, ballistic activity, semantic index,
   snap and settle only.
2. **Prepared Data Pipeline** – immutable semantic catalogs and complete
   prepared parent/child frames, including the first LogBox page.
3. **Visible Presentation Frame** – one atomic immutable amount/count/LogBox
   snapshot selected from a prepared deck.
4. **Committed Live Query** – the sole owner of the committed watch/read/page
   lifecycle after settle.

`DashboardNavigationState` is a fifth, structural value owner for plane,
parent, direction, rail-open and retained child identity. It neither owns
motion nor visible values.

The public snapshots are immutable. No all-purpose `ChangeNotifier` contains
motion and data presentation together.

## 4. Rewritten and added production areas

The milestone-to-final diff changes 165 files with 14,416 insertions and
19,380 deletions. The principal canonical files are:

- motion: `dashboard_motion_kernel.dart`, `dashboard_motion_state.dart`,
  `dashboard_semantic_catalog.dart`, `dashboard_display_frame_coalescer.dart`;
- prepared data: `dashboard_prepared_deck.dart`,
  `dashboard_prepared_deck_pipeline.dart`, `dashboard_prepared_deck_cache.dart`,
  `dashboard_prepared_binary_codec.dart`, `dashboard_prepared_formatter.dart`,
  `method_channel_dashboard_prepared_repository.dart`;
- visible/committed state: `dashboard_visible_frame.dart`,
  `dashboard_visible_frame_store.dart`,
  `dashboard_committed_query_controller.dart`;
- orchestration/navigation: `dashboard_core_controller.dart`,
  `dashboard_time_navigation_controller.dart`,
  `dashboard_time_navigation_state.dart`;
- UI isolation: `core_dashboard.dart`, `dashboard_summary_pill.dart`,
  `dashboard_logbox_viewport.dart`, `dashboard_logbox_header.dart`,
  `time_refinement_rail.dart`, `transaction_direction_toggle.dart`;
- shared stable carousel: `centered_carousel.dart`,
  `centered_carousel_controller.dart`, `centered_carousel_physics.dart`;
- Android/native: `FluviLedgerReadService.kt`,
  `FluviPreparedDeckModels.kt`, `DashboardBinaryCodec.kt`,
  `DashboardQueryArguments.kt`, `MainActivity.kt`;
- diagnostics: `dashboard_interaction_diagnostics.dart`,
  `dashboard_performance_counters.dart`,
  `dashboard_render_phase_probe.dart`;
- startup: `dashboard_bootstrap_controller.dart`, which now exposes an
  explicit retryable failure instead of an endless initialization screen.

## 5. Deleted production paths

The following old production sources were deleted; there is no feature flag,
fallback or parallel source of truth:

- `dashboard_adjacent_parent_prewarm_coordinator.dart`
- `dashboard_background_work_coordinator.dart`
- `dashboard_parent_bundle_registry.dart`
- `dashboard_rail_controller.dart`
- `dashboard_rail_motion_coordinator.dart`
- `dashboard_summary_amount_controller.dart`
- `dashboard_log_paging_coordinator.dart`
- `dashboard_log_performance_diagnostics.dart`
- `dashboard_log_presentation_adapter.dart`
- `current_query_controller.dart`
- `dashboard_live_query_lease_coordinator.dart`
- `dashboard_motion_trace.dart`
- `dashboard_parent_display_bundle.dart`
- `dashboard_presentation_diagnostics.dart`
- `dashboard_presentation_store.dart`
- `dashboard_query_debug.dart`
- `dashboard_batch_metrics.dart`
- `dashboard_child_preview_bundle.dart`
- `dashboard_child_preview_repository.dart`
- `dashboard_child_summary_repository.dart`
- `dashboard_ledger_repository.dart`
- `dashboard_stress_fixture.dart`
- `method_channel_dashboard_ledger_repository.dart`
- `dashboard_visible_presentation_target.dart`
- `scope_summary_metrics.dart`
- `time_child_summary.dart`
- `summary_metrics_presentation.dart`
- `summary_pill_presenter.dart`
- `summary_pill_view_model.dart`
- `time_rail_data_source_factory.dart`

The obsolete profile fixture repository and tests coupled to those deleted
owners were removed as well. No golden test was added or regenerated; obsolete
dashboard golden tests were deleted from this branch.

## 6. Motion hot path

The only semantic-crossing path is:

```text
ScrollPosition
  → DashboardMotionKernel logical index
  → immutable DashboardSemanticCatalog[index]       O(1)
  → active DashboardPreparedDeck.frames[queryKey]   O(1)
  → DashboardDisplayFrameCoalescer latest target
  → one localized DashboardVisibleFrame publication
```

There is no `async`, repository, platform channel, live lease, SQL, parse,
formatting, grouping, sorting, LogBox projection or per-pixel diagnostic in
this path. Multiple crossings in one display frame replace the pending target;
there is no queue or delayed replay. Crossings on different display frames are
published independently.

The carousel controller, Flutter `ScrollController`, application physics and
attached `ScrollPosition` identities are retained across child, parent, plane,
direction, rail-open and visible-frame changes. No physical constant or product
animation duration was changed.

## 7. Prepared deck pipeline and transport

A preparation request is keyed by direction, exact parent QueryKey, filters,
refinements, child kind, core revision, page size, model version and semantic
window identity. The central in-flight registry deduplicates equal work.

Android executes the parent batch on its IO dispatcher. Every parent deck uses
a constant six SQL calls: parent aggregate, child aggregates, bounded parent
page, bounded child first pages, category lookup and partner lookup. Month→day
does not issue 30–31 child calls; year→month does not issue 12. SUM→year uses
an explicit bounded year window.

Kotlin maps the bounded rows into a compact versioned binary DTO. Dart receives
`Uint8List`, transfers decode/projection to a worker isolate and publishes only
the complete immutable `DashboardPreparedDeck`. Each
`DashboardPreparedFrame` already includes formatted amount, count, empty/error
state, stable row/group/asset identities and the lazy LogBox viewport's first
page plus cursor. Motion never performs projection.

## 8. Parent navigation while the rail is open

Navigation first updates structural intent and starts its visual motion. The
Motion Kernel and carousel identity are retained. The semantic child mapping is
deterministic: the same day is retained when valid, otherwise clamped to the
new month's last day; year parents retain month; SUM retains the explicit year
selection rule.

For a warm target, the new parent child frame is selected atomically from the
deck within one display frame. For a cold target, the old frame remains wholly
consistent while preparation runs; no mixed parent/child, dash or partial
placeholder is published. Only the complete latest target deck can replace it.
Rapid A→B→C navigation rejects A/B completions by generation and epoch.

## 9. Committed live-query ownership

Semantic crossings are previews and never query owners. Settle promotes the
already visible frame to committed metadata without publishing pixels,
rebinding LogBox, restarting amount animation, resetting the viewport or
creating controllers. It then swaps the single committed live lease.

Live results are accepted only when committed QueryKey, direction, filters,
refinements, core revision, committed generation and presentation epoch all
match. A stale callback increments the rejection counter and cannot update
visible or motion state.

The visible-frame store is the single owner of the monotonically increasing
frame generation. Preview and committed-live publication both allocate from
that sequence. The first final profile run exposed the prior split sequence:
a live frame could make the next preview look stale. The regression
`live frame generation cannot make the next semantic preview stale` reproduces
that collision; commit `f364bacb` removes both local counters and makes the
store allocator canonical.

## 10. Cache, revision and seed correctness

The cache stores only complete immutable decks in a bounded O(1) LRU. Its
residency policy covers active, adjacent and required opposite-direction
targets without changing correctness. Cache warmth is not required for motion.

The exact deck key includes every data-distinguishing field. A revision change
invalidates lookup and in-flight completion. Revision zero is rejected before
cache insertion and before visible publication, so a pre-seed empty deck cannot
overwrite or become visible after revision one.

## 11. UI rebuild and paint boundaries

Stable isolated subtrees now own:

- SummaryPill shell motion;
- rail motion;
- amount presentation;
- count presentation;
- LogBox viewport;
- direction SVG pulse;
- header.

Visible-frame changes reach only the amount/count/LogBox/child-label consumers.
The dashboard root, header, rail and pulse do not rebuild per child crossing.
The pulse and SummaryPill keep stable animation controllers, and appropriate
`RepaintBoundary` nodes isolate their paint work. LogBox retains one State,
controller and lazy sliver; a frame change is an immutable VM pointer swap with
stable row keys.

## 12. Reproducible profile environment and results

Workflow: [GitHub Actions run 31053294491](https://github.com/elizerpist/exptv2/actions/runs/31053294491), completed successfully.

Current artifact:
[dashboard-profile-results-f364bacb79cd24314dc1491474d80cfc4a18df07](https://github.com/elizerpist/exptv2/actions/runs/31053294491/artifacts/8949573673).

Milestone artifact:
[dashboard-profile-baseline-bb6c294](https://github.com/elizerpist/exptv2/actions/runs/31053294491/artifacts/8949642620).

Environment: GitHub-hosted Ubuntu 24.04 Azure runner, Linux
6.17.0-1020-azure x86_64, Android Emulator 36.5.10 (build 15081367), API 35
x86_64 Pixel 7 / Android 15, four guest processors and 2,048 MiB guest RAM
(16 GiB host). KVM acceleration was active. Flutter 3.41.4 profile mode and
Dart 3.11.1 android_x64 ran with Android animations enabled and verbose flow
logging disabled. The emulator command used `-gpu swangle -feature -Vulkan`;
the actual renderer was ANGLE/OpenGL ES 3.1 over the SwiftShader software
Vulkan device.

This renderer limitation matters: 244 of 247 measured current frames missed
the raster budget, with raster p95 values between 254.969 and 345.760 ms. Those
numbers are reported below rather than hidden. This environment can establish
motion/data causality, deterministic targets, UI-isolate work, ownership and
rebuild behavior; it cannot by itself establish physical-device GPU raster
smoothness. The acceptance gate therefore did not reinterpret SwiftShader
raster misses as data-pipeline stalls.

### A–J current profile

Motion outcome and publication data:

| Scenario | Rows | Duration ms | Start→target/settle | Semantic sequence | Visible sequence | Publishes / coalescer | Max/frame |
|---|---:|---:|---|---|---|---:|---:|
| A SUM/year/month | 658 | 6782.895 | 12→13/13 | structural | 6→13 | 4 / 2 | 1 |
| B year/month populated | 658 | 3723.421 | 6→3/3 | 7→8→9→10→11→0→1→2→3 | 7→8→9→10→11→3 | 7 / 6 | 1 |
| C year/month empty | 0 | 3650.886 | 6→3/3 | 7→8→9→10→11→0→1→2→3 | 7→8→9→10→11→3 | 6 / 6 | 1 |
| D month/day populated | 94 | 3623.331 | 13→22/22 | 14→15→16→17→18→19→20→21→22 | 14→15→16→17→18→22 | 6 / 6 | 1 |
| E month/day empty | 0 | 3706.007 | 13→22/22 | 14→15→16→17→18→19→20→21→22 | 14→15→16→17→18→22 | 6 / 6 | 1 |
| F parent while rail open | 94 | 3409.588 | 13→13/13 | structural | 13 | 1 / 1 | 1 |
| G direction while rail open | 6 | 3015.963 | 13→13/13 | structural | 13 | 2 / 2 | 1 |
| H pulse + parent navigation | 94 | 3425.030 | 13→13/13 | structural | 13 | 2 / 2 | 1 |
| I first fling | 94 | 3752.147 | 13→22/22 | 14→15→16→17→18→19→20→21→22 | 14→15→16→17→18→22 | 6 / 6 | 1 |
| J tenth fling | 94 | 3768.561 | 13→22/22 | 14→15→16→17→18→19→20→21→22 | 14→15→16→17→18→22 | 6 / 6 | 1 |

UI build timing and process allocation proxy:

| Scenario | Frames | UI p50/p95/p99/worst ms | UI misses | RSS delta bytes |
|---|---:|---:|---:|---:|
| A | 39 | 0.214 / 11.462 / 22.213 / 22.213 | 1 | -3,309,568 |
| B | 24 | 1.506 / 8.761 / 15.035 / 15.035 | 0 | 1,712,128 |
| C | 24 | 1.475 / 2.813 / 6.477 / 6.477 | 0 | 831,488 |
| D | 23 | 1.697 / 16.905 / 17.304 / 17.304 | 2 | -9,289,728 |
| E | 24 | 1.381 / 6.010 / 8.494 / 8.494 | 0 | 1,396,736 |
| F | 21 | 0.239 / 1.590 / 13.094 / 13.094 | 0 | -3,026,944 |
| G | 21 | 0.218 / 4.720 / 6.340 / 6.340 | 0 | -368,640 |
| H | 24 | 0.197 / 2.597 / 4.685 / 4.685 | 0 | -12,406,784 |
| I | 23 | 1.600 / 13.194 / 18.882 / 18.882 | 1 | -3,448,832 |
| J | 24 | 1.425 / 8.358 / 37.988 / 37.988 | 1 | 847,872 |

The signed RSS delta is the harness's bounded process-level allocation-burst
proxy; negative values mean collection/release exceeded allocation over that
window. VM GC instrumentation recorded zero pauses and zero pause microseconds
in all ten scenarios.

Raw raster timing from the software renderer:

| Scenario | Raster p50/p95/p99/worst ms | Raster misses/frames |
|---|---:|---:|
| A | 242.713 / 282.976 / 358.767 / 358.767 | 39/39 |
| B | 236.420 / 256.405 / 278.359 / 278.359 | 24/24 |
| C | 230.967 / 259.870 / 265.382 / 265.382 | 24/24 |
| D | 241.921 / 270.347 / 272.028 / 272.028 | 23/23 |
| E | 235.165 / 254.969 / 267.772 / 267.772 | 24/24 |
| F | 240.018 / 310.467 / 315.139 / 315.139 | 20/21 |
| G | 243.450 / 345.760 / 354.101 / 354.101 | 21/21 |
| H | 241.629 / 274.177 / 335.973 / 335.973 | 24/24 |
| I | 244.180 / 326.737 / 379.123 / 379.123 | 22/23 |
| J | 245.511 / 264.369 / 270.396 / 270.396 | 23/24 |

Measured build/layout/paint boundaries:

| Scenario | Root/header/rail/pulse builds | LogBox/row builds | Layout/paint | Amount starts |
|---|---:|---:|---:|---:|
| A | 2 / 2 / 2 / 4 | 4 / 56 | 0 / 14 | 1 |
| B | 0 / 0 / 0 / 0 | 7 / 24 | 0 / 14 | 0 |
| C | 0 / 0 / 0 / 0 | 6 / 0 | 0 / 13 | 0 |
| D | 0 / 0 / 0 / 0 | 6 / 21 | 0 / 13 | 0 |
| E | 0 / 0 / 0 / 0 | 6 / 0 | 0 / 13 | 0 |
| F | 1 / 1 / 1 / 2 | 1 / 0 | 0 / 7 | 1 |
| G | 2 / 2 / 2 / 4 | 2 / 4 | 0 / 6 | 2 |
| H | 2 / 2 / 2 / 4 | 2 / 0 | 0 / 8 | 1 |
| I | 0 / 0 / 0 / 0 | 6 / 21 | 0 / 14 | 0 |
| J | 0 / 0 / 0 / 0 | 6 / 21 | 0 / 14 | 0 |

Across A–J: 247 frames, five UI build-budget misses, worst UI task
37.988 ms, 46 visible publications, 43 coalescer selections, maximum one
publication per display frame, zero measured GC pauses, zero stale callback,
and zero controller/physics/position recreation. The child-fling scenarios
B/C/D/E/I/J each had zero dashboard-root, header, rail and pulse rebuilds.

### Before/after comparable measurements

The milestone artifact records the old architecture under identical CI runner
and renderer policy with density fixtures:

| Baseline rows | Frames | UI p50/p95/p99/worst ms | UI misses | Raster p50/p95/p99/worst ms | Raster misses | Root/pill/rail builds | LogBox build/projection/rows | VM projections / µs | Layout µs |
|---:|---:|---:|---:|---:|---:|---:|---:|---:|---:|
| 0 | 384 | 0.618 / 3.159 / 5.128 / 6.373 | 0 | 219.932 / 313.218 / 346.304 / 362.437 | 384 | 18 / 18 / 18 | 48 / 42 / 0 | 58 / 137 | 6,202 |
| 94 | 375 | 0.628 / 10.132 / 50.036 / 67.214 | 16 | 235.335 / 298.680 / 359.343 / 440.630 | 375 | 18 / 18 / 18 | 48 / 42 / 552 | 59 / 47,541 | 260,698 |
| 1,000 | 375 | 0.672 / 22.733 / 61.225 / 74.363 | 30 | 236.742 / 328.968 / 359.542 / 366.125 | 374 | 18 / 18 / 18 | 48 / 42 / 804 | 59 / 105,116 | 275,981 |

The old UI p95 rose from 3.159 to 10.132 to 22.733 ms with density; UI
misses rose 0→16→30, and LogBox VM projection grew 137→47,541→105,116 µs.
The old root, SummaryPill and rail each rebuilt 18 times in every fixture.
The baseline comparison gate reported -68.82% for 0 versus 94 rows and
+124.37% for 1,000 versus 94 rows, outside its 10% density target.

The new rail experiments do not project LogBox or rebuild root/header/rail/
pulse during crossings, all six motion I/O counters are zero, and the physical
sequence/target/settle is exact across paired densities. The worst current UI
task was 37.988 ms, versus 67.214 ms at 94 and 74.363 ms at 1,000 rows in the
milestone harness. Because the milestone fixture harness predates the native
A–J harness, timing deltas are directional before/after evidence rather than a
claim that the two workloads are byte-for-byte identical.

The milestone harness predates A–J and measures 0/94/1000-row density fixtures;
the current harness uses real seeded native Room/SQLite scenarios. The report
compares compatible frame and gesture measurements and does not present the two
different fixture methods as identical experiments.

## 13. Empty versus populated evidence

Year→month B/C used the same start/velocity and produced the exact same nine
semantic indices and target/settle index 3 at 658 versus 0 rows. Duration was
3723.421 versus 3650.886 ms, a 72.535 ms (1.95%) difference.

Month→day D/E produced the exact same nine semantic indices, the same
coalesced visible sequence and target/settle index 22 at 94 versus 0 rows.
Duration was 3623.331 versus 3706.007 ms, an 82.676 ms (2.28%) difference.

The automated comparison confirms equal targets and settles for both pairs.
UI-build p95 was 67.89% lower in empty B/C and 64.45% lower in empty D/E, but
this no longer changes the physical result. Raster p95 changed +1.35% and
-5.69%, respectively, under SwiftShader.

Deterministic unit/widget tests additionally exercise 0, 1, 94 and 658-row
decks with the same start position and velocity. Target, settle and semantic
sequence are data-independent.

## 14. Cold versus warm evidence

Cold preparation is exercised with delayed native/repository completions and
rapid target replacement. The deterministic tests prove the old coherent
frame remains visible, the rail remains active, completion only fills the
cache, and only a complete matching generation/epoch can atomically publish.
Preparation decode/projection runs in the worker isolate, and every A–J motion
window reports zero platform, SQL, repository, formatting and LogBox work.

The physical cold/warm proxy I/J is also invariant: identical start, velocity,
semantic sequence, visible sequence, target and settle, with a 0.44% duration
difference. Thus cache warmth changes availability, not motion correctness.

Correctness does not depend on prewarm: a cold deck keeps the prior coherent
visible frame while physical motion continues, then performs one atomic latest
target publication.

## 15. First versus tenth fling evidence

I and J both started at index 13, crossed
14→15→16→17→18→19→20→21→22, displayed
14→15→16→17→18→22 and settled at 22. Duration was 3752.147 versus
3768.561 ms: 16.414 ms or 0.44%. Both published six targets, never more than
one per display frame, and both recorded all six motion I/O counters as zero.
The automated comparison reports equal target/settle; UI p95 was 13.194 versus
8.358 ms and software-raster p95 326.737 versus 264.369 ms.

The same motion catalog, controller, physics and simulation are used for both;
no first-use data work is reachable from a fling callback.

## 16. Test and verification results

- Focused dashboard/application verification: 47/47 passed in Ubuntu proot.
- Full Flutter non-golden suite: 250/250 passed in Ubuntu proot and GitHub CI.
- Flutter analyze: no issues locally (142.4 seconds) and in GitHub CI.
- Boundary script: verified locally and in CI.
- GitHub `test-flutter`: success in 1m18s.
- GitHub `test-core`: Room/Robolectric, native prepared-deck/query-count and
  Android bridge tests succeeded in 4m28s.
- GitHub current A–J profile: success in 9m10s.
- GitHub milestone baseline capture: success in 12m00s.
- GitHub debug APK build/release: success in 4m35s.
- Golden tests/assets added or regenerated: zero.

The deterministic suite covers the 15 requested groups: 100-crossing I/O
isolation; data-density invariance; cold/warm parity; long fling; 100-run
repeatability; display-frame coalescing; settle no-op; stable identities;
open-rail parent mapping including clamp and A→B→C; direction races; revision
invalidation; seed gate; SummaryPill/pulse transitions; LogBox stability; and
seeded randomized state-machine invariants.

## 17. Proof that motion performs no data I/O

The static boundary test rejects repository/platform/formatting/projection
dependencies from motion sources. The 100-crossing test resets and checks all
six runtime counters. The profile report captures deltas around only the
measured motion interval. Required values are:

```text
sqlCallsDuringMotion             = 0
platformCallsDuringMotion        = 0
repositoryReadsDuringMotion      = 0
liveLeaseStartsDuringMotion      = 0
logBoxProjectionsDuringMotion    = 0
formattingDuringMotion           = 0
```

Every scenario A–J reported zero for all six values; their aggregate is also
zero. The scenario-wide repository deltas are shown separately because they
include permitted preparation or committed-live work outside physical motion:

| Scenario | SQL/platform/deck calls | Channel/SQL µs | Dart parse / decode-projection µs | Payload bytes |
|---|---:|---:|---:|---:|
| A | 6 / 1 / 1 | 132,629 / 99,821 | 1,422 / 15,927 | 46,320 |
| B | 0 / 0 / 0 | 0 / 0 | 0 / 1,770 | 0 |
| C | 0 / 0 / 0 | 0 / 0 | 0 / 13,554 | 0 |
| D | 0 / 0 / 0 | 0 / 0 | 0 / 4,816 | 0 |
| E | 0 / 0 / 0 | 0 / 0 | 0 / 6,285 | 0 |
| F | 6 / 1 / 1 | 32,357 / 14,724 | 158 / 11,322 | 4,126 |
| G | 6 / 1 / 1 | 63,173 / 38,929 | 1,156 / 20,553 | 31,307 |
| H | 6 / 1 / 1 | 49,149 / 21,714 | 330 / 18,848 | 4,060 |
| I | 0 / 0 / 0 | 0 / 0 | 0 / 4,074 | 0 |
| J | 0 / 0 / 0 | 0 / 0 | 0 / 2,754 | 0 |

A/F/G/H demonstrate the constant six-query parent batch. The nonzero
decode/projection-only deltas in B/C/D/E/I/J are committed-live work observed
over the whole scenario after promotion; none occurred inside the guarded
motion interval.

## 18. Proof that settle is a visual no-op

`DashboardMotionKernel` emits settle metadata to the committed owner. The
settle test starts from a visible preview and proves no visible publish, no
LogBox bind/projection, no amount animation restart, no viewport reset and no
controller creation. The committed frame reuses the visible snapshot; only the
single live lease may change after promotion.

The focused settle test passes, including zero deltas for visible publish,
LogBox binding/projection, amount start, viewport reset and identity creation.
The profile uses the same promotion path. Same-target settle does not append a
second semantic value; it may start the one committed lease after promotion,
but the motion interval records zero lease starts and the visible frame stays
unchanged.

## 19. Proof of stable controller, position and physics identity

The 100-transition widget test retains the same rail State,
`CenteredCarouselController`, `ScrollController`, application physics and,
where Flutter attachment lifecycle permits, `ScrollPosition`; it also retains
the LogBox State/controller. Every A–J report records `identities_before` and
`identities_after` plus recreation counters.

All ten A–J reports have equal `identities_before` and `identities_after` for
Motion Kernel, carousel controller, Flutter ScrollController, ScrollPosition
and physics. Aggregate controller, physics and position recreation counts are
0/0/0. The 100-transition widget test independently proves the same property
and also retains the LogBox State/controller.

## 20. Delivery

Implementation commit: `f364bacb79cd24314dc1491474d80cfc4a18df07`

Branch: `refactor/dashboard-complete-motion-data-isolation`, pushed to
`origin`.

GitHub Actions:
[successful run 31053294491](https://github.com/elizerpist/exptv2/actions/runs/31053294491).

APK release:
[fluvi-debug-f364bac](https://github.com/elizerpist/exptv2/releases/tag/fluvi-debug-f364bac).

Release asset:
[fluvi_f364bac.apk](https://github.com/elizerpist/exptv2/releases/download/fluvi-debug-f364bac/fluvi_f364bac.apk),
149,586,527 bytes.

Downloaded APK:
`/storage/emulated/0/Download/fluvi/fluvi_f364bac.apk`.

SHA-256:
`272cdbfb07e2ea54f942d5032dbbc9960a1894f564da8fc8a21e62bb12c55833`.
The local file matches the release digest exactly and `unzip -tq` reports no
archive errors. Existing APKs in the download directory were left untouched.
