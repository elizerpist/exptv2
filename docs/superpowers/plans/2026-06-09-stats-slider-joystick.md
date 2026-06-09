# Stats Slider Joystick Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Replace the stats slider sheet with a long-press joystick mini trigger that uses a temporary floating value card, adaptive range, quantized stepping, and restrained haptics.

**Architecture:** Keep the feature inside the existing calendar menu surface. Add a focused range helper for adaptive financial scale calculations, then convert `CalendarValueSliderPanel` from expand/collapse sheet behavior into a mini joystick control that still calls the existing `onChanged` callbacks owned by `CalendarMenuOverlay`.

**Tech Stack:** Flutter/Dart, existing `CalendarMenuOverlay`, existing widget tests, `HapticFeedback`, GitHub Actions debug APK release workflow.

---

## File Structure

- Create `lib/features/transactions/widgets/calendar_menu/calendar_joystick_range.dart`
  - Owns adaptive range, nice max, nice step, snapping, and clamping.
  - Pure Dart logic so it is easy to test.
- Modify `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`
  - Replaces the large sheet UI with joystick mini trigger and temporary floating card.
  - Owns gesture state, timer tick loop, fade state, and haptic throttling.
- Modify `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
  - Passes observed data max into the joystick for threshold and heatmap modes.
  - Removes min/max edit callbacks from the normal stats path.
- Modify `test/transactions/calendar_menu_widgets_test.dart`
  - Replaces old open-sheet tests with joystick behavior tests.
  - Adds haptic channel assertions.
- Add `test/transactions/calendar_joystick_range_test.dart`
  - Covers adaptive max, empty data fallback, nice step, snap, and clamp behavior.

Implementation must happen on branch `stats-joystick`.

---

### Task 1: Create The `stats-joystick` Branch

**Files:**
- No file changes.

- [ ] **Step 1: Confirm clean worktree**

Run:

```bash
git status --short
```

Expected: no output.

- [ ] **Step 2: Create branch from current main**

Run:

```bash
git switch -c stats-joystick
```

Expected: `Switched to a new branch 'stats-joystick'`.

- [ ] **Step 3: Confirm branch**

Run:

```bash
git branch --show-current
```

Expected:

```text
stats-joystick
```

---

### Task 2: Adaptive Joystick Range Helper

**Files:**
- Create: `lib/features/transactions/widgets/calendar_menu/calendar_joystick_range.dart`
- Add: `test/transactions/calendar_joystick_range_test.dart`

- [ ] **Step 1: Write the failing range helper tests**

Create `test/transactions/calendar_joystick_range_test.dart`:

```dart
import 'package:exptv2/features/transactions/widgets/calendar_menu/calendar_joystick_range.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CalendarJoystickRange', () {
    test('uses zero min and rounds observed max to a readable ceiling', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 12000,
        observedMax: 38200,
        fallbackMax: 50000,
      );

      expect(range.min, 0);
      expect(range.max, 50000);
      expect(range.step, 1000);
    });

    test('keeps current value inside the adaptive range even above observed max', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 120000,
        observedMax: 38000,
        fallbackMax: 50000,
      );

      expect(range.max, 250000);
      expect(range.clamp(300000), 250000);
    });

    test('falls back when there is no observed data', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 0,
        observedMax: 0,
        fallbackMax: 50000,
      );

      expect(range.max, 50000);
      expect(range.step, 1000);
    });

    test('snaps to the adaptive step and clamps to boundaries', () {
      final range = CalendarJoystickRange.adaptive(
        currentValue: 1000,
        observedMax: 22000,
        fallbackMax: 50000,
      );

      expect(range.snap(1499), 1000);
      expect(range.snap(1501), 2000);
      expect(range.clamp(-100), 0);
      expect(range.clamp(range.max + range.step), range.max);
    });
  });
}
```

- [ ] **Step 2: Run the helper test and verify it fails**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_joystick_range_test.dart'
```

Expected: FAIL because `calendar_joystick_range.dart` does not exist.

- [ ] **Step 3: Implement the helper**

Create `lib/features/transactions/widgets/calendar_menu/calendar_joystick_range.dart`:

