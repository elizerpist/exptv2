# Fluvi Summary Debug Signal Path Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Identify and fix the production Room-to-Summary `0 Ft` data-path failure and port the Spendee on-screen debug console and floating button into Fluvi as a debug-only signal tracer.

**Architecture:** Keep Room, `FluviLedgerReadService`, the existing method/event channels, `CurrentQueryController`, and SummaryPill as the only production data path. Add one debug-only structured logger/ring buffer plus a native diagnostic event bridge; port the Spendee console renderer over that store without putting query or ledger state in the UI.

**Tech Stack:** Flutter/Dart, Kotlin, Room, MethodChannel/EventChannel, Flutter widget/unit tests, Gradle core tests.

## Global Constraints

- The SummaryPill must never read `DemoSeedReport` or hardcode a demo amount.
- The child rail physics, controller, spec, item geometry, haptics, and SummaryPill navigation animations are out of scope and must remain unchanged.
- The debug logger exists only in debug/development builds and uses a bounded 500-entry ring buffer matching Spendee.
- Native diagnostics carry a correlation flow ID, query key, scope, revision, totalMinor, entryCount, and duration where available.
- The debug overlay must be an overlay/Stack sibling and must not change dashboard or bottom-navigation geometry.
- No polling, arbitrary refresh delay, synchronous disk logging, or per-scroll-frame logging.

---

### Task 1: Establish failing data-path and logger contract tests

**Files:**
- Modify: `test/features/dashboard/query/method_channel_dashboard_ledger_repository_test.dart`
- Modify: `test/features/dashboard/application/dashboard_core_controller_test.dart`
- Create: `test/core/diagnostics/fluvi_diagnostic_logger_test.dart`
- Create: `test/core/debug/fluvi_debug_overlay_test.dart`

**Interfaces:**
- Consumes existing `DashboardLedgerResult`, method-channel payloads, and `DashboardCoreController`.
- Produces failing acceptance tests for non-zero July data, bounded diagnostics, debug overlay geometry, and absent release path.

- [ ] Write one test that starts a production query with `MonthScope(2026-07)`, receives the native payload with `68900000`, and asserts the amount presentation is non-zero.
- [ ] Write one test that emits more than 500 diagnostic events and asserts only the newest 500 remain.
- [ ] Write one test that the debug overlay has no normal-layout child and uses the Spendee floating-button keys/position contract.
- [ ] Run the focused tests inside Ubuntu proot and confirm failures identify the missing logger/overlay or missing non-zero bridge path.

### Task 2: Add the centralized debug diagnostic model and bounded store

**Files:**
- Create: `lib/core/diagnostics/fluvi_diagnostic_event.dart`
- Create: `lib/core/diagnostics/fluvi_diagnostic_logger.dart`
- Create: `lib/core/diagnostics/fluvi_diagnostic_bridge.dart`
- Modify: `lib/features/dashboard/query/application/dashboard_query_debug.dart`

**Interfaces:**
- `FluviDiagnosticEvent` is immutable and formats `[FLOW][D#]` entries without sensitive payloads.
- `FluviDiagnosticLogger.log(FluviDiagnosticEvent)` is the one Flutter debug sink and exposes a bounded `ValueListenable` projection.
- `FluviDiagnosticBridge` listens to the native diagnostic EventChannel only in debug builds and forwards native events to the logger.

- [ ] Implement the logger with Spendee's 500-entry limit and frame-coalesced notifications.
- [ ] Give every event a flow ID; preserve query key, scope, revision, direction, totalMinor, formatted total, entry count, and duration fields.
- [ ] Make `DashboardQueryDebug.mark` write through the logger and retain `debugPrint`-compatible diagnostics in debug mode.
- [ ] Add stale-result logging without logging every carousel frame.
- [ ] Run logger unit tests to green.

### Task 3: Port the Spendee debug UI 1:1

**Files:**
- Create: `lib/core/debug/debug_console.dart`
- Create: `lib/core/debug/debug_floating_button.dart`
- Modify: `lib/app/shell/fluvi_app_shell.dart`
- Test: `test/core/debug/fluvi_debug_overlay_test.dart`

