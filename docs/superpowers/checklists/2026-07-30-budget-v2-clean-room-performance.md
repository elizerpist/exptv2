# Budget V2 clean-room performance refactor — acceptance checklist

## Required evidence

- User source: 2026-07-30 request for a complete maximum-performance refactor
  and explicit approval to proceed without further confirmations.
- Migration source: `docs/migration-guide.md`.
- Visual reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.

| ID | Source instruction/reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| B2P-001 | User + reference screenshot | `budget_v2/`, Budget V2 host route | Reference layout and all existing Budget V2 user flows are preserved: header, five-avatar belt, card pages, type/period/search/filter controls, log and bottom navigation. | Golden/widget contract tests and final screenshot comparison. | NOT DONE |
| B2P-002 | Migration: clean feature boundary | `spendee_budget_mode_host.dart`, new `budget_v2/` | The Budget V2 route constructs its own dashboard and never constructs `BalanceFrameInput`, `BudgetV2FrameData`, `SpendeeBalanceDashboard`, `BalanceFrameResolver`, or `_SpendeeLegacyInteractionCoordinator`. | Source-contract test plus direct source inspection. | NOT DONE |
| B2P-003 | Migration: local/settled/committed ownership | selection controller | Physical offset, settled avatar and committed query have separate owners and one-way transitions. | Unit tests for state transitions and external selection epochs. | NOT DONE |
| B2P-004 | User: avatar must not stutter | repaint rail | Continuous drag repaints only the belt transforms; SVG/icon subtree identity is retained and card/log/store do not rebuild on direct frames. | Widget instrumentation test with stable keys/build counters; source review. | NOT DONE |
| B2P-005 | Migration: cancellation | selection controller | Pointer-down cancels pending publication/inertia and obsolete generations can never commit. | Widget tests for pre-emption, interruption and timer cancellation. | NOT DONE |
| B2P-006 | Migration: indexed/cached queries | snapshot/cache | One immutable snapshot prepares the active record scope and per-avatar aggregates once per source revision; no raw-record double scan during interaction. | Unit test with resolver counters/real-size fixture and source inspection. | NOT DONE |
| B2P-007 | Existing V2 contract | dashboard + store adapter | A settled avatar commits at most one primary category filter; vendor remains tertiary; leaving V2 observes synchronized shared store filters. | Production-route widget tests. | NOT DONE |
| B2P-008 | Existing V2 contract | new limit edit controller | Long-press preview, clear, drag/auto ticks and final persistence work without the legacy coordinator. | Lifecycle widget tests and store persistence test. | NOT DONE |
| B2P-009 | Migration: bounded diagnostics | new diagnostics | Diagnostics are interaction-scoped and bounded; no per-frame logging. | Trace-source test and trace review. | NOT DONE |
| B2P-010 | Global Flutter workflow | code/test suite | Targeted tests and full `flutter analyze` run successfully inside Ubuntu proot. | Recorded command output. | NOT DONE |
| B2P-011 | User: commit, push, build, download | Git/GitHub Actions | Clean feature branch is committed, pushed, GitHub Actions succeeds, and the generated APK is downloaded to Android Downloads with SHA-256 recorded. | Git/GitHub run/artifact/file inspection. | NOT DONE |

## Completion rule

Every row must be `DONE`, or the user must explicitly defer it. An APK build is
only delivery evidence after the functional, visual and performance rows are
also `DONE`.
