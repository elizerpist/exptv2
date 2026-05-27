# Calendar Canvas Menu Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build the expt0926 header calendar menu in Flutter, with matching modes and controls, while rendering all month cards and day cells on one canvas.

**Architecture:** `TransactionHomePage` owns overlay visibility and passes loaded transactions/categories into a dedicated calendar menu overlay. Pure Dart render builders precompute annual day/month data, and a single `CustomPaint` draws the annual calendar body from immutable render models. Header controls, mode selector, and slider panels remain normal Flutter widgets because they are interactive controls rather than the heavy repeated calendar grid.

**Tech Stack:** Flutter/Dart, `CustomPainter`, existing `TransactionStore`, `TransactionRecord`, `TransactionCategory`, `AppColors`, Flutter widget/unit tests, GitHub Actions Android build.

---

## File Structure

Create these files:

- `lib/features/transactions/models/calendar_menu_mode.dart`: enum and display metadata for `normal`, `summary`, `heatmap`, and `category` modes.
- `lib/features/transactions/models/calendar_render_models.dart`: immutable render models for annual calendar, month cards, day cells, heatmap overlays, and thresholds.
- `lib/features/transactions/data/calendar_render_builder.dart`: pure Dart builder that converts transactions/categories into annual render data.
- `lib/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart`: four-button selector matching the React Native visual styles.
- `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`: bottom floating slider panel for threshold and heatmap modes.
- `lib/features/transactions/widgets/calendar_menu/calendar_canvas.dart`: scroll wrapper, `RepaintBoundary`, hit testing, and `CustomPaint` host.
- `lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart`: deterministic card/day geometry calculator used by the widget, painter, and tests.
- `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`: single painter that draws month cards, day cells, and mode-specific marks.
- `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`: slide-up menu shell with year navigation, title, selector, canvas, and slider panels.
- `test/transactions/calendar_render_builder_test.dart`: unit tests for annual data, threshold, summary, heatmap, and category calculations.
- `test/transactions/calendar_menu_widgets_test.dart`: widget tests for selector, slider panel, overlay open/close, and single-canvas body.

Modify these files:

- `lib/features/transactions/widgets/header_card/transaction_header_card.dart`: add `onCalendarPressed` callback and wire the existing calendar icon.
- `lib/features/transactions/transaction_home_page.dart`: add `_calendarOpen`, pass transactions/categories into the calendar menu overlay, close conflicting overlays.
- `test/transactions/header_card_test.dart`: assert the calendar icon calls its callback.

Do not change database, Kotlin bridge, category CRUD, transaction persistence, notification scraping, bottom navigation, or existing limit manager behavior in this feature.

---

### Task 1: Calendar Mode And Render Models

**Files:**
- Create: `lib/features/transactions/models/calendar_menu_mode.dart`
- Create: `lib/features/transactions/models/calendar_render_models.dart`
- Test: `test/transactions/calendar_render_builder_test.dart`

- [ ] **Step 1: Write the failing tests for mode labels and basic annual shape**

Add this test file with the first two tests:

```dart
import 'package:exptv2/features/transactions/data/calendar_render_builder.dart';
import 'package:exptv2/features/transactions/models/calendar_menu_mode.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('calendar menu modes keep original Hungarian labels and order', () {
    expect(CalendarMenuMode.values, const [
      CalendarMenuMode.normal,
      CalendarMenuMode.summary,
      CalendarMenuMode.heatmap,
      CalendarMenuMode.category,
    ]);
    expect(CalendarMenuMode.normal.title, 'Küszöbérték nézet');
    expect(CalendarMenuMode.summary.title, 'Összefoglaló');
    expect(CalendarMenuMode.heatmap.title, 'Hőtérkép');
    expect(CalendarMenuMode.category.title, 'Domináns kategória');
  });

  test('render builder creates 12 Monday-first month grids', () {
    final data = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: const [],
      categories: const [],
      thresholdValue: 1000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 10000,
    );

    expect(data.year, 2026);
    expect(data.months.length, 12);
    expect(data.months.first.month, 1);
    expect(data.months.first.name, 'January');
    expect(data.months.first.weekdayLabels, const ['M', 'T', 'W', 'T', 'F', 'S', 'S']);
    expect(data.months.first.days.length, 31);
    expect(data.months.first.leadingBlankDays, 3);
    expect(data.thresholdRange.min, 0);
    expect(data.thresholdRange.max, 1000);
  });
}
```

- [ ] **Step 2: Run the new test and verify it fails because the files do not exist**

Run: `flutter test test/transactions/calendar_render_builder_test.dart`

Expected: FAIL with import errors for `calendar_render_builder.dart` and `calendar_menu_mode.dart`.

- [ ] **Step 3: Add the calendar mode enum**

Create `lib/features/transactions/models/calendar_menu_mode.dart`:

```dart
enum CalendarMenuMode { normal, summary, heatmap, category }

extension CalendarMenuModeX on CalendarMenuMode {
  String get title => switch (this) {
    CalendarMenuMode.normal => 'Küszöbérték nézet',
    CalendarMenuMode.summary => 'Összefoglaló',
    CalendarMenuMode.heatmap => 'Hőtérkép',
    CalendarMenuMode.category => 'Domináns kategória',
  };
}
```

- [ ] **Step 4: Add render model classes**

Create `lib/features/transactions/models/calendar_render_models.dart`:

```dart
import 'package:flutter/material.dart';

class CalendarThresholdRange {
  const CalendarThresholdRange({required this.min, required this.max});

  final double min;
  final double max;
}

class CalendarYearRenderData {
  const CalendarYearRenderData({
    required this.year,
    required this.months,
    required this.thresholdRange,
  });

  final int year;
  final List<CalendarMonthRenderData> months;
  final CalendarThresholdRange thresholdRange;
}

class CalendarMonthRenderData {
  const CalendarMonthRenderData({
    required this.year,
    required this.month,
    required this.name,
    required this.weekdayLabels,
    required this.leadingBlankDays,
    required this.days,
    required this.income,
    required this.expense,
    required this.balance,
    required this.transactionCount,
  });

  final int year;
  final int month;
  final String name;
  final List<String> weekdayLabels;
  final int leadingBlankDays;
  final List<CalendarDayRenderData> days;
  final double income;
  final double expense;
  final double balance;
  final int transactionCount;

  bool get hasTransactions => transactionCount > 0;
}

class CalendarDayRenderData {
  const CalendarDayRenderData({
    required this.date,
    required this.day,
    required this.income,
    required this.expense,
    required this.hasIncome,
    required this.hasExpense,
    required this.meetsThreshold,
    required this.heatmapPercentage,
    required this.dominantCategoryId,
    required this.dominantCategoryColor,
    required this.isToday,
  });

  final DateTime date;
  final int day;
  final double income;
  final double expense;
  final bool hasIncome;
  final bool hasExpense;
  final bool meetsThreshold;
  final double heatmapPercentage;
  final int? dominantCategoryId;
  final Color dominantCategoryColor;
  final bool isToday;
}
```

