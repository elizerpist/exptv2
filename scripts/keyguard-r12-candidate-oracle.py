#!/usr/bin/env python3
"""Fail-closed verifier for the R12 *timing-only* real-service control.

This deliberately does not certify compositor pixels, privacy or the full
R12 gate. Those require separate real-service visual/lifecycle evidence.
"""
import argparse
import re
import sys
import uuid
from pathlib import Path


def verify(raw: str, fixture: str, capture: str, source: str, mode: str, run_id: str, prior_pid: str = "") -> list[str]:
    errors: list[str] = []
    if not re.fullmatch(r"[0-9a-f]{40}", source):
        errors.append("source_invalid")
    if mode not in {"SURFACE_LIVE", "SURFACE_STATIC", "LEGACY_R11"}:
        errors.append("mode_invalid")
    try:
        if str(uuid.UUID(run_id)) != run_id:
            raise ValueError()
    except (ValueError, AttributeError):
        errors.append("uuid_invalid")
    method = "fourRealWakeCyclesUseRequestedRoute"
    if (raw.count("INSTRUMENTATION_STATUS: test=" + method) != 2 or
            "INSTRUMENTATION_STATUS: numtests=1" not in raw or
            "INSTRUMENTATION_STATUS_CODE: 1" not in raw or
            "INSTRUMENTATION_STATUS_CODE: 0" not in raw or
            "INSTRUMENTATION_CODE: -1" not in raw or
            not re.search(r"(?m)^OK \(1 test\)\s*$", raw)):
        errors.append("instrumentation_not_exact_success")
    if re.search(r"FAILURES!!!|INSTRUMENTATION_FAILED|INSTRUMENTATION_STATUS_CODE: -[1234]|Exception|timed out", raw, re.I):
        errors.append("instrumentation_failure_or_skip")
    process = re.findall(r"(?m)^PROCESS up=\d+ source=(\S+) run=(\S+) capture=(\S+) mode=(\S+) pid=(\d+)\s*$", fixture)
    if len(process) != 1:
        errors.append("process_row_missing_or_duplicate")
    else:
        observed_source, observed_run, capture_id, observed_mode, pid = process[0]
        if (observed_source, observed_run, observed_mode) != (source, run_id, mode):
            errors.append("process_identity_mismatch")
        if pid == prior_pid or pid == "0":
            errors.append("not_fresh_process")
        if not capture_id or capture_id == "UNOBSERVED" or f"captureId={capture_id}" not in capture:
            errors.append("capture_identity_mismatch")
        if f"build={source}" not in capture:
            errors.append("capture_source_mismatch")
    wakes = re.findall(r"(?m)^WAKE up=\d+ name=(cold|warm[123]) wake=(\d+) attached=(\d+) (.+)$", fixture)
    withdrawals = re.findall(r"(?m)^WITHDRAWN up=\d+ name=(cold|warm[123]) trigger=(\d+) detached=(\d+) physicalRemoval=UNOBSERVED\s*$", fixture)
    if [row[0] for row in wakes] != ["cold", "warm1", "warm2", "warm3"]:
        errors.append("four_wakes_missing_or_reordered")
    if [row[0] for row in withdrawals] != ["cold", "warm1", "warm2", "warm3"]:
        errors.append("four_withdrawals_missing_or_reordered")
    for name, wake, attach, details in wakes:
        if int(attach) < int(wake):
            errors.append("wake_clock_order:" + name)
        if mode == "SURFACE_LIVE" and not re.search(r"firstPost=\d+ distinct=\d+", details):
            errors.append("live_posts_missing:" + name)
        if mode == "SURFACE_STATIC" and not re.search(r"firstPost=\d+", details):
            errors.append("static_post_missing:" + name)
        if mode == "LEGACY_R11" and "route=LEGACY_R11" not in details:
            errors.append("legacy_route_missing:" + name)
    for name, trigger, detached in withdrawals:
        if int(detached) < int(trigger):
            errors.append("withdraw_clock_order:" + name)
    if mode == "LEGACY_R11":
        interval = re.findall(r"(?m)^LOCKED_INTERVAL up=\d+ name=warm1 start=(\d+) end=(\d+) postsStart=UNOBSERVED postsEnd=UNOBSERVED route=LEGACY_R11\s*$", fixture)
    else:
        interval = re.findall(r"(?m)^LOCKED_INTERVAL up=\d+ name=warm1 start=(\d+) end=(\d+) postsStart=\d+ postsEnd=\d+\s*$", fixture)
    if len(interval) != 1 or int(interval[0][1]) - int(interval[0][0]) < 5000:
        errors.append("locked_interval_missing_or_short")
    if fixture.count("RESULT ") != 1 or "PASS timing_control_only" not in fixture or re.search(r"(?m)^FAILURE ", fixture):
        errors.append("fixture_failure_or_missing_cleanup")
    return errors


def main() -> int:
    parser = argparse.ArgumentParser()
    for name in ("raw", "fixture", "capture", "source", "mode", "run-id"):
        parser.add_argument("--" + name, required=True)
    parser.add_argument("--prior-pid", default="")
    args = parser.parse_args()
    try:
        errors = verify(Path(args.raw).read_text(), Path(args.fixture).read_text(), Path(args.capture).read_text(),
                        args.source, args.mode, args.run_id, args.prior_pid)
    except (OSError, UnicodeError) as error:
        print("FAIL evidence_unreadable", error)
        return 1
    if errors:
        print("FAIL timing_control " + ",".join(errors))
        return 1
    print("PASS timing_control_only; compositor/privacy/full_contract=NOT_ESTABLISHED")
    return 0


if __name__ == "__main__":
    sys.exit(main())
