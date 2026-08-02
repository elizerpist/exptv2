# Fluvi Summary Amount, Observer Lifecycle, and Rail Hot-Path Checklist

## Architecture card

### Scope and sources

- User requirement: diagnose the persistent `0 Ft` through Room → ReadService → native DTO → bridge → query state → SummaryPill; then remove the independent rail-performance regression without changing carousel physics.
- Accepted reference paths: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/core/debug/debug_console.dart`, `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/core/debug/debug_floating_button.dart`.
- Existing implementation paths: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`, `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`, `lib/features/dashboard/query/application/current_query_controller.dart`, `lib/features/dashboard/query/data/method_channel_dashboard_ledger_repository.dart`, `lib/features/dashboard/application/dashboard_core_controller.dart`, `lib/core/motion/dashboard_motion_host.dart`, `lib/features/dashboard/query/application/dashboard_query_debug.dart`, `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`, `lib/core/diagnostics/fluvi_diagnostic_logger.dart`, `lib/app/shell/fluvi_app_shell.dart`.

### Single source and write path

- Source of truth: production Room ledger query result for `DashboardLedgerResult.totalMinor`.
- Read model: `DashboardLedgerResult` / `SummaryAmountPresentation`.
- Only write path: `SeedFluviDemoDatasetUseCase` for demo data; no UI or report shortcut.
- Error owner: `CurrentQueryController` and the native query bridge; debug presentation only reports the error.

### State ownership

| State | Owner | Publication rule |
| --- | --- | --- |
| Structured diagnostic entries | `FluviDiagnosticLogger` | Debug-only bounded ring buffer; no business state |
| Native diagnostic stream subscription | `FluviDiagnosticBridge` / debug shell owner | Active only while debug sink is available |
| Current query scope/result | `CurrentQueryController` | Latest-wins query result; each native subscription is identity-safe |
| Summary amount | `SummaryPillPresenter` from query state | Never reads seed report or DAO |
| Overlay visibility | `FluviAppShell`/debug presentation | Debug build only; does not alter dashboard layout |
| Carousel motion | Shared `CenteredCarousel` owner | Untouched: no query, transition, or logger work may enter its motion algorithm |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Debug console UI | Spendee `DebugConsoleDialog` | Port visual/interaction structure 1:1; adapt only imports and services | Spendee source inspection and widget tests |
| Diagnostic storage | Fluvi dashboard debug prints plus Spendee bounded store | One Fluvi debug logger sink; dashboard diagnostics write through it | Ring-buffer and event-flow tests |
| Dashboard query | `CurrentQueryController`, `MethodChannelDashboardLedgerRepository`, native EventChannel session | Repair the existing production observer; no parallel demo query or one-shot/polling workaround | Room/bridge/controller E2E test |
| Child rail and SummaryPill motion | Existing shared engines | Do not modify | Diff and regression test boundary |
| Rail preview updates | `DashboardTimeNavigationController` presentation state | Keep preview local to navigation; no query generation, repository watch, amount update, or D8–D10 event | 100-preview / one-settle controller test |
| Diagnostics hot path | `FluviDiagnosticLogger` overlay sink | Store structured bounded events; do not rebuild dashboard/root or synchronously format build-time events | Listener/rebuild boundary test and profile measurement |

### Layer flow

`Room → FluviLedgerReadService → identity-safe MainActivity EventChannel session → Flutter repository → CurrentQueryController → SummaryPillPresenter → SummaryAmountView`.

Native/application layers emit structured metadata only. The Flutter debug overlay renders immutable diagnostic entries and owns no query or ledger state.

### Proven code-level causes

1. The prior native dashboard EventChannel retained one mutable
   `dashboardObservationJob`, and `onCancel` cancelled it unconditionally.
   Flutter's `EventChannel.receiveBroadcastStream` sends the original listen
   arguments again on cancellation. Therefore an old listener cancellation
   may arrive after a replacement listener and cancel the replacement Room
   observer. No slice and no error then reached Dart, leaving
   `CurrentQueryController` in its initial loading state.
2. Every rail preview notified `DashboardCoreController`; the aggregate
   `DashboardMotionHost` consequently rebuilt the full dashboard during a
   fling. Preview timing `debugPrint` calls compounded the hot-path work.
   Preview never changed `effectiveScope`, so this work was unnecessary and
   independent from the shared carousel physics.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| OBS-01 | User runtime FLOW log, D2 | `android/fluvi-core/.../FluviLedgerReadService.kt` | Direct July 2026 and year 2026 reads return the recorded non-zero income/expense totals from the same Room database contract | New Kotlin integration test; local Robolectric execution blocked by Termux SQLite native linker | PARTIAL |
