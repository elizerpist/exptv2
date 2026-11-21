#!/usr/bin/env python3
"""Identical Android-test-only cadence accounting and controlled phase probe."""
from pathlib import Path
p=Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/material/KeyguardHeaderMaterialViewInstrumentationTest.kt')
s=p.read_text()
a=s.index('    private fun passiveReferences(')
b=s.index('    /** Compare every ROI pixel',a)
part=s[a:b]
old='''                                  referencePhase: Float = PHASE_A): PassiveReferences {'''
new='''                                  referencePhase: Float = PHASE_A,
                                  fullProfile: KeyguardMaterialProfile = calibratedOrbProfile()): PassiveReferences {'''
assert part.count(old)==1;part=part.replace(old,new)
old='''            val profile = calibratedOrbProfile()
            val artifact = AndroidKeyguardShaderArtifactReader.load(activity, profile.effectId, profile.usesPortal)'''
new='''            val profile = fullProfile
            val artifact = AndroidKeyguardShaderArtifactReader.load(activity, profile.effectId, profile.usesPortal)'''
assert part.count(old)==1;part=part.replace(old,new)
s=s[:a]+part+s[b:]
a=s.index('    @Test fun r22_3TranslucentSteadyCadence()')
b=s.index('    @Test fun isolatedStandbyPreservesAuthorizedComposition()',a)
part=s[a:b]
old='''                    state = "inFlight=${observed.isolatedFramesInFlight} ready=${observed.isolatedFramesReady} owned=${observed.isolatedFramesCompositorOwned} route=${observed.effectiveRoute}"'''
new='''                    val summary = requireNotNull(fixture.window.attachmentRenderSummary())
                    state = "inFlight=${observed.isolatedFramesInFlight} ready=${observed.isolatedFramesReady} owned=${observed.isolatedFramesCompositorOwned} route=${observed.effectiveRoute} produced=${observed.isolatedFramesProduced} published=${observed.isolatedFramesPublished} dropped=${observed.isolatedFramesDropped} skipped=${summary.isolatedTranslucentSteadySkipped}"'''
assert part.count(old)==1;part=part.replace(old,new)
start=part.index('                var state = "UNOBSERVED"')
end=part.index('                assertTrue("terminal fixed-pool snapshot',start)
block=part[start:end]
part=part[:start]+part[end:]
insert=part.index('                assertEquals("cadence observation overflow"')
part=part[:insert]+block+part[insert:]
s=s[:a]+part+s[b:]
marker='''    @Test fun isolatedStandbyPreservesAuthorizedComposition()'''
test='''    @Test fun r22_4ControlledTranslucentProducerAndCompositorPhases() {
        val translucent = calibratedOrbProfile().copy(opacity = .5f)
        val refA = passiveReferences(referencePhase = PHASE_A, fullProfile = translucent)
        val refB = passiveReferences(referencePhase = PHASE_B, fullProfile = translucent)
        try {
            assertTrue("NOT REACHED: independent translucent A/B references are not distinct",
                compareMaterialPixels(refA.full, refB.full).meaningful())
            withOrbRetirementFixture("r22-4-controlled-translucent", NoopKeyguardOrbRecoveryTestHook,
                initialProfile = translucent) { f ->
                val errors = mutableListOf<String>()
                val held = mutableListOf<OrbRetirementCapture>()
                val phases = listOf(PHASE_A, PHASE_C, PHASE_B, PHASE_A)
                phases.forEachIndexed { i, phase ->
                    val result = runCatching {
                        f.capture(phase, "phase-$i") { image ->
                            val reference = if (i == 2) refB.full else refA.full
                            compareMaterialPixels(reference, image).nearlyEqual()
                        }
                    }
                    result.onSuccess { held += it }.onFailure { errors += "phase=$i:$phase ${it.javaClass.simpleName}:${it.message}" }
                }
                try {
                    File(f.activity.filesDir, "keyguard-material-smoke/r22-4-controlled-phases.txt")
                        .writeText("phases=$phases captured=${held.map { it.frame.lease to it.frame.testRequestId }} errors=$errors\\n")
                    assertTrue("controlled phase/compositor evidence failed: $errors", errors.isEmpty())
                    assertEquals(4, held.size)
                    assertTrue("A/B compositor phases must be distinct", compareMaterialPixels(held[0].bitmap, held[2].bitmap).meaningful())
                    assertTrue("A return must match independent A", compareMaterialPixels(held[0].bitmap, held[3].bitmap).nearlyEqual())
                } finally { held.forEach { it.bitmap.recycle() } }
            }
        } finally { refA.recycle(); refB.recycle() }
    }

'''
assert s.count(marker)==1;s=s.replace(marker,test+marker)
p.write_text(s)
