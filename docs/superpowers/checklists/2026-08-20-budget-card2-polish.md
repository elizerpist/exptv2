# Budget Card2 polish — acceptance checklist

## Architecture card

### Scope and sources

- User requirement: Card2 pager shadow clipping, immediate Partner feedback, and
  aggregate Budget avatar intrinsic depth.
- Approved physical reference:
  `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260819-234720.png`.
- Existing owners:
  `BudgetDistributionPager`, `BudgetDistributionPageCard`,
  `BudgetPartnerDistributionCard`, `DashboardEphemeralFocusController`, and
  `BudgetCategoryAvatarSvg`.

### Single source and write path

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Pager/page physics | `BudgetDistributionPageController` | Card2 | Existing `PageController`; no replacement |
| Partner semantic focus | `DashboardEphemeralFocusController` via Core | Prepared focus publication | Authoritative only |
| Pending Partner visual intent | Partner-card presentation state | Current compatible card frame | Immediate local paint only; clears/acknowledges against authoritative focus |
| Aggregate avatar hue | `DashboardBudgetAggregateVisual` | Immutable target catalog | Read only |
| Aggregate avatar lighting | Avatar-specific face-tone projector | Prepared avatar artwork | SVG creation only during immutable avatar preparation |

### Reuse and centralization decision

| Candidate | Existing owner | Decision |
| --- | --- | --- |
| Card visual tokens | `FluviVisualTokens` / `FluviRoundedBox` | Preserve; change only pager clipping contract |
| Focus flow | `DashboardBudgetLogboxDrilldownCoordinator` / Core | Preserve as semantic owner; add no second filter |
| Donut selection | `BudgetClayDonutScene` | Preserve retained scene; only feed pending selected index |
| Avatar SVG body | `BudgetCategoryAvatarSvg.avatarDisc` | Extend one face-tone projection; no Flutter gradient replacement |

## Requirements

| ID | Source/reference | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BCP-01 | Screenshot + user A | Pager/card surface | PageView does not clip travelling rounded-card shadows or add a rectangular backdrop | Pager widget test + source inspection | DONE |
| BCP-02 | User B | Partner card | Tap paints row and donut selection synchronously while focus stays authoritative | Widget tests with incomplete/failed/superseded focus Futures | DONE |
| BCP-03 | User B | Partner card | Pending intent invalidates for target/direction/scope/frame changes and row has no 120ms animation | Widget/architecture test | DONE |
| BCP-04 | User C | Avatar artwork | Aggregate preserves canonical cyan/purple hue but receives category-equivalent authored light/main/body/depth | Unit/artwork test | DONE |
| BCP-05 | Protected a84bad3 | Distribution/rail | No SVG/PictureInfo return, scene identity unchanged by selection, and no repository/bridge work on hot paths | Existing boundary/performance tests | DONE |
| BCP-06 | Delivery | GitHub Actions | Focused suite, analyzer, human `lib/main.dart` APK and SHA-256 evidence | CI run + downloaded artifact | DONE |
| BCP-07 | Physical acceptance | Android device | Slow/fast pager swipe, Partner tap feedback, aggregate avatar depth, and TimeRail/Budget regression verified on a human-operated device | Manual user test of the delivered APK | BLOCKED — awaiting user device test |
