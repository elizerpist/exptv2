# Budget category avatar rail — acceptance checklist

## Architecture card

### Scope and sources

- User requirement: Budget card1 becomes a five-position, cyclic category
  avatar rail with no Budget/business side effects.
- Accepted visual reference:
  `spendeetest@144d78c30dc4cc5e9f230903fd6274c98e62e118`:
  `spendee_budget_v2_avatar_carousel.dart`, its avatar-belt composition, and
  the `GlossyCategoryAvatar` / category icon render path.
- Existing motion owner:
  `TimeRefinementRail` → `CenteredCarousel` →
  `CenteredCarouselController` → `CenterSnapScrollPhysics`.
- Existing data owner: the applied directional `CurrentQueryController`
  facet presentation.  Its ordered `QueryMenuCategoryFacet` collection is the
  only input; this feature neither starts nor owns a repository request.
- Existing geometry owner: `DashboardGeometryResolver`'s
  `subheaderOneBounds` and its existing Budget upper-card cascade.

### Single source and write path

- Category source: already-applied directional Query facet data.
- Derived read model: one immutable, lightweight Budget avatar item list.
- Avatar geometry: the constrained 72px card1 item shell uses the approved
  66px authored-disc scale (59.4px centre, 46px inner, 36px outer).
- Only write path: the rail-local `CenteredCarouselController` may change its
  centered *presentation* index. It never writes Query, category selection,
  paging, LogBox, or repository state.
- Error/readiness: the existing prepared vector atlas remains the asset owner;
  the Budget rail only receives already-prepared vectors after dashboard
  readiness.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Ordered category avatar input | `DashboardBudgetCategoryPresentation` | `CoreDashboard` | Changes only when applied facets or direction change |
| Centered avatar identity | Budget rail's stable `CenteredCarouselController` | Budget surface lifetime | Rail-local only; no business publication |
| Drag/fling/snap | shared `CenteredCarouselController` + `CenterSnapScrollPhysics` | Rail controller lifetime | Flutter Scrollable owns user/ballistic motion |
| Asset/gradient data | `PreparedVectorAssetAtlas` + category catalogs | process | Prepared before dashboard is interactive |

### Centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- |
| Drag/fling/snap physics | `CenteredCarousel` TimeRail profile | trajectory, friction, fling bound, snap and interruption | Extract physical profile from visual spec; reuse TimeRail profile exactly | profile identity test |
| Category icon/color | category catalogs + prepared vector atlas | stable asset ID, gradient and white icon rendering | Reuse current catalog/atlas pipeline | widget and catalog tests |
| Avatar face | Spendee `GlossyCategoryAvatar` | gradient, gloss, rim, shadow and layer order | Port the smallest shared category presentation primitive | widget inspection/tests |

### Layer flow

Applied Query facets → immutable Budget avatar presentation → Budget mode
surface → rail-local shared carousel → prepared category avatar primitive.

## Acceptance checklist

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BAR-01 | Task §1, §7 | Budget core surface + geometry tests | The existing `subheaderOneBounds` / upper-card host remains the 72 logical-pixel card1 slot; no downstream Y position changes. | card1/rail rect equality, 72px host height, card2 top regression | DONE |
| BAR-02 | Task §2A, §11 | shared centered carousel | Budget uses the identical TimeRefinementRail physical profile, never the divergent avatar preset. | profile object identity test + shared carousel regression suite | DONE |
| BAR-03 | Task §2B–3, reference SHA | core category presentation | Avatar face retains the Spendee gloss/rim/shadow layer ordering while rendering through the authoritative current category catalog and prepared-vector asset path. | source inspection + prepared-vector catalog/widget tests; Android visual check remains | PARTIAL |
| BAR-04 | Task §4, §13 | Budget category presentation | Ordered applied facets become immutable id/name/color/icon inputs without repository access. | directional facet unit test + counting repository Core integration | DONE |
| BAR-05 | Task §5–6 | Budget rail | Five logical positions remain cyclic for 0, 1, 2–4, 5 and 5+ categories; current center is preserved by stable id. | finite-count, modulo and stable-id replacement widget tests | DONE |
| BAR-06 | Task §8–9 | centered carousel + Budget rail | Shadows/glow use unclipped rail paint bounds and rail ticks stay below the Budget/dashboard/LogBox rebuild boundary. | `Clip.none` rail assertion + dashboard-root rebuild probe | DONE |
| BAR-07 | Task §10, §16 | Budget card1 gesture region | Horizontal rail drags stay local; header mode swipe and vertical scrolling ownership remain intact. | Core mode/rail fling test + protected LogBox gesture suite | DONE |
| BAR-08 | Task §14, §18 | tests/boundaries | RED → GREEN → REFACTOR tests, focused regression suites and analyzer pass without weakened protected tests. | targeted, boundary and analyzer runs pass; broad dashboard directory run has one unrelated pre-existing diagnostic assertion failure | PARTIAL |
| BAR-09 | Task §15 | human verification | Normal `lib/main.dart` APK is visually checked on Android for Spendee parity and physical rail feel. | human device testing only | NOT DONE |
| BAR-10 | Task §19 | git | One focused local commit only; no push, merge, rebase, golden or production harness. | `git status`, log, diff inspection | DONE |

## Explicit architecture decision

The old `avatars` preset is not used because it has a different maximum fling
velocity, items-per-fling bound, and snap stiffness from TimeRefinementRail.
The Budget rail will use the exact TimeRefinementRail motion profile together
with an avatar-only layout/visual profile.  Its ticks are rail-local and never
start Query, paging, scene preparation, asset decoding, or dashboard business
publication.

## Automated validation record

- `flutter analyze`: no issues.
- Focused category/motion/mode suite: 61 tests passed.
- `test/boundary`: 21 tests passed.
- Protected LogBox viewport/partner-swipe/prepared-scene/stable-surface suite:
  75 tests passed.
- A broader dashboard application/presentation directory run exposed one
  unrelated pre-existing assertion in
  `dashboard_core_ephemeral_focus_test`: the test expects a full
  `retainedKey=...` diagnostic while the current baseline emits
  `retainedKeyDigest=...`. This feature does not modify that owner or test.
