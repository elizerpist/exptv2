# Production Query Menu — acceptance checklist

Scope: the production implementation on branch `query`, based on current
`main` (`381f2306856fcf6903b53e41b3b0c897aa497e1b`). Functional dashboard
baseline: `e64e84aededa61f7f41124100309e819eceb269e`. UI source: 
`.superpowers/brainstorm/19647-1786313605/content/querymenu.html`.

### Presentation responsibility note

`query_menu_sheet.dart` is intentionally the HTML-to-Flutter compositor for
this one sheet and is larger than the normal presentation-file guideline. It
contains no persistence, transport, SQL, canonical-query calculation or
animation engine: those responsibilities live respectively in the repository/
controllers, domain scopes, and `FacetPickerMorphHost`. It may be split by
section only when a second production surface shares a section renderer; doing
so now would create artificial shared abstractions rather than reduce an
actual ownership boundary.

| ID | Source | Intended owner / code area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| QRY-01 | §6, §18 | `CurrentQueryController`, Dashboard core integration | One applied scope; menu edits only a draft; Apply is a single transition | `query_composer_controller_test`, `dashboard_core_query_application_test` | DONE |
| QRY-02 | §7–9, §40 | `FluviSlideUpSheet` | Query and future add transaction share a query-agnostic slide-up shell | `fluvi_slide_up_sheet_test`, source boundary test | DONE |
| QRY-03 | §4, §37–38 | Query presentation tokens/widgets | White-sheet HTML hierarchy, controls and sticky CTA are ported with centralized metrics | Widget hierarchy/mobile-width tests; device screenshot/manual review remains required | PARTIAL |
| QRY-04 | §10–11 | Shared `FacetPicker` transition | Category/partner picker share one sheet-local transition and never create a second modal route | `query_menu_sheet_test` opens, selects and reverses both pickers | DONE |
| QRY-05 | §12–14, §32, §34 | Core read service + typed Flutter adapter | Real Room-backed count, facets, search and amount domain; no Dart ledger filtering | Flutter adapter/boundary tests + Kotlin compilation; local Room test resource link is environment-blocked | PARTIAL |
| QRY-06 | §15–16 | `CurrentLedgerQueryScope` / core query models | Direction/exclusive, intra-facet OR and inter-facet AND are canonical and stable | Dart semantics tests pass; native Room semantic test is environment-blocked | PARTIAL |
| QRY-07 | §17, §33, §35–36 | Composer controller/read coordinator | Latest-wins async reads; slider drag remains local; no I/O in animation/pointer frame | Controller + local-slider widget test/code boundary inspection | DONE |
| QRY-08 | §20–24 | `DashboardTemporalAvailability` + navigation/catalogs | Restrictive time removes excluded years/months; unrestricted filters retain existing cyclic/infinite behavior | Availability/navigation/catalog/controller tests | DONE |
| QRY-09 | §19 | Dashboard presentation | Applied filter chips occur directly below transaction count and remove/clear atomically | Chip widget + applied-query controller tests | DONE |
| QRY-10 | §25–31 | Room saved-query schema/use case/bridge | Named, direction-scoped saved queries; list/load/dirty/update/save-as-new/rename/delete; no frozen results | Dart controller/bridge tests + Kotlin compilation; local Room test is environment-blocked | PARTIAL |
| QRY-11 | §27–28 | Room v3→v4 migration | Fixed-slot records migrate to named saved queries without data loss | Migration test is present but local Android unit-test resource linking is blocked by Termux AAPT2 | BLOCKED |
| QRY-12 | §5, §39 | Dashboard integration | Milestone rail, controller identity, PreparedDashboardIndex and rail-critical correctness stay intact | `scripts/test-fluvi-fast.sh`: 120 tests passed | DONE |
| QRY-13 | §42–44 | Test/boundary suites | No goldens, no Room import in Flutter, core remains SQL owner, no human-APK harness | Query boundary test + source inspection | DONE |
| QRY-14 | §45 | Current architecture docs | Applied/draft, persistence, availability, shared sheet and chips are documented | `fluvi-core-foundation.md` direct review | DONE |
