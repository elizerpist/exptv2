package com.fluvi.app.lockscreen.material

import android.graphics.HardwareBufferRenderer
import android.graphics.Paint
import android.graphics.RenderNode
import android.hardware.HardwareBuffer
import android.hardware.SyncFence
import android.os.Handler
import android.os.HandlerThread
import android.view.SurfaceControl
import java.time.Duration
import java.util.IdentityHashMap
import java.util.concurrent.atomic.AtomicReference
import java.util.function.Consumer
import org.junit.After
import org.junit.Assert.*
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.annotation.Config
import org.robolectric.annotation.Implementation
import org.robolectric.annotation.Implements
import org.robolectric.annotation.LooperMode
import org.robolectric.annotation.RealObject
import org.robolectric.shadows.ShadowSystemClock

/** Calls the real production Worker/publishSteady/consumeRelease state machine.
 * The platform transaction is wrapped locally; no Android compositor or physical
 * release is claimed by this JVM test. */
@RunWith(RobolectricTestRunner::class)
@LooperMode(LooperMode.Mode.PAUSED)
@Config(sdk = [35], manifest = Config.NONE, shadows = [KeyguardOrbSteadyCapacityTest.TransactionShadow::class,
    KeyguardOrbSteadyCapacityTest.BufferShadow::class, KeyguardOrbSteadyCapacityTest.FenceShadow::class])
class KeyguardOrbSteadyCapacityTest {
    @Implements(value = SurfaceControl.Transaction::class, minSdk = 34)
    class TransactionShadow {
        @RealObject lateinit var real: SurfaceControl.Transaction
        private var release: Consumer<SyncFence?>? = null
        @Implementation fun __constructor__() = Unit
        @Implementation fun setBuffer(child: SurfaceControl, buffer: HardwareBuffer, acquire: SyncFence?,
                                      listener: Consumer<SyncFence?>): SurfaceControl.Transaction {
            release = listener
            return real
        }
        @Implementation fun apply() {
            lastRelease = release
            if (deliverDuringApply) release?.accept(releaseOnApply)
            if (throwDuringApply) throw IllegalStateException("test-wrapped apply failure")
        }
        @Implementation fun close() = Unit
        companion object {
            var deliverDuringApply = false
            var throwDuringApply = false
            var releaseOnApply: SyncFence? = null
            var lastRelease: Consumer<SyncFence?>? = null
        }
    }

    @Implements(value = HardwareBuffer::class, minSdk = 34)
    class BufferShadow {
        @RealObject lateinit var real: HardwareBuffer
        @Implementation fun __constructor__(nativePtr: Long) = Unit
        @Implementation fun getWidth(): Int = sizes[real]?.first ?: 168
        @Implementation fun getHeight(): Int = sizes[real]?.second ?: 168
        @Implementation fun close() = Unit
        companion object {
            val sizes = IdentityHashMap<HardwareBuffer, Pair<Int, Int>>()
            @JvmStatic @Implementation fun isSupported(width: Int, height: Int, format: Int, layers: Int, usage: Long) = true
        }
    }

    @Implements(value = SyncFence::class, minSdk = 34)
    class FenceShadow {
        @RealObject lateinit var real: SyncFence
        @Implementation fun __constructor__() = Unit
        @Implementation fun isValid() = true
        @Implementation fun await(duration: Duration) = signalled
        @Implementation fun close() { closed.add(real) }
        companion object {
            var signalled = false
            val closed = java.util.Collections.newSetFromMap(IdentityHashMap<SyncFence, Boolean>())
        }
    }

    private var failBeforeApply = false
    private var throwObserver = false
    private var allowRenderCalls = 0
    private val renderHook = object : KeyguardOrbRecoveryTestHook {
        override fun allowRender(lease: KeyguardOrbBufferLease): Boolean {
            allowRenderCalls++
            return false
        }
    }

