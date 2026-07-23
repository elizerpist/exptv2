# Stats Common Snapshot Mode Acceptance Checklist

Reference context:

- Page 1 approved common stats prototype: `docs/prototypes/stats_common_2025_final_0710.html`
- Page 2 approved common stats prototype: `docs/prototypes/stats_common_2025_stat_page_2_final_0710.html`
- Common render spec: `docs/superpowers/specs/2026-07-10-stat-common-render-page1-2-design.md`

New HTML:

- `docs/prototypes/stats_common_2025_snapshot_mode.html`

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SNAP-HTML-01 | User: "egy html fájlt építs" | Prototype file | A standalone snapshot mode HTML exists in `docs/prototypes` | Static test + file inspection | DONE |
| SNAP-REF-01 | Existing approved stats design | Shared shell | Prototype keeps the common stats shell mental model: header/FastInfo, type toggle, SummaryPill, SearchPill, content area | Static test + visual inspection | DONE |
| SNAP-MODE-01 | User: "snapshot mode" | Snapshot concept | UI clearly presents saved snapshots as recallable filter/view presets | Static test + visual inspection | DONE |
| SNAP-DATA-01 | User: "a snapshot elmenti a category scopeot, a bevétel/kiadás oldalt, a tresholdot, és a havi/éves nézetet"; later: "lehet vendor filter is" | Snapshot state | Each snapshot stores category scope, vendor filter, active income/expense side, threshold, annual/monthly view state, target page, and focused month when the saved view is monthly | Static test + JS inspection | DONE |
| SNAP-RECALL-01 | User: "instant előhívhatja" | Snapshot recall | Tapping a snapshot immediately applies its stored category scope, vendor filter, income/expense side, threshold, annual/monthly view state, page, and visible summary state | Static test + JS inspection | DONE |
| SNAP-STEP-01 | User: "nem kellenek a nyíl navigátor gombok, csak swipe, tap-select" | Snapshot navigation | Snapshot navigation uses horizontal swipe of the snapshot card row and tap-select only; no previous/next arrow buttons remain | Static test + JS inspection | DONE |
| SNAP-JOYSTICK-01 | User: "user infinite loopban válthat is instant a joystickkal. drag lef vagy drag right, olyankor egy tick feedback, és egyet steppel" | FAB joystick | Dragging the FAB left/right steps one snapshot per tick in an infinite loop and shows tick feedback for each step | Static test + JS inspection | DONE |
| SNAP-SAVE-01 | User: "fényképezőgép legyen az ikonja" | Snapshot creation | The first snapshot row card is a camera-icon save card that captures the current visible state into a new snapshot | Static test + JS inspection | DONE |
| SNAP-HU-01 | Ongoing stats menu language rule | Visible copy | Snapshot prototype uses Hungarian stats-menu copy, except allowed brand/app name if shown | Static test + visual inspection | DONE |
| SNAP-VIEW-01 | Common render spec | View binding | Snapshots can target Page 1, Page 2, and monthly focused states without introducing old render modes | Static test + JS inspection | DONE |
| SNAP-WARN-01 | Threshold behavior | Threshold warning | Snapshot recall with threshold > 0 shows concise hidden-transaction warning | Static test + visual inspection | DONE |
| SNAP-SHEET-01 | User: "user fabot tappeli ... az egyben egy snapshot editor is" | FAB bottom sheet | Snapshot cards and camera save card live inside the FAB bottom sheet above the threshold slider/input instead of occupying permanent screen space | Static test + visual inspection | DONE |
