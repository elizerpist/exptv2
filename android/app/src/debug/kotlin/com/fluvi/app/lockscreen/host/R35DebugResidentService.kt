package com.fluvi.app.lockscreen.host

import android.app.Service
import android.content.Intent
import android.content.pm.ApplicationInfo
import android.graphics.Color
import android.graphics.Bitmap
import android.graphics.PixelFormat
import android.hardware.HardwareBuffer
import android.media.ImageReader
import android.os.Binder
import android.os.Handler
import android.os.IBinder
import android.os.Looper
import android.os.Parcel
import android.os.Process
import com.android.systemui.keyguard.fluvi.R29HostRenderer
import com.android.systemui.keyguard.fluvi.R29PreparedOrb
import com.android.systemui.keyguard.fluvi.R29ResidentStore
import com.fluvi.r29.contract.R29Protocol
import com.fluvi.r29.contract.R29WireCodec
import java.security.MessageDigest
import java.security.SecureRandom
import java.io.File
import java.io.FileOutputStream
import java.util.concurrent.Executor
import java.util.concurrent.Executors

/**
 * Disposable same-UID, separately running demo receiver. Its ImageReader
 * surface is a test output, not the primary clock or a retail host. This class
 * and its non-exported service declaration exist only in debug builds.
 */
internal class R35DebugResidentService : Service() {
    private val handler = Handler(Looper.getMainLooper())
    private val main = Executor { task -> handler.post(task) }
    private val worker = Executors.newSingleThreadExecutor { task -> Thread(task, "r35-test-render") }
    private lateinit var store: R29ResidentStore
    private lateinit var images: ImageReader
    private val pending = ArrayDeque<Frame>()
    private var connectedNonce: String? = null
    private var callback: IBinder? = null
    private var death: IBinder.DeathRecipient? = null
    private var emptyPending = false
    private var destroyed = false
    private val outputLock = Any()
    private var renderedSequence = 0L
    private var renderedNonce: String? = null
    private var renderedDigest = ""
    private var differentPixels = 0
    private var savedFrames = 0
    private data class Frame(val nonce: String?, val sequence: Long, val empty: Boolean, val callback: IBinder?)

    override fun onCreate() {
        super.onCreate()
        check(applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE != 0)
        images = ImageReader.newInstance(SIZE, SIZE, PixelFormat.RGBA_8888, 4,
            HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or HardwareBuffer.USAGE_CPU_READ_OFTEN)
        images.setOnImageAvailableListener({ reader ->
            val image = reader.acquireNextImage() ?: return@setOnImageAvailableListener
            val frame = if (pending.isEmpty()) null else pending.removeFirst()
            try {
                if (frame == null) return@setOnImageAvailableListener
                val plane = image.planes[0]
                val buffer = plane.buffer
                val digest = MessageDigest.getInstance("SHA-256")
                val first = IntArray(4) { buffer.get(it).toInt() and 0xff }
                var changed = 0
                val row = ByteArray(SIZE * 4)
                val pixels = if (savedFrames < 24) IntArray(SIZE * SIZE) else null
                for (y in 0 until SIZE) {
                    buffer.position(y * plane.rowStride)
                    buffer.get(row)
                    digest.update(row)
                    for (x in 0 until SIZE) {
                        val offset = x * 4
                        if ((0..3).any { (row[offset + it].toInt() and 0xff) != first[it] }) changed++
                        pixels?.set(y * SIZE + x, Color.argb(row[offset + 3].toInt() and 0xff,
                            row[offset].toInt() and 0xff, row[offset + 1].toInt() and 0xff,
                            row[offset + 2].toInt() and 0xff))
                    }
                }
                val hash = digest.digest().joinToString("") { "%02x".format(it.toInt() and 0xff) }
                if (pixels != null) {
                    val directory = File(filesDir, "r35-demo-captures")
                    if (directory.mkdirs() || directory.isDirectory) {
                        val bitmap = Bitmap.createBitmap(pixels, SIZE, SIZE, Bitmap.Config.ARGB_8888)
                        try {
                            FileOutputStream(File(directory, "frame-${++savedFrames}-seq-${frame.sequence}.png")).use {
                                check(bitmap.compress(Bitmap.CompressFormat.PNG, 100, it))
                            }
                        } finally { bitmap.recycle() }
                    }
                }
                synchronized(outputLock) {
                    renderedNonce = frame.nonce
                    renderedSequence = frame.sequence
                    renderedDigest = hash
                    differentPixels = changed
                }
                // This receipt proves only this test surface's acquired empty
                // buffer, never a SystemUI/physical-screen composition.
                if (frame.empty && changed == 0 && frame.callback != null && frame.nonce != null) {
                    synchronized(this@R35DebugResidentService) {
                        if (emptyPending && connectedNonce == frame.nonce && callback === frame.callback &&
                            store.current(System.currentTimeMillis()) == null) {
                            sendCallback(frame.callback, R29WireCodec.CALLBACK_EMPTY, frame.nonce, frame.sequence)
                        }
                    }
                }
            } finally { image.close() }
        }, handler)
        store = R29ResidentStore(R29HostRenderer(applicationContext, worker), worker, main,
            scheduleExpiry = { task, delay -> check(handler.postDelayed(task, delay)) },
            cancelExpiry = { task -> handler.removeCallbacks(task) }) {
            if (!destroyed) {
                val ready = store.current(System.currentTimeMillis())
                draw(ready, Frame(ready?.descriptor?.session, ready?.descriptor?.sequence ?: 0L, false, null))
            }
        }
    }

