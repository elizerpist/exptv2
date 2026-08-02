# Fluvi Demo Dataset Vertical Slice

## Goal

Provide a deterministic, idempotent demo dataset in the real Room database and
prove that it travels through the existing core revision, SQL read service,
Flutter bridge, current query controller, and SummaryPill amount path.

## Architecture

`DemoDatasetGenerator` is pure Kotlin and produces an immutable dataset plan;
it knows catalog IDs but no Flutter colors, SVG paths, widgets, or DAOs.
`SeedFluviDemoDatasetUseCase` owns one atomic Room write and reuses the core's
validation, revision, projection, and repository boundaries. The Flutter debug
bridge sends one seed command and receives a report; it never sends records or
aggregates data. Dashboard observation is driven by Room's core-revision
invalidation and uses the same canonical query scope for totals and pages.

## Scope

- Seven closed local-calendar months: 2026-01-01 through 2026-08-01.
- Exactly 100 entries per month, 700 entries total.
- Six income and 94 expense entries per month.
- Ten demo categories in addition to the seeded Uncategorized category.
- Approximately 20–30 deterministic demo partners.
- Monthly income targets near HUF 700,000.
- Monthly expense targets between HUF 600,000 and HUF 800,000.
- Low, medium, recurring high, and occasional exceptional expenses.
- Debug-only seed trigger and debug-only navigation to July 2026.
- No final LogBox widget; only its stable paged read contract.

## State and write ownership

| Concern | Owner | Rule |
| --- | --- | --- |
| Dataset values | `DemoDatasetGenerator` | Pure deterministic output; no I/O |
| Seed transaction | `SeedFluviDemoDatasetUseCase` | One Room transaction and one completion report |
| Seed completion/version | existing `fluvi_app_settings` metadata | Nullable demo metadata, migrated safely |
| Ledger revision | `FluviCoreRevisionRepository` | Increment after the atomic dataset write |
| Dashboard read | `FluviLedgerReadService` | SQL total and bounded page from one scope |
| Query state | `CurrentQueryController` | Latest-wins, distinct scope, revision-aware cache |
| Navigation to demo period | debug coordinator | Never changes production default |
| Amount rendering | Summary amount presentation | Uses query result only; never seed report totals |

## Canonical data flow

```text
debug seed command
  -> SeedFluviDemoDatasetUseCase
  -> Room transaction: categories + partners + ledger rows + metadata
  -> core revision invalidation
  -> FluviLedgerReadService total/page
  -> native stream bridge
  -> CurrentQueryController latest-wins state
  -> SummaryAmountPresentation and future LogBox read model
```

## Idempotency

The seed version is `1` and the PRNG seed is `20260107`. Every demo category,
partner, alias, and ledger row receives a deterministic valid 26-character ULID
derived from the version and ordinal. The metadata row records completion. A
second run with `forceReset == false` is a no-op when the manifest is complete.
`forceReset == true` deletes only the known demo IDs in foreign-key-safe order;
it never scans or deletes user rows.

## Query and LogBox contract

The native slice includes `queryKey`, `coreRevision`, `direction`,
`timeScope`, `totalMinor`, `entryCount`, and a bounded page with stable cursor
ordering (`bookedLocalEpochDay DESC`, `bookedLocalTimeMinutes DESC`, `id DESC`).
Rows expose stable category and partner IDs plus resolved display fields; they
do not expose Flutter `Color`, `Widget`, `IconData`, or asset paths.

## Demo navigation

The production initial scope remains the current month. When the debug seed
command succeeds, a debug-only coordinator moves the existing time navigation
controller to `MONTH / 2026-07 / rail closed`. This is separate from the core
seed use case and does not hardcode a production date.

## Verification

- Pure generator tests assert exact month counts, totals, ranges, references,
  and deterministic output.
- In-memory Room tests assert atomic writes, metadata, revision, query totals,
  pages, and rollback.
- Idempotency and force-reset tests prove no duplicates and preservation of
  non-demo rows.
- Bridge contract tests assert report and row mapping.
- Query observer tests assert revision-triggered emission without refresh.
- Flutter controller tests assert latest-wins scope updates and stale amount
  behavior.
- Architecture checks assert UI does not depend on Room/DAO and the SummaryPill
  does not receive seed-specific data.
