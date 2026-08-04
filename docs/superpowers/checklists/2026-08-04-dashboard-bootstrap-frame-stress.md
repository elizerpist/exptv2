# Dashboard bootstrap, preview diagnostics and stress checklist

Frozen best baseline: `1430c50` (`feat(fluvi): render complete child previews during rail motion`).

Prior performance milestone: `c0754f4` (`milestone: preserve smooth rail and correct dashboard before live preview rendering`).

Feature branch: `feature/dashboard-bootstrap-frame-stress`.

This slice preserves the existing rail/query/LogBox behavior and adds proof,
cold-start gating and bounded-data instrumentation. No golden test is required.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BF-01 | User prompt §1 | Git history and frozen-surface audit | Work starts from `1430c50`; centered carousel and rail motion files are unchanged | `git show`, final diff allowlist | DONE |
| BF-02 | User prompt §3 | Presentation snapshot/diagnostics | `presentationMode` is independent from `dataOrigin` | Unit test with fresh-query data used as preview | DONE |
| BF-03 | User prompt §4–5 | Diagnostics ring buffer | Crossing → selection → publish events retain query key, generation, digest and bounded counters | Unit test and event invariant test | DONE |
| BF-04 | User prompt §4 | Frame diagnostics | Frame-presented events are end-of-frame coalesced without unbounded callbacks | Fake frame scheduler test | DONE |
| BF-05 | User prompt §6 | Current query/store | Late committed result may update cache but cannot overwrite a newer visible preview | Delayed-result regression test | DONE |
| BF-06 | User prompt §7–8 | `DashboardBootstrapController`, app shell | Core dashboard mounts only after a valid immutable initial snapshot is ready | Bootstrap phase and widget gate tests | DONE |
| BF-07 | User prompt §8 | Initial snapshot | First Dashboard frame has valid key, scope, direction, amount, count and rows/explicit empty; dash frame count is zero | First-frame test | DONE |
| BF-08 | User prompt §10–12 | Bundle/read model | Summary data is exact while preview rows remain bounded and empty children are explicit | Bundle budget and empty-bucket tests | DONE |
| BF-09 | User prompt §10 | Stress fixtures | Seeded 10k/50k/100k fixtures are deterministic and cover both directions, filters and zero buckets | Fixture unit tests | DONE |
| BF-10 | User prompt §15 | Cache instrumentation | Parent/bundle/row caches expose bounded row count, estimated bytes, hit and eviction counters | Cache stress test | DONE |
| BF-11 | User prompt §13–14 | Native/read diagnostics | Batch metrics expose SQL/mapping/payload/decode/projection timing without hot-path string logging | Typed boundary model and unit test; native execution unavailable locally | PARTIAL |
| BF-12 | User prompt §16–18 | Lease/stress diagnostics | Overlapped lease/read counts and crossing-to-publish timing are measured; lease timing is unchanged unless evidence requires it | Preview counters and frame diagnostics; physical lease-overlap/profile measurement unavailable locally | PARTIAL |
| BF-13 | User prompt §19 | Regression suite | Bootstrap, no-dash, frame coalescing, late-result, zero-I/O, bounded rows, eviction, revision/direction and identity tests pass | Ubuntu/proot non-golden test suite | DONE |
| BF-14 | User workflow | Delivery | After all requirements are green: one final commit, one push, one online build, APK downloaded to `/storage/emulated/0/Download`; no local APK build | GitHub Actions and file/hash check | NOT DONE |

## Frozen surfaces

- `lib/shared/motion/centered_carousel/` physics, simulation and controller.
- `lib/features/dashboard/widgets/time_refinement_rail.dart` motion adapter.
- Dashboard item extent, velocity mapping, cyclic mapping, snap and haptics.
- Existing amount/count calculation and LogBox visual design.
- No verbose per-frame FLOW string assembly in profile/hot paths.

## Known evidence limits

Physical device frame timings, RSS, GC and raster p95/p99 cannot be invented.
If the connected CI/device profile runner is unavailable, those acceptance
items remain explicitly `BLOCKED` or `PARTIAL` in the final report.
