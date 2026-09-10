# Direction-circle repair evidence snapshot

This directory is the immutable evidence reader snapshot for the repair
cycle rooted at physically tested application source
`0b108b73e8e13b7a3bbd397dd9c98e8bb0db79aa`. The journal-bearing branch head
`d3795d54751a7cc64aa753b36520def70af9d424` changes only the prompt-writer
journal and is not a tested application build.

## Export provenance

| Document | Drive ID | Drive modified (UTC) | Raw export bytes | Raw SHA-256 | Local reader bytes / SHA-256 |
| --- | --- | --- | ---: | --- | --- |
| Fluvi logs avatar fling | `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs` | 2026-09-10T13:04:13.037Z | 592,797 | `de24763fd6570f7353bf148b9fe8868e83f3459c598bc663723384df2c00cc77` | 590,797 / `202f6d188d1e36e795ef64c527bc5fb825de0dc558f64bab47247b253811ada2` |
| Fluvi logs time fling | `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE` | 2026-09-10T13:05:44.435Z | 315,518 | `3e4f07bf8a8ef9c6fb0f419f30a9fc4cc9d5f2ce94e071b876afac80674876a2` | 314,519 / `1f067052f3548a9b1ac7c5ab6f2efb3045430779028b732bdab6e4888be1d0b0` |
| Fluvi budget bug | `1KCxfP-l4dKEDHwfdwMu7OttTUtUaqIeyA32ViPNUKxc` | 2026-09-10T13:06:29.051Z | 321,642 | `f73c15b94a0f0ac90001cff97e9287fbfc2b79e55b04a75319fc40aea35e538b` | 320,643 / `9c8fd2c6c74f1c5a5d5f4c972b92f2d5da9058c11e40c4838c0a7a291c1a1885` |

Export timestamp: 2026-09-10, during this repair preflight. The connector
returned the raw Drive export bytes; their sizes and hashes are the
authoritative export evidence. The checked-in readers use LF line endings
because the repository patch transport normalizes CRLF, hence their separate
size/hash is recorded rather than misrepresenting it as raw-byte identical.

All three exports identify session `fluvi-1789045402258792` and
`profile/0b108b73e8e1`.

## Retention audit

| Snapshot | LIVE_TAIL retained sequence range(s) | Unique / duplicate audit | Session count and eviction |
| --- | --- | --- | --- |
| Avatar | 9118–10117 and 9121–10120; union 9118–10120 | 1,003 unique; 997 overlapping duplicate sequence records, all content-identical; no differing duplicate | 10,120 events; 1,837 evicted in the second tail |
| Time | 11663–12662 | 1,000 unique; no internal duplicate or gap | 12,662 events; 4,379 evicted |
| Budget | 11690–12689 | 1,000 unique; no internal duplicate or gap | 12,689 events; 4,406 evicted |

The Time/Budget overlap 11690–12662 is content-identical. There is a hard
session retention gap of 1,542 sequence numbers, 10121–11662; no causal chain
in this repair crosses it. `USER_MARK` and `USER_MARK_RETAINED_*` entries are
observation/mirroring records, not causal runtime mechanism evidence.

## Anomaly closure ledger

