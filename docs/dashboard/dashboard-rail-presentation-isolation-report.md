# Dashboard rail/presentation isolation report

Date: 2026-08-06

This report covers the targeted isolation requested after the best-performing
dashboard milestone. It deliberately separates deterministic local proof,
headless-emulator profile evidence and physical-device validation.

## 1. Milestone and implementation commits

- best-performance source commit: `c083ef403c45e7365779734d13cd0683a9f371ce`;
- recoverable milestone commit: `2243cfda9d507f4e55124713c50b320b07520fae`;
- milestone branch:
  `milestone/dashboard-best-performance-before-rail-presentation-isolation`;
- annotated milestone tag:
  `milestone/dashboard-best-performance-before-rail-presentation-isolation-20260806`;
- targeted implementation commit:
  `3c3a3a1dbe2d99cf44d82cd48a280b6cca7e3f8e`;
- work branch: `refactor/dashboard-rail-presentation-isolation`.

## 2. Proven root cause

The density-dependent feeling did not originate in release velocity, the
ballistic handoff, simulation target, ScrollActivity interruption, metric
correction, controller identity or physics identity. Thirty identical runs per
fixture produced exact empty/populated motion parity.

The first density-dependent divergence occurred after the prepared-index
lookup. A visible-frame publication rebuilt the selected LogBox content. The
milestone implementation recreated a per-group sliver/delegate description and
then built, laid out and painted populated rows; an empty frame built no rows.
That render work made intermediate populated child presentation less continuous
and therefore made an identical physical fling feel shorter. The larger monthly
LogBox render workload explains why year -> month felt worse than month -> day.

## 3. Divergence category

| Candidate | Measured result | Conclusion |
|---|---|---|
| gesture release velocity | exact empty/populated parity | not the cause |
| ballistic input velocity | exact parity | not the cause |
| ballistic endpoint | exact pixels and logical delta | not the cause |
| activity interruption/replacement | zero in all normal density runs | not the cause |
| viewport/scroll metric correction | zero in all density runs | not the cause |
| UI/render work after frame selection | populated frames build visible rows; empty frames do not | first divergence/root cause |

## 4. Final presentation path

```text
ScrollPosition
  -> logical index
  -> immutable semantic catalog lookup
  -> O(1) PreparedPresentationFrame reference lookup
  -> last target for the current display frame
  -> atomically stage navigation/amount/count/LogBox lane pointers
  -> lane-local notification
  -> one stable LogBox viewport and one lazy flat SliverList
  -> only visible preprojected rows build
```

The prepared data runtime, bootstrap barrier, immutable index, frame coalescer,
committed paging ownership and motion kernel were retained. Settle remains a
metadata-only visual no-op. No rail crossing or settle initiates data work.

## 5. Empty/populated deterministic comparison

Every value below is from 30 identical scripted gestures per fixture.

| Pair | Release velocity | Ballistic input | Logical delta | Pixel distance | Interruptions | Metric changes |
|---|---:|---:|---:|---:|---:|---:|
| month/day empty | -2032.8611936301181 | 2199.9966122376204 | 10 | 524.5201793722808 | 0 | 0 |
| month/day populated | -2032.8611936301181 | 2199.9966122376204 | 10 | 524.5201793722808 | 0 | 0 |
| year/month empty | -2032.8611936301181 | 2199.9966122376204 | 10 | 524.5201793722808 | 0 | 0 |
| year/month populated | -2032.8611936301181 | 2199.9966122376204 | 10 | 524.5201793722808 | 0 | 0 |

Velocity drift is 0%, endpoint drift is 0 px and logical drift is 0 children.

## 6. Month/day matrix

The matrix ran 150 flings: 0 rows, 2 rows, 9 bounded preview rows across three
groups, a large amount with two rows, and mixed empty/populated crossings.
Every fixture reached the exact same endpoint with zero activity interruption,
metric change, root/Summary/rail/SVG rebuild, identity recreation and data I/O.

Representative debug widget-harness presentation timings:

| Density | Apply p50 us | Apply p95 us | Apply p99 us | Log bind p95 us | Row builds p95 |
|---|---:|---:|---:|---:|---:|
| empty | 495 | 758 | 1787 | 130 | 0 |
| 2 rows | 460 | 929 | 1079 | 441 | 16 |
| 9 rows | 418 | 792 | 2219 | 276 | 56 |
| large amount / 2 rows | 390 | 955 | 1658 | 148 | 16 |

