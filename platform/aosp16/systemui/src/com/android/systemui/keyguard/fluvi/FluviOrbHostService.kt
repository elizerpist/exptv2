package com.android.systemui.keyguard.fluvi

import android.app.Service
import android.content.BroadcastReceiver
import android.content.ComponentCallbacks2
import android.content.Context
import android.content.Intent
import android.content.IntentFilter
import android.content.pm.PackageManager
import android.content.res.Configuration
import android.database.ContentObserver
import android.hardware.display.DisplayManager
import android.os.Binder
import android.os.Build
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Parcel
import android.os.UserHandle
import android.os.UserManager
import android.util.DisplayMetrics
import android.view.Display
import android.view.View
import android.provider.Settings
import com.fluvi.r29.contract.R29Protocol
import com.fluvi.r29.contract.R29PublisherIdentity
import com.fluvi.r29.contract.R29WireCodec
import java.security.MessageDigest
import java.security.SecureRandom
import java.util.TimeZone
import java.util.concurrent.Executor
import java.util.concurrent.Executors
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow

/**
 * Reference-only explicit service. This service authenticates every incoming
 * transaction. Scene integration must still impose draw-time restrictions; an
 * accepted or READY descriptor alone is never permission to reveal it.
 */
class FluviOrbHostService : Service() {
    private val main = Handler(Looper.getMainLooper())
    private val random = SecureRandom()
    private lateinit var runtime: R29HostRuntime
    private data class ClientConnection(
        val nonce: String,
        val binder: IBinder,
        val death: IBinder.DeathRecipient,
    )
    private val connectionLock = Any()
    private var clientConnection: ClientConnection? = null

    private fun clientDied(nonce: String, binder: IBinder) {
        val old = synchronized(connectionLock) {
            val current = clientConnection
            if (current == null || current.nonce != nonce || current.binder !== binder) return
            clientConnection = null
            current
        }
        runCatching { old.binder.unlinkToDeath(old.death, 0) }
        runtime.store.clientDied(nonce)
    }

    private fun cleanDetach(nonce: String) {
        synchronized(connectionLock) {
            val current = clientConnection
            if (current == null || current.nonce != nonce) return
            runtime.store.detach(nonce)
            clientConnection = null
            runCatching { current.binder.unlinkToDeath(current.death, 0) }
        }
    }

    override fun onCreate() {
        super.onCreate()
        runtime = R29HostRuntime.get(applicationContext)
    }

    override fun onBind(intent: Intent?): IBinder = endpoint

    private fun trustedCaller(uid: Int): Boolean = runCatching {
        val pm = packageManager
        val packages = pm.getPackagesForUid(uid)?.toList() ?: emptyList()
        val info = pm.getPackageInfo("com.fluvi.app", PackageManager.GET_SIGNING_CERTIFICATES)
        val certs = info.signingInfo?.apkContentsSigners?.map { signature ->
            MessageDigest.getInstance("SHA-256").digest(signature.toByteArray())
                .joinToString("") { "%02x".format(it.toInt() and 0xff) }
        } ?: emptyList()
        val isPrimaryUser = UserHandle.getUserHandleForUid(uid) == UserHandle.getUserHandleForUid(0)
        val userManager = getSystemService(UserManager::class.java)
        val foregroundUnlocked = userManager?.isUserForeground == true && userManager.isUserUnlocked
        R29Protocol.trustedPublisher(R29PublisherIdentity(
            callingUid = uid,
            packageUid = info.applicationInfo?.uid ?: -1,
            userId = if (isPrimaryUser && foregroundUnlocked) 0 else -1,
            packages = packages,
            certificates = certs,
            enrolled = Settings.Secure.getInt(contentResolver, ENROLLMENT_SETTING, 0) == 1,
            debuggableHost = Build.TYPE == "userdebug" || Build.TYPE == "eng",
        ))
    }.getOrDefault(false)

    private fun matchesDisplay(width: Int, height: Int, densityDpi: Int): Boolean = runCatching {
        val display = getSystemService(DisplayManager::class.java)?.getDisplay(Display.DEFAULT_DISPLAY)
            ?: return@runCatching false
        val metrics = DisplayMetrics()
        @Suppress("DEPRECATION")
        display.getRealMetrics(metrics)
        metrics.widthPixels == width && metrics.heightPixels == height && metrics.densityDpi == densityDpi
    }.getOrDefault(false)

    private fun sendCallback(callback: IBinder, code: Int, nonce: String, value: Long) {
        val data = Parcel.obtain()
        try {
            data.writeInterfaceToken(R29WireCodec.INTERFACE)
            data.writeString(nonce)
            data.writeLong(value)
            callback.transact(code, data, null, IBinder.FLAG_ONEWAY)
        } finally { data.recycle() }
    }

