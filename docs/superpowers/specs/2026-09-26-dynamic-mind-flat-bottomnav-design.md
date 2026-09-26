# Design — Dynamic Mind scale and flat BottomNav stretch

## Ownership and reuse

Mind visual alternatives already belong to `MindYearHeatmapPresentationSettings` and its controller. The dynamic-scale toggle and handle-size choice extend that single Mind-only owner. `MindYearHeatmapPaletteResolver` remains the one source of ordered heatmap/legend colors; a small immutable resolved-scale value may be shared by annual cells, legend, and the compact Mind range presentation. No financial frame, score projection, or Query owner receives visual state.

`DashboardShellPresentationSettings` already owns BottomNav form. Its new stored stretch target belongs there. A pure layout input bridges the shell's physical BottomNav top to `DashboardGeometryResolver`; the resolver alone distributes the resulting progress-scaled height. This keeps one geometry authority and avoids render-object measurement loops.

## Dynamic Mind palette contract

The resolver maps score to a ten-stop `MindHeatmapResolvedScale`. It clamps below 18 and above 82. Between adjacent score anchors, it calls `Color.lerp` only between matching stop indices. Tile intensity remains a second, independent interpolation along the already-resolved stop list. Empty cells retain the existing neutral sample. The widget animates only the resolved presentation scale over 350 ms; no score or data work occurs during the animation.

The range renderer owns a normalized active-segment paint rect. The gradient shader rect is the active segment itself, so a color position is always a ratio of that current segment width. Each filled handle samples the resolved scale at its segment endpoint; the visible diameter may be 90% while the existing semantic/hit target is retained.

## Flat BottomNav geometry contract

For eligible `straight + containedFlat` shell presentation, the resolved delta is:

`max(0, physicalBottomNavTop - currentResolvedSearchPillTop)`.

`currentResolvedSearchPillTop` is based on the current resolved LogBox header top plus existing scaled Ledger inset, count-height, and count-to-search gap. The resolver never owns a copied 24px BNB constant. `off` passes zero. `expandedHeader` uses the delta only in the expanded header endpoint; `modeContent` passes it as the existing mode-content extra height. Both are multiplied naturally by existing header expansion progress.

This bridges bottom navigation location into layout once; it never moves the nav or removes SearchPill. The existing physical LogBox header/handle geometry stays authoritative so standalone/notch/pill collapse modes compose without double counting.
