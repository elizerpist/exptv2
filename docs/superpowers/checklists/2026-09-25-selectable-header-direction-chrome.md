# Acceptance checklist — selectable Header and direction chrome

| ID | Requirement | Owner | Verification | Status |
| --- | --- | --- | --- | --- |
| APP-01 | One session appearance owner with independent defaults/copy/equality/setters | `FluviGlobalAppearance` | unit/controller RED→GREEN | DONE |
| UI-01 | Existing MEGJELENÉS section exposes all stable controls; inactive white is impossible | tuner | widget test | DONE |
| HANDLE-01 | Standalone preserves current lane and interactions | resolver/handle | geometry/widget test | DONE |
| HANDLE-02 | Notch and pill remove/reclaim the lower lane and track Header bottom | resolver/CoreDashboard | progress geometry/widget test | DONE |
| RAIL-01 | Legacy split buttons remain compatible; rail has one surface/two hit halves/moving pill | direction toggle | widget test | DONE |
| RAIL-02 | Sliding gradient shader rect is full rail, not travelling pill | rail geometry | pure anti-false-green test | DONE |
| RAIL-03 | Rapid semantic selection and current artwork/drag ownership survive | direction toggle/CoreDashboard | interaction regression | DONE |
| LABEL-01 | Balance/Mind label moves value and compresses chart without outer-header growth | shared Header layout | mounted chart/value tests | DONE |
| LABEL-02 | Budget is unaffected | Header mode tests | regression test | DONE |
| MIND-01 | Mind expanded surface choice is session-owned, defaulting to separate cards without resetting global appearance choices | `FluviGlobalAppearance` | unit/controller test | DONE |
| MIND-02 | Separate cards preserves current Mind Header/body geometry, radii and elevation | Mind surface | mounted geometry regression | DONE |
| MIND-03 | Seamless Mind has zero Header/body gap, square internal seam corners, retained outer corners and one elevation | Mind presentation/geometry | structural anti-false-green test | DONE |
| MIND-04 | Seamless expansion has no slit/radius jump and drives existing direction/Summary movement without semantic changes | resolver/Mind surface | collapsed/midpoint/expanded test | DONE |
| MIND-05 | Balance stays modular and Budget unchanged for either Mind setting | cross-mode surfaces | regression test | DONE |
| BUDGET-01 | Budget avatar/content relationship is one independent session setting with three exact variants and the current separate composition as default | `FluviGlobalAppearance` | unit/controller test | DONE |
| BUDGET-02 | Separate preserves existing Budget Header, avatar anchors, content-card bounds, radii and depth | Budget surface | mounted geometry regression | DONE |
| BUDGET-03 | Overlapping glow moves only the Budget detail card upward; avatar anchors remain fixed; only the selected avatar overlaps and tints the card top | Budget surface/layout | mounted bounds/visual-layer test | DONE |
| BUDGET-04 | Avatar rail is behind unchanged avatar anchors; the center avatar alone visibly escapes the rail and the content remains a distinct detail surface | Budget surface/layout | mounted bounds/visual-layer test | DONE |
| BUDGET-05 | Budget relationship choice is live and does not alter Mind, Balance, Budget semantics, selection or controllers | CoreDashboard/mode host | cross-mode/controller regression | DONE |
| PERF-01 | No data/query/repository/physics owner changes | code review/protected tests | source/diff audit | DONE |
| DEL-01 | Exact source has CI, human APK, and SCIP evidence | delivery | workflow/APK/graph | DONE — app `c7579273…`; Actions `36218541043` core/Flutter/APK gates PASS; downloaded human APK and exact-source graph `8b46e53b…`. |
| PHYS-01 | Device visual/installation validation | user | user-only | PENDING — USER ONLY |
