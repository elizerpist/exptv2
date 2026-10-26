package com.fluvi.core.pulse

import java.security.MessageDigest
import kotlin.math.roundToLong

/** Creates typed, source-addressable facts from the B/C immutable snapshot. */
object PulseStoryFactResolver {
    fun resolve(situation: PulseSituationSnapshot, candidate: PulsePriorityCandidate): PulseStoryFactBundle {
        val leading = situation.evidenceUnits.firstOrNull { it.evidenceKey == candidate.leadingEvidenceKey }
            ?: return PulseStoryFactBundle(situation.situationKey, situation.sourceCoreRevision, emptyList())
        val facts = mutableListOf<PulseStoryFact>()
        fun add(
            kind: PulseStoryFactKind,
            certainty: PulseStoryCertainty,
            amount: Long? = null,
            decimal: Double? = null,
            count: Int? = null,
            due: Long? = null,
            unit: PulseEvidenceUnit = leading,
            includedInForecast: Boolean = false,
        ) {
            if (amount == null && decimal == null && count == null && due == null) return
            facts += PulseStoryFact(
                factKey = "${unit.evidenceKey}/${kind.name}", kind = kind,
                sourceSignalKeys = unit.sourceSignalKeys, sourceEvidenceKeys = setOf(unit.evidenceKey),
                sourceFactKeys = unit.sourceFactKeys, certainty = certainty,
                amountMinor = amount, decimalValue = decimal, countValue = count,
                dueLocalEpochDay = due, periodKey = situation.periodKey,
                sourceCoreRevision = situation.sourceCoreRevision, includedInForecast = includedInForecast,
            )
        }
        fun budgetFacts(unit: PulseEvidenceUnit, category: Boolean) {
            unit.affectedBudgetMinor?.let { add(if (category) PulseStoryFactKind.categoryBudgetAmount else PulseStoryFactKind.actualBudgetLimit, PulseStoryCertainty.observed, amount = it, unit = unit) }
            unit.impactRatio?.let { ratio ->
                unit.affectedBudgetMinor?.let { limit ->
                    add(if (category) PulseStoryFactKind.categorySpentAmount else PulseStoryFactKind.actualBudgetSpent,
                        PulseStoryCertainty.observed, amount = (limit * ratio).roundToLong(), unit = unit)
                }
                add(PulseStoryFactKind.measuredRatio, PulseStoryCertainty.observed, decimal = ratio * 100.0, unit = unit)
            }
        }

        when (situation.domain) {
            PulseSituationDomain.monthlyBudget -> {
                situation.evidenceUnits.forEach { unit ->
                    when (unit.indicatorId) {
                        "PULSE-001" -> {
                            budgetFacts(unit, category = false)
                            unit.actualImpactMinor?.takeIf { it > 0 }?.let { add(PulseStoryFactKind.actualBudgetOverrun, PulseStoryCertainty.observed, amount = it, unit = unit) }
                        }
                        "PULSE-004" -> {
                            unit.affectedBudgetMinor?.let { add(PulseStoryFactKind.actualBudgetLimit, PulseStoryCertainty.observed, amount = it, unit = unit) }
                            unit.projectedImpactMinor?.takeIf { it > 0 }?.let { overrun ->
                                add(PulseStoryFactKind.projectedBudgetOverrun, PulseStoryCertainty.projected, amount = overrun, unit = unit)
                                unit.affectedBudgetMinor?.let { limit -> add(PulseStoryFactKind.projectedBudgetSpent, PulseStoryCertainty.projected, amount = limit + overrun, unit = unit) }
                            }
                        }
                        "PULSE-003" -> unit.measuredValue?.let { add(PulseStoryFactKind.spendingPaceRatio, PulseStoryCertainty.estimated, decimal = it, unit = unit) }
                        "PULSE-005" -> unit.dueLocalEpochDay?.let { add(PulseStoryFactKind.forecastCrossingDate, PulseStoryCertainty.projected, due = it, unit = unit, includedInForecast = true) }
                        "PULSE-017" -> {
                            unit.projectedImpactMinor?.takeIf { it > 0 }?.let { add(PulseStoryFactKind.knownPendingObligation, PulseStoryCertainty.scheduled, amount = it, unit = unit, includedInForecast = situation.evidenceUnits.any { evidence -> evidence.indicatorId == "PULSE-004" }) }
                            unit.dueLocalEpochDay?.let { add(PulseStoryFactKind.knownDueDate, PulseStoryCertainty.scheduled, due = it, unit = unit) }
                        }
                    }
                }
            }
            PulseSituationDomain.categoryBudget -> {
                budgetFacts(leading, category = true)
                leading.actualImpactMinor?.takeIf { it > 0 }?.let { add(PulseStoryFactKind.actualBudgetOverrun, PulseStoryCertainty.observed, amount = it) }
                leading.projectedImpactMinor?.takeIf { it > 0 }?.let { add(PulseStoryFactKind.projectedBudgetOverrun, PulseStoryCertainty.projected, amount = it) }
            }
            PulseSituationDomain.spendingBehavior -> leading.measuredValue?.let { add(PulseStoryFactKind.spendingPaceRatio, PulseStoryCertainty.estimated, decimal = it) }
            PulseSituationDomain.monthlyCashflow -> leading.projectedImpactMinor?.let { add(PulseStoryFactKind.projectedNetCashflow, PulseStoryCertainty.projected, amount = it) }
            PulseSituationDomain.liquidity -> {
                if (leading.indicatorId == "PULSE-012") leading.measuredValue?.let { add(PulseStoryFactKind.estimatedReserveDays, PulseStoryCertainty.estimated, decimal = it) }
                if (leading.indicatorId == "PULSE-013") leading.dueLocalEpochDay?.let { add(PulseStoryFactKind.projectedNegativeBalanceDate, PulseStoryCertainty.projected, due = it) }
            }
            PulseSituationDomain.expectedIncome -> {
                leading.measuredValue?.let { add(PulseStoryFactKind.expectedIncomeOverdueDays, PulseStoryCertainty.scheduled, count = it.roundToLong().toInt()) }
                leading.affectedObligationMinor?.let { add(PulseStoryFactKind.expectedIncomeAmount, PulseStoryCertainty.scheduled, amount = it) }
                leading.dueLocalEpochDay?.let { add(PulseStoryFactKind.expectedIncomeDueDate, PulseStoryCertainty.scheduled, due = it) }
            }
            PulseSituationDomain.recurringBurden -> leading.projectedImpactMinor?.let { add(PulseStoryFactKind.recurringBurdenAmount, PulseStoryCertainty.scheduled, amount = it) }
            PulseSituationDomain.subscriptionLoad -> leading.projectedImpactMinor?.let { add(PulseStoryFactKind.subscriptionBurdenAmount, PulseStoryCertainty.scheduled, amount = it) }
            PulseSituationDomain.upcomingObligation -> {
                leading.projectedImpactMinor?.let { add(PulseStoryFactKind.knownPendingObligation, PulseStoryCertainty.scheduled, amount = it) }
                leading.dueLocalEpochDay?.let { add(PulseStoryFactKind.knownDueDate, PulseStoryCertainty.scheduled, due = it) }
            }
            PulseSituationDomain.categorizationQuality -> leading.measuredValue?.let { add(PulseStoryFactKind.uncategorizedCount, PulseStoryCertainty.observed, count = it.roundToLong().toInt()) }
            PulseSituationDomain.parserReview -> leading.measuredValue?.let { add(PulseStoryFactKind.pushReviewCount, PulseStoryCertainty.observed, count = it.roundToLong().toInt()) }
            PulseSituationDomain.processingHealth -> leading.measuredValue?.let { add(PulseStoryFactKind.processingBacklogCount, PulseStoryCertainty.observed, count = it.roundToLong().toInt()) }
        }
        return PulseStoryFactBundle(situation.situationKey, situation.sourceCoreRevision, facts.distinctBy { it.factKey }.sortedBy { it.factKey })
    }
}

