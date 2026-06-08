# Main Notification Listener Parser Design

Date: 2026-06-08
Project: `exptv2`

## Context

`exptv2` already has a notification capture path, parser profile training, captured
push message storage, transaction insertion from parsed push text, and
merchant-based category inheritance on a feature branch. The user wants that
parser work merged into `main`, then extended so Android push notifications are
handled by `NotificationListenerService` without a continuously running parser
service.

The desired runtime model is event-driven:

1. Android invokes the listener when a notification arrives.
2. The listener quickly decides whether this app/profile is enabled.
3. Eligible notifications are stored as captured push messages.
4. The parser tries to extract transaction data.
5. Parsed transactions are inserted into the database.
6. The listener finishes the work and waits for the next Android event.

There is no visual companion for this design.

## Goals

1. Merge the previously implemented parser, push-log, training, and merchant
   category propagation work into `main`.
2. Use `NotificationListenerService` as the event-driven notification entry
   point.
3. Add a Settings option that globally enables or disables automatic push
   parser work.
4. Keep app/profile enablement independent: disabling one app profile must not
   disable other enabled profiles.
5. If an app profile is disabled, notifications for that app do no work: no
   message insert, no parse, and no transaction insert.
6. Preserve captured message storage for enabled profiles, including active
   profile messages that fail parsing so they can be reviewed and trained later.
7. Preserve existing working parsing behavior for configured apps.
8. Add detailed debug logs visible in the on-screen debug console.
9. Keep the implementation battery-friendly: no polling and no foreground
   parser service.

## Non-Goals

- No foreground service for the parser.
- No polling loop.
- No parser category assignment UI. Categories remain a transaction-level user
  decision, then later inherit by merchant.
- No capture of disabled-profile notifications for audit/training.
- No broad UI redesign beyond the global Settings toggle needed for this
  feature.
- No Android APK build on the phone. APK builds remain GitHub Actions work.

## Enablement Model

There are two independent enablement levels.

### Global Push Parser Toggle

The Settings toggle controls automatic push parser work globally.

If this toggle is off:

- `NotificationListenerService` returns immediately.
- No captured push message row is inserted.
- No parser profile is evaluated.
- No transaction row is inserted.
- A debug log records the skip reason as `global_disabled`.

This toggle does not revoke Android notification listener permission. It only
controls the app's own processing.

### Profile Toggle

Each parser profile keeps its own enabled state.

If the Erste profile is disabled and the Revolut profile is enabled:

- Erste notifications are skipped completely.
- Revolut notifications still use the normal enabled-profile flow.

If one notification matches multiple profiles, disabled profiles are ignored. If
at least one enabled matching profile exists, processing may continue with the
enabled profile. Disabled matches never block enabled matches.

If a notification matches only disabled profiles:

- no captured push message row is inserted
- no parse is attempted
- no transaction row is inserted
- a debug log records `profile_disabled`

If a notification matches no configured enabled profile and no configured
disabled profile:

- the listener returns without storing the message
- a debug log records `no_enabled_profile_match`

## Listener Flow

`NotificationListenerService.onNotificationPosted(...)` should remain small and
fast. It extracts only the notification metadata needed for filtering:

- package name
- app label if available
- title
- text/body
- post timestamp

The service then runs this decision order:

1. Check the global push parser toggle. If off, return.
2. Load parser profiles.
3. Evaluate enabled profiles against package name and app label.
4. If no enabled profile matches, check whether a disabled profile matched so
   the debug reason can distinguish `profile_disabled` from
   `no_enabled_profile_match`.
5. For an enabled match, insert the captured push message.
6. Run the parser using enabled matching parser profiles.
7. If parsing succeeds, insert the transaction and link it to the captured
   message.
8. If parsing fails, keep the captured message with no linked transaction so the
   user can train it later.

The listener should perform database and parser work off the Android main
thread, using the existing coroutine/repository pattern. It must not keep a
long-lived worker alive after the notification event is handled.

