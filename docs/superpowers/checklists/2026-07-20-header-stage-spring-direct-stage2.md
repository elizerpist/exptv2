# Header stage spring and direct Stage 2 checklist

User request: deep analysis for header stage release behavior. The user reports that Stage 1 to Stage 0 collapse and Stage 2 to Stage 0 collapse do not receive the expected spring animation at the end, and that Stage 0 cannot be pulled directly to Stage 2 even with a deep pull.

Current root-cause evidence:

- `SpendeeHeaderStageController.release()` already returns `springBack=true` when current drag height differs from the target height.
- `_SpendeeTestDashboardState.build()` already selects `Curves.elasticOut` when `_springBack` is true.
- The dashboard root is keyed with `ValueKey('spendee-test-dashboard-stage-${_stage.name}')`. Because `_endHeaderDrag()` changes `_stage` in the same `setState()` as `_headerHeight`, the keyed root changes identity at release time and can recreate the animated header subtree instead of preserving the previous height for the implicit spring animation.
- `_targetForDragOffset()` cannot return `SpendeeHeaderStage.stage2` from settled `stage0`; it returns only `stage0` or `stage1`. This explains why a deep Stage 0 pull always settles at Stage 1.

| ID | Source instruction or evidence | Intended code area | Acceptance condition | Verification method | Status |
| --- | --- | --- | --- | --- | --- |
| HSG-001 | User report: Stage 1 to Stage 0 collapse has no spring at release | `_SpendeeTestDashboardState._endHeaderDrag`, dashboard root keys, header animation widget | Stage 1 collapse to Stage 0 visibly animates from the dragged height to Stage 0 height using the configured spring/elastic release curve. | `stage 1 collapse keeps the dragged height for spring animation` widget test. | DONE |
| HSG-002 | User report: Stage 2 to Stage 0 collapse also lacks the final spring | Same as HSG-001, plus Stage 2 content teardown timing | Stage 2 direct collapse to Stage 0 preserves the animated header subtree long enough for the spring height animation to be visible, without instantly replacing the whole dashboard subtree. | `stage 2 collapse keeps the dragged height for spring animation` widget test. | DONE |
| HSG-003 | Code evidence: `ValueKey('spendee-test-dashboard-stage-${_stage.name}')` is stage-dependent | Dashboard root/test key strategy | Stage test findability remains available without using a key that recreates the animated subtree during every stage transition. | Stable dashboard root plus non-disruptive stage marker; verified by `test/widget_test.dart` and interaction suite. | DONE |
| HSG-004 | User request: "ha nagyon lehúzzuk, akkor kapja meg az alsó ticket is, és közvetlen stage2 legyen" | `SpendeeHeaderStageController.dragBy` and `_targetForDragOffset` | From settled Stage 0, a deep downward drag crossing both Stage 1 and Stage 2 thresholds emits two haptic ticks and releases directly to Stage 2. | `one deep Stage 0 drag reports both lower haptic thresholds` controller test and `deep stage 0 drag opens stage 2 directly` widget test. | DONE |
| HSG-005 | Existing behavior: Stage 0 height can already be dragged up to Stage 2 height but target is capped to Stage 1 | Header stage release target model | Drag visual height, tick count, armed target, and release target agree; there is no state where the header visually reaches Stage 2 depth but releases to Stage 1 unless the Stage 2 threshold was not crossed. | `Stage 0 drag just below direct Stage 2 threshold releases Stage 1` plus direct Stage 2 threshold tests. | DONE |
| HSG-006 | Current turn asks for analysis, not implementation | Workflow guard | Do not change implementation code until the user explicitly asks to code. | Git diff review confirms only checklist/documentation changed in this analysis step. | DONE |