    private val endpoint = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code == INTERFACE_TRANSACTION) {
                reply?.writeString(R29WireCodec.INTERFACE)
                return true
            }
            if (code !in R29WireCodec.TRANSACTION_SESSION..R29WireCodec.TRANSACTION_OWNERSHIP)
                return super.onTransact(code, data, reply, flags)
            val callerUid = getCallingUid()
            val originalIdentity = clearCallingIdentity()
            try {
                if (!trustedCaller(callerUid)) throw SecurityException("R29 publisher not enrolled")
                if (data.dataSize() !in 1..R29Protocol.MAX_PARCEL_BYTES) throw SecurityException("R29 parcel size")
                data.enforceInterface(R29WireCodec.INTERFACE)
                when (code) {
                R29WireCodec.TRANSACTION_SESSION -> {
                    val ownershipEpoch = data.readLong()
                    val quiescent = data.readInt() == 1
                    val callback = data.readStrongBinder() ?: throw SecurityException("R29 callback missing")
                    if (data.dataAvail() != 0 || ownershipEpoch <= 0 || !quiescent)
                        throw SecurityException("R29 owner not quiescent")
                    val bytes = ByteArray(16).also(random::nextBytes)
                    val nonce = bytes.joinToString("") { "%02x".format(it.toInt() and 0xff) }
                    synchronized(connectionLock) {
                        if (!runtime.store.beginSession(nonce) { token, sequence ->
                                runCatching { sendCallback(callback, R29WireCodec.CALLBACK_READY, token, sequence) }
                            }) throw SecurityException("R29 session refused")
                        val previous = clientConnection
                        val death = IBinder.DeathRecipient { clientDied(nonce, callback) }
                        clientConnection = ClientConnection(nonce, callback, death)
                        try {
                            callback.linkToDeath(death, 0)
                        } catch (error: Throwable) {
                            clientConnection = null
                            runtime.store.clientDied(nonce)
                            throw error
                        } finally {
                            if (previous != null) runCatching { previous.binder.unlinkToDeath(previous.death, 0) }
                        }
                    }
                    runCatching { sendCallback(callback, R29WireCodec.CALLBACK_SESSION, nonce, ownershipEpoch) }
                        .onFailure { clientDied(nonce, callback) }
                }
                R29WireCodec.TRANSACTION_PREPARE -> {
                    val descriptor = R29WireCodec.readDescriptor(data)
                    if (descriptor.timeZoneId != TimeZone.getDefault().id ||
                        !matchesDisplay(descriptor.displayWidth, descriptor.displayHeight, descriptor.densityDpi)) {
                        runtime.store.invalidate(descriptor.session, descriptor.sequence)
                    } else {
                        runtime.store.prepare(descriptor, System.currentTimeMillis(), data.dataSize())
                    }
                }
                R29WireCodec.TRANSACTION_INVALIDATE -> {
                    val nonce = data.readString() ?: throw SecurityException("R29 nonce missing")
                    val sequence = data.readLong()
                    if (data.dataAvail() != 0) throw SecurityException("R29 trailing data")
                    runtime.store.invalidate(nonce, sequence)
                }
                R29WireCodec.TRANSACTION_DETACH -> {
                    val nonce = data.readString() ?: throw SecurityException("R29 nonce missing")
                    if (data.dataAvail() != 0) throw SecurityException("R29 trailing data")
                    cleanDetach(nonce)
                }
                R29WireCodec.TRANSACTION_OWNERSHIP -> {
                    val nonce = data.readString() ?: throw SecurityException("R29 nonce missing")
                    val sequence = data.readLong()
                    if (data.dataAvail() != 0) throw SecurityException("R29 trailing data")
                    val callback = synchronized(connectionLock) {
                        clientConnection?.takeIf { it.nonce == nonce }?.binder
                    } ?: throw SecurityException("R29 current client missing")
                    runtime.requestEmpty(nonce, sequence) {
                        runCatching { sendCallback(callback, R29WireCodec.CALLBACK_EMPTY, nonce, sequence) }
                    }
                }
                }
                return true
            } finally {
                restoreCallingIdentity(originalIdentity)
            }
        }
    }

    companion object { const val ENROLLMENT_SETTING = "fluvi_r29_demo_enrolled" }
}

