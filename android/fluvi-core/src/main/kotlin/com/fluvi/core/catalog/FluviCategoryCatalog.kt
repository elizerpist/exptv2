package com.fluvi.core.catalog

object FluviCategoryCatalog {
    val colorIds: Set<String> = (1..21)
        .mapTo(linkedSetOf()) { index -> "color_" + index.toString().padStart(2, '0') }

    val iconIds: Set<String> = (1..50)
        .mapTo(linkedSetOf()) { index -> "icon_" + index.toString().padStart(2, '0') }

    const val SYSTEM_UNCATEGORIZED_COLOR_ID = "color_01"
    const val SYSTEM_UNCATEGORIZED_ICON_ID = "icon_01"
}
