# Carousel threshold no-tick follow-up checklist

Source log window: user-provided logs from `2026-07-20 20:57:08.99` through `20:58:26.68`.

Current evidence:

- `20:57:26.25` shows `carousel_drag ... selected=category-16-expense-all_time-all residual=-46.0 velocity=-545.7`.
- The carousel switch threshold is expected to be below that residual magnitude, so release should visibly continue to the next avatar and emit a `carousel_tick`.
- Instead, the next carousel event is `20:57:26.40 carousel_filter_schedule selected=category-16-expense-all_time-all`, with no intervening `carousel_tick`.
- Similar no-tick releases with small residuals also appear, for example `20:57:59.19 residual=-8.4` and `20:58:24.13 residual=-10.9`; those may be legitimate spring-back cases and must be distinguished from the threshold-crossing failure above.

| ID | Source instruction or evidence | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| CNT-001 | User report: "még mindig elő lehet idézni azt hogy tick nélkül ugrik" | `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart` carousel release path | A release whose residual exceeds the snap threshold cannot settle/publish the current item without a boundary tick. | `budget carousel threshold release ticks before publishing filter` widget test. | DONE |
| CNT-002 | Log evidence: `residual=-46.0 velocity=-545.7` followed by schedule of the same selected item | `SpendeeCenterCarouselController.releaseMotion` plus dashboard release animation frame application | The release plan, animation application, and final selected item agree on the same target index for threshold-crossing residuals, including after prior live ticks. | `center carousel release settle nudges near-boundary snaps into a tick` controller test plus full interaction suite. | DONE |
| CNT-003 | Log evidence: many rapid diagram motions interleaved with carousel drags and idle publishes | Programmatic diagram recenter and carousel drag interruption boundaries | Programmatic `source=diagram` carousel motion cannot leave a stale selected key or stale residual that causes the next drag release to silently snap back. | Existing `budget carousel continues an interrupted release drag` and `chart taps use the faster diagram recenter step timing` widget tests stayed green after release serial/final-frame changes. | DONE |
| CNT-004 | Log evidence: repeated `carousel_filter_schedule selected=overview...` without a nearby tick or motion start | Budget filter scheduling diagnostics | Add or verify diagnostics that identify whether a no-tick schedule came from spring-back, center tap, stale motion finalizer, or threshold snap. | Added `carousel_release_plan` and `carousel_release_settle` perf logs; threshold widget test asserts tick order before filter schedule. | DONE |
| CNT-005 | User instruction from prior message: code only after explicit approval | Workflow guard | Do not change implementation code for this follow-up until the user explicitly says to code. | Git diff review before approval shows only checklist/spec documentation changes for this follow-up. | DONE |
