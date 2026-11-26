package com.fluvi.app.lockscreen

import android.os.Parcel
import android.os.SystemClock
import android.util.Base64
import android.view.accessibility.AccessibilityNodeInfo
import java.security.MessageDigest

/** A parcel digest is only a transient equality token, never diagnostic data.
 * It includes the framework node/window identity without depending on hidden
 * SDK methods. Any serialization failure or changed parent fails closed. */
internal object KeyguardR443ParentIdentity {
    fun of(node: AccessibilityNodeInfo): String? {
        val unique = runCatching { node.uniqueId }.getOrNull()
        if (unique != null) return "unique:$unique"
        val parcel = Parcel.obtain()
        val copy = runCatching { AccessibilityNodeInfo.obtain(node) }.getOrNull()
        if (copy == null) { parcel.recycle(); return null }
        return try {
            copy.writeToParcel(parcel, 0)
            if (parcel.dataSize() > 65536 || parcel.hasFileDescriptors()) null else {
                val bytes = parcel.marshall()
                val hash = MessageDigest.getInstance("SHA-256").digest(bytes)
                bytes.fill(0)
                "parcel:" + Base64.encodeToString(hash, Base64.NO_WRAP)
            }
        } catch (_: Exception) { null }
        finally { copy.recycle(); parcel.recycle() }
    }
}

/** Request-owned, bounded deferred work. No borrowed hierarchy node or parent
 * is retained. A missing stable parent identity is incomplete evidence. */
internal class KeyguardR443Inventory(
    private val budget: KeyguardR44ExtraBudget,
    private val authority: () -> Boolean,
) : AutoCloseable {
    private data class Candidate(
        val owner: KeyguardR44TreeReader,
        val node: AccessibilityNodeInfo,
        val ordinal: Int,
        val parentOrdinal: Int,
        val parentId: String?,
        val root: Boolean,
        val viewId: String?,
    )
    private val pending = ArrayList<Candidate>(7)
    var overflow = 0
        private set

    fun collect(owner: KeyguardR44TreeReader, node: AccessibilityNodeInfo,
                parent: AccessibilityNodeInfo?, ordinal: Int, parentOrdinal: Int, viewId: String?) {
        if (budget.restrictionObserved || budget.hardFailure || !authority()) return
        owner.candidateSeen(ordinal, parentOrdinal)
        if (pending.size >= 7) {
            overflow++
            owner.candidateOverflow()
            owner.candidateRejected(ordinal, "OVERFLOW")
            owner.unresolvedCandidate()
            return
        }
        val parentStarted = if (owner.diagnosticsEnabled()) SystemClock.uptimeMillis() else 0L
        val parentId = if (parent == null) null else runCatching {
            val currentParent = node.parent
            try {
                if (currentParent == null || currentParent != parent) null
                else KeyguardR443ParentIdentity.of(currentParent)
            } finally { currentParent?.recycle() }
        }.getOrNull()
        if (parent != null && owner.diagnosticsEnabled()) owner.candidateParentCheck(ordinal, SystemClock.uptimeMillis() - parentStarted)
        if (parent != null && parentId == null) {
            owner.candidateRejected(ordinal, "NO_PARENT_ID")
            owner.unresolvedCandidate()
            return
        }
        val copy = runCatching { AccessibilityNodeInfo.obtain(node) }.getOrNull()
        if (copy == null) {
            owner.candidateRejected(ordinal, "COPY_FAILED")
            owner.unresolvedCandidate()
            return
        }
        pending += Candidate(owner, copy, ordinal, parentOrdinal, parentId, parent == null, viewId)
        owner.pendingCandidate()
    }

    /** All direct/eager restrictions and the full window inventory have been
     * consumed before any deferred optional call. A positive is not published
     * until every retained candidate is resolved. */
    fun resolve(canExtend: (KeyguardR44TreeReader) -> Boolean) {
        // Kotlin's stable sort preserves encounter order within each class,
        // including when equal ordinals belong to different windows.
        val ordered = pending.sortedBy { it.owner.candidatePriority(it.parentOrdinal) }
        for (candidate in ordered) {
            val owner = candidate.owner
            if (budget.restrictionObserved || budget.hardFailure || !authority()) {
                owner.candidateRejected(candidate.ordinal, if (budget.restrictionObserved) "RESTRICTION" else "STALE_OR_FAILURE")
                owner.unresolvedCandidate()
                continue
            }
            owner.resolveDeferred(candidate.node, candidate.ordinal, candidate.parentOrdinal,
                candidate.parentId, candidate.root, candidate.viewId, authority,
                overflow == 0 && canExtend(owner))
        }
    }

    override fun close() {
        pending.forEach { runCatching { it.node.recycle() } }
        pending.clear()
    }
}