```dart
import 'dart:math' as math;

class CalendarJoystickRange {
  const CalendarJoystickRange({
    required this.min,
    required this.max,
    required this.step,
  });

  factory CalendarJoystickRange.adaptive({
    required double currentValue,
    required double observedMax,
    required double fallbackMax,
  }) {
    const min = 0.0;
    final safeFallback = fallbackMax > min ? fallbackMax : 50000.0;
    final sourceMax = math.max(currentValue, observedMax);
    final rawMax = sourceMax > min ? sourceMax * 1.2 : safeFallback;
    final max = _niceCeil(rawMax);
    final step = _niceStep(max / 80);
    return CalendarJoystickRange(min: min, max: max, step: step);
  }

  final double min;
  final double max;
  final double step;

  double clamp(double value) => value.clamp(min, max).toDouble();

  double snap(double value) {
    final snapped = (value / step).round() * step;
    return clamp(snapped.toDouble());
  }

  static double _niceCeil(double value) {
    if (value <= 0) return 50000;
    final exponent = math.pow(10, value.log10Floor()).toDouble();
    final normalized = value / exponent;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2.5
            ? 2.5
            : normalized <= 5
                ? 5
                : 10;
    return nice * exponent;
  }

  static double _niceStep(double value) {
    if (value <= 100) return 100;
    final exponent = math.pow(10, value.log10Floor()).toDouble();
    final normalized = value / exponent;
    final nice = normalized <= 1
        ? 1
        : normalized <= 2
            ? 2
            : normalized <= 5
                ? 5
                : 10;
    return nice * exponent;
  }
}

extension on double {
  int log10Floor() => math.log(this).toIntLog10Floor();
}

extension on num {
  int toIntLog10Floor() {
    final value = this / math.ln10;
    return value.floor();
  }
}
```

- [ ] **Step 4: Run the helper test and fix compile issues**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_joystick_range_test.dart'
```

Expected: PASS.

- [ ] **Step 5: Commit helper**

Run:

```bash
git add lib/features/transactions/widgets/calendar_menu/calendar_joystick_range.dart test/transactions/calendar_joystick_range_test.dart
git commit -m "Add adaptive calendar joystick range"
```

Expected: commit succeeds.

---

### Task 3: Joystick Widget Tests

**Files:**
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Replace old sheet tests with joystick tests**

In `test/transactions/calendar_menu_widgets_test.dart`, replace these tests:

- `threshold slider panel edits collapses and drags as category filter`
- `heatmap slider panel shows editable and compact controls`
- `calendar overlay slider card stays draggable after leaving bottom area`
- `threshold slider drag does not rebuild calendar render data`

with:

```dart
  testWidgets('threshold joystick long press shows floating value card', (
    tester,
  ) async {
    var changed = 1000.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarValueSliderPanel.threshold(
              value: 1000,
              observedMax: 22000,
              fallbackMax: 50000,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(
      const ValueKey('calendar-threshold-joystick-trigger'),
    );
    expect(trigger, findsOneWidget);
    expect(
      find.byKey(const ValueKey('calendar-threshold-joystick-value-card')),
      findsNothing,
    );

    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 60));
    expect(
      find.byKey(const ValueKey('calendar-threshold-joystick-value-card')),
      findsOneWidget,
    );
    expect(find.text('1 000 Ft'), findsOneWidget);

    await gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 220));
    expect(changed, greaterThan(1000));

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 700));
    expect(
      find.byKey(const ValueKey('calendar-threshold-joystick-value-card')),
      findsNothing,
    );
  });

  testWidgets('heatmap joystick supports downward drag and boundary label', (
    tester,
  ) async {
    var changed = 10000.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarValueSliderPanel.heatmap(
              value: 10000,
              observedMax: 50000,
              fallbackMax: 50000,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(
      const ValueKey('calendar-heatmap-joystick-trigger'),
    );
    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 60));
    await gesture.moveBy(const Offset(0, 180));
    await tester.pump(const Duration(milliseconds: 900));

    expect(changed, 0);
    expect(find.text('Min 0 Ft'), findsOneWidget);

    await gesture.up();
    await tester.pump(const Duration(milliseconds: 700));
  });

  testWidgets('joystick dead zone prevents accidental value changes', (
    tester,
  ) async {
    var changed = 1000.0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarValueSliderPanel.threshold(
              value: 1000,
              observedMax: 22000,
              fallbackMax: 50000,
              onChanged: (value) => changed = value,
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(
      const ValueKey('calendar-threshold-joystick-trigger'),
    );
    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 60));
    await gesture.moveBy(const Offset(0, -6));
    await tester.pump(const Duration(milliseconds: 240));

    expect(changed, 1000);

    await gesture.up();
    await tester.pumpAndSettle();
  });

  testWidgets('joystick haptics activate and tick without frame spam', (
    tester,
  ) async {
    final hapticCalls = <MethodCall>[];
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (call) async {
      if (call.method == 'HapticFeedback.vibrate') hapticCalls.add(call);
      return null;
    });
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(SystemChannels.platform, null);
    });

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarValueSliderPanel.threshold(
              value: 1000,
              observedMax: 22000,
              fallbackMax: 50000,
              onChanged: (_) {},
            ),
          ),
        ),
      ),
    );

    final trigger = find.byKey(
      const ValueKey('calendar-threshold-joystick-trigger'),
    );
    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 60));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 260));
    await gesture.up();

    expect(
      hapticCalls.map((call) => call.arguments),
      contains('HapticFeedbackType.mediumImpact'),
    );
    expect(
      hapticCalls.map((call) => call.arguments),
      contains('HapticFeedbackType.selectionClick'),
    );
    expect(hapticCalls.length, lessThan(8));
  });
