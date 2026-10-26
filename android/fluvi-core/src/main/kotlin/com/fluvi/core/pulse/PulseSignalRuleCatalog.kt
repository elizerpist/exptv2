package com.fluvi.core.pulse

/**
 * Canonical raw-signal contract for all financial measurements.  This is not a
 * triage catalog: evidence families and dependencies are provenance only.
 */
object PulseSignalRuleCatalog {
    private val rules = listOf(
        rule(PulseIndicatorId.monthlyBudgetUtilization, "budgetUtilization", PulseSignalComparisonOperator.greaterThanOrEqual, "actual-budget-spending", maximum = PulseSignalStrength.strong),
        rule(PulseIndicatorId.categoryBudgetUtilization, "categoryBudgetUtilization", PulseSignalComparisonOperator.greaterThanOrEqual, "category-budget-spending", maximum = PulseSignalStrength.strong, target = PulseSignalTargetStrategy.category),
        rule(PulseIndicatorId.spendingMomentum, "paceRatio", PulseSignalComparisonOperator.greaterThanOrEqual, "spending-velocity", dependencies = listOf("PULSE-001"), maximum = PulseSignalStrength.medium, confirmations = 2),
        rule(PulseIndicatorId.monthEndForecast, "forecastBudgetOverrun", PulseSignalComparisonOperator.greaterThanOrEqual, "spending-projection", dependencies = listOf("PULSE-003"), maximum = PulseSignalStrength.strong),
        rule(PulseIndicatorId.limitCrossing, "daysUntilLimitCrossing", PulseSignalComparisonOperator.dueWithin, "spending-projection", dependencies = listOf("PULSE-004"), maximum = PulseSignalStrength.medium),
        rule(PulseIndicatorId.spendingOutlier, "dailyDeviation", PulseSignalComparisonOperator.deviationAbove, "behavioral-anomaly", maximum = PulseSignalStrength.medium, confirmations = 2),
        rule(PulseIndicatorId.spendingConcentration, "concentrationShare", PulseSignalComparisonOperator.greaterThanOrEqual, "behavioral-anomaly", maximum = PulseSignalStrength.medium),
        rule(PulseIndicatorId.incomeExpenseRatio, "expenseIncomeRatio", PulseSignalComparisonOperator.greaterThanOrEqual, "income-expense-flow", maximum = PulseSignalStrength.strong),
        rule(PulseIndicatorId.netCashflowForecast, "netCashflow", PulseSignalComparisonOperator.lessThanOrEqual, "income-expense-flow", dependencies = listOf("PULSE-004"), maximum = PulseSignalStrength.strong),
        rule(PulseIndicatorId.fixedBurdenCoverage, "coverageRatio", PulseSignalComparisonOperator.lessThanOrEqual, "cash-balance-coverage", maximum = PulseSignalStrength.critical),
        rule(PulseIndicatorId.lateIncome, "overdueDays", PulseSignalComparisonOperator.overdueBy, "scheduled-obligations", maximum = PulseSignalStrength.strong, target = PulseSignalTargetStrategy.occurrence),
        rule(PulseIndicatorId.reserveCoverDays, "reserveDays", PulseSignalComparisonOperator.lessThanOrEqual, "cash-balance-coverage", maximum = PulseSignalStrength.critical),
        rule(PulseIndicatorId.negativeTrajectory, "daysUntilNegative", PulseSignalComparisonOperator.dueWithin, "cash-balance-coverage", dependencies = listOf("PULSE-009"), maximum = PulseSignalStrength.critical),
        rule(PulseIndicatorId.cashflowStability, "normalizedVolatility", PulseSignalComparisonOperator.greaterThanOrEqual, "income-expense-flow", maximum = PulseSignalStrength.medium, confirmations = 2),
        rule(PulseIndicatorId.recurringBurden, "recurringBurdenRatio", PulseSignalComparisonOperator.greaterThanOrEqual, "recurring-burden", maximum = PulseSignalStrength.strong),
        rule(PulseIndicatorId.subscriptionLoad, "subscriptionLoad", PulseSignalComparisonOperator.greaterThanOrEqual, "recurring-burden", maximum = PulseSignalStrength.medium, requiresPositiveThreshold = true),
        rule(PulseIndicatorId.upcomingGhostLoad, "upcomingGhostLoad7d", PulseSignalComparisonOperator.greaterThanOrEqual, "scheduled-obligations", maximum = PulseSignalStrength.medium, requiresPositiveThreshold = true),
        rule(PulseIndicatorId.uncategorizedTransactions, "uncategorizedCount", PulseSignalComparisonOperator.greaterThanOrEqual, "categorization-quality", maximum = PulseSignalStrength.medium),
        rule(PulseIndicatorId.categoryOverrideAnomaly, "overrideRatio", PulseSignalComparisonOperator.greaterThanOrEqual, "categorization-quality", maximum = PulseSignalStrength.medium, target = PulseSignalTargetStrategy.partner),
        rule(PulseIndicatorId.uncertainPushRecognition, "reviewCount", PulseSignalComparisonOperator.greaterThanOrEqual, "parser-review", maximum = PulseSignalStrength.medium),
        rule(PulseIndicatorId.processingBacklog, "backlogCount", PulseSignalComparisonOperator.greaterThanOrEqual, "processing-health", maximum = PulseSignalStrength.strong),
    )

    private fun rule(
        id: PulseIndicatorId,
        metric: String,
        operator: PulseSignalComparisonOperator,
        family: String,
        dependencies: List<String> = emptyList(),
        maximum: PulseSignalStrength,
        confirmations: Int = 1,
        requiresPositiveThreshold: Boolean = false,
        target: PulseSignalTargetStrategy = PulseSignalTargetStrategy.global,
    ) = PulseSignalRuleDefinition(
        indicatorId = id,
        metricKey = metric,
        comparisonOperator = operator,
        evidenceFamily = family,
        dependencyIds = dependencies,
        maximumStandaloneStrength = maximum,
        confirmationsRequired = confirmations,
        requiresPositiveThreshold = requiresPositiveThreshold,
        targetStrategy = target,
    )

    fun ruleFor(id: PulseIndicatorId): PulseSignalRuleDefinition =
        rules.first { it.indicatorId == id }

    fun all(): List<PulseSignalRuleDefinition> = rules
}
