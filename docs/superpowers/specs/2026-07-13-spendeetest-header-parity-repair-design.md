# Spendee Test Header Parity Repair Design

## Status and approval

Approved direction: the user accepted the 2026-07-13 audit conclusion that the Flutter implementation must reproduce the complete HTML paint graph instead of approximating it, and explicitly requested both the design repair and the Stage 1/2 behavior repair.

## Mandatory references

- Source of truth: `docs/prototypes/color_lab.html`, Budget mode C1/C2/C3 common-header screens.
- HTML screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260713-192134.png`.
- Current app screenshot: `/storage/emulated/0/Pictures/Screenshots/Screenshot_20260713-192139.png`.
- Header interaction notes: `docs/superpowers/specs/2026-07-13-focus-mode-header-notes.md`.
- Flutter integration: `lib/features/transactions/widgets/experimental/spendee_test_dashboard.dart`.
- Current stage model: `lib/features/transactions/widgets/experimental/spendee_header_stage_controller.dart`.

The prototype viewport is 412×892 logical pixels. Device layouts may have a different height, but all horizontal dimensions and Stage 0/1 constants remain in logical pixels and Stage 2 continues to derive from the bottom safety relationship defined by the HTML.

## Considered approaches

### 1. Continue patching the current `BoxDecoration` tree

This is the smallest diff, but it cannot express the CSS inset shadows and combined glow masks directly, and it preserves the paint-order mistake that hid the white border. Rejected.

### 2. Dedicated immutable visual specification plus painters

Use a pure `SpendeeHeaderVisualSpec` for computed colors/opacity/geometry and dedicated painters for the outer glow, card glass layers, foreground border and menu surface. Keep semantic content and gestures as Flutter widgets above the painted surfaces. Chosen because every HTML layer receives an explicit Flutter owner and can be unit/golden tested.

### 3. Render the HTML inside a WebView

This would visually reuse CSS but would split gestures, accessibility and live `TransactionStore` data across Flutter and a web runtime. Rejected for production behavior and performance.

## Visual contract

### Computed Budget state

The HTML runtime state—not the root fallback—is authoritative:

- Cool scale center: `50`.
- Cool window width: `28`.
- Sample positions: `36`, `50`, `64`.
- Sampled colors: `#61E1FB`, `#14C5E1`, `#0390CA`.
- Gradient angle: CSS `112deg`.
- Header graphic-layer opacity at mode-opacity center `50`: `0.57`.
- Reactive right accent: sampled right color mixed `42%` toward white, then rendered at alpha `0.26`.

Only the graphic layer uses `0.57`. Text, menu, handle and the one-pixel border stay fully opaque according to their own colors.

### Card layer order

Back to front:

1. Reactive outer glow behind the dashboard.
2. Card drop shadows with HTML offsets, blur radii and colors.
3. Card-clipped `BackdropFilter` at sigma `18`.
4. Base sampled Budget gradient.
5. White radial gloss centered at `14% 20%`, `rgba(255,255,255,.52)` to transparent at the HTML stop.
6. Reactive radial gloss centered at `width - 36.8`, `30.8`, with `.26`, `.13`, transparent stops at `0`, `.34`, `.68`.
7. White diagonal gloss at CSS `164deg`, `.28` to transparent at `.54`.
8. Semantic content.
9. Header handle and menu surface.
10. Foreground one-logical-pixel pure-white border, radius `24`.

The foreground border must be visibly white on the straight top edge at DPR 1. It must not be painted behind an opaque child.

### Outer glow

- Bounds at Stage 0: left/right `-36`, top `24`, height `264`.
- Height grows by exactly `currentHeaderHeight - 104`.
- Blur sigma: `34`.
- Opacity: `.24`.
- Vertical mask: transparent at the top, fully present after `48` logical pixels.
- Radial mask: alpha `1` at center, `.88` at `.46`, `.56` at `.72`, `.18` at `.90`, transparent at the edge.
- Both masks intersect; the glow must have no rectangular edge.

