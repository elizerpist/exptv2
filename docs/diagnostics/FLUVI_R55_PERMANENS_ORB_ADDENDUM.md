# R55 addendum — Permanens ORB

## 1. Title and task intent

Execute the original R55 handoff and this addendum in the same full Fluvi Android application. Finish R55’s unlock fix and diagnostics. Before cutting the HUMAN APK, add a user-selected persistent ORB for the locked, dark display. Deliver one in-place update containing both. The phone owner performs physical acceptance.

## 2. Authoritative application state

The owner tested `com.fluvi.app` 0.1.5 (7), source `41add67b7f4d4ecdf7a0a48abff64ca85364ac9e`, on a Nothing Phone (2a) A142, Nothing OS 5, Android 17 / API 37. The original R55 handoff is in `docs/FLUVI_ENGINEERING_JOURNAL.md` at `ba17b72fb69b0e9c97c955e6c79e22dcfbd8941e`. The reviewed product branch `implement/r55-wa-early-withdrawal` contains `8ddf2946ea3918a55f73330640edb3536d2fffc2`. Verify its current ancestry, keep equivalent work already present, and build on it.

## 3. Hard preflight

Apply the original 21-part handoff, its evidence and release gates, the project instructions, prompt-writer 2.2, widget addendum 1.3 and senior workflow 1.0. Reuse the R55 audit for unchanged material. Read the R51 locked-sleep qualification, R52 withdrawal review E52.1/E52.6/H52.5 and the R51 wake milestone. Identify the actual product SHA, signer and installed upgrade reference separately from journal, tooling and fixture refs.

## 4. Physical user evidence

The owner saw the correct-looking ORB for a few seconds after darkening the locked phone. The new requirement is intentional steady visibility after pressing power. With the feature enabled, the selected ORB or Fluvi mask should be the only visible element on the otherwise black display. The app must impose no expiry while the system permits ambient display. The normal lockscreen resumes on wake. Direct unlock must withdraw the ORB at the first forbidden frame.

## 5. Log audit

R52 documented the earlier observation. Its frozen phone capture contained no owned hide for that exact direct-to-sleep occurrence. R54/R55 unlock captures describe different episodes. Neither establishes whether the old pixels were on a transition frame, in steady AOD, or over a genuinely powered-off panel. Reuse the existing reports. The first new owner test belongs on the combined APK.

## 6. Commit and test audit

R51 introduced the single Balance ORB wake entrance and terminal sleep withdrawal. The R55 product moves an existing application-window veto ahead of node reads and records the outcome for the same attachment. Preserve both. Review the actual `WaWakeEpisode`, `WaLockscreenService`, `WaOrbWindow`, binding, packet producer and their tests before the scoped edit.

## 7. Graph provenance and impact

The R54 graph at `e86ab3bb92e5f30e69af57b498ac1ba6d9addbe8` indexes the tested Dart source. Trace the settings page through `fluvi/header_orb_widget`, `MainActivity`, `HeaderOrbBinding` and the WA service in source. Kotlin and the OEM compositor are outside that Dart index. Regenerate the product graph for the combined source as required by R55.

## 8. Current source facts

The interactive WA route requires the default display ON, interactive and keyguard locked. SCREEN_OFF, a noninteractive device or a non-ON display can withdraw it. The product already stores a binding-owned, generation-identified Balance frame packet in `HeaderOrbWidgetContent` and per-size styles in `HeaderOrbBinding`. Reuse that packet, saved position and existing brand mask. Never generate an approximation from a generic logo or a screenshot.

## 9. Evidence boundaries

- **E-A1 PROVEN.** The existing interactive route withdraws under the conditions above.
- **E-A2 PROVEN.** Android distinguishes a noninteractive device, low-power DOZE, suspended DOZE and display OFF. SCREEN_OFF alone does not identify the panel state.
- **E-A3 UNPROVEN.** Nothing’s A142 compositor will present Fluvi’s app-owned ambient pixels while locked. **MISSING EVIDENCE.** A sustained ORB-only interval on the exact phone and candidate. A successful add, draw or commit is an app receipt.

## 10. Reviewer decision and competing explanations

