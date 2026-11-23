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
    main.drain()
    check(received.isEmpty()) { "stale READY escaped after invalidation" }
    check(store.current(System.currentTimeMillis()) == null)
    val current = input(nonce, 3)
    check(store.prepare(current, System.currentTimeMillis(), 2048))
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
    val beforeExpiry = changes
    clock = still.validUntilEpochMs
    scheduled.single().run()
    check(changes == beforeExpiry + 1) { "static expiry must invalidate the display owner" }
    check(timed.current(clock) == null)
    println("PASS: main adoption, READY, invalidate, reset, death, and static-expiry controls")
}