object PulseStoryRoleResolver {
    fun evidenceUnits(situation: PulseSituationSnapshot, candidate: PulsePriorityCandidate): List<PulseEvidenceUnit> =
        situation.evidenceUnits.sortedWith(compareBy<PulseEvidenceUnit> { it.evidenceKey != candidate.leadingEvidenceKey }.thenBy { it.evidenceKey })
}

object PulseStoryHeadlineResolver {
    fun resolve(context: PulseStoryContext): Pair<PulseStoryTemplateDefinition, String>? {
        val facts = context.facts.facts
        fun fact(kind: PulseStoryFactKind) = facts.firstOrNull { it.kind == kind }
        val claim = when (context.situation.domain) {
            PulseSituationDomain.monthlyBudget -> when {
                context.candidate.kind == PulsePriorityCandidateKind.recovery -> PulseStoryClaimType.verifiedRecovery
                fact(PulseStoryFactKind.actualBudgetOverrun)?.amountMinor?.let { it > 0 } == true -> PulseStoryClaimType.actualBreach
                fact(PulseStoryFactKind.projectedBudgetOverrun)?.amountMinor?.let { it > 0 } == true -> PulseStoryClaimType.projectedBreach
                else -> PulseStoryClaimType.highSpendingPace
            }
            PulseSituationDomain.categoryBudget -> if (fact(PulseStoryFactKind.actualBudgetOverrun)?.amountMinor?.let { it > 0 } == true) PulseStoryClaimType.actualBreach else PulseStoryClaimType.projectedBreach
            PulseSituationDomain.spendingBehavior -> PulseStoryClaimType.unusualSpending
            PulseSituationDomain.monthlyCashflow -> PulseStoryClaimType.negativeCashflow
            PulseSituationDomain.liquidity -> PulseStoryClaimType.insufficientCoverage
            PulseSituationDomain.expectedIncome -> PulseStoryClaimType.overdueExpectedIncome
            PulseSituationDomain.recurringBurden, PulseSituationDomain.subscriptionLoad -> PulseStoryClaimType.recurringBurden
            PulseSituationDomain.upcomingObligation -> PulseStoryClaimType.upcomingObligation
            PulseSituationDomain.categorizationQuality, PulseSituationDomain.parserReview -> PulseStoryClaimType.dataQualityIssue
            PulseSituationDomain.processingHealth -> PulseStoryClaimType.processingIssue
        }
        val template = if (claim == PulseStoryClaimType.verifiedRecovery) recoveryTemplate(context.situation.domain) else PulseStoryTemplateCatalog.find(context.situation.domain, claim)
            ?: return null
        if (template.requiredFactKinds.any { required -> facts.none { it.kind == required && it.certainty in template.allowedCertainties } }) return null
        val text = when (claim) {
            PulseStoryClaimType.actualBreach -> if (context.situation.domain == PulseSituationDomain.categoryBudget) "Az érintett kategória kerete túllépésben van." else "Túllépted a havi kereted."
            PulseStoryClaimType.projectedBreach -> if (context.situation.domain == PulseSituationDomain.categoryBudget) "Az érintett kategória kerete a hónap végére szorossá válhat." else "A hónap végére túllépheted a kereted."
            PulseStoryClaimType.highSpendingPace -> "A havi kereted jelentős része már elfogyott."
            PulseStoryClaimType.unusualSpending -> "Az utóbbi napokban szokatlanul megemelkedett a költésed."
            PulseStoryClaimType.negativeCashflow -> "A hónap várható pénzáramlása negatív."
            PulseStoryClaimType.insufficientCoverage -> "A közelgő kötelezettségekre nem látszik elegendő fedezet."
            PulseStoryClaimType.overdueExpectedIncome -> "Egy várt bevételed még nem érkezett meg."
            PulseStoryClaimType.upcomingObligation -> "Jelentős kiadás várható hamarosan."
            PulseStoryClaimType.recurringBurden -> if (context.situation.domain == PulseSituationDomain.subscriptionLoad) "Az előfizetéseid terhelése elérte a beállított határt." else "A rendszeres kiadásaid jelentős részt kötnek le a bevételeidből."
            PulseStoryClaimType.dataQualityIssue -> if (context.situation.domain == PulseSituationDomain.parserReview) "Banki értesítések felülvizsgálatra várnak." else "Tranzakciók még kategorizálatlanok."
            PulseStoryClaimType.processingIssue -> "Néhány banki értesítés feldolgozása elakadt."
            PulseStoryClaimType.verifiedRecovery -> "A korábbi pénzügyi helyzet igazolhatóan javult."
        }
        return template to text
    }

