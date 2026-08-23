# Space Fabric live pipeline and perceptual-motion checklist

## Architecture card

| State / mechanism | Existing owner | Required write path | Reuse decision |
|---|---|---|---|
| Header phase | `DashboardHeaderVisualController` | one ticker → `_advance` → `_phase` | preserve; no second clock |
| Header repaint | `_DashboardHeaderVisualPainter` | controller `Listenable` → `CustomPainter.repaint` | preserve; prove with real ticker |
| Fragment phase | `DashboardHeaderFragmentUniformLayout` | paint input → retained shader uniform | add test-only observation only |
| Space Fabric mapping | `spaceFabricSourceUv` | `uPhase` → source UV | preserve metric model; calibrate only after evidence |
| Perceptual raster metric | Header temporal test helper | captured real-paint rasters | centralize instead of weak ad-hoc thresholds |

| ID | Source | Code area | Acceptance condition | Verification | Status |
|---|---|---|---|---|---|
| LIVE-01 | RED-01–04 | controller / painter / backend | Real ticker advances phase, causes retained shader uniform writes and raster repaint without `debugAdvance`. | Widget raster test plus backend observation. | DONE |
| LIVE-02 | RED-05–09 | temporal test utility | 1/3/5-second raster deltas meet byte-scale perceptual thresholds and broad changed-pixel fractions. | Real ticker raster metrics. | DONE |
| LIVE-03 | RED-08–14 | test-side source-map probe | Source UV motion, feature centroid/shape and field-count energy distinguish geometry from paint failure. | Deterministic probe. | DONE |
| LIVE-04 | RED-15–17 | controller / temporal test | `speed=0` freezes; `speed=.1/.3/.6/1` increases temporal phase response. | Real ticker and phase tests. | DONE |
| LIVE-05 | Diagnostics | visual engine / backend | One bounded selection-time liveness event proves ticker → paint → uniform, without per-frame logging. | Source and diagnostic tests. | DONE |
| LIVE-06 | Protected architecture | shader / controller | ABI v3, one clock, IDs 14–17, Cool P/W, static, Full Field, Portal and touch remain unchanged. | Focused/protected tests and diffs. | PARTIAL — protected suite pending |
| LIVE-07 | Delivery | CI / APK | Exact remote match, required CI success and normal `lib/main.dart` profile APK hash. | GitHub Actions and local SHA-256. | NOT DONE |
| LIVE-08 | Physical acceptance | Android | Four variants visibly animate; speed-1 and fresh diagnostics accepted by a human. | Fresh device observation and log. | NOT DONE |
