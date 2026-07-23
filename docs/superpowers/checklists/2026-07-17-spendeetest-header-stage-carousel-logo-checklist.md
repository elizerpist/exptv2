# SpendeeTest Header Stage, Carousel, Diagram, and Logo Checklist

Source of truth: `docs/prototypes/color_lab.html`

Verified release evidence:

- Targeted SpendeeTest tests: 35/35 PASS.
- Transaction tests: 57/57 PASS.
- Golden update and rerun: PASS; reviewed by visual inspection.
- Final full suite: 912/912 PASS in 09:58.
- `flutter analyze`: clean in 42s.
- `git diff --check`: clean.

| ID | Source Instruction / Reference | Intended Code Area | Acceptance Condition | Verification Method | Status |
|---|---|---|---|---|---|
| HDR-001 | User: header stage 0-1-2 states | `spendee_header_stage_controller.dart`, `spendee_test_dashboard.dart` | Stage 0, 1, and 2 settle consistently after drag/release. | Flutter controller tests + manual app drag check. | DONE - targeted 35/35; full suite 912/912. |
| HDR-002 | User: tick must be felt while dragging handle | Header drag thresholds and haptics | Threshold crossing emits one selection tick per threshold per pointer sequence. | Flutter controller tests + manual haptic check. | DONE - targeted 35/35; full suite 912/912. |
| HDR-003 | User: stage 1 tick position equals stage 1 height | Stage 1 trigger math | Stage 0 -> stage 1 trigger occurs when dragged header reaches C2/stage1 height, not before. | Controller tests assert trigger distance equals `stage1Height - stage0Height`. | DONE - targeted 35/35; full suite 912/912. |
| HDR-004 | User: release before tick collapses with spring | Release animation | Releasing below stage 1 trigger returns to stage 0 with spring animation. | Controller tests + widget animation inspection. | DONE - targeted 35/35; full suite 912/912. |
| HDR-005 | User: overshoot beyond stage 1 collapses back smoothly to stage 1 | Release animation | Dragging below/past stage 1 then releasing animates back to stage 1, no instant jump. | Controller tests assert spring for overshoot-to-stage1 + manual drag check. | DONE - targeted 35/35; full suite 912/912. |
| HDR-006 | User: popping stage 1 toward stage 0 also springs | Stage 1 popout/collapse | Stage 1 -> stage 0 collapse path uses spring. | Controller tests assert spring on stage1 collapse. | DONE - targeted 35/35; full suite 912/912. |
| HDR-007 | User: same rules for stage 2 | Stage 2 trigger/release math | Stage 1 -> stage 2 trigger occurs at C3/stage2 height; overshoot and collapse paths animate with spring. | Controller tests for stage2 trigger and overshoot. | DONE - targeted 35/35; full suite 912/912. |
| CAR-001 | User: stage 1/2 category avatars use old backheader wheel behavior | `spendee_center_carousel_controller.dart`, stage carousel UI | Swipe/fling feels like a wheel, slows down, then snaps to an avatar. | Controller tests + manual swipe check. | DONE - targeted 35/35; reviewed golden rerun PASS. |
| CAR-002 | User: current swipe shifts whole row incorrectly | Stage carousel layout | Carousel visual offset is residual/inertial only; final row is centered and snapped. | Widget tests/manual swipe check. | DONE - targeted 35/35; reviewed golden rerun PASS. |
| CAR-003 | User: avatars animate when edge avatar moves to center | Stage carousel item animation | New centered avatar performs grow-shrink pulse. | Widget animation test + manual check. | DONE - targeted 35/35; full suite 912/912. |
| LOG-001 | User: logbox avatar design must match category avatar design | `transaction_log_box.dart`, experimental `_SpendeeLogBox` | Logbox avatars use same glossy circle layering as category avatars. | Widget inspection + screenshot/manual check. | DONE - transaction 57/57; golden visual inspection. |
| LAY-001 | User: `color_lab.html` C1/C2 source of truth | Header visual/layout spec | C1/C2 values are read from HTML and centralized in Flutter spec/controller. | Code inspection and tests. | DONE - targeted 35/35; analyze clean in 42s. |
| LAY-002 | User: stage1 glossy container removes partition progress bar | `_BudgetExtendedInfo` | Stage 1 glossy container contains avatar carousel only, not spent/remaining labels or partition bar. | Widget test + manual check. | DONE - targeted 35/35; golden visual inspection. |
| LAY-003 | User: partitioned progress bar moves under limit number in stage 0 | Header core | Header core shows only partition bar under the limit number, visible in all expanded stages. | Widget test + manual stage checks. | DONE - targeted 35/35; golden visual inspection. |
| LAY-004 | User: stage1 glossy container size/position matches C2 | Header layout | Stage 1 glossy container is positioned at left/right 16, top 96, height 130, matching C2. | Code inspection + widget size test. | DONE - targeted 35/35; reviewed golden rerun PASS. |
| LAY-005 | User: avatar sizes match C2 | Avatar spec | Category avatar sizes are center 66, near 46, outer 36 with matching icon sizes. | Widget test + code inspection. | DONE - targeted 35/35; reviewed golden rerun PASS. |
| LAY-006 | User: stage1 bottom C2 and stage2 bottom C3 pixel exact | Stage geometry | Stage 1 bottom equals C2; stage 2 bottom equals C3 bottom formula. | Controller/spec tests for 412x892 viewport. | DONE - targeted 35/35; reviewed golden rerun PASS. |
| DIA-001 | User: stage2 donut diagram must match C3 | `_BudgetPiePanel`, `_BudgetPiePainter` | Donut uses C3 dimensions: SVG 112, viewBox 120, center 60, radius 40, base stroke 13, selected stroke 17. | Painter/widget tests + screenshot/manual check. | DONE - targeted 35/35; golden visual inspection. |
| DIA-002 | User: highlighted segment has outer glow | `_BudgetPiePainter` | Selected donut arc gets outer glow/drop-shadow equivalent. | Painter pixel test/manual check. | DONE - reviewed golden rerun PASS and visual inspection. |
| DIA-003 | User: inner glass circle radius is HTML value and no padding to selected slice | `_BudgetPiePainter` | Inner glass disc radius is 29 in 120 viewBox scale; selected stroke inner edge touches it visually. | Painter geometry test/code inspection. | DONE - targeted 35/35; golden visual inspection. |
| DIA-004 | User: donut list rows tappable and set highlighted category | `_BudgetPiePanel`, dashboard state | Tapping a row selects that category and updates highlighted donut segment. | Widget tap test/manual check. | DONE - targeted 35/35; full suite 912/912. |
| DIA-005 | User: avatars tick until selected category is reached | Programmatic carousel selection | List tap animates/ticks avatar carousel to selected category and settles centered. | Controller/programmatic selection test + manual check. | DONE - targeted 35/35; full suite 912/912. |
| LOGO-001 | User: D1A logo + brand name + motto source of truth | Brand lockup UI | Brand lockup uses D1A layout: logo left 30, top 6, size 47.88; wordmark left 82.25, top 10.602, size 30.096; tagline ratio .46. | Widget geometry test + code inspection. | DONE - targeted 35/35; reviewed golden rerun PASS. |
| LOGO-002 | User: tapping logo opens slide-up logo editor sheet | Dashboard brand/logo interaction | Logo tap opens bottom sheet editor. | Widget tap test/manual check. | DONE - targeted 35/35; full suite 912/912. |
| LOGO-003 | User: editor contains all HTML palette colors and preview | Logo editor sheet | Editor includes palette slots from HTML and live logo preview. | Widget test + code inspection. | DONE - targeted 35/35; analyze clean in 42s. |
| LOGO-004 | User: tap slot then logo component recolors it | Logo editor state | Selecting a palette/custom slot then tapping a logo path updates that component color. | Widget test/manual check. | DONE - targeted 35/35; full suite 912/912. |
| LOGO-005 | User: 5 custom gradient slots with editable left/right and slider ratio | Logo editor custom slots | Exactly 5 custom slots exist; left/right endpoints use selected palette color and boundary slider updates gradient ratio. | Widget test/manual check. | DONE - targeted 35/35; full suite 912/912. |
| BUILD-001 | User: one big build at end only | GitHub Actions | Only one final online build is triggered after all implementation and one commit/push. | Git/GitHub command log. | DONE - commit `bd90302accbb60a3344dec7050448ffc7551e958`; sole `workflow_dispatch` run [29611003495](https://github.com/elizerpist/exptv2/actions/runs/29611003495) completed successfully. |
| BUILD-002 | User: download APK to `/storage/emulated/0/Download/spendee` | GitHub release/artifact download | Final APK is downloaded into the requested folder. | File existence check. | DONE - run `29611003495` release asset `exptv2-debug-bd90302.apk` downloaded to `/storage/emulated/0/Download/spendee/exptv2-debug-bd90302.apk`; 155379398 bytes; SHA-256 `801455d032aef7ebef6e0e73c7881d6d05f22af389447888bb6c9cc3ef9ad9f5`. |
