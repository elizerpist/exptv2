# Foreground speculation fairness implementation plan

**Goal:** Keep low-priority Query and scene work behind raw foreground input while preserving exact committed readiness.

**Architecture:** Inject one runtime-owned input-fair speculative grant scheduler into `DashboardCoreController`; it starts exactly one admitted Query neighbour per grant. Convert the deferred rich projection into a resumable private builder driven by the existing scene cache's budget/checkpoint loop. Tighten partner-side effects to explicit self-claim, and separate pointer-only diagnostic fields from formal vertical-session fields.

## Plan

1. Add controlled-scheduler RED tests for one-neighbour-per-grant, pointer interleaving, clear-all retention, and post-Apply first-input ordering; then add the injected runtime scheduler and refactor the prewarm state machine.
2. Add deterministic rich-projection RED coverage that exhausts a synthetic 3000-unit slice inside a single payload; then expose private resumable projection steps and drive them from the existing scene preparation checkpoints.
3. Add passive arena-acceptance and stale no-scroll velocity RED regressions; then make recognizer acceptance self-claim-only and make pointer-only summaries independent of formal interaction state.
4. Re-run focused behavior, partner, viewport, scene, paging and Query suites; run fast tests, analysis, boundaries; inspect the final diff; make one commit and obtain one normal human APK.