- [ ] **Step 5: Add the minimal builder implementation**

Create `lib/features/transactions/data/calendar_render_builder.dart` with this implementation, then keep it focused in this file:

```dart
import 'package:flutter/material.dart';

import '../models/calendar_render_models.dart';
import '../models/transaction_category.dart';
import '../models/transaction_record.dart';

class CalendarRenderBuilder {
  const CalendarRenderBuilder._();

  static const weekdayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
  static const monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  static CalendarYearRenderData buildYear({
    required int year,
    required List<TransactionRecord> transactions,
    required List<TransactionCategory> categories,
    required double thresholdValue,
    required double heatmapMinValue,
    required double heatmapCurrentValue,
    DateTime? today,
    double? customThresholdMin,
    double? customThresholdMax,
  }) {
    final todayValue = today == null ? DateTime.now() : today;
    final normalizedToday = _dateOnly(todayValue);
    final byDate = <DateTime, List<TransactionRecord>>{};
    for (final record in transactions) {
      final parsed = _parseDate(record.normalizedDate);
      if (parsed == null) continue;
      final date = _dateOnly(parsed);
      byDate.putIfAbsent(date, () => []).add(record);
    }

    final dailyExpenses = byDate.values
        .map((records) => records.where((record) => record.amount < 0).fold<double>(0, (sum, record) => sum + record.amount.abs()))
        .where((value) => value > 0)
        .toList();
    final calculatedMin = dailyExpenses.isEmpty ? 0.0 : dailyExpenses.reduce((a, b) => a < b ? a : b);
    final calculatedMax = dailyExpenses.isEmpty ? 1000.0 : dailyExpenses.reduce((a, b) => a > b ? a : b);
    final thresholdMin = customThresholdMin == null ? calculatedMin : customThresholdMin;
    final thresholdMax = customThresholdMax == null ? calculatedMax : customThresholdMax;

    final categoryColors = <int, Color>{
      for (final category in categories) category.transactionCategoryID: category.slotColor,
    };

    return CalendarYearRenderData(
      year: year,
      thresholdRange: CalendarThresholdRange(min: thresholdMin, max: thresholdMax),
      months: List.generate(12, (index) {
        final month = index + 1;
        final daysInMonth = DateTime(year, month + 1, 0).day;
        final firstDay = DateTime(year, month, 1);
        final leadingBlankDays = firstDay.weekday - 1;
        var monthIncome = 0.0;
        var monthExpense = 0.0;
        var transactionCount = 0;
        final days = <CalendarDayRenderData>[];

        for (var day = 1; day <= daysInMonth; day += 1) {
          final date = DateTime(year, month, day);
          final dateKey = _dateOnly(date);
          final records = byDate.containsKey(dateKey) ? byDate[dateKey]! : const <TransactionRecord>[];
          transactionCount += records.length;
          var income = 0.0;
          var expense = 0.0;
          final expenseByCategory = <int, double>{};
          for (final record in records) {
            if (record.amount > 0) {
              income += record.amount;
            } else if (record.amount < 0) {
              final absolute = record.amount.abs();
              expense += absolute;
              expenseByCategory.update(record.transactionCategoryID, (value) => value + absolute, ifAbsent: () => absolute);
            }
          }
          monthIncome += income;
          monthExpense += expense;
          final dominantCategoryId = _dominantCategoryId(expenseByCategory);
          days.add(CalendarDayRenderData(
            date: date,
            day: day,
            income: income,
            expense: expense,
            hasIncome: income > 0,
            hasExpense: expense > 0,
            meetsThreshold: expense >= thresholdValue,
            heatmapPercentage: _heatmapPercentage(expense, heatmapMinValue, heatmapCurrentValue),
            dominantCategoryId: dominantCategoryId,
            dominantCategoryColor: _categoryColor(dominantCategoryId, categoryColors),
            isToday: _dateOnly(date) == normalizedToday,
          ));
        }

        return CalendarMonthRenderData(
          year: year,
          month: month,
          name: monthNames[index],
          weekdayLabels: weekdayLabels,
          leadingBlankDays: leadingBlankDays,
          days: days,
          income: monthIncome,
          expense: monthExpense,
          balance: monthIncome - monthExpense,
          transactionCount: transactionCount,
        );
      }),
    );
  }

  static DateTime? _parseDate(String value) {
    final parsed = DateTime.tryParse(value);
    if (parsed != null) return parsed;
    final compact = value.replaceAll('.', '-');
    return DateTime.tryParse(compact);
  }

  static DateTime _dateOnly(DateTime value) => DateTime(value.year, value.month, value.day);

  static double _heatmapPercentage(double expense, double minValue, double currentValue) {
    if (expense <= minValue || currentValue <= minValue) return 0;
    final percentage = (expense - minValue) / (currentValue - minValue);
    return percentage.clamp(0, 1).toDouble();
  }

  static int? _dominantCategoryId(Map<int, double> expenseByCategory) {
    int? id;
    var amount = -1.0;
    for (final entry in expenseByCategory.entries) {
      if (entry.value > amount) {
        id = entry.key;
        amount = entry.value;
      }
    }
    return id;
  }

  static Color _categoryColor(int? id, Map<int, Color> categoryColors) {
    if (id == null) return const Color(0xFF9CA3AF);
    final explicitColor = categoryColors[id];
    if (explicitColor != null) return explicitColor;
    return switch (id) {
      1 => const Color(0xFFEF4444),
      2 => const Color(0xFFF97316),
      4 => const Color(0xFF22C55E),
      6 => const Color(0xFFF472B6),
      11 => const Color(0xFF38BDF8),
      15 => const Color(0xFF64748B),
      21 => const Color(0xFFEC4899),
      _ => const Color(0xFF9CA3AF),
    };
  }
}
```

