package com.fluvi.app.lockscreen

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.AccessibilityServiceInfo
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.hardware.display.DisplayManager
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Display
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.view.accessibility.AccessibilityWindowInfo
import com.fluvi.app.MainActivity
import com.fluvi.app.lockscreen.host.R29Ownership
import com.fluvi.app.lockscreen.host.R29OwnershipStore
import com.fluvi.app.lockscreen.host.R35ResidentPublisher
import com.fluvi.app.lockscreen.host.R38ReferenceAdmission
import com.fluvi.app.runtime.FluviFinancialCardPresenter
import com.fluvi.app.runtime.FluviLockScreenCardContent
import com.fluvi.app.runtime.FluviLockScreenCardCoordinator
import com.fluvi.app.lockscreen.material.KeyguardOrbRetirementEvent
import com.fluvi.app.lockscreen.material.FluviKeyguardMaterialStore
import com.fluvi.app.lockscreen.material.FluviActiveHeaderMaterialStore
import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.app.lockscreen.material.KeyguardOrbOwnershipSlotSnapshot
import com.fluvi.app.lockscreen.material.KeyguardOrbColdWorkSnapshot
import com.fluvi.app.lockscreen.material.KeyguardOrbFirstOfferObservation
import com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceObservation
import com.fluvi.app.lockscreen.material.KeyguardR19FirstPaintTicket
import com.fluvi.app.lockscreen.material.AndroidKeyguardShaderArtifactReader
import com.fluvi.app.lockscreen.material.KeyguardMaterialTimeSource
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicInteger
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicIntegerArray
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.Job
import kotlinx.coroutines.NonCancellable
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.cancel
import kotlinx.coroutines.coroutineScope
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext

/**
 * A single Fluvi-owned, opt-in accessibility overlay. It never reads node
 * text/content descriptions, captures screenshots, performs global actions,
 * or hosts third-party widgets. The service is attached only by Android after
 * the user enables this exact component in Accessibility settings.
 */
class FluviKeyguardCardService : AccessibilityService() {
    private val mainHandler = Handler(Looper.getMainLooper())
    /** The only persistent item is a recovery obligation for a bit we set;
     * it cannot activate a trial or carry display authority across processes. */
    private val r444ProfileOwner by lazy {
        val prefs = getSharedPreferences("fluvi_r444_flag_recovery", Context.MODE_PRIVATE)
        KeyguardR444ProfileOwner(AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS,
            readFlags = { runCatching { serviceInfo?.flags }.getOrNull() },
            writeFlags = { flags -> runCatching {
                val current = requireNotNull(serviceInfo)
                val ownedBit = AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS
                // Another service setting may have changed since the first
                // read: update only the bit that this trial owns.
                current.flags = r444MergeOwnedFlag(current.flags, flags, ownedBit)
                serviceInfo = current
                true
            }.getOrDefault(false) },
            pendingRestore = { runCatching { prefs.getBoolean("restore_owned_bit", false) }.getOrNull() },
            setPendingRestore = { pending -> prefs.edit().putBoolean("restore_owned_bit", pending).commit() })
    }
    @Volatile private var r444ConfigurationReady = Build.VERSION.SDK_INT != 37
    private data class R442ScreenOn(val session: Long, val uptime: Long)
    @Volatile private var r442ScreenOn: R442ScreenOn? = null
    // Protected by queueLock; request replacement cannot buy a second batch
    // in the same physical wake or transfer ownership to another session.
    private val r445WakeBudget = KeyguardR445WakeBudget()
    private data class R442Lookup(val status: String, val identity: String?, val verified: Boolean,
                                  val clockVerified: Boolean = false, val udfpsVerified: Boolean = false,
                                  val smallClockVerified: Boolean = false, val largeClockVerified: Boolean = false)
    @Volatile private var r442Lookup = R442Lookup("UNAVAILABLE", null, false)
    private var r442LookupGeneration = 0L
    private var r442PackageReceiverRegistered = false
    private val r442PackageReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.data?.schemeSpecificPart != "com.android.systemui") return
            if (r446HasBackend()) r446Cancel("systemUiPackageChanged")
            // An updated SystemUI cannot inherit its predecessor's witness.
            r442Lookup = R442Lookup("PENDING", null, false)
            if (::overlay.isInitialized && overlay.isAttached) hideImmediately("systemUiPackageChanged")
            prepareR442ResourceLookup()
        }
    }

    /** Resolve the exact resource once per service/SystemUI installation,
     * away from both capture toggles and the wake-time single reader. */
    private fun prepareR442ResourceLookup() {
        if (Build.VERSION.SDK_INT != 37) return
        val generation = ++r442LookupGeneration
        // Installed-ID lookup is preparation, never a wake-path IPC. If
        // the service comes up while locked, USER_PRESENT schedules it later.
        val keyguard = getSystemService(android.app.KeyguardManager::class.java)
        if (keyguard == null || keyguard.isKeyguardLocked) {
            r442Lookup = R442Lookup("PENDING_UNLOCK", null, false)
            return
        }
        val expectedSession = session.get()
        r442Lookup = R442Lookup("PENDING", null, false)
        CoroutineScope(serviceJob + Dispatchers.IO).launch {
            val lookup = try {
                @Suppress("DEPRECATION")
                val info = packageManager.getPackageInfo("com.android.systemui", 0)
                val identity = "${info.longVersionCode}:${info.lastUpdateTime}"
                val resources = packageManager.getResourcesForApplication("com.android.systemui")
                fun verifiedId(name: String): Boolean = runCatching {
                    val id = resources.getIdentifier(name, "id", "com.android.systemui")
                    id != 0 && resources.getResourceName(id) == "com.android.systemui:id/$name"
                }.getOrDefault(false)
                val verified = verifiedId("device_entry_icon_view")
                R442Lookup(if (verified) "VERIFIED" else "MISSING", identity, verified,
                    clockVerified = verifiedId("keyguard_clock_switch"), udfpsVerified = verifiedId("udfps_view"),
                    smallClockVerified = verifiedId("lockscreen_clock_view"),
                    largeClockVerified = verifiedId("lockscreen_clock_view_large"))
            } catch (_: Exception) {
                R442Lookup("FAILURE", null, false)
            }
            mainHandler.post {
                if (serviceJob.isActive && r442LookupGeneration == generation &&
                    session.get() == expectedSession &&
                    FluviKeyguardCardServiceRegistry.serviceForInstrumentation() === this@FluviKeyguardCardService)
                    r442Lookup = lookup
            }
        }
    }
    // Retail builds never probe a host. The reference-only owner is loaded
    // before any local admission, including after a process restart.
    @Volatile private var referenceOwnership: R29Ownership? = null
    private var referencePublisher: R35ResidentPublisher? = null
    private var referenceFirstFreshService = false
    private var referenceLocalPresentationAttempted = false
    private var referenceServiceSerial = 0L

    @Volatile private var r448DisplayRoute = KeyguardR448DisplayRoute.FLUVI_STREAM
    private var r448RouteGeneration = 0L
    private val r448SampleOnly by lazy { KeyguardR448Safety.sampleOnly(applicationContext) }

    private fun localPresentationAllowed(): Boolean = !r448SampleOnly && r444ConfigurationReady &&
        referenceOwnership?.appMayShow() != false && r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
        r448Frame == null

    /** A prior process may have left native work behind. Only a genuinely
     * fresh reference installation's first service can assert no prior owner. */
    private fun initializeReferenceOwnership() {
        if (Build.TYPE != "userdebug" && Build.TYPE != "eng") return
        val ownership = R29Ownership(R29OwnershipStore(applicationContext))
        referenceOwnership = ownership
        referenceServiceSerial += 1
        if (!ownership.appMayShow()) return
        referenceFirstFreshService = runCatching {
            val prefs = getSharedPreferences("fluvi_r38_reference_admission", Context.MODE_PRIVATE)
            val unseen = !prefs.contains("serviceStarted")
            @Suppress("DEPRECATION") val info = packageManager.getPackageInfo(packageName, 0)
            val fresh = info.firstInstallTime == info.lastUpdateTime
            val saved = prefs.edit().putBoolean("serviceStarted", true).commit()
            unseen && fresh && saved
        }.getOrDefault(false)
    }

    /** Main-owned check; all native borrowers are checked by exact ownership. */
    private fun referenceOldOwnerAbsent(): Boolean {
        if (!::overlay.isInitialized || overlay.isAttached || referenceLocalPresentationAttempted || r18Active != null)
            return false
        return synchronized(queueLock) {
            val state = r18Coordinator.snapshot()
            r18ProvisionalWake == null && state.reservation == null && state.activeOutputs == 0 &&
                r18DrainBindings.all { it == null || it.drained }
        }
    }

    /** The reference host is discovered while unlocked, never by a wake path. */
    private fun startReferenceEnrollmentIfEligible() {
        if (r448SampleOnly) return
        val owner = referenceOwnership ?: return
        if (!referenceFirstFreshService || !owner.appMayShow() || referencePublisher != null) return
        val settings = lastSettings ?: return
        // Other modes have no revisioned FULL projection in the current bridge.
        if (!settings.requested || settings.presentationMode != KeyguardCardPresentationMode.ORB ||
            settings.focus.mode.name != "budget" || settings.focus.categoryId.isNullOrBlank()) return
        val serial = referenceServiceSerial
        lateinit var publisher: R35ResidentPublisher
        publisher = R35ResidentPublisher(applicationContext, owner,
            java.util.concurrent.Executor { task -> mainHandler.post(task) },
            object : R35ResidentPublisher.Listener {
                override fun onReady(session: String, sequence: Long) = Unit
                override fun onUnavailable() = Unit
                override fun onEmpty(session: String, sequence: Long, epoch: Long) {
                    if (serial != referenceServiceSerial || !serviceJob.isActive) publisher.close()
                }
            })
        referencePublisher = publisher
        publisher.probePrimaryHost { verified ->
            if (!serviceJob.isActive || serial != referenceServiceSerial || referencePublisher !== publisher) return@probePrimaryHost
            if (!verified) {
                referencePublisher = null
                publisher.close()
                return@probePrimaryHost
            }
            val keyguard = getSystemService(android.app.KeyguardManager::class.java)
            val power = getSystemService(android.os.PowerManager::class.java)
            val unlocked = keyguard != null && power != null && !keyguard.isKeyguardLocked && power.isInteractive
            val noOld = referenceOldOwnerAbsent()
            val evidence = R38ReferenceAdmission.Evidence(
                trustedHost = true, firstServiceOnFreshInstall = referenceFirstFreshService,
                unlocked = unlocked, noLocalPresentation = noOld,
                noReservation = noOld, noOwnedOutput = noOld,
            )
            val epoch = R38ReferenceAdmission(owner).begin(evidence) {
                keyguard?.isKeyguardLocked == false && power?.isInteractive == true && referenceOldOwnerAbsent()
            }
            if (epoch != null) publisher.connectAfterDrain(epoch)
            else { referencePublisher = null; publisher.close() }
        }
    }
    private val platformSystemStateReader by lazy { AndroidKeyguardSystemStateReader(this) }
    @Volatile internal var systemStateReaderOverride: KeyguardSystemStateReader? = null
    /** Optional instrumentation seam. It orders a negative acquisition/result;
     * it never skips the production classifier, authority gate or admission. */
    @Volatile internal var inspectionProbeForTest: KeyguardInspectionProbeForTest? = null
    /** Fixture-only count of completed-read R25 evaluations; null in production. */
    @Volatile internal var r41R25EvaluationsForTest: AtomicLong? = null
    internal fun inspectionStateForTest() = KeyguardInspectionStateForTest(
        inspectionAuthority, synchronized(queueLock) { inspectionQueue.pendingRequest() },
        wakeCycleOwner.current()?.id, ::overlay.isInitialized && overlay.isAttached, retryCount,
    )
    internal fun knownOwnOverlayIdentityForTest(): KeyguardOwnOverlayIdentity? = knownOwnOverlayIdentity
    /** A test-only scalar view of the existing owner and host geometry. */
    internal fun r22VisualIdentityForTest(): KeyguardR22VisualIdentityForTest? {
        check(Looper.myLooper() == Looper.getMainLooper())
        val owner = r18Active ?: return null
        val host = owner.host ?: return null
        val output = owner.output as? com.fluvi.app.lockscreen.material.KeyguardOrbDirectOutput ?: return null
        if (!host.isAttachedToWindow || host.width <= 0 || host.height <= 0) return null
        val snapshot = r18Coordinator.snapshot()
        if (snapshot.reservation !== owner.token) return null
        val location = IntArray(2)
        host.getLocationOnScreen(location)
        return KeyguardR22VisualIdentityForTest(owner.token.id, owner.token.stamp.firstRequestId,
            snapshot.proofRequestId, System.identityHashCode(host), output.attachment, output.generation,
            output.childId, android.graphics.Rect(location[0], location[1],
                location[0] + host.width, location[1] + host.height))
    }
    private val systemReads = java.util.concurrent.atomic.AtomicLongArray(KeyguardSystemReadPurpose.entries.size)
    private val mainSystemReads = java.util.concurrent.atomic.AtomicLongArray(KeyguardSystemReadPurpose.entries.size)
    private fun readSystemState(purpose: KeyguardSystemReadPurpose): KeyguardSystemState {
        systemReads.incrementAndGet(purpose.ordinal)
        if (Looper.myLooper() == Looper.getMainLooper()) mainSystemReads.incrementAndGet(purpose.ordinal)
        return withMainWorkEvidence(KeyguardMainWorkEvidence.SYSTEM_GATE) {
            (systemStateReaderOverride ?: platformSystemStateReader).read(purpose)
        }
    }

    internal fun requestSystemCheckForTest() { requestSystemCheck("blockedReaderRegression") }
    internal fun r447ScheduleOutputReadyForTest() {
        check(KeyguardR447TestHooks.CONTROLLED_TOPOLOGY)
        requestSystemCheck("r18Ready", evaluate = true, sampleOrigin = R447SystemOrigin.INTERNAL_OUTPUT_READY)
    }
    internal fun r447SampleOrderForTest(request: Long): KeyguardFirstAuthorizedOrb.SampleOrder = synchronized(queueLock) {
        firstAuthorizedOrb.sampleOrder(request, firstAuthorizedOrb.sceneSerial())
    }
    internal fun r447SamplerIdleForTest(): Boolean = !systemSampler.hasOutstandingWork()

    internal fun renderModeStatus(): KeyguardOrbRenderModeStatus {
        check(Looper.myLooper() == Looper.getMainLooper())
        val configured = KeyguardOrbRenderModeStore.read(applicationContext)
        return if (::overlay.isInitialized) overlay.renderModeStatus()
        else KeyguardOrbRenderModeStatus(configured, configured, visible = false)
    }

    internal fun r448SafetyForInstrumentation(): Triple<Boolean, Boolean, Boolean> =
        Triple(r448SampleOnly, localPresentationAllowed(), lastMaterialProfile != null)

    /** Selection revokes the previous route before accepting a new owner. */
    internal fun setR448DisplayRoute(route: KeyguardR448DisplayRoute): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (getSystemService(android.app.KeyguardManager::class.java)?.isKeyguardLocked != false ||
            !FluviKeyguardCardServiceRegistry.connected) return false
        if (r448DisplayRoute == route) return true
        if ((KeyguardR44Trial.active || r446CaptureId != null) && !stopR444Trial("ROUTE_CHANGED")) return false
        if (r448Frame != null) {
            r446Cancel("ROUTE_CHANGED")
            if (r448Frame != null) return false
        }
        hideImmediately("r448RouteChanged")
        if (::overlay.isInitialized && overlay.isAttached) return false
        r448RouteGeneration++
        r448DisplayRoute = route
        refreshR18RouteOnMain()
        publishReadAheadState(invalidate = true)
        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM)
            requestSystemCheck("r448RouteChanged", evaluate = true)
        return true
    }

    internal fun r448DisplayRouteStatus(): Map<String, Any> {
        check(Looper.myLooper() == Looper.getMainLooper())
        val active = when {
            r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r448Frame?.isAttached() == true -> "WIDGETS_ANYWHERE"
            r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
                ((::overlay.isInitialized && overlay.isAttached) ||
                    (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED && r446Observation?.submittedAt != null)) -> "FLUVI_STREAM"
            else -> "NONE"
        }
        return mapOf("configured" to r448DisplayRoute.name, "active" to active,
            "generation" to r448RouteGeneration,
            "sampleOnly" to r448SampleOnly,
            "reason" to if (r448SampleOnly && !KeyguardR44Trial.active) "SAMPLE_ONLY_NORMAL_DISABLED"
                else if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) "PUBLIC_SAMPLE_ONLY" else "NONE")
    }

    /** Bounded test observation of the current authorized target. The
     * service and the Window remain the only owners of display authority. */
    internal fun surfaceMetricsForInstrumentation() =
        if (::overlay.isInitialized) overlay.surfaceMetricsForTest() else null

    /** A selector changes no active presentation. Detached preparation may
     * use the new choice before the next independently authorized show. */
    internal fun onOrbRenderModeChanged() {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "routeChanged")
        synchronized(queueLock) { firstAcquisition.invalidate() }
        publishReadAheadState(invalidate = true)
        clearR14Recovery("routeChanged")
        val hadR18 = r18Active != null
        if (hadR18) hideImmediately("r18RouteChanged", terminalWake = false)
        if (::overlay.isInitialized && !overlay.isAttached) {
            overlay.prepareRetainedView(lastSettings ?: FluviKeyguardCardSettings.read(applicationContext), lastMaterialProfile)
        }
        refreshR18RouteOnMain()
        if (hadR18) requestSystemCheck("r18RouteChanged", evaluate = true)
    }

    /** Explicit unlocked owner action. Dispose every previously prepared
     * surface before switching material domains and invalidate old reads. */
    internal fun setR44SyntheticTrial(enabled: Boolean, expanded: Boolean = false): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        invalidateR442Receipt("trialChanged")
        if (Build.VERSION.SDK_INT != 37 || !KeyguardOrbRenderModeStore.diagnosticBuild(applicationContext)) return false
        val km = getSystemService(android.app.KeyguardManager::class.java) ?: return false
        if (km.isKeyguardLocked || !::overlay.isInitialized || !FluviKeyguardCardServiceRegistry.connected) return false
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        if (enabled && (!settings.requested || settings.presentationMode != KeyguardCardPresentationMode.ORB)) return false
        val current = r444ProfileOwner.snapshot
        if (enabled && KeyguardR44Trial.active &&
            ((expanded && current.kind == KeyguardR444ProfileOwner.Kind.EXPANDED) ||
                (!expanded && current.kind in setOf(KeyguardR444ProfileOwner.Kind.STANDARD,
                    KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED)))) return true
        if (!enabled) return stopR444Trial("trialStopped")
        hideImmediately("r444ProfileChange")
        if (overlay.isAttached) return false
        visibilityEpoch.incrementAndGet()
        interactionEpoch.incrementAndGet()
        synchronized(queueLock) { inspectionQueue.clearPending() }
        publishInspectionAuthority()
        stopFinancialObservation()
        invalidateFullContent()
        overlay.clearPrivateOrbPoster()
        overlay.dispose()
        KeyguardR44Trial.set(false, false)
        val configured = r444ProfileOwner.start(expanded)
        r444ConfigurationReady = r444ProfileOwner.snapshot.ready
        if (!configured || !r444ConfigurationReady) return false
        KeyguardR44Trial.set(true, r442Lookup.verified)
        return runCatching {
            overlay.prepareRetainedView(settings, lastMaterialProfile)
            true
        }.getOrElse {
            KeyguardR44Trial.set(false, false)
            r444ConfigurationReady = r444ProfileOwner.stop()
            runCatching { overlay.dispose() }
            false
        }
    }

    /** Safe even when no capture is open or the device has just locked. */
    internal fun stopR444Trial(reason: String = "captureStopped"): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (Build.VERSION.SDK_INT != 37) return true
        r449Session = null
        r446Cancel(reason)
        r47RecordingHeader = false
        r47Header = null
        r446CaptureId = null
        val active = KeyguardR44Trial.active || r444ProfileOwner.snapshot.kind != KeyguardR444ProfileOwner.Kind.INACTIVE
        invalidateR442Receipt(reason)
        if (active) {
            if (::overlay.isInitialized) hideImmediately("r444:$reason")
            visibilityEpoch.incrementAndGet()
            interactionEpoch.incrementAndGet()
            synchronized(queueLock) { inspectionQueue.clearPending() }
            publishInspectionAuthority()
            stopFinancialObservation()
            invalidateFullContent()
            if (::overlay.isInitialized) {
                overlay.clearPrivateOrbPoster()
                overlay.dispose()
            }
            KeyguardR44Trial.set(false, false)
        }
        r444ConfigurationReady = r444ProfileOwner.stop()
        if (active && r444ConfigurationReady && ::overlay.isInitialized) runCatching {
            overlay.prepareRetainedView(lastSettings ?: FluviKeyguardCardSettings.read(applicationContext), lastMaterialProfile)
        }
        return r444ConfigurationReady
    }

    private data class R442Receipt(val capture: String, val session: Long, val process: String,
                                   val profileRevision: Long)
    @Volatile private var r442Receipt: R442Receipt? = null
    private var r442Starting = false
    private var r442Reason = "notStarted"
    private var r442ReceiptRevision = 0L

    private fun invalidateR442Receipt(reason: String) {
        r442Receipt = null
        r442Reason = reason
        r442ReceiptRevision += 1
    }

    private fun rejectR442Start(reason: String): Map<String, Any?> {
        invalidateR442Receipt(reason)
        return mapOf("active" to false, "reason" to reason)
    }

    /** The service owns both the sample domain and the capture receipt. The
     * reducer may run off Main, but only this service/session can acknowledge
     * the resulting ID. No receipt survives a rebind or capture replacement. */
    internal suspend fun startR442SampleCapture(
        build: String?, buildMode: String?, captureMode: String?, expanded: Boolean = false,
        oneWakePrint: Boolean = false,
        r46Request: String? = null, r46Route: String? = null,
    ): Map<String, Any?> {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (r442Starting) return mapOf("active" to false, "reason" to "startInProgress")
        val previousReceipt = r442Receipt
        if (previousReceipt != null && KeyguardCardDiagnostics.activeCaptureId() == previousReceipt.capture)
            return mapOf("active" to false, "reason" to "trialAlreadyActive")
        if (previousReceipt != null && KeyguardR44Trial.active && !stopR444Trial("captureReplaced"))
            return mapOf("active" to false, "reason" to "profileRestoreFailed")
        invalidateR442Receipt("starting")
        if (Build.VERSION.SDK_INT != 37 || !KeyguardOrbRenderModeStore.diagnosticBuild(applicationContext))
            return rejectR442Start("unsupportedBuild")
        if (FluviKeyguardCardServiceRegistry.serviceForInstrumentation() !== this ||
            !FluviKeyguardCardServiceRegistry.connected || !::overlay.isInitialized)
            return rejectR442Start("serviceUnavailable")
        val km = getSystemService(android.app.KeyguardManager::class.java)
            ?: return rejectR442Start("keyguardUnavailable")
        if (km.isKeyguardLocked) return rejectR442Start("phoneLocked")
        if (r442Lookup.status == "PENDING_UNLOCK" || r442Lookup.status == "UNAVAILABLE")
            prepareR442ResourceLookup()
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        if (!settings.requested || settings.presentationMode != KeyguardCardPresentationMode.ORB)
            return rejectR442Start("orbServiceNotEnabled")
        r442Starting = true
        var accepted = false
        try {
            if (!setR44SyntheticTrial(true, expanded) || !KeyguardR44Trial.active ||
                KeyguardR44Trial.profile(null) == null || KeyguardR44Trial.settings(settings).showFinancialDetails ||
                !overlay.r442SamplePrepared())
                return rejectR442Start("samplePreparationFailed")
            val expectedSession = session.get()
            val expectedProcess = KeyguardCardDiagnostics.currentProcessInstanceId()
            val expectedRevision = r442ReceiptRevision
            val expectedProfileRevision = r444ProfileOwner.snapshot.revision
            val snapshot = withContext(Dispatchers.IO) {
                KeyguardCardDiagnostics.startCapture(applicationContext, build, buildMode, captureMode, r46Request != null,
                    r442ExpectedSession = expectedSession, r446PrintRequested = oneWakePrint,
                    r46Request = r46Request, r46Route = r46Route)
            }
            val id = snapshot["captureId"] as? String
            if (id == null || snapshot["captureState"] != "REC" ||
                KeyguardCardDiagnostics.activeCaptureId() != id ||
                FluviKeyguardCardServiceRegistry.serviceForInstrumentation() !== this ||
                !FluviKeyguardCardServiceRegistry.connected || session.get() != expectedSession ||
                KeyguardCardDiagnostics.currentProcessInstanceId() != expectedProcess || !KeyguardR44Trial.active ||
                r442ReceiptRevision != expectedRevision || !overlay.r442SamplePrepared() ||
                r444ProfileOwner.snapshot.revision != expectedProfileRevision || !r444ProfileOwner.snapshot.ready) {
                invalidateR442Receipt("serviceOrCaptureChanged")
                return mapOf("active" to false, "reason" to r442Reason, "snapshot" to snapshot)
            }
            r442Receipt = R442Receipt(id, expectedSession, expectedProcess, expectedProfileRevision)
            r442Reason = "armed"
            accepted = true
            return r442SampleStatus() + mapOf("snapshot" to snapshot)
        } catch (cancelled: CancellationException) {
            invalidateR442Receipt("startCancelled")
            throw cancelled
        } catch (failure: Exception) {
            invalidateR442Receipt("captureFailed")
            return mapOf("active" to false, "reason" to "captureFailed", "errorClass" to failure.javaClass.simpleName)
        } finally {
            if (!accepted && KeyguardR44Trial.active &&
                FluviKeyguardCardServiceRegistry.serviceForInstrumentation() === this) {
                val failureReason = r442Reason
                stopR444Trial("startFailed")
                r442Reason = failureReason
            }
            r442Starting = false
        }
    }

    internal fun r442SampleStatus(): Map<String, Any?> {
        check(Looper.myLooper() == Looper.getMainLooper())
        val receipt = r442Receipt
        val observedFlags = runCatching { serviceInfo?.flags }.getOrNull()
        val profileBefore = r444ProfileOwner.snapshot
        val included = observedFlags?.let { it and AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS != 0 }
        val flagMatches = included != null && when (profileBefore.kind) {
            KeyguardR444ProfileOwner.Kind.EXPANDED, KeyguardR444ProfileOwner.Kind.STANDARD_ALREADY_INCLUDED -> included
            KeyguardR444ProfileOwner.Kind.STANDARD -> !included
            else -> false
        }
        if (receipt != null && (FluviKeyguardCardServiceRegistry.serviceForInstrumentation() !== this ||
                !FluviKeyguardCardServiceRegistry.connected || session.get() != receipt.session ||
                KeyguardCardDiagnostics.currentProcessInstanceId() != receipt.process ||
                KeyguardCardDiagnostics.activeCaptureId() != receipt.capture || !KeyguardR44Trial.active ||
                r444ProfileOwner.snapshot.revision != receipt.profileRevision || !profileBefore.ready || !flagMatches)) {
            if (KeyguardR44Trial.active) stopR444Trial("serviceOrCaptureChanged")
            else invalidateR442Receipt("serviceOrCaptureChanged")
        }
        val current = r442Receipt
        val profile = r444ProfileOwner.snapshot
        val printState = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) when (r45Wa.phase) {
            KeyguardR45Phase.PREPARED -> "WAIT_OFF"
            KeyguardR45Phase.WAIT_WAKE -> "WAIT_WAKE"
            KeyguardR45Phase.OPENING -> "WAIT_READ"
            KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED -> "ISSUED"
            KeyguardR45Phase.RETIRED -> "CONSUMED"
        } else r446Owner.state.name
        return mapOf("active" to (current != null), "reason" to r442Reason,
            "captureId" to current?.capture, "serviceSession" to current?.session,
            "process" to current?.process, "materialDomain" to if (current != null) "fixedSample" else "none",
            "profile" to profile.kind.name, "profileRevision" to profile.revision,
            "previousFlags" to profile.before, "actualFlags" to if (current != null) observedFlags else profile.actual,
            "printArmed" to (current != null && printState in setOf("WAIT_OFF", "WAIT_WAKE", "WAIT_READ", "ISSUED")),
            "routeConfirmed" to r448DisplayRoute.name, "actionKind" to r449Action,
            "sampleShape" to if (r45Circle) "CIRCLE" else "ORB",
            "printState" to printState, "printReason" to r449LastTerminal,
            "sessionExpiresAt" to r449Session?.expiresAt,
            "includeNotImportant" to (if (current != null) included else
                profile.actual?.let { it and AccessibilityServiceInfo.FLAG_INCLUDE_NOT_IMPORTANT_VIEWS != 0 }) )
    }

    // Separate from the normal classification and financial grant. The
    // capability and all surface objects are process-local and single-use.
    private val r446Owner = KeyguardR446PrintOwner()
    @Volatile private var r446ReadArm: KeyguardR446PrintOwner.Arm? = null
    @Volatile private var r446CaptureId: String? = null
    @Volatile private var r446Preparing = false
    @Volatile private var r446RestrictionSeen = false
    @Volatile private var r446TicketActive = false
    // A system sampler obligation can be coalesced before it becomes an
    // inspection. Remember it separately so a later internal offer cannot
    // erase that safety boundary. All accesses use queueLock.
    private var r447SystemBarrier = 0L
    private var r447SystemSatisfied = 0L
    private var r447DecisionOrdinal = 0L
    private var r446Presenter: KeyguardR446WindowPresenter? = null
    @Volatile private var r47RecordingHeader = false
    @Volatile private var r47Header: FluviActiveHeaderMaterialStore.Snapshot? = null

    private fun r47HeaderCurrent(): Boolean = !r47RecordingHeader || r47Header?.let {
        FluviActiveHeaderMaterialStore.isCurrentReference(it)
    } == true

    private fun r47PrivateAllowed(surface: KeyguardSurface, state: KeyguardSystemState?, complete: Boolean): Boolean {
        if (!r47RecordingHeader) return true
        val material = r47Header ?: return false
        val settings = lastSettings ?: return false
        val currentState = state ?: return false
        if (settings.generation != material.settingsGeneration || settings.presentationMode != KeyguardCardPresentationMode.ORB ||
            !FluviActiveHeaderMaterialStore.isCurrentReference(material)) return false
        val signals = KeyguardCardSignals(settings.requested, FluviKeyguardCardServiceRegistry.connected,
            currentState.userUnlocked, currentState.primaryDisplay, currentState.interactive, currentState.displayOn,
            currentState.keyguardLocked, surface, settings.showFinancialDetails, currentState.available,
            currentState.displayOff)
        return KeyguardR47PrivateAdmission.allows(signals, complete, materialCurrent = true)
    }
    @Volatile private var r448Frame: KeyguardR448WidgetsAnywhereFrame? = null
    private var r448FrameOwner: KeyguardR448WidgetsAnywhereFrame.Owner? = null
    private var r448FrameGeneration = 0L
    private var r448HideAt: Long? = null
    private var r448RemoveAt: Long? = null
    private var r448RetireError: String? = null
    private fun r446HasBackend() = r446Presenter != null || r448Frame != null

    /** Separate public-display lease: a Fluvi target, scene serial and R446
     * ticket are deliberately not inputs to this route. Main owns the lease;
     * the revision is also sampled by the bounded worker. */
    private val r45Wa = KeyguardR45WaLifetime()
    private val r45Direct = KeyguardR45DirectLifetime()
    private val r45IngressSequence = AtomicLong(0)
    private val r45DirectRevision = AtomicLong(0)
    @Volatile private var r45WaOwnIdentity: KeyguardOwnOverlayIdentity? = null
    private var r45DirectReadActive = false
    private var r45DirectReadPending = false
    private var r45DirectLower: List<KeyguardR45LowerWindow> = emptyList()
    private var r45Circle = false

    private data class R449Wake(
        val arm: KeyguardR45SampleIntent, val context: KeyguardDiagnosticContext,
        val owner: KeyguardR448WidgetsAnywhereFrame.Owner, val screenAt: Long, var expiresAt: Long = Long.MAX_VALUE,
        var issued: Boolean = false, var allowedRevision: Long = -1L, var issueAt: Long? = null,
        var lower: List<KeyguardR45LowerWindow> = emptyList(),
        var validatorRetryRevision: Long = -1L,
        var pendingValidation: ((Boolean) -> Unit)? = null,
        var privateSurface: KeyguardSurface = KeyguardSurface.UNKNOWN,
    )
    @Volatile private var r449Wake: R449Wake? = null
    private val r449RestrictionRevision = AtomicLong(0)
    private var r449ReadActive = false
    private var r449ReadPending = false
    private var r449FirstRead = true
    private var r449Action = "ONE_WAKE"
    private var r449LastTerminal = "UNOBSERVED"
    private data class R449FluviRecovery(val observation: KeyguardR449RecoveryObservation,
                                          val arm: KeyguardR446PrintOwner.Arm, var consumed: Boolean = false)
    private var r449FluviRecovery: R449FluviRecovery? = null
    private data class R449Session(val capture: String, val serviceSession: Long, val route: KeyguardR448DisplayRoute,
                                   val routeGeneration: Long, val expiresAt: Long, val circle: Boolean)
    private var r449Session: R449Session? = null
    private var r449SessionPreparing = false

    private fun r449Current(wake: R449Wake, revision: Long): Boolean =
        r449Wake === wake && r449RestrictionRevision.get() == revision &&
            r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE &&
            r448RouteGeneration == wake.owner.route && FluviKeyguardCardServiceRegistry.connected &&
            r448FrameOwner == wake.owner && r45Wa.current(wake.arm, wake.owner.wake, wake.owner.material) &&
            session.get() == wake.arm.session && wakeEpoch == wake.owner.wake &&
            KeyguardCardDiagnostics.activeCaptureId() == wake.arm.capture &&
            KeyguardR44Trial.active && r47HeaderCurrent() && SystemClock.uptimeMillis() < wake.expiresAt

    private fun r449BeginWake(arm: KeyguardR45SampleIntent, screenAt: Long) {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) return
        val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
        val prepared = r448FrameOwner ?: return r446Cancel("wa:missingOwner")
        val context = currentDiagnosticAttempt?.takeIf { it.captureId == arm.capture &&
            it.serviceSession == arm.session && it.originWakeEpoch == wakeEpoch }
            ?: return r446Cancel("wa:missingCaptureContext")
        val bound = prepared.copy(wake = wakeEpoch)
        if (!frame.bindWake(prepared, bound)) return r446Cancel("wa:ownerBindFailed")
        if (!r45Wa.bind(arm, bound.wake, bound.material)) return r446Cancel("wa:lifetimeBindFailed")
        r448FrameOwner = bound
        val wake = R449Wake(arm, context, bound, screenAt)
        r449Wake = wake
        r449RestrictionRevision.incrementAndGet()
        r449ReadPending = false
        r449FirstRead = true
        runCatching { KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, r446ArmAt,
            wakeEpoch, 0, "UNOBSERVED", "UNOBSERVED", "NOT_ATTEMPTED", null, null, null, null,
            null, null, null, null, "UNOBSERVED", armGeneration = arm.generation, wakeArmState = "ARMED")) }
        r45RecordStage(context, "WIDGETS_ANYWHERE", "INTENT", SystemClock.uptimeMillis(),
            detail = if (arm.circle) "CIRCLE" else "ORB")
        r449ScheduleRead()
    }

    private fun r45TryBeginWaWake() {
        val arm = r45Wa.intent ?: return
        val screen = r442ScreenOn ?: return
        if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE || r449Wake != null ||
            r45Wa.phase != KeyguardR45Phase.OPENING || screen.session != arm.session ||
            wakeCycleOwner.current()?.id != wakeEpoch || currentDiagnosticAttempt == null) return
        r449BeginWake(arm, screen.uptime)
    }

    private fun r45RecordStage(context: KeyguardDiagnosticContext?, route: String, stage: String, at: Long,
                               decision: String = "UNOBSERVED", revision: Long = 0L,
                               readStart: Long? = null, readEnd: Long? = null, detail: String = "UNOBSERVED") {
        if (context == null) return
        runCatching { KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(context, route, stage, at,
            decision = decision, revision = revision, readStart = readStart, readEnd = readEnd, detail = detail)) }
    }

    private fun r45RecordIngress(context: KeyguardDiagnosticContext?, route: String, sequence: Long,
                                 meta: KeyguardAccessibilityEventMeta, receivedAt: Long, own: Boolean,
                                 decision: KeyguardR45IngressAction, phase: String, revision: Long) {
        if (context == null) return
        val origin = when {
            own -> "EXACT_OWN"
            decision == KeyguardR45IngressAction.IGNORE && meta.displayId > 0 -> "OTHER_DISPLAY"
            decision == KeyguardR45IngressAction.IGNORE -> "VERIFIED_LOWER"
            meta.packageName == null -> "UNKNOWN"
            meta.packageName == packageName -> "SAME_PACKAGE_UNVERIFIED"
            meta.packageName == "com.android.systemui" -> "SYSTEM_UI"
            else -> "OTHER"
        }
        runCatching { KeyguardCardDiagnostics.recordR45(KeyguardR45Observation(context, route, "INGRESS", receivedAt,
            sequence, meta.eventTimeUptimeMs?.takeIf { it in 1..receivedAt }, meta.eventType, meta.windowChanges,
            meta.windowId.takeIf { it >= 0 }, meta.displayId.takeIf { it >= 0 }, origin, decision.name, phase, revision)) }
    }

    private fun r45DirectCurrent(lease: KeyguardR45DirectLifetime.Lease): Boolean =
        r45Direct.current(lease, SystemClock.uptimeMillis()) &&
            FluviKeyguardCardServiceRegistry.connected &&
            r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM && r448RouteGeneration == lease.route &&
            session.get() == lease.session && wakeEpoch == lease.wake &&
            KeyguardCardDiagnostics.activeCaptureId() == lease.capture && KeyguardR44Trial.active &&
            r47HeaderCurrent() && r446Presenter != null

    /** One in-flight and one latest pending recheck for this exact target.
     * A partial inventory or an unverified parent keeps the child hidden. */
    private fun r45ScheduleDirectRead(lease: KeyguardR45DirectLifetime.Lease) {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (!r45DirectCurrent(lease)) return
        if (r45DirectReadActive) { r45DirectReadPending = true; return }
        val revision = r45DirectRevision.get()
        r45DirectReadActive = true
        r449Scope.launch {
            val started = SystemClock.uptimeMillis()
            val lookup = r442Lookup
            val read = runCatching {
                KeyguardWindowSnapshotReader(this@FluviKeyguardCardService, packageName).read(
                    KeyguardWindowSnapshotReader.Request(knownOwn = null, attachGeneration = 0,
                        freshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY,
                        strictOwnAttribution = true, r44Enabled = true, r443Sample = true,
                        r443Diagnostics = true, r444UdfpsVerified = lookup.udfpsVerified, r446Print = true),
                    authorityIsCurrent = { r45Direct.lease === lease && r45DirectRevision.get() == revision &&
                        session.get() == lease.session && KeyguardR44Trial.active },
                )
            }.getOrNull()
            val ended = SystemClock.uptimeMillis()
            val state = runCatching { readSystemState(KeyguardSystemReadPurpose.PUBLICATION) }
                .getOrElse { KeyguardSystemState(-1L, -1L, available = false) }
            val classification = read?.let { KeyguardR44SurfaceClassifier.classify(it.snapshots,
                it.rootUnavailable, it.walkTruncated, strictOwnAttribution = true, syntheticTrial = true) }
            val target = if (read != null && classification != null && !read.abortedStale)
                KeyguardR446PrintPolicy.evaluate(read.snapshots, classification, read.rootUnavailable, read.walkTruncated)
            else null
            val restrictions = KeyguardR449RestrictionEvidence.fromInventory(read?.snapshots.orEmpty(), ended,
                read == null || read.rootUnavailable || read.abortedStale, read?.walkTruncated == true)
            val values = restrictions.exclusions.let { listOf(it.credential, it.shade, it.foreign, it.powerMenu) }
            val restricted = state.excluded || target?.reason == "RESTRICTION" ||
                values.any { it == KeyguardR448Admission.Presence.PRESENT }
            val normal = read?.let { KeyguardR44SurfaceClassifier.classify(it.snapshots, it.rootUnavailable,
                it.walkTruncated, strictOwnAttribution = true, syntheticTrial = false).surface }
                ?: KeyguardSurface.UNKNOWN
            val allowed = state.eligible && state.startedAt >= ended && target?.target == lease.target &&
                values.all { it == KeyguardR448Admission.Presence.CLEAR } &&
                r47PrivateAllowed(normal, state, read != null && !read.rootUnavailable && !read.walkTruncated && !read.abortedStale)
            mainHandler.post {
                r45DirectReadActive = false
                if (r45DirectCurrent(lease) && r45DirectRevision.get() == revision) {
                    val result = if (restricted) "RESTRICTED" else if (allowed) "ALLOW" else "UNKNOWN"
                    r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "RECOVERY", SystemClock.uptimeMillis(),
                        result, revision, started, ended, target?.reason ?: restrictions.reason)
                    if (restricted) r446Cancel("direct:restriction")
                    else if (allowed && r45Direct.phase == KeyguardR45Phase.SUSPENDED) {
                        r45DirectLower = restrictions.lower
                        r45Direct.visible(lease)
                        val valid = { r45DirectCurrent(lease) && r45DirectRevision.get() == revision }
                        val resumed = r446Presenter?.resume(lease.token, valid, valid) {
                            if (r45Direct.lease === lease && r45Direct.phase != KeyguardR45Phase.SUSPENDED)
                                r446Cancel("direct:ownerExpiredOrChanged")
                        } == true
                        if (resumed) r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "REVEAL",
                            SystemClock.uptimeMillis(), revision = revision, detail = "resume")
                        else r45Direct.suspend(lease)
                    }
                }
                if (r45DirectReadPending && r45Direct.lease != null) {
                    r45DirectReadPending = false
                    r45Direct.lease?.let(::r45ScheduleDirectRead)
                }
            }
        }
    }

    /** At most one inventory and one pending revision. All platform reads
     * occur off Main; unknown or stale evidence cannot grant the public view. */
    private fun r449ScheduleRead() {
        check(Looper.myLooper() == Looper.getMainLooper())
        val wake = r449Wake ?: return
        if (r449ReadActive) { r449ReadPending = true; return }
        val revision = r449RestrictionRevision.get()
        if (!r449Current(wake, revision)) return
        val own = r448Frame?.ownIdentity(wake.owner)
        r45WaOwnIdentity = own
        val freshness = if (r449FirstRead) KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
            else KeyguardWindowFreshness.FRAMEWORK_EVENT
        r449FirstRead = false
        r449ReadActive = true
        r449Scope.launch {
            val started = SystemClock.uptimeMillis()
            val system = runCatching { readSystemState(KeyguardSystemReadPurpose.INSPECTION) }
                .getOrElse { KeyguardSystemState(-1L, -1L, available = false) }
            val lookup = r442Lookup
            val inventory = runCatching {
                KeyguardWindowSnapshotReader(this@FluviKeyguardCardService, packageName).read(
                    KeyguardWindowSnapshotReader.Request(knownOwn = own, attachGeneration = wake.owner.material,
                        knownOwnAtInventory = { r45WaOwnIdentity },
                        freshness = freshness, strictOwnAttribution = true, r44Enabled = true,
                        r443Sample = true, r443Diagnostics = true, r444UdfpsVerified = lookup.udfpsVerified),
                    authorityIsCurrent = { r449Wake === wake && r449RestrictionRevision.get() == revision &&
                        session.get() == wake.arm.session && wakeEpoch == wake.owner.wake && KeyguardR44Trial.active },
                )
            }.getOrNull()
            val ended = SystemClock.uptimeMillis()
            val evidence = runCatching {
                KeyguardR449RestrictionEvidence.fromInventory(inventory?.snapshots.orEmpty(), ended,
                    inventory == null || inventory.rootUnavailable || inventory.abortedStale,
                    inventory?.walkTruncated == true)
            }.getOrElse {
                KeyguardR449RestrictionEvidence.fromInventory(emptyList(), ended, unavailable = true, truncated = true)
            }
            mainHandler.post {
                r449ReadActive = false
                if (r449Current(wake, revision)) r449Apply(wake, revision, started, ended, system, evidence)
                if (r449ReadPending && r449Wake != null) {
                    r449ReadPending = false
                    r449ScheduleRead()
                }
            }
        }
    }

    private fun r449Apply(wake: R449Wake, revision: Long, started: Long, ended: Long,
                          system: KeyguardSystemState, evidence: KeyguardR449RestrictionEvidence.Result) {
        val stamp = KeyguardR448Admission.Stamp(wake.owner.route, wake.owner.wake, wake.owner.material)
        val privateAllowed = r47PrivateAllowed(evidence.privateSurface, system, evidence.reason == "CLEAR")
        val decision = KeyguardR448Admission.evaluate(KeyguardR448Admission.Inputs(stamp, wake.screenAt,
            system, evidence.exclusions,
            if (r47RecordingHeader) KeyguardR448Admission.Domain.PRIVATE else KeyguardR448Admission.Domain.PUBLIC_SAMPLE,
            materialAuthorized = privateAllowed),
            stamp, SystemClock.uptimeMillis())
        if (r45Wa.phase == KeyguardR45Phase.SUSPENDED)
            r45RecordStage(wake.context, "WIDGETS_ANYWHERE", "RECOVERY", SystemClock.uptimeMillis(),
                decision.name, revision, started, ended, evidence.reason)
        runCatching { KeyguardCardDiagnostics.recordR449Admission(KeyguardR449AdmissionObservation(
            wake.context, wake.arm.generation, wake.owner.route, wake.owner.material, revision, r449Action,
            wake.screenAt, started, ended, system, evidence.exclusions, evidence.reason, decision, wake.issueAt)) }
        if (decision != KeyguardR448Admission.Decision.ALLOW) {
            if (decision == KeyguardR448Admission.Decision.RESTRICTED ||
                decision == KeyguardR448Admission.Decision.SYSTEM_EXCLUDED) r446Cancel("wa:${evidence.reason}")
            return
        }
        wake.allowedRevision = revision
        wake.privateSurface = evidence.privateSurface
        wake.lower = evidence.lower
        val pendingValidation = wake.pendingValidation
        wake.pendingValidation = null
        if (pendingValidation != null) r449ValidateSystem(wake, pendingValidation)
        // An equivalent pending show keeps its original 50 ms due time. The
        // fresh inventory above updates its restriction revision, not a new
        // permission for an already attached or replaced owner.
        if (wake.issued) {
            if (r45Wa.phase == KeyguardR45Phase.SUSPENDED) {
                val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
                val valid = { val current = r449RestrictionRevision.get()
                    r449Current(wake, current) && wake.allowedRevision == current }
                val checkSystem: ((Boolean) -> Unit) -> Unit = { done -> r449ValidateSystem(wake, done) }
                if (frame.isAttached()) frame.resumeChecked(wake.owner, valid, checkSystem)
                else if (!frame.hasOwnedWindow()) r449RequestFrame(wake, frame, valid, checkSystem)
            }
            return
        }
        val frame = r448Frame ?: return r446Cancel("wa:missingFrame")
        val issueAt = SystemClock.uptimeMillis()
        wake.issueAt = issueAt
        wake.issued = true
        wake.expiresAt = if (r47RecordingHeader) Long.MAX_VALUE else issueAt + 2_000L
        runCatching { KeyguardCardDiagnostics.recordR449Admission(KeyguardR449AdmissionObservation(
            wake.context, wake.arm.generation, wake.owner.route, wake.owner.material, revision, r449Action,
            wake.screenAt, started, ended, system, evidence.exclusions, evidence.reason, decision, issueAt)) }
        r446Observation = KeyguardR446Observation(wake.context, r446ArmAt, wake.owner.wake, 0,
            "NOT_REQUIRED", evidence.reason, "WA_WAITING", null, null, issueAt, null, null, null, null,
            null, "UNOBSERVED", armGeneration = wake.arm.generation, wakeArmState = "ARMED",
            readFinishedAt = ended, decisionAt = issueAt)
        runCatching { KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation)) }
        val valid = { val current = r449RestrictionRevision.get()
            r449Current(wake, current) && wake.allowedRevision == current }
        val checkSystem: ((Boolean) -> Unit) -> Unit = { done -> r449ValidateSystem(wake, done) }
        r449RequestFrame(wake, frame, valid, checkSystem)
        if (!r47RecordingHeader) mainHandler.postDelayed({ if (r449Wake === wake) r446Cancel("deadline") },
            (wake.expiresAt - SystemClock.uptimeMillis()).coerceAtLeast(0L))
    }

    private fun r449RequestFrame(wake: R449Wake, frame: KeyguardR448WidgetsAnywhereFrame,
                                 valid: () -> Boolean, checkSystem: ((Boolean) -> Unit) -> Unit) {
        val settings = lastSettings ?: return r446Cancel("wa:settingsUnavailable")
        val metrics = resources.displayMetrics
        val geometry = resolveKeyguardOverlayGeometry(
            KeyguardUsableBounds(0, 0, metrics.widthPixels, metrics.heightPixels), metrics.density,
            resources.getDimensionPixelSize(com.fluvi.app.R.dimen.fluvi_keyguard_card_height),
            KeyguardCardPresentationMode.ORB, settings.cardPosition, settings.orbPosition, settings.verticalOffsetDp,
            resources.getDimensionPixelSize(com.fluvi.app.R.dimen.fluvi_keyguard_orb_size))
        if (!frame.requestShowChecked(wake.owner, geometry, valid, checkSystem)) r446Cancel("wa:showDenied")
    }

    /** Check platform state asynchronously at each publication boundary. If
     * a real event invalidated the inventory meanwhile, retain one waiter and
     * resume it only after that revision has independently been read. */
    private fun r449ValidateSystem(wake: R449Wake, done: (Boolean) -> Unit) {
        check(Looper.myLooper() == Looper.getMainLooper())
        val revision = r449RestrictionRevision.get()
        if (!r449Current(wake, revision)) { done(false); return }
        if (wake.allowedRevision != revision) { wake.pendingValidation = done; return }
        r449Scope.launch {
            val state = runCatching { readSystemState(KeyguardSystemReadPurpose.PUBLICATION) }
                .getOrElse { KeyguardSystemState(-1L, -1L, available = false) }
            mainHandler.post {
                val current = r449RestrictionRevision.get()
                if (!r449Current(wake, current)) done(false)
                else if (current != revision || wake.allowedRevision != current) done(false)
                else if (state.excluded) {
                    r446Cancel("wa:systemExcluded")
                    done(false)
                } else done(state.eligible && state.startedAt >= wake.screenAt &&
                    r47PrivateAllowed(wake.privateSurface, state, complete = true))
            }
        }
    }

    private fun r448RecordFrameEvent(event: KeyguardR448WidgetsAnywhereFrame.Event) {
        if (event.owner != r448FrameOwner) return
        when (event.stage) {
            "ATTACHED" -> r449Wake?.let {
                r45Wa.attached(it.arm)
                if (r45Wa.phase == KeyguardR45Phase.SUSPENDED) mainHandler.post { r449ScheduleRead() }
            }
            "REVEAL" -> r449Wake?.let { r45Wa.visible(it.arm) }
            "CONCEAL" -> r449Wake?.let { r45Wa.suspend(it.arm) }
            "PRE_ADD_UNVERIFIED", "POST_ADD_UNVERIFIED", "RESUME_UNVERIFIED" -> r449Wake?.let { wake ->
                val revision = r449RestrictionRevision.get()
                if (wake.validatorRetryRevision != revision) {
                    wake.validatorRetryRevision = revision
                    mainHandler.post { if (r449Wake === wake) r449ScheduleRead() }
                }
            }
            "HIDE" -> if (r448HideAt == null) r448HideAt = event.at
            "REMOVE_RETURN" -> if (r448RemoveAt == null) r448RemoveAt = event.at
            "REMOVE_FAILED" -> r448RetireError = event.detail ?: "UNKNOWN"
        }
        val previous = r446Observation
        if (previous != null) runCatching {
            KeyguardCardDiagnostics.recordR448Frame(KeyguardR448FrameObservation(
                previous.context, event.owner, event.stage, event.at, event.detail))
        }
        if (previous != null) r45RecordStage(previous.context, "WIDGETS_ANYWHERE", event.stage, event.at,
            detail = if (event.stage == "MOTION") "linked=R448_FRAME" else event.detail ?: "UNOBSERVED")
        if (previous != null && r449Wake?.issued == true) {
            val next = when (event.stage) {
                "ADD_BEGIN" -> previous.copy(backend = "WA_ADD_BEGIN", attachBegin = event.at)
                "ATTACHED" -> previous.copy(backend = "WA_ATTACHED", attachEnd = event.at)
                "ADD_RETURN" -> previous.copy(backend = "WA_ADD_RETURN")
                "FIRST_SHADER_DRAW" -> previous.copy(backend = "WA_SHADER_DRAW", frameAt = event.at)
                else -> previous
            }
            if (next !== previous) {
                r446Observation = next
                runCatching { KeyguardCardDiagnostics.recordR446(next) }
            }
        }
        if (event.stage in setOf("DENIED_SECOND_CHECK", "ADD_FAILED", "DEBOUNCE_POST_FAILED")) {
            mainHandler.post {
                if (event.owner == r448FrameOwner &&
                    r449Wake?.issued == true)
                    r446Cancel("wa:${event.stage}")
            }
        }
    }
    private var r446ArmAt = 0L
    private var r446Observation: KeyguardR446Observation? = null
    // Written and read under queueLock. A start is attributed to an arm only
    // when that arm and the SCREEN_ON boundary already exist at reader entry.
    private var r448StartedRequest: Long? = null
    private var r448StartedArm: Long? = null

    internal fun r446PresenterForInstrumentation() = r446Presenter
    internal fun r446PreparePresenterForInstrumentation(timeSource: KeyguardMaterialTimeSource): KeyguardR446WindowPresenter {
        check(Looper.myLooper() == Looper.getMainLooper())
        return KeyguardR446WindowPresenter(this, timeSource).also { r446Presenter = it }
    }

    internal suspend fun startR446PrintCapture(build: String?, buildMode: String?, mode: String?,
                                              sampleAction: String = "ONE_WAKE", diagnosticCircle: Boolean = false,
                                              r46Request: String? = null): Map<String, Any?> {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (r446Preparing) return mapOf("active" to false, "reason" to "startInProgress")
        if (r448Frame != null || r446Presenter != null) return mapOf("active" to false, "reason" to "retirementPending")
        r449Action = sampleAction
        r45Circle = diagnosticCircle
        val route = r448DisplayRoute
        val routeGeneration = r448RouteGeneration
        r446Preparing = true
        try {
            val receipt = startR442SampleCapture(build, buildMode, mode, expanded = false, oneWakePrint = true,
                r46Request = r46Request, r46Route = route.name)
            val capture = receipt["captureId"] as? String
            if (receipt["active"] != true || capture == null) return receipt
            val useHeader = r46Request != null && !r448SampleOnly
            val header = if (useHeader) FluviActiveHeaderMaterialStore.applicable(applicationContext) else null
            if (useHeader && header == null) {
                // Keep the recorder usable for a no-show report. Do not make
                // a public sample, ticket or native window in this state.
                r47RecordingHeader = true
                r47Header = null
                r446CaptureId = capture
                r446ArmAt = SystemClock.uptimeMillis()
                r442Reason = "activeHeaderUnavailableOrDisclosureDisabled"
                KeyguardR46RecordingStore.offer(capture,
                    "R47_MATERIAL origin=missing reason=activeHeaderUnavailableOrDisclosureDisabled")
                return receipt + mapOf("printPurpose" to "activeHeader", "printArmed" to true,
                    "sampleShape" to "ORB", "materialOrigin" to "missing", "materialReason" to r442Reason)
            }
            r47RecordingHeader = useHeader
            r47Header = header
            if (header != null) KeyguardR46RecordingStore.offer(capture,
                "R47_MATERIAL origin=active_header_semantic token=${header.correlation} " +
                    "sourceRevision=${header.profile.publisherRevision} animated=${header.motionEnabled && header.profile.animated} playback=shader")
            val sample = header?.profile ?: KeyguardR44Trial.profile(null)
            if (sample == null) { stopR444Trial("samplePreparationFailed"); return mapOf("active" to false, "reason" to "samplePreparationFailed") }
            val artifact = runCatching { withContext(Dispatchers.IO) {
                AndroidKeyguardShaderArtifactReader.load(applicationContext, sample.effectId, sample.usesPortal)
            } }.getOrNull()
            val display = displayManager?.getDisplay(Display.DEFAULT_DISPLAY)
            if (artifact == null || display == null || r442Receipt?.capture != capture ||
                KeyguardCardDiagnostics.activeCaptureId() != capture || !KeyguardR44Trial.active ||
                !r47HeaderCurrent() ||
                r448DisplayRoute != route || r448RouteGeneration != routeGeneration ||
                getSystemService(android.app.KeyguardManager::class.java)?.isKeyguardLocked != false) {
                stopR444Trial("samplePreparationFailed")
                return mapOf("active" to false, "reason" to "samplePreparationFailed")
            }
            r46DisplayFacts = currentR46DisplayFacts()
            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) {
                val frame = KeyguardR448WidgetsAnywhereFrame(this)
                val prepared = KeyguardR448WidgetsAnywhereFrame.Owner(routeGeneration, 0, ++r448FrameGeneration)
                r448HideAt = null
                r448RemoveAt = null
                r448RetireError = null
                val preparedOk = if (header != null) frame.prepareActiveHeader(prepared, header, artifact, ::r448RecordFrameEvent)
                    else frame.preparePublic(prepared, KeyguardR46PublicMaterial.demo(), artifact, diagnosticCircle, ::r448RecordFrameEvent)
                if (!preparedOk) {
                    stopR444Trial("samplePreparationFailed")
                    return mapOf("active" to false, "reason" to "samplePreparationFailed")
                }
                r448Frame = frame
                r448FrameOwner = prepared
            } else {
                val presenter = KeyguardR446WindowPresenter(this)
                presenter.onR46Interval = { detail -> r45RecordStage(r446Observation?.context, "FLUVI_STREAM",
                    "MOTION", SystemClock.uptimeMillis(), detail = detail) }
                // Keep ownership even if preparation or cleanup fails.
                r446Presenter = presenter
                val preparedOk = if (header != null) presenter.prepareActiveHeader(display, header, artifact)
                    else presenter.preparePublic(display, KeyguardR46PublicMaterial.demo(), artifact, diagnosticCircle)
                if (!preparedOk) {
                    stopR444Trial("samplePreparationFailed")
                    return mapOf("active" to false, "reason" to "samplePreparationFailed")
                }
                if (!presenter.awaitInputReady()) {
                    stopR444Trial("inputPreparationFailed")
                    return mapOf("active" to false, "reason" to "inputPreparationFailed")
                }
                if (r446Presenter !== presenter) {
                    stopR444Trial("serviceOrCaptureChanged")
                    return mapOf("active" to false, "reason" to "serviceOrCaptureChanged")
                }
            }
            if (r442Receipt?.capture != capture || KeyguardCardDiagnostics.activeCaptureId() != capture ||
                !KeyguardR44Trial.active || !r47HeaderCurrent() || r448DisplayRoute != route || r448RouteGeneration != routeGeneration ||
                getSystemService(android.app.KeyguardManager::class.java)?.isKeyguardLocked != false) {
                stopR444Trial("serviceOrCaptureChanged")
                return mapOf("active" to false, "reason" to "serviceOrCaptureChanged")
            }
            r446Observation = null
            r447DecisionOrdinal = 0L
            r446RestrictionSeen = false
            r446ReadArm = null
            r446ArmAt = SystemClock.uptimeMillis()
            r446CaptureId = capture
            if (route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
                r45Wa.prepare(capture, session.get(), routeGeneration, sampleAction, diagnosticCircle)
            else r446Owner.arm(session.get(), capture)
            r449LastTerminal = "UNOBSERVED"
            return receipt + mapOf("printPurpose" to if (useHeader) "activeHeader" else "fixedSampleOneWake", "printArmed" to true,
                "sampleShape" to if (diagnosticCircle) "CIRCLE" else "ORB")
        } finally {
            r446Preparing = false
        }
    }

    /** Explicit UI action; the old R442/R446 channel calls retain their
     * historical meaning. The route is confirmed by this service after the
     * frame is prepared, not inferred by Flutter from a persisted setting. */
    internal suspend fun startR449SampleCapture(build: String?, buildMode: String?, mode: String?,
                                               action: String?, requestedRoute: String?,
                                               diagnosticCircle: Boolean = false,
                                               r46Request: String? = null): Map<String, Any?> {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (action != "ONE_WAKE" && action != "SESSION") return mapOf("active" to false, "reason" to "unsupportedAction")
        val route = r448DisplayRoute.name
        if (requestedRoute != route) return mapOf("active" to false, "reason" to "routeChanged",
            "routeConfirmed" to route, "actionKind" to action)
        val result = startR446PrintCapture(build, buildMode, mode, action, diagnosticCircle, r46Request)
        if (result["active"] == true && result["printArmed"] == true && r448DisplayRoute.name == route) {
            r449Action = action
            val capture = result["captureId"] as String
            KeyguardCardDiagnostics.recordR449Intent(capture, action, route, SystemClock.uptimeMillis())
            val newSession = if (action == "SESSION") R449Session(capture, session.get(), r448DisplayRoute,
                r448RouteGeneration, if (r46Request == null) SystemClock.uptimeMillis() + 120_000L else Long.MAX_VALUE,
                diagnosticCircle) else null
            r449Session = newSession
            if (newSession != null && r46Request == null) mainHandler.postDelayed({
                if (r449Session === newSession) stopR444Trial("sampleSessionExpired")
            }, 120_000L)
            return result + mapOf("routeRequested" to route, "routeConfirmed" to route, "actionKind" to action,
                "sessionExpiresAt" to newSession?.expiresAt)
        }
        return result + mapOf("routeRequested" to requestedRoute, "routeConfirmed" to r448DisplayRoute.name,
            "actionKind" to action)
    }

    private var r46StartingRequest: String? = null
    private var r46StartedRequest: String? = null
    private var r46StartedReceipt: Map<String, Any?>? = null

    private suspend fun rollbackR46Start(request: String) = withContext(NonCancellable) {
        val partial = withContext(Dispatchers.IO) { KeyguardR46RecordingStore.status(applicationContext) }
        val partialId = partial["captureId"] as? String
        if (partial["requestId"] == request && partialId != null) {
            stopR444Trial("r46StartFailed")
            withContext(Dispatchers.IO) {
                if (KeyguardCardDiagnostics.activeCaptureId() == partialId)
                    KeyguardCardDiagnostics.freezeR46Capture(applicationContext)
                KeyguardR46RecordingStore.abort(applicationContext, partialId)
            }
        }
    }

    /** One request owns both the recorder and the armed, public ORB. */
    internal suspend fun startR46Recording(build: String?, buildMode: String?, request: String?,
                                           route: String?): Map<String, Any?> {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (request.isNullOrBlank() || request.length > 120 ||
            route !in setOf("FLUVI_STREAM", "WIDGETS_ANYWHERE"))
            return mapOf("active" to false, "reason" to "invalidRequest")
        if (r46StartedRequest == request && r46StartedReceipt != null &&
            r442SampleStatus()["active"] == true) return requireNotNull(r46StartedReceipt)
        if (r46StartingRequest != null || r442Receipt != null)
            return mapOf("active" to false, "reason" to "startInProgress")
        if (route != r448DisplayRoute.name) return mapOf("active" to false, "reason" to "routeChanged")
        r46StartingRequest = request
        try {
            val result = startR449SampleCapture(build, buildMode, "FULL", "SESSION", route,
                diagnosticCircle = false, r46Request = request)
            if (result["active"] == true && result["printArmed"] == true &&
                result["routeConfirmed"] == route && result["sampleShape"] == "ORB") {
                val receipt = result + mapOf("state" to "RECORDING", "policy" to "R46_ALL", "requestId" to request)
                r46StartedRequest = request
                r46StartedReceipt = receipt
                return receipt
            }
            rollbackR46Start(request)
            return result + mapOf("active" to false)
        } catch (failure: Exception) {
            try { rollbackR46Start(request) } catch (rollback: Exception) { failure.addSuppressed(rollback) }
            throw failure
        } finally {
            r46StartingRequest = null
        }
    }

    internal fun stopR46Owner(capture: String): Boolean {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (r46StartingRequest != null) return false
        if (r442Receipt?.capture == capture && !stopR444Trial("r46UserStop")) return false
        r46StartedRequest = null
        r46StartedReceipt = null
        return true
    }

    /** A session is an explicit, bounded public-data authority. Prepare the
     * next wake only on an actual screen-off/user-present boundary; a late
     * preparation from a stopped, replaced or expired session is discarded. */
    private fun r449PrepareSessionWake() {
        check(Looper.myLooper() == Looper.getMainLooper())
        val active = r449Session ?: return
        if (r449SessionPreparing || r446HasBackend() || r448Frame != null ||
            (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r45Wa.phase != KeyguardR45Phase.RETIRED) ||
            (active.route == KeyguardR448DisplayRoute.FLUVI_STREAM && r446Owner.state in setOf(KeyguardR446PrintOwner.State.WAIT_OFF,
                KeyguardR446PrintOwner.State.WAIT_WAKE, KeyguardR446PrintOwner.State.WAIT_READ,
                KeyguardR446PrintOwner.State.ISSUED))) return
        fun current() = r449Session === active && SystemClock.uptimeMillis() < active.expiresAt &&
            active.capture == KeyguardCardDiagnostics.activeCaptureId() && r442Receipt?.capture == active.capture &&
            active.serviceSession == session.get() && KeyguardR44Trial.active &&
            r448DisplayRoute == active.route && r448RouteGeneration == active.routeGeneration
        if (!current()) return
        r449SessionPreparing = true
        CoroutineScope(serviceJob + Dispatchers.Main.immediate).launch {
            try {
                val header = if (r47RecordingHeader) FluviActiveHeaderMaterialStore.applicable(applicationContext) else null
                if (r47RecordingHeader && header == null) {
                    r442Reason = "activeHeaderUnavailableOrDisclosureDisabled"; return@launch
                }
                r47Header = header
                val sample = header?.profile ?: KeyguardR44Trial.profile(null) ?: return@launch
                val artifact = runCatching { withContext(Dispatchers.IO) {
                    AndroidKeyguardShaderArtifactReader.load(applicationContext, sample.effectId, sample.usesPortal)
                } }.getOrNull() ?: run { r442Reason = "samplePreparationFailed"; return@launch }
                if (!current() || !r47HeaderCurrent() || r446HasBackend()) return@launch
                val display = displayManager?.getDisplay(Display.DEFAULT_DISPLAY)
                    ?: run { r442Reason = "samplePreparationFailed"; return@launch }
                if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) {
                    val frame = KeyguardR448WidgetsAnywhereFrame(this@FluviKeyguardCardService)
                    val owner = KeyguardR448WidgetsAnywhereFrame.Owner(active.routeGeneration, 0, ++r448FrameGeneration)
                    val preparedOk = if (header != null) frame.prepareActiveHeader(owner, header, artifact, ::r448RecordFrameEvent)
                        else frame.preparePublic(owner, KeyguardR46PublicMaterial.demo(), artifact, active.circle, ::r448RecordFrameEvent)
                    if (!preparedOk) {
                        r442Reason = "samplePreparationFailed"; return@launch
                    }
                    if (!current() || !r47HeaderCurrent() || r446HasBackend()) { frame.retire(owner, "SESSION_REPLACED"); return@launch }
                    r448Frame = frame
                    r448FrameOwner = owner
                } else {
                    val presenter = KeyguardR446WindowPresenter(this@FluviKeyguardCardService)
                    presenter.onR46Interval = { detail -> r45RecordStage(r446Observation?.context, "FLUVI_STREAM",
                        "MOTION", SystemClock.uptimeMillis(), detail = detail) }
                    r446Presenter = presenter
                    val preparedOk = if (header != null) presenter.prepareActiveHeader(display, header, artifact)
                        else presenter.preparePublic(display, KeyguardR46PublicMaterial.demo(), artifact, active.circle)
                    if (!preparedOk || !presenter.awaitInputReady()) {
                        r446Cancel("inputPreparationFailed"); r442Reason = "inputPreparationFailed"; return@launch
                    }
                    if (!current() || !r47HeaderCurrent() || r446Presenter !== presenter || r448Frame != null) {
                        if (r446Presenter === presenter) r446Cancel("sessionReplaced")
                        return@launch
                    }
                }
                r448HideAt = null; r448RemoveAt = null; r448RetireError = null
                r446Observation = null; r447DecisionOrdinal = 0L; r446RestrictionSeen = false
                r446ReadArm = null; r446ArmAt = SystemClock.uptimeMillis(); r446CaptureId = active.capture
                if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
                    r45Wa.prepare(active.capture, active.serviceSession, active.routeGeneration, "SESSION", active.circle)
                else r446Owner.arm(active.serviceSession, active.capture)
                r449LastTerminal = "UNOBSERVED"
                if (getSystemService(android.os.PowerManager::class.java)?.isInteractive == false) {
                    if (active.route == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) r45Wa.screenOff()
                    else r446Owner.screenOff()
                }
                r442Reason = "armed"
            } finally {
                r449SessionPreparing = false
            }
        }
    }

    private fun r446Cancel(reason: String) {
        check(Looper.myLooper() == Looper.getMainLooper())
        val at = SystemClock.uptimeMillis()
        val r45Context = r449Wake?.context ?: r446Observation?.context
        val r45Route = if (r449Wake != null) "WIDGETS_ANYWHERE" else "FLUVI_STREAM"
        r45RecordStage(r45Context, r45Route, "TERMINAL", at, detail = reason.take(80))
        val cancelledArm = r446Owner.arm
        if (cancelledArm != null) r449LastTerminal = reason
        r449FluviRecovery?.let { recovery ->
            runCatching { KeyguardCardDiagnostics.recordR449Recovery(
                recovery.observation.copy(stage = "TERMINAL_$reason", at = at)) }
        }
        r449FluviRecovery = null
        val pendingValidation = r449Wake?.pendingValidation
        r449Wake?.pendingValidation = null
        r45Wa.retire()
        r45Direct.retire()
        r45WaOwnIdentity = null
        r45DirectRevision.incrementAndGet()
        r45DirectReadPending = false
        r45DirectLower = emptyList()
        r449RestrictionRevision.incrementAndGet()
        r449Wake = null
        if (pendingValidation != null) runCatching { pendingValidation(false) }
        r449ReadPending = false
        r446ReadArm = null
        r446RestrictionSeen = true
        r446TicketActive = false
        r446Owner.revoke() // invalidate before hiding or releasing the child
        val presenter = r446Presenter
        val retired = presenter?.dispose()
        if (retired?.errorClass == null) r446Presenter = null
        if (retired?.hideReturn != null) r45RecordStage(r45Context, r45Route, "CONCEAL", retired.hideReturn, detail = reason.take(80))
        if (retired?.releaseReturn != null) r45RecordStage(r45Context, r45Route, "REMOVE_RETURN", retired.releaseReturn, detail = reason.take(80))
        val frame = r448Frame
        val frameOwner = r448FrameOwner
        if (frame != null && frameOwner != null) {
            val removed = runCatching { frame.isRetired() || frame.retire(frameOwner, reason) }.getOrDefault(false)
            if (removed) { r448Frame = null; r448FrameOwner = null }
            else if (r448RetireError == null) r448RetireError = "REMOVAL_UNCONFIRMED"
        }
        // Observation must never precede or suppress authority revocation and
        // the real child hide, even if a diagnostic producer fails.
        if (cancelledArm != null) runCatching {
            KeyguardCardDiagnostics.recordR447ArmTerminal(cancelledArm.capture, cancelledArm.generation, at, reason)
        }
        // A later freeze, unlock or duplicate cleanup must not relabel or
        // erase the original withdrawal and its actual return timestamps.
        r446Observation?.let { previous ->
            val next = previous.retireOnce(at, reason, retired?.hideReturn ?: r448HideAt,
                retired?.releaseReturn ?: r448RemoveAt, retired?.errorClass ?: r448RetireError)
            r446Observation = next
            KeyguardCardDiagnostics.recordR446(next)
        }
        if (r446Observation == null && cancelledArm != null) {
            val context = currentDiagnosticAttempt?.takeIf { it.captureId == cancelledArm.capture &&
                it.serviceSession == cancelledArm.session }
            if (context != null) {
                val terminal = KeyguardR446Observation(context, r446ArmAt, context.originWakeEpoch, 0,
                    "UNOBSERVED", "UNOBSERVED", "NOT_ATTEMPTED", null, null, null, null, null,
                    null, null, at, reason, retired?.hideReturn ?: r448HideAt,
                    retired?.releaseReturn ?: r448RemoveAt, retired?.errorClass ?: r448RetireError,
                    armGeneration = cancelledArm.generation, wakeArmState = "ARMED")
                KeyguardCardDiagnostics.recordR446(terminal)
            }
        }
    }

    private fun r447RecordWakeArm() {
        val context = currentDiagnosticAttempt ?: return
        if (r446CaptureId == null || context.captureId != r446CaptureId ||
            r442ScreenOn?.session != context.serviceSession ||
            wakeCycleOwner.current()?.id != context.originWakeEpoch) return
        val arm = r446Owner.arm
        val waArm = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) r45Wa.intent else null
        val armed = if (waArm != null) r45Wa.phase in setOf(KeyguardR45Phase.OPENING,
            KeyguardR45Phase.ATTACHED_HIDDEN, KeyguardR45Phase.VISIBLE, KeyguardR45Phase.SUSPENDED) &&
            waArm.session == context.serviceSession && waArm.capture == context.captureId
        else r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && arm != null &&
            arm.session == context.serviceSession && arm.capture == context.captureId
        val generation = if (armed) waArm?.generation ?: arm?.generation ?: 0L else 0L
        KeyguardCardDiagnostics.recordR446(KeyguardR446Observation(context, if (armed) r446ArmAt else 0,
            context.originWakeEpoch, 0, "UNOBSERVED", "UNOBSERVED", "NOT_ATTEMPTED", null, null,
            null, null, null, null, null, null, "UNOBSERVED", armGeneration = generation,
            wakeArmState = if (armed) "ARMED" else "NOT_ARMED"))
    }

    private data class R447Decision(
        val disposition: KeyguardR447Disposition, val order: KeyguardFirstAuthorizedOrb.SampleOrder,
        val systemBarrier: Long, val ownerState: String, val ticket: KeyguardR446PrintOwner.Ticket?, val at: Long,
    )

    private fun r446Apply(inspection: Inspection, request: KeyguardCardInspectionRequest,
                          disposition: CompletedDisposition, readFinishedAt: Long, mainEnteredAt: Long): Boolean {
        // The independent WA route must never issue or consume a direct ticket.
        if (r448DisplayRoute != KeyguardR448DisplayRoute.FLUVI_STREAM) return false
        val arm = inspection.r446Arm ?: return false
        val context = request.diagnosticContext ?: return false
        val eligibility = inspection.r446Eligibility
        val scene = inspection.r19ReadSceneSerial
        val target = eligibility?.target
        val stamp = inspection.r447Stamp
        val ordinal = ++r447DecisionOrdinal
        // The platform read stays outside queueLock. It is only an exclusion
        // gate; neither this read nor a scheduling offer grants output.
        val currentSystem = if (target != null && disposition == CompletedDisposition.NORMAL &&
            !inspection.abortedStale && authorityIsCurrent(request) && !r446RestrictionSeen)
            readSystemState(KeyguardSystemReadPurpose.PUBLICATION) else null
        val presenter = r446Presenter
        val route = r448DisplayRoute
        val routeGeneration = r448RouteGeneration
        val decision = synchronized(queueLock) {
            val decidedAt = SystemClock.uptimeMillis()
            val order = firstAuthorizedOrb.sampleOrder(request.id, scene)
            val state = r446Owner.state.name
            val reject = when {
                r446ReadArm != arm || r446Owner.arm != arm || context.captureId != arm.capture ||
                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ -> KeyguardR447Disposition.ARM_MISMATCH
                !authorityIsCurrent(request) || inspection.abortedStale -> KeyguardR447Disposition.STALE_AUTHORITY
                disposition == CompletedDisposition.R32_RESTRICTION_ONLY -> KeyguardR447Disposition.RESTRICTION_ONLY
                r446RestrictionSeen || eligibility?.reason == "RESTRICTION" || currentSystem?.excluded == true ->
                    KeyguardR447Disposition.RESTRICTION_OBSERVED
                target == null -> KeyguardR447Disposition.TARGET_MISSING
                stamp == null || stamp.arm != arm || stamp.request != request.id || stamp.authority != inspectionAuthority ||
                    stamp.target != target || stamp.scene != scene -> KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
                order.result == KeyguardFirstAuthorizedOrb.SampleResult.SCENE_CHANGED -> KeyguardR447Disposition.SCENE_CHANGED
                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_COMPLETED -> KeyguardR447Disposition.NEWER_COMPLETED
                order.result == KeyguardFirstAuthorizedOrb.SampleResult.NEWER_BARRIER_REQUIRED || stamp.barrier > request.id ->
                    KeyguardR447Disposition.NEWER_BARRIER_REQUIRED
                stamp.freshness == null || !inspectionFreshness.isEstablished(inspectionAuthority, stamp.freshness) ||
                    stamp.systemBarrier != stamp.systemSatisfied || stamp.systemBarrier != r447SystemBarrier ||
                    r447SystemBarrier != r447SystemSatisfied || currentSystem?.eligible != true ->
                    KeyguardR447Disposition.FRESHNESS_UNESTABLISHED
                !r47PrivateAllowed(inspection.r446Normal?.surface ?: KeyguardSurface.UNKNOWN, currentSystem,
                    !inspection.rootUnavailable && !inspection.walkTruncated && !inspection.abortedStale) ->
                    KeyguardR447Disposition.PRIVATE_NOT_AUTHORIZED
                presenter == null -> KeyguardR447Disposition.PRESENTER_UNAVAILABLE
                else -> null
            }
            val ticket = if (reject == null) r446Owner.issue(request.session, context.captureId, request.wakeGeneration,
                request.id, requireNotNull(scene), requireNotNull(target), decidedAt, publicFixture = !r47RecordingHeader) else null
            if (ticket != null) {
                r446TicketActive = true
                r446ReadArm = null
            }
            R447Decision(reject ?: if (ticket == null) KeyguardR447Disposition.ISSUE_REJECTED
                else KeyguardR447Disposition.ISSUED, order, r447SystemBarrier, state, ticket, decidedAt)
        }
        var observation = KeyguardR446Observation(context, r446ArmAt, request.wakeGeneration, request.id,
            inspection.r446Normal?.let { "${it.surface}/${it.reason}" } ?: "UNOBSERVED",
            eligibility?.reason ?: "UNOBSERVED", if (decision.ticket == null) "NOT_ATTEMPTED" else "TICKET_ISSUED",
            target?.windowId, scene, if (decision.ticket == null) null else decision.at, null, null, null, null, null, "UNOBSERVED",
            armGeneration = arm.generation, decisionOrdinal = ordinal, handoff = decision.disposition,
            order = decision.order, freshnessRevision = stamp?.freshness,
            systemBarrierAtRead = stamp?.systemBarrier, systemBarrierAtDecision = decision.systemBarrier,
            ownerState = decision.ownerState, wakeArmState = "ARMED", inventoryAt = stamp?.inventoryAt,
            readFinishedAt = readFinishedAt, mainEnteredAt = mainEnteredAt, decisionAt = decision.at)
        if (r446Owner.arm == arm || decision.ticket != null) r446Observation = observation
        KeyguardCardDiagnostics.recordR446(observation)
        if (route == KeyguardR448DisplayRoute.FLUVI_STREAM && decision.disposition == KeyguardR447Disposition.TARGET_MISSING &&
            r449FluviRecovery == null && !r446RestrictionSeen && r446Owner.arm == arm &&
            r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ && authorityIsCurrent(request)) {
            val unresolved = inspection.r449UnresolvedUpper
            val inventoryAt = stamp?.inventoryAt
            if (unresolved != null && inventoryAt != null) {
                val initial = KeyguardR449RecoveryObservation(context, arm.generation, request.wakeGeneration,
                    request.id, unresolved.host, unresolved.upper, inventoryAt, "WAIT_REAL_CHANGE", decision.at)
                val recovery = R449FluviRecovery(initial, arm)
                r449FluviRecovery = recovery
                KeyguardCardDiagnostics.recordR449Recovery(initial)
                val successor = synchronized(queueLock) {
                    listOfNotNull(inspectionQueue.pendingRequest(), inspectionQueue.activeRequest()).firstOrNull {
                        it.id > request.id && it.session == request.session && it.wakeGeneration == request.wakeGeneration &&
                            inspectionAuthority.matches(it) && it.r42FrameworkEvent && it.r32FrameworkIngressId != null &&
                            it.r14Ingress?.let { event -> event.callbackAt >= inventoryAt && event.displayId == Display.DEFAULT_DISPLAY &&
                                (event.windowId == unresolved.upper || event.windowId == unresolved.host ||
                                    (event.windowId < 0 && event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED)) } == true
                    }
                }
                if (successor != null) {
                    recovery.consumed = true
                    KeyguardCardDiagnostics.recordR449Recovery(initial.copy(stage = "ADOPT_CURRENT_SUCCESSOR",
                        at = SystemClock.uptimeMillis(), successor = successor.id))
                }
            }
        }
        val ticket = decision.ticket ?: return false
        val qualifiedTarget = requireNotNull(target)
        val settings = lastSettings ?: return false.also {
            observation = observation.copy(handoff = KeyguardR447Disposition.SETTINGS_UNAVAILABLE)
            r446Observation = observation
            KeyguardCardDiagnostics.recordR446(observation)
            r446Cancel("settingsUnavailable")
        }
        val metrics = resources.displayMetrics
        val geometry = resolveKeyguardOverlayGeometry(
            KeyguardUsableBounds(0, 0, metrics.widthPixels, metrics.heightPixels), metrics.density,
            resources.getDimensionPixelSize(com.fluvi.app.R.dimen.fluvi_keyguard_card_height),
            KeyguardCardPresentationMode.ORB, settings.cardPosition, settings.orbPosition, settings.verticalOffsetDp,
            resources.getDimensionPixelSize(com.fluvi.app.R.dimen.fluvi_keyguard_orb_size))
        fun openingOwned(): Boolean = !r446RestrictionSeen && KeyguardR44Trial.active &&
            r448DisplayRoute == route && r448RouteGeneration == routeGeneration &&
            r446Owner.current(ticket, session.get(), KeyguardCardDiagnostics.activeCaptureId(), wakeEpoch,
                firstAuthorizedOrb.sceneSerial(), SystemClock.uptimeMillis()) && authorityIsCurrent(request) &&
            synchronized(queueLock) {
                stamp != null && stamp.freshness != null && stamp.authority == inspectionAuthority &&
                    inspectionFreshness.isEstablished(inspectionAuthority, stamp.freshness) &&
                    stamp.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied
            }
        fun valid(): Boolean = openingOwned() && readSystemState(KeyguardSystemReadPurpose.PUBLICATION).let { state ->
            state.eligible && r47PrivateAllowed(inspection.r446Normal?.surface ?: KeyguardSurface.UNKNOWN, state,
                !inspection.rootUnavailable && !inspection.walkTruncated && !inspection.abortedStale)
        }
        val screenAt = r442ScreenOn?.takeIf { it.session == request.session }?.uptime
            ?: return false.also { r446Cancel("direct:missingScreenBoundary") }
        val lease = KeyguardR45DirectLifetime.Lease(ticket, arm.capture, request.session, request.wakeGeneration,
            routeGeneration, qualifiedTarget, screenAt, ticket.deadline)
        r45Direct.open(lease)
        r45DirectLower = inspection.r45Lower
        r45RecordStage(context, "FLUVI_STREAM", "INTENT", decision.at,
            detail = if (r45Circle) "CIRCLE" else "ORB")
        fun stillOwned(): Boolean = r45DirectCurrent(lease) &&
            r45Direct.phase != KeyguardR45Phase.SUSPENDED
        observation = observation.copy(issuedAt = decision.at,
            attachBegin = if (route == KeyguardR448DisplayRoute.FLUVI_STREAM) SystemClock.uptimeMillis() else null,
            backend = if (route == KeyguardR448DisplayRoute.FLUVI_STREAM) "ATTEMPTED" else "WA_WAITING")
        r446Observation = observation
        KeyguardCardDiagnostics.recordR446(observation)
        runCatching { inspectionProbeForTest?.r447PresenterInvoked(request.id) }
        val qualifiedPresenter = requireNotNull(presenter)
        val receipt = qualifiedPresenter.show(ticket, qualifiedTarget, geometry, ::valid, ::stillOwned,
            onInvalidated = { if (r45Direct.lease === lease && r45Direct.phase != KeyguardR45Phase.SUSPENDED)
                r446Cancel("ownerExpiredOrChanged") },
            onFirstTraversal = { at -> r45RecordStage(context, "FLUVI_STREAM", "FIRST_DRAW", at) }) { at ->
            val previous = r446Observation
            if (previous != null && previous.request == request.id && stillOwned()) {
                val next = previous.copy(frameAt = at)
                r446Observation = next
                KeyguardCardDiagnostics.recordR446(next)
                r45RecordStage(context, "FLUVI_STREAM", "FIRST_SHADER_DRAW", at)
            }
        }
        if (receipt.status != "SUBMITTED") {
            r446Observation = observation.copy(backend = receipt.status + (receipt.errorClass?.let { ":$it" } ?: ""),
                attachEnd = receipt.attachedAt, submittedAt = receipt.submittedAt)
            KeyguardCardDiagnostics.recordR446(requireNotNull(r446Observation))
            r446Cancel("attachOrSubmitFailed")
            return false
        }
        r45Direct.visible(lease)
        r45RecordStage(context, "FLUVI_STREAM", "REVEAL", requireNotNull(receipt.submittedAt), detail = "directSubmission")
        observation = observation.copy(backend = "SUBMITTED", attachEnd = receipt.attachedAt, submittedAt = receipt.submittedAt)
        r446Observation = observation
        KeyguardCardDiagnostics.recordR446(observation)
        if (!r47RecordingHeader) mainHandler.postDelayed({ if (r45Direct.lease === lease) r446Cancel("deadline") },
            (ticket.deadline - SystemClock.uptimeMillis()).coerceAtLeast(0))
        return true
    }
    private var nextSystemGateId = 0L
    private val systemGateExecutor = java.util.concurrent.Executors.newSingleThreadExecutor { task ->
        Thread(task, "Fluvi-system-gate")
    }
    private val systemSampler = KeyguardSystemStateSampler(
        reader = { KeyguardSystemStateReader(::readSystemState) },
        worker = { systemGateExecutor.execute(it) },
        main = { mainHandler.post(it) },
        current = { inspectionAuthority },
        receive = ::applySystemState,
        reserveBeforeMain = ::reserveR18WakeBeforeMain,
        trace = KeyguardSystemSamplerTrace { phase, request, detail ->
            KeyguardCardDiagnostics.r41SamplerMark(phase, request, detail)
        },
    )
    private val mainWorkEvidence = KeyguardMainWorkEvidence()
    private val session = AtomicLong(0L)
    private val visibilityEpoch = AtomicLong(0L)
    /** Pointer interaction invalidates only inspections that began before the
     * touch. A new, genuine SystemUI event still starts a fresh inspection and
     * therefore retains full security authority while a finger is down. */
    private val interactionEpoch = AtomicLong(0L)
    /** Binder window traversal has its own one-wide lane. Financial Room work
     * cannot occupy it while a wake needs an eligibility decision. */
    private val serviceJob = SupervisorJob()
    private val surfaceDispatcher = Dispatchers.IO.limitedParallelism(1)
    private val financialDispatcher = Dispatchers.IO.limitedParallelism(1)
    private val inspectionScope = CoroutineScope(serviceJob + surfaceDispatcher)
    private val r449Scope = CoroutineScope(serviceJob + Dispatchers.IO)
    private class R43Plan(val captureId: String) {
        @Volatile var wakeAt = 0L
        val holds = AtomicIntegerArray(4)
        private val lastPassiveAt = AtomicLong(Long.MIN_VALUE)
        fun allowPassive(now: Long): Boolean {
            while (true) {
                val old = lastPassiveAt.get()
                if (old != Long.MIN_VALUE && now - old < 1_000L) return false
                if (lastPassiveAt.compareAndSet(old, now)) return true
            }
        }
    }
    @Volatile private var r43Plan: R43Plan? = null
    @Volatile private var r43EffectiveFlags: Int? = null
    private val r43Labels = arrayOf("CLOCK_1", "PIN", "CLOCK_2", "SHADE")

    /** One explicit opt-in, four bounded observations after the next wake.
     * The labels describe the owner's schedule, never a display permission. */
    internal fun armR43Capture(captureId: String) {
        mainHandler.post {
            if (Build.VERSION.SDK_INT >= 37 && KeyguardCardDiagnostics.r43Enabled(captureId))
                r43Plan = R43Plan(captureId)
        }
    }

    private fun scheduleR43Holds(wakeAt: Long) {
        val plan = r43Plan ?: return
        if (!KeyguardCardDiagnostics.r43Enabled(plan.captureId) || plan.wakeAt != 0L) return
        plan.wakeAt = wakeAt
        r43Labels.indices.forEach { index ->
            mainHandler.postDelayed({
                if (r43Plan === plan && KeyguardCardDiagnostics.r43Enabled(plan.captureId)) {
                    inspectionScope.launch {
                        if (!plan.holds.compareAndSet(index, KeyguardR43HoldTiming.OPEN, KeyguardR43HoldTiming.OBSERVER_RESERVED) ||
                            !KeyguardCardDiagnostics.r43Enabled(plan.captureId)) return@launch
                        val authority = inspectionAuthority
                        val scene = firstAuthorizedOrb.sceneHint()
                        val evidence = KeyguardR43SurfaceEvidence()
                        val busy = synchronized(queueLock) {
                            inspectionQueue.activeRequest() != null || inspectionQueue.pendingRequest() != null
                        }
                        if (busy) {
                            KeyguardCardDiagnostics.recordR43(applicationContext, KeyguardR43Observation(
                                plan.captureId, authority.serviceSession, authority.wakeGeneration, null, scene,
                                SystemClock.uptimeMillis(), "OBSERVER_SKIPPED_BUSY", r43Labels[index], r43EffectiveFlags,
                                true, KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.ROOT_UNAVAILABLE),
                                true, false, true, 0, 0, 0, evidence))
                            plan.holds.compareAndSet(index, KeyguardR43HoldTiming.OBSERVER_RESERVED, KeyguardR43HoldTiming.OBSERVER_INCOMPLETE)
                            return@launch
                        }
                        val observation = runCatching {
                            val result = windowSnapshotReader.read(
                                KeyguardWindowSnapshotReader.Request(knownOwnOverlayIdentity,
                                    authority.attachGeneration, r43Evidence = evidence),
                                authorityIsCurrent = {
                                    serviceJob.isActive && r43Plan === plan &&
                                        KeyguardCardDiagnostics.r43Enabled(plan.captureId) &&
                                        inspectionAuthority == authority && firstAuthorizedOrb.sceneHint() == scene
                                },
                            )
                            val classification = KeyguardSurfaceClassifier.classifyDetailed(result.snapshots,
                                unavailableRoot = result.rootUnavailable, walkTruncated = result.walkTruncated)
                            evidence.attachMarkers(result.snapshots)
                            KeyguardR43Observation(plan.captureId, authority.serviceSession, authority.wakeGeneration,
                                null, scene, SystemClock.uptimeMillis(), "OBSERVER", r43Labels[index], r43EffectiveFlags,
                                result.timing.ownAttributionAmbiguous,
                                classification, result.rootUnavailable, result.walkTruncated, result.abortedStale,
                                result.windowsReadMs, result.treeScanMs, result.visitedNodeCount, evidence)
                        }.getOrElse {
                            KeyguardR43Observation(plan.captureId, authority.serviceSession, authority.wakeGeneration,
                                null, scene, SystemClock.uptimeMillis(), "OBSERVER_ERROR", r43Labels[index], r43EffectiveFlags, true,
                                KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.ROOT_UNAVAILABLE),
                                true, false, true, 0, 0, 0, KeyguardR43SurfaceEvidence())
                        }
                        KeyguardCardDiagnostics.recordR43(applicationContext, observation)
                        if (observation.rootUnavailable || observation.truncated || observation.stale) {
                            plan.holds.compareAndSet(index, KeyguardR43HoldTiming.OBSERVER_RESERVED, KeyguardR43HoldTiming.OBSERVER_INCOMPLETE)
                        }
                    }
                }
            }, 4_000L + 6_000L * index)
        }
    }

    private fun recordR43Passive(request: KeyguardCardInspectionRequest, read: SystemWindowsRead,
                                 classification: KeyguardSurfaceClassification, scene: Long?) {
        val plan = r43Plan ?: return
        val evidence = read.r43Evidence ?: return
        if (!KeyguardCardDiagnostics.r43Enabled(plan.captureId) || request.diagnosticContext?.captureId != plan.captureId) return
        val at = SystemClock.uptimeMillis()
        val stale = scene == null || scene != firstAuthorizedOrb.sceneHint()
        evidence.attachMarkers(read.snapshots)
        val elapsed = at - plan.wakeAt
        val index = if (plan.wakeAt > 0L) KeyguardR43HoldTiming.passiveIndex(elapsed) else -1
        val inHold = index in r43Labels.indices &&
            !read.rootUnavailable && !read.walkTruncated && !read.abortedStale && !stale
        val holdState = if (inHold) plan.holds.get(index) else -1
        val label = if (inHold && KeyguardR43HoldTiming.canAcceptPassive(holdState)) r43Labels[index] else null
        val accepted = KeyguardCardDiagnostics.recordR43(applicationContext, KeyguardR43Observation(
            plan.captureId, request.session, request.wakeGeneration, request.id, scene, at, "PASSIVE", label,
            r43EffectiveFlags, read.timing.ownAttributionAmbiguous, classification,
            read.rootUnavailable, read.walkTruncated, read.abortedStale || stale,
            read.windowsReadMs, read.treeScanMs, read.visitedNodeCount, evidence))
        if (accepted && label != null) plan.holds.compareAndSet(index, holdState, KeyguardR43HoldTiming.PASSIVE_RETAINED)
    }
    private val financialScope = CoroutineScope(serviceJob + financialDispatcher)
    private val queueLock = Any()
    private val inspectionQueue = KeyguardCardInspectionQueue()
    /** Diagnostic-only receipt for a completed ordered positive waiting for
     * Main. It contains no node, View, financial data or display authority. */
    private data class R41ShadowReceipt(
        val request: Long, val session: Long, val wake: Long, val visibility: Long,
        val interaction: Long, val attachment: Long, val scene: Long,
        val context: KeyguardDiagnosticContext,
    )
    @Volatile private var r41ShadowReceipt: R41ShadowReceipt? = null
    private val r25Publication = KeyguardOpeningPublication<R25Completed>()
    private val r25ExclusionPosted = AtomicBoolean(false)
    /** Test dispatch may hold a single Main continuation without blocking Main. */
    @Volatile internal var r25MainDispatchForTest: ((KeyguardCardInspectionRequest, Runnable) -> Boolean)? = null
    /** Test-only asynchronous gate: holding the continuation never blocks the Main Looper. */
    @Volatile internal var r32MainApplyGateForTest: ((KeyguardCardInspectionRequest, Runnable) -> Boolean)? = null
    private suspend fun r32AwaitApplyGateForTest(request: KeyguardCardInspectionRequest) {
        val gate = r32MainApplyGateForTest ?: return
        val resume = CompletableDeferred<Unit>()
        if (gate(request, Runnable { resume.complete(Unit) })) resume.await()
    }
    internal fun r25ReaderBarrierForTest(acknowledge: () -> Unit) {
        inspectionScope.launch { acknowledge() }
    }
    private var r25MainSnapshot: R25RouteSnapshot? = null // queueLock; published by Main
    /** Main-published state only; the reader never consults a View or Main-owned owner fields. */
    private var r32MainSnapshot: R32DirectSnapshot? = null // queueLock
    private val openingHandoff = KeyguardOpeningInspectionHandoff()
    private val firstAcquisition = KeyguardFirstAcquisition()
    // Main publishes eligibility; the sampler can reserve only a successor
    // of that exact authority under the inspection queue lock. A reservation
    // is a reader/host preparation opportunity, not an admission to show.
    private data class R18ProvisionalWake(
        val sampleId: Long,
        val previousAuthority: KeyguardInspectionAuthority,
        val targetAuthority: KeyguardInspectionAuthority,
        val routeRevision: Long,
        val firstRequestId: Long,
        val receivedAt: Long,
        val reservedAt: Long,
        val source: String,
        val token: KeyguardOrbPresentationCoordinator.Reservation,
        val preparation: KeyguardCardWindow.R18Preparation,
        @Volatile var diagnosticContext: KeyguardDiagnosticContext? = null,
    )
    @Volatile private var r18ProvisionalWake: R18ProvisionalWake? = null
    @Volatile private var r18RouteEnabled = false
    @Volatile private var r18WakeOpen = false
    private var r18RouteRevision = 0L // queueLock
    private var r18AdoptedSampleId: Long? = null // Main
    private data class R18RouteSnapshot(val preparation: KeyguardCardWindow.R18Preparation,
        val settingsRevision: Long, val materialRevision: Long, val dataRevision: Long, val layoutRevision: Long)
    private data class R18Identity(val token: KeyguardOrbPresentationCoordinator.Reservation,
        val preparation: KeyguardCardWindow.R18Preparation)
    /** Main-published scalar route and revision identity; never a View or grant. */
    private data class R25RouteSnapshot(
        val authority: KeyguardInspectionAuthority,
        val stateRevision: Long,
        val freshnessRevision: Long,
        val routeRevision: Long,
        val settingsGeneration: Long,
        val dataGeneration: Long,
        val layoutRevision: Long,
        val materialRevision: Long,
        val backend: String,
        val reservationId: Long?,
        val hostGeneration: Long?,
        val outputGeneration: Long?,
    )
    private data class R32DirectSnapshot(
        val readAhead: KeyguardReadAheadSnapshot,
        val route: R25RouteSnapshot,
        val reservation: KeyguardOrbPresentationCoordinator.Reservation,
        val sceneSerial: Long,
    )
    private class R18Active(token: KeyguardOrbPresentationCoordinator.Reservation,
                            preparation: KeyguardCardWindow.R18Preparation,
                            val diagnosticContext: KeyguardDiagnosticContext?) {
        @Volatile var identity = R18Identity(token, preparation)
        val token get() = identity.token
        val preparation get() = identity.preparation
        @Volatile var host: android.view.View? = null
        var hostReady = false
        var hostWindowId: Int? = null
        var binding = false
        var bound = false
        @Volatile var output: Any? = null
        var firstProof: KeyguardFirstAuthorizedOrb.Proof? = null // Main
        var paintRequested = false // Main; this exact virgin target only
        var lastReconciledScene = -1L // Main, at most once per scene
        var lastExpiredProof = 0L // Main, diagnostic coalescing only
        var lastR22WaitReason: String? = null // Main, bounded diagnostic coalescing only
        @Volatile var r21Binding: R21Binding? = null
        // Diagnostic identity only. Written after a successful grant and read
        // on withdrawal; never used to admit or retain a presentation.
        @Volatile var r41GrantRequest = 0L
        // Published only after the original coordinator ACK. No witness is
        // acquired or armed during the first-show path.
        @Volatile var r40Acknowledged: R21Binding? = null
    }
    private data class R21Binding(val token: KeyguardOrbPresentationCoordinator.Reservation,
        val attachment: Long, val outputGeneration: Long, val childId: Int?,
        val context: KeyguardDiagnosticContext?, val reveal: KeyguardOrbPresentationCoordinator.Reveal,
        val r41ProofId: Long?)
    private data class R21Ingress(val owner: R18Active, val binding: R21Binding,
        val decision: KeyguardOrbPresentationCoordinator.IngressDecision)
    private class R40Read(val owner: R18Active, val identity: R18Identity, val binding: R21Binding,
                          val authority: KeyguardInspectionAuthority, val scene: Long) {
        val provenance = KeyguardR40ClockProvenance()
    }

    private class R18DrainBinding(val token: KeyguardOrbPresentationCoordinator.Reservation,
        val diagnosticContext: KeyguardDiagnosticContext?, val attachment: Long, val generation: Long, val output: Any) {
        var drained = false // queueLock; retained for a possible late receipt
    }
    private val r18Coordinator = KeyguardOrbPresentationCoordinator(queueLock)
    private val firstAuthorizedOrb = KeyguardFirstAuthorizedOrb(queueLock)
    private val r40RemovalGate = KeyguardR40RemovalGate(queueLock, r18Coordinator)
    private val r40AppUid = android.os.Process.myUid()
    private val r19JoinPosted = AtomicBoolean(false)
    private val r18DrainBindings = arrayOfNulls<R18DrainBinding>(2) // queueLock
    private var r18RouteSnapshot: R18RouteSnapshot? = null // queueLock
    private var r18NextHostGeneration = 0L // queueLock
    @Volatile private var r18Active: R18Active? = null
    private var r18FallbackWake: Long? = null // Main
    private var r18ProofRequestId: Long? = null // Main, current complete inspection only
    // Main-owned diagnostic observation only. It never grants visibility or
    // initiates another system read, and carries its own original authority.
    private var latestSamplerEvidence: KeyguardSamplerEvidence? = null
    // Published only by Main, guarded by the same lock as reservation. The
    // reader may consume this immutable snapshot but cannot change a View.
    private var readAheadStateRevision = 0L
    private var readAheadShowInProgress = false
    private var readAheadSnapshot: KeyguardReadAheadSnapshot? = null
    private val nextInspectionId = AtomicLong(0L)
    private var nextR14IngressId = 0L
    private var nextR14RecoveryId = 0L
    /** Main owns the one-use, authority-qualified token; it never owns a View. */
    @Volatile private var r14Recovery: KeyguardR14Recovery? = null
        set(value) = synchronized(queueLock) {
            field = value
            if (value != null) r32MainSnapshot = null
        }
    private var contentJob: Job? = null
    private var coreObservation: Job? = null
    private var observedFocusGeneration: Long? = null
    private var activeFocusGeneration: Long? = null
    private var renderedFullContent: FluviLockScreenCardContent? = null
    /** A deterministic invalid focus must not turn every SystemUI event into
     * another doomed database resolve. Cleared with a new focus or a
     * deliberate content invalidation. */
    private var terminalContentFailure: Pair<Long, String>? = null
    /** A transient query failure is retried only by a meaningful core
     * invalidation, focus change, or new visible session—not by a burst of
     * accessibility content events from the same lockscreen. */
    private var transientContentFailure: Pair<Long, String>? = null
    private var resolvingFocusGeneration: Long? = null
    private var resolveQueued = false
    private var receiverRegistered = false
    private var displayRegistered = false
    private var retryCount = 0
    private var retryRunnable: Runnable? = null
    private var retryToken: RetryToken? = null
    private var nextRetryId = 0L
    @Volatile private var wakeEpoch = 0L
    /** One physical wake can be signalled by DisplayManager, accessibility and
     * ACTION_SCREEN_ON in either order. The pure owner prevents the late
     * broadcast from invalidating a compatible early inspection. */
    private val wakeCycleOwner = KeyguardWakeCycleOwner()
    /** Published from the main-thread lifecycle owner.  Binder traversal uses
     * this immutable snapshot instead of sampling five generations halfway
     * through a node walk. */
    @Volatile private var inspectionAuthority = KeyguardInspectionAuthority(
        serviceSession = 0L,
        visibilityEpoch = 0L,
        wakeGeneration = 0L,
        interactionEpoch = 0L,
        attachGeneration = 0L,
    )
    @Volatile private var knownOwnOverlayIdentity: KeyguardOwnOverlayIdentity? = null
    private val inspectionFreshness = KeyguardInspectionFreshness()
    /** The reader owns no visibility authority.  It only receives immutable
     * request identity and cooperatively stops after this service publishes a
     * newer authority snapshot. */
    private val windowSnapshotReader by lazy {
        KeyguardWindowSnapshotReader(this, packageName)
    }
    private val inspectionsAbortedBeforeRead = AtomicLong(0L)
    private val inspectionsAbortedDuringWalk = AtomicLong(0L)
    private val nodeReadsAfterInvalidation = AtomicLong(0L)
    private val freshReconciliationsScheduled = AtomicLong(0L)
    private val activeInspectionCount = AtomicInteger(0)
    private val maximumConcurrentInspections = AtomicInteger(0)
    private val maximumPendingInspections = AtomicInteger(0)
    @Volatile private var lastSettings: KeyguardCardSettings? = null
    @Volatile private var lastMaterialProfile: KeyguardMaterialProfile? = null
    private var showEvent = false
    private var appliedDecision = KeyguardCardVisibility.HIDDEN_DISCONNECTED
    /** Surface uncertainty is distinct from a terminal device exclusion.  The
     * window lifecycle remains authoritative for attachment; this state keeps
     * UNKNOWN results from churning authority while that lifecycle is already
     * detached. */
    private var surfacePresentationState = KeyguardSurfacePresentationState.TERMINALLY_EXCLUDED
    private var overlayAttachGeneration = 0L
    private lateinit var overlay: KeyguardCardWindow
    /** These identities are diagnostic-only and stay stable across the
     * generation invalidation that a terminal hide must perform. */
    private var currentDiagnosticAttempt: KeyguardDiagnosticContext? = null
    private var activeWindowDiagnosticOperation: KeyguardDiagnosticOperation? = null
    private var terminalHideState: KeyguardTerminalHideState? = null

    /** Must be called by the main-thread lifecycle owner after every
     * generation transition.  It never reads View state and is safe for the
     * one-wide Binder worker to consume. */
    private fun publishInspectionAuthority(renewSystemWork: Boolean = true) {
        val current = KeyguardInspectionAuthority(
            serviceSession = session.get(),
            visibilityEpoch = visibilityEpoch.get(),
            wakeGeneration = wakeEpoch,
            interactionEpoch = interactionEpoch.get(),
            attachGeneration = overlayAttachGeneration,
        )
        var r25Retired: KeyguardOpeningPublication.Discarded<R25Completed>? = null
        synchronized(queueLock) {
            if (inspectionAuthority != current) {
                if (r40RemovalGate.hasWitness) r40RemovalGate.clear()
                r25Publication.waitingRequest()?.takeIf { !current.matches(it) }?.let {
                    r25Retired = r25Publication.discard(inspectionQueue, it)
                }
                readAheadStateRevision += 1L
                val early = r18ProvisionalWake
                val adopting = early != null && early.previousAuthority == inspectionAuthority &&
                    early.targetAuthority == current && early.routeRevision == r18RouteRevision
                if (!adopting) {
                    openingHandoff.invalidate()
                    cancelR18ReservationLocked()
                    firstAcquisition.invalidate()
                }
            }
            inspectionFreshness.publish(current)
            inspectionAuthority = current
            publishReadAheadSnapshotLocked()
        }
        if (renewSystemWork) systemSampler.renewPending { old ->
            old.copy(id = ++nextSystemGateId, authority = current, queuedAt = SystemClock.uptimeMillis(),
                r447Duplicate = null)
        }
        r25Retired?.let { old ->
            recordR25("DISCARDED", old.ticket.request, old.successor, old.ticket.value.route,
                readEnd = old.ticket.value.read.finishedAt, reason = "AUTHORITY_CHANGED")
            old.successor?.takeIf { serviceJob.isActive }?.let { actual ->
                inspectionScope.launch { processInspectionQueue(actual) }
            }
        }
    }

    /** Main owns the sampled fields. Lock ordering is queue then freshness;
     * neither lock is held across a Binder call or a Main handoff. */
    private fun publishReadAheadSnapshotLocked() {
        val freshness = inspectionFreshness.revisionFor(inspectionAuthority)
        readAheadSnapshot = freshness?.let {
            KeyguardReadAheadSnapshot(
                authority = inspectionAuthority,
                freshnessRevision = it,
                stateRevision = readAheadStateRevision,
                detached = ::overlay.isInitialized && !overlay.isAttached,
                showInProgress = readAheadShowInProgress,
                surfaceState = surfacePresentationState,
            )
        }
        r25MainSnapshot = r25BuildSnapshotLocked()
        val route = r25MainSnapshot
        val ahead = readAheadSnapshot
        val owner = r18Active
        val coordinator = r18Coordinator.snapshot()
        val proposed = if (route?.backend == "R18_DIRECT" && ahead != null && owner != null &&
            owner.preparation.full && owner.preparation.emptyAwaitingDisclosure && !owner.paintRequested &&
            owner.firstProof == null && r14Recovery == null && coordinator.reservation === owner.token &&
            coordinator.proofRequestId == null && coordinator.grant == KeyguardOrbPresentationCoordinator.Grant.NONE &&
            (coordinator.host == KeyguardOrbPresentationCoordinator.Host.NONE ||
                coordinator.host == KeyguardOrbPresentationCoordinator.Host.INERT ||
                coordinator.host == KeyguardOrbPresentationCoordinator.Host.READY)
        ) R32DirectSnapshot(ahead, route, owner.token, firstAuthorizedOrb.sceneSerial()) else null
        r32MainSnapshot = KeyguardR34SnapshotIdentity.publish(r32MainSnapshot, proposed) { old, next ->
            old.readAhead == next.readAhead && old.route == next.route && old.reservation === next.reservation &&
                old.sceneSerial == next.sceneSerial
        }
    }

    private fun publishReadAheadState(invalidate: Boolean = false) {
        val retired = synchronized(queueLock) {
            val discarded = if (invalidate) {
                openingHandoff.invalidate()
                readAheadStateRevision += 1L
                r18RouteRevision += 1L
                cancelR18ReservationLocked()
                firstAcquisition.invalidate()
                r25Publication.waitingRequest()?.let { r25Publication.discard(inspectionQueue, it) }
            } else null
            publishReadAheadSnapshotLocked()
            discarded
        }
        retired?.let { old ->
            recordR25("DISCARDED", old.ticket.request, old.successor, old.ticket.value.route,
                readEnd = old.ticket.value.read.finishedAt, reason = "STATE_INVALIDATED")
            old.successor?.takeIf { serviceJob.isActive }?.let { actual ->
                inspectionScope.launch { processInspectionQueue(actual) }
            }
        }
    }

    private fun setReadAheadShowInProgress(value: Boolean) {
        synchronized(queueLock) {
            readAheadStateRevision += 1L
            readAheadShowInProgress = value
            publishReadAheadSnapshotLocked()
        }
    }

    /** Called under queueLock; reads only immutable/scalar state already
     * published by Main. It never consults a View or Android platform API. */
    private fun r25BuildSnapshotLocked(): R25RouteSnapshot? {
        val ahead = readAheadSnapshot ?: return null
        val settings = lastSettings ?: return null
        val profile = lastMaterialProfile ?: return null
        if (ahead.authority != inspectionAuthority || !ahead.detached || ahead.showInProgress ||
            (ahead.surfaceState != KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE &&
                ahead.surfaceState != KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE) ||
            !settings.requested || !settings.showFinancialDetails || !settings.focus.isValid ||
            settings.presentationMode != KeyguardCardPresentationMode.ORB ||
            settings.animationMode == KeyguardCardAnimationMode.OFF || !profile.animated ||
            r14Recovery != null || firstAuthorizedOrb.current() != null) return null
        val coordinator = r18Coordinator.snapshot()
        val owner = r18Active
        if (owner == null) {
            if (r18ProvisionalWake != null || (coordinator.reservation != null &&
                coordinator.grant != KeyguardOrbPresentationCoordinator.Grant.RETIRED)) return null
        } else {
            val token = owner.token
            if (coordinator.reservation !== token || token.stamp.authority != ahead.authority ||
                !owner.preparation.full || !owner.preparation.emptyAwaitingDisclosure || owner.paintRequested ||
                coordinator.grant != KeyguardOrbPresentationCoordinator.Grant.NONE ||
                coordinator.host == KeyguardOrbPresentationCoordinator.Host.INPUT_ARMED ||
                coordinator.host == KeyguardOrbPresentationCoordinator.Host.REMOVAL_PENDING ||
                coordinator.host == KeyguardOrbPresentationCoordinator.Host.REMOVED) return null
        }
        return R25RouteSnapshot(ahead.authority, ahead.stateRevision, ahead.freshnessRevision,
            r18RouteRevision, settings.generation, settings.focus.generation, settings.layoutRevision,
            profile.publisherRevision, if (owner == null) "STOCK" else "R18_DIRECT",
            owner?.token?.id, owner?.token?.stamp?.hostGeneration, owner?.preparation?.outputGeneration)
    }

    private fun r25SnapshotLocked(request: KeyguardCardInspectionRequest): R25RouteSnapshot? {
        val published = r25MainSnapshot ?: return null
        if (!published.authority.matches(request) || r25BuildSnapshotLocked() != published) return null
        return published
    }

    private fun readAheadStillCurrent(snapshot: KeyguardReadAheadSnapshot): Boolean =
        synchronized(queueLock) {
            readAheadSnapshot == snapshot && inspectionAuthority == snapshot.authority &&
                inspectionFreshness.revisionFor(snapshot.authority) == snapshot.freshnessRevision
        }

    private fun authorityIsCurrent(request: KeyguardCardInspectionRequest): Boolean {
        val published = inspectionAuthority
        val provisional = r18ProvisionalWake
        return if (provisional != null && published == provisional.previousAuthority) {
            provisional.targetAuthority.matches(request)
        } else published.matches(request)
    }

    /** Caller holds queueLock; platform and View operations are forbidden. */
    private fun cancelR18ReservationLocked() {
        val early = r18ProvisionalWake ?: return
        r18ProvisionalWake = null
        r18Coordinator.seal(early.token, early.targetAuthority, early.firstRequestId, true)
        r18Coordinator.retired(early.token)
        if (inspectionAuthority == early.previousAuthority) inspectionFreshness.publish(inspectionAuthority)
        firstAcquisition.invalidate()
    }

    /** Called on Main only, outside queueLock. This publishes scalar route
     * eligibility for a later worker sample; it performs no screen admission. */
    private fun refreshR18RouteOnMain() {
        val settings = lastSettings
        val profile = lastMaterialProfile
        val eligible = r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM &&
            Build.VERSION.SDK_INT == 35 && settings != null && profile != null &&
            ::overlay.isInitialized && overlay.preparedInitialLiveOrb(settings, profile)
        val preparation = if (eligible) overlay.r18Preparation() ?: overlay.prepareR18() else null
        val next = if (preparation != null && settings != null && profile != null &&
            settings.generation >= 0 && profile.publisherRevision >= 0 && settings.focus.generation >= 0) {
            R18RouteSnapshot(preparation, settings.generation, profile.publisherRevision,
                settings.focus.generation, settings.layoutRevision)
        } else null
        synchronized(queueLock) {
            if (r18RouteSnapshot != next) {
                r18RouteSnapshot = next
                r18RouteEnabled = next != null
                r18RouteRevision += 1L
                cancelR18ReservationLocked()
            }
            publishReadAheadSnapshotLocked()
        }
    }

    /** Called on the system sampler, never Main. The queue still has exactly
     * one physical reader. Main must adopt this exact next-wake authority
     * before the result can affect a View or a financial subscription. */
    private fun reserveR18WakeBeforeMain(
        sample: KeyguardSystemGateRequest, state: KeyguardSystemState,
    ): (() -> Unit)? {
        if (!localPresentationAllowed()) return null
        if (state.excluded) {
            synchronized(queueLock) { openingHandoff.invalidate() }
            sealR18(sample.authority, Long.MAX_VALUE, "systemSample", sample, state)
            return null
        }
        if (!state.eligible || !sample.evaluate || sample.wakeSource == null ||
            !FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return null
        val queuedAt = SystemClock.uptimeMillis()
        val requestId = nextInspectionId.incrementAndGet()
        val early = synchronized(queueLock) {
            if (!localPresentationAllowed()) return@synchronized null
            val route = r18RouteSnapshot ?: return@synchronized null
            if (!r18RouteEnabled || r18WakeOpen || r18ProvisionalWake != null ||
                inspectionAuthority != sample.authority) return@synchronized null
            val target = sample.authority.copy(wakeGeneration = sample.authority.wakeGeneration + 1)
            val prep = route.preparation
            val stamp = KeyguardOrbPresentationStamp(target, requestId, r18RouteRevision,
                route.materialRevision, route.dataRevision, prep.width, prep.height, prep.densityDpi,
                prep.full, ++r18NextHostGeneration, prep.outputGeneration, Display.DEFAULT_DISPLAY)
            val token = r18Coordinator.reserve(stamp, sample.id, sample.authority, inspectionAuthority,
                sampleEligible = true, routeEligible = true) ?: return@synchronized null
            R18ProvisionalWake(sample.id, sample.authority, target, r18RouteRevision, requestId,
                sample.evaluationReceivedAt, queuedAt, sample.wakeSource, token, prep).also { r18ProvisionalWake = it }
        } ?: return null
        // Diagnostic allocation is outside the queue/authority lock and keeps
        // its original wake identity. A cancelled reservation is not a grant.
        val capture = sample.diagnosticCaptureId
        if (capture != null && capture == KeyguardCardDiagnostics.activeCaptureId()) {
            early.diagnosticContext = runCatching {
                KeyguardCardDiagnostics.beginLockAttempt(this, early.targetAuthority.serviceSession,
                    early.targetAuthority.wakeGeneration, early.source, early.receivedAt)
            }.getOrNull()
            KeyguardCardDiagnostics.r41Bind(early.diagnosticContext, sample.r41WakeOrdinal)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.SYSTEM_ELIGIBLE, early.diagnosticContext)
        }
        val authority = early.targetAuthority
        val request = KeyguardCardInspectionRequest(
            id = early.firstRequestId, trigger = sample.evaluationReason,
            session = authority.serviceSession, visibilityEpoch = authority.visibilityEpoch,
            interactionEpoch = authority.interactionEpoch, attachGeneration = authority.attachGeneration,
            wakeGeneration = authority.wakeGeneration, queuedAtUptimeMs = queuedAt,
            windowFreshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY,
            eventTimeUptimeMs = sample.eventTime, diagnosticContext = early.diagnosticContext,
            triggerReceivedUptimeMs = sample.evaluationReceivedAt,
        )
        val offer = synchronized(queueLock) {
            if (r18ProvisionalWake !== early || inspectionAuthority != early.previousAuthority ||
                r18WakeOpen || !r18RouteEnabled || r18RouteRevision != early.routeRevision) {
                if (r18ProvisionalWake === early) cancelR18ReservationLocked()
                return@synchronized null
            }
            inspectionFreshness.publish(authority)
            inspectionFreshness.require(authority, KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
            firstAcquisition.begin(authority, preparedLiveOrb = true)
            firstAuthorizedOrb.requireRead(request.id)
            val startsWorker = inspectionQueue.offer(request)
            val snapshot = readAheadSnapshot
            val openingArmed = if (Build.VERSION.SDK_INT == 35 && early.preparation.emptyAwaitingDisclosure && early.preparation.full &&
                snapshot?.detached == true && !readAheadShowInProgress &&
                r18Coordinator.snapshot().reservation === early.token) {
                openingHandoff.arm(early.token, early.token.id, request, authority, early.routeRevision)
            } else false
            val promoted = if (!startsWorker) r25PromoteWaitingLocked() else null
            Triple(if (startsWorker) inspectionQueue.activeRequest() else promoted?.successor,
                openingArmed, promoted?.ticket)
        } ?: return null
        val r41OfferNs = if (request.diagnosticContext?.captureId != null &&
            request.diagnosticContext.captureId == KeyguardCardDiagnostics.activeCaptureId()) System.nanoTime() else Long.MIN_VALUE
        runCatching { inspectionProbeForTest?.openingReserved(request, early.token.id, offer.second) }
        offer.third?.let { old -> r25RequestExclusionCheck(old.request.session) }
        return {
            // A cancellation after posting Main cannot relabel this work.
            // An offered active item must run even if cancelled in the gap;
            // its stale-read branch drains the single-owner queue.
            offer.first?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
            if (r41OfferNs != Long.MIN_VALUE) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER,
                request.diagnosticContext, request.id, atNs = r41OfferNs)
            offer.third?.let { old ->
                recordR25("SUPERSEDED", old.request, offer.first, old.value.route,
                    at = queuedAt, readEnd = old.value.read.finishedAt, reason = "EARLY_OFFER_BEFORE_CLAIM")
            }
        }
    }

    /** Immutable capture ownership is carried even when receipt delivery is
     * later than withdrawal or another wake. The reducer applies its capture
     * token/freeze gate before retaining this bounded boundary observation. */
    private fun recordR18(owner: R18Active, phase: String, observedAt: Long = SystemClock.uptimeMillis(),
                          proof: Long? = null, sample: KeyguardSystemState? = null, reservedAt: Long? = null,
                          r19ReadScene: Long? = null, r19Freshness: Long? = null,
                          r19ReadStart: Long? = null, r19Inspection: Inspection? = null,
                          exactIdentity: R18Identity? = null) {
        val context = owner.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        val identity = exactIdentity ?: owner.identity
        val token = identity.token
        val prep = identity.preparation
        // A sealed identity may have been replaced after the transition;
        // do not attach the then-current output's child to that old owner.
        val child = if (exactIdentity == null)
            (owner.output as? com.fluvi.app.lockscreen.material.KeyguardOrbDirectOutput)?.childId else null
        val currentScene = firstAuthorizedOrb.sceneSerial()
        val nsBefore = System.nanoTime()
        val alignedUptime = SystemClock.uptimeMillis()
        val nsAfter = System.nanoTime()
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
            serviceSession = token.stamp.authority.serviceSession, wakeEpoch = token.stamp.authority.wakeGeneration,
            requestId = proof ?: token.stamp.firstRequestId, attachGeneration = prep.attachment,
            observedUptimeMs = observedAt, diagnosticContext = context,
            deferredFields = { mapOf("r18Host" to token.stamp.hostGeneration, "r18Output" to prep.outputGeneration,
                "r18ReservationId" to token.id, "r18Child" to (child ?: "UNOBSERVED"), "r18Privacy" to if (prep.full) "full" else "discreet",
                "r18Phase" to phase, "r18Proof" to (proof ?: "UNOBSERVED"),
                "r18SampleStart" to (sample?.startedAt ?: "UNOBSERVED"),
                "r18SampleEnd" to (sample?.finishedAt ?: "UNOBSERVED"),
                "r18Reservation" to (reservedAt ?: "UNOBSERVED"),
                "r18AlignUptime" to alignedUptime, "r18AlignNano" to (nsBefore + (nsAfter - nsBefore) / 2),
                "r18AlignUncertaintyNs" to ((nsAfter - nsBefore) / 2 + 1_000_000L),
                "r19Intent" to if (prep.emptyAwaitingDisclosure) "EMPTY" else "DISCREET_OR_AUTHORIZED",
                "r19SceneRead" to (r19ReadScene ?: "UNOBSERVED"), "r19SceneNow" to currentScene,
                "r19Freshness" to (r19Freshness ?: "UNOBSERVED"), "r19ReadStart" to (r19ReadStart ?: "UNOBSERVED"),
                "r19RootMs" to (r19Inspection?.windowTiming?.activeRootTotalMs ?: "UNOBSERVED"),
                "r19RootFlags" to (r19Inspection?.windowTiming?.activeRootPrefetchFlags ?: "UNOBSERVED"),
                "r19ChildFlags" to (r19Inspection?.windowTiming?.acceptedChildPrefetchFlags ?: "UNOBSERVED")) })
    }

    private fun startR18Stage(token: KeyguardOrbPresentationCoordinator.Reservation,
                              prep: KeyguardCardWindow.R18Preparation, settings: KeyguardCardSettings,
                              context: KeyguardDiagnosticContext?, sample: KeyguardSystemState? = null,
                              reservedAt: Long? = null) {
        if (!localPresentationAllowed()) {
            synchronized(queueLock) {
                openingHandoff.invalidate()
                if (r18Coordinator.seal(token, token.stamp.authority, Long.MAX_VALUE, true) != null)
                    r18Coordinator.retired(token)
            }
            return
        }
        val owner = R18Active(token, prep, context)
        r18Active = owner
        synchronized(queueLock) { publishReadAheadSnapshotLocked() }
        recordR18(owner, "WAKE_ADOPTED", sample = sample, reservedAt = reservedAt)
        recordR18(owner, "HOST_ADD_BEGIN")
        if (!overlay.stageR18Host(token.stamp.hostGeneration, settings)) {
            failR18Stage(owner, "hostStageFailed"); return
        }
        val host = overlay.stagedR18Host(token.stamp.hostGeneration)
        if (host == null || !r18Coordinator.attachInertHost(token, host)) {
            failR18Stage(owner, "hostIdentityChanged"); return
        }
        owner.host = host
        recordR18(owner, "HOST_ADDED")
        maybeBindR18(owner)
    }

    private fun onR18HostReady(generation: Long, host: android.view.View, windowId: Int) {
        val owner = r18Active ?: return
        val token = owner.token
        if (token.stamp.hostGeneration != generation || owner.host !== host ||
            !r18Coordinator.hostReady(token, host)) return
        owner.hostReady = true
        owner.hostWindowId = windowId
        knownOwnOverlayIdentity = KeyguardOwnOverlayIdentity(windowId, Display.DEFAULT_DISPLAY,
            token.stamp.authority.attachGeneration)
        recordR18(owner, "HOST_READY")
        maybeBindR18(owner)
    }

    /** Main owns ingress. Serial invalidation itself is linearized with the
     * coordinator's submit boundary; Android and diagnostic work stay out of
     * that scalar lock. */
    private data class R19SceneInvalidation(val retained: R21Ingress?, val scene: Long)

    private fun invalidateR19Scene(reason: String, ordinaryRecheck: Boolean = false,
                                   meta: KeyguardAccessibilityEventMeta? = null, callbackAt: Long? = null): R19SceneInvalidation {
        val owner = r18Active
        val identity = owner?.identity
        val binding = owner?.r21Binding?.takeIf { it.token === identity?.token }
        val previous: KeyguardFirstAuthorizedOrb.Proof?
        val decision: KeyguardOrbPresentationCoordinator.IngressDecision?
        val needsStockFallback: Boolean
        val scene: Long
        val observedAt = callbackAt ?: SystemClock.uptimeMillis()
        synchronized(queueLock) {
            previous = firstAuthorizedOrb.current()
            if (r40RemovalGate.hasWitness) r40RemovalGate.clear()
            scene = firstAuthorizedOrb.externalIngress()
            if (reason == "INGRESS" && ordinaryRecheck && meta != null) {
                openingHandoff.externalInvalidation(scene, observedAt)
            }
            val snapshot = r18Coordinator.snapshot()
            decision = if (owner != null && identity != null && owner.preparation.emptyAwaitingDisclosure &&
                snapshot.host == KeyguardOrbPresentationCoordinator.Host.INPUT_ARMED &&
                snapshot.grant != KeyguardOrbPresentationCoordinator.Grant.PRESENTED)
                r18Coordinator.arbitrateIngress(identity.token, owner.host, owner.output, ordinaryRecheck && binding != null)
            else null
            needsStockFallback = owner != null && owner.preparation.emptyAwaitingDisclosure &&
                snapshot.host == KeyguardOrbPresentationCoordinator.Host.INPUT_ARMED &&
                snapshot.grant != KeyguardOrbPresentationCoordinator.Grant.PRESENTED &&
                decision?.action != KeyguardOrbPresentationCoordinator.IngressAction.KEEP_SUBMITTED
        }
        if (owner != null && owner.preparation.emptyAwaitingDisclosure && previous != null)
            recordR18(owner, "R19_EXPIRED_$reason", proof = previous.requestId,
                r19ReadScene = previous.sceneSerial, r19Freshness = previous.freshnessRevision)
        if (decision != null && binding != null && decision.action == KeyguardOrbPresentationCoordinator.IngressAction.CANCEL_PENDING)
            runCatching { recordR21(binding, "INGRESS", callbackAt ?: SystemClock.uptimeMillis(), decision.ordinal,
                decision.phase.name, decision.action.name, source = reason, meta = meta, callbackAt = callbackAt) }
        if (needsStockFallback && owner != null) failR18Stage(owner, "sceneChangedBeforeSubmit")
        val retained = if (owner != null && binding != null && decision?.action == KeyguardOrbPresentationCoordinator.IngressAction.KEEP_SUBMITTED)
            R21Ingress(owner, binding, decision) else null
        return R19SceneInvalidation(retained, scene)
    }

    /** Exact original capture owner is immutable even if a later host replaces
     * it. Deferred field formatting runs on the existing diagnostic consumer. */
    private fun recordR21(binding: R21Binding, stage: String, at: Long, ordinal: Long?,
                          submitPhase: String, result: String, source: String = "UNOBSERVED",
                          meta: KeyguardAccessibilityEventMeta? = null, callbackAt: Long? = null,
                          offered: Long? = null) {
        val context = binding.context ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        val stamp = binding.token.stamp
        val reveal = binding.reveal
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "R21_$stage",
            serviceSession = stamp.authority.serviceSession, wakeEpoch = stamp.authority.wakeGeneration,
            requestId = stamp.firstRequestId, attachGeneration = binding.attachment,
            observedUptimeMs = at, diagnosticContext = context, deferredFields = { mapOf(
                "r18Host" to stamp.hostGeneration, "r18Output" to binding.outputGeneration,
                "r18ReservationId" to binding.token.id, "r18Child" to (binding.childId ?: "UNOBSERVED"), "r18Privacy" to if (stamp.full) "full" else "discreet",
                "r21Reservation" to binding.token.id, "r21Reveal" to reveal.sequence, "r21Proof" to reveal.proofRequestId,
                "r21Ordinal" to (ordinal ?: "UNOBSERVED"), "r21SubmitPhase" to submitPhase,
                "r21Result" to result, "r21Source" to source,
                "r21EventType" to (meta?.eventType ?: "UNOBSERVED"), "r21WindowChanges" to (meta?.windowChanges ?: "UNOBSERVED"),
                "r21Display" to (meta?.displayId ?: "UNOBSERVED"), "r21Window" to (meta?.windowId ?: "UNOBSERVED"),
                "r21Own" to if (meta == null) "UNOBSERVED" else "false", "r21EventAt" to (meta?.eventTimeUptimeMs?.takeIf { it > 0 } ?: "UNOBSERVED"),
                "r21CallbackAt" to (callbackAt ?: "UNOBSERVED"), "r21Offered" to (offered ?: "UNOBSERVED")) })
    }

    private fun onR19Allocated(attachment: Long, generation: Long, at: Long) {
        val owner = r18Active ?: return
        if (owner.preparation.attachment != attachment || owner.preparation.outputGeneration != generation) return
        recordR18(owner, "R19_ALLOCATED", at)
        maybeBindR18(owner)
    }

    private fun onR18BufferReady(attachment: Long, generation: Long, at: Long) {
        val owner = r18Active ?: return
        if (owner.preparation.attachment != attachment || owner.preparation.outputGeneration != generation) return
        recordR18(owner, "BUFFER_READY", at)
        maybeBindR18(owner)
    }

    private fun maybeBindR18(owner: R18Active) {
        if (r18Active !== owner) return
        val token = owner.token
        val prep = owner.preparation
        val output = overlay.r19AllocatedOutput(prep) ?: return
        if (owner.output !== output) {
            val accepted = synchronized(queueLock) {
                val empty = r18DrainBindings.indexOfFirst { it == null }
                val free = if (empty >= 0) empty else r18DrainBindings.indexOfFirst { it?.drained == true }
                if (free < 0 || !r18Coordinator.attachPreparedOutput(token, output)) false
                else {
                    r18DrainBindings[free] = R18DrainBinding(token, owner.diagnosticContext,
                        prep.attachment, prep.outputGeneration, output)
                    true
                }
            }
            if (!accepted) { failR18Stage(owner, "outputCapacityOrIdentity"); return }
            owner.output = output
            // The allocation callback may have preceded wake adoption. Preserve
            // the original timestamp for this exact still-current output.
            overlay.r19AllocatedAt(prep)?.let { recordR18(owner, "R19_ALLOCATED", it) }
            overlay.r18ReadyAt(prep)?.let { recordR18(owner, "BUFFER_READY", it) }
        }
        // A blank resource is not an image. Only a matching real posted frame
        // can set the coordinator's image-ready bit.
        val firstFrameReady = overlay.r18PreparedOutput(prep) === output
        if (firstFrameReady) r18Coordinator.imageReady(token, output)
        // The pre-existing discreet and replacement paths still bind only
        // after their real poster; only a virgin FULL intent binds blank.
        if (!prep.emptyAwaitingDisclosure && !firstFrameReady) return
        if (owner.hostReady && !owner.binding && !owner.bound) {
            owner.binding = true
            overlay.bindR18Host(token.stamp.hostGeneration, prep) { success ->
                if (r18Active !== owner || owner.token !== token || owner.preparation != prep) return@bindR18Host
                owner.binding = false
                if (!success) { failR18Stage(owner, "hiddenBindFailed"); return@bindR18Host }
                owner.bound = true
                recordR18(owner, "HIDDEN_BOUND")
                if (prep.emptyAwaitingDisclosure) advanceR19First(owner)
                else requestSystemCheck("r18Ready", evaluate = true,
                    sampleOrigin = R447SystemOrigin.INTERNAL_OUTPUT_READY)
            }
        }
        if (prep.emptyAwaitingDisclosure) advanceR19First(owner)
    }

    private fun scheduleR19Join() {
        if (!r19JoinPosted.compareAndSet(false, true)) return
        if (!mainHandler.post {
                r19JoinPosted.set(false)
                r18Active?.let(::advanceR19First)
            }) r19JoinPosted.set(false)
    }

    private fun recordOpeningWait(owner: R18Active, proof: Long?, reason: String) {
        if (owner.lastR22WaitReason == reason) return
        owner.lastR22WaitReason = reason
        val context = owner.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R22_ACQUISITION")) return
        runCatching { traceKeyguard("R22_ACQUISITION", "WAIT", requestId = proof, diagnosticContext = context,
            deferredFields = { mapOf("r22Reservation" to owner.token.id,
                "r22Wait" to reason, "r22WaitRequest" to (proof ?: "UNOBSERVED")) }) }
    }

    /** Join a complete physical MAIN proof with this exact hidden virgin
     * output. Neither output creation, binding nor worker completion can
     * independently grant display or financial demand. */
    private fun advanceR19First(owner: R18Active) {
        if (r18Active !== owner || overlay.isAttached || !owner.preparation.emptyAwaitingDisclosure) return
        val token = owner.token
        val proof = owner.firstProof
        if (proof == null || !firstAuthorizedOrb.isCurrent(proof)) {
            recordOpeningWait(owner, proof?.requestId, if (proof == null) "NO_CURRENT_PROOF" else "PROOF_EXPIRED")
            if (proof != null && owner.lastExpiredProof != proof.requestId) {
                owner.lastExpiredProof = proof.requestId
                recordR18(owner, "R19_PROOF_EXPIRED", proof = proof.requestId,
                    r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
            }
            // The original/reserved reader or its genuine successor owns the
            // next decision. A missing worker is reconciled once per scene.
            val needsRead = synchronized(queueLock) {
                val scene = firstAuthorizedOrb.sceneSerial()
                if (inspectionQueue.hasCurrentWork(inspectionAuthority) || owner.lastReconciledScene == scene ||
                    retryToken != null || retryCount >= RETRY_DELAYS_MS.size) false
                else { owner.lastReconciledScene = scene; true }
            }
            if (needsRead) {
                retryCount += 1
                requestSystemCheck("r19Reconcile", evaluate = true)
            }
            return
        }
        val stamp = token.stamp
        val prep = owner.preparation
        val settings = lastSettings ?: return
        val profile = lastMaterialProfile ?: return
        val stable = synchronized(queueLock) {
            val active = inspectionQueue.activeRequest()
            val pending = inspectionQueue.pendingRequest()
            val newer = listOfNotNull(active, pending).any { inspectionAuthority.matches(it) && it.id > proof.requestId }
            firstAuthorizedOrb.isCurrent(proof) && !newer && inspectionAuthority == proof.authority &&
                inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) &&
                r18RouteRevision == proof.selectionRevision
        }
        if (!stable || proof.hostGeneration != stamp.hostGeneration || proof.outputGeneration != prep.outputGeneration ||
            proof.materialRevision != profile.publisherRevision || proof.dataRevision != settings.focus.generation ||
            prep.visualKey != profile.visualKey || overlay.r18Preparation() != prep || !settings.showFinancialDetails) {
            recordOpeningWait(owner, proof.requestId, "PROOF_OR_REVISION_CHANGED")
            return
        }
        if (owner.output == null) { recordOpeningWait(owner, proof.requestId, "OUTPUT_NOT_READY"); return }
        if (owner.paintRequested && (!owner.bound || overlay.r18PreparedOutput(prep) !== owner.output ||
                !overlay.isR18Bound(stamp.hostGeneration, prep))) {
            recordOpeningWait(owner, proof.requestId, "HIDDEN_BIND_NOT_READY")
            return
        }
        // A fresh real system sample is needed for painting as well as at the
        // final presentation boundary. The scene itself is the retained proof.
        val system = readSystemState(KeyguardSystemReadPurpose.ADMISSION)
        if (KeyguardCardVisibilityPolicy.decide(signalsFromSystemState(settings, KeyguardSurface.MAIN_KEYGUARD, system)) !=
            KeyguardCardVisibility.SHOW_FULL) {
            recordOpeningWait(owner, proof.requestId, "SYSTEM_INELIGIBLE")
            invalidateR19Scene("SYSTEM")
            scheduleR19Join()
            return
        }
        val stillCurrent = synchronized(queueLock) {
            firstAuthorizedOrb.isCurrent(proof) && inspectionAuthority == proof.authority &&
                inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) &&
                r18RouteRevision == proof.selectionRevision &&
                listOfNotNull(inspectionQueue.activeRequest(), inspectionQueue.pendingRequest())
                    .none { inspectionAuthority.matches(it) && it.id > proof.requestId }
        }
        if (!stillCurrent) return
        if (!owner.paintRequested) {
            // Claim one immutable write ticket under the same scalar lock as
            // ingress and read obligations. No Android call occurs inside it.
            val ticket = synchronized(queueLock) {
                if (!firstAuthorizedOrb.isCurrent(proof) || inspectionAuthority != proof.authority ||
                    !inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) ||
                    r18RouteRevision != proof.selectionRevision ||
                    listOfNotNull(inspectionQueue.activeRequest(), inspectionQueue.pendingRequest())
                        .any { inspectionAuthority.matches(it) && it.id > proof.requestId }) null
                else {
                    owner.paintRequested = true
                    r32MainSnapshot = null
                    openingHandoff.invalidate()
                    KeyguardR19FirstPaintTicket(prep.attachment, prep.outputGeneration,
                        proof.requestId, proof.sceneSerial, proof.dataRevision, prep.visualKey)
                }
            } ?: return
            recordR18(owner, "R19_PAINT_REQUEST", proof = proof.requestId)
            if (!overlay.authorizeR19First(prep, ticket)) { failR18Stage(owner, "firstPaintRejected"); return }
        }
        if (!owner.bound || owner.output == null || overlay.r18PreparedOutput(prep) !== owner.output ||
            !overlay.isR18Bound(stamp.hostGeneration, prep)) {
            recordOpeningWait(owner, proof.requestId, "HIDDEN_BIND_NOT_READY")
            return
        }
        val consume = synchronized(queueLock) {
            val active = inspectionQueue.activeRequest()
            val pending = inspectionQueue.pendingRequest()
            val newer = listOfNotNull(active, pending).any { inspectionAuthority.matches(it) && it.id > proof.requestId }
            !newer && inspectionAuthority == proof.authority &&
                inspectionFreshness.isEstablished(inspectionAuthority, proof.freshnessRevision) &&
                r18RouteRevision == proof.selectionRevision &&
                firstAuthorizedOrb.isCurrent(proof) && firstAuthorizedOrb.consume(proof)
        }
        if (!consume) return
        recordR18(owner, "R19_PROOF_CONSUMED", proof = proof.requestId,
            r19ReadScene = proof.sceneSerial, r19Freshness = proof.freshnessRevision)
        r18ProofRequestId = proof.requestId
        try {
            appliedDecision = KeyguardCardVisibility.SHOW_FULL
            retryCount = 0
            cancelWakeRetry("shown")
            wakeTiming?.takeIf { it.wakeGeneration == proof.authority.wakeGeneration }?.mainKeyguardConfirmedAt =
                SystemClock.uptimeMillis()
            showFullContent(proof.authority.serviceSession, proof.authority.visibilityEpoch,
                proof.dataRevision, "r19Continuation", owner.diagnosticContext, proof.requestId)
        } finally {
            if (r18ProofRequestId == proof.requestId) r18ProofRequestId = null
        }
    }

    private fun onR18Failure(attachment: Long, generation: Long, reason: String) {
        val owner = r18Active
        if (owner == null) {
            synchronized(queueLock) {
                r18RouteEnabled = false
                r18RouteSnapshot = null
                r18RouteRevision += 1L
                cancelR18ReservationLocked()
            }
            return
        }
        if (owner.preparation.attachment == attachment && owner.preparation.outputGeneration == generation)
            failR18Stage(owner, reason)
    }

    private fun onR18Drained(attachment: Long, generation: Long, output: Any) {
        mainHandler.post {
            if (r18Active == null && r18FallbackWake == wakeEpoch && FluviKeyguardCardServiceRegistry.connected)
                requestSystemCheck("r18DrainReady", evaluate = true,
                    sampleOrigin = R447SystemOrigin.INTERNAL_OUTPUT_READY)
        }
        val binding = synchronized(queueLock) {
            val index = r18DrainBindings.indexOfFirst {
                it?.attachment == attachment && it.generation == generation && it.output === output
            }
            if (index < 0) null else r18DrainBindings[index]?.takeIf { !it.drained }?.also {
                it.drained = true
                r18Coordinator.outputDrained(it.token, output)
            }
        } ?: return
        val context = binding.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "OUTPUT_DRAINED",
            serviceSession = binding.token.stamp.authority.serviceSession,
            wakeEpoch = binding.token.stamp.authority.wakeGeneration,
            requestId = binding.token.stamp.firstRequestId, attachGeneration = attachment,
            diagnosticContext = context, deferredFields = { mapOf("r18Host" to binding.token.stamp.hostGeneration,
                "r18Output" to generation, "r18ReservationId" to binding.token.id, "r18Phase" to "OUTPUT_DRAINED") })
    }

    /** Worker-only scalar observation; capture association belongs to the
     * original exact output, even after replacement or withdrawal. */
    private fun onR19Observation(observation: KeyguardOrbSurfaceObservation) {
        if (observation.stage != "R19_PAINT_ENTER" && observation.stage != "POSTER" &&
            observation.stage != "R20_FIRST_FRAME") return
        val binding = synchronized(queueLock) { r18DrainBindings.firstOrNull {
            it?.attachment == observation.attachment && it.generation == observation.generation
        } } ?: return
        val context = binding.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        val phase = if (observation.stage == "POSTER") "R19_POSTER" else observation.stage
        val first = observation.firstFrame
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", phase,
            serviceSession = binding.token.stamp.authority.serviceSession,
            wakeEpoch = binding.token.stamp.authority.wakeGeneration,
            requestId = first?.requestId ?: binding.token.stamp.firstRequestId, attachGeneration = observation.attachment,
            observedUptimeMs = observation.observedAtUptimeMs, diagnosticContext = context,
            surfaceMetrics = observation.metrics, deferredFields = {
                fun ns(value: Long?) = value?.takeIf { it > 0 } ?: "UNOBSERVED"
                mapOf("r18Host" to binding.token.stamp.hostGeneration, "r18Output" to observation.generation,
                    "r18ReservationId" to binding.token.id, "r19Poster" to if (observation.stage == "POSTER") observation.detail else "UNOBSERVED",
                    "r34AssetGeneration" to (observation.r34AssetGeneration ?: "UNOBSERVED"),
                    "r34PrepareStart" to (observation.r34PrepareStartUptimeMs ?: "UNOBSERVED"),
                    "r34Ready" to (observation.r34ReadyUptimeMs ?: "UNOBSERVED"),
                    "r20Method" to (first?.method ?: "UNOBSERVED"), "r20EntryNs" to ns(first?.entryNs),
                    "r20PainterStartNs" to ns(first?.painterStartNs), "r20PainterEndNs" to ns(first?.painterEndNs),
                    "r20ConfigureEndNs" to ns(first?.configureEndNs), "r20LockBeginNs" to ns(first?.lockBeginNs),
                    "r20LockReturnNs" to ns(first?.lockReturnNs), "r20DrawEndNs" to ns(first?.drawEndNs),
                    "r20PostReturnNs" to ns(first?.postReturnNs), "r20Failure" to (first?.failure ?: "UNOBSERVED"),
                    "r27WarmStatus" to (first?.warmStatus ?: "UNOBSERVED"),
                    "r27WarmSelector" to (first?.warmSelector ?: "UNOBSERVED"),
                    "r27WarmLoadNs" to ns(first?.warmLoadNs), "r27WarmQueueNs" to ns(first?.warmQueueNs),
                    "r27WarmConstructorNs" to ns(first?.warmConstructorNs),
                    "r27WarmOverlap" to (first?.warmOverlap ?: "UNOBSERVED"))
            })
    }

    private fun onR18Receipt(attachment: Long, generation: Long,
                             receipt: com.fluvi.app.lockscreen.material.KeyguardOrbPresentationLane.Receipt) {
        val binding = synchronized(queueLock) { r18DrainBindings.firstOrNull {
            it?.attachment == attachment && it.generation == generation
        } } ?: return
        val context = binding.diagnosticContext ?: return
        if (context.captureId == null || !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "${receipt.operation}_RECEIPT",
            serviceSession = binding.token.stamp.authority.serviceSession,
            wakeEpoch = binding.token.stamp.authority.wakeGeneration,
            requestId = binding.token.stamp.firstRequestId, attachGeneration = attachment,
            observedUptimeMs = receipt.committedUptimeMs ?: receipt.applyReturnUptimeMs ?: receipt.submitStartUptimeMs,
            diagnosticContext = context, deferredFields = { mapOf(
                "r18Host" to binding.token.stamp.hostGeneration, "r18Output" to generation,
                "r18ReservationId" to binding.token.id, "r18Phase" to receipt.operation, "r18ApplyBegin" to receipt.submitStartUptimeMs,
                "r18ApplyEnd" to (receipt.applyReturnUptimeMs ?: "UNOBSERVED"),
                "r18Commit" to (receipt.committedUptimeMs ?: "UNOBSERVED"),
                "r18LatchNs" to (receipt.latchNanos ?: "UNOBSERVED"),
                "r18PresentNs" to (receipt.presentSignalNanos ?: "UNOBSERVED"),
                "r18PresentState" to receipt.presentState,
            ) })
    }

    /** The positive being applied is the only place a missing full scene may
     * be requested. If it or the host is delayed, a later independent read
     * must supply another complete MAIN and fresh final system proof. */
    private fun prepareR18Decision(owner: R18Active, request: KeyguardCardInspectionRequest,
                                   inspection: Inspection, decision: KeyguardCardVisibility,
                                   settings: KeyguardCardSettings, readSceneSerial: Long?,
                                   readStartedAt: Long, readFinishedAt: Long): Boolean {
        val token = owner.token
        val stamp = token.stamp
        val profile = lastMaterialProfile ?: run { failR18Stage(owner, "profileMissing"); return false }
        val revisionCurrent = synchronized(queueLock) { r18RouteRevision == stamp.selectionRevision }
        if (!revisionCurrent || inspectionAuthority != stamp.authority ||
            profile.publisherRevision != stamp.materialRevision || settings.focus.generation != stamp.dataRevision ||
            inspection.surfaceReason != KeyguardSurfaceReason.MAIN_CONFIRMED || inspection.rootUnavailable ||
            inspection.walkTruncated || inspection.abortedStale) {
            failR18Stage(owner, "positiveOrRevisionChanged"); return false
        }
        val full = decision == KeyguardCardVisibility.SHOW_FULL
        if (owner.preparation.full != full) {
            val next = overlay.prepareR18(full = full, authorizedFull = full) { prep ->
                val nextStamp = stamp.copy(firstRequestId = request.id, full = full,
                    outputGeneration = prep.outputGeneration)
                val replacement = r18Coordinator.replaceUnshown(token, nextStamp) ?: return@prepareR18 false
                owner.identity = R18Identity(replacement.reservation, prep)
                owner.output = null
                owner.binding = false
                owner.bound = false
                true
            }
            if (next == null) failR18Stage(owner, "disclosurePreparationFailed")
            else recordR18(owner, if (full) "PREPARE_FULL" else "PREPARE_DISCREET")
            return false
        }
        if (owner.preparation.emptyAwaitingDisclosure && full) {
            val revision = inspection.freshnessRevision
            val scene = readSceneSerial
            recordR18(owner, "R19_FIRST_POSITIVE", readFinishedAt, proof = request.id,
                r19ReadScene = scene, r19Freshness = revision, r19ReadStart = readStartedAt,
                r19Inspection = inspection)
            val proofResult = synchronized(queueLock) {
                val proof = if (scene != null && revision != null) firstAuthorizedOrb.offer(
                    request.id, inspectionAuthority, scene, revision, stamp.hostGeneration,
                    owner.preparation.outputGeneration, stamp.selectionRevision, stamp.materialRevision,
                    stamp.dataRevision, full = true, completeMain = true, freshSystemEligible = true) else null
                if (proof != null) {
                    owner.firstProof = proof
                    r32MainSnapshot = null
                }
                proof to if (proof == null) firstAuthorizedOrb.offerRejection(request.id, scene, revision,
                    stamp.hostGeneration, owner.preparation.outputGeneration) else null
            }
            val proof = proofResult.first
            if (proof == null) {
                if (request.diagnosticContext?.captureId != null) runCatching {
                    traceKeyguard("R22_ACQUISITION", "PROOF_REJECTED", request,
                        deferredFields = { mapOf("r22Reservation" to owner.token.id,
                            "r22Positive" to request.id, "r22Reject" to (proofResult.second ?: "UNOBSERVED")) })
                }
                recordR18(owner, "R19_PROOF_EXPIRED", proof = request.id)
                scheduleR19Join()
            } else {
                if (request.diagnosticContext?.captureId != null) runCatching {
                    traceKeyguard("R22_ACQUISITION", "PROOF_ACCEPTED", request,
                        deferredFields = { mapOf("r22Reservation" to owner.token.id,
                            "r22Positive" to request.id, "r22Reject" to "ACCEPTED") })
                }
                recordR18(owner, "R19_PROOF_ACCEPTED", proof = request.id)
                maybeBindR18(owner)
                advanceR19First(owner)
            }
            return false // continuation has its own one-shot Main join
        }
        val expectedVisual = if (full) profile.visualKey else profile.neutralized().visualKey
        if (owner.preparation.visualKey != expectedVisual || overlay.r18Preparation() != owner.preparation) {
            failR18Stage(owner, "visualIdentityChanged"); return false
        }
        if (!owner.bound || !overlay.isR18Bound(stamp.hostGeneration, owner.preparation) ||
            overlay.r18PreparedOutput(owner.preparation) !== owner.output || owner.output == null) {
            maybeBindR18(owner)
            recordR18(owner, "WAITING_INPUTS")
            return false
        }
        return true
    }

    /** Same-wake recovery owns a fresh host/output and must re-read after
     * asynchronous readiness; the old visible grant is never revived. */
    private fun tryStartR18Readmission(request: KeyguardCardInspectionRequest,
                                       inspection: Inspection, settings: KeyguardCardSettings): Boolean {
        if (!localPresentationAllowed() || r18Active != null || overlay.isAttached || r18FallbackWake == wakeEpoch ||
            inspection.surfaceReason != KeyguardSurfaceReason.MAIN_CONFIRMED || inspection.rootUnavailable ||
            inspection.walkTruncated || inspection.abortedStale) return false
        val previous = r18Coordinator.snapshot()
        if (previous.grant != KeyguardOrbPresentationCoordinator.Grant.RETIRED ||
            previous.reservation?.stamp?.authority?.wakeGeneration != wakeEpoch) return false
        // Same-wake readmission retains the earlier discreet/reinspection
        // contract; the new virgin continuation is initial-admission only.
        overlay.prepareR18(full = false)
        refreshR18RouteOnMain()
        val reserved = synchronized(queueLock) {
            val route = r18RouteSnapshot ?: return@synchronized null
            val prep = route.preparation
            val stamp = KeyguardOrbPresentationStamp(inspectionAuthority, request.id, r18RouteRevision,
                route.materialRevision, route.dataRevision, prep.width, prep.height, prep.densityDpi, prep.full,
                ++r18NextHostGeneration, prep.outputGeneration, Display.DEFAULT_DISPLAY)
            val token = r18Coordinator.reserveReadmission(stamp, request.id, inspectionAuthority,
                sampleEligible = true, routeEligible = r18RouteEnabled) ?: return@synchronized null
            token to prep
        } ?: return false
        startR18Stage(reserved.first, reserved.second, settings, request.diagnosticContext)
        return true
    }

    private fun failR18Stage(owner: R18Active, reason: String) {
        if (r18Active !== owner) return
        r18FallbackWake = wakeEpoch
        owner.r21Binding?.let { binding -> runCatching {
            recordR21(binding, "FALLBACK", SystemClock.uptimeMillis(), r18Coordinator.revealOrdinal(binding.reveal),
                "UNOBSERVED", reason)
        } }
        recordR18(owner, "FALLBACK:$reason")
        hideImmediately("r18Fallback:$reason", terminalWake = false,
            diagnosticContext = owner.diagnosticContext, causingInspectionRequestId = owner.token.stamp.firstRequestId)
        // A failed exact host removal is not permission to create another
        // window or an automatic retry loop. A later real event can retry.
        if (r18Active === owner) { recordR18(owner, "FALLBACK_BLOCKED_HOST"); return }
        requestSystemCheck("r18Fallback", evaluate = true, freshness = KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE)
    }

    /** Pure authority transition first; native hide is queued immediately and
     * never waits for the Main reconciliation or a borrower. */
    private fun sealR18(authority: KeyguardInspectionAuthority, requestId: Long, reason: String,
                        systemRequest: KeyguardSystemGateRequest? = null,
                        systemState: KeyguardSystemState? = null): R18Active? {
        val owner = r18Active ?: return null
        val identity = owner.identity
        val token = identity.token
        val sealed = synchronized(queueLock) {
            val accepted = r18Coordinator.seal(token, authority, requestId, true) != null
            if (accepted) {
                openingHandoff.invalidate()
                if (r40RemovalGate.hasWitness) r40RemovalGate.clearFor(token)
            }
            accepted
        }
        if (!sealed) return null
        firstAuthorizedOrb.invalidate()
        finishR18Seal(owner, identity, reason, requestId, SystemClock.uptimeMillis(), systemRequest, systemState)
        return owner
    }

    /** The exact reservation was sealed under queueLock; use only its captured
     * attachment/output after leaving the lock. */
    private fun finishR18Seal(owner: R18Active, identity: R18Identity, reason: String, requestId: Long,
                              sealedAt: Long, systemRequest: KeyguardSystemGateRequest? = null,
                              systemState: KeyguardSystemState? = null) {
        val token = identity.token
        val r41SealNs = if (owner.diagnosticContext?.captureId != null &&
            owner.diagnosticContext.captureId == KeyguardCardDiagnostics.activeCaptureId()) System.nanoTime() else Long.MIN_VALUE
        overlay.sealR18FromAnyThread(identity.preparation.attachment, identity.preparation.outputGeneration)
        if (r41SealNs != Long.MIN_VALUE) {
            val binding = owner.r21Binding?.takeIf { it.token === token }
            val proof = binding?.r41ProofId ?: owner.r41GrantRequest
            if (proof > 0) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.CANCEL,
                binding?.context ?: owner.diagnosticContext, proof, atNs = r41SealNs)
        }
        owner.r21Binding?.takeIf { it.token === token }?.let { binding -> runCatching {
            recordR21(binding, "SEAL", sealedAt, r18Coordinator.revealOrdinal(binding.reveal), "CANCELLED", reason, offered = requestId.takeUnless { it == Long.MAX_VALUE })
        } }
        recordR18(owner, "SEALED:$reason", observedAt = sealedAt, exactIdentity = identity)
        // The original sampler request and successful sealed generation are
        // captured here, not recovered later from a newer service operation.
        val context = owner.diagnosticContext
        if (reason == "systemSample" && systemRequest != null && systemState != null &&
            context?.captureId != null && context.captureId == systemRequest.diagnosticCaptureId &&
            context.captureId == KeyguardCardDiagnostics.activeCaptureId() &&
            KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) {
            val prep = identity.preparation
            runCatching { KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "R26_SYSTEM_SEAL",
                serviceSession = token.stamp.authority.serviceSession, wakeEpoch = token.stamp.authority.wakeGeneration,
                requestId = token.stamp.firstRequestId, attachGeneration = prep.attachment,
                observedUptimeMs = sealedAt, diagnosticContext = context,
                deferredFields = { mapOf("r18Host" to token.stamp.hostGeneration,
                    "r18Output" to prep.outputGeneration, "r18ReservationId" to token.id,
                    "r26SystemRequest" to systemRequest.id, "r26SystemReason" to systemRequest.reason,
                    "r26SystemReceived" to systemRequest.receivedAt,
                    "r26SystemStart" to systemState.startedAt, "r26SystemEnd" to systemState.finishedAt) }) }
        }
    }

    /** Capture-qualified, bounded producer for the existing diagnostic worker.
     * Nothing is formatted or recorded during first admission or the ACK. */
    private fun recordR40(owner: R18Active, identity: R18Identity, phase: String, at: Long,
                          requestId: Long?, windowId: Int?) {
        val context = owner.diagnosticContext ?: return
        if (context.captureId == null || context.captureId != KeyguardCardDiagnostics.activeCaptureId() ||
            !KeyguardCardDiagnostics.wantsEvent("R18_PIPELINE")) return
        val stamp = identity.token.stamp
        runCatching {
            KeyguardCardDiagnostics.captureEvent(this, "R18_PIPELINE", "R40_$phase",
                serviceSession = stamp.authority.serviceSession, wakeEpoch = stamp.authority.wakeGeneration,
                requestId = requestId ?: stamp.firstRequestId,
                attachGeneration = identity.preparation.attachment, observedUptimeMs = at,
                diagnosticContext = context, deferredFields = { mapOf(
                    "r18Host" to stamp.hostGeneration, "r18Output" to identity.preparation.outputGeneration,
                    "r18ReservationId" to identity.token.id, "r18Privacy" to if (stamp.full) "full" else "discreet",
                    "r40Window" to (windowId ?: "UNOBSERVED"), "r40Request" to (requestId ?: "UNOBSERVED"),
                ) })
        }
    }

    private fun finishR18AfterWindow(owner: R18Active?) {
        if (owner == null || r18Active !== owner) return
        val token = owner.token
        if (overlay.hasR18Host(token.stamp.hostGeneration)) return
        owner.host?.let { r18Coordinator.hostRemoved(token, it) }
        if (r18Coordinator.retired(token)) r18Active = null
    }

    private fun r18ActionAllowed(): Boolean {
        val owner = r18Active ?: return true
        val host = owner.host ?: return false
        return r18Coordinator.mayAct(owner.token, host)
    }

    private fun recordMaximum(counter: AtomicInteger, value: Int) {
        var observed = counter.get()
        while (value > observed && !counter.compareAndSet(observed, value)) observed = counter.get()
    }

    /** Numeric, bounded attachment-gap evidence, never a visibility input.
     * These nested scopes are retained separately and must not be summed.
     * nanoTime matches the renderer/Choreographer observation clock; CPU is
     * this thread's whole-scope CPU, not a claim about Binder or GPU work. */
    private inline fun <T> withMainWorkEvidence(kind: Int, requestId: Long = 0L, operation: () -> T): T {
        if (Looper.myLooper() != Looper.getMainLooper() || !KeyguardCardDiagnostics.wantsEvent("MAIN_WORK")) {
            return operation()
        }
        val startedNs = System.nanoTime()
        val startedCpuNs = android.os.Debug.threadCpuTimeNanos()
        try {
            return operation()
        } finally {
            val endedNs = System.nanoTime()
            val cpuNs = keyguardThreadCpuDelta(startedCpuNs, android.os.Debug.threadCpuTimeNanos())
            mainWorkEvidence.record(kind, requestId, startedNs, endedNs, cpuNs)
        }
    }

    /** An authority change may make an external surface request stale.  Keep
     * exactly one current reconciliation behind the active Binder call rather
     * than relabelling that old result as current.  Terminal exclusions call
     * clearPending instead and never reach this path. */
    private fun preservePendingReconciliation(
        reason: String,
        requirePending: Boolean,
        freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
    ) {
        if (!FluviKeyguardCardServiceRegistry.connected || !::overlay.isInitialized) return
        val needsReconciliation = synchronized(queueLock) {
            if (requirePending) inspectionQueue.pendingRequest() != null
            else inspectionQueue.activeRequest() != null || inspectionQueue.pendingRequest() != null
        }
        if (!needsReconciliation || wakeCycleOwner.current() == null || lastSettings?.requested != true) return
        freshReconciliationsScheduled.incrementAndGet()
        scheduleEvaluation(
            "authorityReconcile:$reason",
            triggerReceivedUptimeMs = SystemClock.uptimeMillis(),
            freshness = freshness,
        )
    }

    /** Capture instrumentation is intentionally observational: callers pass
     * their already-known identifiers and it never requests a new inspection,
     * material profile, content resolve, or window operation. */
    private fun traceKeyguard(
        stage: String,
        reason: String,
        request: KeyguardCardInspectionRequest? = null,
        requestId: Long? = null,
        attachGeneration: Long? = null,
        observedUptimeMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = null,
        operation: KeyguardDiagnosticOperation? = null,
        fields: Map<String, Any?> = emptyMap(),
        deferredFields: (() -> Map<String, Any?>)? = null,
        surfaceMetrics: com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics? = null,
    ) {
        if (!KeyguardCardDiagnostics.wantsEvent(stage)) return
        withMainWorkEvidence(
            KeyguardMainWorkEvidence.DIAGNOSTIC_PRODUCER,
            request?.id ?: requestId ?: operation?.causingInspectionRequestId ?: 0L,
        ) {
            val capturedContext = operation?.context ?: diagnosticContext ?: request?.diagnosticContext ?: currentDiagnosticAttempt
            KeyguardCardDiagnostics.captureEvent(
                context = this,
                stage = stage,
                reason = reason,
                serviceSession = request?.session ?: session.get(),
                wakeEpoch = request?.wakeGeneration ?: wakeEpoch,
                requestId = request?.id ?: requestId ?: operation?.causingInspectionRequestId,
                attachGeneration = attachGeneration,
                observedUptimeMs = observedUptimeMs,
                diagnosticContext = capturedContext,
                operation = operation,
                fields = fields,
                deferredFields = deferredFields,
                surfaceMetrics = surfaceMetrics,
            )
        }
    }

    /** Technical, capture-qualified recovery evidence. Formatting happens on
     * the diagnostic consumer; no display or acquisition work is triggered. */
    private fun recordR14Recovery(
        action: String, recovery: KeyguardR14Recovery, request: KeyguardCardInspectionRequest? = null,
        pending: KeyguardCardInspectionRequest? = null, displaced: Long? = null,
        observedAt: Long? = null, readStart: Long? = null, readEnd: Long? = null,
        requestId: Long? = null, showOperation: Long? = null,
    ) {
        if (!KeyguardCardDiagnostics.wantsEvent("R14_RECOVERY")) return
        val context = if (request != null) request.diagnosticContext else currentDiagnosticAttempt
        if (context?.captureId == null || context != recovery.diagnosticContext) return
        val origin = pending?.r14Ingress
        traceKeyguard("R14_RECOVERY", action, request = request, requestId = requestId,
            observedUptimeMs = observedAt, diagnosticContext = context,
            deferredFields = { mapOf(
                "r14Recovery" to recovery.id,
                "r14PreviousHide" to (recovery.hideOperationId ?: "UNOBSERVED"),
                "r14PreviousAttach" to recovery.previousAttachment,
                "r14Authority" to "${recovery.authority.serviceSession}/${recovery.authority.wakeGeneration}/${recovery.authority.visibilityEpoch}/${recovery.authority.interactionEpoch}/${recovery.authority.attachGeneration}",
                "r14DeferredA" to (recovery.deferredRequestId ?: "UNOBSERVED"),
                "r14Current" to (request?.id ?: requestId ?: "UNOBSERVED"),
                "r14OriginalB" to (recovery.pendingRequestId ?: "UNOBSERVED"),
                "r14Pending" to (pending?.id ?: "UNOBSERVED"),
                "r14Displaced" to (displaced ?: "UNOBSERVED"),
                "r14Ingress" to (origin?.id ?: "UNOBSERVED"),
                "r14Origin" to when (origin?.origin) {
                    KeyguardR14Origin.SYSTEM_UI -> "systemUi"
                    KeyguardR14Origin.OWN -> "own"
                    KeyguardR14Origin.AMBIGUOUS -> "ambiguous"
                    KeyguardR14Origin.OTHER -> "other"
                    null -> "syntheticOrUnavailable"
                },
                "r14Window" to (origin?.windowId ?: "UNOBSERVED"),
                "r14Display" to (origin?.displayId ?: "UNOBSERVED"),
                "r14Event" to (origin?.eventAt ?: "UNOBSERVED"),
                "r14Callback" to (origin?.callbackAt ?: "UNOBSERVED"),
                "r14ReadStart" to (readStart ?: "UNOBSERVED"),
                "r14ReadEnd" to (readEnd ?: "UNOBSERVED"),
                "r14Show" to (showOperation ?: "UNOBSERVED"),
                "r14ReplacementOmitted" to (recovery.replacements - 4).coerceAtLeast(0),
                "r14Physical" to "UNOBSERVED",
            ) })
    }

    private fun clearR14Recovery(reason: String) {
        val previous = r14Recovery ?: return
        recordR14Recovery("END_$reason", previous)
        r14Recovery = null
    }

    private data class WakeTiming(
        val wakeGeneration: Long,
        val wakeReceivedAt: Long,
        val rootWasPrepared: Boolean,
        val profileWasDecoded: Boolean,
        val presentationMode: String,
        val eligibility: KeyguardWakeEligibilityEvidence? = null,
        var inspectionQueuedAt: Long? = null,
        var inspectionStartedAt: Long? = null,
        var inspectionFinishedAt: Long? = null,
        var mainKeyguardConfirmedAt: Long? = null,
        var attachRequestedAt: Long? = null,
        var addViewReturnedAt: Long? = null,
        val draws: KeyguardDrawPublication = KeyguardDrawPublication(),
        var retryCount: Int = 0,
        var rejectedLateResults: Int = 0,
        var eventAgeMs: Long? = null,
    )

    private data class RetiredSurfaceEvidence(
        val attachment: Long, val generation: Long,
        val metrics: com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics,
        val atRevoke: com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics.HolderOperation,
    )

    /** A retry is tied to the exact hidden result which requested it. The
     * follow-up gets fresh inspection authority only if that wake/visibility
     * state still exists when its short backoff expires. */
    private data class RetryToken(
        val retryId: Long,
        val retryIndex: Int,
        val requestId: Long,
        val session: Long,
        val visibilityEpoch: Long,
        val interactionEpoch: Long,
        val attachGeneration: Long,
        val wakeGeneration: Long,
        val scheduledAtUptimeMs: Long,
        val dueAtUptimeMs: Long,
        val windowFreshness: KeyguardWindowFreshness,
        val diagnosticContext: KeyguardDiagnosticContext?,
    )

    private var wakeTiming: WakeTiming? = null
    /** The service state that owned the currently attached root's first-draw
     * diagnostics. Deferred draw work must match this original identity, not
     * merely whichever wake happens to be current when it returns. */
    private var firstDrawOwner: KeyguardFirstDrawOwner? = null

    private val displayManager by lazy { getSystemService(DisplayManager::class.java) }

    private val screenReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context, intent: Intent) {
            val r41Capture = KeyguardCardDiagnostics.activeCaptureId()
            val r41AtNs = if (r41Capture != null) System.nanoTime() else Long.MIN_VALUE
            val receivedAt = SystemClock.uptimeMillis()
            val r41Ordinal = if (intent.action == Intent.ACTION_SCREEN_ON)
                KeyguardCardDiagnostics.r41Provisional(r41Capture, 1, session.get(), receivedAt, r41AtNs) else 0L
            when (intent.action) {
                Intent.ACTION_SCREEN_OFF -> {
                    if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE && r45Wa.screenOff()) {
                        r446ReadArm = null
                    } else if (r446Owner.state == KeyguardR446PrintOwner.State.WAIT_OFF) {
                        r446Owner.screenOff()
                        r446ReadArm = null
                    } else if (r446HasBackend()) r446Cancel("screenOff")
                    r442ScreenOn = null
                    val owner = currentDiagnosticAttempt
                    hideImmediately("screenOff", triggerReceivedUptimeMs = receivedAt)
                    if (r449Session != null) r449PrepareSessionWake()
                    if (owner != null) traceKeyguard("SCREEN_OFF_RECEIVED", "broadcast", observedUptimeMs = receivedAt,
                        diagnosticContext = owner, fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true))
                }
                Intent.ACTION_USER_PRESENT -> {
                    if (r446HasBackend()) r446Cancel("userPresent")
                    r442ScreenOn = null
                    if (Build.VERSION.SDK_INT == 37 && r442Lookup.status in setOf("PENDING_UNLOCK", "PENDING", "UNAVAILABLE"))
                        prepareR442ResourceLookup()
                    val owner = currentDiagnosticAttempt
                    hideImmediately("userPresent", triggerReceivedUptimeMs = receivedAt)
                    if (::overlay.isInitialized && !overlay.isAttached && lastSettings?.requested == true) {
                        overlay.prepareR18()
                        refreshR18RouteOnMain()
                    }
                    if (r449Session != null) r449PrepareSessionWake()
                    if (owner != null) traceKeyguard("USER_PRESENT_RECEIVED", "broadcast", observedUptimeMs = receivedAt,
                        diagnosticContext = owner, fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true))
                }
                Intent.ACTION_SCREEN_ON -> {
                    r442ScreenOn = R442ScreenOn(session.get(), receivedAt)
                    scheduleR43Holds(receivedAt)
                    if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
                        r45Wa.screenOn(session.get(), KeyguardCardDiagnostics.activeCaptureId())
                    else if (r446Owner.wake(session.get(), KeyguardCardDiagnostics.activeCaptureId()))
                        r446ReadArm = r446Owner.arm
                    beginOrJoinWakeCycle("wake", receivedAt, r41CaptureId = r41Capture, r41Ordinal = r41Ordinal)
                    r447RecordWakeArm()
                    // An already running pre-screen walk cannot carry the
                    // one-wake arm. Offer one successor on the same reader;
                    // the queue rechecks for suitable work before accepting it.
                    val boundaryArm = r446ReadArm
                    if (boundaryArm != null && wakeCycleOwner.current() != null) {
                        r448RecordBoundary(boundaryArm, receivedAt)
                        scheduleEvaluation("r448ScreenBoundary", triggerReceivedUptimeMs = receivedAt,
                            freshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY)
                    }
                    r45TryBeginWaWake()
                }
            }
        }
    }

    private data class R46DisplayFacts(val state: Int, val rotation: Int, val width: Int,
                                       val height: Int, val densityDpi: Int)
    private var r46DisplayFacts: R46DisplayFacts? = null
    private fun currentR46DisplayFacts(): R46DisplayFacts? = runCatching {
        val display = displayManager?.getDisplay(Display.DEFAULT_DISPLAY) ?: return@runCatching null
        val metrics = resources.displayMetrics
        R46DisplayFacts(display.state, display.rotation, metrics.widthPixels, metrics.heightPixels, metrics.densityDpi)
    }.getOrNull()

    /** A display callback is not a grant. A proven unchanged, ON primary
     * display may retain current proof; every other non-terminal change
     * conceals first and obtains a fresh inventory. */
    private fun r46ReconcileDisplay() {
        val before = r46DisplayFacts
        val after = currentR46DisplayFacts()
        r46DisplayFacts = after
        val wake = r449Wake
        val direct = r45Direct.lease
        if (wake == null && direct == null && r446Owner.state != KeyguardR446PrintOwner.State.ISSUED) return
        if (after?.state == Display.STATE_OFF) { r446Cancel("displayOff"); return }
        val locked = runCatching { getSystemService(android.app.KeyguardManager::class.java)?.isKeyguardLocked == true }.getOrDefault(false)
        val interactive = runCatching { getSystemService(android.os.PowerManager::class.java)?.isInteractive == true }.getOrDefault(false)
        val sameOnDisplay = before != null && before == after && after.state == Display.STATE_ON && locked && interactive
        val waCurrent = wake != null && r449Current(wake, r449RestrictionRevision.get()) &&
            wake.allowedRevision == r449RestrictionRevision.get()
        val directCurrent = direct != null && r45Direct.phase == KeyguardR45Phase.VISIBLE && r45DirectCurrent(direct)
        if (sameOnDisplay && (waCurrent || directCurrent)) {
            r45RecordStage(wake?.context ?: r446Observation?.context,
                if (wake != null) "WIDGETS_ANYWHERE" else "FLUVI_STREAM", "DISPLAY_REFRESH",
                SystemClock.uptimeMillis(), detail = "unchangedOnLocked")
            return
        }
        if (wake != null) {
            r449RestrictionRevision.incrementAndGet()
            wake.allowedRevision = -1L
            val pending = wake.pendingValidation
            wake.pendingValidation = null
            r45Wa.suspend(wake.arm)
            if (r448Frame?.conceal(wake.owner, "displayRecheck") != true) {
                r446Cancel("wa:displayConcealFailed"); return
            }
            if (pending != null) runCatching { pending(false) }
            r449ScheduleRead()
        } else if (direct != null) {
            r45DirectRevision.incrementAndGet()
            r45Direct.suspend(direct)
            if (r446Presenter?.conceal(direct.token) != true) {
                r446Cancel("direct:displayConcealFailed"); return
            }
            r45ScheduleDirectRead(direct)
        } else r446Cancel("displayUnverified")
    }

    private val displayListener = object : DisplayManager.DisplayListener {
        override fun onDisplayAdded(displayId: Int) = Unit
        override fun onDisplayRemoved(displayId: Int) {
            if (displayId == Display.DEFAULT_DISPLAY && r446HasBackend()) r446Cancel("displayRemoved")
        }
        override fun onDisplayChanged(displayId: Int) {
            val r41Capture = KeyguardCardDiagnostics.activeCaptureId()
            if (displayId != Display.DEFAULT_DISPLAY && r41Capture == null) return
            val r41AtNs = if (r41Capture != null) System.nanoTime() else Long.MIN_VALUE
            val receivedAt = SystemClock.uptimeMillis()
            val r41Ordinal = KeyguardCardDiagnostics.r41Provisional(r41Capture, 2, session.get(), receivedAt, r41AtNs)
            if (displayId != Display.DEFAULT_DISPLAY) return
            r46ReconcileDisplay()
            invalidateR19Scene("DISPLAY")
            traceKeyguard("DISPLAY_EVENT", "changed", observedUptimeMs = receivedAt, fields = mapOf("displayId" to displayId))
            val cycle = beginOrJoinWakeCycle("display", receivedAt, schedule = false,
                r41CaptureId = r41Capture, r41Ordinal = r41Ordinal)
            if (cycle == null) return
            scheduleEvaluation(
                "display",
                triggerReceivedUptimeMs = receivedAt,
                freshness = if (cycle?.started == true) {
                    KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
                } else {
                    KeyguardWindowFreshness.FRAMEWORK_EVENT
                },
            )
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        if (r446HasBackend()) r446Cancel("serviceRebound")
        if (::overlay.isInitialized && overlay.isAttached) hideImmediately("r444ServiceRebound")
        stopFinancialObservation()
        invalidateFullContent()
        invalidateR442Receipt("serviceRebound")
        KeyguardR44Trial.set(false, false)
        r444ConfigurationReady = if (Build.VERSION.SDK_INT == 37) r444ProfileOwner.recover() else true
        r43EffectiveFlags = runCatching { serviceInfo?.flags }.getOrNull()
        KeyguardCardDiagnostics.activeCaptureId()?.let { id ->
            if (KeyguardCardDiagnostics.r43Enabled(id)) armR43Capture(id)
        }
        initializeReferenceOwnership()
        r448DisplayRoute = KeyguardR448DisplayRouteStore.read(applicationContext)
        r448RouteGeneration++
        session.incrementAndGet()
        mainWorkEvidence.resetSession(session.get(), android.os.Process.myTid().toLong())
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "SERVICE_CONNECTED")
        publishInspectionAuthority()
        FluviKeyguardCardServiceRegistry.connected(this)
        if (Build.VERSION.SDK_INT == 37) {
            if (!r442PackageReceiverRegistered) {
                val packageFilter = IntentFilter().apply {
                    addAction(Intent.ACTION_PACKAGE_ADDED)
                    addAction(Intent.ACTION_PACKAGE_REMOVED)
                    addAction(Intent.ACTION_PACKAGE_REPLACED)
                    addDataScheme("package")
                }
                registerReceiver(r442PackageReceiver, packageFilter, Context.RECEIVER_EXPORTED)
                r442PackageReceiverRegistered = true
            }
            prepareR442ResourceLookup()
        }
        overlay = KeyguardCardWindow(
            serviceContext = this,
            mainWorkEvidence = mainWorkEvidence,
            onOpen = { if (r18ActionAllowed()) openFocusedFluvi() },
            onToggle = { if (r18ActionAllowed()) toggleView() },
            onInteractionStarted = { if (r18ActionAllowed()) onOverlayInteractionStarted() },
            onSurfaceMotionIneligible = {
                synchronized(queueLock) { firstAcquisition.invalidate() }
                if (r18Active != null) {
                    sealR18(inspectionAuthority, Long.MAX_VALUE, "motionIneligible")
                    mainHandler.post {
                        hideImmediately("r18MotionIneligible", terminalWake = false)
                        requestSystemCheck("r18MotionIneligible", evaluate = true)
                    }
                }
            },
            onPositionCommitted = { mode, card, orb, revision ->
                if (r18ActionAllowed()) onOverlayPositionCommitted(mode, card, orb, revision)
            },
            onInteractionDiagnostic = { event, detail ->
                val attached = overlay.isAttached
                val attach = overlay.currentAttachGeneration
                mainHandler.post {
                    KeyguardCardDiagnostics.record(this, event, detail, attached)
                    traceKeyguard(event.removePrefix("KG|"), detail, attachGeneration = attach)
                }
            },
            onWindowDiagnostic = { stage, detail, attach, observedAt, fields ->
                // Window callbacks can occur immediately beside add/remove.
                // Capture-store mutation is deferred with the immutable
                // timestamp/owner so it cannot sit in front of that operation.
                val capturedOperation = activeWindowDiagnosticOperation
                val capturedFields = fields
                // A restriction record belongs only to the operation/capture
                // active at the actual Window boundary, never a later wake.
                if (stage != "R22_4_TRANSITION" || capturedOperation?.context?.captureId != null) mainHandler.post {
                    if (stage.startsWith("MATERIAL_") || stage.startsWith("BOOTSTRAP_") || stage == "ADD_VIEW_RETURN") {
                        KeyguardCardDiagnostics.recordColdPreparation(
                            session.get(),
                            if (stage == "ADD_VIEW_RETURN") "FIRST_ATTACH" else stage,
                            observedAt,
                        )
                    }
                    if (stage == "ADD_VIEW_RETURN") {
                        wakeTiming?.takeIf { it.wakeGeneration == wakeEpoch && it.addViewReturnedAt == null }
                            ?.addViewReturnedAt = observedAt
                    }
                    traceKeyguard(
                        stage,
                        detail,
                        attachGeneration = attach,
                        observedUptimeMs = observedAt,
                        operation = capturedOperation,
                        fields = capturedFields,
                    )
                }
            },
            armColdRootDiagnostic = { attach ->
                val owner = activeWindowDiagnosticOperation
                if (attach != 1L || owner?.context?.captureId == null) null
                else { stage, at, fields ->
                    mainHandler.post {
                        traceKeyguard(stage, "r10ColdRoot", observedUptimeMs = at,
                            attachGeneration = attach, operation = owner, fields = fields)
                    }
                }
            },
            armFirstOfferDiagnostic = { attach ->
                val operation = activeWindowDiagnosticOperation
                val captureOwner = KeyguardCardDiagnostics.drawEvidenceOwner()
                if (operation?.context?.captureId == null || captureOwner == null) null
                else { observation: KeyguardOrbFirstOfferObservation ->
                    // Retain the original capture and show operation. A late
                    // Worker/commit callback cannot be relabelled by a new
                    // attachment or capture, and formatting stays on reducer.
                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === captureOwner) {
                        KeyguardCardDiagnostics.captureEvent(
                            context = this,
                            stage = "R11_FIRST",
                            reason = observation.stage,
                            serviceSession = operation.context.serviceSession,
                            wakeEpoch = operation.context.originWakeEpoch,
                            attachGeneration = attach,
                            observedUptimeMs = observation.at,
                            operation = operation,
                            deferredFields = { mapOf(
                                "r11Renderer" to observation.renderer,
                                "r11Attachment" to observation.lease.attachment,
                                "r11Generation" to observation.lease.generation,
                                "r11Slot" to observation.slot,
                                "r11Use" to observation.use,
                                "r11Ready" to observation.readyAt,
                                "r11Offer" to observation.offeredAt,
                                "r11Grant" to observation.grantAt,
                                "r11Child" to observation.childId,
                                "r11GrantId" to observation.grantId,
                                "r11Origin" to observation.origin,
                                "r11Detail" to observation.detail,
                                "r11ExtraAt" to observation.extraAt,
                                "r11ShaderHit" to observation.shaderHit,
                                "r11ShaderConstructed" to observation.shaderConstructed,
                                "r11ShaderWallNs" to observation.shaderWallNs,
                                "r11ShaderCpuNs" to observation.shaderCpuNs,
                            ) },
                        )
                    }
                }
            },
            armSurfaceDiagnostic = { attach ->
                val operation = activeWindowDiagnosticOperation
                val owner = KeyguardCardDiagnostics.drawEvidenceOwner()
                if (operation?.context?.captureId == null || owner == null) null
                else { observation ->
                    if (KeyguardCardDiagnostics.drawEvidenceOwner() === owner) {
                        // This is the callback receipt, not a compositor or
                        // physical-pixel timestamp. It is linked to the exact
                        // original show operation and output generation.
                        // A non-DIRECT show can also occur without a failed
                        // R18 reservation. Record the actual receipt for its
                        // original operation; only the reducer may pair it
                        // with that operation's non-DIRECT candidate.
                        if (observation.stage == "FIRST_POST" && observation.full && observation.attachment == attach) {
                            val request = operation.causingInspectionRequestId
                            val show = operation.showOperationId
                            if (request != null && show != null) KeyguardCardDiagnostics.r41Mark(
                                KeyguardR41RawLedger.FALLBACK_POST_RECEIPT, operation.context,
                                request, show, observation.generation)
                        }
                        KeyguardCardDiagnostics.captureEvent(
                            context = this,
                            stage = "R12_SURFACE",
                            reason = observation.stage,
                            serviceSession = operation.context.serviceSession,
                            wakeEpoch = operation.context.originWakeEpoch,
                            attachGeneration = attach,
                            observedUptimeMs = observation.observedAtUptimeMs,
                            operation = operation,
                            surfaceMetrics = observation.metrics,
                            deferredFields = { mapOf(
                                "r12Attachment" to observation.attachment,
                                "r12Generation" to observation.generation,
                                "r12Detail" to observation.detail,
                                "r12Privacy" to if (observation.full) "full" else "discreet",
                            ) },
                        )
                    }
                }
            },
            onSurfaceFailure = { reason -> hideImmediately("r12SurfaceFailure:$reason") },
            onR18HostReady = ::onR18HostReady,
            onR18HostAttached = { generation, at ->
                r18Active?.takeIf { it.token.stamp.hostGeneration == generation }?.let { recordR18(it, "HOST_ATTACHED", at) }
            },
            onR18BufferReady = ::onR18BufferReady,
            onR18Failure = ::onR18Failure,
            onR18Receipt = ::onR18Receipt,
            onR18Drained = ::onR18Drained,
            onR19Allocated = ::onR19Allocated,
            onR19Observation = ::onR19Observation,
            r18PipelineEnabled = true,
            onFirstRootPreDraw = ::recordFirstRootPreDraw,
            onFirstRootDraw = ::recordFirstRootDraw,
            onFirstShaderDraw = ::recordFirstShaderDraw,
            onBootstrapDraw = ::recordBootstrapDraw,
            onBootstrapCommit = ::recordBootstrapCommit,
            onLivePromotion = ::recordLivePromotion,
            onFrameCommit = ::recordFirstFrameCommit,
        )
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "SETTINGS_LOAD_START")
        val settings = FluviKeyguardCardSettings.read(applicationContext)
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "SETTINGS_LOAD_END")
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "PROFILE_LOAD_START")
        val profile = if (r444ConfigurationReady && !r448SampleOnly) FluviKeyguardMaterialStore.read(applicationContext) else null
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "PROFILE_LOAD_END")
        lastSettings = settings
        lastMaterialProfile = profile
        registerRuntimeSignals()
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "ROOT_PREPARE_START")
        if (r444ConfigurationReady) overlay.prepareRetainedView(settings, profile)
        refreshR18RouteOnMain()
        publishReadAheadState()
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "ROOT_PREPARE_END")
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_CONNECTED", "connected", false)
        traceKeyguard("SERVICE_CONNECTED", "connected")
        startReferenceEnrollmentIfEligible()
        beginOrJoinWakeCycle("connected")
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent) {
        val r41Capture = KeyguardCardDiagnostics.activeCaptureId()
        val r41AtNs = if (r41Capture != null) System.nanoTime() else Long.MIN_VALUE
        val callbackReceivedAt = SystemClock.uptimeMillis()
        val r41Ordinal = if (r41Capture != null) {
            val eventAt = event.eventTime
            KeyguardCardDiagnostics.r41Provisional(r41Capture, 3, session.get(), callbackReceivedAt, r41AtNs,
                if (eventAt > 0 && eventAt <= callbackReceivedAt) eventAt else -1L)
        } else 0L
        // Copy only non-sensitive metadata while Android owns the event. In
        // particular, do not hand AccessibilityEvent itself to the worker.
        val meta = KeyguardAccessibilityEventMeta(
            eventType = event.eventType,
            windowId = event.windowId,
            displayId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) event.displayId else Display.DEFAULT_DISPLAY,
            windowChanges = if (event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED) event.windowChanges else 0,
            packageName = event.packageName?.toString(),
            eventTimeUptimeMs = event.eventTime,
        )
        inspectionProbeForTest?.frameworkCopy(meta, event.eventType, event.windowId,
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) event.displayId else Display.DEFAULT_DISPLAY,
            if (event.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED) event.windowChanges else 0,
            event.packageName?.toString(), event.eventTime)
        acceptAccessibilityMetadata(meta, callbackReceivedAt, frameworkEvent = true,
            r41CaptureId = r41Capture, r41Ordinal = r41Ordinal)
    }

    /** A controlled fixture enters through the same metadata adapter as the
     * real framework callback. It never supplies a classification/decision. */
    internal fun acceptAccessibilityMetadataForTest(meta: KeyguardAccessibilityEventMeta) {
        check(Looper.myLooper() == Looper.getMainLooper())
        acceptAccessibilityMetadata(meta, SystemClock.uptimeMillis(), frameworkEvent = false)
    }

    private fun acceptAccessibilityMetadata(
        meta: KeyguardAccessibilityEventMeta,
        callbackReceivedAt: Long,
        frameworkEvent: Boolean,
        r41CaptureId: String? = null,
        r41Ordinal: Long = 0,
    ) {
        if (!KeyguardCardEventGate.isSurfaceEvent(meta.eventType)) return
        val eventSequence = r45IngressSequence.incrementAndGet()
        val waWake = r449Wake
        if (waWake != null) {
            val ownWa = r448Frame?.isOwnWindow(meta.windowId, meta.displayId) == true
            val action = KeyguardR45IngressPolicy.decide(meta, ownWa, null, waWake.lower)
            r45RecordIngress(waWake.context, "WIDGETS_ANYWHERE", eventSequence, meta, callbackReceivedAt,
                ownWa, action, r45Wa.phase.name, r449RestrictionRevision.get())
            if (action == KeyguardR45IngressAction.IGNORE) return
            if (action == KeyguardR45IngressAction.OWN_REMOVED) {
                r446Cancel("wa:ownWindowRemoved")
                return
            }
            r449RestrictionRevision.incrementAndGet()
            waWake.allowedRevision = -1L
            val pending = waWake.pendingValidation
            waWake.pendingValidation = null
            r45Wa.suspend(waWake.arm)
            if (r448Frame?.conceal(waWake.owner, "unclassifiedEvent") != true) {
                r446Cancel("wa:concealFailed")
                return
            }
            if (pending != null) runCatching { pending(false) }
            r449ScheduleRead()
            return
        }
        val direct = r45Direct.lease
        if (direct != null && r448DisplayRoute == KeyguardR448DisplayRoute.FLUVI_STREAM) {
            val action = KeyguardR45IngressPolicy.decide(meta, false, direct.target.windowId, r45DirectLower)
            r45RecordIngress(r446Observation?.context, "FLUVI_STREAM", eventSequence, meta, callbackReceivedAt,
                false, action, r45Direct.phase.name, r45DirectRevision.get())
            if (action == KeyguardR45IngressAction.IGNORE) return
            if (action == KeyguardR45IngressAction.TARGET_REMOVED) {
                r446Cancel("direct:targetRemoved")
                return
            }
            r45DirectRevision.incrementAndGet()
            r45Direct.suspend(direct)
            if (r446Presenter?.conceal(direct.token) != true) {
                r446Cancel("direct:concealFailed")
                return
            }
            r45RecordStage(r446Observation?.context, "FLUVI_STREAM", "CONCEAL", SystemClock.uptimeMillis(),
                revision = r45DirectRevision.get(), detail = "unclassifiedEvent")
            r45ScheduleDirectRead(direct)
            return
        }
        if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) {
            // A WA frame must identify its own exact attached window. A
            // same-package Activity or an ambiguous event remains a veto.
            val ownSampleEvent = if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE)
                r448Frame?.isOwnWindow(meta.windowId, meta.displayId) == true
            else meta.packageName == packageName
            if (ownSampleEvent) return
            r446Cancel("externalWindowTransition")
        }
        val eventAge = meta.eventTimeUptimeMs
            ?.takeIf { it in 1..callbackReceivedAt }
            ?.let { callbackReceivedAt - it }
        val own = ::overlay.isInitialized && overlay.isOwnAccessibilityWindow(meta.windowId, meta.displayId)
        val r14Origin = KeyguardR14IngressClassifier.classify(meta, own)
        val action = KeyguardCardEventGate.decide(meta, own)
        if (KeyguardR441RestrictionIngress.mustWithdraw(Build.VERSION.SDK_INT, meta, own,
                ::overlay.isInitialized && overlay.isAttached)) {
            // The existing owner is withdrawn before any optional lazy-extra
            // IPC. A new read must independently regain current authority.
            hideImmediately("r441UnresolvedSurfaceChange", terminalWake = false,
                awaitingSurfaceWithdrawal = true, triggerReceivedUptimeMs = callbackReceivedAt)
        }
        // No witness means ordinary reconciliation remains entirely in charge.
        // A matched framework event seals the exact owner before Main work.
        if (r40RemovalGate.hasWitness && frameworkEvent &&
            meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            meta.windowChanges and AccessibilityEvent.WINDOWS_CHANGE_REMOVED != 0) {
            val fallbackOwner = r18Active
            val matched = synchronized(queueLock) {
                val owner = r18Active
                val identity = owner?.identity
                val withdrawal = r40RemovalGate.remove(meta, callbackReceivedAt, true, own,
                    identity?.token, inspectionAuthority, r40AppUid)
                if (owner != null && identity != null && withdrawal?.reservation === identity.token &&
                    r18Active === owner && owner.identity === identity) {
                    openingHandoff.invalidate()
                    firstAuthorizedOrb.invalidate()
                    owner to identity
                } else null
            }
            if (matched != null) {
                val at = SystemClock.uptimeMillis()
                finishR18Seal(matched.first, matched.second, "r40ClockWindowRemoved", Long.MAX_VALUE, at)
                recordR40(matched.first, matched.second, "REMOVAL_MATCH", at, null, meta.windowId)
            } else if (fallbackOwner != null) {
                recordR40(fallbackOwner, fallbackOwner.identity, "REMOVAL_FALLBACK", callbackReceivedAt, null, meta.windowId)
            }
        } else if (frameworkEvent && meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED &&
            meta.windowChanges and AccessibilityEvent.WINDOWS_CHANGE_REMOVED != 0) {
            val owner = r18Active
            if (owner?.r40Acknowledged != null)
                recordR40(owner, owner.identity, "REMOVAL_FALLBACK", callbackReceivedAt, null, meta.windowId)
        }
        // Invalidate before sampler, queue, diagnostics or coalescing. Only a
        // positively identified exact current own window is exempt.
        val invalidation = if (!own && (meta.displayId == Display.DEFAULT_DISPLAY || meta.displayId < 0))
            invalidateR19Scene("INGRESS", ordinaryRecheck = action == KeyguardEventAction.INSPECT, meta = meta, callbackAt = callbackReceivedAt) else null
        val retained = invalidation?.retained
        inspectionProbeForTest?.ingress(meta, callbackReceivedAt, action, frameworkEvent)
        if (KeyguardCardDiagnostics.wantsEvent("ACCESSIBILITY_EVENT")) traceKeyguard(
            "ACCESSIBILITY_EVENT",
            if (action == KeyguardEventAction.IGNORE_OWN) "ownIgnored" else "surface",
            observedUptimeMs = callbackReceivedAt,
            fields = mapOf(
                "eventType" to meta.eventType,
                "windowChanges" to meta.windowChanges,
                "windowId" to meta.windowId,
                "displayId" to meta.displayId,
                "eventTimeUptimeMs" to (meta.eventTimeUptimeMs?.takeIf { it > 0 } ?: "NA"),
                "eventAgeMs" to (eventAge ?: "NA_invalidOrFuture"),
                "classification" to r14Origin.name,
                "overlayState" to if (::overlay.isInitialized && overlay.isAttached) "attached" else "hidden",
            ),
        )
        when (action) {
            KeyguardEventAction.IGNORE_OWN -> {
                requestSystemCheck("accessibilityOwn", callbackReceivedAt, eventTime = meta.eventTimeUptimeMs)
                KeyguardCardDiagnostics.record(this, "KG|OWN_EVENT_IGNORED", "ownSignal", overlay.isAttached)
                // The package-less post-add race reaches INSPECT, not an
                // eager detach. A positively matched own event needs no work.
            }
            KeyguardEventAction.INSPECT -> {
                val ingress = KeyguardR14Ingress(
                    id = ++nextR14IngressId,
                    externalSystemUi = r14Origin == KeyguardR14Origin.SYSTEM_UI,
                    windowId = meta.windowId, displayId = meta.displayId, eventType = meta.eventType,
                    eventAt = meta.eventTimeUptimeMs, callbackAt = callbackReceivedAt, origin = r14Origin,
                )
                val cycle = beginOrJoinWakeCycle("accessibility", callbackReceivedAt, schedule = false,
                    eventTime = meta.eventTimeUptimeMs, r41CaptureId = r41CaptureId, r41Ordinal = r41Ordinal)
                if (cycle == null) {
                    retained?.let { pending ->
                        runCatching { recordR21(pending.binding, "INGRESS", callbackReceivedAt, pending.decision.ordinal,
                            pending.decision.phase.name, "NO_CYCLE", r14Origin.name, meta, callbackReceivedAt) }
                        if (r18Active === pending.owner && r18Coordinator.isAppliedPending(pending.binding.token,
                                pending.owner.host, pending.owner.output)) failR18Stage(pending.owner, "ingressCycleUnavailable")
                    }
                    return
                }
                val offered = scheduleEvaluationFromIngress(
                    "window",
                    meta.eventTimeUptimeMs,
                    triggerReceivedUptimeMs = callbackReceivedAt,
                    freshness = if (cycle?.started == true) {
                        KeyguardWindowFreshness.LIFECYCLE_BOUNDARY
                    } else {
                        KeyguardWindowFreshness.FRAMEWORK_EVENT
                    },
                    meta = meta,
                    frameworkEvent = frameworkEvent,
                    ingress = ingress,
                    externalScene = invalidation?.scene,
                )
                r449FluviRecovery?.let { recovery ->
                    val initial = recovery.observation
                    val relevant = frameworkEvent && offered != null && !recovery.consumed &&
                        r446Owner.arm == recovery.arm && r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ &&
                        wakeEpoch == initial.wake && callbackReceivedAt >= initial.inventoryAt &&
                        meta.displayId == Display.DEFAULT_DISPLAY &&
                        (meta.windowId == initial.host || meta.windowId == initial.upper ||
                            (meta.windowId < 0 && meta.eventType == AccessibilityEvent.TYPE_WINDOWS_CHANGED))
                    if (relevant) {
                        recovery.consumed = true
                        KeyguardCardDiagnostics.recordR449Recovery(initial.copy(stage = "REAL_CHANGE_OFFERED",
                            at = callbackReceivedAt, successor = offered))
                    }
                }
                retained?.let { pending ->
                    runCatching { recordR21(pending.binding, "INGRESS", callbackReceivedAt, pending.decision.ordinal,
                        pending.decision.phase.name, if (offered != null) "RECHECK_OFFERED" else "OFFER_REJECTED",
                        r14Origin.name, meta, callbackReceivedAt, offered) }
                    if (offered == null && r18Active === pending.owner &&
                        r18Coordinator.isAppliedPending(pending.binding.token, pending.owner.host, pending.owner.output))
                        failR18Stage(pending.owner, "ingressOfferUnavailable")
                }
            }
        }
    }

    override fun onInterrupt() {
        if (Build.VERSION.SDK_INT == 37) stopR444Trial("serviceInterrupted")
        hideImmediately("interrupt")
    }

    override fun onUnbind(intent: Intent?): Boolean {
        cleanup("unbind")
        return super.onUnbind(intent)
    }

    override fun onDestroy() {
        cleanup("destroy")
        super.onDestroy()
    }

    override fun onTrimMemory(level: Int) {
        super.onTrimMemory(level)
        if (::overlay.isInitialized) overlay.onMemoryTrim(level)
    }

    /** Freeze's scalar cut shares the same order as queue offers; no Android,
     * formatting or diagnostic-consumer work runs while this lock is held. */
    internal fun cutR22DiagnosticCapture(cut: () -> Unit) {
        synchronized(queueLock) { cut() }
    }

    /** Called by the unlocked Flutter Activity through the process-local
     * registry. This is only an invalidation signal; preferences remain the
     * durable source of truth. */
    internal fun onSettingsChangedFromApplication(settings: KeyguardCardSettings) {
        mainHandler.post {
            if (r446HasBackend() && lastSettings != settings) r446Cancel("settingsChanged")
            if (r18Active != null && lastSettings != settings) sealR18(inspectionAuthority, Long.MAX_VALUE, "settingsChanged")
            clearR14Recovery("settingsChanged")
            publishReadAheadState(invalidate = true)
            try {
            val previous = lastSettings
            lastSettings = settings
            if ((!settings.requested || !settings.showFinancialDetails) && ::overlay.isInitialized) overlay.clearPrivateOrbPoster()
            if (r18Active != null && previous != settings) hideImmediately("r18SettingsChanged", terminalWake = false)
            if (!settings.requested) {
                hideImmediately("settings")
                disableSelf()
            } else if (!settings.showFinancialDetails) {
                // Privacy tightening must redact the existing root before an
                // asynchronous query can return. It is not a window detach.
                redactImmediately("settings")
                overlay.updateMaterial(lastMaterialProfile, settings)
                if (overlay.isAttached) scheduleEvaluation("settings")
                else requestSystemCheck("privacyTightened")
            } else {
                // A position-only change is a WindowManager layout update,
                // not a financial invalidation or view-state reset.
                if (previous?.showFinancialDetails != settings.showFinancialDetails) showEvent = false
                overlay.updateMaterial(lastMaterialProfile, settings)
                scheduleEvaluation("settings")
            }
            } finally {
                publishReadAheadState(invalidate = true)
                refreshR18RouteOnMain()
            }
        }
    }

    /** Layout patches intentionally bypass the general settings/evaluation
     * lane: a drag has already updated the retained root and must not start a
     * financial resolve, material reload or focus-generation change. */
    internal fun onLayoutChangedFromApplication(settings: KeyguardCardSettings) {
        mainHandler.post {
            if (r47RecordingHeader && !r47HeaderCurrent() && r446HasBackend())
                r446Cancel("presentationModeChanged")
            publishReadAheadState(invalidate = true)
            try {
            lastSettings = settings
            if (::overlay.isInitialized) overlay.updateLayoutSettings(settings)
            } finally {
                publishReadAheadState(invalidate = true)
            }
        }
    }

    private fun onOverlayInteractionStarted() {
        // This only invalidates reads that predate the pointer stream. A later
        // real SystemUI event starts a fresh inspection and remains allowed to
        // hide the overlay even while the finger is down.
        val before = inspectionAuthority
        interactionEpoch.incrementAndGet()
        val after = before.copy(interactionEpoch = interactionEpoch.get())
        val owner = r18Active
        if (owner != null && !r18Coordinator.advanceInteraction(owner.token, before, after)) {
            sealR18(before, Long.MAX_VALUE, "interactionAuthority")
            hideImmediately("r18InteractionAuthority", terminalWake = false)
            return
        }
        publishInspectionAuthority()
        preservePendingReconciliation("interaction", requirePending = false)
    }

    private fun onOverlayPositionCommitted(
        mode: KeyguardCardPresentationMode,
        card: KeyguardCardCardPosition,
        orb: KeyguardCardOrbPosition,
        expectedLayoutRevision: Long,
    ) {
        clearR14Recovery("layoutChanged")
        publishReadAheadState(invalidate = true)
        try {
        val settings = FluviKeyguardCardSettings.patchLayout(
            applicationContext,
            mapOf(
                "presentationMode" to mode.wireValue,
                "cardPosition" to mapOf("yFraction" to card.yFraction),
                "orbPosition" to mapOf("xFraction" to orb.xFraction, "yFraction" to orb.yFraction),
            ),
            expectedLayoutRevision = expectedLayoutRevision,
        )
        lastSettings = settings
        // A newer reset/layout patch won the race. Return the attached root
        // to that persisted geometry without entering the general settings
        // path or re-resolving financial content.
        if (settings.layoutRevision != expectedLayoutRevision + 1L) {
            overlay.updateLayoutSettings(settings)
        }
        } finally {
            publishReadAheadState(invalidate = true)
        }
    }

    internal fun onFinancialFocusChangedFromApplication() {
        mainHandler.post {
            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "focusChanged")
            clearR14Recovery("focusChanged")
            publishReadAheadState(invalidate = true)
            try {
            showEvent = false
            if (::overlay.isInitialized) overlay.clearPrivateOrbPoster()
            if (r18Active != null) hideImmediately("r18FocusChanged", terminalWake = false)
            invalidateFullContent()
            // A focus change may make a visible amount misleading. Redact in
            // place when possible; do not bounce the overlay root.
            if (overlay.isAttached && appliedDecision == KeyguardCardVisibility.SHOW_FULL) {
                applyPresentation({ FluviFinancialCardPresenter.loading() }, "focusChanged")
            }
            scheduleEvaluation("focusChanged")
            } finally {
                publishReadAheadState(invalidate = true)
            }
        }
    }

    /** Profile publication is a retained-view mutation only. It must not
     * cause an inspection, financial resolve, or WindowManager operation. */
    internal fun onMaterialProfileChangedFromApplication(profile: KeyguardMaterialProfile) {
        if (r448SampleOnly) return
        mainHandler.post {
            if (r448SampleOnly) return@post
            if (r18Active != null) sealR18(inspectionAuthority, Long.MAX_VALUE, "materialChanged")
            synchronized(queueLock) { firstAcquisition.invalidate() }
            clearR14Recovery("materialChanged")
            lastMaterialProfile = profile
            if (!::overlay.isInitialized) return@post
            val hadR18 = r18Active != null
            if (hadR18) hideImmediately("r18MaterialChanged", terminalWake = false)
            overlay.updateMaterial(profile, lastSettings ?: FluviKeyguardCardSettings.read(applicationContext))
            publishReadAheadState(invalidate = true)
            refreshR18RouteOnMain()
            if (hadR18) requestSystemCheck("r18MaterialChanged", evaluate = true)
            KeyguardCardDiagnostics.record(this, "KG|MATERIAL_SCENE", "profile:${profile.publisherRevision}", overlay.isAttached)
        }
    }

    /** A newly committed header invalidates the exact prepared private owner;
     * the next owner must capture its own matching generation. */
    internal fun onActiveHeaderChangedFromApplication() {
        check(Looper.myLooper() == Looper.getMainLooper())
        if (!r47RecordingHeader || r47HeaderCurrent()) return
        r446Cancel("activeHeaderChanged")
        r47Header = FluviActiveHeaderMaterialStore.applicable(applicationContext)
        r449PrepareSessionWake()
    }

    private fun registerRuntimeSignals() {
        if (!receiverRegistered) {
            val filter = IntentFilter().apply {
                addAction(Intent.ACTION_SCREEN_OFF)
                addAction(Intent.ACTION_SCREEN_ON)
                addAction(Intent.ACTION_USER_PRESENT)
            }
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                registerReceiver(screenReceiver, filter, Context.RECEIVER_NOT_EXPORTED)
            } else {
                @Suppress("UnspecifiedRegisterReceiverFlag")
                registerReceiver(screenReceiver, filter)
            }
            receiverRegistered = true
        }
        if (!displayRegistered) {
            displayManager.registerDisplayListener(displayListener, mainHandler)
            displayRegistered = true
        }
    }

    /** Opens only a genuinely new eligible wake. SCREEN_ON joins a cycle that
     * was already established by a fresh Display/accessibility signal. */
    private fun beginOrJoinWakeCycle(
        source: String,
        receivedAtUptimeMs: Long = SystemClock.uptimeMillis(),
        schedule: Boolean = true,
        freshState: KeyguardSystemState? = null,
        eventTime: Long? = null,
        sampleRequest: KeyguardSystemGateRequest? = null,
        r41CaptureId: String? = null,
        r41Ordinal: Long = 0,
    ): KeyguardWakeCycleTransition? {
        val existing = wakeCycleOwner.current()
        if (existing != null) {
            if (freshState == null) requestSystemCheck(source, receivedAtUptimeMs, eventTime = eventTime)
            val transition = if (source == "wake") {
                val ordinal = if (r41CaptureId == currentDiagnosticAttempt?.captureId) r41Ordinal else 0
                KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, ordinal, screen = true)
                val joined = wakeCycleOwner.beginOrJoin(existing.id, source, receivedAtUptimeMs)
                traceKeyguard(
                    "SCREEN_ON_RECEIVED",
                    "joined:${joined.cycle.firstSignal}",
                    observedUptimeMs = receivedAtUptimeMs,
                    fields = mapOf("wakeCycleId" to joined.cycle.id, "joinedExistingCycle" to true),
                )
                joined
            } else {
                KeyguardWakeCycleTransition(existing, started = false, screenOnJoined = false)
            }
            // The early inspection already owns the current authority. Do
            // not replace it merely because another signal names the same
            // wake; schedule only when no compatible work exists.
            if (schedule && !hasCompatibleCycleInspection()) {
                scheduleEvaluation(source, triggerReceivedUptimeMs = receivedAtUptimeMs)
            }
            return transition
        }
        if (freshState == null) {
            requestSystemCheck(source, receivedAtUptimeMs, evaluate = true, wakeSource = source, eventTime = eventTime,
                r41CaptureId = r41CaptureId, r41Ordinal = r41Ordinal)
            return null
        }
        if (!freshState.eligible || lastSettings?.requested != true) return null
        val early = synchronized(queueLock) {
            r18ProvisionalWake?.takeIf {
                it.sampleId == sampleRequest?.id && it.previousAuthority == inspectionAuthority &&
                    it.targetAuthority.wakeGeneration == wakeEpoch + 1L && it.routeRevision == r18RouteRevision
            }
        }
        val cycleTransition = wakeCycleOwner.beginOrJoin(wakeEpoch + 1L, source, receivedAtUptimeMs)
        val cycle = cycleTransition.cycle
        r18WakeOpen = true
        clearR14Recovery("newWake")
        wakeEpoch = cycle.id
        // A new wake is a new eligible cycle; a prior terminal exclusion must
        // not suppress its first authoritative inspection.
        terminalHideState = null
        surfacePresentationState = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE
        publishInspectionAuthority()
        firstDrawOwner = null
        retryCount = 0
        cancelWakeRetry()
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        val preparedInitialLive = ::overlay.isInitialized &&
            overlay.preparedInitialLiveOrb(settings, lastMaterialProfile)
        synchronized(queueLock) {
            if (early == null || early.targetAuthority != inspectionAuthority || r18ProvisionalWake !== early) {
                firstAcquisition.begin(inspectionAuthority, preparedInitialLive)
            } else if (r18Coordinator.adopt(early.token, early.token.stamp)) {
                r18AdoptedSampleId = early.sampleId
                r18ProvisionalWake = null
            } else {
                cancelR18ReservationLocked()
                firstAcquisition.begin(inspectionAuthority, preparedInitialLive)
            }
        }
        wakeTiming = WakeTiming(
            wakeGeneration = wakeEpoch,
            wakeReceivedAt = receivedAtUptimeMs,
            rootWasPrepared = ::overlay.isInitialized && overlay.hasPreparedRoot,
            profileWasDecoded = lastMaterialProfile != null,
            presentationMode = settings.presentationMode.wireValue,
            eligibility = if (sampleRequest?.diagnosticCaptureId != null &&
                sampleRequest.diagnosticCaptureId == KeyguardCardDiagnostics.activeCaptureId())
                KeyguardWakeEligibilityEvidence(sampleRequest?.id, sampleRequest?.authority,
                    receivedAtUptimeMs, freshState.startedAt, freshState.finishedAt, SystemClock.uptimeMillis(),
                    sampleRequest.diagnosticCaptureId)
            else null,
        )
        currentDiagnosticAttempt = early?.diagnosticContext ?: KeyguardCardDiagnostics.beginLockAttempt(
            this,
            session.get(),
            wakeEpoch,
            source,
            receivedAtUptimeMs,
        )
        if (r442ScreenOn?.session == session.get()) r447RecordWakeArm()
        val wakeOrdinal = if (sampleRequest != null && sampleRequest.diagnosticCaptureId == currentDiagnosticAttempt?.captureId)
            sampleRequest.r41WakeOrdinal else if (r41CaptureId == currentDiagnosticAttempt?.captureId) r41Ordinal else 0
        KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, wakeOrdinal)
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.SYSTEM_ELIGIBLE, currentDiagnosticAttempt)
        if (source == "wake") {
            val screenOrdinal = if (sampleRequest != null && sampleRequest.diagnosticCaptureId == currentDiagnosticAttempt?.captureId)
                sampleRequest.r41ScreenOrdinal else if (r41CaptureId == currentDiagnosticAttempt?.captureId) r41Ordinal else 0
            KeyguardCardDiagnostics.r41Bind(currentDiagnosticAttempt, screenOrdinal, screen = true)
        }
        // A SCREEN_ON may have arrived before the fresh system sample that
        // creates this cycle. The WA owner starts when both are available.
        r45TryBeginWaWake()
        if (early != null && r18AdoptedSampleId == early.sampleId) {
            r18FallbackWake = null
            startR18Stage(early.token, early.preparation, settings, currentDiagnosticAttempt, freshState, early.reservedAt)
        }
        synchronized(queueLock) { inspectionQueue.activeRequest() }?.let { occupied ->
            traceKeyguard(
                "WORKER_OCCUPIED_AT_WAKE",
                occupied.trigger,
                requestId = occupied.id,
                diagnosticContext = currentDiagnosticAttempt,
                observedUptimeMs = receivedAtUptimeMs,
                fields = mapOf(
                    "activeOriginalSession" to occupied.session,
                    "activeOriginalWake" to occupied.wakeGeneration,
                    "activeOriginalVisibilityEpoch" to occupied.visibilityEpoch,
                    "activeOriginalInteractionEpoch" to occupied.interactionEpoch,
                    "activeOriginalAttachGeneration" to occupied.attachGeneration,
                    "activeQueuedAtUptimeMs" to occupied.queuedAtUptimeMs,
                ),
            )
        }
        traceKeyguard(
            if (source == "wake") "SCREEN_ON_RECEIVED" else "WAKE_CYCLE_STARTED",
            source,
            observedUptimeMs = receivedAtUptimeMs,
            fields = mapOf("sourceEventTime" to "NA", "sourceTimeUnavailable" to true),
        )
        if (schedule) {
            scheduleEvaluation(
                source,
                triggerReceivedUptimeMs = receivedAtUptimeMs,
                freshness = KeyguardWindowFreshness.LIFECYCLE_BOUNDARY,
            )
        }
        return cycleTransition
    }

    private fun hasCompatibleCycleInspection(excludingId: Long? = null): Boolean = synchronized(queueLock) {
        inspectionQueue.hasCurrentWork(inspectionAuthority, excludingId)
    }

    /** queueLock held. This checks scheduling identities, never show authority. */
    private fun r448BoundaryDecisionLocked(arm: KeyguardR446PrintOwner.Arm,
                                           authority: KeyguardInspectionAuthority): KeyguardR448WakeReadBoundary.Decision {
        fun work(value: KeyguardCardInspectionRequest?) = value?.let {
            KeyguardR448WakeReadBoundary.Work(it.id, authority.matches(it),
                it.session == arm.session && it.diagnosticContext?.captureId == arm.capture)
        }
        return KeyguardR448WakeReadBoundary.decide(work(inspectionQueue.activeRequest()),
            work(inspectionQueue.pendingRequest()), r448StartedRequest, r448StartedArm == arm.generation)
    }

    private fun r448RecordBoundary(arm: KeyguardR446PrintOwner.Arm, screenAt: Long) {
        val context = currentDiagnosticAttempt ?: return
        if (context.captureId != arm.capture || context.serviceSession != arm.session ||
            context.originWakeEpoch != wakeCycleOwner.current()?.id) return
        val observation = synchronized(queueLock) {
            KeyguardR448BoundaryObservation(context, arm.generation, screenAt,
                inspectionQueue.activeRequest()?.id, inspectionQueue.pendingRequest()?.id,
                r448StartedRequest, r448StartedArm == arm.generation,
                r448BoundaryDecisionLocked(arm, inspectionAuthority))
        }
        runCatching { KeyguardCardDiagnostics.recordR448Boundary(observation) }
    }

    private enum class R447SystemOrigin { UNPROVEN, INTERNAL_OUTPUT_READY }

    /** No View/platform acquisition on this main-owned submission path. */
    private fun requestSystemCheck(
        reason: String,
        receivedAt: Long = SystemClock.uptimeMillis(),
        evaluate: Boolean = false,
        wakeSource: String? = null,
        retry: Boolean = false,
        freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
        eventTime: Long? = null,
        completedInspectionId: Long? = null,
        r41CaptureId: String? = null,
        r41Ordinal: Long = 0,
        sampleOrigin: R447SystemOrigin = R447SystemOrigin.UNPROVEN,
    ) {
        if (!FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return
        val captureId = KeyguardCardDiagnostics.activeCaptureId()
        val wakeOrdinal = if (captureId != null && captureId == r41CaptureId && wakeSource != null) r41Ordinal else 0
        val (sampleBarrier, duplicate) = if (r446CaptureId == null) 0L to null else synchronized(queueLock) {
            val samplerIdle = !systemSampler.hasOutstandingWork()
            val arm = r446ReadArm
            val active = inspectionQueue.activeRequest()
            val revision = inspectionFreshness.revisionFor(inspectionAuthority)
            val scene = firstAuthorizedOrb.sceneSerial()
            val order = active?.let { firstAuthorizedOrb.sampleOrder(it.id, scene) }
            val proof = if (sampleOrigin == R447SystemOrigin.INTERNAL_OUTPUT_READY && samplerIdle &&
                evaluate && wakeSource == null && !retry && !freshness.requiresCacheClear &&
                arm != null && arm.capture == captureId && arm.session == inspectionAuthority.serviceSession &&
                active != null && inspectionAuthority.matches(active) && inspectionQueue.pendingRequest() == null &&
                revision != null && inspectionFreshness.isEstablished(inspectionAuthority, revision) &&
                order != null && order.required == active.id && order.barrier <= active.id &&
                r447SystemBarrier == r447SystemSatisfied) {
                KeyguardR447DuplicateProof(inspectionAuthority, scene, revision, active.id, order.required,
                    order.barrier, r447SystemBarrier, arm.generation, readAheadStateRevision, r18RouteRevision)
            } else null
            if (proof == null && r446CaptureId != null) r447SystemBarrier += 1L
            r447SystemBarrier to proof
        }
        systemSampler.offer(KeyguardSystemGateRequest(++nextSystemGateId, inspectionAuthority,
            reason, receivedAt, SystemClock.uptimeMillis(), evaluate, wakeSource,
            eventTime = eventTime, retry = retry, freshness = freshness, completedInspectionId = completedInspectionId,
            diagnosticCaptureId = captureId, r41WakeOrdinal = wakeOrdinal,
            r41ScreenOrdinal = if (wakeSource == "wake") wakeOrdinal else 0,
            r447SystemBarrier = sampleBarrier, r447Duplicate = duplicate))
    }

    private fun applySystemState(request: KeyguardSystemGateRequest, state: KeyguardSystemState) {
        // The sampler checks every identity, even for a negative answer.
        if (!FluviKeyguardCardServiceRegistry.connected || lastSettings?.requested != true) return
        latestSamplerEvidence = if (request.diagnosticCaptureId != null &&
            request.diagnosticCaptureId == KeyguardCardDiagnostics.activeCaptureId())
            KeyguardSamplerEvidence(request.id, request.authority, state.startedAt, state.finishedAt,
                SystemClock.uptimeMillis(), state.eligible, state.excluded, request.diagnosticCaptureId)
        else null
        if (state.excluded) {
            val vetoAt = SystemClock.uptimeMillis()
            val vetoArm = r446Owner.arm
            val vetoWa = r449Wake
            val vetoContext = currentDiagnosticAttempt?.takeIf {
                vetoArm != null && it.captureId == vetoArm.capture && it.serviceSession == vetoArm.session &&
                    it.originWakeEpoch == request.authority.wakeGeneration &&
                    r446Owner.state in setOf(KeyguardR446PrintOwner.State.WAIT_READ, KeyguardR446PrintOwner.State.ISSUED)
            }
            val vetoScreenAt = r442ScreenOn?.takeIf { it.session == request.authority.serviceSession }?.uptime
            if (vetoWa != null || r446Owner.state == KeyguardR446PrintOwner.State.WAIT_READ ||
                r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) r446Cancel("systemGate")
            hideImmediately("systemGate:${request.reason}", triggerReceivedUptimeMs = request.receivedAt)
            // An unlock sample may arrive after USER_PRESENT saw the old arm.
            // Prepare only a future wake, after hiding the excluded one.
            if ((vetoArm != null || vetoWa != null) && state.available && state.primaryDisplay &&
                state.interactive && state.displayOn && !state.keyguardLocked && r449Session != null)
                r449PrepareSessionWake()
            // Preserve the actual accepted acquisition after the mandatory
            // hide. Diagnostic failures must never delay or undo exclusion.
            if (vetoContext != null && vetoArm != null) runCatching {
                KeyguardCardDiagnostics.recordR448SystemVeto(KeyguardR448SystemVeto(vetoContext,
                    vetoArm.generation, request.id, request.diagnosticCaptureId == vetoArm.capture,
                    request.reason, request.receivedAt, request.queuedAt,
                    vetoScreenAt, vetoAt, state))
            }
            return
        }
        if (!state.eligible) {
            invalidateR19Scene("SYSTEM")
            if (r18Active?.preparation?.emptyAwaitingDisclosure == true) scheduleR19Join()
            return
        }
        if (r446CaptureId != null) synchronized(queueLock) {
            if (request.r447SystemBarrier == r447SystemBarrier && request.authority == inspectionAuthority)
                r447SystemSatisfied = request.r447SystemBarrier
        }
        if (!request.evaluate) return
        val cycle = request.wakeSource?.let {
            beginOrJoinWakeCycle(it, request.evaluationReceivedAt, schedule = false, freshState = state, sampleRequest = request,
                r41CaptureId = request.diagnosticCaptureId, r41Ordinal = request.r41WakeOrdinal)
        }
        if (request.wakeSource != "wake") request.screenOnReceivedAt?.let {
            beginOrJoinWakeCycle("wake", it, schedule = false, freshState = state, sampleRequest = request,
                r41CaptureId = request.diagnosticCaptureId, r41Ordinal = request.r41ScreenOrdinal)
        }
        if (wakeCycleOwner.current() == null) return
        if (r18AdoptedSampleId == request.id) {
            r18AdoptedSampleId = null
            if (hasCompatibleCycleInspection()) return
        }
        if (request.retry && hasCompatibleCycleInspection(request.completedInspectionId)) return
        scheduleEvaluationWithSampleProvenance(request.evaluationReason, request.eventTime, request.evaluationReceivedAt,
            if (cycle?.started == true) KeyguardWindowFreshness.LIFECYCLE_BOUNDARY else request.freshness,
            sampleDuplicate = request.r447Duplicate)
    }

    private fun scheduleWakeRetry(
        cause: KeyguardCardInspectionRequest,
        freshness: KeyguardWindowFreshness,
        reason: String = "hiddenUnknown",
    ) {
        if (retryCount >= RETRY_DELAYS_MS.size) return
        cancelWakeRetry("replaced")
        val delay = RETRY_DELAYS_MS[retryCount]
        retryCount += 1
        val scheduledAt = SystemClock.uptimeMillis()
        val token = RetryToken(
            retryId = ++nextRetryId,
            retryIndex = retryCount,
            requestId = cause.id,
            session = cause.session,
            visibilityEpoch = visibilityEpoch.get(),
            interactionEpoch = interactionEpoch.get(),
            attachGeneration = overlayAttachGeneration,
            wakeGeneration = cause.wakeGeneration,
            scheduledAtUptimeMs = scheduledAt,
            dueAtUptimeMs = scheduledAt + delay,
            windowFreshness = freshness,
            diagnosticContext = cause.diagnosticContext,
        )
        retryToken = token
        wakeTiming?.takeIf { it.wakeGeneration == token.wakeGeneration }?.retryCount = retryCount
        traceKeyguard(
            "RETRY_SCHEDULED",
            reason,
            cause,
            fields = mapOf(
                "retryId" to token.retryId,
                "retryIndex" to token.retryIndex,
                "requestedDelayMs" to delay,
                "scheduledAtUptimeMs" to token.scheduledAtUptimeMs,
                "dueAtUptimeMs" to token.dueAtUptimeMs,
                "causingRequestId" to cause.id,
            ),
        )
        retryRunnable = Runnable {
            retryRunnable = null
            retryToken = null
            val firedAt = SystemClock.uptimeMillis()
            traceKeyguard(
                "RETRY_FIRED",
                "timer",
                requestId = token.requestId,
                observedUptimeMs = firedAt,
                diagnosticContext = token.diagnosticContext,
                fields = mapOf(
                    "retryId" to token.retryId,
                    "retryIndex" to token.retryIndex,
                    "scheduledAtUptimeMs" to token.scheduledAtUptimeMs,
                    "dueAtUptimeMs" to token.dueAtUptimeMs,
                    "schedulerLatenessMs" to (firedAt - token.dueAtUptimeMs),
                    "causingRequestId" to token.requestId,
                ),
            )
            if (token.session != session.get() ||
                token.visibilityEpoch != visibilityEpoch.get() ||
                token.interactionEpoch != interactionEpoch.get() ||
                token.attachGeneration != overlayAttachGeneration ||
                token.wakeGeneration != wakeEpoch ||
                !FluviKeyguardCardServiceRegistry.connected
            ) return@Runnable
            // A terminal state observed by the retry is caused by this
            // callback, not by the timer's ideal due time. Lateness is
            // recorded separately above.
            if (hasCompatibleCycleInspection(token.requestId)) {
                traceKeyguard(
                    "RETRY_SUPPRESSED_FOR_PENDING",
                    "compatibleWork",
                    requestId = token.requestId,
                    observedUptimeMs = firedAt,
                    diagnosticContext = token.diagnosticContext,
                    fields = mapOf("retryId" to token.retryId, "retryIndex" to token.retryIndex),
                )
                return@Runnable
            }
            requestSystemCheck(
                "surfaceRetry",
                receivedAt = firedAt,
                evaluate = true,
                retry = true,
                freshness = token.windowFreshness,
                completedInspectionId = token.requestId,
            )
        }.also { mainHandler.postDelayed(it, delay) }
    }

    private fun cancelWakeRetry(reason: String = "superseded"): Boolean {
        val pending = retryRunnable ?: return false
        mainHandler.removeCallbacks(pending)
        retryRunnable = null
        retryToken?.let { token ->
            traceKeyguard(
                "RETRY_CANCELLED",
                reason,
                requestId = token.requestId,
                diagnosticContext = token.diagnosticContext,
                fields = mapOf(
                    "retryId" to token.retryId,
                    "retryIndex" to token.retryIndex,
                    "scheduledAtUptimeMs" to token.scheduledAtUptimeMs,
                    "dueAtUptimeMs" to token.dueAtUptimeMs,
                    "causingRequestId" to token.requestId,
                    "cancelReason" to reason,
                ),
            )
        }
        retryToken = null
        return true
    }

    /** Captures authority at request creation, not when a delayed worker gets
     * CPU. At most one Binder traversal and one latest follow-up can exist. */
    private fun scheduleEvaluation(
        trigger: String,
        eventTimeUptimeMs: Long? = null,
        triggerReceivedUptimeMs: Long? = null,
        freshness: KeyguardWindowFreshness = KeyguardWindowFreshness.FRAMEWORK_EVENT,
        reconciliationIntent: KeyguardCardInspectionRequest? = null,
    ) {
        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
            reconciliationIntent, null, false)
    }

    private fun scheduleEvaluationWithSampleProvenance(
        trigger: String, eventTimeUptimeMs: Long?, triggerReceivedUptimeMs: Long?,
        freshness: KeyguardWindowFreshness, sampleDuplicate: KeyguardR447DuplicateProof?,
    ) {
        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
            null, null, false, sampleDuplicate = sampleDuplicate)
    }

    private fun scheduleEvaluationFromIngress(trigger: String, eventTimeUptimeMs: Long?,
        triggerReceivedUptimeMs: Long?, freshness: KeyguardWindowFreshness,
        meta: KeyguardAccessibilityEventMeta, frameworkEvent: Boolean, ingress: KeyguardR14Ingress,
        externalScene: Long?): Long? =
        scheduleEvaluationCommon(trigger, eventTimeUptimeMs, triggerReceivedUptimeMs, freshness,
            null, meta, frameworkEvent, ingress, externalScene)


    private fun scheduleEvaluationCommon(trigger: String, eventTimeUptimeMs: Long?,
        triggerReceivedUptimeMs: Long?, freshness: KeyguardWindowFreshness,
        reconciliationIntent: KeyguardCardInspectionRequest?, meta: KeyguardAccessibilityEventMeta?,
        frameworkEvent: Boolean, ingress: KeyguardR14Ingress? = null, externalScene: Long? = null,
        sampleDuplicate: KeyguardR447DuplicateProof? = null): Long? {
        if (!FluviKeyguardCardServiceRegistry.connected) return null
        val now = SystemClock.uptimeMillis()
        val authority = inspectionAuthority
        val nextId = nextInspectionId.incrementAndGet()
        val request = if (reconciliationIntent != null) {
            reconciliationIntent.reacquireAfterWithdrawal(authority, nextId, now, freshness) ?: return null
        } else KeyguardCardInspectionRequest(
            id = nextId,
            trigger = trigger,
            session = authority.serviceSession,
            visibilityEpoch = authority.visibilityEpoch,
            interactionEpoch = authority.interactionEpoch,
            attachGeneration = authority.attachGeneration,
            wakeGeneration = authority.wakeGeneration,
            queuedAtUptimeMs = now,
            windowFreshness = freshness,
            eventTimeUptimeMs = eventTimeUptimeMs,
            diagnosticContext = currentDiagnosticAttempt,
            triggerReceivedUptimeMs = triggerReceivedUptimeMs,
            r14Ingress = ingress,
            r32FrameworkIngressId = ingress?.id?.takeIf { frameworkEvent && meta != null },
            r34SceneSerial = externalScene?.takeIf { frameworkEvent && meta != null && ingress != null },
            r42SceneSerial = externalScene?.takeIf { meta != null && ingress != null },
            r42FrameworkEvent = frameworkEvent && meta != null,
            wakeEligibility = wakeTiming?.takeIf { it.wakeGeneration == authority.wakeGeneration }?.eligibility
                ?.takeIf { it.captureId == currentDiagnosticAttempt?.captureId && it.captureId == KeyguardCardDiagnostics.activeCaptureId() },
            latestSamplerEvidence = latestSamplerEvidence?.takeIf {
                it.belongsTo(authority, currentDiagnosticAttempt?.captureId) && it.captureId == KeyguardCardDiagnostics.activeCaptureId()
            },
        )
        if (request.trigger != "surfaceRetry" && request.trigger != "r448ScreenBoundary")
            cancelWakeRetry("supersededBy:${request.trigger}")
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration && request.trigger != "r448ScreenBoundary" }?.let {
            if (it.inspectionQueuedAt == null) it.inspectionQueuedAt = now
            request.eventTimeUptimeMs?.takeIf { eventTime -> eventTime <= now }?.let { eventTime ->
                it.eventAgeMs = now - eventTime
            }
        }
        var postClaimForTest: KeyguardOpeningInspectionHandoff.PostClaimSnapshot? = null
        val queueOffer = synchronized(queueLock) {
            if (trigger == "r448ScreenBoundary") {
                val arm = r446ReadArm ?: return null
                val screen = r442ScreenOn ?: return null
                if (screen.session != arm.session || arm.session != authority.serviceSession ||
                    arm.capture != currentDiagnosticAttempt?.captureId ||
                    arm.capture != KeyguardCardDiagnostics.activeCaptureId() ||
                    r446Owner.state != KeyguardR446PrintOwner.State.WAIT_READ) return null
                val decision = r448BoundaryDecisionLocked(arm, authority)
                if (decision != KeyguardR448WakeReadBoundary.Decision.OFFER) return null
            }
            val isProvedDuplicate = if (sampleDuplicate == null) false else {
                val active = inspectionQueue.activeRequest()
                val sampleOrder = active?.let { firstAuthorizedOrb.sampleOrder(it.id, firstAuthorizedOrb.sceneSerial()) }
                reconciliationIntent == null && meta == null && ingress == null && !frameworkEvent &&
                    !request.windowFreshness.requiresCacheClear && sampleDuplicate.authority == authority &&
                    sampleDuplicate.scene == firstAuthorizedOrb.sceneSerial() &&
                    sampleDuplicate.armGeneration == r446ReadArm?.generation &&
                    sampleDuplicate.systemBarrier == r447SystemBarrier && r447SystemBarrier == r447SystemSatisfied &&
                    sampleDuplicate.stateRevision == readAheadStateRevision && sampleDuplicate.routeRevision == r18RouteRevision &&
                    active?.id == sampleDuplicate.activeRequest && inspectionQueue.pendingRequest() == null &&
                    sampleOrder?.required == sampleDuplicate.required && sampleOrder?.barrier == sampleDuplicate.barrier &&
                    inspectionFreshness.isEstablished(authority, sampleDuplicate.revision)
            }
            inspectionFreshness.require(authority, request.windowFreshness)
            firstAuthorizedOrb.requireRead(request.id, if (isProvedDuplicate)
                KeyguardFirstAuthorizedOrb.SampleOffer.INTERNAL_DUPLICATE else KeyguardFirstAuthorizedOrb.SampleOffer.BARRIER)
            publishReadAheadSnapshotLocked()
            val replacedPending = inspectionQueue.pendingRequest()
            val startsWorker = inspectionQueue.offer(request)
            val actualPending = inspectionQueue.pendingRequest()
            openingHandoff.offered(request, actualPending, externalScene, firstAuthorizedOrb.sceneSerial(), frameworkEvent, replacedPending)
            openingHandoff.observePostClaimOffer(
                request, replacedPending, inspectionQueue.activeRequest(), actualPending, frameworkEvent,
                metadataPresent = meta != null,
            )?.let {
                KeyguardCardDiagnostics.recordR22PostClaim(it)
                if (inspectionProbeForTest != null) postClaimForTest = it
            }
            if (inspectionQueue.pendingRequest() != null) {
                recordMaximum(maximumPendingInspections, 1)
            }
            val promoted = if (!startsWorker) r25PromoteWaitingLocked() else null
            R25QueueOffer(
                start = if (startsWorker) inspectionQueue.activeRequest() else promoted?.successor,
                previousPending = replacedPending,
                pendingAtOffer = actualPending,
                pendingAfter = inspectionQueue.pendingRequest(),
                activeAfter = inspectionQueue.activeRequest(),
                superseded = promoted?.ticket,
            )
        }
        if (request.trigger == "r448ScreenBoundary") {
            cancelWakeRetry("supersededBy:${request.trigger}")
            wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
                if (it.inspectionQueuedAt == null) it.inspectionQueuedAt = now
            }
        }
        val r41OfferNs = if (request.diagnosticContext?.captureId != null &&
            request.diagnosticContext.captureId == KeyguardCardDiagnostics.activeCaptureId()) System.nanoTime() else Long.MIN_VALUE
        val r41OfferUptime = if (r41OfferNs != Long.MIN_VALUE) SystemClock.uptimeMillis() else now
        postClaimForTest?.let { observed -> runCatching { inspectionProbeForTest?.postClaimObserved(observed) } }
        val startsWorker = queueOffer.start != null
        inspectionProbeForTest?.queueOffered(request, queueOffer.previousPending, queueOffer.pendingAfter, startsWorker)
        runCatching { inspectionProbeForTest?.r25QueueTransition(request, queueOffer.pendingAtOffer,
            queueOffer.activeAfter, queueOffer.superseded?.request) }
        if (meta != null) inspectionProbeForTest?.ingressOffered(meta, request, queueOffer.previousPending,
            queueOffer.pendingAfter, startsWorker, frameworkEvent)
        // Exclusion is mandatory and stays ordered before the successor. The
        // optional description of the superseded ticket may follow dispatch.
        queueOffer.superseded?.let { old -> r25RequestExclusionCheck(old.request.session) }
        val recovery = r14Recovery
        val recoveryToReport = if (recovery?.used == true && queueOffer.previousPending != null && queueOffer.pendingAfter != null) {
            val next = recovery.copy(replacements = recovery.replacements + 1)
            r14Recovery = next
            next.takeIf { it.replacements <= 4 }
        } else null
        // The queue already selected the exact reader under queueLock. Do not
        // make that independent work wait for optional producer reporting.
        queueOffer.start?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }
        // Shadow only: these four scalar facts do not evaluate all H2 vetoes,
        // claim the mailbox, alter ordering or grant any presentation.
        val shadow = r41ShadowReceipt
        if (shadow != null && r41OfferNs != Long.MIN_VALUE && frameworkEvent && ingress?.externalSystemUi == true &&
            shadow.context.captureId == request.diagnosticContext?.captureId) {
            val original = queueOffer.activeAfter
            var facts = 0L
            if (original?.id == shadow.request && original.session == shadow.session &&
                original.wakeGeneration == shadow.wake) facts = facts or 1L
            if (queueOffer.pendingAfter?.id == request.id) facts = facts or 2L
            if (externalScene != null && externalScene != shadow.scene) facts = facts or 4L
            if (request.session == shadow.session && request.wakeGeneration == shadow.wake &&
                request.visibilityEpoch == shadow.visibility && request.interactionEpoch == shadow.interaction &&
                request.attachGeneration == shadow.attachment) facts = facts or 8L
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ORDERED_SHADOW_OFFER,
                shadow.context, shadow.request, request.id, facts, atNs = r41OfferNs)
        }
        if (r41OfferNs != Long.MIN_VALUE) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.OFFER,
            request.diagnosticContext, request.id, atNs = r41OfferNs)
        queueOffer.superseded?.let { old ->
            recordR25("SUPERSEDED", old.request, queueOffer.start, old.value.route,
                at = r41OfferUptime, readEnd = old.value.read.finishedAt, reason = "OFFER_BEFORE_CLAIM")
        }
        recoveryToReport?.let { next ->
            recordR14Recovery("REPLACED", next, request, queueOffer.pendingAfter,
                displaced = queueOffer.previousPending?.id, observedAt = r41OfferUptime)
        }
        traceKeyguard(
            if (startsWorker) "INSPECTION_QUEUED" else "INSPECTION_COALESCED",
            trigger,
            request,
            observedUptimeMs = r41OfferUptime,
            fields = mapOf(
                "queuedAtUptimeMs" to now,
                "triggerReceivedUptimeMs" to (request.triggerReceivedUptimeMs ?: "NA"),
                "eventTimeUptimeMs" to (request.eventTimeUptimeMs ?: "NA"),
                "replacedPendingRequestId" to (queueOffer.previousPending?.id ?: "NA"),
                "requestVisibilityEpoch" to request.visibilityEpoch,
                "requestInteractionEpoch" to request.interactionEpoch,
                "requestWakeGeneration" to request.wakeGeneration,
                "windowFreshness" to request.windowFreshness.name,
            ),
        )
        return request.id
    }

    private data class CompletedInspection(
        val request: KeyguardCardInspectionRequest,
        val result: Inspection,
        val startedAt: Long,
        val finishedAt: Long,
        // Frozen for the lifetime of this physical read. It selects queue
        // ordering only; current scene and disclosure are still checked on Main.
        val r38MilestoneOrdered: Boolean,
        val r42ReadOwner: R32DirectSnapshot?,
    ) {
        // Main sets this only after all mandatory restriction checks. The
        // worker uses it solely to recover if the promised successor vanished.
        var r42SuppressedPositive = false
    }

    private sealed interface InspectionOutcome {
        data class Completed(val inspection: Inspection) : InspectionOutcome
        data class Yielded(val successor: KeyguardCardInspectionRequest,
            val partial: SystemWindowsRead, val sceneAtRead: Long,
            val reason: KeyguardOpeningYieldReason) : InspectionOutcome
    }

    private sealed interface PhysicalReadOutcome {
        data class Completed(val read: CompletedInspection) : PhysicalReadOutcome
        data class Yielded(val request: KeyguardCardInspectionRequest,
            val successor: KeyguardCardInspectionRequest, val partial: SystemWindowsRead,
            val sceneAtRead: Long, val startedAt: Long, val finishedAt: Long,
            val reason: KeyguardOpeningYieldReason) : PhysicalReadOutcome
    }

    private data class InspectionHandoff(
        val diagnosticPreparationFinishedAt: Long,
        val requestedAt: Long,
        val requestedAtNs: Long,
    )

    private data class R25Completed(
        val read: CompletedInspection,
        val handoff: InspectionHandoff,
        val route: R25RouteSnapshot,
    )

    private data class R25QueueOffer(
        val start: KeyguardCardInspectionRequest?,
        val previousPending: KeyguardCardInspectionRequest?,
        val pendingAtOffer: KeyguardCardInspectionRequest?,
        val pendingAfter: KeyguardCardInspectionRequest?,
        val activeAfter: KeyguardCardInspectionRequest?,
        val superseded: KeyguardOpeningPublication.Ticket<R25Completed>?,
    )

    private sealed interface R25Completion {
        data class Stock(val reason: String, val route: R25RouteSnapshot?,
            val pending: KeyguardCardInspectionRequest?) : R25Completion
        data class Promote(val successor: KeyguardCardInspectionRequest, val route: R25RouteSnapshot) : R25Completion
        data class Park(val notice: KeyguardOpeningPublication.Notice?, val route: R25RouteSnapshot) : R25Completion
    }

    private data class R32OverlapPlan(
        val predecessor: KeyguardCardInspectionRequest,
        val successor: KeyguardCardInspectionRequest,
        val direct: R32DirectSnapshot,
        val readScene: Long,
        val currentScene: Long,
        val reservedAt: Long,
    )

    private enum class CompletedDisposition { NORMAL, R32_RESTRICTION_ONLY }

    private data class ReadAheadDecision(
        val snapshot: KeyguardReadAheadSnapshot?,
        val successor: KeyguardCardInspectionRequest?,
        val pendingId: Long?,
        val reason: String,
        val currentFreshnessRevision: Long?,
        val outstandingFreshness: KeyguardWindowFreshness?,
        val negativeFreshnessRevision: Long?,
        val r32Plan: R32OverlapPlan? = null,
    )

    /** Captured only during diagnostics. Both owner-bearing result fields are
     * stripped before a report can outlive the reader that produced it. */
    private data class R41DeferredInspectionReport(
        val read: CompletedInspection,
        val handoff: InspectionHandoff,
        val decision: ReadAheadDecision,
    )

    private fun finishR41Reports(reports: java.util.ArrayDeque<R41DeferredInspectionReport>?, discard: Boolean) {
        if (reports == null) return
        while (reports.isNotEmpty()) {
            val report = reports.removeFirst()
            try {
                if (!discard) traceCompletedInspection(report.read, report.handoff, report.decision)
            } finally {
                KeyguardCardDiagnostics.r41FinishReport(report.read.request.diagnosticContext, discarded = discard)
            }
        }
    }

    private fun readInspection(request: KeyguardCardInspectionRequest): PhysicalReadOutcome {
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WORKER, request.diagnosticContext, request.id)
        // Volatile pointer checks only before a first reveal. No optional
        // provenance, coordinator lock or allocation on opening reads.
        val visibleOwner = r18Active
        val visibleBinding = visibleOwner?.r40Acknowledged
        val r40Read = if (visibleOwner != null && visibleBinding != null) synchronized(queueLock) {
            val identity = visibleOwner.identity
            val state = r18Coordinator.snapshot()
            if (r18Active === visibleOwner && visibleOwner.r40Acknowledged === visibleBinding &&
                visibleOwner.r21Binding === visibleBinding && identity.token === visibleBinding.token &&
                visibleOwner.host === visibleBinding.reveal.host && visibleOwner.output === visibleBinding.reveal.output &&
                inspectionAuthority == visibleBinding.reveal.authority && inspectionAuthority.matches(request) &&
                state.reservation === identity.token && state.grant == KeyguardOrbPresentationCoordinator.Grant.PRESENTED &&
                r18Coordinator.revealOrdinal(visibleBinding.reveal) != null)
                R40Read(visibleOwner, identity, visibleBinding, inspectionAuthority, firstAuthorizedOrb.sceneSerial())
            else null
        } else null
        var r42ReadOwner: R32DirectSnapshot? = null
        val r38MilestoneOrdered = synchronized(queueLock) {
            r42ReadOwner = r34EmptyDirectLocked(request)
            r42ReadOwner != null || r37EarlyStampLocked(request) != null
        }
        val concurrent = activeInspectionCount.incrementAndGet()
        recordMaximum(maximumConcurrentInspections, concurrent)
        val (started, startedArm) = synchronized(queueLock) {
            val now = SystemClock.uptimeMillis()
            val screen = r442ScreenOn
            val arm = r446ReadArm
            r448StartedRequest = request.id
            r448StartedArm = arm?.takeIf { screen != null && screen.session == request.session &&
                now >= screen.uptime && it.session == request.session &&
                it.capture == request.diagnosticContext?.captureId }?.generation
            now to r448StartedArm
        }
        val claimedOpening = if (openingHandoff.claimedRequestId == request.id)
            synchronized(queueLock) {
                openingHandoff.successorStarted(request, started)?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
                openingHandoff.snapshotForSuccessor(request)?.takeIf { it.claimedId == request.id }
            } else null
        if (claimedOpening != null) recordOpeningAcquisition("B_START", request, claimedOpening, started)
        if (request.diagnosticContext?.captureId?.let { it == KeyguardCardDiagnostics.activeCaptureId() } == true) synchronized(queueLock) {
            openingHandoff.followCObservation(request, started, null)?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
        }
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.READ_START, request.id, request.attachGeneration)
        val result = try {
            inspectionProbeForTest?.openingOrderSelected(request, r38MilestoneOrdered)
            inspectionProbeForTest?.started(request)
            traceKeyguard("INSPECTION_STARTED", request.trigger, request, observedUptimeMs = started,
                fields = mapOf("queueMs" to (started - request.queuedAtUptimeMs),
                    "queuedAtUptimeMs" to request.queuedAtUptimeMs,
                    "authorityCurrentAtStart" to authorityIsCurrent(request)))
            if (r40Read != null) runCatching { inspectionProbeForTest?.r40ProvenanceStarted(request) }
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_START, request.diagnosticContext, request.id)
            inspectSurface(request, started, r38MilestoneOrdered, r40Read).also {
                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.READ_END, request.diagnosticContext, request.id)
            }
        } catch (failure: Throwable) {
            val cancelledAt = SystemClock.uptimeMillis()
            if (startedArm != null) request.diagnosticContext?.let { context ->
                runCatching { KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(
                    context, startedArm, request.id, request.queuedAtUptimeMs, started, cancelledAt,
                    "FAILED_${failure.javaClass.simpleName.take(40)}", "UNOBSERVED", authorityIsCurrent(request))) }
            }
            if (claimedOpening != null) synchronized(queueLock) {
                openingHandoff.successorFinished(request, cancelledAt, "CANCELLED")
                openingHandoff.followReadFinished(request, cancelledAt, null, "CANCELLED")
                    ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
            }
            if (request.diagnosticContext?.captureId?.let { it == KeyguardCardDiagnostics.activeCaptureId() } == true)
                synchronized(queueLock) {
                    openingHandoff.followCObservation(request, cancelledAt, "CANCELLED")
                        ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
                }
            throw failure
        } finally { activeInspectionCount.decrementAndGet() }
        val finished = SystemClock.uptimeMillis()
        if (startedArm != null) request.diagnosticContext?.let { context ->
            val completed = (result as? InspectionOutcome.Completed)?.inspection
            runCatching { KeyguardCardDiagnostics.recordR448Worker(KeyguardR448WorkerObservation(
                context, startedArm, request.id, request.queuedAtUptimeMs, started, finished,
                if (result is InspectionOutcome.Yielded) "YIELDED" else if (completed?.abortedStale == true) "STALE" else "COMPLETED",
                completed?.r446Eligibility?.reason ?: "UNOBSERVED", authorityIsCurrent(request))) }
        }
        val opening = if (openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
            openingHandoff.readFinished(request, finished)
            openingHandoff.snapshot(request.id)
        } else null
        if (opening != null) {
            val timing = when (result) {
                is InspectionOutcome.Completed -> result.inspection.windowTiming
                is InspectionOutcome.Yielded -> result.partial.timing
            }
            val phase = when (result) {
                is InspectionOutcome.Yielded -> "YIELDED"
                is InspectionOutcome.Completed -> if (result.inspection.abortedStale) "A_STALE" else "A_FINISHED"
            }
            recordOpeningAcquisition(phase, request, opening, finished, timing,
                (result as? InspectionOutcome.Completed)?.inspection)
        }
        if (result is InspectionOutcome.Yielded) {
            if (result.partial.r37Boundary?.startsWith("R442_") == true) {
                val context = request.diagnosticContext
                val screen = result.partial.r442ScreenAt
                val boundary = result.partial.r37ClaimAt
                if (context != null && screen != null && boundary != null)
                    KeyguardCardDiagnostics.recordR442Handoff(KeyguardR442HandoffObservation(
                        context, request.id, result.successor.id, screen, result.successor.queuedAtUptimeMs,
                        started, boundary, finished, result.partial.r37Boundary))
            }
            recordR34Read(request, result.partial.r34ReadOwner, "TRANSFER", started, finished,
                result.partial.r34InventoryAt, result.sceneAtRead, result.successor.id,
                result.partial.r37Boundary?.let { "R37_${it}@${result.partial.r37ClaimAt}" } ?: "SAFE_CHILD")
            if (claimedOpening != null) synchronized(queueLock) {
                openingHandoff.successorFinished(request, finished, "YIELDED_TO_C")
                openingHandoff.followReadFinished(request, finished, result.partial.timing.ingressCallEnd, "YIELDED_TO_C")
                    ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
            }
            if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.yielded(request.id)
            runCatching { inspectionProbeForTest?.yielded(request, result.successor, started, finished, result.partial.visitedNodeCount) }
            return PhysicalReadOutcome.Yielded(request, result.successor, result.partial, result.sceneAtRead, started, finished, result.reason)
        }
        val inspection = (result as InspectionOutcome.Completed).inspection
        recordR34Read(request, inspection.r34ReadOwner, "READ_END", started, finished,
            inspection.r34InventoryAt, inspection.r19ReadSceneSerial, outcome = when {
                inspection.r34PausedForOffer -> "PAUSED"
                inspection.abortedStale -> "STALE"
                inspection.rootUnavailable || inspection.walkTruncated || inspection.windowTiming.ownAttributionAmbiguous -> "INCOMPLETE"
                else -> inspection.decision.name
            })
        if (claimedOpening != null) {
            val closed = synchronized(queueLock) {
                openingHandoff.successorFinished(request, finished)
                openingHandoff.followReadFinished(request, finished, inspection.windowTiming.ingressCallEnd, "FINISHED")
                    ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
                openingHandoff.snapshotForSuccessor(request)?.takeIf {
                    it.openingId == claimedOpening.openingId &&
                        it.reservationId == claimedOpening.reservationId && it.claimedId == request.id
                }
            }
            if (closed != null) recordOpeningAcquisition("B_FINISHED", request, closed, finished,
                inspection.windowTiming, inspection, started)
        }
        if (request.diagnosticContext?.captureId?.let { it == KeyguardCardDiagnostics.activeCaptureId() } == true) synchronized(queueLock) {
            openingHandoff.followCObservation(request, finished,
                "${inspection.decision.name}/${inspection.surfaceReason.name}/${inspection.rootUnavailable}/${inspection.walkTruncated}/${inspection.abortedStale}")
                ?.let { KeyguardCardDiagnostics.recordR22PostClaim(it) }
        }
        // Order real completed reads even when a newer successor read ahead of
        // the preceding Main apply. No nodes or result objects are retained.
        firstAuthorizedOrb.readCompleted(request.id)
        runCatching { inspectionProbeForTest?.r447SampleReadCompleted(request, inspection.r446Eligibility, inspection.abortedStale) }
        val visibleOrArmed = r18Active?.let { owner -> owner.host?.let { r18Coordinator.mayAct(owner.token, it) } } == true
        val disqualifying = inspection.decision != KeyguardCardVisibility.SHOW_FULL &&
            inspection.decision != KeyguardCardVisibility.SHOW_DISCREET &&
            (inspection.decision != KeyguardCardVisibility.HIDDEN_UNKNOWN || visibleOrArmed)
        if (disqualifying && !inspection.abortedStale && authorityIsCurrent(request)) {
            val current = KeyguardInspectionAuthority(request.session, request.visibilityEpoch, request.wakeGeneration,
                request.interactionEpoch, request.attachGeneration)
            sealR18(current, request.id, inspection.surfaceReason.name)
        }
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.READ_END, request.id, request.attachGeneration)
        if (KeyguardR15AcquisitionTestHooks.ENABLED) {
            KeyguardR15AcquisitionTestHooks.outcome(request.id, inspection.decision, inspection.surfaceReason,
                authorityIsCurrent(request), started, finished)
        }
        inspectionProbeForTest?.readCompleted(request, inspection.decision, inspection.surfaceReason,
            inspection.rootUnavailable, inspection.walkTruncated, inspection.abortedStale, started, finished)
        return PhysicalReadOutcome.Completed(CompletedInspection(request, inspection, started, finished,
            r38MilestoneOrdered, r42ReadOwner))
    }

    private fun newInspectionHandoff(): InspectionHandoff {
        val prepared = SystemClock.uptimeMillis()
        return InspectionHandoff(prepared, SystemClock.uptimeMillis(), System.nanoTime())
    }

    /** All callers hold queueLock. A newer request must be a genuine service
     * ingress of the same owner and cannot inherit an unserved cache clear. */
    private fun r25CompatibleLocked(ticket: R25Completed, next: KeyguardCardInspectionRequest): Boolean {
        val route = r25SnapshotLocked(ticket.read.request) ?: return false
        val genuine = next.r14Ingress != null || when (next.trigger) {
            "window", "display", "wake", "accessibility" -> true
            else -> false
        }
        return route.backend == "STOCK" && ticket.route.backend == "STOCK" &&
            route == ticket.route && genuine && next.id > ticket.read.request.id &&
            route.authority.matches(next) && !next.windowFreshness.requiresCacheClear &&
            inspectionFreshness.isEstablished(route.authority, route.freshnessRevision)
    }

    private fun r25CompleteLocked(read: CompletedInspection, handoff: InspectionHandoff): R25Completion {
        r41R25EvaluationsForTest?.incrementAndGet()
        val request = read.request
        val result = read.result
        val pending = inspectionQueue.pendingRequest()
        val route = r25SnapshotLocked(request)
        fun bypass(reason: String) = R25Completion.Stock(reason, route, pending)
        if (route == null) return bypass("ROUTE_OR_STATE")
        if (!inspectionQueue.canPublishCompleted(request)) return bypass("ORDER_OR_OWNER")
        if (result.decision != KeyguardCardVisibility.SHOW_FULL || result.surfaceReason != KeyguardSurfaceReason.MAIN_CONFIRMED)
            return bypass("CLASSIFICATION")
        if (result.rootUnavailable || result.walkTruncated || result.abortedStale || result.windowTiming.ownAttributionAmbiguous)
            return bypass("INCOMPLETE_OR_AMBIGUOUS")
        if (!result.signals.systemStateAvailable || !result.signals.userUnlocked || !result.signals.primaryDisplay ||
            !result.signals.interactive || !result.signals.displayOn || !result.signals.keyguardLocked)
            return bypass("SYSTEM_INELIGIBLE")
        if (result.freshnessRevision != route.freshnessRevision || result.r19ReadSceneSerial == null ||
            !inspectionFreshness.isEstablished(route.authority, route.freshnessRevision)) return bypass("FRESHNESS_OR_SCENE")
        if (read.r38MilestoneOrdered) return bypass("DIRECT_ORDERED")
        if (!KeyguardOpeningRoutePolicy.useCompletedHandoff(route.backend)) return bypass("DIRECT_ORDERED")
        val ticket = R25Completed(read, handoff, route)
        if (pending != null) {
            if (!r25CompatibleLocked(ticket, pending)) return bypass("PENDING_INCOMPATIBLE")
            return inspectionQueue.handoffCompleted(request, pending)?.let { R25Completion.Promote(it, route) }
                ?: bypass("TRANSFER_CHANGED")
        }
        return r25Publication.park(inspectionQueue, request, ticket)?.let { R25Completion.Park(it.noticeToPost, route) }
            ?: bypass("TICKET_UNAVAILABLE")
    }

    private fun r25PromoteWaitingLocked(): KeyguardOpeningPublication.Superseded<R25Completed>? {
        val waiting = r25Publication.waitingTicket() ?: return null
        val pending = inspectionQueue.pendingRequest() ?: return null
        if (!r25CompatibleLocked(waiting.value, pending)) return null
        return r25Publication.supersede(inspectionQueue, waiting.request, pending)
    }

    /** A suppressed positive may have missed an exclusion. This coalesced
     * sampler check can withdraw but never schedules a positive inspection. */
    private fun r25RequestExclusionCheck(originalSession: Long) {
        if (!r25ExclusionPosted.compareAndSet(false, true)) return
        if (!mainHandler.post {
                r25ExclusionPosted.set(false)
                if (inspectionAuthority.serviceSession == originalSession && serviceJob.isActive)
                    requestSystemCheck("r25SuppressedPositive", evaluate = false)
            }) r25ExclusionPosted.set(false)
    }

    private fun recordR25(phase: String, request: KeyguardCardInspectionRequest,
                          successor: KeyguardCardInspectionRequest? = null,
                          route: R25RouteSnapshot? = null, at: Long? = null,
                          readEnd: Long? = null, reason: String = "UNOBSERVED") {
        val context = request.diagnosticContext ?: return
        if (context.captureId == null || context.captureId != KeyguardCardDiagnostics.activeCaptureId() ||
            !KeyguardCardDiagnostics.wantsEvent("R25_OPENING")) return
        val observed = at ?: SystemClock.uptimeMillis()
        val readerHigh = maximumConcurrentInspections.get()
        runCatching {
            traceKeyguard("R25_OPENING", phase, request, observedUptimeMs = observed,
                deferredFields = { mapOf("r25Backend" to (route?.backend ?: "UNOBSERVED"),
                    "r25Original" to request.id, "r25Successor" to (successor?.id ?: "UNOBSERVED"),
                    "r25ReadEnd" to (readEnd ?: "UNOBSERVED"), "r25Reason" to reason,
                    "r25SuccessorQueued" to (successor?.queuedAtUptimeMs ?: "UNOBSERVED"),
                    "r25ReaderHigh" to readerHigh,
                    "r25TicketHigh" to if (phase == "PARKED" || phase == "MAIN_CLAIM") 1 else "UNOBSERVED") })
        }
    }

    private fun r25PostDrain(notice: KeyguardOpeningPublication.Notice, request: KeyguardCardInspectionRequest) {
        // A test dispatcher may invoke the continuation reentrantly from the
        // reader. The actual claim and View admission always run on Main.
        val invoked = AtomicBoolean(false)
        val drain = Runnable {
            if (invoked.compareAndSet(false, true)) {
                if (Looper.myLooper() == Looper.getMainLooper()) r25DrainOnMain(notice)
                else if (!mainHandler.post { r25DrainOnMain(notice) }) r25FallbackDrain(notice)
            }
        }
        val posted = runCatching { r25MainDispatchForTest?.invoke(request, drain) ?: mainHandler.post(drain) }.getOrDefault(false)
        if (!posted && invoked.compareAndSet(false, true)) r25FallbackDrain(notice)
    }

    private fun r25FallbackDrain(notice: KeyguardOpeningPublication.Notice) {
        if (serviceJob.isActive) {
            // One existing ordered Main dispatch is the only live-owner fallback.
            inspectionScope.launch {
                try {
                    withContext(Dispatchers.Main.immediate) { r25DrainOnMain(notice) }
                } catch (failure: Exception) {
                    android.util.Log.e("FluviKeyguard", "R25 ordered Main dispatch failed", failure)
                    r25DiscardNoticeIfCurrent(notice)
                }
            }
        } else {
            r25DiscardNoticeIfCurrent(notice)
        }
    }

    private fun r25DiscardNoticeIfCurrent(notice: KeyguardOpeningPublication.Notice) {
        val discarded = synchronized(queueLock) {
            r25Publication.discardFailedNotice(inspectionQueue, notice)
        } ?: return
        recordR25("DISCARDED", discarded.ticket.request, discarded.successor, discarded.ticket.value.route,
            readEnd = discarded.ticket.value.read.finishedAt, reason = "MAIN_DISPATCH_FAILED")
        // Preserve a real successor and its freshness if the service still
        // lives; a dead session cannot start more work.
        discarded.successor?.takeIf { serviceJob.isActive }?.let { actual ->
            inspectionScope.launch { processInspectionQueue(actual) }
        }
    }

    private fun r25DrainOnMain(notice: KeyguardOpeningPublication.Notice) {
        val ticket = synchronized(queueLock) { r25Publication.claim(inspectionQueue, notice) } ?: return
        val completed = ticket.value
        val request = ticket.request
        try {
            val current = synchronized(queueLock) {
                r25SnapshotLocked(request) == completed.route &&
                    firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, completed.read.result.r19ReadSceneSerial)
            }
            recordR25("MAIN_CLAIM", request, route = completed.route, readEnd = completed.read.finishedAt,
                reason = if (current) "CURRENT" else "OBSOLETE")
            if (current) applyCompletedInspection(completed.read, completed.handoff)
            else {
                if (KeyguardCardDiagnostics.wantsEvent("INSPECTION_REJECTED"))
                    traceKeyguard("INSPECTION_REJECTED", "r25Obsolete", request,
                        fields = mapOf("rejectionReason" to "r25Obsolete"))
                r25RequestExclusionCheck(request.session)
            }
        } finally {
            val next = synchronized(queueLock) { r25Publication.finish(inspectionQueue, request) }
            if (next != null && serviceJob.isActive) inspectionScope.launch { processInspectionQueue(next) }
            scheduleR19Join()
        }
    }

    /** Main is still the only authority to accept an answer or mutate Views.
     * A stale speculative pair triggers normal reconciliation, never SHOW. */
    private fun applyCompletedInspection(
        read: CompletedInspection,
        handoff: InspectionHandoff,
        readAhead: KeyguardReadAheadSnapshot? = null,
        reservedSuccessor: KeyguardCardInspectionRequest? = null,
        disposition: CompletedDisposition = CompletedDisposition.NORMAL,
    ): Boolean {
        val entered = SystemClock.uptimeMillis()
        val enteredNs = System.nanoTime()
        val request = read.request
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.MAIN_ENTER, request.id, request.attachGeneration)
        inspectionProbeForTest?.beforeApply(request, read.result.decision)
        val reservationMatches = reservedSuccessor == null || synchronized(queueLock) {
            inspectionQueue.successorForPreceding(request) == reservedSuccessor
        }
        if (disposition == CompletedDisposition.NORMAL && readAhead != null &&
            (!reservationMatches || !readAheadStillCurrent(readAhead))) {
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REJECT, request.id, request.attachGeneration, extra = 1)
            traceKeyguard("INSPECTION_REJECTED", "readAheadAuthorityChanged", request,
                fields = mapOf("rejectionReason" to "readAheadAuthorityChanged"))
            preservePendingReconciliation("readAheadAuthorityChanged", requirePending = false)
            return false
        }
        applyInspection(
            inspection = read.result,
            request = request,
            inspectionStartedAt = read.startedAt,
            inspectionFinishedAt = read.finishedAt,
            diagnosticPreparationFinishedAt = handoff.diagnosticPreparationFinishedAt,
            mainHandoffRequestedAt = handoff.requestedAt,
            mainApplyEnteredAt = entered,
            mainHandoffRequestedAtNs = handoff.requestedAtNs,
            mainApplyEnteredAtNs = enteredNs,
            disposition = disposition,
            r42Read = read,
        )
        inspectionProbeForTest?.afterApply(request, read.result.decision)
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.MAIN_EXIT, request.id, request.attachGeneration)
        return true
    }

    private fun traceCompletedInspection(read: CompletedInspection, handoff: InspectionHandoff?,
                                         readAhead: ReadAheadDecision? = null) {
        inspectionProbeForTest?.let { probe -> runCatching { probe.beforeOptionalInspectionReport(read.request) } }
        traceInspectionResult(read.request, read.result, read.startedAt, read.finishedAt, handoff, readAhead)
    }

    private fun traceAbortedInspection(read: CompletedInspection) {
        mainHandler.post {
            if (::overlay.isInitialized && overlay.isAttached) requestSystemCheck("abortedInspection:${read.request.id}")
        }
        traceCompletedInspection(read, null)
        traceKeyguard("INSPECTION_REJECTED", "abortedStale", read.request,
            observedUptimeMs = read.finishedAt, fields = mapOf("rejectionReason" to "abortedStale"))
    }

    /** Scheduling eligibility only; this never grants visibility. Called under
     * queueLock and reads Main-published scalar identity, never a View or Binder. */
    private fun r34EmptyDirectLocked(request: KeyguardCardInspectionRequest): R32DirectSnapshot? {
        if (Build.VERSION.SDK_INT != 35 || !r18RouteEnabled || !inspectionAuthority.matches(request) ||
            !inspectionQueue.canPublishCompleted(request)) return null
        val published = r32MainSnapshot ?: return null
        val route = published.route
        val ahead = readAheadSnapshot ?: return null
        val state = r18Coordinator.snapshot()
        val token = published.reservation
        if (route.backend != "R18_DIRECT" || route != r25MainSnapshot || ahead != published.readAhead ||
            !ahead.detached || ahead.showInProgress || readAheadShowInProgress || r14Recovery != null ||
            token !== state.reservation || token.id != route.reservationId ||
            token.stamp.authority != inspectionAuthority || !token.stamp.full ||
            token.stamp.hostGeneration != route.hostGeneration || token.stamp.outputGeneration != route.outputGeneration ||
            r18RouteRevision != route.routeRevision || state.imageReady || state.proofRequestId != null ||
            state.grant != KeyguardOrbPresentationCoordinator.Grant.NONE ||
            (state.host != KeyguardOrbPresentationCoordinator.Host.NONE &&
                state.host != KeyguardOrbPresentationCoordinator.Host.INERT &&
                state.host != KeyguardOrbPresentationCoordinator.Host.READY) ||
            firstAuthorizedOrb.current() != null || r25Publication.waitingRequest() != null ||
            r25Publication.claimedRequest() != null || r18DrainBindings.any { it != null && !it.drained && it.token !== token }
        ) return null
        return published
    }

    /** Capture only a genuinely empty, unpublished reservation before the
     * first inventory. This cannot authorize presentation. */
    private fun r37EarlyStampLocked(request: KeyguardCardInspectionRequest): KeyguardR37ReservationStamp? {
        val early = r18ProvisionalWake ?: return null
        val ahead = readAheadSnapshot ?: return null
        val route = r18RouteSnapshot ?: return null
        val state = r18Coordinator.snapshot()
        if (Build.VERSION.SDK_INT != 35 || !r18RouteEnabled || r18Active != null ||
            early.firstRequestId != request.id || !early.targetAuthority.matches(request) ||
            inspectionAuthority != early.previousAuthority || ahead.authority != early.previousAuthority ||
            early.routeRevision != r18RouteRevision || route.preparation != early.preparation ||
            !early.preparation.full || !early.preparation.emptyAwaitingDisclosure ||
            !ahead.detached || ahead.showInProgress || readAheadShowInProgress || r14Recovery != null ||
            !inspectionQueue.canPublishCompleted(request) || state.reservation !== early.token || state.adopted ||
            state.host != KeyguardOrbPresentationCoordinator.Host.NONE || state.imageReady ||
            state.proofRequestId != null || state.grant != KeyguardOrbPresentationCoordinator.Grant.NONE ||
            firstAuthorizedOrb.current() != null || r25Publication.waitingRequest() != null ||
            r25Publication.claimedRequest() != null || r18DrainBindings.any { it != null && !it.drained }
        ) return null
        return KeyguardR37ReservationStamp(early.token, request.id, early.targetAuthority,
            readAheadStateRevision, early.routeRevision)
    }

    /** Resolve the exact pre-inventory reservation only after Main adopts it.
     * A changed revision, relock, replacement or outstanding pixel owner
     * leaves the original conservative path in charge. */
    private fun r37AdoptedOwnerLocked(request: KeyguardCardInspectionRequest,
                                      stamp: KeyguardR37ReservationStamp?): R32DirectSnapshot? {
        stamp ?: return null
        val owner = r34EmptyDirectLocked(request) ?: return null
        val active = r18Active ?: return null
        if (r18ProvisionalWake != null || active.token !== stamp.token ||
            !KeyguardR37Ownership.sameAdoption(stamp, owner.reservation, request.id,
                inspectionAuthority, readAheadStateRevision, r18RouteRevision)) return null
        return owner
    }

    private fun r34SameEmptyOwnerLocked(request: KeyguardCardInspectionRequest,
                                         original: R32DirectSnapshot): Boolean {
        val now = r34EmptyDirectLocked(request) ?: return false
        return now.reservation === original.reservation && now.route == original.route &&
            now.readAhead == original.readAhead
    }

    /** Scheduling only: the selected request still needs its own physical
     * read and every existing Main/final disclosure gate. No platform call or
     * diagnostic formatting is performed while the queue lock is held. */
    private class R42Precheck { var reason = 0L; var pending = 0L }

    private fun r42SelectBeforeReadLocked(scheduled: KeyguardCardInspectionRequest,
                                           trace: R42Precheck?): KeyguardCardInspectionRequest? {
        val owner = r34EmptyDirectLocked(scheduled) ?: run { trace?.reason = 1; return null }
        val active = r18Active ?: run { trace?.reason = 2; return null }
        val state = r18Coordinator.snapshot()
        if (r18ProvisionalWake != null || !state.adopted || active.token !== owner.reservation ||
            !active.preparation.emptyAwaitingDisclosure || !active.preparation.full) { trace?.reason = 3; return null }
        val latest = inspectionQueue.pendingRequest() ?: run { trace?.reason = 4; return null }
        trace?.pending = latest.id
        val scene = firstAuthorizedOrb.sceneSerial()
        if (!r42ActualLatestLocked(scheduled, latest, scene)) { trace?.reason = 5; return null }
        val ticket = inspectionFreshness.beforeRead(scheduled) ?: run { trace?.reason = 6; return null }
        if (inspectionFreshness.beforeRead(latest) != ticket ||
            !openingHandoff.canRetireUnstartedForR42(scheduled, owner.reservation)) { trace?.reason = 7; return null }
        val selected = inspectionQueue.selectUnstartedLatest(scheduled, latest, ticket.reason)
            ?: run { trace?.reason = 8; return null }
        openingHandoff.retireUnstartedForR42(scheduled, owner.reservation)
        trace?.reason = 9
        return selected
    }

    private fun r42ActualLatestLocked(request: KeyguardCardInspectionRequest,
                                      candidate: KeyguardCardInspectionRequest?, scene: Long): Boolean {
        val next = candidate ?: return false
        val event = next.r14Ingress ?: return false
        return inspectionQueue.pendingRequest() === next && next.id > request.id &&
            inspectionAuthority.matches(next) && next.r42SceneSerial == scene &&
            event.displayId == Display.DEFAULT_DISPLAY &&
            (event.origin == KeyguardR14Origin.SYSTEM_UI || event.origin == KeyguardR14Origin.AMBIGUOUS) &&
            event.callbackAt <= next.queuedAtUptimeMs && (event.eventAt == null || event.eventAt <= event.callbackAt)
    }

    private data class R42StaleSuccessor(val requestId: Long, val oldScene: Long,
                                         val currentScene: Long, val cause: Long)

    private fun r34ActualLatestLocked(request: KeyguardCardInspectionRequest,
                                      candidate: KeyguardCardInspectionRequest?, scene: Long): Boolean {
        val next = candidate ?: return false
        val event = next.r14Ingress ?: return false
        return inspectionQueue.pendingRequest() == next && next.id > request.id &&
            inspectionAuthority.matches(next) && next.r34SceneSerial == scene &&
            next.r32FrameworkIngressId == event.id && event.displayId == Display.DEFAULT_DISPLAY &&
            (event.origin == KeyguardR14Origin.SYSTEM_UI || event.origin == KeyguardR14Origin.AMBIGUOUS) &&
            event.callbackAt <= next.queuedAtUptimeMs && (event.eventAt == null || event.eventAt <= event.callbackAt)
    }

    private data class R34Superseded(val successor: KeyguardCardInspectionRequest?, val waiting: Boolean)

    /** Called only after the reader returned, or on Main before applying its
     * result. Restrictive/incomplete results retain their ordered handling. */
    private fun r34SupersedeCompletedLocked(read: CompletedInspection): R34Superseded? {
        val result = read.result
        val owner = result.r34ReadOwner ?: return null
        if (!r34SameEmptyOwnerLocked(read.request, owner)) return null
        val partialPause = result.r34PausedForOffer && result.abortedStale
        val completeFull = !result.abortedStale && result.decision == KeyguardCardVisibility.SHOW_FULL &&
            result.surfaceReason == KeyguardSurfaceReason.MAIN_CONFIRMED && !result.rootUnavailable &&
            !result.walkTruncated && !result.windowTiming.ownAttributionAmbiguous &&
            result.signals.systemStateAvailable && result.signals.userUnlocked && result.signals.primaryDisplay &&
            result.signals.interactive && result.signals.displayOn && !result.signals.displayOff &&
            result.signals.keyguardLocked
        if (!partialPause && !completeFull) return null
        val current = firstAuthorizedOrb.sceneSerial()
        val pending = inspectionQueue.pendingRequest()
        return when (KeyguardR34LatestScenePolicy.decide(result.r19ReadSceneSerial, current,
            emptyOwner = true, safeBoundary = true, restrictiveEvidence = false,
            pendingScene = pending?.r34SceneSerial,
            genuineCompatiblePending = r34ActualLatestLocked(read.request, pending, current))) {
            KeyguardR34LatestScenePolicy.Action.TRANSFER -> {
                val next = inspectionQueue.handoffCompleted(read.request, requireNotNull(pending)) ?: return null
                openingHandoff.invalidate()
                R34Superseded(next, waiting = false)
            }
            KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER -> {
                if (!inspectionQueue.parkObsoleteAfterRead(read.request)) return null
                openingHandoff.invalidate()
                R34Superseded(null, waiting = true)
            }
            KeyguardR34LatestScenePolicy.Action.KEEP_READING -> null
        }
    }

    /** Capture-qualified scalar milestones; fields are built on the reducer. */
    private fun recordR34Read(request: KeyguardCardInspectionRequest, owner: R32DirectSnapshot?,
                              phase: String, started: Long, finished: Long, inventory: Long?,
                              scene: Long?, successor: Long? = null, outcome: String? = null) {
        val exactOwner = owner ?: return
        val context = request.diagnosticContext ?: return
        if (context.captureId == null || context.captureId != KeyguardCardDiagnostics.activeCaptureId() ||
            !KeyguardCardDiagnostics.wantsEvent("R34_OPENING")) return
        traceKeyguard("R34_OPENING", phase, request, observedUptimeMs = finished, diagnosticContext = context,
            deferredFields = {
                mapOf("r34Request" to request.id, "r34Next" to (successor ?: "UNOBSERVED"),
                    "r34Reservation" to exactOwner.reservation.id, "r34Host" to (exactOwner.route.hostGeneration ?: "UNOBSERVED"),
                    "r34Output" to (exactOwner.route.outputGeneration ?: "UNOBSERVED"),
                    "r34Scene" to (scene ?: "UNOBSERVED"), "r34Inventory" to (inventory ?: "UNOBSERVED"),
                    "r34Start" to started, "r34End" to finished, "r34Outcome" to (outcome ?: "UNOBSERVED"),
                    "r34ReaderHigh" to maximumConcurrentInspections.get())
            })
    }

    private fun traceR34Superseded(read: CompletedInspection, result: R34Superseded) {
        recordR34Read(read.request, read.result.r34ReadOwner, if (result.waiting) "WAIT_OFFER" else "TRANSFER",
            read.startedAt, read.finishedAt, read.result.r34InventoryAt, read.result.r19ReadSceneSerial,
            result.successor?.id, if (read.result.r34PausedForOffer) "PARTIAL" else "STALE_POSITIVE")
        traceKeyguard("INSPECTION_REJECTED", if (result.waiting) "r34WaitForOffer" else "r34LatestOffered",
            read.request, observedUptimeMs = read.finishedAt,
            fields = mapOf("rejectionReason" to if (result.waiting) "r34WaitForOffer" else "r34LatestOffered",
                "successorRequestId" to (result.successor?.id ?: "UNOBSERVED")))
    }

    /** queueLock only: uses Main-published scalars plus the current queue and
     * coordinator, never Main-owned Views or platform calls. */
    private fun reserveR32SuccessorLocked(read: CompletedInspection,
                                          pending: KeyguardCardInspectionRequest?): R32OverlapPlan? {
        val next = pending ?: return null
        val published = r32MainSnapshot ?: return null
        val ahead = readAheadSnapshot ?: return null
        val freshness = inspectionFreshness.beforeRead(read.request) ?: return null
        val state = r18Coordinator.snapshot()
        val token = published.reservation
        val ingress = next.r14Ingress
        val currentScene = firstAuthorizedOrb.sceneSerial()
        val signals = read.result.signals
        val facts = KeyguardR32OverlapPolicy.Facts(
            first = read.request, successor = next, authority = inspectionAuthority,
            actualActive = inspectionQueue.activeRequest(), actualPending = inspectionQueue.pendingRequest(),
            noPreceding = inspectionQueue.canPublishCompleted(read.request),
            genuineFrameworkIngress = ingress != null && next.r32FrameworkIngressId != null &&
                next.r32FrameworkIngressId == ingress.id && ingress.callbackAt >= read.startedAt &&
                ingress.callbackAt <= next.queuedAtUptimeMs &&
                (ingress.eventAt == null || ingress.eventAt <= ingress.callbackAt),
            ingressDisplay = ingress?.displayId, ingressOrigin = ingress?.origin,
            detached = ahead.detached, noShowInProgress = !ahead.showInProgress,
            direct = published.route.backend == "R18_DIRECT", emptyAwaitingDisclosure = true,
            reservationCurrent = state.reservation === token && token.id == published.route.reservationId &&
                token.stamp.authority == inspectionAuthority && token.stamp.full &&
                token.stamp.hostGeneration == published.route.hostGeneration &&
                token.stamp.outputGeneration == published.route.outputGeneration,
            routeCurrent = r32MainSnapshot === published && ahead == published.readAhead &&
                r25MainSnapshot == published.route && r18RouteRevision == published.route.routeRevision,
            hostSafe = state.host == KeyguardOrbPresentationCoordinator.Host.NONE ||
                state.host == KeyguardOrbPresentationCoordinator.Host.INERT ||
                state.host == KeyguardOrbPresentationCoordinator.Host.READY,
            grantNone = state.grant == KeyguardOrbPresentationCoordinator.Grant.NONE,
            noPaintOrProof = state.proofRequestId == null && firstAuthorizedOrb.current() == null,
            noRecovery = true, // recovery invalidates the Main-published R32 snapshot under this lock
            noQueuedPublication = r25Publication.waitingRequest() == null && r25Publication.claimedRequest() == null,
            freshnessEstablished = inspectionFreshness.isEstablished(inspectionAuthority, freshness.revision) &&
                freshness.revision == published.route.freshnessRevision,
            firstFreshnessRevision = read.result.freshnessRevision, currentFreshnessRevision = freshness.revision,
            completeFullMain = read.result.decision == KeyguardCardVisibility.SHOW_FULL &&
                read.result.surfaceReason == KeyguardSurfaceReason.MAIN_CONFIRMED && !read.result.rootUnavailable &&
                !read.result.walkTruncated && !read.result.abortedStale,
            systemEligible = signals.requested && signals.serviceConnected && signals.systemStateAvailable &&
                signals.userUnlocked && signals.primaryDisplay && signals.interactive && signals.displayOn &&
                !signals.displayOff && signals.keyguardLocked,
            ownUnambiguous = !read.result.windowTiming.ownAttributionAmbiguous,
            readScene = read.result.r19ReadSceneSerial, currentScene = currentScene,
        )
        if (KeyguardR32OverlapPolicy.rejection(facts) != null) return null
        val reserved = inspectionQueue.reserveSuccessor(read.request) { it == next } ?: return null
        return R32OverlapPlan(read.request, reserved, published, requireNotNull(facts.readScene), currentScene, 0L)
    }

    /** Capture only scalar pair identity/times; reduction and formatting stay
     * on the existing bounded diagnostic consumer. */
    private fun recordR32(plan: R32OverlapPlan, phase: String, at: Long,
                          pendingId: Long? = null, outcome: String? = null,
                          readScene: Long? = null) {
        val context = plan.predecessor.diagnosticContext ?: return
        if (context.captureId == null || context.captureId != KeyguardCardDiagnostics.activeCaptureId() ||
            !KeyguardCardDiagnostics.wantsEvent("R32_OVERLAP")) return
        runCatching {
            traceKeyguard("R32_OVERLAP", phase, plan.predecessor, observedUptimeMs = at,
                diagnosticContext = context, deferredFields = {
                    mapOf("r32A" to plan.predecessor.id, "r32B" to plan.successor.id,
                        "r32C" to (pendingId ?: "UNOBSERVED"), "r32Reservation" to plan.direct.reservation.id,
                        "r32ReadScene" to plan.readScene, "r32CurrentScene" to plan.currentScene,
                        "r32Reserve" to plan.reservedAt, "r32Backend" to "R18_DIRECT",
                        "r32Outcome" to (outcome ?: "UNOBSERVED"),
                        "r32BScene" to (readScene ?: "UNOBSERVED"))
                })
        }
    }

    /** Revalidation happens after A's ordered Main handling and after B's
     * physical read, before any positive result is applied. */
    private fun r32PositiveStillCurrentLocked(plan: R32OverlapPlan, read: CompletedInspection): Boolean {
        val state = r18Coordinator.snapshot()
        return inspectionQueue.activeRequest() == plan.successor && inspectionQueue.pendingRequest() == null &&
            inspectionAuthority == plan.direct.readAhead.authority &&
            readAheadSnapshot == plan.direct.readAhead && r32MainSnapshot === plan.direct &&
            plan.direct.sceneSerial == firstAuthorizedOrb.sceneSerial() && r25MainSnapshot == plan.direct.route && r18RouteRevision == plan.direct.route.routeRevision &&
            state.reservation === plan.direct.reservation &&
            state.grant == KeyguardOrbPresentationCoordinator.Grant.NONE && state.proofRequestId == null &&
            (state.host == KeyguardOrbPresentationCoordinator.Host.NONE ||
                state.host == KeyguardOrbPresentationCoordinator.Host.INERT ||
                state.host == KeyguardOrbPresentationCoordinator.Host.READY) &&
            firstAuthorizedOrb.current() == null &&
            read.result.surfaceReason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
            !read.result.rootUnavailable && !read.result.walkTruncated && !read.result.abortedStale &&
            !read.result.windowTiming.ownAttributionAmbiguous &&
            read.result.signals.systemStateAvailable && read.result.signals.userUnlocked &&
            read.result.signals.primaryDisplay && read.result.signals.interactive &&
            read.result.signals.displayOn && !read.result.signals.displayOff && read.result.signals.keyguardLocked &&
            inspectionFreshness.isEstablished(inspectionAuthority, plan.direct.route.freshnessRevision) &&
            read.result.freshnessRevision == plan.direct.route.freshnessRevision &&
            firstAuthorizedOrb.isUnclaimedReadCurrent(read.request.id, read.result.r19ReadSceneSerial)
    }

    private suspend fun processR32Overlap(read: CompletedInspection, handoff: InspectionHandoff,
                                          plan: R32OverlapPlan): KeyguardCardInspectionRequest? = coroutineScope {
        val earlier = plan.predecessor
        val successor = plan.successor
        var precedingReleased = false
        var completed = false
        recordR32(plan, "RESERVED", plan.reservedAt)
        try {
            val earlierApply = async(Dispatchers.Main) {
                r32AwaitApplyGateForTest(earlier)
                recordR32(plan, "A_MAIN_ENTER", SystemClock.uptimeMillis())
                try {
                    applyCompletedInspection(read, handoff, disposition = CompletedDisposition.R32_RESTRICTION_ONLY)
                } finally {
                    recordR32(plan, "A_MAIN_EXIT", SystemClock.uptimeMillis(), outcome = "RESTRICTION_ONLY")
                }
            }
            recordR32(plan, "B_READ_START", SystemClock.uptimeMillis())
            val successorOutcome = readInspection(successor)
            val bEnd = when (successorOutcome) {
                is PhysicalReadOutcome.Completed -> successorOutcome.read.finishedAt
                is PhysicalReadOutcome.Yielded -> successorOutcome.finishedAt
            }
            val pendingAtFinish = synchronized(queueLock) { inspectionQueue.pendingRequest()?.id }
            val bScene = (successorOutcome as? PhysicalReadOutcome.Completed)?.read?.result?.r19ReadSceneSerial
            recordR32(plan, "B_READ_END", bEnd, pendingAtFinish,
                if (successorOutcome is PhysicalReadOutcome.Completed) successorOutcome.read.result.decision.name else "UNEXPECTED_YIELD", bScene)
            earlierApply.await()
            traceCompletedInspection(read, handoff)
            precedingReleased = synchronized(queueLock) { inspectionQueue.finishPrecedingExact(earlier, successor) }
            if (!precedingReleased) {
                recordR32(plan, "PAIR_LOST", SystemClock.uptimeMillis())
                completed = true
                return@coroutineScope null
            }
            var reconcile = false
            when (successorOutcome) {
                is PhysicalReadOutcome.Yielded -> {
                    // reserveSuccessor excludes another opening transfer while
                    // the predecessor exists. Never rename B as its successor.
                    recordR32(plan, "B_REJECTED", SystemClock.uptimeMillis(), outcome = "UNEXPECTED_YIELD")
                    reconcile = true
                }
                is PhysicalReadOutcome.Completed -> {
                    val successorRead = successorOutcome.read
                    if (successorRead.result.abortedStale) {
                        traceAbortedInspection(successorRead)
                        reconcile = true
                    } else {
                        val positive = successorRead.result.decision == KeyguardCardVisibility.SHOW_FULL ||
                            successorRead.result.decision == KeyguardCardVisibility.SHOW_DISCREET
                        val nextHandoff = newInspectionHandoff()
                        // Revalidate at Main entry, not before posting to Main: a real
                        // C, withdrawal, or route change can arrive during dispatch.
                        // Negative evidence always takes the ordinary ordered path.
                        val applied = withContext(Dispatchers.Main.immediate) {
                            val current = !positive || synchronized(queueLock) {
                                r32PositiveStillCurrentLocked(plan, successorRead)
                            }
                            if (!current) false else {
                                applyCompletedInspection(successorRead, nextHandoff)
                                true
                            }
                        }
                        if (!applied) {
                            traceCompletedInspection(successorRead, null)
                            recordR32(plan, "B_REJECTED", SystemClock.uptimeMillis(), outcome = "REVALIDATION")
                            reconcile = true
                        } else {
                            traceCompletedInspection(successorRead, nextHandoff)
                            // Reaching the ordered Main path is not proof that it
                            // granted or displayed B; existing proof records own that.
                            recordR32(plan, "B_MAIN_PATH", SystemClock.uptimeMillis(), outcome = successorRead.result.decision.name)
                        }
                    }
                }
            }
            // If no real newer request exists, use the established Main-owned
            // reconciliation path; an actual pending C must never be replaced.
            if (reconcile) withContext(Dispatchers.Main.immediate) {
                val noPending = synchronized(queueLock) { inspectionQueue.pendingRequest() == null }
                if (noPending) preservePendingReconciliation("r32Successor", requirePending = false)
            }
            val next = synchronized(queueLock) { inspectionQueue.complete(successor) }
            completed = true
            next
        } finally {
            if (!completed) {
                val cleanup = synchronized(queueLock) {
                    val exact = precedingReleased || inspectionQueue.finishPrecedingExact(earlier, successor)
                    if (exact && inspectionQueue.canPublishCompleted(successor))
                        true to inspectionQueue.complete(successor) else false to null
                }
                if (cleanup.first && serviceJob.isActive) {
                    if (cleanup.second != null) inspectionScope.launch { processInspectionQueue(requireNotNull(cleanup.second)) }
                    else mainHandler.post {
                        if (serviceJob.isActive && inspectionAuthority == plan.direct.readAhead.authority)
                            requestSystemCheck("r32PairCancelled", evaluate = true)
                    }
                }
            }
        }
    }

    private suspend fun processInspectionQueue(first: KeyguardCardInspectionRequest) {
        var request: KeyguardCardInspectionRequest? = first
        var promotedOwner: KeyguardCardInspectionRequest? = null
        var r41DeferredReports: java.util.ArrayDeque<R41DeferredInspectionReport>? = null
        try {
        while (request != null) {
            val scheduled = request ?: break
            val r42Trace = if (scheduled.diagnosticContext?.captureId?.let {
                    it == KeyguardCardDiagnostics.activeCaptureId()
                } == true) R42Precheck() else null
            val selected = synchronized(queueLock) { r42SelectBeforeReadLocked(scheduled, r42Trace) }
            if (selected != null) {
                // Publish the new exact owner before any observer or possible
                // cancellation can unwind this coroutine.
                request = selected
                promotedOwner = selected
                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_PRESTART,
                    scheduled.diagnosticContext, scheduled.id, selected.id,
                    selected.windowFreshness.ordinal.toLong() + 1L +
                        (if (selected.r42FrameworkEvent) 16L else 0L) +
                        32L * (selected.r14Ingress?.origin?.ordinal ?: 0))
            }
            if (r42Trace != null) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_PRECHECK,
                scheduled.diagnosticContext, scheduled.id, r42Trace.pending, r42Trace.reason)
            val active = selected ?: scheduled
            val physical = readInspection(active)
            if (physical is PhysicalReadOutcome.Yielded) {
                promotedOwner = physical.successor
                request = physical.successor
                continue
            }
            var read = (physical as PhysicalReadOutcome.Completed).read
            val superseded = if (read.r38MilestoneOrdered) null else
                synchronized(queueLock) { r34SupersedeCompletedLocked(read) }
            if (superseded != null) {
                traceCompletedInspection(read, null)
                traceR34Superseded(read, superseded)
                promotedOwner = superseded.successor
                request = superseded.successor
                continue
            }
            if (read.result.r34PausedForOffer) {
                // Eligibility changed while nodes were being released: send an
                // ordered UNKNOWN, never discard evidence for a now-live owner.
                read = read.copy(result = read.result.copy(abortedStale = false, walkTruncated = true,
                    r34PausedForOffer = false))
            }
            if (read.result.abortedStale) {
                val next = synchronized(queueLock) { inspectionQueue.complete(active) }
                if (promotedOwner == active) promotedOwner = null
                traceAbortedInspection(read)
                request = next
                continue
            }
            val decision = synchronized(queueLock) {
                val snapshot = readAheadSnapshot
                val freshness = snapshot?.let { inspectionFreshness.beforeRead(active) }
                val negative = KeyguardReadAheadNegative(read.result.decision, read.result.surfaceReason,
                    read.result.rootUnavailable, read.result.walkTruncated, read.result.abortedStale,
                    read.result.freshnessRevision)
                val pending = inspectionQueue.pendingRequest()
                val reason = when {
                    pending == null -> "noPending"
                    snapshot == null -> "snapshotUnavailable"
                    freshness == null -> "authority"
                    else -> KeyguardReadAheadPolicy.rejection(snapshot, negative, active, pending,
                        freshness.revision, freshness.reason)
                }
                val successor = if (reason != "eligible" || snapshot == null || freshness == null) null else
                    inspectionQueue.reserveSuccessor(active) { candidate ->
                        KeyguardReadAheadPolicy.permits(snapshot, negative, active, candidate,
                            freshness.revision, freshness.reason)
                    }
                // The empty R34 owner has one physical reader and no competing
                // R32 positive A/B Main owner.
                val r32 = if (!read.r38MilestoneOrdered && successor == null && r34EmptyDirectLocked(active) == null)
                    reserveR32SuccessorLocked(read, pending) else null
                ReadAheadDecision(snapshot, successor ?: r32?.successor, pending?.id,
                    when {
                        r32 != null -> "r32Eligible"
                        reason == "eligible" && successor == null -> "reservationLost"
                        else -> reason
                    }, freshness?.revision, freshness?.reason, negative.freshnessRevision, r32)
            }
            inspectionProbeForTest?.readAheadDecision(active, decision.pendingId, decision.successor?.id,
                decision.reason, decision.snapshot, decision.currentFreshnessRevision,
                decision.outstandingFreshness, decision.negativeFreshnessRevision)
            val handoff = newInspectionHandoff()
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HANDOFF, active.id, active.attachGeneration)
            val r32Plan = decision.r32Plan?.copy(reservedAt = SystemClock.uptimeMillis())
            if (r32Plan != null) {
                request = processR32Overlap(read, handoff, r32Plan)
                if (promotedOwner == active) promotedOwner = null
                scheduleR19Join()
                continue
            }
            if (decision.successor == null || decision.snapshot == null) {
                // This choice was frozen for the physical read. Every R25
                // outcome for this ordered route is Stock, so preserve its
                // existing Main application without rebuilding an R25 route.
                // Negative/read-ahead reservations above remain unchanged.
                if (!read.r38MilestoneOrdered) {
                when (val opening = synchronized(queueLock) { r25CompleteLocked(read, handoff) }) {
                    is R25Completion.Promote -> {
                        traceCompletedInspection(read, null)
                        recordR25("SUPERSEDED", active, opening.successor, opening.route, readEnd = read.finishedAt,
                            reason = "PENDING_AT_COMPLETION")
                        r25RequestExclusionCheck(active.session)
                        promotedOwner = opening.successor
                        request = opening.successor
                        continue
                    }
                    is R25Completion.Park -> {
                        traceCompletedInspection(read, if (opening.notice != null) handoff else null)
                        recordR25("PARKED", active, route = opening.route, readEnd = read.finishedAt,
                            reason = if (opening.notice != null) "AWAITING_MAIN" else "COALESCED_MAIN_NOTICE")
                        opening.notice?.let {
                            recordR25("POST_REQUESTED", active, route = opening.route, readEnd = read.finishedAt)
                            r25PostDrain(it, active)
                        }
                        if (promotedOwner == active) promotedOwner = null
                        request = null
                        continue
                    }
                    is R25Completion.Stock -> if (read.result.decision == KeyguardCardVisibility.SHOW_FULL)
                        recordR25("BYPASS", active, opening.pending, opening.route, readEnd = read.finishedAt,
                            reason = opening.reason)
                }
                } else {
                    KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ORDERED_BYPASS,
                        active.diagnosticContext, active.id)
                }
                val r41CaptureId = active.diagnosticContext?.captureId
                val r41CaptureEnabled = r41CaptureId != null && r41CaptureId == KeyguardCardDiagnostics.activeCaptureId()
                val scene = read.result.r19ReadSceneSerial
                if (r41CaptureEnabled && read.r38MilestoneOrdered && scene != null &&
                    read.result.decision == KeyguardCardVisibility.SHOW_FULL &&
                    read.result.surfaceReason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
                    !read.result.rootUnavailable && !read.result.walkTruncated && !read.result.abortedStale &&
                    !read.result.windowTiming.ownAttributionAmbiguous) {
                    r41ShadowReceipt = R41ShadowReceipt(active.id, active.session, active.wakeGeneration,
                        active.visibilityEpoch, active.interactionEpoch, active.attachGeneration, scene,
                        requireNotNull(active.diagnosticContext))
                }
                val r41DispatchTid = if (r41CaptureEnabled) android.os.Process.myTid().toLong() else 0L
                val r41DispatchNs = if (r41CaptureEnabled) System.nanoTime() else Long.MIN_VALUE
                val lateSuperseded = try { withContext(Dispatchers.Main.immediate) {
                    if (r41ShadowReceipt?.request == active.id) r41ShadowReceipt = null
                    if (r41DispatchNs != Long.MIN_VALUE) {
                        val r41MainNs = System.nanoTime()
                        val r41MainTid = android.os.Process.myTid().toLong()
                        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.DISPATCH, active.diagnosticContext,
                            active.id, atNs = r41DispatchNs, tid = r41DispatchTid)
                        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.MAIN, active.diagnosticContext,
                            active.id, atNs = r41MainNs, tid = r41MainTid)
                    }
                    r32AwaitApplyGateForTest(active)
                    val latest = if (read.r38MilestoneOrdered) null else
                        synchronized(queueLock) { r34SupersedeCompletedLocked(read) }
                    if (latest == null) applyCompletedInspection(read, handoff)
                    latest
                } } finally {
                    if (r41ShadowReceipt?.request == active.id) r41ShadowReceipt = null
                }
                if (lateSuperseded != null) {
                    traceCompletedInspection(read, null)
                    traceR34Superseded(read, lateSuperseded)
                    promotedOwner = lateSuperseded.successor
                    request = lateSuperseded.successor
                    continue
                }
                var r41ReservedReport = false
                request = synchronized(queueLock) {
                    val next = inspectionQueue.complete(active)
                    if (next != null) r41ReservedReport = KeyguardCardDiagnostics.r41ReserveReport(active.diagnosticContext)
                    next
                }
                if (promotedOwner == active) promotedOwner = null
                if (read.r42SuppressedPositive && request == null && serviceJob.isActive) mainHandler.post {
                    if (serviceJob.isActive && inspectionAuthority.matches(active))
                        requestSystemCheck("r42SuccessorLost", evaluate = true)
                }
                scheduleR19Join()
                if (r41ReservedReport) {
                    val reports = r41DeferredReports ?: java.util.ArrayDeque<R41DeferredInspectionReport>().also { r41DeferredReports = it }
                    if (reports.size < 16) {
                        val safeResult = if (read.result.r34ReadOwner == null && read.result.r40Read == null) read.result
                            else read.result.copy(r34ReadOwner = null, r40Read = null)
                        reports.addLast(R41DeferredInspectionReport(read.copy(result = safeResult), handoff,
                            decision.copy(r32Plan = null)))
                    } else KeyguardCardDiagnostics.r41FinishReport(active.diagnosticContext, discarded = true)
                } else {
                    finishR41Reports(r41DeferredReports, discard = false)
                    r41DeferredReports = null
                    traceCompletedInspection(read, handoff, decision)
                }
                continue
            }

            // Only B may use the one physical reader while A waits for its
            // ordered Main apply. C remains a single coalesced pending item.
            val snapshot = decision.snapshot
            val successor = decision.successor
            val next = coroutineScope {
                val earlierApply = async(Dispatchers.Main) {
                    r32AwaitApplyGateForTest(active)
                    applyCompletedInspection(read, handoff, snapshot, successor)
                }
                val successorOutcome: PhysicalReadOutcome
                val earlierAccepted = try {
                    successorOutcome = readInspection(successor)
                    earlierApply.await()
                } finally {
                    synchronized(queueLock) { inspectionQueue.finishPreceding(active) }
                }
                traceCompletedInspection(read, handoff, decision)
                when (successorOutcome) {
                    is PhysicalReadOutcome.Yielded -> {
                        // The queue refuses this while an R12 predecessor is
                        // present. Preserve the exact promoted owner if a
                        // future caller nevertheless reaches this boundary.
                        successorOutcome.successor
                    }
                    is PhysicalReadOutcome.Completed -> {
                        val successorRead = successorOutcome.read
                        if (successorRead.result.abortedStale) {
                            traceAbortedInspection(successorRead)
                        } else if (!earlierAccepted) {
                            traceCompletedInspection(successorRead, null)
                            traceKeyguard("INSPECTION_REJECTED", "readAheadPredecessorRejected", successor,
                                fields = mapOf("rejectionReason" to "readAheadPredecessorRejected"))
                        } else {
                            val nextHandoff = newInspectionHandoff()
                            withContext(Dispatchers.Main.immediate) {
                                applyCompletedInspection(successorRead, nextHandoff, snapshot)
                            }
                            traceCompletedInspection(successorRead, nextHandoff)
                        }
                        synchronized(queueLock) { inspectionQueue.complete(successor) }
                    }
                }
            }
            request = next
            if (promotedOwner == active) promotedOwner = null
            scheduleR19Join()
        }
        } finally {
            if (!serviceJob.isActive) synchronized(queueLock) {
                val owner = promotedOwner
                if (owner != null && !inspectionQueue.abandonSessionIfActive(owner))
                    inspectionQueue.abandonOpeningTransferIfActive(owner)
                request?.takeIf { it != owner }?.let { inspectionQueue.abandonOpeningTransferIfActive(it) }
            } else {
                // Exceptions or coroutine cancellation cannot strand the
                // single reader or discard a handoff already claimed during
                // node recycling. Do not create a replacement positive result.
                val owner = request ?: promotedOwner
                val recovery = owner?.let { old -> synchronized(queueLock) { inspectionQueue.recoverUnwoundReader(old) } }
                if (recovery != null && owner != null && serviceJob.isActive) {
                    val next = recovery.next
                    if (next != null) inspectionScope.launch { processInspectionQueue(next) }
                    else mainHandler.post {
                        if (serviceJob.isActive && inspectionAuthority.matches(owner))
                            requestSystemCheck("r34ReaderCancelled", evaluate = true)
                    }
                }
            }
            finishR41Reports(r41DeferredReports, discard = request != null || promotedOwner != null)
        }
    }

    /** Capture ownership and primitive times are copied before enqueueing;
     * no accessibility node, View or mutable worker state enters diagnostics. */
    private fun recordOpeningAcquisition(phase: String, request: KeyguardCardInspectionRequest,
        opening: KeyguardOpeningInspectionHandoff.Snapshot, at: Long,
        timing: KeyguardWindowSnapshotReader.Timing? = null, result: Inspection? = null,
        bStartedAt: Long? = null) {
        val originalContext = opening.diagnosticContext ?: return
        if (originalContext.captureId == null || originalContext.captureId != KeyguardCardDiagnostics.activeCaptureId() ||
            !KeyguardCardDiagnostics.wantsEvent("R22_ACQUISITION")) return
        runCatching { traceKeyguard("R22_ACQUISITION", phase, request, observedUptimeMs = at,
            diagnosticContext = originalContext, deferredFields = { mapOf(
                "r22Opening" to opening.openingId, "r22Reservation" to opening.reservationId,
                "r22AStart" to (opening.startedAt ?: "UNOBSERVED"),
                "r22Scene" to (opening.sceneAtRead ?: "UNOBSERVED"),
                "r22IngressAt" to (opening.firstIngressAt ?: "UNOBSERVED"),
                "r22IngressScene" to (opening.firstIngressScene ?: "UNOBSERVED"),
                "r22FirstOffer" to (opening.firstOfferedId ?: "UNOBSERVED"),
                "r22FirstOfferAt" to (opening.firstOfferedAt ?: "UNOBSERVED"),
                "r22LatestOffer" to (opening.latestOfferedId ?: "UNOBSERVED"),
                "r22LatestOfferAt" to (opening.latestOfferedAt ?: "UNOBSERVED"),
                "r22Framework" to (opening.latestFrameworkEvent ?: "UNOBSERVED"),
                "r22IngressId" to (opening.latestIngressId ?: "UNOBSERVED"),
                "r22EventType" to (opening.latestEventType ?: "UNOBSERVED"),
                "r22Display" to (opening.latestDisplay ?: "UNOBSERVED"),
                "r22EventAt" to (opening.latestEventAt ?: "UNOBSERVED"),
                "r22Replaced" to (opening.replacedId ?: "UNOBSERVED"),
                "r22Replacement" to (opening.replacementId ?: "UNOBSERVED"),
                "r22Claimed" to (opening.claimedId ?: "UNOBSERVED"),
                "r22ClaimAt" to (opening.claimedAt ?: "UNOBSERVED"),
                "r22AEnd" to (opening.completedAt ?: "UNOBSERVED"),
                "r27FirstIncomplete" to (timing?.firstIncompleteReason?.name ?: "UNOBSERVED"),
                "r27YieldReason" to (timing?.openingYieldReason?.name ?: "UNOBSERVED"),
                "r27Checks" to opening.incompleteChecks, "r27Eligible" to opening.incompleteEligible,
                "r27Rejected" to opening.incompleteRejected, "r27Yielded" to opening.incompleteYielded,
                "r27FirstReject" to (opening.firstIncompleteRejection ?: "UNOBSERVED"),
                "r22Checkpoint" to (opening.lastCheckpoint ?: "UNOBSERVED"),
                "r22CheckpointAt" to (opening.lastCheckpointAt ?: "UNOBSERVED"),
                "r22Visited" to (opening.checkpointVisited ?: "UNOBSERVED"),
                "r22Roots" to (opening.checkpointRoots ?: "UNOBSERVED"),
                "r22Children" to (opening.checkpointChildren ?: "UNOBSERVED"),
                "r22Why" to (opening.lastReason ?: "UNOBSERVED"),
                "r22Call" to (timing?.ingressCallKind ?: "UNOBSERVED"),
                "r22CallBegin" to (timing?.ingressCallBegin ?: "UNOBSERVED"),
                "r22CallEnd" to (timing?.ingressCallEnd ?: "UNOBSERVED"),
                "r22BStart" to (bStartedAt ?: if (phase == "B_START") at else "UNOBSERVED"),
                "r22BEnd" to (if (phase == "B_FINISHED") at else "UNOBSERVED"),
                "r22Decision" to (result?.decision?.name ?: "UNOBSERVED"),
                "r22Reason" to (result?.surfaceReason?.name ?: "UNOBSERVED"),
                "r22Incomplete" to (result?.let { "${it.rootUnavailable}/${it.walkTruncated}/${it.abortedStale}" } ?: "UNOBSERVED"),
                "r22AFirstRoot" to (timing?.originalOpening?.let { e ->
                    "${e.rootWindow ?: "NA"}/${e.rootStrategy ?: "NA"}/${e.rootFlags ?: "NA"}/${timing.acceptedChildPrefetchFlags ?: "NA"}"
                } ?: "UNOBSERVED"),
                "r22AFirstChild" to (timing?.originalOpening?.let { e ->
                    "${e.firstOrdinal ?: "NA"}/${e.firstDepth ?: "NA"}/${e.firstParentOrdinal ?: "NA"}/${e.firstIndex ?: "NA"}/${e.firstResult ?: "NA"}"
                } ?: "UNOBSERVED"),
                "r22AInvalid" to (timing?.originalOpening?.let { e ->
                    "${e.invalidOrdinal ?: "NA"}/${e.invalidDepth ?: "NA"}/${e.invalidParentOrdinal ?: "NA"}/${e.invalidIndex ?: "NA"}/${e.invalidKind ?: "NA"}/${e.exceptionClass?.take(32) ?: "NA"}"
                } ?: "UNOBSERVED"),
                "r22ACheckpoint" to (timing?.originalOpening?.let { e ->
                    "${e.checkpointInstalled}/${e.checkpointState ?: "UNOBSERVED"}/${e.checkpointWindow ?: "NA"}/${e.checkpointIndex ?: "NA"}"
                } ?: "UNOBSERVED"),
                "r22ADecisive" to (timing?.originalOpening?.decisiveMarker ?: "UNOBSERVED"),
            ) }) }
    }

    /** Capture immutable results, build verbose fields on the diagnostic
     * consumer. No reduction/formatting runs ahead of the next tree walk. */
    private fun traceInspectionResult(
        request: KeyguardCardInspectionRequest,
        originalResult: Inspection,
        startedAt: Long,
        finishedAt: Long,
        handoff: InspectionHandoff?,
        readAhead: ReadAheadDecision?,
    ) {
        if (!KeyguardCardDiagnostics.wantsEvent("INSPECTION_FINISHED")) return
        // The R40 read owner can retain Views. Only this stripped immutable
        // technical result may cross into the diagnostic consumer.
        val result = if (originalResult.r34ReadOwner == null && originalResult.r40Read == null) originalResult
            else originalResult.copy(r34ReadOwner = null, r40Read = null)
        val r12Reason = readAhead?.reason
        val r12Pending = readAhead?.pendingId
        val r12Reserved = readAhead?.successor?.id
        val r12Revision = readAhead?.snapshot?.freshnessRevision
        val appContext = applicationContext
        val abortedBefore = inspectionsAbortedBeforeRead.get()
        val abortedDuring = inspectionsAbortedDuringWalk.get()
        val readsAfter = nodeReadsAfterInvalidation.get()
        val fields = { mapOf(
            "queuedAtUptimeMs" to request.queuedAtUptimeMs,
            "startedAtUptimeMs" to startedAt,
            "triggerReceivedUptimeMs" to (request.triggerReceivedUptimeMs ?: "NA"),
            "eventTimeUptimeMs" to (request.eventTimeUptimeMs ?: "NA"),
            "eventType" to (request.r14Ingress?.eventType ?: "UNOBSERVED"),
            "wakeCallbackAt" to (request.wakeEligibility?.callbackAt ?: "UNOBSERVED"),
            "wakeSampleStart" to (request.wakeEligibility?.startedAt ?: "UNOBSERVED"),
            "wakeSampleEnd" to (request.wakeEligibility?.finishedAt ?: "UNOBSERVED"),
            "wakeSampleMain" to (request.wakeEligibility?.deliveredAt ?: "UNOBSERVED"),
            "wakeSampleRequest" to (request.wakeEligibility?.sampleRequestId ?: "UNOBSERVED"),
            "wakeSampleAuthority" to (request.wakeEligibility?.sampleAuthority?.let {
                "${it.serviceSession}/${it.wakeGeneration}/${it.visibilityEpoch}/${it.interactionEpoch}/${it.attachGeneration}"
            } ?: "UNOBSERVED"),
            "latestSampler" to (request.latestSamplerEvidence?.let {
                "${it.requestId}:${it.startedAt}/${it.finishedAt}/${it.deliveredAt}:${it.eligible}/${it.excluded}"
            } ?: "UNOBSERVED"),
            "latestSamplerAuthority" to (request.latestSamplerEvidence?.authority?.let {
                "${it.serviceSession}/${it.wakeGeneration}/${it.visibilityEpoch}/${it.interactionEpoch}/${it.attachGeneration}"
            } ?: "UNOBSERVED"),
            "requestVisibilityEpoch" to request.visibilityEpoch,
            "requestInteractionEpoch" to request.interactionEpoch,
            "requestWakeGeneration" to request.wakeGeneration,
            "inspectionTotalMs" to (finishedAt - startedAt),
            "windowsReadMs" to (result.windowsReadMs ?: "NA"),
            "treeScanMs" to (result.treeScanMs ?: "NA"),
            "windowCount" to result.windowCount,
            "visitedNodeCount" to result.visitedNodeCount,
            "rootUnavailable" to result.rootUnavailable,
            "walkTruncated" to result.walkTruncated,
            "getWindowsMs" to result.windowTiming.getWindowsMs,
            "relevantWindowCount" to result.windowTiming.relevantWindowCount,
            "rootAcquisitionCount" to result.windowTiming.rootAcquisitionCount,
            "rootAcquisitionTotalMs" to result.windowTiming.rootAcquisitionTotalMs,
            "rootAcquisitionMaxMs" to result.windowTiming.rootAcquisitionMaxMs,
            "readerStrategy" to result.windowTiming.readerStrategy,
            "prefetchFlags" to result.windowTiming.prefetchFlags,
            "activeRootFlags" to (result.windowTiming.activeRootPrefetchFlags ?: "UNOBSERVED"),
            "acceptedChildFlags" to (result.windowTiming.acceptedChildPrefetchFlags ?: "UNOBSERVED"),
            "cacheEnabled" to (result.windowTiming.cacheEnabled ?: "NA"),
            "freshnessPolicy" to result.windowTiming.freshnessPolicy,
            "cacheClearResult" to result.windowTiming.cacheClearResult,
            "activeCandidateWindowId" to (result.windowTiming.activeCandidateWindowId ?: "NA"),
            "returnedRootWindowId" to (result.windowTiming.returnedRootWindowId ?: "NA"),
            "activeRootAccepted" to result.windowTiming.activeRootAccepted,
            "fallbackReason" to (result.windowTiming.fallbackReason ?: "NA"),
            "ownAttributionAmbiguous" to result.windowTiming.ownAttributionAmbiguous,
            "activeRootCallCount" to result.windowTiming.activeRootCallCount,
            "activeRootTotalMs" to result.windowTiming.activeRootTotalMs,
            "perWindowRootCallCount" to result.windowTiming.rootAcquisitionCount,
            "perWindowRootTotalMs" to result.windowTiming.rootAcquisitionTotalMs,
            "childAcquisitionCount" to result.windowTiming.childAcquisitionCount,
            "childAcquisitionTotalMs" to result.windowTiming.childAcquisitionTotalMs,
            "firstChildAcquisitionMs" to (result.windowTiming.firstChildAcquisitionMs ?: "UNOBSERVED"),
            "childAcquisitionMaxMs" to result.windowTiming.childAcquisitionMaxMs,
            "firstNullRootId" to (result.windowTiming.firstNullRootId ?: "UNOBSERVED"),
            "firstNullRootType" to (result.windowTiming.firstNullRootType ?: "UNOBSERVED"),
            "firstNullRootDisplay" to (result.windowTiming.firstNullRootDisplay ?: "UNOBSERVED"),
            "firstNullRootLayer" to (result.windowTiming.firstNullRootRelativeLayer ?: "UNOBSERVED"),
            "firstNullRootSource" to (result.windowTiming.firstNullRootSource ?: "UNOBSERVED"),
            "localProcessingMs" to result.windowTiming.localProcessingMs,
            "slowWindowCalls" to result.windowTiming.slowCalls.joinToString(";"),
            "walkTruncationReasons" to result.windowTiming.walkTruncationReasons.joinToString(",").ifEmpty { "none" },
            "surfaceClassification" to result.decision.name,
            "surfaceMarkers" to result.surfaceMarkers,
            "abortedStale" to result.abortedStale,
            "inspectionsAbortedBeforeRead" to abortedBefore,
            "inspectionsAbortedDuringWalk" to abortedDuring,
            "nodeReadsAfterInvalidation" to readsAfter,
        ) }
        KeyguardCardDiagnostics.captureEventBatch(appContext, request.session, request.wakeGeneration,
            request.id, request.diagnosticContext) {
            val values = fields()
            buildList {
                add(KeyguardDeferredTimingEvent("WINDOWS_READ_FINISHED", "apiCall", finishedAt, values))
                add(KeyguardDeferredTimingEvent("TREE_SCAN_FINISHED", "idOnly", finishedAt, values))
                add(KeyguardDeferredTimingEvent("INSPECTION_FINISHED", result.surfaceReason.name, finishedAt, values))
                if (handoff != null) add(KeyguardDeferredTimingEvent("INSPECTION_MAIN_APPLY_POSTED", request.trigger,
                    handoff.requestedAt, mapOf("inspectionFinishedAtUptimeMs" to finishedAt,
                        "diagnosticPreparationFinishedAtUptimeMs" to handoff.diagnosticPreparationFinishedAt,
                        "mainHandoffRequestedAtUptimeMs" to handoff.requestedAt)))
                if (r12Reason != null && handoff != null) add(KeyguardDeferredTimingEvent("R12_ADMISSION", r12Reason,
                    finishedAt, mapOf("r12Pending" to (r12Pending ?: "UNOBSERVED"),
                        "r12Reserved" to (r12Reserved ?: "UNOBSERVED"),
                        "r12FreshnessRevision" to (r12Revision ?: "UNOBSERVED"),
                        "r12PriorApplyQueued" to handoff.requestedAt)))
            }
        }
    }

    /** Captured under the queue lock immediately before the physical window
     * inventory. The target is added only from that inventory's classifier. */
    private data class R447InventoryStamp(
        val arm: KeyguardR446PrintOwner.Arm, val request: Long,
        val authority: KeyguardInspectionAuthority, val scene: Long,
        val freshness: Long?, val barrier: Long, val systemBarrier: Long,
        val systemSatisfied: Long, val inventoryAt: Long, val target: KeyguardR446Target? = null,
    )

    private data class Inspection(
        val signals: KeyguardCardSignals,
        val decision: KeyguardCardVisibility,
        val surfaceReason: KeyguardSurfaceReason,
        val surfaceMarkers: String = KeyguardSurfaceMarkers().compact(),
        val ownOverlayWindowId: Int? = null,
        val windowCount: Int = 0,
        val visitedNodeCount: Int = 0,
        val rootUnavailable: Boolean = false,
        val walkTruncated: Boolean = false,
        val windowsReadMs: Long? = null,
        val treeScanMs: Long? = null,
        val windowTiming: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
        val abortedStale: Boolean = false,
        val freshnessRevision: Long? = null,
        val r19ReadSceneSerial: Long? = null,
        val r34ReadOwner: R32DirectSnapshot? = null,
        val r34InventoryAt: Long? = null,
        val r34PausedForOffer: Boolean = false,
        val r40Read: R40Read? = null,
        val r446Arm: KeyguardR446PrintOwner.Arm? = null,
        val r446Eligibility: KeyguardR446Eligibility? = null,
        val r446Normal: KeyguardSurfaceClassification? = null,
        val r447Stamp: R447InventoryStamp? = null,
        val r449UnresolvedUpper: KeyguardR449RestrictionEvidence.UnresolvedUpper? = null,
        val r45Lower: List<KeyguardR45LowerWindow> = emptyList(),
    )

    /** A missing Budget category is a user-visible configuration state, not a
     * generic exception.  Keeping this typed also prevents every window event
     * from restarting an impossible `requireNotNull` query. */
    private sealed interface FullContentResolveResult {
        val diagnosticCode: String
        data class Ready(val content: FluviLockScreenCardContent) : FullContentResolveResult {
            override val diagnosticCode = "ready"
        }
        data class InvalidFocus(override val diagnosticCode: String) : FullContentResolveResult
        object StaleRequest : FullContentResolveResult { override val diagnosticCode = "staleRequest" }
        data class Failure(override val diagnosticCode: String) : FullContentResolveResult
    }

    private data class SystemWindowsRead(
        val snapshots: List<KeyguardWindowSnapshot>,
        val rootUnavailable: Boolean,
        val walkTruncated: Boolean,
        val windowsReadMs: Long,
        val treeScanMs: Long,
        val visitedNodeCount: Int,
        val timing: KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(),
        val abortedStale: Boolean = false,
        val freshnessRevision: Long? = null,
        val yieldedTo: KeyguardCardInspectionRequest? = null,
        val yieldReason: KeyguardOpeningYieldReason? = null,
        val firstIncompleteReason: KeyguardWalkIncompleteReason? = null,
        val r34ReadOwner: R32DirectSnapshot? = null,
        val r34InventoryAt: Long? = null,
        val r34PausedForOffer: Boolean = false,
        val r37Boundary: String? = null,
        val r37ClaimAt: Long? = null,
        val r442ScreenAt: Long? = null,
        val r43Evidence: KeyguardR43SurfaceEvidence? = null,
        val r447Stamp: R447InventoryStamp? = null,
    )

    /** Technical-only operation timing. It measures API call duration, not
     * presumed Binder cost: framework cache hits are intentionally possible. */
    private data class WindowReadTiming(
        val getWindowsMs: Long = 0L,
        val relevantWindowCount: Int = 0,
        val rootAcquisitionCount: Int = 0,
        val rootAcquisitionTotalMs: Long = 0L,
        val rootAcquisitionMaxMs: Long = 0L,
        val childAcquisitionCount: Int = 0,
        val childAcquisitionTotalMs: Long = 0L,
        val childAcquisitionMaxMs: Long = 0L,
        val localProcessingMs: Long = 0L,
        val slowCalls: List<String> = emptyList(),
    )

    private class WindowReadTimingAccumulator(private val getWindowsMs: Long) {
        var relevantWindows = 0
        var rootCount = 0
        var rootTotal = 0L
        var rootMax = 0L
        var childCount = 0
        var childTotal = 0L
        var childMax = 0L
        private val slow = mutableListOf<Pair<Long, String>>()

        fun root(window: AccessibilityWindowInfo, displayId: Int, elapsedMs: Long) {
            rootCount += 1; rootTotal += elapsedMs; rootMax = maxOf(rootMax, elapsedMs)
            slow += elapsedMs to "root:w=${window.id},t=${window.type},d=$displayId,$elapsedMs"
        }

        fun child(windowId: Int, index: Int, elapsedMs: Long) {
            childCount += 1; childTotal += elapsedMs; childMax = maxOf(childMax, elapsedMs)
            slow += elapsedMs to "child:w=$windowId,i=$index,$elapsedMs"
        }

        fun snapshot(treeElapsedMs: Long): KeyguardWindowSnapshotReader.Timing = KeyguardWindowSnapshotReader.Timing(
            getWindowsMs = getWindowsMs,
            relevantWindowCount = relevantWindows,
            rootAcquisitionCount = rootCount,
            rootAcquisitionTotalMs = rootTotal,
            rootAcquisitionMaxMs = rootMax,
            childAcquisitionCount = childCount,
            childAcquisitionTotalMs = childTotal,
            childAcquisitionMaxMs = childMax,
            localProcessingMs = (treeElapsedMs - rootTotal - childTotal).coerceAtLeast(0L),
            slowCalls = slow.sortedByDescending { it.first }.take(3).map { it.second },
        )
    }

    private data class VisibleIds(
        val ids: Set<String>,
        val truncated: Boolean,
        val visitedNodeCount: Int,
        val abortedStale: Boolean = false,
    )

    private fun inspectSurface(request: KeyguardCardInspectionRequest, startedAt: Long,
                               r38MilestoneOrdered: Boolean, r40Read: R40Read?): InspectionOutcome {
        // The settings/profile input is maintained on the service lifetime;
        // an inspection must not contend on preferences/JSON work at wake.
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        val baseline = quickSignals(settings, KeyguardSurface.UNKNOWN)
        if (!baseline.requested || !baseline.serviceConnected || !baseline.userUnlocked ||
            !baseline.primaryDisplay || !baseline.interactive || !baseline.displayOn || !baseline.keyguardLocked
        ) {
            return InspectionOutcome.Completed(Inspection(baseline, KeyguardCardVisibilityPolicy.decide(baseline), KeyguardSurfaceReason.NO_WINDOWS))
        }
        if (!authorityIsCurrent(request)) {
            inspectionsAbortedBeforeRead.incrementAndGet()
            return InspectionOutcome.Completed(Inspection(
                baseline,
                KeyguardCardVisibility.HIDDEN_UNKNOWN,
                KeyguardSurfaceReason.NO_WINDOWS,
                abortedStale = true,
            ))
        }
        // Preserve legacy opening bookkeeping, but bind the read's authority
        // scene only after cache work, immediately before physical inventory.
        synchronized(queueLock) {
            if (openingHandoff.openingRequestId == request.id)
                openingHandoff.readStarted(request, firstAuthorizedOrb.sceneSerial(), startedAt)
        }
        var sceneAtRead: Long? = null
        val r44Mode = Build.VERSION.SDK_INT == 37 && settings.presentationMode == KeyguardCardPresentationMode.ORB
        val syntheticAtRead = r44Mode && KeyguardR44Trial.active
        val profileAtRead = if (syntheticAtRead) r444ProfileOwner.snapshot else null
        val expandedAtRead = syntheticAtRead && profileAtRead?.expandedPolicy == true
        val lookupAtRead = r442Lookup
        val screenAtRead = r442ScreenOn
        val printAtRead = r446ReadArm?.takeIf {
            screenAtRead != null && screenAtRead.session == request.session && startedAt >= screenAtRead.uptime &&
                it.session == request.session && it.capture == request.diagnosticContext?.captureId
        }
        val read = readSystemWindows(request, startedAt, r38MilestoneOrdered, r40Read, lookupAtRead,
            syntheticAtRead, profileAtRead, printAtRead) { sceneAtRead = it }
        if (read.yieldedTo != null) return InspectionOutcome.Yielded(read.yieldedTo, read,
            requireNotNull(sceneAtRead), requireNotNull(read.yieldReason))
        if (read.abortedStale || !authorityIsCurrent(request) ||
            (profileAtRead != null && r444ProfileOwner.snapshot.revision != profileAtRead.revision)) {
            if (!read.abortedStale) inspectionsAbortedDuringWalk.incrementAndGet()
            if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, true,
                KeyguardSurfaceClassification(KeyguardSurface.UNKNOWN, KeyguardSurfaceReason.NO_MAIN_MARKER),
                lookup = lookupAtRead, profile = profileAtRead)
            return InspectionOutcome.Completed(Inspection(
                baseline,
                KeyguardCardVisibility.HIDDEN_UNKNOWN,
                KeyguardSurfaceReason.NO_WINDOWS,
                windowCount = read.snapshots.size,
                visitedNodeCount = read.visitedNodeCount,
                rootUnavailable = read.rootUnavailable,
                walkTruncated = read.walkTruncated,
                windowsReadMs = read.windowsReadMs,
                treeScanMs = read.treeScanMs,
                windowTiming = read.timing,
                abortedStale = true,
                freshnessRevision = read.freshnessRevision,
                r19ReadSceneSerial = sceneAtRead,
                r34ReadOwner = read.r34ReadOwner,
                r34InventoryAt = read.r34InventoryAt,
                r34PausedForOffer = read.r34PausedForOffer,
            ))
        }
        val snapshots = inspectionProbeForTest?.snapshots(request, read.snapshots) ?: read.snapshots
        val strictOwn = r18Active != null || r18ProvisionalWake?.targetAuthority?.matches(request) == true
        val classification = if (r44Mode) {
            KeyguardR44SurfaceClassifier.classify(snapshots, read.rootUnavailable, read.walkTruncated,
                strictOwn, syntheticTrial = syntheticAtRead, expanded = expandedAtRead)
        } else KeyguardSurfaceClassifier.classifyDetailed(snapshots,
            unavailableRoot = read.rootUnavailable, walkTruncated = read.walkTruncated,
            strictOwnAttribution = strictOwn)
        if (r44Mode) recordR44Read(request, read, sceneAtRead, startedAt, syntheticAtRead, false, classification,
            snapshots, inspectionProbeForTest != null, strictOwn, lookupAtRead, profileAtRead)
        if (read.r43Evidence != null) runCatching { recordR43Passive(request, read, classification, sceneAtRead) }
        val printArm = printAtRead?.takeIf { it == r446ReadArm }
        val controlledSample = printArm != null && KeyguardR447TestHooks.CONTROLLED_TOPOLOGY &&
            inspectionProbeForTest?.r447ControlledSampleTopology() == true &&
            snapshots.all { candidate -> read.snapshots.any { it === candidate } }
        val printEligibility = if (printArm != null && syntheticAtRead &&
            (inspectionProbeForTest == null || controlledSample))
            KeyguardR446PrintPolicy.evaluate(if (controlledSample) snapshots else read.snapshots,
                classification, read.rootUnavailable, read.walkTruncated)
        else null
        val printNormal = if (printArm != null) KeyguardR44SurfaceClassifier.classify(read.snapshots,
            read.rootUnavailable, read.walkTruncated, strictOwn, syntheticTrial = false) else null
        val signals = quickSignals(settings, classification.surface)
        return InspectionOutcome.Completed(Inspection(
            signals,
            KeyguardCardVisibilityPolicy.decide(signals),
            classification.reason,
            classification.markers.compact(),
            read.snapshots.firstOrNull { it.ownOverlay }?.windowId?.takeIf { it >= 0 },
            windowCount = read.snapshots.size,
            visitedNodeCount = read.visitedNodeCount,
            rootUnavailable = read.rootUnavailable,
            walkTruncated = read.walkTruncated,
            windowsReadMs = read.windowsReadMs,
            treeScanMs = read.treeScanMs,
            windowTiming = read.timing,
            freshnessRevision = read.freshnessRevision,
            r19ReadSceneSerial = sceneAtRead,
            r34ReadOwner = read.r34ReadOwner,
            r34InventoryAt = read.r34InventoryAt,
            r40Read = r40Read,
            r446Arm = printArm,
            r446Eligibility = printEligibility,
            r446Normal = printNormal,
            r447Stamp = read.r447Stamp?.copy(target = printEligibility?.target),
            r449UnresolvedUpper = if (printArm != null) KeyguardR449RestrictionEvidence.unresolvedUpper(
                read.snapshots, if (inspectionProbeForTest == null) classification else
                    KeyguardR44SurfaceClassifier.classify(read.snapshots, read.rootUnavailable, read.walkTruncated,
                        strictOwn, syntheticTrial = syntheticAtRead, expanded = expandedAtRead), read.walkTruncated) else null,
            r45Lower = if (printEligibility?.target != null) KeyguardR449RestrictionEvidence.fromInventory(
                read.snapshots, startedAt, read.rootUnavailable, read.walkTruncated).lower else emptyList(),
        ))
    }

    private fun recordR44Read(request: KeyguardCardInspectionRequest, read: SystemWindowsRead,
                              scene: Long?, startedAt: Long, synthetic: Boolean, stale: Boolean,
                              result: KeyguardSurfaceClassification,
                              windows: List<KeyguardWindowSnapshot> = read.snapshots,
                              injected: Boolean = false, strictOwn: Boolean = false,
                              lookup: R442Lookup = r442Lookup,
                              profile: KeyguardR444ProfileOwner.Snapshot? = null) {
        val owner = request.diagnosticContext ?: return
        if (owner.captureId == null || owner.captureId != KeyguardCardDiagnostics.activeCaptureId()) return
        val host = windows.firstOrNull { it.r44?.let { e -> e.active && e.host != null } == true }
            ?: windows.firstOrNull { it.r44?.active == true }
        val evidence = windows.mapNotNull { it.r44 }
        val hostEvidence = host?.r44
        val legacy = KeyguardSurfaceClassifier.classifyDetailed(windows,
            unavailableRoot = read.rootUnavailable, walkTruncated = read.walkTruncated,
            strictOwnAttribution = strictOwn).surface
        val shadow = if (stale) null else KeyguardR44SurfaceClassifier.classify(windows,
            read.rootUnavailable, read.walkTruncated, strictOwn, syntheticTrial = true,
            expanded = synthetic && profile?.expandedPolicy == true)
        val cover = when {
            stale || read.rootUnavailable || read.walkTruncated -> "UNOBSERVED"
            hostEvidence?.host == null -> "HOST_ABSENT"
            windows.any { it !== host && !it.ownOverlay && it.displayId == 0 &&
                host != null && it.layer >= host.layer && it.r44?.verifiedPassive != true } -> "VETO_UNKNOWN_OR_COVER"
            shadow?.reason == KeyguardSurfaceReason.FOREIGN_ABOVE -> "VETO_UNKNOWN_OR_COVER"
            shadow?.surface == KeyguardSurface.MAIN_KEYGUARD -> "CHECKED_CLEAR"
            else -> "NOT_REACHED"
        }
        val secondary = if (host == null) emptyList() else windows.filter { w ->
            w !== host && !w.ownOverlay && w.displayId == 0 && w.layer >= host.layer
        }.sortedByDescending { it.layer }
        fun describe(w: KeyguardWindowSnapshot): KeyguardR444WindowObservation {
            val category = when {
                w.ownOverlay -> "OWN"
                w.packageName == null -> "UNKNOWN"
                w.packageName == "com.android.systemui" -> "SYSTEMUI"
                w.packageName == "android" || w.packageName == "com.android.keyguard" -> "SYSTEM"
                else -> "FOREIGN"
            }
            return KeyguardR444WindowObservation(w.windowId, w.layer - (host?.layer ?: w.layer),
                w.type, w.r444Active, w.r444Focused, category, w.r444OwnGeneration,
                w.r44?.verifiedRoot == true, w.r444Visited, w.r444RootRole)
        }
        val receipt = r442Receipt?.let {
            if (it.capture == owner.captureId && it.session == owner.serviceSession &&
                it.process == KeyguardCardDiagnostics.currentProcessInstanceId()) "armed" else "stale"
        } ?: "notArmed"
        KeyguardCardDiagnostics.recordR44(KeyguardR44ReadObservation(
            owner, request.id, request.visibilityEpoch, scene, startedAt, SystemClock.uptimeMillis(), legacy,
            result.surface, result.reason, synthetic, injected, stale, read.rootUnavailable, read.walkTruncated,
            host?.windowId, host?.layer, hostEvidence?.verifiedRoot == true, hostEvidence?.host,
            hostEvidence?.content, hostEvidence?.contentBelowHost == true,
            evidence.isNotEmpty() && evidence.all { it.complete }, evidence.sumOf { it.advertised },
            evidence.sumOf { it.fetched }, evidence.sumOf { it.failed }, evidence.sumOf { it.unsupported }, evidence.any { it.budgetHit },
            evidence.sumOf { it.extraMs }, lookup.status, lookup.identity, shadow?.surface, shadow?.reason,
            evidence.sumOf { it.rawHost }, evidence.sumOf { it.rawEntry }, evidence.sumOf { it.rawClock },
            evidence.sumOf { it.rejectedUnverified }, evidence.sumOf { it.rejectedAncestry },
            evidence.sumOf { it.rejectedExcluded }, evidence.sumOf { it.rejectedForeign },
            evidence.sumOf { it.rejectedHidden }, evidence.firstNotNullOfOrNull { it.firstCandidate },
            evidence.firstNotNullOfOrNull { it.firstCarrier }, cover, receipt,
            windows.mapNotNull { w -> w.r44?.let { e -> KeyguardR443WindowObservation(
                w.windowId, e.advertised, e.fetched, e.r443Overflow, e.complete) } }
                .sortedByDescending { it.advertised }.take(8),
            evidence.flatMap { it.r443Candidates }.take(7),
            appliedGate = result.r444Gate, profile = profile?.kind?.name ?: "UNOBSERVED",
            profileRevision = profile?.revision, previousFlags = profile?.before, actualFlags = profile?.actual,
            clockResourceVerified = lookup.clockVerified,
            hostNodes = evidence.sumOf { it.r444HostNodes },
            hostCarriers = evidence.fold(0) { mask, item -> mask or item.r444HostCarriers },
            hostParent = hostEvidence?.r444HostParent, contentParent = hostEvidence?.r444ContentParent,
            secondaryCount = secondary.size, secondaryOverflow = (secondary.size - 4).coerceAtLeast(0),
            r444Windows = (listOfNotNull(host) + secondary.take(4)).map(::describe),
            r445SmallInstalled = lookup.smallClockVerified, r445LargeInstalled = lookup.largeClockVerified,
            r445EntryInstalled = lookup.verified, r445IndexStatus = hostEvidence?.r445IndexStatus ?: "NO_HOST",
            r445IndexCalls = hostEvidence?.r445IndexCalls.orEmpty().take(3),
        ))
    }

    private fun quickSignals(settings: KeyguardCardSettings, surface: KeyguardSurface): KeyguardCardSignals {
        val state = readSystemState(KeyguardSystemReadPurpose.INSPECTION)
        return signalsFromSystemState(settings, surface, state)
    }

    private fun signalsFromSystemState(settings: KeyguardCardSettings, surface: KeyguardSurface, state: KeyguardSystemState): KeyguardCardSignals {
        return KeyguardCardSignals(
            requested = settings.requested,
            serviceConnected = FluviKeyguardCardServiceRegistry.connected,
            userUnlocked = state.available && state.userUnlocked,
            primaryDisplay = state.available && state.primaryDisplay,
            interactive = state.available && state.interactive,
            displayOn = state.available && state.displayOn,
            keyguardLocked = state.available && state.keyguardLocked,
            surface = surface,
            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active,
            systemStateAvailable = state.available,
            displayOff = state.displayOff,
        )
    }

    private fun readSystemWindows(request: KeyguardCardInspectionRequest, startedAt: Long, r38MilestoneOrdered: Boolean,
                                  r40Read: R40Read?, lookup: R442Lookup, syntheticAtRead: Boolean,
                                  profileAtRead: KeyguardR444ProfileOwner.Snapshot?, printAtRead: KeyguardR446PrintOwner.Arm?,
                                  onInventoryScene: (Long) -> Unit): SystemWindowsRead {
        // Resolve the outstanding requirement at acquisition, not when an
        // event happened to replace a timer/pending request. A successful
        // boundary is consumed once, without clearing on every later event.
        val freshness = synchronized(queueLock) { inspectionFreshness.beforeRead(request) }
        // Selection happens at the eligible physical call, not while reading
        // an empty inventory or a per-window fallback. A superseding freshness
        // revision or authority cannot consume a newer wake's opportunity.
        val selectRootStrategy = {
            val initial = synchronized(queueLock) {
                val current = inspectionFreshness.beforeRead(request)
                val compatible = freshness != null && current != null &&
                    current.authority == freshness.authority && current.revision == freshness.revision &&
                    authorityIsCurrent(request)
                firstAcquisition.take(request, if (compatible) freshness else null)
            }
            val historicalZero = if (KeyguardR15AcquisitionTestHooks.ENABLED) {
                KeyguardR15AcquisitionTestHooks.begin(request, freshness, initial)
            } else false
            when {
                historicalZero -> KeyguardActiveRootStrategy.R15_HISTORICAL_ZERO
                initial && Build.VERSION.SDK_INT == 35 -> KeyguardActiveRootStrategy.R18_INITIAL_HYBRID
                else -> KeyguardActiveRootStrategy.STOCK
            }
        }
        val captureOpening = request.diagnosticContext?.captureId != null &&
            request.diagnosticContext.captureId == KeyguardCardDiagnostics.activeCaptureId()
        val r43CurrentPlan = r43Plan?.takeIf { it.captureId == request.diagnosticContext?.captureId &&
            KeyguardCardDiagnostics.r43Enabled(it.captureId) }
        val r43Evidence = if (r43CurrentPlan?.allowPassive(SystemClock.uptimeMillis()) == true)
            KeyguardR43SurfaceEvidence() else {
            if (r43CurrentPlan != null) KeyguardCardDiagnostics.r43PassiveSkipped(r43CurrentPlan.captureId)
            null
        }
        val (r34Eligible, r37EarlyStamp) = synchronized(queueLock) {
            val adopted = !r38MilestoneOrdered && r34EmptyDirectLocked(request) != null
            adopted to if (adopted || r38MilestoneOrdered) null else r37EarlyStampLocked(request)
        }
        val r37Eligible = r34Eligible || r37EarlyStamp != null
        val r442Enabled = Build.VERSION.SDK_INT == 37 &&
            lastSettings?.presentationMode == KeyguardCardPresentationMode.ORB
        fun r442PendingLocked(screen: R442ScreenOn? = r442ScreenOn): KeyguardCardInspectionRequest? {
            val pending = inspectionQueue.pendingRequest()
            return pending?.takeIf {
                KeyguardR442YieldPolicy.permits(Build.VERSION.SDK_INT, r442Enabled, screen?.uptime,
                    screen?.session, startedAt, inspectionAuthority, inspectionQueue.activeRequest(), request, it)
            }
        }
        var r37Boundary: String? = null
        var r37ClaimAt: Long? = null
        var r442ClaimScreenAt: Long? = null
        var r443ScreenAt: Long? = null
        var r443Pending: KeyguardCardInspectionRequest? = null
        var r447Stamp: R447InventoryStamp? = null
        var r443BoundaryAt: Long? = null
        var r443BoundaryReason: String? = null
        var r34ReadOwner: R32DirectSnapshot? = null
        var r34ReadScene: Long? = null
        var r34InventoryAt: Long? = null
        var r34PausedForOffer = false
        val yieldHandle = if (!r34Eligible && openingHandoff.openingRequestId == request.id) synchronized(queueLock) {
            openingHandoff.yieldHandle(request)
        } else null
        val followHandle = if (!r38MilestoneOrdered && !r34Eligible && openingHandoff.claimedRequestId == request.id) synchronized(queueLock) {
            openingHandoff.followHandle(request)
        } else null
        val ingressReader = if (captureOpening) synchronized(queueLock) { openingHandoff.ingressReader(request) } else null
        val result = windowSnapshotReader.read(
            request = KeyguardWindowSnapshotReader.Request(
                knownOwn = knownOwnOverlayIdentity,
                attachGeneration = request.attachGeneration,
                r44Enabled = Build.VERSION.SDK_INT == 37 &&
                    lastSettings?.presentationMode == KeyguardCardPresentationMode.ORB,
                r44DeviceEntryResourceVerified = lookup.verified,
                r443Sample = syntheticAtRead,
                // Unknown attachment state takes the immediate, conservative route.
                r443Live = r40Read != null || readAheadSnapshot?.detached != true,
                r443Diagnostics = captureOpening,
                r444Expanded = syntheticAtRead && profileAtRead?.expandedPolicy == true,
                r444ClockVerified = lookup.clockVerified,
                r444UdfpsVerified = lookup.udfpsVerified,
                r445SmallClockVerified = lookup.smallClockVerified,
                r445LargeClockVerified = lookup.largeClockVerified,
                r446Print = printAtRead != null,
                r445ClaimBatch = if (syntheticAtRead && printAtRead == null && readAheadSnapshot?.detached == true) { {
                    synchronized(queueLock) {
                        val screen = r442ScreenOn
                        if (screen == null || screen.session != request.session ||
                            request.wakeGeneration != wakeEpoch || !authorityIsCurrent(request) ||
                            !KeyguardR44Trial.active || r444ProfileOwner.snapshot.revision != profileAtRead?.revision) null
                        else r445WakeBudget.claim(request.session, request.wakeGeneration, screen.uptime)
                    }
                } } else null,
                r443Boundary = if (captureOpening && r442Enabled) { structuralReason ->
                    val at = SystemClock.uptimeMillis()
                    synchronized(queueLock) {
                        val screen = r442ScreenOn
                        if (screen != null && screen.session == request.session && startedAt < screen.uptime) {
                            val pending = inspectionQueue.pendingRequest()
                            val reason = when {
                                pending == null -> "NO_PENDING"
                                structuralReason != "ELIGIBLE" -> structuralReason
                                r442PendingLocked(screen) == null -> "OWNER_MISMATCH"
                                else -> "ELIGIBLE_PENDING"
                            }
                            if (r443BoundaryAt == null || (r443Pending == null && pending != null)) {
                                r443ScreenAt = screen.uptime; r443Pending = pending
                                r443BoundaryAt = at; r443BoundaryReason = reason
                            }
                        }
                    }
                } else null,
                freshness = freshness?.reason ?: KeyguardWindowFreshness.FRAMEWORK_EVENT,
                activeRootStrategyAtCall = selectRootStrategy,
                knownOwnAtInventory = { knownOwnOverlayIdentity },
                strictOwnAttribution = followHandle != null || r18Active != null ||
                    r18ProvisionalWake?.targetAuthority?.matches(request) == true,
                r40Provenance = r40Read?.provenance,
                openingYieldHint = when {
                    r34Eligible -> { { r34ReadOwner != null && r34ReadScene?.let { firstAuthorizedOrb.sceneHint() > it } == true } }
                    yieldHandle != null -> { { openingHandoff.hasHint(yieldHandle) } }
                    followHandle != null -> { { openingHandoff.hasFollowHint(followHandle) } }
                    else -> null
                },
                followOnOpening = followHandle != null,
                r34ExactSystemRoot = r34Eligible,
                r37YieldHint = if (r442Enabled) {
                    { synchronized(queueLock) { r442PendingLocked() != null } }
                } else if (r37Eligible) {
                    { r34ReadScene?.let { firstAuthorizedOrb.sceneHint() > it } == true }
                } else null,
                claimR37Yield = if (r442Enabled) { { boundary, freshnessSafe, visited, roots, children ->
                    val at = SystemClock.uptimeMillis()
                    val claimed = synchronized(queueLock) {
                        val screen = r442ScreenOn
                        val pending = if (freshnessSafe) r442PendingLocked(screen) else null
                        pending?.takeIf { r442ScreenOn === screen }
                            ?.let { inspectionQueue.handoffOpening(request, it) }?.also {
                            r37Boundary = "R442_$boundary:$visited/$roots/$children"
                            r37ClaimAt = at
                            r442ClaimScreenAt = screen?.uptime
                            openingHandoff.invalidate()
                        }
                    }
                    if (claimed != null) runCatching {
                        inspectionProbeForTest?.r37BoundaryClaimed(request, claimed, boundary, at)
                    }
                    claimed
                } } else if (r37Eligible) { { boundary, freshnessSafe, visited, roots, children ->
                    val at = SystemClock.uptimeMillis()
                    val claimed = synchronized(queueLock) {
                        val owner = r34ReadOwner ?: r37AdoptedOwnerLocked(request, r37EarlyStamp)
                            ?.also { r34ReadOwner = it }
                        if (owner == null) return@synchronized null
                        val scene = firstAuthorizedOrb.sceneSerial()
                        val pending = inspectionQueue.pendingRequest()
                        val action = KeyguardR34LatestScenePolicy.decide(
                            r34ReadScene, scene, r34SameEmptyOwnerLocked(request, owner),
                            safeBoundary = freshnessSafe, restrictiveEvidence = false,
                            pendingScene = pending?.r34SceneSerial,
                            genuineCompatiblePending = r34ActualLatestLocked(request, pending, scene))
                        // No new parking or synthetic request: without the
                        // genuine latest offer the original read continues.
                        if (action != KeyguardR34LatestScenePolicy.Action.TRANSFER) return@synchronized null
                        val successor = inspectionQueue.handoffOpening(request, requireNotNull(pending))
                        if (successor != null) {
                            r37Boundary = "$boundary:$visited/$roots/$children"
                            r37ClaimAt = at
                            openingHandoff.invalidate()
                        }
                        successor
                    }
                    if (claimed != null) runCatching {
                        inspectionProbeForTest?.r37BoundaryClaimed(request, claimed, boundary, at)
                    }
                    claimed
                } } else null,
                beforeWindowsAcquisition = {
                    synchronized(queueLock) {
                        val scene = firstAuthorizedOrb.sceneSerial()
                        onInventoryScene(scene)
                        if (printAtRead != null && printAtRead == r446ReadArm && authorityIsCurrent(request)) {
                            val order = firstAuthorizedOrb.sampleOrder(request.id, scene)
                            r447Stamp = R447InventoryStamp(printAtRead, request.id, inspectionAuthority, scene,
                                freshness?.revision, order.barrier, r447SystemBarrier, r447SystemSatisfied,
                                SystemClock.uptimeMillis())
                        }
                        if (r37Eligible) {
                            r34ReadOwner = if (r34Eligible) r34EmptyDirectLocked(request)
                                else r37AdoptedOwnerLocked(request, r37EarlyStamp)
                            // Capture the original scene before inventory even
                            // when the exact reservation is not yet adopted.
                            r34ReadScene = scene
                            r34InventoryAt = SystemClock.uptimeMillis()
                        }
                        if (followHandle != null)
                            openingHandoff.followReadStarted(inspectionQueue, request,
                                scene, SystemClock.uptimeMillis())
                    }
                },
                openingFirstIngressUptime = if (captureOpening && r442Enabled) {
                    { ingressReader?.invoke()?.takeIf { it > 0L } ?: r442ScreenOn?.uptime ?: -1L }
                } else ingressReader,
                openingChildBefore = if (((yieldHandle != null || followHandle != null || r34Eligible) && inspectionProbeForTest != null) ||
                    (captureOpening && followHandle != null)) {
                    { window, index ->
                        if (captureOpening && followHandle != null && openingHandoff.observesFollowChildren(followHandle) &&
                            request.diagnosticContext?.captureId == KeyguardCardDiagnostics.activeCaptureId()) {
                            synchronized(queueLock) {
                                if (request.diagnosticContext?.captureId == KeyguardCardDiagnostics.activeCaptureId())
                                    openingHandoff.noteFollowChild(followHandle)
                            }
                        }
                        runCatching { inspectionProbeForTest?.openingChildBefore(request, window, index) }
                        Unit
                    }
                } else null,
                openingChildReturned = if ((yieldHandle != null || followHandle != null || r34Eligible) && inspectionProbeForTest != null) {
                    { window, index, present ->
                        runCatching { inspectionProbeForTest?.openingChildReturned(request, window, index, present) }
                        Unit
                    }
                } else null,
                openingEligibleCheckpoint = if (KeyguardR15AcquisitionTestHooks.ENABLED &&
                    (yieldHandle != null || followHandle != null || r34Eligible) && inspectionProbeForTest != null) {
                    { window, index ->
                        runCatching { inspectionProbeForTest?.openingEligibleCheckpoint(request, window, index) }
                        Unit
                    }
                } else null,
                captureOriginalOpeningEvidence = captureOpening && yieldHandle != null,
                claimOpeningYield = if (r34Eligible || yieldHandle != null || followHandle != null) { { checkpoint, yieldReason, physicalBoundary, safeInventory, visited, roots, children ->
                    val at = SystemClock.uptimeMillis()
                    synchronized(queueLock) {
                        if (r34Eligible) {
                            val owner = r34ReadOwner ?: return@synchronized null
                            val scene = firstAuthorizedOrb.sceneSerial()
                            val pending = inspectionQueue.pendingRequest()
                            val action = KeyguardR34LatestScenePolicy.decide(
                                r34ReadScene, scene, r34SameEmptyOwnerLocked(request, owner),
                                safeInventory && physicalBoundary && yieldReason == KeyguardOpeningYieldReason.CLEAN_OPENING,
                                restrictiveEvidence = false, pendingScene = pending?.r34SceneSerial,
                                genuineCompatiblePending = r34ActualLatestLocked(request, pending, scene))
                            if (action == KeyguardR34LatestScenePolicy.Action.WAIT_FOR_OFFER) {
                                // Do not release queue ownership here: the reader must first unwind its nodes.
                                r34PausedForOffer = true
                                return@synchronized null
                            }
                            if (action != KeyguardR34LatestScenePolicy.Action.TRANSFER) return@synchronized null
                            val successor = inspectionQueue.handoffOpening(request, requireNotNull(pending))
                            if (successor != null) openingHandoff.invalidate()
                            return@synchronized successor
                        }
                        if (yieldHandle != null && !openingHandoff.isCurrent(yieldHandle)) return@synchronized null
                        val presentation = r18Coordinator.snapshot()
                        val latest = inspectionFreshness.beforeRead(request)
                        val freshnessSafe = freshness != null && latest != null && physicalBoundary &&
                            latest.authority == freshness.authority && latest.revision >= freshness.revision &&
                            (latest.revision > freshness.revision ||
                                inspectionFreshness.isEstablished(freshness.authority, freshness.revision))
                        val activeOwner = r18Active
                        val identity = activeOwner?.identity
                        val provisional = r18ProvisionalWake
                        val virginDirect = KeyguardR27VirginDirectPolicy.matches(
                            followHandle?.opening ?: request, presentation, r18RouteRevision,
                            identity?.token, identity?.preparation,
                            provisional?.token, provisional?.preparation,
                            r18RouteSnapshot?.preparation,
                        )
                        val pending = inspectionQueue.pendingRequest()
                        val incompleteFreshnessSafe = freshnessSafe && latest != null && pending != null &&
                            !pending.windowFreshness.requiresCacheClear &&
                            inspectionFreshness.isEstablished(latest.authority, latest.revision)
                        val conditions = KeyguardOpeningInspectionHandoff.Conditions(
                            reservationCurrent = presentation.reservation != null,
                            routeCurrent = r18RouteEnabled,
                            authorityCurrent = authorityIsCurrent(request),
                            hostSafe = presentation.host == KeyguardOrbPresentationCoordinator.Host.NONE ||
                                presentation.host == KeyguardOrbPresentationCoordinator.Host.INERT ||
                                presentation.host == KeyguardOrbPresentationCoordinator.Host.READY,
                            grantNone = presentation.grant == KeyguardOrbPresentationCoordinator.Grant.NONE,
                            noPaint = true,
                            noVisibleOrShowing = readAheadSnapshot?.detached == true && !readAheadShowInProgress && r14Recovery == null,
                            freshnessEstablished = if (followHandle != null)
                                freshnessSafe && latest != null && pending != null && !pending.windowFreshness.requiresCacheClear &&
                                    latest.revision == freshness?.revision && inspectionFreshness.isEstablished(latest.authority, latest.revision)
                            else if (yieldReason == KeyguardOpeningYieldReason.INCOMPLETE_NULL_CHILD) incompleteFreshnessSafe else freshnessSafe,
                            noObservedDisqualifier = safeInventory,
                            workRemaining = true,
                            virginDirect = virginDirect,
                            noRetainedProof = firstAuthorizedOrb.current() == null && activeOwner?.firstProof == null,
                        )
                        val successor = if (followHandle != null) {
                            if (yieldReason != KeyguardOpeningYieldReason.CLEAN_OPENING) null else
                                openingHandoff.claimFollow(inspectionQueue, followHandle, presentation.reservation,
                                    r18RouteRevision, firstAuthorizedOrb.sceneSerial(), conditions, checkpoint, at, children)
                        } else openingHandoff.claim(
                            inspectionQueue, request, presentation.reservation, r18RouteRevision,
                            firstAuthorizedOrb.sceneSerial(),
                            if (r38MilestoneOrdered) conditions else
                                conditions.copy(noVisibleOrShowing = readAheadSnapshot?.detached == true && !readAheadShowInProgress),
                            checkpoint, at, visited, roots, children,
                            observationCaptureId = request.diagnosticContext?.captureId?.takeIf {
                                it == KeyguardCardDiagnostics.activeCaptureId()
                            }, yieldReason = yieldReason,
                        )
                        if (successor != null) runCatching {
                            openingHandoff.snapshot(request.id)?.postClaim?.let {
                                KeyguardCardDiagnostics.recordR22PostClaim(it)
                            }
                        }
                        successor
                    }
                } } else null,
                pauseOpeningAfterYieldAttempt = if (r34Eligible) { { r34PausedForOffer } } else null,
                onDecisiveSystemMarker = {
                    if (authorityIsCurrent(request)) {
                        if (r446ReadArm != null || r446TicketActive) {
                            r446RestrictionSeen = true
                            mainHandler.post { if (r446HasBackend()) r446Cancel("decisiveMarker") }
                        }
                        sealR18(KeyguardInspectionAuthority(request.session, request.visibilityEpoch, request.wakeGeneration,
                            request.interactionEpoch, request.attachGeneration), request.id, "decisiveSystemMarker")
                        if (Build.VERSION.SDK_INT >= 37) mainHandler.post {
                            // Never let a stale reader hide a newer attachment.
                            if (authorityIsCurrent(request) && ::overlay.isInitialized && overlay.isAttached)
                                hideImmediately("r441DecisiveMarker", terminalWake = false,
                                    awaitingSurfaceWithdrawal = true,
                                    triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                                    diagnosticContext = request.diagnosticContext,
                                    causingInspectionRequestId = request.id)
                        }
                    }
                },
                r43Evidence = r43Evidence,
            ),
            authorityIsCurrent = { freshness != null && authorityIsCurrent(request) &&
                (profileAtRead == null || r444ProfileOwner.snapshot.revision == profileAtRead.revision) },
            onFreshnessEstablished = { freshness?.let(inspectionFreshness::boundaryEstablished) },
        )
        if (captureOpening && r443ScreenAt != null && r443BoundaryAt != null) {
            val owner = request.diagnosticContext
            if (owner != null) KeyguardCardDiagnostics.recordR443Boundary(KeyguardR443BoundaryObservation(
                owner, request.id, r443Pending?.id, requireNotNull(r443ScreenAt),
                r443Pending?.queuedAtUptimeMs, startedAt, requireNotNull(r443BoundaryAt),
                SystemClock.uptimeMillis(), if (result.yieldedTo != null) "TAKEN" else
                    if (r443BoundaryReason == "ELIGIBLE_PENDING") "NOT_CLAIMED" else requireNotNull(r443BoundaryReason),
                result.timing.ingressCallKind, result.timing.ingressCallBegin, result.timing.ingressCallEnd,
            ))
        }
        if (KeyguardR15AcquisitionTestHooks.ENABLED) KeyguardR15AcquisitionTestHooks.finish(result)
        if (result.abortedStale) inspectionsAbortedDuringWalk.incrementAndGet()
        if (result.nodeReadsAfterInvalidation > 0) {
            nodeReadsAfterInvalidation.addAndGet(result.nodeReadsAfterInvalidation.toLong())
        }
        return SystemWindowsRead(
            snapshots = result.snapshots,
            rootUnavailable = result.rootUnavailable,
            walkTruncated = result.walkTruncated,
            windowsReadMs = result.windowsReadMs,
            treeScanMs = result.treeScanMs,
            visitedNodeCount = result.visitedNodeCount,
            timing = result.timing,
            abortedStale = result.abortedStale,
            freshnessRevision = freshness?.revision,
            yieldedTo = result.yieldedTo,
            yieldReason = result.yieldReason,
            firstIncompleteReason = result.firstIncompleteReason,
            r34ReadOwner = r34ReadOwner,
            r34InventoryAt = r34InventoryAt,
            r34PausedForOffer = r34PausedForOffer && result.abortedStale,
            r37Boundary = r37Boundary,
            r37ClaimAt = r37ClaimAt,
            r442ScreenAt = r442ClaimScreenAt,
            r43Evidence = r43Evidence,
            r447Stamp = r447Stamp,
        )
    }

    /** Kept temporarily as a narrow, testable reference while the API-33
     * reader owns production acquisition.  It is never called by production
     * classification; uncertain active-root reads fall back inside the reader
     * before a surface decision is made. */
    @Suppress("unused")
    private fun readSystemWindowsLegacy(request: KeyguardCardInspectionRequest): SystemWindowsRead = runCatching {
        if (!authorityIsCurrent(request)) {
            inspectionsAbortedBeforeRead.incrementAndGet()
            return@runCatching SystemWindowsRead(
                emptyList(), rootUnavailable = false, walkTruncated = false,
                windowsReadMs = 0L, treeScanMs = 0L, visitedNodeCount = 0, abortedStale = true,
            )
        }
        val readStartedAt = SystemClock.uptimeMillis()
        val currentWindows = windows
        val windowsReadMs = SystemClock.uptimeMillis() - readStartedAt
        val treeStartedAt = SystemClock.uptimeMillis()
        val timing = WindowReadTimingAccumulator(windowsReadMs)
        var unavailableRoot = false
        var walkTruncated = false
        var visitedNodeCount = 0
        val knownOwn = knownOwnOverlayIdentity
        val snapshots = mutableListOf<KeyguardWindowSnapshot>()
        for (window in currentWindows) {
            if (!authorityIsCurrent(request)) {
                inspectionsAbortedDuringWalk.incrementAndGet()
                return@runCatching SystemWindowsRead(
                    snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                )
            }
            val displayId = if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.R) window.displayId else Display.DEFAULT_DISPLAY
            // Secondary displays cannot decide this default-display overlay's
            // eligibility, so do not pay a root Binder call for them.
            if (displayId != Display.DEFAULT_DISPLAY) continue
            timing.relevantWindows += 1
            val exactKnownOwn = knownOwn != null && knownOwn.windowId == window.id &&
                knownOwn.displayId == displayId && knownOwn.attachGeneration == request.attachGeneration &&
                window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            if (exactKnownOwn) {
                snapshots += KeyguardWindowSnapshot(
                    windowId = window.id,
                    packageName = packageName,
                    type = window.type,
                    layer = window.layer,
                    displayId = displayId,
                    ownOverlay = true,
                    visibleViewIds = emptySet(),
                )
                continue
            }
            if (!authorityIsCurrent(request)) {
                inspectionsAbortedDuringWalk.incrementAndGet()
                return@runCatching SystemWindowsRead(
                    snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                )
            }
            val rootStartedAt = SystemClock.uptimeMillis()
            val root = runCatching { window.root }.getOrNull()
            timing.root(window, displayId, SystemClock.uptimeMillis() - rootStartedAt)
            if (!authorityIsCurrent(request)) {
                root?.recycle()
                inspectionsAbortedDuringWalk.incrementAndGet()
                return@runCatching SystemWindowsRead(
                    snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                    SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                )
            }
            if (root == null) unavailableRoot = true
            val rootPackage = root?.packageName?.toString()
            val own = rootPackage == this.packageName && window.type == AccessibilityWindowInfo.TYPE_ACCESSIBILITY_OVERLAY
            val ids = if (rootPackage in setOf("com.android.systemui", "com.android.keyguard", "android")) {
                root?.let { visibleResourceIds(it, request, window.id, timing) }?.also {
                    walkTruncated = walkTruncated || it.truncated
                    visitedNodeCount += it.visitedNodeCount
                    if (it.abortedStale) {
                        root.recycle()
                        inspectionsAbortedDuringWalk.incrementAndGet()
                        return@runCatching SystemWindowsRead(
                            snapshots, unavailableRoot, walkTruncated, windowsReadMs,
                            SystemClock.uptimeMillis() - treeStartedAt, visitedNodeCount, abortedStale = true,
                        )
                    }
                }?.ids.orEmpty()
            } else {
                emptySet()
            }
            root?.recycle()
            snapshots += KeyguardWindowSnapshot(
                windowId = window.id,
                packageName = rootPackage,
                type = window.type,
                layer = window.layer,
                displayId = displayId,
                ownOverlay = own,
                visibleViewIds = ids,
            )
        }
        val treeElapsedMs = SystemClock.uptimeMillis() - treeStartedAt
        SystemWindowsRead(snapshots, unavailableRoot, walkTruncated, windowsReadMs, treeElapsedMs, visitedNodeCount, timing.snapshot(treeElapsedMs))
    }.getOrDefault(SystemWindowsRead(emptyList(), rootUnavailable = false, walkTruncated = false, windowsReadMs = 0L, treeScanMs = 0L, visitedNodeCount = 0))

    /** Bounded, ID-only traversal. Never read node.text, event.text,
     * contentDescription, input values, screenshots, or foreign app trees. */
    private fun visibleResourceIds(
        root: AccessibilityNodeInfo,
        request: KeyguardCardInspectionRequest,
        windowId: Int,
        timing: WindowReadTimingAccumulator,
    ): VisibleIds {
        val ids = linkedSetOf<String>()
        var visited = 0
        var truncated = false
        var abortedStale = false
        fun visit(node: AccessibilityNodeInfo?) {
            if (node == null) return
            if (!authorityIsCurrent(request)) {
                abortedStale = true
                return
            }
            if (visited >= 96) {
                truncated = true
                return
            }
            visited += 1
            try {
                if (!node.isVisibleToUser) return
                node.viewIdResourceName?.let(ids::add)
                node.className?.toString()?.takeIf { it.contains("BouncerContent") }?.let { ids.add("element:BouncerContent") }
                for (index in 0 until node.childCount) {
                    if (!authorityIsCurrent(request)) {
                        abortedStale = true
                        return
                    }
                    val childStartedAt = SystemClock.uptimeMillis()
                    val child = node.getChild(index)
                    timing.child(windowId, index, SystemClock.uptimeMillis() - childStartedAt)
                    if (!authorityIsCurrent(request)) {
                        nodeReadsAfterInvalidation.incrementAndGet()
                        child?.recycle()
                        abortedStale = true
                        return
                    }
                    visit(child)
                    child?.recycle()
                    if (abortedStale) return
                }
            } catch (_: Exception) {
                // A stale node produces UNKNOWN rather than an unsafe show.
            }
        }
        visit(root)
        return VisibleIds(ids, truncated, visited, abortedStale)
    }

    private fun applyInspection(
        inspection: Inspection,
        request: KeyguardCardInspectionRequest,
        inspectionStartedAt: Long,
        inspectionFinishedAt: Long,
        diagnosticPreparationFinishedAt: Long,
        mainHandoffRequestedAt: Long,
        mainApplyEnteredAt: Long,
        mainHandoffRequestedAtNs: Long,
        mainApplyEnteredAtNs: Long,
        disposition: CompletedDisposition = CompletedDisposition.NORMAL,
        r42Read: CompletedInspection? = null,
    ) {
        // Captured at Main entry before policy/diagnostic work. This can only
        // correlate Fluvi-owned spans; a missing or partial snapshot is not
        // evidence that the uncovered time belongs to GPU, Binder, or the
        // scheduler.
        val mainHandoffEvidence = slowMainHandoffEvidenceSnapshot(
            mainHandoffRequestedAtNs,
            mainApplyEnteredAtNs,
        )
        withMainWorkEvidence(KeyguardMainWorkEvidence.INSPECTION_APPLY, request.id) {
        var decisionObservedAt: Long? = null
        try {
        wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.apply {
            this.inspectionStartedAt = inspectionStartedAt
            this.inspectionFinishedAt = inspectionFinishedAt
        }
        // A provisional successor can revoke the old detached read before
        // Main adopts its wake; the old answer cannot act in that interval.
        if (!authorityIsCurrent(request)) {
            if (inspection.r446Arm != null) r446Apply(inspection, request, disposition, inspectionFinishedAt, mainApplyEnteredAt)
            if (disposition == CompletedDisposition.R32_RESTRICTION_ONLY)
                requestSystemCheck("r32PredecessorAuthorityChanged", evaluate = false)
            traceKeyguard("INSPECTION_REJECTED", "r18AuthorityChanged", request,
                fields = mapOf("rejectionReason" to "r18AuthorityChanged"))
            return
        }
        // A stale Binder walk has no authority over a newer session/epoch.
        // In particular, it must not remove an overlay attached by a later
        // wake inspection.
        when (KeyguardCardInspectionGate.decide(
            expectedSession = request.session,
            currentSession = session.get(),
            expectedEpoch = request.visibilityEpoch,
            currentEpoch = visibilityEpoch.get(),
            expectedInteractionEpoch = request.interactionEpoch,
            currentInteractionEpoch = interactionEpoch.get(),
            expectedAttachGeneration = request.attachGeneration,
            currentAttachGeneration = overlayAttachGeneration,
            expectedWakeGeneration = request.wakeGeneration,
            currentWakeGeneration = wakeEpoch,
            // Unknown acquisition/transition is not a fabricated terminal
            // exclusion. The surface policy below withdraws it nonterminally.
            displayEligibleNow = !inspection.signals.systemStateAvailable ||
                (inspection.signals.interactive && !inspection.signals.displayOff),
            keyguardLockedNow = !inspection.signals.systemStateAvailable || inspection.signals.keyguardLocked,
        )) {
            KeyguardInspectionAction.DROP_STALE -> {
                KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REJECT, request.id, request.attachGeneration, extra = 2)
                // Reject the old surface answer, but independently acquire a
                // CURRENT exclusion check. It cannot hide using old authority.
                requestSystemCheck("staleInspection:${request.id}")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.let {
                    it.rejectedLateResults += 1
                }
                KeyguardCardDiagnostics.record(this, "KG|INSPECTION_STALE", "surfaceEpoch", overlay.isAttached)
                traceKeyguard("INSPECTION_REJECTED", "stale", request, fields = mapOf("rejectionReason" to "surfaceEpoch"))
                return
            }
            KeyguardInspectionAction.HIDE_CURRENT_GATE -> {
                KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.REJECT, request.id, request.attachGeneration, extra = 3)
                hideImmediately(
                    "currentGate",
                    triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                    diagnosticContext = request.diagnosticContext,
                    causingInspectionRequestId = request.id,
                )
                return
            }
            KeyguardInspectionAction.APPLY -> Unit
        }
        // An unresolved same-package/overlay root cannot be attributed to
        // the staged host. Remove it and reacquire normally before showing.
        val r18Owner = r18Active
        if (r18Owner != null && inspection.windowTiming?.ownAttributionAmbiguous == true) {
            failR18Stage(r18Owner, "ambiguousOwnWindow")
            return
        }
        // Recording a window id is also a mutation of current overlay state,
        // so it belongs behind all session/epoch/attach checks.
        inspection.ownOverlayWindowId?.let { windowId ->
            overlay.recordAccessibilityWindowId(windowId, request.attachGeneration)
            if (overlay.isAttached && request.attachGeneration == overlayAttachGeneration) {
                knownOwnOverlayIdentity = KeyguardOwnOverlayIdentity(
                    windowId = windowId,
                    displayId = Display.DEFAULT_DISPLAY,
                    attachGeneration = overlayAttachGeneration,
                )
            }
        }
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
        if (r446Preparing) return
        // This build variant exists solely for the explicit fixed sample. It
        // never resolves or presents a normal financial lockscreen scene.
        if (r448SampleOnly && !KeyguardR44Trial.active) {
            if ((::overlay.isInitialized && overlay.isAttached) || r18Active != null)
                hideImmediately("r448SampleOnly")
            return
        }
        val printCapture = r446CaptureId != null && r446CaptureId == request.diagnosticContext?.captureId
        if (printCapture) {
            if (r446Owner.state == KeyguardR446PrintOwner.State.ISSUED) return
            if (r448DisplayRoute != KeyguardR448DisplayRoute.WIDGETS_ANYWHERE &&
                inspection.r446Arm != null && r446Apply(inspection, request, disposition, inspectionFinishedAt, mainApplyEnteredAt)) return
            if (inspection.r446Eligibility?.reason == "RESTRICTION")
                    r446Cancel("restriction")
            if (r448DisplayRoute == KeyguardR448DisplayRoute.WIDGETS_ANYWHERE) return
        }
        var signals = inspection.signals.copy(requested = settings.requested,
            serviceConnected = FluviKeyguardCardServiceRegistry.connected,
            showFinancialDetails = settings.showFinancialDetails && !KeyguardR44Trial.active)
        var decision = KeyguardCardVisibilityPolicy.decide(signals)
        // Preserve the normal negative/retry machinery, but never grant a
        // second, display-global route during a print-only capture.
        if (printCapture && (decision == KeyguardCardVisibility.SHOW_FULL ||
                decision == KeyguardCardVisibility.SHOW_DISCREET)) return
        if (KeyguardSystemAdmission.requiresFreshRead(overlay.isAttached, appliedDecision, decision)) {
            // The only inspection-apply Main acquisition: actual admission or
            // disclosure increase. One snapshot feeds all final system gates.
            val admission = readSystemState(KeyguardSystemReadPurpose.ADMISSION)
            signals = signalsFromSystemState(settings, signals.surface, admission)
            decision = KeyguardCardVisibilityPolicy.decide(signals)
        }
        if (Build.VERSION.SDK_INT == 37 && settings.presentationMode == KeyguardCardPresentationMode.ORB &&
            (decision == KeyguardCardVisibility.SHOW_FULL || decision == KeyguardCardVisibility.SHOW_DISCREET) &&
            !synchronized(queueLock) { firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, inspection.r19ReadSceneSerial) }) {
            traceKeyguard("INSPECTION_REJECTED", "r44SceneChanged", request,
                fields = mapOf("rejectionReason" to "r44SceneChanged"))
            requestSystemCheck("r44SceneChanged")
            return
        }
        // An obsolete predecessor may reconcile restrictions and own-window
        // identity, but its historical positive can never schedule disclosure.
        if (disposition == CompletedDisposition.R32_RESTRICTION_ONLY &&
            (decision == KeyguardCardVisibility.SHOW_FULL || decision == KeyguardCardVisibility.SHOW_DISCREET)) {
            traceKeyguard("INSPECTION_REJECTED", "r32RestrictionOnly", request,
                fields = mapOf("rejectionReason" to "r32RestrictionOnly"))
            return
        }
        val recovery = r14Recovery
        val boundary = if (recovery != null || inspectionProbeForTest != null) synchronized(queueLock) {
            inspectionQueue.pendingRequest() to SystemClock.uptimeMillis()
        } else null
        inspectionProbeForTest?.beforeDecision(request, decision, boundary?.first, inspectionAuthority)
        decisionObservedAt = boundary?.second ?: SystemClock.uptimeMillis()
        val completeMain = inspection.surfaceReason == KeyguardSurfaceReason.MAIN_CONFIRMED &&
            !inspection.rootUnavailable && !inspection.walkTruncated && !inspection.abortedStale
        // A wake sampler can be eligible while a PIN or shade is present.
        // Count an eligible opening only after this complete, current MAIN
        // read and its actual policy/admission checks have returned positive.
        if (completeMain && decision == KeyguardCardVisibility.SHOW_FULL && signals.systemStateAvailable)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.ELIGIBLE, request.diagnosticContext)
        val mayDefer = recovery != null && !recovery.used && !overlay.isAttached && completeMain &&
            (decision == KeyguardCardVisibility.SHOW_FULL || decision == KeyguardCardVisibility.SHOW_DISCREET)
        if (recovery != null && boundary != null && KeyguardR14ReadmissionPolicy.shouldDefer(
                recovery, inspectionAuthority, settings,
                mayDefer && overlay.eligibleLiveReadmission(settings, lastMaterialProfile), overlay.isAttached,
                surfacePresentationState, completeMain, decision, request, inspectionStartedAt,
                boundary.second, boundary.first,
            )) {
            val used = recovery.copy(used = true, deferredRequestId = request.id,
                pendingRequestId = boundary.first?.id)
            r14Recovery = used
            recordR14Recovery("DEFERRED", used, request, boundary.first,
                observedAt = boundary.second, readStart = inspectionStartedAt, readEnd = inspectionFinishedAt)
            return
        }
        if (recovery?.used == true && !recovery.successorRecorded && recovery.authority.matches(request)) {
            val next = recovery.copy(successorRecorded = true)
            r14Recovery = next
            recordR14Recovery("SUCCESSOR_${decision.name}", next, request, boundary?.first,
                observedAt = decisionObservedAt, readStart = inspectionStartedAt, readEnd = inspectionFinishedAt)
        }
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.DECISION, request.id, request.attachGeneration, extra = decision.ordinal)
        val r42OldOwner = r42Read?.r42ReadOwner
        val r42OldScene = inspection.r19ReadSceneSerial
        var r42PostReason = 0L
        var r42PostPending = 0L
        val r42Stale = when {
            disposition != CompletedDisposition.NORMAL -> { r42PostReason = 1; null }
            r42Read?.r38MilestoneOrdered != true -> { r42PostReason = 2; null }
            r42OldOwner == null -> { r42PostReason = 3; null }
            r42OldScene == null -> { r42PostReason = 4; null }
            inspection.freshnessRevision == null -> { r42PostReason = 5; null }
            !completeMain || decision != KeyguardCardVisibility.SHOW_FULL || !signals.systemStateAvailable -> { r42PostReason = 6; null }
            else -> synchronized(queueLock) {
                val pending = inspectionQueue.pendingRequest()
                r42PostPending = pending?.id ?: 0L
                val scene = firstAuthorizedOrb.sceneSerial()
                val freshness = pending?.let(inspectionFreshness::beforeRead)
                when {
                    !r34SameEmptyOwnerLocked(request, r42OldOwner) -> { r42PostReason = 7; null }
                    pending == null -> { r42PostReason = 8; null }
                    freshness == null -> { r42PostReason = 9; null }
                    !r42ActualLatestLocked(request, pending, scene) -> { r42PostReason = 10; null }
                    firstAuthorizedOrb.isUnclaimedReadCurrent(request.id, r42OldScene) -> { r42PostReason = 11; null }
                    else -> { r42PostReason = 12; R42StaleSuccessor(pending.id, r42OldScene, scene, if (r42OldScene != scene) 1L else 2L) }
                }
            }
        }
        KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_POSTCHECK,
            request.diagnosticContext, request.id, r42PostPending, r42PostReason)
        if (r42Stale != null) {
            r42Read?.r42SuppressedPositive = true
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_STALE_POSITIVE,
                request.diagnosticContext, request.id, r42Stale.requestId, r42Stale.currentScene + 1L)
            KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.R42_STALE_DETAIL,
                request.diagnosticContext, request.id, r42Stale.oldScene + 1L, r42Stale.cause)
            return
        }
        if (decision == KeyguardCardVisibility.SHOW_FULL || decision == KeyguardCardVisibility.SHOW_DISCREET)
            inspectionProbeForTest?.positiveApplyAttempt(request, decision)
        val staged = r18Active
        val r40 = inspection.r40Read
        if (r40 != null) {
            val window = r40.provenance.clockWindowId
            val revision = inspection.freshnessRevision
            val evidence = if (window != null && revision != null && completeMain &&
                decision == KeyguardCardVisibility.SHOW_FULL && overlay.isAttached)
                KeyguardR40WindowEvidence(window, Display.DEFAULT_DISPLAY, r40AppUid, request.id,
                    r40.scene, inspectionStartedAt, inspectionFinishedAt) else null
            val armed = if (evidence == null) false else synchronized(queueLock) {
                val active = inspectionQueue.activeRequest()
                val pending = inspectionQueue.pendingRequest()
                val newer = (active != null && inspectionAuthority.matches(active) && active.id > request.id) ||
                    (pending != null && inspectionAuthority.matches(pending) && pending.id > request.id)
                r18Active === r40.owner && r40.owner.identity === r40.identity &&
                    r40.owner.r40Acknowledged === r40.binding && r40.owner.r21Binding === r40.binding &&
                    r40.owner.host === r40.binding.reveal.host && r40.owner.output === r40.binding.reveal.output &&
                    inspectionAuthority == r40.authority && inspectionAuthority.matches(request) && !newer &&
                    inspection.r19ReadSceneSerial == r40.scene && firstAuthorizedOrb.sceneSerial() == r40.scene &&
                    inspectionFreshness.isEstablished(r40.authority, requireNotNull(revision)) &&
                    r40RemovalGate.armPresented(evidence, r40.binding.reveal, r40.authority, r40.scene, r40AppUid)
            }
            recordR40(r40.owner, r40.identity, if (armed) "ARMED" else "UNATTRIBUTED",
                inspectionFinishedAt, request.id, window)
        }
        if (staged != null && !overlay.isAttached &&
            (decision == KeyguardCardVisibility.SHOW_DISCREET || decision == KeyguardCardVisibility.SHOW_FULL)) {
            if (!prepareR18Decision(staged, request, inspection, decision, settings,
                    inspection.r19ReadSceneSerial, inspectionStartedAt, inspectionFinishedAt)) return
            r18ProofRequestId = request.id
        } else if (staged == null && !overlay.isAttached &&
            (decision == KeyguardCardVisibility.SHOW_DISCREET || decision == KeyguardCardVisibility.SHOW_FULL) &&
            tryStartR18Readmission(request, inspection, settings)) return
        appliedDecision = decision
        when (decision) {
            KeyguardCardVisibility.SHOW_DISCREET -> {
                retryCount = 0
                cancelWakeRetry("shown")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                stopFinancialObservation()
                showEvent = false
                applyPresentation(
                    { FluviFinancialCardPresenter.discreet() },
                    "discreet:${request.trigger}",
                    diagnosticContext = request.diagnosticContext,
                    causingInspectionRequestId = request.id,
                )
            }
            KeyguardCardVisibility.SHOW_FULL -> {
                retryCount = 0
                cancelWakeRetry("shown")
                wakeTiming?.takeIf { it.wakeGeneration == request.wakeGeneration }?.mainKeyguardConfirmedAt = SystemClock.uptimeMillis()
                val focus = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus
                showFullContent(
                    request.session,
                    request.visibilityEpoch,
                    focus.generation,
                    request.trigger,
                    request.diagnosticContext,
                    request.id,
                )
            }
            else -> {
                if (decision == KeyguardCardVisibility.HIDDEN_UNKNOWN || decision == KeyguardCardVisibility.HIDDEN_OCCLUDED) {
                    handleRecoverableSurface(inspection, request, decision)
                } else {
                    hideImmediately(
                        decision.name,
                        triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                        diagnosticContext = request.diagnosticContext,
                        causingInspectionRequestId = request.id,
                    )
                }
            }
        }
        // Detail is deliberately published only after show/hide/awaiting
        // work.  The original decision timestamp remains attached.
        KeyguardCardDiagnostics.record(this, "KG|SURFACE_DECISION", "${decision.name}:${inspection.surfaceReason.name}", overlay.isAttached)
        traceKeyguard(
            "INSPECTION_APPLIED",
            inspection.surfaceReason.name,
            request,
            observedUptimeMs = decisionObservedAt,
            fields = mapOf(
                "decision" to decision.name,
                "surfaceClassification" to inspection.surfaceReason.name,
                "surfaceMarkers" to inspection.surfaceMarkers,
                "systemStateAvailable" to signals.systemStateAvailable,
                "visibilityEpochAtApply" to visibilityEpoch.get(),
                "pendingRequestIdAtApply" to (synchronized(queueLock) {
                    (inspectionQueue.successorForPreceding(request) ?: inspectionQueue.pendingRequest())?.id
                } ?: "NA"),
            ),
        )
        } finally {
            if (r18ProofRequestId == request.id) r18ProofRequestId = null
            val decisionAt = decisionObservedAt
            traceKeyguard(
                "INSPECTION_MAIN_APPLY_STARTED",
                request.trigger,
                request,
                observedUptimeMs = mainApplyEnteredAt,
                deferredFields = { mapOf(
                    "inspectionFinishedAtUptimeMs" to inspectionFinishedAt,
                    "diagnosticPreparationFinishedAtUptimeMs" to diagnosticPreparationFinishedAt,
                    "mainHandoffRequestedAtUptimeMs" to mainHandoffRequestedAt,
                    "mainApplyEnteredAtUptimeMs" to mainApplyEnteredAt,
                    "inspectionFinishToHandoffMs" to (mainHandoffRequestedAt - inspectionFinishedAt),
                    "handoffToMainEntryMs" to (mainApplyEnteredAt - mainHandoffRequestedAt),
                    "mainEntryToDecisionMs" to (decisionAt?.let { it - mainApplyEnteredAt } ?: "NA"),
                ) + (mainHandoffEvidence?.let { it.snapshot.diagnosticFields(it.durationNs) } ?: emptyMap()) },
            )
        }
        }
    }

    /**
     * Retains at most three overlapping, owned Main scopes for a slow handoff
     * in a FULL diagnostic capture.  Endpoint clock is System.nanoTime;
     * nearby Uptime values remain the cross-event timeline clock.  CPU spans
     * are deliberately not summed because they may be nested.
     */
    private data class SlowMainHandoffSnapshot(
        val durationNs: Long,
        val snapshot: KeyguardMainWorkEvidence.Snapshot,
    )

    private fun slowMainHandoffEvidenceSnapshot(fromNs: Long, toNs: Long): SlowMainHandoffSnapshot? {
        if (!KeyguardCardDiagnostics.wantsFullEvidence() || toNs <= fromNs) return null
        val durationNs = toNs - fromNs
        if (durationNs < SLOW_MAIN_HANDOFF_EVIDENCE_NS) return null
        return SlowMainHandoffSnapshot(durationNs, mainWorkEvidence.snapshotOverlapping(fromNs, toNs))
    }

    /**
     * UNKNOWN and OCCLUDED exclude presentation without proving that the
     * physical wake ended. A detached observation must not invalidate newer
     * work. Real withdrawal revokes the old answer, then reacquires the intent.
     */
    private fun handleRecoverableSurface(
        inspection: Inspection,
        request: KeyguardCardInspectionRequest,
        decision: KeyguardCardVisibility,
    ) {
        val compatiblePending = synchronized(queueLock) {
            (inspectionQueue.successorForPreceding(request) ?: inspectionQueue.pendingRequest())
                ?.takeIf(inspectionAuthority::matches)
        }
        val hadCompatiblePending = compatiblePending != null
        // This is only the timer budget. Eligibility is sampled when the
        // fallback fires, independently of local withdrawal and tree work.
        val retryAvailable = retryCount < RETRY_DELAYS_MS.size
        val wasAttached = overlay.isAttached
        val awaitingReason = if (decision == KeyguardCardVisibility.HIDDEN_OCCLUDED) "occluded" else "unknown"
        // A missing/incomplete tree needs one deliberate freshness boundary
        // before a timer retry. A normal event-driven NO_MAIN observation does
        // not: the framework already invalidated the cache for that event.
        // Withdrawing a currently visible presentation is contradictory
        // evidence and therefore also receives a fresh successor.
        val successorFreshness = when {
            wasAttached -> KeyguardWindowFreshness.CONTRADICTORY_OBSERVATION
            inspection.rootUnavailable || inspection.walkTruncated ->
                KeyguardWindowFreshness.MISSING_FRESHNESS_EVIDENCE
            else -> KeyguardWindowFreshness.FRAMEWORK_EVENT
        }
        val beforeVisibilityEpoch = visibilityEpoch.get()
        val transition = KeyguardAwaitingSurfacePolicy.onUnknown(
            current = surfacePresentationState,
            overlayAttached = wasAttached,
            hasCompatiblePendingRequest = hadCompatiblePending,
            retryAvailable = retryAvailable,
        )
        surfacePresentationState = transition.nextState
        if (transition.withdrawVisibleOverlay) {
            val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
            val previousFull = overlay.currentPresentationFull()
            val previousAttach = overlayAttachGeneration
            val qualifies = overlay.visibleRootForReadmission() && previousFull != null &&
                overlay.renderModeStatus().effective == KeyguardOrbRenderMode.SURFACE_LIVE &&
                overlay.eligibleLiveReadmission(settings, lastMaterialProfile)
            val hidden = hideImmediately(
                reason = "${decision.name}:${inspection.surfaceReason.name}",
                terminalWake = false,
                triggerReceivedUptimeMs = request.triggerReceivedUptimeMs,
                diagnosticContext = request.diagnosticContext,
                causingInspectionRequestId = request.id,
                awaitingSurfaceWithdrawal = true,
            )
            if (qualifies && hidden != null && !overlay.isAttached && inspectionAuthority.wakeGeneration == request.wakeGeneration) {
                val recovery = KeyguardR14Recovery(
                    id = ++nextR14RecoveryId, authority = inspectionAuthority,
                    settingsGeneration = settings.generation, layoutRevision = settings.layoutRevision,
                    focusGeneration = settings.focus.generation, full = settings.showFinancialDetails,
                    previousFull = requireNotNull(previousFull), hideOperationId = hidden.hideOperationId,
                    previousAttachment = previousAttach, diagnosticContext = hidden.context,
                )
                r14Recovery = recovery
                recordR14Recovery("WITHDRAWN", recovery, request)
            }
        }
        traceKeyguard(
            "AWAITING_MAIN_SURFACE",
            inspection.surfaceReason.name,
            request,
            fields = mapOf(
                "decision" to decision.name,
                "overlayAttached" to wasAttached,
                "presentationState" to transition.nextState.name,
                "followupAction" to transition.followup.name,
                "pendingRequestId" to (compatiblePending?.id ?: "NA"),
                "visibilityEpochBefore" to beforeVisibilityEpoch,
                // The detached branch deliberately leaves authority alone.
                "visibilityEpochAfter" to visibilityEpoch.get(),
            ),
        )

        if (transition.withdrawVisibleOverlay) {
            // Withdrawal changed authority. Record the obligation under the
            // new authority even when the retry budget is exhausted.
            synchronized(queueLock) {
                inspectionFreshness.require(inspectionAuthority, successorFreshness)
                publishReadAheadSnapshotLocked()
            }
            when (transition.followup) {
                KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING -> {
                    // The queued request was captured under the withdrawn
                    // generation. Replace it exactly once under current
                    // authority; never relabel its old answer as fresh.
                    if (decision == KeyguardCardVisibility.HIDDEN_UNKNOWN) traceKeyguard(
                        "PENDING_REPLACED_AFTER_UNKNOWN",
                        "withdrawalAuthorityChanged",
                        requestId = compatiblePending?.id,
                        diagnosticContext = request.diagnosticContext,
                        fields = mapOf("causingRequestId" to request.id),
                    )
                    val intent = checkNotNull(compatiblePending)
                    freshReconciliationsScheduled.incrementAndGet()
                    scheduleEvaluation(
                        intent.trigger,
                        freshness = successorFreshness,
                        reconciliationIntent = intent,
                    )
                }
                KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK ->
                    scheduleWakeRetry(request, successorFreshness, awaitingReason)
                KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT -> traceKeyguard(
                    "RETRY_BUDGET_EXHAUSTED_AWAITING",
                    "${awaitingReason}Visible",
                    request,
                )
            }
            return
        }

        // Already hidden: do not call hideImmediately. A compatible pending
        // request has the same authority and can run as soon as this active
        // request completes. The active cause itself never counts as future
        // work here.
        synchronized(queueLock) {
            inspectionFreshness.require(inspectionAuthority, successorFreshness)
            publishReadAheadSnapshotLocked()
        }
        when (transition.followup) {
            KeyguardUnknownSurfaceFollowup.CONTINUE_PENDING -> traceKeyguard(
                "RETRY_SUPPRESSED_FOR_PENDING",
                "${awaitingReason}AlreadyHidden",
                request,
            )
            KeyguardUnknownSurfaceFollowup.SCHEDULE_FALLBACK ->
                scheduleWakeRetry(request, successorFreshness, awaitingReason)
            KeyguardUnknownSurfaceFollowup.WAIT_FOR_EVENT -> traceKeyguard(
                "RETRY_BUDGET_EXHAUSTED_AWAITING",
                "${awaitingReason}AlreadyHidden",
                request,
            )
        }
    }

    private fun showFullContent(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        trigger: String,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
    ) {
        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
        val focusChanged = activeFocusGeneration != focusGeneration
        if (focusChanged) {
            showEvent = false
            invalidateFullContent()
            activeFocusGeneration = focusGeneration
        }
        terminalContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation({ FluviFinancialCardPresenter.unavailable(code) }, "invalidFocus:$trigger", diagnosticContext, causingInspectionRequestId)
            return
        }
        transientContentFailure?.takeIf { it.first == focusGeneration }?.let { (_, code) ->
            applyPresentation({ FluviFinancialCardPresenter.unavailable(code) }, "contentUnavailable:$trigger", diagnosticContext, causingInspectionRequestId)
            return
        }
        val cached = renderedFullContent
        val plan = KeyguardCardContentRefreshPolicy.firstOrSurfacePlan(
            focusChanged = focusChanged,
            hasCurrentContent = cached != null && !focusChanged,
            resolveInFlightForFocus = resolvingFocusGeneration == focusGeneration,
        )
        if (cached != null && !focusChanged) {
            applyPresentation({ FluviFinancialCardPresenter.full(cached, showEvent) }, "cached:$trigger", diagnosticContext, causingInspectionRequestId)
        } else if (plan.publishLoading) {
            // First full render only. Repeated same-surface inspection keeps
            // the current amount or existing loading presentation untouched.
            applyPresentation({ FluviFinancialCardPresenter.loading() }, "loading:$trigger", diagnosticContext, causingInspectionRequestId)
        }
        if (r18Active != null && !overlay.isAttached) return
        beginFinancialObservation(
            expectedSession,
            expectedEpoch,
            focusGeneration,
            diagnosticContext,
            causingInspectionRequestId,
        )
        if (plan.startResolve) {
            resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "first", diagnosticContext, causingInspectionRequestId)
        }
    }

    private fun beginFinancialObservation(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
    ) {
        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
        if (coreObservation?.isActive == true && observedFocusGeneration == focusGeneration) return
        stopFinancialObservation(keepRenderedContent = true)
        observedFocusGeneration = focusGeneration
        coreObservation = financialScope.launch {
            val core = com.fluvi.core.FluviCoreFactory.create(applicationContext)
            try {
                var firstEmission = true
                core.query.observeCoreRevision().collectLatest {
                    if (firstEmission) {
                        firstEmission = false
                        return@collectLatest
                    }
                    withContext(Dispatchers.Main.immediate) {
                        resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "coreRevision", diagnosticContext, causingInspectionRequestId)
                    }
                }
            } finally {
                core.close()
            }
        }
    }

    private fun resolveFullContent(
        expectedSession: Long,
        expectedEpoch: Long,
        focusGeneration: Long,
        reason: String,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
    ) {
        check(android.os.Looper.myLooper() == android.os.Looper.getMainLooper())
        // A queued core-revision callback can outlive the subscription that
        // produced it.  It must not start private work in the sample domain.
        if (r448SampleOnly || !r444ConfigurationReady || KeyguardR44Trial.active) return
        if (contentJob?.isActive == true) {
            if (resolvingFocusGeneration == focusGeneration) {
                // A core observer's initial emission commonly follows the
                // explicit first resolve. Coalesce it instead of cancelling
                // the in-flight query and flashing loading again.
                resolveQueued = true
                return
            }
            contentJob?.cancel()
        }
        resolvingFocusGeneration = focusGeneration
        resolveQueued = false
        KeyguardCardDiagnostics.record(this, "KG|RESOLVE_STARTED", reason, overlay.isAttached)
        contentJob = financialScope.launch {
            val focus = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus
            val outcome = when {
                focus.generation != focusGeneration -> FullContentResolveResult.StaleRequest
                !focus.isValid -> FullContentResolveResult.InvalidFocus("missingCategory")
                else -> resolveKeyguardContent(focus)
            }
            withContext(Dispatchers.Main.immediate) {
                try {
                    val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)
                    val ownsPublication = KeyguardCardContentPublicationPolicy.canApply(
                        KeyguardCardContentPublication(
                            requestSession = expectedSession,
                            currentSession = session.get(),
                            requestEpoch = expectedEpoch,
                            currentEpoch = visibilityEpoch.get(),
                            requestFocusGeneration = focusGeneration,
                            currentFocusGeneration = (lastSettings ?: FluviKeyguardCardSettings.read(applicationContext)).focus.generation,
                            currentlyFull = appliedDecision == KeyguardCardVisibility.SHOW_FULL,
                            detailsStillAllowed = settings.showFinancialDetails,
                            displayStillEligible = true,
                        ),
                    )
                    // A rejected financial result needs no remote read. A
                    // genuine new publication still receives its fresh guard.
                    val publicationState = if (ownsPublication) readSystemState(KeyguardSystemReadPurpose.PUBLICATION) else null
                    if (publicationState?.excluded == true) hideImmediately("publicationGate")
                    val stillCurrent = ownsPublication && publicationState?.eligible == true
                    val content = (outcome as? FullContentResolveResult.Ready)?.content
                    if (!stillCurrent || content == null) {
                        if (stillCurrent && outcome is FullContentResolveResult.InvalidFocus) {
                            terminalContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                { FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode) },
                                "invalidFocus:${outcome.diagnosticCode}",
                                diagnosticContext,
                                causingInspectionRequestId,
                            )
                        } else if (stillCurrent && outcome is FullContentResolveResult.Failure) {
                            transientContentFailure = focusGeneration to outcome.diagnosticCode
                            applyPresentation(
                                { FluviFinancialCardPresenter.unavailable(outcome.diagnosticCode) },
                                "contentUnavailable:${outcome.diagnosticCode}",
                                diagnosticContext,
                                causingInspectionRequestId,
                            )
                        }
                        KeyguardCardDiagnostics.record(
                            this@FluviKeyguardCardService,
                            "KG|CONTENT_STALE",
                            if (content == null) "resolve:${outcome.diagnosticCode}" else "contentEpoch",
                            overlay.isAttached,
                        )
                    } else {
                        renderedFullContent = content
                        activeFocusGeneration = focusGeneration
                        terminalContentFailure = null
                        transientContentFailure = null
                        applyPresentation({ FluviFinancialCardPresenter.full(content, showEvent) }, "content", diagnosticContext, causingInspectionRequestId)
                        KeyguardCardDiagnostics.record(this@FluviKeyguardCardService, "KG|CONTENT_APPLIED", "full", overlay.isAttached)
                    }
                } finally {
                    val rerun = resolveQueued && activeFocusGeneration == focusGeneration
                    resolveQueued = false
                    resolvingFocusGeneration = null
                    contentJob = null
                    if (rerun) resolveFullContent(expectedSession, expectedEpoch, focusGeneration, "coalescedRevision", diagnosticContext, causingInspectionRequestId)
                }
            }
        }
    }

    private suspend fun resolveKeyguardContent(focus: KeyguardCardFocus): FullContentResolveResult = try {
        FullContentResolveResult.Ready(
            FluviLockScreenCardCoordinator.resolve(applicationContext, focus.asFinancialFocus()),
        )
    } catch (error: CancellationException) {
        throw error
    } catch (error: IllegalArgumentException) {
        // The resolver's known invalid-focus paths are intentionally distinct
        // from an unavailable database. Do not retain the exception message:
        // it can include implementation details and is not useful on a lock
        // screen diagnostic surface.
        FullContentResolveResult.InvalidFocus("invalidFocus")
    } catch (_: Throwable) {
        FullContentResolveResult.Failure("queryFailure")
    }

    private inline fun applyPresentation(
        presentationFactory: () -> com.fluvi.app.runtime.FluviFinancialCardPresentation,
        reason: String,
        diagnosticContext: KeyguardDiagnosticContext? = currentDiagnosticAttempt,
        causingInspectionRequestId: Long? = null,
    ) {
        val owner = if (diagnosticContext?.captureId != null) KeyguardCardDiagnostics.drawEvidenceOwner() else null
        val scope = owner?.let { com.fluvi.app.runtime.FluviFinancialOrbWork.begin() }
        var operation: KeyguardDiagnosticOperation? = null
        try {
            operation = applyResolvedPresentation(presentationFactory(), reason, diagnosticContext,
                causingInspectionRequestId, scope)
        } finally {
            if (scope != null) {
                if (!scope.completed) scope.finish(false, false, returned = false)
                com.fluvi.app.runtime.FluviFinancialOrbWork.end(scope)
                if (KeyguardR15AcquisitionTestHooks.ENABLED) {
                    KeyguardR15AcquisitionTestHooks.financialCompleted(causingInspectionRequestId, scope)
                }
                if (owner === KeyguardCardDiagnostics.drawEvidenceOwner()) {
                    // Fields are converted to strings by the diagnostic worker.
                    // A capture rotation cannot attach this scope to the new owner.
                    runCatching {
                        KeyguardCardDiagnostics.captureEvent(
                            context = this, stage = "R13_FINANCIAL", reason = "scoped",
                            requestId = causingInspectionRequestId, diagnosticContext = diagnosticContext,
                            operation = operation, attachGeneration = scope.attachment,
                            observedUptimeMs = scope.endUptimeMs,
                            deferredFields = { mapOf(
                                "r13Start" to scope.startUptimeMs, "r13End" to scope.endUptimeMs,
                                "r13WallNs" to scope.wallNs, "r13CpuNs" to scope.cpuNs,
                                "r13Construct" to scope.constructions, "r13Demand" to scope.demands,
                                "r13Paint" to scope.paints, "r13PaintDone" to scope.paintCompletions,
                                "r13Bind" to scope.legacyBinds, "r13Noop" to scope.noOp,
                                "r13Returned" to scope.resultReturned, "r13Success" to scope.successful,
                                "r13PaintWallNs" to scope.paintWallNs, "r13PaintCpuNs" to scope.paintCpuNs,
                                "r13PaintMaxWallNs" to scope.paintMaxWallNs,
                                "r13PaintMaxCpuNs" to scope.paintMaxCpuNs,
                                "r13PaintStart" to scope.firstPaintStartUptimeMs,
                                "r13PaintEnd" to scope.lastPaintEndUptimeMs,
                                "r13Route" to scope.routeCode,
                            ) },
                        )
                    }
                }
            }
        }
    }

    private fun applyResolvedPresentation(
        presentation: com.fluvi.app.runtime.FluviFinancialCardPresentation,
        reason: String,
        diagnosticContext: KeyguardDiagnosticContext?,
        causingInspectionRequestId: Long?,
        scope: com.fluvi.app.runtime.FluviFinancialOrbWork.Scope?,
    ): KeyguardDiagnosticOperation? {
        if (!localPresentationAllowed()) return null
        if (KeyguardR44Trial.active && presentation.full) return null
        if (referenceOwnership != null) referenceLocalPresentationAttempted = true
        val settings = lastSettings ?: FluviKeyguardCardSettings.read(applicationContext).also { lastSettings = it }
        val directOwner = r18Active?.takeIf { !overlay.isAttached }
        val directToken = directOwner?.token
        if (directOwner != null && directToken != null) {
            val proof = r18ProofRequestId
            val continuation = directOwner.firstProof
            if (proof == null || proof != causingInspectionRequestId || directOwner.preparation.full != presentation.full ||
                (directOwner.preparation.emptyAwaitingDisclosure &&
                    (continuation == null || continuation.requestId != proof || !firstAuthorizedOrb.isCurrent(continuation)))) return null
            val stamp = directToken.stamp
            if (!r18Coordinator.grant(directToken, inspectionAuthority, proof, completeMain = true,
                    finalSystemEligible = true, disclosedFull = presentation.full,
                    selectionRevision = stamp.selectionRevision, materialRevision = stamp.materialRevision,
                    dataRevision = stamp.dataRevision)) {
                failR18Stage(directOwner, "grantRejected")
                return null
            }
            if (directOwner.diagnosticContext?.captureId != null &&
                directOwner.diagnosticContext.captureId == KeyguardCardDiagnostics.activeCaptureId()) {
                directOwner.r41GrantRequest = proof
                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.GRANT, directOwner.diagnosticContext,
                    proof, directToken.id, stamp.outputGeneration)
            }
            recordR18(directOwner, "GRANT", proof = proof)
        }
        // `showOrUpdate` applies material only after a real content/layout
        // mutation (or attach). A repeated MAIN_CONFIRMED must not push the
        // same scene through the renderer before it can be called NO_OP.
        wakeTiming?.takeIf { it.wakeGeneration == wakeEpoch && it.attachRequestedAt == null }?.attachRequestedAt =
            SystemClock.uptimeMillis()
        val showOperation = if (!overlay.isAttached) {
            KeyguardCardDiagnostics.newShowOperation(
                context = diagnosticContext,
                attachGeneration = overlayAttachGeneration + 1L,
                causingInspectionRequestId = causingInspectionRequestId,
            )
        } else null
        val showDecisionAt = SystemClock.uptimeMillis()
        activeWindowDiagnosticOperation = showOperation
        setReadAheadShowInProgress(true)
        val result = try {
            // A candidate at the real fallback display call is not yet a
            // proven effective authorization. A matching first-post callback
            // is recorded separately and never fabricates a grant.
            if (directOwner == null && presentation.full &&
                showOperation?.context?.captureId != null) {
                val request = showOperation.causingInspectionRequestId
                val show = showOperation.showOperationId
                val attachment = showOperation.attachGeneration
                if (request != null && show != null && attachment != null)
                    KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.FALLBACK_CANDIDATE,
                        showOperation.context, request, show, attachment)
            }
            overlay.showOrUpdate(presentation, settings, directToken?.stamp?.hostGeneration)
        } finally {
            setReadAheadShowInProgress(false)
            activeWindowDiagnosticOperation = null
        }
        scope?.let {
            it.attachment = showOperation?.attachGeneration ?: overlay.currentAttachGeneration
            it.routeCode = overlay.effectiveRouteForFinancialDiagnostics()
            it.finish(result == KeyguardCardWindow.Result.NO_OP,
                result != KeyguardCardWindow.Result.FAILED && result != KeyguardCardWindow.Result.PENDING)
        }
        if (directOwner != null && directToken != null) {
            if (result != KeyguardCardWindow.Result.ATTACHED) {
                if (r18Coordinator.discardUnpublishedGrant(directToken)) {
                    val proof = directOwner.r41GrantRequest
                    if (proof > 0) KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.CANCEL,
                        directOwner.diagnosticContext, proof)
                    directOwner.r41GrantRequest = 0L
                }
                if (result == KeyguardCardWindow.Result.FAILED) failR18Stage(directOwner, "inputActivationFailed")
                return null
            }
            val host = directOwner.host
            val continuation = directOwner.firstProof
            val inputFailure = when {
                host == null -> "R31_INPUT_HOST_MISSING"
                directOwner.preparation.emptyAwaitingDisclosure &&
                    (continuation == null || !firstAuthorizedOrb.isCurrent(continuation)) -> "R31_INPUT_PROOF_STALE"
                !r18Coordinator.armInput(directToken, host) -> "R31_INPUT_ARM_FAILED"
                else -> null
            }
            if (inputFailure != null) {
                runCatching { recordR18(directOwner, inputFailure, proof = continuation?.requestId) }
                failR18Stage(directOwner, "inputAuthorityFailed")
                return null
            }
        }
        if (result == KeyguardCardWindow.Result.PENDING) {
            if (directOwner == null) r18FallbackWake = wakeEpoch
            return null
        }
        // The operation ID is allocated before attachment, but all capture
        // processing follows WindowManager.addView/showOrUpdate.
        if (showOperation != null) {
            traceKeyguard(
                "SHOW_FOR_ATTACH",
                reason,
                requestId = causingInspectionRequestId,
                attachGeneration = overlayAttachGeneration + 1L,
                observedUptimeMs = showDecisionAt,
                diagnosticContext = diagnosticContext,
                operation = showOperation,
                fields = mapOf(
                    "presentationMode" to settings.presentationMode.name,
                    "rootWasPrepared" to overlay.hasPreparedRoot,
                    "profileWasDecoded" to (lastMaterialProfile != null),
                    "r12Configured" to overlay.renderModeStatus().configured.name,
                    "r12Effective" to overlay.renderModeStatus().effective.name,
                    "r12Privacy" to if (presentation.full) "full" else "discreet",
                    "r12DisplayHz" to (overlay.displayRefreshRate() ?: "UNOBSERVED"),
                ),
            )
            val material = overlay.materialDiagnostics()
            traceKeyguard(
                "SHOW_ATTACH_RENDER_INPUT",
                reason,
                requestId = causingInspectionRequestId,
                attachGeneration = overlayAttachGeneration + 1L,
                diagnosticContext = diagnosticContext,
                operation = showOperation,
                fields = mapOf(
                    "hardwareAccelerated" to (material?.hardwareAccelerated ?: "NA"),
                    "rendererBackend" to (material?.activeRenderer ?: "NA"),
                ),
            )
        }
        when (result) {
            KeyguardCardWindow.Result.ATTACHED -> {
                val previousAuthority = inspectionAuthority
                overlayAttachGeneration = overlay.currentAttachGeneration
                if (directOwner != null && directToken != null &&
                    !r18Coordinator.bindPresentedAttachment(directToken, previousAuthority,
                        previousAuthority.copy(attachGeneration = overlayAttachGeneration))) {
                    failR18Stage(directOwner, "attachmentAuthorityChanged")
                    return null
                }
                surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                knownOwnOverlayIdentity = directOwner?.hostWindowId?.let {
                    KeyguardOwnOverlayIdentity(it, Display.DEFAULT_DISPLAY, overlayAttachGeneration)
                }
                publishInspectionAuthority()
                if (directOwner != null && directToken != null) {
                    // The input host is now enabled. Re-sample the system at
                    // the actual join rather than reusing the wake sample.
                    val finalSystem = readSystemState(KeyguardSystemReadPurpose.ADMISSION)
                    val stamp = directToken.stamp
                    val continuation = directOwner.firstProof
                    // The same queue lock serializes a newly arrived scene
                    // event with the final proof comparison and submit gate.
                    val permit = synchronized(queueLock) {
                        val currentProof = if (directOwner.preparation.emptyAwaitingDisclosure)
                            continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
                        if (finalSystem.eligible) r18Coordinator.queueReveal(directToken,
                            inspectionAuthority, completeMainStillCurrent = currentProof, finalSystemEligible = true,
                            selectionRevision = stamp.selectionRevision, materialRevision = stamp.materialRevision,
                            dataRevision = stamp.dataRevision) else null
                    }
                    if (permit == null) {
                        failR18Stage(directOwner, "finalPublicationCheck")
                        return null
                    }
                    recordR18(directOwner, "INPUT_ARMED")
                    recordR18(directOwner, "REVEAL_QUEUED")
                    val binding = R21Binding(directToken, directOwner.preparation.attachment,
                        directOwner.preparation.outputGeneration,
                        (directOwner.output as? com.fluvi.app.lockscreen.material.KeyguardOrbDirectOutput)?.childId,
                        directOwner.diagnosticContext, permit,
                        if (directOwner.diagnosticContext?.captureId != null) causingInspectionRequestId else null)
                    directOwner.r21Binding = binding
                    overlay.revealR18(directOwner.preparation,
                        boundary = {
                            val crossed: Boolean
                            val ordinal: Long?
                            synchronized(queueLock) {
                                val currentProof = if (directOwner.preparation.emptyAwaitingDisclosure)
                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
                                crossed = localPresentationAllowed() && currentProof && r18Coordinator.crossSubmitBoundary(permit)
                                ordinal = if (crossed) r18Coordinator.revealOrdinal(permit) else null
                            }
                            if (crossed) runCatching { recordR21(binding, "CROSS", SystemClock.uptimeMillis(), ordinal, "CROSSED", "ACCEPTED") }
                            crossed
                        }, nativeApplied = {
                            val at = SystemClock.uptimeMillis()
                            val ordinal = r18Coordinator.markNativeApplyReturned(permit)
                            runCatching { recordR21(binding, "NATIVE_APPLY", at, ordinal, "APPLIED",
                                if (ordinal != null) "ACCEPTED" else "STALE") }
                            ordinal != null
                        }, stillAuthorized = {
                            synchronized(queueLock) {
                                val currentProof = if (directOwner.preparation.emptyAwaitingDisclosure)
                                    continuation != null && firstAuthorizedOrb.isCurrent(continuation) else true
                                localPresentationAllowed() && currentProof && r18Coordinator.isCrossedCurrent(permit)
                            }
                        }, done = { success ->
                            if (r18Active !== directOwner || directOwner.token !== directToken) return@revealR18
                            if (success && r18Coordinator.revealSubmitted(permit)) {
                                recordR18(directOwner, "REVEAL_APPLIED")
                                runCatching { recordR21(binding, "ACK", SystemClock.uptimeMillis(), r18Coordinator.revealOrdinal(permit), "ACKNOWLEDGED", "ACCEPTED") }
                                // Publish an existing binding only; no traversal, allocation or arming here.
                                directOwner.r40Acknowledged = binding
                                KeyguardCardDiagnostics.r41Mark(KeyguardR41RawLedger.WINNER,
                                    binding.context, binding.r41ProofId ?: 0L, directToken.id, binding.outputGeneration)
                            } else if (!success && r18Coordinator.snapshot().grant == KeyguardOrbPresentationCoordinator.Grant.REVEAL_QUEUED)
                                failR18Stage(directOwner, "revealFailed")
                        })
                }
                r14Recovery?.let { recordR14Recovery("ATTACHED", it, requestId = causingInspectionRequestId,
                    showOperation = showOperation?.showOperationId) }
                preservePendingReconciliation("attach", requirePending = true)
                r14Recovery = null
                firstDrawOwner = KeyguardFirstDrawOwner(
                    session = session.get(),
                    wakeGeneration = wakeEpoch,
                    attachGeneration = overlayAttachGeneration,
                    diagnosticOperation = showOperation,
                )
                wakeTiming?.draws?.attach(requireNotNull(firstDrawOwner).identity)
                KeyguardCardDiagnostics.attach(this, "attached")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH", reason, true)
                traceKeyguard(
                    "ATTACH_CONFIRMED",
                    reason,
                    requestId = causingInspectionRequestId,
                    attachGeneration = overlayAttachGeneration,
                    diagnosticContext = diagnosticContext,
                    operation = showOperation,
                )
                publishWakeTiming("attached")
            }
            KeyguardCardWindow.Result.CONTENT_UPDATED,
            KeyguardCardWindow.Result.REDACTED -> {
                if (overlay.isAttached) surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                KeyguardCardDiagnostics.record(this, "KG|CONTENT_UPDATE", "$reason:${result.name}", true)
                traceKeyguard("CONTENT_UPDATED", reason, requestId = causingInspectionRequestId, diagnosticContext = diagnosticContext)
            }
            KeyguardCardWindow.Result.LAYOUT_UPDATED -> {
                if (overlay.isAttached) surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                KeyguardCardDiagnostics.record(this, "KG|LAYOUT_UPDATE", reason, true)
            }
            KeyguardCardWindow.Result.NO_OP -> {
                if (overlay.isAttached) surfacePresentationState = KeyguardSurfacePresentationState.VISIBLE
                traceKeyguard("SURFACE_RECONFIRMED", reason, requestId = causingInspectionRequestId, diagnosticContext = diagnosticContext)
            }
            KeyguardCardWindow.Result.PENDING -> Unit
            KeyguardCardWindow.Result.FAILED -> {
                r14Recovery?.let { recordR14Recovery("ATTACH_FAILED", it, requestId = causingInspectionRequestId,
                    showOperation = showOperation?.showOperationId) }
                r14Recovery = null
                surfacePresentationState = KeyguardSurfacePresentationState.AWAITING_MAIN_SURFACE
                KeyguardCardDiagnostics.attach(this, "failed")
                KeyguardCardDiagnostics.record(this, "KG|ATTACH_FAILED", "window", false)
                traceKeyguard(
                    "ATTACH_FAILED",
                    "window",
                    requestId = causingInspectionRequestId,
                    attachGeneration = overlayAttachGeneration + 1L,
                    diagnosticContext = diagnosticContext,
                    operation = showOperation,
                )
            }
        }
        return showOperation
    }

    private fun toggleView() {
        if (appliedDecision != KeyguardCardVisibility.SHOW_FULL) return
        val content = renderedFullContent ?: return
        showEvent = !showEvent
        applyPresentation({ FluviFinancialCardPresenter.full(content, showEvent) }, "toggle")
    }

    private fun openFocusedFluvi() {
        if (appliedDecision != KeyguardCardVisibility.SHOW_FULL &&
            appliedDecision != KeyguardCardVisibility.SHOW_DISCREET
        ) return
        val focus = FluviKeyguardCardSettings.read(applicationContext).focus
        hideImmediately("open")
        startActivity(
            Intent(this, MainActivity::class.java).apply {
                action = ACTION_OPEN_FOCUS
                putExtra(EXTRA_MODE, focus.mode.name)
                putExtra(EXTRA_AXIS, focus.timeAxis.name)
                putExtra(EXTRA_DIRECTION, focus.direction.name)
                putExtra(EXTRA_CATEGORY, focus.categoryId)
                addFlags(Intent.FLAG_ACTIVITY_NEW_TASK or Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
            },
        )
    }

    /** Main-thread terminal path. It makes the retained root locally invisible
     * and removes it before cancelling database/diagnostic work. A late Binder
     * answer can only fail its captured authority checks afterwards. */
    private fun recoverySlot(slot: KeyguardOrbOwnershipSlotSnapshot?): String = slot?.let {
        "slot:${it.slotId},use:${it.useGeneration},lease:${it.lease?.attachment ?: "NA"}/${it.lease?.generation ?: "NA"},state:${it.state},retired:${it.retired},receipt:${it.callbackReceived},fence:${it.fencePending}"
    } ?: "UNOBSERVED"

    /** Formatted only on the diagnostic consumer from bounded Worker samples. */
    private fun coldWork(sample: KeyguardOrbColdWorkSnapshot?, part: Int): String {
        if (sample == null) return "UNOBSERVED"
        return when (part) {
            0 -> "renderer:${sample.renderer},lease:${sample.attachment}/${sample.generation},slot:${sample.slot}/${sample.use},key:${sample.keyHash},program:${sample.programHash},size:${sample.width}x${sample.height},passes:${sample.passes},prev:${sample.previousValid},primed:${sample.primed}"
            1 -> "config:${sample.configuredAt},callback:${sample.callbackAt ?: "UNOBSERVED"},pending:${sample.callbackPending},frame:${sample.frameAt},frameNs:${sample.frameNs},workerQueue:${sample.workerQueueAt ?: "UNOBSERVED"}"
            2 -> "resources:${sample.resourcesStart}/${sample.resourcesEnd},shader:${sample.shaderStart}/${sample.shaderEnd},submit:${sample.submitBegin ?: "UNOBSERVED"}/${sample.submitEnd ?: "UNOBSERVED"}"
            else -> "result:${sample.resultAt ?: "UNOBSERVED"},status:${sample.resultStatus ?: "UNOBSERVED"},fence:${sample.fenceValid ?: "UNOBSERVED"},state:${sample.disposition}"
        }
    }

    private fun hideImmediately(
        reason: String,
        terminalWake: Boolean = true,
        awaitingSurfaceWithdrawal: Boolean = false,
        triggerReceivedUptimeMs: Long? = null,
        diagnosticContext: KeyguardDiagnosticContext? = currentDiagnosticAttempt,
        causingInspectionRequestId: Long? = null,
    ): KeyguardDiagnosticOperation? {
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HIDE_ENTER, causingInspectionRequestId ?: 0L, overlayAttachGeneration)
        val r18AtHide = r18Active
        sealR18(inspectionAuthority, Long.MAX_VALUE, reason)
        publishReadAheadState(invalidate = true)
        val wasAttachedBefore = ::overlay.isInitialized && overlay.isAttached
        if (terminalWake || wasAttachedBefore) clearR14Recovery(if (terminalWake) "terminal" else "newWithdrawal")
        // Also revoke checks created since an already-idempotent terminal
        // cleanup. This does not wait for their platform calls to return.
        if (terminalWake) systemSampler.clearPending()
        if (!KeyguardTerminalHideGate.shouldProcess(
                terminalWake = terminalWake,
                overlayAttached = wasAttachedBefore || r18AtHide != null,
                serviceSession = session.get(),
                visibilityEpoch = visibilityEpoch.get(),
                previous = terminalHideState,
            )
        ) {
            // The first terminal transition already invalidated all attach
            // authority. Repeating it would only churn epochs, diagnostics and
            // material cleanup while the root is known detached.
            KeyguardCardDiagnostics.recordHiddenNoop(this)
            KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HIDE_RETURN, causingInspectionRequestId ?: 0L, overlayAttachGeneration, extra = 1)
            return null
        }
        val exclusionAt = SystemClock.uptimeMillis()
        val hideOperation = KeyguardCardDiagnostics.newHideOperation(
            context = diagnosticContext,
            attachGeneration = overlayAttachGeneration.takeIf { it > 0 },
            causingInspectionRequestId = causingInspectionRequestId,
            triggerReceivedUptimeMs = triggerReceivedUptimeMs,
        )
        val invalidatedVisibilityEpoch = visibilityEpoch.incrementAndGet()
        interactionEpoch.incrementAndGet()
        // Invalidate publication before the retained root can be detached.
        // Its already-posted observer cleanup remains responsible for removing
        // only its own listener after the framework draw traversal ends.
        firstDrawOwner = null
        wakeTiming?.draws?.detach()
        if (terminalWake) {
            // A later SCREEN_ON must allocate a new physical cycle. A visible
            // surface change inside the same wake does not pass this path.
            wakeCycleOwner.end()
            r18WakeOpen = false
            wakeEpoch += 1L
            cancelWakeRetry("terminalHide")
            synchronized(queueLock) { inspectionQueue.clearPending() }
        }
        knownOwnOverlayIdentity = null
        publishInspectionAuthority(renewSystemWork = !terminalWake)
        surfacePresentationState = if (terminalWake) {
            KeyguardSurfacePresentationState.TERMINALLY_EXCLUDED
        } else {
            KeyguardSurfacePresentationState.WITHDRAWN_AWAITING_SURFACE
        }
        publishReadAheadState()
        appliedDecision = KeyguardCardVisibility.HIDDEN_UNKNOWN
        showEvent = false
        val dragWasActive = ::overlay.isInitialized && overlay.isDragActive
        var removeReturnedAt: Long? = null
        var localHideBeginAt: Long? = null
        var attachedRootRemoved = false
        var retiredSurface: RetiredSurfaceEvidence? = null
        if (::overlay.isInitialized) {
            localHideBeginAt = SystemClock.uptimeMillis()
            activeWindowDiagnosticOperation = hideOperation
            val removed = try {
                val onLayerHideCommitted: ((Long) -> Unit)? =
                    if (wasAttachedBefore && hideOperation.context?.captureId != null &&
                        KeyguardCardDiagnostics.wantsEvent("ISOLATED_LAYER_HIDE_COMMIT_RECEIVED")
                    ) { receivedAt ->
                        // This closure is bound to the original operation;
                        // never recover ownership from a later active hide.
                        traceKeyguard(
                            "ISOLATED_LAYER_HIDE_COMMIT_RECEIVED", "transactionCommitNotPhysicalRemoval",
                            observedUptimeMs = receivedAt,
                            attachGeneration = hideOperation.attachGeneration,
                            operation = hideOperation,
                        )
                    } else null
                val onRetirementEvent: ((KeyguardOrbRetirementEvent) -> Unit)? =
                    if (wasAttachedBefore && hideOperation.context?.captureId != null &&
                        KeyguardCardDiagnostics.wantsEvent("R09_RETIREMENT")
                    ) { event ->
                        traceKeyguard("R09_RETIREMENT", event.reason,
                            observedUptimeMs = event.observedAtUptimeMs,
                            attachGeneration = hideOperation.attachGeneration,
                            operation = hideOperation,
                            deferredFields = { mapOf(
                                "r09Stage" to event.stage,
                                "r09Lease" to "${event.lease.attachment}/${event.lease.generation}",
                                "r09Child" to event.childIdentity,
                                "r09Slot" to (event.slotId ?: "UNOBSERVED"),
                                "r09Use" to (event.useGeneration ?: "UNOBSERVED"),
                            ) })
                    } else null
                val onSurfaceRevoked: ((Long, Long, com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics,
                    com.fluvi.app.lockscreen.material.KeyguardOrbSurfaceMetrics.HolderOperation) -> Unit)? =
                    if (wasAttachedBefore && hideOperation.context?.captureId != null &&
                        KeyguardCardDiagnostics.wantsEvent("R15_SURFACE_REVOKED")) {
                        { attach, generation, metrics, atRevoke ->
                            retiredSurface = RetiredSurfaceEvidence(attach, generation, metrics, atRevoke)
                        }
                    } else null
                overlay.hide(onLayerHideCommitted, onRetirementEvent, onSurfaceRevoked)
            } finally {
                activeWindowDiagnosticOperation = null
            }
            removeReturnedAt = SystemClock.uptimeMillis()
            attachedRootRemoved = wasAttachedBefore && removed && !overlay.isAttached
            finishR18AfterWindow(r18AtHide)
            if (r18Active == null && !overlay.isAttached && FluviKeyguardCardServiceRegistry.connected &&
                lastSettings?.requested == true && r18FallbackWake != wakeEpoch &&
                reason != "unbind" && reason != "destroy" && reason != "settings") {
                overlay.prepareR18()
                refreshR18RouteOnMain()
            }
            publishReadAheadState()
            if (wasAttachedBefore && KeyguardCardDiagnostics.wantsEvent("ATTACHMENT_RENDER_SUMMARY")) {
                val summary = overlay.attachmentRenderSummary()
                if (summary != null) traceKeyguard(
                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
                    requestId = causingInspectionRequestId,
                    observedUptimeMs = removeReturnedAt,
                    operation = hideOperation,
                    deferredFields = { mapOf(
                        "clockCallbacks" to summary.clockCallbacks,
                        "isolatedFramesProduced" to summary.isolatedFramesProduced,
                        "isolatedFramesPublished" to summary.isolatedFramesPublished,
                        "isolatedFramesDropped" to summary.isolatedFramesDropped,
                        "isolatedTranslucentSteadySkipped" to summary.isolatedTranslucentSteadySkipped,
                        "isolatedCompletionGapMaxMs" to summary.isolatedCompletionGapMaxMs,
                        "r09Placement" to "submitted:${summary.positionSubmissions},suppressed:${summary.positionSuppressions}",
                        "r10Cold0" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 0),
                        "r10Cold0b" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 1),
                        "r10Cold0c" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 2),
                        "r10Cold0d" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(0), 3),
                        "r10Cold1" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 0),
                        "r10Cold1b" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 1),
                        "r10Cold1c" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 2),
                        "r10Cold1d" to coldWork(summary.coldWork.filter { it.attachment == 0L }.getOrNull(1), 3),
                        "r10Live0" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 0),
                        "r10Live0b" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 1),
                        "r10Live0c" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 2),
                        "r10Live0d" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(0), 3),
                        "r10Live1" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 0),
                        "r10Live1b" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 1),
                        "r10Live1c" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 2),
                        "r10Live1d" to coldWork(summary.coldWork.filter { it.attachment > 0L }.getOrNull(1), 3),
                        "r09FirstWork" to (summary.firstWork?.let {
                            "attach:${it.attachment},gen:${it.generation},request:${it.requestedAt},start:${it.startedAt ?: "UNOBSERVED"},result:${it.resultAt ?: "UNOBSERVED"},status:${it.resultStatus ?: "UNOBSERVED"}"
                        } ?: "UNOBSERVED"),
                        "r09FirstFrames" to (summary.firstWork?.let {
                            "workerAck:${it.firstAt ?: "UNOBSERVED"}:${it.firstSlot ?: "UNOBSERVED"}/${it.firstUse ?: "UNOBSERVED"},steadyApply:${it.secondAt ?: "UNOBSERVED"}:${it.secondSlot ?: "UNOBSERVED"}/${it.secondUse ?: "UNOBSERVED"}"
                        } ?: "UNOBSERVED"),
                        "isolatedFirstIdentity" to (summary.isolatedFirstHandoff?.let {
                            "first/direct:attach:${it.attachment},generation:${it.generation},slot:${it.slotId},use:${it.useGeneration},child:${it.childIdentity}"
                        } ?: "UNOBSERVED"),
                        "isolatedFirstReady" to (summary.isolatedFirstHandoff?.times?.let {
                            "ready:${it.readyAtUptimeMs},post:${it.postedAtUptimeMs},main:${it.mainEntryAtUptimeMs},applyBegin:${it.applyBeginAtUptimeMs},applyEnd:${it.applyEndAtUptimeMs}"
                        } ?: "UNOBSERVED"),
                        "isolatedFirstCommit" to (summary.isolatedFirstHandoff?.let {
                            "receipt:${it.commitReceiptAtUptimeMs ?: "UNOBSERVED"},main:${it.commitMainAtUptimeMs ?: "UNOBSERVED"},bootstrapRetired:${it.bootstrapRetiredAtUptimeMs ?: "UNOBSERVED"}"
                        } ?: "UNOBSERVED"),
                        "r22Passive" to (summary.passiveStandby?.let {
                            "backend:${it.backend},eligible:${it.eligibility},lease:${it.attachment}/${it.generation},draw:${it.firstDrawAtUptimeMs ?: "UNOBSERVED"},exit:${it.lastExitReason}"
                        } ?: "backend:UNAVAILABLE,eligible:UNAVAILABLE,lease:UNAVAILABLE,draw:UNOBSERVED,exit:UNAVAILABLE"),
                        "r08Route" to summary.effectiveRoute,
                        "r08Origin" to (summary.recovery?.let {
                            "${if (it.inherited) "inherited" else "entered"}:renderer:${it.rendererId},attach:${it.originAttachment},gen:${it.originGeneration},child:${it.childId},grant:${it.grantId},cause:${it.reason}"
                        } ?: "UNOBSERVED"),
                        "r08Times" to (summary.recovery?.let {
                            "start:${it.startedAt},offer:${it.offeredAt},claim:${it.claimedAt ?: "UNOBSERVED"},draw:${it.firstViewDrawAt ?: "UNOBSERVED"},restore:${it.restoredAt ?: "UNOBSERVED"},n:${it.opportunities}"
                        } ?: "UNOBSERVED"),
                        "r08Anchor" to (summary.recovery?.anchor?.let {
                            "elapsed:${it.elapsedSeconds},phase:${it.phase},background:${it.backgroundPhase},interior:${it.interiorPhase}"
                        } ?: "UNOBSERVED"),
                        "r08Transition" to (summary.recovery?.transitionPreserved ?: "UNOBSERVED"),
                        "r08Slot0" to recoverySlot(summary.recovery?.slots?.getOrNull(0)),
                        "r08Slot1" to recoverySlot(summary.recovery?.slots?.getOrNull(1)),
                        "r08Slot2" to recoverySlot(summary.recovery?.slots?.getOrNull(2)),
                        "r08Worker" to (summary.worker?.takeIf { it.workerSampleAtUptimeMs > 0L }?.let {
                            val reason = when (it.workerBlockReason) {
                                1 -> "notEligible"; 2 -> "readyMain"; 3 -> "noFree"; 4 -> "wrongSize"; 5 -> "active"; else -> "unknown"
                            }
                            "seq:${it.workerSampleSequence},age:${(summary.observedAt - it.workerSampleAtUptimeMs).coerceAtLeast(0L)},desired:${it.workerDesiredAttachment}/${it.workerDesiredGeneration},attached:${it.workerAttachedAttachment}/${it.workerAttachedGeneration},reason:$reason"
                        } ?: "UNOBSERVED"),
                        "r08Grant" to (summary.worker?.takeIf { it.workerSampleAtUptimeMs > 0L }?.let {
                            "id:${it.workerGrantIdentity},lease:${it.workerGrantAttachment}/${it.workerGrantGeneration},active:${it.workerGrantActive},running:${it.workerRunning}"
                        } ?: "UNOBSERVED"),
                        "r08Progress" to (summary.worker?.takeIf { it.workerSampleAtUptimeMs > 0L }?.let {
                            "completedAt:${it.workerLastCompletionAtUptimeMs.takeIf { value -> value > 0L } ?: "UNOBSERVED"},inFlight:${it.inFlight},ready:${it.ready},owned:${it.compositorOwned}"
                        } ?: "UNOBSERVED"),
                        "shaderFrames" to summary.orb.frames,
                        "shaderCalls" to summary.shaderCalls,
                        "phaseAdvances" to summary.phaseAdvances,
                        "firstPhase" to (summary.orb.firstPhase ?: "NA"),
                        "lastPhase" to (summary.orb.lastPhase ?: "NA"),
                        "firstShaderTraversalAt" to (summary.orb.firstAt ?: "NA"),
                        "lastShaderTraversalAt" to (summary.orb.lastAt ?: "NA"),
                        "drawGapCount" to summary.orb.gaps,
                        "drawGapTotalMs" to summary.orb.gapTotalMs,
                        "drawGapMaxMs" to summary.orb.gapMaxMs,
                        "drawInvalidOrder" to summary.orb.invalidOrder,
                        "backgroundFrames" to summary.background.frames,
                        "animationStarts" to summary.animationStarts,
                        "animationStops" to summary.animationStops,
                        "clockRunning" to summary.clockRunning,
                        "liveState" to summary.liveState,
                        "drawEvidenceMode" to "cpuSubmissionNotPresentation",
                        "drawEvidenceOmitted" to (summary.orbGaps.omittedGaps + summary.backgroundGaps.omittedGaps),
                        "drawObserverNs" to (summary.orbGaps.observerNs + summary.backgroundGaps.observerNs),
                        "drawObservedFrames" to summary.orbGaps.observedDraws,
                        "drawUnpairedFrames" to summary.orbGaps.unpairedDraws,
                        "drawCoalescedCallbacks" to summary.orbGaps.coalescedCallbacks,
                        "drawEvidenceBreaks" to summary.orbGaps.samplingBreaks,
                        "drawEvidenceRejected" to summary.orbGaps.rejected,
                        "orbDrawGaps" to summary.orbGaps.compact(),
                        "backgroundDrawGaps" to summary.backgroundGaps.compact(),
                    ) },
                ) else traceKeyguard(
                    "ATTACHMENT_RENDER_SUMMARY", "withdrawalBoundary",
                    requestId = causingInspectionRequestId,
                    observedUptimeMs = removeReturnedAt,
                    operation = hideOperation,
                    fields = mapOf("r22Passive" to "backend:DIRECT,eligible:UNAVAILABLE,lease:UNAVAILABLE,draw:UNOBSERVED,exit:UNAVAILABLE"),
                )
            }
            if (wasAttachedBefore && removed) KeyguardCardDiagnostics.record(this, "KG|DETACH", reason, false)
            if (!wasAttachedBefore) traceKeyguard(
                "HIDE_NOOP_ALREADY_HIDDEN",
                reason,
                requestId = causingInspectionRequestId,
                observedUptimeMs = removeReturnedAt,
                diagnosticContext = diagnosticContext,
                operation = hideOperation,
            )
            // A failed remove still leaves meaningful terminal cleanup to a
            // later exclusion signal; do not install the idempotent guard.
            if (terminalWake && (!wasAttachedBefore || removed || !overlay.isAttached)) {
                terminalHideState = KeyguardTerminalHideState(session.get(), invalidatedVisibilityEpoch)
            }
        }
        // Visibility and removal have already run.  Publish the exact
        // timestamps afterwards so recording cannot delay the critical path.
        traceKeyguard(
            "HIDE_DECIDED",
            reason,
            requestId = causingInspectionRequestId,
            observedUptimeMs = exclusionAt,
            attachGeneration = overlayAttachGeneration.takeIf { it > 0 },
            diagnosticContext = diagnosticContext,
            operation = hideOperation,
            fields = mapOf(
                "triggerReceivedUptimeMs" to (triggerReceivedUptimeMs ?: "NA"),
                "terminalWake" to terminalWake,
                "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
                "visibilityEpochBefore" to (invalidatedVisibilityEpoch - 1L),
            ),
        )
        retiredSurface?.let { (attachment, generation, metrics, atRevoke) ->
            // Bound to the actual captured child and hide operation. Worker
            // completion after removal can update only this generation's
            // primitive metrics, not the current service operation.
            traceKeyguard("R15_SURFACE_REVOKED", "synchronousAccessClosure",
                observedUptimeMs = removeReturnedAt, attachGeneration = attachment,
                operation = hideOperation, surfaceMetrics = metrics, deferredFields = { mapOf(
                    "r15TargetAttachment" to attachment, "r15Generation" to generation,
                    "r15AtRevoke" to "${atRevoke.coherent}:${atRevoke.id}:${atRevoke.lockEnter ?: "UNOBSERVED"}/${atRevoke.lockReturn ?: "UNOBSERVED"}:${atRevoke.drawReturn ?: "UNOBSERVED"}:${atRevoke.postEnter ?: "UNOBSERVED"}/${atRevoke.postReturn ?: "UNOBSERVED"}:${atRevoke.recordAt ?: "UNOBSERVED"}",
                ) })
        }
        localHideBeginAt?.let { localHideAt ->
            traceKeyguard(
                "LOCAL_HIDE_BEGIN",
                reason,
                requestId = causingInspectionRequestId,
                observedUptimeMs = localHideAt,
                attachGeneration = overlayAttachGeneration.takeIf { it > 0 },
                diagnosticContext = diagnosticContext,
                operation = hideOperation,
                fields = mapOf(
                    "attachedBefore" to wasAttachedBefore,
                    "dragActive" to dragWasActive,
                    "awaitingSurfaceWithdrawal" to awaitingSurfaceWithdrawal,
                ),
            )
        }
        // Window visibility is already withdrawn; only now cancel potentially
        // blocking work and persist the compact diagnostic summary.
        stopFinancialObservation()
        KeyguardCardDiagnostics.record(
            this,
            "KG|HIDE_TIMING",
            "source=$reason|exclusionToHideRequestMs=" +
                (triggerReceivedUptimeMs?.let { exclusionAt - it } ?: -1L) +
                "|exclusionToRemoveReturnMs=" +
                (removeReturnedAt?.minus(exclusionAt) ?: -1L) +
                "|cancelledWakeJobs=${if (terminalWake) 1 else 0}|dragWasActive=$dragWasActive|rollbackLayoutCallsDuringHide=0",
            false,
        )
        traceKeyguard(
            "HIDE_COMPLETED",
            reason,
            requestId = causingInspectionRequestId,
            observedUptimeMs = removeReturnedAt ?: SystemClock.uptimeMillis(),
            diagnosticContext = diagnosticContext,
            operation = hideOperation,
            fields = mapOf(
                "signalToDecisionMs" to (triggerReceivedUptimeMs?.let { exclusionAt - it } ?: "NA"),
                "signalToRemoveReturnMs" to (triggerReceivedUptimeMs?.let { signal -> removeReturnedAt?.minus(signal) } ?: "NA"),
                "attachedAfter" to (::overlay.isInitialized && overlay.isAttached),
                "dragActive" to dragWasActive,
            ),
        )
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.HIDE_RETURN, causingInspectionRequestId ?: 0L, overlayAttachGeneration)
        return hideOperation.takeIf { attachedRootRemoved }
    }

    /** Both callbacks arrive after their draw stacks have unwound. The event
     * still carries its original attach id, so a wake A callback cannot write
     * timing into wake B after a fast lock/unlock/reattach sequence. */
    private fun recordFirstRootPreDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        traceKeyguard("FIRST_ROOT_PREDRAW", "observed", attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs, operation = owner.diagnosticOperation,
            deferredFields = { mapOf("r09RootSize" to "${event.rootWidth}x${event.rootHeight}",
                "r09TargetSize" to if (event.targetWidth > 0 && event.targetHeight > 0)
                    "${event.targetWidth}x${event.targetHeight}" else "UNOBSERVED",
                "r09AttachState" to event.attachStateAtRegistration) })
    }

    private fun recordFirstRootDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        val timing = wakeTiming?.takeIf { it.wakeGeneration == owner.wakeGeneration } ?: return
        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.ROOT, event.observedAtUptimeMs) {
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_ROOT_DRAW", event.observedAtUptimeMs)
            traceKeyguard(
                "FIRST_ROOT_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            publishWakeTiming("firstRootDraw")
        }
    }

    private fun recordFirstShaderDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        val timing = wakeTiming?.takeIf { it.wakeGeneration == owner.wakeGeneration } ?: return
        timing.draws.record(owner.identity, KeyguardDrawPublication.Stage.SHADER, event.observedAtUptimeMs) {
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_SHADER_DRAW", event.observedAtUptimeMs)
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_CURRENT_MATERIAL_DRAW", event.observedAtUptimeMs)
            KeyguardCardDiagnostics.recordColdPreparation(session.get(), "FIRST_LIVE_DRAW", event.observedAtUptimeMs)
            traceKeyguard(
                "FIRST_SHADER_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            traceKeyguard(
                "FIRST_CURRENT_MATERIAL_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            traceKeyguard(
                "FIRST_LIVE_DRAW",
                "observed",
                attachGeneration = event.attachGeneration,
                observedUptimeMs = event.observedAtUptimeMs,
                operation = owner.diagnosticOperation,
            )
            publishWakeTiming("firstShaderDraw")
        }
    }

    private fun recordBootstrapDraw(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "BOOTSTRAP_DRAW", event.observedAtUptimeMs)
        traceKeyguard(
            "BOOTSTRAP_DRAW",
            "paletteFallbackNotPhysicalPresentation",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    private fun recordBootstrapCommit(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(
            session.get(),
            "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED",
            event.observedAtUptimeMs,
        )
        traceKeyguard(
            "BOOTSTRAP_COMMIT_CALLBACK_RECEIVED",
            "rendererCommittedNotPhysicalPresentation",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    private fun recordLivePromotion(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(session.get(), "MATERIAL_LIVE_PROMOTED", event.observedAtUptimeMs)
        traceKeyguard(
            "MATERIAL_LIVE_PROMOTED",
            "sameRetainedAttachment",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    /** Frame commit is closer to renderer completion than Canvas.onDraw, but
     * is still not a physical-display presentation timestamp. */
    private fun recordFirstFrameCommit(event: KeyguardFirstDrawEvent) {
        val owner = firstDrawOwner ?: return
        if (!owner.accepts(event, session.get(), wakeEpoch, overlayAttachGeneration)) return
        KeyguardCardDiagnostics.recordColdPreparation(
            session.get(),
            "FRAME_COMMIT_CALLBACK_RECEIVED",
            event.observedAtUptimeMs,
        )
        traceKeyguard(
            "FRAME_COMMIT_CALLBACK_RECEIVED",
            "rendererCommittedNotPhysicalPresentation",
            attachGeneration = event.attachGeneration,
            observedUptimeMs = event.observedAtUptimeMs,
            operation = owner.diagnosticOperation,
        )
    }

    private fun publishWakeTiming(stage: String) {
        val timing = wakeTiming ?: return
        val queue = timing.inspectionStartedAt?.minus(timing.inspectionQueuedAt ?: timing.inspectionStartedAt ?: 0L)
        val inspect = timing.inspectionFinishedAt?.minus(timing.inspectionStartedAt ?: timing.inspectionFinishedAt ?: 0L)
        val confirmedToAttach = timing.attachRequestedAt?.minus(timing.mainKeyguardConfirmedAt ?: timing.attachRequestedAt ?: 0L)
        val attachToDraw = timing.draws.firstRootAt?.minus(timing.addViewReturnedAt ?: timing.draws.firstRootAt ?: 0L)
        val callbackToDraw = timing.draws.firstRootAt?.minus(timing.wakeReceivedAt)
        KeyguardCardDiagnostics.record(
            this,
            "KG|WAKE_TIMING",
            "stage=$stage|wake=${timing.wakeGeneration}|eventAgeMs=${timing.eventAgeMs ?: -1L}|inspectionQueueMs=${queue ?: -1L}|" +
                "inspectionDurationMs=${inspect ?: -1L}|confirmedToAttachMs=${confirmedToAttach ?: -1L}|" +
                "attachToFirstDrawMs=${attachToDraw ?: -1L}|callbackToFirstDrawMs=${callbackToDraw ?: -1L}|" +
                "firstShaderDrawAt=${timing.draws.firstShaderAt ?: -1L}|" +
                "retryCount=${timing.retryCount}|rootWasPrepared=${timing.rootWasPrepared}|" +
                "profileWasDecoded=${timing.profileWasDecoded}|presentationMode=${timing.presentationMode}|" +
                "rejectedLateResults=${timing.rejectedLateResults}",
            overlay.isAttached,
        )
    }

    internal fun materialDiagnostics(): Map<String, Any?> {
        val values = if (::overlay.isInitialized) overlay.materialDiagnostics() else null
        val profile = if (r448SampleOnly) null else FluviKeyguardMaterialStore.read(applicationContext)
        val focus = FluviKeyguardCardSettings.read(applicationContext).focus
        return mapOf(
            "overlayAttached" to (::overlay.isInitialized && overlay.isAttached),
            "appliedVisibility" to appliedDecision.name,
            "systemRecurringReads" to systemReads.get(KeyguardSystemReadPurpose.RECURRING.ordinal),
            "systemRecurringMainReads" to mainSystemReads.get(KeyguardSystemReadPurpose.RECURRING.ordinal),
            "systemAdmissionMainReads" to mainSystemReads.get(KeyguardSystemReadPurpose.ADMISSION.ordinal),
            "systemPublicationMainReads" to mainSystemReads.get(KeyguardSystemReadPurpose.PUBLICATION.ordinal),
            "systemSamplerMaximumActive" to systemSampler.maximumActive,
            "systemSamplerMaximumPending" to systemSampler.maximumPending,
            "systemSamplerStaleRejected" to systemSampler.rejected,
            // `rendererBackend` remains for older Flutter diagnostics; the
            // requested/active pair tells whether AGSL actually compiled and
            // drew instead of merely being available on this API level.
            "rendererBackend" to values?.activeRenderer,
            "requestedRenderer" to values?.requestedRenderer,
            "activeRenderer" to values?.activeRenderer,
            "r08EffectiveRoute" to values?.effectiveRoute,
            "r08Attachment" to (values?.attachment ?: 0L),
            "r08RecoveryGeneration" to (values?.recoveryGeneration ?: 0L),
            "r08RecoveryRestoredAt" to values?.recoveryRestoredAt,
            "r08AttachmentShaderCalls" to (values?.attachmentShaderCalls ?: 0),
            "r08AttachmentShaderTraversals" to (values?.attachmentShaderTraversals ?: 0L),
            "r08AttachmentPhaseAdvances" to (values?.attachmentPhaseAdvances ?: 0),
            "hardwareAccelerated" to (values?.hardwareAccelerated ?: false),
            "shaderCreationCount" to (values?.shaderCreationCount ?: 0),
            "shaderPreparationRequests" to (values?.preparationRequests ?: 0),
            "shaderPreparationCompletions" to (values?.preparationCompletions ?: 0),
            "shaderPreparationFailures" to (values?.preparationFailures ?: 0),
            "gpuPreparationRequests" to (values?.gpuPreparationRequests ?: 0),
            "gpuPreparationCompletions" to (values?.gpuPreparationCompletions ?: 0),
            "gpuPreparationFailures" to (values?.gpuPreparationFailures ?: 0),
            "coldPresentationState" to values?.coldPresentationState,
            "shaderArtifactLoadCount" to (values?.artifactLoadCount ?: 0),
            "shaderArtifactMetadataParseCount" to (values?.artifactMetadataParseCount ?: 0),
            "animationStartCount" to (values?.animationStartCount ?: 0),
            "animationStopCount" to (values?.animationStopCount ?: 0),
            "drawCount" to (values?.frameCallbackCount ?: 0),
            "frameCallbackCount" to (values?.frameCallbackCount ?: 0),
            // The standalone API-34 ORB uses its renderer-thread
            // Choreographer, so its actual completed/published buffer counts
            // must not be represented as ViewRoot callbacks.
            "isolatedOrbFramesProduced" to (values?.isolatedFramesProduced ?: 0),
            "isolatedOrbFramesPublished" to (values?.isolatedFramesPublished ?: 0),
            "isolatedOrbFramesDropped" to (values?.isolatedFramesDropped ?: 0),
            "isolatedOrbFramesInFlight" to (values?.isolatedFramesInFlight ?: 0),
            "isolatedOrbFramesReady" to (values?.isolatedFramesReady ?: 0),
            "isolatedOrbFramesCompositorOwned" to (values?.isolatedFramesCompositorOwned ?: 0),
            "isolatedOrbWorkerRunning" to (values?.isolatedWorkerRunning ?: false),
            "isolatedOrbWorkerDesiredAttachment" to (values?.isolatedWorkerDesiredAttachment ?: -1L),
            "isolatedOrbWorkerDesiredGeneration" to (values?.isolatedWorkerDesiredGeneration ?: -1L),
            "isolatedOrbWorkerAttachedAttachment" to (values?.isolatedWorkerAttachedAttachment ?: -1L),
            "isolatedOrbWorkerAttachedGeneration" to (values?.isolatedWorkerAttachedGeneration ?: -1L),
            "isolatedOrbCompletionGapMaxMs" to (values?.isolatedCompletionGapMaxMs ?: 0L),
            "frameIntervalP50" to (values?.frameIntervalP50 ?: 0),
            "frameIntervalP95" to (values?.frameIntervalP95 ?: 0),
            "largeFrameGapCount" to (values?.largeFrameGapCount ?: 0),
            "materialConfigurationUpdateCount" to (values?.configurationUpdateCount ?: 0),
            "materialConfigurationNoOpCount" to (values?.configurationNoOpCount ?: 0),
            "lastRendererFailure" to values?.rendererFailure,
            "shaderCompileAttempts" to ((values?.orb?.shaderCompileAttempts ?: 0) + (values?.background?.shaderCompileAttempts ?: 0)),
            "shaderCompileSuccesses" to ((values?.orb?.shaderCompileSuccesses ?: 0) + (values?.background?.shaderCompileSuccesses ?: 0)),
            "shaderCompileFailures" to ((values?.orb?.shaderCompileFailures ?: 0) + (values?.background?.shaderCompileFailures ?: 0)),
            "onDrawCount" to ((values?.orb?.onDrawCount ?: 0) + (values?.background?.onDrawCount ?: 0)),
            "shaderDrawCount" to ((values?.orb?.shaderDrawCount ?: 0) + (values?.background?.shaderDrawCount ?: 0)),
            "bootstrapDrawCount" to ((values?.orb?.bootstrapDrawCount ?: 0) + (values?.background?.bootstrapDrawCount ?: 0)),
            "fallbackDrawCount" to ((values?.orb?.fallbackDrawCount ?: 0) + (values?.background?.fallbackDrawCount ?: 0)),
            "phaseAdvanceCount" to ((values?.orb?.phaseAdvanceCount ?: 0) + (values?.background?.phaseAdvanceCount ?: 0)),
            "transitionCompletedCount" to ((values?.orb?.transitionCompletedCount ?: 0) + (values?.background?.transitionCompletedCount ?: 0)),
            "lastFailureStage" to (values?.orb?.failureStage ?: values?.background?.failureStage),
            "lastFailureClass" to (values?.orb?.failureClass ?: values?.background?.failureClass),
            "lastFailureMessage" to (values?.orb?.failureMessage ?: values?.background?.failureMessage),
            "shaderSourceHash" to (profile?.sourceShaderHash ?: values?.orb?.generatedAgslHash),
            "generatedAgslHash" to (values?.orb?.generatedAgslHash ?: values?.background?.generatedAgslHash),
            "adapterVersion" to (values?.orb?.adapterVersion ?: values?.background?.adapterVersion),
            "profileStatus" to FluviKeyguardMaterialStore.status(applicationContext),
            "profileRevision" to (profile?.publisherRevision ?: -1L),
            "focusGeneration" to focus.generation,
            "effectId" to profile?.effectId,
            "animationMode" to FluviKeyguardCardSettings.read(applicationContext).animationMode.wireValue,
            "privacyMode" to if (FluviKeyguardCardSettings.read(applicationContext).showFinancialDetails) "full" else "discreet",
        )
    }

    private fun redactImmediately(reason: String) {
        if (r18Active != null) {
            hideImmediately("r18Redact:$reason", terminalWake = false)
            stopFinancialObservation()
            return
        }
        visibilityEpoch.incrementAndGet()
        publishInspectionAuthority()
        showEvent = false
        appliedDecision = KeyguardCardVisibility.SHOW_DISCREET
        if (::overlay.isInitialized && overlay.isAttached) {
            applyPresentation({ FluviFinancialCardPresenter.discreet() }, "redact:$reason")
        }
        stopFinancialObservation()
    }

    private fun invalidateFullContent() {
        renderedFullContent = null
        activeFocusGeneration = null
        resolveQueued = false
        resolvingFocusGeneration = null
        terminalContentFailure = null
        transientContentFailure = null
        contentJob?.cancel()
        contentJob = null
    }

    private fun stopFinancialObservation(keepRenderedContent: Boolean = false) {
        contentJob?.cancel()
        contentJob = null
        coreObservation?.cancel()
        coreObservation = null
        observedFocusGeneration = null
        resolvingFocusGeneration = null
        resolveQueued = false
        if (!keepRenderedContent) {
            renderedFullContent = null
            activeFocusGeneration = null
            terminalContentFailure = null
            transientContentFailure = null
        }
    }

    private fun cleanup(reason: String) {
        if (Build.VERSION.SDK_INT == 37) stopR444Trial("serviceLost")
        invalidateR442Receipt("serviceLost")
        r442ScreenOn = null
        r442LookupGeneration += 1
        r442Lookup = R442Lookup("UNAVAILABLE", null, false)
        if (r442PackageReceiverRegistered) {
            runCatching { unregisterReceiver(r442PackageReceiver) }
            r442PackageReceiverRegistered = false
        }
        referenceServiceSerial += 1
        referencePublisher?.let { publisher ->
            // Withdraw the host before a clean detach. If no matching empty
            // receipt arrives, durable suppression remains in force.
            publisher.onInputsChanging()
            if (!publisher.requestEmpty()) publisher.close()
        }
        referencePublisher = null
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.CLEANUP_ENTER, attachment = overlayAttachGeneration)
        traceKeyguard(if (reason == "destroy") "SERVICE_DESTROYED" else "SERVICE_UNBOUND", reason)
        hideImmediately(reason)
        systemSampler.dispose()
        // No join/await: an in-flight framework call may finish later. Its
        // disposed result cannot mutate this service's root or authority.
        systemGateExecutor.shutdown()
        if (receiverRegistered) {
            runCatching { unregisterReceiver(screenReceiver) }
            receiverRegistered = false
        }
        if (displayRegistered) {
            displayManager.unregisterDisplayListener(displayListener)
            displayRegistered = false
        }
        if (::overlay.isInitialized) overlay.dispose()
        KeyguardR44Trial.set(false, false)
        FluviKeyguardCardServiceRegistry.disconnected(this)
        KeyguardCardDiagnostics.record(this, "KG|SERVICE_DISCONNECTED", reason, false)
        serviceJob.cancel()
        KeyguardR14ForensicProbe.mark(KeyguardR14ForensicProbe.CLEANUP_EXIT, attachment = overlayAttachGeneration)
    }

    companion object {
        private val RETRY_DELAYS_MS = longArrayOf(16L, 32L, 64L)
        /** One display interval: below this scalar handoff timing remains
         * available, but a FULL capture does not copy correlation spans. */
        private const val SLOW_MAIN_HANDOFF_EVIDENCE_NS = 16_000_000L
        const val ACTION_OPEN_FOCUS = "com.fluvi.app.lockscreen.OPEN_FOCUS"
        const val EXTRA_MODE = "com.fluvi.app.lockscreen.MODE"
        const val EXTRA_AXIS = "com.fluvi.app.lockscreen.AXIS"
        const val EXTRA_DIRECTION = "com.fluvi.app.lockscreen.DIRECTION"
        const val EXTRA_CATEGORY = "com.fluvi.app.lockscreen.CATEGORY"
    }
}
