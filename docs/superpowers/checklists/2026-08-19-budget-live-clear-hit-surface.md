# Budget live clear + centre hit surface acceptance checklist

## Architecture card

- Scope/source: 2026-08-19 user report; only the proven presentation tri-state
  adapter and the selected-avatar input composition are in scope.
- Single source/write path: `DashboardBudgetLimitEditController` owns an active
  or pending limit overlay and is the only RAM/persistence write owner. The
  presentation controller derives the immutable live selection; the rail only
  renders it and forwards pointer input to the existing interaction shell.
- Reuse: retain `BudgetTargetAvatarInteraction` for raw press/long-press and
  `CenteredCarousel` for horizontal scrolling/tap-to-centre. No parallel
  gesture recognizer or second overlay is introduced.
- Layer flow: pointer -> existing interaction/quick-edit controller ->
  `DashboardBudgetLimitEditController` -> presentation `ValueNotifier` ->
  selected avatar paint. Repository writes remain release-only in the edit
  controller.

| ID | Source | Area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BLC-01 | Proven `effectiveLimitFor ?? confirmed` root cause | `dashboard_budget_presentation_controller.dart` | Explicit active/pending `null` survives as no-limit; positive and absent overlays retain their distinct values | RED/GREEN controller tests | DONE |
| BLC-02 | Very-long physical contract | edit -> presentation -> rail | Clear hides header limit/chrome while pointer stays down and with zero repository writes; release cannot resurrect stale confirmed value | focused widget/controller tests | DONE |
| BLC-03 | 112 px shell vs 72 px input source evidence | rail/interaction composition | First pointer down in an outer visible selected-shell region reaches the existing press interaction | hit-test widget test | DONE |
| BLC-04 | Protected carousel behavior | rail | Item extent, controller ownership, horizontal scroll and side tap-to-centre stay unchanged | existing/focused rail/carousel tests + code inspection | DONE |
| BLC-05 | Hot-path contract | changed production paths | Clear and pointer feedback have no I/O, SVG generation or catalogue rebuild | code inspection + controller/widget tests | DONE |
| BLC-06 | Delivery contract | branch/CI artifact | Focused tests, analyzer, intentional commit, remote workflow and normal `lib/main.dart` APK are complete | commands + artifact SHA | DONE |
