# Fluvi Cascaded Header Reveal Acceptance Checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| CASCADE-01 | User screenshots + current upper-card implementation | `HeaderCascadeMotion`, `DashboardGeometryResolver` | Upper card retains its existing expanded endpoint, `-18px` collapse shift, `0.90` scale, and progress-driven opacity | unit/resolver tests + direct inspection | DONE |
| CASCADE-02 | User master-progress requirement | `DashboardGeometryResolver`, `DashboardMotionHost` | One normalized reveal progress (`1 - collapseProgress / collapseTravel`) drives both cards | source inspection + unit test | DONE |
| CASCADE-03 | User stagger intervals | `HeaderCascadeMotion` | Upper uses `0.00..0.72`; lower uses `0.18..1.00`; both use continuous eased progress | unit test | DONE |
| CASCADE-04 | User lower-anchor formula | `HeaderCascadeMotion` | Lower collapsed top equals current upper top plus upper height minus hidden overlap | unit test | DONE |
| CASCADE-05 | User lower motion profile | `HeaderCascadeMotion` | Lower Y, horizontal inset/width, opacity, and scale all change; lower is not opacity-only | unit test + widget geometry test | DONE |
| CASCADE-06 | User z-order requirement | `CoreDashboard` | Split Stack paint order is lower → upper → header | source inspection + widget test | DONE |
| CASCADE-07 | User reverse-motion requirement | shared calculator | Same equations are continuous and reversible for every progress value | unit test | DONE |
| CASCADE-08 | User layout preservation | dashboard geometry | Expanded card endpoints and all downstream controls remain unchanged | resolver/widget tests | DONE |
| CASCADE-09 | User golden deferral | test suite | No golden test is added or required; unit/widget/static checks cover the change | file/test audit; 99 non-golden tests passed | DONE |
| CASCADE-10 | User delivery workflow | GitHub/Download | Commit, push, successful CI APK build, and direct APK download completed | commit `9990b11`, GitHub Actions run `30694169994` (all jobs successful), APK verified at `/storage/emulated/0/Download/fluvi/fluvi_9990b11.apk` | DONE |

Delivery evidence: the APK is a 147,702,112-byte Android package downloaded from the successful debug-build artifact. Golden tests were intentionally skipped per the user instruction.
