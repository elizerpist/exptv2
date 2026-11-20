#!/usr/bin/env python3
"""Overlay only androidTest; never alter application runtime in either arm."""
from pathlib import Path
import sys
p = Path(sys.argv[1]) / 'android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardR12ServiceTimingInstrumentationTest.kt'
s = p.read_text()
old = 'KeyguardR15AcquisitionTestHooks.historicalRootOnlyOptIn = arm == "candidate"'
assert s.count(old) == 1
s = s.replace(old, 'KeyguardR15AcquisitionTestHooks.historicalRootOnlyOptIn = false // Exercise each actual production path.')
needle = 'assertEquals("real service must own the selected holder route", if (wakeMode == KeyguardOrbRenderMode.LEGACY_R11) 0 else 1, surfaceCount)'
replacement = '''val r18DirectExpected = args.getString("r18ExpectedPipeline") == "true"
                    assertEquals("real service must own the selected expected route", if (r18DirectExpected || wakeMode == KeyguardOrbRenderMode.LEGACY_R11) 0 else 1, surfaceCount)'''
assert s.count(needle) == 1
s = s.replace(needle, replacement)
needle = 'if (wakeMode != KeyguardOrbRenderMode.LEGACY_R11) {\n                        await("$name first current target post"'
replacement = '''if (r18DirectExpected) {
                        // Existing R16 holder-only metrics are not available for R18.
                        // Independent video and the bounded capture remain separate
                        // evidence; visible=true is not a physical first pixel.
                        SystemClock.sleep(1000)
                        record("WAKE", "name=$name wake=$wake attached=$attached firstPost=UNOBSERVED distinct=UNOBSERVED route=R18_DIRECT physicalPresentation=UNOBSERVED")
                    } else if (wakeMode != KeyguardOrbRenderMode.LEGACY_R11) {
                        await("$name first current target post"'''
assert s.count(needle) == 1
s = s.replace(needle, replacement)
p.write_text(s)