/** Process-lifetime owner: an ordinary client unbind does not destroy a ready image. */
internal class R29HostRuntime private constructor(context: Context) : ComponentCallbacks2 {
    private val application = context.applicationContext
    private val mainHandler = Handler(Looper.getMainLooper())
    private val worker = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "fluvi-r29-host-prepare").apply { isDaemon = true }
    }
    private val main = Executor { runnable -> mainHandler.post(runnable) }
    val store = R29ResidentStore(
        R29HostRenderer(application, worker), worker, main,
        scheduleExpiry = { runnable, delay ->
            check(mainHandler.postDelayed(runnable, delay)) { "R29 expiry handler unavailable" }
        },
        cancelExpiry = { runnable -> mainHandler.removeCallbacks(runnable) },
    ) { notifyClockObservers() }
    @Volatile var onChanged: (() -> Unit)? = null
    private val observerLock = Any()
    private val clockObservers = LinkedHashMap<() -> Unit, View>()
    private data class PendingEmpty(val nonce: String, val sequence: Long, val receipt: () -> Unit,
                                    var registered: Boolean = false)
    private var pendingEmpty: PendingEmpty? = null
    // Changes only when a current owner draws an orb, not for repeated empty draws.
    private var ownerVisualEpoch = 0L

    fun addClockObserver(view: View, observer: () -> Unit) {
        synchronized(observerLock) { clockObservers[observer] = view }
        notifyClockObservers()
    }

    fun removeClockObserver(view: View, observer: () -> Unit) {
        synchronized(observerLock) {
            if (clockObservers[observer] === view) clockObservers.remove(observer)
        }
        notifyClockObservers()
    }

    fun isOnlyFrameOwner(view: View, observer: () -> Unit): Boolean = synchronized(observerLock) {
        clockObservers.size == 1 && clockObservers[observer] === view
    }

    private fun notifyClockObservers() {
        onChanged?.invoke()
        val callbacks = synchronized(observerLock) { clockObservers.keys.toList() }
        callbacks.forEach { runCatching { it() } }
    }

    /** Invalidation is immediate. EMPTY remains pending until a real clock-root
     * draw without the image and a matching frame-commit callback. */
    fun requestEmpty(nonce: String, sequence: Long, receipt: () -> Unit): Boolean {
        if (!store.invalidate(nonce, sequence)) return false
        synchronized(observerLock) { pendingEmpty = PendingEmpty(nonce, sequence, receipt) }
        mainHandler.post { notifyClockObservers() }
        return true
    }

    /** Called by the single persistent parent, never by a disposable scene child. */
    fun onOwnerDraw(view: View, observer: () -> Unit, orbDrawn: Boolean, noOutgoingScene: Boolean) {
        if (!view.isAttachedToWindow || !view.isHardwareAccelerated || !view.viewTreeObserver.isAlive) return
        var visualEpoch = 0L
        val pending = synchronized(observerLock) {
            if (clockObservers.size != 1 || clockObservers[observer] !== view) return
            if (orbDrawn) { ownerVisualEpoch += 1; return }
            if (!noOutgoingScene) return
            val value = pendingEmpty ?: return
            if (value.registered || !store.isCurrentEmpty(value.nonce, value.sequence)) return
            value.registered = true
            visualEpoch = ownerVisualEpoch
            value
        }
        val registered = runCatching {
            view.viewTreeObserver.registerFrameCommitCallback {
                val deliver = synchronized(observerLock) {
                    val valid = pendingEmpty === pending && clockObservers.size == 1 &&
                        clockObservers[observer] === view && view.isAttachedToWindow &&
                        ownerVisualEpoch == visualEpoch && store.isCurrentEmpty(pending.nonce, pending.sequence)
                    if (valid) pendingEmpty = null
                    else if (pendingEmpty === pending) pending.registered = false
                    valid
                }
                if (deliver) pending.receipt()
            }
        }.isSuccess
        if (!registered) synchronized(observerLock) {
            if (pendingEmpty === pending) pending.registered = false
        }
    }

    private val revokeReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) { store.reset() }
    }
    private val publisherReceiver = object : BroadcastReceiver() {
        override fun onReceive(context: Context?, intent: Intent?) {
            if (intent?.data?.schemeSpecificPart == "com.fluvi.app") store.reset()
        }
    }

    init {
        val systemChanges = IntentFilter().apply {
            addAction(Intent.ACTION_TIME_CHANGED)
            addAction(Intent.ACTION_TIMEZONE_CHANGED)
            addAction(Intent.ACTION_DATE_CHANGED)
            addAction("android.intent.action.USER_SWITCHED") // Intent.ACTION_USER_SWITCHED is platform-only.
            addAction(Intent.ACTION_CONFIGURATION_CHANGED)
        }
        application.registerReceiver(revokeReceiver, systemChanges, Context.RECEIVER_NOT_EXPORTED)
        val packageChanges = IntentFilter().apply {
            addAction(Intent.ACTION_PACKAGE_REMOVED)
            addAction(Intent.ACTION_PACKAGE_REPLACED)
            addAction(Intent.ACTION_PACKAGE_RESTARTED)
            addDataScheme("package")
        }
        application.registerReceiver(publisherReceiver, packageChanges, Context.RECEIVER_NOT_EXPORTED)
        application.contentResolver.registerContentObserver(
            Settings.Secure.getUriFor(FluviOrbHostService.ENROLLMENT_SETTING), false,
            object : ContentObserver(mainHandler) {
                override fun onChange(selfChange: Boolean) { store.reset() }
            },
        )
        application.registerComponentCallbacks(this)
    }

    override fun onTrimMemory(level: Int) {
        if (R35HostMemoryPolicy.shouldEvict(level)) store.reset()
    }
    override fun onLowMemory() { store.reset() }
    override fun onConfigurationChanged(newConfig: Configuration) { store.reset() }

    companion object {
        @Volatile private var instance: R29HostRuntime? = null
        private val mutableRuntime = MutableStateFlow<R29HostRuntime?>(null)
        val runtime: StateFlow<R29HostRuntime?> = mutableRuntime
        fun get(context: Context): R29HostRuntime = instance ?: synchronized(this) {
            instance ?: R29HostRuntime(context).also {
                instance = it
                // The clock composition may already exist before enrollment.
                // Wake never has to discover, bind or initialize the host.
                mutableRuntime.value = it
            }
        }
    }
}
