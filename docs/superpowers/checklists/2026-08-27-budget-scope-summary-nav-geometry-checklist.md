# Acceptance checklist — Budget scope refactor and physical geometry repairs

Baseline: branch `separated-core-modes`, local/remote `58bd90eb4aa7a62584869ccad40f747ac1f5268c`, clean worktree, Fluvi Logs revision 45. Source: user task issued 2026-08-27, current source, r45, and three supplied physical screenshots. `NOT DONE` means not yet verified; no physical acceptance is claimed here.

| ID | Requirement / intended owner | Acceptance condition | Verification | Status |
|---|---|---|---|---|
| SUM-01 | `SummarySegmentedTrackGeometry` | one Rect owns visual, clip, hit and semantics; no `visualOffsetForTrack` | pure + physical widget fling tests | DONE |
| SUM-02 | Summary geometry | large icon only; left inset equals top inset; all active content fits | geometry/widget tests | DONE |
| SUM-03 | Summary geometry | equal active gaps = pre-regression content-edge gap / 2; stable amount zone/separators | resolver/widget tests | DONE |
| SUM-04 | Summary settings/tuner | mode-layout enum/control/runtime variants removed, no persistent active choice | unit/widget tests | DONE |
| SUM-05 | temporal controller/trio | prepared YEAR/MONTH/DAY publication remains foreground; Trio collapses immediately at idle | interaction/fake-motion tests | DONE |
| NAV-01 | `Bnb03BottomNavigationContour` | FAB and nav exact centre; left/right contour and clearance mirror | pure geometry tests | DONE |
| NAV-02 | BottomNav painters | fill/clip/stroke use one geometry; one continuous optional contour in rounded/straight modes | raster/widget matrix | DONE |
| LIM-01 | limit domain/native schema | only active base-month and YearMonth override limit truth | Dart tests green; native Kotlin compiles; Room execution pending CI | PARTIAL |
| LIM-02 | migration | MONTH wins, SUM→base, YEAR seeds missing month values deterministically; idempotent | migration matrix authored; native Room execution pending CI | PARTIAL |
| LIM-03 | resolved month | `override ?? base ?? unavailable` is sole denominator authority | resolver tests | DONE |
| ANA-01 | typed scope analyses | Day/Month/Year/Sum semantic numerators and denominators cannot collapse into generic actual | controller tests | DONE |
| ANA-02 | Day projection | Core as-of date, zero calendar days, selected-day invariance, no DB read, forecast distinct from edit actual | pure/controller tests | DONE |
| ANA-03 | Year/Sum analyses | 12-month bounded aggregation/vector edit exactness; cached completed-month typical average | pure/controller tests | DONE |
| EDT-01 | edit controller/repository | Month/Day same override; Year atomic proportional vector with identity-serialized stale-write protection; Sum base only | optimistic/batch Dart tests green; native batch lane pending CI | PARTIAL |
| RNG-01 | shared ring authority | same Fluvi geometry/material/caps for all strategies | source-contract/painter tests; production painter consumes `BudgetProgressRingGeometry.source` | DONE |
| RNG-02 | scope fills | Month clockwise; Day bottom-up/.75 marker; Year 12 independent slots; Sum short marker | visual/pure tests | DONE |
| PRF-01 | prepared inputs | avatar/time interactions resolve first visible state with zero repository I/O; no scan/rebuild | targeted prepared-path tests green; CI profile pending | PARTIAL |
| REG-01 | protected dashboard | LogBox controller/position, query semantics, bounded scene caches, legacy Summary all survive | `scripts/test-fluvi-fast.sh`: 273 passed | DONE |
| VER-01 | delivery | targeted/protected tests, native tests, analyse, diff check, GitHub human APK run/download | ongoing; no physical approval claimed | PARTIAL |
