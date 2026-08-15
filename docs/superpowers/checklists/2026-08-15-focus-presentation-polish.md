# Focus presentation and LogBox polish — acceptance checklist

Starting revision: `80c72e54a2da55cfcb11020c6c80f0b90af4c533` (`query`).

## Architecture card

### Scope and sources

- User requirement: transition-safe Query dismissal, shell-backed LogBox
  presentation, and temporary Category/Partner focus without changing the
  committed directional Query.
- Existing owners extended: `DashboardCoreController`,
  `PreparedDashboardIndex`, `DashboardLogBoxPreparedSceneCache`, the stable
  LogBox viewport/render surface, and `FluviSlideUpSheet`.
- New focused owners: `DashboardEphemeralFocusController` for the overlay
  state, `DashboardFocusMembershipSeed` for already-prepared base membership,
  and the viewport-owned `DashboardLogBoxPartnerSwipeController` for one
  transient row translation.

### Single sources and write paths

| State | Owner | Lifetime | Only write path |
| --- | --- | --- | --- |
| Committed directional Query | `CurrentQueryController` | applied Query lifetime | existing Query candidate/Apply flow |
| Category/Partner focus | `DashboardEphemeralFocusController` | exact base-query/revision lifetime | `DashboardCoreController` atomic focus publication |
| Focus membership | `PreparedDashboardDirectionalPartition` | retained base-index lifetime | prepared-index native/codec build |
| One swiped-row translation | `DashboardLogBoxPartnerSwipeController` | one pointer sequence | viewport gesture arbiter |
| Sheet-transition speculation gate | `DashboardCoreController` | reverse route transition | sheet lifecycle callbacks |

### Reuse and boundary decisions

- Cross-axis arbitration extends `GestureDirectionArbiter`, also used by the
  summary pill; the LogBox does not carry a sibling gesture algorithm.
- The renderer receives prepared semantic rows and forwards intents only. It
  does not filter data, create text layouts, access Room, or mutate Query.
- Focus derives an immutable prepared presentation in an isolate from raw
  semantic base membership; it does not issue a repository read from pointer
  input and it never serializes focus into a committed Query key.
- The existing large viewport/render files remain cohesive single-surface
  owners. New pure focus and transient-interaction logic is extracted into
  dedicated files rather than extending their data/query responsibilities.

### Layer flow

`avatar tap / row swipe → viewport interaction → DashboardCoreController →
ephemeral focus owner + derived prepared index → existing scene/cache →
renderer`.

| ID | Source requirement | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QSD-1 | Query-sheet reverse must not contend with speculative work | `FluviSlideUpSheet`, shell, `DashboardCoreController` scheduling boundary | Exact Query publication precedes dismissal; rail/summary/chip speculative work is paused for the real reverse transition and resumes only after it completes | lifecycle unit/widget regression + diagnostics; human heavy-Apply review | PARTIAL — automated contract green; physical hitch review pending |
| LBOX-1 | Shell background continuity / no dark LogBox haze | `DashboardLogBoxRenderSurface`, visual tokens | Empty gutters are transparent to the shell; local card depth does not accumulate as a viewport-wide veil | renderer pixel/structural tests + Android review | PARTIAL — no surface fill and bounded direct card depth proven; Android visual review pending |
| LBOX-2 | Crisp white rounded LogBox bodies | prepared LogBox visual resources + render surface | Card body is final-transform Canvas geometry, never an upscaled cached raster; text/layout cache ownership stays unchanged | renderer structural test + DPR capture/manual check | PARTIAL — direct Canvas path proven; DPR visual review pending |
| FOCUS-1 | Ephemeral category focus | application focus owner, query facet projection, prepared focus scope | Base query is never mutated; focus publishes `base ∩ category`, and clearing restores base | unit/widget state regression | DONE |
| FOCUS-2 | Ephemeral partner focus | application focus owner + presentation gesture arbitration | Base query is never mutated; focus publishes `base ∩ partner`, and clearing restores base | unit/widget state regression | DONE |
| FOCUS-3 | Independent focus composition and stale protection | application focus owner | Category and partner focus intersect independently; new base identity invalidates stale focus | unit regression | DONE |
| FOCUS-4 | Avatar tap safety | viewport interaction owner | True avatar tap focuses once; motion beyond slop delegates to unchanged vertical scroll | interaction regression | PARTIAL — deterministic test green; physical gesture feel pending |
| FOCUS-5 | Left-swipe partner focus | viewport interaction/transient presentation owner | Only deliberate left horizontal gesture wins; vertical/right/diagonal paths cannot focus; transient row reaches viewport edge without rebuilding text | interaction/renderer regression | PARTIAL — deterministic test green; physical swipe review pending |
| PERF-1 | Preserve smooth scrolling boundary | existing vertical/rail controllers and cache owners | Controller, position and physics identities are stable; resource readiness remains geometry-neutral; all miss counters remain fail-closed | `dashboard_scroll_milestone_test.dart` + focused regressions | DONE |
| QUERY-1 | Preserve Query staging and independent directional state | `CurrentQueryController`, prepared index/candidate path | Apply stays atomic; Cancel preserves base; focus is not serialized in base query keys | Query regression suite | DONE |
| ARCH-1 | Ownership / dependency boundary | new focus, gesture, and renderer files | no widget-owned Query/Room work; one focus owner; shared arbitration is reused | cold-start/boundary suite + source inspection | DONE |
| APK-1 | Normal human build / physical follow-up | GitHub Actions | `lib/main.dart` normal APK for exact pushed SHA is downloaded and checksum recorded; visual/gesture acceptance remains pending human confirmation | Actions artifact + SHA-256 | NOT DONE |

## Facts verified before implementation

- The sheet is the custom `FluviSlideUpSheet`, not a `showModalBottomSheet` route.
- Before the fix, chip/rail/summary work could begin after `isOpen` flipped but before
  the reverse layer was removed. The new gate is released from the actual removal
  frame.
- The former fixed-DPR `drawImageNine` group body was removed. Group body/corners now
  use direct final-transform Canvas `drawRRect`; the development-only depth toggle
  isolates the local card foot without introducing a viewport background.
- The prepared index still keeps bounded preview frames. It now additionally carries
  bounded raw semantic base membership per direction (no TextPainters or rich row
  view models) so focus never reads Room from a tap/swipe.

## Verification evidence before delivery

- Focused focus, gesture, query-dismissal, renderer, codec, and avatar suites: green.
- `test/regression/dashboard_scroll_milestone_test.dart`: green.
- `./scripts/test-fluvi-fast.sh`: 184 tests green.
- `./scripts/verify-fluvi-boundaries.sh`: green.
- `flutter analyze --no-pub`: no issues.
- Full `flutter test`: 546 tests green.
- Kotlin `:fluvi-core:compileDebugKotlin`: green in Ubuntu proot.
- Physical Android acceptance for QSD-1/LBOX-1/LBOX-2/FOCUS-4/FOCUS-5 remains pending
  the normal human APK built from the exact pushed SHA.
