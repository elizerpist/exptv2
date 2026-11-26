package com.fluvi.app.lockscreen.material

import android.content.Context
import com.fluvi.app.lockscreen.FluviKeyguardCardSettings
import java.util.UUID

/**
 * The last frame that the foreground dashboard actually committed.  Header
 * colours can encode private data, so this store has no public-material API.
 * It is bounded to one in-memory scene and is lost on process death.
 * A retained scene is an input to a later admission check, never an admission.
 */
internal object FluviActiveHeaderMaterialStore {
    internal class Snapshot private constructor(
        val profile: KeyguardMaterialProfile,
        val settingsGeneration: Long,
        val activeMode: String,
        val modeEpoch: Long,
        val correlation: String,
        val receivedAtNanos: Long,
    ) {
        companion object {
            internal fun create(profile: KeyguardMaterialProfile, settingsGeneration: Long,
                                activeMode: String, modeEpoch: Long): Snapshot = Snapshot(
                profile.copy(
                    colors = profile.colors.clone(), stops = profile.stops.clone(),
                    commonSettings = profile.commonSettings.clone(),
                    background = profile.background.copy(settings = profile.background.settings.clone()),
                    interior = profile.interior.copy(settings = profile.interior.settings.clone()),
                ), settingsGeneration, activeMode, modeEpoch, UUID.randomUUID().toString(), System.nanoTime(),
            )
        }
    }

    internal data class Receipt(val accepted: Boolean, val reason: String)

    @Volatile private var current: Snapshot? = null
    private var publisherEpoch = -1L
    private var publisherSession: String? = null
    private var publisherRevision = -1L

    /** Called only on the Activity channel; a background/locked callback is
     * rejected before it can replace the last committed foreground frame. */
    @Synchronized
    fun publish(context: Context, values: Map<*, *>, epoch: Long,
                foregroundAndUnlocked: Boolean): Receipt {
        if (!foregroundAndUnlocked || epoch <= 0) return Receipt(false, "foregroundUnavailable")
        val settings = FluviKeyguardCardSettings.read(context)
        if (!settings.requested || !settings.showFinancialDetails) return Receipt(false, "disclosureDisabled")
        val profile = (KeyguardMaterialProfile.decode(values) as? KeyguardMaterialProfile.Companion.DecodeResult.Accepted)
            ?.profile ?: return Receipt(false, "invalidProfile")
        val mode = values["activeMode"] as? String ?: return Receipt(false, "missingMode")
        val modeEpoch = (values["modeEpoch"] as? Number)?.toLong() ?: return Receipt(false, "missingModeEpoch")
        if (mode !in setOf("balance", "budget", "mind") || modeEpoch < 0 ||
            profile.sceneIdentity != "active-header:$mode:$modeEpoch" ||
            values["sourceAnimated"] != profile.animated) return Receipt(false, "sourceMismatch")
        if (!KeyguardMaterialPublicationOrder.accepts(publisherEpoch, publisherSession, publisherRevision,
                epoch, profile.publisherSession, profile.publisherRevision)) return Receipt(false, "stalePublisher")
        publisherEpoch = epoch
        publisherSession = profile.publisherSession
        publisherRevision = profile.publisherRevision
        current = Snapshot.create(profile, settings.generation, mode, modeEpoch)
        return Receipt(true, "accepted")
    }

    /** Returns only the exact still-current generation. No settings value or
     * public-sample result on its own grants permission to present it. */
    fun applicable(context: Context): Snapshot? {
        val candidate = current ?: return null
        val settings = FluviKeyguardCardSettings.read(context)
        return candidate.takeIf { current === it && settings.requested && settings.showFinancialDetails &&
            settings.generation == it.settingsGeneration }
    }

    fun isCurrent(context: Context, snapshot: Snapshot): Boolean = applicable(context) === snapshot

    /** Cheap per-owner check; settings changes invalidate the reference first. */
    fun isCurrentReference(snapshot: Snapshot): Boolean = current === snapshot

    @Synchronized
    fun invalidate() { current = null }
}
