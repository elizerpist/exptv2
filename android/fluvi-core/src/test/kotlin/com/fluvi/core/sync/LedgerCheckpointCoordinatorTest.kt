package com.fluvi.core.sync

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import com.fluvi.core.database.FluviDatabase
import com.fluvi.core.database.FluviDatabaseFactory
import com.fluvi.core.database.entity.FluviLedgerDeletionArchiveEntity
import com.fluvi.core.model.CheckpointKind
import com.fluvi.core.model.CheckpointStatus
import com.fluvi.core.model.FluviClock
import com.fluvi.core.model.FluviIdGenerator
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

@RunWith(RobolectricTestRunner::class)
@Config(sdk = [28])
class LedgerCheckpointCoordinatorTest {
    private lateinit var database: FluviDatabase
    private lateinit var coordinator: LedgerCheckpointCoordinator

    @Before
    fun setUp() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        database = FluviDatabaseFactory.createInMemory(
            context = context,
            clock = FluviClock { 1_700_000_000_000L },
        )
        coordinator = LedgerCheckpointCoordinator(
            database = database,
            idGenerator = IncrementingIds(),
            clock = FluviClock { 1_700_000_000_000L },
        )
    }

    @After
    fun tearDown() {
        database.close()
    }

    @Test
    fun dailyCheckpointDeduplicatesByLocalDayAndDestructiveCheckpointIsSeparate() = runBlocking {
        val daily = coordinator.prepareDaily(localEpochDay = 20_000L)
        val repeatedDaily = coordinator.prepareDaily(localEpochDay = 20_000L)
        val destructive = coordinator.prepareBeforeDestructive()

        assertEquals(daily.id, repeatedDaily.id)
        assertNotEquals(daily.id, destructive.id)
        assertEquals(CheckpointKind.daily, daily.kind)
        assertEquals(CheckpointKind.beforeDestructive, destructive.kind)
        assertEquals(CheckpointStatus.prepared, destructive.status)
        assertNull(destructive.preparedBundlePath)
    }

    @Test
    fun checkpointLifecycleOnlyRecordsPreparationContractAndNeverRestoresData() = runBlocking {
        val checkpoint = coordinator.prepareManual()
        database.ledgerDeletionArchiveDao().upsert(
            FluviLedgerDeletionArchiveEntity(
                entryId = "00000000000000000000000010",
                ledgerSheetRowPayload = "{\"entryId\":\"00000000000000000000000010\"}",
                deletedAtUtcMs = 1_700_000_000_000L,
                requiredCheckpointId = checkpoint.id,
            ),
        )

        coordinator.markBundlePrepared(checkpoint.id, "/private/fluvi/checkpoint.bundle")
        coordinator.markAcknowledged(checkpoint.id, "remote-file-id")
        val restorePlan = coordinator.prepareRestore(checkpoint.id)

        val acknowledged = requireNotNull(database.ledgerBackupCheckpointDao().findById(checkpoint.id))
        assertEquals(CheckpointStatus.acknowledged, acknowledged.status)
        assertEquals("remote-file-id", acknowledged.remoteBackupFileId)
        assertEquals(checkpoint.id, restorePlan.targetCheckpointId)
        assertEquals(CheckpointKind.beforeRestore, restorePlan.preRestoreCheckpoint.kind)
        assertNull(database.ledgerDeletionArchiveDao().findByEntryId("00000000000000000000000010"))
        assertTrue(database.ledgerDao().queryEntriesCount() == 0L)
    }

    @Test
    fun acknowledgedCheckpointMustHaveAPreparedBundleOrRemoteArtifactBeforeRestore() = runBlocking {
        val checkpoint = coordinator.prepareManual()

        val acknowledgement = runCatching {
            coordinator.markAcknowledged(checkpoint.id, remoteBackupFileId = null)
        }.exceptionOrNull()

        assertTrue(acknowledgement is IllegalArgumentException)
    }

    private class IncrementingIds : FluviIdGenerator {
        private var nextValue = 1L

        override fun next(): String = nextValue++.toString().padStart(26, '0')
    }
}