**D-A1 IMPLEMENTATION.** Add the setting, reuse the canonical frame and implement a separate, event-driven ambient presentation through the already-authorized WA accessibility service. Use one ORB-sized, transparent, non-touchable, non-focusable `TYPE_ACCESSIBILITY_OVERLAY` window. Keep the interactive wake owner and all R55 vetoes independent.

**D-A2 EVIDENCE_COLLECTION.** Test this single route with the controls in §17. A residual transition predicts brief pixels that disappear in steady ambient conditions. A usable ambient route predicts persistent pixels matching the selected style only with the feature enabled. OEM suppression remains plausible if an eligible ambient episode and app submission are observed but the ORB is physically absent. Stock clock, fingerprint, wallpaper or notification pixels outside the ORB mean the ORB-only appearance has not passed. Failure to enter AOD does not establish suppression.

## 11. Scope and settings

Add one Android switch named **Permanens ORB** in the existing **Zárképernyő** screen alongside the ORB settings. Use the subtitle “Lezárás után is látható, amíg a telefon Always-On Display módja aktív.” Default OFF on new installs and upgrades. Persist the choice through process restart and reboot. The master lockscreen setting, permission and active binding still apply. Show the saved request separately from an observed state or unavailable material. If support is undetermined, say so. Preserve the launcher widget, dashboard and existing settings.

## 12. Ownership and transitions

| Observed condition | Required action |
| --- | --- |
| Option OFF or master disabled | Revoke any ambient owner immediately. Run normal R55 behavior. |
| Entering sleep | Withdraw the interactive owner normally. SCREEN_OFF alone never grants ambient publication. |
| Default display in DOZE, positively locked, noninteractive, settings and current material valid | Permit one event-driven ambient submission for this ownership generation. Support both sleeping from the main lockscreen and locking directly from an app once the gate is valid. |
| DOZE_SUSPEND | Let the system retain permitted pixels. If suspension was the first observed state, record that fact and wait for a drawable opportunity. Never wake the CPU to manufacture frames. |
| Fully OFF, missing/unknown required state, lost permission or service, or revoked binding | Release the ambient presentation and invalidate pending work. Respect system suppression and later re-evaluate only on a fresh eligible event. |
| Wake, direct unlock, or a known restricted scene | Revoke ambient ownership immediately. Allow only the existing R55 route to grant a fresh normal lockscreen ORB. Keep PIN, shade, camera, launcher, other apps and other displays clean. |

Recheck the generation and current public state before publication and on asynchronous completion. Ambient and interactive owners must never both publish visible pixels. A late callback must not restore either revoked owner.

## 13. Required red tests

Exercise preference migration and restart, the OFF control, SCREEN_OFF followed by true OFF, locked DOZE with valid material, DOZE_SUSPEND with no CPU-driven updates, and direct unlock from ambient. Reorder a delayed ambient callback after unlock, wake, feature disable and service loss. Assert zero stale publications and no duplicate ORB on rapid cycles. Cover 56/112 dp, both ORB and Fluvi mask, a changed palette and an invalidated packet. Keep app decisions and optical assertions separate.

## 14. Visual implementation contract

Prepare an ambient frame from the current verified packet before it is needed. Recheck ownership when using it. Apply the selected size, position, palette and per-size style. Draw only the ORB area, with transparent corners. The dim ambient image may hold a static frame. Preserve the configured animation and accepted entrance on the interactive lockscreen. Respect system brightness, pixel shifting and pocket/schedule suppression. Never keep the normal screen awake, wake it on power-off, paint a fullscreen black cover, hide system controls, change global AOD settings or require privileged access. If the stock phone offers a normal user setting for removing the clock or ambient wallpaper, give its verified settings path. Let the owner decide whether to use it. Report any system UI still visible outside the ORB.

## 15. Performance and diagnostics

Use cached material, event-driven transitions and a bounded per-episode receipt. Avoid polling, periodic alarms, a permanent wake lock, or a Flutter engine refresh loop. Keep the original physical wake target of ≤10 ms and first-forbidden-frame unlock target independent. AOD trials cannot pass the cold-screen wake target. Export build, display, locked/interactive states, monotonic timestamps, owner/generation, style/size, material identity, publish/revoke reason and any error. Record delivery or sampling gaps. Use the existing lockscreen diagnostics Copy flow and preserve the original R55 last-unlock report. Keep private screen and financial content out of logs.

