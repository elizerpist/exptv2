# exptv2 Flutter Rebuild Guide

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development or superpowers:executing-plans when implementing this guide task-by-task. This file is the product and architecture guide for rebuilding the old React Native `expt2` app from scratch in Flutter/Dart.

**Goal:** Rebuild the previous React Native expense tracker as a clean Flutter app named `exptv2`.

**Source App:** `/storage/emulated/0/androidapps/expt0926`

**Target Project Folder:** `/data/data/com.termux/files/usr/var/lib/proot-distro/installed-rootfs/ubuntu/home/flutteruser/flutterapps/exptv2`

**Architecture:** Build a feature-first Flutter app with local-first persistence, typed domain models, repositories, Riverpod state, and modular UI widgets. Do not port the React Native monolith line-by-line; preserve the product behavior and rebuild it with Flutter-native structure.

**Tech Stack:** Flutter, Dart, Riverpod, GoRouter, Drift/SQLite, `intl`, `fl_chart`, Flutter haptics, local JSON import/export, widget/unit/integration tests.

---

## 1. Product Summary

`expt2` is a personal finance tracker focused on fast manual transaction entry, category-based expense organization, budget limits, monthly navigation, live summaries, notifications, and lightweight analytics.

The original app was an Expo React Native app with a local Express backend and JSON files. The Flutter rebuild should keep the product model but remove the need for a Node backend in the MVP. The app should be offline-first and store data locally on-device.

Core user value:

- Record income and expense transactions quickly.
- Organize transactions by custom categories.
- Filter by transaction type, category, merchant, month, and text search.
- See monthly, yearly, and all-time financial summaries.
- Set monthly/category budget limits and receive local in-app alerts.
- Review transactions through compact swipeable cards.
- Customize category colors/icons through a slot-based system.
- View statistics and spending distribution.

---

## 2. Original App Findings

The original app contains these important files:

- `App.js`: main state, routing, screen composition, filters, summaries, menu visibility, backend loading.
- `simple-backend.js`: Express backend with CRUD endpoints and JSON file persistence.
- `newApiService.js`: frontend API facade for categories, transactions, notifications, budgets, theme settings.
- `transactionmanager.js`: monthly transaction list, swipe month navigation, filtering, deletion callbacks.
- `transactionlogbox.js`: individual transaction card, merchant edit, amount edit, swipe delete/filter.
- `categorymenu.js`, `categorycard.js`: category grid, selection, edit, delete protection.
- `addnewtransactionmenucontent.js`: transaction form.
- `addnewcategorymenu.js`, `modifycategorymenu.js`, `IconPickerMenu.js`, `SlotManager.js`: category customization.
- `backheader-stage0.js`, `backheader-stage1.js`, `backheader-stage2.js`: staged header, balance, budget bars, analytics panel.
- `summarypill.js`, `searchpill.js`, `transactionpills.js`: core filter/summary controls.
- `budgetpicker.js`: budget limit editor with alert toggle and progress.
- `notificationmanager.js`, `notificationlogbox.js`: notification list and detail cards.
- `repeatableoptions.js`, `repeatativeexpenses.js`: recurring expense UI and backend router.
- `statistics.js`, `bubbleview.js`, `cardview.js`, `chartboxcategory.js`, `kordiagram.js`, `oszlopdiagram.js`, `wafflechart.js`, `calendarmenu.js`, `monthcard.js`: statistics/calendar visualization.

Original active data files:

- `data/transaction-logs.json`
- `data/transaction-categories.json`
- `data/budgets.json`
- `data/push-notifications.json`
- `data/budget-limit-notifications.json`
- `data/recurring-transaction-notifications.json`
- `data/search-history.json`
- `data/user-preferences.json`
- `data/fastinfo.json`
- `slot-mappings.json`

The source app also contains many backups and disabled files. Treat those as history, not implementation source.

---

## 3. Flutter Rebuild Principles

1. Rebuild, do not transliterate.
   The React Native project grew into a large single-app composition. Flutter should split features into small files with clear ownership.

2. Local-first.
   The MVP should not require `node simple-backend.js`. Use SQLite via Drift for structured app data.

3. Signed amount rule.
   Expenses are stored as negative values. Income is stored as positive values. UI formatting may show `-12 500 Ft` or `+280 000 Ft`.

4. Preserve collective vs individual edits.
   Merchant rename and category change affect all transactions with the same display merchant. Amount edit affects only the selected transaction.

5. Preserve fast interaction style.
   Transaction cards, summary pills, category customization, and month navigation rely heavily on swipe gestures and haptic feedback.

6. Build stable data first.
   The app has many UI features; they should sit on a tested domain/data layer before recreating complex animation polish.

7. Use Flutter-native presentation.
   Pixel values from React Native are references only. Preserve hierarchy and behavior, but use Flutter layouts, gestures, theming, and animation primitives.

---

## 4. Recommended Folder Structure

Create the app with:

```bash
proot-distro login ubuntu --user flutteruser
cd ~/flutterapps/exptv2
flutter create --project-name exptv2 .
```

Recommended structure after scaffold:

