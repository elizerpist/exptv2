# Implementation plan: Mind square 4×3 + Balance unified/Tetris

1. Add failing pure/settings tests for Mind four-column style, square/free
   geometry, selector placement fallback, and the 3×4/2×6 footer matrix.
2. Extend the existing Mind presentation setting/controller and the existing
   `MindYearHeatmapFourColumnFit`; bind the same direct-grid selector once in
   its calculated top/bottom location. Update the Mind tuner.
3. Add failing Balance settings/pure geometry tests for outer style, body
   style and the four slot allocations.
4. Extend the existing Balance settings/controller and tuner; add a small pure
   four-section resolver instead of embedding ratio arithmetic in a widget.
5. Reuse the Budget unified parent/seam strategy in the Balance core surface;
   keep the established cascade during transitions and use the new body
   resolver only at the settled unified content endpoint.
6. Add focused widget/geometry regressions for selection preservation,
   conditional controls, unified geometry, and no duplicated body children.
7. Run the relevant test groups in Ubuntu proot, format/check/analyze, inspect
   changed source and reference screenshot, update the acceptance checklist,
   commit/push, monitor the exact online human APK run, download and hash it.