- [ ] **Step 6: Run the task tests and commit**

Run: `flutter test test/transactions/calendar_render_builder_test.dart`

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/models/calendar_menu_mode.dart lib/features/transactions/models/calendar_render_models.dart lib/features/transactions/data/calendar_render_builder.dart test/transactions/calendar_render_builder_test.dart
git commit -m "feat: add calendar render models"
```

---

### Task 2: Calendar Render Builder Behavior

**Files:**
- Modify: `test/transactions/calendar_render_builder_test.dart`
- Modify: `lib/features/transactions/data/calendar_render_builder.dart`

- [ ] **Step 1: Add failing behavior tests for summary, threshold, heatmap, and category**

Append these tests inside `main()` in `test/transactions/calendar_render_builder_test.dart`:

```dart
  test('render builder calculates threshold, summary, and heatmap values', () {
    final data = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: [
        record(id: 1, date: '2026.05.04', amount: -5000, categoryId: 6),
        record(id: 2, date: '2026.05.04', amount: 2000, categoryId: 5),
        record(id: 3, date: '2026.05.08', amount: -15000, categoryId: 7),
      ],
      categories: [category(id: 6, colorSlot: 7), category(id: 7, colorSlot: 1)],
      thresholdValue: 10000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 20000,
      today: DateTime(2026, 5, 4),
    );

    final may = data.months[4];
    expect(data.thresholdRange.min, 5000);
    expect(data.thresholdRange.max, 15000);
    expect(may.income, 2000);
    expect(may.expense, 20000);
    expect(may.balance, -18000);
    expect(may.transactionCount, 3);

    final may4 = may.days[3];
    expect(may4.hasIncome, isTrue);
    expect(may4.hasExpense, isTrue);
    expect(may4.meetsThreshold, isFalse);
    expect(may4.heatmapPercentage, 0.25);
    expect(may4.isToday, isTrue);

    final may8 = may.days[7];
    expect(may8.meetsThreshold, isTrue);
    expect(may8.heatmapPercentage, 0.75);
    expect(may8.dominantCategoryId, 7);
    expect(may8.dominantCategoryColor, const Color(0xFFF97316));
  });

  test('custom threshold min and max override calculated expense range', () {
    final data = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: [record(id: 1, date: '2026.05.04', amount: -5000, categoryId: 6)],
      categories: const [],
      thresholdValue: 1000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 10000,
      customThresholdMin: 100,
      customThresholdMax: 9000,
    );

    expect(data.thresholdRange.min, 100);
    expect(data.thresholdRange.max, 9000);
  });
```

Add these helpers at the bottom of the file:

```dart
TransactionRecord record({
  required int id,
  required String date,
  required double amount,
  required int categoryId,
}) {
  return TransactionRecord.fromMap({
    'id': id,
    'date': date,
    'time': '12:00',
    'merchant': 'Shop',
    'amount': amount,
    'userAssignedName': null,
    'transactionCategoryID': categoryId,
  });
}

TransactionCategory category({required int id, required int colorSlot}) {
  return TransactionCategory.fromMap({
    'transactionCategoryID': id,
    'name': 'Category $id',
    'type': 'kiadás',
    'colorSlot': colorSlot,
    'iconSlot': 0,
    'backgroundColor': '#64748b',
    'hasLimit': false,
    'limitAmount': 0,
    'alertActive': false,
    'isCustomIcon': true,
  });
}
```

- [ ] **Step 2: Run the behavior tests**

Run: `flutter test test/transactions/calendar_render_builder_test.dart`

Expected: FAIL if any summary, heatmap, threshold override, or dominant category behavior is missing.

- [ ] **Step 3: Adjust the builder until these exact tests pass**

Keep changes inside `CalendarRenderBuilder.buildYear`. Use these rules:

```dart
final expense = record.amount < 0 ? record.amount.abs() : 0.0;
final income = record.amount > 0 ? record.amount : 0.0;
final meetsThreshold = dailyExpense >= thresholdValue;
final heatmapPercentage = ((dailyExpense - heatmapMinValue) / (heatmapCurrentValue - heatmapMinValue)).clamp(0, 1).toDouble();
final balance = monthIncome - monthExpense;
```

- [ ] **Step 4: Run all render builder tests and commit**

Run: `flutter test test/transactions/calendar_render_builder_test.dart`

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/data/calendar_render_builder.dart test/transactions/calendar_render_builder_test.dart
git commit -m "test: cover calendar render data behavior"
```

---

### Task 3: Mode Selector Widget

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart`
- Test: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Write the failing selector widget test**

Create `test/transactions/calendar_menu_widgets_test.dart` with this first test:

```dart
import 'package:exptv2/features/transactions/models/calendar_menu_mode.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('calendar mode selector renders four tappable mode buttons', (tester) async {
    var selected = CalendarMenuMode.normal;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarModeSelector(
            activeMode: selected,
            transitionLocked: false,
            onModeChanged: (mode) => selected = mode,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('calendar-mode-selector')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-normal')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-summary')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-heatmap')), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-mode-category')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-heatmap')));
    expect(selected, CalendarMenuMode.heatmap);
  });
}
```

- [ ] **Step 2: Run the selector test and verify it fails**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: FAIL with missing `calendar_mode_selector.dart`.

- [ ] **Step 3: Implement the selector widget**

Create `lib/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/calendar_menu_mode.dart';

class CalendarModeSelector extends StatelessWidget {
  const CalendarModeSelector({
    super.key,
    required this.activeMode,
    required this.onModeChanged,
    this.transitionLocked = false,
  });

  final CalendarMenuMode activeMode;
  final ValueChanged<CalendarMenuMode> onModeChanged;
  final bool transitionLocked;

