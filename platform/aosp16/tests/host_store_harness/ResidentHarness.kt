package com.android.systemui.keyguard.fluvi
import com.fluvi.r29.contract.*
import java.util.concurrent.Executor

private class Queue : Executor {
    val jobs = ArrayDeque<Runnable>()
    override fun execute(task: Runnable) { jobs.addLast(task) }
    fun drain() { while (jobs.isNotEmpty()) jobs.removeFirst().run() }
}
private fun input(nonce: String, sequence: Long): R29Descriptor {
    val now = System.currentTimeMillis()
    val p = R29Portal(false, 0, 0f, 0f, 50f, 68f, false, 0f, List(12) { 0f })
    val m = R29Material("dualTide", 1, .3f, 1f, 1f,
        listOf(0xff123456.toInt(), 0xffabcdef.toInt()), listOf(0f, 1f), 1f, 50f,
        List(40) { 0f }, p, p, 1080f, 2400f)
    return R29Descriptor(nonce, sequence, sequence, 7, 3, 4, 5,
        now - 1000, now + 60_000, 0, 0, 1080, 2400, 420, 168, .5f, .8f,
        R29Disclosure.FULL, true, m)
}
fun main() {
    val incoming = R39SceneFacts(false, true, true, true, true, false)
    check(R39ScenePolicy.allow(incoming))
    check(!R39ScenePolicy.allow(incoming.copy(wakingFromOff = false)))
    check(!R39ScenePolicy.allow(incoming.copy(fromAbsent = false)))
    check(!R39ScenePolicy.allow(incoming.copy(toLockscreen = false)))
    check(!R39ScenePolicy.allow(incoming.copy(noOverlays = false)))
    check(!R39ScenePolicy.allow(incoming.copy(userDriven = true)))
    val idle = incoming.copy(idleLockscreen = true, wakingFromOff = false, fromAbsent = false, toLockscreen = false)
    check(R39ScenePolicy.allow(idle))
    check(!R39ScenePolicy.allow(idle.copy(noOverlays = false)))
    val receipt = R39EmptyEvidence(true, true, true, true, true, true, true)
    check(R39EmptyPolicy.mayAcknowledge(receipt))
    listOf(receipt.copy(validFenceSignalled = false), receipt.copy(sameAttachedRoot = false),
        receipt.copy(samePendingRequest = false), receipt.copy(nextEmptyDrawObserved = false),
        receipt.copy(singleOriginalOwner = false), receipt.copy(noLaterOrbDraw = false),
        receipt.copy(sameEmptyGeneration = false)).forEach { check(!R39EmptyPolicy.mayAcknowledge(it)) }
    val nonce = "0123456789abcdef0123456789abcdef"
    val worker = Queue(); val main = Queue(); val renderer = R29HostRenderer()
    val received = mutableListOf<Long>()
    val store = R29ResidentStore(renderer, worker, main) { }
    check(store.beginSession(nonce) { _, seq -> received.add(seq) })
    val first = input(nonce, 1)
    check(store.prepare(first, System.currentTimeMillis(), 2048))
    worker.drain()
    checkNotNull(renderer.pending).invoke(Result.success(R29PreparedOrb(first)))
    check(store.current(System.currentTimeMillis()) == null) {
        "first worker output was exposed before main/draw owner adoption"
    }
    check(store.invalidate(nonce, 2))
    check(store.isCurrentEmpty(nonce, 2)) { "only the exact invalidation may await an empty-frame receipt" }
    check(!store.isCurrentEmpty(nonce, 1))
    main.drain()
    check(received.isEmpty()) { "stale READY escaped after invalidation" }
    check(store.current(System.currentTimeMillis()) == null)
    val current = input(nonce, 3)
    check(store.prepare(current, System.currentTimeMillis(), 2048))
    check(!store.isCurrentEmpty(nonce, 2)) { "a newer generation revokes the older empty receipt" }
    worker.drain()
    checkNotNull(renderer.pending).invoke(Result.success(R29PreparedOrb(current)))
    check(store.current(System.currentTimeMillis()) == null)
    main.drain()
    check(store.current(System.currentTimeMillis())?.descriptor?.sequence == 3L)
    check(received == listOf(3L)) { "a current adopted output must produce one READY" }
    val late = input(nonce, 4)
    check(store.prepare(late, System.currentTimeMillis(), 2048))
    worker.drain()
    checkNotNull(renderer.pending).invoke(Result.success(R29PreparedOrb(late)))
    store.reset()
    main.drain()
    check(received == listOf(3L)) { "reset must reject an unadopted completion" }
    check(store.current(System.currentTimeMillis()) == null)
    val replacementNonce = "fedcba9876543210fedcba9876543210"
    check(store.beginSession(replacementNonce) { _, seq -> received.add(seq) })
    check(!store.isCurrentEmpty(nonce, 2)) { "an old session must not acquire an empty receipt" }
    val replacement = input(replacementNonce, 1)
    check(store.prepare(replacement, System.currentTimeMillis(), 2048))
    worker.drain()
    checkNotNull(renderer.pending).invoke(Result.success(R29PreparedOrb(replacement)))
    main.drain()
    check(store.current(System.currentTimeMillis())?.descriptor?.session == replacementNonce)
    check(!store.clientDied(nonce)) { "an old connection death cannot reset a new session" }
    check(store.current(System.currentTimeMillis()) != null)
    check(store.clientDied(replacementNonce))
    check(store.current(System.currentTimeMillis()) == null) { "unexpected death must revoke adopted output" }
    // A second request arrives while the first renderer job still owns the
    // sole worker. Completion of obsolete A must neither become current nor
    // produce READY; the actual pending B must start and be adopted instead.
    val raceWorker = Queue(); val raceMain = Queue(); val raceRenderer = R29HostRenderer()
    val raceReceipts = mutableListOf<Long>()
    val race = R29ResidentStore(raceRenderer, raceWorker, raceMain) { }
    check(race.beginSession(nonce) { _, seq -> raceReceipts.add(seq) })
    val raceA = input(nonce, 1)
    val raceB = input(nonce, 2)
    check(race.prepare(raceA, System.currentTimeMillis(), 2048))
    raceWorker.drain()
    val finishA = checkNotNull(raceRenderer.pending)
    check(race.prepare(raceB, System.currentTimeMillis(), 2048))
    finishA(Result.success(R29PreparedOrb(raceA)))
    raceMain.drain()
    check(raceReceipts.isEmpty()) { "obsolete A must never report READY" }
    check(race.current(System.currentTimeMillis()) == null)
    raceWorker.drain()
    checkNotNull(raceRenderer.pending).invoke(Result.success(R29PreparedOrb(raceB)))
    raceMain.drain()
    check(raceReceipts == listOf(2L)) { "only the latest B may report READY" }
    check(race.current(System.currentTimeMillis())?.descriptor?.sequence == 2L)
    race.detach(nonce)
    check(race.current(System.currentTimeMillis())?.descriptor?.sequence == 2L) {
        "a clean detach must retain the acknowledged generation"
    }
    if (R35HostMemoryPolicy.shouldEvict(10)) race.reset()
    check(race.current(System.currentTimeMillis()) == null) { "genuine low-memory pressure must evict" }
    // A static image must expire even if no draw calls current().
    val timedWorker = Queue(); val timedMain = Queue(); val timedRenderer = R29HostRenderer()
    val scheduled = mutableListOf<Runnable>()
    var clock = System.currentTimeMillis()
    var changes = 0
    val timed = R29ResidentStore(timedRenderer, timedWorker, timedMain,
        scheduleExpiry = { task, _ -> scheduled.clear(); scheduled.add(task) },
        cancelExpiry = { task -> scheduled.remove(task) }, nowEpochMs = { clock }) { changes++ }
    check(timed.beginSession(nonce) { _, _ -> })
    val still = input(nonce, 1).copy(motion = R29Motion.STATIC)
    check(timed.prepare(still, clock, 2048))
    timedWorker.drain()
    checkNotNull(timedRenderer.pending).invoke(Result.success(R29PreparedOrb(still)))
    timedMain.drain()
    timed.detach(nonce) // clean detach keeps the adopted image and its expiry
    // UI_HIDDEN describes a visibility change, not memory pressure. A cleanly
    // detached image must remain available for the next eligible frame.
    if (R35HostMemoryPolicy.shouldEvict(20)) timed.reset()
    check(timed.current(clock) != null) { "UI_HIDDEN must not evict a ready detached image" }
    val beforeExpiry = changes
    clock = still.validUntilEpochMs
    scheduled.single().run()
    check(changes == beforeExpiry + 1) { "static expiry must invalidate the display owner" }
    check(timed.current(clock) == null)
    check(R35HostMemoryPolicy.shouldEvict(10)) // RUNNING_LOW
    check(R35HostMemoryPolicy.shouldEvict(15)) // RUNNING_CRITICAL
    check(R35HostMemoryPolicy.shouldEvict(40)) // BACKGROUND
    check(R35HostMemoryPolicy.shouldEvict(80)) // COMPLETE
    check(!R35HostMemoryPolicy.shouldEvict(5)) // RUNNING_MODERATE
    check(!R35HostMemoryPolicy.shouldEvict(20)) // UI_HIDDEN
    println("PASS: main adoption, latest-wins, READY, detach, pressure, invalidate, reset, death, and expiry controls")
}
