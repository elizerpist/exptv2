package com.fluvi.core.sync

/**
 * A restore plan is deliberately not execution. A future storage adapter owns
 * bundle download, validation, atomic database replacement, and reopening.
 */
data class LedgerRestorePlan(
    val targetCheckpointId: String,
    val preRestoreCheckpoint: LedgerCheckpointPreparation,
)
