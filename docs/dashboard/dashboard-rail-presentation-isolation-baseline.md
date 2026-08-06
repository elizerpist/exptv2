# Dashboard rail/presentation isolation baseline

Date: 2026-08-06

## Recoverable milestone

- Source HEAD before the milestone:
  `c083ef403c45e7365779734d13cd0683a9f371ce`
- Milestone commit:
  `2243cfda9d507f4e55124713c50b320b07520fae`
- Milestone subject:
  `milestone: best dashboard performance before rail presentation isolation`
- Milestone branch:
  `milestone/dashboard-best-performance-before-rail-presentation-isolation`
- Annotated tag:
  `milestone/dashboard-best-performance-before-rail-presentation-isolation-20260806`
- Work branch: `refactor/dashboard-rail-presentation-isolation`

The milestone commit is intentionally empty: its parent and tree preserve the
exact best-performing implementation. Existing untracked `.tmp-*` logs and
`test/features/dashboard/presentation/failures/` are user-owned artifacts and
were neither modified nor committed.

## Baseline source hashes

| Ownership | File | SHA-256 |
|---|---|---|
| dashboard rail widget | `lib/features/dashboard/widgets/time_refinement_rail.dart` | `e669d118a2dd6607d295543ddc848f1683d538486b1270b02b8e981b1fbf684a` |
| presentation re-export | `lib/features/dashboard/presentation/widgets/time_refinement_rail.dart` | `5cb67e0aaf92b44430534d28da68832daa9ff52bd95989e0262e60a5a15feaa9` |
| viewport/gesture widget | `lib/shared/motion/centered_carousel/centered_carousel.dart` | `d454fc2608fbf4532745fe39e0c4b9c6aaefdc511e3f946b6788899f8bf8fcc6` |
| controller/position owner | `lib/shared/motion/centered_carousel/centered_carousel_controller.dart` | `2ce33c8a88a52585049d6cb95304e0487097a3e00bbf52b5e694ecb3d1350bbb` |
| physics | `lib/shared/motion/centered_carousel/centered_carousel_physics.dart` | `1b3539cea8ac2870f7fae2c64e78f657187df0046b01d77e21c295c8c2c8a5ec` |
| carousel math | `lib/shared/motion/centered_carousel/centered_carousel_math.dart` | `5558bf2bf909a6316c337e07a777addfc44430060f03cc3070e28a3ad366a6e8` |
| carousel metrics | `lib/shared/motion/centered_carousel/centered_carousel_metrics.dart` | `6d9d73066afcf6cef698ec2bb3939b2d3f4ea6168ae9253bf782b6081fa7008a` |
| prepared index | `lib/features/dashboard/runtime/domain/prepared_dashboard_index.dart` | `470ff2f595d57460abc453eca04480f4cc3f02a76a20d24a9829911463ad27e5` |

The Flutter framework's `ScrollPosition` is used directly; Fluvi has no
feature-local `ScrollPosition` implementation to hash. Its concrete identity
is instead captured by the existing widget identity test and will be captured
per fling by the new diagnostic recorder.

## Fresh local verification

Commands ran through Ubuntu proot, not the Termux Flutter binary:

```bash
find test -type f -name '*_test.dart' ! -name '*_golden_test.dart' -print0 |
  xargs -0 /home/flutteruser/flutter/bin/flutter test --reporter compact

/home/flutteruser/flutter/bin/flutter analyze
```

Results:

- non-golden Flutter suite: **237/237 PASS**;
- Flutter analyze: **PASS**, `No issues found!`;
- no golden test was run or generated.

## Current interaction/data counters

The latest committed A–J profile for this exact implementation lineage proves
the following navigation/motion deltas:

| Counter | Baseline value |
|---|---:|
| navigation-triggered SQL | 0 |
| navigation-triggered repository reads | 0 |
| navigation-triggered native exact-scope subscribes | 0 |
| navigation-triggered native exact-scope cancels | 0 |
| navigation-triggered bridge payloads | 0 |
| navigation-triggered index builds | 0 |
| motion-time LogBox projections | 0 |
| motion-time formatting | 0 |
| global revision subscriptions per session | 1 |
| controller recreations | 0 |
| physics recreations | 0 |
| ScrollPosition recreations | 0 |

Bootstrap remains one immutable index build with five counted SQL reads. The
recorded payload is 193,830 bytes, 256 frames and 700 source rows. These are
bootstrap costs, not interaction deltas.

## Current performance reference

The most recent headless Android emulator profile used the unchanged scripted
`tester.fling` input and reported:

| Pair | Populated UI p95 | Empty UI p95 | Endpoint delta |
|---|---:|---:|---:|
| year → month | 11.036 ms | 3.759 ms | 0 children |
| month → day | 13.394 ms | 4.720 ms | 0 children |
| first → tenth month/day | 11.825 / 8.446 ms | n/a | 0 children |

The synthetic test delivered the same semantic endpoint, but populated frames
used materially more UI time and built visible LogBox rows while empty frames
built none. The old harness did not capture raw pointer sample cadence,
gesture-release velocity, exact ballistic handoff, activity replacement or
metric correction, and ran each density comparison only once. Therefore this
is a performance correlation, not yet the causal root-cause proof required by
the current task.
