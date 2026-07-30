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
| B2P-004 | User: avatar must not stutter | repaint rail + standalone dashboard | Continuous drag repaints only the belt transforms; SVG/icon subtree identity is retained and the real standalone route does not mutate/notify the store or resolve/prepare snapshots on direct frames. | Retained-widget/build-counter contracts plus the 4,096-record `SpendeeBudgetV2Dashboard` production swipe contract (same mother-card/log identity, zero direct store notifications and zero direct snapshot work before idle commit). | DONE |
| B2P-005 | Migration: cancellation | selection controller + rail/session hand-off | Every raw pointer-down cancels pending publication/inertia, finalizes an active diagnostic session, and starts a fresh generation; obsolete releases cannot settle or commit. | Selection-controller and real standalone restarted-release contract: exactly one old cancelled one-frame terminal (`commit_count=0`), then a distinct fresh Travel two-frame terminal (`commit_count=1`), one commit trace and one store notification. | DONE |
| B2P-006 | Migration: indexed/cached queries | snapshot/cache | One immutable snapshot prepares the active record scope and per-avatar aggregates once per source revision; no raw-record double scan during interaction. | 4,096-record guarded cache fixture plus the real standalone swipe’s cache counters (zero direct resolves/preparations) and source inspection. | DONE |
| B2P-007 | Existing V2 contract | dashboard + store adapter | A settled avatar commits at most one primary category filter; vendor remains tertiary; leaving V2 observes synchronized shared store filters. | Production-route contract verifies one final primary commit and tertiary vendor filtering. | DONE |
| B2P-008 | Existing V2 contract | new limit edit controller | Long-press preview, clear, drag/auto ticks and final persistence work without the legacy coordinator. | Limit-edit and persistence-coordinator lifecycle contracts plus production-route coverage. | DONE |
| B2P-009 | Migration: bounded diagnostics | UI-free `budget_v2_interaction_diagnostics.dart` + scoped presentation policy | A bounded, sanitized final record contains only source revision/counts/index/commit duration; no direct-frame trace is emitted. Legacy raw chart build traces are disabled only inside the standalone B2 context. | Red/green diagnostics and rail contracts; 4,096-record production contract verifies one final summary and rejects raw money, merchant/vendor, and `[BudgetV2Chart]` output. | DONE |
| B2P-010 | Global Flutter workflow | code/test suite | Targeted tests and full `flutter analyze` run successfully inside Ubuntu proot. | Fresh 2026-07-30 Ubuntu/proot relevant suite passed: 154 tests in 01:40; final-tree `flutter analyze`: no issues (49.5s). | DONE |
| B2P-011 | User: commit, push, build, download | Git/GitHub Actions | Clean feature branch is committed, pushed, GitHub Actions succeeds, and the generated APK is downloaded to Android Downloads with SHA-256 recorded. | Git/GitHub run/artifact/file inspection remains for the feature-delivery sequence. | NOT DONE |

## Completion rule

Every row must be `DONE`, or the user must explicitly defer it. An APK build is
only delivery evidence after the functional, visual and performance rows are
also `DONE`.
