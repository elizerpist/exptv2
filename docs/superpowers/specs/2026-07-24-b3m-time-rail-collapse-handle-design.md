# B3M time-rail collapse handle design

## Approved inputs

- User instruction dated 2026-07-24.
- Latest screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260724-004911.png`.
- Existing host: `balance_latest_layout.html`.
- Shared interaction source: `attachTodayRedesignScrollInteraction()`.
- Shared rail source: `createTodayTimeScopeDrawer()`.

## Root cause

The full-screen `.stage2-redesign-scroll-viewport` is vertically scrollable and owns `touch-action: pan-y`. Collapse progress is calculated directly from that viewport's `scrollTop`, so a native drag started anywhere inside the screen can collapse or expand the header.

## Interaction contract

For the current exit-mode B3M family, the full-screen viewport is no longer user-scrollable vertically. It remains programmatically scrollable so the compact budget pill and the controller can still set the two header states.

The only vertical gesture owner is a dedicated button inside the existing time-scope control row. Pointer capture keeps an active gesture bound to the handle. An upward drag increases the viewport scroll offset and collapses the screen; a downward drag reduces it and expands the screen. On release, the controller settles to the closest endpoint. A tap, Enter or Space toggles between endpoints.

The year-pill rail keeps its existing horizontal pan and click behavior. It is deliberately not itself a vertical gesture surface, avoiding axis conflict.

## Visual contract

The handle is a child of `.stage2-redesign-time-scope-control`, whose height remains `21px`. It is absolutely centered in that existing free strip and therefore contributes no new flow height. It contains:

- one short rounded horizontal bar;
- the label `Húzd a nézetet`;
- one accessible button hit area and an explicit collapse/expand label.

No time-scope, year-rail, detail-card, bottom-navigation or screen dimension may change.

## Scope

The shared factory/controller change covers B3M-A3 and every current independent clone derived from it, including Budget, Budget 3D, Mind and annual Mind. Legacy non-exit prototypes retain their existing viewport behavior.
