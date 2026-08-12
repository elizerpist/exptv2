# Committed vertical paging performance checklist

Source: user task request of 2026-08-13 for `query` at `07b879d`.

| ID | Requirement / source | Intended owner / area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| VPG-01 | Slim committed page reads; no per-page aggregate/catalog rereads | `FluviLedgerReadService`, Android adapter, page request/codec | A bounded cursor page uses authoritative committed totals and maps only its rows | Kotlin tests + source inspection | PARTIAL — Dart tests and Kotlin compilation are green; the Robolectric execution is blocked locally by AAPT2 daemon startup. |
| VPG-02 | Temporal page predicates must preserve semantics without `strftime` on epoch day | `FluviLedgerReadService` predicate builder | Year/month/day selections compile to half-open epoch-day ranges, preserving OR-within / AND-across groups | Kotlin predicate and page-equivalence tests | PARTIAL — implementation and Kotlin compilation complete; Robolectric execution awaits online verification. |
| VPG-03 | Keep exact committed identity and revision validation | Dart request, native adapter, binary page codec | Stale revision/query/generation cannot publish and authoritative metadata matches response | Dart/Kotlin codec tests | PARTIAL — Dart codec/controller tests green; native execution awaits online verification. |
| VPG-04 | Deferred forward demand cannot be lost by temporary motion | Paging controller lifecycle | Motion defers exact demand and resumes it automatically when idle; stale demand does not resume | Controller lifecycle tests | NOT DONE |
| VPG-05 | Latency-aware bounded sequential lookahead | Pure demand planner / viewport session | Minimum two-page safety rises only within retention/last-page bounds using latency and scroll consumption; cursor loads stay sequential | Planner tests + controller tests | NOT DONE |
| VPG-06 | Atomic, cooperative committed-page text preparation | `CommittedLogViewportCache` | Partial layouts remain private; bounded yielding work commits atomically; supersede/width/dispose releases partial resources | Cache tests | NOT DONE |
| VPG-07 | Preserve ownership and hot-path invariants | Existing controllers/caches/render surface | No rail/cache-owner/physics changes, no render-time TextPainter, no dependent page parallelism | Code review + regression suite | NOT DONE |
| VPG-08 | Device acceptance and APK | GitHub Actions normal `lib/main.dart` APK | Manual 388-row scroll trace confirms first demand/resume and no misses/jank; APK downloaded to `/storage/emulated/0/Download` | Online build + manual physical test | PARTIAL |

Architecture card:

- `ExplicitCommittedPagingController` owns exact sequential keyset acquisition.
- `CommittedLogViewportCache` owns page data/presentation lifetime and atomic drawable publication.
- `DashboardLogBoxViewport` derives scroll demand only; it owns neither I/O nor page cache.
- Android `FluviLedgerReadService` remains the bounded SQL/row-mapping owner; Room remains source of truth.
- The existing rail scene preparation scheduler may be reused only through a neutral shared primitive; rail bank ownership remains separate.