    private lateinit var worker: Any
    private lateinit var handler: Handler
    private lateinit var slot: Any
    private lateinit var frame: Any
    private lateinit var child: SurfaceControl
    private val lease = KeyguardOrbBufferLease(7, 11, "fixture-visual", "fixture-program", 168, 168)

    private fun type(suffix: String) = Class.forName(
        "com.fluvi.app.lockscreen.material.KeyguardOrbBufferRenderer\$$suffix")
    private fun Any.field(name: String): java.lang.reflect.Field = javaClass.getDeclaredField(name).apply { isAccessible = true }
    private fun Any.read(name: String): Any? = field(name).get(this)
    private fun Any.write(name: String, value: Any?) = field(name).set(this, value)
    private fun allocate(type: Class<*>): Any {
        val unsafeType = Class.forName("sun.misc.Unsafe")
        val field = unsafeType.getDeclaredField("theUnsafe").apply { isAccessible = true }
        return unsafeType.getMethod("allocateInstance", Class::class.java).invoke(field.get(null), type)
    }
    private fun fakeBuffer(width: Int = 168, height: Int = 168): HardwareBuffer {
        val buffer = HardwareBuffer::class.java.getDeclaredConstructor(Long::class.javaPrimitiveType)
            .apply { isAccessible = true }.newInstance(1L)
        BufferShadow.sizes[buffer] = width to height
        return buffer
    }
    private fun fakeFence(): SyncFence = SyncFence::class.java.getDeclaredConstructor()
        .apply { isAccessible = true }.newInstance()
    private fun onWorker(block: () -> Unit) {
        val failure = AtomicReference<Throwable?>()
        handler.post { try { block() } catch (error: Throwable) { failure.set(error) } }
        shadowOf(handler.looper).idle()
        failure.get()?.let { throw it }
    }

    @Before fun setup() {
        TransactionShadow.deliverDuringApply = false
        TransactionShadow.throwDuringApply = false
        TransactionShadow.releaseOnApply = null
        TransactionShadow.lastRelease = null
        val renderer = KeyguardOrbBufferRenderer(
            onFirstPublished = { _, _ -> }, onFirstCommitReceived = { _, _, _ -> },
            onFirstCommitted = {}, onFailure = { _, _ -> }, onSizeChanged = {}, recoveryHook = renderHook,
            steadyPublicationBarrier = KeyguardOrbSteadyPublicationBarrier {
                if (failBeforeApply) throw IllegalStateException("before-apply")
            }, publicationObserver = KeyguardOrbBufferPublicationObserver {
                if (throwObserver) throw IllegalStateException("observer-after-transfer")
            })
        val delegateMethod = renderer.javaClass.getDeclaredMethod("delegate").apply { isAccessible = true }
        val api = delegateMethod.invoke(renderer)
        worker = requireNotNull(api.read("worker"))
        handler = worker.read("handler") as Handler
        val buffer = fakeBuffer()
        val hardwareRenderer = allocate(HardwareBufferRenderer::class.java) as HardwareBufferRenderer
        val node = allocate(RenderNode::class.java) as RenderNode
        child = allocate(SurfaceControl::class.java) as SurfaceControl
        val state = type("Worker\$SlotState").enumConstants.single { (it as Enum<*>).name == "READY_FOR_MAIN" }
        val slotType = type("Worker\$Slot")
        slot = slotType.declaredConstructors.single { it.parameterCount == 19 }.apply { isAccessible = true }
            .newInstance(1L, buffer, hardwareRenderer, node, null, null, null, null, Paint(), Paint(),
                state, false, 3L, lease, null, null, false, false, false)
        val producer = KeyguardOrbBufferProducerFrame(lease, 1, 3, 42, KeyguardMaterialTime(1f, .2f, .3f, .4f))
        frame = type("ReadyFrame").declaredConstructors.single { it.parameterCount == 12 }.apply { isAccessible = true }
            .newInstance(producer, lease, 1L, 3L, buffer, null, 1L, null, null, null, null, null)
        val target = type("Worker\$PublicationTarget").declaredConstructors.single { it.parameterCount == 3 }
            .apply { isAccessible = true }.newInstance(lease, child, true)
        onWorker {
            @Suppress("UNCHECKED_CAST")
            (worker.read("slots") as MutableList<Any>).add(slot)
            val store = requireNotNull(worker.read("publicationTarget"))
            store.javaClass.getDeclaredMethod("install", Any::class.java).apply { isAccessible = true }.invoke(store, target)
        }
    }