| Event family | Representative retained sequences | Classification | Source/test evidence | Action |
| --- | --- | --- | --- | --- |
| Direction circle identity mismatch | Avatar 9139→9148→9150→9173→9182 | PROVEN-HARMFUL — REPAIRED | Per-direction `_selectedIdentityByDirection` retained target 4 while rail `_replaceItems` retained physical aggregate stable ID 0; artwork guard correctly suppressed mismatched chrome | Direction-domain replacement now rebases physical rail to presentation's remembered direction target; real rail/presentation/artwork regression and strengthened G profile gate |
| Background exact-local hotset rejection and resource deferral | Avatar 9193/4, 9373/4, 9438/9, 9514/5, 9524/5, 9780/1, 9846/7, 10052/3 | PROVEN-EXPECTED — NO CHANGE | All have `targetHandle=-`, `interactionEpoch=0`, and `pendingHotsetPlans=8`; Core only makes the resource a dependency when an exact current candidate exists. Final flights 9/10 have accepted exact publications and no pending paint | Preserved foreground/current-target guard; no Avatar production change |
| Stale vertical page commit | Avatar 9191, 9371, 10047; Budget 12465 | PROVEN-EXPECTED — NO CHANGE | Paging request-generation/scope guards reject `staleRequest`; later current pages commit, e.g. Budget 12615/12629 | Existing stale-page tests cover structural supersession; no page change |
| Ready-ahead deferred | Avatar 9304, 9653, 9775, 9969, 10049; Time/Budget 12297, 12595 | PROVEN-EXPECTED — NO CHANGE | Idle-prewarm is deferred when `motionActive=true`; controller retains deferred intent and later commits pages (Budget 12602–12631) | Existing bounded ready-ahead tests; no foreground work moved into motion |
| Scene slice over budget | Avatar includes 10039 (7,040 µs); Time/Budget representative 11668/9, 12457/8, 12535/6, 12604/5 | PROVEN-EXPECTED — NO CHANGE | Scene cache reports post-slice measurements, then checkpoints/yields. Completion records expose yields and no semantic/raster work; final Avatar summary has zero per-tick repository/index/scene/canonical work | Preserve cooperative checkpoint architecture; a measured atomic slice alone is not a surviving interaction defect |
| Candidate scene retention rejection | Time/Budget 12117, 12477, 12545, 12624, 12648, 12653 | PROVEN-EXPECTED — NO CHANGE | `retainedUniqueRows` 2,458/2,464 exceeds hard `maxRows=2,048`, while optional Phase-B retention is explicitly non-authoritative; Phase-A remains publishable | Existing candidate-bound and reentrant-preview tests; no cache expansion |
| Time Phase-A candidate pending | 11667, 11708, 11750, 11791, 11970, 12010, 12198, 12242, 12302, 12368, 12405 | PROVEN-EXPECTED — NO CHANGE | The latest-wins foreground resource lane explicitly retains the prior exact visual while it acquires the candidate. Each retained current candidate has a terminal/bound outcome; sampled final flows have `liveRootMisses=0` and exact paint | Preserve Phase-A liveness; do not turn a bounded pending resource state into a Time-physics change |
| Optional rich-scene unavailable | Time/Budget 11831, 12340 | PROVEN-EXPECTED — NO CHANGE | Both records explicitly state `phaseAReady=true richPhaseBOptional=true`; current source retains the valid scene/Phase-A authority and refuses a non-empty fallback | Existing Phase-A-without-rich-scene tests; no rendering fallback or cache change |
| Speculative scene preparation cancelled | Time/Budget 12169 | PROVEN-EXPECTED — NO CHANGE | Owner is `speculativeMaintenance`, priority 1; the cache releases only its managed staging bank and rethrows cancellation, while foreground Phase-A publication remains separate | Preserve cancellation and resource cleanup; no foreground work is promoted |
| Time final-summary duplicate | Time/Budget 11863+11954 (flow 5), 12056+12182 (flow 6) | DIAGNOSTIC DEFECT — REPAIRED | Summary was emitted before promotion; stale duplicate release then failed and had a conflicting `canonicalSettleCommits=0` summary | Emit `TM|FLIGHT_SUMMARY` only after promotion/restore succeeds; stale rejection remains observable |
| Direct Time settle/paint stale rejection | 11955, 12183, 12443, 12526 | PROVEN-EXPECTED — NO CHANGE | Exact generation/query/presentation/frame/viewport guards reject superseded reports. At 12526 an Expense expected paint arrives after Income frame 493 is live | Kept guards; the summary lifecycle fix suppresses only the contradictory duplicate summary, not these guard events |
| Mirrored older Time stale rejection | Original 10935, retained only through 12657/12666/12675 | MISSING EVIDENCE | The original event is inside the hard retention gap; its later `USER_MARK_RETAINED_EXCEPTIONAL_OUTCOME` mirror carries no causal predecessor/successor | Capture a trace retaining the original 10935 vicinity before attributing a production mechanism |
| User observations other than unresolved markers | Avatar 10117 `avatar_fling`; Time/Budget 12662 `time_fling`; Budget 12671/12689 `budget_limit` | PROVEN-EXPECTED — NO CHANGE | `USER_MARK` is an observation marker only. The first two accompany physically accepted behavior; the direction-circle mechanism is classified separately from the `budget_limit` markers by its retained source events | No production action is inferred from a marker alone |
| Mind live-list marker | Budget 12680 | MISSING EVIDENCE | Only `USER_MARK issue=mind_slider_no_live_list` is retained; no `MIND|DRAG_START`, `MIND|PREVIEW_FRAME`, `MIND|LIVE_ROOT_MISS`, or slider summary accompanies it | No production change. Existing bounded Mind pipeline emits these identities; next reproducer must hold a real RangeSlider drag and capture start → preview frame → exact LogBox paint → slider summary |
| Avatar filter marker | Avatar 10120 | MISSING EVIDENCE | A `USER_MARK` follows a retained healthy final Avatar flight; there is no corresponding filter interaction in the retained window | No production change; reproduce one filter action with its input/query/live/painter sequence retained |

The tested current graph is unavailable: tooling `d985950733ea760c454218d497172893a13c4e95`
indexes `33ee878b070345c336bb73df2b087d9a63c87c5a`, not `0b108b73…`.
It was not used as runtime or current-source proof.
