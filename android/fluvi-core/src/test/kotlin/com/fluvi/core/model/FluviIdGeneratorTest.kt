package com.fluvi.core.model

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class FluviIdGeneratorTest {
    @Test
    fun monotonicUlidsHaveCanonicalLengthAndLexicalCreationOrder() {
        val generatorClass = Class.forName(
            "com.fluvi.core.model.MonotonicUlidGenerator",
        )
        val generator = generatorClass.getDeclaredConstructor().newInstance()
        val next = generatorClass.getMethod("next")

        val first = next.invoke(generator) as String
        val second = next.invoke(generator) as String

        assertEquals(26, first.length)
        assertEquals(26, second.length)
        assertTrue(first < second)
    }
}