## 7. Year/month matrix

The matrix ran 120 flings: empty months, populated months under a 658-entry
year with a 94-entry populated month, mixed empty/populated months, forward and
reverse. Forward and reverse were exact sign mirrors. All normal runs reported
zero activity interruptions and zero metric changes.

Representative final full-suite debug timings:

| Density/direction | Apply p50 us | Apply p95 us | Apply p99 us | Log bind p95 us | Row builds p95 |
|---|---:|---:|---:|---:|---:|
| empty | 409 | 829 | 839 | 83 | 0 |
| populated forward | 415 | 602 | 623 | 162 | 40 |
| mixed | 466 | 694 | 715 | 185 | 20 |
| populated reverse | 450 | 1133 | 1312 | 285 | 40 |

These microsecond values are debug widget-test measurements, not AOT or
physical-device smoothness claims.

## 8. First/warm comparison

Bootstrap publishes the complete immutable index before enabling interaction,
so the first fling and the tenth use the same prepared lookup and presentation
path. The local density harness has no first-interaction projection or data
acquisition. Exact AOT first/tenth frame and duration values require the online
profile artifact and remain outside the local debug proof.

## 9. Identity evidence

- controller recreation count: 0;
- physics recreation count: 0;
- ScrollPosition recreation count: 0;
- LogBox State and vertical ScrollController remain stable;
- the 100-change widget test preserves rail State/controller/physics/position;
- all per-fling start/ballistic/settle identity sets contain exactly one value.

The unchanged milestone/final SHA-256 values are:

| File | SHA-256 |
|---|---|
| `centered_carousel_physics.dart` | `1b3539cea8ac2870f7fae2c64e78f657187df0046b01d77e21c295c8c2c8a5ec` |
| `centered_carousel_math.dart` | `5558bf2bf909a6316c337e07a777addfc44430060f03cc3070e28a3ad366a6e8` |
| `centered_carousel_metrics.dart` | `6d9d73066afcf6cef698ec2bb3939b2d3f4ea6168ae9253bf782b6081fa7008a` |
| `prepared_dashboard_index.dart` | `470ff2f595d57460abc453eca04480f4cc3f02a76a20d24a9829911463ad27e5` |

## 10. Rebuild/layout/paint counters

Each deterministic density run asserts:

- dashboard root rebuild delta: 0;
- Summary shell rebuild delta: 0;
- rail subtree rebuild from presentation: 0;
- LogBox outer viewport rebuild: 0;
- SVG build/restart delta: 0;
- controller/physics/position recreation: 0;
- scroll metric change/correction: 0;
- activity interruption: 0.

Profile-only render probes add rail/LogBox layout and paint counts/durations
without changing constraints. They are not installed when the bounded flight
recorder is disabled.

## 11. Presentation apply percentiles

The local 270-fling values are listed in sections 6 and 7. The recorder exports
apply p50/p95/p99, selector/equality/notifier/amount/count/LogBox splits, build,
layout, paint and raster timing. Final AOT values are accepted only from the
online profile JSON.

## 12. UI/raster percentiles

The milestone emulator reference was:

| Pair | Populated UI p95 | Empty UI p95 | Endpoint delta |
|---|---:|---:|---:|
| year/month | 11.036 ms | 3.759 ms | 0 children |
| month/day | 13.394 ms | 4.720 ms | 0 children |
| first/tenth | 11.825 / 8.446 ms | n/a | 0 children |

Current AOT UI/raster p50/p95/p99, GC and RSS remain pending until GitHub
Actions produces the exact-commit profile artifact. The workflow fails closed
on motion I/O, activity/metrics/rebuild/identity violations and optionally on
physical frame budgets.

## 13. Modified files

Production ownership changes:

- `dashboard_visible_frame_store.dart` and `dashboard_visible_frame.dart`;
- `prepared_presentation_frame.dart`;
- `dashboard_log_viewport_state.dart`;
- `dashboard_logbox_viewport.dart` and `dashboard_logbox_header.dart`;
- `dashboard_summary_pill.dart` and `core_dashboard.dart`;
- `dashboard_presentation_controller.dart` and
  `dashboard_core_controller.dart`;
- `dashboard_performance_counters.dart` and
  `dashboard_render_phase_probe.dart`;
- `dashboard_rail_flight_recorder.dart`;
- `centered_carousel.dart`, `centered_carousel_controller.dart` and
  `centered_carousel_motion_diagnostics.dart`;
