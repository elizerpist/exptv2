# Budget V2 clean-room performance refactor — acceptance checklist

## Required evidence

- User source: 2026-07-30 request for a complete maximum-performance refactor
  and explicit approval to proceed without further confirmations.
- Migration source: `docs/migration-guide.md`.
- Visual reference: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260729-204523.png`.

| ID | Source instruction/reference | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| B2P-001 | User + reference screenshot | `budget_v2/`, Budget V2 host route | Reference layout and all existing Budget V2 user flows are preserved: header, five-avatar belt, card pages, type/period/search/filter controls, log and bottom navigation. | Widget contracts passed; inspected the mandatory reference. A fresh screenshot from the final GitHub-built APK is still required for the actual visual comparison. | PARTIAL |
| B2P-002 | Migration: clean feature boundary | `spendee_budget_mode_host.dart`, new `budget_v2/` | The Budget V2 route constructs its own dashboard and never constructs `BalanceFrameInput`, `BudgetV2FrameData`, `SpendeeBalanceDashboard`, `BalanceFrameResolver`, or `_SpendeeLegacyInteractionCoordinator`. | `spendee_budget_v2_contract_test.dart` plus direct host/dashboard source inspection. | DONE |
| B2P-003 | Migration: local/settled/committed ownership | selection controller | Physical offset, settled avatar and committed query have separate owners and one-way transitions. | `budget_v2_selection_controller_core_test.dart` and `budget_v2_selection_controller_test.dart`. | DONE |
| B2P-004 | User: avatar must not stutter | repaint rail | Continuous drag repaints only the belt transforms; SVG/icon subtree identity is retained and card/log/store do not rebuild on direct frames. | Avatar-carousel retained-widget/build-counter contracts and production direct-preview-local contract. | DONE |
| B2P-005 | Migration: cancellation | selection controller | Pointer-down cancels pending publication/inertia and obsolete generations can never commit. | Selection-controller and production pointer-down pre-emption contracts. | DONE |
| B2P-006 | Migration: indexed/cached queries | snapshot/cache | One immutable snapshot prepares the active record scope and per-avatar aggregates once per source revision; no raw-record double scan during interaction. | 4,096-record guarded cache fixture plus production snapshot contracts and source inspection. | DONE |
| B2P-007 | Existing V2 contract | dashboard + store adapter | A settled avatar commits at most one primary category filter; vendor remains tertiary; leaving V2 observes synchronized shared store filters. | Production-route contract verifies one final primary commit and tertiary vendor filtering. | DONE |
| B2P-008 | Existing V2 contract | new limit edit controller | Long-press preview, clear, drag/auto ticks and final persistence work without the legacy coordinator. | Limit-edit and persistence-coordinator lifecycle contracts plus production-route coverage. | DONE |
| B2P-009 | Migration: bounded diagnostics | new diagnostics | Diagnostics are interaction-scoped and bounded; no per-frame logging. | Bounded generation-diagnostics unit contract and direct source/trace review. | DONE |
| B2P-010 | Global Flutter workflow | code/test suite | Targeted tests and full `flutter analyze` run successfully inside Ubuntu proot. | 2026-07-30 Ubuntu/proot records: focused 81 tests passed; full analysis clean (140.2s); relevant 150-test suite passed (03:02). | DONE |
| B2P-011 | User: commit, push, build, download | Git/GitHub Actions | Clean feature branch is committed, pushed, GitHub Actions succeeds, and the generated APK is downloaded to Android Downloads with SHA-256 recorded. | Git/GitHub run/artifact/file inspection remains for the feature-delivery sequence. | NOT DONE |

## Completion rule

Every row must be `DONE`, or the user must explicitly defer it. An APK build is
only delivery evidence after the functional, visual and performance rows are
also `DONE`.