  @override
  Widget build(BuildContext context) {
    return Container(
      key: const ValueKey('calendar-mode-selector'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColors.gray200),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: CalendarMenuMode.values.map((mode) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: _ModeButton(
              mode: mode,
              active: mode == activeMode,
              onTap: transitionLocked ? null : () => onModeChanged(mode),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _ModeButton extends StatelessWidget {
  const _ModeButton({required this.mode, required this.active, required this.onTap});

  final CalendarMenuMode mode;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final size = active ? 24.0 : 20.0;
    return InkWell(
      key: ValueKey('calendar-mode-${mode.name}'),
      onTap: onTap,
      customBorder: mode == CalendarMenuMode.heatmap ? null : const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: _baseColor,
          shape: mode == CalendarMenuMode.heatmap ? BoxShape.rectangle : BoxShape.circle,
          borderRadius: mode == CalendarMenuMode.heatmap ? BorderRadius.circular(2) : null,
          border: Border.all(
            color: active ? AppColors.primary : _inactiveBorder,
            width: active ? 2 : 1,
          ),
          boxShadow: active
              ? [BoxShadow(color: Colors.black.withValues(alpha: 0.4), offset: const Offset(0, 3), blurRadius: 4)]
              : const [],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(mode == CalendarMenuMode.heatmap ? 1 : 99),
          child: CustomPaint(painter: _ModeGlyphPainter(mode)),
        ),
      ),
    );
  }

  Color get _baseColor => switch (mode) {
    CalendarMenuMode.normal => AppColors.gray50,
    CalendarMenuMode.summary => AppColors.income,
    CalendarMenuMode.heatmap => AppColors.white,
    CalendarMenuMode.category => const Color(0xFFF97316),
  };

  Color get _inactiveBorder => switch (mode) {
    CalendarMenuMode.normal => const Color(0xFF9CA3AF),
    _ => AppColors.gray200,
  };
}

class _ModeGlyphPainter extends CustomPainter {
  const _ModeGlyphPainter(this.mode);

  final CalendarMenuMode mode;

  @override
  void paint(Canvas canvas, Size size) {
    if (mode == CalendarMenuMode.summary) {
      canvas.drawRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height), Paint()..color = AppColors.expense);
    }
    if (mode == CalendarMenuMode.heatmap) {
      canvas.drawRect(Rect.fromLTWH(size.width / 2, 0, size.width / 2, size.height), Paint()..color = AppColors.primary);
    }
  }

  @override
  bool shouldRepaint(_ModeGlyphPainter oldDelegate) => oldDelegate.mode != mode;
}
```

- [ ] **Step 4: Run the selector test and commit**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/calendar_menu/calendar_mode_selector.dart test/transactions/calendar_menu_widgets_test.dart
git commit -m "feat: add calendar mode selector"
```

---

### Task 4: Slider Panel Widget

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Add failing slider panel tests**

Append this import:

```dart
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart';
```

Append these tests inside `main()`:

```dart
  testWidgets('threshold slider panel shows editable Hungarian threshold label', (tester) async {
    var changed = 1000.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarValueSliderPanel.threshold(
            value: 1000,
            min: 0,
            max: 2000,
            onChanged: (value) => changed = value,
            onMinChanged: (_) {},
            onMaxChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Küszöbérték: 1 000 Ft'), findsOneWidget);
    await tester.drag(find.byKey(const ValueKey('calendar-threshold-slider')), const Offset(80, 0));
    expect(changed, isNot(1000));
  });

  testWidgets('heatmap slider panel shows editable current coloring label', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CalendarValueSliderPanel.heatmap(
            value: 10000,
            min: 0,
            max: 50000,
            onChanged: (_) {},
            onMinChanged: (_) {},
            onMaxChanged: (_) {},
          ),
        ),
      ),
    );

    expect(find.text('Aktuális színezés: 10 000 Ft'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsOneWidget);
  });
```

- [ ] **Step 2: Run the slider tests and verify they fail**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: FAIL with missing `CalendarValueSliderPanel`.

- [ ] **Step 3: Implement the slider panel**

Create `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_record.dart';

enum CalendarSliderKind { threshold, heatmap }

class CalendarValueSliderPanel extends StatelessWidget {
  const CalendarValueSliderPanel.threshold({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onMinChanged,
    required this.onMaxChanged,
  }) : kind = CalendarSliderKind.threshold;

  const CalendarValueSliderPanel.heatmap({
    super.key,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
    required this.onMinChanged,
    required this.onMaxChanged,
  }) : kind = CalendarSliderKind.heatmap;

  final CalendarSliderKind kind;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onMinChanged;
  final ValueChanged<double> onMaxChanged;

  @override
  Widget build(BuildContext context) {
    final label = kind == CalendarSliderKind.threshold ? 'Küszöbérték' : 'Aktuális színezés';
    final sliderKey = kind == CalendarSliderKind.threshold ? 'calendar-threshold-slider' : 'calendar-heatmap-slider';
    return Positioned(
      left: 20,
      right: 20,
      bottom: 40,
      child: Material(
        color: AppColors.white,
        elevation: 8,
        shadowColor: Colors.black.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        child: Container(
          key: ValueKey('$sliderKey-panel'),
          padding: const EdgeInsets.symmetric(horizontal: 15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.gray200),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 8),
              Text(
                '$label: ${formatHuf(value)}',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.gray800),
              ),
              Row(
                children: [
                  _EditableLimitText(value: min, onSubmitted: onMinChanged),
                  Expanded(
                    child: SliderTheme(
                      data: SliderTheme.of(context).copyWith(
                        activeTrackColor: AppColors.primary,
                        inactiveTrackColor: AppColors.gray200,
                        thumbColor: AppColors.primary,
                        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                      ),
                      child: Slider(
                        key: ValueKey(sliderKey),
                        value: value.clamp(min, max).toDouble(),
                        min: min,
                        max: max <= min ? min + 1 : max,
                        divisions: kind == CalendarSliderKind.heatmap ? ((max - min) / 100).round().clamp(1, 1000) : null,
                        onChanged: onChanged,
                      ),
                    ),
                  ),
                  _EditableLimitText(value: max, onSubmitted: onMaxChanged),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditableLimitText extends StatelessWidget {
  const _EditableLimitText({required this.value, required this.onSubmitted});

  final double value;
  final ValueChanged<double> onSubmitted;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      child: TextField(
        controller: TextEditingController(text: value.round().toString()),
        keyboardType: TextInputType.number,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 11, color: AppColors.gray500),
        decoration: const InputDecoration(border: InputBorder.none, isDense: true),
        onSubmitted: (text) {
          final parsed = double.tryParse(text);
          onSubmitted(parsed == null ? value : parsed);
        },
      ),
    );
  }
}
```

