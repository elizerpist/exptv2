# Mind Year Heatmap design specification

## Authority and data flow

`DashboardCoreController` remains the sole owner of the canonical Query and
the existing `previewMindAmountRange` / `commitMindAmountRange` lifecycle. A
Mind-only projection is a derived read model, not a second query store. Its
identity is the current non-amount domain scope key (including the active
focus signature), prepared-index generation and revision, and selected year.
Navigation epochs that retain this membership identity intentionally do not
force a rebuild. Replacing the identity
atomically replaces the single active projection and increments its generation.

The immutable source projection is built once from the current direction's
resident `DashboardFocusMembershipSeed`: entries outside the selected local
calendar year are rejected during construction; each remaining local day owns
sorted amount contributions plus prefix sums. Amount previews use binary range
bounds then at most 366 day buckets. They do not read repositories, room,
indices or source entries, parse dates, mutate the canonical Query or retain an
unbounded cache.

The Android profile drives both thumbs through twenty physical pointer moves.
It rejects missing live publication, any source-row/repository/index work, a
preview p95 above 8 ms, either engine build/raster p95 above 12 ms, or more
than one missed build/raster frame in that isolated interaction sample.

## Rendering and interaction

Mind + `TimePlane.year` renders twelve stable MonthCard shells in a 3x4
`GridView` inside one `Expanded` viewport. Each card exposes only its Hungarian
month label and valid square day tiles. The dynamic tile field listens to the
projection frame; static shell/chrome do not listen to amount-only previews.

The compact Mind presentation of the shared range control keeps the Query Menu
presentation unchanged. Its footer is a sibling after the `Expanded` viewport,
so the slider has independent hit testing and never overlays scrolling cells.
The viewport alone opts out of the host vertical expansion recognizer; all
other host gesture behavior remains unchanged.

## Color semantics

The visible projection sums matching contributions per local day, finds global
min/max across non-empty daily totals for the selected filtered year, and gives
the renderer named states: `empty`, `minimum`, `interpolated`, `maximum`, and
`equalRange`. Empty is visually distinct; minimum is colored even at numeric
zero normalization; equal range uses one explicit palette token.
