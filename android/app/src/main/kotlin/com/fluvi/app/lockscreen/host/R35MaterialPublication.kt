package com.fluvi.app.lockscreen.host

import com.fluvi.app.lockscreen.material.KeyguardMaterialProfile
import com.fluvi.r29.contract.R29Protocol

/** Only these provenance scalars are taken from the Flutter material channel. */
internal data class R35MaterialEvidence(
    val targetCoreRevision: Long,
    val visualCoreRevision: Long,
    val currentCoreRevision: Long,
    val focusGeneration: Long,
    val layoutRevision: Long,
    val privacyRevision: Long,
    val visualProjectionFull: Boolean,
) {
    companion object {
        fun fromWire(value: Any?): R35MaterialEvidence? {
            val map = value as? Map<*, *> ?: return null
            // Flutter's standard codec represents an integer as Int or Long.
            // Do not truncate floating-point or other unverified values.
            fun integer(key: String): Long? = when (val item = map[key]) {
                is Int -> item.toLong()
                is Long -> item
                else -> null
            }
            return R35MaterialEvidence(
                targetCoreRevision = integer("targetCoreRevision") ?: return null,
                visualCoreRevision = integer("visualCoreRevision") ?: return null,
                currentCoreRevision = integer("currentCoreRevision") ?: return null,
                focusGeneration = integer("focusGeneration") ?: return null,
                layoutRevision = integer("layoutRevision") ?: return null,
                privacyRevision = integer("privacyRevision") ?: return null,
                visualProjectionFull = map["visualProjectionFull"] as? Boolean ?: return null,
            )
        }
    }
}

/**
 * Connects the existing profile/settings producers to an explicitly enrolled
 * publisher. No consumer is installed by default: the stock overlay continues
 * unchanged on devices without an actual trusted primary host. An enrolling
 * caller must first wire and drain both stock submission gates and obtain a
 * verified R29HostClient session; this hook alone does neither.
 */
internal object R35MaterialPublication {
    interface Consumer {
        fun onInputsChanging()
        fun onProfileAccepted(profile: KeyguardMaterialProfile, evidence: R35MaterialEvidence?)
        fun onPublicationFailure() {}
    }

    private data class Enrollment(val owner: R29Ownership, val session: String, val consumer: Consumer)
    @Volatile private var enrollment: Enrollment? = null

    @Synchronized fun install(owner: R29Ownership, session: String, consumer: Consumer): Boolean {
        if (enrollment != null || owner.phase() != R29Ownership.Phase.HOST ||
            !R29Protocol.validSession(session)) return false
        enrollment = Enrollment(owner, session, consumer)
        return true
    }

    @Synchronized fun remove(consumer: Consumer) {
        if (enrollment?.consumer === consumer) enrollment = null
    }

    fun inputsChanging(): Boolean {
        val current = enrollment ?: return false
        if (current.owner.phase() != R29Ownership.Phase.HOST) return false
        return runCatching { current.consumer.onInputsChanging(); true }.getOrElse {
            failClosed(current)
            false
        }
    }

    fun profileAccepted(profile: KeyguardMaterialProfile, rawEvidence: Any?) {
        val current = enrollment ?: return
        if (current.owner.phase() != R29Ownership.Phase.HOST) return
        // A profile is mutable through its array members. Freeze the complete
        // local input before an asynchronous publisher can inspect it.
        val snapshot = profile.copy(
            colors = profile.colors.copyOf(),
            stops = profile.stops.copyOf(),
            commonSettings = profile.commonSettings.copyOf(),
            background = profile.background.copy(settings = profile.background.settings.copyOf()),
            interior = profile.interior.copy(settings = profile.interior.settings.copyOf()),
        )
        runCatching { current.consumer.onProfileAccepted(snapshot, R35MaterialEvidence.fromWire(rawEvidence)) }
            .onFailure { failClosed(current) }
    }

    private fun failClosed(current: Enrollment) {
        synchronized(this) {
            if (enrollment !== current) return
            enrollment = null
        }
        current.owner.hostUnavailable()
        runCatching { current.consumer.onPublicationFailure() }
    }
}