    override fun onBind(intent: Intent?): IBinder = endpoint

    private fun requireSameUid() {
        val uid = Binder.getCallingUid()
        val packages = packageManager.getPackagesForUid(uid)?.toList()
        if (uid != Process.myUid() || packages != listOf(packageName) ||
            applicationInfo.flags and ApplicationInfo.FLAG_DEBUGGABLE == 0) throw SecurityException("R35 fixture caller")
    }

    private fun sendCallback(target: IBinder, code: Int, nonce: String, sequence: Long) {
        val out = Parcel.obtain()
        try {
            out.writeInterfaceToken(R29WireCodec.INTERFACE)
            out.writeString(nonce)
            out.writeLong(sequence)
            check(target.transact(code, out, null, IBinder.FLAG_ONEWAY))
        } finally { out.recycle() }
    }

    private fun clearConnection() {
        val old = callback
        val oldDeath = death
        if (old != null && oldDeath != null) runCatching { old.unlinkToDeath(oldDeath, 0) }
        callback = null
        death = null
        connectedNonce = null
    }

    private val endpoint = object : Binder() {
        override fun onTransact(code: Int, data: Parcel, reply: Parcel?, flags: Int): Boolean {
            if (code == INTERFACE_TRANSACTION) { reply?.writeString(R29WireCodec.INTERFACE); return true }
            if (code !in R29WireCodec.TRANSACTION_SESSION..R29WireCodec.TRANSACTION_OWNERSHIP &&
                code != PROBE && code != PROBE_DRAW)
                return super.onTransact(code, data, reply, flags)
            requireSameUid()
            if (data.dataSize() > R29Protocol.MAX_PARCEL_BYTES) throw SecurityException("R35 parcel size")
            data.enforceInterface(R29WireCodec.INTERFACE)
            when (code) {
                R29WireCodec.TRANSACTION_SESSION -> {
                    val epoch = data.readLong()
                    val drained = data.readInt() == 1
                    val target = data.readStrongBinder() ?: throw SecurityException("R35 callback missing")
                    if (epoch <= 0 || !drained || data.dataAvail() != 0) throw SecurityException("R35 drain missing")
                    val nonce = ByteArray(16).also(SecureRandom()::nextBytes)
                        .joinToString("") { "%02x".format(it.toInt() and 0xff) }
                    synchronized(this@R35DebugResidentService) {
                        clearConnection()
                        check(store.beginSession(nonce) { token, seq ->
                            runCatching { sendCallback(target, R29WireCodec.CALLBACK_READY, token, seq) }
                        })
                        val recipient = IBinder.DeathRecipient {
                            synchronized(this@R35DebugResidentService) {
                                if (connectedNonce == nonce) { clearConnection(); store.clientDied(nonce) }
                            }
                        }
                        target.linkToDeath(recipient, 0)
                        callback = target
                        death = recipient
                        connectedNonce = nonce
                        emptyPending = false
                    }
                    sendCallback(target, R29WireCodec.CALLBACK_SESSION, nonce, epoch)
                }
                R29WireCodec.TRANSACTION_PREPARE -> {
                    val descriptor = R29WireCodec.readDescriptor(data)
                    synchronized(this@R35DebugResidentService) {
                        if (!emptyPending && descriptor.session == connectedNonce)
                            store.prepare(descriptor, System.currentTimeMillis(), data.dataSize())
                    }
                }
                R29WireCodec.TRANSACTION_INVALIDATE, R29WireCodec.TRANSACTION_OWNERSHIP -> {
                    val nonce = data.readString() ?: throw SecurityException("R35 nonce missing")
                    val sequence = data.readLong()
                    if (data.dataAvail() != 0) throw SecurityException("R35 trailing data")
                    synchronized(this@R35DebugResidentService) {
                        if (nonce == connectedNonce && store.invalidate(nonce, sequence) &&
                            code == R29WireCodec.TRANSACTION_OWNERSHIP) {
                            emptyPending = true
                            val target = callback
                            handler.post { draw(null, Frame(nonce, sequence, true, target)) }
                        }
                    }
                }
                R29WireCodec.TRANSACTION_DETACH -> {
                    val nonce = data.readString() ?: throw SecurityException("R35 nonce missing")
                    if (data.dataAvail() != 0) throw SecurityException("R35 trailing data")
                    synchronized(this@R35DebugResidentService) {
                        if (nonce == connectedNonce) { store.detach(nonce); clearConnection() }
                    }
                }
                PROBE -> {
                    if (data.dataAvail() != 0 || reply == null) throw SecurityException("R35 probe")
                    synchronized(outputLock) {
                        reply.writeNoException()
                        reply.writeInt(Process.myPid())
                        reply.writeString(renderedNonce)
                        reply.writeLong(renderedSequence)
                        reply.writeString(renderedDigest)
                        reply.writeInt(differentPixels)
                    }
                }
                PROBE_DRAW -> {
                    if (data.dataAvail() != 0) throw SecurityException("R35 draw probe")
                    handler.post {
                        val ready = store.current(System.currentTimeMillis())
                        draw(ready, Frame(ready?.descriptor?.session, ready?.descriptor?.sequence ?: 0L, false, null))
                    }
                    reply?.writeNoException()
                }
            }
            return true
        }
    }

    /** Main-thread-only: a submitted frame is correlated with its acquired buffer. */
    private fun draw(orb: R29PreparedOrb?, frame: Frame) {
        if (destroyed) return
        val canvas = images.surface.lockHardwareCanvas()
        try {
            canvas.drawColor(Color.rgb(19, 23, 29))
            orb?.draw(canvas, 0f, 0f, System.nanoTime())
            pending.addLast(frame)
        } finally { images.surface.unlockCanvasAndPost(canvas) }
    }

    override fun onDestroy() {
        destroyed = true
        synchronized(this) { clearConnection(); store.reset() }
        images.close()
        worker.shutdown()
        super.onDestroy()
    }

    companion object {
        const val PROBE = IBinder.FIRST_CALL_TRANSACTION + 100
        const val PROBE_DRAW = IBinder.FIRST_CALL_TRANSACTION + 101
        private const val SIZE = 512
    }
}
