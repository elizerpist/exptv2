# Budget V2 income and distribution acceptance checklist

| ID | Requirement source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| BUDGETV2-001 | User: the expense side lacks the sum-category avatar | Budget V2 bar/rail model | Expense belt includes the stable overview/sum avatar plus every active expense category. | Production-host widget test. | DONE |
| BUDGETV2-002 | User: income needs its own avatars, chart, limit and cards | Balance dashboard + Budget V2 adapters | Income type resolves an independent, non-empty Budget V2 belt and mother-card from filtered income records/categories. | Production-host widget test. | DONE |
| BUDGETV2-003 | User: category card needs a title | Distribution card | The category-distribution page displays `Kategóriák eloszlása` at its top left. | Widget test. | DONE |
| BUDGETV2-004 | User: fourth switchable card, vendor distribution with real data | Distribution aggregation + mother-card pages | A fourth page, `Vendorok eloszlása`, uses the filtered records' merchant sums and central category colors, and is pageable like the category distribution. | Unit/widget test with distinct merchant totals. | DONE |

## Evidence ledger

All commands ran from `/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree` in the Ubuntu proot environment.

- BUDGETV2-001: `/home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 production expense belt includes the overview Budget avatar" -r expanded` — `00:04 +1: All tests passed!`, `TEST_EXIT=0`.
- BUDGETV2-002: `/home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 production income resolves its own overview, category belt and mother card" -r expanded` — `00:04 +1: All tests passed!`, `TEST_EXIT=0`.
- BUDGETV2-003: `/home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 mother-card cycles readable pages and keeps its page on category selection" -r expanded` — `00:05 +1: All tests passed!`, `TEST_EXIT=0`; the test asserts the title is left of the mother-card centre.
- BUDGETV2-004: `/home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart --plain-name "BudgetV2 fourth mother-card page renders the filtered vendor distribution from real records" -r expanded` — `00:04 +1: All tests passed!`, `TEST_EXIT=0`; verifies the live `MOL=1000`, `Lidl=850`, `BKK=150` SVG slices.
- Regression suite: `/home/flutteruser/flutter/bin/flutter test test/spendeetest/spendee_budget_v2_contract_test.dart -r expanded` — `00:17 +17: All tests passed!`, `TEST_EXIT=0`.
- Static analysis: `/home/flutteruser/flutter/bin/flutter analyze lib/features/transactions/widgets/experimental/balance/budget_v2_frame_data.dart lib/features/transactions/widgets/experimental/balance/spendee_budget_v2_components.dart lib/features/transactions/widgets/experimental/balance/spendee_balance_dashboard.dart lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart test/spendeetest/spendee_budget_v2_contract_test.dart` — `No issues found!`, `ANALYZE_EXIT=0`.
