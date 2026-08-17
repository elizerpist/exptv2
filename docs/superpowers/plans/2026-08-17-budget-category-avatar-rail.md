# Budget category avatar rail Implementation Plan

> **For agentic workers:** This plan is executed inline because the work has
> tightly coupled shared-engine, presentation, and wiring changes. No
> subagents are used.

**Goal:** Replace Budget card1's empty placeholder content with a category
avatar rail that has the exact current TimeRefinementRail motion profile and
the approved Spendee avatar appearance.

**Architecture:** Derive immutable avatar inputs from already-applied Query
facets; keep the selected avatar and all motion inside a small Budget rail;
reuse one extracted shared physical profile; port only the reusable avatar face
to the current prepared-vector category pipeline.

**Tech Stack:** Flutter widget tests, the existing `CenteredCarousel`, current
category catalogs/prepared vector atlas, and dashboard geometry resolver.

## Global constraints

- Do not add repository, Query, paging, scene or LogBox work to avatar input.
- Use TimeRefinementRail's physical profile exactly; do not use the legacy
  avatar profile.
- Keep current Budget card1 outer geometry and all protected dashboard owners.
- Do not add golden tests, a production test harness, a push, merge or rebase.

---

### Task 1: Prove the new contracts in RED

**Files:** test files beside the existing centered-carousel and dashboard
presentation tests.

- [ ] Add tests for physical-profile identity, cyclic category mapping,
  preserved card1 bounds, category asset/gradient mapping, gesture isolation,
  and local rebuild ownership.
- [ ] Run the focused tests and record expected failures caused by missing
  Budget rail/presentation seams.

### Task 2: Separate shared physical and visual profiles

**Files:** `lib/shared/motion/centered_carousel/centered_carousel_spec.dart`,
`centered_carousel.dart`, shared tests.

- [ ] Extract one physical-profile object without changing TimeRefinementRail
  behavior.
- [ ] Add avatar layout values that reference the TimeRail profile by identity.
- [ ] Preserve the legacy generic avatar preset for its existing consumer.

### Task 3: Add the Budget presentation and avatar renderer

**Files:** dashboard application/core-mode presentation plus a shared core
category avatar primitive.

- [ ] Map applied directional facet data only when it changes.
- [ ] Prepare rail-local visual items once per source update and preserve the
  centered stable id where still available.
- [ ] Render only the five-position cyclic belt through `CenteredCarousel`,
  using catalog gradients and prepared category vectors.

### Task 4: Wire card1 and verify

**Files:** Budget mode surface, dashboard composition, documentation/checklist
and focused tests.

- [ ] Replace only card1's old empty content; preserve the existing cascade,
  card height and zone2 placement.
- [ ] Run formatting, focused and broader affected suites, plus analyzer.
- [ ] Re-read the checklist, inspect the final diff, and make one local commit.
