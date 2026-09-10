# Avatar-only correctness-preserving fling pacing — acceptance checklist

Authoritative sources: the 2026-09-09 physical-feedback instruction in the
Codex thread, the current Drive document `Fluvi logs avatar fling`
(`1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`), and the frozen recovery
snapshot at
`docs/superpowers/evidence/2026-09-09-avatar-fling-pacing/drive-fluvi-logs-avatar-fling-1FF1BnHJ-20260909T201350Z.txt`.

Tested physical source: `33ee878b070345c336bb73df2b087d9a63c87c5a` on
`fix/avatar-target-liveness-codex-20260909`; its parent is
`6adeb42c90f9bef91532c4fe74f37404634ad250`. The matching code graph is
currently unavailable: **GRAPH STALE FOR TESTED HEAD**.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| PAC-01 | Physical feedback §§2–5; Drive log | Evidence/forensics | The exact physical build, one-session retained range, duplicate snapshots, retention gaps, export metadata and frozen hash are recorded without merging sessions. | Drive metadata/text read; byte/hash and per-sequence audit | DONE |
| PAC-02 | Physical feedback §§1,4,13–14 | Existing Avatar publication path | Every surviving non-empty final target remains physical = desired = accepted = painted = Budget/Header/progress/LogBox = canonical. | Persistent production composition; final-target assertions | PARTIAL |
| PAC-03 | Physical feedback §§1,11–12 | Protected carousel/motion ownership | Preserve the `e8b73e3…` Avatar-motion architecture; do not change physics, controller, ScrollPosition, geometry, Time, Mind, visual layout, cache/store/controller identity or add a second authority. | Protected-path diff and boundary suite | PARTIAL |
| PAC-04 | Physical feedback §§5,8–10,15 | Diagnostic pipeline | Identify the first materially variable latency boundary for the physical session. Do not promote correlation to causality. | Deduplicated target timeline plus bounded instrumentation | PARTIAL |
| PAC-05 | Physical feedback §10, §13 | Real CoreDashboard composition | A deterministic persistent production-parent reproducer uses nine non-empty targets, cold/warm/mixed resources, supersession and 20 forward/reverse cycles. | Red/green Flutter composition test | DONE |
| PAC-06 | Physical feedback §15 | Existing Avatar diagnostic owners | Capture per-target physical/semantic/resource/publication/paint/canonical timing and FrameTiming distributions without diagnostic-created stalls. | Focused report/test and diagnostic-overhead review | PARTIAL |
| PAC-07 | Physical feedback §10 | Proven first boundary only | A red cadence/performance gate distinguishes physical cadence, semantic delay, synchronous work, rendering misses and asynchronous readiness. | Deterministic failing test/profile before repair | NOT DONE |
| PAC-08 | Physical feedback §§10,14,16 | Existing responsible owner | Make the smallest root-cause repair; retain latest-wins, stale rejection, one pending candidate and existing resource lane. | Focused correctness and pacing tests | NOT DONE |
| PAC-09 | Physical feedback §§13,15 | Avatar final-state surfaces | No earlier target, empty-only outcome, dropped publication or settle-only workaround may satisfy the final gate. | Final target, endpoint, aggregate and stale-completion cases | NOT DONE |
| PAC-10 | Physical feedback §§15,17 | Test/profile evidence | Compare per-target distributions and worst cases against the protected e8 architecture; separately report inherited/environment failures. | Local Ubuntu-proot tests, actual profile JSON | NOT DONE |
| PAC-11 | Physical feedback §§18–20; global AGENTS.md | Documentation/delivery | Commit only verified, atomic work; push exact application SHA; CI, normal human APK, matching SCIP and honest report all identify the same source SHA. | GitHub Actions/artifacts, APK hash, graph manifest | NOT DONE |
| PAC-12 | Physical feedback §4, §20 | Human validation | Automated results never substitute for device acceptance. | Final report says `PHYSICAL VALIDATION PENDING — USER ONLY` | NOT DONE |

## Current forensic boundary

The frozen physical session proves restored publication and uneven pacing, but
does not yet prove the owner of the delay. Its direct tick counters report zero
repository requests, index builds, scene preparations and canonical commits;
therefore none of those may be blamed without a deterministic causal trace.
The observed post-settle foreground scene preparation is explicitly excluded
from the in-flight root cause until a timing correlation shows otherwise.

## 2026-09-10 checkpoint

- The new production-composition requirement was RED on this worktree: both
  renderer duration fields were absent. It is GREEN after the existing
  correlation, render-phase probe and selected chrome acknowledgement were
  extended; no motion/publication owner changed.
- The retained, real `persistent20cycles` composition test completed in
  Ubuntu proot in 69 seconds (`+1: All tests passed`). It performs 20 forward
  and 20 reverse flights and asserts final exactness, paint identity, bounded
  resources and carousel/position/physics identity.
- PAC-02/PAC-03 remain partial because those local checks cannot establish the
  requested Android physical cadence. PAC-04/PAC-06 remain partial because a
  fresh physical capture with the new per-target timings is still required.
- Full source audit and evidence are recorded in
  `docs/superpowers/forensics/2026-09-10-avatar-fling-pacing.md`.
