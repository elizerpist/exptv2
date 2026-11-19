# R10 ORB first-render source navigation

Application source: `7a1ec21b55aeaf69ef56c2b49dcc5114d7271b60`.
This file accompanies the exact-source SCIP-Dart 1.6.2 manifest in
`docs/codegraph/manifest.json`. The SCIP index describes Dart definitions and
references only. Kotlin links below are manually checked native-source
navigation, not inferred SCIP call edges, measured runtime calls, or proof of
the phone's rendering latency.

Manifest SHA-256 `5228b75e1b1b38092f4ddeea056456aaf5f19ef8e98947953aa4c7894cf78781`;
index SHA-256 `d0f8d076ff684acdf46fa80d2acc5fc46de8891dbf90b1eb718b955bf0438706`.
The index contains 808 documents, 20,253 repository-defined symbols, 136,383
references and 42,214 graph edges. All 102 shard hashes and record counts were
independently checked. The bridge query records three production and five test
references. Tooling analysis and 16 tests passed. Source worktree:
`/workspace/r10-final-source`; tooling worktree: `/workspace/r10-tooling`.

Paths below start at `android/app/src/main/kotlin/com/fluvi/app/lockscreen/`.
The corresponding API35 controls are in the same packages below
`android/app/src/androidTest/kotlin/`.

| Boundary | Definition / direct consumers at application SHA |
| --- | --- |
| Explicit detached prepare | `KeyguardCardWindow.kt:158` calls `KeyguardCardMaterialController.kt:969`, and its artifact callback reconciles at `:1079`; no authorization follows from the prepared result. |
| Show authorization and reentrancy | `KeyguardCardWindow.kt:176` begins the pending show at `:182`, before material update and `addView`; `:242` passes the actual root and generation into `Controller.onAttached` at `:569`. Cancellation is in the window's `finally`. |
| Visible scene ownership | `KeyguardCardMaterialController.kt:348` selects the previous layer only from the current attached owner; exact first submission at `:1261` and the View draw at `KeyguardHeaderMaterialView.kt:687` update that owner. Detach at controller `:669` clears it. |
| Prime and live arbitration | `material/KeyguardOrbBufferRenderer.kt:1329` and `:1482` own the bounded key and state; Main revokes unsubmitted detached demand at `:1369`. The callback at `:1890` reads the current demand and `:2052` rechecks before actual render submission. |
| First ready / direct / commit | Renderer `:1123` hands off a real ready result; `:1155` publishes the exact current child. Controller `:1261` and its following commit callbacks retain the current owner. The first direct transaction's receipt does not establish physical presentation. |
| Withdraw / release / fence | Window `:324` calls controller `:669` for immediate visibility retirement. Renderer `:1609` queues the exact-child final clear; `:1757` processes actual release receipts, `:2395` drains unsubmitted producer results and `:2439` completes the appropriate fence. Neither time nor commit is buffer reuse permission. |
| Cold observations and report | `KeyguardFirstDrawObservation.kt:12` arms actual attach/layout plus a Main async marker; window `:203` arms it before add. `FluviKeyguardCardService.kt:404` carries the original operation, and `:2117`/`:2229` consume the boundary snapshot. `KeyguardCardSettings.kt:1753` reserves compact rows and the measured worst gap; `:2023` retains verbose episodes. |
| Actual-service experiment | `KeyguardServiceOverlayInstrumentationTest.kt:100` drives independent cold/warm attempts; `scripts/test-keyguard-r10-cold.sh:77` selects it and archives both repetitions. The harness commit and application/test APKs remain separate identities. |
| Focused controls | `KeyguardHeaderMaterialViewInstrumentationTest.kt:63`, `:89`, `:161`, `:214` cover prepared-only prior content, first show, unsubmitted arbitration and visible/privacy updates. `KeyguardFirstDrawObservationInstrumentationTest.kt:28` tests attach ownership; `KeyguardCardDiagnosticsInstrumentationTest.kt:897` covers FULL/LIGHT export pressure. `scripts/test-keyguard-r09-panel.sh:50` selects them with the existing R09 controls. |

The physical result is decided by the user. Successful compilation or a
graph query does not establish compositor pixels, buffer release or improved
phone presentation.
