package com.fluvi.core.repository

import java.util.Locale

internal object PartnerAliasNormalizer {
    private val whitespace = Regex("\\s+")

    fun displayName(name: String): String = name.trim().also {
        require(it.isNotEmpty()) { "Partner name must not be blank." }
    }

    fun normalize(name: String): String = displayName(name)
        .lowercase(Locale.ROOT)
        .replace(whitespace, " ")
}
