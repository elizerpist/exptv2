# R39 exact-source native inventory

Stock application: `fd7112e4e52952caaee1f740526c87f10ddc7cb2`.
Graph manifest: `b8544ab092c6148613188ca5f3ab9f15612c946f:docs/codegraph/manifest.json`.
SCIP-Dart 1.6.2 covers Dart only; the Kotlin entries below are direct source navigation, not SCIP edges or runtime observations. Native submit/commit is not a physical pixel. The SystemUI source is independently pinned at `47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9`.

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

SystemUI reference callers and generation gate:
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:41:import com.fluvi.r29.contract.R39ScenePolicy
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:52:class R38ClockScene @Inject constructor(
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:64:    fun modifier(): Modifier {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:115:            val canDraw = runtime.isOnlyFrameOwner(view, changed) &&
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:144:                runtime.onOwnerDraw(view, changed, orbDrawn = false, noOutgoingScene = noOutgoingScene)
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:146:                runtime.onOwnerDraw(view, changed, orbDrawn = true, noOutgoingScene = false)
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:153:    private fun currentStateAllows(bypass: Boolean, defaultBlueprint: Boolean): Boolean {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:157:            is ObservableTransitionState.Idle -> R39ScenePolicy.allow(R39SceneFacts(
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/clock/src/com/android/systemui/keyguard/fluvi/R38ClockScene.kt:161:            is ObservableTransitionState.Transition.ChangeScene -> R39ScenePolicy.allow(R39SceneFacts(
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/contract/src/com/fluvi/r29/contract/R39ScenePolicy.kt:13:object R39ScenePolicy {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/patches/0002-r38-clock-root.patch:15:+    val fluviFrameOwner: R38ClockScene,
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/patches/0002-r38-clock-root.patch:25:+            Modifier.fillMaxSize().then(viewModel.fluviFrameOwner.modifier()).pointerInput(Unit) {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:229:    private var ownerVisualEpoch = 0L
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:243:    fun isOnlyFrameOwner(view: View, observer: () -> Unit): Boolean = synchronized(observerLock) {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:263:    fun onOwnerDraw(view: View, observer: () -> Unit, orbDrawn: Boolean, noOutgoingScene: Boolean) {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:268:            if (orbDrawn) { ownerVisualEpoch += 1; return }
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:271:            if (value.registered || !store.isCurrentEmpty(value.nonce, value.sequence)) return
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:273:            visualEpoch = ownerVisualEpoch
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/FluviOrbHostService.kt:281:                        ownerVisualEpoch == visualEpoch && store.isCurrentEmpty(pending.nonce, pending.sequence)
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/src/com/android/systemui/keyguard/fluvi/R29ResidentStore.kt:105:    fun isCurrentEmpty(nonce: String, sequence: Long): Boolean = synchronized(lock) {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:4:import com.fluvi.r29.contract.R39ScenePolicy
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:10:class FluviR39ScenePolicyTest {
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:14:        assertTrue(R39ScenePolicy.allow(incoming))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:17:            incoming.copy(userDriven = true)).forEach { assertFalse(R39ScenePolicy.allow(it)) }
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:22:        assertTrue(R39ScenePolicy.allow(idle))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:23:        assertFalse(R39ScenePolicy.allow(idle.copy(noOverlays = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/systemui/tests/com/android/systemui/keyguard/fluvi/FluviR39ScenePolicyTest.kt:24:        assertFalse(R39ScenePolicy.allow(idle.copy(idleLockscreen = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:22:    check(R39ScenePolicy.allow(incoming))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:23:    check(!R39ScenePolicy.allow(incoming.copy(wakingFromOff = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:24:    check(!R39ScenePolicy.allow(incoming.copy(fromAbsent = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:25:    check(!R39ScenePolicy.allow(incoming.copy(toLockscreen = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:26:    check(!R39ScenePolicy.allow(incoming.copy(noOverlays = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:27:    check(!R39ScenePolicy.allow(incoming.copy(userDriven = true)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:29:    check(R39ScenePolicy.allow(idle))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:30:    check(!R39ScenePolicy.allow(idle.copy(noOverlays = false)))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:44:    check(store.isCurrentEmpty(nonce, 2)) { "only the exact invalidation may await an empty-frame receipt" }
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:45:    check(!store.isCurrentEmpty(nonce, 1))
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:51:    check(!store.isCurrentEmpty(nonce, 2)) { "a newer generation revokes the older empty receipt" }
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/ResidentHarness.kt:68:    check(!store.isCurrentEmpty(nonce, 2)) { "an old session must not acquire an empty receipt" }
47acc9a2992cf3a98f9c51082f14fe4e7d0cbef9:platform/aosp16/tests/host_store_harness/run.sh:14:  "$root/platform/aosp16/contract/src/com/fluvi/r29/contract/R39ScenePolicy.kt" \

```
