# Google Sheets Sync Design

## Goal

Add Google Sheets synchronization for Exptv2 transactions while keeping the
local app database as the only source of truth.

The Google Sheet is a mirrored view for the signed-in Google account. It is not
an import surface, and edits made directly in Google Sheets may be overwritten
by the next sync.

## Confirmed Google Setup

The Google Cloud setup uses one Exptv2 OAuth app. Users do not enter their own
API keys or OAuth clients in the app UI. Each user signs in with their own
Google account, and the sheet is created in that user's Google Drive.

- Sheets API is enabled.
- OAuth consent is configured in testing mode.
- Scope: `https://www.googleapis.com/auth/drive.file`.
- Android package: `com.exptv2.app`.
- Registered SHA-1: `22:98:12:07:52:AC:2A:01:7D:AE:4D:A0:B6:3C:FA:26:3A:FD:9C:29`.
- Android client ID: `881674880679-h7abq4ipc3igqt65r870h4b5m34kghc7.apps.googleusercontent.com`.
- Web/server client ID: `881674880679-ndqgunmnbq49nkdd4oikelnhu88ip13l.apps.googleusercontent.com`.

The app must not use or store a Google OAuth client secret.

## Scope

This work has three parts:

1. Remove unused transaction location fields.
2. Replace the current Google placeholder with a real Google Sheets sync panel.
3. Ensure GitHub Actions signs the APK with the same keystore whose SHA-1 is
   registered in Google Cloud.

The existing local CSV file save and CSV share actions stay. Clipboard export
is removed.

## Cleanup Requirements

`address`, `latitude`, and `longitude` are not used by the app and must be
removed from the transaction model and persistence layer before the Google
sheet schema is finalized.

Required cleanup:

- Remove the fields from Dart `TransactionRecord`.
- Remove the fields from Kotlin `ExpenseTransactionEntity`.
- Remove them from repository insert/update paths.
- Remove them from recurring, push-recurring, and seed transaction creation.
- Remove them from CSV export headers and rows.
- Update tests and fixtures that currently pass or assert these fields.
- Add a Room migration from version 8 to version 9 by recreating the
  `transactions` table without those columns, copying existing data, restoring
  indexes, and preserving all transaction IDs and recurring links.

The migration must not drop user transactions.

## User Experience

The settings export panel becomes an export and sync panel with these actions:

- Save CSV to phone.
- Share CSV.
- Connect Google Sheets.
- Sync now.
- Open Google Sheet.
- Disconnect Google Sheets.

The panel shows:

- connection state,
- signed-in Google email when available,
- last successful sync time,
- current sync state,
- last error if sync failed.

No visible in-app explanation should describe implementation details. The UI
copy should stay short and operational.

## Connection Flow

When the user enables Google sync:

1. The app starts Google Sign-In using the configured web/server client ID and
   `drive.file` scope.
2. If the user grants access, the app creates a spreadsheet named
   `Exptv2 Transactions` unless an existing spreadsheet ID is already stored.
3. The app stores the signed-in account identity, spreadsheet ID, sync enabled
   flag, last sync metadata, and dirty state in local settings.
4. The app performs an initial full sync.

If sign-in is cancelled, no local data changes and sync remains disabled.

Disconnecting Google Sheets disables sync and removes local Google sync
metadata. It does not delete the spreadsheet from Drive.

## Sheet Structure

The spreadsheet has one worksheet per transaction year. Worksheet titles are
plain years such as `2024`, `2025`, and `2026`.

Each yearly sheet contains a fixed header row and all transactions for that
year. The app writes a complete replacement for each affected year during sync.

Recommended columns:

- `id`
- `date`
- `time`
- `type`
- `amount`
- `merchant`
- `userAssignedName`
- `categoryId`
- `category`
- `recurring`

The sheet schema excludes `address`, `latitude`, and `longitude`.

## Sync Model

The selected sync model is full yearly sheet rewrite.

For each sync:

1. Load local transactions and categories from the local repository.
2. Group transactions by year.
3. Create missing yearly worksheets.
4. Clear each affected yearly worksheet.
5. Write the header and all rows for that year using Sheets batch APIs.
6. Update local sync metadata after all affected years succeed.

The app remains the source of truth. Google Sheets is a mirror.

## Sync Triggers

Sync only runs from the app UI. It does not run from the foreground push
listener, background app process, Android boot handlers, or notification
capture paths.

Automatic sync starts only when all of these are true:

- the user opens the app UI,
- the security gate is passed and the app is usable,
- Google sync is enabled,
- no Google sync is already running for the current UI entry.

Manual sync is always available inside the app UI when Google sync is connected.
Manual sync performs the same full reconcile as automatic app-entry sync.

There is no automatic background retry loop.

## Offline and Error Behavior

If there is no network, Google auth fails, or a Google API request fails:

- local data remains unchanged,
- the dirty state remains,
- the UI shows a waiting or failed sync state,
- the app does not retry in the background,
- the next app-entry sync or manual sync tries again.

Partial remote writes are handled by rerunning a full yearly sync on the next
attempt. Because the local database is the source of truth, retrying a full
rewrite is safe.

## Signing Requirement

The APK used for Google Sign-In must be signed with the keystore whose SHA-1 is
registered in Google Cloud. The current GitHub Actions workflow builds a debug
APK; it must be updated to sign that APK with the stable Exptv2 keystore.

The keystore file must not be committed to the repository. Store it in GitHub
Secrets as base64 plus its passwords and alias. The workflow should decode the
keystore at build time and configure Android signing from secrets.

The locally created Exptv2 debug keystore currently has:

- alias: `exptv2debug`
- SHA-1: `22:98:12:07:52:AC:2A:01:7D:AE:4D:A0:B6:3C:FA:26:3A:FD:9C:29`

## Implementation Boundaries

Use focused units:

- transaction export row builder shared by CSV and Sheets,
- Google auth client wrapper,
- Sheets API client wrapper,
- sync repository for stored sync metadata,
- sync orchestrator for yearly reconcile,
- settings panel widget for user actions and status.

The Google Sheets integration should stay in Dart unless a native Android API is
required. File save and share can continue using the existing native bridge.

## Testing

Required tests:

- transaction row export excludes location fields,
- CSV export no longer includes clipboard-only behavior or location columns,
- Room migration preserves transaction data while removing location columns,
- sync orchestrator creates missing yearly sheets and writes rows grouped by
  year,
- manual sync invokes the same reconcile path as app-entry sync,
- app-entry sync does not run before the security gate is passed,
- offline/API errors preserve dirty state and show failure status,
- disconnect clears local sync metadata without deleting local transactions.

GitHub Actions must run analyze, Flutter tests, and the Android APK build with
the configured signing key.