```text
lib/
  main.dart
  app/
    expt_app.dart
    router.dart
    app_shell.dart
    theme/
      app_theme.dart
      app_colors.dart
      app_spacing.dart
  core/
    database/
      app_database.dart
      tables.dart
      migrations.dart
    formatters/
      currency_formatter.dart
      date_formatter.dart
    haptics/
      haptic_service.dart
    ids/
      transaction_id_generator.dart
    result/
      app_failure.dart
    widgets/
      app_bottom_nav.dart
      app_fab.dart
      confirm_dialog.dart
  features/
    dashboard/
      domain/dashboard_summary.dart
      presentation/dashboard_screen.dart
      presentation/widgets/stage_header.dart
      presentation/widgets/summary_pill.dart
      presentation/widgets/transaction_type_pills.dart
      presentation/widgets/search_pill.dart
    transactions/
      domain/transaction_log.dart
      data/transaction_repository.dart
      application/transaction_controller.dart
      presentation/widgets/transaction_list.dart
      presentation/widgets/transaction_log_card.dart
      presentation/widgets/add_transaction_sheet.dart
    categories/
      domain/category.dart
      domain/category_type.dart
      data/category_repository.dart
      application/category_controller.dart
      presentation/category_picker_sheet.dart
      presentation/category_editor_sheet.dart
      presentation/widgets/category_card.dart
    slots/
      domain/icon_slot.dart
      domain/slot_mapping.dart
      data/slot_repository.dart
      application/slot_controller.dart
      presentation/icon_picker_sheet.dart
      presentation/widgets/slot_icon.dart
    budgets/
      domain/budget_limit.dart
      data/budget_repository.dart
      application/budget_controller.dart
      presentation/budget_picker_sheet.dart
      presentation/widgets/budget_bar.dart
    notifications/
      domain/app_notification.dart
      data/notification_repository.dart
      application/notification_controller.dart
      presentation/notification_screen.dart
      presentation/widgets/notification_card.dart
    recurring/
      domain/recurring_transaction.dart
      data/recurring_repository.dart
      application/recurring_controller.dart
      presentation/recurring_screen.dart
    statistics/
      domain/statistics_models.dart
      application/statistics_controller.dart
      presentation/statistics_screen.dart
      presentation/widgets/category_bar_chart.dart
      presentation/widgets/category_pie_chart.dart
      presentation/widgets/waffle_chart.dart
      presentation/widgets/bubble_view.dart
    calendar/
      presentation/calendar_sheet.dart
      presentation/widgets/month_card.dart
    settings/
      data/preferences_repository.dart
      presentation/settings_screen.dart
      presentation/fast_info_settings_screen.dart
      presentation/theme_settings_screen.dart
      presentation/import_export_screen.dart
test/
  core/
  features/
integration_test/
```

---

## 5. Recommended Dependencies

Start with these packages:

```bash
flutter pub add flutter_riverpod go_router drift sqlite3_flutter_libs path_provider path intl collection uuid fl_chart flutter_svg shared_preferences
flutter pub add --dev build_runner drift_dev flutter_lints
```

Optional after MVP:

```bash
flutter pub add local_auth file_picker share_plus
flutter pub add --dev integration_test
```

Rationale:

- `flutter_riverpod`: predictable app state and feature controllers.
- `go_router`: simple route shell for home, notifications, settings, statistics.
- `drift`: typed SQLite persistence.
- `intl`: Hungarian currency/date formatting.
- `fl_chart`: bar and pie charts.
- `flutter_svg`: reusable icon assets if custom SVG icons are kept.
- `shared_preferences`: simple UI preferences where SQLite is unnecessary.

---


## 5.1 Color Design Tokens

These values preserve the old React Native app color design. Do not copy icon assets from the old app; rebuild icons with Flutter icon widgets or another Flutter-native icon set later.

### Core App Palette

Use these as centralized Flutter tokens, for example in `AppColors` or a `ThemeExtension`.

| Token | Hex | Original use | Flutter note |
| --- | --- | --- | --- |
| `primary` | `#06b6d4` | Main turquoise-blue accent, FAB, active controls, selected slot accent | FAB must use this exact blue shade. |
| `primaryDark` | `#0891b2` | Pressed/strong primary states | Use for pressed FAB or darker selected states. |
| `primaryLight` | `#67e8f9` | Soft primary highlight | Use sparingly for light accent backgrounds. |
| `white` | `#ffffff` | Cards, surfaces, foreground on strong colors | Keep as base surface color. |
| `gray50` | `#f8fafc` | Screen background / very light surface | Main scaffold background candidate. |
| `gray100` | `#f1f5f9` | Light cards, inactive chips, subtle panels | Light gray token. |
| `gray200` | `#e2e8f0` | Borders, dividers, disabled outlines | Primary border gray. |
| `gray300` | `#cbd5e1` | Stronger borders, disabled UI | Secondary border gray. |
| `gray400` | `#94a3b8` | Placeholder text, muted icons | Muted foreground. |
| `gray500` | `#64748b` | Secondary text | Default secondary label. |
| `gray600` | `#475569` | Dark secondary text | Emphasized secondary label. |
| `gray700` | `#334155` | Primary body text in some cards | Dark gray token. |
| `gray800` | `#1e293b` | Headings / dark foreground | Primary text candidate. |
| `gray900` | `#0f172a` | Strongest text / dark backgrounds | Use only where maximum contrast is needed. |
| `success` | `#16a34a` | Income/success text and states | Use for positive amounts. |
| `successBright` | `#22c55e` | Brighter green accents and slot color | Keep separate from semantic success if needed. |
| `danger` | `#dc2626` | Expense/danger text and states | Use for negative amounts. |
| `dangerBright` | `#ef4444` | Brighter red accents and slot color | Keep separate from semantic danger if needed. |
| `warning` | `#f59e0b` | Warnings, budget attention | Use for budget warning states. |
| `info` | `#3b82f6` | Informational blue, chart/slot color | Do not replace FAB with this; FAB stays `#06b6d4`. |

