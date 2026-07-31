# Task 3 — Fluvi visual primitives report

## Acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| T3-01 | Task 3 Step 1 | `test/features/dashboard/presentation/dashboard_primitives_test.dart` | Brand, selected action, handle, and horizontal rail contracts are expressed as widget tests. | Focused Flutter widget test RED then GREEN. | DONE |
| T3-02 | Task 3 Step 2 | `assets/fluvi/` | Three newly authored local SVG files contain the Fluvi mark, wallet, and bag with no external dependency. | Source review and asset rendering through widget tests. | DONE |
| T3-03 | Task 3 / CORE-UI-04 | `lib/core/design/dashboard_mode_palette.dart` | Shared page, radii, neutral, text, and action palette decisions have one source. | Source review and `flutter analyze`. | DONE |
| T3-04 | Task 3 / CORE-UI-06/08 | `lib/core/motion/dashboard_motion_host.dart` | One Stateful motion owner subscribes to `DashboardCoreController`, resolves geometry, and supplies immutable visual frames. | Focused source review, widget tests, `flutter analyze`. | DONE |
| T3-05 | Task 3 Step 3 | `lib/features/dashboard/presentation/widgets/` | All leaves are input-only, use precomputed bounds, and the rail is the only leaf with horizontal scrolling. | Widget tests and source review. | DONE |
| T3-06 | Task 3 Step 4 | Flutter package | Focused tests, full tests, analyzer, and whitespace validation are clean. | Proot `flutter test`, `flutter analyze`, `git diff --check`. | DONE |

## Architecture ownership

- `DashboardLayoutMetrics -> DashboardGeometryResolver -> DashboardLayoutFrame`
  remains the sole geometry writer. Leaves only size to supplied
  `DashboardBounds`; they never position themselves globally.
- `DashboardCoreController` remains the only motion-host subscription. The
  host derives its immutable visual frame from its child-controller state.
- `DashboardMotionHost` is the sole Task 3 stateful/ticker-owning widget.
  Every visual leaf is input-only, except the rail's own horizontal scroll
  viewport.
- `FluviVisualTokens` and `DashboardModePaletteResolver` own shared visual
  decisions; `DashboardMotionTokens` owns timing constants.

## Reference inspection

Inspected directly before implementation:
`/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/superpowers/evidence/screenshots/b3ma3-reference-expanded.png`.
It informs the lockup's compact mark-to-wordmark relationship only. No source
code, asset, or runtime dependency is copied from the reference worktree.

## TDD evidence

- RED: `dashboard_primitives_test.dart` was run before production files were
  added. It failed as expected with missing primitive imports and constructors:
  `FluviBrandLockup`, `TransactionDirectionToggle`,
  `DashboardCollapseHandle`, and `TimeRefinementRail`.
- GREEN: the same focused command completed with `+4: All tests passed!` for
  brand semantic keys, selected expense assets/label, collapse-handle tap, and
  horizontal five-pill rail.

## Final verification and commit

- Focused primitive test: `+4: All tests passed!`.
- Full Flutter suite: `+21: All tests passed!`.
- Analyzer: `Analyzing fluvi...` completed in Ubuntu/proot with exit status 0.
- `git diff --check` and `git diff --cached --check`: each completed with exit
  status 0.
- Commit: `feat(fluvi): add dashboard visual primitives` (local only; no push).
