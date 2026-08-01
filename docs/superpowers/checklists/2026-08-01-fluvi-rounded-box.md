# Fluvi shared rounded-box geometry checklist

References:

- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/balance_latest_layout.html`
- `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/prototypes/color_lab.html`
- Android screenshots in `/storage/emulated/0/Pictures/Screenshots`

| ID | Source requirement | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| RBOX-01 | User: income/expense controls are too short | `DashboardLayoutMetrics`, dashboard geometry | Direction controls use the reference 52 logical-pixel height and the lower stack remains derived from that metric | Geometry and widget tests | DONE |
| RBOX-02 | User: sizes may differ, shape may not | `FluviVisualTokens`, rounded-box primitive | Generic dashboard components use one centralized 16 logical-pixel rounded-box radius; no generic component uses a 999-pixel pill radius | Widget tests and source inspection | DONE |
| RBOX-03 | User: summary and rail keep their own heights | metrics and component renderers | Summary, action controls, search, and rail retain their independent heights while sharing the shape token | Geometry/widget tests | DONE |
| RBOX-04 | User: explicit overrides only | design-system primitive and explicit exceptions | Only explicitly circular/handle/navigation shapes bypass the generic rounded-box primitive | Boundary/static inspection | DONE |
| RBOX-05 | User: no golden screenshot | verification workflow | No golden test, release build, or screenshot generation is run for this change | Workflow record | DONE |
