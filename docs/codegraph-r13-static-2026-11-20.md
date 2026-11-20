# R13 financial fallback graph and Kotlin source inventory

Application source: `e3a3ef5ca6370c3eca573f699ff21168c24df9fc`. Core implementation commit: `9167e85598d39be2f87e49ca62973c326b505dd5`. Reference production baseline: `9495b1144bb5400efcdb95ec3a8be2adc6e0b21a`. The generated manifest and Dart SCIP index are navigation evidence, not a runtime or physical-presentation proof. SCIP-Dart 1.6.2 indexes Dart; it does **not** index Kotlin. The following Kotlin locations are manually checked against the exact application checkout.

| Boundary | Current Kotlin definition / consumer | Contract and limitation |
| --- | --- | --- |
| Financial projection | `runtime/FluviFinancialCardPresentation.kt:12,30,33,40` | Four presenter paths retain a scalar accent; each presentation synchronizes the first actual bitmap demand. |
| Shared painter | `runtime/FluviLockScreenCard.kt:567,569` | The notification extension delegates to the same 96x96 ARGB painter; no process-wide pixel cache. |
| Real widget | `widget/financial/FluviFinancialSnapshotWidget.kt:360,384,407` | The widget's actual RemoteViews consumer requests the bitmap; privacy and text remain presentation-owned. |
| Notification | `runtime/FluviRuntimeMonitoring.kt:601` | A full notification requests the extension directly. |
| Render route / old reference | `lockscreen/KeyguardCardWindow.kt:163,189,282,407,700,720,1021` | Main retires/hides the legacy owner and clears its fallback when Surface takes ownership. Route changes use the authorized presentation; legacy-only `apply` binds the bitmap. |
| Retained View | `lockscreen/material/KeyguardHeaderMaterialView.kt:303` | The actual setter drops the prior fallback reference; no bitmap is recycled. |
| Scope timing | `runtime/FluviFinancialOrbWork.kt:8,47,57`; `lockscreen/FluviKeyguardCardService.kt:2230,2251,2276` | A capture-qualified thread-local scope brackets actual keyguard presentation construction through the window result. Independent widget and notification calls are outside that scope. |
| Bounded reduction / hide | `lockscreen/KeyguardCardSettings.kt:1434,1874,2060,2133,2333` | Reduction is capture/attempt-owned. A 32-entry recent history supplies **lower-bound retained scope overlap**, and missing coverage is explicitly UNOBSERVED. This is not OS scheduling or physical visibility. |
| Tests | `lockscreen/KeyguardFinancialOrbDemandInstrumentationTest.kt`, `lockscreen/KeyguardFinancialSnapshotRemoteViewsInstrumentationTest.kt`, `lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt`, `lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt`, `lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt` | Device test definitions are not proof they ran or passed. Panel composition is not an independent real-service compositor/privacy verdict. |

The renderer, admission and privacy policies, legacy consumers, Surface producer, launcher's animated orb, and dashboard are not replaced by the R13 bitmap change. No claim about the cause of handset lag, GPU speed, actual presentation/removal or user acceptance follows from this inventory.
