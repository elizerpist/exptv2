package com.fluvi.core.pulse

/** One versioned source of C-phase scoring rules. No policy is hidden in UI code. */
object PulsePriorityPolicyCatalog {
    const val policyVersion = 1
    const val materialModifier = 15
    const val dueSoonModifier = 10
    const val independentEvidenceModifier = 10

    fun base(indicatorId: String, strength: PulseSignalStrength?): Int? = when (indicatorId) {
        "PULSE-001" -> when (strength) {
            PulseSignalStrength.critical -> 100
            PulseSignalStrength.strong -> 85
            else -> 65
        }
        "PULSE-002" -> if (strength == PulseSignalStrength.critical || strength == PulseSignalStrength.strong) 85 else 65
        "PULSE-004" -> 85
        "PULSE-006" -> 45
        "PULSE-008" -> 60
        "PULSE-009" -> 70
        "PULSE-010" -> when (strength) {
            PulseSignalStrength.critical -> 100
            PulseSignalStrength.strong -> 85
            else -> 70
        }
        "PULSE-011" -> 80
        "PULSE-012" -> if (strength == PulseSignalStrength.critical) 100 else 65
        "PULSE-013" -> if (strength == PulseSignalStrength.critical) 100 else 85
        "PULSE-015" -> 65
        "PULSE-016" -> 45
        "PULSE-017" -> 70
        "PULSE-018", "PULSE-019" -> 35
        "PULSE-020" -> 40
        "PULSE-021" -> 45
        // Supporting/derived indicators never manufacture a new leading score.
        else -> null
    }

    fun materialThreshold(indicatorId: String, affectedBudgetMinor: Long?): Long? = when (indicatorId) {
        "PULSE-001", "PULSE-002", "PULSE-004" -> affectedBudgetMinor?.let { maxOf(1_000_000L, it / 10L) }
        "PULSE-009" -> 1_000_000L
        "PULSE-011", "PULSE-015", "PULSE-016", "PULSE-017" -> 3_000_000L
        else -> null
    }

    fun allowsDueSoon(indicatorId: String): Boolean = indicatorId in setOf("PULSE-011", "PULSE-017")

    fun allowsIndependentModifier(indicatorId: String): Boolean = indicatorId !in setOf("PULSE-018", "PULSE-019", "PULSE-020", "PULSE-021")

    fun recoveryEligibleBase(base: Int): Boolean = base >= 65
}