    @After fun cleanup() {
        if (!::worker.isInitialized) return
        (worker.read("thread") as HandlerThread).quitSafely()
        (worker.read("fenceThread") as HandlerThread).quitSafely()
        TransactionShadow.lastRelease = null
        TransactionShadow.releaseOnApply = null
        BufferShadow.sizes.clear()
        FenceShadow.signalled = false
        FenceShadow.closed.clear()
    }

    private fun publish() {
        worker.javaClass.declaredMethods.single { it.name == "publishSteady" }.apply { isAccessible = true }
            .invoke(worker, slot, frame)
    }
    private fun state() = (slot.read("state") as Enum<*>).name

    private fun setState(value: Any, state: String) {
        value.write("state", type("Worker\$SlotState").enumConstants.single { (it as Enum<*>).name == state })
    }

    private fun makeSlot(id: Long, owner: KeyguardOrbBufferLease, state: String, retired: Boolean = false): Any {
        val buffer = fakeBuffer(owner.width, owner.height)
        val renderer = allocate(HardwareBufferRenderer::class.java) as HardwareBufferRenderer
        val node = allocate(RenderNode::class.java) as RenderNode
        val value = type("Worker\$Slot").declaredConstructors.single { it.parameterCount == 19 }
            .apply { isAccessible = true }.newInstance(id, buffer, renderer, node, null, null, null, null,
                Paint(), Paint(), type("Worker\$SlotState").enumConstants.single { (it as Enum<*>).name == state },
                retired, 1L, owner, null, null, false, false, false)
        return value
    }

    private fun spec(opacity: Double = 1.0, full: Boolean = true): KeyguardOrbBufferRenderSpec {
        val portal = mapOf("enabled" to false, "effectIndex" to 0, "phase" to 0.0, "phaseSpeed" to 0.0,
            "paletteCenterPercent" to 50.0, "paletteWindowPercent" to 68.0, "rotationEnabled" to false,
            "rotationSpeed" to 0.0, "settings" to List(12) { 0.0 })
        val profile = requireNotNull(KeyguardMaterialProfile.fromMap(mapOf(
            "schemaVersion" to 1, "shaderAbiVersion" to 6, "sourceShaderHash" to KeyguardMaterialProfile.SOURCE_SHADER_HASH,
            "publisherSession" to "test", "publisherRevision" to 1L, "sceneIdentity" to "fixture",
            "effectId" to "deepDrift", "effectShaderId" to 8, "phase" to .5, "elapsedSeconds" to 1.0,
            "phaseSpeed" to .3, "colors" to listOf(0xff102030.toInt(), 0xff405060.toInt(), 0xff708090.toInt()),
            "stops" to listOf(0.0, .5, 1.0), "opacity" to opacity, "paletteSplitPercent" to 50.0,
            "commonSettings" to List(40) { .2 }, "background" to portal, "interior" to portal,
            "referenceWidth" to 390.0, "referenceHeight" to 220.0)))
        return KeyguardOrbBufferRenderSpec(lease,
            KeyguardShaderArtifact("deepDrift", false, "fixture", KeyguardHeaderShader.Metadata("source", "generated", "test")),
            KeyguardMaterialScene(profile, full, 0))
    }

    private fun invokeWorker(name: String, vararg args: Any?) {
        worker.javaClass.declaredMethods.single { it.name == name }.apply { isAccessible = true }.invoke(worker, *args)
    }

