#!/usr/bin/env python3
"""Provenance guard only: physical visibility/privacy requires service tests."""
from pathlib import Path
import subprocess

root = Path(__file__).resolve().parent.parent
service_path = 'android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt'
surface_path = 'android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardCardSurface.kt'
reader_path = 'android/app/src/main/kotlin/com/fluvi/app/lockscreen/KeyguardWindowSnapshotReader.kt'
service = (root / service_path).read_text()
surface = (root / surface_path).read_text()
reader = (root / reader_path).read_text()
baseline = subprocess.check_output(['git', 'show', '0905f0d6e81cba396663c6b09898171913c195a9:' + surface_path], cwd=root, text=True)

def section(text, start, end):
    a = text.index(start)
    return text[a:text.index(end, a)]

# The actual positive classifier must remain byte-for-byte R38, including all
# priority, foreign-window and incomplete-tree privacy checks.
start = '    fun classifyDetailed('
end = '\n}\n\ninternal enum class KeyguardCardVisibility'
assert section(surface, start, end) == section(baseline, start, end)

# No R39 provenance, arm, allocation, timestamp or formatting in the original
# grant/native-apply segment. Test-only post-ACK pointer publication is later.
grant = section(service, '            val stamp = directToken.stamp\n            if (!r18Coordinator.grant(',
                '            recordR18(directOwner, "GRANT", proof = proof)')
apply = section(service, '                        }, nativeApplied = {', '                        }, stillAuthorized = {')
for block in (grant, apply):
    assert all(term not in block for term in ('r39', 'r40', 'R40', 'Provenance', 'armPresented'))

read_entry = section(service, '    private fun readInspection(', '        val r38MilestoneOrdered')
assert 'visibleOwner?.r40Acknowledged' in read_entry
assert 'if (visibleOwner != null && visibleBinding != null) synchronized(queueLock)' in read_entry
assert 'Grant.PRESENTED' in read_entry and 'R40Read(' in read_entry
ack = section(service, 'if (success && r18Coordinator.revealSubmitted(permit)) {', '} else if (!success')
assert ack.index('r18Coordinator.revealSubmitted(permit)') < ack.index('directOwner.r40Acknowledged = binding')
assert all(term not in ack for term in ('armPresented', 'r40ProvenanceStarted', 'KeyguardR40ClockProvenance('))
assert 'if (r40Read != null) runCatching { inspectionProbeForTest?.r40ProvenanceStarted(request) }' in service
assert 'if (r40 != null && rootPackage in SYSTEM_PACKAGES && root != null)' in reader
assert 'if (r40Provenance != null) r40Provenance.marker(id)' in reader
print('PASS R38 classifier, grant and native submit unchanged; optional traversal reachable only from post-ACK owner')
print('LIMIT: structural evidence is not a composited frame or real-device service test')
