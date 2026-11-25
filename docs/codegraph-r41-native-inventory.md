# R41 native stock-opening inventory — work in progress

Application source: `a659765f34c875e6c4ecc8af347ff335288202d2` (R40 baseline `11b4a67a08f402968bd55ff62f63f0494227d0a9`). Dart SCIP graph commit: `e678d3b5c80c37f9f32ce4f903306ce85f5fac34`, index SHA-256 `870f84e9d8451ba8a25cbb19e43dca08d1b216943948c7a1088b83617ab5b7aa`, manifest SHA-256 `c97c44e0c8f5c20606dfe1fd1990a0ee3f9c0cc8e9f3389f766a487b9b82d288`. The graph indexes Dart, not Kotlin. The locations below are direct source navigation and do not imply executed call paths.

| Native edge or component | Exact source and meaning |
| --- | --- |
| Initial callback and identity | `FluviKeyguardCardService.kt:1596`, `:1628`, `:1848`: screen, display and accessibility callbacks; `:2187` adopts/joins a wake, `:2332` requests system sampling. |
| Sampler lane | `KeyguardSystemState.kt:63`, `:92`, `:142`–`:175`: one sampler, offer/coalescing, worker and Main receipt. `FluviKeyguardCardService.kt:644` may reserve the existing DIRECT route before Main under its existing authority checks. |
| Inspection queue and Main | `FluviKeyguardCardService.kt:2525`, `:2614`, `:3456`, `:3051`, `:4512`: queue offer, committed worker launch, physical reader, completion and actual Main policy application. R38 milestone ordering and R19 join remain active. |
| Shadow only | `FluviKeyguardCardService.kt:2629` records partial H2 scalar opportunity flags. The guarded H2 intervention and its real-service validation are not implemented in this source; no shadow flag is an eligible claim. |
| Direct authorization and output | `FluviKeyguardCardService.kt:5182`, `:5211`, `:5394`, `:1345`: successful coordinator grant, exact-owner successful reveal acknowledgement and cancellation. A cancelled grant is not an effective winner. |
| Non-DIRECT output | `FluviKeyguardCardService.kt:5241` records the original show candidate and `:1768`–`:1785` the matching first-post callback. The reducer requires the same request/show; neither is yet an equivalent fallback authorization or optical presentation. |
| Reducer and freeze | `KeyguardR41RawLedger.kt:9`, `:22`, `:59` is the bounded scalar mailbox; `KeyguardCardSettings.kt:1719`–`:1765`, `:2582`–`:2677` bind capture owners and reduce on the diagnostic consumer. `:1467` freezes; `:2839`–`:3066` emits clock, accounting, rows and explicit loss. `KeyguardR41AttemptLedger.kt:35`, `:148`, `:183`, `:192` retain and render bounded per-attempt/request data. The scalar ledger retains 32 requests per attempt; any later eviction remains explicit. |
| Flutter console | `lib/core/diagnostics/keyguard_timing_capture_bridge.dart:61`, `:84`–`:98`, `:147` and `lib/core/debug/debug_console.dart:14` consume the existing method-channel report; Dart SCIP is the source of graph references. |
| Offline interpretation | `scripts/analyze-r41.py:52`, `:127`, `:157`, `:177` keep missing data, sampler lanes and strict per-attempt verdicts distinct. Current production rows declare `coverage=INCOMPLETE`; do not report an end-to-end timing pass. |

The exact R41 service safety controls and the equivalent fallback grant remain unqualified. A native submit, callback receipt or frame capture is not the physically visible pixel. See the append-only engineering journal and linked CI artifacts for runs, failed preconditions, retained loss and source identities.

The 25-request LIGHT/FULL export and overflow controls passed in run `45523978535` on this exact application SHA; this proves neither complete coverage nor physical performance.

At `KeyguardCardSettings.kt:2943` compact R41 rows precede protected show/hide and R18 cores; verbose R41 request/receipt/sampler records begin after those existing cores. This is an export-selection change only. LIGHT/FULL targeted red/green runs `45527189111`/`45527327095` establish the specific omission and repair, not privacy, source-wide qualification or complete timing coverage.