    private fun recoveryTemplate(domain: PulseSituationDomain) = PulseStoryTemplateDefinition(
        "${domain.name}-recovery-v1", PulseStoryTemplateCatalog.version, domain, PulseStoryClaimType.verifiedRecovery,
        emptySet(), allowedCertainties = setOf(PulseStoryCertainty.observed, PulseStoryCertainty.projected, PulseStoryCertainty.estimated),
    )
}

object PulseStoryEvidenceSelector {
    fun select(context: PulseStoryContext, claim: PulseStoryClaimType): Pair<List<PulseStoryFragment>, List<PulseStoryExclusion>> {
        val fragments = mutableListOf<PulseStoryFragment>()
        val exclusions = mutableListOf<PulseStoryExclusion>()
        val facts = context.facts.facts
        fun fragment(fact: PulseStoryFact, text: String): PulseStoryFragment = PulseStoryFragment(
            PulseStoryFragmentRole.evidence, "${context.situation.domain.name}-evidence-v1", text,
            fact.sourceSignalKeys.sorted(), fact.sourceEvidenceKeys.sorted(), fact.sourceFactKeys.sorted(), fact.certainty,
        )
        fun first(kind: PulseStoryFactKind) = facts.firstOrNull { it.kind == kind }
        when (claim) {
            PulseStoryClaimType.actualBreach -> first(PulseStoryFactKind.actualBudgetOverrun)?.let { fact ->
                fragments += fragment(fact, "A túllépés jelenleg ${PulseHungarianFormatter.money(requireNotNull(fact.amountMinor))}.")
            }
            PulseStoryClaimType.projectedBreach -> first(PulseStoryFactKind.projectedBudgetOverrun)?.let { fact ->
                fragments += fragment(fact, "Az előrejelzés ${PulseHungarianFormatter.money(requireNotNull(fact.amountMinor))} várható kerettúllépést mutat.")
            }
            PulseStoryClaimType.highSpendingPace -> first(PulseStoryFactKind.measuredRatio)?.let { fact ->
                fragments += fragment(fact, "A keretkihasználtság ${PulseHungarianFormatter.percent(requireNotNull(fact.decimalValue))}.")
            }
            PulseStoryClaimType.unusualSpending -> first(PulseStoryFactKind.spendingPaceRatio)?.let { fact ->
                fragments += fragment(fact, "A költési ütem ${PulseHungarianFormatter.ratio(requireNotNull(fact.decimalValue))} a fenntartható ütemhez képest.")
            }
            PulseStoryClaimType.negativeCashflow -> first(PulseStoryFactKind.projectedNetCashflow)?.let { fact ->
                fragments += fragment(fact, "A várható havi nettó pénzáramlás ${PulseHungarianFormatter.money(requireNotNull(fact.amountMinor))}.")
            }
            PulseStoryClaimType.insufficientCoverage -> first(PulseStoryFactKind.estimatedReserveDays)?.let { fact ->
                fragments += fragment(fact, "A becsült tartalékfedezet ${PulseHungarianFormatter.days(requireNotNull(fact.decimalValue).roundToLong().toInt())}.")
            }
            PulseStoryClaimType.overdueExpectedIncome -> first(PulseStoryFactKind.expectedIncomeOverdueDays)?.let { fact ->
                fragments += fragment(fact, "A bevétel ${PulseHungarianFormatter.days(requireNotNull(fact.countValue))} késésben van.")
                first(PulseStoryFactKind.expectedIncomeAmount)?.let { amount -> if (fragments.size < 2) fragments += fragment(amount, "A várt összeg ${PulseHungarianFormatter.money(requireNotNull(amount.amountMinor))}.") }
            }
            PulseStoryClaimType.upcomingObligation -> first(PulseStoryFactKind.knownPendingObligation)?.let { fact ->
                fragments += fragment(fact, "Az ismert várható kiadás ${PulseHungarianFormatter.money(requireNotNull(fact.amountMinor))}.")
            }
            PulseStoryClaimType.recurringBurden -> facts.firstOrNull { it.kind == PulseStoryFactKind.recurringBurdenAmount || it.kind == PulseStoryFactKind.subscriptionBurdenAmount }?.let { fact ->
                fragments += fragment(fact, "Az ismert havi teher ${PulseHungarianFormatter.money(requireNotNull(fact.amountMinor))}.")
            }
            PulseStoryClaimType.dataQualityIssue -> facts.firstOrNull { it.kind == PulseStoryFactKind.uncategorizedCount || it.kind == PulseStoryFactKind.pushReviewCount }?.let { fact ->
                val subject = if (fact.kind == PulseStoryFactKind.uncategorizedCount) "tranzakció" else "banki értesítés"
                fragments += fragment(fact, "${requireNotNull(fact.countValue)} $subject érintett.")
            }
            PulseStoryClaimType.processingIssue -> first(PulseStoryFactKind.processingBacklogCount)?.let { fact -> fragments += fragment(fact, "${requireNotNull(fact.countValue)} feldolgozási elem várakozik vagy hibás.") }
            PulseStoryClaimType.verifiedRecovery -> {}
        }
        facts.filter { fact -> fragments.none { fact.factKey in it.sourceFactKeys } }.forEach { fact ->
            if (fact.includedInForecast) exclusions += PulseStoryExclusion(fact.factKey, fact.sourceSignalKeys.firstOrNull(), fact.sourceEvidenceKeys.firstOrNull(), "same-forecast-lineage", "Az adat már a felhasznált előrejelzés része, ezért nem szerepel külön összegként.")
        }
        return fragments.take(2) to exclusions
    }
}