### Supplemental UI Colors Found in Source

These colors appear in specific UI areas of the old app. Keep them available as named tokens, but do not let them override the core palette above.

| Token | Hex | Original use | Flutter note |
| --- | --- | --- | --- |
| `surfaceNearWhite` | `#fdfdfe` | Transaction log editable/background variant | Use only where the old logbox almost-white surface is needed. |
| `surfaceWarmGray` | `#f8f9fa` | Menu pills / light option containers | Separate from slate `gray50`. |
| `surfaceFlatGray` | `#f5f5f5` | Chart/background fallback | Legacy neutral surface. |
| `neutral500` | `#6b7280` | Default icon/slot neutral gray | Used by hardcoded icons and slot fallback visuals; icons themselves are not copied. |
| `neutral700` | `#374151` | Dark neutral slot gray | Slot palette gray. |
| `neutral800` | `#1f2937` | Dark neutral / `themeutils.DARK` | Also slot palette gray. |
| `darkSplash` | `#0f172a` | Loading screen dark slate background | Same value as `gray900`, but the name documents its old use. |
| `budgetOverLegacy` | `#ff4444` | Budget over-limit/progress warning | Legacy bright red; keep distinct from `danger`. |
| `budgetApproachingLegacy` | `#ff8800` | Budget approaching-limit warning | Legacy bright orange; keep distinct from `warning`. |
| `coinGold` | `#fbbf24` | Back header gold/coin accent | Specialized decorative accent. |
| `coinGoldLight` | `#fcd34d` | Back header gold highlight | Specialized decorative accent. |
| `coinGoldDark` | `#d97706` | Back header gold shadow | Specialized decorative accent. |
| `coinCream` | `#fef3c7` | Back header gold border/highlight | Specialized decorative accent. |
| `errorOverlay` | `#d73027` | Error overlay background | Developer/error UI only. |
| `errorOverlayDark` | `#b71c1c` | Error overlay darker button/background | Developer/error UI only. |
| `errorOverlayText` | `#ffcdd2` | Error overlay pale red text | Developer/error UI only. |
| `chartBlue50` | `#dbeafe` | Old waffle chart low intensity | Chart-only gradient step. |
| `chartBlue300` | `#93c5fd` | Old waffle chart light intensity | Chart-only gradient step. |
| `chartBlue400` | `#60a5fa` | Old waffle chart medium intensity | Chart-only gradient step. |
| `chartBlue600` | `#2563eb` | Old waffle chart high intensity | Chart-only gradient step. |
| `chartBlue700` | `#1d4ed8` | Old waffle chart maximum intensity | Chart-only gradient step. |
| `teal500Legacy` | `#14b8a6` | Legacy category/import data color | Data/category color, not the FAB primary. |
| `sky400Legacy` | `#38bdf8` | Legacy notification/category color | Data/category color, not the FAB primary. |
| `rose600Legacy` | `#e11d48` | Legacy category/import data color | Data/category color. |
| `purple600Legacy` | `#7c3aed` | Legacy category/import data color | Data/category color. |
| `green700Legacy` | `#15803d` | Legacy category/import data color | Data/category color. |

Notes:

- The old source contains saved category colors in JSON backups. Treat those as user data/migration values, not as the app brand palette.
- Icon SVG/path definitions are intentionally excluded. Only their neutral/default color references are recorded as design tokens.
- The FAB and primary action color remains `#06b6d4` everywhere, even where other blue colors appear in charts or category data.

### Slot Color Palette

The old app lets users map icons into slots and gives slots a fixed color palette. Preserve these colors and their order for compatibility with any saved slot index.

| Slot index | Hex |
| --- | --- |
| 0 | `#ef4444` |
| 1 | `#f97316` |
| 2 | `#eab308` |
| 3 | `#84cc16` |
| 4 | `#22c55e` |
| 5 | `#10b981` |
| 6 | `#06b6d4` |
| 7 | `#0ea5e9` |
| 8 | `#3b82f6` |
| 9 | `#6366f1` |
| 10 | `#8b5cf6` |
| 11 | `#a855f7` |
| 12 | `#d946ef` |
| 13 | `#ec4899` |
| 14 | `#f43f5e` |
| 15 | `#6b7280` |
| 16 | `#374151` |
| 17 | `#1f2937` |
| 18 | `#064e3b` |
| 19 | `#7c2d12` |
| 20 | `#4c1d95` |

