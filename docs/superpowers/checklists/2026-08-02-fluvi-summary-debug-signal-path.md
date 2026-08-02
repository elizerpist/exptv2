# Fluvi Summary Amount and On-Screen Debugger Checklist

## Architecture card

### Scope and sources

- User requirement: diagnose the persistent `0 Ft` through Room → ReadService → native DTO → bridge → query state → SummaryPill and port the Spendee on-screen logger 1:1.
- Accepted reference paths: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/core/debug/debug_console.dart`, `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/core/debug/debug_floating_button.dart`.
- Existing implementation paths: `android/app/src/main/kotlin/com/fluvi/app/MainActivity.kt`, `android/fluvi-core/src/main/kotlin/com/fluvi/core/query/FluviLedgerReadService.kt`, `lib/features/dashboard/query/application/current_query_controller.dart`, `lib/features/dashboard/query/application/dashboard_query_debug.dart`, `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart`, `lib/app/shell/fluvi_app_shell.dart`.

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
| Current query scope/result | `CurrentQueryController` | Latest-wins query result |
| Summary amount | `SummaryPillPresenter` from query state | Never reads seed report or DAO |
| Overlay visibility | `FluviAppShell`/debug presentation | Debug build only; does not alter dashboard layout |

### Reuse and centralization decision

| Candidate | Existing owner | Decision | Proof |
| --- | --- | --- | --- |
| Debug console UI | Spendee `DebugConsoleDialog` | Port visual/interaction structure 1:1; adapt only imports and services | Spendee source inspection and widget tests |
| Diagnostic storage | Fluvi dashboard debug prints plus Spendee bounded store | One Fluvi debug logger sink; dashboard diagnostics write through it | Ring-buffer and event-flow tests |
| Dashboard query | `CurrentQueryController` and `MethodChannelDashboardLedgerRepository` | Extend existing production path; no parallel demo query | Room/bridge/controller E2E test |
| Child rail and SummaryPill motion | Existing shared engines | Do not modify | Diff and regression test boundary |

### Layer flow

`Room → FluviLedgerReadService → MainActivity DTO/EventChannel → Flutter repository → CurrentQueryController → SummaryPillPresenter → SummaryAmountView`.

Native/application layers emit structured metadata only. The Flutter debug overlay renders immutable diagnostic entries and owns no query or ledger state.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SPDBG-01 | User requirement | `lib/features/dashboard/presentation/widgets/dashboard_summary_pill.dart` | The existing amount region remains present and `0 Ft` is treated as a real empty result, not missing UI | Focused widget test | DONE |
| SPDBG-02 | User requirement | Core query/read path | July 2026 income and expense totals come from the production Room query and reach the SummaryPill | Existing native/core tests plus focused bridge/controller integration test; runtime APK evidence pending | PARTIAL |
| SPDBG-03 | User requirement | `lib/core/debug/` | Spendee floating button and console layout/interaction are ported without Fluvi restyling | Source comparison and widget tests | DONE |
| SPDBG-04 | User requirement | `lib/core/diagnostics/` | Logger is debug-only, bounded to the Spendee limit, and does not own business state | Unit tests and boundary inspection | DONE |
| SPDBG-05 | User requirement | `android/app/MainActivity.kt` + Flutter bridge | Native D0–D6 events reach the same on-screen logger with flow ID and scope metadata | EventChannel parser test and direct Kotlin inspection; native runtime evidence pending | PARTIAL |
| SPDBG-06 | User requirement | `lib/features/dashboard/query/` | D3–D10 events share query key/correlation ID and show where non-zero becomes zero | Focused event-flow code inspection and bridge/controller tests | DONE |
| SPDBG-07 | User requirement | `lib/app/shell/fluvi_app_shell.dart` | Debug button is an overlay, does not change dashboard/bottom-nav geometry, and is absent in release | Widget test and static `kDebugMode` inspection | DONE |
| SPDBG-08 | User requirement | `lib/features/dashboard/query/` | Empty scopes explicitly render `0 Ft`; valid July scopes render formatted non-zero HUF | Presenter/widget and E2E tests | DONE/PARTIAL |
| SPDBG-09 | User requirement | All changed code | No hardcoded demo amount, report shortcut, polling, or child rail/SummaryPill motion regression | Search, diff, focused regression suite | DONE |
| SPDBG-10 | User requirement | Debug overlay | D0–D10 is searchable/visible as `[FLOW][D#]`, with timestamp, scope, total, count, revision, and duration where known | Widget/logger tests and direct code inspection | PARTIAL |
| SPDBG-11 | User requirement | `docs/` | Spendee source mapping, root cause, and diagnostic evidence are documented | Documentation review; runtime root cause is explicitly unverified without device | PARTIAL |
| SPDBG-12 | Global delivery rule | Worktree | All statuses are truthful before any later commit/build handoff | Checklist reread | DONE |
