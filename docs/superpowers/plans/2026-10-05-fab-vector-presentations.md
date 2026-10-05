# FAB vector presentation acceptance checklist

Source request: user instruction on 2026-10-05, with the supplied visual source
`/storage/emulated/0/spendee/asset/fluvi_add_expense_vector.svg` inspected
directly.  The asset is a transparent-background, layered purple 3D expense
illustration.  This task extends the existing global FAB presentation authority;
it must not create another FAB, direction, or action owner.

| ID | Requirement | Intended owner | Acceptance / verification | Status |
| --- | --- | --- | --- | --- |
| FVP-01 | Bundle the supplied vector as an app asset. | `assets/fluvi/actions/` | App asset lookup works through the already-declared `assets/fluvi/actions/` bundle prefix and no runtime path refers to `/storage`. | DONE |
| FVP-02 | Keep the two current choices and add a third compact, recolourable SVG-in-button choice. | `FluviFabIconPresentation`, `FluviGlobalAppearance` | Four enum choices appear in the existing FAB setting; equality/copy/default contracts remain correct. | DONE |
| FVP-03 | Compact vector mode keeps the normal FAB shell, ring and diagonal direction-gradient core; the vector is smaller than artwork and its transparent regions reveal the core. | `Bnb03BottomNavigation` | Focused widget test proves shell/ring/core remain, vector is inside the core and smaller than the visible footprint. | DONE |
| FVP-04 | Compact vector has independently user-editable rendered colour treatment and shadow without editing the source SVG. | existing global appearance controller/tuner | Live primary/highlight controls drive a value-equal SVG color mapper; controller and tuner tests prove updates. | DONE |
| FVP-05 | Add a fourth full-size baby-blue vector choice: same optical FAB artwork footprint, no white shell, no coloured ring/core or backing button. | `Bnb03BottomNavigation` | Focused widget test proves full footprint and absence of shell/ring/core; inspected golden proves the baby-blue output. | DONE |
| FVP-06 | Keep one Shop hit target, direction semantics and routing unchanged. | existing `Bnb03BottomNavigation` | Existing FAB hit-target/tap coverage remains and both new renderers stay below the one existing semantic target. | DONE |
| FVP-07 | Verify visual and static quality before final app build. | tests / CI | Focused RED/GREEN tests, inspected goldens, formatter/focused-analyzer/diff checks, successful online normal correctness gates, and exact Human APK delivery for `f5d6876fa8099779dbcc9aadb6f98a94a18ea164`. | DONE |
| FVP-08 | Correct the fourth vector treatment to the photographed cyan of the reference FAB; retain its no-shell/full-artwork contract. | `FluviFabReferenceMaterial` + existing full-vector presentation in `Bnb03BottomNavigation` | The full-vector semantic palette resolves the sampled `#06B6D4`/`#DDF9FC` material from one global visual token; focused color contract and the regenerated golden retain the no-shell/full-artwork contract. | DONE |

Architecture decision: the supplied SVG stays source artwork.  A single
`Bnb03FabVectorArtwork` rendering primitive applies the user-selected compact
palette/shadow through a value-equal SVG color mapper; it does not mutate
the asset, create a second FAB, or own transaction direction.  The large
baby-blue variant uses the same primitive at the current direction-artwork
optical footprint while deliberately omitting the button shell/core.
