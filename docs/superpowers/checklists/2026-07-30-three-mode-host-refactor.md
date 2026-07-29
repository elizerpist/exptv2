# Three-mode host refactor acceptance checklist

| ID | Source | Intended code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| MODE-001 | User: “3 mode van, 3 adatfolyammal” | `spendee_dashboard_mode.dart`, mode hosts | The five existing variants map to exactly three mode families: Balance, Budget, Mind. | Focused unit test for every enum value. | NOT DONE |
| MODE-002 | User: “a módnak van ui variánsa amit nem szedsz ki” | mode mapping and hosts | Balance/Balance V2 and Budget/Budget V2 remain selectable visual variants with their existing behavior routes. | Existing mode/menu contract tests plus new mapping test. | NOT DONE |
| MODE-003 | User: “egyszerre csak egy látszik” | dashboard router | Exactly one selected host is mounted; inactive mode trees are absent rather than merely hidden by `IndexedStack`, `Offstage`, or disabled `TickerMode`. | Widget test checks host keys before and after switches. | NOT DONE |
| MODE-004 | User: “menükhöz nem nyúlsz” | `spendee_test_dashboard.dart` menu code | Menu labels, order, keys, locations, and A/B controls are unchanged. | Existing dashboard interaction/contract tests; source review of menu-only diff. | NOT DONE |
| MODE-005 | Approved design | host lifecycle | A mode or variant switch disposes host-local timers, animation controllers, gesture state, and caches. | Lifecycle regression widget test with host disposal observer. | NOT DONE |
| MODE-006 | Approved design | host state boundary | Shared TransactionStore filter state survives a switch, while local carousel/collapse/motion state resets in the new variant. | Widget test using a selected category and a host-local state probe. | NOT DONE |
| MODE-007 | User: “csak logikát racionalizálsz” | all refactor files | No intentional visual or business-logic change is introduced. | Existing Balance, Budget, Mind, and interaction regression suites. | NOT DONE |
| MODE-008 | User: current app remains usable until migration | build/test surface | The refactor passes targeted Flutter analysis and test coverage in Ubuntu/proot; unrelated dirty files are not staged. | Ubuntu `flutter analyze`/`flutter test`, `git diff --check`, staged-file review. | NOT DONE |