### Category/menu surface

- Size `33.6×33.6`, radius `13.6`, top `14`, right `20`.
- Fill `rgba(255,255,255,.32)`.
- Border `rgba(255,255,255,.48)` rendered in the foreground.
- Top inset `rgba(255,255,255,.68)` at one pixel.
- Bottom inset `rgba(120,220,230,.14)` at one pixel.
- Three bars, each `16×3`, gap `3`, pill radius.
- Bar gradient: `.96` white, `.72` pale cyan at `.52`, `.46` cyan at `1`.
- No unrelated grey fill or external cyan shadow.

### Core content and dashboard geometry

- Brand lockup above the card must be restored from `final_spendeevector.svg` or an exact packaged derivative; it may not be redrawn approximately.
- Stage 0 title is `BUDGET`, not `Budget`.
- Stage 0 has the HTML title and value only; the unapproved `Elköltve ...` subvalue is removed.
- Text value retains the HTML white shadows and `.45` logical-pixel light stroke.
- Home content remains `4` pixels below the current header bottom and moves by the exact header-height delta.
- Type row: height `66`, horizontal padding `28`, vertical padding `12`; pill height `42`, radius `21` and HTML shadows.
- Summary: horizontal margin `28`, height `59`, radius `20`.
- Search: horizontal margin `28`, top/bottom margin `12`, height `45`, radius `20`.
- Logbox: height `64.8`, horizontal margin `20`, vertical margin `4`, radius `18`.

## Interaction contract

### State model

The drag controller owns:

- `settledStage`: Stage 0, 1 or 2.
- `settledHeight`: the exact snap height.
- `dragOffset`: signed displacement from the settled height.
- `armedTarget`: target selected by threshold crossing.
- per-threshold tick state for the current pointer sequence.

The widget must never infer the target from a transient rebuilt controller. A geometry update preserves the settled stage and remaps its height; it does not silently create a Stage 0 controller.

### Stage transitions

- Stage 0, below first trigger, release: Stage 0 with elastic return.
- Stage 0, at/after first trigger, release: Stage 1 and remain there.
- Stage 1, initial downward popout: one tick. Release while popped out but before Stage 2: Stage 0.
- Stage 1, pop out then drag manually back to zero before release: remain Stage 1 with spring response.
- Stage 1, cross Stage 2 trigger: one additional tick. Release: Stage 2.
- Stage 2 allows `18` logical pixels of downward overshoot and emits one popout tick.
- Stage 2 release while popped out: Stage 1.
- Stage 2 pop out then manually return to zero: remain Stage 2.
- Signed upward deltas must work throughout an active pointer sequence.

The visible handle has a full-width, 28-pixel-high hit area. Vertical header drag and horizontal avatar-carousel drag have separate gesture regions and must not steal each other.

### Error handling

Stage 1/2 must support zero categories, one category, more than five categories, large transaction counts and categories with/without limits. Every pointer phase is checked for `FlutterError`, overflow and asynchronous exceptions. A caught exception fails the acceptance test; no error box may flash.

## Verification contract

- Pure tests for exact sampled colors, opacity, accent and geometry.
- Unit tests for every state-machine transition and geometry replacement while settled/dragging.
- 412×892 widget tests using real pointer gestures, not direct controller calls only.
- Tests capture `tester.takeException()` after drag start, updates, release and settle.
- Widget tests assert header and home-content rectangles move by the same delta.
- Golden crops for Stage 0 header, menu button, Stage 1 and Stage 2.
- Fresh Android screenshots compared with the mandatory HTML screenshot before any visual item returns to `DONE`.
- Structural key existence alone is not visual verification.

## Scope boundaries

- Existing database/repository/native bridge data flow remains unchanged.
- Existing current-dashboard mode remains unchanged.
- This repair is limited to the Spendee test dashboard and reusable visual/controller helpers required by it.
