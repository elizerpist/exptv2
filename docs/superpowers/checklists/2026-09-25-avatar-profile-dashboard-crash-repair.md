# Acceptance checklist — Avatar profile dashboard crash repair

Scope authority: physical Android screenshot and the user-approved **FLUVI —
Critical Fix: Avatar Color Profile Switch Destroys the Dashboard on Physical
Android** request, 2026-09-25.

Affected behavioral source: `368b482c8bfcb5aed0d5e351f4e07fc9863ccc40`;
documentation head at investigation start:
`ac0f7d4fd25e901e6d2c50ea76af6d7e44feedb3`.

## Architecture card

| State/resource | Sole owner / write path | Rendering consumers | Required boundary |
| --- | --- | --- | --- |
| Selected avatar profile | `DashboardHeaderVisualController.setAvatarColorProfile` | profile scope, Header tuning, CoreDashboard | presentation-only mutation; no domain/query write |
| Profile-specific LogBox resources | `PreparedVectorAssetAtlas.prepareLogBoxRasters` | shell bootstrap, CoreDashboard, LogBox | a ready DPR has all four immutable profile banks |
| Dashboard lifecycle | existing `CoreDashboardState` | Header/cards/LogBox/mode surfaces | bank selection cannot throw from `build` or remount/reset state |

| ID | Requirement / source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| REP-01 | Physical Android symptom | Production-parent dashboard test | Reproduce the profile-switch failure and capture the first framework exception/stack before production changes. | RED widget test with `takeException`. | DONE — changing the view DPR after ready-state and selecting Pastel raised `StateError: Bad state: LogBox raster resources are not prepared for DPR 2.625.` before the repair. |
| ROOT-01 | Suspected resource boundary | Atlas + CoreDashboard + shell | Prove or reject the synchronous profile-raster lookup hypothesis from an exact exception and current source. | Captured exception plus source trace. | DONE — pre-repair `CoreDashboard.build()` called `logBoxRastersFor(View.of(context).devicePixelRatio, profile: ...)`; the captured StateError is its missing-DPR branch. |
| RES-01 | All profile readiness | Prepared atlas | For a prepared DPR, each of original/pastel/saturated/vivid has a valid immutable LogBox raster bank. | Atlas readiness/profile matrix test. | DONE — `PreparedLogBoxRasterBank` is exhaustive and the atlas test proves all four sets after prepare at DPR 1 and 2. |
| CORE-01 | Physical failure shape | CoreDashboard production parent | On every profile switch, `ready-core-dashboard`, Header, direction controls, Summary, mode host and LogBox stay mounted without ErrorWidget or exception. | Mounted regression. | DONE — populated production-parent Original → Pastel → Saturated → Vivid → Original test remains live and exception-free. |
| CONT-01 | User interaction invariants | CoreDashboard/LogBox/mode hosts | State identity, mode, Summary, Query, direction, ScrollPositions and carousel/controller identities remain unchanged. | Profile-cycle production-parent tests. | DONE — core, LogBox and Balance-carousel state identities plus mode, Query generation and direction are retained by the profile-cycle regression. |
| VIS-01 | Avatar presentation contract | Profile scope/atlas/badges | Same semantic handles and rows render requested profile colours in generic badges, Balance, Budget and LogBox. | Cross-surface profile tests. | DONE — profile-specific LogBox set is asserted in the production dashboard regression; existing category/budget appearance coverage remains focused-green. |
| SAFE-01 | Crash containment | Profile-bank boundary | A missing alternate bank cannot grey-screen CoreDashboard; fallback, if necessary, is deterministic Original presentation only and does not mutate selected profile. | Missing-bank/diagnostic test. | DONE — shell supplies an exhaustive immutable bank before dashboard readiness; `forProfile` has an Original visual fallback for malformed future input and the profile state is never changed. |
| PERF-01 | No-data-work boundary | Appearance controller + atlas | Switching uses already-prepared in-memory banks with no repository/Query/index/scene/financial work or extra decode. | Counters/resource tests. | DONE — the mounted profile-cycle asserts no index prepare, picture decode or raster build increase, and no Query/direction mutation. |
| REG-01 | Protect 368b global appearance | Existing tuner/controller | Direction profiles, artwork toggle and global typography remain functional. | Focused no-regression tests. | DONE — focused global appearance/controller, category badge and Budget-avatar suites exercised the retained controls. |
| DEL-01 | Delivery rule | GitHub Actions + SCIP | Exact repair SHA has human APK evidence and separate exact-source graph. | CI/APK/tooling proof. | NOT DONE |
| PHYS-01 | User evidence boundary | Android user | Repaired APK must be physically retested; previous avatar-switch validation is FAIL. | User only. | FAIL — AVATAR PROFILE SWITCH |
| MENU-01 | Custom-settings density feedback, 2026-09-25 | Header visual tuner + its existing controller | Every top-level custom-settings topic, including `Körvonalak`, is a named collapsible section rather than an always-open block. | Focused mounted tuner widget test. | DONE — all existing top-level tuner topics use the same `_DashboardHeaderTunerTopic` chrome, while the established Borders, LogBox palette, corner and animation sections remain in that same owner. |
| MENU-02 | Custom-settings density feedback, 2026-09-25 | Existing tuner-section session state | New sections start collapsed; opening/collapsing a topic changes only its UI chrome and preserves its contained setting values. | Controller/widget interaction test. | DONE — a fresh controller has no expanded sections; the widget test sets a border value, collapses its topic and proves the value survives. |
| MENU-03 | Custom-settings density feedback, 2026-09-25 | Tuner semantics/layout | The section headers expose expanded/collapsed semantics, retain stable keys, and do not duplicate their child headings. | Mounted widget assertions and source inspection. | DONE — `_CollapsibleTunerSection` retains `Semantics(expanded: ...)`, stable topic keys and suppresses only the direct duplicate child heading. |
