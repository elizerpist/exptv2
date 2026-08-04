# Plan: dashboard rail smoothness

## Goal

Remove stale lease activation, redundant amount work, duplicate idle handling,
motion-overlapping adjacent prewarm and hot-path diagnostic/projection overhead
without changing rail physics or preview semantics.

## Steps

1. Add and run failing lease, stale-result, amount, idle, prewarm, bundle-log
   and LogBox instrumentation tests.
2. Add a shared motion-start/idle signal to the existing centered carousel
   command boundary; keep all scroll ownership and physics unchanged.
3. Add query-side pending lease invalidation and generation guards. Preserve
   active lease caching while suppressing irrelevant visible notifications.
4. Implement amount `directPreview`/`noOp` behavior and truthful numeric
   diagnostics without removing valid non-rail crossfades.
5. Move semantic idle/settle dedupe to the motion epoch boundary and stop
   treating raw scroll-end notifications as independent semantic events.
6. Add a motion-aware, latest-wins adjacent-prewarm coordinator with no visible
   publish from the prewarm lane.
7. Make bundle decoding emit an aggregate event and gate per-child logs behind
   the existing verbose diagnostic path.
8. Add bounded LogBox phase counters and keep the stable lazy viewport boundary.
9. Run targeted tests, full non-golden tests, static analysis, stress fixtures,
   and profile measurements with verbose FLOW logging off.
10. Update the checklist honestly. Only after every required item is DONE:
    commit, push, run one online full build, and download the final APK.

## Verification gates

- No preview repository/native/watch/paging I/O.
- Pending lease cancellation count increases on new motion and stale lease
  activation count remains zero.
- One idle and one settle per motion epoch.
- Preview amount update duration is zero; equal amount is a no-op.
- Existing rail crossing/final target/controller/position/physics tests remain
  green.
- LogBox viewport identity and lazy rendering remain green.
- Stress cache remains bounded.
