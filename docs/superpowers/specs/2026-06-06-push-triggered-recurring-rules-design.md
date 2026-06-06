# Push-Triggered Recurring Rules Design

Date: 2026-06-06
Project: `exptv2`

## Context

`exptv2` already has manual recurring transactions, monthly recurring ghost
cards, recurring alarm activation, FastInfo exclusions for recurring-generated
records, a notification/event capture engine, and a profile-based push parser
training UI. The current recurring model is still shaped around manual monthly
rules: a fixed day and amount activate by date.

The new feature changes the recurring concept into a broader fixed-item rule
system. Some fixed items should still activate by date. Others should appear as
monthly ghost cards but activate only when a matching bank push notification is
captured and parsed. This is needed for payments such as loans, utility bills,
or other recurring bank debits where the real amount and date can vary.

The long-term design should favor clear domain language over preserving the old
table names. The existing recurring Settings panel will be removed from Settings
and replaced by a FAB long-press recurring manager.

## Goals

1. Replace the old manual-only recurring model with a clean recurring rule and
   rule-instance model.
2. Support two activation triggers: date-triggered fixed items and
   push-triggered fixed items.
3. Keep one visible monthly ghost instance per active rule in the current or a
   future month, while hiding past pending instances.
4. Activate push-triggered ghost instances from parsed notification events.
5. Reuse the existing parser training pattern inside each push-triggered rule.
6. Move recurring management out of Settings and into a FAB long-press manager
   card.
7. Move category creation from FAB long-press to the category menu header plus
   button.
8. Preserve the existing user-controlled merchant rename/reset behavior.
9. Keep pending ghosts out of balance and transaction totals, matching current
   behavior.

## Non-Goals

- No separate recurring implementation for income and expense. Both use the
  same rule model.
- No separate table family just for push-triggered fixed items.
- No automatic learning that silently changes the user's estimated amount or
  expected day after each activation.
- No foreground polling service. Push-triggered activation happens on captured
  notification events; date-triggered activation keeps the existing alarm path.
- No visual browser/diagram companion for this design.

## Core Concepts

### Recurring Rule

A `recurring_rule` is the user-managed definition of a monthly fixed item. It is
not a transaction. It creates monthly instances.

Shared fields:

- `id`
- `triggerType`: `date` or `push`
- `transactionType`: `expense` or `income`
- `name`: user-controlled display name
- `estimatedAmount`: expected monthly amount
- `expectedDayOfMonth`: expected monthly day
- `categoryId`
- `isActive`
- `createdAt`
- `updatedAt`

Push-trigger fields:

- `appFilterText`
- `packageName`
- `appLabel`
- `sampleText`
- `includeKeyword`
- `amountPattern`
- `amountSelection`
- `merchantPattern`
- `merchantSelection`
- `dateToleranceDays`
- `amountTolerancePercent`
- `amountToleranceMin`

For date-triggered rules, push-trigger fields remain empty/defaulted.

### Recurring Rule Instance

A `recurring_rule_instance` is the monthly ghost/activation record for one rule
and one period.

Fields:

- `id`
- `ruleId`
- `periodKey`, for example `2026-06`
- `status`: `pending`, `activated`, or `expired`
- `estimatedDate`
- `estimatedAmount`
- `triggerTypeSnapshot`
- `transactionTypeSnapshot`
- `nameSnapshot`
- `categoryIdSnapshot`
- `categoryNameSnapshot`
- `categoryColorSnapshot`
- `categoryIconSlotSnapshot`
- `activatedTransactionId`
- `activatedAt`
- `matchedNotificationEventId`
- `matchConfidence`
- `createdAt`
- `updatedAt`

Instances carry snapshots so historical UI and notification cards remain stable
even if the rule or category is edited later.

### Transaction Link

Transactions created from recurring instances should remain connected to the
source recurring data.

The target model should support:

- `recurringRuleId`
- `recurringInstanceId`

The old `recurringTransactionId` field can be migrated or superseded. Dart
models should expose an `isRecurringGenerated` concept independent of the old
field name.

## Monthly Instance Rules

Every active rule creates at most one instance per month.

Date generation:

- `estimatedDate` uses `expectedDayOfMonth`.
- If the month is shorter, the day clamps to the last day of the month.
- `estimatedAmount` uses the rule's user-entered `estimatedAmount`.

