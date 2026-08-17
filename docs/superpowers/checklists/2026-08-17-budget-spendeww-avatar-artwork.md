# Budget spendeww avatar artwork checklist

Reference worktree: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree` at `144d78c30dc4cc5e9f230903fd6274c98e62e118`.

The reference body is the complete dynamic SVG returned by
`BudgetV2FluviSvg.avatarDisc` in
`lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart`.
It is not the unrelated `assets/category_icons/slot_*.png` set. The reference
uses the SVG body plus the category slot glyph, with a distinct selected
progress-shell treatment.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-1 | User task §1–7; reference `BudgetV2FluviSvg.avatarDisc` | `core/categories/presentation` | Regular Budget avatars render the complete source SVG, including its authored lower floor/blob and intrinsic highlight/depth. | Widget/source contract test; pending human APK comparison. | PARTIAL |
| ARC-2 | User task §5, §10; reference `_BudgetV2FluviAvatarDisc` | `core/categories/presentation`, Budget rail | Center uses the reference selection chrome with the core SVG; artwork and glyph scale together without clipping or a second generic shadow. | Widget test; pending human APK comparison. | PARTIAL |
| ARC-3 | User task §8–9 | `budget_category_avatar_rail.dart` | Inventory data stays immutable/presentation-only; rail uses prepared category glyphs and cached SVG loaders without I/O or source generation per carousel tick. | Existing rail/rebuild tests; code inspection. | DONE |
| ARC-4 | User task §13–16; milestone `8d559cf` | Dashboard/query/LogBox/motion owners | No changes to repository ownership, core mode switching, CenteredCarousel physics, geometry, Query, or LogBox. `GlossyCategoryAvatar` remains available to unrelated consumers. | Diff inspection; protected suites. | DONE |
| ARC-5 | User task §11, §17 | `test/features/dashboard/presentation` | RED proof rejects `GlossyCategoryAvatar` in the Budget rail and proves the complete SVG artwork path, category glyph mapping, selected treatment, and centered-id preservation. | Focused Flutter tests. | DONE |
| ARC-6 | User task §17–18; global build delivery rule | CI human APK | Dart format, analyzer, relevant tests, online normal `lib/main.dart` APK build, download to `/storage/emulated/0/Download/fluvi`, SHA-256, and pending human visual check. | Command/CI output plus physical test. | PARTIAL |

## Selected-avatar refinement acceptance

The SVG body remains the approved historical artwork source. Flutter removes
unsupported SVG filters, so the explicit blurred upper white stripe is
intentionally omitted: its hard, unblurred fallback is not approved. The
radial face gradient remains the sole upper-left diffuse illumination. The
selection shell is independent, enlarged paint-only chrome with a pure-white
face; it must not resize the category body or glyph.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-7 | User task §3; current physical screenshot | `BudgetCategoryAvatarSvg` | The explicit `M166 190 C205 132 300 118 353 174` white SVG path is absent, while the face radial gradient and all other body geometry remain. | SVG source contract test; human APK. | PARTIAL — automated contract passes; human visual verification pending. |
| ARC-8 | User task §4–7; current physical screenshot | `BudgetCategoryAvatarArtwork` | Selected and unselected body/glyph use the same fixed geometry; shell is a separate sibling paint layer. | Widget geometry test; code inspection; human APK. | PARTIAL — automated geometry contract passes; human visual verification pending. |
| ARC-9 | User task §6, §8 | `BudgetCategoryAvatarSelectionChrome` | The 112px white shell has track-inner radius 34.73px and 4.84px clearance around the 29.89px avatar sphere; card layout stays unchanged. | Numeric geometry/widget tests; existing card geometry test; human APK. | PARTIAL — automated geometry/background contracts pass; human visual verification pending. |
| ARC-10 | User task §9–12 | Budget rail / `CenteredCarousel` | Exactly one shell follows the centered item; time-rail motion profile, prepared SVG inputs, data owners, and tick isolation remain unchanged. | Rail/profile/boundary tests. | DONE |
| ARC-11 | User task §18–20 | Normal human APK | Normal `lib/main.dart` APK is built and downloaded; physical visual checks are explicitly pending. | CI job/build artifact + human test. | PARTIAL — `47095de6` human APK is built and SHA-256 verified; human visual verification remains pending. |

## Center-shell ownership and tap-centering refinement acceptance

The shared `CenteredCarouselController` remains the sole owner of drag, fling,
snap, interruption, and programmatic centering. The Budget rail only opts into
that existing tap-to-center path. Artwork variants are prepared when category
input changes; neither a tap nor a carousel tick may create SVG input or start
data work.

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-12 | User task §3A, §6.1, §6.3 | `BudgetCategoryAvatarSvg` / Budget rail | Normal avatars retain their projected floor/blob; the selected centered core has no projected floor/blob, so only its shell paints the lower cast shadow. | SVG/rail widget contracts; human APK. | PARTIAL — automated artwork/rail contract passes; human visual verification pending. |
| ARC-13 | User task §3B, §6.2 | `BudgetCategoryAvatarSelectionChrome` | Shell layout and painter are independently forced to one square visual diameter; face and track remain circles. | Widget geometry contract; human APK. | PARTIAL — square-domain contract passes; human visual verification pending. |
| ARC-14 | User task §3C, §6.4 | `BudgetCategoryAvatarSvg` | The bad lower body arc is absent from both variants; radial face depth and the normal variant's floor/blob stay present. | SVG source contracts; human APK. | PARTIAL — automated SVG contract passes; human visual verification pending. |
| ARC-15 | User task §3D, §6.5 | Budget carousel preset | Tapping an avatar uses the existing `CenteredCarouselController.tapToPhysicalIndex` programmatic motion path and does not directly jump the logical center. | Widget/motion tests. | PARTIAL — widget/motion contract passes; human tap feel verification pending. |
| ARC-16 | User task §5, §7–10 | Rail boundaries | No data/query/logbox/core-mode/physics/card-geometry owner changes; card1 bounds stay fixed. | Existing rail, mode-host, profile, and boundary tests. | DONE |
| ARC-17 | User task delivery contract | Push/build/download | One focused production commit is pushed; exact normal human APK is downloaded and hash verified. | GitHub job/release artifact plus SHA-256. | PARTIAL — `afd6178e` human APK is built, released, downloaded, and SHA-256 verified; human Android visual/tap verification remains pending. |

## Financial-limit Budget foundation acceptance

Reference worktree: `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree`
at `144d78c30dc4cc5e9f230903fd6274c98e62e118`.
The aggregate visual contract is `BudgetV2FrameData._overviewSlot` and the
overview icon selection in `spendee_budget_v2_components.dart`. The native
core, not a Query facet or the visible LogBox, is the authority for Budget
actuals and limits.

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FLB-1 | User task §5A, §6.3, §8.1 | `budget_category_avatar_artwork.dart` | Normal-avatar SVG and selected shell use one target-derived shadow-tone helper; no hardcoded pink shell cast shadow remains. | Unit/source contract using two target colors; APK visual check. | PARTIAL — focused rail contracts and the normal APK build pass; human visual verification remains pending. |
| FLB-2 | User task §5B, §6.2, §8.2 | Avatar SVG geometry | Centered-core viewport has the normal viewport dimensions and its source centre equals the sphere centre; normal rail retains its floor-biased full artwork viewport. | Numeric SVG geometry tests; APK visual check. | PARTIAL — numeric contract and normal APK build pass; human visual verification remains pending. |
| FLB-3 | User task §5C, §6.5, §8.3–8.4, §8.19 | Budget target catalog and rail | Handle 0 is a typed aggregate target; real categories follow authoritative inventory order; Expense Budget and Income Goal use exact reference titles, colors, gradients and prepared vectors. Zero categories still yields one cyclic target. | Target-domain/rail widget tests; direct reference inspection; APK visual check. | PARTIAL — target/rail tests and normal APK build pass; human visual verification remains pending. |
| FLB-4 | User task §5D, §8.5–8.9 | Core financial-limit domain, Room v5 | Immutable aggregate/category + sum/year/month key, scaled-100 integer amount, missing-versus-zero semantics, constraints, FK cascade, 4→5 migration, repository/use-case and revision-aware CRUD are present. | Kotlin unit/DAO/migration tests. | DONE — clean Room core CI passed. |
| FLB-5 | User task §8.10–8.18 | Core query acquisition, Android bridge, runtime codec/cache | A query-independent exact-revision Budget snapshot is acquired through bounded set-based native work, transported in a versioned binary payload, decoded into dense O(1) target/period cells and cached by revision/year window. Query-only publication reuses the identical snapshot. | Native aggregation/codec tests; Flutter runtime/cache tests. | DONE — native bridge CI and targeted runtime codec/cache tests passed. |
| FLB-6 | User task §8.16–8.18 | `DashboardPreparedRevisionBundle`, runtime publication | A dashboard bundle may publish only when index and Budget snapshot have the same revision; missing exact data fails closed without interaction-time repair I/O. | Bundle mismatch/fail-closed tests. | DONE — runtime/bundle tests passed. |
| FLB-7 | User task §8.20–8.24 | `DashboardBudgetPresentationController`, Budget header | Existing rail/time/direction semantic ticks bind `actual / limit` by dense O(1) lookup and rebuild only local Budget presentation. No database/bridge/query/LogBox work occurs on a tick. | Controller/widget/rebuild-isolation tests. | DONE — targeted controller/rail widget suite passed. |
| FLB-8 | User task §8.26–8.28 | Native demo seed | Demo version and one seed transaction insert deterministic aggregate/category limits for both directions, SUM, all prepared years and all prepared months; under/equal/over examples exist per direction and plane. | Native demo-manifest coverage tests. | DONE — demo seed/core CI passed. |
| FLB-9 | User task §12–14 | Diagnostics, protected dashboard owners | Bounded financial-limit/target/header diagnostics exist; protected Query/LogBox/physics/geometry owners and zero-miss contracts remain unchanged. | Targeted protected suites; final diff review. | PARTIAL — protected Flutter/core suites and final diff pass; the separate profile harness still hits the pre-existing initial LogBox surface-width race before the scenarios execute. |
| FLB-10 | User task §15–16 and global delivery rule | Git/GitHub human delivery | Focused commits are pushed; the successful normal `lib/main.dart` APK is downloaded to `/storage/emulated/0/Download/fluvi` and SHA-256 verified. Human physical acceptance remains explicitly pending. | GitHub Actions/release artifact and local hash. | PARTIAL — `e20eb53a` normal APK is built, released, downloaded, and hash-verified; human physical acceptance remains pending. |
