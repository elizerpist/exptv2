# R39 exact-source native inventory

Stock application: `fd7112e4e52952caaee1f740526c87f10ddc7cb2`.
Graph manifest: `b8544ab092c6148613188ca5f3ab9f15612c946f:docs/codegraph/manifest.json`.
SCIP-Dart 1.6.2 covers Dart only; the Kotlin entries below are direct source navigation, not SCIP edges or runtime observations. Native submit/commit is not a physical pixel. The SystemUI source is independently pinned at `dce225d8b219716510ebb94a5078fc8311fe0e8e`.

```text
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:331:    private val r39RemovalGate = KeyguardR39RemovalGate(queueLock, r18Coordinator)
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:439:                r39RemovalGate.clear()
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:804:            r39RemovalGate.clear()
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1201:                        inspection.authorizingClockWindowId?.let { window ->
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1291:    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1303:                r39RemovalGate.clearFor(token)
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1313:    private fun finishR18Seal(owner: R18Active, identity: R18Identity, reason: String, requestId: Long,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1344:    private fun recordR39(owner: R18Active, phase: String, at: Long,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1821:    internal fun acceptAccessibilityMetadataForTest(meta: KeyguardAccessibilityEventMeta) {
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1826:    private fun acceptAccessibilityMetadata(
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1847:                val withdrawal = r39RemovalGate.remove(meta, callbackReceivedAt, true, own,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1859:                recordR39(sealed.first, "REMOVAL_MATCH", sealedAt, meta = meta,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:1862:                recordR39(capturedOwner, "REMOVAL_FALLBACK", callbackReceivedAt, meta = meta, callbackAt = callbackReceivedAt)
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3684:        val authorizingClockWindowId: Int? = null,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3776:    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:3852:            authorizingClockWindowId = classification.authorizingClockWindowId,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4449:            val window = inspection.authorizingClockWindowId
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4463:                        r39RemovalGate.armPresented(evidence, binding.reveal, inspectionAuthority,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4466:                if (armed) recordR39(staged, "REARMED", SystemClock.uptimeMillis(),
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:4993:                    r18Coordinator.grant(directToken, inspectionAuthority, proof, completeMain = true,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5152:                                val applied = r18Coordinator.markNativeApplyReturned(permit)
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5157:                                    r39RemovalGate.arm(evidence, permit, inspectionAuthority,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5164:                                if (r39Armed != null) recordR39(directOwner, "ARMED", at,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt:5166:                                else recordR39(directOwner, "UNATTRIBUTED", at, identity = r39Identity)
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1049:                    timeline.values["r39Witness"] = "ATTRIBUTED"
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1055:                "R39_UNATTRIBUTED" -> timeline.values.putIfAbsent("r39Witness", "UNATTRIBUTED")
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1056:                "R39_REMOVAL_MATCH", "R39_REMOVAL_FALLBACK" -> {
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1057:                    val countKey = if (event.reason == "R39_REMOVAL_MATCH") "r39Matched" else "r39Fallback"
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:1060:                    if (event.reason == "R39_REMOVAL_MATCH") {
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSettings.kt:2702:                        append(" r39Witness=${value("r39Witness")} r39Window=${value("r39Window")} r39Request=${value("r39Request")} r39ReadEnd=${value("r39ReadEnd")} r39Arm=${value("r39ArmAt")}")
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:33:    val authorizingClockWindowId: Int? = null,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:54:    val verifiedRootWindow: Boolean = false,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt:158:                candidate.windowId >= 0 && candidate.verifiedRootWindow &&
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardWindow.kt:595:    fun sealR18FromAnyThread(attachment: Long, outputGeneration: Long) {
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationCoordinator.kt:283:    fun markNativeApplyReturned(reveal: Reveal): Long? = synchronized(lock) {
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardR39RemovalGate.kt:20:internal class KeyguardR39RemovalGate(
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:692:            val verifiedRootWindow = rootPackage == "com.android.systemui" &&
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt:777:                verifiedRootWindow = verifiedRootWindow,
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:132:    fun sealR18() { direct?.seal() }
fd7112e4e52952caaee1f740526c87f10ddc7cb2:android/app/src/main/kotlin/com/fluvi/app/lockscreen/material/KeyguardOrbSurfacePresenter.kt:133:    fun sealR18(attachment: Long, generation: Long) { direct?.sealMatching(attachment, generation) }

SystemUI reference callers, generation and fence gate:
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:41:import com.fluvi.r29.contract.R39ScenePolicy
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:52:class R38ClockScene @Inject constructor(
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:64:    fun modifier(): Modifier {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:115:            val canDraw = runtime.isOnlyFrameOwner(view, changed) &&
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:144:                runtime.onOwnerDraw(view, changed, orbDrawn = false, noOutgoingScene = noOutgoingScene)
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:146:                runtime.onOwnerDraw(view, changed, orbDrawn = true, noOutgoingScene = false)
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:153:    private fun currentStateAllows(bypass: Boolean, defaultBlueprint: Boolean): Boolean {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:157:            is ObservableTransitionState.Idle -> R39ScenePolicy.allow(R39SceneFacts(
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:161:            is ObservableTransitionState.Transition.ChangeScene -> R39ScenePolicy.allow(R39SceneFacts(
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/contract/src/com/fluvi/r29/contract/R39ScenePolicy.kt:13:object R39ScenePolicy {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/contract/src/com/fluvi/r29/contract/R39ScenePolicy.kt:31:object R39EmptyPolicy {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/patches/0002-r38-clock-root.patch:15:+    val fluviFrameOwner: R38ClockScene,
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/patches/0002-r38-clock-root.patch:25:+            Modifier.fillMaxSize().then(viewModel.fluviFrameOwner.modifier()).pointerInput(Unit) {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:30:import com.fluvi.r29.contract.R39EmptyPolicy
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:234:    private var ownerVisualEpoch = 0L
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:248:    fun isOnlyFrameOwner(view: View, observer: () -> Unit): Boolean = synchronized(observerLock) {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:271:    fun onOwnerDraw(view: View, observer: () -> Unit, orbDrawn: Boolean, noOutgoingScene: Boolean) {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:275:                if (clockObservers.size == 1 && clockObservers[observer] === view) ownerVisualEpoch += 1
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:286:            if (!store.isCurrentEmpty(value.nonce, value.sequence)) return
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:293:            visualEpoch = ownerVisualEpoch
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:306:                transaction.addTransactionCompletedListener(main) { stats ->
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:307:                    val fence = runCatching { stats.presentFence }.getOrNull()
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:321:                                        val valid = R39EmptyPolicy.mayAcknowledge(R39EmptyEvidence(
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:326:                                            noLaterOrbDraw = ownerVisualEpoch == visualEpoch,
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:327:                                            sameEmptyGeneration = store.isCurrentEmpty(pending.nonce, pending.sequence)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:342:                root.applyTransactionOnDraw(transaction)
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:105:    fun isCurrentEmpty(nonce: String, sequence: Long): Boolean = synchronized(lock) {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:5:import com.fluvi.r29.contract.R39EmptyPolicy
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:6:import com.fluvi.r29.contract.R39ScenePolicy
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:12:class FluviR39ScenePolicyTest {
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:16:        assertTrue(R39ScenePolicy.allow(incoming))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:19:            incoming.copy(userDriven = true)).forEach { assertFalse(R39ScenePolicy.allow(it)) }
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:24:        assertTrue(R39ScenePolicy.allow(idle))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:25:        assertFalse(R39ScenePolicy.allow(idle.copy(noOverlays = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:26:        assertFalse(R39ScenePolicy.allow(idle.copy(idleLockscreen = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:30:        assertTrue(R39EmptyPolicy.mayAcknowledge(complete))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:34:            complete.copy(sameEmptyGeneration = false)).forEach { assertFalse(R39EmptyPolicy.mayAcknowledge(it)) }
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:22:    check(R39ScenePolicy.allow(incoming))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:23:    check(!R39ScenePolicy.allow(incoming.copy(wakingFromOff = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:24:    check(!R39ScenePolicy.allow(incoming.copy(fromAbsent = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:25:    check(!R39ScenePolicy.allow(incoming.copy(toLockscreen = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:26:    check(!R39ScenePolicy.allow(incoming.copy(noOverlays = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:27:    check(!R39ScenePolicy.allow(incoming.copy(userDriven = true)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:29:    check(R39ScenePolicy.allow(idle))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:30:    check(!R39ScenePolicy.allow(idle.copy(noOverlays = false)))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:32:    check(R39EmptyPolicy.mayAcknowledge(receipt))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:36:        receipt.copy(sameEmptyGeneration = false)).forEach { check(!R39EmptyPolicy.mayAcknowledge(it)) }
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:50:    check(store.isCurrentEmpty(nonce, 2)) { "only the exact invalidation may await an empty-frame receipt" }
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:51:    check(!store.isCurrentEmpty(nonce, 1))
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:57:    check(!store.isCurrentEmpty(nonce, 2)) { "a newer generation revokes the older empty receipt" }
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:74:    check(!store.isCurrentEmpty(nonce, 2)) { "an old session must not acquire an empty receipt" }
dce225d8b219716510ebb94a5078fc8311fe0e8e:platform/aosp16/tests/host_store_harness/run.sh:14:  "$root/platform/aosp16/contract/src/com/fluvi/r29/contract/R39ScenePolicy.kt" \

```
