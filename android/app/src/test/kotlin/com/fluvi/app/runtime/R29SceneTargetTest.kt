package com.fluvi.app.runtime

import org.robolectric.RuntimeEnvironment
import com.fluvi.core.FluviCoreFactory
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** Uses the real saved-focus producer and Room database, not an R29 descriptor fixture. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class R29SceneTargetTest {
    @Test fun budgetSceneTargetCarriesTheRevisionOfItsActualScopedProjection() = runBlocking {
        val context = RuntimeEnvironment.getApplication()
        val core = FluviCoreFactory.create(context)
        try {
            core.demoSeed.seed()
            val category = core.categories.list().first()
            val expectedRevision = core.query.currentCoreRevision()
            val focus = FluviLockScreenCardConfiguration(
                enabled = true,
                mode = FluviLockScreenCardConfiguration.Mode.budget,
                categoryId = category.id,
                generation = 41,
            )
            val target = FluviLockScreenCardCoordinator.materialSceneTarget(context, focus)
            assertTrue("a real seeded category must be projected", target.projectionAvailable)
            assertNotNull(target.categoryColorId)
            assertEquals(41L, target.focusGeneration)
            assertEquals("the revision must travel on the actual Dart channel", expectedRevision,
                target.toMap()["coreRevision"])
        } finally {
            core.close()
        }
    }
}
