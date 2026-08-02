package com.fluvi.core.demo

import com.fluvi.core.model.CategoryAssignmentMode
import com.fluvi.core.model.LedgerDirection

data class DemoCategoryDraft(
    val id: String,
    val name: String,
    val colorId: String,
    val iconId: String,
)

data class DemoPartnerDraft(
    val id: String,
    val aliasId: String,
    val name: String,
    val defaultCategoryId: String,
)

data class DemoEntryDraft(
    val id: String,
    val partnerId: String,
    val categoryId: String,
    val assignmentMode: CategoryAssignmentMode,
    val note: String?,
    val direction: LedgerDirection,
    val amountScaled100: Long,
    val bookedLocalEpochDay: Long,
    val bookedLocalTimeMinutes: Int,
    val occurredAtUtcMs: Long,
)

data class DemoMonthReport(
    val year: Int,
    val month: Int,
    val entryCount: Int,
    val incomeCount: Int,
    val expenseCount: Int,
    val incomeTargetScaled100: Long,
    val expenseTargetScaled100: Long,
    val incomeTotalScaled100: Long,
    val expenseTotalScaled100: Long,
)

data class DemoDatasetPlan(
    val version: Int,
    val prngSeed: Long,
    val categories: List<DemoCategoryDraft>,
    val partners: List<DemoPartnerDraft>,
    val entries: List<DemoEntryDraft>,
    val monthlyReports: List<DemoMonthReport>,
)

data class DemoSeedReport(
    val seedVersion: Int,
    val prngSeed: Long,
    val createdCategoryCount: Int,
    val createdPartnerCount: Int,
    val createdEntryCount: Int,
    val monthlyReports: List<DemoMonthReport>,
    val earliestEntryAtUtcMs: Long,
    val latestEntryAtUtcMs: Long,
    val alreadySeeded: Boolean,
    val durationMs: Long,
)
