# Summary navigation motion recovery checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| SNM-01 | User: keep working rail/query/amount path unchanged | shared carousel, query, amount, navigation | No shared-carousel diff; preview does not create a query; amount remains outside navigation motion. | `git diff` inspection; `dashboard_core_controller_test`; `summary_pill_presentation_widget_test` | DONE |
| SNM-02 | User: every real rail tick moves mother + child together | rail adapter + motion region | One changed nearest logical index produces one Y-only impulse on the full text block, capped at 4 px; initial/duplicate/settle/rebase/recenter do not. | Motion-controller, motion-region, rail adapter tests; tick golden | DONE |
| SNM-03 | User: no queue or double haptic | tick controller | Rapid ticks retarget one controller and return to zero; no motion code invokes haptics. | Controller/widget tests and source inspection | DONE |
| SNM-04 | User: horizontal parent X + fade | common text transition | Forward/backward parent commits animate the whole block in X only with concurrent opacity, same 190-ms fade language and latest-wins replacement. | Transition math, widget frame tests, horizontal-drag golden | DONE |
| SNM-05 | User: horizontal drag feedback/boundaries | SummaryPill gesture + motion region | Drag previews current/candidate blocks; commit continues motion while query starts independently; cancel returns; SUM resists only. | YEAR/MONTH/SUM widget tests; December-to-January preview test; parallel callback timing assertion | DONE |
| SNM-06 | User: rail and pill gestures isolated | rail/SummaryPill widgets | Rail drag never begins parent transition; pill swipe never drags rail. | `core_dashboard_test`; SummaryPill and rail widget tests | DONE |
| SNM-07 | User: delivery | repository/CI/release | All checklist items are verified, committed, pushed, built online and APK downloaded. | Proot suite, GitHub Actions, SHA-256 | PARTIAL |

## Verification notes

- Focused motion, rail, query, gesture and golden suite: 54 tests passed after
  the final lifecycle review fixes. This includes the rail physics, gesture
  isolation, preview-without-query and the two motion golden checks.
- Changed-source `dart analyze` completed with no issues. The repository-wide
  `flutter analyze --no-fatal-infos` had only the three pre-existing infos
  outside this change (`fluvi_diagnostic_event.dart` and the web fullscreen
  adapter) before the final targeted check.
- Independent review found and the final suite covers: stale cancel completion
  cannot clear a later gesture; horizontal drag release is curve-continuous;
  rail reconfiguration resets the presentation dedupe baseline before the
  next real tick.
- The complete suite has two known, environment-specific dashboard golden
  failures. They reproduce unchanged on the pre-work baseline commit `1005230`
  (expanded: 14.79%; collapsed: 12.56%) and concern whole-surface SVG/shadow
  rendering rather than the SummaryPill motion region. The two new motion
  goldens pass.
