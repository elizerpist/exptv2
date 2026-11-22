package com.fluvi.r29.contract

import android.os.BadParcelableException
import android.os.IBinder
import android.os.Parcel

/**
 * Fixed, data-only Binder wire format. The receiving onTransact MUST check
 * Binder.getCallingUid(), current enrollment and the actual Parcel.dataSize()
 * before calling [readDescriptor]. It must not use a UID from this parcel.
 */
internal object R29WireCodec {
    const val INTERFACE = "com.android.systemui.fluvi.r29.v1"
    const val TRANSACTION_SESSION = IBinder.FIRST_CALL_TRANSACTION
    const val TRANSACTION_PREPARE = IBinder.FIRST_CALL_TRANSACTION + 1
    const val TRANSACTION_INVALIDATE = IBinder.FIRST_CALL_TRANSACTION + 2
    const val TRANSACTION_DETACH = IBinder.FIRST_CALL_TRANSACTION + 3
    const val TRANSACTION_OWNERSHIP = IBinder.FIRST_CALL_TRANSACTION + 4
    const val CALLBACK_SESSION = IBinder.FIRST_CALL_TRANSACTION
    const val CALLBACK_READY = IBinder.FIRST_CALL_TRANSACTION + 1
    const val CALLBACK_EMPTY = IBinder.FIRST_CALL_TRANSACTION + 2

    fun writeDescriptor(out: Parcel, d: R29Descriptor) {
        out.writeInt(d.schemaVersion)
        out.writeString(d.session)
        out.writeLong(d.sequence)
        out.writeLong(d.visualRevision)
        out.writeLong(d.dataRevision)
        out.writeLong(d.focusGeneration)
        out.writeLong(d.layoutRevision)
        out.writeLong(d.privacyRevision)
        out.writeLong(d.validFromEpochMs)
        out.writeLong(d.validUntilEpochMs)
        out.writeInt(d.userId)
        out.writeInt(d.displayId)
        out.writeInt(d.displayWidth)
        out.writeInt(d.displayHeight)
        out.writeInt(d.densityDpi)
        out.writeInt(d.orbSizePx)
        out.writeFloat(d.xFraction)
        out.writeFloat(d.yFraction)
        out.writeInt(d.disclosure.ordinal)
        out.writeInt(if (d.projectionCurrent) 1 else 0)
        out.writeInt(d.motion.ordinal)
        out.writeInt(d.period.ordinal)
        out.writeString(d.timeZoneId)
        val m = d.material
        out.writeInt(m.schemaVersion)
        out.writeInt(m.shaderAbiVersion)
        out.writeString(m.sourceShaderHash)
        out.writeString(m.effectId)
        out.writeInt(m.effectShaderId)
        out.writeFloat(m.phase)
        out.writeFloat(m.elapsedSeconds)
        out.writeFloat(m.phaseSpeed)
        out.writeInt(m.colors.size)
        m.colors.forEach(out::writeInt)
        out.writeInt(m.stops.size)
        m.stops.forEach(out::writeFloat)
        out.writeFloat(m.opacity)
        out.writeFloat(m.paletteSplitPercent)
        out.writeInt(m.commonSettings.size)
        m.commonSettings.forEach(out::writeFloat)
        writePortal(out, m.background)
        writePortal(out, m.interior)
        out.writeFloat(m.referenceWidth)
        out.writeFloat(m.referenceHeight)
    }

    private fun writePortal(out: Parcel, p: R29Portal) {
        out.writeInt(if (p.enabled) 1 else 0)
        out.writeInt(p.effectIndex)
        out.writeFloat(p.phase)
        out.writeFloat(p.phaseSpeed)
        out.writeFloat(p.paletteCenterPercent)
        out.writeFloat(p.paletteWindowPercent)
        out.writeInt(if (p.rotationEnabled) 1 else 0)
        out.writeFloat(p.rotationSpeed)
        out.writeInt(p.settings.size)
        p.settings.forEach(out::writeFloat)
    }

    /** Fails closed on malformed counts before allocating a collection. */
    fun readDescriptor(input: Parcel): R29Descriptor {
        if (input.dataSize() !in 1..R29Protocol.MAX_PARCEL_BYTES) throw BadParcelableException("parcelSize")
        fun text(max: Int): String = input.readString()?.takeIf { it.length in 1..max }
            ?: throw BadParcelableException("text")
        fun bool(): Boolean = when (input.readInt()) {
            0 -> false
            1 -> true
            else -> throw BadParcelableException("boolean")
        }
        fun floats(min: Int, max: Int): List<Float> {
            val size = input.readInt()
            if (size !in min..max || size > input.dataAvail() / 4) throw BadParcelableException("floatCount")
            return List(size) { input.readFloat() }
        }
        fun ints(min: Int, max: Int): List<Int> {
            val size = input.readInt()
            if (size !in min..max || size > input.dataAvail() / 4) throw BadParcelableException("intCount")
            return List(size) { input.readInt() }
        }
        fun portal(): R29Portal {
            val enabled = bool()
            val effectIndex = input.readInt()
            val phase = input.readFloat()
            val phaseSpeed = input.readFloat()
            val center = input.readFloat()
            val window = input.readFloat()
            val rotation = bool()
            val rotationSpeed = input.readFloat()
            val settings = floats(12, 12)
            return R29Portal(enabled, effectIndex, phase, phaseSpeed, center, window, rotation, rotationSpeed, settings)
        }
        val schema = input.readInt()
        val session = text(32)
        val sequence = input.readLong()
        val visual = input.readLong()
        val data = input.readLong()
        val focus = input.readLong()
        val layout = input.readLong()
        val privacy = input.readLong()
        val validFrom = input.readLong()
        val validUntil = input.readLong()
        val user = input.readInt()
        val display = input.readInt()
        val width = input.readInt()
        val height = input.readInt()
        val density = input.readInt()
        val size = input.readInt()
        val x = input.readFloat()
        val y = input.readFloat()
        val disclosure = R29Disclosure.entries.getOrNull(input.readInt()) ?: throw BadParcelableException("disclosure")
        val current = bool()
        val motion = R29Motion.entries.getOrNull(input.readInt()) ?: throw BadParcelableException("motion")
        val period = R29Period.entries.getOrNull(input.readInt()) ?: throw BadParcelableException("period")
        val timeZone = text(64)
        val materialSchema = input.readInt()
        val shaderAbi = input.readInt()
        val hash = text(64)
        val effect = text(64)
        val effectId = input.readInt()
        val phase = input.readFloat()
        val elapsed = input.readFloat()
        val speed = input.readFloat()
        val colors = ints(2, 10)
        val stops = floats(2, 10)
        val opacity = input.readFloat()
        val split = input.readFloat()
        val common = floats(40, 40)
        val background = portal()
        val interior = portal()
        val referenceWidth = input.readFloat()
        val referenceHeight = input.readFloat()
        if (input.dataAvail() != 0) throw BadParcelableException("trailingData")
        val material = R29Material(effect, effectId, phase, elapsed, speed, colors, stops, opacity, split,
            common, background, interior, referenceWidth, referenceHeight, materialSchema, shaderAbi, hash)
        return R29Descriptor(session, sequence, visual, data, focus, layout, privacy, validFrom, validUntil,
            user, display, width, height, density, size, x, y, disclosure, current, material,
            motion, period, timeZone, schema)
    }
}
