# Stats Slider Joystick Design

## Context

The stats page currently uses `CalendarValueSliderPanel` for the category threshold and heatmap scale controls. The panel can be collapsed into a small floating trigger button, but the open slider card takes too much vertical space from the calendar. The approved direction is to remove the open sheet from the normal interaction path and turn the collapsed trigger into a joystick-style value control.

Supporting visual: `docs/superpowers/specs/stats-slider-joystick-focused.excalidraw`.

## Goals

- Keep the stats calendar width and height visually clear while adjusting threshold/scale values.
- Preserve fast value control for category and heatmap modes.
- Show the current value clearly during adjustment without leaving a persistent panel on screen.
- Use adaptive ranges so users do not need to manually configure min/max for normal use.
- Add haptic feedback that confirms activation and meaningful value ticks without becoming noisy.

## Non-Goals

- No permanent side rail.
- No full slider sheet for the default path.
- No custom min/max gesture hidden inside the joystick interaction.
- No unrelated changes to calendar rendering, mode selection, export actions, or month focus behavior.

## Recommended UX

The collapsed mini slider trigger remains near the lower-right edge of the stats overlay. It becomes a joystick control:

1. User long-presses the trigger.
2. The control enters active joystick mode and shows a temporary floating value card near the trigger.
3. Vertical drag changes the active value:
   - upward drag increases the amount,
   - downward drag decreases the amount.
4. The value is clamped to the adaptive range.
5. Releasing the press commits the current value and fades the floating card out after a short delay.

The floating card is the approved value display. It should show full formatted HUF values, for example `10 000 Ft`. At range boundaries it can temporarily show `Min 0 Ft` or `Max 50 000 Ft`.

The floating card should only be visible while the joystick is active and briefly after release. It should not become another persistent sheet.

## Adaptive Range

The range should be automatic and data-driven by default.

For each control:

- `min = 0`
- `rawMax = max(currentValue, observedMax) * 1.2`
- `max = niceCeil(rawMax)`

`observedMax` is mode-specific:

- Category threshold mode: use the maximum relevant observed expense/category day amount from the existing calendar threshold data.
- Heatmap mode: use the maximum relevant heatmap/day amount from the current year data.

`niceCeil` should round to readable financial steps, for example:

- 10 000
- 25 000
- 50 000
- 100 000
- 250 000
- 500 000
- 1 000 000

The implementation may derive this with a general "nice number" algorithm rather than a fixed list, as long as the output remains readable.

If there is no observed data, fall back to the existing safe defaults already used by the calendar slider logic.

## Joystick Stepping

The joystick should not map every pixel directly to one fixed HUF amount. It should use adaptive, quantized stepping:

- Choose a base step from the current range, such as `niceStep(max / 80)` or another similarly smooth ratio.
- Snap values to that step.
- Use drag distance from the activation point to control speed:
  - small distance: 1 step per tick,
  - medium distance: 2-3 steps per tick,
  - large distance: 5+ steps per tick.

There should be an initial dead zone of roughly 8-12 px so a long-press does not accidentally change the value.

Updates should be paced on a timer or throttled gesture loop so a long drag feels controlled instead of producing frame-by-frame value jumps.

## Haptics

Use haptics sparingly.

- Long-press activation: `HapticFeedback.mediumImpact()`.
- Value ticks: throttled `HapticFeedback.selectionClick()` only when the quantized value crosses a step boundary.
- Minimum interval between tick haptics: roughly 80-120 ms.
- Range boundary hit: one `HapticFeedback.mediumImpact()` when min or max is reached.
- Do not repeat boundary haptics while the user remains clamped at the same boundary.
- Do not add a separate release haptic by default.

This gives a clear start signal and tactile tick feedback without making fast adjustments irritating.

## State And Error Handling

The widget should track:

- whether joystick mode is active,
- the drag activation point,
- the current adaptive range,
- the current quantized value,
- the last value that produced a tick haptic,
- the last boundary that produced a boundary haptic,
- the temporary visibility/fade state of the floating value card.

If range calculation produces invalid values, the control should fall back to existing slider defaults and clamp to a safe positive max.

If haptic calls are unavailable or ignored by the platform, the UI should still work normally.

## Integration Points

The likely implementation surface is `CalendarValueSliderPanel`.

The existing collapsed `_MiniButton` can become the joystick trigger. The expanded panel path can be removed from the default stats flow or kept only if a future explicit settings path needs manual editing.

The parent `CalendarMenuOverlay` should continue owning the value notifiers:

- `_thresholdValue`
- `_heatmapMinValue`
- `_heatmapCurrentValue`
- `_heatmapMaxValue`

The joystick should call the same `onChanged` callbacks as the old slider so calendar rendering behavior remains localized.

The stats menu may later expose a rare range setting: `Skála tartomány -> Auto / Egyéni`. That is not required for the first joystick implementation because the approved default is adaptive auto range.

## Testing

Widget tests should cover:

- collapsed trigger is visible for threshold and heatmap modes,
- long-press shows the floating value card,
- upward drag increases the value,
- downward drag decreases the value,
- value clamps at adaptive min and max,
- floating card shows formatted HUF values and boundary labels,
- release hides/fades the floating card,
- callbacks are not fired before the dead zone is crossed,
- adaptive range calculation handles empty data and large observed values.

Manual verification on device should cover:

- long-press activation haptic,
- tick haptic frequency during slow and fast drags,
- one-time boundary haptic at min/max,
- no excessive vibration during sustained fast movement,
- no important calendar content is persistently covered.

## Delivery Requirements

Implementation must happen on a new branch named `stats-joystick`, not on any existing statistics branch.

After implementation:

- commit the finished code,
- push `stats-joystick` to the user's GitHub remote,
- run the APK build online through GitHub, not locally in Termux,
- provide a direct APK download link.

The APK should not be delivered only as a GitHub Actions artifact. Prefer publishing the built APK as a GitHub Release asset, then provide the release asset download URL.

## Approved Decision

Use the joystick trigger with:

- temporary floating value card,
- adaptive automatic range,
- quantized ratio-based stepping,
- long-press activation haptic,
- throttled tick haptics,
- one-time boundary haptics.
