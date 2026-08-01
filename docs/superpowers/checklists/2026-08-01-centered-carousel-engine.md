# Centered Motion Carousel Engine Acceptance Checklist

Source instruction: latest user specification for a generic Flutter
`CenteredCarousel<T>` engine, plus the existing Fluvi time-rail behavior
reference previously inspected in the Balance HTML prototype.

Reference behavior:

- Balance prototype: the time rail is a horizontal, center-selected belt with
  continuous scale/opacity interpolation during drag and snap settling.
- Fluvi implementation before this change:
  `lib/features/dashboard/presentation/widgets/time_refinement_rail.dart`
  (legacy `SingleChildScrollView`/`Row`; to be replaced by the shared engine).

## Architecture and ownership

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CCE-ARCH-01 | Structuring Apps: one shared mechanism | `lib/shared/motion/centered_carousel/` | One generic engine owns scroll, selection, visual metrics, friction projection and snap physics; domain adapters contain no duplicate motion logic | Boundary test and source inspection | DONE |
| CCE-ARCH-02 | Structuring Apps: one state owner | `CenteredCarouselController`, dashboard rail owner | Scroll controller and selected/raw index have one owner; dashboard parent does not rebuild on every scroll pixel | Controller/widget tests and source inspection | DONE |
| CCE-ARCH-03 | No external carousel package | `pubspec.yaml`, shared engine | No CarouselSlider/PageView/external carousel dependency is introduced | Boundary/source test | DONE |

## Shared specification and math

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CCE-SPEC-01 | Immutable configurable spec | `centered_carousel_spec.dart` | All item, interpolation, fling, spring, interaction and programmatic-scroll values are configurable with the specified defaults | Unit test | DONE |
| CCE-MATH-01 | Fractional center distance | `centered_carousel_math.dart`, `centered_carousel_metrics.dart` | Every frame derives signed/absolute distance, proximity, scale and opacity from `offset / itemExtent`; center is selected/highlighted | Unit tests | DONE |
| CCE-MATH-02 | Fixed item slot | `centered_carousel.dart` | Slot width is always `itemExtent`; only visual content is transformed | Widget/source test | DONE |
| CCE-MATH-03 | Dynamic side padding | `centered_carousel.dart` | Padding is `max(0, (viewportWidth - itemExtent)/2)`; first and last finite items can center | Widget tests | DONE |

## Motion and interaction

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CCE-PHYS-01 | Friction projection then spring snap | `centered_carousel_physics.dart` | Release velocity is multiplied, projected with `FrictionSimulation`, rounded to an index, bounded, then snapped with `ScrollSpringSimulation` to an exact slot offset | Physics unit tests | DONE |
| CCE-PHYS-02 | Fling limits and direction | `centered_carousel_physics.dart` | Threshold, minimum one-item movement, max velocity, max item count and list bounds all work | Physics unit tests | DONE |
| CCE-CTRL-01 | Central controller API | `centered_carousel_controller.dart` | Controller exposes selected/raw index, scroll controller, animate/jump/update configuration, deduplicated callbacks and optional haptics | Controller tests | DONE |
| CCE-CTRL-02 | Resize/orientation stability | controller/widget lifecycle | Selected index remains stable and is recentered after viewport changes | Widget/controller test | DONE |
| CCE-WIDGET-01 | Generic widget | `centered_carousel.dart` | Horizontal `ListView.builder`, shared physics, per-item listening, semantics, tap-to-center, opacity/scale and transparent unclipped viewport are implemented | Widget tests and source inspection | DONE |
| CCE-WIDGET-02 | Platform-independent input | shared widget/physics | Android touch, web mouse/trackpad and desktop pointer use the same Flutter motion path | Shared source inspection; widget test | DONE |

## Domain adapters and visual contract

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CCE-TIME-01 | Five visible centered rail items | `time_refinement_rail.dart` | Rail presents two items on each side and the nearest center item is selected/highlighted | Widget test | DONE |
| CCE-TIME-02 | Continuous rounded-box rail visuals | `time_refinement_rail.dart`, shared visual tokens | Rail items use the centralized rounded-box radius, white inactive surface, highlight gradient active surface, and engine metrics; no pill-specific shape or background container | Widget/source test | DONE |
| CCE-TIME-03 | Effective infinite belt | time rail adapter | Time values repeat through a sufficiently long centered sequence while the motion engine remains generic and finite/bounds-safe | Widget/controller test | DONE |
| CCE-AVATAR-01 | Reusable avatar adapter | `lib/features/profile/widgets/avatar_carousel.dart` | Avatar adapter uses the same `CenteredCarousel<T>` and receives proximity/signed distance without owning motion logic | Widget/source test | DONE |

## Verification and maintainability

| ID | Requirement/source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CCE-TEST-01 | Required math/physics cases | `test/shared/motion/centered_carousel/` | Zero/small/positive/negative/large velocity, bounds, scale, opacity, symmetry, empty/single-item and callback cases are covered | Focused Flutter tests | DONE |
| CCE-TEST-02 | Widget behavior | `test/shared/motion/centered_carousel/`, domain tests | Drag, fling, tap-to-center, resize and avatar reuse are covered without new golden tests | Focused Flutter tests | DONE |
| CCE-BOUNDARY-01 | Boundary-contract test | `test/boundary/fluvi_boundary_test.dart` or dedicated structural test | Shared engine has no forbidden dependencies and domain adapters do not define physics/scroll listeners | Boundary test/script | DONE |
| CCE-VERIFY-01 | No regression | existing dashboard tests | Existing focused dashboard suites and `git diff --check` pass; no release build is run until requested | Ubuntu/proot Flutter test command | DONE |

Verification note: the focused analyzer run for the new engine and both
adapters reports `No issues found`. A full-project analyzer run still reports
two pre-existing web-platform `dart:html` informational diagnostics in
`lib/core/platform/fullscreen_controller_web.dart`; no new carousel diagnostic
remains.
