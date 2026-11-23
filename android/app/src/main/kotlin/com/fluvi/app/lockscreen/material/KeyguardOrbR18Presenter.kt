package com.fluvi.app.lockscreen.material

import android.annotation.TargetApi
import android.content.Context
import android.os.Handler
import android.os.Looper
import android.os.SystemClock
import android.view.Display
import android.view.View
import java.util.concurrent.atomic.AtomicBoolean
import java.util.concurrent.atomic.AtomicLong
import java.util.concurrent.atomic.AtomicReference

/** The R18 producer owns one private, unparented image until the window owner
 * supplies an attached host. This class never decides whether showing is
 * allowed: its caller must supply the exact current grant at submission. */
@TargetApi(35)
internal class KeyguardOrbR18Presenter(
    private val context: Context,
    private val worker: KeyguardOrbSurfaceWorker,
    private val captureActive: () -> Boolean,
    private val onPrepared: (Long, Long, Long) -> Unit,
    private val onFailure: (Long, Long, String, () -> Unit) -> Unit,
    private val onReceipt: (Long, Long, KeyguardOrbPresentationLane.Receipt) -> Unit = { _, _, _ -> },
    private val onDrained: (Long, Long, Any) -> Unit = { _, _, _ -> },
    private val onAllocated: (Long, Long, Long) -> Unit = { _, _, _ -> },
    private val onObservation: (KeyguardOrbSurfaceObservation) -> Unit = {},
    private val acquirePrivatePoster: (KeyguardMaterialProfile, KeyguardOrbSurfaceTarget, KeyguardR19FirstPaintTicket) ->
        KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>? = { _, _, _ -> null },
    private val privatePosterIsCurrent: (KeyguardR34PrivatePoster.Image) -> Boolean = { false },
) {
    private data class Owner(
        val serial: Long,
        val attachment: Long,
        val generation: Long,
        val target: KeyguardOrbSurfaceTarget,
        val preparedAt: Long,
        val ready: AtomicBoolean = AtomicBoolean(false),
        @Volatile var readyAtUptimeMs: Long = 0L,
        val bound: AtomicBoolean = AtomicBoolean(false),
        val posterLease: AtomicReference<KeyguardR34PrivateAssetCache.Lease<KeyguardR34PrivatePoster.Image>?> = AtomicReference(),
        @Volatile var posterSelected: Boolean = false,
        @Volatile var posterDisplayed: Boolean = false,
        @Volatile var posterInFlight: Boolean = false,
        @Volatile var fallbackWaiting: Boolean = false,
        @Volatile var posterVisualKey: String? = null,
        @Volatile var posterProfile: KeyguardMaterialProfile? = null,
        @Volatile var posterTicket: KeyguardR19FirstPaintTicket? = null,
    )

    private val main = Handler(Looper.getMainLooper())
    private val serial = AtomicLong()
    private val owner = AtomicReference<Owner?>()
    private val requestedOwner = AtomicReference<Pair<Long, Long>?>()
    // Main-owned; only created for virgin animated DIRECT outputs.
    @Volatile private var warmup: KeyguardOrbDirectProgramWarmup? = null
    private val lane: KeyguardOrbPresentationLane = KeyguardOrbPresentationLane(
        captureActive = captureActive,
        onFailure = { output, reason ->
            val captured = owner.get()?.takeIf { it.target.directOutput === output }
            // Stop current authority immediately. Even a failure delivered
            // after seal still belongs to its original host, not a successor.
            if (captured != null) seal(captured.serial)
            main.post {
                onFailure(output.attachment, output.generation, reason) {
                    lane.hostRemovedAfterFailedHide(output)
                }
            }
        },
        onReceipt = { output, receipt ->
            // Immutable original identity survives a later attachment.
            onReceipt(output.attachment, output.generation, receipt)
        },
        onDrained = { output -> onDrained(output.attachment, output.generation, output) },
    )
    /** Called by the shared render worker. A posted buffer is evidence of
     * readiness only, not physical presentation or an admission. */
    fun onWorkerFirstPosted(target: KeyguardOrbSurfaceTarget, at: Long) {
        val captured = owner.get()?.takeIf { it.target === target && !target.revoked } ?: return
        if (captured.fallbackWaiting) {
            captured.fallbackWaiting = false
            worker.grantPresentation(target)
            return
        }
        if (captured.posterDisplayed) {
            val output = target.directOutput ?: return
            lane.promoteLive(output, stillCurrent = { owner.get() === captured && !target.revoked }) { success ->
                if (success && owner.get() === captured && !target.revoked) {
                    captured.posterDisplayed = false
                    worker.grantPresentation(target)
                } else if (owner.get() === captured && !target.revoked) onWorkerFailure(target, "r34LivePromotion")
            }
            return
        }
        if (captured.ready.compareAndSet(false, true)) {
            captured.readyAtUptimeMs = at
            main.post {
            if (owner.get() === captured && !target.revoked) onPrepared(captured.attachment, captured.generation, at)
            }
        }
    }

    /** Returns true only when this exact direct target belonged to R18. */
    fun onWorkerFailure(target: KeyguardOrbSurfaceTarget, reason: String): Boolean {
        val captured = owner.get()?.takeIf { it.target === target } ?: return false
        seal(captured.serial)
        val output = target.directOutput
        main.post { onFailure(captured.attachment, captured.generation, reason) {
            if (output != null) lane.hostRemovedAfterFailedHide(output)
        } }
        return true
    }

    /** Main may request this after first unlock. Only a discreet scene is
     * precomputed without a fresh disclosure grant. No WMS host is created. */
    fun prepare(attachment: Long, generation: Long, profile: KeyguardMaterialProfile,
                width: Int, height: Int, densityDpi: Int, full: Boolean = false,
                authorizedFull: Boolean = false, emptyAwaitingDisclosure: Boolean = false) {
        checkMain()
        require(!full || authorizedFull || emptyAwaitingDisclosure)
        require(!emptyAwaitingDisclosure || (full && !authorizedFull))
        seal()
        val ticket = serial.incrementAndGet()
        requestedOwner.set(attachment to generation)
        val warmSelector = if (emptyAwaitingDisclosure) KeyguardOrbProgramSelector.forProfile(profile) else null
        worker.prepareHiddenDirect(attachment, generation, width, height, densityDpi,
            if (emptyAwaitingDisclosure) null else profile, full, lane,
            stillCurrent = { serial.get() == ticket },
            created = { target ->
                val next = Owner(ticket, attachment, generation, target, SystemClock.uptimeMillis())
                if (serial.get() != ticket || !owner.compareAndSet(null, next)) {
                    worker.revoke(target, discardFull = true)
                    target.directOutput?.let(lane::retire)
                } else {
                    main.post {
                        if (owner.get() === next && !target.revoked) {
                            onAllocated(attachment, generation, next.preparedAt)
                            if (warmSelector != null && owner.get() === next && !target.revoked) {
                                val preparation = warmup ?: KeyguardOrbDirectProgramWarmup(context, worker::prewarmDirect).also { warmup = it }
                                preparation.request(target, warmSelector) {
                                    owner.get() === next && serial.get() == ticket && !target.revoked
                                }
                            }
                        }
                    }
                }
            },
            failed = { reason ->
                main.post {
                    if (serial.get() == ticket) onFailure(attachment, generation, reason) {}
                }
            },
            emptyAwaitingDisclosure = emptyAwaitingDisclosure,
            reporter = onObservation,
        )
    }

    /** A virgin output is bindable without a posted frame. This reference is
     * an identity only and never constitutes disclosure or image readiness. */
    fun allocatedOutput(attachment: Long, generation: Long, full: Boolean,
                        width: Int, height: Int, densityDpi: Int): Any? {
        checkMain()
        val current = owner.get() ?: return null
        val target = current.target
        return if (current.attachment == attachment && current.generation == generation && !target.revoked &&
            target.full == full && target.width == width && target.height == height && target.densityDpi == densityDpi)
            target.directOutput else null
    }

    /** Original allocation time, including an output created before wake adoption. */
    fun allocatedAt(attachment: Long, generation: Long): Long? {
        checkMain()
        val current = owner.get() ?: return null
        return current.preparedAt.takeIf {
            current.attachment == attachment && current.generation == generation && !current.target.revoked
        }
    }

    fun authorizeFirst(attachment: Long, generation: Long, profile: KeyguardMaterialProfile,
                       ticket: KeyguardR19FirstPaintTicket): Boolean {
        checkMain()
        val current = owner.get() ?: return false
        if (current.attachment != attachment || current.generation != generation || current.target.revoked ||
            !current.target.full) return false
        val existing = current.target.firstDirectAuthorization.get()
        if (existing != null) return existing.attachment == ticket.attachment && existing.generation == ticket.generation &&
            existing.dataRevision == ticket.dataRevision && existing.visualKey == ticket.visualKey
        val lease = acquirePrivatePoster(profile, current.target, ticket)
        if (lease != null && current.target.firstDirectAuthorization.compareAndSet(null, ticket)) {
            current.posterLease.set(lease)
            current.posterSelected = true
            current.posterVisualKey = profile.visualKey
            current.posterProfile = profile.copyForSurface()
            current.posterTicket = ticket
            current.target.r34StartPhase = lease.value.phase
            runCatching { onObservation(KeyguardOrbSurfaceObservation(attachment, generation, "POSTER",
                SystemClock.uptimeMillis(), "R34_PRIVATE_${lease.value.bufferStatus}", true,
                r34AssetGeneration = lease.value.ticket.generation,
                r34PrepareStartUptimeMs = lease.value.prepareStartedAtUptimeMs,
                r34ReadyUptimeMs = lease.value.readyAtUptimeMs)) }
            val readyAt = SystemClock.uptimeMillis()
            main.post {
                if (owner.get() === current && !current.target.revoked && current.posterLease.get() === lease &&
                    current.ready.compareAndSet(false, true)) {
                    current.readyAtUptimeMs = readyAt
                    onPrepared(attachment, generation, readyAt)
                }
            }
            return true
        }
        lease?.close()
        if (lease == null) runCatching { onObservation(KeyguardOrbSurfaceObservation(attachment, generation,
            "POSTER", SystemClock.uptimeMillis(), "R34_MISS_OR_STALE_OR_CAPACITY", true)) }
        return worker.authorizeDirectFirst(current.target, profile, ticket)
    }

    fun hasReady(attachment: Long, generation: Long): Boolean {
        checkMain()
        val current = owner.get() ?: return false
        return current.attachment == attachment && current.generation == generation &&
            current.ready.get() && !current.target.revoked
    }

    fun readyAt(attachment: Long, generation: Long): Long? {
        val current = owner.get() ?: return null
        return current.readyAtUptimeMs.takeIf { current.attachment == attachment && current.generation == generation && it > 0 }
    }

    fun preparedOutput(attachment: Long, generation: Long, profile: KeyguardMaterialProfile,
                       full: Boolean, width: Int, height: Int, densityDpi: Int): Any? {
        checkMain()
        val current = owner.get() ?: return null
        val target = current.target
        val visual = (if (full) profile else profile.neutralized()).visualKey
        val imageMatches = target.firstPostedVisualKey == visual ||
            (current.posterSelected && current.posterVisualKey == visual &&
                (current.posterLease.get() != null || current.posterInFlight || current.posterDisplayed || current.fallbackWaiting))
        return if (current.attachment == attachment && current.generation == generation && current.ready.get() &&
            !target.revoked && target.full == full && target.width == width && target.height == height &&
            target.densityDpi == densityDpi && imageMatches) target.directOutput else null
    }

    /** Call only from Main after actual attachment. The framework-owned
     * reparent transaction transfers to the compositor even on failure. */
    fun bind(host: View, attachment: Long, generation: Long, done: (Boolean) -> Unit) {
        checkMain()
        val current = owner.get()
        if (current == null || current.attachment != attachment || current.generation != generation ||
            current.target.revoked || !host.isAttachedToWindow || host.display?.displayId != Display.DEFAULT_DISPLAY ||
            host.width != current.target.width || host.height != current.target.height) {
            done(false); return
        }
        val parent = host.rootSurfaceControl
        val output = current.target.directOutput
        if (parent == null || output == null || !output.child.isValid) { done(false); return }
        val location = IntArray(2)
        host.getLocationInSurface(location)
        val transaction = runCatching { parent.buildReparentTransaction(output.child) }.getOrNull()
        if (transaction == null) { done(false); return }
        var posterIncluded = false
        output.posterChild?.takeIf { it.isValid }?.let { poster ->
            val additional = runCatching { parent.buildReparentTransaction(poster) }.getOrNull()
            if (additional != null) {
                posterIncluded = runCatching { transaction.merge(additional); true }.getOrDefault(false)
                runCatching { additional.close() }
            }
        }
        current.target.blankBindPending.set(true)
        lane.bind(output, transaction, location[0].toFloat(), location[1].toFloat(),
            current.target.width, current.target.height, posterIncluded,
            stillCurrent = { owner.get() === current && !current.target.revoked },
            completed = { success ->
                current.target.blankBindPending.set(false)
                if (success && owner.get() === current && !current.target.revoked) current.bound.set(true)
                main.post { done(success && owner.get() === current && !current.target.revoked) }
            },
        )
    }

    /** Input and the exact fresh privacy proof must already be armed. */
    fun reveal(attachment: Long, generation: Long, crossGrantBoundary: () -> Boolean,
               nativeApplied: () -> Boolean, stillAuthorized: () -> Boolean = { true }, done: (Boolean) -> Unit) {
        checkMain()
        val current = owner.get()
        if (current == null || current.attachment != attachment || current.generation != generation ||
            current.target.revoked || !current.ready.get() || !current.bound.get()) {
            done(false); return
        }
        val output = current.target.directOutput ?: run { done(false); return }
        val poster = current.posterLease.getAndSet(null)
        if (current.posterSelected && poster == null) { done(false); return }
        val directPoster = poster != null && poster.value.buffer != null && output.posterBound && output.posterChild?.isValid == true
        current.posterInFlight = poster != null
        lane.reveal(output, posterLease = if (directPoster) poster else null, crossGrantBoundary = {
            owner.get() === current && !current.target.revoked &&
                (poster == null || privatePosterIsCurrent(poster.value)) && crossGrantBoundary()
        }, nativeApplied = {
            owner.get() === current && !current.target.revoked && nativeApplied()
        }, stillAuthorized = {
            owner.get() === current && !current.target.revoked &&
                (poster == null || privatePosterIsCurrent(poster.value)) && stillAuthorized()
        }, completed = { success ->
            val live = success && owner.get() === current && !current.target.revoked
            if (live) {
                if (poster == null) worker.grantPresentation(current.target)
                else {
                    val profile = current.posterProfile
                    val ticket = current.posterTicket
                    if (directPoster) {
                        current.posterDisplayed = true
                        if (profile == null || ticket == null || !worker.authorizeDirectFirst(current.target, profile, ticket))
                            onWorkerFailure(current.target, "r34LiveContinuation")
                    } else {
                        current.fallbackWaiting = true
                        if (profile == null || ticket == null ||
                            !worker.authorizeDirectCachedFallback(current.target, profile, ticket, poster) {
                                privatePosterIsCurrent(poster.value)
                            }) {
                            poster.close()
                            onWorkerFailure(current.target, "r34CanvasFallback")
                        }
                    }
                }
            } else if (poster != null && !directPoster) poster.close()
            current.posterInFlight = false
            val acknowledgement = Runnable { done(success && owner.get() === current && !current.target.revoked) }
            val dispatcher = if (KeyguardOrbSurfaceWorkerTestHooks.ENABLED) KeyguardOrbSurfaceWorkerTestHooks.dispatchRevealDone else null
            if (dispatcher != null) dispatcher(acknowledgement) else main.post(acknowledgement)
        })
    }

    fun hasLiveOutputs(): Boolean = lane.hasLiveOutputs()

    fun setMotionAllowed(allowed: Boolean) {
        checkMain()
        owner.get()?.target?.let { worker.setMotionAllowed(it, allowed) }
    }

    /** A stale worker may only cancel the exact output it evaluated. */
    fun sealMatching(attachment: Long, generation: Long) {
        val expected = requestedOwner.get() ?: return
        if (expected.first != attachment || expected.second != generation) return
        val current = owner.get()
        if (current != null && current.attachment == attachment && current.generation == generation) {
            seal(current.serial)
        } else if (requestedOwner.compareAndSet(expected, null)) {
            serial.incrementAndGet()
        }
    }

    /** Callable from a current worker exclusion, even when Main is occupied.
     * Actual root touch disabling/removal belongs to the window owner. */
    fun seal(expectedSerial: Long? = null) {
        while (true) {
            val current = owner.get() ?: run {
                if (expectedSerial == null) { requestedOwner.set(null); serial.incrementAndGet() }
                return
            }
            if (expectedSerial != null && current.serial != expectedSerial) return
            if (!owner.compareAndSet(current, null)) continue
            val requested = requestedOwner.get()
            if (requested?.first == current.attachment && requested.second == current.generation)
                requestedOwner.compareAndSet(requested, null)
            serial.incrementAndGet()
            warmup?.retire(current.target)
            current.posterLease.getAndSet(null)?.close()
            worker.revoke(current.target, discardFull = true)
            current.target.directOutput?.let(lane::retire)
            return
        }
    }

    fun dispose() {
        checkMain()
        seal()
        warmup?.dispose()
        warmup = null
        lane.closeWhenDrained()
    }

    private fun checkMain() = check(Looper.myLooper() == Looper.getMainLooper())
}
