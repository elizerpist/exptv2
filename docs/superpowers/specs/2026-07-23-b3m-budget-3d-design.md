# B3M Budget 3D Design

## Decision

Use approach 1: create `B3M-B3D` as a separate, deep DOM clone of the already-built interactive `B3M-B` Budget screen. The new screen is placed immediately beside B3M-B; B3M-B itself remains unchanged. The clone has no runtime dependency on the original B3M-B DOM after creation.

## Authoritative reference and re-read gate

The sole visual source of truth is `/storage/emulated/0/spendee/budget3d.png` (1024 × 1536, sRGB). It was inspected at original resolution and sampled directly before this design was written. It must be re-opened before any B3M-B3D implementation edit and before visual verification.

The reference's left app surface occupies roughly 684 px of the image. Normalised to the 412 px B3M prototype width, its significant geometry is:

| Reference treatment | Reference measurement | B3M-B3D target |
| --- | --- | --- |
| Outer app inset / inner content gutter | 28 px / 17 px normalised | Keep the B3M shell and use its 17–18 px content gutter. |
| Hero | 627 × 191 px / 377 × 115 px normalised | Preserve B3M's header interaction geometry; reproduce the rounded, elevated gradient treatment within it. |
| Hero and major-card corner radius | about 29 px / 17 px normalised | 17–18 px CSS-equivalent radius, not a sharper pill. |
| Main elevated card | 627 × 516 px / 377 × 311 px normalised | Preserve B3M's available expanded-stage height; distribute the same clay hierarchy across its current card and inner panels. |
| Depth offsets | visible 6–14 px reference layers / 4–8 px normalised | Use a lower coloured/extruded layer plus a diffuse shadow; avoid flat `drop-shadow`-only imitation. |

Reference palette measurements that must anchor the scoped CSS:

- surface: `#F5F6FB`;
- hero progression: `#5FA4F5` / `#4D8CE9` → `#6E6DEB` → `#8E5EED`;
- ink: `#162454` and soft secondary `#6166A6`;
- pink depth: `#F558A5` / `#D655B3`;
- supporting yellow, blue, green and violet category colours remain sourced from the current category fixture rather than copied screenshot data.

The screenshot supplies visual treatment only. Its brand, amounts, labels, categories, avatar art, chart values and chart series are never imported.

## Screen architecture

1. Render B3M-B exactly as it is today.
2. Deep-clone that finished B3M-B screen-column into an independent B3M-B3D screen-column. Mark only the clone with `data-budget-3d-mode-screen="true"` and a distinct `data-screen` value.
3. Rebind the clone's own collapse/expand scroll controller, time-rail drawer, limit editor, and category-summary pagination/swipe handlers. The binding functions resolve elements only below the B3M-B3D screen root; no listener closes over, queries, or mirrors B3M-B.
4. Scope all visual rules beneath `data-budget-3d-mode-screen="true"`. Existing B3M-B rules and visual output cannot change.
5. Retain the current B3M-B data-bearing DOM: Budget header values, selected category, limit amount, ring percent, rhythm bars, current donut slices and values, top-three list, vendor list, pagination and rail placeholder.

The existing C4W reference is not queried by B3M-B3D. It is not a live visual or data dependency of this new screen.

## Visual mapping

### Shell, header, and state model

The shell is a cool glass-clay surface rather than plain white. The hero becomes the reference's light-blue to indigo to violet elevated slab, with a one-pixel white upper highlight, a soft outside shadow and a subtle internal glow. Text remains the current B3M-B text and stays white.

Expanded state retains the B3M-B partition progress, `elköltve` / `maradt` values, avatar rail, detail region and permanent time rail. Collapsed state retains the B3M-B x/y heading rule; it receives the material treatment but does not reveal expanded-only progress data. The reference shows an expanded composition, so its material hierarchy applies to both states while B3M's state-specific information rules remain authoritative.

### Avatar rail and icons

Current avatars retain their category identity and fixture data. Each receives a coloured lower depth layer, white upper edge light, soft lateral shadow and a selected-ring treatment. The selected category's colour drives that depth; the reference pink is not hard-coded over B3M data. Existing rail centring, placeholder status and indicator semantics stay intact.

### Main card and panels

The main Budget component card becomes a raised clay slab: off-white gradient surface, white top edge, cool diffuse lower-right shadow and a faint upper-left highlight. Its two inner panels have their own smaller elevated surfaces and matching radii rather than becoming a single flat area. The shared category header and editable limit retain their present hierarchy and positions.

### Current charts, not reference chart data

The current limit ring gets a real lower extrusion layer under its existing conic-gradient value ring; it keeps the current percentage and clockwise 12-o'clock origin. The current SVG donut keeps its existing slice set, active slice, percent and legend, but gains a controlled lower duplicate/depth treatment per slice, thicker top surface and selected-slice lift. The current rhythm bars get a coloured lower layer and bright top gradient. No screenshot chart or value is inserted.

The right-panel vendor page keeps its current horizontal swipe, dots and inner vertical scrolling. Its data and row semantics do not change; only the container material and minor depth treatments change.

### Rest of the interactive screen

Action controls, month/search controls, year rail and shared bottom navigation stay functionally identical. Within B3M-B3D they receive the same soft glass / elevated finish where they are visible, without replacing their labels, icons, dimensions or navigation model.

## Interaction and data boundaries

- Preserve collapse, expand, drag/scroll response, permanent time rail, current layout boundaries and bottom navigation.
- Preserve the existing noninteractive avatar placeholder behavior.
- Preserve editable category limit semantics, including Enter, Escape, blur and button save behavior.
- Preserve right-panel native horizontal swipe and vendor-list vertical scrolling.
- Do not add a new chart, source fixture, production Flutter change or external dependency.
- Do not alter B3M-B, C4W, the first-row Balance screens, or the existing source HTML outside the isolated B3M-B3D factory/style/test coverage needed to build the clone.

## Verification strategy

Add a targeted static contract for the independent clone, listener rebinding, B3M-B isolation, source-referenced palette/radii/depth selectors, current-data preservation and current interaction hooks. Run the existing Budget and B3M-A3 static contracts, parse inline scripts, run `git diff --check`, and verify the served HTML responds successfully.

Because browser automation is expressly out of scope, the final visual check compares the re-opened reference with the B3M-B3D implementation by direct code/geometry/palette inspection and requires a fresh user screenshot for the final human visual sign-off. No completion claim may treat a passing static test as pixel-level visual proof.