    /** Invoked by the policy suite: all pressure inputs and receipt acceptance
     * are production Worker code. Fake fence stays unsignalled. */
    fun assertRealWorkerReceiptRestartsMixedSizePressure() {
        val current = spec()
        val old = lease.copy(attachment = 6, generation = 10, width = 164, height = 164)
        val oldSlot = makeSlot(2, old, "PUBLISHED", retired = true)
        val otherCurrent = makeSlot(3, lease, "PUBLISHED")
        val fence = fakeFence()
        onWorker {
            setState(slot, "PUBLISHED")
            @Suppress("UNCHECKED_CAST")
            (worker.read("slots") as MutableList<Any>).addAll(listOf(oldSlot, otherCurrent))
            worker.write("desired", current)
            worker.write("attachedLease", lease)
            worker.write("running", true)
            invokeWorker("evaluatePressure", current, true)
            ShadowSystemClock.advanceBy(Duration.ofMillis(8))
            invokeWorker("evaluatePressure", current, true)
            ShadowSystemClock.advanceBy(Duration.ofMillis(11))
            val before = worker.read("pressureProgress") as Long
            invokeWorker("release", lease, 1L, 3L, fence, System.identityHashCode(child), false)
            assertEquals("WAIT_RELEASE_FENCE", state())
            assertEquals(true, slot.read("callbackReceived"))
            assertEquals(before + 1, worker.read("pressureProgress"))
            val duplicate = fakeFence()
            invokeWorker("release", lease, 1L, 3L, duplicate, System.identityHashCode(child), false)
            assertTrue("duplicate fence must be closed", FenceShadow.closed.contains(duplicate))
            assertEquals(before + 1, worker.read("pressureProgress"))
            val oldFence = fakeFence()
            invokeWorker("release", old, 2L, 1L, oldFence, System.identityHashCode(child), false)
            assertEquals("old-lease release cannot refresh the current grant", before + 1, worker.read("pressureProgress"))
            ShadowSystemClock.advanceBy(Duration.ofMillis(33))
            invokeWorker("evaluatePressure", current, true)
            assertNull("current-lease real receipt must restart the WRONG_SIZE_OLD filter", worker.read("offeredPressure"))
            assertEquals("unsignalled fence must still own its use", "WAIT_RELEASE_FENCE", state())
            worker.write("running", false)
        }
        FenceShadow.signalled = true
        val fenceHandler = worker.read("fenceHandler") as Handler
        // A prior unsignalled poll may have scheduled the next real worker
        // check 16 ms later on the paused test looper.
        shadowOf(fenceHandler.looper).idleFor(Duration.ofMillis(32))
        shadowOf(handler.looper).idle()
        onWorker {
            assertEquals("actual fence completion restores the exact use", "FREE", state())
            assertNull(worker.read("offeredPressure"))
        }
    }

