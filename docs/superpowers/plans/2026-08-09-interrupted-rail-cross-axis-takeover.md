# Interrupted rail reconciliation and first-gesture takeover plan

**Base:** `0f47fd2fbb6f218ec8a2076b3ead226894c23d77`  
**Working branch:** `fix/dashboard-rail-reopen-vertical-takeover`

## 1. Establish executable RED reproductions

- [x] Add the interrupted SUM close/reopen test without changing production
  behavior; record the existing divergent center failure.
- [x] Add the fresh pointer-on-preview sibling test using the real
  pointer-down path, without manually promoting the frame; record the stale
  rejection failure.
- [x] Keep the existing preserve-ballistic test explicit so the reconciliation
  policy cannot accidentally become global.

## 2. Commit A — rail reconciliation

- [x] Add explicit semantic install policy to the motion kernel and centered
  carousel.
- [x] Add a silent interruption/recenter operation that preserves controller,
  position, and physics identities and invalidates old commands.
- [x] Use reconciliation only for close/reopen, plane, closed structural, and
  no-continuation revision transitions.
- [x] Reset `TimeRefinementRail` baseline for a structural reconciliation even
  when the catalog identity is unchanged.
- [x] Run the focused carousel, motion, presentation, and navigation tests;
  commit `fix: reconcile interrupted rail state on structural boundaries`.

## 3. Commit B — first gesture takeover

- [x] Factor canonical child retention with explicit settled/takeover reason.
- [x] On a fresh vertical pointer, synchronously cancel speculation, interrupt
  rail ownership, retain the exact visible child, promote the same frame, and
  seed committed metadata before ScrollStart.
- [x] Preserve rejection for old queued activity; add bounded diagnostics.
- [x] Refactor the stale and dense sibling tests so they do not manually seed
  the state that production pointer-down must create.
- [x] Run the focused viewport/controller tests; commit
  `fix: allow first vertical gesture to take over rail preview`.

## 4. Consolidate, verify, and deliver

- [x] Add I16/I17 to the existing audit, with one primary owner each.
- [x] Run the requested targeted suite, then `scripts/test-fluvi-fast.sh`.
- [ ] Push the working branch; trigger one final profile/human workflow.
- [ ] Download and hash the normal human diagnostic APK. Report physical
  validation as waiting for the user.
