# Balance Movers, exact palettes and Latest correction — Acceptance Checklist

## Architecture card

### Scope and sources

- User requirements: 2026-09-24 prompts for Category Movers, exact 11 × 3
  Balance Header palettes, and Latest two-row/local-time correction.
- Existing owners: `DashboardBalanceLinkedProjection` / its immutable
  `DashboardBalanceLinkedPresentation`; `BalanceDashboardCoreSurface` and
  `BalanceLinkedDetailCard`; `DashboardHeaderVisualController`,
  `DashboardBalanceHeaderColorState` and
  `DashboardBalanceHeaderPaletteCatalog`.
- Protected source: `6e962187e90e2a82431b1f91b224d2b52a6e0ba7`.

### Single sources and write paths

| State | Owner | Write path | UI boundary |
| --- | --- | --- | --- |
| Movers financial data | `DashboardBalanceLinkedProjection` | Resident prepared membership → immutable linked presentation | Lower/upper widgets only render and retain local inspected mover id. |
| Latest local clock | `DashboardBalanceScopedTransaction` | `DashboardLedgerEntry.bookedLocalTimeMinutes` → projection | Widgets format the supplied integer only. |
| Palette family/variant/window | `DashboardHeaderVisualTuning` | `DashboardHeaderVisualController` setters | Tuner forwards user selection; header policy samples immutable catalog data. |

### Reuse / centralization decision

| Requirement | Existing owner reused | Explicit non-duplication decision |
| --- | --- | --- |
| Movers comparison math | `dashboard_balance_category_movers_projection.dart` | Port/rebind the one dormant engine; no widget or second query engine. |
| Carousel motion/selection | existing `CenteredCarousel` + Balance local topic state | Add only a finite topic mapping; no controller/physics owner. |
| Palette interpolation | `DashboardHeaderPerceptualColorMath` | Exact anchor arrays are catalog data; existing perceptual interpolation remains between anchors. |
| Category visuals | `BalanceCategoryVisualBadge` / category catalog | Movers uses the established resolver, not copied colour/icon rules. |
| Local time formatting | existing `_formatClock` in linked detail | No `occurredOrder` decoding or wall-clock read. |

## Acceptance inventory

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| ARC-01 | Architecture card | All changed app files | One declared owner/write path per derived data or visual setting; UI has no repository/Query work. | Source audit + focused boundary/no-source-work tests | DONE — local source/test evidence |
| MOV-01 | Journal 2026-09-24 | Movers projection + linked presentation | Reconnect selected-direction current/reference comparison using full resident membership; preserve exact comparison semantics and finite `New`. | Pure RED→GREEN tests | DONE — focused projection test |
| MOV-02 | Journal 2026-09-24 | Movers projection | Retain/render at most top five; no N×category full-membership trend scan; ranking stays identical. | Boundedness/ranking test + source inspection | DONE — bounded top-five test |
| MOV-03 | Journal 2026-09-24 | Balance topic domain/surface/detail | Add Movers as 11th topic immediately before Top Category; one existing carousel, indicator strip and lower shell. | Mounted production-parent tests | DONE — mounted rail mapping test |
| MOV-04 | Journal 2026-09-24 | Movers renderer | Compact hero, diverging five-row overview, local inspected detail, Back/stale replacement/empty state; no Query/Summary mutation. | Widget interaction tests | DONE — mounted local-state test |
| PAL-01 | Palette prompt | Balance color catalog | Exactly 11 families × exact Original/Saturated/Vivid anchor arrays = 33 combinations; Original data unchanged. | Full-array catalog tests | DONE — all 33 complete arrays asserted |
| PAL-02 | Palette prompt | Header visual state/controller | Variant is explicit state; defaults Soft rainbow/Original/50/28; mutations preserve every unrelated setting and no-op on reselect. | Controller/state tests | DONE — focused controller/state test |
| PAL-03 | Palette prompt | Header tuner/policy | Existing 11-family selector remains; adjacent three-entry variant selector works; window geometry/animation/foreground/opacity unchanged. | Mounted tuner/policy tests | DONE — mounted tuner/policy test |
| LATEST-01 | Latest correction prompt | Scoped transaction DTO/presentation identity | Local minutes flow directly from ledger; visible time participates in linked identity even when UTC ordering remains same. | Projection RED→GREEN test | DONE — exact identity test |
| LATEST-02 | Latest correction prompt | Selected carousel preview | Exactly two visual rows; date is inline, title/rounded-square avatar remain, no amount and no mechanics change. | Mounted surface/bounds test | DONE — selected-rail mapping test |
| LATEST-03 | Latest correction prompt | Main Latest lower rows | Five fixed rows remain no-scroll/no-divider; metadata includes category/date/HH:mm; semantics include time. | Mounted detail/bounds test | DONE — fixed-row/semantics test |
| REG-01 | All prompts/milestone | Existing systems | Header financial data, query/Summary, Mind/Budget, carousel mechanics, global geometry and Category/Partner contracts untouched. | Focused protected suites + diff audit | PARTIAL — final CI/fast-suite gate pending |
| DEL-01 | User delivery instruction | App/tooling/docs delivery | One final application build after all three units, APK identity/hash, final exact-SHA SCIP, separate journal-only commit. | CI/APK/graph/Git evidence | NOT DONE |
| PHYS-01 | User evidence boundary | Android device review | Physical validation remains a user decision. | User validation | BLOCKED — USER ONLY |
