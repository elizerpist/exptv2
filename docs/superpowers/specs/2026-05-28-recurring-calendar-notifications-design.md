# Recurring Alarm, Calendar, Notification, and UI Corrections Design

Date: 2026-05-28
Project: `exptv2`

## Context

This design covers the next implementation batch for `exptv2`. The app is a Flutter UI backed by Kotlin/Room for expense data. The important constraint for recurring transaction activation is battery use: it must follow the Maethclock/Maethalarm exact-alarm method, not a foreground monitor and not continuous polling.

The Maethclock artifact available locally is `/data/data/com.termux/files/home/maethclock-artifact-check/app-release.apk`. Its strings show the relevant pattern:

- Flutter package component: `package:maethclock/services/alarm_scheduler_service.dart`
- Method channel: `maethclock/alarm`
- Method names: `syncAlarms`, `setupAlarm`, `dismissAlarm`, `snoozeAlarm`
- Native scheduling APIs: `AlarmManager`, `setExact`, `setExactAndAllowWhileIdle`, `setAlarmClock`
- Exact alarm permission flow: `canScheduleExactAlarms`, `requestExactAlarmsPermission`
- Receivers: scheduled notification receiver and boot receiver through the local-notifications alarm scheduling stack

The current `exptv2` implementation already has Room entities for transactions, categories, limits, recurring transactions, recurring ghosts, and notification cards. It also has a WorkManager based recurring worker, but the next design replaces the runtime behavior with a Maethclock-style exact alarm scheduler.

## Goals

1. Activate recurring ghost transactions at `00:01` using the Maethclock-style background exact alarm method.
2. Avoid foreground services and continuous background polling.
3. Keep ghost rows visible only in non-sum views until activation; activated ghosts disappear and become real transactions.
4. Add a persistent on-screen debug date override for testing recurring activation.
5. Implement original-style notification card triggers for recurring activation and budget/limit alerts.
6. Move the calendar out of the header into a dedicated bottom navigation tab replacing Groceries.
7. Apply the requested UI corrections for magnet strip, category menu, header behavior, summary pill, and logbox swipe behavior.

## Non-Goals

This batch will not connect push-parser notification scraping to automatic transaction creation. It will only keep the existing push-parser base intact while improving the expense tracker, recurring transaction, notification card, and UI systems.

## Architecture

### Maethclock-Style Recurring Alarm Scheduler

Add a small Flutter service wrapper modeled after Maethclock's `AlarmSchedulerService`:

- `lib/features/transactions/services/recurring_alarm_scheduler_service.dart`
- Method channel name: `exptv2/recurring_alarm`
- Public methods:
  - `syncRecurringAlarms()`
  - `processRecurringNow({DateTime? targetDate})`
  - `setDebugDateOverride(DateTime date)`
  - `clearDebugDateOverride()`
  - `loadRecurringAlarmDebugState()`

Add native Kotlin components:

- `RecurringAlarmMethodChannel`
- `RecurringAlarmScheduler`
- `RecurringAlarmReceiver`
- `RecurringBootReceiver`
- `RecurringDebugClockStore`
- `RecurringAlarmDebugLogger`

The scheduler will use `AlarmManager` and choose the strongest available exact scheduling mode:

1. `setAlarmClock` when exact alarm clock behavior is available and appropriate.
2. `setExactAndAllowWhileIdle` when exact alarm permission is granted.
3. `setExact` as a lower-tier exact fallback where supported.
4. App-open/resume processing as the final safety net if the OS delays or blocks background exact alarms.

`WorkManager` remains only as a compatibility fallback if needed, not as the primary trigger path.

### Trigger Semantics

Recurring transactions are monthly. For a recurring item with day `D`, the planner creates a pending ghost for the current period using effective day `min(D, lastDayOfMonth)`.

Activation moment:

- `triggerMillis` is the effective due date at `00:01`, local timezone.
- Before `00:01`, the ghost is pending.
- At or after `00:01`, the receiver or app-open sync activates it.

Activation behavior:

- Insert a normal `ExpenseTransactionEntity`.
- Mark the ghost row activated.
- Update `RecurringTransactionEntity.lastProcessedPeriodKey`.
- Insert a notification card.
- Reschedule the next exact alarm.
- Emit debug logs.

Display behavior:

- Sum view: ghost transactions are hidden and do not count in summary/balance.
- Monthly/yearly views: pending ghost rows are shown in the relevant month/year log list.
- Activated month: pending ghost disappears and the real transaction appears.
- Summary pill and balance use only real transactions.

### App Lifecycle

On app startup:

1. Load debug date override.
2. Run due recurring processing using app-clock date.
3. Ensure pending ghosts for the active period.
4. Load Room data.
5. Sync the next exact alarm.

On app resume:

1. Run due recurring processing.
2. Reload transactions/ghosts/notifications.
3. Sync the next exact alarm.

On scheduled receiver fire:

1. Load debug clock state, but default to real device time for real background alarms.
2. Process due recurring transactions.
3. Save triggered recurring IDs/count for later Flutter consumption.
4. Sync next exact alarm.

### Debug Date Override

The debug date override is persistent until reset.

UI:

- A floating debug date button is visible above the app like the existing debug log button.
- It opens a compact date controller with:
  - current effective app date
  - previous day
  - next day
  - date picker/input
  - reset to real date
  - run recurring processing now

Behavior:

- Changing the debug date immediately calls the same native processing path as the scheduled receiver.
- Debug date is used by Flutter UI period references and by explicit debug processing calls.
- Debug logs must show whether the app used real time or debug override.

Required debug log examples:

- `[RecurringAlarm] sync start active=3`
- `[RecurringAlarm] exact permission=true`
- `[RecurringAlarm] scheduled next=2026-05-29 00:01 mode=setAlarmClock`
- `[RecurringAlarm] receiver fired now=2026-05-29 00:01`
- `[RecurringAlarm] debug override set=2026-06-01`
- `[RecurringAlarm] processing target=2026-06-01 00:01 dueGhosts=2`
- `[RecurringAlarm] activated recurringId=9 ghostId=31 transactionId=20260601001`
- `[RecurringAlarm] notification card inserted type=recurring_transaction_alert`
- `[RecurringAlarm] rescheduled next=2026-06-02 00:01`

## Notification Cards

The notification card system should match the original `expt0926` behavior and naming where practical.

Native card types:

- `recurring_transaction_alert`
- `budget_alert`
- `spending_limit`
- `monthly_budget_alert`
- `system`

Recurring activation card:

- Created when a ghost activates.
- Uses type `recurring_transaction_alert`.
- Includes recurring ID, transaction ID, amount, category ID/name/color/icon slot, trigger date, next due date, timestamp, unread state.

Budget/limit cards:

- Created when a category or overview budget crosses an active alert threshold.
- Reuses current `CategoryLimit` and `LimitManager` data.
- Avoid duplicate active cards for the same target/window/period unless the threshold state clears and crosses again.
- If spending drops below the clear threshold after edits/deletes, the active alert state can clear.

Flutter notification page:

- Keep the current Notification tab.
- Keep month grouping and month swipe.
- Logbox design stays close to original: 140 minimum height, rounded 25, category/notification avatar, two-line title block, details area.
- Right swipe deletes with confirmation.
- Left swipe marks read or performs the budget-limit action when implemented.

## Calendar Navigation

Remove the calendar button from `TransactionHeaderCard`.

Replace `AppTab.groceries` with a calendar tab:

- Label: `Naptar`
- Icon: calendar outline
- The old blank Groceries page is removed from the shell stack.

Calendar tab layout:

- Top starts at the screen top.
- Bottom ends at the top of the bottom nav.
- It is not an overlay from the header.
- It keeps the original modes:
  - normal threshold view
  - summary view
  - heatmap view
  - dominant category view

Year view:

- Shows 12 month cards on one canvas/painter path for performance.
- Left/right swipe changes year.
- Month cards use stable dimensions across all modes.
- Pie/donut statistics remain available in category mode.

Month detail view:

- Tapping a month card animates into a single-month detail screen inside the calendar tab.
- The selected month card expands/zooms into place.
- A back arrow returns to annual view.
- Left/right swipe changes adjacent month.
- Below the enlarged month canvas, show detailed stats:
  - income
  - expense
  - balance
  - transaction count
  - top categories
  - daily high/low markers

## Category Menu

The category picker remains opened by the header category button, but becomes an inline modal:

- Not a slide-up card.
- Not draggable by swipe.
- Top remains the current menu top.
- Bottom ends at the top of bottom nav.
- It does not cover the bottom nav.
- It filters categories by the active transaction type:
  - income pill active: income categories
  - expense pill active: expense categories

Add/edit category sheets remain slide-up cards like Add New Transaction unless later changed separately.

## Header Card

Magnet strip:

- Increase strip height by 50% from current 70 to 105.
- The strip reaches the screen edges.
- Ends are not pill-shaped at the screen edge.
- Internal mode-specific shapes still follow theme settings, but the full-width base strip uses square screen-edge contact.

Calendar:

- Remove header calendar icon and callback.

Shadow:

- Header card bottom shadow remains visible during downward swipe/fastinfo reveal.
- FastInfo and header remain visually one unit; the header should not cast an internal seam shadow onto FastInfo.

Spring:

- Downward pull snap-back uses the original `expt0926` spring feel:
  - tension around 150
  - friction around 10
  - short rest thresholds
- Flutter equivalent should use a spring simulation/controller rather than only `AnimatedSlide` with ease-out cubic for drag snap-back.

Backheader:

- The expand button remains at the bottom of the backheader area while the card slides.
- The button should not become difficult to trigger after swiping.