object PulseStoryTimeCauseResolver {
    fun resolve(context: PulseStoryContext): PulseStoryFragment? {
        val fact = context.facts.facts.firstOrNull { it.kind == PulseStoryFactKind.knownDueDate && it.certainty == PulseStoryCertainty.scheduled }
            ?: context.facts.facts.firstOrNull { it.kind == PulseStoryFactKind.expectedIncomeDueDate && it.certainty == PulseStoryCertainty.scheduled }
            ?: return null
        val date = fact.dueLocalEpochDay ?: return null
        return PulseStoryFragment(PulseStoryFragmentRole.timeCause, "known-due-date-v1", "Esedékessége ${PulseHungarianFormatter.relativeDate(date, context.generatedAtUtcMs, "Europe/Budapest")}.", fact.sourceSignalKeys.sorted(), fact.sourceEvidenceKeys.sorted(), fact.sourceFactKeys.sorted(), fact.certainty)
    }
}

object PulseStoryValidator {
    fun validate(draft: PulseStoryDraft): String? {
        if (draft.headline.isBlank()) return "missing-headline"
        if (draft.fragments.count { it.role == PulseStoryFragmentRole.evidence } > 2) return "too-many-evidence"
        if (draft.fragments.count { it.role == PulseStoryFragmentRole.timeCause } > 1) return "too-many-time-cause"
        if (draft.fragments.any { it.sourceFactKeys.isEmpty() || it.sourceSignalKeys.isEmpty() }) return "missing-source-mapping"
        if (draft.claimType == PulseStoryClaimType.projectedBreach && !draft.headline.contains("túllépheted")) return "projected-as-observed"
        if (draft.claimType == PulseStoryClaimType.actualBreach && draft.headline.contains("túllépheted")) return "observed-as-projected"
        return null
    }
}

