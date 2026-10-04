# Balance / Budget / FAB refinement acceptance checklist

Reference inspected: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20261004-154337.png`.

## Architecture card

| Concern | Single owner / extension | State and write path | Boundary |
| --- | --- | --- | --- |
| Balance Month/Year savings ring | `BalanceAlternativeSavingsRingCard` | Existing immutable `BalanceAlternativeSavingsPresentation`; no new state | Render-only card receives prepared scalar totals. |
| Balance simple income/expense lane | `BalanceHeaderIncomeExpensePartition` plus `DashboardPartitionLaneGeometry` tokens | Existing resident Balance totals and existing `BalancePresentationSettings.headerGraphPresentation` | Header renderer receives published totals only; no query/repository path. |
| Budget partition height | `DashboardBudgetHeaderPresentationProfile` | Existing controller `setPartitionHeightPercent` | Geometry only; Budget allocation data stays in the prepared partition. |
| FAB direction visual | `Bnb03BottomNavigation` | Existing `TransactionDirectionController` and `FluviGlobalAppearance.directionColorProfile` | Shell listens to existing owners; FAB owns no selection/persistence. |
| Direction gradient / FAB color resolver | `FluviDirectionColorPaletteCatalog` | Global presentation controller's existing direction-profile write path | The same semantic gradient drives the active direction pill and FAB. |

## Acceptance checklist

| ID | Requirement source | Code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BAL-SAV-01 | User + latest screenshot | `balance_alternative_extended_sheet_cards.dart` | Month Savings ring uses available card space more fully while title, amount and percentage stay readable. | Shared-card geometry test + updated visual golden inspection. | DONE |
| BAL-SAV-02 | User + latest screenshot | `balance_alternative_extended_sheet_cards.dart` | Year Savings uses the same enlarged ring treatment. | Shared component golden + geometry test. | DONE |
| BAL-PART-01 | User | `balance_header_income_expense_partition.dart` | Simple Balance income/expense lane has the Budget limit lane's neutral empty track and an app softened-dark fill. | Widget decoration/token contract test. | DONE |
| BUD-PART-01 | User | `dashboard_budget_header_presentation.dart` | Height slider extends below the former 7px minimum to its authored 3.5px lower endpoint while the 7px baseline remains at 0%; upper sizing stays bounded. | Profile geometry unit test. | DONE |
| FAB-ASSET-01 | User | `assets/fluvi/actions/`, `pubspec.yaml` | Both supplied RGBA PNGs are copied byte-for-byte and declared through the existing Flutter asset directory. | SHA-256/file existence + widget asset test. | DONE |
| FAB-DIR-01 | User | `bnb03_bottom_navigation.dart`, `fluvi_app_shell.dart` | Income selection shows the income PNG; expense selection shows the expense PNG. | Widget test. | DONE |
| FAB-DIR-02 | User | `FluviDirectionColorPaletteCatalog` consumer in BNB-03 | The inner FAB has the active pill's left/middle/right colors in the same diagonal orientation; outer ring uses the middle color. | Resolver/painter test for income, expense and profile change. | DONE |
| FAB-DIR-03 | User | `fluvi_app_shell.dart` | Direction change reaches the FAB through the existing transaction-direction controller; no new source of truth. | Boundary test + source inspection. | DONE |
| ARC-01 | Global AGENTS.md | affected presentation files | No UI repository/query work; one existing state owner per setting and one central direction-color token resolver. | Fail-closed boundary/import test. | DONE |
| REG-01 | User | affected tests | Existing Budget progress, direction-pill, BNB/FAB, and Balance card behavior remains green. | Focused suites + 434-test fast suite. | DONE |
| DEL-01 | Global AGENTS.md | GitHub Actions | Application commit is pushed; exact online Human APK is downloaded and SHA-256 checked. | Run `37209966301`, release `fluvi-human-diagnostic-953d7fe`, local artifact checksum and ZIP inspection. | DONE |

## Reference re-read checkpoint

Before final build/commit, re-open the screenshot above and re-check every row.
