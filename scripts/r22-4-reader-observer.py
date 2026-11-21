#!/usr/bin/env python3
"""Apply a bounded debug-only observation for the existing real A/B reader.

The inspected app is candidate source plus this recorded test patch. It never
changes an acquired node, classification, cache, flag or grant. Profile/release
are not built from this diagnostic overlay.
"""
from pathlib import Path
p=Path('android/app/src/debug/kotlin/com/fluvi/app/lockscreen/KeyguardR15AcquisitionTestHooks.kt')
s=p.read_text()
s=s.replace('''    @Volatile var beforeChildCall: ((KeyguardCardInspectionRequest, Int, Int) -> Unit)? = null
''','''    @Volatile var beforeChildCall: ((KeyguardCardInspectionRequest, Int, Int) -> Unit)? = null
    @Volatile var firstFailureObserver: ((Long, Int, Int, Int?, Long, String) -> Unit)? = null
''',1)
s=s.replace('''        var childFlags: Int? = null,
        var result:''','''        var childFlags: Int? = null,
        var latestChildFlags: Int? = null,
        var failureRecorded: Boolean = false,
        var result:''',1)
s=s.replace('''        runCatching { beforeChildCall?.invoke(pending.request, window, index) }
        if (!pending.childCalled)''','''        runCatching { beforeChildCall?.invoke(pending.request, window, index) }
        pending.latestChildFlags = flags
        if (!pending.childCalled)''',1)
needle='''    fun returnedChild(window: Int, index: Int, present: Boolean) {'''
assert s.count(needle)==1
s=s.replace(needle,'''    fun firstFailure(window: Int, index: Int, duration: Long, error: Throwable) {
        val pending = active.get() ?: return
        val observer = firstFailureObserver ?: return
        if (pending.failureRecorded) return
        pending.failureRecorded = true
        val frames = error.stackTrace.asSequence().filter {
            it.className.startsWith("android.") || it.className.startsWith("com.fluvi.")
        }.take(5).joinToString(";") { "${it.className}.${it.methodName}:${it.lineNumber}" }
        runCatching { observer(pending.request.id, window, index, pending.latestChildFlags, duration,
            "${error.javaClass.name}[$frames]") }
    }

'''+needle)
p.write_text(s)
p=Path('android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt')
s=p.read_text()
needle='''                    val childReturnedAt = SystemClock.uptimeMillis()
                    timing.child(windowId, index, childReturnedAt - startedAt)'''
assert s.count(needle)==1
s=s.replace(needle,'''                    val childReturnedAt = SystemClock.uptimeMillis()
                    if (KeyguardR15AcquisitionTestHooks.ENABLED) acquisition.exceptionOrNull()?.let { error ->
                        KeyguardR15AcquisitionTestHooks.firstFailure(windowId, index, childReturnedAt - startedAt, error)
                    }
                    timing.child(windowId, index, childReturnedAt - startedAt)''')
p.write_text(s)
p=Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR22FirstInspectionFixture.kt')
s=p.read_text()
needle='''            KeyguardR15AcquisitionTestHooks.observer = { observation ->'''
assert s.count(needle)==1
s=s.replace(needle,'''            KeyguardR15AcquisitionTestHooks.firstFailureObserver = { request, window, index, flags, duration, stack ->
                records.add("FIRST_READER_FAILURE req=$request window=$window index=$index flags=$flags durationMs=$duration at=${SystemClock.uptimeMillis()} stack=$stack")
            }
            KeyguardR15AcquisitionTestHooks.observer = { observation ->''')
needle='''            releaseEntry.countDown()
            assertTrue("NOT REACHED: original opening reached no clean eligible post-marker checkpoint", entered.await(20, TimeUnit.SECONDS))'''
assert s.count(needle)==1
s=s.replace(needle,'''            records.add("INDEPENDENT_BEFORE_A at=${SystemClock.uptimeMillis()} interactive=${power.isInteractive} locked=${keyguard.isKeyguardLocked} shade=${independentShadeWindow() ?: "NONE"}")
            releaseEntry.countDown()
            assertTrue("NOT REACHED: original opening reached no clean eligible post-marker checkpoint", entered.await(20, TimeUnit.SECONDS))''')
needle='''                assertTrue("NOT REACHED: claimed B did not physically start", bStarted.await(15, TimeUnit.SECONDS))
                assertEquals("B must run on the same physical reader", aThread.get(), bThread.get())'''
assert s.count(needle)==1
s=s.replace(needle,'''                assertTrue("NOT REACHED: claimed B did not physically start", bStarted.await(15, TimeUnit.SECONDS))
                records.add("INDEPENDENT_AT_B at=${SystemClock.uptimeMillis()} interactive=${power.isInteractive} locked=${keyguard.isKeyguardLocked} shade=${independentShadeWindow() ?: "NONE"}")
                assertEquals("B must run on the same physical reader", aThread.get(), bThread.get())''')
needle='''            KeyguardR15AcquisitionTestHooks.afterReturnedChild = null'''
assert s.count(needle)==1
s=s.replace(needle,'''            KeyguardR15AcquisitionTestHooks.firstFailureObserver = null
            KeyguardR15AcquisitionTestHooks.afterReturnedChild = null''')
needle="""        val stableExternal = AtomicBoolean(false)"""
assert s.count(needle)==1
s=s.replace(needle,needle+"\n        val pendingTraceCount = AtomicLong(0L)")
needle="""                        if (scenario == "stable" && stableReading.get() && frameworkEvent) stableExternal.set(true)"""
assert s.count(needle)==1
s=s.replace(needle,"""                        if (pendingTraceCount.incrementAndGet() <= 32) records.add(
                            "PENDING_ORIGIN id=${request.id} origin=${request.r14Ingress?.origin ?: "NONE"} " +
                                "previous=${previous?.id} previousOrigin=${previous?.r14Ingress?.origin ?: "NONE"} " +
                                "pending=${pending?.id} pendingOrigin=${pending?.r14Ingress?.origin ?: "NONE"} " +
                                "framework=$frameworkEvent startsWorker=$startsWorker at=${SystemClock.uptimeMillis()}")
"""+needle)
needle="""            KeyguardR15AcquisitionTestHooks.firstFailureObserver = null"""
assert s.count(needle)==1
s=s.replace(needle,"""            records.add("PENDING_ORIGIN_OMITTED=${(pendingTraceCount.get() - 32L).coerceAtLeast(0L)}")
"""+needle)
p.write_text(s)
