package com.fluvi.app.lockscreen.material

import android.graphics.HardwareRenderer
import android.graphics.Paint
import android.graphics.PixelFormat
import android.graphics.RenderNode
import android.hardware.HardwareBuffer
import android.media.ImageReader
import android.os.Build
import android.os.Handler
import android.os.Looper
import java.util.concurrent.ExecutorService
import java.util.concurrent.Executors
import kotlin.math.min

/**
 * A request owns only immutable material inputs.  In particular it never
 * receives a View-owned RuntimeShader: the worker creates, configures, draws,
 * and discards its own instance.  That makes a real renderer exercise useful
 * as preparation without introducing concurrent uniform mutation.
 */
internal data class KeyguardGpuMaterialPreparationRequest(
    val key: String,
    val artifact: KeyguardShaderArtifact,
    val profile: KeyguardMaterialProfile,
    val shape: KeyguardHeaderMaterialView.Shape,
    val width: Int,
    val height: Int,
    val cornerRadiusPx: Float,
)

internal enum class KeyguardGpuMaterialPreparationStatus {
    READY,
    FAILED,
    NOT_SUPPORTED,
}

internal data class KeyguardGpuMaterialPreparationResult(
    val request: KeyguardGpuMaterialPreparationRequest,
    val status: KeyguardGpuMaterialPreparationStatus,
    /** True only after ImageReader supplied a non-empty rendered output. */
    val outputAcquired: Boolean,
    val failure: Throwable? = null,
)

/** Injectable boundary for production hardware preparation and deterministic
 * ownership/race tests. */
internal interface KeyguardGpuMaterialPreparer {
    fun prepare(
        request: KeyguardGpuMaterialPreparationRequest,
        onCompleted: (KeyguardGpuMaterialPreparationResult) -> Unit,
    )

    fun dispose()
}

/**
 * One worker, one running renderer request and one replaceable successor.
 * A running GPU call is deliberately not cancelled: drivers do not promise
 * interruption.  An obsolete completion is discarded by the controller, and
 * every renderer/image resource is still released on this worker.
 */
internal class AndroidKeyguardGpuMaterialPreparer(
    private val executor: ExecutorService = Executors.newSingleThreadExecutor { runnable ->
        Thread(runnable, "fluvi-keyguard-gpu-prepare").apply { isDaemon = true }
    },
    private val mainHandler: Handler = Handler(Looper.getMainLooper()),
) : KeyguardGpuMaterialPreparer {
    private data class Pending(
        val request: KeyguardGpuMaterialPreparationRequest,
        val onCompleted: (KeyguardGpuMaterialPreparationResult) -> Unit,
    )

    private val lock = Any()
    private var active: Pending? = null
    private var pending: Pending? = null
    private var closed = false

    override fun prepare(
        request: KeyguardGpuMaterialPreparationRequest,
        onCompleted: (KeyguardGpuMaterialPreparationResult) -> Unit,
    ) {
        val start: Pending? = synchronized(lock) {
            if (closed) {
                mainHandler.post {
                    onCompleted(
                        KeyguardGpuMaterialPreparationResult(
                            request,
                            KeyguardGpuMaterialPreparationStatus.FAILED,
                            outputAcquired = false,
                            failure = IllegalStateException("preparer-disposed"),
                        ),
                    )
                }
                return
            }
            val running = active
            if (running?.request?.key == request.key || pending?.request?.key == request.key) return
            val next = Pending(request, onCompleted)
            if (running == null) {
                active = next
                next
            } else {
                // The newest selected material replaces a not-yet-started
                // request. There is no unbounded preparation backlog.
                pending = next
                null
            }
        }
        start?.let(::run)
    }

    private fun run(work: Pending) {
        executor.execute {
            val result = render(work.request)
            mainHandler.post {
                val next = synchronized(lock) {
                    if (active === work) active = null
                    val successor = pending
                    pending = null
                    if (!closed && successor != null) {
                        active = successor
                        successor
                    } else null
                }
                work.onCompleted(result)
                next?.let(::run)
            }
        }
    }

    private fun render(request: KeyguardGpuMaterialPreparationRequest): KeyguardGpuMaterialPreparationResult {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.TIRAMISU) {
            return KeyguardGpuMaterialPreparationResult(
                request,
                KeyguardGpuMaterialPreparationStatus.NOT_SUPPORTED,
                outputAcquired = false,
            )
        }
        return runCatching {
            val width = request.width.coerceAtLeast(1)
            val height = request.height.coerceAtLeast(1)
            val reader = ImageReader.newInstance(
                width,
                height,
                PixelFormat.RGBA_8888,
                2,
                HardwareBuffer.USAGE_GPU_COLOR_OUTPUT or HardwareBuffer.USAGE_GPU_SAMPLED_IMAGE,
            )
            val renderer = HardwareRenderer()
            try {
                val node = RenderNode("fluvi-keyguard-material-warmup").apply {
                    setPosition(0, 0, width, height)
                }
                val shader = KeyguardHeaderShader(request.artifact)
                val canvas = node.beginRecording(width, height)
                try {
                    val paint = Paint(Paint.ANTI_ALIAS_FLAG)
                    val time = KeyguardMaterialTime(
                        elapsedSeconds = request.profile.elapsedSeconds,
                        phase = request.profile.phase,
                        backgroundPhase = request.profile.background.phase,
                        interiorPhase = request.profile.interior.phase,
                    )
                    shader.configure(request.profile, width, height, time)
                    paint.shader = shader.runtimeShader
                    when (request.shape) {
                        KeyguardHeaderMaterialView.Shape.ORB -> {
                            val radius = min(width, height) / 2f
                            canvas.drawCircle(width / 2f, height / 2f, radius, paint)
                        }
                        KeyguardHeaderMaterialView.Shape.CARD_BACKGROUND ->
                            canvas.drawRoundRect(0f, 0f, width.toFloat(), height.toFloat(), request.cornerRadiusPx, request.cornerRadiusPx, paint)
                    }
                    paint.shader = null
                } finally {
                    node.endRecording()
                }
                renderer.setSurface(reader.surface)
                renderer.setContentRoot(node)
                // This wait is confined to the independent preparation worker.
                // No show, hide, draw, or accessibility callback joins it.
                renderer.createRenderRequest().setWaitForPresent(true).syncAndDraw()
                val image = reader.acquireLatestImage()
                    ?: error("gpu-output-unavailable")
                try {
                    checkNotNull(image.hardwareBuffer) { "gpu-output-hardware-buffer-unavailable" }
                    check(image.width > 0 && image.height > 0) { "gpu-output-empty" }
                } finally {
                    image.close()
                }
                KeyguardGpuMaterialPreparationResult(
                    request,
                    KeyguardGpuMaterialPreparationStatus.READY,
                    outputAcquired = true,
                )
            } finally {
                renderer.destroy()
                reader.close()
            }
        }.getOrElse { error ->
            KeyguardGpuMaterialPreparationResult(
                request,
                KeyguardGpuMaterialPreparationStatus.FAILED,
                outputAcquired = false,
                failure = error,
            )
        }
    }

    override fun dispose() {
        synchronized(lock) {
            closed = true
            pending = null
        }
        executor.shutdown()
    }
}
