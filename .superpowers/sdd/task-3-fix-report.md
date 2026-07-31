# Task 3 review corrections — visual policy and motion verification

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| T3F-01 | Review finding 1 | `dashboard_mode_palette.dart`, `dashboard_motion_host.dart`, `transaction_direction_toggle.dart` | The motion host resolves the active mode palette once, carries it in `DashboardVisualFrame`, and the direction toggle receives its palette explicitly with no renderer-side mode/default resolution. | `dashboard_visual_policy_test.dart` validates the budget frame palette and a supplied custom toggle palette; source scan finds the resolver only in the host. | DONE |
| T3F-02 | Review finding 1 | `dashboard_mode_palette.dart` | Balance keeps the original income (`#7048E8 → #F542A7`) and expense (`#FF8A3D → #F542A7`) action gradients; Balance, Budget, and Mind have explicit, distinct upcoming-header tones. | Direct source review plus budget-versus-balance palette assertion in the focused widget test. | DONE |
| T3F-03 | Review finding 2 | `FluviVisualTokens`, `DashboardMotionTokens`, presentation leaves | Brand, summary, action, search, and rail typography; filter aspect ratio; and host transition curve are semantic tokens, with leaves selecting tokens or supplied dynamic palette values. | Source scan reports no raw `TextStyle`, font-weight, text-height, raw aspect ratio, or raw `Curves` policy in affected leaves/host. | DONE |
| T3F-04 | Review finding 3 | `test/core/motion/dashboard_visual_policy_test.dart` | `DashboardMotionHost` has deterministic controller-driven widget coverage for the .90 → 1.12 → .98 → 1.00 420 ms pulse, 180 ms rail reveal, collapse endpoint geometry, disabled-animation static state, and controller replacement. | Focused Flutter widget suite: `+12: All tests passed!`. | DONE |
| T3F-05 | Task scope | Task 3 files only | No Task 4 shell/CoreDashboard or data logic changed; host remains the sole stateful ticker/listener owner and leaves remain input-only. | Diff and source inspection. | DONE |
| T3F-06 | Review verification | Flutter package | Focused tests, full tests, analyzer, and whitespace validation are clean. | Ubuntu/proot commands below and final `git diff --check`. | DONE |

## Architecture card

- Single visual-mode owner: `DashboardMotionHost` resolves
  `DashboardModePaletteResolver.resolve(widget.mode)` and supplies that immutable
  palette through `DashboardVisualFrame`.
- Input-only renderer boundary: `TransactionDirectionToggle` receives
  `DashboardModePalette`; it has no mode argument, resolver call, or Balance
  fallback.
- Token owner: `FluviVisualTokens` owns leaf typography and filter proportion;
  `DashboardMotionTokens` owns the shared transition curve and durations.
- Motion ownership is unchanged: `DashboardMotionHost` alone owns Flutter
  tickers and subscribes only to `DashboardCoreController`.

## TDD evidence

- RED: before production edits, Ubuntu/proot focused tests failed exactly for
  missing `DashboardModePalette.upcomingHeaderTone`, missing
  `DashboardVisualFrame.palette`, missing required toggle `palette`, and
  missing brand typography tokens. This exposed the requested policy/frame and
  visual-token API gaps.
- GREEN: after the minimal policy and token changes, the focused command
  completed with `+12: All tests passed!`.
- Timing note: collapse coverage first pumps the controller-notification frame,
  then advances 180 ms. This captures the real animation start and avoids
  assuming an animation tick occurred during synchronous notification.

## Verification evidence

```sh
proot-distro login --user flutteruser ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && \
   /home/flutteruser/flutter/bin/flutter test test/core/motion/dashboard_visual_policy_test.dart test/features/dashboard/presentation/dashboard_primitives_test.dart'
# +12: All tests passed!

proot-distro login --user flutteruser ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && \
   /home/flutteruser/flutter/bin/flutter test'
# +29: All tests passed!

proot-distro login --user flutteruser ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && \
   /home/flutteruser/flutter/bin/flutter analyze'
# Analyzing fluvi... (exit 0)

git diff --check
# exit 0
```

No APK build or push was run.
