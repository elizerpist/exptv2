#!/usr/bin/env python3
"""Structural R41 guard; real service and visual controls remain required."""
from pathlib import Path

root = Path(__file__).resolve().parent.parent
source = (root / "android/app/src/main/kotlin/com/fluvi/app/lockscreen/FluviKeyguardCardService.kt").read_text()

def section(start: str, end: str) -> str:
    begin = source.index(start)
    return source[begin:source.index(end, begin)]

offer = section("    private fun scheduleEvaluationCommon(", "    private data class CompletedInspection(")
launch = "queueOffer.start?.let { actual -> inspectionScope.launch { processInspectionQueue(actual) } }"
assert offer.index(launch) < offer.index('traceKeyguard(\n            if (startsWorker)'), \
    "optional queue reporting still precedes the committed reader launch"

ordered = section("            if (decision.successor == null || decision.snapshot == null) {",
                  "                val lateSuperseded =")
assert "if (!read.r38MilestoneOrdered)" in ordered, \
    "ordered DIRECT still reconstructs the inapplicable R25 route"
assert ordered.index("if (!read.r38MilestoneOrdered)") < ordered.index("r25CompleteLocked(read, handoff)")
assert "withContext(Dispatchers.Main.immediate)" in source[source.index("                val lateSuperseded ="):], \
    "ordered inspection must still hand off to Main"

handoff = section("    private fun applyInspection(", "    /**\n     * UNKNOWN and OCCLUDED")
assert "slowMainHandoffEvidenceSnapshot(" in handoff, "FULL snapshot must be captured at Main entry"
assert "deferredFields =" in handoff, "FULL overlap formatting must run on the reducer"
print("PASS R41 structural ordering; this does not establish service, privacy or physical timing")
