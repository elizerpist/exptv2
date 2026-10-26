package com.fluvi.core.pulse

/**
 * Canonical indicator-to-situation map.  A signal can be referenced by a
 * second situation, but a descriptor is stable and never creates a duplicate
 * raw signal or a second financial fact.
 */
object PulseSituationCatalog {
    const val policyVersion: Int = 1

    fun descriptors(signal: PulseRawSignal): List<PulseSituationDescriptor> {
        val period = signal.periodKey
        val target = signal.targetKey.ifBlank { "aggregate" }
        fun descriptor(
            domain: PulseSituationDomain,
            key: String,
            role: PulseSituationSignalRole,
            targetKey: String = target,
        ) = PulseSituationDescriptor(key, domain, targetKey, period, role)
        return when (signal.indicatorId) {
            PulseIndicatorId.monthlyBudgetUtilization -> listOf(
                descriptor(PulseSituationDomain.monthlyBudget, "monthly-budget/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.categoryBudgetUtilization -> listOf(
                descriptor(PulseSituationDomain.categoryBudget, "category-budget/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.spendingMomentum -> listOf(
                descriptor(PulseSituationDomain.monthlyBudget, "monthly-budget/$period", PulseSituationSignalRole.supporting),
            )
            PulseIndicatorId.monthEndForecast -> listOf(
                descriptor(PulseSituationDomain.monthlyBudget, "monthly-budget/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.limitCrossing -> listOf(
                descriptor(PulseSituationDomain.monthlyBudget, "monthly-budget/$period", PulseSituationSignalRole.derived),
            )
            PulseIndicatorId.spendingOutlier,
            PulseIndicatorId.spendingConcentration,
            -> listOf(
                descriptor(PulseSituationDomain.spendingBehavior, "spending-behavior/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.incomeExpenseRatio,
            PulseIndicatorId.netCashflowForecast,
            -> listOf(
                descriptor(PulseSituationDomain.monthlyCashflow, "monthly-cashflow/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.cashflowStability -> listOf(
                descriptor(PulseSituationDomain.monthlyCashflow, "monthly-cashflow/$period", PulseSituationSignalRole.supporting),
            )
            PulseIndicatorId.fixedBurdenCoverage,
            PulseIndicatorId.reserveCoverDays,
            PulseIndicatorId.negativeTrajectory,
            -> listOf(
                descriptor(PulseSituationDomain.liquidity, "liquidity/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.lateIncome -> listOf(
                descriptor(PulseSituationDomain.expectedIncome, "expected-income/$target", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.recurringBurden -> listOf(
                descriptor(PulseSituationDomain.recurringBurden, "recurring-burden/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.subscriptionLoad -> listOf(
                descriptor(PulseSituationDomain.subscriptionLoad, "subscription-load/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.upcomingGhostLoad -> listOf(
                descriptor(PulseSituationDomain.upcomingObligation, "upcoming-obligation/$target/$period", PulseSituationSignalRole.leadingEligible),
                // Same raw evidence is a secondary reference for the monthly
                // budget situation. It can be counted there once, never twice.
                descriptor(PulseSituationDomain.monthlyBudget, "monthly-budget/$period", PulseSituationSignalRole.supporting, "aggregate"),
            )
            PulseIndicatorId.uncategorizedTransactions -> listOf(
                descriptor(PulseSituationDomain.categorizationQuality, "categorization-quality/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.categoryOverrideAnomaly -> listOf(
                descriptor(PulseSituationDomain.categorizationQuality, "categorization-quality/$target/$period", PulseSituationSignalRole.supporting),
            )
            PulseIndicatorId.uncertainPushRecognition -> listOf(
                descriptor(PulseSituationDomain.parserReview, "parser-review/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
            PulseIndicatorId.processingBacklog -> listOf(
                descriptor(PulseSituationDomain.processingHealth, "processing-health/$target/$period", PulseSituationSignalRole.leadingEligible),
            )
        }
    }
}