```

Add these imports near the top:

```dart
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
```

- [ ] **Step 2: Run widget tests and verify they fail**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_menu_widgets_test.dart'
```

Expected: FAIL because `observedMax`, `fallbackMax`, and joystick keys do not exist yet.

---

### Task 4: Implement Joystick Control

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart`

- [ ] **Step 1: Replace imports and constructors**

At the top of `calendar_value_slider_panel.dart`, replace imports with:

```dart
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';
import '../../models/transaction_record.dart';
import 'calendar_joystick_range.dart';
```

Replace `CalendarValueSliderPanel` with:

```dart
enum CalendarSliderKind { threshold, heatmap }

class CalendarValueSliderPanel extends StatefulWidget {
  const CalendarValueSliderPanel.threshold({
    super.key,
    required this.value,
    required this.observedMax,
    required this.fallbackMax,
    required this.onChanged,
  }) : kind = CalendarSliderKind.threshold;

  const CalendarValueSliderPanel.heatmap({
    super.key,
    required this.value,
    required this.observedMax,
    required this.fallbackMax,
    required this.onChanged,
  }) : kind = CalendarSliderKind.heatmap;

  final CalendarSliderKind kind;
  final double value;
  final double observedMax;
  final double fallbackMax;
  final ValueChanged<double> onChanged;

  @override
  State<CalendarValueSliderPanel> createState() =>
      _CalendarValueSliderPanelState();
}
```

- [ ] **Step 2: Replace state fields and constants**

Replace `_CalendarValueSliderPanelState` fields with:

```dart
class _CalendarValueSliderPanelState extends State<CalendarValueSliderPanel> {
  static const _deadZone = 10.0;
  static const _tickInterval = Duration(milliseconds: 90);
  static const _fadeDelay = Duration(milliseconds: 600);
  static const _minimumHapticGap = Duration(milliseconds: 100);