Visibility:

- Pending instances are visible only for current and future periods.
- Pending instances from earlier months are expired/hidden after month change.
- Past pending ghosts must not remain visible for either date-triggered or
  push-triggered rules.

Totals:

- Pending instances do not affect balance.
- Pending instances do not affect income or expense totals.
- Pending instances appear as ghost cards only.
- Activated real transactions affect balance and totals.

FastInfo and charts:

- Pending instances may feed only cards that explicitly describe expected or
  upcoming fixed items.
- Activated recurring-generated transactions are excluded from trend/average
  FastInfo cards and chart calculations that intentionally ignore fixed items.
- Balance and ordinary income/expense totals include only real activated
  transactions.

## Activation Semantics

### Date Trigger

A date-triggered rule follows the existing manual recurring behavior:

1. A monthly pending instance is generated.
2. The alarm/resume processing path activates due instances.
3. Activation inserts a normal transaction.
4. The instance is marked `activated`.
5. Notification cards and limit checks run through the existing native expense
   pipeline.

### Push Trigger

A push-triggered rule creates the same monthly pending instance, but activation
comes from a captured push event.

Flow:

1. Notification listener/accessibility capture saves a `notification_event`.
2. The parser reads active parser/rule data.
3. A parsed candidate transaction is produced from amount, merchant, type, and
   event timestamp.
4. The push recurring matcher checks current-month pending push instances.
5. If one strong match is found, the instance activates.
6. Activation inserts a normal transaction using the real push data.
7. The instance stores `matchedNotificationEventId` and `matchConfidence`.
8. Notifications and downstream store refreshes run as usual.

Activation transaction values:

- amount: exact parsed push amount
- date/time: notification timestamp or parsed event time if later supported
- merchant: raw parsed push merchant
- userAssignedName: recurring rule name or existing rename-derived user name
- category: recurring rule category
- transaction type: recurring rule transaction type

The raw merchant must be preserved so the existing merchant rename/reset model
continues to work. The user-controlled name may be shown through
`userAssignedName`, and the existing reset button can return the affected
merchant group to the raw parsed merchant.

## Push Matching

Push matching should be deterministic and explainable. It should not rely on an
opaque ML model.

Candidate score inputs:

- app/package/app label match
- include keyword match
- merchant regex extraction and optional merchant selection match
- parsed amount present
- amount within tolerance
- event date within `estimatedDate +/- dateToleranceDays`
- transaction type match
- current period pending instance exists

Default tolerances:

- `dateToleranceDays`: 5
- `amountTolerancePercent`: 20
- `amountToleranceMin`: 5000 HUF

The matcher should compare only pending push-triggered instances for the current
period. It should not activate future-month instances and should not revive
past pending instances.

If `merchantSelection` was learned from the sample push, it is a disambiguation
constraint. This prevents two similar fixed items from the same bank app from
matching only on app, date, and approximate amount.

Conflict handling is global Settings state, not per-rule state:

- `automaticBestMatch`: activate the best score; mark low-margin matches with
  match confidence/uncertain metadata.
- `askOnMultipleMatches`: if multiple plausible instances match, create a
  confirmation prompt/card instead of activating automatically.

Recommended default: `automaticBestMatch`.

## Parser Training In Push Rules

Each push-triggered rule gets a parser training component based on the existing
notification parser profile UI.

The component includes:

- app picker/filter
- sample notification text
- transaction type inherited from the active main income/expense pill, with no
  separate income/expense selector inside the recurring manager
- amount token selection
- merchant token selection
- advanced regex fields
- parser preview
- tolerance controls

This component is scoped to one recurring rule. Global parser profiles can still
exist for general notification parsing, but push-triggered fixed items need
their own trigger profile to distinguish cases such as multiple loans from the
same bank app.

## UI Design

### FAB Behavior

- FAB tap: open the existing add transaction sheet.
- FAB long press: open the recurring manager card.
- The recurring manager inherits the same transaction type context as FAB tap:
  the active main transaction pill determines whether a newly saved recurring
  rule is `income` or `expense`.
- FAB long press no longer opens category creation.

### Recurring Manager Card

The recurring manager is a combined slide-up card, using the same interaction
family as the add transaction sheet and FastInfo helper sheets.

