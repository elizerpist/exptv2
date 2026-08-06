package com.fluvi.core.repository

import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.entity.FluviPartnerAliasEntity
import com.fluvi.core.database.entity.FluviPartnerEntity

/**
 * Expands a semantic Partner selection against one immutable database
 * snapshot. No DAO access is allowed here: prepared-index construction uses
 * the same snapshot for filtering and row projection.
 */
internal fun expandPartnerSelection(
    selectedPartnerIds: Set<String>,
    allPartners: List<FluviPartnerEntity>,
): Set<String> {
    if (selectedPartnerIds.isEmpty()) return emptySet()
    val partnersById = allPartners.associateBy { it.id }
    val selectedCanonicalIds = selectedPartnerIds
        .sorted()
        .mapTo(linkedSetOf()) { selectedPartnerId ->
            resolveCanonicalFrom(partnersById, selectedPartnerId)
        }
    return partnersById.keys.sorted().filterTo(linkedSetOf()) { candidateId ->
        resolveCanonicalFrom(partnersById, candidateId) in selectedCanonicalIds
    }
}

internal class FluviPartnerRepository(
    private val database: FluviDatabase,
) {
    private val partners = database.partnerDao()
    private val futureReferences = database.futureReferenceDao()

    suspend fun findByNormalizedAlias(normalizedAlias: String): FluviPartnerEntity? =
        partners.findByNormalizedAlias(normalizedAlias)

    suspend fun allEntities(): List<FluviPartnerEntity> = partners.allPartners()

    suspend fun requireById(partnerId: String): FluviPartnerEntity = requireNotNull(
        partners.findById(partnerId),
    ) {
        "Unknown partner ID: " + partnerId
    }

    suspend fun insert(
        partner: FluviPartnerEntity,
        alias: FluviPartnerAliasEntity,
    ) {
        partners.insert(partner)
        partners.insertAlias(alias)
    }

    suspend fun deleteAll(partnerIds: List<String>) {
        if (partnerIds.isEmpty()) return
        partners.deleteAliases(partnerIds)
        partners.deleteAll(partnerIds)
    }

    suspend fun resolveCanonicalPartnerId(partnerId: String): String {
        val visited = mutableSetOf<String>()
        var current = requireById(partnerId)

        while (current.mergedIntoPartnerId != null) {
            check(visited.add(current.id)) {
                "Partner merge cycle detected at " + current.id + "."
            }
            current = requireById(current.mergedIntoPartnerId)
        }
        return current.id
    }

    /** Returns every stored identity whose effective Partner is [canonicalPartnerId]. */
    suspend fun partnerIdsResolvingTo(canonicalPartnerId: String): Set<String> {
        val partnersById = partners.allPartners().associateBy { it.id }
        require(canonicalPartnerId in partnersById) {
            "Unknown partner ID: " + canonicalPartnerId
        }
        return partnersById.keys.filterTo(linkedSetOf()) { candidateId ->
            resolveCanonicalFrom(partnersById, candidateId) == canonicalPartnerId
        }
    }

    /**
     * Returns a donor and every identity merged beneath it, even if the donor
     * itself is currently merged into another Partner.
     */
    suspend fun partnerIdsInMergeSubtree(rootPartnerId: String): Set<String> {
        val allPartners = partners.allPartners()
        require(allPartners.any { it.id == rootPartnerId }) {
            "Unknown partner ID: " + rootPartnerId
        }
        val childrenByTarget = allPartners.groupBy { it.mergedIntoPartnerId }
        val result = linkedSetOf<String>()
        val pending = ArrayDeque<String>()
        pending.add(rootPartnerId)

        while (pending.isNotEmpty()) {
            val currentId = pending.removeFirst()
            check(result.add(currentId)) {
                "Partner merge cycle detected at " + currentId + "."
            }
            childrenByTarget[currentId].orEmpty().forEach { child ->
                pending.add(child.id)
            }
        }
        return result
    }

    suspend fun changeDefaultCategory(
        partnerId: String,
        categoryId: String,
        updatedAtUtcMs: Long,
    ) {
        check(
            partners.changeDefaultCategory(
                partnerId = partnerId,
                categoryId = categoryId,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Partner default category update did not affect exactly one row."
        }
    }

    suspend fun setDisplayNameOverride(
        partnerId: String,
        displayNameOverride: String?,
        updatedAtUtcMs: Long,
    ) {
        check(
            partners.setDisplayNameOverride(
                partnerId = partnerId,
                displayNameOverride = displayNameOverride,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Partner display-name update did not affect exactly one row."
        }
    }

    suspend fun setMergeTarget(
        donorId: String,
        recipientId: String?,
        updatedAtUtcMs: Long,
    ) {
        check(
            partners.setMergeTarget(
                donorId = donorId,
                recipientId = recipientId,
                updatedAtUtcMs = updatedAtUtcMs,
            ) == 1,
        ) {
            "Partner merge update did not affect exactly one row."
        }
    }

    suspend fun retargetInheritedRecurrenceRules(
        partnerIds: Collection<String>,
        categoryId: String,
        updatedAtUtcMs: Long,
    ): Int {
        if (partnerIds.isEmpty()) {
            return 0
        }
        return futureReferences.retargetInheritedRecurrenceRules(
            partnerIds = partnerIds.toList(),
            categoryId = categoryId,
            mode = com.fluvi.core.model.CategoryAssignmentMode.partnerDefault,
            updatedAtUtcMs = updatedAtUtcMs,
        )
    }
}

private fun resolveCanonicalFrom(
    partnersById: Map<String, FluviPartnerEntity>,
    partnerId: String,
): String {
    val visited = mutableSetOf<String>()
    var current = requireNotNull(partnersById[partnerId]) {
        "Unknown partner ID: " + partnerId
    }
    while (current.mergedIntoPartnerId != null) {
        check(visited.add(current.id)) {
            "Partner merge cycle detected at " + current.id + "."
        }
        current = requireNotNull(partnersById[current.mergedIntoPartnerId]) {
            "Partner merge target is missing: " + current.mergedIntoPartnerId
        }
    }
    return current.id
}