**Interfaces:**
- `DebugFloatingButton` exposes the Spendee-compatible `Positioned` and button keys.
- `DebugConsoleDialog` renders `FluviDiagnosticLogger` entries and retains Spendee's Dialog geometry, colors, radius, typography, copy, clear, and timestamped monospace log behavior.

- [ ] Port only Spendee UI structure and visual values from the inspected source; omit Spendee-only recurring/native controls unless Fluvi has an equivalent service.
- [ ] Place the button in the root Stack above dashboard content and below no normal layout flow; use the exact Spendee left/bottom geometry relative to Fluvi's bottom navigation.
- [ ] Guard creation with `kDebugMode` and ensure release code has no rendered button or listener.
- [ ] Add copy/clear and empty-state behavior using the same Spendee interaction contract.
- [ ] Run widget tests to green.

### Task 4: Add native D0–D6 diagnostic bridge and scope evidence

**Files:**
- Modify: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`
- Create/modify: native diagnostic bridge tests under `android/app/src/test` or existing Flutter method-channel tests
- Modify: `lib/core/diagnostics/fluvi_diagnostic_bridge.dart`

**Interfaces:**
- Native `debugLog` emits to Logcat and the debug EventChannel when a listener is active.
- Query and seed stages carry one flow ID per query run and the actual active scope.

- [ ] Add a debug-only diagnostic EventChannel and lifecycle-safe sink handling.
- [ ] Emit D0 seed start, D1 commit, D2 database verification, D3 active scope/revision, D4 Room observer, D5 ReadService result, and D6 native bridge send.
- [ ] Include exact period boundaries and `totalMinor`/entry count in query logs.
- [ ] Log explicit `ACTIVE SCOPE OUTSIDE DEMO DATASET` and `QUERY ZERO RESULT` warnings for empty August/other scopes.
- [ ] Keep native diagnostics out of release behavior and avoid logging notes/PII.
- [ ] Run native/core and bridge tests to green.

### Task 5: Trace D7–D10 and fix the first proven zero boundary

**Files:**
- Modify: `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`
- Modify: `lib/features/dashboard/query/application/current_query_controller.dart`
- Modify: `lib/features/dashboard/time_navigation/presentation/summary_pill_presenter.dart`
- Modify: `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`
- Test: `test/features/dashboard/query/method_channel_dashboard_ledger_repository_test.dart`
- Test: `test/features/dashboard/query/current_query_controller_test.dart`

**Interfaces:**
- D7 bridge parser, D8 controller acceptance, D9 presentation emission, and D10 rendered amount use the same correlation ID/query key.
- `SummaryAmountPresentation` remains derived only from `DashboardQueryState`.

- [ ] Add D7 parsed DTO logging with parse errors.
- [ ] Add D8 accepted/stale result logging with generation and dropped-stale events.
- [ ] Add D9 raw/formatted/loading/stale/error logging and D10 only on changed rendered amount/query key.
- [ ] Reproduce the `0 Ft` scenario through the actual bridge/controller path, identify the first stage where a known July non-zero value becomes zero, and write the smallest regression test for that stage.
- [ ] Fix only that root cause; preserve empty-scope `0 Ft` behavior and production scope ownership.
- [ ] Verify no SummaryPill or seed-report shortcut was introduced.

### Task 6: End-to-end verification and documentation

**Files:**
- Modify: `docs/superpowers/checklists/2026-08-02-fluvi-summary-debug-signal-path.md`
- Create/modify: `docs/diagnostics/fluvi-summary-signal-path.md`
- Test: relevant Flutter/core suites

**Interfaces:**
- The evidence document records Spendee source files, Fluvi ports, the diagnosed root cause, and D0–D10 values for July income, July expense, and empty August.

- [ ] Run all focused Flutter tests and non-golden Flutter tests in Ubuntu proot.
- [ ] Run clean Room core tests in CI-compatible environment.
- [ ] Verify child rail and SummaryPill navigation source diffs are unchanged.
- [ ] Update checklist statuses honestly; leave runtime screenshot items partial if no attached Android device is available.
- [ ] Inspect final diff for hardcoded demo amounts, release leakage, polling, and sensitive logs.
- [ ] Do not commit, push, or build unless separately requested by the user.
