# Budget V2 avatar belt recovery — acceptance checklist

## Scope and evidence

- Product surface: Balance dashboard, Budget V2 avatar rail.
- User source: the 2026-07-29/30 conversation and supplied device traces.
- Visual evidence inspected: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.
- Diagnostic evidence: V2 rail logs show an input can be followed by a delayed
  filter publish and a `BalanceTrace balance-frame-resolve` of up to 505 ms.
- Non-goal: redesigning the visual language or changing the shared TransactionStore
  category-filter semantics.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BELT-001 | User: every selection must remain swipeable; no cooldown | `spendee_budget_v2_avatar_carousel.dart` | Pointer contact immediately stops an in-flight rail tween and the next horizontal drag is accepted without waiting for the prior step or filter debounce. A dragless contact still settles the original external request. | Widget regression tests; post-build device trace remains required. | PARTIAL |
| BELT-002 | User: a real belt, not a delayed/out-of-sync carousel | Avatar rail state coordination | Local drag state, settled rail state, and dashboard filter commit have one-way ownership. A host acknowledgement must not start a second `source=step` animation. | Widget regression test with a parent rebuild during direct drag. | DONE |
| BELT-003 | User: avatar centered with a few pixels of ring padding; no visual offset | V2 avatar/ring layout | Existing square ring and centred avatar geometry remains fixed while the belt moves; retained incoming slots do not alter the centred item's layout. | Existing centring/layout tests and screenshot inspection. | PARTIAL |
| BELT-004 | User: circle/chart transition must not freeze input | `balance_frame.dart`, V2 dashboard call site | V2 filter commits resolve only the data used by the V2 surface; unused normal-detail metrics are skipped. Rail interaction is independent of that final commit. | Unit test for lightweight frame equivalence of query/summary/log groups; targeted dashboard tests; post-build device trace remains required. | PARTIAL |
| BELT-005 | Existing V2 feature contract | Avatar rail and dashboard | Explicit external selection epochs still animate a centred step; direct drag continues to defer the final filter until idle. | Existing remote-step and direct-debounce tests. | DONE |
| BELT-006 | User: solve rather than add noisy logs | All changed code | No per-frame diagnostic logging is added; diagnostics stay bounded and interaction-scoped. | Existing bounded-diagnostics test and independent source review. | DONE |
| BELT-007 | User: separate commit, push, build, download | Git/GitHub Actions | This repair is one code-only commit after the migration-guide commit, pushed to `spendeetest`; a successful GitHub APK is downloaded to Android Downloads. | `git show`, GitHub run result, SHA-256 and file inspection. | DONE |

## State contract

1. **Physical rail state** is owned locally while a pointer/motion is active.
2. **Settled avatar** is emitted once the local rail reaches a centred index.
3. **Committed dashboard filter** is delayed only as a batching boundary. It may
   never reject, defer, or overwrite a new direct manipulation.
4. **External chart/tap requests** carry an explicit epoch. Only a new epoch may
   command an external rail step; a normal parent rebuild or local acknowledgement
   may not do so.

## Verification record — 2026-07-30

- RED: `a dragless pointer release completes the interrupted external request`
  failed before the final ownership correction because no external settlement
  reached index 2.
- GREEN: the same focused widget test passed after keeping external ownership
  until Flutter actually recognises a horizontal drag.
- `flutter test --no-pub test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/balance_frame_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart --reporter compact --timeout 150s`
  completed with **77 passing tests**.
- Targeted `flutter analyze` of the four production files and three affected
  test files completed with **No issues found**.
- An independent read-only review identified the dragless-pointer edge case;
  its regression is included above. Fresh physical-device swipe/performance
  evidence and a screenshot are intentionally still outstanding.
- Published source commit: `40dbd93` (`fix(budget): decouple v2 avatar belt
  from filter commits`), after migration-guide commit `54dd1ec`.
- GitHub Actions run `30498561823` completed successfully, including Flutter
  analysis/tests, Android unit tests and debug APK build:
  <https://github.com/elizerpist/exptv2/actions/runs/30498561823>.
- Downloaded APK: `/storage/emulated/0/Download/exptv2-debug-40dbd93.apk`
  (`155 MiB`, SHA-256
  `31b702b509efd6ae7a01738042992e6bd476683d8335af37c1608851894cdaf0`),
  matching the GitHub release asset digest.
