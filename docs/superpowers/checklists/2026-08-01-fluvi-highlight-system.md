# Fluvi centralized highlight system checklist

Reference: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/balance_latest_layout.html`, B3M active time-rail pill.

| ID | Source requirement | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| HIGHLIGHT-01 | User: one app highlight color/gradient | `FluviVisualTokens` | The Balance B3M `#715efb → #b484f3 → #e478c3` gradient has one official token | Source inspection | DONE |
| HIGHLIGHT-02 | User: all non-income/expense highlights use it | rail, dots, bottom nav, FAB, future border token | Active rail pill, indicator dot, bottom colored surfaces, FAB, and highlight border resolve from the shared token | Source inspection and widget tests | DONE |
| HIGHLIGHT-03 | User: summary chevron follows active rail highlight | `DashboardSummaryPill` | Active-rail chevron is shader-filled from the shared gradient | Widget test and source inspection | DONE |
| HIGHLIGHT-04 | User: touch/slide movement gets an effect | `DashboardMotionHost`, `DashboardCollapseHandle` | Expansion dragging is exposed in the immutable visual frame and drives the pressed highlight layer | Motion/widget test and source inspection | DONE |
| HIGHLIGHT-05 | User: income/expense keep their own colors | `DashboardModePaletteResolver` | Income and expense gradients remain separate from the app highlight gradient | Source inspection | DONE |
| HIGHLIGHT-06 | User: no build yet | release artifacts | No release build is run in this iteration | Direct workflow record | DONE |
