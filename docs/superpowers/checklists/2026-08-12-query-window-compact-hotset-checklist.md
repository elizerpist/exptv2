# Query Physical Window, Compact Assembly, and Chip Hotset Checklist

## Architecture card

| State | Existing owner | Intended change | Publication rule |
| --- | --- | --- | --- |
| Query candidate physical bounds | `DashboardCoreController` / active `PreparedDashboardIndex` | derive one exact start/end descriptor from the active prepared index | never derive from visible temporal anchor |
| Compact prepared-index data | `DashboardDataRuntime` / `PreparedDashboardIndex` | retain deterministic navigation semantics without eagerly allocating rich zero-frame presentation state | navigation stays RAM-only; visible scopes still require prepared scene coverage |
| Chip-removal candidates | `DashboardCoreController` candidate LRU | protect the active applied query's exact one-step chip neighbors | active index is not counted as speculative candidate capacity |
| Candidate scenes/layouts | `DashboardLogBoxPreparedSceneCache` | retain complete hotset banks with unique-resource accounting | only atomically activated banks can render |

## Acceptance checklist

| ID | Source requirement | Code area | Acceptance | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QW-01 | Physical Query window is independent of visible year | core candidate requests/cache keys | draft, Apply and chip prewarm use active index start/end bounds | controller/runtime RED→GREEN tests | DONE |
| QW-02 | Expense-only change reuses Income after temporal navigation | core/runtime request composition | identical active physical bounds preserve `built=expense`, `reused=income` | directional reuse regression test | DONE |
| QC-01 | Compact decode diagnoses actual assembly cost | codec/runtime worker | granular zero-universe and worker-wall metrics are emitted | heavy codec fixture | DONE |
| QC-02 | Compact decode does not eagerly create rich zero state | domain index/codec/scene preparation | deterministic zero state is compact; exact visible window materializes before scene readiness | heavy fixture plus scene-window test | DONE |
| QH-01 | Every active chip X has an exact retained candidate | core candidate LRU | five removals plus clear-all coexist; active index consumes no speculative slot | controller hotset test | DONE |
| QH-02 | Candidate scene budget counts shared resources once | prepared scene cache | resource/byte accounting deduplicates shared layouts and evicts non-hotset first | cache ownership test | DONE |
| QH-03 | Identity/revision/foreground priority remain correct | core/cache | temporal navigation within active window retains hits; revision invalidates; unfinished speculation can cancel | controller/cache tests | DONE |
| QP-01 | Protected dashboard behavior remains intact | dashboard core/scene/paging/query model | no rail physics, paging, direction-independence, or fail-closed regression | focused suite: 108 tests; `flutter analyze` | DONE |
| QP-02 | Delivery | CI/release/download | one final GitHub APK only after code/test verification | Actions run and downloaded APK checksum | PARTIAL — pending online build |

## Scope constraints

- No rail physics, controller/ScrollPosition identity, paging or Query sheet
  lifecycle redesign.
- No render-time TextPainter, formatting, SQL, MethodChannel, sorting or
  uncontrolled materialization.
- No new prepared-index, Query candidate, or scene-cache owner.
- No golden tests or human-APK automation harness.
