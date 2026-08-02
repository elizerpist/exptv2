# Fluvi Summary amount signal path

## Scope

The current dashboard amount is sourced exclusively from the production
ledger query:

`Room → FluviLedgerReadService → MainActivity DTO/EventChannel → Flutter repository → CurrentQueryController → SummaryPillPresenter → SummaryAmountView`

The demo seed report is not used as a UI data source.

## Diagnostic implementation

The on-screen console is a port of the Spendee implementation at:

- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/core/debug/debug_console.dart`
- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/core/debug/debug_floating_button.dart`

Fluvi-specific adaptation is limited to the existing Fluvi diagnostic sink,
the native EventChannel, and the shell overlay owner. The Spendee recurring
alarm and native IME panels were not copied because Fluvi has no corresponding
services.

The logger keeps the Spendee limit of 500 entries and is debug-only. Events are
rendered as `[FLOW][D#]` lines and carry a query flow ID, scope, revision,
minor-unit total, formatted total, and entry count when available.

## Event chain

| Stage | Owner | Meaning |
| --- | --- | --- |
| D0 | native demo bridge | seed started |
| D1 | native demo bridge | seed transaction committed |
| D2 | native demo bridge | direct Room/read verification |
| D3 | native query stream | active query scope |
| REV | native query stream | core revision changed |
| D4 | native query stream | Room observer emitted |
| D5 | native method channel | read-service result |
| D6 | native query stream | DTO sent to Flutter |
| D7 | Flutter repository | DTO parsed |
| D8 | `CurrentQueryController` | accepted or dropped stale result |
| D9 | `SummaryPillPresenter` | amount projection emitted |
| D10 | `SummaryAmountView` | changed amount actually rendered |

Zero is not silently treated as missing data. A `QUERY_ZERO_RESULT` marker is
added when a real result has `totalMinor == 0`; a loading state with no result
keeps `totalMinor` absent and renders the existing `0 Ft` placeholder.

## Current evidence

The focused Flutter bridge/controller test proves that a July 2026 expense
slice with `totalMinor=68,900,000` reaches the amount presentation unchanged
and formats as `689000,00 Ft` under the existing project formatter.

The non-golden Flutter suite passes with 179 tests, including the unchanged
CenteredCarousel physics/widget regression tests, the new bridge/logger tests,
the debug overlay tests, and the boundary test. The Android app Kotlin source
also passes `:app:compileDebugKotlin` when resource processing is excluded.

The in-memory/native core tests that verify Room aggregation cannot complete in
the current Ubuntu/proot runtime because the SQLite native library fails with
`UnsatisfiedLinkError`. No Android device is attached to this workspace, so a
runtime D0–D10 screenshot and the final installed-APK scope cannot yet be
observed here.

Therefore the previous `0 Ft` root cause is not claimed as a proven source
code defect until the debug console is opened on the same installed APK. The
first runtime discriminator is D3: if it reports `MonthScope(2026-08)` (or a
2025 scope), zero is the correct SQL result and the seed-to-July debug
navigation was not applied. If D4/D5 is non-zero but D7–D10 becomes zero, the
corresponding boundary is the defect location.
