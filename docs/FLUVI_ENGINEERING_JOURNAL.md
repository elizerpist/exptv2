# Fluvi Engineering Journal

Shared evidence journal for the Fluvi prompt-writer and coding agents. Read this file in full before every implementation attempt. Entries record physically tested application SHAs, observed behavior, evidence boundaries, failed loops, and the next allowed investigation scope. USER_MARK log entries are annotations and are never treated as runtime proof by themselves.

## 2026-09-10 — Physical feedback on `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`

- Feedback time: 2026-09-10 10:07 Europe/Budapest.
- Exact physically tested application SHA proven by the refreshed runtime logs: `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.
- Application branch: `fix/avatar-fling-pacing-codex-20260910`.
- Parent: `33ee878b070345c336bb73df2b087d9a63c87c5a`.
- APK marker in the logs: `fluvi_HUMAN_DIAGNOSTIC_6e96218.apk`.
- Commit title at the tested SHA: `test(profile): correlate Avatar fling render pacing`.
- Current physical result: Avatar fling appears good and overall performance is good. Preserve this state as the new minimum performance floor while repairing the remaining defects.
- Remaining physical defects reported by the user:
  - switching between income and expense hitches/stutters;
  - after changing month, the limit-circle progress is not visibly populated until an Avatar is changed afterward.
- Avatar-log audit: the retained flight summary is healthy (`semanticTicks=61`, `duplicateTicks=0`, `coalescedTicks=48`, `acceptedPublications=27`, `paintedPublications=27`, final `physicalSettled=7`, `endingPendingTargetHandle=null`). Retained frame summary: median build 1.293 ms, p95 build 2.716 ms, p99 build 10.082 ms, max build 37.569 ms; median raster 1.030 ms, p95 raster 1.813 ms, p99 raster 5.740 ms, max raster 15.583 ms; median total 2.459 ms, p95 total 4.387 ms, p99 total 19.198 ms, max total 39.684 ms. Mismatch/reject events observed during rapid supersession are anomaly candidates, not proof of a surviving-target defect; do not touch the Avatar critical path unless a surviving/final target anomaly is proven.
- Avatar log frozen snapshot: Google Doc `Fluvi logs avatar fling`, ID `1FF1BnHJHOEygG3QhMeDfrehzjo0YzIztaGJfNTWZqNs`, plain-text export SHA-256 `dc6d3e987fa46e77a397b47cf5836b0b673e9efc8c5b7e28fef8776c30e084d6`, 1,411,657 bytes, 2,004 lines. Session `243426112422`; two retained windows cover union sequence 5873–6887 without observed gaps, with overlapping duplicate snapshots. The latest `USER_MARK` still names an older `avatar_filter_stuck` issue; the user's newer physical feedback says Avatar fling now appears good, and USER_MARK is not runtime proof.
- Time-log audit: captured retained flight is healthy (`semanticTicks=3`, `distinctTicks=3`, `duplicateTicks=0`, `maxTickGapMs=40`, `acceptedPublishesForFlight=3`, `matchingAcceptedPublishesForFlight=3`, `matchingPaintedPublishesForFlight=3`, `settleVisualDelta=0.0`, `correctlyCaptured=true`, no ending pending target/replay). A `USER_MARK issue=time_target_jump` and an isolated `SUMMARY_SETTLE_REJECTED_UNACCEPTED_TARGET` remain anomaly candidates and must be classified from surrounding runtime evidence before any Time production change.
- Time log frozen snapshot: Google Doc `Fluvi logs time fling`, ID `1XSzi1TO8CfVKDGxAMkUYhJihbqy7nEDUcmqs8mboxoE`, plain-text export SHA-256 `c76a6ae13e2d37abe77e5581d2038b30e097b68c47edc06f4b240101e08b9fb5`, 1,462,414 bytes, 2,004 lines. Session `243426112422`; two retained windows cover union sequence 8958–9972 with overlapping duplicate snapshots.
- Month/limit-progress evidence boundary: around the month interaction, the generic Budget progress pipeline does emit `LIVE_INTERACTION_ACCEPTED`, `LIMIT|STATE`, `BUDGET_PROGRESS_BOUND`, `BUDGET_PROGRESS_WIDGET_BUILT`, `BUDGET_PROGRESS_PAINTED`, and `SUMMARY_TARGET_PAINTED` events. Therefore the physical defect is NOT proven to be a generic “no progress publication” failure. The exact limit-circle projection/identity/state/listener/render invalidation path must be traced and the first failing boundary proven.
- Direction-switch evidence boundary: the physical hitch is proven by user testing, but its owner/root cause is not yet proven. Instrument and correlate the direction input/controller, target data/resource readiness, visible publication, Budget presentation, build/layout/paint/raster, and frame timing before changing behavior.
- Historical loop guards:
  - `aa61242c4b933ad9d650361ae1014d67fd184186`: physically smooth Avatar motion, but Avatar correctness/publication failed; do not return to this tradeoff.
  - `33ee878b070345c336bb73df2b087d9a63c87c5a`: Avatar correctness was restored, but physical fling became choppy; do not preserve correctness at unbounded performance cost.
  - `e8b73e3e939104164e55b09caf592f84ee59fb14`: previous protected motion floor recorded in `MILESTONE_COMMITS.md`.
  - `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`: current physically good overall-performance floor and required base for the next repair. Do not accidentally base work on `separated-core-modes`, which is not the tested SHA.
- Milestone intent: the final application repair built on `6e962187...`, after it fixes the income/expense switch hitch and month-limit-circle defect while preserving the current Avatar/Time performance and correctness, is intended to become the next Fluvi milestone commit. The journal-only commit containing this entry is NOT the milestone application SHA.
- Required next scope: audit fresh Avatar and Time anomalies; repair only proven surviving anomalies; prove and repair the first causal boundary for direction-switch hitch; reproduce and repair month-change limit-circle invalidation without requiring an Avatar change; preserve the `6e962187...` performance floor and all existing gesture/physics/controller identities unless current evidence proves them causal.
- Prompt-writer source change: documentation journal only. No production source, tests, workflow, build configuration, graph, milestone file, or application behavior changed by this entry.
- Physical validation of any future repair: `PENDING — USER ONLY` until the exact produced APK is tested by the user.