    @Test fun translucentSteadyLeavesTheThirdSlotForAnAuthorizedSuccessor() {
        val translucent = spec(opacity = .5)
        onWorker {
            invokeWorker("markFirstPublished", frame, System.identityHashCode(child), "first/direct")
        }
        shadowOf(handler.looper).idle()
        onWorker {
            // One acknowledged first use and one actual test-wrapped steady
            // submission are held by the compositor. A third is still FREE.
            assertEquals("PUBLISHED", state())
            val steady = makeSlot(2, lease, "READY_FOR_MAIN")
            val free = makeSlot(3, lease, "FREE")
            @Suppress("UNCHECKED_CAST")
            (worker.read("slots") as MutableList<Any>).addAll(listOf(steady, free))
            val buffer = steady.read("buffer") as HardwareBuffer
            val producer = KeyguardOrbBufferProducerFrame(lease, 2, 1, 42, KeyguardMaterialTime(1f, .4f, .3f, .4f))
            val steadyFrame = type("ReadyFrame").declaredConstructors.single { it.parameterCount == 12 }.apply { isAccessible = true }
                .newInstance(producer, lease, 2L, 1L, buffer, null, 1L, null, null, null, null, null)
            worker.javaClass.declaredMethods.single { it.name == "publishSteady" }.apply { isAccessible = true }
                .invoke(worker, steady, steadyFrame)
            assertEquals("PUBLISHED", (steady.read("state") as Enum<*>).name)
            worker.write("desired", translucent)
            worker.write("attachedLease", lease)
            worker.write("firstLeaseSubmitted", lease)
            worker.write("running", true)
            invokeWorker("render", 100_000_000L)
            assertEquals("optional translucent steady must stop before selecting the third buffer", 0, allowRenderCalls)
            assertEquals("FREE", (free.read("state") as Enum<*>).name)
            assertEquals(1L, worker.read("translucentSteadySkipped"))
            // A later authorized opaque generation may select that slot. The
            // test hook stops before actual GPU work; device panels verify pixels.
            val successor = lease.copy(generation = lease.generation + 1)
            val grant = type("Worker\$PublicationTarget").declaredConstructors.single { it.parameterCount == 3 }
                .apply { isAccessible = true }.newInstance(successor, child, true)
            val store = requireNotNull(worker.read("publicationTarget"))
            store.javaClass.getDeclaredMethod("install", Any::class.java).apply { isAccessible = true }.invoke(store, grant)
            slot.write("retired", true)
            steady.write("retired", true)
            worker.write("desired", spec().copy(lease = successor))
            worker.write("attachedLease", successor)
            invokeWorker("render", 116_000_000L)
            assertEquals("opaque successor must be admitted to the writable slot", 1, allowRenderCalls)
            worker.write("running", false)
        }
    }

    @Test fun twoSlotLimitDoesNotApplyToOpaqueNeutralOrUnacknowledgedFirstFrames() {
        onWorker {
            setState(slot, "PUBLISHED")
            val second = makeSlot(2, lease, "PUBLISHED")
            val free = makeSlot(3, lease, "FREE")
            @Suppress("UNCHECKED_CAST")
            (worker.read("slots") as MutableList<Any>).addAll(listOf(second, free))
            worker.write("attachedLease", lease)
            worker.write("running", true)
            worker.write("firstLeaseSubmitted", lease)
            worker.write("desired", spec(opacity = 1.0, full = true))
            invokeWorker("render", 100_000_000L)
            assertEquals("opaque steady output must remain eligible", 1, allowRenderCalls)
            worker.write("desired", spec(opacity = .5, full = false))
            invokeWorker("render", 116_000_000L)
            assertEquals("neutral output must remain eligible", 2, allowRenderCalls)
            worker.write("desired", spec(opacity = .5, full = true))
            worker.write("firstLeaseSubmitted", null)
            invokeWorker("render", 132_000_000L)
            assertEquals("unacknowledged first output must remain eligible", 3, allowRenderCalls)
            assertEquals(0L, worker.read("translucentSteadySkipped"))
            worker.write("running", false)
        }
    }

    @Test fun earlyValidFenceKeepsTheExactUseOwnedUntilItSignals() {
        val fence = fakeFence()
        TransactionShadow.deliverDuringApply = true
        TransactionShadow.releaseOnApply = fence
        onWorker {
            publish()
            assertEquals("WAIT_RELEASE_FENCE", state())
            assertEquals(true, slot.read("callbackReceived"))
            assertFalse(FenceShadow.closed.contains(fence))
        }
        val fenceHandler = worker.read("fenceHandler") as Handler
        shadowOf(fenceHandler.looper).idle()
        onWorker { assertEquals("unsignalled fence cannot release storage", "WAIT_RELEASE_FENCE", state()) }
        FenceShadow.signalled = true
        shadowOf(fenceHandler.looper).idleFor(Duration.ofMillis(16))
        shadowOf(handler.looper).idle()
        onWorker { assertEquals("FREE", state()) }
        assertTrue(FenceShadow.closed.contains(fence))
    }

