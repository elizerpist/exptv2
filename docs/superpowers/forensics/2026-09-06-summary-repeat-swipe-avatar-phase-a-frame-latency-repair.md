# Forensic journal — Summary repeat swipe / Avatar Phase-A authority / latency

## Authoritative base

- Application worktree and physical source: `9e8a7b3a0a1f17bbd9433927e1d8a0afcd8413e9`.
- Repair branch: `fix/summary-repeat-swipe-avatar-phase-a-frame-latency-codex-20260906`.
- Parent: `a8ad6e5cae641a19a7a23acc917313a4c41ac851`.
- Tooling worktree/graph commit: `70aa55a33df55f259196b9a526a687d0823e9b8f`.
- CURRENT graph manifest source head: `9e8a7b3a0a1f17bbd9433927e1d8a0afcd8413e9`; raw index SHA-256:
  `51f70b2b9bac6f7d642eee9eeddb06d9a2e6b59fadf0c6eff8f9b52e3c884892`.

The graph is current for the application source. It is used only for source
navigation and first-order impact discovery; all causal conclusions below are
from frozen runtime evidence plus CURRENT source.

## Session lineage and frozen evidence

The former session `fluvi-1788669322121683` remains **historical same-SHA
evidence**. Its source-level findings remain useful, but none of its
sequence-specific counts, timing ranges, or physical-occurrence claims are
reused here.

The authorized current session is `fluvi-1788686737010611`,
`profile/9e8a7b3a0a1f`, core revision 2. All three Drive documents were
fully opened, then materialized once and frozen locally at
`2026-09-06T14:00:11+02:00`. The frozen files are read-only; later mutable
Drive updates are excluded from this repair cycle unless the user explicitly
supersedes this snapshot.

| Document | Drive ID | Frozen file | Bytes | SHA-256 | LIVE_TAIL headers | Unique range |
| --- | --- | --- | ---: | --- | --- | --- |
| Fluvi logs avatar fling | `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs` | `docs/superpowers/evidence/2026-09-06-profile-9e8a7b3a-session-fluvi-1788686737010611/fluvi-logs-avatar-fling.txt` | 637792 | `fb95ea63204fc67ff8c5fd9687374c073d0b771dc2933202b2e803d88b9a8d9d` | `1185–2184`, `1186–2185` | 1185–2185 |
| Fluvi logs time fling | `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE` | `docs/superpowers/evidence/2026-09-06-profile-9e8a7b3a-session-fluvi-1788686737010611/fluvi-logs-time-fling.txt` | 901597 | `f96cf8f5995b1f9c7106a7b2ccc529798e4c0b02f7a9d16daaedd927ab107a31` | `4998–5997`, `4999–5998` | 4998–5998 |
| Fluvi logs slider | `13jUTJW6sg-gaG7Zt3EofLxPauSvoKOqLpqss8dAR_rU` | `docs/superpowers/evidence/2026-09-06-profile-9e8a7b3a-session-fluvi-1788686737010611/fluvi-logs-slider.txt` | 728959 | `9cef610403acf46351e99e90015cd8a4747dad1ad60a434e1dada117e989cfe7` | `14752–15751`, `14753–15752` | 14752–15752 |

`manifest.json` alongside the files records the Drive modified timestamps,
serialization rule, headers, hashes and retention ranges. Each document has
2,000 event paragraphs: 1,001 unique sequence IDs and 999 byte-identical
duplicate payloads. There are no differing duplicates.

The three windows are not continuous. Retention gaps are `2186–4997` and
`5999–14751`. Runtime/mark ranges are:

| Document | Runtime timestamp range | USER_MARKs | What is absent |
| --- | --- | --- | --- |
| Avatar | 11:25:16.37–11:25:24.24 | 2184 avatar_fling; 2185 avatar_filter_stuck | Earlier portion of generation 5 and all cross-window activity |
| Time | 11:27:02.45–11:27:20.55 | 5997 time_fling; 5998 time_target_jump | Pointer coordinates, hit path, arena winner and later runtime activity |
| Slider | 11:28:50.43–11:28:53.53 | 15751 mind_slider; 15752 mind_slider_no_live_list | Raw pointer/onChanged/raster stages and later interaction activity |