Recommended Flutter representation:

```dart
class AppColors {
  static const primary = Color(0xFF06B6D4);
  static const primaryDark = Color(0xFF0891B2);
  static const primaryLight = Color(0xFF67E8F9);

  static const gray50 = Color(0xFFF8FAFC);
  static const gray100 = Color(0xFFF1F5F9);
  static const gray200 = Color(0xFFE2E8F0);
  static const gray300 = Color(0xFFCBD5E1);
  static const gray400 = Color(0xFF94A3B8);
  static const gray500 = Color(0xFF64748B);
  static const gray600 = Color(0xFF475569);
  static const gray700 = Color(0xFF334155);
  static const gray800 = Color(0xFF1E293B);
  static const gray900 = Color(0xFF0F172A);

  static const success = Color(0xFF16A34A);
  static const successBright = Color(0xFF22C55E);
  static const danger = Color(0xFFDC2626);
  static const dangerBright = Color(0xFFEF4444);
  static const warning = Color(0xFFF59E0B);
  static const info = Color(0xFF3B82F6);

  static const surfaceNearWhite = Color(0xFFFDFDFE);
  static const surfaceWarmGray = Color(0xFFF8F9FA);
  static const surfaceFlatGray = Color(0xFFF5F5F5);
  static const neutral500 = Color(0xFF6B7280);
  static const neutral700 = Color(0xFF374151);
  static const neutral800 = Color(0xFF1F2937);
  static const darkSplash = Color(0xFF0F172A);
  static const budgetOverLegacy = Color(0xFFFF4444);
  static const budgetApproachingLegacy = Color(0xFFFF8800);
  static const coinGold = Color(0xFFFBBF24);
  static const coinGoldLight = Color(0xFFFCD34D);
  static const coinGoldDark = Color(0xFFD97706);
  static const coinCream = Color(0xFFFEF3C7);
  static const errorOverlay = Color(0xFFD73027);
  static const errorOverlayDark = Color(0xFFB71C1C);
  static const errorOverlayText = Color(0xFFFFCDD2);
  static const chartBlue50 = Color(0xFFDBEAFE);
  static const chartBlue300 = Color(0xFF93C5FD);
  static const chartBlue400 = Color(0xFF60A5FA);
  static const chartBlue600 = Color(0xFF2563EB);
  static const chartBlue700 = Color(0xFF1D4ED8);
  static const teal500Legacy = Color(0xFF14B8A6);
  static const sky400Legacy = Color(0xFF38BDF8);
  static const rose600Legacy = Color(0xFFE11D48);
  static const purple600Legacy = Color(0xFF7C3AED);
  static const green700Legacy = Color(0xFF15803D);

  static const slotColors = <Color>[
    Color(0xFFEF4444), Color(0xFFF97316), Color(0xFFEAB308),
    Color(0xFF84CC16), Color(0xFF22C55E), Color(0xFF10B981),
    Color(0xFF06B6D4), Color(0xFF0EA5E9), Color(0xFF3B82F6),
    Color(0xFF6366F1), Color(0xFF8B5CF6), Color(0xFFA855F7),
    Color(0xFFD946EF), Color(0xFFEC4899), Color(0xFFF43F5E),
    Color(0xFF6B7280), Color(0xFF374151), Color(0xFF1F2937),
    Color(0xFF064E3B), Color(0xFF7C2D12), Color(0xFF4C1D95),
  ];
}
```

## 6. Domain Model

### 6.1 TransactionLog

Fields:

- `id`: integer, generated as `YYMMNN` when possible.
- `date`: calendar date.
- `time`: local time.
- `amount`: signed integer or decimal; expenses negative, income positive.
- `merchant`: original merchant/source name.
- `userAssignedName`: optional user-edited display name.
- `transactionCategoryId`: required category id.
- `latitude`, `longitude`, `address`: optional geolocation fields.
- `createdAt`, `updatedAt`.

Rules:

- Display merchant is `userAssignedName ?? merchant`.
- Transaction type is derived from amount sign.
- Amount edit updates one transaction only.
- Merchant rename updates `userAssignedName` for every transaction whose display merchant matches the old name.
- Category change from a transaction card updates all transactions with the same display merchant.

### 6.2 Category

Fields:

- `id`: integer.
- `name`: string.
- `type`: enum `expense` or `income`.
- `colorSlot`: integer 0-20.
- `iconSlot`: integer 0-20.
- `hasLimit`: bool.
- `limitAmount`: integer amount in selected currency.
- `alertActive`: bool.
- `createdAt`, `updatedAt`.

Rules:

- Category picker filters by active transaction type.
- Category cannot be deleted when any transaction references it.
- Category edit can change name, color slot, icon slot.
- Category card tap applies a category filter.
- Category icon long press opens edit mode.

### 6.3 SlotMapping

Fields:

- `slot`: integer 0-20.
- `iconId`: string.
- `colorSlot`: integer 0-20.

Rules:

