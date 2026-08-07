# Implementation plan — Dashboard LogBox scene cache and profile diagnostics

1. Add red tests for the initial-anchor cache gap, scene completeness/atomicity, rotation-before-commit, boundedness, and profile diagnostic gating/console.
2. Introduce the immutable scene-window request and canonical prepared-scene cache; migrate the stable CustomPaint surface to scene lookups only.
3. Coordinate parent scene-window preparation in `DashboardCoreController` before its existing presentation commit; gate input during the bounded structural rotation without changing presentation/rail/physics classes.
4. Add deterministic scale fixtures and metrics, then enforce the 700/10k/50k/100k bounds and rail-zero-work invariants.
5. Unify diagnostic policy, add app-side useful event emission and live status, then replace the copy-only report path with an onscreen report UX.
6. Run focused and full non-golden tests/analyze in Ubuntu, recheck frozen hashes, commit/push, build the diagnostic profile APK on GitHub Actions, download it to the required device path, and verify the artifact.
