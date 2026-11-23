# R29.1 partial checkpoint: native source inventory

Application/source head: `de807259cd370d18e422772ed0943b8d65be4bca`.
The SCIP manifest in this commit is the unchanged output of graph run
[45120835804](https://github.com/elizerpist/exptv2/actions/runs/45120835804).
SCIP covers Dart, **not Kotlin or AOSP**. The following locations were checked
in the named source; they are source navigation, not runtime or pixel proof.

- `android/fluvi-core/.../FluviCore.kt:71`: `keyguardBudgetProjection` reads
  revision, category, total and limits in one Room transaction. The common
  limit projection is `query/FluviKeyguardBudgetProjection.kt:21`.
- `android/app/.../runtime/FluviLockScreenCard.kt:285,310,489` invokes the
  scoped core read and shares the existing limit calculation.
- `android/app/.../MainActivity.kt:1215,1231,1239,1253` serves the actual
  `publishProfile` and `sceneTarget` MethodChannel calls and adds the settings
  and current-revision observations. `lib/app/platform/`
  `dashboard_keyguard_material_bridge.dart:79,91,104,120,163` selects the
  actual frame, attaches conservative provenance and publishes it.
- `android/app/.../lockscreen/host/R29PublisherSnapshot.kt:44`,
  `R29HostClient.kt:23` and `R29OwnershipStore.kt:10` exist but have no
  production instantiation or call to the snapshot builder. No enrolled
  publisher or exclusive old-owner drain is thereby established.
- `platform/aosp16/systemui/.../FluviOrbHostService.kt:38,50,61` owns Binder
  caller verification and death/detach discrimination. `R29ResidentStore.kt:`
  `30,58,74,91,105,114,144,156` contains the expiry, session, preparation,
  invalidation, clean detach, unexpected death, current-slot and Worker→Main
  adoption boundaries. `R29HostRenderer.kt:65,82,99,143` owns preparation,
  quarantine and bounded fence wait. These are source-only host paths; no
  SystemUI lockscreen scene currently invokes `R29PreparedOrb.draw`.
- `platform/aosp16/contract/.../R29FramePolicy.kt` is separately visible to a
  test module. Policy tests do not exercise compositor pixels or prove the
  first eligible/restrictive frame.

AOSP `frameworks/base` parent: `99b01a65cc4c104933788b3143285ab6bae65827`.
The only staged patch remains the **incomplete bootstrap**
`platform/aosp16/patches/0001-r29-host-bootstrap-WIP.patch`, SHA-256
`d11979969378a3dee98666fd3237b623ee3bf5acd2757db70212f0c7c7766a15`.
The scene, transition latch and correlated empty-frame receipt are missing.