- A slot maps to one icon id and one color slot.
- The same icon id should not be assigned to multiple slots unless the product decision changes.
- Slot 0 is valid and must never be treated as falsy.

Default color slots:

```text
0  #ef4444  red
1  #f97316  orange
2  #eab308  yellow
3  #84cc16  lime
4  #22c55e  green
5  #10b981  emerald
6  #06b6d4  cyan
7  #0ea5e9  sky
8  #3b82f6  blue
9  #6366f1  indigo
10 #8b5cf6  violet
11 #a855f7  purple
12 #d946ef  fuchsia
13 #ec4899  pink
14 #f43f5e  rose
15 #6b7280  gray
16 #374151  dark gray
17 #1f2937  darker gray
18 #064e3b  emerald dark
19 #7c2d12  orange dark
20 #4c1d95  violet dark
```

### 6.4 BudgetLimit

Use one table for both overall monthly limits and category monthly limits.

Fields:

- `id`
- `scope`: enum `monthlyOverview` or `categoryMonth`
- `year`: integer.
- `month`: integer 1-12.
- `categoryId`: nullable; only used for category month limits.
- `hasLimit`: bool.
- `limitAmount`: integer.
- `alertActive`: bool.
- `createdAt`, `updatedAt`.

Rules:

- Monthly overview compares total expense spending for selected month.
- Category limit compares selected month spending for that category.
- When spending is at or above 100 percent, create or update a budget notification.
- Alert/bell state controls visual alert intent, but the original app logged budget exceed events even if the bell was inactive.

### 6.5 AppNotification

Fields:

- `id`: string.
- `type`: enum `budgetAlert`, `monthlyBudgetAlert`, `recurringTransactionAlert`, `transaction`, `system`, `reminder`.
- `title`
- `message`
- `timestamp`
- `isRead`
- `payloadJson`

Rules:

- Notification screen filters/group by selected month.
- Budget alert card can support increasing a category limit by 25 percent.
- Swipe/tap behavior can be implemented after basic list and detail behavior.

### 6.6 RecurringTransaction

Fields:

- `id`
- `name`
- `amount`
- `dayOfMonth`: 1-31.
- `categoryId`
- `isActive`
- `createdAt`, `updatedAt`, `lastProcessedMonth`

Rules:

- Recurring transactions are expenses unless a future type field is added.
- Processing should avoid duplicate creation for the same month.
- Upcoming view should show next 30 days.

### 6.7 FastInfoConfig

Store six configurable slots:

- `pill1`, `pill2`, `pill3`
- `box1`, `box2`, `box3`

Each slot points to a metric id, not a hardcoded value. Supported initial metric ids:

- `savings`
- `todayTransactionCount`
- `monthlyLimit`
- `trend`
- `categoryCount`
- `averageDailySpend`
- `lastTransactionAge`
- `topCategory`
- `topMerchant`
- `monthlyExpenseCount`
- `monthlyExpenseTotal`

---

## 7. Database Tables

Use Drift tables:

```text
transaction_logs
categories
slot_mappings
budget_limits
app_notifications
recurring_transactions
fast_info_slots
search_history
frequent_merchants
user_preferences
```

Indexes:

- `transaction_logs(date)`
- `transaction_logs(transaction_category_id)`
- `transaction_logs(merchant)`
- `transaction_logs(user_assigned_name)`
- `categories(type)`
- `budget_limits(year, month, scope, category_id)`
- `app_notifications(timestamp)`
- `app_notifications(type)`
- `recurring_transactions(day_of_month, is_active)`

Migration rule:

- Version 1 creates the schema.
- Add future columns through Drift migrations, not destructive resets.

---

## 8. Navigation and Screens

### 8.1 AppShell

Bottom navigation:

- Home
- Statistics
- Notifications
- Settings

The old app displayed "Groceries" for the stats nav item. In the rebuild, name this tab "Statisztikák" unless the product intentionally keeps "Groceries".

### 8.2 Home Dashboard

Home contains:

- Stage header.
- Transaction type pills: `Kiadás`, `Bevétel`.
- Summary pill.
- Search/filter pill.
- Monthly transaction list.
- Floating action button.

State:

- selected month
- active transaction type
- category filter
- merchant filter
- search query
- stage state: stage0, stage1, stage2

### 8.3 Stage Header

Stage0:

- total balance across all transactions
- balance hide/show
- calendar button
- category button
- FastInfo preview
- button/gesture to open Stage1

Stage1:

- budget overview/category budget bar
- swipe budget bar left to cycle categories
- swipe right to return to overall budget
- tap budget bar opens BudgetPicker
- visual progress bar if limit exists
- bell icon if limit exists
- button/gesture to open Stage2 or return Stage0

Stage2:

- extended analytics area
- budget bar remains available
- category chart switcher: bar, pie, waffle
- back/close control

Implementation note:

- Build Stage0 first.
- Implement Stage1 budget bars after budget repository is tested.
- Implement Stage2 after statistics calculations are stable.

### 8.4 Add Transaction Flow

Open with FAB.

Fields:

- transaction name / merchant
- amount
- category selector
- date picker
- time picker

Save behavior:

- active tab `expense`: store `-abs(amount)`
- active tab `income`: store `abs(amount)`
- require non-empty merchant/name
- require valid amount greater than zero
- require category
- refresh summaries and transaction list after save

### 8.5 Transaction List and Card

Card shows:

- category icon circle
- display merchant
- amount
- time
- optional position/count if in paged mode

Gestures:

- swipe right: delete confirmation
- swipe left: set merchant fast filter
- tap merchant: edit merchant display name for all matching transactions
- tap amount: edit amount for this transaction only
- long press category icon: open category picker and apply selected category to all matching merchant transactions

### 8.6 Category Management

Category sheet:

- filters categories by active transaction tab.
- grid cards show name, icon, color, transaction count.
- card tap applies category filter.
- icon long press opens edit sheet.
- plus button opens add category sheet.
- delete button is active only when transaction count is zero.

Add/edit category sheet:

- name input
- swipe between color picker and icon picker
- color picker shows 21 slots
- icon picker shows slot icons
- long press icon slot opens slot icon assignment sheet

### 8.7 Search and Filter

Search pill combines:

- text query against display merchant
- active category filter
- active merchant filter

Clear actions:

- clear category filter
- clear merchant filter
- clear search query
- clear all filters

Summary pill titles should include active filter context:

- no filter: `Kiadások (Szeptember)`
- category filter: `Élelmiszer (Szeptember)`
- merchant filter: `Tesco (Szeptember)`

### 8.8 Calendar

Calendar sheet:

- month grid
- month navigation
- heatmap mode for spending intensity
- selected month updates dashboard and transaction list

MVP:

- Month picker and transaction heat indicators.

After MVP:

- Heatmap min/max controls and detailed day overlays.

### 8.9 Notifications

Notification screen:

- same selected month as dashboard or independent month state.
- list grouped by date: Ma, Tegnap, MM.DD.
- unread count.
- mark read.
- delete notification.
- clear all.

Notification types:

- budget limit alert
- monthly budget alert
- recurring transaction alert
- transaction/system/reminder

### 8.10 Recurring Transactions

Screen:

- form: name, amount, day of month, category, active state.
- list existing recurring expenses.
- edit existing item by tapping.
- swipe right delete.
- swipe left toggle active/inactive.

Processing:

- run on app startup and once per day while app is opened.
- create transaction when `dayOfMonth` matches and current month was not processed.
- create recurring notification after transaction creation.

### 8.11 Statistics

Statistics screen:

- time period toggle: month/year.
- previous/next period buttons.
- view toggle: bubble/card.
- charts: category bar, pie/donut, waffle.

MVP calculations:

- spending by category for selected month.
- income total, expense total, balance.
- top category.
- top merchant.

---

## 9. Repository APIs

Create these repository interfaces before building UI:

```dart
abstract class TransactionRepository {
  Future<List<TransactionLog>> watchOrFetchMonth(int year, int month);
  Stream<List<TransactionLog>> watchMonth(int year, int month);
  Future<List<TransactionLog>> getAll();
  Future<TransactionLog> add(TransactionDraft draft);
  Future<void> updateAmount(int id, num signedAmount);
  Future<int> renameMerchant({required String oldDisplayName, required String newDisplayName});
  Future<int> changeCategoryForMerchant({required String displayMerchant, required int categoryId});
  Future<void> delete(int id);
}
```

```dart
abstract class CategoryRepository {
  Stream<List<Category>> watchAll();
  Future<List<Category>> getByType(CategoryType type);
  Future<Category> add(CategoryDraft draft);
  Future<Category> update(Category category);
  Future<bool> canDelete(int categoryId);
  Future<void> delete(int categoryId);
  Future<Map<int, int>> transactionCounts();
}
```

```dart
abstract class BudgetRepository {
  Stream<List<BudgetLimit>> watchMonth(int year, int month);
  Future<BudgetLimit?> getOverview(int year, int month);
  Future<BudgetLimit?> getCategoryLimit(int year, int month, int categoryId);
  Future<void> setOverviewLimit(int year, int month, num amount, bool alertActive);
  Future<void> setCategoryLimit(int year, int month, int categoryId, num amount, bool alertActive);
  Future<void> clearLimit(BudgetLimit limit);
  Future<void> checkLimitsAfterTransaction(int year, int month);
}
```

```dart
abstract class SlotRepository {
  Stream<List<SlotMapping>> watchMappings();
  Future<List<SlotMapping>> getMappings();
  Future<void> updateSlot({required int slot, required String iconId, required int colorSlot});
  Future<void> clearSlot(int slot);
}
```

```dart
abstract class NotificationRepository {
  Stream<List<AppNotification>> watchMonth(int year, int month);
  Future<void> add(AppNotificationDraft draft);
  Future<void> markRead(String id);
  Future<void> delete(String id);
  Future<void> clearAll();
}
```

---

## 10. Implementation Phases

### Phase 0: Project Scaffold

- Create Flutter project in `~/flutterapps/exptv2`.
- Add dependencies.
- Enable Flutter linting.
- Create folder structure.
- Add this guide to source control.

Verification:

```bash
flutter pub get
flutter analyze
flutter test
```

