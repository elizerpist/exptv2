# Category/Partner drill-down and Balance Header plan

> **Execution:** Inline.  The immutable linked-presentation extension, lower-card
> state, Header tuning policy and shared renderer all have coupled ownership and
> test seams; splitting them would introduce conflicting edits without reducing
> the critical path.  The user explicitly requires a single final build after
> both product bundles.

**Goal:** Deliver local Top Category/Top Partner drill-downs and manual Balance
Header palettes with a corrected shared Header opacity composition, without
changing financial, Query, carousel, Header-geometry, Budget or Mind ownership.

**Architecture:**

```text
resident active-direction memberships
  -> existing DashboardBalanceLinkedProjection
  -> bounded immutable category/partner insight maps
  -> DashboardBalanceLinkedPresentation
  -> existing lower linked card + local selected entity id

existing DashboardHeaderVisualController.tuning
  -> Balance palette state/catalog/window sampler
  -> reactive Balance Header frame
  -> existing clipped Header paint layer over an opaque white base
```

## Steps

1. Audit current source/graph/journal and preserve the `22f58adf` Balance
   extensions.  Record Drive evidence as absent for both new presentation areas.
2. Add RED pure tests for bounded category and partner projections, then add the
   immutable projection helper and presentation fields.  Preserve `_rank` as the
   source of existing list semantics.
3. Add RED mounted lower-card tests, implement local entity-id master/detail
   state and bounded category-/partner-only renderers, then prove update/back,
   scroll and no-source-work behavior.
4. Add RED Header catalog/window/policy and opacity-composition tests.  Add the
   Balance palette state/sampler/policy, wire it into the existing controller and
   tuner, and replace the static Balance policy without altering Balance values.
5. Add the clipped opaque white Header base and linear shared opacity application
   exactly once in the canonical paint transport.  Validate static and Fragment
   fallback/animated paths without fading Header content.
6. Run focused RED→GREEN tests and protected regressions in Ubuntu/proot,
   format/analyze/diff-check.  Re-read the checklist and inspect the complete
   diff for scope-lock violations.
7. Make one application commit containing both approved bundles, push it once,
   monitor the corresponding GitHub Actions run and download/hash its single
   human diagnostic APK.  Classify the existing Mind profile failure only from
   exact evidence.
8. Regenerate SCIP from that exact application SHA on the tooling branch, append
   factual delivery evidence in a journal-only commit, push it without treating
   it as a build trigger, and report remaining physical validation honestly.

## Planned production files

- `lib/features/dashboard/application/dashboard_balance_primary_projection.dart`
- `lib/features/dashboard/application/dashboard_balance_entity_insights_projection.dart`
- `lib/features/dashboard/presentation/core_modes/balance_linked_detail_card.dart`
- `lib/features/dashboard/presentation/core_dashboard.dart`
- `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_engine.dart`
- `lib/features/dashboard/presentation/core_modes/dashboard_header_balance_color_scale.dart`
- `lib/features/dashboard/presentation/core_modes/dashboard_header_visual_tuner.dart`
- `lib/features/dashboard/presentation/core_modes/dashboard_core_mode_surface_primitives.dart`

## Planned test areas

- `dashboard_balance_entity_insights_test.dart`
- `balance_linked_detail_card_test.dart`
- `balance_dashboard_core_surface_test.dart`
- Header visual engine/static renderer/tuner/Core tests

No code is to issue a repository request, mutate a Query, create a controller,
or scan ledger rows from a widget interaction.  No APK build starts until all
of steps 2–6 are complete.