- [ ] **Step 4: Run widget tests and commit**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart test/transactions/calendar_menu_widgets_test.dart
git commit -m "feat: add calendar slider panel"
```

---

### Task 5: Calendar Canvas Layout And Painter

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart`
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart`
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_canvas.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Add failing tests for a single canvas body and deterministic layout**

Append these imports:

```dart
import 'package:exptv2/features/transactions/data/calendar_render_builder.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_canvas.dart';
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart';
```

Append these tests inside `main()`:

```dart
  test('calendar canvas layout creates two columns and six rows', () {
    final layout = CalendarCanvasLayout.calculate(width: 390, mode: CalendarMenuMode.normal);
    expect(layout.monthRects.length, 12);
    expect(layout.monthRects[0].left, 0);
    expect(layout.monthRects[1].left, greaterThan(layout.monthRects[0].right));
    expect(layout.monthRects[2].top, greaterThan(layout.monthRects[0].bottom));
  });

  testWidgets('calendar canvas renders annual body as one CustomPaint', (tester) async {
    final renderData = CalendarRenderBuilder.buildYear(
      year: 2026,
      transactions: const [],
      categories: const [],
      thresholdValue: 1000,
      heatmapMinValue: 0,
      heatmapCurrentValue: 10000,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 500,
            child: CalendarCanvas(
              data: renderData,
              mode: CalendarMenuMode.normal,
              thresholdValue: 1000,
              heatmapMinValue: 0,
              heatmapCurrentValue: 10000,
              onMonthSelected: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('calendar-canvas')), findsOneWidget);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('January'), findsNothing);
    expect(find.text('1'), findsNothing);
  });
```

- [ ] **Step 2: Run widget tests and verify missing canvas files fail**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: FAIL with missing calendar canvas classes.

- [ ] **Step 3: Implement canvas layout calculator**

Create `lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart`:

```dart
import 'dart:ui';

import '../../models/calendar_menu_mode.dart';

class CalendarCanvasLayout {
  const CalendarCanvasLayout({required this.size, required this.monthRects});

  final Size size;
  final List<Rect> monthRects;

  static CalendarCanvasLayout calculate({required double width, required CalendarMenuMode mode}) {
    final cardGap = width * 0.04;
    final cardWidth = width * 0.48;
    final cardHeight = mode == CalendarMenuMode.summary ? 200.0 : 140.0;
    const rowGap = 15.0;
    final rects = <Rect>[];
    for (var index = 0; index < 12; index += 1) {
      final row = index ~/ 2;
      final column = index % 2;
      final left = column == 0 ? 0.0 : cardWidth + cardGap;
      final top = row * (cardHeight + rowGap);
      rects.add(Rect.fromLTWH(left, top, cardWidth, cardHeight));
    }
    final totalHeight = 6 * cardHeight + 5 * rowGap;
    return CalendarCanvasLayout(size: Size(width, totalHeight), monthRects: rects);
  }
}
```

- [ ] **Step 4: Implement canvas widget and painter**

Create `lib/features/transactions/widgets/calendar_menu/calendar_canvas.dart`:

```dart
import 'package:flutter/material.dart';

import '../../models/calendar_menu_mode.dart';
import '../../models/calendar_render_models.dart';
import 'calendar_canvas_layout.dart';
import 'calendar_canvas_painter.dart';

class CalendarCanvas extends StatelessWidget {
  const CalendarCanvas({
    super.key,
    required this.data,
    required this.mode,
    required this.thresholdValue,
    required this.heatmapMinValue,
    required this.heatmapCurrentValue,
    required this.onMonthSelected,
  });

