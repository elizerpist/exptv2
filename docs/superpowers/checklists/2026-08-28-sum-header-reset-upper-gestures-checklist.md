# Acceptance checklist — SUM scale, Header semantics, Summary reset and upper gestures

**Baseline:** `separated-core-modes` at `79ce29e9`; Drive *Fluvi Logs* r45;
supplied conceptual SUM reference:
`/storage/emulated/0/Pictures/Screenshots/Screenshot_20260828-073311.png`.
No physical Android acceptance is claimed by this checklist.

| ID | Source / intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- |
| SUM-01 | User / shared ring painter | Exactly three .50/.75/.90 scale spheres lie on the canonical clockwise source track centreline | `budget_category_avatar_rail_test.dart` pure geometry | DONE |
| SUM-02 | User / shared sphere material | .50 green, .75 yellow and .90 red preserve health hue family and use DAY’s geometry/material authority; typical marker remains separate | source/material test | DONE |
| HDR-01 | User / Header metric projection | DAY/MONTH/YEAR/SUM expose Napi tempó/Havi állás/Éves állás/Havi átlag and tempó/havi budget/éves budget/alap budget exactly once | presentation test | DONE |
| HDR-02 | User / Budget Header | Primary pairs use daily average/allowed daily average, monthly actual/limit, annual actual/resolved total, average/base respectively | controller + DAY widget regression | DONE |
| RST-01 | User / reset target resolver | Background reset targets canonical logical current MONTH/year/month and skips already matching dimensions/no-op | pure sequencer tests | DONE |
| RST-02 | User / selector command seam | Reset visibly sequences normal carousel crossings and uses Core prepared candidate publication rather than direct final assignment | selector command source path + sequencer tests | DONE |
| RST-03 | User / hit arbitration | Only Summary non-selector background taps reset; selector flings, drags and mirrored layouts preserve existing owner | background/selector widget test and shared Rect resolver | DONE |
| RST-04 | User / lifecycle | At most one reset is live; direct Summary/avatar/direction/upper input cancels stale generations | sequencer generation test + direct input hooks | DONE |
| GST-01 | User / upper gesture coordinator | Header and collapse handler keep the exact expansion semantics through one underlying expansion controller | coordinator test + Core wiring | DONE |
| GST-02 | User / direction and Summary backgrounds | Direction tap selects direction; vertical drag expands. Summary background tap resets; vertical drag expands; selectors never expand | direction arena + normal/mirrored Summary background drag/hit tests | PARTIAL — physical gesture matrix still required |
| GST-03 | User / mode content | Non-interactive upper card surface vertically expands without stealing avatar/pager/donut taps or horizontal controls | host background-layer source review | PARTIAL — full widget conflict matrix still required |
| GST-04 | User / nested scrolling | Upper internal list consumes vertical drag first; same-pointer boundary overscroll reaches expansion; controller and position identity/offset survive | ListView handoff/identity widget test | DONE |
| REG-01 | MILESTONE_COMMITS | Prepared navigation/cache, one LogBox controller/position, foreground input priority, bounded paint and Budget scope semantics remain intact | focused protected suites plus full-suite attempt | PARTIAL — full suite is blocked by four reproduced inherited tests listed in the plan |
| DOC-01 | User documentation | Final plan records formulas, labels, tick/cancel state machine, ownership and real verification evidence without false physical claim | this plan/checklist | DONE |
| DEL-01 | User delivery | Focused production commit is pushed; matching human APK job succeeds and downloaded APK SHA-256 is recorded | git + Actions + filesystem | NOT DONE |
