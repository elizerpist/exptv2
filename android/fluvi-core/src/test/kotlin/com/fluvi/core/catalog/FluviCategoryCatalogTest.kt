package com.fluvi.core.catalog

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FluviCategoryCatalogTest {
    @Test
    fun catalogProvidesExactlyTwentyOneStableColorIdsAndFiftyStableIconIds() {
        val catalogClass = Class.forName(
            "com.fluvi.core.catalog.FluviCategoryCatalog",
        )
        val catalog = catalogClass.getField("INSTANCE").get(null)
        @Suppress("UNCHECKED_CAST")
        val colorIds = catalogClass.getMethod("getColorIds").invoke(catalog) as Set<String>
        @Suppress("UNCHECKED_CAST")
        val iconIds = catalogClass.getMethod("getIconIds").invoke(catalog) as Set<String>

        assertEquals(21, colorIds.size)
        assertEquals(50, iconIds.size)
        assertEquals(colorIds.size, colorIds.toSet().size)
        assertEquals(iconIds.size, iconIds.toSet().size)
        assertTrue(colorIds.all { it.startsWith("color_") })
        assertTrue(iconIds.all { it.startsWith("icon_") })
    }
}