  final CalendarYearRenderData data;
  final CalendarMenuMode mode;
  final double thresholdValue;
  final double heatmapMinValue;
  final double heatmapCurrentValue;
  final void Function(int year, int month) onMonthSelected;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth.isFinite ? constraints.maxWidth : MediaQuery.of(context).size.width;
        final layout = CalendarCanvasLayout.calculate(width: width, mode: mode);
        return SingleChildScrollView(
          key: const ValueKey('calendar-canvas-scroll'),
          child: GestureDetector(
            key: const ValueKey('calendar-canvas'),
            onTapUp: (details) {
              for (var i = 0; i < layout.monthRects.length; i += 1) {
                if (layout.monthRects[i].contains(details.localPosition)) {
                  onMonthSelected(data.year, i + 1);
                  return;
                }
              }
            },
            child: RepaintBoundary(
              child: CustomPaint(
                size: layout.size,
                painter: CalendarCanvasPainter(data: data, mode: mode, layout: layout),
              ),
            ),
          ),
        );
      },
    );
  }
}
```

Create `lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart` with focused drawing primitives:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/calendar_menu_mode.dart';
import '../../models/calendar_render_models.dart';
import '../../models/transaction_record.dart';
import 'calendar_canvas_layout.dart';

class CalendarCanvasPainter extends CustomPainter {
  CalendarCanvasPainter({required this.data, required this.mode, required this.layout});

  final CalendarYearRenderData data;
  final CalendarMenuMode mode;
  final CalendarCanvasLayout layout;

  @override
  void paint(Canvas canvas, Size size) {
    for (var i = 0; i < data.months.length; i += 1) {
      _drawMonth(canvas, layout.monthRects[i], data.months[i]);
    }
  }

  void _drawMonth(Canvas canvas, Rect rect, CalendarMonthRenderData month) {
    final rrect = RRect.fromRectAndRadius(rect, const Radius.circular(15));
    canvas.drawShadow(Path()..addRRect(rrect), Colors.black.withValues(alpha: 0.1), 3, true);
    canvas.drawRRect(rrect, Paint()..color = AppColors.gray50);
    canvas.drawRRect(rrect, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = AppColors.gray200);
    canvas.save();
    canvas.clipRRect(rrect);
    if (mode == CalendarMenuMode.summary && month.hasTransactions) {
      final overlay = month.balance >= 0 ? AppColors.income : AppColors.expense;
      canvas.drawRRect(rrect, Paint()..color = overlay.withValues(alpha: 0.1));
    }
    _drawCenteredText(canvas, month.name, Offset(rect.center.dx, rect.top + 14), 12, FontWeight.w600, AppColors.gray800);
    if (mode == CalendarMenuMode.summary && month.hasTransactions) {
      final balanceColor = month.balance >= 0 ? const Color(0xFF059669) : const Color(0xFFDC2626);
      final prefix = month.balance >= 0 ? '+' : '-';
      _drawCenteredText(canvas, '$prefix${formatHuf(month.balance.abs())}', Offset(rect.center.dx, rect.top + 30), 10, FontWeight.w700, balanceColor);
    }
    _drawWeekdays(canvas, rect, month);
    _drawDays(canvas, rect, month);
    canvas.restore();
  }

  void _drawWeekdays(Canvas canvas, Rect rect, CalendarMonthRenderData month) {
    final top = rect.top + (mode == CalendarMenuMode.summary ? 44 : 26);
    final cellWidth = rect.width / 7;
    for (var i = 0; i < month.weekdayLabels.length; i += 1) {
      _drawCenteredText(canvas, month.weekdayLabels[i], Offset(rect.left + cellWidth * i + cellWidth / 2, top), 8, FontWeight.w600, AppColors.gray500);
    }
  }

  void _drawDays(Canvas canvas, Rect rect, CalendarMonthRenderData month) {
    final gridTop = rect.top + (mode == CalendarMenuMode.summary ? 54 : 36);
    final cellWidth = rect.width / 7;
    final cellHeight = (rect.bottom - gridTop - 8) / 6;
    for (final day in month.days) {
      final index = month.leadingBlankDays + day.day - 1;
      final column = index % 7;
      final row = index ~/ 7;
      final cell = Rect.fromLTWH(rect.left + column * cellWidth, gridTop + row * cellHeight, cellWidth, cellHeight);
      _drawDayCell(canvas, cell, day);
    }
  }

  void _drawDayCell(Canvas canvas, Rect cell, CalendarDayRenderData day) {
    final center = cell.center;
    final radius = (cell.shortestSide * 0.38).clamp(3, 11).toDouble();
    var textColor = AppColors.gray500;
    if ((mode == CalendarMenuMode.normal || mode == CalendarMenuMode.summary) && day.isToday) {
      canvas.drawCircle(center, radius, Paint()..color = AppColors.primary);
      textColor = AppColors.white;
    } else if (mode == CalendarMenuMode.normal && day.meetsThreshold) {
      canvas.drawCircle(center, radius, Paint()..style = PaintingStyle.stroke..strokeWidth = 1..color = const Color(0xFF9CA3AF));
    } else if (mode == CalendarMenuMode.category && day.dominantCategoryId != null) {
      canvas.drawCircle(center, radius, Paint()..color = day.dominantCategoryColor);
      textColor = AppColors.white;
    } else if (mode == CalendarMenuMode.heatmap && day.heatmapPercentage > 0) {
      final overlay = RRect.fromRectAndRadius(cell.deflate(2), const Radius.circular(3));
      final percentage = day.heatmapPercentage;
      if (percentage <= 0.15) {
        canvas.drawRRect(overlay, Paint()..color = AppColors.white);
      } else {
        canvas.drawRRect(overlay, Paint()..color = AppColors.primary.withValues(alpha: percentage * 0.8));
        canvas.drawRRect(overlay, Paint()..color = AppColors.white.withValues(alpha: (1 - percentage) * 0.4));
      }
    }
    if (mode == CalendarMenuMode.summary && !day.isToday) {
      if (day.hasIncome) canvas.drawCircle(Offset(cell.left + 4, cell.top + 1), 2.5, Paint()..color = AppColors.income);
      if (day.hasExpense) canvas.drawCircle(Offset(cell.right - 4, cell.top + 1), 2.5, Paint()..color = AppColors.expense);
    }
    _drawCenteredText(canvas, day.day.toString(), center, 10, FontWeight.w600, textColor);
  }

  void _drawCenteredText(Canvas canvas, String text, Offset center, double fontSize, FontWeight weight, Color color) {
    final painter = TextPainter(
      text: TextSpan(text: text, style: TextStyle(fontSize: fontSize, fontWeight: weight, color: color)),
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    )..layout();
    painter.paint(canvas, center - Offset(painter.width / 2, painter.height / 2));
  }

  @override
  bool shouldRepaint(CalendarCanvasPainter oldDelegate) {
    return oldDelegate.data != data || oldDelegate.mode != mode || oldDelegate.layout.size != layout.size;
  }
}
```

- [ ] **Step 5: Run widget tests and commit**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/calendar_menu/calendar_canvas.dart lib/features/transactions/widgets/calendar_menu/calendar_canvas_layout.dart lib/features/transactions/widgets/calendar_menu/calendar_canvas_painter.dart test/transactions/calendar_menu_widgets_test.dart
git commit -m "feat: add calendar canvas painter"
```

---

### Task 6: Calendar Menu Overlay

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Add failing overlay tests**

Append this import:

```dart
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart';
```

Append this test inside `main()`:

```dart
  testWidgets('calendar menu overlay switches modes and shows matching title and controls', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarMenuOverlay(
              transactions: const [],
              categories: const [],
              onClose: () {},
              onMonthSelect: (_, __) {},
            ),
          ),
        ),
      ),
    );

    expect(find.text('Küszöbérték nézet'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-threshold-slider')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-heatmap')));
    await tester.pumpAndSettle();
    expect(find.text('Hőtérkép'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('calendar-mode-category')));
    await tester.pumpAndSettle();
    expect(find.text('Domináns kategória'), findsOneWidget);
    expect(find.byKey(const ValueKey('calendar-heatmap-slider')), findsNothing);
  });
```

- [ ] **Step 2: Run overlay test and verify it fails**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: FAIL with missing overlay implementation.

- [ ] **Step 3: Implement the overlay**

Create `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`:

```dart
import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../data/calendar_render_builder.dart';
import '../../models/calendar_menu_mode.dart';
import '../../models/transaction_category.dart';
import '../../models/transaction_record.dart';
import 'calendar_canvas.dart';
import 'calendar_mode_selector.dart';
import 'calendar_value_slider_panel.dart';

class CalendarMenuOverlay extends StatefulWidget {
  const CalendarMenuOverlay({
    super.key,
    required this.transactions,
    required this.categories,
    required this.onClose,
    required this.onMonthSelect,
  });

  final List<TransactionRecord> transactions;
  final List<TransactionCategory> categories;
  final VoidCallback onClose;
  final void Function(int year, int month) onMonthSelect;

  @override
  State<CalendarMenuOverlay> createState() => _CalendarMenuOverlayState();
}

