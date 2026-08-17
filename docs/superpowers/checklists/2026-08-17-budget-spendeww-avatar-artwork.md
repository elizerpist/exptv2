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