## 16. Implementation order

Verify existing R55 work, reproduce the interactive-only baseline, add control tests, wire the setting to the native authority, implement the specified ambient route, then run focused validation. Continue the independent R55 work if the ambient route meets contrary evidence. Return that evidence to the reviewer before attempting any different presentation architecture.

## 17. Validation and raw artifacts

Run R55’s original gates plus targeted Flutter/Kotlin tests and a signed upgrade with seeded settings. Use these matched physical controls on the combined APK. Start unplugged, face up, with the same location, palette and size. Record the owner-selected system AOD setting and schedule. Start with a recognizable 56 dp Fluvi mask.

| Trial | Expected outcome |
| --- | --- |
| Fluvi option OFF, system AOD enabled | Normal R55 wake/unlock. After sleep, establish the stock ambient image and verify no Fluvi pixels. |
| Fluvi option ON, system AOD enabled | Lock without unlocking. Observe without touch at 10 s, 60 s and 180 s. Check both the ORB and the rest of the panel. Wake to the normal lockscreen. Repeat with direct fingerprint unlock and check for a ghost or duplicate. |
| Fluvi option ON, system AOD disabled or actually suppressed | Once the primary display reaches true OFF, it stays dark. The app never wakes it. Record a missing eligible interval as NOT REACHED. |

Keep one transition-only export and the owner's optical observations for each condition. Separate stable ORB visibility, whole-panel black outside the ORB, interactive animation and first forbidden frame. The steady visual test can be performed by eye. A precisely timed frame claim needs an independent optical reference. A blank system screenshot, a finite observation or an emulator alone cannot establish permanent handset visibility. Cap the initial steady hold at three minutes per condition. There is no corresponding production timeout.

## 18. Commit discipline

Make a scoped addendum commit on top of the verified R55 work. Apply the original commit-body and journal rules. Include the E/H/D update, controls, raw evidence references, limits, protected milestones and remaining decision.

## 19. Build and delivery

After integrating both tasks, produce one full, signed, in-place-upgradeable Fluvi HUMAN APK from the final product SHA. Use the existing signer, package and monotonically valid version. Verify upgrading the signed R54 reference with app data, ORB preferences and widget binding preserved. Verify the public direct APK download, byte size, SHA-256, package/version, signer and embedded source. The app must expose both the R55 Copy action and the new switch.

## 20. Completion report

Provide the direct APK link, source SHA, SHA-256, version, signing/upgrade result and actual PASS / FAIL / NOT RUN per check. Report R55 and the ambient feature independently. Distinguish the implemented route, stock/automated observations, OEM compositor capability, ORB-only visual result and physical acceptance. If the safe candidate can run the experiment but the A142 result is pending, deliver it as a HUMAN test candidate with the three controls above.

## 21. Definition of done

The feature passes on the target phone only when the owner sees the selected ORB remain as the sole visible element throughout a steady, locked ambient interval, sees expected normal behavior with the switch OFF, and verifies clean wake/unlock. Track OS suppression, extra OEM content and missing observations explicitly. Preserve the combined candidate and raw evidence for the reviewer if the requested appearance cannot be qualified. Record **PHYSICAL VALIDATION — PENDING, USER ONLY** until the owner tests the exact APK.

[R55 handoff](https://github.com/elizerpist/exptv2/blob/ba17b72fb69b0e9c97c955e6c79e22dcfbd8941e/docs/FLUVI_ENGINEERING_JOURNAL.md#L26078) · [R52 locked-sleep evidence](https://github.com/elizerpist/exptv2/blob/ba17b72fb69b0e9c97c955e6c79e22dcfbd8941e/docs/diagnostics/FLUVI_R52_ORB_WITHDRAWAL_REVIEW.md#L51) · [R55 product](https://github.com/elizerpist/exptv2/commit/8ddf2946ea3918a55f73330640edb3536d2fffc2) · [Android display states](https://developer.android.com/reference/android/view/Display#STATE_DOZE) · [Android screen-off broadcast](https://developer.android.com/reference/android/content/Intent#ACTION_SCREEN_OFF) · [AOSP always-on display](https://android.googlesource.com/platform/frameworks/base/+/refs/heads/main/packages/SystemUI/docs/device-entry/doze.md)
