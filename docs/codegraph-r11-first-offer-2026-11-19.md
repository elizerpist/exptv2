# R11 first-offer exact-source inventory

Application source: `1d19624751169e3af0270b151378cdfcdf1a1129`; parent
`d87c7ba330c0d38cd4a0611ebf0dae92e262b5b0`. Source checkout:
`/workspace/r11-graph-source`; independent tooling checkout:
`/workspace/r11-tooling`. SCIP-Dart 1.6.2 indexed 808 Dart documents,
20,253 repository symbols, 136,383 references and 42,214 edges. Index SHA-256
`3f2ed32dd0146e6ef30f5c702ddadcc278b378d55ec7e8ea592ed82786367dc7`;
manifest SHA-256 `12576550a54bfd98112ac9b657fe7359e16b58eb47149c94ccbd6fdc9094a28a`.
All 102 shard hashes and their record counts were verified. The bridge query
finds three production and five test references; the raw query is beside this
inventory. SCIP-Dart does **not** index Kotlin; the following is manual source
navigation and is not runtime or physical-presentation evidence.

Paths below start at `android/app/src/main/kotlin/com/fluvi/app/lockscreen/`.

| Boundary | Definition and callers |
| --- | --- |
| Authorized show / exact operation | `FluviKeyguardCardService.kt:2003` creates the show operation; `KeyguardCardWindow.kt:178` calls the controller and `:204` binds the capture-qualified reporter before `addView`. |
| Controller lifetime / privacy | `material/KeyguardCardMaterialController.kt:575` installs attachment state, `:675` retires it, `:820` binds the reporter, and `:1231` selects a lease including privacy lifetime. `:1283` records first CPU output; `:1322` checks the exact token before retiring the bootstrap. |
| First-offer state | `material/KeyguardOrbFirstOffer.kt:8` implements one open/pending/claimed/settled/revoked handoff; `:21`, `:24`, `:37`, `:53`, `:64` own offer, claim, Main revoke, unclaimed Worker revoke and settle. It never grants display or releases a compositor-owned slot. |
| Producer / captured request | `material/KeyguardOrbBufferRenderer.kt:1622` binds a worker spec to the captured token; `:2208` captures that token with the render request and measures only the first two current slot-local shader preparations at `:2489`. |
| Ready before/after grant | Renderer `:1189` offers the exact READY use, `:1221` posts a coalesced normal nudge, `:911` creates/reparents/places the existing child and calls `setAttachment` at `:1720`, and `:1233` is the one Main consume function for either caller. |
| Direct transfer / callback | Renderer `:1264` rechecks root, orb, dimensions, lease and exact current child, directly applies the first transaction, settles ownership and queues `:1888` before external observation. First commit is an app callback, not physical presentation. |
| Revoke / fence / steady | Renderer `:1179` revokes pending or claimed unpublished uses, `:2005` drains the exact ready use through the existing producer-fence path, `:1913` receives real releases, and `:2507` preserves the existing Worker steady route. No timeout marks a slot reusable. |
| Visible capture / export | `FluviKeyguardCardService.kt:415` closes over the original capture and show operation; `KeyguardCardSettings.kt:1309` reduces bounded events and reconciles events arriving before SHOW at `:1509`. Snapshot/freeze is `:1720`, compact output `:1916`, actual hide context `:1960`. |
| Test consumers | `KeyguardHeaderMaterialViewInstrumentationTest.kt:61,62,64,90,324` cover real offer/grant order, same-visual privacy generation, early revoke and the baseline-compatible early-nudge control. Existing stale READY, failure and same-root privacy tests are at `:2476`, `:2514`, `:2565`. `KeyguardCardDiagnosticsInstrumentationTest.kt:900` covers FULL/LIGHT visible-freeze ownership and budget. Pure interleavings are in `KeyguardOrbFirstOfferTest.kt`. |
| Service/CI consumers | `KeyguardServiceOverlayInstrumentationTest.kt:102,367` separate bounded image sampling from timing-only service processes. `scripts/test-keyguard-r11-cold.sh:9` pins R10 baseline source and enforces identities; `scripts/test-keyguard-r09-panel.sh:58` registers the independent panel cases. |

A state-machine test, CPU submission, transaction commit, successful hide or
matching graph does not prove correct physical pixels, real release, or user
acceptance. The application report records each actual device gate separately.
