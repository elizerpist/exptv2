# 339bfc3 day-rail scene coverage — acceptance checklist

Base: `339bfc3459826319504e249c3a4d8d44012004af`
Working branch: `fix/day-rail-scene-coverage-rebase`

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SCN-01 | §3–8 | scene-window lifecycle | Prove and close the settled-anchor/active-coverage gap that leaves April day viewport scenes absent. | Controller lifecycle regression | DONE |
| SCN-02 | §9–13 | `DashboardCoreController` | A child settle schedules at most one bounded scene-window rebase outside the settle callback, pointer, crossing and paint paths. | Coordinator spy + hot-path counters | DONE |
| SCN-03 | §14–20 | coverage identity | Coverage keys only include index/revision and visible year/month inputs that alter required scene payloads; day settles in one month skip rebase. | Identity/no-op test | DONE |
| SCN-04 | §21–28 | serialized coordinator | One preparation runs at a time; the latest desired coverage wins and stale completion cannot activate. | Delayed preparer regression | DONE |
| SCN-05 | §29–32 | prepared scene cache | Every next-finer rail entry, including an empty payload, has a complete scene before lookup. | April day catalog test | DONE |
| SCN-06 | §34–36 | diagnostics | Transition-only rebase events and physical report expose active/desired coverage, generation, queue, duration and cache sizes. | Diagnostics/report test | DONE |
| SCN-07 | §37–46 | temporal regression | July→April/February, December→January and SUM→YEAR all supply next-finer catalog coverage with zero critical/text misses. | Core integration tests | DONE |
| SCN-08 | §47–49 | frozen vertical/data scale | Existing vertical 94/658/1000 and bounded large-data behavior remains unchanged. | Existing regression/scale suite | DONE |
| SCN-09 | §50–55 | performance freeze | Rail hot path remains lookup-only; rail/physics, paging, render extent and SummaryPill frozen paths have no diff. | Source diff + SHA audit | DONE |
| SCN-10 | §63 | verification | Focused and full non-golden Flutter suite plus analysis pass; no golden is added. | Ubuntu/proot commands | DONE |
| SCN-11 | §56–57 | delivery | Normal-app HUMAN_DIAGNOSTIC profile APK is built, downloaded, hash- and ZIP-verified. | GitHub Actions + local artifact checks | PARTIAL |
| SCN-12 | §65 | physical validation | User validates April 12 populated and empty day behavior on device. | User physical capture | BLOCKED |

## Architecture card

- **Existing owner extended:** `DashboardCoreController` remains the sole owner of scene-window coordination. No renderer, rail or paging owner is added.
- **Write path:** child settle updates the authoritative navigation temporal anchor synchronously; the core controller then queues one post-settle coverage request. The existing preparer stages a complete window and atomically activates it.
- **Coverage source:** `renderCriticalLogBoxSceneWindowFor(navigation.state)` remains the canonical selector. A small immutable coverage identity prevents redundant day-within-month preparation.
- **UI boundary:** the painter continues to perform only `sceneFor` lookup. A missing rail scene remains a hard diagnostic, never a paint-time fallback.
- **Evidence:** red/green lifecycle tests cover populated and empty day scenes, rapid latest-wins coalescing, day no-op settling and temporal boundaries; frozen-path audit and normal human APK deliver the final evidence.

## Verification record

- Focused lifecycle suite: `dashboard_scene_window_rotation_test.dart` — 11/11 PASS.
- Full non-golden suite: 365/365 PASS.
- `flutter analyze`: `No issues found`.
- Frozen-path audit against `339bfc3459826319504e249c3a4d8d44012004af`: all listed rail, physics, paging, renderer, SummaryPill and visible-frame files have zero diff.
- Delivery and physical-device capture remain outstanding at this pre-commit checkpoint; the latter is intentionally not inferred from emulator or unit evidence.
