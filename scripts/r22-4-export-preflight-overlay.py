from pathlib import Path
p=Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt')
s=p.read_text()
old='''                val (show, hide) = checkNotNull(expected[id])
                assertTrue(row.contains("firstShow=$show/")); assertTrue(row.contains("finalHide=$hide/"))'''
new='''                val (show, hide) = checkNotNull(expected[id])
                // The compact core must identify the original wake callback,
                // not a later pipeline ingress or test-trigger timestamp.
                val wakeCallback = id * 10_000L
                assertTrue("R22.4 precondition: actual wake callback missing from compact core: $row",
                    row.contains("wakeCallback=$wakeCallback "))
                assertTrue("R22.4 precondition: wake identity missing: $row", row.contains("wake=$id "))
                assertTrue(row.contains("firstShow=$show/")); assertTrue(row.contains("finalHide=$hide/"))'''
assert s.count(old)==1;s=s.replace(old,new)
p.write_text(s)
