# R10 corrected candidate source navigation

Exact application source: `8a91bf2d79f25780bb420c1a4d14abe846eac333`,
parent `7a1ec21b55aeaf69ef56c2b49dcc5114d7271b60`. The separately committed
graph uses SCIP-Dart 1.6.2; its manifest SHA-256 is
`8861fa8edf92084d44c5889b9880cf47bf0cf8e7d2edfa3f193c60ade0ca7282` and its
index SHA-256 is `d2dead5900c63d2afd8cf3ac13f0d86b63d02beaec7c6b3fc7346908517ef19b`.
The manifest contains 808 documents, 20,253 repository symbols, 136,383
references and 42,214 edges. The bridge query finds three production and five
test references. The source checkout was `/workspace/r10-corrected-source`;
the independent tooling checkout was `/workspace/r10-tooling`.

Dart SCIP does not cover Kotlin. The following native path inventory is based
on direct source inspection; it is navigation, not proof of runtime behavior.
Paths start at `android/app/src/main/kotlin/com/fluvi/app/lockscreen/`.

| Boundary | Exact native definitions and consumers |
| --- | --- |
| Explicit prewarm | `KeyguardCardWindow.kt:158` → `material/KeyguardCardMaterialController.kt:975` → artifact callback `:1085` → qualified `:1217` → renderer configure. A detached prime has no presentation authority. |
| Fresh authorized show | `KeyguardCardWindow.kt:176` enters `beginAuthorizedShow` at `:182` before apply/add; the actual root and attachment are passed to `Controller.onAttached` at window `:242`, controller `:569`. The pending state ends in `finally`. |
| No-op hide correction | `KeyguardCardMaterialController.kt:669` preserves an already-armed explicit prime only for a hide on an already detached controller with no pending authorized show. Real withdrawal and dispose invalidate it. The delayed-reader API35 control is `KeyguardHeaderMaterialViewInstrumentationTest.kt:89`. |
| Prior visible scene | Controller update at `:348` selects a previous scene only from qualifying content on the same current root. Exact first direct publication is `:1267`; `KeyguardHeaderMaterialView.kt:687` acknowledges an actually submitted current View shader. |
| Key / arbitration / GPU | `material/KeyguardOrbBufferRenderer.kt:1329` owns bounded prime key/state, `:1482` receives configure, `:1890` re-reads demand at frame callback, `:2052` selects a slot and rechecks before GPU submission. |
| First current handoff | Renderer `:1123` handles actual completion, `:1155` submits to the exact current child, and the controller's first submit/commit handlers retain the attachment identity. Transaction receipt is not physical presentation. |
| Withdrawal / release | Window `:324` invokes controller `:669`; renderer `:1609` queues exact-child final clear, `:1757` accepts actual release receipts, `:2395` drains producer work, and `:2439` handles fence completion. Pool reuse still requires actual ownership evidence. |
| Cold diagnostics | `KeyguardFirstDrawObservation.kt:12` observes attach/layout and asynchronous Main availability; window `:203` arms it before add. `FluviKeyguardCardService.kt:404` captures the original operation; `:2117`/`:2229` export bounded Worker/handoff records. `KeyguardCardSettings.kt:1753` admits compact records and the worst measured gap before verbose rows. |
| Evidence controls | `KeyguardServiceOverlayInstrumentationTest.kt:100` is the actual service cold/warm experiment selected by `scripts/test-keyguard-r10-cold.sh:77`. The API35 panel includes the prepared-only, no-op hide, no-detached-resubmission, arbitration, visible/privacy and root-observation cases, plus `KeyguardCardDiagnosticsInstrumentationTest.kt:897` FULL/LIGHT export. |

SCIP references, assertions and trace milestones do not establish physical
screen presentation or user acceptance. See the application journal and
R10 validation report for the immutable failed and passed gate evidence.
