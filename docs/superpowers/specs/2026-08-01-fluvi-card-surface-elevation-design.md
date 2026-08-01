# Fluvi Shared Card Surface Elevation

## Reference

The visual reference is the Balance B3M card treatment in
`/data/data/com.termux/files/home/ubuntu/flutteruser/flutterapps/spendeetest-worktree/balance_latest_layout.html`.
The normal Balance cards use a neutral border, a downward soft elevation
shadow, and a subtle top inner highlight. The separate Budget 3D mode also
uses a small blur-free offset shadow as a hard lower lip; Fluvi adopts that
lower-lip idea centrally without using a pink border.

## Design

`FluviRoundedBox` remains the single owner of elongated rounded card surfaces.
When a caller does not explicitly provide shadows, it receives the shared
`FluviVisualTokens.cardSurfaceShadows` list:

1. `cardFootShadow`: neutral, blur-free, 4 logical pixels downward;
2. `cardElevationShadow`: neutral, soft, 10 logical pixels downward with an
   18 logical pixel blur.

The surface color, gradient, radius, and any explicit border remain owned by
the caller. Therefore active and inactive income/expense controls keep their
different fills while sharing the same 3D material treatment. Header cards,
subheader cards, summary surfaces, year chips, and action controls all inherit
the same two shadow layers through the shared primitive.

## Non-goals

- No pink-specific border or shadow is introduced.
- No per-widget shadow implementation is added.
- The BNB-03 circular center action is not converted into a card surface.
- Existing layout dimensions, motion, gradients, and rounded radii are not
  redesigned.