Height and gestures:

- the long-press recurring card can contain more content than the old category
  card, but its maximum expanded height must stop at the top of the summary pill
  area, matching the old add-category card height ceiling
- the card content is scrollable
- the card is manually draggable up/down and swipe-dismissible
- a downward swipe inside the body becomes manual card drag only when the inner
  scroll view is already at the top; otherwise it scrolls content normally
- the handle area always supports free manual drag

Top controls:

- trigger mode: `Idő` / `Push`
- no separate `Kiadás` / `Bevétel` selector; the active main pill is the source
  of truth for a new rule's type

Middle editor:

- shared fields:
  - name
  - estimated amount
  - expected day of month
  - category
  - active state
- date trigger:
  - no parser section
- push trigger:
  - parser training section
  - app/sample/amount/merchant fields
  - tolerance controls

Bottom manager list:

- one shared manager list, not a separate sheet
- grouped/tagged by trigger and transaction type
- items show badges:
  - `Időzített fix`
  - `Push fix`
  - `Kiadás`
  - `Bevétel`
- each item supports:
  - tap to load into the upper editor
  - active/inactive toggle
  - delete

Saving:

- New rules use the currently active main transaction pill type when saved.
- If no item is selected, save creates a new rule.
- If an item is selected, save updates that rule.
- After save, the bottom list refreshes and the manager stays open.

### Settings Changes

Remove the current recurring transaction Settings panel.

Settings should not expose recurring transaction CRUD anymore. Global automation
settings can remain in the native settings payload without a recurring submenu:

- push fixed-item match handling: automatic best match / ask on multiple matches

### Category Creation

Category creation moves into the category menu header:

- Add a plus button in the category menu header.
- The plus button opens the existing category editor/create flow.
- FAB long press is reserved for recurring manager.

## Native/Data Migration

The current Room tables should be replaced/migrated conceptually:

- old `recurring_transactions` -> new `recurring_rules`
- old `recurring_ghost_transactions` -> new `recurring_rule_instances`

Migration behavior:

1. Create new tables.
2. Copy existing recurring transactions as `triggerType = date` rules.
3. Copy existing pending/activated ghosts as rule instances.
4. Preserve category snapshots.
5. Preserve activated transaction links where available.
6. Migrate transaction recurring references into the new recurring link fields.
7. Keep compatibility parsing in Dart/native models only as long as needed for a
   single migration window.

The implementation can either drop old tables after migration or keep them
unused. The target domain code should use the new names only.

## Data Boundaries

Native Kotlin/Room owns:

- durable recurring rules
- monthly instance generation
- date-trigger activation
- push-trigger matching and activation
- transaction creation from recurring activation
- notification-card creation for activation/conflicts

Flutter/Dart owns:

- recurring manager UI
- parser training UX
- Settings option for conflict handling
- store refreshes and rendering
- ghost cards and list interactions

The parser matching should be native-side so push-trigger activation can work
when Flutter UI is not active.

## Error Handling

Invalid rule:

- Missing name, category, amount, or expected day blocks save.
- Push trigger also requires a valid app/sample parser preview before save.

Invalid regex:

- The editor shows preview errors and disables save.

Push parse failure:

- Store notification event only.
- Do not create transaction.
- Do not activate an instance.

Ambiguous match:

- Follow global Settings.
- If asking is enabled, create a notification card or pending approval entry.
- Do not activate more than one instance from one push event.

Duplicate event:

- Existing notification event hashing remains the first defense.
- Push activation should also check that `matchedNotificationEventId` was not
  already used by another recurring instance.

Deleted/inactive rule:

- Inactive rules do not generate future pending instances.
- Disabling a rule hides/deletes future pending instances.
- Already activated transactions remain untouched.

## Testing Strategy

Native unit tests:

- recurring rule generation creates one instance per active rule and period
- old recurring rows migrate to date-triggered rules
- pending past instances expire/hide after month change
- date-triggered rules activate by due date
- push-triggered rules do not activate by date
- push matching succeeds for app/merchant/amount/date tolerance
- push matching rejects out-of-window and out-of-tolerance events
- ambiguous matches follow global Settings behavior
- one notification event cannot activate multiple instances

Dart model/store tests:

- recurring rule and instance models parse native maps
- TransactionStore exposes pending instances as ghost cards
