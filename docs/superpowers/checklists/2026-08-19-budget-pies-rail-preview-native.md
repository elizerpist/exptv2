# Budget pies — rail-preview-native acceptance checklist

## Architecture card

### Scope and sources

- User requirement: exact `LedgerTimeScope` analytics for Budget Category and
  Partner pies; no dynamic SVG/PictureInfo selection variants; TimeRail preview
  must bind LogBox, header, and both pies to one scope.
- Accepted visual reference: the existing Fluvi clay-donut geometry in
  `budget_category_distribution_svg.dart` (Spendee-derived, already accepted).
- Existing implementation paths: Budget distribution controllers, drawable
  bank, cards, prepared rhythm/partner snapshots, and native grouped Budget
  read service.

### Single source and write path

- Analysis identity: `DashboardVisibleFrame.scope.timeScope` (`LedgerTimeScope`).
- Persisted limit identity: `DashboardBudgetPeriodResolver` only.
- Category Day data: `PreparedBudgetRhythmSnapshot` target-local day points.
- Partner Day data: sparse partner/category/day points from the existing native
  grouped acquisition, transported in the exact revision snapshot.
- Scene preparation/publication owner: the bounded Budget distribution drawable
  controller. UI only paints an immutable scene and emits existing intents.

### Reuse and centralization

| Mechanism | Existing owner | Decision |
| --- | --- | --- |
| TimeRail semantic preview | `DashboardVisibleFrameStore` / existing rail | Reuse exact visible scope; no new rail engine |
| Clay geometry and hit test | `BudgetCategoryDistributionSvg` | Extract one shared scene geometry authority used by painter and hit test |
| Category/Partner cards | shared Card2 surface | Reuse one `BudgetClayDonutView` |
| Financial limit period | `DashboardBudgetPeriodResolver` | Keep for denominator only; explicitly exclude from chart key |

## Acceptance

| ID | Source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BPN-01 | §8.1–8.2 | controllers/core dashboard | Chart identity is `coreRevision × LedgerTimeScope`; Day is not collapsed to Month | July 18/19 scope + retained-preview tests | DONE |
| BPN-02 | §9.1 | rhythm snapshot/projector | Category Day values come from exact prepared rhythm points; no I/O | Day projector and hot-path counter tests | DONE |
| BPN-03 | §9.2 | native partner snapshot/codec/projector | Partner Day target frames come from the existing grouped acquisition with versioned sparse transport | Dart codec/projector green; native GitHub job pending | PARTIAL |
| BPN-04 | §10–11 | shared pie scene/view/cards | One Canvas clay scene painter serves Category and Partner; selection is paint-time only; no `SvgPicture`/`PictureInfo` Budget path | scene/card/pager/boundary tests | DONE |
| BPN-05 | §10, §15 | geometry/hit test | Painter and hit test share slice geometry; selection-absent slice stays unlifted without false aggregate semantics | shared-geometry hit/absence tests | DONE |
| BPN-06 | §12–14 | bounded drawable scene bank/core dashboard | Current direct child domain is retained; TimeRail preview publishes exact retained scene atomically | exact Day retained lookup and bounded-cache tests | DONE |
| BPN-07 | §18 | diagnostics | Scope binding and scene-hotset diagnostics expose exact semantic scope and no SVG/decode hot work | source inspection + scene counter tests | DONE |
| BPN-08 | §20–22 | regression/delivery | Protected preview focus/header/rhythm/card behaviour stays green; normal `lib/main.dart` APK is pushed, built, downloaded and hashed | targeted tests/analyzer green; GitHub Actions artifact pending | PARTIAL |
| BPN-09 | structuring-apps | boundary suite | Presentation has no repository/native/renderer decode dependency and there is one scene geometry authority | boundary test | DONE |
