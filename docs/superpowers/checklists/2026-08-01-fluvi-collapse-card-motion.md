# Fluvi collapse card motion checklist

Reference: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/balance_latest_layout.html`,
`attachTodayRedesignScrollInteraction` and its interaction CSS.

| ID | Source requirement | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| COLLAPSE-CARD-01 | User: white cards slide while handle moves | `DashboardGeometryResolver`, `DashboardLayoutFrame` | The two white lower cards expose the same staged collapse progress as opacity plus reference translate values | Geometry test | DONE |
| COLLAPSE-CARD-02 | Balance HTML: insight card motion | `CoreDashboard` renderer | First white card translates up to `-18px` and scales to `0.90` as it fades | Geometry/widget test | DONE |
| COLLAPSE-CARD-03 | Balance HTML: detail card motion | `CoreDashboard` renderer | Second white card translates up to `-24px` and scales to `0.96` as it fades | Geometry/widget test | DONE |
| COLLAPSE-CARD-04 | User: preserve existing opacity/layers | dashboard stack | Transform is applied to each card's own layer; card ordering and surrounding stack geometry remain unchanged | Widget/source inspection | DONE |
| COLLAPSE-CARD-05 | User: no release build yet | workflow | No release build or screenshot generation is run for this change | Workflow record | DONE |