Expected:

- Analyze has no errors.
- Default widget test passes or is replaced by an app smoke test.

### Phase 1: Core Domain and Database

Build:

- Drift schema.
- Domain models.
- Currency/date formatters.
- Transaction id generator.
- Repository implementations.

Tests:

- expense amount stays negative.
- income amount stays positive.
- `YYMMNN` id generation increments within month.
- slot 0 is accepted.
- category delete fails when transaction count is greater than zero.
- merchant rename affects all display matches.
- amount update affects one transaction only.

### Phase 2: Home MVP

Build:

- App shell with bottom nav.
- Home dashboard.
- selected month state.
- transaction type pills.
- summary pill with monthly/yearly/all-time swipe.
- transaction list.
- add transaction sheet.

Tests:

- adding expense updates monthly expense summary.
- adding income updates income summary.
- changing month changes visible transaction list.
- summary pill cycles period on horizontal swipe.

### Phase 3: Categories and Slots

Build:

- Category picker sheet.
- Category card grid.
- Add/edit category sheet.
- Slot icon/color rendering.
- Icon picker sheet.

Tests:

- category picker filters income/expense categories.
- category card tap sets category filter.
- category delete button disabled when count is nonzero.
- changing category icon slot updates all category renderers.
- slot 0 icon renders.

### Phase 4: Transaction Card Interactions

Build:

- swipe right delete confirmation.
- swipe left merchant fast filter.
- merchant edit.
- amount edit.
- category change by merchant.

Tests:

- swipe left sets merchant filter.
- delete removes selected transaction.
- merchant rename updates all matching display merchants.
- category change updates all same-merchant transactions.
- amount edit updates only selected transaction id.

### Phase 5: Budget Limits and Stage1 Header

Build:

- Budget repository.
- monthly overview limit.
- category monthly limits.
- BudgetPicker sheet.
- Stage1 budget bar.
- alert bell state.
- progress indicator.
- budget notification generation.

Tests:

- monthly overview spending uses only expenses.
- category spending uses selected category and selected month.
- progress is capped visually at 100 percent.
- budget exceed creates one active notification per budget scope/month.
- increasing limit can clear or downgrade alert state if spending is below new limit.

### Phase 6: Notifications

Build:

- notification list grouped by date.
- unread count.
- mark read.
- delete.
- clear all.
- budget alert detail.
- recurring alert detail.

Tests:

- unread count excludes read notifications.
- selected month filters notifications.
- clearing all empties repository.

### Phase 7: Recurring Transactions

Build:

- recurring screen.
- add/edit/delete/toggle.
- monthly processor.
- recurring notification creation.

Tests:

- invalid day rejected.
- inactive recurring transaction is not processed.
- active recurring transaction creates a transaction on matching day.
- same recurring transaction does not process twice for same month.

### Phase 8: Statistics and Calendar

Build:

- statistics controller.
- category bar chart.
- pie/donut chart.
- waffle chart.
- bubble/card views.
- calendar month sheet.
- month heat indicators.

Tests:

- category spending totals match transactions.
- top merchant uses display merchant.
- selected month controls statistics.
- empty month shows zero state.

### Phase 9: Settings, FastInfo, Import/Export

Build:

- settings screen.
- FastInfo slot editor.
- currency/language/theme preferences.
- JSON export.
- JSON import with validation.
- backup list based on exported files.

Tests:

- FastInfo config persists.
- selected currency affects formatting.
- exported JSON can be imported into a fresh database.
- invalid import shows validation error and does not alter existing data.

---

## 11. Critical UI Behaviors to Preserve

### SummaryPill

- Has three states: monthly, yearly, all-time.
- Horizontal swipe cycles `monthly -> yearly -> all-time -> monthly`.
- Haptic feedback on cycle.
- Title reflects filter context.

### TransactionLogCard

- Right swipe: delete confirmation.
- Left swipe: fast merchant filter.
- Merchant edit is collective by display merchant.
- Category change is collective by display merchant.
- Amount edit is individual.
- Timestamp/date/geolocation are display-only in the card.

### CategoryCard

- Card tap applies filter.
- Icon long press opens edit.
- Delete button is red and active only when there are no transactions.
- Delete button is gray/inactive when category has transactions.

### BudgetBar

- First item is overall monthly budget.
- Later items are expense categories.
- Swipe left cycles forward through category budgets.
- Swipe right returns to overall budget.
- Tapping opens BudgetPicker.
- If limit exists, show progress bar and bell.
- Progress color becomes warning/danger near or over limit.

### Month Navigation

- Transaction list and notifications support month swipe.
- Dashboard summaries derive from selected month.
- Haptic feedback on month change.

---

## 12. Data Migration From Old App

Do not migrate automatically in the first commit. Add a manual import command or import screen after the database layer is stable.

Old JSON mappings:

- `transaction-logs.json.logs[]` -> `transaction_logs`
- `transaction-categories.json.categories[]` -> `categories`
- `slot-mappings.json` -> `slot_mappings`
- `fastinfo.json` -> `fast_info_slots`
- `budget-limit-notifications.json` -> `app_notifications`
- `recurring-transaction-notifications.json` -> `app_notifications`
- `search-history.json.frequentMerchants[]` -> `frequent_merchants`
- `user-preferences.json` -> `user_preferences`

