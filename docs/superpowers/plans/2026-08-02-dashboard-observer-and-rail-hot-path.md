# Dashboard Observer and Rail Hot-Path Plan

## Design decision

The reported D2 values prove the seed and Room data are correct. D8 with no
native D3–D7 proves only that Flutter accepted a scope, not that a native
observer returned a snapshot. The repair remains inside the existing
`CurrentQueryController → DashboardLedgerRepository → EventChannel →
FluviLedgerReadService` production path.

The rail is a separate performance incident. Preview remains a navigation
presentation concern; it must never update `CurrentQueryController`. The
shared carousel engine and its physics are explicitly out of scope.

## Steps

1. Prove direct Room reads for July/year/all-time values and add structured
   subscription-stage diagnostics D8A–D8D.
2. Write failing tests for native observer subscription identity, initial
   snapshot/error completion, real empty scope, and 100 previews/zero queries.
3. Repair the EventChannel observer lifecycle with a unique listener identity
   so an older cancellation cannot stop the newest observation. Propagate
   parse and native errors to a non-loading state.
4. Split preview notifications from committed dashboard motion/query updates;
   keep SummaryPill preview projection available without rebuilding the amount
   region or starting a query.
5. Make diagnostic capture bounded and structured in the hot path; move render
   diagnostics to deduplicated state transitions and keep the overlay isolated.
6. Run targeted Flutter/Kotlin suites in Ubuntu, then the unmodified carousel
   regression suites. Runtime/profile evidence is collected only on-device.

## Explicit non-goals

- No edits to `lib/shared/motion/centered_carousel/**`.
- No changes to spring/friction/velocity/spec/slot geometry/haptic parameters.
- No hardcoded total, seed-report shortcut, polling, or one-shot-only fallback.
