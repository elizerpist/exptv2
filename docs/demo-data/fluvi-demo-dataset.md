# Fluvi deterministic demo dataset

Status: implementation slice in progress; no commit, push, or APK build has
been performed.

## Dataset contract

The debug seed is owned by `SeedFluviDemoDatasetUseCase` in the Kotlin core.
Flutter sends only `forceReset`; it does not generate IDs, dates, amounts, or
ledger rows. The native command writes through the existing Room repositories
inside one `withTransaction` block.

| Field | Value |
| --- | --- |
| Seed version | `1` |
| PRNG seed | `20260107` |
| Local timezone | `Europe/Budapest` |
| Local interval | `2026-01-01` inclusive to `2026-08-01` exclusive |
| Entries | `700` (`100` per month) |
| Monthly mix | `6` income + `94` expense |
| Categories | `10` demo + the existing single Uncategorized |
| Partners | `27` |
| Money | existing `amount_scaled_100` integer contract |

The seed is idempotent by deterministic manifest IDs and the app-settings
metadata fields `demo_seed_version` and `demo_seed_completed_at_utc_ms`.
`forceReset=true` removes only the known deterministic demo IDs and refuses to
remove rows that have acquired external ledger references.

## Categories and catalog assignment

The generator stores only stable catalog IDs. The current deterministic
assignment is:

| Category | colorId | iconId |
| --- | --- | --- |
| Fizetés | `color_18` | `icon_25` |
| Egyéb bevétel | `color_19` | `icon_05` |
| Lakhatás | `color_17` | `icon_35` |
| Élelmiszer | `color_15` | `icon_13` |
| Közlekedés | `color_16` | `icon_17` |
| Rezsi | `color_21` | `icon_20` |
| Egészség | `color_06` | `icon_11` |
| Szórakozás | `color_12` | `icon_43` |
| Vásárlás | `color_02` | `icon_49` |
| Előfizetések | `color_20` | `icon_14` |

Uncategorized remains explicitly pinned to `color_01` + `icon_01`; the seed
never creates a second system category.

## Monthly targets

All values below are human-readable HUF totals. The generated plan validates
the exact integer totals before Room is touched.

| Month | Entries | Income | Expense |
| --- | ---: | ---: | ---: |
| 2026-01 | 100 | 705,000 | 642,000 |
| 2026-02 | 100 | 694,000 | 781,000 |
| 2026-03 | 100 | 712,000 | 668,000 |
| 2026-04 | 100 | 701,000 | 735,000 |
| 2026-05 | 100 | 698,000 | 612,000 |
| 2026-06 | 100 | 721,000 | 798,000 |
| 2026-07 | 100 | 707,000 | 689,000 |

Each month contains recurring rent/utilities/transport/subscriptions,
low-value daily purchases, medium variable purchases, and a high-value
exception such as a household appliance, dental treatment, travel, electronics,
insurance, holiday advance, or repair. Entry overrides are deliberately
included and can differ from the partner default category.

## Runtime path

```text
FLUVI_SEED_DEMO debug flag
  -> DemoSeedCoordinator
  -> MethodChannelDemoDataBridge
  -> MainActivity / com.fluvi/demo_data
  -> SeedFluviDemoDatasetUseCase
  -> Room transaction
  -> core_revision + projection/outbox
  -> FluviLedgerReadService.observeSlice
  -> EventChannel / com.fluvi/dashboard_query_stream
  -> CurrentQueryController
  -> SummaryAmountPresentation
```

`FluviLedgerReadService.readSlice` uses one canonical `FluviQueryScope` for the
SQL aggregate and the stable, cursor-based first page. The returned
`queryKey` and `coreRevision` are part of both the SummaryPill result and the
future `DashboardLedgerRow`/LogBox contract. Category and partner display
metadata is batched in the read service; Flutter receives IDs and names, never
Flutter `Color`, `Widget`, `IconData`, or asset paths.

The query observer is revision-driven. A seed transaction advances the core
revision once, Room invalidation emits a fresh slice, and the Flutter query
controller applies only the current scope generation. The old one-shot read
API remains available for direct reads and compatibility, while the Android
repository uses the EventChannel for ongoing observation.

## Debug entry point

Run a debug build with `FLUVI_SEED_DEMO=true`. The production current-date
default is not changed. After the seed command succeeds, the separate
`DemoSeedCoordinator` sends a navigation intent to a closed July 2026 month
scope so the seeded rows are immediately visible.

The bridge returns a typed `DemoSeedReport` containing seed version, PRNG seed,
created counts, monthly reports, date bounds, idempotency state, and duration.
SummaryPill never reads these report totals; it displays only the real
dashboard SQL result.

## Outbox and projection

The seed uses the normal `LedgerChangePublisher` for the inserted rows and
advances the existing core revision. Local projection/outbox records therefore
follow the same invariant as ordinary ledger writes. The demo command is
debug-only at the Android bridge boundary; production builds reject that
bridge. No global production outbox behavior is disabled.

## Verification status

Passing locally in the Ubuntu/proot Flutter environment:

- pure deterministic generator tests;
- seed report bridge decoding;
- EventChannel dashboard bridge decoding;
- latest-wins query observer tests;
- demo July navigation controller test.

The Room integration tests compile and reach execution, but the local Android
ARM64/proot Robolectric environment currently fails before test setup with
`UnsatisfiedLinkError: no conscrypt_openjdk_jni-linux-aarch_64`. This is an
environment blocker for executing those tests here, not a test assertion
result. The full Android app resource task is similarly blocked locally by
AAPT2 daemon startup; Kotlin compilation of both `fluvi-core` and the app
bridge succeeds when resource processing is excluded.

## Future LogBox contract

The native read model already exposes a bounded page with stable ordering:

```text
occurred/booked local day DESC,
booked local time DESC,
entryId DESC
```

Rows contain entry ID, direction, integer amount, timestamps, partner and
category IDs/display names, category `colorId`/`iconId`, assignment mode,
origin kind, note, and the shared `queryKey`/`coreRevision`. A future LogBox
can page using `nextCursor` without changing SummaryPill or the query owner.
