#!/usr/bin/env python3
"""Build one fail-closed aggregate specimen from archived, single-test bytes.

This tool does not infer pixels, process identities, or success from a status
file. Unsupported or incomplete extractions retain their raw evidence and
remain NOT_ESTABLISHED. The run metadata must come from the completed Actions
run; package receipts and process start ticks must have been measured on-device.
"""
from __future__ import annotations

import argparse
import hashlib
import importlib.util
import json
import re
import shutil
import sys
import uuid
from pathlib import Path

sys.dont_write_bytecode = True


def module(name: str, filename: str):
    spec = importlib.util.spec_from_file_location(name, Path(__file__).with_name(filename))
    value = importlib.util.module_from_spec(spec)
    assert spec.loader is not None
    spec.loader.exec_module(value)
    return value


aggregate = module("r14aggregate", "keyguard-r14-aggregate.py")
timing = module("r12timing", "keyguard-r12-candidate-oracle.py")


def key_values(text: str) -> dict[str, str]:
    result: dict[str, str] = {}
    for line in text.splitlines():
        if "=" not in line:
            continue
        key, value = line.split("=", 1)
        if re.fullmatch(r"[A-Za-z_]+", key):
            if key in result:
                raise ValueError(f"duplicate_identity:{key}")
            result[key] = value
    return result


def receipt(path: Path) -> str:
    match = re.fullmatch(r"expected=([0-9a-f]{64}) installed=([0-9a-f]{64})(?: path=[^\n]+)?\n?",
                         path.read_text().replace("\r\n", "\n"))
    if not match or match[1] != match[2]:
        raise ValueError("installed_package_receipt_invalid")
    return match[1]


def process(path: Path) -> tuple[int, int]:
    match = re.fullmatch(r"pid=([0-9]+) startTicks=([0-9]+)\n?", path.read_text().replace("\r\n", "\n"))
    if not match or min(int(match[1]), int(match[2])) <= 0:
        raise ValueError("real_process_identity_missing")
    return int(match[1]), int(match[2])


