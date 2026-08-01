# Fluvi category visual catalog

## Architecture card

- Persistent source of truth: Room `fluvi_categories` rows. The only stored
  visual values remain stable `colorId` and `iconId` strings.
- Backend catalog owner: `FluviCategoryCatalog` validates the allowed ID
  contract and seeds explicit Uncategorized defaults.
- Presentation catalog owner: one Flutter catalog resolves IDs to immutable
  gradient and SVG asset tokens. No feature widget owns a color/icon map.
- Flow: Room entity → public category model/API → Flutter category model →
  `CategoryVisualResolver` → shared visual widgets.
- Write path: existing typed category use cases remain the only Room mutation
  path. Visual resolution is read-only and never writes presentation data.
- Backup policy: no archive category state is introduced. Existing backup and
  checkpoint behavior remains independent from catalog resolution.

## Acceptance checklist

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| CAT-01 | Fluvi architecture + user spec | Room entity/use case | Room stores only category IDs, not colors, gradients, SVG paths or Flutter types | Direct code audit + Room tests | DONE |
| CAT-02 | Spendee `docs/prototypes/color_lab.html` and `mind_global_rail_stage_layout_reference.html` | Shared catalog manifest | Exactly 21 source gradients are preserved, including A/middle/B colors and direction | Manifest contract test | DONE |
| CAT-03 | Spendee `lib/features/transactions/slots/category_icon_manager.dart` | `assets/category_icons/` | Exactly 50 selected category SVGs are copied without rasterization or path recreation | Asset count + SVG parse test | DONE |
| CAT-04 | Existing Fluvi backend IDs | Kotlin catalog | Existing `color_01…21` and `icon_01…50` meanings remain stable | Kotlin ID contract test + compile | DONE |
| CAT-05 | User spec | Shared machine-readable manifest | Backend and Flutter allowed IDs derive from or contract-test against one catalog definition | Generator + manifest/Dart contract test | DONE |
| CAT-06 | User spec | Flutter resolver | Every current Fluvi category surface resolves through one central resolver; no pre-existing category surface was present to migrate | Source audit + resolver tests | DONE |
| CAT-07 | User spec | Flutter widgets | Shared category visual badge/icon widget accepts IDs, not raw color/path mappings | Source audit + resolver/widget contract | DONE |
| CAT-08 | Existing `flutter_svg` dependency | Flutter assets/pubspec | All category icons are registered as SVG assets and rendered with the existing SVG renderer | Asset load contract test | DONE |
| CAT-09 | Existing Room core | DAO/repository/model/API | Public category list and get-by-ID read operations are available without exposing Room/DAO internals | Kotlin compile + category API test | DONE |
| CAT-10 | User spec | Uncategorized seed/defaults | Uncategorized uses explicit stable IDs and remains non-deletable | Existing regression + generated defaults | DONE |
| CAT-11 | User spec | Category editor integration boundary | Picker/preview integration uses the same 21/50 catalog; no new archive state is introduced | Current Fluvi has no category editor/list screen; shared preview is ready | PARTIAL (deferred to category UI slice) |
| CAT-12 | User spec | Documentation | Spendee-to-Fluvi mapping, IDs, asset paths and catalog version are documented | Mapping report review | DONE |
| CAT-13 | User instruction | Git workflow | No APK/web build; commit and push only after verification | Git status + push result | IN PROGRESS |

## Reference paths

- Spendee palette source:
  `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/prototypes/color_lab.html`
- Spendee palette reference:
  `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/docs/prototypes/mind_global_rail_stage_layout_reference.html`
- Spendee icon source:
  `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/assets/icons/lucide/`
- Spendee icon ordering:
  `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/lib/features/transactions/slots/category_icon_manager.dart`
- Fluvi backend architecture:
  `docs/architecture/fluvi-core-foundation.md`