/** Deterministic D-phase pipeline. It never writes Core, signal, triage, or priority state. */
object PulseStoryComposer {
    fun compose(context: PulseStoryContext): PulseStoryCompositionResult {
        if (context.facts.sourceCoreRevision != context.situation.sourceCoreRevision || context.situation.sourceCoreRevision != context.candidate.situation.sourceCoreRevision) {
            return PulseStoryCompositionResult(PulseStoryCompositionStatus.staleSnapshot, reasonCode = "source-revision-mismatch", explanationHu = "A Story bemenete nem ugyanahhoz a Core állapothoz tartozik.")
        }
        val headline = PulseStoryHeadlineResolver.resolve(context)
            ?: return PulseStoryCompositionResult(PulseStoryCompositionStatus.insufficientFacts, reasonCode = "missing-headline-facts", explanationHu = "A pontos fő állításhoz szükséges tényadatok hiányoznak.")
        val (template, text) = headline
        val (evidence, initialExclusions) = PulseStoryEvidenceSelector.select(context, template.claimType)
        val time = PulseStoryTimeCauseResolver.resolve(context)
        val headlineFragment = PulseStoryFragment(PulseStoryFragmentRole.headline, template.templateId, text,
            context.candidate.leadingSignalKey.let(::listOf), listOf(context.candidate.leadingEvidenceKey),
            context.situation.evidenceUnits.firstOrNull { it.evidenceKey == context.candidate.leadingEvidenceKey }?.sourceFactKeys?.sorted().orEmpty(),
            when (template.claimType) { PulseStoryClaimType.projectedBreach, PulseStoryClaimType.negativeCashflow -> PulseStoryCertainty.projected; PulseStoryClaimType.upcomingObligation, PulseStoryClaimType.overdueExpectedIncome -> PulseStoryCertainty.scheduled; else -> PulseStoryCertainty.observed })
        val fragments = listOf(headlineFragment) + evidence + listOfNotNull(time)
        val detail = fragments.filter { it.role != PulseStoryFragmentRole.headline }.joinToString(" ") { it.renderedText }.ifBlank { null }
        val storyKey = "story/${context.situation.situationKey}/${if (template.claimType == PulseStoryClaimType.verifiedRecovery) "recovery" else "risk"}"
        val content = fingerprint(listOf(storyKey, template.templateId, fragments.sortedBy { it.role.ordinal }.joinToString("|") { "${it.role}:${it.renderedText}:${it.sourceFactKeys.sorted()}" }).joinToString("|"))
        val material = fingerprint(listOf(storyKey, template.claimType, materialFacts(context.facts.facts).joinToString("|"), context.candidate.leadingEvidenceKey).joinToString("|"))
        val draft = PulseStoryDraft(storyKey, context.situation.situationKey, context.candidate.kind, template.claimType, text, detail,
            fragments, initialExclusions, context.priorityFrameId, context.situation.sourceCoreRevision, template.version,
            content, material, context.evaluationMode, context.generatedAtUtcMs)
        val error = PulseStoryValidator.validate(draft)
        return if (error == null) PulseStoryCompositionResult(PulseStoryCompositionStatus.composed, draft)
        else PulseStoryCompositionResult(PulseStoryCompositionStatus.validationFailed, reasonCode = error, explanationHu = "A Story állítása nem felelt meg a forrás- és bizonyossági ellenőrzésnek.")
    }

    private fun materialFacts(facts: List<PulseStoryFact>): List<String> = facts.sortedBy { it.factKey }.map { fact ->
        val bucket = fact.amountMinor?.let { (it / 10_000L).toString() }
            ?: fact.decimalValue?.let { (it * 10).roundToLong().toString() }
            ?: fact.countValue?.toString() ?: fact.dueLocalEpochDay?.toString().orEmpty()
        "${fact.kind}:$bucket:${fact.certainty}"
    }

    private fun fingerprint(value: String): String = MessageDigest.getInstance("SHA-256")
        .digest(value.toByteArray()).joinToString("") { "%02x".format(it) }.take(24)
}