def make(args: argparse.Namespace) -> tuple[dict, list[str]]:
    method = aggregate.REQUIRED.get((args.row, args.route))
    if method is None or not re.fullmatch(r"[0-9a-f]{40}", args.source):
        raise ValueError("source_or_required_case_invalid")
    identity = key_values(args.identity.read_text())
    run_uuid = str(uuid.UUID(identity.get("run_uuid", "")))
    if (identity.get("source") or identity.get("source_sha")) != args.source:
        raise ValueError("identity_source_mismatch")
    selector = identity.get("selector", "")
    expected_selector = aggregate.expected_class(args.row) + "#" + method
    if selector != expected_selector:
        raise ValueError("identity_method_or_class_mismatch")
    if identity.get("mode") is not None and args.route in aggregate.ROUTES and identity["mode"] != args.route:
        raise ValueError("identity_route_mismatch")
    pid, start = process(args.process)
    app = receipt(args.app_before)
    test = receipt(args.test_before)
    if app != receipt(args.app_after) or test != receipt(args.test_after):
        raise ValueError("installed_bytes_changed")
    metadata = json.loads(args.run_metadata.read_text())
    if not (metadata.get("databaseId") == args.run_id and metadata.get("headSha") == args.source
            and metadata.get("event") == "workflow_dispatch"
            and any(job.get("databaseId") == args.job_id for job in metadata.get("jobs", []))):
        raise ValueError("run_or_job_provenance_mismatch")
    raw = args.transcript.read_text().replace("\r\n", "\n")
    exact_test = aggregate.instrumented(raw, method, aggregate.expected_class(args.row))
    fixture = args.fixture.read_text().replace("\r\n", "\n")
    if not fixture.strip():
        raise ValueError("fixture_missing")
    args.out.mkdir(parents=True, exist_ok=False)
    files: dict[str, str] = {}

    def copy(label: str, source: Path) -> str:
        name = f"{label}{source.suffix}"
        target = args.out / name
        shutil.copyfile(source, target)
        files[name] = hashlib.sha256(target.read_bytes()).hexdigest()
        return name

    case = dict(row=args.row, route=args.route, method=method, source=args.source, scope=args.scope,
                run_id=args.run_id, job_id=args.job_id, pid=pid, process_start=start, run_uuid=run_uuid,
                app_sha256=app, test_sha256=test, installed_app_sha256=app, installed_test_sha256=test,
                transcript=copy("transcript", args.transcript), app_receipt=copy("app-before", args.app_before),
                test_receipt=copy("test-before", args.test_before), app_after_receipt=copy("app-after", args.app_after),
                test_after_receipt=copy("test-after", args.test_after), run_metadata=copy("run-metadata", args.run_metadata),
                fixture=copy("fixture", args.fixture), identity_file=copy("identity", args.identity),
                process_file=copy("process", args.process), records="records.jsonl")
    actual_process = dict(kind="PROCESS", source=args.source, run_uuid=run_uuid, pid=pid,
                          process_start=start, route=args.route, row=args.row)
    result: dict = dict(kind="RESULT", row=args.row, status="NOT_ESTABLISHED",
                        reason="row_specific_evidence_not_yet_verified")
    if not exact_test:
        result.update(status="FAIL", reason="instrumentation_not_exact_success")
    elif args.row == "r12_natural_timing" and args.capture:
        capture_text = args.capture.read_text()
        errors = timing.verify(raw, fixture, capture_text, args.source, args.route, run_uuid)
        copy("capture", args.capture)
        result.update(status="PASS" if not errors else "FAIL", timing_errors=errors,
                      meaning="producer_timing_only_not_compositor")
    elif args.row in {"r12_ordered", "r12_occlusion"} and args.route == "LEGACY_R11":
        result.update(status="PASS", meaning="exact_legacy_service_instrumentation_only")
    elif args.row == "r14_pressure" and len(args.report) == 1:
        report_text = args.report[0].read_text()
        report = copy("report", args.report[0])
        captures = re.findall(r"(?m)^captureId=([^\n]+)$", report_text)
        if len(captures) == 1:
            case["capture_id"] = captures[0]
        result.update(status="PASS", report=report)
        if (f"build={args.source}\n" not in report_text or f"captureMode={args.route}\n" not in report_text
                or len(captures) != 1 or aggregate.check_specific(args.row, args.route, result, args.out)):
            result.update(status="FAIL", reason="pressure_report_failed")
    elif args.row == "r12_pressure" and len(args.report) == 2:
        paths = [copy(f"report-{index}", path) for index, path in enumerate(args.report)]
        result.update(status="PASS", reports=paths)
        if any(f"build={args.source}\n" not in path.read_text() for path in args.report) or aggregate.check_specific(args.row, args.route, result, args.out):
            result.update(status="FAIL", reason="pressure_reports_failed")
    elif args.row == "r13_service_demand_burst":
        inspections = [line for line in fixture.splitlines() if line.startswith("inspection=")]
        changes = [line for line in fixture.splitlines() if line.startswith("financialChange=OBSERVED ")]
        ids = [re.match(r"inspection=(\d+) ", line) for line in inspections]
        if len(inspections) == 32 and all(ids) and len({item[1] for item in ids}) == 32 and len(changes) == 1:
            numbers = dict(re.findall(r"(actualPaints|actualBinds)=([0-9]+)", changes[0]))
            result.update(status="PASS", distinct_completed_inspections=32, first_attach=True,
                          geometry_only=sum("geometryOnly=true" in line for line in inspections) == 1,
                          content_change=True, actual_paints=int(numbers.get("actualPaints", "-1")),
                          actual_legacy_binds=int(numbers.get("actualBinds", "-1")))
            if aggregate.check_specific(args.row, args.route, result, args.out):
                result.update(status="FAIL", reason="financial_scope_failed")
    elif args.row == "r12_selector_persistence" and all((args.phase_one_fixture, args.phase_one_receipt,
            args.phase_one_identity, args.phase_one_process, args.phase_one_transcript,
            args.phase_one_app_before, args.phase_one_app_after, args.phase_one_test_before, args.phase_one_test_after)):
        first_fixture = args.phase_one_fixture.read_text().replace("\r\n", "\n")
        first_receipt = key_values(args.phase_one_receipt.read_text())
        first_identity = key_values(args.phase_one_identity.read_text())
        first_pid, first_start = process(args.phase_one_process)
        first_raw = args.phase_one_transcript.read_text().replace("\r\n", "\n")
        first_receipts = (receipt(args.phase_one_app_before), receipt(args.phase_one_app_after),
                          receipt(args.phase_one_test_before), receipt(args.phase_one_test_after))
        pending = re.search(r"(?m)^stage=PENDING .* attachment=(\d+) before=(\w+) selected=(\w+) effective=(\w+) pending=true$", first_fixture)
        attached = re.search(r"(?m)^stage=REATTACHED .* attachment=(\d+) configured=(\w+) effective=(\w+) pending=false$", first_fixture)
        restored = re.search(r"(?m)^stage=PRE_FIXTURE_READ .* configured=(\w+) pid=(\d+) processStart=(\d+)$", fixture)
        restarted = re.search(r"(?m)^stage=RESTARTED .* configured=(\w+) effective=(\w+) fallback=(true|false)$", fixture)
        eligible = re.search(r"(?m)^stage=ELIGIBLE_AGAIN .* effective=(\w+)$", fixture)
        legacy_fallback = re.search(r"(?m)^stage=INELIGIBLE_FALLBACK .* configured=SURFACE_LIVE effective=LEGACY_R11$", fixture)
        first_ok = (aggregate.instrumented(first_raw, method, aggregate.expected_class(args.row))
            and first_identity.get("source") == args.source and first_identity.get("run_uuid") == run_uuid
            and first_identity.get("selector") == expected_selector and first_identity.get("mode") == args.route
            and first_receipt.get("source") == args.source and first_receipt.get("case") == run_uuid
            and first_receipt.get("target") == args.route and first_receipt.get("result") == "PASS"
            and first_receipt.get("pid") == str(first_pid) and first_receipt.get("processStart") == str(first_start)
            and first_receipts == (app, app, test, test) and pending and attached
            and 0 <= first_fixture.find("stage=FIXTURE_START ") < first_fixture.find("stage=PENDING ") < first_fixture.find("stage=REATTACHED ")
            and pending[2] == pending[4] and pending[3] == args.route and pending[2] != args.route
            and attached[2] == attached[3] == args.route and int(attached[1]) > int(pending[1]))
        second_ok = (restored and 0 <= fixture.find("stage=PRE_FIXTURE_READ ") < fixture.find("stage=FIXTURE_START ") < fixture.find("stage=RESTARTED ")
            and restored[1] == args.route and restored[2] == str(pid) and restored[3] == str(start)
            and restarted and restarted[1] == args.route and eligible and eligible[1] == args.route)
        fallback_ok = bool(restarted and ((args.route != "LEGACY_R11" and restarted[2] == "LEGACY_R11" and restarted[3] == "true")
                                      or (args.route == "LEGACY_R11" and legacy_fallback)))
        phase_one = [dict(actual_process, phase=1, pid=first_pid, process_start=first_start),
                     dict(kind="SELECTOR_WRITE", route=pending[3] if pending else "UNOBSERVED"),
                     dict(kind="PHASE_COMPLETE" if attached else "PHASE_INCOMPLETE")]
        second_process = dict(actual_process, phase=2)
        extra_second = [dict(kind="RESTORED_BEFORE_FIXTURE", route=restored[1] if restored else "UNOBSERVED")]
        result.update(status="PASS" if first_ok and second_ok else "FAIL", real_store_write=bool(pending),
                      attached_pending_boundary=bool(pending), configured=args.route,
                      effective_after_fresh_attach=attached[3] if attached else None,
                      process_ids=[first_pid, pid], second_process_restored=bool(second_ok),
                      unsupported_fallback_checked=fallback_ok)
        phase_path = args.out / "phase-one-records.jsonl"
        phase_path.write_text("".join(json.dumps(item, sort_keys=True) + "\n" for item in phase_one))
        files[phase_path.name] = hashlib.sha256(phase_path.read_bytes()).hexdigest()
        case.update(phase_one_records=phase_path.name, phase_one_fixture=copy("phase-one-fixture", args.phase_one_fixture),
                    phase_one_identity=copy("phase-one-identity", args.phase_one_identity),
                    phase_one_process=copy("phase-one-process", args.phase_one_process),
                    phase_one_store_receipt=copy("phase-one-store", args.phase_one_receipt),
                    phase_one_transcript=copy("phase-one-transcript", args.phase_one_transcript),
                    phase_one_app_receipt=copy("phase-one-app-before", args.phase_one_app_before),
                    phase_one_app_after_receipt=copy("phase-one-app-after", args.phase_one_app_after),
                    phase_one_test_receipt=copy("phase-one-test-before", args.phase_one_test_before),
                    phase_one_test_after_receipt=copy("phase-one-test-after", args.phase_one_test_after))
        actual_process = second_process
    else:
        extra_second = []
    if args.row != "r12_selector_persistence" or "extra_second" not in locals():
        extra_second = []
    record_rows = [actual_process] + extra_second + [result]
    (args.out / "records.jsonl").write_text("".join(json.dumps(item, sort_keys=True) + "\n" for item in record_rows))
    files["records.jsonl"] = hashlib.sha256((args.out / "records.jsonl").read_bytes()).hexdigest()
    case["evidence_sha256"] = files
    (args.out / "r14-case.json").write_text(json.dumps(case, indent=2, sort_keys=True) + "\n")
    return case, aggregate.verify_case(args.out, case, args.source)


def main() -> int:
    parser = argparse.ArgumentParser()
    for name in ("source", "scope", "row", "route"):
        parser.add_argument("--" + name, required=True)
    for name in ("run-id", "job-id"):
        parser.add_argument("--" + name, type=int, required=True)
    for name in ("identity", "process", "transcript", "fixture", "app-before", "test-before",
                 "app-after", "test-after", "run-metadata", "out"):
        parser.add_argument("--" + name, type=Path, required=True)
    parser.add_argument("--capture", type=Path)
    parser.add_argument("--report", type=Path, action="append", default=[])
    for name in ("phase-one-fixture", "phase-one-receipt", "phase-one-identity", "phase-one-process",
                 "phase-one-transcript", "phase-one-app-before", "phase-one-app-after", "phase-one-test-before", "phase-one-test-after"):
        parser.add_argument("--" + name, type=Path)
    try:
        args = parser.parse_args()
        case, errors = make(args)
        print(f"{case['row']}[{case['route']}]=" + ("FAIL:" + ",".join(errors) if errors else "PASS"))
        return 1 if errors else 0
    except (OSError, UnicodeError, ValueError, TypeError, json.JSONDecodeError) as error:
        print(f"CASE_NOT_ESTABLISHED: {error}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
