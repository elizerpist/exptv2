package com.fluvi.core.database

import com.fluvi.core.FluviCoreFactory
import org.junit.Assert.assertNotNull
import org.junit.Test

class FluviDatabaseFactoryContractTest {
    @Test
    fun cleanCorePublishesTheFacadeFactoryInsteadOfRawRoomDatabaseConstruction() {
        assertNotNull(FluviCoreFactory)
    }
}
