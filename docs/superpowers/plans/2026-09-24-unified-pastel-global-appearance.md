# Unified pastel appearance and global typography implementation plan

## Ownership decision

The existing dashboard-lifetime visual tuning controller is the natural
session-only appearance settings owner. It will gain one coherent global
appearance value (direction profile, avatar profile, artwork visibility and
typography profile), rather than creating persistence or a competing Header
selection. The existing Header frame reads the typography projection only; the
root app/shell applies the same profile to inherited Theme typography.

```text
DashboardHeaderVisualController.tuning (one session owner)
  -> global appearance state
  -> root Theme / inherited typography
  -> shared direction renderer + category palette scope
  -> Header visual frames
  -> prepared LogBox font/cache invalidation
```

Category semantics remain owned by the generated canonical catalog. A new
presentation catalog maps `(avatar profile, semantic color handle)` to a
three-stop `LinearGradient`, retaining the original handle's exact angles and
stops. `PreparedVectorAssetAtlas` owns a bounded prepared badge bank for all
four profiles, so LogBox receives profile-correct prepared display lists.

## Sequence

1. Add RED catalog/state tests for exact direction and avatar data, artwork
   visibility and one global typography selection.
2. Add the neutral appearance/profile resolver and integrate it into the
   existing tuning/controller/tuner without persistence or ticker changes.
3. Build the four predeclared category gradient banks and update generic,
   Balance/Budget and LogBox avatar consumers through a profile-aware atlas
   API.
4. Bind direction controls to the direction profile and artwork boolean.
5. Move the Header typography field to the global profile, apply it at the app
   scope, eliminate BNB03's hardcoded family, and thread the profile into
   explicit custom TextPainter owners.
6. Add profile identity to LogBox prepared text/scene cache admission; on a
   typography-only change rebuild text resources through the existing bounded
   preparation path while preserving data/Query/index identity.
7. Run focused RED/GREEN, cross-surface and protected suites; inspect source
   residual font owners and confirm the acceptance checklist.
8. Commit the coherent app change, push, obtain the normal exact-source online
   APK, download it to `/storage/emulated/0/Download/fluvi`, verify signature,
   SHA and embedded commit, then regenerate SCIP separately.

## Exclusions

No category JSON rewrite, repository/Query/projection/financial change,
direction semantic change, carousel change, Header palette math alteration,
asset recoloring, new persistence, new ticker, or per-frame palette/raster
work.
