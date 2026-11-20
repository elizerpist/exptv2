#!/usr/bin/env python3
"""Wait for the calibrated actual underlay before the existing panel assertion.
Only androidTest is overlaid; runtime source and assertions remain unchanged.
"""
from pathlib import Path
p = Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardOrbPresentationPipelineInstrumentationTest.kt')
s = p.read_text()
old = '''            val before = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
            before.save(File(runDir, "01-before.png"))
            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)'''
new = '''            val size = context.resources.getDimensionPixelSize(R.dimen.fluvi_keyguard_orb_size)
            val expectedUnderlay = Color.rgb(11, 177, 67)
            // waitForIdleSync can return while the launch splash is still
            // physically composed. Require the known underlay at both the
            // eventual sample and the screen centre before taking the control.
            val before = awaitScreenshot(10_000) { bitmap ->
                val x = 100 + size / 2; val y = 250 + size / 2
                x in 0 until bitmap.width && y in 0 until bitmap.height &&
                    colorDistance(expectedUnderlay, bitmap.getPixel(x, y)) <= 15 &&
                    colorDistance(expectedUnderlay, bitmap.getPixel(bitmap.width / 2, bitmap.height / 2)) <= 15
            }
            before.save(File(runDir, "01-before.png"))'''
assert s.count(old) == 1
p.write_text(s.replace(old, new))
