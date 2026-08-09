# Interrupted rail reconciliation and vertical takeover

**Source:** user-approved `FLUVI — INTERRUPTED RAIL RECONCILIATION +
FIRST-GESTURE CROSS-AXIS TAKEOVER FIX` specification, 2026-08-09.

**Base:** `0f47fd2fbb6f218ec8a2076b3ead226894c23d77`.

This change intentionally leaves the rail-critical scene bank, prepared
revision bundle, scene-window cancellation model, rail physics, and committed
vertical paging algorithm unchanged. It only corrects motion/presentation
ownership at two structural boundaries.

## Acceptance checklist

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| R1 | §2–5, interrupted close/reopen | centered carousel + motion kernel | Explicit preserve/reconcile install policy; reconcile silently stops stale motion and synchronously centers the canonical child. | RED/GREEN controller and carousel tests | DONE |
| R2 | §2–5, identity and no synthetic events | centered carousel | Reconcile preserves controller, position, and physics identity; emits no start, preview, settle, or haptic. | widget/unit test with callback counts and identities | DONE |
| R3 | §4–6, canonical rail state | presentation controller + rail widget | After a close/reopen or other structural reconcile, Summary/query/motion/physical center agree; late interrupted settle cannot win. | controller integration test and baseline synchronization test | DONE |
| R4 | §7, §13, stale versus fresh distinction | LogBox viewport | Old queued activity remains rejected, while a fresh current-scope pointer is not rejected merely because its frame was preview. | focused widget test | DONE |
| R5 | §8–12, cross-axis ownership | core + presentation + navigation | Pointer-down synchronously takes over the current valid rail preview: rail idle, child retained, same frame committed, page-zero metadata ready before ScrollStart. | exact one-pointer dense-2025 regression test | DONE |
| R6 | §10, no fake settle | time navigation | Settled retention and vertical takeover share one canonical child-anchor operation with an explicit reason; takeover emits neither haptic nor settled callback. | navigation/controller test | DONE |
| R7 | §14, diagnostics | diagnostics/counters | Reconciliation and preview takeover are recorded; center mismatch and fresh-gesture rejection counters are zero in accepted paths. | focused tests and final diagnostic evidence | PARTIAL |
| R8 | §15–21, targeted test ownership | existing motion/presentation tests | Tests reproduce both defects before runtime code and retain preserve-continuity behavior as a separate contract. | recorded RED then GREEN test output | DONE |
| R9 | §22, test audit | `docs/dashboard-test-coverage-audit.md` | I16 and I17 each have exactly one primary owner; no duplicate regression suite is added. | document review | DONE |
| R10 | §23–24, frozen architecture | dashboard runtime | No changes to RailCriticalSceneBank, scene atomicity, physics, paging, seed, dimensions, or performance thresholds. | diff audit | DONE |
| R11 | §25–32, delivery | CI + GitHub artifact | Targeted/fast verification, one final A–J profile without threshold changes, and normal `lib/main.dart` HUMAN diagnostic APK. Physical validation remains user-owned. | CI runs, SHA-256, user status | NOT DONE |

## State ownership

```text
rail open parent/direction change  -> preservePhysicalContinuity
rail close/reopen/plane/revision   -> reconcileCanonicalSelection

fresh LogBox pointer on preview    -> synchronous vertical takeover
old queued vertical activity       -> stale rejection
```

The two rails remain independent from scene preparation: rail visual
availability stays owned by `RailCriticalSceneBank`; this work changes only
semantic center and cross-axis input ownership.