  Timer? _tickTimer;
  Timer? _fadeTimer;
  var _active = false;
  var _showValueCard = false;
  var _dragOffsetY = 0.0;
  var _currentValue = 0.0;
  double? _lastTickHapticValue;
  _JoystickBoundary? _lastBoundaryHaptic;
  DateTime? _lastSelectionHapticAt;
```

Add the private enum after the state class:

```dart
enum _JoystickBoundary { min, max }
```

- [ ] **Step 3: Replace `build` with joystick UI**

Replace the current `build` method with:

```dart
  @override
  Widget build(BuildContext context) {
    final sliderKey = _sliderKey;
    final displayValue = _range.clamp(_currentValueOrWidgetValue);
    final boundaryLabel = _boundaryLabel(displayValue);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        if (_showValueCard)
          Align(
            alignment: Alignment.bottomRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(0, 0, 76, 120),
              child: AnimatedOpacity(
                key: ValueKey('$sliderKey-joystick-value-card'),
                opacity: _showValueCard ? 1 : 0,
                duration: const Duration(milliseconds: 140),
                child: Material(
                  color: AppColors.white,
                  elevation: 8,
                  shadowColor: Colors.black.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 104),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.gray200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      boundaryLabel ?? formatHuf(displayValue),
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.gray800,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        Align(
          alignment: Alignment.bottomRight,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 0, 20, 112),
            child: GestureDetector(
              key: ValueKey('$sliderKey-joystick-trigger'),
              behavior: HitTestBehavior.opaque,
              onLongPressStart: _handleLongPressStart,
              onLongPressMoveUpdate: _handleLongPressMoveUpdate,
              onLongPressEnd: (_) => _finishJoystick(),
              onLongPressCancel: _finishJoystick,
              child: Material(
                color: _active ? AppColors.primary : AppColors.gray800,
                elevation: 7,
                shadowColor: Colors.black.withValues(alpha: 0.16),
                borderRadius: BorderRadius.circular(99),
                child: const SizedBox(
                  width: 38,
                  height: 38,
                  child: Icon(Icons.tune, color: AppColors.white, size: 18),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
```

- [ ] **Step 4: Add computed properties and gesture methods**

Add these methods inside `_CalendarValueSliderPanelState`:

```dart
  String get _sliderKey => widget.kind == CalendarSliderKind.threshold
      ? 'calendar-threshold'
      : 'calendar-heatmap';

  CalendarJoystickRange get _range => CalendarJoystickRange.adaptive(
        currentValue: widget.value,
        observedMax: widget.observedMax,
        fallbackMax: widget.fallbackMax,
      );

  double get _currentValueOrWidgetValue => _active ? _currentValue : widget.value;

  void _handleLongPressStart(LongPressStartDetails details) {
    _fadeTimer?.cancel();
    _currentValue = _range.snap(widget.value);
    _dragOffsetY = 0;
    _lastTickHapticValue = _currentValue;
    _lastBoundaryHaptic = null;
    setState(() {
      _active = true;
      _showValueCard = true;
    });
    unawaited(HapticFeedback.mediumImpact());
    _tickTimer?.cancel();
    _tickTimer = Timer.periodic(_tickInterval, (_) => _applyJoystickTick());
  }

  void _handleLongPressMoveUpdate(LongPressMoveUpdateDetails details) {
    _dragOffsetY = details.offsetFromOrigin.dy;
  }

  void _finishJoystick() {
    _tickTimer?.cancel();
    _tickTimer = null;
    if (!_active) return;
    setState(() => _active = false);
    _fadeTimer?.cancel();
    _fadeTimer = Timer(_fadeDelay, () {
      if (mounted) setState(() => _showValueCard = false);
    });
  }

  void _applyJoystickTick() {
    if (!_active || _dragOffsetY.abs() <= _deadZone) return;
    final range = _range;
    final direction = _dragOffsetY < 0 ? 1 : -1;
    final speed = _speedForOffset(_dragOffsetY.abs());
    final next = range.snap(_currentValue + direction * range.step * speed);
    if (next == _currentValue) {
      _handleBoundaryHaptic(next);
      return;
    }
    setState(() => _currentValue = next);
    widget.onChanged(next);
    _handleTickHaptic(next);
    _handleBoundaryHaptic(next);
  }

  int _speedForOffset(double distance) {
    if (distance >= 140) return 5;
    if (distance >= 90) return 3;
    return 1;
  }

  String? _boundaryLabel(double value) {
    final range = _range;
    if (value <= range.min) return 'Min ${formatHuf(range.min)}';
    if (value >= range.max) return 'Max ${formatHuf(range.max)}';
    return null;
  }

  void _handleTickHaptic(double value) {
    if (_lastTickHapticValue == value) return;
    final now = DateTime.now();
    final last = _lastSelectionHapticAt;
    if (last != null && now.difference(last) < _minimumHapticGap) return;
    _lastTickHapticValue = value;
    _lastSelectionHapticAt = now;
    unawaited(HapticFeedback.selectionClick());
  }

  void _handleBoundaryHaptic(double value) {
    final range = _range;
    final boundary = value <= range.min
        ? _JoystickBoundary.min
        : value >= range.max
            ? _JoystickBoundary.max
            : null;
    if (boundary == null) {
      _lastBoundaryHaptic = null;
      return;
    }
    if (_lastBoundaryHaptic == boundary) return;
    _lastBoundaryHaptic = boundary;
    unawaited(HapticFeedback.mediumImpact());
  }
```

- [ ] **Step 5: Add lifecycle cleanup and remove old sheet-only classes**

Add:

```dart
  @override
  void didUpdateWidget(covariant CalendarValueSliderPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_active && oldWidget.value != widget.value) {
      _currentValue = widget.value;
    }
  }

  @override
  void dispose() {
    _tickTimer?.cancel();
    _fadeTimer?.cancel();
    super.dispose();
  }
```

Remove these old members/classes from `calendar_value_slider_panel.dart`:

- `_collapsed`
- `_verticalOffset`
- `_handleDragUpdate`
- `_collapse`
- `_expand`
- `_MiniButton`
- `_EditableLimitText`
- `_EditableLimitTextState`
- `DebugTextField` import

- [ ] **Step 6: Run joystick widget tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_menu_widgets_test.dart'
```

Expected: the new joystick tests compile. Some overlay tests may still fail until Task 5 updates call sites.

---

### Task 5: Overlay Integration And Observed Max

**Files:**
- Modify: `lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart`
- Modify: `test/transactions/calendar_menu_widgets_test.dart`

- [ ] **Step 1: Update `CalendarValueSliderPanel` call sites**

In `calendar_menu_overlay.dart`, replace the threshold panel call with:

```dart
                    return CalendarValueSliderPanel.threshold(
                      value: threshold,
                      observedMax: data.thresholdRange.max,
                      fallbackMax: 50000,
                      onChanged: (value) => _thresholdValue.value = value,
                    );
```

Replace the heatmap panel call with:

```dart
                        return CalendarValueSliderPanel.heatmap(
                          value: heatmapCurrent,
                          observedMax: _observedMaxExpense(data),
                          fallbackMax: heatmapMax,
                          onChanged: (value) {
                            _heatmapCurrentValue.value = value;
                          },
                        );
```

- [ ] **Step 2: Remove obsolete min/max mutation callbacks**

Delete the old `onMinChanged` and `onMaxChanged` callback blocks from the threshold and heatmap panel call sites. Leave `_customThresholdMin`, `_customThresholdMax`, `_heatmapMinValue`, and `_heatmapMaxValue` fields in place only if other code still reads them; do not add a custom range UI in this task.

- [ ] **Step 3: Add observed max helper**

Inside `_CalendarMenuOverlayState`, add:

```dart
  double _observedMaxExpense(CalendarYearRenderData data) {
    var maxExpense = 0.0;
    for (final month in data.months) {
      for (final day in month.days) {
        if (day.expense > maxExpense) maxExpense = day.expense;
      }
    }
    return maxExpense;
  }
```

- [ ] **Step 4: Update overlay expectations in tests**

In `test/transactions/calendar_menu_widgets_test.dart`, update assertions that looked for slider keys:

Replace:

```dart
find.byKey(const ValueKey('calendar-threshold-slider'))
```

with:

```dart
find.byKey(const ValueKey('calendar-threshold-joystick-trigger'))
```

Replace:

```dart
find.byKey(const ValueKey('calendar-heatmap-slider'))
```

with:

```dart
find.byKey(const ValueKey('calendar-heatmap-joystick-trigger'))
```

Do this in the dropdown/focused-month tests and any remaining stats page tests.

- [ ] **Step 5: Add overlay no-rebuild joystick test**

Add this test near the old no-rebuild test location:

```dart
  testWidgets('threshold joystick drag does not rebuild calendar render data', (
    tester,
  ) async {
    final year = DateTime.now().year;
    DebugConsole.clear();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 390,
            height: 780,
            child: CalendarMenuOverlay(
              fullScreen: true,
              transactions: [
                _record(
                  id: 1,
                  date: '$year-01-02',
                  amount: -8000,
                  categoryId: 1,
                ),
                _record(
                  id: 2,
                  date: '$year-01-03',
                  amount: -22000,
                  categoryId: 1,
                ),
              ],
              categories: const [
                TransactionCategory(
                  transactionCategoryID: 1,
                  name: 'Élelmiszer',
                  type: 'kiadás',
                  colorSlot: 1,
                  iconSlot: null,
                  backgroundColor: null,
                  icon: null,
                  notification: null,
                  hasLimit: false,
                  limitAmount: 0,
                  alertActive: false,
                  isCustomIcon: false,
                  originalIcon: null,
                ),
              ],
              onClose: () {},
              onMonthSelect: (_, _) {},
            ),
          ),
        ),
      ),
    );

    expect(
      DebugConsole.allText,
      contains('[Perf] CalendarRender build source=overlay'),
    );

    DebugConsole.clear();
    final trigger = find.byKey(
      const ValueKey('calendar-threshold-joystick-trigger'),
    );
    final gesture = await tester.startGesture(tester.getCenter(trigger));
    await tester.pump(kLongPressTimeout + const Duration(milliseconds: 60));
    await gesture.moveBy(const Offset(0, -120));
    await tester.pump(const Duration(milliseconds: 220));
    await gesture.up();

    expect(
      DebugConsole.allText,
      isNot(contains('[Perf] CalendarRender build source=overlay')),
    );
  });
```

- [ ] **Step 6: Run calendar widget tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_menu_widgets_test.dart test/transactions/calendar_joystick_range_test.dart'
```

Expected: PASS.

- [ ] **Step 7: Commit overlay integration**

Run:

```bash
git add lib/features/transactions/widgets/calendar_menu/calendar_value_slider_panel.dart lib/features/transactions/widgets/calendar_menu/calendar_menu_overlay.dart test/transactions/calendar_menu_widgets_test.dart
git commit -m "Replace stats slider sheet with joystick control"
```

Expected: commit succeeds.

---

### Task 6: Full Relevant Verification

**Files:**
- No planned code changes.

- [ ] **Step 1: Run focused transaction tests**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/transactions/calendar_menu_widgets_test.dart test/transactions/calendar_joystick_range_test.dart test/transactions/calendar_render_builder_test.dart'
```

Expected: PASS.

- [ ] **Step 2: Run app smoke widget test**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter test test/widget_test.dart'
```

Expected: PASS.

- [ ] **Step 3: Run analyzer if local Flutter works**

Run:

```bash
proot-distro login ubuntu --user flutteruser -- bash -lc 'cd /data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/exptv2 && /home/flutteruser/flutter/bin/flutter analyze'
```

Expected: PASS. If the local Flutter binary fails due Termux/Android environment issues, record the exact failure and rely on GitHub Actions for analyzer/build.

- [ ] **Step 4: Confirm no local APK build was run**

Run:

```bash
git status --short
```

Expected: no APK build output or unrelated generated files in the worktree.

---

### Task 7: Push And Online APK Build

**Files:**
- No planned code changes.

- [ ] **Step 1: Confirm branch and commits**

Run:

```bash
git branch --show-current
git log --oneline -3
git status --short
```

Expected:

```text
stats-joystick
```

and a clean worktree.

- [ ] **Step 2: Push branch to GitHub**

Run:

```bash
git push -u origin stats-joystick
```

Expected: branch is pushed to `https://github.com/elizerpist/exptv2.git`.

- [ ] **Step 3: Start GitHub Actions APK build on the branch**

Run:

```bash
gh workflow run android-build.yml --ref stats-joystick
```

Expected: workflow dispatch succeeds.

- [ ] **Step 4: Watch the online build**

Run:

```bash
gh run list --workflow android-build.yml --branch stats-joystick --limit 1
```

Copy the newest run id, then run:

```bash
gh run watch <run-id> --exit-status
```

Expected: the run completes successfully. The workflow publishes `exptv2-debug.apk` to the `debug-latest` GitHub Release.

- [ ] **Step 5: Verify direct APK release link**

Run:

```bash
gh release view debug-latest --json assets,url --jq '.url, (.assets[] | select(.name=="exptv2-debug.apk") | .url)'
```

Expected: output includes a release URL and an asset URL.

Final direct APK download link to provide to the user:

```text
https://github.com/elizerpist/exptv2/releases/download/debug-latest/exptv2-debug.apk
```

- [ ] **Step 6: Final response**

Report:

- branch name,
- latest commit hash,
- local verification commands and outcomes,
- GitHub Actions run URL,
- direct APK download link.

Do not describe the APK as an Actions artifact; it is a GitHub Release asset.

---

## Self-Review

- Spec coverage: joystick trigger, floating card, adaptive range, quantized stepping, haptics, boundary labels, no persistent sheet, branch, push, and direct APK release link are covered.
- Placeholder scan: no red-flag placeholder steps remain.
- Type consistency: `CalendarJoystickRange`, `observedMax`, `fallbackMax`, joystick value keys, and callback names are used consistently across tasks.
