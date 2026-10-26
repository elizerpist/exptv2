package com.fluvi.core.pulse

/**
 * Versioned, native copy contract.  Template IDs are stable diagnostics and
 * are intentionally independent from the Flutter renderer.
 */
object PulseStoryTemplateCatalog {
    const val version: Int = 1

    private fun definition(
        id: String,
        domain: PulseSituationDomain,
        claim: PulseStoryClaimType,
        required: Set<PulseStoryFactKind>,
        optional: Set<PulseStoryFactKind> = emptySet(),
        certainty: Set<PulseStoryCertainty>,
    ) = PulseStoryTemplateDefinition(id, version, domain, claim, required, optional, certainty)

    val templates: List<PulseStoryTemplateDefinition> = listOf(
        definition("monthly-budget-actual-breach-v1", PulseSituationDomain.monthlyBudget, PulseStoryClaimType.actualBreach,
            setOf(PulseStoryFactKind.actualBudgetOverrun), setOf(PulseStoryFactKind.actualBudgetLimit), setOf(PulseStoryCertainty.observed)),
        definition("monthly-budget-projected-breach-v1", PulseSituationDomain.monthlyBudget, PulseStoryClaimType.projectedBreach,
            setOf(PulseStoryFactKind.projectedBudgetOverrun), setOf(PulseStoryFactKind.actualBudgetLimit), setOf(PulseStoryCertainty.projected)),
        definition("monthly-budget-high-usage-v1", PulseSituationDomain.monthlyBudget, PulseStoryClaimType.highSpendingPace,
            setOf(PulseStoryFactKind.measuredRatio), emptySet(), setOf(PulseStoryCertainty.observed, PulseStoryCertainty.estimated)),
        definition("category-budget-actual-breach-v1", PulseSituationDomain.categoryBudget, PulseStoryClaimType.actualBreach,
            setOf(PulseStoryFactKind.actualBudgetOverrun), setOf(PulseStoryFactKind.categoryBudgetAmount), setOf(PulseStoryCertainty.observed)),
        definition("category-budget-projected-breach-v1", PulseSituationDomain.categoryBudget, PulseStoryClaimType.projectedBreach,
            setOf(PulseStoryFactKind.projectedBudgetOverrun), setOf(PulseStoryFactKind.categoryBudgetAmount), setOf(PulseStoryCertainty.projected)),
        definition("spending-behavior-pace-v1", PulseSituationDomain.spendingBehavior, PulseStoryClaimType.unusualSpending,
            setOf(PulseStoryFactKind.spendingPaceRatio), emptySet(), setOf(PulseStoryCertainty.observed, PulseStoryCertainty.estimated)),
        definition("monthly-cashflow-negative-v1", PulseSituationDomain.monthlyCashflow, PulseStoryClaimType.negativeCashflow,
            setOf(PulseStoryFactKind.projectedNetCashflow), emptySet(), setOf(PulseStoryCertainty.projected, PulseStoryCertainty.estimated)),
        definition("liquidity-coverage-v1", PulseSituationDomain.liquidity, PulseStoryClaimType.insufficientCoverage,
            setOf(PulseStoryFactKind.estimatedReserveDays), emptySet(), setOf(PulseStoryCertainty.observed, PulseStoryCertainty.estimated)),
        definition("expected-income-overdue-v1", PulseSituationDomain.expectedIncome, PulseStoryClaimType.overdueExpectedIncome,
            setOf(PulseStoryFactKind.expectedIncomeOverdueDays), setOf(PulseStoryFactKind.expectedIncomeAmount), setOf(PulseStoryCertainty.scheduled)),
        definition("recurring-burden-v1", PulseSituationDomain.recurringBurden, PulseStoryClaimType.recurringBurden,
            setOf(PulseStoryFactKind.recurringBurdenAmount), emptySet(), setOf(PulseStoryCertainty.scheduled, PulseStoryCertainty.projected)),
        definition("subscription-load-v1", PulseSituationDomain.subscriptionLoad, PulseStoryClaimType.recurringBurden,
            setOf(PulseStoryFactKind.subscriptionBurdenAmount), emptySet(), setOf(PulseStoryCertainty.scheduled, PulseStoryCertainty.observed)),
        definition("upcoming-obligation-v1", PulseSituationDomain.upcomingObligation, PulseStoryClaimType.upcomingObligation,
            setOf(PulseStoryFactKind.knownPendingObligation), setOf(PulseStoryFactKind.knownDueDate), setOf(PulseStoryCertainty.scheduled)),
        definition("categorization-quality-v1", PulseSituationDomain.categorizationQuality, PulseStoryClaimType.dataQualityIssue,
            setOf(PulseStoryFactKind.uncategorizedCount), emptySet(), setOf(PulseStoryCertainty.observed)),
        definition("parser-review-v1", PulseSituationDomain.parserReview, PulseStoryClaimType.dataQualityIssue,
            setOf(PulseStoryFactKind.pushReviewCount), emptySet(), setOf(PulseStoryCertainty.observed)),
        definition("processing-health-v1", PulseSituationDomain.processingHealth, PulseStoryClaimType.processingIssue,
            setOf(PulseStoryFactKind.processingBacklogCount), emptySet(), setOf(PulseStoryCertainty.observed)),
    )

    fun find(domain: PulseSituationDomain, claim: PulseStoryClaimType): PulseStoryTemplateDefinition? =
        templates.firstOrNull { it.domain == domain && it.claimType == claim }
}
