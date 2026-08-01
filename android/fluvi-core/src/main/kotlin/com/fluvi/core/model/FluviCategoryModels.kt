package com.fluvi.core.model

import java.text.Normalizer
import java.util.Locale

/** Public, persistence-free category data exposed by the clean core. */
data class FluviCategory(
    val id: String,
    val name: String,
    val colorId: String,
    val iconId: String,
    val isSystemUncategorized: Boolean,
    val createdAtUtcMs: Long,
    val updatedAtUtcMs: Long,
)

object FluviCategoryNameNormalizer {
    fun normalize(value: String): String = Normalizer
        .normalize(value.trim(), Normalizer.Form.NFKC)
        .lowercase(Locale.ROOT)
}
