# Fluvi Core Foundation — clean-room architecture

**Status:** the clean Room core was verified on GitHub Actions run 30622441391.
The repository now also contains a separate, data-free Flutter dashboard host;
this document remains the acceptance source for the Room-core boundary.

## Scope and source

- User instruction, 2026-07-31: Fluvi is a complete clean rewrite. The first
  delivery contains an independently usable database-management core only.
- It must not inherit features, models, repositories, UI, or data from any
  existing worktree.
- The initial core delivery deliberately had no Flutter UI or Android
  application module. The repository now has a Flutter host and `:app` module,
  but neither calls Room or creates a second core write path.
- There is still no Google API client, notification parser runtime, Sheets
  adapter, recurring runtime, or restore runtime.

The Git worktree supplies version control and generic build tooling only. It is
not a source of Fluvi behaviour.

## Fluvi core architecture card

### Single source and write path

- Source of truth: a new Room v1 database, fluvi_core.db.
- Supported external entry point: FluviCoreFactory returns FluviCore. Room,
  DAOs, repositories, and transaction wiring are module-internal.
- Read model: immutable Kotlin models returned by FluviLedgerReadService.
- Only write path: Kotlin use case -> repository -> one
  RoomDatabase.withTransaction transaction.
- SQLite triggers reject invalid persisted ledger ID/amount/local-time/revision
  values even if a lower-level database write is attempted inside the module.
- Error/retry owner: LedgerSyncOutboxRepository owns durable pending
  projections. A later, separate adapter/coordinator will own network retries.
- No direct database caller: there is no presentation layer in this slice.

### State ownership

| State | Owner | Lifetime | Publication rule |
| --- | --- | --- | --- |
| Canonical ledger, Partner, category state | internal FluviDatabase | persistent | only typed core use cases mutate it |
| Effective flat Sheet row | LedgerSheetProjection | derived at command time | stored only in the per-entry outbox payload |
| Pending export | LedgerSyncOutboxRepository | until remote acknowledgement | coalesced by stable entry ID |
| Year-to-workspace mapping | FluviLedgerSyncWorkspaceRepository | persistent | one workspace identity per booking year; no API client |
| Saved Query snapshot slots | FluviQuerySnapshotRepository | persistent | exactly Snapshot 1 and Snapshot 2; explicit save/load only |
| Unsaved Query | later presentation controller | process/session | explicitly absent from Room |
| Checkpoint metadata | LedgerCheckpointRepository | persistent | remote bundle/upload stays outside this first core |

### Reuse and centralization decision

| Candidate | Existing owner | Shared invariant | Decision | Proof |
| --- | --- | --- | --- | --- |
| Legacy Exptv2/Spendee Room/data layer | legacy worktrees only | none accepted; schema and semantics differ | do not reuse or wrap | no com.exptv2/Flutter imports or old table names in Fluvi |
| New ID, category resolution, query scope, Sheet projection | Fluvi core owner | each has one semantic definition | create one neutral Kotlin implementation | focused unit/Room tests |
| Flutter dashboard UI | Flutter app host | rendering and temporary gesture state only | keep data-free until a typed core adapter is designed | no Room/repository/query/logbox import in `lib/` |

### Layer flow

future Flutter adapter -> typed core contract -> Kotlin use case -> repository
-> Room

The current Flutter dashboard is not yet this adapter: it has no core call or
database write path. A future adapter remains an external consumer and may not
become a second write path.

### Module boundary

The repository contains two separated production modules:

    android/
      fluvi-core/       # Android library; Kotlin + Room only
      app/              # Flutter Android host; no Room construction
    lib/                # Flutter data-free presentation

`android:fluvi-core` contains no Flutter plugin or application plugin. The
Flutter host may build a debug APK in GitHub Actions, never as a local Termux
APK build.

## Core data contract

### General values

- All persistent primary keys are stable 26-character ULID strings.
- HUF is the global currency in one app_settings row. No entry has a
  per-row currency.
- app_settings also owns a monotonic core_revision watermark. User-owned
  ledger, Partner, category, and saved-Query changes advance it; outbox
  acknowledgement and checkpoint transport bookkeeping do not.
- Money is a positive amount_scaled_100; income/expense carries the sign.
- An entry carries local booking day, local booking time (0..1439), and a UTC
  instant.
- Categories store only one stable colour ID (from 21 catalog values) and one
  stable icon ID (from 50 catalog values). The core stores no palette slot,
  colour literal, asset path, or UI index.

### Current transactional tables

- app_settings
- categories
- partners, partner_aliases
- ledger_entries
- ledger_deletion_archive
- query_snapshots, query_snapshot_periods, query_snapshot_categories,
  query_snapshot_partners, query_snapshot_refinements
- ledger_sync_outbox, ledger_sync_workspaces, ledger_backup_checkpoints

### Schema-only future tables

These establish v1 foreign-key-safe structure but have no runtime engine in
this slice:

- recurrence_rules, time_recurring_rule_config, push_recurring_rule_config,
  occurrence_overrides
- notification_inbox

The Inbox status values are exactly unclassified|recognized|invalid,
unprocessed|transaction_created|ignored|duplicate, and
unused|selected|incorporated.

### Partner/category invariants

- Partner is the one shared vendor/manual-name concept. An entry has only
  Partner plus optional note.
