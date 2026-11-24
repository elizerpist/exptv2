#!/usr/bin/env python3
"""Judge only the synthetic R35 separate-process instrumentation evidence."""
import re
import sys
from pathlib import Path

FRAME = re.compile(r"R35_DEMO_(A|B|EMPTY) sequence=(\d+) receiverPid=(\d+) changedPixels=(\d+) sha256=([0-9a-f]{64})")
RETAINED = re.compile(r"R35_PARENT_B_NO_READY storedRevision=2 receiverPid=(\d+) retainedSequence=(\d+) changedPixels=(\d+) sha256=([0-9a-f]{64})")


def verdict(arm: str, instrumentation: str, logcat: str) -> tuple[bool, str]:
    if arm not in ("parent", "candidate"):
        return False, "unknown arm"
    if "INSTRUMENTATION_FAILED" in instrumentation or "Process crashed" in instrumentation or "shortMsg=" in instrumentation:
        return False, "instrumentation infrastructure failed"
    frames = FRAME.findall(logcat)
    if len([f for f in frames if f[0] == "A"]) != 1:
        return False, "matching A image not established exactly once"
    a = next(f for f in frames if f[0] == "A")
    if int(a[1]) <= 0 or int(a[2]) <= 0 or int(a[3]) <= 0:
        return False, "A identity or pixels invalid"
    if logcat.count("R35_DEMO_B_ATTEMPT storedRevision=2") != 1:
        return False, "accepted B store attempt not established"
    if arm == "parent":
        retained = RETAINED.findall(logcat)
        if logcat.count("R35_PARENT_FIXTURE: A seeded explicitly") != 1 or len(retained) != 1:
            return False, "parent fixture or live-receiver observation absent"
        if any(f[0] != "A" for f in frames):
            return False, "unexpected parent B or EMPTY output"
        pid, sequence, pixels, digest = retained[0]
        if (pid, sequence, digest) != (a[2], a[1], a[4]) or int(pixels) <= 0:
            return False, "parent did not retain the same A in the live receiver"
        if "B never reached independently prepared READY" not in instrumentation or not re.search(r"Tests run: 1,\s*Failures: 1", instrumentation):
            return False, "expected parent B failure not established"
        return True, "PARENT_EXPECTED_RED_AFTER_A_AND_ACCEPTED_B"
    if "FAILURES!!!" in instrumentation or not re.search(r"OK \(1 test\)", instrumentation):
        return False, "candidate instrumentation did not pass"
    if [f[0] for f in frames] != ["A", "B", "EMPTY"]:
        return False, "candidate A/B/EMPTY order or uniqueness invalid"
    _, b, empty = frames
    if not (int(a[1]) < int(b[1]) < int(empty[1])) or not (a[2] == b[2] == empty[2]):
        return False, "candidate sequence or receiver identity changed"
    if int(b[3]) <= 0 or int(empty[3]) != 0 or a[4] == b[4]:
        return False, "candidate pixels do not establish changed B and EMPTY"
    return True, "CANDIDATE_PASS_A_B_EMPTY"


def main() -> int:
    if len(sys.argv) != 4:
        print("usage: r35-publisher-verdict.py parent|candidate instrumentation.txt logcat.txt", file=sys.stderr)
        return 2
    ok, result = verdict(sys.argv[1], Path(sys.argv[2]).read_text(errors="replace"), Path(sys.argv[3]).read_text(errors="replace"))
    print(result)
    return 0 if ok else 1


if __name__ == "__main__":
    raise SystemExit(main())
