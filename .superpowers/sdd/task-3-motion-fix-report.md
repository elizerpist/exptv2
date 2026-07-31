# Task 3 motion-host review corrections

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| T3M-01 | Important review finding 1 | `lib/core/motion/dashboard_motion_host.dart` | The mode palette is resolved at host initialization and only when its effective policy input changes (mode or injected resolver identity); ticker-driven frame builds reuse the cached immutable palette. | Counter-injected resolver widget test with animation ticks, a mode update, and a resolver-identity update. | DONE |
| T3M-02 | Important review finding 2 | `lib/core/motion/dashboard_motion_host.dart` | A controller replacement detaches the old listener and atomically adopts the replacement controller's static collapse, rail, and pulse-rest state. | Deterministic widget test swaps during active collapse, rail, and pulse motion. | DONE |
| T3M-03 | Important review finding 2 | `lib/core/motion/dashboard_motion_host.dart` | Subsequent notifications from the replacement controller still drive collapse, rail, and direction pulse motion. | Same deterministic replacement test. | DONE |
| T3M-04 | Task scope | Task 3 motion host and focused motion test only | `DashboardMotionHost` remains the sole stateful ticker owner and only listens to the aggregate controller; no Task 4/data/assets changes. | Diff/source inspection. | DONE |
| T3M-05 | Delivery request | Flutter package | Red evidence, focused tests, full tests, analyzer, and whitespace check are recorded truthfully. | Ubuntu/proot command output and `git diff --check`. | DONE |

## Architecture card

- **Single visual owner:** `DashboardMotionHost` owns the three ticker controllers,
  cached mode palette, and controller-swap reset protocol.
- **Read path:** `DashboardCoreController` publishes aggregate temporary state to
  the host; `DashboardVisualFrame` carries immutable geometry, palette, and
  visual values to leaves.
- **Palette policy:** `DashboardModePaletteResolver` remains the centralized
  semantic policy. A typed resolver lookup is an explicit host dependency so
  policy evaluation can be observed without inspecting private state.
- **Swap protocol:** removing the old aggregate listener, attaching the new one,
  stopping all three tickers, assigning replacement static values, resetting the
  pulse revision, and then rendering is one host-owned lifecycle transaction.
- **Scope boundary:** no leaf owns ticker, cache, or controller-swap behavior.

## TDD evidence

- **RED 1:** Before production edits, the focused Ubuntu/proot test command
  failed to compile because `DashboardModePaletteLookup` and
  `DashboardMotionHost.paletteResolver` did not exist. This is the requested
  observable caching seam, not a colour-equality assertion.
- **GREEN 1:** After adding the typed policy dependency, cached frame state,
  and replacement reset protocol, the focused suite completed with
  `+9: All tests passed!`.
- **RED 2:** The additional resolver-identity regression failed before its
  one-line cache-input fix with `Expected: <1>` and `Actual: <0>`, proving a
  same-mode policy replacement would otherwise leave the cache stale.
- **GREEN 2:** The same focused suite again completed with
  `+9: All tests passed!` after refreshing on a mode or resolver-identity
  change only.

## Verification evidence

```sh
proot-distro login --user flutteruser ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && \
   /home/flutteruser/flutter/bin/flutter test test/core/motion/dashboard_visual_policy_test.dart'
# +9: All tests passed!

proot-distro login --user flutteruser ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && \
   /home/flutteruser/flutter/bin/flutter test'
# +31: All tests passed!

proot-distro login --user flutteruser ubuntu -- bash -lc \
  'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/fluvi && \
   /home/flutteruser/flutter/bin/flutter analyze'
# Analyzing fluvi... (exit 0)

git diff --check
# exit 0
```

Source inspection confirms the production resolver call is only the host's
default injected policy and all aggregate-controller listener/ticker ownership
remains in `DashboardMotionHost`. No APK build or push was run.
