package com.fluvi.app.lockscreen.host

import android.content.ComponentName
import android.content.Context
import android.content.Intent
import android.content.ServiceConnection
import android.content.pm.ApplicationInfo
import android.content.pm.PackageManager
import android.os.Binder
import android.os.IBinder
import android.os.Parcel
import android.os.Process
import android.os.UserHandle
import com.fluvi.r29.contract.R29Descriptor
import com.fluvi.r29.contract.R29Protocol
import com.fluvi.r29.contract.R29WireCodec
import java.util.concurrent.Executor
import java.util.concurrent.Executors

/**
 * Explicit reference-host client. It is not a stock-device rendering path.
 * An enrolling caller must first durably suppress and drain both old owners.
 */
internal class R29HostClient(
    context: Context,
    private val ownership: R29Ownership,
    private val main: Executor,
    private val listener: Listener,
    /** Same-UID, non-exported fixture service, accepted only in a debuggable APK. */
    private val testHost: ComponentName? = null,
) {
    interface Listener {
        fun onSession(nonce: String, epoch: Long)
        fun onReady(nonce: String, sequence: Long)
        fun onHostUnavailable()
        fun onHostEmpty(nonce: String, sequence: Long, epoch: Long) {}
    }

    private val application = context.applicationContext
    private val worker = Executors.newSingleThreadExecutor { task ->
        Thread(task, "fluvi-r29-publisher").apply { isDaemon = true }
    }
    private val lock = Any()
    private var remote: IBinder? = null
    private var expectedUid = -1
    private var session: String? = null
    private var epoch = -1L
    private var sentSequence = 0L
    private var bound = false
    // Accessed under lock together with the active remote and owner epoch.
    private val emptyReceipt = R35EmptyReceipt()
    private val component = testHost ?: ComponentName("com.android.systemui",
        "com.android.systemui.keyguard.fluvi.FluviOrbHostService")

    init {
        require(testHost == null ||
            (application.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0 &&
                testHost.packageName == application.packageName &&
                testHost.className == "com.fluvi.app.lockscreen.host.R35DebugResidentService"))
    }

    /** Resolves the explicit system component and compares its current platform signer and UID. */
    private fun trustedHostUid(): Int? = runCatching {
        val pm = application.packageManager
        val service = pm.getServiceInfo(component, 0)
        val app = service.applicationInfo ?: return@runCatching null
        val packages = pm.getPackagesForUid(app.uid)?.toList() ?: return@runCatching null
        if (testHost != null) {
            return@runCatching if (application.applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0 &&
                !service.exported && service.packageName == application.packageName && app.uid == Process.myUid() &&
                packages == listOf(application.packageName) &&
                pm.checkSignatures(application.packageName, service.packageName) == PackageManager.SIGNATURE_MATCH &&
                UserHandle.getUserHandleForUid(app.uid) == UserHandle.getUserHandleForUid(0)) app.uid else null
        }
        if (!service.exported || service.packageName != "com.android.systemui" ||
            app.flags and ApplicationInfo.FLAG_SYSTEM == 0 || packages != listOf("com.android.systemui") ||
            pm.checkSignatures("android", "com.android.systemui") != PackageManager.SIGNATURE_MATCH ||
            UserHandle.getUserHandleForUid(app.uid) != UserHandle.getUserHandleForUid(0)) null else app.uid
    }.getOrNull()

    /** Call only after the old owner drain for this exact durable epoch. */
    fun connect(value: Long) {
        if (ownership.epoch() != value || !ownership.hostMayBeRequested()) return unavailable()
        worker.execute {
            val uid = trustedHostUid() ?: return@execute unavailable()
            synchronized(lock) { expectedUid = uid; epoch = value }
            main.execute {
                val success = runCatching {
                    application.bindService(Intent().setComponent(component), connection, Context.BIND_AUTO_CREATE)
                }.getOrDefault(false)
                synchronized(lock) { bound = success }
                if (!success) unavailable()
            }
        }
    }

    private val connection = object : ServiceConnection {
        override fun onServiceConnected(name: ComponentName, service: IBinder) {
            worker.execute {
                val valid = name == component && trustedHostUid() == synchronized(lock) { expectedUid } &&
                    runCatching { service.interfaceDescriptor == R29WireCodec.INTERFACE }.getOrDefault(false)
                val value = synchronized(lock) { epoch }
                if (!valid || ownership.epoch() != value || !ownership.hostMayBeRequested()) {
                    unavailable(); return@execute
                }
                synchronized(lock) { remote = service }
                if (!send(service, R29WireCodec.TRANSACTION_SESSION) { out ->
                        out.writeLong(value)
                        out.writeInt(1) // The caller's exact-epoch drain was confirmed above.
                        out.writeStrongBinder(callback)
                    }) unavailable()
            }
        }
        override fun onServiceDisconnected(name: ComponentName) = unavailable()
        override fun onBindingDied(name: ComponentName) = unavailable()
        override fun onNullBinding(name: ComponentName) = unavailable()
    }

    private val callback = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code == INTERFACE_TRANSACTION) {
                reply?.writeString(R29WireCodec.INTERFACE)
                return true
            }
            if (code !in R29WireCodec.CALLBACK_SESSION..R29WireCodec.CALLBACK_EMPTY)
                return super.onTransact(code, data, reply, flags)
            val sender = getCallingUid()
            val original = clearCallingIdentity()
            try {
                val pinnedUid = synchronized(lock) { expectedUid }
                if (sender != pinnedUid || trustedHostUid() != pinnedUid || data.dataSize() > R29Protocol.MAX_PARCEL_BYTES)
                    throw SecurityException("untrusted R29 host callback")
                data.enforceInterface(R29WireCodec.INTERFACE)
                val nonce = data.readString() ?: throw SecurityException("R29 nonce missing")
                val value = data.readLong()
                if (!R29Protocol.validSession(nonce) || data.dataAvail() != 0) throw SecurityException("R29 callback invalid")
                when (code) {
                    R29WireCodec.CALLBACK_SESSION -> {
                        val active = synchronized(lock) {
                            if (value != epoch || remote == null || !ownership.hostOwns(value)) false
                            else { session = nonce; sentSequence = 0; true }
                        }
                        if (active) main.execute {
                            if (synchronized(lock) { session == nonce && remote != null && epoch == value })
                                listener.onSession(nonce, value)
                        }
                    }
                    R29WireCodec.CALLBACK_READY -> {
                        val current = synchronized(lock) {
                            nonce == session && value == sentSequence && remote != null &&
                                ownership.isCurrentHost(epoch)
                        }
                        if (current) main.execute {
                            if (synchronized(lock) { nonce == session && value == sentSequence && remote != null &&
                                    ownership.isCurrentHost(epoch) })
                                listener.onReady(nonce, value)
                        }
                    }
                    R29WireCodec.CALLBACK_EMPTY -> {
                        val acceptedEpoch = synchronized(lock) {
                            if (nonce != session || remote == null || value != sentSequence ||
                                !emptyReceipt.matches(nonce, value, epoch) ||
                                !ownership.hostConfirmedEmpty(epoch)) null
                            else {
                                emptyReceipt.clear()
                                session = null
                                epoch
                            }
                        }
                        if (acceptedEpoch != null) main.execute {
                            if (ownership.epoch() == acceptedEpoch && ownership.appMayShow())
                                listener.onHostEmpty(nonce, value, acceptedEpoch)
                        }
                    }
                }
                return true
            } finally { restoreCallingIdentity(original) }
        }
    }

    /** Prepared descriptors carry no category, labels, amounts or executable shader source. */
    fun publish(value: R29Descriptor) {
        val snapshot = R29Protocol.immutable(value)
        worker.execute {
            val target = synchronized(lock) {
                if (snapshot.session != session || snapshot.sequence <= sentSequence || remote == null ||
                    !ownership.isCurrentHost(epoch) ||
                    R29Protocol.invalidReason(snapshot, System.currentTimeMillis(), 1) != null) return@execute
                sentSequence = snapshot.sequence
                remote
            } ?: return@execute
            if (!send(target, R29WireCodec.TRANSACTION_PREPARE) { R29WireCodec.writeDescriptor(it, snapshot) }) unavailable()
        }
    }

    fun invalidate(nonce: String, sequence: Long) {
        worker.execute {
            val target = synchronized(lock) {
                if (nonce != session || sequence <= sentSequence || remote == null ||
                    !ownership.isCurrentHost(epoch)) return@execute
                sentSequence = sequence
                remote
            } ?: return@execute
            if (!send(target, R29WireCodec.TRANSACTION_INVALIDATE) { out ->
                    out.writeString(nonce); out.writeLong(sequence)
                }) unavailable()
        }
    }

    /**
     * Ask the trusted owner to remove its output. A true return only means the
     * request was queued. The stock owner remains suppressed until the host
     * sends the matching authenticated EMPTY receipt for a completed no-orb
     * composition. The staged reference host intentionally never sends one.
     */
    fun requestEmpty(sequence: Long): Boolean {
        val request = synchronized(lock) {
            val nonce = session ?: return false
            val target = remote ?: return false
            if (sequence <= sentSequence || !ownership.isCurrentHost(epoch) ||
                !emptyReceipt.begin(nonce, sequence, epoch)) return false
            if (ownership.beginExit() != epoch) {
                emptyReceipt.clear()
                return false
            }
            sentSequence = sequence
            nonce to target
        }
        return try {
            worker.execute {
                val active = synchronized(lock) {
                    session == request.first && remote === request.second &&
                        emptyReceipt.matches(request.first, sequence, epoch)
                }
                if (active && !send(request.second, R29WireCodec.TRANSACTION_OWNERSHIP) { out ->
                        out.writeString(request.first); out.writeLong(sequence)
                    }) unavailable()
            }
            true
        } catch (_: java.util.concurrent.RejectedExecutionException) {
            unavailable()
            false
        }
    }

    private fun send(target: IBinder, code: Int, write: (Parcel) -> Unit): Boolean {
        val data = Parcel.obtain()
        return try {
            data.writeInterfaceToken(R29WireCodec.INTERFACE)
            write(data)
            data.dataSize() <= R29Protocol.MAX_PARCEL_BYTES && target.transact(code, data, null, IBinder.FLAG_ONEWAY)
        } catch (_: Throwable) { false } finally { data.recycle() }
    }

    /** Clean detach may leave an already acknowledged demo image in host RAM. */
    fun close() {
        worker.execute {
            val (target, nonce) = synchronized(lock) { remote to session }
            if (target != null && nonce != null) send(target, R29WireCodec.TRANSACTION_DETACH) { it.writeString(nonce) }
            unavailable()
            worker.shutdown()
        }
    }

    private fun unavailable() {
        val (wasBound, unavailableEpoch) = synchronized(lock) {
            remote = null; session = null; sentSequence = 0
            emptyReceipt.clear()
            val result = bound
            bound = false
            result to epoch
        }
        ownership.hostUnavailable(unavailableEpoch)
        main.execute {
            if (wasBound) runCatching { application.unbindService(connection) }
            listener.onHostUnavailable()
        }
    }
}
