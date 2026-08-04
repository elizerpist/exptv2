# Dashboard live preview bundle acceptance checklist

Baseline: `561fe924112f15565b24947cf070d982416d9f56` (`561fe92`)

Milestone commit: `c0754f4` — `milestone: preserve smooth rail and correct dashboard before live preview rendering`

Feature branch: `feature/dashboard-live-preview-bundle`

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| B-01 | User prompt §0 | Git history | Baseline remains unchanged and work starts from `561fe92` | `git show`, branch ancestry | DONE |
| B-02 | User prompt §2 | `docs/dashboard/rail-live-preview-root-cause.md` | D11 → visible-publish and first-open paths are traced to their source | Direct code audit plus document review | DONE |
| B-03 | User prompt §4–6 | `lib/features/dashboard/query/data/dashboard_child_preview_bundle.dart` | Immutable data-only bundle has exact parent, child-period, revision, key and preview-page identity | Unit tests | DONE |
| B-04 | User prompt §5, §6 | Flutter repository adapter and native query service | MONTH/YEAR/SUM bundle projection is batch-based, revision/direction guarded and bounded | Dart bridge tests; native tests in CI | PARTIAL — MONTH/YEAR are batch-projected and guarded; SUM remains sparse actual-year projection and needs device/CI verification |
| B-05 | User prompt §7 | `DashboardSummaryMetricsController`, `DashboardPresentationStore` | First mother → child open resolves a complete child snapshot synchronously from the prepared bundle | Regression test; first-open/read/watch counters | DONE |
| B-06 | User prompt §9–12 | Rail callback and summary presentation lane | Every semantic crossing uses the same full snapshot publish path; amount/count/LogBox change together | Intermediate sequence and full-publish regression test | DONE |
| B-07 | User prompt §10 | Rail presentation adapter | No trailing debounce or settle-only gate suppresses distinct-frame preview crossings | Event-path audit and crossing sequence test | DONE |
| B-08 | User prompt §13 | Summary/store promotion | Settle promotes an identical preview without a second visual publish, list rebind or amount animation | Settle visual no-op test | DONE |
| B-09 | User prompt §14–15 | Tap/fling adapter | Single tap and fling crossing call the same preview API and remain interruptible | Shared `_queuePreview` path audit | DONE |
| B-10 | User prompt §16–19 | LogBox adapter/viewport | Preview state is complete, old rows never leak, viewport identity remains stable and no preview I/O occurs | Mixed empty/populated, identity and I/O tests | DONE |
| B-11 | User prompt §19–21 | Centered carousel and dashboard rail | Physics, controller, ScrollPosition, crossing sequence and final target match baseline | No physics/time-rail diff; existing carousel suite | PARTIAL — identity/crossing tests pass; physical profile comparison remains pending |
| B-12 | User prompt §17.11–17.13 | Bundle cache | Empty buckets are explicit where finite, stale revisions/directions are rejected | Bundle model, bridge, native completeness tests | PARTIAL — Dart tests pass; native tests await CI because Java is unavailable locally |
| B-13 | User prompt §17.14 | Dashboard motion/presentation lanes | Preview publish latency is at most one frame without row-count-proportional rail cost | Logger-off profile benchmark | BLOCKED — no Java/device profile runner is available in this Termux session |
| B-14 | User workflow | Delivery | All non-golden tests and analyze pass; one final push triggers one online build; APK is downloaded to `/storage/emulated/0/Download` | Local Ubuntu/proot tests, CI, file check | NOT DONE |

## Explicit frozen surfaces

- `CenteredCarouselController` physics, simulation, velocity mapping, item extent, snap and gesture ownership.
- Existing amount/count calculations and parent/child query-key construction.
- Existing LogBox visual layout, design tokens and stable viewport identity.
- No golden tests and no local APK build.
