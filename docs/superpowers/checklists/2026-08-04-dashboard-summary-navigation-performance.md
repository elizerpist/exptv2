# Dashboard SummaryPill parent-navigation performance checklist

Baseline commit: `3dd650c225c24bc4382ceddd208ec35fae2a0e4f`.
Backup tag: `milestone/dashboard-rail-smoothness-3dd650c`.
Working branch: `feature/dashboard-summary-navigation-performance`.
Golden tests are explicitly excluded.

| ID | Source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| SNP-01 | User prompt §1–§4 | Summary navigation ownership | Month/year parent motion path and every state owner are documented before code changes | Architecture map and audit document | DONE |
| SNP-02 | User prompt §3.5–§3.6 | Parent navigation data path | Parent preview does not wait for repository, child deck parse, lease, prewarm, or full dashboard publish | Red month/year preview tests and counters | DONE |
| SNP-03 | User prompt §5–§7 | Presentation store/index | Parent preview uses the central store and O(1) exact parent snapshot lookup | Unit tests with parent index/cache hit | DONE |
| SNP-04 | User prompt §8–§10 | Parent motion coordinator | One preview per distinct parent crossing, one idle, one settle, final-only commit | Epoch tests for month/year tap/fling | DONE |
| SNP-05 | User prompt §9 | Parent/child cursor ownership | Parent navigation never commits an old child scope or mixes child cursor with target parent | Open/closed rail parent-navigation tests | DONE |
| SNP-06 | User prompt §11 | Bootstrap coordinator | First dashboard frame has exact parent snapshot, valid count/content and no dash | Existing bootstrap first-frame regression suite | DONE |
| SNP-07 | User prompt §12–§14 | Lease/prewarm integration | Parent and child motion cancel pending lease; active old results are cache-only; prewarm is motion-aware | Existing delayed lease/result/prewarm suite plus motion wiring | DONE |
| SNP-08 | User prompt §13 | Summary amount/count | Parent preview is direct/no-op; equal amount never starts a tween or broad notify | Existing amount policy suite plus parent preview tests | DONE |
| SNP-09 | User prompt §15–§16 | Widget rebuild boundaries | SummaryPill/Header/root/rail identities remain stable and parent preview is narrow | Existing widget boundary suite; no device counter run | PARTIAL |
| SNP-10 | User prompt §17–§18 | Diagnostics | Parent/child preview phases have compact typed counters without hot-path string flood | Diagnostic event tests | DONE |
| SNP-11 | User prompt §20–§21 | Stress/profile | 5k/20k/100k fixtures remain bounded; month/year parent motion and child motion have measurable profile evidence | Deterministic stress tests pass; device profile unavailable in Termux | PARTIAL |
| SNP-12 | User prompt §22, §25 | Delivery | One final commit, push, online CI/build and APK verification after implementation | CI run, artifact hash, final report | NOT DONE |

## Frozen invariants

- Do not change rail or SummaryPill physics, friction, simulation, velocity
  mapping, snap, item extent, cyclic mapping, gesture ownership, or controller
  ownership.
- Do not add a second UI truth source, query owner, or cache owner.
- Parent preview performs no repository/native/watch/paging I/O.
- Child preview continues to render every distinct semantic crossing available
  in separate display frames.
- Preview amount/count/content use direct immutable snapshot publication.
- The SummaryPill and LogBox viewport roots keep stable identity.
- No QueryKey-based root key, eager full list, hidden widget cache, or golden
  test is allowed.
