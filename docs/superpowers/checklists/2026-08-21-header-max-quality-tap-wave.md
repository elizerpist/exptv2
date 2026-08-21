# Header maximum-quality renderer + tap-wave acceptance checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| HQ-01 | User: root-cause gate | docs + diagnostics | Current local Fluvi Logs is located/read, or absence is explicitly evidenced without invented CRITICAL entries. | exhaustive local search recorded | BLOCKED |
| HQ-02 | User: max-quality smoothness | Header paint lane | Dynamic fields do not rebuild semantic dashboard state, data, rails, or queries on a phase tick. | controller/resource tests | DONE |
| HQ-03 | User: preserve quality | mesh/backend | Maximum quality keeps spatial fidelity; quality/config changes reconfigure once, not each phase tick. | deterministic renderer tests | DONE |
| HQ-04 | User: motion protection | shared motion | CenteredCarousel physics, friction, velocity, and snap output are unchanged. | existing motion tests + no physics diff | DONE |
| HQ-05 | User: bounded resources | Header controller | No ticker/controller per layer/tap and no unbounded raster/wave resource growth. | identity/resource tests | DONE |
| TW-01 | `color_lab.html` pointer touch audit | shared Header controller | Pointer-down/move/release semantics, normalized origin, interval/capacity rules match source. | pure source-contract tests | DONE |
| TW-02 | `color_lab.html` CSS/renderer audit | Header visual painter | Fixed pink/magenta multi-layer overlay, trail and field ripple use audited colors, order, timing, clip and composition. | projection/widget tests | DONE |
| TW-03 | User: no canned ripple | gesture/render | Header body triggers source wave; hamburger/tuner do not. | widget tests | DONE |
| TW-04 | User: shared three-mode direction | Header visual engine | Wave is shared Header visual state, not Budget accounting code, and uses the one existing clock. | architecture/identity tests | DONE |
| TW-05 | User: live tuner | existing tuner | Every real source control appears once; app-added constant controls retain source defaults and update locally. | tuner tests | DONE |
| VR-01 | User: RED -> GREEN -> REFACTOR | tests | Each production phase has a failing focused RED run followed by GREEN evidence. | captured commands/results | DONE |
| VR-02 | User: delivery | git/CI/APK | Two focused commits are pushed, required CI succeeds, normal `lib/main.dart` APK is downloaded and hashed. | GitHub Actions + SHA-256 | NOT DONE |
| VR-03 | User: physical truthfulness | final handoff | No physical smoothness claim without user/device evidence. | final report | DONE |

## Execution evidence

* Renderer RED: the new renderer-contract test did not compile against the
  original Header mesh API because layer-composite opacity, cadence projection,
  packed colour mutation and retained vertices generations did not exist.
  GREEN: focused Header renderer/effect/tuner suite passed with 34 tests, and
  focused analysis reported no issues.
* Tap-wave RED: `dashboard_header_tap_wave_test.dart` did not compile before
  the shared wave state/projection existed. GREEN: its fixed palette, source
  intervals/caps, field equation, trail keyframes and release cleanup all pass
  in the same 34-test focused suite.
* The broader protected-motion regression subset passed (154 tests), including
  CenteredCarousel physics/identity/widget tests, Motion Kernel, prepared
  Budget, committed cache/paging, Dashboard host and Budget presentation.
* `flutter test` was started for the entire repository but has a pre-existing
  failure in `dashboard_rail_density_trace_test.dart`: its `fling()` targets
  `(206, 721)` outside the default `800 × 600` test viewport, so the expected
  flight events do not exist. The exact four failures reproduce unchanged in a
  detached clean worktree at pre-task SHA
  `1e396d78af13f1c0e0e5234f375dc86b1ccc8f44`; they are not attributed to this
  Header task. The full run was then interrupted rather than letting unrelated
  failures hide the task result.