| OBS-02 | User runtime FLOW log, D8 without D3–D7 | Native EventChannel session + Flutter repository | Every accepted committed scope reaches repository watch, native subscribe, initial snapshot, Dart decode, controller result, and `loading=false`; failures become errors, never infinite loading | Flutter stream lifecycle tests pass; on-device FLOW trace remains required | PARTIAL |
| OBS-03 | User runtime FLOW log | `MainActivity.kt` native bridge | A late cancellation for an old EventChannel listener cannot cancel the currently active subscription | New native session unit test plus successful `:app:compileDebugKotlin`; native test execution deferred to CI due local AAPT2 limitation | PARTIAL |
| OBS-04 | User requirement | Query state/presentation | Initial loading uses a non-zero-result placeholder; real empty scopes render `0 Ft`, `loading=false` | Focused controller/presenter/widget tests | DONE |
| OBS-05 | User requirement | DTO parser and error path | `totalMinor`, count, key and revision parse losslessly; parse/native errors visibly end loading | Dart bridge/error tests | DONE |
| PERF-01 | User rail report | `DashboardTimeNavigationController` → dashboard core | 100 preview events cause zero query generations, watches, amount-state updates, or D8–D10 events; one settled child causes one query | Failing-then-passing core-controller test | DONE |
| PERF-02 | User rail report | Dashboard/listenable topology | Rail preview no longer rebuilds the full dashboard motion host or amount region unnecessarily | Root-notification boundary test and direct listener inspection | DONE |
| PERF-03 | User rail report | Debug logger / SummaryPill diagnostics | Closed logger performs only bounded structured appends; panel updates are isolated; D10 is emitted only for a genuine rendered amount-state change, not from unguarded build work | Presentation tests; profile/on-device timing remains required | PARTIAL |
| PERF-04 | User rail regression prohibition | `lib/shared/motion/centered_carousel/**` | No shared physics, spec, controller or rail wiring changes; target delta/tap/haptic suites remain green | Zero diff in shared carousel plus focused physics/controller suites | DONE |
| SPDBG-03 | User requirement | `lib/core/debug/` | Spendee floating button and console layout/interaction are ported without Fluvi restyling | Source comparison and widget tests | DONE |
| SPDBG-04 | User requirement | `lib/core/diagnostics/` | Logger is debug-only, bounded to the Spendee limit, and does not own business state | Unit tests and boundary inspection | DONE |
| SPDBG-05 | User requirement | `android/app/MainActivity.kt` + Flutter bridge | Native D0–D6 events reach the same on-screen logger with flow ID and scope metadata | EventChannel parser test and direct Kotlin inspection; native runtime evidence pending | PARTIAL |
| SPDBG-06 | User requirement | `lib/features/dashboard/query/` | D3–D10 events share query key/correlation ID and show where non-zero becomes zero | Focused event-flow code inspection and bridge/controller tests | DONE |
| SPDBG-07 | User requirement | `lib/app/shell/fluvi_app_shell.dart` | Debug button is an overlay, does not change dashboard/bottom-nav geometry, and is absent in release | Widget test and static `kDebugMode` inspection | DONE |
| SPDBG-08 | User requirement | `lib/features/dashboard/query/` | Empty scopes explicitly render `0 Ft`; valid July scopes render formatted non-zero HUF | Presenter/widget and E2E tests | PARTIAL |
| SPDBG-09 | User requirement | All changed code | No hardcoded demo amount, report shortcut, polling, or child rail/SummaryPill motion regression | Search, diff, focused regression suite | DONE |
| SPDBG-10 | User requirement | Debug overlay | D0–D10 is searchable/visible as `[FLOW][D#]`, with timestamp, scope, total, count, revision, and duration where known | Widget/logger tests and direct code inspection | PARTIAL |
| SPDBG-11 | User requirement | `docs/` | Spendee source mapping, root cause, and diagnostic evidence are documented | Documentation review; runtime root cause is explicitly unverified without device | PARTIAL |
| SPDBG-12 | Global delivery rule | Worktree | All statuses are truthful before any later commit/build handoff | Checklist reread | DONE |
| VER-01 | Global delivery rule | Full Flutter suite | Full suite has no unrelated visual-regression failures before a release handoff | `flutter test` currently has two failing `core_dashboard_*` golden baselines (12.56% and 14.79% pixel difference); do not rebaseline without approved visual reference | BLOCKED |

## Verification record

- Focused Flutter suites pass: dashboard core preview boundary, query controller,
  MethodChannel repository mapping, summary presenter/widget, navigation
  controller, and unchanged centered-carousel physics/controller/widget suites.
- `:app:compileDebugKotlin` passes with Android resource tasks excluded. Android
  unit-test compilation cannot complete locally because the Termux/proot
  environment cannot start the Linux AAPT2 daemon during `processDebugResources`.
- A full `flutter test` run executes the functional suites successfully except
  the two dashboard visual baselines listed in `VER-01`. Their
  generated diff images were inspected and deliberately not accepted as new
  baselines: the visual delta is far broader than this observer/hot-path change.
- Runtime D0-D10 proof requires the next debug APK/device run. No commit, push,
  online build, or APK install has been initiated for this change set.