- A Partner can have a non-destructive display-name override and reversible
  merge target.
- Alias matching is exact on normalized aliases.
- The seeded system Uncategorized category is non-deletable.
- Category delete atomically redirects Partner defaults, active ledger category
  values, recurrence values, and occurrence overrides to Uncategorized.
- Partner default change updates only active rows marked partnerDefault,
  including rows stored under identities currently merged into the canonical
  Partner; entryOverride rows do not change.
- Every ledger row stores exactly one materialized effective category. There is
  no split/line-item table.

### Ledger, deletion, and projection invariants

- A ledger entry is active only while it exists in ledger_entries.
- Delete copies its last flat LedgerSheetRow projection once into the bounded
  archive, replaces/creates one delete outbox operation, and removes the active
  entry in the same transaction. The archive is purged only after its required
  checkpoint is acknowledged, so it is bounded rather than edit history.
- Ordinary edits do not write permanent edit-history records.
- Repeated unsynced writes to one entry produce one final outbox upsert.
- A projection has one row per active ledger entry and includes resolved Partner
  name, effective category, booking year, and hidden stable IDs/revision.
- booking year maps to exactly one persistent workspace identifier. The later
  Sheets adapter derives its destination from this mapping; the core makes no
  Google API call.

### Query and checkpoint invariants

- Direction is required and exclusive.
- Selected category/Partner IDs are OR within each facet and AND across facets.
- Explicit period selections within one time group are OR (so, for example,
  `2024-01` and `2026-02` can be selected together); distinct time groups
  combine by AND.
- The time menu is a prefilter for available categories and Partners: it lists
  only values actually represented by the selected temporal scope. Its output
  is not a second hierarchy or UI state owner.
- Loaded snapshots and a later current-session condition combine by AND.
- There are exactly two saved snapshot slots, Snapshot 1 and Snapshot 2. Each
  is direction-affine and a save replaces only that slot. The unsaved current
  query is not persisted, resets on restart, and only becomes active when
  explicitly loaded.
- Timeline reads use keyset cursors and summaries use SQL aggregation, never a
  full Kotlin list.
- Checkpoints in this slice are metadata/preparation contracts only: daily,
  manual, before-destructive, before-restore, before-schema-upgrade. A daily
  checkpoint deduplicates by local day; destructive and restore guards each
  receive their own checkpoint ID. They record a source_core_revision and do
  not duplicate an edit-history copy of every ledger row.
- An acknowledged checkpoint must identify a prepared local bundle or remote
  backup artifact; only such a checkpoint can produce a restore guard plan.
- Bundle creation/upload/download/database replacement remain outside this
  core. A restore call returns a guarded restore plan, never mutates data.

## Acceptance checklist

| ID | Source | Intended area | Acceptance condition | Verification | Status |
| --- | --- | --- | --- | --- | --- |
| FCORE-01 | User, 2026-07-31 | repository root, Gradle settings | Flutter/UI/app consumer remains separate; `android:fluvi-core` has no Flutter or application-plugin dependency | tracked-file and dependency audit | DONE — core boundary verified; Flutter consumer is separately guarded |
| FCORE-02 | structuring-apps | android/fluvi-core | One library module owns Room; `FluviCoreFactory` is the supported facade and no presentation/database bridge exists | settings/import audit | DONE — source audit and CI boundary check passed |
| FCORE-03 | prior Fluvi decisions | database schema | Fresh v1 DB is clean-room and contains current plus schema-only future tables | Room schema/seed test | DONE — generated v1 schema and x86 Room tests passed |
| FCORE-04 | prior Fluvi decisions | IDs/catalog | ULIDs, 21/50 catalog identities, global HUF and scalar validation are centralized | domain tests | DONE — focused JVM tests and x86 Room tests passed |
| FCORE-05 | prior Fluvi decisions | Partner/category use cases | Default/change/delete/merge rules maintain the agreed materialized category semantics | transactional Room tests | DONE — x86 Room tests passed |
| FCORE-06 | prior Fluvi decisions | Ledger use case | Create/update/override/delete are one write path; archive is deletion-only | transactional Room tests | DONE — x86 Room tests passed |
| FCORE-07 | prior Fluvi decisions | Sheet projection/outbox | One active entry maps to one current row; five edits coalesce | projection/outbox tests | DONE — x86 Room tests passed |
| FCORE-08 | prior Fluvi decisions | Query/snapshots | Cursor timeline, SQL summary, normalized direction-affine snapshots obey scope rules | Room/query tests | DONE — x86 Room tests passed |
| FCORE-09 | prior Fluvi decisions | checkpoint metadata | Daily/pre-operation checkpoint state is modeled without a network adapter | clock-driven unit tests | DONE — x86 Room tests passed |
| FCORE-10 | user scope | recurring/Inbox | Only schemas exist; no ghosts, parser, listener, UI, API, or restore runtime is smuggled in | source audit | DONE — staged audit and CI boundary check passed |
| FCORE-11 | scale requirement | read service | 50,000 entries return bounded pages and SQL aggregates | synthetic Room test | DONE — x86 Room test passed |
| FCORE-12 | delivery requirement | final branch | Every status is truthful; no claim of UI, APK, Sheets API, restore, recurring, or Inbox runtime | checklist reread + CI | DONE — checklist re-read; CI run 30622441391 passed |
