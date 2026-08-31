# Post-df1d physical regression repair — acceptance checklist

Source of truth: user request **FLUVI — POST-df1d PHYSICAL REGRESSION REPAIR** (2026-08-31), current local source `df1d4a3ca9ca83565260a6f7618ab3786ca5650e`, and the three current Google Docs captures reviewed on 2026-08-31.

This checklist is deliberately an execution contract. A passing analyzer or APK is not sufficient: every row must be `DONE`, or the user must explicitly defer it.

| ID | Source / evidence | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MIND-01 | User §9.1; `Fluvi logs slider` seq 2964–3060; `QueryAmountRangeControl._schedulePreview` | `query_amount_range_control.dart`, shared display-frame scheduler | Amount preview is published before the matching next paint, with latest-value coalescing; no post-frame-only boundary | Scheduler-order widget test and production Dashboard/LogBox drag test while pointer remains down | DONE |
| MIND-02 | User §9.2; slider range-cache/unmount log evidence | Mind range binding and `mind_dashboard_core_surface.dart` | Amount-only canonical reconciliation retains the domain, element/recognizer and local values; no loading/unmount | Delayed-commit production-parent test; counters | DONE |
| MIND-03 | User §9.3–9.4; release-time `QUERY_APPLY → INDEX_BUILD` logs | `CoreDashboard` Mind commit + visible-frame/LogBox lane | The latest exact preview remains authoritative through one async canonical commit; release causes no first visible delta | Slow/fast/reverse pointer-down tests plus delayed canonical completion | DONE |
| MIND-04 | User §9.5/§14 | Mind controller and range control tests | 20 immediate next-frame interactions, both thumbs/directions, empty and populated range cases | Focused tests without `pumpAndSettle` before the live assertion | DONE |
| TIME-01 | User §10.1–10.2; time-log lacks pointer verdicts | Segmented summary wiring, centered carousel and Core lifecycle | New pointer interrupts ballistic/settling motion immediately; background work cannot gate it; every pointer has a typed acceptance/rejection record | Production-parent immediate re-entry tests and bounded diagnostics | DONE |
| TIME-02 | User §10.3; current selector emits then assigns settle target | `_HierarchyValueSelectorState`, `DashboardCoreController` | Emitted, accepted and painted targets are distinct; only accepted/painted target may settle | Typed synchronous acceptance test including rejected/stale target | DONE |
| TIME-03 | User §10.4–10.5 | Segmented selector/Core target settlement | `2025 → 2024 → 2025` and fast reversals settle to latest painted exact target with zero release delta | Production-parent reversal and 20 re-entry tests | DONE |
| AV-01 | User §11.1; avatar log has aggregate-only diagnostics | Avatar rail / coordinator / render diagnostics | Direct, ballistic, settling, interrupted, cancelled and superseded counters are split, including Budget/LogBox matching paint | Focused tests + bounded interaction summary | DONE |
| AV-02 | User §11.2–11.5; physical Avatar fling | Avatar rail → drilldown → Core live focus lane | Every direct and ballistic crossing atomically publishes target, Budget and exact LogBox before settle; stale revision cannot win | Production Budget parent test with active ballistic crossing and interruption | DONE |
| ID-01 | User §12/§14 | shared visible-frame/live-interaction identity | Relevant visible layers share revision, query/refinement, source/phase/generation and presentation epoch; mixed projections are rejected | visible-frame and production-parent identity assertions | DONE |
| PERF-01 | User §14 | Core interaction paths | No repository/native/index/foreground scene/text layout work during a prepared move; no artificial cooldown | Counters in all focused regression tests | DONE |
| DIAG-01 | User §13 | Mind/Summary/Avatar bounded diagnostics | Bounded numeric summaries contain required lifecycle/paint evidence; no per-vsync formatted log spam | Code review and diagnostic tests | DONE |
| VALID-01 | User §18–20 | test/analyze/commit/build workflow | All relevant automated validation is recorded honestly; exact committed source profile APK is built only after validation | command log, final source SHA, online build status | PARTIAL — online profile human-diagnostic build is intentionally after the functional commit and push |

## Architecture / centralization card

- **Existing reusable core:** `DashboardDisplayFrameCoalescer` already owns one-slot pre-display-frame coalescing. Mind must use it or a small equally shared adapter rather than another local scheduler.
- **Interaction authority:** `DashboardCoreController` owns prepared live projections, visible-frame identity, generation rules and scene activation. Widgets only collect intent and retain local physical gesture state.
- **Presentation owners:** `DashboardPresentationController` owns visible-frame publication; `DashboardLogBoxRenderSurface` owns the actual LogBox paint lane; `DashboardBudgetLogboxDrilldownCoordinator` adapts Avatar handles to the Core focus use case.
- **No duplicated mechanism:** Segmented and Avatar must use the existing core live-publication/generation seam; no widget-local Query, cache or timer/cooldown may be introduced.
- **Known boundary defects to prove:** Mind's `addPostFrameCallback`, Segmented's void crossing callback/early settle ownership, and missing Segmented Core direct-pointer preemption are source-visible. The exact Avatar ballistic drop and Summary physical rejection flag remain evidence-gated until red production-parent tests/instrumentation trace them.

## Automated evidence recorded before the functional commit

- `flutter test test/features/dashboard/presentation/core_dashboard_geometry_golden_test.dart` — FAIL: six golden pixel mismatches. The exact same six failures and pixel counts reproduce at clean `df1d4a3ca9ca83565260a6f7618ab3786ca5650e`, so this is an inherited environment/golden baseline failure rather than a delta from this repair.
- `flutter test test/shared/motion/centered_carousel` — PASS (`CENTERED_CAROUSEL_TEST_EXIT=0`) in Ubuntu proot.
- `flutter analyze` — PASS (`FLUTTER_ANALYZE_EXIT=0`) in Ubuntu proot.
- `dart format --output=none --set-exit-if-changed` for all changed Dart files — PASS.
- `git diff --check` — PASS.

The profile human-diagnostic APK is deliberately not represented as complete
until this exact functional commit has been pushed and its GitHub Actions run
has produced the required artifact. Physical validation remains user-only.
