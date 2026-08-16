# Query publication reservation and hotset-promotion acceptance checklist

## Architecture card

### Scope and sources

- User requirement: the 2026-08-16 continuation prompt, Anomaly A and Anomaly B.
- Protected baseline: `ef651f087c3e49af0efe4a24476dd608ea65c925`.
- Existing implementation: `lib/features/dashboard/application/dashboard_core_controller.dart` and `lib/features/dashboard/application/prepared_query_candidate.dart`.
- Existing data/paging owners: `DashboardDataRuntime`, `PreparedDashboardIndexBuilder`, and `ExplicitCommittedPagingController`.

### Single source and write path

- Publication/readiness priority owner: `DashboardCoreController._committedReadyAheadPriority`.
- Query candidate operation owner: `DashboardCoreController._activeQueryCandidatePreparation`.
- Native prepared-index lane: `DashboardDataRuntime` / `PreparedDashboardIndexBuilder`.
- Candidate data cache and scene-cache lease owners remain the existing controller LRU and `DashboardLogBoxPreparedSceneCache`.
- UI only forwards Query/gesture intent; it does not acquire repository data or own scheduler state.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Publication reservation | `DashboardCoreController` committed-ready priority scope | one immutable Query Apply | gates speculation before structural side effects; binds only to the matching committed paging metadata |
| Exact ready-ahead binding | same scope + `ExplicitCommittedPagingController` metadata | current committed scope | settles before rail/Summary/Query-chip speculation resumes |
| In-flight candidate operation | `DashboardCoreController` active candidate preparation | one immutable candidate key | one native acquisition; same-target foreground intent promotes ownership |
| Native builder token | `PreparedDashboardIndexBuilder` | one prepare operation | only genuinely superseded candidate identities are cancelled |

### Layer flow

Query UI intent → `DashboardCoreController` → `DashboardDataRuntime` / `ExplicitCommittedPagingController` → repository / scene-cache capability.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QPR-01 | User Anomaly A phase 1 | `dashboard_core_controller.dart` | Direct and sheet Query publications reserve the existing readiness owner before every structural side effect. | RED/GREEN controller ordering tests | DONE |
| QPR-02 | User Anomaly A phase 2 | same | The same reservation binds only after exact new paging metadata (`queryKey`, revision, generation) exists. | focused binding/terminal/multi-page tests | DONE |
| QPR-03 | User Anomaly A | same | Query-chip, rail and Summary starts are gated during reservation, including callbacks scheduled before it. | real/test scene-owner diagnostic ordering test | DONE |
| QPR-04 | User Anomaly A | same | Stale/superseded/failing Apply releases only its own reservation and leaves the old visible dashboard authoritative on failure. | supersede/failure tests | DONE |
| QPR-05 | User Anomaly A | same | Sheet reverse-transition ownership and controller/physics/geometry identities remain unchanged. | route, paging, viewport and scroll regressions | DONE |
| QHP-01 | User Anomaly B | controller + `prepared_query_candidate.dart` | One candidate cache identity has at most one native/index acquisition. | controllable repository RED/GREEN test | DONE |
| QHP-02 | User Anomaly B | same | Exact in-flight hotset work transfers to foreground without a same-target cancel/restart and publishes once. | diagnostic/count/scene-retention test | DONE |
| QHP-03 | User Anomaly B | same | Data-ready/scene-preparing operation is adopted without a second index build. | controllable scene-preparation test | DONE |
| QHP-04 | User Anomaly B | same | Different targets still supersede correctly; stale hotset continuation cannot cache, activate or publish. | different-target/stale/repeated-removal tests | DONE |
| QHP-05 | User Anomaly B | same | Capacity, clear-all hotset membership, directional independence and Query Menu Apply/Cancel behavior are unchanged. | existing candidate/capacity/directional regressions | DONE |
| QAR-01 | Global architecture gate | boundary tests + direct inspection | No new repository/paging/cache owner or presentation-layer workflow; only existing controller and runtime owners are extended. | existing boundary suite + source inspection | DONE |
| QVR-01 | User automated acceptance | targeted Flutter suites, fast suite, analyzer | All mandated regression suites and static analysis are green without weakening tests. | Ubuntu-proot test/analyze output | DONE |
| QDL-01 | Global delivery | GitHub Actions / `/storage/emulated/0/Download/fluvi` | Each pushed application-code commit receives a successful normal human APK download and checksum. | exact-SHA Actions job + local SHA-256 | NOT DONE |
| QPH-01 | User physical acceptance | normal `lib/main.dart` human APK | New ordering and same-target promotion are compared against `ef651f0` on device; automated results are not called physical validation. | human Android trace | NOT DONE |

## Commit 1 verification record

- RED reproduced on `ef651f0`: a direct prepared-hit publication admitted
  `SUMMARY_PARENT_HOTSET_PREPARE_STARTED` between publication start and
  committed-ready-ahead satisfaction.
- GREEN coverage: real scene-owner callback, held render-scheduled rail
  callback, prepared-miss fallback, zero-page, one-page, five-page
  ready-ahead, structural supersede, activation failure, and the existing
  Query-sheet reverse-transition regression.
- Fresh automated evidence before Commit 1: Query application 38/38,
  scene-window rotation 32/32, paging/viewport/scene-cache/geometry 80/80,
  selected architecture boundaries 11/11, and `flutter analyze` with no
  issues.

## Commit 2 TDD target

- First RED case: hold one admitted Query-chip hotset index acquisition for
  exact candidate X, issue foreground Apply for X, then prove that baseline
  behavior cancels/restarts X while the target behavior has exactly one
  acquisition, no X cancellation, one retained exact scene and one publish.

## Commit 2 verification record

- RED reproduced on Commit 1 / starting HEAD: the controllable exact hotset
  candidate X received two Query index acquisitions after foreground chip
  intent (`Expected: <1>; Actual: <2>`).
- GREEN coverage: exact in-flight index promotion; data-ready but
  scene-preparing promotion; vertical pointer protection of a promoted scene;
  different-target cancellation; stale promoted continuation rejection; and
  rapid distinct chip removals.
- Fresh automated evidence: Query application 43/43; requested
  scene/paging/viewport/scene-cache/vertical-geometry group 97/97;
  `./scripts/test-fluvi-fast.sh` 218/218; `flutter analyze` with no issues;
  and `./scripts/verify-fluvi-boundaries.sh` passed.
- Ownership review: the controller still owns the one in-flight candidate and
  its existing LRU policy; `DashboardDataRuntime` still owns the one native
  prepared-index builder lane; `DashboardLogBoxPreparedSceneCache` still owns
  scene leases. No new cache, scheduler, repository path, paging owner, or UI
  workflow was introduced.