USER_MARK labels identify the user's observation and build, not a causal
mechanism or an exact event correlation.

## Re-audited findings

### Summary input ownership — PROVEN boundary, root cause still UNPROVEN

Successful selector requests reach `SUMMARY_POINTER_ACCEPTED` at Time seq
5032, 5138, 5220 and 5251. At 5032, 5138 and 5251 the prior activity is
`HoldScrollActivity`; accepted raw pointer down uses the existing
controller/position/physics identities. CURRENT `CenteredCarousel` source
already invalidates the old command on direct pointer down.

The same retained Time window contains a full `COLLAPSE|GEOMETRY` run
beginning at 5408 after selector acceptance without another
`SUMMARY_POINTER_ACCEPTED`. This supports a pre-selector ownership route,
not delayed semantic publication or a proven timer cooldown. It does **not**
contain global/local pointer coordinates, visual/interaction rects, hit-test
path, gesture-arena participants/winner, upper-coordinator owner, or variant
epoch. The following alternatives remain open:

1. pointer started outside the glyph-sized selector rect but inside the
   visually attributable selector cell;
2. pointer started inside the selector but lost arena/lifecycle ownership;
3. stale geometry/variant/overlay intercepted it.

CURRENT source confirms the candidate boundary: segmented selectors use their
same glyph-sized track rect for paint, hit test and semantics, while the
full Summary background is opaque and owns vertical collapse gestures. The
diagnostic/reproducer must distinguish these alternatives before geometry is
changed.

### Avatar readable Phase-A resource authority — PROVEN and implementation-ready

The frozen Avatar window independently reproduces the source-supported gap:

```
AV|LIVE_ROOT_MISS
  -> VERTICAL_PREVIEW_ROOT_ARM_STARTED
  -> VERTICAL_PREVIEW_ROOT_ARMED
  -> FOCUS_PHASE_A_INTERACTION_FRAME_PUBLISHED
  -> AV|VISIBLE_PUBLICATION_ACCEPTED
  -> AV|LOGBOX_TARGET_PAINT_REJECTED
  -> LOGBOX_PHASE_A_READABLE_ROWS fallbackSource=readableResourceMissing
  -> LOGBOX_NONEMPTY_PRESENTATION_WITHOUT_PAINT
  -> previewSurfaceHeight=13 / renderedContentExtent=13
```

Within the retained unique range there are 21 visible Avatar publications, 19
current-identity paint rejection events, 21
`readableResourceMissing`/nonempty-without-paint events, and 21 thirteen-pixel
preview extents. Four `AV|LOGBOX_TARGET_PAINTED` events occur, but some target
handles reappear under a newer presentation/frame identity, so raw paint-event
counts are not terminal-outcome counts.

CURRENT source explains the mismatch: `DashboardLogBoxViewport` calls
`CommittedLogViewportCache.armPreviewRootResources`, whose private prearmed
root is for later committed adoption. The active `railPreview` painter instead
requires `DashboardLogBoxPreparedSceneCache.hasCompleteReadablePhaseAFor` on
the exact payload. A newly derived Avatar focus payload can be published while
its compact semantic preview geometry is not armed in that painter-visible
authority. `VERTICAL_PREVIEW_ROOT_ARMED` therefore does not currently mean
rail-preview readiness. The red production-parent test must reproduce exactly
that split, then the repair must make publication use the same resource owner
as the painter or retain/coalesce the prior valid visual.

### Avatar frame cadence — PROVEN frame misses; exact cause UNPROVEN

The retained terminal summaries are five unique flights, generations 5–9:

| Generation | Samples | Missed | Build p50/p95/max µs | Raster p50/p95/max µs | Total p50/p95/max µs |
| --- | ---: | ---: | --- | --- | --- |
| 5 | 89 | 3 | 1220 / 2593 / 15085 | 5691 / 11711 / 14202 | 8280 / 16160 / 23660 |
| 6 | 40 | 14 | 2503 / 17124 / 17597 | 9187 / 15835 / 29027 | 13194 / 35911 / 40085 |
| 7 | 57 | 14 | 1299 / 15727 / 16155 | 7550 / 15671 / 26637 | 10884 / 28534 / 32666 |
| 8 | 60 | 10 | 1810 / 14889 / 18204 | 5482 / 14338 / 53790 | 8761 / 31645 / 56369 |
| 9 | 62 | 15 | 1433 / 7332 / 17815 | 5932 / 14435 / 17460 | 8969 / 25900 / 34852 |

Aggregate: 308 samples and 56 missed frame-budget samples. Both build and
raster p95 are elevated in multiple flights. The same summaries retain stable
controller/ScrollPosition/physics identity, `avatarRailBuilds=0`, and zero
repository/index/scene/canonical work at semantic ticks. This proves visible
cadence is a real measurement issue, but not that physics is the source. The
correctness repair is performed first; then frame stages are remeasured and
only a correlated residual source may be optimized.

### Slider — instrumentation-first

The frozen tail contains interactions 6–9, not the historical interaction
numbers/counts. Their retained terminal summaries report 7/10/5/15 preview
publications respectively, each with one canonical commit and zero drag-time
repository/index work, domain invalidation, unmount or loading exposure.

Thirty-five retained accepted preview-to-paint pairs match by frame generation:
minimum 2716 µs, p50 3091 µs, p95 3401 µs and maximum 3889 µs. All 35 retained
paint acknowledgements are non-empty and paint one bounded visible row. This
does not establish the whole user-visible list continuously changed: raw
pointer, recognizer, `onChanged`, visible-row and raster stages are not
captured. Production slider behavior remains unchanged until the requested
bounded end-to-end instrumentation and a deterministic regression prove a
specific fault.

### Time / LogBox — protected by current evidence

The current Time window records:

- flight 18: two accepted / two painted, no transient query/index/scene work;
- flight 19: five accepted / five exact-empty paints, one canonical settle,
  zero settle delta;
- flight 20: two accepted / two exact-empty paints; its duplicated terminal
  summary is one physical flight, not two;
- flight 21: one accepted / one exact-empty paint and one canonical settle;
- flight 22: two accepted / two exact-empty paints and one canonical settle.

The early `SUMMARY_SETTLE_REJECTED_UNPAINTED_OR_SUPERSEDED` at 5034 follows
an older expected target, while subsequent current targets receive exact-empty
paint outcomes. No retained Time target paint rejection, transient query apply,
index build, or scene preparation is present in the summarized flights. The
current evidence protects Time data/paint/extent authority; the Summary work
is restricted to input ownership.

## Classification at implementation start

| Track | Status |
| --- | --- |
| Frozen evidence provenance and global deduplication | PROVEN |
| Summary selector route reaches direct preemption when accepted | PROVEN |
| Exact cause of failed selector ownership | UNPROVEN — bounded diagnostics/reproducer required |
| Avatar committed-prearm versus rail-preview readable-resource split | PROVEN |
| Avatar accepted nonempty target may paint zero rows / 13 px extent | PROVEN |
| Avatar frame-budget misses | PROVEN |
| Avatar build/raster source or physics cause | UNPROVEN |
| Slider preview-to-paint fast path | PROVEN for retained pairs |
| Slider pointer-to-visible-list latency | MISSING EVIDENCE |
| Time query/painter/extent path | PROTECTED; no change authorized without new reproducer |

## Evidence limitations

The frozen files are complete exports of the two retained Live Tail snapshots,
not full session traces. They do not establish events in the two retention
gaps, physical pixel appearance, Flutter arena winner, or raw pointer/raster
completion for Slider. A test or diagnostic must not claim those facts merely
because a related log event exists.

## Implementation and automated validation