## Parser and Transaction Semantics

The parser uses only enabled profiles. Disabled profiles are excluded from both
capture eligibility and parse attempts.

For an enabled profile that matches the notification source:

- the notification text is stored before parsing
- valid parsed amount and merchant create an expense transaction
- duplicate protection from the existing parser work is preserved
- the notification event is linked to the created transaction
- merchant category inheritance is applied before insert
- new merchant transactions without inherited category remain uncategorized

Merchant category behavior remains:

- a user's category choice for one merchant applies to all transactions with the
  same original merchant
- future parsed transactions for that merchant inherit the category
- user-controlled merchant renaming continues to use the original merchant as
  the grouping key

## Captured Message Semantics

Only notifications from enabled matching profiles are saved.

Saved captured messages can have either state:

- linked transaction exists
- no linked transaction exists

No linked transaction can mean parse failure, non-transaction content from an
enabled app, or a message that still needs manual training. The UI should not
need to distinguish deleted logs from other no-link reasons for this feature.

Notifications skipped because of global off, disabled profile, or no matching
enabled profile are intentionally not saved.

## Settings UI

Add one global option in Settings for automatic push parser processing.

The control should follow the existing Settings style and should be clear that
it controls background notification parsing, not Android permission itself. The
exact label can be finalized during implementation, but the meaning is:

- on: enabled profiles are processed by the notification listener
- off: the listener ignores all notifications

Profile-level switches continue to control individual app/parser profiles.

## Debug Logging

Add detailed logs to the on-screen debug console path with stable reason names.

Required logs:

- listener event received with package/app label and timestamp
- `global_disabled`
- `profile_disabled`
- `no_enabled_profile_match`
- enabled profile match with profile id/name/package
- captured message inserted with event id
- parse started with profile id/name
- parse failed with reason
- parse succeeded with amount and merchant
- duplicate skipped
- transaction inserted with transaction id
- notification event linked to transaction id
- elapsed timing for listener work

Logs should avoid dumping excessive full message text by default. Short previews
are acceptable when already used by the existing debug console style.

## Error Handling

Malformed or incomplete profiles should not crash listener processing.

Expected handling:

- invalid regex logs `parse_failed` with the profile id/name
- missing notification text logs `parse_failed` or `empty_text`
- database insert failure logs the exception and leaves no partial transaction
  link
- a failed profile does not prevent another enabled matching profile from being
  tried if the existing parser model supports multiple candidates

## Performance and Battery

The feature must remain event-driven.

The listener should:

- do only profile/toggle checks before any message insert
- avoid processing notifications from disabled or unrelated apps
- avoid polling installed apps or notifications
- reuse cached/profile store data where the existing code supports it
- finish each event after parse and database work

This is intentionally better for battery than a continuously running parser
service.

## Testing

Add red tests before implementation for these cases:

1. Global toggle off skips capture, parse, and transaction insert.
2. Disabled matching profile skips capture, parse, and transaction insert.
3. Disabled Erste profile does not block enabled Revolut profile.
4. Enabled matching profile stores the captured message.
5. Enabled matching profile with valid text inserts and links a transaction.
6. Enabled matching profile with unparsable text stores the message with no
   linked transaction.
7. Parser uses only enabled profiles.
8. Merchant category inheritance still applies to push-created transactions.
9. Settings/native bridge can read and write the global push parser toggle.

Existing parser, push-log, and transaction tests must remain green.

## Main Integration

Implementation happens on `main`.

The prior parser branch should be merged carefully into `main`, resolving
conflicts without dropping current main changes. After the merge, the
NotificationListenerService feature should be implemented on top of the merged
parser code.

The completed work should be committed and pushed so GitHub Actions can build
the APK.

## Acceptance Criteria

- With the global toggle off, no notification creates captured messages or
  transactions.
- With the global toggle on and a profile disabled, that app's notifications do
