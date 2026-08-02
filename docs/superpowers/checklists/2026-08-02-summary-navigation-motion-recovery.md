# Summary navigation motion recovery checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SNM-01 | User: keep working rail/query/amount path unchanged | shared carousel, query, amount, navigation | No shared-carousel diff; preview does not create a query; amount remains outside navigation motion. | Existing physics/query tests, focused widget test, diff inspection | NOT DONE |
| SNM-02 | User: every real rail tick moves mother + child together | rail adapter + motion region | One changed nearest logical index produces one Y-only impulse on the full text block, capped at 4 px; initial/duplicate/settle/rebase/recenter do not. | Unit and widget tests | NOT DONE |
| SNM-03 | User: no queue or double haptic | tick controller | Rapid ticks retarget one controller and return to zero; no motion code invokes haptics. | Controller/widget test and source inspection | NOT DONE |
| SNM-04 | User: horizontal parent X + fade | common text transition | Forward/backward parent commits animate the whole block in X only with concurrent opacity, same 170-ms fade language and latest-wins replacement. | Math and widget frame tests | NOT DONE |
| SNM-05 | User: horizontal drag feedback/boundaries | SummaryPill gesture + motion region | Drag previews current/candidate blocks; commit continues motion while query starts independently; cancel returns; SUM resists only. | Widget tests including YEAR/MONTH/SUM | NOT DONE |
| SNM-06 | User: rail and pill gestures isolated | rail/SummaryPill widgets | Rail drag never begins parent transition; pill swipe never drags rail. | Gesture integration test | NOT DONE |
| SNM-07 | User: delivery | repository/CI/release | All checklist items are verified, committed, pushed, built online and APK downloaded. | Proot suite, GitHub Actions, SHA-256 | NOT DONE |