Import validation:

- Reject transaction without date, time, merchant, amount, category id.
- Reject category without id, name, type.
- Normalize category type: `kiadás` -> `expense`, `bevétel` -> `income`.
- Normalize date formats: `YYYY.MM.DD` and `YYYY-MM-DD`.
- Preserve old transaction ids if unique.
- Preserve signed amounts.
- If a transaction references a missing category, import it into an `Uncategorized` category of the matching transaction type.

---

## 13. Formatting Rules

Currency:

- Default currency: HUF.
- Default locale: `hu_HU`.
- Expenses display with `-`.
- Income displays with `+`.
- Zero displays as `0 Ft`.

Dates:

- Internal storage uses date/time types.
- UI default date format: `YYYY.MM.DD`.
- Month labels use Hungarian month names.

Transaction type:

```text
amount < 0 => expense
amount > 0 => income
amount = 0 => invalid for user-created transaction
```

---

## 14. Testing Strategy

Required unit test groups:

- `currency_formatter_test.dart`
- `transaction_id_generator_test.dart`
- `transaction_repository_test.dart`
- `category_repository_test.dart`
- `budget_repository_test.dart`
- `slot_repository_test.dart`
- `recurring_controller_test.dart`
- `statistics_controller_test.dart`

Required widget test groups:

- `summary_pill_test.dart`
- `transaction_log_card_test.dart`
- `category_picker_sheet_test.dart`
- `budget_picker_sheet_test.dart`
- `notification_screen_test.dart`

Required integration flows:

- add expense -> see transaction -> summary updates.
- add income -> switch income tab -> summary updates.
- create category -> add transaction with it -> category count updates.
- set category budget -> add expense over limit -> notification appears.
- create recurring expense -> process day -> transaction and notification appear.

---

## 15. Build and Run Commands

From Ubuntu proot:

```bash
cd ~/flutterapps/exptv2
flutter pub get
flutter analyze
flutter test
flutter run
```

For Android release later:

```bash
flutter build apk --release
```

Before every handoff:

```bash
flutter analyze
flutter test
```

Expected:

- `flutter analyze` exits with no issues.
- `flutter test` passes all unit and widget tests.

---

## 16. MVP Definition

The first usable version is complete when these flows work:

- App opens to Home.
- User can add expense and income transactions.
- User can create and edit categories.
- Transaction list filters by month and type.
- Summary pill shows monthly, yearly, all-time totals.
- User can delete a transaction.
- User can set a category filter and clear it.
- Data persists after app restart.

Budget, notifications, recurring transactions, statistics, and import/export come after the MVP data and home flows are stable.

---

## 17. Product Decisions Already Made

- Rebuild in Flutter/Dart, not React Native.
- Project name: `exptv2`.
- Keep original app concept: personal finance tracker.
- Preserve signed amount semantics.
- Preserve category/merchant collective update behavior.
- Replace Express JSON backend with local Flutter persistence for MVP.
- Preserve Hungarian-first UI labels.
- Use feature-first structure.
- Keep category icon/color slot model.

---

## 18. Open Decisions For Implementation Start

These must be answered before coding the UI, but they do not block database scaffolding:

- Exact visual style: faithfully recreate original turquoise/gray card UI or simplify.
- Whether Stage2 analytics is part of MVP or Phase 8.
- Whether notification monitoring of external Android notifications is required in Flutter MVP.
- Whether old JSON data should be imported automatically on first launch or through a manual import screen.
- Whether the "Groceries" bottom nav item should be renamed to "Statisztikák".

Recommended defaults:

- Use a cleaner Flutter-native version of the original turquoise/gray UI.
- Keep Stage2 out of MVP.
- Keep external notification monitoring out of MVP.
- Use manual import after MVP.
- Rename "Groceries" to "Statisztikák".

---

## 19. Implementation Checklist

- [ ] Scaffold Flutter project.
- [ ] Add dependencies and linting.
- [ ] Create database schema.
- [ ] Create domain models.
- [ ] Create repositories.
- [ ] Add repository tests.
- [ ] Build app shell and routing.
- [ ] Build Home MVP.
- [ ] Build add transaction flow.
- [ ] Build category management.
- [ ] Build transaction card gestures.
- [ ] Build budget limits.
- [ ] Build notifications.
- [ ] Build recurring transactions.
- [ ] Build statistics.
- [ ] Build settings and FastInfo.
- [ ] Build JSON import/export.
- [ ] Run full test suite.
- [ ] Build release APK.

---

## 20. Notes For Future Agents

The old app is useful for behavior discovery, not as code to copy. The largest risk is recreating the original monolithic state shape in Flutter. Keep the data layer and domain rules small, tested, and independent before building animated UI.

If there is uncertainty, implement in this order:

1. Data model.
2. Repository tests.
3. Plain UI without animation.
4. Gestures.
5. Animation and haptics.
6. Visual polish.

This keeps `exptv2` maintainable while preserving the original app's important behavior.
