# Acceptance checklist — unified pastel appearance and global typography

Scope authority: user-approved **FLUVI — Unified Pastel Color System +
User-Selectable Direction/Avatar Palettes + Action Artwork Toggle + Global App
Typography** request, 2026-09-24.

Starting application evidence: `90d3a756d5bd22a2384f2fd14680234a7675a71a`;
current documentation head at intake: `f47d1851cd038dd162fda6a53ef2cb0b1004343a`.

| ID | Source / requirement | Intended owner | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| DIR-01 | User Part A | Global appearance state + direction palette resolver | Exactly original/pastel/saturated/vivid; original preserves the real `#715EFB/#B484F3/#E478C3` income and `#FF8A3D/#F542A7` expense treatment. | Exact catalog + mounted toggle tests. | DONE |
| DIR-02 | User Part A | Shared `TransactionDirectionToggle` | Profile changes selected control material only in every mode; inactive style, selected direction, gesture, bounds, shadow and pulse remain unchanged. | Production-parent widget test. | DONE |
| AVA-01 | User Part B | Presentation-only category palette catalog | `color_01`…`color_21`, fallback, three stops and authored angles remain canonical; four profiles each resolve 21 exact three-anchor gradients. | Complete 189-anchor catalog test plus canonical identity/angle test. | DONE |
| AVA-02 | User Part B | `PreparedVectorAssetAtlas` | A bounded profile × category prepared badge bank supplies ordinary badges and LogBox resources without hot-path gradient/raster creation. | Atlas identity/resource-count and LogBox badge switch tests. | DONE |
| AVA-03 | User Part B | Avatar profile scope/bindings | Balance, Budget, generic CategoryVisualBadge and LogBox change visual gradients while category IDs/icons/query/transaction identity do not. | Mounted cross-surface tests. | DONE |
| ART-01 | User Part C | Global appearance state + `TransactionDirectionToggle` | `showsDirectionArtwork` defaults true; one switch hides both existing wallet/bag assets without recoloring or modifying SVGs. | Mounted ON/OFF and source-hash/diff audit. | DONE |
| ART-02 | User Part C | Direction renderer | OFF removes icon space and centers text while retaining controls' fixed bounds, semantics and direction behavior. | Bounds/selection widget test. | DONE |
| TYPO-01 | User Part D | One global appearance typography profile | One App/Color Lab authority replaces independent Header typography state; App default preserves inherited family and Color Lab is `FluviColorLabInter`. | State/controller + mounted app scope tests. | DONE |
| TYPO-02 | User Part D | Root theme and explicit style resolver | All ordinary application text/numbers inherit the selected family without changing typography metrics. | Representative Balance/Mind/Budget/Summary/Query/tuner/nav mounted tests. | DONE |
| TYPO-03 | User Part D | Explicit typography consumers | Header frames, BNB03, custom painters and all LogBox prepared text resolve the global profile; no visible hardcoded `SF Pro Text` island remains. | Source audit + dedicated BNB/Header/LogBox tests. | DONE |
| TYPO-04 | User Part D | LogBox text/scene cache | Typography profile/generation invalidates text layouts safely, never leaves mixed-font committed rows, and does not cause repository/query/prepared-index work. | Cache generation and no-domain-work tests. | DONE |
| UI-01 | User settings contract | Existing Header visual tuner | Stable direction/avatar/artwork/global-typography controls exist, labels are Hungarian, choices are independent and no persistence owner is added. | Tuner mounted test and state-preservation tests. | DONE |
| INV-01 | User scope lock | Existing controllers/policies | No financial, query, Summary, time navigation, carousel physics, Header palette math or category semantic identity change. | Diff audit + protected regressions. | DONE |
| PERF-01 | User performance contract | Appearance/atlas/cache owners | No repository/index/query/projection/scene work from profile switches; no per-frame palette/raster work or new ticker/controller. | Focused counters/source audit/regressions. | DONE |
| DEL-01 | Global delivery rule | GitHub Actions + tooling worktree | Atomic app delivery, exact-source online human APK downloaded and SHA/identity verified, then separately regenerated exact-source SCIP. | CI/API/APK/tooling evidence. | DONE |
| PHYS-01 | User-only boundary | Android user | Visual/contrast/install acceptance is never inferred. | User only. | PENDING — USER ONLY |

## Immutable exact-data references

- Direction profile anchors and all 189 alternate category anchors are exactly
  the user prompt in this conversation. Production tests must encode every
  supplied value; this checklist deliberately does not create a second mutable
  color specification.
- Original category data remains sourced from
  `assets/category_catalog/category_catalog.json`; generated Dart is evidence,
  not an editable canonical input.
- Fallback remains `#64748B → #7C8CA3 → #94A3B8`.
