# Budget V2 avatar belt recovery implementation plan

> **For agentic workers:** execute each task with the listed verification before
> moving to the next one. Do not stage unrelated worktree changes.

**Goal:** Restore the Budget V2 avatar strip as a responsive direct-manipulation
belt: the next touch preempts stale motion, local rail state is never re-driven by
a parent acknowledgement, and the final dashboard update avoids unused expensive
detail calculations.

**Architecture:** Keep the rendering belt in its dedicated carousel file. Add a
small rail ownership/epoch coordinator rather than moving widget layout or timer
code into another large file. Treat the dashboard filter as a downstream,
cancelable consumer. Introduce an opt-in lightweight `BalanceFrameResolver` path
for the V2 presentation, preserving query, summary, and log output while omitting
normal-detail metrics not rendered by V2.

**Tech stack:** Flutter/Dart, existing `SpendeeCenterCarouselController`, widget
tests, `BalanceFrameResolver` unit tests, GitHub Actions APK build.

## Guardrails

- Preserve the existing 360 ms final-filter debounce as a batching boundary only.
- Do not alter the shared TransactionStore category-filter API.
- Do not add per-frame logs or a new input lock.
- External requests remain epoch-based and must still animate correctly.
- Run Flutter checks only through Ubuntu proot; build the APK only through GitHub
  Actions.

### Task 1 — write red regressions

**Files:**

- `test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart`
- `test/spendeetest/balance_frame_test.dart`

**Work:**

1. Add a widget test that starts local direct manipulation, rebuilds the parent
   with a different `selectedIndex` but unchanged external epoch, and proves the
   rail is not driven by a `source=step` external motion.
2. Add a widget test that starts an epoch-driven external step, sends pointer
   contact before drag recognition, and proves contact interrupts it immediately.
3. Add a resolver test specifying lightweight V2 output: query, summary, visible
   transaction count and transaction-log groups equal the full result, while
   normal-detail metric collections are empty/default.
4. Run the focused tests and record the expected RED result before production
   changes.

### Task 2 — make rail ownership explicit

**Files:**

- Add `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_rail_coordinator.dart`
- Modify `lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart`

**Work:**

1. Centralise interaction serial and owner/epoch acceptance in the small helper.
2. Ignore ordinary `selectedIndex` rebuilds; only a newer
   `externalSelectionEpoch` starts an external movement.
3. On raw pointer down, preempt an active external motion and re-centre its local
   physical residual before the gesture arena accepts the next horizontal drag.
4. Retain existing bounded diagnostics and no-op safely for a simple tap.

### Task 3 — remove V2-only post-filter calculation debt

**Files:**

- Modify `lib/features/transactions/state/balance_frame.dart`
- Modify `lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart`

**Work:**

1. Add an opt-in `includeDetailMetrics` resolver mode.
2. In lightweight mode build the filter query, summary, counts and transaction-log
   groups, returning safe defaults for the normal-detail-only fields.
3. Select that path only for Budget V2; standard dashboard/budget paths keep their
   full frame.

### Task 4 — verify behaviour and integration

**Commands:**

```bash
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter test --no-pub test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/balance_frame_test.dart test/spendeetest/spendee_budget_v2_contract_test.dart --reporter expanded --timeout 120s'
proot-distro login ubuntu -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree && /home/flutteruser/flutter/bin/flutter analyze --no-pub lib/features/transactions/state/balance_frame.dart lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_rail_coordinator.dart lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_avatar_carousel.dart lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart test/spendeetest/spendee_budget_v2_avatar_carousel_test.dart test/spendeetest/balance_frame_test.dart'
```

Then inspect diffs, update the checklist only with real evidence, and run a
targeted review of the changed files.

### Task 5 — publish without mixing unrelated changes

1. Stage only the recovery source, tests, checklist and plan.
2. Commit the recovery separately from `54dd1ec`.
3. Push `spendeetest`, monitor its GitHub Actions run, download its APK to
   `/storage/emulated/0/Download`, and record its hash.