## Summary Pill

- Horizontal swipe still cycles sum/monthly/yearly.
- Vertical swipe changes month in monthly mode and year in yearly mode.
- Content changes immediately with no fade-out/fade-in animation.
- Drag movement can still animate, but text/number replacement is instant.
- The title must always state what is being summarized:
  - `Sum`
  - `2026`
  - `Marcius 2026`
  - plus active filter labels when merchant/category filters are applied.
- Summary value is computed from the currently visible real transaction logs after filters, not from hidden or unfiltered database totals.

## Transaction Logbox Swipe

Right swipe delete:

- Border height exactly matches the log card height.
- When delete threshold is crossed, the card stays pinned at the right endpoint while the confirmation dialog is open.
- If user taps `Megse`, the card slides back.
- If user confirms delete, the row is removed after deletion.

Left swipe/fast filter:

- Existing fast-filter behavior remains.
- Border height matches log card.

Avatar tap filter:

- Category avatar tap filters by category.
- Search pill can show two filter capsules simultaneously:
  - merchant/fast-filter capsule
  - category/avatar capsule
- Capsule colors match their source colors.
- The text input area must not cover the capsules.

Name edit:

- Existing transaction rename/reset behavior remains.
- Original merchant name is preserved.
- Custom user name is visually darker; original/default name is gray.

## Search Pill

- Focus highlight matches Add New Transaction text input: blue outer outline.
- Remove the unwanted inner text-wrapper outline.
- Two capsules must fit without being hidden by the text input region.

## Magnet Strip Theme Settings

Theme settings must control the actual strip rendering:

- `fade`
- `nofade`
- `budget`
- `magnetcard`
- `adaptive`

The strip should not collapse to a plain line for magnetcard mode. It should render the selected magnetic-strip shape and colors as configured by the user.

## Data Flow

Recurring activation data flow:

1. User creates or edits a recurring transaction in settings.
2. Kotlin stores `RecurringTransactionEntity`.
3. Flutter calls `syncRecurringAlarms`.
4. Kotlin computes the next `00:01` due ghost trigger.
5. Kotlin schedules exact alarm using Maethclock-style method.
6. Alarm receiver fires.
7. Repository activates due ghosts.
8. Repository inserts real transaction and notification card.
9. Scheduler computes the next trigger.
10. Flutter reloads on next app open/resume or immediate debug call.

Debug date data flow:

1. User changes floating debug date.
2. Flutter writes override through MethodChannel.
3. Kotlin stores override.
4. Kotlin processes due ghosts for that effective date.
5. Flutter reloads store data and debug log.

Calendar data flow:

1. Calendar tab reads transactions and categories from `TransactionStore`.
2. Render builder produces yearly canvas data.
3. Canvas painter draws month cards consistently across all modes.
4. Month tap changes internal calendar state to month detail view.

## Error Handling

Exact alarm permission:

- If exact alarms are not permitted, log the state and expose it in debug.
- Use app-open/resume processing as safety net.
- Do not silently fall back to continuous foreground monitoring.

Receiver failures:

- Catch exceptions in receiver processing.
- Write debug log into persistent native debug store.
- Reschedule the next attempt when possible.

Notification card duplicates:

- Recurring activation cards are deduplicated by activated ghost/transaction.
- Budget alerts are deduplicated by target/window/period/type while active.

## Testing

Native/Kotlin tests:

- `RecurringGhostPlanner` uses `00:01` trigger.
- End-of-month effective day works.
- Already processed period does not activate twice.
- Scheduler computes next trigger correctly.
- Receiver calls repository and reschedules.
- Boot receiver reschedules.
- Notification card factory uses `recurring_transaction_alert`.

Flutter tests:

- Debug date controller persists override and triggers processing.
- Calendar tab replaces Groceries.
- Header calendar button is gone.
- Calendar month tap enters detail view; back returns to annual view.
- Year/month swipe works in calendar views.
- Summary pill content switches instantly.
- Category menu is inline and not draggable.
- Logbox delete stays pinned while dialog is visible and slides back only on cancel.
- Search pill renders two capsules without overlap.
- Magnet strip height and edge behavior match requirements.

Integration/manual verification:

- Create recurring transaction due today.
- Set debug date to due date at/after `00:01`.
- Verify ghost disappears and real transaction appears.
- Verify notification card appears.
- Verify summary excludes pending ghosts and includes activated real transaction.
- Build on GitHub Actions after implementation and inspect APK artifact.

## Implementation Boundaries

Keep files focused. Do not put large UI, scheduler, or debug logic into a single file.

Expected file groups:

- `lib/features/transactions/services/`
- `lib/features/transactions/widgets/debug_date/`
- `lib/features/calendar/`
- `android/app/src/main/kotlin/com/exptv2/app/expense/recurring/` or equivalent package split
- existing notification/card widgets updated in place where small

No unrelated visual redesign should be mixed into this batch.
