# SummaryPill Projection and Motion Checklist

Source: approved SummaryPill refinement request, 2026-08-01.

| ID | Source requirement | Intended code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| SP-01 | Separate navigation projection | `time_navigation/presentation`, SummaryPill | `SummaryNavigationPresentation` is derived only from synchronous navigation state; title/subtitle do not read query state. | Presenter unit test and delayed-query widget test. | DONE — projection is query-independent and the delayed-query test is green. |
| SP-02 | Separate amount projection | query presentation/controller boundary | `SummaryAmountPresentation` updates independently and keeps the previous amount visible while a new scope loads. | Fake delayed-query widget test. | DONE — stale amount remains visible and crossfades after the delayed result. |
| SP-03 | Immediate child settle | navigation controller + SummaryPill | A settled child updates subtitle by the next Flutter frame, independently of query completion. | Delayed-query widget test with a two-second fake repository. | DONE — next-frame subtitle assertion is green. |
| SP-04 | Rail toggle hierarchy | SummaryPill presentation | Rail open/close keeps the plane title stable and morphs only the subtitle. | Rail toggle widget test. | DONE — title stability and subtitle-only update are green. |
| SP-05 | Cyclic plane ring | `DashboardTimeNavigationController` | Up cycles SUM→YEAR→MONTH→SUM and down cycles SUM→MONTH→YEAR→SUM; cursors survive wrapping. | Controller transition tests over two full cycles. | DONE — both four-step sequences and cursor preservation are green. |
| SP-06 | Plane transition axis | `SummaryPillTextTransition` | Plane changes move title/subtitle only on Y; every sampled frame has `dx == 0`. | Transition unit/widget axis-purity test. | DONE — vertical offset samples are green. |
| SP-07 | Parent transition axis | `SummaryPillTextTransition` | Parent changes move the subtitle only on X; every sampled frame has `dy == 0`. | Transition unit/widget axis-purity test. | DONE — horizontal offset samples are green. |
| SP-08 | Latest-wins transitions | text transition component | A new content snapshot interrupts the old animation; stale completion cannot restore old text. | Rapid replacement widget test. | DONE — latest subtitle remains after interruption. |
| SP-09 | Gesture feedback and cancellation | `DashboardSummaryPill` | Drag feedback is small and axis-locked; cancelled gestures spring/ease back without navigation or haptic. | Gesture widget tests. | DONE — committed/cancelled gesture behavior is green. |
| SP-10 | SummaryPill haptic | `DashboardSummaryPill` gesture layer | Exactly one selection haptic occurs for a committed gesture; cancelled gestures emit none. | Injectable haptic test seam/widget test. | DONE — one committed tick and zero cancelled ticks are asserted. |
| SP-11 | Contextual child labels | `time_refinement_rail.dart` presentation adapter | YEAR child chips render only localized month names; domain mapping and rail physics remain unchanged. | Label formatter unit/widget test and physics regression suite. | DONE — month label and shared physics tests are green. |
| SP-12 | Rail non-regression | shared carousel boundary and existing tests | No child carousel engine/controller/spec/data-source or wiring behavior is modified; the only rail change is the presentation-only month label adapter. | Git diff path audit plus existing targeted tests. | DONE — protected engine/controller/spec/data-source paths are unchanged; all 162 non-golden tests pass. |
| SP-13 | Full subtitle context | `summary_navigation_presentation.dart`, shared time formatter | YEAR-open shows `YYYY. month`; MONTH-open shows `YYYY. month day.`; child chips remain short. | Presenter unit tests for all plane/rail combinations. | DONE — full-context presenter cases pass. |
| SP-14 | Settled-path timing | navigation controller, dashboard aggregate, SummaryPill | Settled commit is synchronous and atomic; query/amount cannot delay navigation text. | Focused settle-path test plus debug timing marks. | DONE — atomic controller test passes; S0–S8 marks cover the boundary. |
| SP-15 | Preview-to-settle continuity | navigation state/projector, text transition | Preview value is the displayed child; settle commits the same value without reverting or starting a second morph. | Preview→settle continuity widget/controller test. | DONE — displayed-child and atomic settle assertions pass. |
| SP-16 | Immediate tap target | child-selection presentation boundary | A one-step target is visible by the next frame and remains visible through settle. | One-tile tap/target regression test. | DONE — pending/preview target path is covered by the settle continuity and delayed-query tests. |
| SP-17 | Latest-wins deduplication | `summary_pill_text_transition.dart` | Identical rendered navigation content does not restart a transition; stale completion cannot restore old content. | Rapid replacement and same-content revision widget tests. | DONE — rapid replacement passes; equal content is deduplicated by content identity. |
| SP-18 | Single-line month labels | `time_refinement_rail.dart` presentation only | All Hungarian month names remain one line, fully visible, and scale down only the text. | Hungarian month stress widget test. | DONE — all 12 labels and visible rail FittedBox constraints pass. |
| SP-19 | Protected rail engine | shared carousel files and wiring | No physics/controller/spec/itemExtent/spacing/viewport/data-source/wiring changes. | Diff path audit plus unchanged carousel regression suite. | DONE — protected paths are unchanged and rail regression tests pass. |

## Explicitly protected files

The implementation may not modify the shared child rail engine or its wiring:

- `lib/shared/motion/centered_carousel/centered_carousel.dart`
- `lib/shared/motion/centered_carousel/centered_carousel_controller.dart`
- `lib/shared/motion/centered_carousel/centered_carousel_physics.dart`
- `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`
- `lib/features/dashboard/widgets/time_refinement_rail.dart` except the presentation-only label adapter
- `lib/features/dashboard/time_navigation/presentation/time_rail_data_source_factory.dart`

The last two paths may only receive label/presentation changes where explicitly required; no physics, controller, spec, data-source, callback, item, or wiring behavior may change.