    @Test fun wrongLeaseSlotOrUseAndDuplicateCannotDrainAnotherUse() {
        onWorker {
            publish()
            invokeWorker("release", lease.copy(generation = lease.generation + 1), 1L, 3L, null,
                System.identityHashCode(child), false)
            invokeWorker("release", lease, 44L, 3L, null, System.identityHashCode(child), false)
            invokeWorker("release", lease, 1L, 4L, null, System.identityHashCode(child), false)
            assertEquals("PUBLISHED", state())
            val realWrappedReceipt = requireNotNull(TransactionShadow.lastRelease)
            realWrappedReceipt.accept(null)
            assertEquals("FREE", state())
            realWrappedReceipt.accept(null)
            assertEquals("FREE", state())
        }
    }

    @Test fun firstDirectPathAlsoReplaysAnEarlyReceiptOnce() {
        onWorker {
            invokeWorker("release", lease, 1L, 3L, null, System.identityHashCode(child), false)
            assertEquals("READY_FOR_MAIN", state())
            assertEquals(true, slot.read("earlyReceiptRetained"))
            invokeWorker("markFirstPublished", frame, System.identityHashCode(child), "first/direct")
        }
        shadowOf(handler.looper).idle()
        onWorker { assertEquals("FREE", state()) }
    }

    @Test fun priorAcceptedUseMayDrainWithoutChangingTheReplacementUse() {
        onWorker {
            publish()
            slot.write("retired", true)
            val next = lease.copy(generation = lease.generation + 1)
            val replacement = makeSlot(2, next, "PUBLISHED")
            @Suppress("UNCHECKED_CAST")
            (worker.read("slots") as MutableList<Any>).add(replacement)
            requireNotNull(TransactionShadow.lastRelease).accept(null)
            assertEquals("FREE", state())
            assertEquals("PUBLISHED", (replacement.read("state") as Enum<*>).name)
            assertEquals(next, replacement.read("lease"))
        }
    }

    @Test fun failureBeforeApplyDrainsProducerButAmbiguousApplyStaysOwned() {
        failBeforeApply = true
        onWorker { publish(); assertEquals("FREE", state()) }
        // A distinct use is admitted after the known pre-transfer failure.
        onWorker {
            setState(slot, "READY_FOR_MAIN")
            slot.write("lease", lease)
            slot.write("useGeneration", 3L)
            failBeforeApply = false
            TransactionShadow.throwDuringApply = true
            publish()
            assertEquals("PUBLISHED", state())
            assertEquals("steady/apply-unknown", slot.read("publicationPath"))
            assertEquals(false, slot.read("callbackReceived"))
        }
    }

    @Test fun throwingObserverAfterTransferCannotDropThePublishedUse() {
        throwObserver = true
        onWorker {
            publish()
            assertEquals("PUBLISHED", state())
            assertEquals(false, slot.read("callbackReceived"))
            requireNotNull(TransactionShadow.lastRelease).accept(null)
            assertEquals("FREE", state())
        }
    }

    @Test fun synchronousSteadyReceiptIsReplayedAfterPublicationAcknowledgement() {
        TransactionShadow.deliverDuringApply = true
        onWorker {
            publish()
            assertNotNull("test transaction did not deliver the receipt", TransactionShadow.lastRelease)
            assertEquals("an exact null-fence receipt must drain after the steady acknowledgement", "FREE", state())
            assertEquals(false, slot.read("earlyReceiptRetained"))
        }
    }

    @Test fun absentReceiptKeepsPublishedUseOwnedUntilItsReceiptArrives() {
        onWorker {
            publish()
            assertEquals("PUBLISHED", state())
            requireNotNull(TransactionShadow.lastRelease).accept(null)
            assertEquals("FREE", state())
        }
    }
}