- `time_refinement_rail.dart`.

Verification/profile wiring changed in the A–J integration test, report schema,
workflow, profile runner and non-golden tests. No data-runtime/index-builder,
repository, SQL, physics, snap, friction, velocity, item extent or gesture
constant changed.

## 14. Added non-golden tests

- bounded/disabled flight recorder and report serialization;
- raw gesture, exact ballistic handoff, geometry and identity capture;
- explicit ballistic replacement detection;
- dashboard crossing/apply/frame/settle recorder wiring;
- 30-run month/day density matrix;
- 30-run year/month density/direction matrix;
- atomic presentation-lane consistency and settle visual no-op;
- one flat lazy LogBox sliver, stable viewport and paging;
- profile schema and fail-closed isolation gate;
- static interaction/performance module boundary.

Local Ubuntu-proot results:

- non-golden Flutter tests: **249/249 PASS**;
- Flutter analyze: **PASS**, no issues;
- Flutter/core boundary script: **PASS**;
- staged diff whitespace check: **PASS**;
- golden files added or modified: **0**.

## 15. Data-work proof

Across the density matrix and existing fake-transport interaction suite:

| Motion/navigation counter | Value |
|---|---:|
| SQL | 0 |
| repository reads | 0 |
| platform/bridge calls | 0 |
| prepared index builds | 0 |
| LogBox projections | 0 |
| formatting/grouping/sorting | 0 |
| live lease starts | 0 |

Bootstrap remains five constant-count SQL calls and one complete immutable
index publication; it is outside interaction.

## 16. Physical-device validation procedure

After downloading the exact-commit profile APK:

```bash
adb install -r app-profile.apk
adb shell am force-stop com.fluvi.app
adb shell am start -n com.fluvi.app/.MainActivity
```

On a release-class physical Android device at its native refresh rate:

1. wait for the first valid populated dashboard frame;
2. run ten identical long forward and reverse month/day flings through empty,
   2-row and 7–9-row days;
3. switch to year and run ten identical long forward/reverse flings through
   empty and populated months;
4. compare the first and tenth flings after a fresh force-stop;
5. repeat while the direction SVG pulse is active;
6. repeat immediately after a prior settle and during SummaryPill navigation;
7. capture `flutter drive --profile`/Perfetto frame timing and the bounded
   profile report with verbose FLOW disabled;
8. confirm that endpoint, sensitivity and intermediate child visibility feel
   equal across density, with no viewport remount.

Emulator evidence does not replace this physical perception check.

## 17. Acceptance status

| Criterion group | Status | Evidence |
|---|---|---|
| milestone preserved/recoverable | PASS | branch, commit and annotated tag |
| physics/gesture constants unchanged | PASS | exact hashes and empty diff |
| exact causal divergence proven | PASS | 270-fling matrix |
| empty/populated velocity parity | PASS | 0% drift |
| empty/populated endpoint parity | PASS | 0 px / 0 child drift |
| no activity interruption/metric correction | PASS | all normal runs zero |
| stable controller/position/physics/viewport | PASS | identity tests/counters |
| crossing is RAM-only/O(1) | PASS | boundary/model/store tests |
| settle is visual no-op | PASS | visible publish/rebind/restart deltas zero |
| no motion-time data work | PASS | all acquisition counters zero |
| no root/Summary/rail/SVG rebuild per crossing | PASS | counter assertions |
| LogBox stable/lazy/bounded | PASS | one flat lazy sliver and identity tests |
| no golden/workaround/physics compensation | PASS | diff and boundary scan |
| local full verification | PASS | 249 tests, analyze, boundaries |
| exact-commit AOT profile matrix | PENDING | GitHub Actions outage/artifact pending |
| physical-device perception | PENDING | requires user/device confirmation |

Until the AOT artifact exists, the branch is not described as fully
profile-validated or merge-ready.

## 18. Online evidence state

The implementation is pushed. Initial run `31117161073` completed native tests
but GitHub Actions failed before the Flutter setup with a service-unavailable
action-download error. A clean workflow-dispatch retry, `31119052673`, also
failed in `Set up job` without executing repository steps. At that time the
official GitHub Status API classified Actions as `major_outage` and described
workflow runs failing to start or failing partway through. The current/milestone
profile and APK artifacts therefore remain externally blocked. This is recorded
as infrastructure state rather than silently converted into a passing
performance result.
