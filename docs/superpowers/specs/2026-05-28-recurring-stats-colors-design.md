# Recurring Alarm, Stats Tab, and Category Color Design

## Goal
Finish the next `exptv2` recurring/calendar/color pass: make background alarm testing observable, keep pending recurring ghosts out of past UI windows, route category colors through slot-based category data, and move the calendar menu into a full-screen Stats bottom tab.

## Current Behavior
The recurring background engine already uses Android `AlarmManager` with `setAlarmClock`/exact alarm fallbacks and a `BroadcastReceiver`. The app log entries named `resume processed` prove foreground resume processing, while background operation is proven by native debug log entries such as `receiver fired` and `receiver processed`.

The category color model is mostly slot-based in Dart through `CategoryColorManager` and `TransactionCategory.slotColor`, but recurring settings cards still render stored `RecurringTransaction.categoryColor`. Native recurring and ghost rows also store snapshot colors for notification payloads, so UI surfaces that can resolve a live category should prefer the current category row.

The calendar currently lives as a home header overlay opened by `header-calendar-button`. The second bottom nav tab is an unused Groceries placeholder.

## Design
Add a debug-only alarm test path to the existing recurring alarm channel. The Dart debug console will expose a small alarm-test button that schedules the same receiver path shortly in the future using a separate native request code. This does not replace the real next recurring alarm and does not introduce polling or a background service. The native log should show scheduling and later receiver execution after the app is backgrounded or locked.

Keep ghost processing and ghost display separate. Native processing must still activate overdue recurring ghosts when an alarm fires late. UI/projection should avoid showing active recurring ghosts for periods before the current month, so old history does not show pending future-planning rows.

Create a small category color resolver for Dart UI surfaces that have both a snapshot model and the current category list. Recurring cards, ghost boxes, notification/log-style category badges, calendar dominant category rendering, category menus, selectors, and limit bars should use `TransactionCategory.slotColor` or `CategoryColorManager` rather than ad hoc hex maps whenever category data is available.

Rename the bottom nav second tab from Groceries to Stats and render the calendar menu there as a full-screen page. The page should occupy the screen from top to the bottom nav top; it should not be a rounded home overlay. The home header calendar button and home calendar overlay state should be removed.

## Verification
Local Flutter cannot currently run in this Termux environment because the bundled Dart executable aborts with a Bionic TLS alignment error. Feasible local checks are `git diff --check`, NUL scans, and static file review. The authoritative Flutter verification is the GitHub Actions workflow, which runs `flutter analyze`, `flutter test`, and `flutter build apk --debug`.
