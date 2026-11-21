from pathlib import Path
import sys
p = Path('android/app/src/androidTest/kotlin/com/fluvi/app/lockscreen/KeyguardCardDiagnosticsInstrumentationTest.kt')
s = p.read_text()
marker = '    @Test fun r20FirstFrameBreakdownSurvivesFreezeAndReplacement()'
assert s.count(marker) == 1
addition = Path(sys.argv[1]).read_text()
assert 'r20IdenticalFirstScalarsAndZeroMotionRemainGenerationBound' not in s
p.write_text(s.replace(marker, addition + marker))
