# Dashboard interaction latency regression checklist

## Scope and constraint

- Sources: user reports and FLOW traces supplied on 2026-08-02 (13:21 and
  13:24), including the follow-up report about a second fling resolving to one
  item and the observed title/subtitle animation mismatch.
- Shared `lib/shared/motion/centered_carousel/**` scroll physics, velocity,
  spring, snap, item extent, mapping and haptic policy are a strict regression
  boundary. This package may use the existing engine but must not tune or fork
  it.
- Existing owners: `DashboardTimeNavigationController` owns time state,
  `DashboardSummaryAmountController` owns summary projection/index caching,
  and `DashboardSummaryPill` owns only pill rendering and gesture feedback.

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ILAT-01 | User: rail continuously lags; tick can lack visual feedback | rail adapter + navigation/summary projection boundary | A rail preview never starts subtitle or amount animation; the selected rail tile is not held behind synchronous dashboard work. | Focused widget/controller regression tests; no shared-carousel diff | DONE — the rail frame-coalesces the dashboard preview after Carousel selection notification; preview presentation is direct. |
| ILAT-02 | User: title and month-name lines animate separately/inconsistently during fling | `SummaryNavigationPresentation`, `SummaryPillTextTransition` | Rail preview replaces the subtitle directly. A committed transition is latest-wins and never leaves an outgoing subtitle visible after a following preview. | Widget test for interrupted transition then preview | DONE — new `rail preview cancels…` regression test. |
| ILAT-03 | User: Summary Pill horizontal swipe also lags | `DashboardSummaryPill`, amount presentation policy | A horizontal parent gesture gets immediate, coherent pill feedback; query/loading state must not create a second competing amount transition. | Gesture/widget test for consecutive horizontal commits | DONE — parent subtitle and scope amount both replace directly; vertical plane changes retain the single text transition. |
| ILAT-04 | User: app needs to "warm up" after start | `DashboardSummaryAmountController` | Once the initial detailed scope is fresh, its child-summary index is prewarmed outside a rail gesture. Opening the initial rail uses that cached index without an interaction-time index request. | Controller test with fake child-summary repository | DONE — new closed-scope prewarm regression test. |
| ILAT-05 | User: second fling after a fling may advance only one item | dashboard rail adapter/navigation lifecycle | Consecutive rail flings preserve the latest selection and no stale settle/preview presentation interrupts the later fling. | Dashboard-level rapid-fling regression test, plus unchanged shared-carousel suites | DONE — new dashboard rail test plus focused unchanged Carousel controller/widget/physics suites. |
| ILAT-06 | FLOW: `D8`/subscribe/cancel and `D10B–D10D` cluster around settles/parent changes | query and Summary Pill presentation boundary | A user interaction never pays an avoidable 120-ms stale/loading crossfade; detailed watch delivery remains latest-wins and semantics-correct. | Focused summary/controller tests and FLOW-code inspection | DONE — scope or stale state resets the amount transition; same-scope passive fresh updates retain latest-wins crossfade. |
| ILAT-07 | User delivery instruction | repository/CI/release | All focused tests and analyze pass; shared-carousel diff is empty; changes are committed, pushed, built online and APK downloaded to `/storage/emulated/0/Download/fluvi`. | Proot tests/analyze; [GitHub Actions run 30746523460](https://github.com/elizerpist/exptv2/actions/runs/30746523460); SHA-256 | DONE — code commit `2bccd10` is pushed; Flutter, Room/core, native bridge and debug APK jobs passed; downloaded `fluvi_2bccd10.apk` SHA-256 `53af48b31ce60070212f0fddc5c1d7894612ad81d4936d77c53d815b2d85425e`. |
