#!/usr/bin/env python3
"""Host controls for source, process, scope and timing-only evidence."""
import importlib.util
import sys
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("oracle", Path(__file__).with_name("keyguard-r12-candidate-oracle.py"))
oracle = importlib.util.module_from_spec(spec)
spec.loader.exec_module(oracle)
source = "a" * 40
run_id = "12345678-1234-4234-8234-123456789abc"
capture_id = "87654321-4321-4321-8321-cba987654321"
raw = ("INSTRUMENTATION_STATUS: numtests=1\n"
       "INSTRUMENTATION_STATUS: test=fourRealWakeCyclesUseRequestedRoute\n"
       "INSTRUMENTATION_STATUS_CODE: 1\n"
       "INSTRUMENTATION_STATUS: test=fourRealWakeCyclesUseRequestedRoute\n"
       "INSTRUMENTATION_STATUS_CODE: 0\nOK (1 test)\nINSTRUMENTATION_CODE: -1\n")
fixture = f"PROCESS up=1 source={source} run={run_id} capture={capture_id} mode=SURFACE_LIVE pid=1234\n"
for index, name in enumerate(("cold", "warm1", "warm2", "warm3")):
    base = 100 + index * 10000
    fixture += f"WAKE up={base+5} name={name} wake={base} attached={base+1} firstPost={base+2} distinct={base+3} meaning=producer_not_presentation\n"
    if index == 1:
        fixture += "LOCKED_INTERVAL up=15201 name=warm1 start=10201 end=15201 postsStart=1 postsEnd=5\n"
    fixture += f"WITHDRAWN up={base+8} name={name} trigger={base+6} detached={base+7} physicalRemoval=UNOBSERVED\n"
fixture += "RESULT up=999 PASS timing_control_only\n"
capture = f"build={source}\ncaptureId={capture_id}\n"
assert not oracle.verify(raw, fixture, capture, source, "SURFACE_LIVE", run_id)
cases = [
    (raw.replace("OK (1 test)", "FAILURES!!!"), fixture, capture, source, "SURFACE_LIVE", run_id, ""),
    (raw.replace("fourRealWakeCyclesUseRequestedRoute", "other"), fixture, capture, source, "SURFACE_LIVE", run_id, ""),
    (raw + "INSTRUMENTATION_STATUS_CODE: -3\n", fixture, capture, source, "SURFACE_LIVE", run_id, ""),
    (raw, fixture, capture, "b" * 40, "SURFACE_LIVE", run_id, ""),
    (raw, fixture, capture, source, "SURFACE_STATIC", run_id, ""),
    (raw, fixture, capture, source, "SURFACE_LIVE", "00000000-0000-4000-8000-000000000001", ""),
    (raw, fixture, capture, source, "SURFACE_LIVE", run_id, "1234"),
    (raw, fixture.replace("name=warm2", "name=warm1"), capture, source, "SURFACE_LIVE", run_id, ""),
    (raw, fixture.replace("physicalRemoval=UNOBSERVED", "physicalRemoval=0", 1), capture, source, "SURFACE_LIVE", run_id, ""),
    (raw, fixture.replace("end=15201", "end=10202"), capture, source, "SURFACE_LIVE", run_id, ""),
    (raw, fixture.replace("PASS timing_control_only", "FAIL cleanup"), capture, source, "SURFACE_LIVE", run_id, ""),
    (raw, fixture.replace("distinct=103", "distinct=UNOBSERVED"), capture, source, "SURFACE_LIVE", run_id, ""),
    (raw, fixture, capture.replace(capture_id, "wrong"), source, "SURFACE_LIVE", run_id, ""),
]
for case in cases:
    assert oracle.verify(*case), case
print(f"PASS timing-only verifier: 1 positive and {len(cases)} fail-closed identity/evidence controls")