class _CalendarMenuOverlayState extends State<CalendarMenuOverlay> {
  var _year = DateTime.now().year;
  var _mode = CalendarMenuMode.normal;
  var _transitionLocked = false;
  var _thresholdValue = 1000.0;
  var _heatmapMinValue = 0.0;
  var _heatmapCurrentValue = 10000.0;
  var _heatmapMaxValue = 50000.0;
  double? _customThresholdMin;
  double? _customThresholdMax;

  @override
  Widget build(BuildContext context) {
    final data = CalendarRenderBuilder.buildYear(
      year: _year,
      transactions: widget.transactions,
      categories: widget.categories,
      thresholdValue: _thresholdValue,
      heatmapMinValue: _heatmapMinValue,
      heatmapCurrentValue: _heatmapCurrentValue,
      customThresholdMin: _customThresholdMin,
      customThresholdMax: _customThresholdMax,
    );
    return Positioned.fill(
      child: Stack(
        children: [
          Positioned.fill(child: GestureDetector(onTap: widget.onClose, child: Container(color: Colors.transparent))),
          Positioned(
            key: const ValueKey('calendar-menu-overlay'),
            top: 286,
            left: 0,
            right: 0,
            bottom: 0,
            child: Material(
              color: AppColors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
                  border: Border.all(color: AppColors.gray200),
                ),
                child: Stack(
                  children: [
                    Column(
                      children: [
                        SizedBox(
                          height: 50,
                          child: Row(
                            children: [
                              const SizedBox(width: 100),
                              Expanded(child: _YearNavigator(year: _year, onPrevious: () => setState(() => _year -= 1), onNext: () => setState(() => _year += 1))),
                              CalendarModeSelector(activeMode: _mode, transitionLocked: _transitionLocked, onModeChanged: _setMode),
                              const SizedBox(width: 12),
                            ],
                          ),
                        ),
                        Text(_mode.title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.gray800)),
                        const SizedBox(height: 8),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 20),
                            child: CalendarCanvas(
                              data: data,
                              mode: _mode,
                              thresholdValue: _thresholdValue,
                              heatmapMinValue: _heatmapMinValue,
                              heatmapCurrentValue: _heatmapCurrentValue,
                              onMonthSelected: widget.onMonthSelect,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_mode == CalendarMenuMode.normal && data.thresholdRange.min != data.thresholdRange.max)
                      CalendarValueSliderPanel.threshold(
                        value: _thresholdValue,
                        min: data.thresholdRange.min,
                        max: data.thresholdRange.max,
                        onChanged: (value) => setState(() => _thresholdValue = value),
                        onMinChanged: (value) => setState(() => _customThresholdMin = value < 0 ? 0 : value),
                        onMaxChanged: (value) => setState(() => _customThresholdMax = value <= data.thresholdRange.min ? data.thresholdRange.min + 1 : value),
                      ),
                    if (_mode == CalendarMenuMode.heatmap)
                      CalendarValueSliderPanel.heatmap(
                        value: _heatmapCurrentValue,
                        min: _heatmapMinValue,
                        max: _heatmapMaxValue,
                        onChanged: (value) => setState(() => _heatmapCurrentValue = value),
                        onMinChanged: (value) => setState(() => _heatmapMinValue = value < 0 ? 0 : value),
                        onMaxChanged: (value) => setState(() => _heatmapMaxValue = value <= _heatmapMinValue ? _heatmapMinValue + 1000 : value),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _setMode(CalendarMenuMode mode) {
    if (_transitionLocked || mode == _mode) return;
    setState(() {
      _transitionLocked = true;
      _mode = mode;
    });
    Future<void>.delayed(const Duration(milliseconds: 300), () {
      if (mounted) setState(() => _transitionLocked = false);
    });
  }
}

class _YearNavigator extends StatelessWidget {
  const _YearNavigator({required this.year, required this.onPrevious, required this.onNext});

  final int year;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(key: const ValueKey('calendar-prev-year'), onPressed: onPrevious, icon: const Icon(Icons.chevron_left, color: AppColors.gray500), iconSize: 24),
        Text('$year', style: const TextStyle(color: AppColors.gray800, fontSize: 16, fontWeight: FontWeight.w600)),
        IconButton(key: const ValueKey('calendar-next-year'), onPressed: onNext, icon: const Icon(Icons.chevron_right, color: AppColors.gray500), iconSize: 24),
      ],
    );
  }
}
```

- [ ] **Step 4: Run overlay tests and commit**

Run: `flutter test test/transactions/calendar_menu_widgets_test.dart`

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart test/transactions/calendar_menu_widgets_test.dart
git commit -m "feat: add calendar menu overlay"
```

---

### Task 7: Header And Home Integration

**Files:**
- Modify: `lib/features/transactions/widgets/header_card/transaction_header_card.dart`
- Modify: `lib/features/transactions/transaction_home_page.dart`
- Modify: `test/transactions/header_card_test.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Add failing header callback assertion**

Modify `test/transactions/header_card_test.dart` so it tracks the calendar callback:

```dart
var calendarPressed = false;
```

Pass the callback into the header:

```dart
onCalendarPressed: () => calendarPressed = true,
```

Tap and assert it:

```dart
await tester.tap(find.byKey(const ValueKey('header-calendar-button')));
expect(calendarPressed, isTrue);
```

- [ ] **Step 2: Run the header test and verify it fails**

Run: `flutter test test/transactions/header_card_test.dart`

Expected: FAIL because `TransactionHeaderCard` has no `onCalendarPressed` parameter.

- [ ] **Step 3: Wire the header callback**

Modify `TransactionHeaderCard` constructor and fields:

```dart
required this.onCalendarPressed,
```

```dart
final VoidCallback onCalendarPressed;
```

Change the existing calendar icon button:

```dart
onPressed: onCalendarPressed,
```

- [ ] **Step 4: Integrate overlay state in home page**

Modify `lib/features/transactions/transaction_home_page.dart`:

Add state:

```dart
var _calendarOpen = false;
```

Pass the callback to the header:

```dart
onCalendarPressed: _openCalendarMenu,
```

Add the overlay after the header and before category overlay:

```dart
if (_calendarOpen)
  CalendarMenuOverlay(
    transactions: widget.store.transactions,
    categories: widget.store.categories,
    onClose: _closeCalendarMenu,
    onMonthSelect: (_, __) {},
  ),
```

Add import:

```dart
import 'widgets/calendar_menu/calendar_menu_overlay.dart';
```

Add methods:

```dart
void _openCalendarMenu() {
  setState(() {
    _headerExpanded = false;
    _categoryMode = null;
    _editingCategory = null;
    _calendarOpen = true;
  });
}

void _closeCalendarMenu() {
  setState(() => _calendarOpen = false);
}
```

Update `_setActiveType` to close the calendar:

```dart
_calendarOpen = false;
```

- [ ] **Step 5: Add home integration widget test**

Append this test in `test/transactions/calendar_menu_widgets_test.dart` after adding imports for repository/store/home:

```dart
  testWidgets('home calendar button opens calendar overlay', (tester) async {
    final store = TransactionStore(CalendarHomeRepository());
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(width: 390, height: 780, child: TransactionHomePage(store: store)),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('header-calendar-button')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('calendar-menu-overlay')), findsOneWidget);
    expect(find.text('Küszöbérték nézet'), findsOneWidget);
  });
```

Add a repository fixture at the bottom of `calendar_menu_widgets_test.dart`:

```dart
class CalendarHomeRepository implements TransactionRepositoryContract {
  @override
  Future<TransactionBootstrap> loadBootstrap() async => TransactionBootstrap(
    categories: const [],
    transactions: const [],
    limits: const [],
  );

  @override
  Future<TransactionRecord> addTransaction(Map<String, Object?> payload) async => throw UnimplementedError();

  @override
  Future<TransactionCategory> addCategory(Map<String, Object?> payload) async => throw UnimplementedError();

  @override
  Future<TransactionCategory> updateCategory(int id, Map<String, Object?> payload) async => throw UnimplementedError();

  @override
  Future<bool> deleteCategory(int id) async => throw UnimplementedError();

  @override
  Future<Map<int, int>> categoryCounts() async => const {};

  @override
  Future<List<CategoryLimit>> listCategoryLimits({String? transactionType, String? window, String? periodKey}) async => const [];

  @override
  Future<CategoryLimit> upsertCategoryLimit(Map<String, Object?> payload) async => throw UnimplementedError();
}
```

The test file will need these imports:

```dart
import 'package:exptv2/features/transactions/data/transaction_repository.dart';
import 'package:exptv2/features/transactions/models/category_limit.dart';
import 'package:exptv2/features/transactions/models/transaction_category.dart';
import 'package:exptv2/features/transactions/models/transaction_record.dart';
import 'package:exptv2/features/transactions/state/transaction_store.dart';
import 'package:exptv2/features/transactions/transaction_home_page.dart';
```

- [ ] **Step 6: Run integration tests and commit**

Run:

```bash
flutter test test/transactions/header_card_test.dart test/transactions/calendar_menu_widgets_test.dart
```

Expected: PASS.

Commit:

```bash
git add lib/features/transactions/widgets/header_card/transaction_header_card.dart lib/features/transactions/transaction_home_page.dart test/transactions/header_card_test.dart test/transactions/calendar_menu_widgets_test.dart
git commit -m "feat: wire calendar menu into header"
```

---

### Task 8: Full Verification, Push, And Online Build

**Files:**
- Modify only files touched by previous tasks if verification exposes compile or analyzer failures.

- [ ] **Step 1: Run formatter**

Run:

```bash
dart format lib/features/transactions/models/calendar_menu_mode.dart lib/features/transactions/models/calendar_render_models.dart lib/features/transactions/data/calendar_render_builder.dart lib/features/transactions/widgets/calendar_menu test/transactions/calendar_render_builder_test.dart test/transactions/calendar_menu_widgets_test.dart test/transactions/header_card_test.dart lib/features/transactions/transaction_home_page.dart lib/features/transactions/widgets/header_card/transaction_header_card.dart
```

Expected: files formatted. In Termux, if local Dart is unavailable, rely on GitHub Actions for final build verification and record that local format could not run.

- [ ] **Step 2: Run focused tests locally when the local Flutter binary works**

Run:

```bash
flutter test test/transactions/calendar_render_builder_test.dart test/transactions/calendar_menu_widgets_test.dart test/transactions/header_card_test.dart
```

Expected: PASS. In Termux, if local Flutter/Dart fails because of the known Bionic TLS issue, continue to GitHub Actions and record the local blocker.

- [ ] **Step 3: Run full test suite when the local Flutter binary works**

Run:

```bash
flutter test
```

Expected: PASS. In Termux, if local Flutter/Dart fails because of the known Bionic TLS issue, continue to GitHub Actions and record the local blocker.

- [ ] **Step 4: Commit any verification fixes**

If formatting or tests required changes, commit them:

```bash
git add lib test
git commit -m "fix: stabilize calendar menu tests"
```

If there are no changes, do not create an empty commit.

- [ ] **Step 5: Push to GitHub**

Run:

```bash
git push origin main
```

Expected: push succeeds.

- [ ] **Step 6: Watch the online Android APK build**

Run:

```bash
gh run list --repo elizerpist/exptv2 --workflow android-build.yml --branch main --limit 1 --json databaseId,status,conclusion,headSha,url
```

Then watch the returned run:

```bash
gh run watch <databaseId> --repo elizerpist/exptv2 --exit-status
```

Expected: workflow conclusion `success`, with `Analyze Dart code`, `Run Flutter tests`, `Build debug APK`, and `Upload debug APK` all successful.

- [ ] **Step 7: Confirm APK artifact**

Run:

```bash
gh api repos/elizerpist/exptv2/actions/runs/<databaseId>/artifacts --jq '.artifacts[] | {name, size_in_bytes, expired}'
```

Expected: artifact named `exptv2-debug-apk`, `expired: false`.

---

## Spec Coverage Self-Review

- Header calendar button and slide-up menu: Task 7 and Task 6.
- Menu header, year navigation, selector, title, slider panels: Task 6, Task 3, Task 4.
- Four modes and original accented Hungarian labels: Task 1, Task 3, Task 6.
- One canvas for all month cards and day cells: Task 5.
- Normal threshold, summary indicators, heatmap overlay, category dominant color: Task 2 and Task 5.
- Read data from current `TransactionStore`: Task 7.
- No database/Kotlin/push scraper changes: file structure section and Task 7 keep scope isolated.
- Verification and GitHub artifact: Task 8.