### Summary repair — source/test-proven geometry boundary

The clean-9e red probe made the diagnosis concrete: a pointer at
`dayVisual.left - 1` is classified as background while still adjacent to the
visually attributable Day section. The production source had used one
glyph-sized rect for paint, hit testing and semantics. That gap is sufficient
to explain the observed pre-selector routing; it does not posit an internal
cooldown.

`SummarySegmentedTrackGeometry` now has distinct visual-content,
geometry-derived interaction-cell and semantics rects. Interaction boundaries
are midpoint/separator-derived, clipped to the navigation zone, disjoint and
do not enter the amount region. `_FixedHierarchyTracks` keeps the existing
visual glyph placement by translating the child back to its original visual
rect. A passive pointer listener records bounded hit classification without
adding another recognizer. The opaque background detector remains responsible
only for the unassigned region and its existing collapse callbacks.

The persistent CoreDashboard test covers immediate repeated Day gestures at
0/16/32/50/100/250/500/1000 ms without `pumpAndSettle`, plus an unassigned
background drag. It proves selector exclusivity and preserved background
collapse in the test environment. A new device trace is still required to
record actual arena winner/hit path for the user interaction.

### Avatar repair — one painter-visible Phase-A authority

The repair adds a compact live-interaction Phase-A binder on the existing
`DashboardLogBoxPreparedSceneCache`. It prepares the exact selected payload's
semantic preview geometry, verifies the exact bounded row/header resources,
and finally calls the same `hasCompleteReadablePhaseAFor` authority consulted
by the active rail-preview painter. The controller receives this existing-cache
binder through its existing scene-window coordinator attachment.

For a nonempty Avatar target, the controller now defers the candidate before
visible acceptance when that exact painter authority cannot satisfy readiness.
It therefore retains the preceding valid visual rather than accepting an
unpaintable 13-pixel result. Once Phase A is ready, the old active-resource
Phase-B activation is allowed only as optional augmentation; it neither gates
nor creates Phase A. This preserves the Phase-A/Phase-B authority split.

The clean-9e private-prearm red probe and the production-parent red assertion
are green on this branch. The repair uses no new cache, visible-frame store,
LogBox, controller or cache-limit expansion. It performs no repository/query/
index/rich projection/TextPainter work in the semantic tick.

### Mind instrumentation — no semantic repair claimed

`QueryAmountRangeControl` now emits one bounded summary per drag with raw
pointer, recognizer, changed/unchanged range, preview-request/publication and
coalescing stages. CoreDashboard logs it with the existing Mind interaction
flow identity; the existing target paint acknowledgement supplies the later
painted-row correlation. The listener is passive and creates no additional
gesture-arena competitor. Mind query/count/paint behavior is unchanged.

The new probe is explicitly compile-time diagnostic opt-in: without
`FLUVI_ONSCREEN_DIAGNOSTICS` it installs neither its passive `Listener` nor a
`Stopwatch`/per-drag counters, even if a host has a summary callback. The
human-diagnostic APK enables that flag, so the requested physical trace stays
available without putting diagnostics on a normal release slider hot path.

This is deliberately not a claim that raster completion or physical visible
list continuity has been proven. That requires the next diagnostic APK trace.

### Validation classification

Formatter, analyzer and all changed focused groups pass. The full application
suite completes at `+278`; the fast suite completes at `+291` once the proot
Flutter PATH is explicitly exported. The first fast-script attempt failed
before tests because its inherited shell PATH lacked `flutter`; that is an
environment invocation result, not an application failure.

The full presentation suite completes at `+582 -19`. A direct clean-base run
proves the eight `dashboard_header_space_fabric_temporal_test.dart` failures
and the `dashboard_logbox_stable_render_surface_test.dart` singleton
Scrollable failure are inherited; the remaining golden/header failures match
the same normalized clean-9e signature. The changed Summary, Avatar Phase-A
and Mind diagnostics groups pass within the broad run. No golden was
regenerated. GitHub CI remains the delivery authority. No local APK was
attempted.

