# Dashboard depth, border and cache-parity follow-up plan

## Scope and source record

This plan is a focused follow-up to `7a663c49` / `02d9be9a`; it preserves the
existing Summary variants, independent temporal selectors, Budget Split/Unified
composition, per-family corner controls, row-height control, prepared amount
publication and custom-painted LogBox architecture.

The read-only source worktree is
`/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree`
at `144d78c30dc4cc5e9f230903fd6274c98e62e118`. It is visual/source evidence
only and must not be edited. The live `Fluvi Logs` document revision inspected
for this work is Drive revision 39 (2026-08-26).

## Architecture decision

1. Keep `DashboardShadowProfile` as the sole depth resolver. Remove contour
   ownership from its Reference3D endpoint: it returns only material/depth
   inputs (outer and inner shadows plus an optional source surface material for
   white summary/search consumers). Header callers retain their mode-palette
   paint layer and never consume a white material override.
2. Add one immutable, dashboard-lifetime `DashboardBorderSettings` owner and
   a single `DashboardBorderProfile`. It maps independently selectable outer
   component types to the current SearchPill border token. Its output is
   paint-only and composes after depth, so Reference3D plus border-off retains
   both source depth layers and Reference3D plus border-on has exactly one
   contour.
3. Keep LogBox inside the existing custom painter. Derive fill, border, dark
   depth and white inner/foot layers from one translated group geometry for a
   leased partner-swipe segment. No row widgets or per-paint text/vector work
   are introduced.
4. Extend the existing central Budget layout frame only with the explicit
   Unified rail offset/clearance contract. Split consumes its existing bounds.
   The card itself continues to use `modeContentBounds`; the rail moves as one
   layout unit and its selected maximum visual envelope is checked against the
   card and diagram bounds.
5. Add one immutable LogBox amount-palette settings owner whose resolved
   income/expense `Color`s are handed to paint resources once per presentation
   binding. Category swatches resolve from `CategoryColorCatalog`; the active
   Balance renderer's only source amount is its unconditional `#FF3E73`, not a
   fabricated Balance green. Palette changes do not enter query, text,
   geometry or scroll ownership, and retained tint pictures prevent a repeated
   offscreen layer in the render hot path.
6. Centralize the handle-to-count spacing in the existing ledger/layout metric
   path. Halve the authored old gap exactly and add the difference to the
   LogBox viewport only.
7. Treat Legacy as the navigation control. First capture canonical target,
   query key, cache hit/request, publication and stale-generation event order
   for identical Legacy, Segmented and BudgetAvatar targets. Then make only
   the producer adapters converge on the existing transition/cache owner;
   cache hits publish immediately, misses remain non-blocking/coalesced and
   stale protection remains intact.

## Execution order

1. Add focused RED tests for header fill, swipe-material translation, border
   profile/settings, Unified clearance, palette model, ledger viewport delta
   and canonical navigation parity.
2. Implement shared presentation owners/profiles and wire their tuner scopes.
3. Repair Header/LogBox depth composition and add the visual controls.
4. Adjust only Unified Budget rail geometry and the central ledger viewport
   metric; verify Split geometry remains unchanged.
5. Trace the three navigation producers against the control; implement the
   smallest shared transition/cache adapter indicated by those traces.
6. Run targeted and milestone suites in Ubuntu proot, `flutter analyze`, then
   review, commit, push and deliver the GitHub-built human APK.

## Non-negotiable invariants

- One vertical LogBox Scrollable, ScrollController and ScrollPosition survive.
- Reference3D source depth values are not retuned to solve Header ownership.
- Borders and palettes are paint-only; row-height geometry remains unchanged.
- Legacy path is never made slower or rewritten speculatively.
- No producer awaits data/settle work before accepting a carousel crossing.
- Cache-miss Budget Card2 and focused LogBox scene work are latest-target
  coalesced until the Summary/BudgetAvatar physical motion lane becomes idle.