### Profile terminal-idle lifecycle — red/green root cause

The first delivery candidate `aa26f01…` exposed a profile-gate failure twice,
once in `B_year_month_rail_populated` and once in `I_first_fling`.  Both
failures ended with a physical `ScrollPosition` already idle but the dashboard
motion state still `drag`:

```
Dashboard rail did not become motion-idle before the profile timeout:
activity=drag scrollActivity=false.
```

The runs also contain multi-second software-EGL frames, but that timing is not
by itself a root cause.  The profile harness, the shared carousel controller,
the motion kernel, and the Time rail have no source diff between `9e8a…` and
`aa26…`. The separate same-source `9e8a…` control run
[`34052858228`](https://github.com/elizerpist/exptv2/actions/runs/34052858228)
also fails in `I_first_fling` with the same normalized state
(`activity=drag scrollActivity=false`) after software-EGL frames up to
3671.89 ms. This proves the profile failure is not introduced by the `aa26…`
repair, while still leaving the underlying shared lifecycle defect in scope.

The current shared-controller test then reproduced a concrete lifecycle race:
after raw contact ends, `_scheduleTerminalActivityCheck` sampled a transient
`HoldScrollActivity` and returned. Flutter defines Hold as *non-scrolling*.
Its later `HoldScrollActivity -> IdleScrollActivity` transition therefore does
not produce another `isScrollingNotifier` false transition. No second terminal
probe was scheduled, so `onSelectionSettled` never reached
`TimeRefinementRail -> DashboardMotionKernel`, leaving the kernel at `drag`
while `hasActiveScrollActivity` was false.

The red test fails on the pre-fix code (`Expected: [2]; Actual: []`). A second
production-parent regression verifies the real
`CoreDashboard -> TimeRefinementRail -> DashboardMotionKernel` chain. The
minimal repair gives a command-scoped terminal Hold exactly one additional
frame-local probe. It stops after that probe, or earlier on a new pointer,
scrolling activity, command invalidation, disposal, or an actual idle settle.
A regression proves a persistent Hold cannot create an unbounded frame loop.
It adds no timer, timeout increase, cooldown, physics change,
controller/position recreation, query work, or target-frequency reduction.

The final bounded implementation passes both shared-controller cases and the
full `core_dashboard_test.dart` suite (`+31`), including the persistent
`CoreDashboard -> TimeRefinementRail -> DashboardMotionKernel` path. This is
local red/green evidence only; the exact new-SHA profile gate remains required
before classifying the CI symptom as repaired.

Current changed-SHA validation is clean for formatter, analyzer, shared motion
(`+35`), Summary (`+48`), application (`+278`) and fast (`+291`) suites. The
full presentation suite is `+583 -19`: the one additional pass is this new
regression and the 19 failures retain the clean-9e header/golden/ticker and
stable-Scrollable signatures. No golden was changed. The final GitHub profile
matrix remains the acceptance check for the original timeout symptom.

### Independent review reconciliation

One review raised three follow-up checks. CURRENT source and tests resolve two
without an extra production change: Phase-A uses
`DashboardLogSemanticPreviewSlot.rowTop`, which includes day-header and
inter-group offsets, rather than `ordinal * rowHeight`; the dedicated
`RED TIME GEOMETRY` pixel regression verifies the first and second group
origins before and after rich Phase-B handoff. Likewise, a nonempty payload
with no complete readable bank returns fail-closed without a marker; the
`RED PHASE-A INVARIANT` pixel regression asserts that it paints no card, bars,
dot or fake content.

The FrameTiming callback, timestamp maps and latency accumulators in the
Avatar rail are already gated by the pre-existing
`FLUVI_PHYSICAL_RAIL_DIAGNOSTICS`/debug policy in the 9e base; the always-on
semantic cadence accumulator is pre-existing bounded flight evidence and was
not altered by this repair. The newly introduced Slider probe is now gated as
described above. No new release hot-path timing collector remains in this
diff.
